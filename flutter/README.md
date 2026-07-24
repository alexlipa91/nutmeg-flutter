# Nutmeg Flutter App

Bump to deploy: 1

## Environment Setup

To run the application locally (Web, Android, or iOS), you must create and configure a `.env.local` file in the `flutter` root directory.

### 1. Create `.env.local`

Create a file named `.env.local` in the `flutter` directory with the following variables:

```env
GOOGLE_API_KEY=your_firebase_google_api_key
FIREBASE_VAPID_KEY=your_firebase_vapid_key
```

### 2. Finding the API Key

You can find the **Firebase / Google API Key** in one of the following locations:

- **Firebase Console (Recommended)**:
  1. Open the [Firebase Console](https://console.firebase.google.com/).
  2. Select the **nutmeg-9099c** project.
  3. Go to **Project Settings** (gear icon ⚙️) > **General**.
  4. Scroll down to **Your apps**, select the Web App (`1:956073807168:web:e8f41b530ab699a8a6fea5`), and copy the **API Key** (starts with `AIzaSy...`).

- **Google Cloud Console**:
  1. Go to [Google Cloud Credentials](https://console.cloud.google.com/apis/credentials?project=nutmeg-9099c).
  2. Locate the Web/Browser API key under **API Keys**.

- **Existing Project Config Files**:
  - Android API Key: `AIzaSyAjyxMFOrglJXpK6QlzJR_Mh8hNH3NcGS0` (located in `android/app/google-services.json`)
  - iOS API Key: `AIzaSyBPrmFO6jmlPHnbuHryxUkFWVP0SUYMspc` (located in `ios/Runner/GoogleService-Info.plist`)

---

## Running the App

- **Web**:
  ```bash
  ./scripts/run_web.sh
  ```

- **Android**:
  ```bash
  ./scripts/run_android.sh
  ```

- **iOS**:
  ```bash
  ./scripts/run_ios.sh
  ```