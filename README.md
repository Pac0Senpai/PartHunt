# PartHunt

**PartHunt** is a collaborative university project exploring an automotive-parts search application.

> **Portfolio snapshot:** This repository contains an earlier version of the project, based on the files available to me. It is **not** the latest version of the application; subsequent development files are held by a collaborator.

## Technologies represented in this repository

- **Flutter / Dart:** Mobile application interface and screens
- **Python / FastAPI:** Example backend endpoint for vehicle identification number (VIN) decoding
- **Firebase Authentication / Cloud Firestore:** Authentication and cloud data features used by the mobile app
- **NHTSA vPIC API:** Public VIN data lookup

The FastAPI example includes a **mock automotive-parts catalog** for demonstration. It is not a live parts inventory or verified replacement-parts database.

## Features in this snapshot

- Vehicle and garage-related screens
- VIN lookup and vehicle information display
- Manual and OEM search interfaces
- User account and saved-parts screens

Some features may require additional setup, configuration, or services to run.

## My contribution

This was a **team project**. My own work focused on the **Python and SQLite** aspects during university development. The Flutter/Dart application was developed collaboratively, with the mobile-interface work handled by my fellow student.

**Note:** Although SQLite was used during the original project work, the current repository snapshot does **not** include the earlier SQLite implementation or a SQLite database file. The code visible here should not be treated as proof of that portion of the work.

## Running the code

### Python backend

The example backend is in `PartsAppBackend/main.py`. With Python installed, install `fastapi`, `uvicorn`, and `requests`, then start the API from that folder with:

```bash
uvicorn main:app --reload
```

Example route: `GET /api/v1/decode-vin/{vin}`.

### Flutter application

The Flutter project is in `parts_app/`. It requires a compatible Flutter SDK and the appropriate **Firebase project configuration** for Firebase-dependent features. Private configuration and credentials are not included in this repository.

## Scope and attribution

This repository is presented as an **educational/portfolio snapshot** of a shared university project, rather than a complete or production-ready application. Contributions from collaborators should be credited appropriately.
