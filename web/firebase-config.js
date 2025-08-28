// TODO: Replace with your actual Firebase config from Firebase Console
// Go to: https://console.firebase.google.com/
// 1. Create new project "PianoQuest"
// 2. Add Web app
// 3. Copy config object below

import { initializeApp } from 'firebase/app';

const firebaseConfig = {
  // Replace these with your actual Firebase config values
  apiKey: "your-api-key-here",
  authDomain: "your-project-id.firebaseapp.com",
  projectId: "your-project-id",
  storageBucket: "your-project-id.appspot.com",
  messagingSenderId: "your-sender-id",
  appId: "your-app-id"
};

// Initialize Firebase
const app = initializeApp(firebaseConfig);
export default app; 