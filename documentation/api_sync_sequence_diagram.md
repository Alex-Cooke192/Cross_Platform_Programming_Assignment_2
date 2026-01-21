```mermaid
sequenceDiagram
  autonumber

  actor Tech as Technician
  participant UI as Flutter UI
  participant Repos as Repositories
  participant DAOs as DAOs
  participant LDB as Local DB (Drift / SQLite)
  participant Sync as Sync Engine
  participant API as Remote Sync API
  participant RDB as Remote DB

  %% User initiates sync
  Tech->>UI: Tap "Sync" logo
  UI-->>Tech: Prompt for API Key
  Tech->>UI: Enter API Key + Tap "Confirm Sync"

  %% UI validates presence of key 
  alt API Key missing
    UI-->>Tech: Error: API Key required
  else API Key provided
    UI->>Sync: syncNow(apiKey)

    %% Gather local pending changes 
    Sync->>DAOs: fetchPendingChanges()
    DAOs->>LDB: SELECT * FROM tables\nWHERE sync_status="pending"
    LDB-->>DAOs: pending rows
    DAOs-->>Sync: changeSet

    %% Short-circuit if nothing to sync 
    alt changeSet is empty
      Sync-->>UI: Nothing to sync
      UI-->>Tech: Up to date
    else changeSet has changes
      %% Push to central API with auth
      Sync->>API: POST /sync (changeSet)\nHeaders: X-API-Key / Bearer apiKey

      %% API authorization
      API->>API: Validate API Key
      alt API Key invalid
        API-->>Sync: 401 Unauthorized
        Sync-->>UI: Sync failed (Unauthorized)
        UI-->>Tech: Invalid API Key
      else API Key valid
        %% Central authoritative write 
        API->>RDB: BEGIN TRANSACTION

        %% Validation & conflict checks
        API->>RDB: Validate changeSet\n(ids, FKs, timestamps)
        alt changeSet validation fails
          API->>RDB: ROLLBACK
          API-->>Sync: 409 Conflict / 400 Error
          Sync-->>UI: Sync failed (conflict)
          UI-->>Tech: Conflict message
        else changeSet validation ok
          %% Apply changes
          API->>RDB: UPSERT inspections
          API->>RDB: UPSERT tasks
          API->>RDB: Write sync metadata (serverTime)
          API->>RDB: COMMIT
          RDB-->>API: OK

          %% Respond with authoritative result
          API-->>Sync: 200 OK (appliedIds, serverTime)

          %% Mark local rows as synced
          Sync->>DAOs: markSynced(appliedIds, serverTime)
          DAOs->>LDB: UPDATE rows\nSET sync_status="synced", synced_at=serverTime
          LDB-->>DAOs: OK
          DAOs-->>Sync: OK

          %% Pull phase
          opt Remote stuff (pull)
            Sync->>API: GET /changes?since=lastServerTime
            API->>RDB: SELECT updated rows
            RDB-->>API: deltaSet
            API-->>Sync: deltaSet
            Sync->>DAOs: applyRemoteDelta(deltaSet)
            DAOs->>LDB: UPSERT delta rows
            LDB-->>DAOs: OK
          end

          Sync-->>UI: Sync successful
          UI-->>Tech: Confirmation message
        end
      end
    end
  end
  ```