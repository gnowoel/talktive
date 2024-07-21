# Talktive

An anonymous group chat app for safely talking to strangers.

**[Click to open the app](https://open.talktive.app/)**

## Main features

**:see_no_evil: Anonymous**

There is no login button. You do not need to enter any personal information to participate in a chat. Just open the app and join the room.

**:cyclone: Random**

You don't know who you're going to meet, and you don't know where they're coming from. All you know is that people here are willing to listen.

**:droplet: Ephemeral**

You can open your heart and share your happiness or sadness. In an hour, everyone goes their separate ways, like strangers you met on a train.

**:lock: Private**

No one but the participants can see your conversations. Expired rooms are not publicly accessible, and all records will eventually be deleted.

## Local setup

Clone the repo:

```
$ git clone https://github.com/gnowoel/talktive.git
$ cd talktive
```

Configure Firebase for Authentication, Realtime Database and Emulators Suite:

```
$ firebase init
$ flutterfire configure
```

Start Emulators Suite:

```
$ firebase emulators:start
```

Watch and compile Cloud Functions code:

```
$ npm run build:watch # Run it in the `functions` directory
```

Optionally start a device simulator or emulator:

```
$ flutter emulators --launch Pixel_3a_API_34_extension_level_7_x86_64
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
