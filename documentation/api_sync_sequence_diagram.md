```mermaid
sequenceDiagram
  autonumber

  actor Tech as Technician
  participant UI as Flutter UI
  participant Sync as Sync Engine
  participant LDB as Local DB
  participant API as Remote Sync API
  participant RDB as Remote DB
  participant Blob as File Storage

  Tech->>UI: Tap Sync
  UI-->>Tech: Prompt for API key
  Tech->>UI: Enter API key and confirm

  alt Missing API key
    UI-->>Tech: Show error
  else API key provided
    UI->>Sync: syncNow(apiKey)

    %% Determine baseline
    Sync->>LDB: Read last sync marker
    LDB-->>Sync: lastSyncAt or null

    alt First sync required
      Sync->>API: GET bootstrap
      API->>API: Validate API key
      alt Unauthorized
        API-->>Sync: 401
        Sync-->>UI: Sync blocked
        UI-->>Tech: Invalid API key
      else Authorized
        API->>RDB: Read bootstrap set
        RDB-->>API: bootstrap set
        API-->>Sync: bootstrap + serverTime
        Sync->>LDB: Apply bootstrap (upsert)
        Sync->>LDB: Save lastSyncAt
        Sync-->>UI: Bootstrap complete
      end
    end

    %% Collect local work
    Sync->>LDB: Read pending inspections
    Sync->>LDB: Read pending tasks
    Sync->>LDB: Read pending attachment metadata
    LDB-->>Sync: changeSet

    alt No pending changes
      Sync-->>UI: Nothing to sync
      UI-->>Tech: Up to date
    else Pending changes exist
      %% Phase 1: sync metadata (rows only)
      Sync->>API: POST sync jobs (rows + attachment metadata)
      API->>API: Validate API key

      alt Unauthorized
        API-->>Sync: 401
        Sync-->>UI: Sync blocked
        UI-->>Tech: Invalid API key
      else Authorized
        API->>RDB: Validate ids and foreign keys
        alt Conflict or invalid payload
          API-->>Sync: Conflict response
          Sync-->>UI: Sync failed
          UI-->>Tech: Conflict message
        else Accepted
          API->>RDB: Upsert inspections
          API->>RDB: Upsert tasks
          API->>RDB: Upsert attachment metadata
          API->>RDB: Commit and compute serverTime
          RDB-->>API: OK
          API-->>Sync: applied ids + serverTime + uploadRequired list

          Sync->>LDB: Mark synced rows (inspections/tasks)
          Sync->>LDB: Mark synced attachment metadata
          Sync->>LDB: Update lastSyncAt

          %% Phase 2: upload file bytes (only when required)
          loop For each attachment requiring upload
            Sync->>LDB: Read attachment info
            LDB-->>Sync: local file reference + metadata
            Sync->>Blob: Upload file bytes (auth)
            alt Upload success
              Blob-->>Sync: storage key
              Sync->>API: POST attachment confirm (id + storage key)
              API->>RDB: Store storage key for attachment
              RDB-->>API: OK
              API-->>Sync: OK
              Sync->>LDB: Save storage key and mark attachment synced
            else Upload failure
              Blob-->>Sync: Error
              Sync->>LDB: Keep attachment pending for retry
            end
          end

          %% Optional pull of remote delta
          opt Pull remote changes since lastSyncAt
            Sync->>API: GET changes since lastSyncAt
            API->>RDB: Read delta rows
            RDB-->>API: delta set
            API-->>Sync: delta set + serverTime
            Sync->>LDB: Apply delta (upsert)
            Sync->>LDB: Update lastSyncAt
          end

          Sync-->>UI: Sync complete
          UI-->>Tech: Confirmation
        end
      end
    end
  end
  ```
