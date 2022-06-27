importScripts("https://www.gstatic.com/firebasejs/7.15.5/firebase-app.js");
importScripts("https://www.gstatic.com/firebasejs/7.15.5/firebase-messaging.js");

//Using singleton breaks instantiating messaging()
// App firebase = FirebaseWeb.instance.app;

firebase.initializeApp({
    apiKey: "AIzaSyDlU4z5DbXqoafB-T-t2mJ8rGv3Y4rAcWY",
    authDomain: "nutmeg-9099c.firebaseapp.com",
    databaseURL: "https://nutmeg-9099c-default-rtdb.europe-west1.firebasedatabase.app",
    projectId: "nutmeg-9099c",
    storageBucket: "nutmeg-9099c.appspot.com",
    messagingSenderId: "956073807168",
    appId: "1:956073807168:web:e8f41b530ab699a8a6fea5",
    measurementId: "G-2EQWC6Y0S6"
});

const messaging = firebase.messaging();
messaging.setBackgroundMessageHandler(function (payload) {
    const promiseChain = clients
        .matchAll({
            type: "window",
            includeUncontrolled: true
        })
        .then(windowClients => {
            for (let i = 0; i < windowClients.length; i++) {
                const windowClient = windowClients[i];
                windowClient.postMessage(payload);
            }
        })
        .then(() => {
            return registration.showNotification("New Message");
        });
    return promiseChain;
});
self.addEventListener('notificationclick', function (event) {
    console.log('notification received: ', event)
});