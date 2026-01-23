# Maintenance System (Flutter)

A **cross-platform, offline-first maintenance inspection system** built with **Flutter**, designed for technicians operating in low- or no-connectivity environments.  
The application supports secure local data persistence, manual synchronisation with a central server, and audit-ready inspection workflows.

---

## Project Overview

This application enables technicians to:

- Authenticate locally using a technician identifier
- Download an initial technician dataset securely
- Open, perform, and complete inspections while offline
- Record task results and notes locally
- Manually synchronise inspection data with a central backend using an API key
- Maintain auditability through timestamps and structured data models

The system is designed with **security, data minimisation, and reliability** in mind, aligning with GDPR-aware principles and offline-first architecture.

---

## Key Features

- **Cross-platform**: Runs on Android (9+) and Windows (10+)
- **Offline-first architecture** using local persistence
- **Secure manual synchronisation** with API key authentication
- **Local SQLite database** implemented via Drift
- **Clear inspection lifecycle** (unopened → in progress → completed)
- **Auditability** via timestamps (opened, updated, completed)
- **Decoupled architecture** using repositories and dependency injection

---

## Architecture Overview

The application follows a layered architecture:

- **UI Layer** – Flutter widgets and screens  
- **Repository Layer** – Abstracts data access logic  
- **Local Persistence Layer** – Drift (SQLite) DAOs  
- **Sync Layer** – Handles secure two-way synchronisation with the backend  
- **Domain Models** – Clean separation between UI, domain, and persistence models  

Dependency injection is used throughout to reduce coupling and improve testability, particularly in the synchronisation and data access layers.

---

## Data Storage & Synchronisation

- Local data is stored securely in a SQLite database using Drift
- Only the **technicians table** is initially synchronised to enable login
- Inspection and task data require **re-authentication via API key** at sync time
- Synchronisation is **manual and explicit**, ensuring user control and security
- Sync logic supports offline changes and basic conflict handling

---

## Security & GDPR Considerations

The system incorporates the following principles:

- **Data minimisation** – Only essential inspection and technician data is stored
- **Secure local storage** – Data persisted locally for offline use
- **Authenticated data access** – API key required for all remote data synchronisation
- **Encrypted transport** – HTTPS used for all network communication
- **Auditability** – Timestamped records provide accountability and traceability

---

## Technologies Used

- **Flutter / Dart**
- **Drift (SQLite)**
- **HTTP REST API**
- **Provider (state management)**
- **Android & Windows targets**

---

## Getting Started

### Prerequisites

- Flutter SDK (latest stable)
- Android Studio or VS Code
- Android emulator or Windows device

### Running the Application

```bash
flutter pub get
flutter run

