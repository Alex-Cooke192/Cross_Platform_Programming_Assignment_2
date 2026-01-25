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
  H --> I{More Tasks?}
  I -->|Yes| G

  I -->|No| J[Complete Inspection]
  J --> J1[Save locally<br/>completed_at, is_completed,<br/>sync_status pending]

  J1 --> L[Show sync state in UI]
  L --> M{Online?}
  M -->|Yes| S{User triggers sync?}
  S -->|Yes| N[Sync pending changes]
  S -->|No| L
  M -->|No| O[Remain pending]
  O --> L

  N --> P[Sync successful<br/>sync_status set to synced]
  P --> C


    ```
