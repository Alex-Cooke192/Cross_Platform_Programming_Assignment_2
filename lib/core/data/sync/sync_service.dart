import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:maintenance_system/core/data/sync/local_sync_adapter.dart';
import 'package:maintenance_system/models/sync_models.dart';
import 'package:maintenance_system/core/data/sync/i_local_attachment_upload_adapter.dart';
import 'i_sync_service.dart';

class SyncService implements ISyncService {
  SyncService({
    required this.baseUrl,
    required this.clientId,
    required this.local,
    http.Client? httpClient,
    this.timeout = const Duration(seconds: 20),
    this.authStyle = AuthStyle.bearer,
  }) : _http = httpClient ?? http.Client();

  final String baseUrl;
  final String clientId;
  final LocalSyncAdapter local;
  final http.Client _http;
  final Duration timeout;
  @override
  final AuthStyle authStyle;

  static const _prefsKeyLastSyncAt = 'sync_last_sync_at';

  @override
  Future<DateTime?> getLastSyncAt() async {
    final prefs = await SharedPreferences.getInstance();
    final s = prefs.getString(_prefsKeyLastSyncAt);
    if (s == null || s.isEmpty) return null;
    return DateTime.tryParse(s);
  }

  Future<void> _setLastSyncAt(DateTime dt) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKeyLastSyncAt, dt.toUtc().toIso8601String());
  }

  static const _lastTechSyncAtKey = 'last_tech_sync_at';

  @override
  Future<DateTime?> getLastTechSyncAt() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_lastTechSyncAtKey);
    if (raw == null || raw.isEmpty) return null;
    return DateTime.tryParse(raw)?.toUtc();
  }

  Future<void> _setLastTechSyncAt(DateTime dt) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastTechSyncAtKey, dt.toUtc().toIso8601String());
  }

  Map<String, String> _buildAuthHeaders(String apiKey) {
    switch (authStyle) {
      case AuthStyle.bearer:
        return {'Authorization': 'Bearer $apiKey'};
      case AuthStyle.xApiKey:
        return {'X-API-Key': apiKey};
    }
  }

  // -----------------------
  // Attachment upload (blob)
  // -----------------------
  //
  // This assumes your backend exposes:
  //   POST  {baseUrl}/attachments/upload
  // with multipart/form-data:
  //   fields: attachment_id, client_id
  //   file: "file"
  //
  // And responds JSON:
  //   { "attachment_id": "...", "remote_key": "..." }
  //
  Future<void> _uploadPendingAttachments({required String apiKey}) async {
    // We can only do this if LocalSyncAdapter can expose pending attachments.
    // Your adapter doesn’t have that method, so we upload via changes collection:
    //
    // - collectLocalChanges includes attachments with localPath stored in DB
    // - but LocalSyncAdapter returns maps without localPath (by design)
    //
    // So: the real uploader should query DB directly.
    //
    // To keep this copy/paste-only, we rely on a pragmatic approach:
    // Add an optional hook: if local is DriftLocalSyncAdapter, it can expose db.
    //
    // If you’d rather keep it clean, implement attachment uploads inside the adapter itself.
    if (local is! LocalAttachmentUploadAdapter) return;

    final helper = local as LocalAttachmentUploadAdapter;
    final pending = await helper.getPendingAttachmentUploads();

    for (final item in pending) {
      final id = item.id;
      final path = item.localPath;
      if (path == null || path.trim().isEmpty) continue;

      final f = File(path);
      if (!await f.exists()) continue;

      final uri = Uri.parse('$baseUrl/attachments/upload');

      final req = http.MultipartRequest('POST', uri);
      req.headers.addAll(_buildAuthHeaders(apiKey));
      req.fields['attachment_id'] = id;
      req.fields['client_id'] = clientId;

      req.files.add(await http.MultipartFile.fromPath('file', path));

      http.StreamedResponse streamed;
      try {
        streamed = await req.send().timeout(timeout);
      } catch (e) {
        // If we can't upload blobs, we still allow the main sync to proceed (metadata-only).
        // Manual retry will happen next sync.
        continue;
      }

      final body = await streamed.stream.bytesToString();
      if (streamed.statusCode == 401) {
        throw SyncException('Unauthorized (wrong API key).', statusCode: 401);
      }
      if (streamed.statusCode < 200 || streamed.statusCode >= 300) {
        // leave pending; retry next time
        continue;
      }

      Map<String, dynamic> data;
      try {
        data = jsonDecode(body) as Map<String, dynamic>;
      } catch (_) {
        continue;
      }

      final remoteKey = (data['remote_key'] ?? '').toString();
      if (remoteKey.isEmpty) continue;

      // Persist remote_key locally so it can be referenced in /sync/jobs metadata.
      await helper.setAttachmentRemoteKey(id, remoteKey);
    }
  }

  @override
  Future<SyncResult> syncNow({required String apiKey}) async {
    // Step 0: upload pending blobs first (best-effort).
    await _uploadPendingAttachments(apiKey: apiKey);

    final storedLastSyncAt = await getLastSyncAt();
    final hasLocalData = await local.hasAnyData();
    final effectiveLastSyncAt = hasLocalData ? storedLastSyncAt : null;

    // 1) Collect local changes (includes attachment metadata + remote_key)
    final changes = await local.collectLocalChanges(lastSyncAt: effectiveLastSyncAt);

    final payload = <String, dynamic>{
      'client_id': clientId,
      if (effectiveLastSyncAt != null)
        'last_sync_at': effectiveLastSyncAt.toUtc().toIso8601String(),
      'changes': changes,
    };

    final uri = Uri.parse('$baseUrl/sync/jobs');

    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      ..._buildAuthHeaders(apiKey),
    };

    http.Response res;
    try {
      res = await _http
          .post(uri, headers: headers, body: jsonEncode(payload))
          .timeout(timeout);
    } catch (e) {
      throw SyncException('Network error: $e');
    }

    if (res.statusCode == 401) {
      throw SyncException('Unauthorized (wrong API key).', statusCode: 401);
    }
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw SyncException(
        'Server error (${res.statusCode}): ${res.body}',
        statusCode: res.statusCode,
      );
    }

    final Map<String, dynamic> data;
    try {
      data = jsonDecode(res.body) as Map<String, dynamic>;
    } catch (e) {
      throw SyncException('Invalid JSON from server: $e');
    }

    final jobId = (data['job_id'] ?? '').toString();
    final serverTimeRaw = (data['server_time'] ?? '').toString();
    final serverTime = DateTime.tryParse(serverTimeRaw)?.toUtc();
    if (serverTime == null) {
      throw SyncException('Server response missing/invalid server_time.');
    }

    final applied = (data['applied'] as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{};
    final appliedIds =
        (data['applied_ids'] as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{};
    final conflicts = (data['conflicts'] as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{};

    final serverChangesDynamic =
        (data['server_changes'] as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{};

    final serverChanges = <String, List<Map<String, dynamic>>>{};
    for (final entry in serverChangesDynamic.entries) {
      final key = entry.key;
      final v = entry.value;
      if (v is List) {
        serverChanges[key] =
            v.whereType<Map>().map((m) => m.cast<String, dynamic>()).toList();
      } else {
        serverChanges[key] = <Map<String, dynamic>>[];
      }
    }

    // 2) Apply server changes locally
    await local.applyServerChanges(serverChanges: serverChanges);

    // 3) Mark applied local items as synced
    await local.markAppliedAsSynced(applied: applied, appliedIds: appliedIds);

    // 4) Update cursor
    await _setLastSyncAt(serverTime);

    await local.purgeCompletedSynced(olderThan: const Duration(days: 0));

    return SyncResult(
      jobId: jobId,
      serverTime: serverTime,
      applied: applied,
      conflicts: conflicts,
      serverChanges: serverChanges,
    );
  }

  // existing syncTechnicians unchanged ...
  @override
  Future<SyncResult> syncTechnicians({required String apiKey}) async {
    final storedLastTechSyncAt = await getLastTechSyncAt();
    final hasTechs = await local.hasAnyTechnicians();
    final effectiveLastTechSyncAt = hasTechs ? storedLastTechSyncAt : null;

    final payload = <String, dynamic>{
      'client_id': clientId,
      if (effectiveLastTechSyncAt != null)
        'last_sync_at': effectiveLastTechSyncAt.toUtc().toIso8601String(),
      'limit': 5000,
    };

    final uri = Uri.parse('$baseUrl/sync/technicians');

    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      ..._buildAuthHeaders(apiKey),
    };

    http.Response res;
    try {
      res = await _http
          .post(uri, headers: headers, body: jsonEncode(payload))
          .timeout(timeout);
    } catch (e) {
      throw SyncException('Network error: $e');
    }

    if (res.statusCode == 401) {
      throw SyncException('Unauthorized (wrong API key).', statusCode: 401);
    }
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw SyncException(
        'Server error (${res.statusCode}): ${res.body}',
        statusCode: res.statusCode,
      );
    }

    final Map<String, dynamic> data;
    try {
      data = jsonDecode(res.body) as Map<String, dynamic>;
    } catch (e) {
      throw SyncException('Invalid JSON from server: $e');
    }

    final serverTimeRaw = (data['server_time'] ?? '').toString();
    final serverTime = DateTime.tryParse(serverTimeRaw)?.toUtc();
    if (serverTime == null) {
      throw SyncException('Server response missing/invalid server_time.');
    }

    final techListDynamic = data['technicians_cache'];
    final techRows = <Map<String, dynamic>>[];

    if (techListDynamic is List) {
      for (final item in techListDynamic) {
        if (item is Map) {
          techRows.add(item.cast<String, dynamic>());
        }
      }
    }

    await local.applyServerChanges(serverChanges: {'technicians_cache': techRows});
    await _setLastTechSyncAt(serverTime);

    return SyncResult(
      jobId: 'technicians_pull',
      serverTime: serverTime,
      applied: const {},
      conflicts: const {},
      serverChanges: {'technicians_cache': techRows},
    );
  }

  @override
  void dispose() {
    _http.close();
  }
}

enum AuthStyle { bearer, xApiKey }
