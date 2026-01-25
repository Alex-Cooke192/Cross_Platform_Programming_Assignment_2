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

  Tech->>UI: Tap "Sync" logo
  UI-->>Tech: Prompt for API Key
  Tech->>UI: Enter API Key + Tap "Confirm Sync"

  alt API Key missing
    UI-->>Tech: Error: API Key required
  else API Key provided
    UI->>Sync: syncNow(apiKey)

    Sync->>DAOs: getLastSyncAt()
    DAOs->>LDB: SELECT last_sync_at FROM sync_state LIMIT 1
    LDB-->>DAOs: lastSyncAt (nullable)
    DAOs-->>Sync: lastSyncAt

    alt lastSyncAt is null (first sync / force bootstrap)
      Sync->>API: GET /bootstrap\nHeaders: X-API-Key / Bearer apiKey
      API->>API: Validate API Key

      alt API Key invalid
        API-->>Sync: 401 Unauthorized
        Sync-->>UI: Sync failed (Unauthorized)
        UI-->>Tech: Invalid API Key
      else API Key valid
        API->>RDB: SELECT technicians (+ optionally inspections metadata)
        RDB-->>API: bootstrapSet
        API-->>Sync: 200 OK (bootstrapSet, serverTime)

        Sync->>DAOs: applyBootstrap(bootstrapSet, serverTime)
        DAOs->>LDB: UPSERT technicians_cache
        DAOs->>LDB: UPDATE sync_state\nSET last_sync_at=serverTime
        LDB-->>DAOs: OK
        DAOs-->>Sync: OK
      end
    end

    Sync->>DAOs: fetchPendingChanges(lastSyncAt)
    DAOs->>LDB: SELECT * FROM tables\nWHERE sync_status="pending"
    LDB-->>DAOs: pending rows
    DAOs-->>Sync: changeSet

    alt changeSet is empty
      Sync-->>UI: Nothing to sync
      UI-->>Tech: Up to date
    else changeSet has changes
      Sync->>API: POST /sync (changeSet)\nHeaders: X-API-Key / Bearer apiKey

      API->>API: Validate API Key
      alt API Key invalid
        API-->>Sync: 401 Unauthorized
        Sync-->>UI: Sync failed (Unauthorized)
        UI-->>Tech: Invalid API Key
      else API Key valid
        API->>RDB: BEGIN TRANSACTION
        API->>RDB: Validate changeSet\n(ids, FKs, timestamps)

        alt changeSet validation fails
          API->>RDB: ROLLBACK
          API-->>Sync: 409 Conflict / 400 Error
          Sync-->>UI: Sync failed (conflict)
          UI-->>Tech: Conflict message
        else changeSet validation ok
          API->>RDB: UPSERT inspections
          API->>RDB: UPSERT tasks
          API->>RDB: Write sync metadata (serverTime)
          API->>RDB: COMMIT
          RDB-->>API: OK

          API-->>Sync: 200 OK (appliedIds, serverTime)

          Sync->>DAOs: markSynced(appliedIds, serverTime)
          DAOs->>LDB: UPDATE rows\nSET sync_status="synced", synced_at=serverTime
          DAOs->>LDB: UPDATE sync_state\nSET last_sync_at=serverTime
          LDB-->>DAOs: OK
          DAOs-->>Sync: OK

          opt Pull remote delta
            Sync->>API: GET /changes?since=lastSyncAt\nHeaders: X-API-Key / Bearer apiKey
            API->>RDB: SELECT updated rows since lastSyncAt
            RDB-->>API: deltaSet
            API-->>Sync: 200 OK (deltaSet, serverTime)

            Sync->>DAOs: applyRemoteDelta(deltaSet, serverTime)
            DAOs->>LDB: UPSERT delta rows
            DAOs->>LDB: UPDATE sync_state\nSET last_sync_at=serverTime
            LDB-->>DAOs: OK
          end

          Sync-->>UI: Sync successful
          UI-->>Tech: Confirmation message
        end
      end
    end
  end



  ```
