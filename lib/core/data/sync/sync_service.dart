import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:maintenance_system/core/data/sync/local_sync_adapter.dart';
import 'package:maintenance_system/models/sync_models.dart';

class SyncService {
  SyncService({
    required this.baseUrl,
    required this.clientId,
    required this.local,
    http.Client? httpClient,
    this.timeout = const Duration(seconds: 20),
    this.authStyle = AuthStyle.bearer,
  }) : _http = httpClient ?? http.Client();

  final String baseUrl;   // e.g. http://10.0.2.2:5000
  final String clientId;  // device id or generated UUID stored on device
  final LocalSyncAdapter local;
  final http.Client _http;
  final Duration timeout;
  final AuthStyle authStyle;

  static const _prefsKeyLastSyncAt = 'sync_last_sync_at';

  Future<DateTime?> getLastSyncAt() async {
    final prefs = await SharedPreferences.getInstance();
    final s = prefs.getString(_prefsKeyLastSyncAt);
    if (s == null || s.isEmpty) return null;
    return DateTime.tryParse(s);
    // Stored as ISO-8601 string.
  }

  Future<void> _setLastSyncAt(DateTime dt) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKeyLastSyncAt, dt.toUtc().toIso8601String());
  }

  static const _lastTechSyncAtKey = 'last_tech_sync_at';

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

  Future<SyncResult> syncNow({required String apiKey}) async {

    final storedLastSyncAt = await getLastSyncAt();
    final hasLocalData = await local.hasAnyData();

    // If local DB is empty, force an initial sync (ignore storedLastSyncAt)
    final effectiveLastSyncAt = hasLocalData ? storedLastSyncAt : null;

    // 1) Collect local changes
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
      // offline, DNS, timeout, etc.
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
      (data['applied_ids'] as Map?)?.cast<String, dynamic>()
      ?? <String, dynamic>{};
    final conflicts = (data['conflicts'] as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{};

    final serverChangesDynamic =
        (data['server_changes'] as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{};

    // server_changes is expected to be: { tableName: [ {...}, ... ] }
    final serverChanges = <String, List<Map<String, dynamic>>>{};
    for (final entry in serverChangesDynamic.entries) {
      final key = entry.key;
      final v = entry.value;
      if (v is List) {
        serverChanges[key] = v
            .whereType<Map>()
            .map((m) => m.cast<String, dynamic>())
            .toList();
      } else {
        serverChanges[key] = <Map<String, dynamic>>[];
      }
    }

    // 2) Apply server changes locally (upsert)
    await local.applyServerChanges(serverChanges: serverChanges);

    // 3) Mark applied local items as synced
    await local.markAppliedAsSynced(
      applied: applied,
      appliedIds: appliedIds,
      );


    // 4) Update last_sync_at (use server time as authoritative)
    await _setLastSyncAt(serverTime);

    await local.purgeCompletedSynced(
      olderThan: const Duration(days: 0),
    );

    return SyncResult(
      jobId: jobId,
      serverTime: serverTime,
      applied: applied,
      conflicts: conflicts,
      serverChanges: serverChanges,
    );
  }

  Future<SyncResult> syncTechnicians({required String apiKey}) async {
  // Cursor (server authoritative time from last pull)
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

  // Expect: { "technicians_cache": [ {...}, ... ] }
  final techListDynamic = data['technicians_cache'];
  final techRows = <Map<String, dynamic>>[];

  if (techListDynamic is List) {
    for (final item in techListDynamic) {
      if (item is Map) {
        techRows.add(item.cast<String, dynamic>());
      }
    }
  }

  // Reuse existing local apply path by shaping it like server_changes
  final serverChanges = <String, List<Map<String, dynamic>>>{
    'technicians_cache': techRows,
  };

  // Apply to local DB (upsert)
  await local.applyServerChanges(serverChanges: {
    'technicians_cache' : techRows
  });

  // Update cursor using authoritative server time
  await _setLastTechSyncAt(serverTime);

  // Return a SyncResult for consistency (even though only techs were synced)
  return SyncResult(
    jobId: 'technicians_pull',
    serverTime: serverTime,
    applied: const {},     // not provided by this endpoint
    conflicts: const {},   // not provided by this endpoint
    serverChanges: serverChanges,
  );
}


  void dispose() {
    _http.close();
  }
}

enum AuthStyle { bearer, xApiKey }

