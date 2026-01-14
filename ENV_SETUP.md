# 🔒 Environment Setup Guide

## Quick Start

1. **Copy the example environment file:**
   ```bash
   cp .env.example .env
   ```

2. **Edit `.env` with your actual API keys:**
   ```bash
   # Use your favorite editor
   nano .env
   # or
   code .env
   ```

3. **Run the app with environment variables:**
   ```bash
   # Development
   flutter run --dart-define-from-file=.env
   
   # Build APK
   flutter build apk --dart-define-from-file=.env
   ```

## Getting Your API Keys

### 🔥 Firebase
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project
3. Click ⚙️ Settings → Project settings
4. Scroll to "Your apps" section
5. Copy the configuration values

### ☁️ Cloudinary
1. Go to [Cloudinary Console](https://cloudinary.com/console)
2. Dashboard shows:
   - Cloud name
   - API Key
   - API Secret
3. Copy these values to `.env`

### 🗺️ Google Maps
1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Select your project
3. Enable these APIs:
   - Maps SDK for Android
   - Maps SDK for iOS
4. Go to **APIs & Services → Credentials**
5. Create API Key
6. **Important:** Restrict your key:
   - **Android:** Add package name + SHA-1 certificate fingerprint
   - **iOS:** Add bundle identifier
7. Copy the API key

## Build Commands

### Development (with .env)
```bash
# Run on device
flutter run --dart-define-from-file=.env

# Hot reload works normally
# Press 'r' to hot reload
```

### Production Build
```bash
# Android APK
GOOGLE_MAPS_API_KEY=your_key flutter build apk --dart-define-from-file=.env

# Android App Bundle (for Play Store)
GOOGLE_MAPS_API_KEY=your_key flutter build appbundle --dart-define-from-file=.env

# iOS (requires macOS)
flutter build ios --dart-define-from-file=.env
```

### CI/CD (GitHub Actions)
Add secrets to your repository:
1. Go to Settings → Secrets and variables → Actions
2. Add each environment variable as a secret
3. The workflow will automatically use them

## Troubleshooting

### "API key not found" error
- Verify `.env` file exists
- Check file is not empty
- Ensure you're running with `--dart-define-from-file=.env`

### Google Maps not showing
- Verify GOOGLE_MAPS_API_KEY is set in environment
- Check API is enabled in Google Cloud Console
- Verify API key restrictions allow your app

### Cloudinary uploads failing
- Check CLOUDINARY_CLOUD_NAME, API_KEY, API_SECRET are correct
- Verify upload preset exists in Cloudinary dashboard
- Check network connectivity

## Security Reminders

✅ **DO:**
- Keep `.env` in `.gitignore`
- Use separate keys for dev/prod
- Rotate keys periodically
- Restrict API keys properly

❌ **DON'T:**
- Commit `.env` to git
- Share API keys publicly
- Use production keys in development
- Skip API key restrictions

## Example .env File

See `.env.example` for a complete template with all required variables.
