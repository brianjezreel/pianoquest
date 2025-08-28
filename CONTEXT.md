Project Context File

PianoQuest — A Piano Learning App with Polyphonic Pitch Detection Using CQT

1. Introduction & Background

Traditional piano-learning apps often focus on monophonic note detection, which limits real-world practice where both hands are used to play chords, harmonies, and accompaniment. Learners struggle to get meaningful feedback on polyphonic passages, leading to frustration and slower progress.

To address this challenge, PianoQuest is proposed: a gamified piano-learning mobile application powered by polyphonic pitch detection using the Constant-Q Transform (CQT) algorithm. The app is developed using Flutter (for cross-platform mobile development) and Firebase (for real-time database and user management).

2. Problem Context

Current piano apps struggle with chord detection and accurate polyphony recognition.

Beginners often receive vague feedback (e.g., “wrong note”) instead of precise, actionable guidance.

Many apps lack gamification, which is vital for motivation and retention.

Thus, there is a need for a polyphonic, feedback-rich, and engaging learning tool for piano learners.

3. Goals & Objectives
General Goal

To design and implement a mobile piano learning app that provides real-time polyphonic pitch detection and feedback using CQT.

Specific Objectives

Implement CQT-based polyphonic pitch detection for accurate recognition of multiple notes.

Develop a Flutter-based mobile application with lessons, practice sessions, achievements, and user progression.

Use Firestore to store user data, lessons, songs, and progress in real time.

Integrate gamification features (XP, levels, achievements) to sustain motivation.

Evaluate the system’s accuracy, latency, and usability through technical testing and user trials.

4. Scope & Limitations

Scope:

Focuses on beginner to intermediate learners.

Detects piano notes (A0–C8) via microphone input.

Offers guided lessons and free practice.

Provides gamified features (XP, levels, badges).

Limitations:

Requires relatively quiet environments for best results.

Works best with acoustic/digital pianos; less effective with synthesized/low-quality sounds.

Latency target: <120 ms (device-dependent).

5. Technology Stack

Frontend: Flutter (cross-platform mobile).

Backend: Firebase (Authentication, Firestore, Storage, Functions).

Database: Firestore (NoSQL, real-time).

Audio Engine: Native CQT pitch detection via Dart FFI.

Gamification: XP + Levels + Achievements stored in Firestore.

6. Firestore Database Schema

Firestore is a NoSQL cloud database structured as collections (like folders) and documents (like JSON objects).

Proposed Schema:
users/{uid}
  name: string
  email: string
  level: int
  xp: int
  achievements: [ids]
  settings: {sound: true, difficulty: "easy"}

songs/{songId}
  title: string
  composer: string
  difficulty: string
  tempo: int
  targetNotes: [
    {timeStart: float, timeEnd: float, midi: int}
  ]

lessons/{lessonId}
  title: string
  module: string
  order: int
  songRefs: [songId]
  objectives: [string]

sessions/{sessionId}
  uid: string
  songId: string
  startedAt: timestamp
  accuracy: float
  timingScore: float
  extras: int
  misses: int

achievements/{achId}
  name: string
  description: string
  xp: int
  rule: string

7. System Features (Based on Wireframe)

Dashboard → central hub with quick links to Lessons, Practice, Achievements, and User Level.

Lessons → structured modules with guided songs and progression requirements.

Practice → free-play mode with real-time feedback powered by polyphonic detection.

Achievements → badges earned by completing milestones.

User Level → XP-based progression system showing growth over time.

8. Algorithmic Approach
Constant-Q Transform (CQT)

Converts audio into semitone-aligned frequency bins.

Enables accurate detection of multiple notes (multi-F0 estimation).

Uses harmonic summation and temporal smoothing to reduce errors.

Feedback System

Correct: target note played on time.

Missed: target note absent.

Extra: unintended note detected.

Timing: onset early/late compared to target.

9. Development Phases
Phase 1: Setup

Initialize Flutter app & Firebase project.

Configure authentication and Firestore.

Phase 2: UI Wireframe Implementation

Build Dashboard, Lessons, Practice, Achievements, and User Level screens.

Phase 3: Firestore Integration

Implement Firestore schema.

Display lessons and songs dynamically.

Store user progress.

Phase 4: Audio Engine (CQT)

Implement CQT pitch detection natively.

Integrate with Flutter via Dart FFI.

Phase 5: Real-Time Feedback

Compare detected vs. target notes.

Display live feedback (correct, missed, extra, timing).

Phase 6: Gamification

Implement XP, leveling, and achievements.

Sync with Firestore.

Phase 7: Testing & Optimization

Optimize audio latency and detection accuracy.

Secure Firestore rules.

Phase 8: Finalization

Conduct evaluation study (technical & user).

Prepare thesis documentation and app demo.

10. User Flow

The user flow outlines how a learner uses PianoQuest:

1. Onboarding & Authentication

User logs in via Firebase Authentication (Google/email).

Profile created with default XP and level.

2. Dashboard

Central hub showing navigation to Lessons, Practice, Achievements, and User Level.

3. Lessons Flow

User selects a lesson → sees objectives.

Plays guided session with live CQT feedback.

After session, summary report (accuracy %, mistakes, XP earned).

Unlocks next lesson if performance ≥ threshold.

4. Practice Flow

User selects any available song.

Plays freely with real-time feedback.

XP gained based on accuracy.

Sessions stored in Firestore.

5. Achievements Flow

User views badges (unlocked and locked).

Achievements awarded automatically when conditions met.

6. User Level Flow

User checks XP and level progress.

Levels unlock new lessons, songs, and achievements.

Simplified Visual Flow
Login → Dashboard
          ├── Lessons → Guided Play → Feedback → Unlock Next Lesson
          ├── Practice → Free Play → Feedback → XP Gain
          ├── Achievements → View Badges → Motivation
          └── User Level → Track XP → Unlock Content

11. Expected Outcomes

A functioning mobile app capable of polyphonic pitch detection in real time.

A gamified piano learning system that motivates learners.

Evaluation results showing improved accuracy and user engagement compared to traditional learning.