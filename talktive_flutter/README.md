# Talktive Flutter Client

A robust, modern lounge chat application front-end built in Flutter. This is the client application for the Talktive project, connecting to the Serverpod-powered backend.

[![google-play-badge](https://github.com/user-attachments/assets/bb22e307-7b4d-4871-ad1a-57d1d4b3b809)](https://play.google.com/store/apps/details?id=app.talktive)

## Main features

**:detective: Anonymous Personas**

Log in securely using your Google account to keep your access safe, but interact with others using a completely anonymous, customizable persona so that your privacy is protected.

**:cyclone: Random**

You don't know who you're going to meet, and you don't know where they're coming from. All you know is that people here are willing to listen.

**:droplet: Ephemeral**

You can open your heart and share your happiness or sadness. In an hour, everyone goes their separate ways, like strangers you met on a train.

**:lock: Private**

No one but the participants can see your conversations. Expired rooms are not publicly accessible, and all records will eventually be deleted.

## Tech Stack & Architecture

Talktive has evolved. It was originally built completely on Firebase but has been migrated to a more scalable architecture:
- **Flutter Framework** for the frontend client.
- **Firebase Auth (Google Sign-In)** for robust, spam-resistant social logins via `serverpod_auth_firebase_flutter`.
- **Serverpod** as the primary backend handling all logic, databases, web sockets, rate limits, and persistence.

## Local setup

See the `README.md` at the root of the monolithic Talktive project repository for comprehensive installation instructions.

You will need to have Docker running for the database and redis dependencies to be handled locally by Serverpod.

## Running the App

Start the Serverpod backend first from the root project folder:
```sh
cd talktive_server
dart bin/main.dart --apply-migrations
```

In a separate terminal, start the Flutter client:
```sh
cd talktive_flutter
flutter run
```
