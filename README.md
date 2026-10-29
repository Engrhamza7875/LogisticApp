# Sabcargo - Premium Logistics & AI Assistant 🚀

Sabcargo is a high-fidelity, professional Flutter application designed for modern logistics management. It combines cutting-edge AI support with a sleek, minimalist UI to provide an elite experience for shipment tracking and freight management.

---

## 🌟 Key Features

### 🤖 AI-Powered Support (Gemini Pro)
Integrated with the **Google Gemini Pro** engine, Sabcargo features a live AI assistant specialized in logistics. It can answer complex questions about shipping rates, prohibited items, tracking details, and international regulations in real-time.

### 📍 Shipment Tracking
A tracking dashboard showing shipment status events and a tracking-ID search. It displays backend status updates; it does not show live GPS vehicle location.

### 📱 Premium Floating Navigation
A unique, centered "Floating Dock" navigation system that separates the app from standard designs, providing a high-end, modern mobile experience.

### 🛡️ Secure PIN Authentication
State-of-the-art security featuring a persistent PIN-based login system. Secure your data with a professional numpad interface integrated with device local storage.

### 🏙️ Interactive Service Explorer
High-resolution, mapped service cards for Air, Sea, Land, and Warehouse logistics. Each service features a dedicated detail sheet with rich informational content.

---

## 🛠️ Technology Stack

- **Framework:** [Flutter](https://flutter.dev/) (2024 Stable)
- **Language:** [Dart](https://dart.dev/)
- **AI Engine:** [Google Generative AI](https://pub.dev/packages/google_generative_ai) (Gemini Pro)
- **Local Persistence:** [Shared Preferences](https://pub.dev/packages/shared_preferences)
- **Backend:** Node.js / Express REST API
- **Database:** MongoDB Atlas (server-side connection only)
- **Animations:** [Animate_do](https://pub.dev/packages/animate_do)
- **UI System:** Custom Vanilla CSS-style Dart Widgets with a focus on Glassmorphism and modern gradients.

---

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (latest stable version)
- A Google Gemini API Key

### Installation
1. Clone the repository.
2. Run `flutter pub get`.
3. Configure `backend/.env` from `backend/.env.example` with your Atlas URI and a strong JWT secret.
4. Run `npm install` and `npm start` from `backend/`.
5. Run the app using `flutter run`.

For existing SQL data, see [DEPLOYMENT_OPTIONS.md](./DEPLOYMENT_OPTIONS.md) for the one-time, non-destructive migration.
The Flutter app uses the backend API URL; never place the MongoDB URI in the app.

---

## 📂 Project Structure

- `lib/core`: Theme definitions, global colors, and design tokens.
- `lib/models`: Data structures for shipments and AI chat messages.
- `lib/screens`: All high-fidelity UI screens and navigation logic.
- `lib/services`: External API handlers (AI, Auth, Shipments).

---

© 2026 Sabcargo Logistics. All rights reserved.
