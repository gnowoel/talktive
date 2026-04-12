importScripts("https://www.gstatic.com/firebasejs/10.7.1/firebase-app-compat.js");
importScripts("https://www.gstatic.com/firebasejs/10.7.1/firebase-messaging-compat.js");

importScripts("firebase-config.js");

try {
  if (typeof firebaseConfig !== 'undefined') {
    firebase.initializeApp(firebaseConfig);
  } else {
    console.error("firebase-config.js did not define firebaseConfig");
  }
  const messaging = firebase.messaging();

  messaging.onBackgroundMessage((payload) => {
    console.log('[firebase-messaging-sw.js] Received background message ', payload);
  });
} catch (e) {
  console.log("Error initializing Firebase messaging SW:", e);
}
