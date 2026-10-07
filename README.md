# SkinCore 🩺✨

**AI-Powered Dermatological Diagnostic & Personalized Skincare Management Platform**

SkinCore is a state-of-the-art mobile and web application designed to empower users with instant AI-driven skin diagnostics, structured medical reports, personalized skincare routine management, and intelligent routine notifications.

---

## 🚀 Key Features & Capabilities

### 🔬 1. Hybrid AI Skin Scan & Diagnostics
- **Primary Neural Classifier**: MobileNetV2 deep learning model classifying skin conditions into 4 primary diagnostic categories:
  - `Acne Vulgaris`
  - `Eczema / Rash`
  - `Pigmentation`
  - `Serious Condition Alert`
- **SkinCore AI Visual Observation**: Ephemeral vision analysis powered by Groq Vision (`qwen-2.5-vl-72b-instruct`) providing clinical visual observations, structural characteristics, and confidence assessments.
- **Safety Handling & Normal-Skin Detection**: Graceful handling of normal-appearing skin, uncertain presentations, and serious condition alerts with dermatological safety warnings.
- **Grad-CAM Visualization**: Heatmap overlays highlighting regions of visual focus during classification.

---

### 📋 2. Medical History & Tabular Reports
- **Tabular Report Logging**: Automatically logs all skin scan results into structured, downloadable tabular medical reports.
- **PDF Export & Printing**: One-click generation and downloading of official PDF medical reports.

---

### 🔐 3. Authentication & Account Management
- **Email & Password Authentication**:
  - Secure member registration and login.
  - Interactive **Password Visibility Toggles (`👁`)** for Password and Confirm Password fields.
  - **Sign-Up Success Card**: Clear feedback modal upon successful account creation ("*Account created successfully! You can now log into your account.*").
  - Persistent user session management without reliance on dev/test credentials.
- **Google OAuth Sign-In**: Integrated Google Sign-In via Firebase Auth.

---

### 🌿 4. User-Configurable Skincare Routine
- **User-Specific Isolation**: Skincare routines are saved strictly per authenticated user account (`User A` never sees `User B`'s routine).
- **Flexible Routine Scheduling**:
  - **Morning Routine** (e.g. 08:00 AM)
  - **Evening Routine** (e.g. 09:00 PM)
  - **Custom Specific Time Routine**
- **Routine Management**:
  - Add multiple products/activities with quick suggestion chips (`Face Wash`, `Vitamin C Serum`, `Moisturizer`, `Sunscreen`, `Retinol`, `Acne Treatment`, `Gentle Cleanser`, `Toner`).
  - Edit times, routine categories, and product names.
  - Delete routine items with confirmation dialogs.
  - Interactive daily checklist on the **Home Page** with progress tracking.
  - Clean empty-state guidance for new users ("*No skincare routine added yet.*").

---

### 🔔 5. Smart Notifications
- Integrated under **Settings & Profile** (`Profile → Smart Notifications`).
- Automatically schedules routine reminders based on the user's saved skincare products and selected times.
- Persists notification preferences per user across app restarts and logins.

---

### 💬 6. AI Skin Consultant Chatbot
- Interactive conversational AI assistant for skincare guidance powered by Groq (`llama-3.3-70b-versatile`).

---

### 🛡️ 7. Privacy & Data Controls
- Local storage encryption option for scan history and medical logs.
- Anonymous diagnostic telemetry controls.
- Cache clearing and full data export capabilities.

---

## 🛠️ Technology Stack

| Layer | Technologies Used |
|---|---|
| **Frontend App** | Flutter (Dart), Flutter Riverpod (State Management), GoRouter, SharedPreferences, Printing / PDF |
| **AI & Backend API** | FastAPI (Python), PyTorch, MobileNetV2, Groq Vision API (`qwen-2.5-vl-72b-instruct`), OpenCV, NumPy |
| **Authentication** | Firebase Auth & Local Encrypted Credential Store |

---

## 📦 Project Structure

```
skincore_project/
├── backend/
│   ├── main.py                     # FastAPI core endpoints (/predict/hybrid, /health)
│   ├── model/                      # PyTorch MobileNetV2 classifier & weights
│   ├── services/
│   │   ├── groq_vision_service.py  # Groq Vision AI integration
│   │   └── chatbot_service.py      # Groq AI consultation chatbot
│   └── utils/                      # Image preprocessing & Grad-CAM utils
└── frontend/flutter_app/
    ├── lib/
    │   ├── core/                   # Router, Theme, DI Providers, Storage Services
    │   ├── models/                 # MedicalReport, SkincareRoutineItem
    │   ├── providers/              # Riverpod Notifiers (Auth, Routine, Notifications, Reports)
    │   ├── features/
    │   │   ├── authentication/     # Login & Sign Up Screen with eye toggles
    │   │   ├── dashboard/          # Home Screen with dynamic routine checklist
    │   │   ├── recommendations/    # Skincare Routine Management UI
    │   │   ├── skin_scan/          # AI Skin Scan & Camera interface
    │   │   ├── progress_tracker/   # Tabular Medical Reports & PDF download
    │   │   ├── chatbot/            # AI Chat Consultation
    │   │   └── settings/           # Profile & Smart Notifications toggle
    │   └── widgets/                # Reusable UI cards, drawers, & gradient buttons
    └── pubspec.yaml
```

---

## 🚦 Getting Started

### 1. Prerequisites
- Python 3.10+
- Flutter SDK (3.x)
- Groq API Key set in environment: `GROQ_API_KEY`

### 2. Running the Backend
```bash
# From project root directory
python -m uvicorn backend.main:app --reload
```
Backend API will be running at `http://127.0.0.1:8000`.

### 3. Running the Flutter App
```bash
# Navigate to flutter_app directory
cd frontend/flutter_app

# Run Flutter Web / Chrome
flutter run -d chrome
```

---

## 📄 License

Developed for **SkinCore** — All Rights Reserved.