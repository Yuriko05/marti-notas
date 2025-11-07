const {initializeApp} = require("firebase-admin/app");
const {getFirestore, FieldValue} = require("firebase-admin/firestore");
const {getMessaging} = require("firebase-admin/messaging");
const {getAuth} = require("firebase-admin/auth");

// Ensure Firebase Admin is initialised once for all functions
initializeApp();

module.exports = {
  getFirestore,
  FieldValue,
  getMessaging,
  getAuth,
};
