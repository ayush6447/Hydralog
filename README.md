# Hydralog 💧

**A sleek, Apple-inspired Flutter application to track your daily hydration, sync your health metrics, and build better habits.**

---

## 📱 Overview

Hydralog is a premium, beautifully designed health and hydration tracker. Built with a stunning dark-mode interface and fluid micro-animations, it not only helps you log your water intake effortlessly but also acts as a centralized dashboard for your daily wellness metrics. 

By integrating with **Android Health Connect** and **Firebase**, Hydralog securely syncs your steps, calories, sleep, and water intake across your devices in real-time.

---

## ✨ Features

- **Intuitive Water Tracking:** Quickly log 250ml, 500ml, 750ml, 1L, or custom amounts. Easily remove accidental entries with a single tap.
- **Health Connect Integration:** Automatically pulls your daily Steps, Active Calories, and Sleep data directly from Android Health Connect (syncs with Samsung Health/Google Fit).
- **Screen Time Tracking:** Monitors your daily digital wellbeing by displaying today's screen time usage.
- **Smart Notifications:** Delivers 12 intelligent, randomized motivational hydration reminders throughout your waking hours. Reminders automatically mute the moment you hit your daily water goal.
- **Cloud Sync:** Uses Google Sign-In and Firebase Firestore to securely back up your hydration history, streaks, and profile data to the cloud.
- **Premium Aesthetics:** Features a modern, glassmorphic UI with vibrant rings, interactive charts, and slick navigation reminiscent of high-end fitness apps.
- **Comprehensive History:** View your past hydration trends and consistency streaks through an interactive bar chart interface.

---

## 🚀 Getting Started

### Prerequisites

- [Flutter SDK](https://flutter.dev/docs/get-started/install) installed (version 3.19+)
- A Firebase project configured for Android (requires `google-services.json` in `android/app/`)
- Android device or emulator running API 26+ (Health Connect requires API 28+)

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/ayush6447/Hydralog.git
   cd Hydralog
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Run the app**
   ```bash
   flutter run
   ```

---

## 🔒 Permissions Used
- **Health Connect (`READ_STEPS`, `READ_ACTIVE_ENERGY_BURNED`, `READ_SLEEP_ASLEEP`)**: Used exclusively to display your daily wellness summary.
- **Usage Stats (Screen Time)**: Used to display your daily screen time on the dashboard.
- **Notifications**: Used to send motivational hydration reminders.

---

*Stay hydrated, stay healthy!*