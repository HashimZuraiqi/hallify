# Security Policy

## 🔒 Sensitive Files

The following files contain sensitive API keys and should **NEVER** be committed to version control:

### Already Gitignored (✅ Safe)
- `.env` - Environment variables
- `.env.*` - Environment variable variants
- `google-services.json` - Firebase Android configuration
- `firebase_options.dart` - Firebase configuration (now removed from tracking)

### Files That Need Attention
- `android/app/src/main/AndroidManifest.xml` - Contains Google Maps API key
- `lib/services/cloudinary_service.dart` - Contains Cloudinary credentials

---

## 🛠️ Setup Instructions

### 1. Remove Hardcoded Secrets

The following files have been updated to use environment variables:
- ✅ `lib/firebase_options.dart` - Uses `String.fromEnvironment()`
- ✅ `lib/services/cloudinary_service.dart` - Uses `ApiConfig`
- ✅ `android/app/src/main/AndroidManifest.xml` - Uses placeholder

### 2. Create Your Local Environment File

```bash
# Copy the example file
cp .env.example .env

# Edit .env and add your actual API keys
```

### 3. Configure Your API Keys

Edit `.env` with your actual credentials:

```bash
# Firebase
FIREBASE_WEB_API_KEY=AIzaSy...
FIREBASE_ANDROID_API_KEY=AIzaSy...

# Cloudinary
CLOUDINARY_CLOUD_NAME=your_cloud_name
CLOUDINARY_API_KEY=123456789
CLOUDINARY_API_SECRET=your_secret

# Google Maps
GOOGLE_MAPS_API_KEY_ANDROID=AIzaSy...
```

### 4. Run with Environment Variables

```bash
# Development build with env vars
flutter run --dart-define-from-file=.env

# Production build
flutter build apk --dart-define-from-file=.env
```

---

## 🔥 If You've Already Committed Secrets

### Immediate Actions:

1. **Rotate ALL exposed API keys immediately**
   - Firebase: Generate new keys in Firebase Console
   - Cloudinary: Rotate API keys in Cloudinary Dashboard
   - Google Maps: Restrict and regenerate keys in Google Cloud Console

2. **Remove sensitive files from Git history**

```bash
# Install BFG Repo-Cleaner
# Download from: https://rtyley.github.io/bfg-repo-cleaner/

# Remove sensitive files from history
bfg --delete-files firebase_options.dart
bfg --delete-files google-services.json

# Clean up
git reflog expire --expire=now --all
git gc --prune=now --aggressive

# Force push (⚠️ WARNING: This rewrites history)
git push --force
```

3. **Update .gitignore**

Ensure these are in `.gitignore`:
```
# API Keys and Secrets
.env
.env.*
google-services.json
GoogleService-Info.plist

# Firebase
firebase_options.dart
android/app/google-services.json
ios/Runner/GoogleService-Info.plist
```

---

## 🔐 Best Practices

### For Development
- ✅ Use `.env` files (never commit)
- ✅ Use `String.fromEnvironment()` for compile-time constants
- ✅ Use environment variables in CI/CD
- ❌ Never hardcode API keys in source code
- ❌ Never commit `.env` files

### For Production
- ✅ Use GitHub Secrets for CI/CD
- ✅ Restrict API keys by:
  - IP address (server-side APIs)
  - Bundle ID (mobile apps)
  - HTTP Referrer (web apps)
- ✅ Enable API key rotation
- ✅ Monitor API usage for anomalies

### API Key Restrictions

#### Firebase API Keys
Firebase API keys are safe to expose in client apps BUT:
- Enable Firebase App Check
- Set up Firebase Security Rules
- Restrict by bundle ID (Android/iOS)

#### Cloudinary
- Use unsigned upload presets for client uploads
- Restrict by HTTP Referrer
- Use signed uploads for sensitive operations

#### Google Maps
- Restrict by:
  - Android: Package name + SHA-1 certificate
  - iOS: Bundle ID
  - Web: HTTP referrers
- Set usage quotas

---

## 📋 Checklist for Contributors

Before committing:
- [ ] No hardcoded API keys in code
- [ ] `.env` is in `.gitignore`
- [ ] Sensitive files are in `.gitignore`
- [ ] Using `String.fromEnvironment()` for secrets
- [ ] Updated `.env.example` if adding new variables
- [ ] Tested with environment variables

---

## 🚨 Reporting Security Issues

If you discover a security vulnerability:
1. **DO NOT** open a public issue
2. Email: [your-email@example.com]
3. Include:
   - Description of vulnerability
   - Steps to reproduce
   - Potential impact

---

## 📚 Additional Resources

- [OWASP Mobile Security](https://owasp.org/www-project-mobile-security/)
- [Firebase Security Best Practices](https://firebase.google.com/docs/rules/basics)
- [Google API Key Best Practices](https://cloud.google.com/docs/authentication/api-keys)
