stateDiagram-v2

  [*] --> AppStarting
  AppStarting --> TechCacheReady : refreshTechnicians()\n(upsert technicians_cache)

  TechCacheReady --> LoggedOut
  LoggedOut --> LoggedIn : technicianId exists\nin technicians_cache

  LoggedIn --> Idle : session active

  Idle --> Inspection : select inspection
  Inspection --> Idle : back to list

  %% Logout
  Idle --> LoggedOut : logout()\n(clear current technician)

  state Inspection {
    direction LR

    %% Explicit entry points
    [*] --> PROG
    [*] --> SYNC
    [*] --> FILES

    %% -----------------------------------------------------------------
    %% 1) Item creation/editing offline (tasks, inspections, attachments)
    %% -----------------------------------------------------------------
    state "Offline create/edit (local persistence)" as OFFLINE {
      direction LR

      LocalDraft --> LocalPending : create/edit item offline\n(set updated_at = now,\n sync_status = \"pending\")
      LocalPending --> LocalPending : further edits offline\n(bump updated_at)
    }

    %% -----------------------------------------------------------------
    %% Progress (derived)
    %% -----------------------------------------------------------------
    state "Progress (derived)" as PROG {
      direction LR

      Outstanding --> InProgress : opened_at = now\ntechnician_id = currentTech\nupdated_at = now

      InProgress --> Completed : completed_at = now\nupdated_at = now
    }

    %% -----------------------------------------------------------------
    %% 2) Queuing + conflict states + 3) Sync success/failure transitions
    %% -----------------------------------------------------------------
    state "Sync status (stored)" as SYNC {
      direction LR

      Synced --> Pending : local row changed\nsync_status = \"pending\"

      %% Queue concept: pending items accumulate until user syncs
      Pending --> Queued : offline or user defers sync\n(item queued locally)

      Queued --> SyncAttempt : syncNow(apiKey)\nPOST /sync/jobs\n(include changed rows + attachment metadata)

      %% Secure sync gate: must be online + valid API key
      SyncAttempt --> AuthFailed : missing/invalid apiKey\nreject request
      AuthFailed --> Queued : keep queued\n(prompt for apiKey)

      %% Failure paths
      SyncAttempt --> Failed : timeout/500/network error\nkeep queued
      Failed --> Queued : retry later\n(optional backoff)

      %% Conflict path
      SyncAttempt --> Conflict : server detects conflict\n(sync_status = \"conflict\")\n(return server copy / conflict info)

      Conflict --> Queued : user resolves conflict\n(choose local/server/merge)\nset sync_status=\"pending\"

      %% Success
      SyncAttempt --> Synced : server accepts\nsync_status = \"synced\"\n(update local from server)
    }

    %% -----------------------------------------------------------------
    %% 4) Secure file handling when offline
    %% -----------------------------------------------------------------
    state "Attachment handling (offline-secure)" as FILES {
      direction LR

      NoAttachment --> StagedLocal : attachFile()\nstore to app sandbox\nlocal_path set\nremote_key null\nsync_status=\"pending\"

      StagedLocal --> StagedLocal : replace/remove file\nupdate metadata + updated_at

      %% Upload only during sync (never background)
      StagedLocal --> UploadAttempt : during SyncAttempt\nupload blob then metadata

      UploadAttempt --> Uploaded : upload ok\nremote_key set\nsync_status=\"synced\"

      UploadAttempt --> UploadFailed : upload fails\nkeep local_path\nsync_status=\"pending\"

      UploadFailed --> StagedLocal : retry later\n(no data loss)

      %% Optional: if you ever allow delete
      Uploaded --> NoAttachment : deleteAttachment()\nremove local file\nremote_key retained or cleared\n(sync_status pending if propagated)
    }

    %% ---------------------------------------------------------------
    %% Cross-links between edit flow and sync/file flows
    %% ---------------------------------------------------------------

    %% Any offline edits push rows into Pending/Queued
    PROG --> OFFLINE : edit inspection/task
    OFFLINE --> SYNC : mark pending/queued

    %% Attachment creation affects sync queue too
    FILES --> SYNC : attachment metadata changed\nqueue for sync

  }

  Idle --> [*] : app closed

