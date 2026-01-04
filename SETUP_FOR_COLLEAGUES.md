# 🔧 Setup Instructions for Team Members & Professor

This guide helps you get the Diari app running on your machine.

## ⚠️ Important Note

Some Firebase configuration files are **not included in the GitHub repository** for security reasons. You'll need to obtain these files separately.

---

## 📋 Required Files (Request from Project Owner)

Contact the project owner to get these files via secure channel (Google Drive, USB, etc.):

### Frontend Files Needed:
1. **`lib/firebase_options.dart`** - Firebase web configuration
2. **`android/app/google-services.json`** - Android Firebase config
3. **`ios/Runner/GoogleService-Info.plist`** - iOS Firebase config (optional if only testing Android)

### Backend Files Needed:
1. **`backend/.env`** - Environment variables configuration
2. **`backend/serviceAccountKey.json`** - Firebase Admin SDK credentials

---

## 🚀 Quick Start (After Getting Config Files)

### Prerequisites Installed?

- **Flutter**: Version 3.9.2+ ([Download](https://docs.flutter.dev/get-started/install))
- **Python**: Version 3.10+ ([Download](https://www.python.org/downloads/))
- **Android Studio** or VS Code with Flutter extension
- **Git**: For cloning repository

---

## Step 1: Clone Repository

```bash
git clone https://github.com/Amaal122/projet_mobile_diari.git
cd projet_mobile_diari
```

---

## Step 2: Setup Frontend (Flutter)

### A. Place Firebase Config Files

Copy the files you received to these locations:

```
projet_mobile_diari/
├── lib/
│   └── firebase_options.dart          ← Place here
├── android/
│   └── app/
│       └── google-services.json       ← Place here
└── ios/
    └── Runner/
        └── GoogleService-Info.plist   ← Place here (iOS only)
```

### B. Install Dependencies

```bash
# In project root directory
flutter pub get
```

### C. Verify Setup

```bash
flutter doctor
# Should show all checks passed (✓)
```

### D. Run the App

```bash
# List available devices
flutter devices

# Run on connected Android device/emulator
flutter run

# OR run on Chrome for testing
flutter run -d chrome --web-port=8082
```

**App should launch successfully!** ✅

---

## Step 3: Setup Backend (Flask)

### A. Navigate to Backend

```bash
cd backend
```

### B. Place Backend Config Files

Copy the files you received:

```
backend/
├── .env                          ← Place here
└── serviceAccountKey.json        ← Place here
```

### C. Create Virtual Environment

**Windows:**
```bash
python -m venv venv
venv\Scripts\activate
```

**macOS/Linux:**
```bash
python3 -m venv venv
source venv/bin/activate
```

### D. Install Dependencies

```bash
pip install -r requirements.txt
```

### E. Run Backend Server

```bash
python run.py
```

**Server should start at:** `http://localhost:5000` ✅

You should see:
```
 * Running on http://127.0.0.1:5000
 * Backend API ready
```

---

## Step 4: Test Everything Works

### Test Backend API

Open browser and visit:
```
http://localhost:5000/api/health
```

Should return:
```json
{
  "status": "healthy",
  "timestamp": "2026-01-04T..."
}
```

### Test Frontend Connection

1. Launch Flutter app (Step 2D)
2. Try to login with test account:
   - **Email:** `testcustomer@diari.test`
   - **Password:** `Customer123!`
3. If login works → Everything connected! ✅

---

## 🧪 Test Accounts

### Customer Account
- Email: `testcustomer@diari.test`
- Password: `Customer123!`

### Chef Account  
- Email: `testchef@diari.test`
- Password: `Chef123!`

---

## 🐛 Troubleshooting

### "Firebase not configured" Error

❌ **Problem:** Missing Firebase config files

✅ **Solution:** Ensure you placed `firebase_options.dart` and `google-services.json` in correct locations (see Step 2A)

### "serviceAccountKey.json not found" Error

❌ **Problem:** Missing backend Firebase credentials

✅ **Solution:** Place `serviceAccountKey.json` in `backend/` directory (see Step 3B)

### "Cannot connect to backend" Error

❌ **Problem:** Backend server not running or wrong URL

✅ **Solution:** 
1. Make sure backend is running: `python run.py`
2. Check `lib/services/api_config.dart` has correct URL:
   ```dart
   static const String baseUrl = 'http://localhost:5000';
   ```

### Port 5000 Already in Use

❌ **Problem:** Another app using port 5000

✅ **Solution:** 
```bash
# Windows: Kill process on port 5000
netstat -ano | findstr :5000
taskkill /PID <PID_NUMBER> /F

# macOS/Linux:
lsof -ti:5000 | xargs kill -9
```

### Flutter App Won't Build

❌ **Problem:** Dependencies or SDK issues

✅ **Solution:**
```bash
flutter clean
flutter pub get
flutter doctor -v  # Check for issues
```

---

## 📱 Alternative: Just Use the APK

**Don't want to setup everything?**

1. Get the pre-built APK from project owner
2. Install on Android device
3. Ask project owner to run backend on their machine
4. Use their IP address for API connection

This is perfect for quick testing/demo!

---

## 🆘 Need Help?

Contact project team members:
- Check project documentation in `README.md`
- Review API documentation in `backend/API_DOCUMENTATION.md`
- Check architecture details in `backend/BACKEND_ARCHITECTURE.md`

---

## ✅ Setup Complete Checklist

- [ ] Cloned repository from GitHub
- [ ] Received all config files from project owner
- [ ] Placed `firebase_options.dart` in `lib/`
- [ ] Placed `google-services.json` in `android/app/`
- [ ] Placed `.env` in `backend/`
- [ ] Placed `serviceAccountKey.json` in `backend/`
- [ ] Ran `flutter pub get`
- [ ] Backend running at `http://localhost:5000`
- [ ] Frontend app launches successfully
- [ ] Can login with test account

**All checked?** You're ready to go! 🎉
