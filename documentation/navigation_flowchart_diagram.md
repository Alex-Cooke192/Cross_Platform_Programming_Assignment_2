```mermaid
flowchart TD
    A[App Launch] --> B[Login / Select Technician]

    B --> C[View Inspections List]

    C --> D[Select Inspection]
    D --> E[Inspection Overview]

    E --> F[Open Inspection]

    F --> G[Select Task]
    G --> H[Complete Task]
    H --> I{More Tasks?}

    I -->|Yes| G
    I -->|No| J[Inspection Completed]

    J --> K[Save Inspection Locally]

    K --> L[Inspection Sync Status View]

    L --> M{Online?}
    M -->|Yes| N[Sync Inspection with Server]
    M -->|No| O[Pending Sync]

    N --> P[Sync Successful]
    O --> L

    P --> C
    ```