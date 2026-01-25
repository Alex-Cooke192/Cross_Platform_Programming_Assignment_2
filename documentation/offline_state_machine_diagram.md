```mermaid
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

    state "Progress (derived)" as PROG {
      direction LR

      Outstanding --> InProgress : opened_at = now\ntechnician_id = currentTech\nupdated_at = now

      InProgress --> Completed : completed_at = now\nupdated_at = now
    }

    state "Sync status (stored)" as SYNC {
      direction LR

      Synced --> Pending : sync_status = "pending"\n(updated local row)

      Pending --> SyncAttempt : syncNow(apiKey)\ncollect pending rows

      SyncAttempt --> Synced : server accepts\nsync_status = "synced"\nlast_synced_at = now (if tracked)

      SyncAttempt --> Pending : keep sync_status="pending"\n(optionally last_sync_error set)
    }
  }

  Idle --> [*] : app closed
  ```
