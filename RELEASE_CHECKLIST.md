# RELEASE_CHECKLIST.md - Pre-Release Verification

**Document Version**: 1.0
**Last Updated**: January 2026
**Purpose**: Comprehensive checklist for all CardShow Pro releases

---

## Overview

This checklist ensures every release meets quality, security, and compliance standards before reaching users. Complete ALL items before submitting to App Store.

**Checklist Responsibility**:
- **Engineering Lead**: Code quality, testing, security
- **QA Lead**: Test coverage, device testing, regression
- **Product Manager**: Feature completeness, user experience
- **Release Manager**: Submission, monitoring, rollback plan

---

## Table of Contents

1. [Pre-Release Planning](#pre-release-planning)
2. [Code Quality Checks](#code-quality-checks)
3. [Testing Verification](#testing-verification)
4. [Security Audit](#security-audit)
5. [App Store Requirements](#app-store-requirements)
6. [Marketing & Documentation](#marketing--documentation)
7. [Build & Archive](#build--archive)
8. [TestFlight Beta Testing](#testflight-beta-testing)
9. [Final Submission](#final-submission)
10. [Post-Release Monitoring](#post-release-monitoring)
11. [Rollback Plan](#rollback-plan)

---

## Pre-Release Planning

### Version Planning

- [ ] **Version number assigned** (follows semantic versioning: MAJOR.MINOR.PATCH)
  - Format: `1.0.0`, `1.1.0`, `1.0.1`
  - MAJOR: Breaking changes or major new features
  - MINOR: New features, backward compatible
  - PATCH: Bug fixes only

- [ ] **Build number incremented**
  - Format: Single integer (e.g., 1, 2, 3...)
  - Must be higher than previous TestFlight/App Store build

- [ ] **Release notes drafted**
  - What's new (user-facing features)
  - Bug fixes
  - Performance improvements
  - Known issues (if any)

- [ ] **Release timeline set**
  - Code freeze date
  - TestFlight submission date
  - Target App Store release date
  - Marketing announcement date

### Feature Completeness

- [ ] **All planned features implemented**
  - Reference: PRD.md feature list
  - Reference: ai/FEATURES.json

- [ ] **No placeholder content in production**
  - No "TODO" text visible to users
  - No lorem ipsum
  - No placeholder images

- [ ] **Feature flags configured**
  - Incomplete features disabled for production
  - Beta features marked appropriately

---

## Code Quality Checks

### Build Success

- [ ] **Clean build succeeds** (no warnings)
  ```bash
  xcodebuild clean build \
    -workspace CardShowPro.xcworkspace \
    -scheme CardShowPro \
    -configuration Release \
    -destination 'platform=iOS Simulator,name=iPhone 16' \
    | xcpretty
  ```

- [ ] **No compiler warnings**
  - Fix or suppress all warnings
  - Warnings = 0 in Release configuration

- [ ] **No force unwraps in critical paths**
  ```bash
  # Search for force unwraps (excluding comments)
  grep -r "!" CardShowProPackage/Sources --include="*.swift" \
    | grep -v "!=" \
    | grep -v "// " \
    | grep -v "/*"
  ```

- [ ] **Swift Concurrency checks pass** (strict mode)
  - No `@MainActor` violations
  - All `Sendable` conformances correct
  - No data races detected

### Code Review

- [ ] **All PRs reviewed and approved**
  - At least 1 reviewer per PR
  - All comments addressed

- [ ] **No commented-out code**
  - Remove dead code
  - Remove debug print statements

- [ ] **SwiftLint passes**
  ```bash
  swiftlint lint --strict
  ```

- [ ] **No hardcoded secrets**
  ```bash
  # Check for API keys, passwords, tokens
  git diff main | grep -iE "(api[_-]?key|secret|password|token)"
  ```

### Performance

- [ ] **App launch time < 3 seconds** (measured with Instruments)
- [ ] **Memory usage < 200 MB** (under normal use)
- [ ] **No memory leaks** (Instruments Leaks template)
- [ ] **Scroll performance > 60 FPS** (list with 1000+ items)

---

## Testing Verification

### Unit Tests

- [ ] **All unit tests pass**
  ```bash
  swift test --package-path CardShowProPackage
  ```

- [ ] **Test coverage ≥ 80%**
  ```bash
  swift test --enable-code-coverage --package-path CardShowProPackage
  xcrun llvm-cov report \
    .build/debug/CardShowProPackageTests.xctest/Contents/MacOS/CardShowProPackageTests \
    -instr-profile=.build/debug/codecov/default.profdata
  ```

- [ ] **No flaky tests**
  - Run test suite 10 times
  - All tests must pass all 10 times

- [ ] **Critical business logic tested**
  - Price calculations
  - Profit margin calculations
  - Platform fee calculations
  - Trade analyzer logic

### Integration Tests

- [ ] **API integration tests pass**
  - PokemonTCG.io: Card search, pricing
  - TCGDex: Pricing data
  - Graceful degradation when APIs unavailable

- [ ] **SwiftData CRUD operations tested**
  - Create: Add cards to inventory
  - Read: Fetch and query cards
  - Update: Edit card details
  - Delete: Remove cards

- [ ] **Cache functionality tested**
  - Price cache expiration (24 hours)
  - Cache hit/miss scenarios
  - Cache clearing

### UI Tests

- [ ] **Critical user flows tested**
  - ✅ Price lookup (camera + manual search)
  - ✅ Add card to inventory
  - ✅ Record sale
  - ✅ Analyze trade
  - ✅ Vendor mode (Pro users)
  - ✅ CRM operations (Pro users)

- [ ] **Navigation tested**
  - All tabs accessible
  - Deep linking works
  - Back navigation doesn't crash
  - NavigationStack state management correct

- [ ] **Error states tested**
  - No internet connection
  - API rate limit exceeded
  - Invalid user input
  - Empty states (no inventory, no sales, etc.)

### Device Testing

- [ ] **Tested on all supported devices**
  - ✅ iPhone SE (3rd gen) - smallest screen
  - ✅ iPhone 16 - standard size
  - ✅ iPhone 16 Plus - large screen
  - ✅ iPhone 16 Pro Max - largest screen
  - ✅ iPad (10th gen) - tablet
  - ✅ iPad Pro 12.9" - largest tablet

- [ ] **Tested on iOS versions**
  - ✅ iOS 17.0 (minimum supported)
  - ✅ iOS 17.4 (current major version)
  - ✅ iOS 18.0 (latest, if available)

- [ ] **Orientation tested** (iPad)
  - Portrait mode
  - Landscape mode
  - Split view / Slide Over

### Regression Testing

- [ ] **Previous bugs verified fixed**
  - Check GitHub Issues marked "closed"
  - Re-test all previously reported bugs

- [ ] **No new regressions introduced**
  - Core features still work
  - Existing UI flows unchanged (unless intentional)

---

## Security Audit

### Code Security

- [ ] **Security checklist completed** (from SECURITY.md)
  - No hardcoded API keys
  - No sensitive data logged
  - All user inputs validated
  - All API calls use HTTPS
  - Error messages don't expose internals

- [ ] **Keychain used for sensitive data**
  - API keys stored in Keychain
  - No credentials in UserDefaults
  - No credentials in plaintext files

- [ ] **Data protection enabled**
  - SwiftData uses device encryption
  - Files use `.completeFileProtection`

### Privacy Compliance

- [ ] **Privacy Policy URL set**
  - App Store Connect → App Information → Privacy Policy URL
  - URL: `https://cardshowpro.com/privacy`
  - Privacy policy document complete and accurate

- [ ] **Info.plist privacy strings present**
  ```xml
  <key>NSCameraUsageDescription</key>
  <string>CardShow Pro uses your camera to scan trading cards.</string>

  <key>NSPhotoLibraryUsageDescription</key>
  <string>Access photos to analyze card images.</string>
  ```

- [ ] **App Privacy labels accurate** (App Store Connect)
  - Data types collected: ✅ Documented
  - Data usage purposes: ✅ Documented
  - Data linked to user: ✅ Documented
  - Data used for tracking: ✅ Documented

- [ ] **GDPR/CCPA compliance verified**
  - User can export data
  - User can delete account
  - Data retention policy documented
  - No tracking without consent

### Dependency Security

- [ ] **All dependencies up to date**
  ```bash
  swift package update
  ```

- [ ] **No known vulnerabilities in dependencies**
  - Check GitHub Security Advisories
  - Review Package.swift dependencies

- [ ] **Dependencies pinned to specific versions**
  ```swift
  // ✅ Good
  .package(url: "...", exact: "4.35.0")

  // ❌ Bad
  .package(url: "...", from: "4.0.0")
  ```

---

## App Store Requirements

### App Store Connect Configuration

- [ ] **App name finalized**
  - Max 30 characters
  - Name: "CardShow Pro - Card Business"

- [ ] **Subtitle set**
  - Max 30 characters
  - Subtitle: "Manage Your Card Business"

- [ ] **Keywords optimized**
  - Max 100 characters
  - Keywords: "pokemon,card,trading,tcg,business,inventory,seller,vendor,pricing,profit,analytics"

- [ ] **Description complete**
  - Compelling, accurate description
  - Key features listed
  - No placeholder text

- [ ] **Screenshots uploaded**
  - ✅ 6.9" Display (iPhone 16 Pro Max) - Required
  - ✅ 6.7" Display (iPhone 16 Plus) - Falls back to 6.9"
  - ✅ 5.5" Display (iPhone 8 Plus) - Falls back to larger
  - ✅ iPad Pro (12.9") - Required for iPad support

- [ ] **App Preview videos uploaded** (optional but recommended)
  - 15-30 second video showing key features
  - Formatted for each device size

- [ ] **App icon set**
  - 1024×1024 PNG (no alpha channel)
  - Meets design guidelines

- [ ] **Support URL set**
  - URL: `https://cardshowpro.com/support`

- [ ] **Marketing URL set** (optional)
  - URL: `https://cardshowpro.com`

### Metadata Review

- [ ] **Copyright year correct**
  - Format: "2026 CardShow Pro LLC"

- [ ] **Age rating set**
  - Likely: 4+ (no objectionable content)
  - Complete questionnaire in App Store Connect

- [ ] **Category selected**
  - Primary: Business
  - Secondary: Productivity

- [ ] **Pricing & availability configured**
  - Free with in-app purchase (subscription)
  - Available in all territories (or select specific countries)

### In-App Purchases

- [ ] **Subscription created in App Store Connect**
  - Product ID: `com.cardshowpro.app.subscription.pro.monthly`
  - Display Name: "CardShow Pro Subscription"
  - Price: $9.99/month
  - Free trial: 14 days

- [ ] **Subscription group configured**
  - Group name: "CardShow Pro Subscriptions"
  - Only one subscription per group (monthly for now)

- [ ] **Subscription tested in sandbox**
  - Test account created (Settings → App Store Connect → Sandbox)
  - Purchase flow works
  - Restore purchases works
  - Cancellation works

### Legal

- [ ] **Terms of Service URL provided**
  - URL: `https://cardshowpro.com/terms`
  - Terms document complete

- [ ] **Privacy Policy URL provided**
  - URL: `https://cardshowpro.com/privacy`
  - Privacy document complete

- [ ] **EULA reviewed** (use Apple's standard EULA or custom)

---

## Marketing & Documentation

### User-Facing Documentation

- [ ] **USER_GUIDE.md complete and accurate**
  - All features documented
  - Screenshots updated (if UI changed)

- [ ] **FAQ updated**
  - Common questions answered
  - Troubleshooting tips included

- [ ] **Onboarding flow tested**
  - First-time user experience smooth
  - Permissions requested appropriately
  - Value proposition clear

### Marketing Materials

- [ ] **Landing page live**
  - URL: `https://cardshowpro.com`
  - Features, pricing, screenshots

- [ ] **Social media prepared**
  - Twitter/X announcement drafted
  - Instagram post designed
  - Facebook post scheduled

- [ ] **Press kit prepared** (if applicable)
  - App icon (various sizes)
  - Screenshots
  - Fact sheet
  - Press release

### Internal Documentation

- [ ] **DEPLOYMENT.md updated** with latest process
- [ ] **TROUBLESHOOTING.md updated** with new known issues
- [ ] **CHANGELOG.md updated** with release notes

---

## Build & Archive

### Pre-Build Checks

- [ ] **Version number updated**
  - Xcode → Target → General → Version: `1.0.0`
  - Xcode → Target → General → Build: `1`

- [ ] **Configuration set to Release**
  - Product → Scheme → Edit Scheme → Run → Build Configuration: Release

- [ ] **Signing configured**
  - Xcode → Target → Signing & Capabilities
  - Team selected
  - Provisioning profile: Automatic or manual (App Store profile)
  - "Automatically manage signing" checked (recommended)

- [ ] **Bitcode enabled** (if applicable)
  - Build Settings → Enable Bitcode: Yes

- [ ] **Debug symbols stripped**
  - Build Settings → Strip Debug Symbols During Copy: Yes (Release only)

### Archive

- [ ] **Archive created successfully**
  ```bash
  xcodebuild archive \
    -workspace CardShowPro.xcworkspace \
    -scheme CardShowPro \
    -configuration Release \
    -archivePath ./build/CardShowPro.xcarchive
  ```

- [ ] **Archive validated**
  - Xcode → Window → Organizer → Archives
  - Select archive → Validate App
  - All validations pass (no errors or warnings)

- [ ] **App size acceptable**
  - Download size < 100 MB (aim for <50 MB)
  - Install size < 200 MB

### Upload to App Store Connect

- [ ] **Uploaded successfully**
  - Xcode → Organizer → Distribute App → App Store Connect
  - Upload completes without errors

- [ ] **Processing complete**
  - App Store Connect → TestFlight
  - Build shows "Ready to Submit" (not "Processing")
  - May take 15 minutes to 2 hours

- [ ] **No compliance issues**
  - Export Compliance: Answer questions about encryption
  - Usually "No" for standard HTTPS usage

---

## TestFlight Beta Testing

### Internal Testing

- [ ] **Internal testers invited**
  - Add team members as internal testers
  - App Store Connect → TestFlight → Internal Testing

- [ ] **Internal build distributed**
  - Share build with internal testers
  - Testers receive TestFlight invitation

- [ ] **Internal testing complete** (24-48 hours)
  - [ ] App launches successfully
  - [ ] Critical features work
  - [ ] No crashes in normal use
  - [ ] Feedback collected and addressed

### External Testing (Optional for V1)

- [ ] **External testers invited**
  - Add beta users (up to 10,000)
  - TestFlight → External Testing

- [ ] **Beta review submitted**
  - Provide test information for Apple review
  - Usually approved within 24 hours

- [ ] **External testing complete** (3-7 days)
  - [ ] Diverse device testing
  - [ ] User feedback collected
  - [ ] Critical bugs fixed
  - [ ] New build uploaded if needed

### Beta Feedback Review

- [ ] **All crashes investigated**
  - TestFlight → Crashes → Review all crash logs
  - Fix critical crashes before release

- [ ] **User feedback reviewed**
  - TestFlight → Feedback → Read all feedback
  - Prioritize issues for immediate fix vs future release

- [ ] **Performance metrics reviewed**
  - Battery usage acceptable
  - Network usage acceptable
  - Storage usage acceptable

---

## Final Submission

### Pre-Submission Checklist

- [ ] **All previous sections complete**
  - Code quality ✅
  - Testing ✅
  - Security ✅
  - App Store requirements ✅
  - TestFlight ✅

- [ ] **Final build uploaded**
  - Latest build in App Store Connect
  - Build number matches release plan

- [ ] **App Store Connect listing finalized**
  - All metadata complete
  - Screenshots current
  - Description accurate
  - No placeholder content

### Submit for Review

- [ ] **Version submitted for review**
  - App Store Connect → App Store → Prepare for Submission
  - Fill out all required fields:
    - [ ] Export compliance information
    - [ ] Content rights information
    - [ ] Advertising identifier (IDFA) usage
    - [ ] Version release preference (manual vs automatic)
  - Click "Submit for Review"

- [ ] **Submission confirmation received**
  - Email from Apple confirming submission
  - Status: "Waiting for Review"

### Review Process

- [ ] **Status monitored**
  - "Waiting for Review" → typically 1-3 days
  - "In Review" → typically 12-48 hours
  - "Pending Developer Release" or "Ready for Sale"

- [ ] **Respond to Apple questions quickly**
  - If Apple contacts, respond within 24 hours
  - Provide requested information or clarifications

### Rejection Handling (If Applicable)

- [ ] **Review rejection reason**
  - Read rejection message carefully
  - Reference guideline violated

- [ ] **Fix issues**
  - Address all concerns
  - Update build if necessary

- [ ] **Provide explanation**
  - Resolution Center → Reply to Apple
  - Explain fixes made

- [ ] **Resubmit**
  - Submit for review again

---

## Post-Release Monitoring

### Launch Day (Day 0)

- [ ] **App appears on App Store**
  - Search for "CardShow Pro" on App Store
  - Verify listing looks correct

- [ ] **Test App Store download**
  - Download from App Store (not TestFlight)
  - Verify app launches and works

- [ ] **Monitor crash reports** (first 24 hours)
  - App Store Connect → Analytics → Crashes
  - Investigate any crashes immediately

- [ ] **Monitor reviews** (first 24 hours)
  - App Store → Ratings & Reviews
  - Respond to negative reviews promptly

- [ ] **Check analytics**
  - Downloads: How many downloads?
  - Sessions: Are users opening the app?
  - Crashes: Any crash trends?

### Week 1 Monitoring

- [ ] **Daily crash monitoring**
  - Review crash logs daily
  - Hot-fix critical crashes within 48 hours

- [ ] **Daily review monitoring**
  - Respond to all 1-3 star reviews
  - Thank users for 4-5 star reviews

- [ ] **Performance metrics**
  - Track daily active users (DAU)
  - Track retention (Day 1, Day 7)
  - Track subscription conversions

- [ ] **Server/API monitoring** (if applicable)
  - Monitor API usage
  - Verify no rate limit issues
  - Check for abuse/excessive usage

### Week 2-4 Monitoring

- [ ] **Weekly crash review**
  - Prioritize crashes by volume
  - Plan fixes for next patch release

- [ ] **Weekly review review**
  - Aggregate common feedback themes
  - Plan feature improvements

- [ ] **Analytics review**
  - Which features are used most?
  - Where do users drop off?
  - Subscription conversion rate?

### Hotfix Criteria

Release emergency hotfix (v1.0.1) if:
- [ ] Crash rate > 1% of sessions
- [ ] Critical feature completely broken
- [ ] Data loss occurring
- [ ] Security vulnerability discovered
- [ ] App rejected by Apple after initial approval (rare)

**Hotfix Process**:
1. Create branch from release tag
2. Fix critical issue
3. Increment PATCH version (e.g., 1.0.0 → 1.0.1)
4. Fast-track through testing
5. Submit as urgent to Apple (request expedited review)

---

## Rollback Plan

### When to Rollback

Rollback if:
- [ ] Critical crash affecting >10% of users
- [ ] Data corruption discovered
- [ ] Security breach exploited
- [ ] Complete feature failure

### Rollback Options

**Option 1: Pull from App Store (Nuclear)**
- App Store Connect → Remove from Sale
- Not recommended (users already downloaded can't get updates)

**Option 2: Release Previous Version**
- Upload previous stable build with new version number
- Submit as "urgent bug fix"
- Users auto-update to stable version

**Option 3: Disable Broken Feature**
- Use remote config / feature flags to disable broken feature
- Keep app available, turn off broken parts
- Requires backend infrastructure (V2 feature)

### Rollback Procedure

1. [ ] **Assess severity**
   - How many users affected?
   - Is data at risk?
   - Can it be fixed with hotfix?

2. [ ] **Notify stakeholders**
   - Engineering team
   - Product team
   - Support team

3. [ ] **Prepare rollback build**
   - Checkout previous stable tag (e.g., `v0.9.0`)
   - Increment version number (e.g., `1.0.1`)
   - Archive and upload

4. [ ] **Submit with explanation**
   - "Critical bug fix - reverting to stable version"
   - Request expedited review

5. [ ] **Monitor rollback**
   - Verify users update to rolled-back version
   - Confirm issue is resolved

6. [ ] **Post-mortem**
   - Document what went wrong
   - Identify gaps in testing
   - Update checklist to prevent recurrence

---

## Sign-Off

Before submitting to App Store, all stakeholders must sign off:

- [ ] **Engineering Lead**: Code quality and testing verified
  - Name: ________________
  - Date: ________________

- [ ] **QA Lead**: All tests passed, no critical bugs
  - Name: ________________
  - Date: ________________

- [ ] **Product Manager**: Features complete, user experience validated
  - Name: ________________
  - Date: ________________

- [ ] **Security Officer**: Security audit complete, no vulnerabilities
  - Name: ________________
  - Date: ________________

- [ ] **Release Manager**: Ready for App Store submission
  - Name: ________________
  - Date: ________________

---

## Release Retrospective

After release (within 2 weeks), conduct retrospective:

### What Went Well?
-

### What Could Be Improved?
-

### Action Items for Next Release
-

---

## Appendix: Quick Reference

### Version Numbers

```
MAJOR.MINOR.PATCH

1.0.0 - Initial release
1.0.1 - Hotfix (bug fixes only)
1.1.0 - Minor update (new features)
2.0.0 - Major update (breaking changes)
```

### Build Numbers

Always increment:
```
1 → 2 → 3 → 4 ...
```

### Release Timelines

**Typical Release Schedule**:
- Code freeze: Friday
- TestFlight upload: Monday
- Internal testing: Monday-Wednesday
- Submit for review: Thursday
- Review time: 1-3 days (Fri-Tue)
- Release: Following Tuesday

**Total time**: ~2 weeks from code freeze to release

### Useful Commands

```bash
# Clean build
rm -rf ~/Library/Developer/Xcode/DerivedData

# Build for release
xcodebuild build -workspace CardShowPro.xcworkspace \
  -scheme CardShowPro -configuration Release

# Run tests
swift test --package-path CardShowProPackage

# Archive
xcodebuild archive -workspace CardShowPro.xcworkspace \
  -scheme CardShowPro -archivePath ./build/CardShowPro.xcarchive

# Check version
agvtool what-version
agvtool what-marketing-version
```

---

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | January 2026 | Initial release checklist for V1.0 |

---

**Remember**: This checklist is comprehensive for a reason. Skipping steps leads to App Store rejections, poor reviews, and user frustration. Take the time to do it right!

**Good luck with your release! 🚀**
