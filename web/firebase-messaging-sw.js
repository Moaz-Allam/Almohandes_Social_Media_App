// Background Web Push handler. Loaded automatically by firebase_messaging on
// web. Must live at the web root so the browser registers it.
importScripts(
  'https://www.gstatic.com/firebasejs/10.12.0/firebase-app-compat.js',
);
importScripts(
  'https://www.gstatic.com/firebasejs/10.12.0/firebase-messaging-compat.js',
);

firebase.initializeApp({
  apiKey: 'AIzaSyAoTgRyYLVDV17WCyO_zmhXarm9vNkLvRk',
  appId: '1:851572571996:web:5bdc82f88f0a72a1e90b99',
  messagingSenderId: '851572571996',
  projectId: 'almohandes-engineer-2026',
  authDomain: 'almohandes-engineer-2026.firebaseapp.com',
  storageBucket: 'almohandes-engineer-2026.firebasestorage.app',
});

const messaging = firebase.messaging();

// FCM `notification` payloads are shown by the browser automatically. This
// handles data-only messages so they still surface a notification.
messaging.onBackgroundMessage((payload) => {
  const title = (payload.notification && payload.notification.title) ||
    (payload.data && payload.data.title) || 'إشعار جديد';
  const body = (payload.notification && payload.notification.body) ||
    (payload.data && payload.data.body) || '';
  self.registration.showNotification(title, {
    body,
    icon: '/icons/Icon-192.png',
  });
});
