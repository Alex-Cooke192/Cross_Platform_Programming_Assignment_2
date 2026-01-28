```mermaid
sequenceDiagram
  autonumber

  actor Tech as Technician
  participant UI as Flutter UI
  participant Repos as Repositories
  participant DAOs as DAOs
  participant LDB as Local DB (Drift / SQLite)

  %% App startup: uses local technicians_cache (no remote sync here)
  UI->>Repos: initApp()
  Repos->>DAOs: loadTechniciansCache()
  DAOs->>LDB: SELECT * FROM technicians_cache
  LDB-->>DAOs: technicians_cache rows
  DAOs-->>Repos: Technician models
  Repos-->>UI: Startup complete (local)

  %% Login (uses local technicians_cache)
  Tech->>UI: Enter technician ID
  UI->>Repos: login(technicianId)
  Repos->>DAOs: getTechnician(technicianId)
  DAOs->>LDB: SELECT * FROM technicians_cache WHERE id = ?
  alt Technician found
    LDB-->>DAOs: technician row
    DAOs-->>Repos: Technician model
    Repos-->>UI: Login successful
  else Not found
    LDB-->>DAOs: 0 rows
    DAOs-->>Repos: null
    Repos-->>UI: Login failed (unknown technician)
  end

  %% Start inspection
  Tech->>UI: Tap Start inspection (inspectionId)
  UI->>Repos: startInspection(inspectionId, technicianId)
  Repos->>DAOs: markInspectionOpened(inspectionId, technicianId)
  DAOs->>LDB: UPDATE inspections SET opened_at=now, technician_id=?, updated_at=now, sync_status="pending" WHERE id=?
  LDB-->>DAOs: OK
  DAOs-->>Repos: OK
  Repos-->>UI: Inspection started

  %% Complete tasks
  loop For each task
    %% Add task result
    Tech->>UI: Enter task result
    UI->>Repos: addTaskResult(taskId, result)
    Repos->>DAOs: updateTaskResult(taskId, result)
    DAOs->>LDB: UPDATE tasks SET result=?, updated_at=now, sync_status="pending" WHERE id=?
    LDB-->>DAOs: OK
    DAOs-->>Repos: OK
    Repos-->>UI: Result saved

    %% Add task notes
    Tech->>UI: Add notes
    UI->>Repos: addTaskNotes(taskId, notes)
    Repos->>DAOs: updateTaskNotes(taskId, notes)
    DAOs->>LDB: UPDATE tasks SET notes=?, updated_at=now, sync_status="pending" WHERE id=?
    LDB-->>DAOs: OK
    DAOs-->>Repos: OK
    Repos-->>UI: Notes saved

    %% Attach file (local only; max 1 per task)
    opt Technician attaches a file
      Tech->>UI: Attach file to task
      UI->>Repos: attachFile(taskId, file)
      Repos->>Repos: validateFile(file)
      Repos->>Repos: copyToAppSandbox(file)
      Repos->>DAOs: upsertAttachment(taskId, metadata, localPath)

      DAOs->>LDB: INSERT INTO attachments(id, task_id, file_name, mime_type, size_bytes, sha256, local_path, remote_key, sync_status, created_at, updated_at)
      note right of LDB
        remote_key stays NULL (local-only)
        task_id is UNIQUE (max 1 attachment per task)
      end note

      DAOs->>LDB: ON CONFLICT(task_id) DO UPDATE SET file_name=?, mime_type=?, size_bytes=?, sha256=?, local_path=?, remote_key=NULL, updated_at=now, sync_status="pending"
      LDB-->>DAOs: OK
      DAOs-->>Repos: OK
      Repos-->>UI: Attachment saved locally
    end

    %% Mark task complete
    Tech->>UI: Mark task complete
    UI->>Repos: completeTask(taskId)
    Repos->>DAOs: markTaskCompleted(taskId)
    DAOs->>LDB: UPDATE tasks SET is_completed=true, completed_at=now, updated_at=now, sync_status="pending" WHERE id=?
    LDB-->>DAOs: OK
    DAOs-->>Repos: OK
    Repos-->>UI: Task completed
  end

  %% Finish inspection
  Tech->>UI: Tap Mark inspection completed
  UI->>Repos: completeInspection(inspectionId)
  Repos->>DAOs: markInspectionCompleted(inspectionId)
  DAOs->>LDB: UPDATE inspections SET is_completed=true, completed_at=now, updated_at=now, sync_status="pending" WHERE id=?
  LDB-->>DAOs: OK
  DAOs-->>Repos: OK
  Repos-->>UI: Inspection completed

```
