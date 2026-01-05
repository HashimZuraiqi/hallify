# GitHub Actions - Quick Start

## What are GitHub Actions?

GitHub Actions is a CI/CD (Continuous Integration/Continuous Deployment) tool that automatically builds, tests, and deploys your app whenever you push code to GitHub.

## What These Workflows Do

### 1. **flutter_build.yml** ✅
- Runs every time you push code
- Tests your app
- Analyzes code for errors
- Builds Android APK and App Bundle
- Builds iOS app
- Creates releases on GitHub

### 2. **release.yml** 🚀
- Manually triggered (you control when)
- Uploads Android app to Google Play
- Uploads iOS app to TestFlight
- Requires Google Play and Apple credentials

### 3. **code_quality.yml** 📊
- Runs on every push
- Checks code formatting
- Scans for security vulnerabilities
- Generates test coverage reports
- Checks for accidental secrets

## Quick Setup (5 minutes)

### Step 1: Push to GitHub
```bash
git remote add origin https://github.com/yourusername/hallify.git
git push -u origin main
```

### Step 2: Go to Repository Settings
1. Click **Settings** → **Secrets and variables** → **Actions**

### Step 3: Add Secrets (for deployment)

**For Google Play:**
- Name: `GOOGLE_PLAY_SERVICE_ACCOUNT_JSON`
- Value: Your service account JSON (paste entire file)

**For Apple TestFlight:**
- Name: `APPLE_ID` → Your Apple ID email
- Name: `APPLE_PASSWORD` → Your Apple ID password  
- Name: `APPLE_APP_SPECIFIC_PASSWORD` → Apple-specific password

### Step 4: That's It!
Workflows now run automatically!

## Monitor Your Builds

1. Go to **Actions** tab in your GitHub repository
2. See all workflow runs
3. Click on a run to see details
4. Download built APK/AAB/iOS from artifacts

## Deploy to App Stores

1. Go to **Actions** tab
2. Click **"Release to Google Play & App Store"**
3. Click **"Run workflow"** button
4. Choose track: internal / alpha / beta / production
5. Watch the deployment in real-time

## Environment Setup

### Get Google Play Service Account
1. Open [Google Play Console](https://play.google.com/console)
2. Settings → API access
3. Create new service account
4. Download JSON key
5. Add to GitHub Secrets

### Get Apple Credentials
1. Go to [AppleID.apple.com](https://appleid.apple.com)
2. Security section
3. Generate app-specific password
4. Add to GitHub Secrets

## File Structure
```
.github/
└── workflows/
    ├── flutter_build.yml      # Main build pipeline
    ├── release.yml            # Deploy to stores
    └── code_quality.yml       # Code analysis
```

## Common Commands

```bash
# Tag for release (triggers build + release)
git tag v1.0.0
git push origin v1.0.0

# View workflow status
gh run list

# View specific run logs
gh run view <run-id> --log
```

## What Happens Automatically

| When | What | Result |
|------|------|--------|
| Push to main | Build + Test | APK/AAB/iOS created |
| Create tag | Build + Test + Release | GitHub release created with APK/AAB |
| Manual trigger | Deploy | App uploaded to stores |
| PR created | Test + Analysis | Check if code passes |

## Costs

✅ **Free!** - GitHub Actions includes:
- 2,000 minutes/month for free accounts
- Unlimited public repositories
- 3,000 minutes/month for private repos (paid plans)

## Next Steps

1. ✅ Push workflows to `.github/workflows/`
2. ✅ Add secrets to repository settings
3. ✅ Make a test push to trigger the build
4. ✅ Check **Actions** tab to watch the build
5. ✅ Download artifacts to test locally
6. ✅ Set up app store deployment when ready

## Need Help?

- Check workflow logs in **Actions** tab
- See errors in the job output
- Read [GitHub Actions docs](https://docs.github.com/en/actions)
- Check [Flutter CI/CD guide](https://docs.flutter.dev/deployment/cd)

## Pro Tips

- Start with `flutter_build.yml` only
- Test workflows on develop branch first
- Use branch protection to require passing builds
- Monitor build times and optimize
- Keep secrets secure - never commit them
- Use git tags for version control
