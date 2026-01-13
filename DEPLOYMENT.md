# CardShow Pro - Deployment & Release Guide

**Version:** 1.0
**Last Updated:** January 13, 2026
**Document Owner:** Engineering & DevOps Team
**Status:** Active Development

---

## Table of Contents

1. [Overview](#overview)
2. [Development Environment Setup](#development-environment-setup)
3. [Code Signing & Certificates](#code-signing--certificates)
4. [App Store Connect Configuration](#app-store-connect-configuration)
5. [TestFlight Beta Distribution](#testflight-beta-distribution)
6. [App Store Submission](#app-store-submission)
7. [Version Management](#version-management)
8. [CI/CD Pipeline](#cicd-pipeline)
9. [Release Process](#release-process)
10. [Post-Release Monitoring](#post-release-monitoring)

---

## Overview

This guide covers the complete deployment process from development to App Store release.

### Release Timeline

| Phase | Duration | Description |
|-------|----------|-------------|
| **Development** | Ongoing | Feature development and testing |
| **Internal Testing** | 1 week | Team testing on devices |
| **TestFlight Beta** | 2-4 weeks | External user testing |
| **App Store Review** | 1-3 days | Apple review process |
| **Release** | Immediate | Go live on App Store |

---

## Development Environment Setup

### Prerequisites

**Required Software:**
- macOS Sonoma (14.0) or later
- Xcode 16.0 or later
- Xcode Command Line Tools
- Git

**Apple Developer Account:**
- Individual or Organization account ($99/year)
- Admin access to App Store Connect

### Initial Setup

```bash
# 1. Install Xcode from App Store
open -a "App Store"

# 2. Install Command Line Tools
xcode-select --install

# 3. Clone repository
git clone https://github.com/yourusername/CardShowPro.git
cd CardShowPro

# 4. Open workspace (NOT project)
open CardShowPro.xcworkspace
```

### Xcode Configuration

**Settings to verify:**

1. **Accounts**
   - Xcode → Settings → Accounts
   - Add Apple ID associated with developer account
   - Download manual profiles if needed

2. **Signing & Capabilities**
   - Select CardShowPro target
   - Enable "Automatically manage signing"
   - Select your Team
   - Verify Bundle ID: `com.cardshowpro.app`

3. **Build Settings**
   - All configurations use XCConfig files
   - Don't modify project settings directly
   - Edit `Config/*.xcconfig` files instead

---

## Code Signing & Certificates

### Certificate Types

| Certificate | Purpose | Valid For |
|------------|---------|-----------|
| **Development** | Local testing on devices | 1 year |
| **Distribution** | App Store submission | 1 year |
| **Push Notification** | Send push notifications | 1 year (future) |

### Creating Certificates

**Option A: Automatic (Recommended)**

```swift
// In Xcode:
1. Select CardShowPro target
2. Signing & Capabilities tab
3. Team: Select your team
4. ✅ Automatically manage signing

Xcode handles everything automatically.
```

**Option B: Manual**

```bash
# 1. Go to developer.apple.com
# 2. Certificates, Identifiers & Profiles
# 3. Create new certificate
# 4. Download and install in Keychain
```

### Provisioning Profiles

**Development Profile:**
- For testing on your devices
- Includes device UDIDs
- Managed automatically by Xcode

**App Store Profile:**
- For App Store distribution
- No device restrictions
- Created during Archive process

### Troubleshooting Signing Issues

```bash
# View installed certificates
security find-identity -v -p codesigning

# View provisioning profiles
ls ~/Library/MobileDevice/Provisioning\ Profiles/

# Reset signing (if issues)
# 1. Delete derived data
rm -rf ~/Library/Developer/Xcode/DerivedData

# 2. Revoke and recreate certificates in developer portal
# 3. Download new profiles in Xcode
```

---

## App Store Connect Configuration

### Initial App Setup

**1. Create App Record**

```
1. Go to appstoreconnect.apple.com
2. My Apps → + button → New App
3. Fill in:
   - Platforms: iOS
   - Name: CardShow Pro
   - Primary Language: English (U.S.)
   - Bundle ID: com.cardshowpro.app
   - SKU: cardshowpro-001
   - User Access: Full Access
```

**2. App Information**

```
Category: Business
Secondary Category: Productivity

Age Rating:
- 4+ (No restricted content)

Privacy Policy URL:
- https://cardshowpro.com/privacy

Support URL:
- https://cardshowpro.com/support

Marketing URL (optional):
- https://cardshowpro.com
```

**3. Pricing & Availability**

```
Price: Free (with In-App Purchases for V2)

Availability:
- All countries initially
- Can restrict by country later

Pre-Order: Not available for first release
```

---

### App Store Metadata

**App Name:**
```
CardShow Pro - Card Business
```

**Subtitle (30 chars):**
```
Manage Your Card Business
```

**Promotional Text (170 chars):**
```
The only app built for card sellers. Track inventory, analyze trades, manage events, and grow your business—all from your phone. Try it free for 14 days.
```

**Description (4000 chars max):**
```
CARDSHOW PRO - THE CARD SELLER'S OPERATING SYSTEM

Built exclusively for trading card sellers, not collectors. Whether you're a full-time vendor, online seller, or weekend trader, CardShow Pro is your all-in-one business management platform.

KEY FEATURES:

📊 BUSINESS INVENTORY
• Track purchase cost and current market value
• Automatic profit margin calculations
• Import cards from price lookup or scan
• Tag and categorize your inventory
• Search and filter by value, date, or profit

💰 INSTANT PRICE LOOKUP
• Fast, accurate TCGPlayer pricing
• All variants (Normal, Holo, Reverse, etc.)
• Pokemon, Magic, Yu-Gi-Oh, and more
• Offline mode with cached prices
• Compare prices across platforms

🤝 TRADE ANALYZER
• Custom trade percentages (70-100%)
• Instant fairness calculations
• Save trade history for records
• Track cards traded in and out

🏪 VENDOR MODE (Coming Soon)
• Manage card show events
• Track sales in real-time
• Generate post-event reports
• Multi-user support for teams

📈 BUSINESS ANALYTICS
• Total inventory value
• Profit margins by card
• Sales trends over time
• ROI tracking

👥 CUSTOMER CRM (Coming Soon)
• Track customer contacts
• Want list alerts
• Purchase history
• Build repeat business

🤖 AI FEATURES (Coming Soon)
• Card grading assistant
• Listing generator for eBay/TCGPlayer
• Market insights and recommendations

FREE FEATURES:
✓ Price lookup (unlimited)
✓ Basic inventory (100 cards max)

PRO SUBSCRIPTION ($9.99/month):
✓ Unlimited inventory
✓ Vendor Mode
✓ Analytics Dashboard
✓ Trade Analyzer
✓ Sales Calculator
✓ Customer CRM
✓ AI Features

14-DAY FREE TRIAL - NO CREDIT CARD REQUIRED

WHY CARDSHOW PRO?

Unlike collection trackers designed for hobbyists, CardShow Pro is built for sellers who need profit tracking, trade tools, and business analytics. Track every dollar spent and earned, optimize your trades, and make data-driven decisions.

TRUSTED BY CARD SELLERS
"CardShow Pro saves me 5+ hours per week and increased my profits by 15%." - Mike, Full-Time Vendor

QUESTIONS?
Email: support@cardshowpro.com
Website: https://cardshowpro.com

Privacy Policy: https://cardshowpro.com/privacy
Terms of Service: https://cardshowpro.com/terms

Download CardShow Pro today and take your card business to the next level.
```

**Keywords (100 chars):**
```
pokemon,card,trading,tcg,business,inventory,seller,vendor,pricing,profit,analytics
```

**What's New (4000 chars):**
```
Version 1.0 - Initial Release

Welcome to CardShow Pro! The first app built exclusively for card sellers.

NEW IN THIS VERSION:
• Instant price lookup for Pokemon cards
• Business inventory with profit tracking
• Search and filter your inventory
• Offline mode with price caching
• Dark mode optimized UI

COMING SOON:
• Multi-game support (Magic, Yu-Gi-Oh, One Piece)
• Vendor Mode for card shows
• Trade Analyzer with custom percentages
• AI-powered features

Thank you for supporting an indie developer building tools for the card community!

Questions or feedback? Email support@cardshowpro.com
```

---

### Screenshots & App Previews

**Required Sizes:**

| Device | Resolution | Count |
|--------|-----------|-------|
| iPhone 6.9" (16 Pro Max) | 1320 x 2868 | 3-10 |
| iPhone 6.7" (15 Plus) | 1290 x 2796 | 3-10 |
| iPhone 6.5" (14 Pro Max) | 1284 x 2778 | 3-10 |
| iPad Pro (6th gen) 13" | 2048 x 2732 | 3-10 |

**Screenshot Guidelines:**

1. **#1 - Hero Shot** (Price Lookup)
   - Show card price lookup in action
   - Real Pokemon card with pricing
   - Title: "Instant Price Lookup"
   - Subtitle: "Fast, accurate pricing for all cards"

2. **#2 - Inventory**
   - Show inventory list with cards
   - Profit margins visible
   - Title: "Track Your Business Inventory"
   - Subtitle: "Purchase cost, market value, profit—all in one place"

3. **#3 - Analytics** (if available)
   - Dashboard with charts
   - Total value, profit trends
   - Title: "Business Analytics"
   - Subtitle: "Make data-driven decisions"

4. **#4 - Features List**
   - Bulleted feature highlights
   - Icons for each feature
   - Title: "Everything You Need"

5. **#5 - Vendor Mode Teaser** (future)
   - Event management UI
   - Title: "Built for Vendors"

**Tools for Screenshots:**
- Xcode Simulator (Cmd+S to capture)
- [Screenshot.rocks](https://screenshot.rocks) for frames
- Figma for text overlays

---

## TestFlight Beta Distribution

### Setup TestFlight

**1. Create TestFlight Build**

```bash
# In Xcode:
1. Product → Archive
2. Wait for build to complete
3. Organizer window opens
4. Select archive → Distribute App
5. Choose: TestFlight & App Store → Next
6. Upload
```

**2. Add Internal Testers**

```
App Store Connect → TestFlight → Internal Testing
- Add up to 100 internal testers (Apple IDs)
- They get immediate access
- No review required
```

**3. Add External Testers**

```
App Store Connect → TestFlight → External Testing
- Create test group (e.g., "Beta Testers")
- Add up to 10,000 external testers (emails)
- Submit for Beta App Review (1-2 days)
- Set public link or invite-only
```

### Beta Testing Process

**Week 1: Internal (Team)**
```
Testers: 5-10 team members
Focus: Critical bugs, crashes, major UX issues
Goal: Fix show-stoppers
```

**Week 2-3: External (Power Users)**
```
Testers: 50-100 vendors/sellers
Focus: Real-world usage, feature requests
Goal: Validate product-market fit
```

**Week 4: Final Beta**
```
Testers: 100-500 users
Focus: Performance, edge cases, final polish
Goal: Confidence for public release
```

### Collecting Feedback

**In-App Feedback:**
```swift
import StoreKit

// Trigger after 7 days of usage
SKStoreReviewController.requestReview()
```

**Beta Feedback Form:**
```
Google Form with:
- What do you like most?
- What's missing?
- Any bugs or crashes?
- Would you pay $9.99/month? (yes/no)
- Net Promoter Score (0-10)
```

**TestFlight Feedback:**
- Automatic crash reports
- User screenshots with annotations
- Build metadata (device, iOS version)

---

## App Store Submission

### Pre-Submission Checklist

**Code Quality:**
- [ ] All tests passing (unit + integration + UI)
- [ ] No compiler warnings
- [ ] No hardcoded API keys or secrets
- [ ] Proper error handling throughout
- [ ] Accessibility labels on interactive elements

**App Store Requirements:**
- [ ] Privacy policy URL set
- [ ] Support URL set
- [ ] Age rating appropriate (4+)
- [ ] Screenshots for all required device sizes
- [ ] App description written (no typos)
- [ ] Keywords optimized
- [ ] Version number bumped
- [ ] Build number incremented

**Legal:**
- [ ] No placeholder text ("Lorem ipsum", "TODO")
- [ ] No copyrighted content without permission
- [ ] No references to TestFlight or beta
- [ ] Privacy policy mentions camera/photo usage

**Functionality:**
- [ ] Tested on real devices (not just simulator)
- [ ] Works offline (if applicable)
- [ ] No crashes on launch
- [ ] All features functional
- [ ] Links open correctly (support, privacy policy)

---

### Submission Process

**1. Create App Store Version**

```
App Store Connect → My Apps → CardShow Pro
→ App Store tab → + Version (e.g., 1.0)
```

**2. Upload Build**

```
1. Archive in Xcode (Product → Archive)
2. Organizer → Distribute App
3. App Store Connect → Upload
4. Wait for processing (~10-30 minutes)
```

**3. Select Build**

```
App Store Connect → Version → Build
→ Select uploaded build
→ Save
```

**4. Complete Metadata**

```
- Screenshots (all device sizes)
- Description
- Keywords
- Support URL
- Privacy Policy URL
- Age Rating
- Copyright
```

**5. Submit for Review**

```
→ Save
→ Submit for Review
→ Answer questionnaires:
  - Advertising Identifier: No (unless using ads)
  - Content Rights: Yes (you own all content)
  - Export Compliance: No (no encryption beyond HTTPS)
```

---

### App Review Process

**Timeline:**
- **Submission → In Review:** 1-48 hours
- **In Review → Decision:** 1-24 hours
- **Total:** 1-3 days average

**Common Rejection Reasons:**

1. **Crashes on Launch**
   - Test on real devices before submission
   - Enable crash reporting (TestFlight feedback)

2. **Incomplete Functionality**
   - "Coming Soon" features must be removed or functional
   - All buttons must work

3. **Privacy Policy Missing Camera Explanation**
   - Add: "We request camera access to scan trading cards"

4. **Misleading Screenshots**
   - Screenshots must show actual app, not mockups
   - No fake reviews or testimonials

5. **In-App Purchase Issues**
   - If offering subscriptions, must be configured in App Store Connect
   - Restore purchases button required

**If Rejected:**
```
1. Read rejection message carefully
2. Fix issues in code
3. Create new build
4. Upload and resubmit
5. Address reviewer notes in "Notes for Reviewer" field
```

---

## Version Management

### Versioning Scheme

**Format:** MAJOR.MINOR.PATCH (e.g., 1.2.3)

- **MAJOR:** Breaking changes, major new features (1.0 → 2.0)
- **MINOR:** New features, backward compatible (1.0 → 1.1)
- **PATCH:** Bug fixes, minor improvements (1.0.0 → 1.0.1)

**Examples:**
```
1.0.0 - Initial App Store release (V1 MVP)
1.1.0 - Add Multi-Game Support (V2)
1.2.0 - Add AI Features (V3)
1.2.1 - Bug fixes
2.0.0 - Complete redesign or major breaking change
```

### Build Numbers

**Rule:** Increment for every TestFlight upload

```
Version 1.0.0:
  Build 1 - First internal test
  Build 2 - Fixed crash
  Build 3 - External beta
  Build 4 - App Store submission

Version 1.0.1:
  Build 5 - Bug fix release
```

### Updating Version Numbers

**Location:** `Config/Shared.xcconfig`

```bash
# Edit Config/Shared.xcconfig
MARKETING_VERSION = 1.0.0
CURRENT_PROJECT_VERSION = 1

# Commit changes
git add Config/Shared.xcconfig
git commit -m "chore: Bump version to 1.0.0 (build 1)"
git tag v1.0.0
git push origin main --tags
```

---

## CI/CD Pipeline

### GitHub Actions Workflow

**File:** `.github/workflows/deploy.yml`

```yaml
name: Deploy

on:
  push:
    tags:
      - 'v*'

jobs:
  build:
    runs-on: macos-latest

    steps:
    - name: Checkout code
      uses: actions/checkout@v3

    - name: Select Xcode
      run: sudo xcode-select -s /Applications/Xcode.app

    - name: Install dependencies
      run: |
        # Add any package dependencies here

    - name: Run tests
      run: |
        xcodebuild test \
          -workspace CardShowPro.xcworkspace \
          -scheme CardShowPro \
          -destination 'platform=iOS Simulator,name=iPhone 16'

    - name: Archive app
      run: |
        xcodebuild archive \
          -workspace CardShowPro.xcworkspace \
          -scheme CardShowPro \
          -archivePath ./build/CardShowPro.xcarchive \
          -configuration Release

    - name: Export IPA
      run: |
        xcodebuild -exportArchive \
          -archivePath ./build/CardShowPro.xcarchive \
          -exportPath ./build \
          -exportOptionsPlist ExportOptions.plist

    - name: Upload to TestFlight
      env:
        APPLE_ID: ${{ secrets.APPLE_ID }}
        APPLE_APP_PASSWORD: ${{ secrets.APPLE_APP_PASSWORD }}
      run: |
        xcrun altool --upload-app \
          --type ios \
          --file ./build/CardShowPro.ipa \
          --username "$APPLE_ID" \
          --password "$APPLE_APP_PASSWORD"
```

**ExportOptions.plist:**

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>app-store</string>
    <key>teamID</key>
    <string>YOUR_TEAM_ID</string>
    <key>uploadBitcode</key>
    <false/>
    <key>uploadSymbols</key>
    <true/>
</dict>
</plist>
```

### Secrets Configuration

**Add to GitHub Repository Secrets:**

```
Settings → Secrets and variables → Actions → New repository secret

APPLE_ID: your-apple-id@email.com
APPLE_APP_PASSWORD: app-specific-password (from appleid.apple.com)
TEAM_ID: Your 10-character Team ID
```

---

## Release Process

### Step-by-Step Release

**1 Week Before Release:**
```bash
# Create release branch
git checkout -b release/1.0.0

# Final testing
# - Run full test suite
# - Manual testing on devices
# - TestFlight beta with 50+ users
```

**3 Days Before Release:**
```bash
# Freeze code
# - No new features
# - Only critical bug fixes

# Prepare App Store metadata
# - Screenshots finalized
# - Description proofread
# - Keywords optimized
```

**Release Day:**
```bash
# 1. Merge release branch
git checkout main
git merge release/1.0.0

# 2. Tag release
git tag v1.0.0
git push origin main --tags

# 3. Create archive in Xcode
# Product → Archive

# 4. Upload to App Store Connect
# Distribute → App Store Connect

# 5. Submit for review
# (or schedule release)

# 6. Create GitHub release
# https://github.com/yourusername/CardShowPro/releases/new
# - Tag: v1.0.0
# - Title: CardShow Pro 1.0.0 - Initial Release
# - Description: Changelog from CHANGELOG.md
```

**After Approval:**
```bash
# Option A: Automatic release (immediately after approval)
# Option B: Manual release (you control when it goes live)
# Option C: Scheduled release (specific date/time)

# Monitor:
# - App Store Connect → App Analytics
# - Crash reports
# - User reviews
# - Support emails
```

---

## Post-Release Monitoring

### Metrics to Track

**Day 1:**
- Downloads
- Crashes (should be <0.1%)
- User reviews (respond to all!)
- Support tickets

**Week 1:**
- Active users
- Retention (Day 1, Day 3, Day 7)
- Feature usage
- Conversion to paid (if applicable)

**Month 1:**
- Monthly Active Users (MAU)
- Churn rate
- Revenue (if subscription)
- Net Promoter Score

### Tools

**App Store Connect:**
- App Analytics (downloads, usage)
- Crash reports
- User reviews

**Third-Party (Optional):**
- Mixpanel, Amplitude (analytics)
- Crashlytics, Sentry (crash reporting)
- App Store review monitoring

### Hotfix Process

**If critical bug found:**

```bash
# 1. Create hotfix branch
git checkout -b hotfix/1.0.1 v1.0.0

# 2. Fix bug
# ... make changes ...

# 3. Test fix
# Run tests + manual verification

# 4. Bump version
# 1.0.0 → 1.0.1
# Build number: increment

# 5. Merge to main
git checkout main
git merge hotfix/1.0.1

# 6. Tag and release
git tag v1.0.1
git push origin main --tags

# 7. Submit to App Store
# Expedited review available for critical bugs

# 8. Update release notes
# "Bug Fixes: Fixed issue where..."
```

---

## Summary

**Key Takeaways:**

✅ **Use Automatic Signing** - Simplifies certificate management
✅ **TestFlight Beta Test** - 2-4 weeks with real users
✅ **Pre-Submission Checklist** - Avoid common rejections
✅ **Version Management** - Semantic versioning + build numbers
✅ **CI/CD Pipeline** - Automate builds and uploads
✅ **Monitor Post-Release** - Track crashes, reviews, metrics

**Timeline for First Release:**
- Week 1-2: Internal testing (team)
- Week 3-4: External beta (50-100 users)
- Week 5: Final polish and App Store submission
- Week 6: Approval and public release

**Estimated Time to App Store:** 5-6 weeks from code complete

---

*For deployment questions, contact the Engineering Team.*
