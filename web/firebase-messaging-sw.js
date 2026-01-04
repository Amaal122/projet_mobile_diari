// Firebase Cloud Messaging Service Worker
importScripts('https://www.gstatic.com/firebasejs/10.7.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.7.0/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: "AIzaSyDxaHMU6qzWDMzh4RJxLpxe66WW-Ih9dXY",
  authDomain: "diari-prototype.firebaseapp.com",
  projectId: "diari-prototype",
  storageBucket: "diari-prototype.firebasestorage.app",
  messagingSenderId: "820634668869",
  appId: "1:820634668869:web:0dcb3d91c3f8f3f3cc4a8d"
});

const messaging = firebase.messaging();

// Handle background messages
messaging.onBackgroundMessage((payload) => {
  console.log('Received background message:', payload);
  const notificationTitle = payload.notification.title;
  const notificationOptions = {
    body: payload.notification.body,
    icon: '/icons/Icon-192.png'
  };
  
  return self.registration.showNotification(notificationTitle, notificationOptions);
});
