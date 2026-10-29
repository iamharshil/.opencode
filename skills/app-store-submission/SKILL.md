---
name: app-store-submission
description: Prepares a mobile app for Apple App Store and Google Play Store submission including metadata, screenshots, privacy declarations, build configuration, and review guideline compliance. Use when readying an app for store review or publication.
allowed-tools: Read, Write, Edit, Bash, Grep, Glob
---
# App Store Submission Preparation

Prepare all metadata, assets, configurations, and compliance artifacts needed to pass App Store and Play Store review on the first attempt.

## Step 1 — Audit the Project for Readiness

Before preparing store metadata, verify the app is technically ready. Glob and check:

1. `app.config.ts` or `app.json` — confirm `bundleIdentifier` (iOS) and `package` (Android) are set and use reverse-domain format.
2. `version` and `buildNumber`/`versionCode` are set. Increment `versionCode` (Android) on every upload; Play Store rejects duplicates.
3. Grep for `console.log` and `__DEV__` — ensure debug logging is gated behind dev checks.
4. Grep for `http://` in API URLs — App Transport Security (iOS) blocks non-HTTPS by default. Fix or add exceptions.
5. Check that app icons exist at required sizes (1024x1024 for App Store, 512x512 for Play Store adaptive icon).

## Step 2 — Prepare Apple App Store Metadata

Generate or help the user write these required fields:

| Field | Constraints |
|-------|------------|
| App Name | 30 characters max. Must be unique on the App Store. |
| Subtitle | 30 characters max. Shown below app name in search. |
| Keywords | 100 characters total, comma-separated. No spaces after commas. Do not repeat words from the app name. |
| Description | 4000 characters max. First 3 lines visible without expand. Front-load key value propositions. |
| Promotional Text | 170 characters. Can be updated without new build. Use for timely messaging. |
| What's New | Required for updates. Describe user-facing changes. |
| Support URL | Required. Must be a live, reachable URL. |
| Privacy Policy URL | Required for all apps. Must be publicly accessible. |
| Category | Primary + optional secondary. Choose carefully — affects search ranking. |

**Screenshot requirements** (at minimum):
- 6.7" iPhone (1290 x 2796) — required
- 6.5" iPhone (1284 x 2778) — required
- 12.9" iPad Pro (2048 x 2732) — required if app supports iPad
- Up to 10 screenshots per locale per device size
- First 3 screenshots are the most impactful (shown in search results)

## Step 3 — Prepare Google Play Store Metadata

| Field | Constraints |
|-------|------------|
| App Name | 30 characters max. |
| Short Description | 80 characters max. Shown in search results. |
| Full Description | 4000 characters max. Supports limited formatting. |
| Feature Graphic | 1024 x 500 px. Required. Displayed at top of listing. |
| Screenshots | Minimum 2, maximum 8 per device type. 16:9 or 9:16 aspect ratio. |

**Data Safety Form** (required): declare all data collection, sharing, and security practices. Walk through each category:
- Data collected (name, email, location, photos, etc.)
- Data shared with third parties
- Data handling practices (encryption in transit, deletion policy)
- Whether the app collects data from children

This form must be accurate. Inconsistencies trigger review rejection.

**Content Rating**: complete the IARC questionnaire in the Play Console. Answer honestly — incorrect ratings cause takedowns.

## Step 4 — Write the Privacy Policy

Every app store requires a privacy policy. Generate one that covers:

1. What data is collected (enumerate specific types)
2. How data is used
3. Third-party services that receive data (analytics, crash reporting, ads)
4. Data retention period
5. User rights (access, deletion, portability)
6. Contact information
7. Children's privacy (COPPA compliance if applicable)

Host it at a publicly accessible URL. A simple static page is sufficient. Do not use a PDF — some reviewers cannot open them.

## Step 5 — Handle Common App Review Rejections

These are the most frequent rejection reasons. Check proactively:

**4.3 — Spam/Duplicate**: your app looks too similar to existing apps or to other apps you have submitted. Ensure unique design, unique name, distinct functionality.

**2.1 — Performance: Crashes/Bugs**: the app crashes during review. Test on the exact devices and OS versions reviewers use (latest stable iOS/Android). Include a demo account in review notes if login is required.

**5.1.1 — Data Collection and Privacy**: missing or inaccurate privacy permission strings. Every iOS permission must have a usage description string explaining WHY the app needs it:

```xml
<!-- Info.plist or app.config.ts infoPlist -->
NSCameraUsageDescription: "Take photos for your profile picture"
NSLocationWhenInUseUsageDescription: "Show restaurants near your location"
NSPhotoLibraryUsageDescription: "Choose photos to share in posts"
```

Vague strings like "This app needs camera access" get rejected. Be specific about user benefit.

**3.1.1 — In-App Purchase**: if the app sells digital content, it must use Apple IAP (30% cut). Physical goods and services can use external payment. This is the single most misunderstood rule. If the user's app sells digital goods (subscriptions, premium features, virtual items), implement StoreKit/Google Billing. Do not link to external payment for digital goods.

**2.3.3 — Screenshots**: screenshots must reflect actual app experience. Do not show features that are not in the submitted build.

## Step 6 — Prepare Review Notes and Demo Credentials

Write review notes that include:

1. Demo account credentials (email/password) or explanation of how to access the app without an account
2. Description of any hardware requirements (Bluetooth devices, specific permissions)
3. Explanation of any features that might seem like they violate guidelines (and why they do not)
4. Steps to test non-obvious functionality

Example:
```
Demo Account:
Email: demo@example.com
Password: ReviewDemo2024!

To test the main feature:
1. Log in with the credentials above
2. Tap "Create" in the tab bar
3. Select any template
4. The AI will generate content (this uses our own API, not on-device)

Note: Location permission is requested when viewing the Map tab
to show nearby events. The app works without granting location.
```

## Step 7 — Configure Build and Signing

### EAS Build (Expo)

```bash
eas build --platform ios --profile production
eas build --platform android --profile production
```

For iOS, EAS manages provisioning profiles and certificates. On first build, it will prompt to create them.

For Android, generate an upload key:
```bash
eas credentials --platform android
```

Choose "Upload Key" management. EAS can manage this automatically.

### App Signing

- **iOS**: use Apple's automatic signing via EAS or Xcode. Manual signing is error-prone.
- **Android**: enroll in Google Play App Signing (strongly recommended). Google holds the app signing key; you hold an upload key. If you lose the upload key, Google can reset it. If you managed your own signing key and lost it, the app is permanently locked out of updates.

## Step 8 — Submit

### EAS Submit (Expo)
```bash
eas submit --platform ios --latest
eas submit --platform android --latest
```

### Pre-submission checklist

- [ ] App icons at all required sizes
- [ ] Splash screen configured
- [ ] Version and build number incremented
- [ ] All permission strings have user-facing descriptions
- [ ] Privacy policy URL is live and accessible
- [ ] Screenshots uploaded for all required device sizes
- [ ] Demo credentials in review notes (if login required)
- [ ] Data safety form completed (Google Play)
- [ ] Content rating completed (Google Play)
- [ ] No debug code, test banners, or placeholder content
- [ ] TestFlight / Internal Testing track verified working before production submission

## Step 9 — Post-Submission

- **Apple review time**: typically 24-48 hours. Can be expedited in emergencies via "Request Expedited Review" (use sparingly).
- **Google review time**: typically a few hours to 3 days for first submission, often faster for updates.
- If rejected, read the rejection reason carefully. Fix only the cited issue. Reply in Resolution Center (Apple) or fix and resubmit (Google). Do not make unrelated changes — this can trigger new issues.
