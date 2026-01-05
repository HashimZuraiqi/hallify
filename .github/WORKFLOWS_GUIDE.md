# GitHub Actions Setup Guide for Hallify

This guide explains how to set up and use GitHub Actions for CI/CD with your Hallify Flutter app.

## 📋 Overview

The workflows included automate:
1. **Testing & Analysis** - Run tests and code analysis on every push
2. **Building** - Automatically build APK, App Bundle, and iOS app
3. **Deployment** - Deploy to Google Play and TestFlight
4. **Code Quality** - Check formatting, analyze code, and scan for security issues

## 🚀 Quick Setup

### Step 1: Push Code to GitHub

```bash
git remote add origin https://github.com/yourusername/hallify.git
git branch -M main
git push -u origin main
```

### Step 2: Enable GitHub Actions

1. Go to your GitHub repository
2. Click **Settings** → **Actions** → **General**
3. Enable "Allow all actions and reusable workflows"
4. Click **Save**

### Step 3: Add Secrets for Deployment

Go to **Settings** → **Secrets and variables** → **Actions** and add:

#### For Google Play Deployment:
- `GOOGLE_PLAY_SERVICE_ACCOUNT_JSON` - Service account JSON file from Google Play Console

#### For TestFlight/App Store:
- `APPLE_ID` - Your Apple ID email
- `APPLE_PASSWORD` - Your Apple ID password
- `APPLE_APP_SPECIFIC_PASSWORD` - App-specific password from Apple ID

## 📁 Workflow Files

### 1. `flutter_build.yml` - Main CI/CD Pipeline
**Triggers on**: Push to main/develop, Pull requests

**Jobs**:
- ✅ Test & Analyze - Runs tests and linting
- 🏗️ Build Android APK - Creates release APK
- 📦 Build App Bundle - Creates AAB for Google Play
- 🍎 Build iOS - Creates iOS build
- 🔖 Create Release - Creates GitHub Release (on tags)

### 2. `release.yml` - Deployment to App Stores
**Triggers on**: Manual workflow dispatch

**Jobs**:
- 🎯 Deploy Android - Uploads to Google Play
- 🍎 Deploy iOS - Uploads to TestFlight

### 3. `code_quality.yml` - Quality & Security
**Triggers on**: Push to main/develop, Pull requests

**Jobs**:
- 📊 Code Quality - Linting, formatting, metrics
- 🔒 Security Scanning - Vulnerability and secret detection
- 📈 Test Coverage - Generates coverage reports

## 🔧 Configuration

### Update Flutter Version

Edit the workflow files and change the Flutter version:

```yaml
- name: Setup Flutter
  uses: subosito/flutter-action@v2
  with:
    flutter-version: '3.13.0'  # ← Update this version
```

### Change Package Name

In `release.yml`, update:
```yaml
packageName: com.yourcompany.hallify  # ← Your package name
```

### Configure Build Settings

In your `pubspec.yaml`:
```yaml
version: 1.0.0+1  # ← Update version before release
```

## 📱 Google Play Setup

### Get Service Account JSON

1. Go to [Google Play Console](https://play.google.com/console)
2. Click **Settings** → **API access**
3. Click **Create new service account**
4. Create a new key (JSON format)
5. Download and save the JSON file
6. Add to GitHub Secrets as `GOOGLE_PLAY_SERVICE_ACCOUNT_JSON`

### Set App Release Track

In `release.yml`, the workflow accepts track input:
- `internal` - Internal testing
- `alpha` - Alpha testing
- `beta` - Beta testing
- `production` - Production release

## 🍎 App Store Setup

### Create App-Specific Password

1. Go to [Apple ID account page](https://appleid.apple.com)
2. Go to **Security** section
3. Under "App Passwords", click **Generate**
4. Select "Other (specify)"
5. Enter "GitHub Actions"
6. Copy and save the password

### Configure Fastlane (iOS)

Create `ios/fastlane/Fastfile`:

```ruby
default_platform(:ios)

platform :ios do
  desc "Push a new beta build to TestFlight"
  lane :beta do
    build_app(
      workspace: "Runner.xcworkspace",
      scheme: "Runner",
      configuration: "Release",
      derived_data_path: "build/ios",
      destination: "generic/platform=iOS",
      export_method: "app-store",
      export_options: {
        signingStyle: "automatic",
        stripSwiftSymbols: true,
        teamID: "YOUR_TEAM_ID"
      }
    )
    
    upload_to_testflight(
      skip_waiting_for_build_processing: true
    )
  end
end
```

## ▶️ Running Workflows

### Automatic Triggers

Workflows run automatically when:
- You push to `main` or `develop` branch
- You create a pull request to `main` or `develop`
- You create a git tag (for releases)

### Manual Triggers

**Deploy to App Stores**:
1. Go to **Actions** tab
2. Select **"Release to Google Play & App Store"**
3. Click **"Run workflow"**
4. Choose the track (internal, alpha, beta, production)
5. Click **"Run workflow"**

### Via Command Line

```bash
# Tag a release
git tag v1.0.0
git push origin v1.0.0

# This triggers the build and release workflows
```

## 📊 Monitoring Builds

### Check Build Status

1. Go to **Actions** tab in your GitHub repository
2. Click on a workflow run to see details
3. Click on a job to see logs

### View Artifacts

After a successful build:
1. Go to the workflow run
2. Scroll down to **Artifacts**
3. Download APK, AAB, or iOS build

## 🔐 Security Best Practices

### Protect Secrets

- ✅ Use GitHub Secrets for sensitive data
- ❌ Never commit credentials
- ❌ Don't use branch protection on develop
- ✅ Require reviews before merging to main

### Secure Workflows

```yaml
# Only run deployment on main branch
if: github.ref == 'refs/heads/main' && github.event_name == 'push'
```

## 🐛 Troubleshooting

### Build fails with "SDK not found"

Solution: Flutter version mismatch. Update in workflow:
```yaml
flutter-version: '3.13.0'  # Match your local version
```

### APK signing fails

Solution: Ensure `android/key.properties` is configured locally and not in git

### iOS build fails

Solution: Check that Xcode build settings are correct:
```bash
cd ios
pod install
```

### Deployment fails with authentication error

Solution: Verify secrets are correctly added:
1. Go to Settings → Secrets and variables → Actions
2. Check that all required secrets exist
3. Verify values are correct (no extra spaces)

## 📝 Example Workflows

### Build and Test Only (No Deployment)

```yaml
on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
      - run: flutter pub get
      - run: flutter test
```

### Tag-Based Releases

```yaml
on:
  push:
    tags:
      - 'v*'

jobs:
  release:
    # Your build jobs here
```

### Scheduled Nightly Builds

```yaml
on:
  schedule:
    - cron: '0 2 * * *'  # 2 AM UTC daily
```

## 🚀 Next Steps

1. ✅ Commit workflow files to `.github/workflows/`
2. ✅ Add required secrets to GitHub
3. ✅ Update app version in `pubspec.yaml`
4. ✅ Test with a small release
5. ✅ Monitor builds in Actions tab
6. ✅ Deploy to production

## 📚 Resources

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Flutter on GitHub Actions](https://docs.flutter.dev/deployment/cd)
- [Google Play Console Help](https://support.google.com/googleplay/android-developer)
- [App Store Connect Help](https://help.apple.com/app-store-connect)

## 💡 Tips

- Use branch protection rules to require successful actions before merging
- Set up notifications for workflow failures
- Monitor build times and optimize slow jobs
- Test workflows on a develop branch first
- Keep workflow files in version control
- Document any custom scripts or configurations

---

For more details, check the individual workflow files in `.github/workflows/`
