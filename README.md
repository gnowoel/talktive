# Talktive

An anonymous group chat app for safely talking to strangers.

**[Click to open the app](https://open.talktive.app/)**

## Features

**:see_no_evil: Anonymous**

There is no login button. You do not need to enter any personal information to participate in a chat. Just open the app and join the room.

**:cyclone: Random**

You don't know who you're going to meet, and you don't know where they're coming from. All you know is that people here are willing to listen.

**:droplet: Ephemeral**

You can open your heart and share your happiness or sadness. In an hour, everyone goes their separate ways, like strangers you met on a train.

**:lock: Private**

No one but the participants can see your conversations. Expired rooms are not publicly accessible, and all records will eventually be deleted.

## Setup

Clone the repo:

```
$ git clone https://github.com/gnowoel/talktive.git
```

Initialize Firebase (Firebase Authentication, Realtime Database and Firebase Emulators Suite):

```
$ firebase init
```

Connect to Firebase with FlutterFire:

```
$ flutterfire configure
```

Start Firebase Emulators Suite:

```
$ firebase emulators:start
```

Watch and compile TypeScript code for Cloud Functions (in the `functions` directory):

```
$ npm run build:watch
```

Optionally start a device simulator or emulator:

```
$ flutter emulators --launch Pixel_3a_API_34_extension_level_7_x86_64
```

Run the tests:

```
$ flutter test
$ flutter test integration_test
```

Start the app:

```
$ flutter run
```
