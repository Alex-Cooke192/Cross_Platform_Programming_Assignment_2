```mermaid
flowchart TD
  A[App Launch] --> B[Login or Select Technician]
  B --> C[View Inspections List]
  C --> D[Select Inspection]
  D --> E[Inspection Overview]

  E --> F[Open Inspection]
  F --> F1[Save locally<br/>opened_at, technician_id,<br/>sync_status pending]

  F --> G[Select Task]
  G --> H[Update Task<br/>result, notes, completion]
  H --> H1[Save locally<br/>updated_at, is_completed,<br/>sync_status pending]

  %% Attachment flow
  H --> T{Attach file}
  T -->|Yes| U[Pick file from device]
  U --> V[Create or update Attachment<br/>task_id unique<br/>local_path, metadata<br/>sync_status pending]
  V --> W[Show attachment state in UI]
  T -->|No| I{More tasks}

  W --> I{More tasks}
  I -->|Yes| G

  I -->|No| J[Complete Inspection]
  J --> J1[Save locally<br/>completed_at, is_completed,<br/>sync_status pending]

  J1 --> L[Show sync state in UI]
  L --> M{Online}
  M -->|Yes| S{User triggers sync}
  S -->|Yes| N[Sync pending changes]
  S -->|No| L
  M -->|No| O[Remain pending]
  O --> L

  %% Attachment upload during sync
  N --> N1{Attachment needs upload}
  N1 -->|Yes| N2[Upload file<br/>set remote_key]
  N1 -->|No| P[Sync complete<br/>sync_status synced]
  N2 --> P

  P --> C

    ```
