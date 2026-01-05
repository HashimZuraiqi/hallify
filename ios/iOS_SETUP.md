# iOS Configuration Guide for Hallify

## ✅ iOS Setup Checklist

### 1. Firebase Setup for iOS

#### Download GoogleService-Info.plist

1. Go to [Firebase Console](https://console.firebase.google.com)
2. Select your Hallify project
3. Go to **Project Settings** (⚙️ icon)
4. Click **Your apps** section
5. Select your iOS app (or create if missing)
6. Download `GoogleService-Info.plist`
7. Place in Xcode:
   - Open `ios/Runner.xcworkspace` in Xcode
   - Drag `GoogleService-Info.plist` into Runner folder
   - Check "Copy items if needed"
   - Select target: **Runner**
   - Click **Finish**

#### Enable Required Firebase Services

In Firebase Console → Authentication:
- ✅ Enable "Email/Password" sign-in method

In Firebase Console → Firestore Database:
- ✅ Create database (production mode)
- ✅ Select region

In Firebase Console → Storage:
- ✅ Create storage bucket

### 2. Google Maps Configuration

#### Get Google Maps API Key

1. Go to [Google Cloud Console](https://console.cloud.google.com)
2. Create or select your project
3. Enable these APIs:
   - ✅ Maps SDK for iOS
   - ✅ Geocoding API
   - ✅ Places API (optional)

4. Create API Key:
   - Go to **Credentials**
   - Click **Create Credentials** → **API Key**
   - Copy the key

#### Add API Key to iOS

**Option A: Via Info.plist (Recommended)**

1. Open `ios/Runner/Info.plist`
2. Add this after the last entry (before `</dict>`):

```xml
<key>com.google.ios.maps.API_KEY</key>
<string>YOUR_GOOGLE_MAPS_API_KEY</string>
```

**Option B: Via AppDelegate (Already configured)**

The `AppDelegate.swift` already includes:
```swift
GMSServices.provideAPIKey("YOUR_GOOGLE_MAPS_API_KEY")
```

Replace `YOUR_GOOGLE_MAPS_API_KEY` with your actual key.

### 3. CocoaPods Dependencies

#### Install CocoaPods (if not already)

```bash
sudo gem install cocoapods
```

#### Install iOS Dependencies

```bash
cd ios
pod install
cd ..
```

This installs all required iOS packages including:
- ✅ Firebase SDKs
- ✅ Google Maps
- ✅ Image Picker
- ✅ Geolocator
- And more...

### 4. iOS Permissions

✅ **Already configured in `Info.plist`:**

| Permission | Usage |
|-----------|-------|
| Location (When in Use) | Show halls on map |
| Camera | Take photos of halls |
| Photo Library | Upload hall images |
| Microphone | For future features |

Users will be prompted for each permission when needed.

### 5. Build Settings

#### Minimum iOS Version

Current: **iOS 11.0** (suitable for most devices)

To change, edit `ios/Podfile`:

```ruby
post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] ||= [
        '$(inherited)',
        'FIREBASE_ANALYTICS_COLLECTION_ENABLED=1',
      ]
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '12.0'  # Change this
    end
  end
end
```

### 6. Signing & Capabilities

#### Configure Team ID

1. Open `ios/Runner.xcworkspace` in Xcode
2. Select **Runner** → **Signing & Capabilities**
3. Select your team under "Signing Certificate"
4. Update bundle identifier if needed:
   - Change `com.example.hallify` to `com.yourcompany.hallify`

#### Enable Required Capabilities

In Xcode, go to **Runner** → **Signing & Capabilities**:

Add these capabilities:

1. **Push Notifications**
   - Click **+ Capability**
   - Search "Push Notifications"
   - Click to add
   - Enable for your app

2. **Background Modes** (optional)
   - Add capability
   - Check: "Background fetch"
   - Check: "Remote notifications"

3. **Maps** (included with google_maps_flutter)

4. **Camera & Photo Library** (included with image_picker)

### 7. Run on iOS Device

#### Option A: Run on Simulator

```bash
# List available simulators
xcrun simctl list devices

# Run on default simulator
flutter run

# Run on specific simulator
flutter run -d "iPhone 15 Pro"
```

#### Option B: Run on Physical Device

1. **Connect your iPhone** via USB cable
2. Trust the computer when prompted on device
3. In Xcode:
   - Go to **Signing & Capabilities**
   - Select your Apple ID/Team
   - Create certificate if needed

4. Run:
```bash
flutter run
```

#### Option C: Build and Install

```bash
# Build for iOS
flutter build ios --release

# This creates an archive you can upload to App Store Connect
```

### 8. Troubleshooting iOS Issues

#### Pod Install Fails

```bash
cd ios
rm -rf Pods
rm Podfile.lock
pod install
cd ..
```

#### Build Fails with "Module not found"

```bash
flutter clean
flutter pub get
cd ios
pod install
cd ..
flutter run
```

#### Google Maps Not Showing

1. Check API key in `AppDelegate.swift` or `Info.plist`
2. Verify Maps API is enabled in Google Cloud Console
3. Check location permission is granted

#### Location Permission Denied

1. Check `Info.plist` has location descriptions (✅ Already added)
2. Allow location in iOS Settings → Hallify
3. Test with Simulator: **Debug** → **Location** → Select location

#### Firebase Auth Not Working

1. Verify `GoogleService-Info.plist` is added to Xcode project
2. Check bundle identifier matches Firebase project
3. Ensure Authentication is enabled in Firebase Console

#### Camera/Photo Library Not Working

1. Grant permissions in device Settings
2. Or test: Simulator → Debug → permissions

### 9. iOS Deployment

#### Build for App Store

1. Update version in `pubspec.yaml`:
```yaml
version: 1.0.0+1  # 1.0.0 is version, +1 is build number
```

2. Build:
```bash
flutter build ios --release
```

3. In Xcode → Product → Archive
4. Distribute to App Store Connect

#### Build for TestFlight

1. Archive the app in Xcode
2. Upload to TestFlight via App Store Connect
3. Invite testers to download and test

### 10. Performance Tips

- Use iOS 13+ for better performance
- Test on real device, not just simulator
- Monitor app size and memory usage
- Use Xcode Profiler for debugging
- Enable release mode for testing: `flutter run --release`

### 11. Quick Reference Commands

```bash
# Clean everything
flutter clean

# Get dependencies
flutter pub get

# Install iOS pods
cd ios && pod install && cd ..

# Run on simulator
flutter run

# Run on device
flutter run

# Run in release mode
flutter run --release

# Build for iOS
flutter build ios --release

# View device logs
flutter logs

# Run with detailed output
flutter run -v
```

### 12. Testing Checklist

Before submitting to App Store:

- [ ] ✅ All features work on real iOS device
- [ ] ✅ Location permission works
- [ ] ✅ Camera/photo upload works
- [ ] ✅ Maps display correctly
- [ ] ✅ Chat messaging works
- [ ] ✅ Firebase authentication works
- [ ] ✅ Image loading is smooth
- [ ] ✅ No crashes in simulator or device
- [ ] ✅ App icon and splash screen display
- [ ] ✅ Orientation works (portrait + landscape)

### 13. Need Help?

- [Flutter iOS Documentation](https://flutter.dev/docs/deployment/ios)
- [Firebase iOS Setup](https://firebase.google.com/docs/ios/setup)
- [Google Maps iOS Guide](https://developers.google.com/maps/documentation/ios-sdk)
- [Xcode Help](https://help.apple.com/xcode)

---

## Summary

✅ **iOS Configuration Status:**
- Firebase configuration files: Ready to add
- Google Maps: Configured in AppDelegate
- Permissions: All set in Info.plist
- CocoaPods: Ready to install
- Build settings: Optimized for iOS

**Next Steps:**
1. Add `GoogleService-Info.plist` to Xcode
2. Add Google Maps API key
3. Run `pod install`
4. Test on simulator or device
5. Build and deploy to App Store
