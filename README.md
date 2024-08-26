# Talktive

A simple anonymous group chat app for comfortably talking to strangers.

<br />

[![button_open-the-app](https://github.com/user-attachments/assets/13c64934-2123-4829-bc8f-6a729b4dfd3d)](https://open.talktive.app/)

## Screenshots

![screenshots](https://github.com/user-attachments/assets/855c3de8-6c62-4d83-bfd9-122a684cd14b)

## Main features

**:see_no_evil: Anonymous**

There is no login button. You do not need to enter any personal information to participate in a chat. Just open the app and join the room.

**:cyclone: Random**

You don't know who you're going to meet, and you don't know where they're coming from. All you know is that people here are willing to listen.

**:droplet: Ephemeral**

You can open your heart and share your happiness or sadness. In an hour, everyone goes their separate ways, like strangers you met on a train.

**:lock: Private**

No one but the participants can see your conversations. Expired rooms are not publicly accessible, and all records will eventually be deleted.

## Implementation

The technical details can be found in the blog post:

* [The Challenges of Building a Simple Chat App with Flutter and Firebase](https://medium.com/@gnowoel/the-challenges-of-building-a-simple-chat-app-with-flutter-and-firebase-b9f0a2f0f889)

## Firebase setup

Create a new Firebase project, and enable the following services:

* Authentication (Anonymous)
* Realtime Database
* Functions

In order to use Cloud Functions, we need to upgrade the project to the Blaze plan (pay-as-you-go).

## Local setup

Clone the repo:

```
$ git clone https://github.com/gnowoel/talktive.git
$ cd talktive
```

Configure Flutterfire:

```
$ firebase login
$ dart pub global activate flutterfire_cli
$ flutterfire configure
```

Configure Firebase:

```
$ firebase init
```

Select the following services:

* Realtime Database
* Functions
* Emulators

For "Functions", select:

* TypeScript

For "Emulators", select:

* Authentication Emulator
* Functions Emulator
* Database Emulator
* Pub/Sub Emulator

## Running

Watch and compile Cloud Functions code (from the `functions` directory):

```
$ npm run build:watch
```

Start Emulators Suite, and take a note of the URL for the HTTP request:

```
$ firebase emulators:start
```

Trigger the scheduler once with an HTTP request, using the URL from the previous step:

```
$ curl http://127.0.0.1:5001/talktive-12345/us-central1/requestedCleanup
```

Optionally start a device simulator or emulator, for example:

```
$ flutter emulators --launch apple_ios_simulator
```

Optionally run the unit and integration tests:

```
$ flutter test
$ flutter test integration_test
```

Start the app:

```
$ flutter run
```

## Deployment

Deploy Realtime Database Securty Rules:

```
$ firebase deploy --only database
```

Deploy Cloud Functions (from the `functions` directory):

```
$ npm run deploy
```

Build the `web` release of the Flutter app:

```
$ flutter build web
```

Upload the `build/web` directory to your hosting service of choice.
