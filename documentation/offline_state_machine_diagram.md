```mermaid
stateDiagram-v2
  [*] --> Ready

  %% ---------- Offline edit ----------
  Ready --> Editing : create or edit item
  Editing --> SavedLocally : save locally
  SavedLocally --> Clean : no pending changes
  SavedLocally --> Dirty : local changes exist

  %% ---------- Queueing ----------
  Dirty --> Queued : add to sync queue

  %% ---------- Connectivity ----------
  Queued --> WaitingForNetwork : offline
  WaitingForNetwork --> Queued : network available

  %% ---------- Sync lifecycle ----------
  Queued --> Syncing : sync triggered
  Syncing --> SyncSuccess : changes accepted
  SyncSuccess --> Clean : local state updated

  Syncing --> SyncFailure : temporary error
  SyncFailure --> RetryPending : retry later
  RetryPending --> Syncing : retry

  %% ---------- Conflict ----------
  Syncing --> Conflict : remote and local differ
  Conflict --> Resolve : manual or automatic resolution
  Resolve --> Queued : resolved change queued
  Resolve --> Clean : local change discarded

  %% ---------- Secure offline storage (conceptual) ----------
  Ready --> SecureStorage : store data offline
  SecureStorage --> Protected : data protected
  SecureStorage --> AtRisk : insufficient protection
  Protected --> Ready
  AtRisk --> Ready

  %% ---------- Terminator ----------
  Clean --> [*] : app closed / session ends
  ```