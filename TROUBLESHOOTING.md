# TROUBLESHOOTING.md - Common Issues & Solutions

**Document Version**: 1.0
**Last Updated**: January 2026
**Target Audience**: Developers and Technical Support

---

## Table of Contents

1. [Quick Diagnostics](#quick-diagnostics)
2. [Build & Compilation Issues](#build--compilation-issues)
3. [Runtime Crashes](#runtime-crashes)
4. [API & Network Issues](#api--network-issues)
5. [SwiftData & Persistence Issues](#swiftdata--persistence-issues)
6. [UI & SwiftUI Issues](#ui--swiftui-issues)
7. [Camera & Image Issues](#camera--image-issues)
8. [Performance Issues](#performance-issues)
9. [Simulator Issues](#simulator-issues)
10. [TestFlight & App Store Issues](#testflight--app-store-issues)
11. [User-Reported Issues](#user-reported-issues)
12. [Known Bugs & Workarounds](#known-bugs--workarounds)

---

## Quick Diagnostics

### First Steps for Any Issue

Before diving into specific troubleshooting:

1. **Check iOS Version**: Ensure device is running iOS 17.0+
2. **Check App Version**: Confirm user is on latest version
3. **Restart App**: Force quit and relaunch
4. **Restart Device**: Power cycle the device
5. **Check Console Logs**: Review Xcode console for error messages
6. **Check Network**: Verify internet connection is working

### Common Quick Fixes

| Issue | Quick Fix |
|-------|-----------|
| App won't launch | Delete and reinstall |
| UI not updating | Pull to refresh or restart app |
| Prices not loading | Check internet connection |
| Camera not working | Grant camera permissions in Settings |
| Data missing | Check if iCloud sync is enabled (if applicable) |
| Slow performance | Clear cache in Settings |

---

## Build & Compilation Issues

### Issue: "Build Failed - Swift Compiler Error"

**Symptoms**:
```
Command CompileSwift failed with a nonzero exit code
```

**Causes**:
1. Swift 6 strict concurrency violations
2. Missing Sendable conformances
3. Syntax errors introduced in recent changes

**Solutions**:

```bash
# 1. Clean build folder
rm -rf ~/Library/Developer/Xcode/DerivedData/CardShowPro-*

# 2. Clean in Xcode
# Product → Clean Build Folder (Cmd+Shift+K)

# 3. Rebuild
xcodebuild build -workspace CardShowPro.xcworkspace \
  -scheme CardShowPro \
  -destination 'platform=iOS Simulator,name=iPhone 16'
```

If errors persist, check for:

**Missing Sendable Conformances**:
```swift
// ❌ Error: Type 'MyModel' does not conform to the 'Sendable' protocol
@Observable
final class MyModel {
    var data: [String] = []
}

// ✅ Fix: Add Sendable conformance
@Observable
final class MyModel: Sendable {
    var data: [String] = []
}
```

**@MainActor Violations**:
```swift
// ❌ Error: Call to main actor-isolated property 'cards' in a synchronous nonisolated context
func updateCards() {
    viewModel.cards = []  // Error if viewModel is @MainActor
}

// ✅ Fix: Make function @MainActor or use Task
@MainActor
func updateCards() {
    viewModel.cards = []
}
```

---

### Issue: "Package Resolution Failed"

**Symptoms**:
```
error: Dependencies could not be resolved because no versions of
'CardShowProPackage' match the requirement 1.0.0
```

**Causes**:
- SPM cache corruption
- Package.swift version mismatch
- Network issues during package resolution

**Solutions**:

```bash
# 1. Reset package cache
rm -rf ~/Library/Caches/org.swift.swiftpm
rm -rf ~/Library/Developer/Xcode/DerivedData

# 2. In Xcode: File → Packages → Reset Package Caches

# 3. Update packages
# File → Packages → Update to Latest Package Versions

# 4. Manually resolve
cd CardShowProPackage
swift package resolve
swift package update
```

If still failing, check `Package.swift`:

```swift
// Ensure platforms are set correctly
platforms: [
    .iOS(.v17)  // Not .iOS("17.0")
]
```

---

### Issue: "Code Signing Failed"

**Symptoms**:
```
error: Signing for "CardShowPro" requires a development team.
```

**Causes**:
- No development team selected in Xcode
- Certificate expired
- Provisioning profile issues

**Solutions**:

**For Development**:
1. Xcode → CardShowPro (target) → Signing & Capabilities
2. Select your Team from dropdown
3. Enable "Automatically manage signing"
4. Xcode will create a dev certificate and profile

**For App Store**:
```bash
# Check certificate expiration
security find-identity -v -p codesigning

# Should show:
# 1) ABC123... "Apple Distribution: Your Name (TEAM_ID)"
#    Valid until: Dec 31, 2025
```

If expired, renew at:
https://developer.apple.com/account/resources/certificates

---

### Issue: "Entitlements Issue"

**Symptoms**:
```
error: Entitlements file "CardShowPro.entitlements" could not be found.
```

**Causes**:
- Entitlements file path incorrect in XCConfig
- File deleted or moved

**Solutions**:

```bash
# 1. Verify file exists
ls -la Config/CardShowPro.entitlements

# 2. Check XCConfig path
cat Config/Shared.xcconfig | grep CODE_SIGN_ENTITLEMENTS

# Should show:
# CODE_SIGN_ENTITLEMENTS = $(SRCROOT)/Config/CardShowPro.entitlements

# 3. If missing, create it
cat > Config/CardShowPro.entitlements << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <!-- Add entitlements here -->
</dict>
</plist>
EOF
```

---

## Runtime Crashes

### Issue: "App Crashes on Launch"

**Symptoms**:
- App icon appears then immediately closes
- Crash log shows `SIGABRT` or `EXC_BAD_ACCESS`

**Common Causes & Fixes**:

**1. SwiftData Model Migration Issue**

```
Thread 1: Fatal error: failed to find a currently active container for...
```

**Fix**: Delete app and reinstall (clears old data model):

```bash
# For simulator
xcrun simctl uninstall booted com.cardshowpro.app
xcrun simctl install booted /path/to/CardShowPro.app
```

**2. Missing Environment Dependency**

```swift
// ❌ Crash if service not provided via .environment()
@Environment(PricingService.self) private var pricing

// ✅ Fix: Ensure service is provided in parent view
.environment(PricingService())
```

**3. Force Unwrap of Nil**

```
Thread 1: Fatal error: Unexpectedly found nil while unwrapping an Optional value
```

**Fix**: Find and replace force unwraps with safe unwraps:

```bash
# Search for force unwraps
grep -r "!" CardShowProPackage/Sources --include="*.swift" | grep -v "!=" | grep -v "// !"
```

---

### Issue: "Crash When Accessing Camera"

**Symptoms**:
```
[access] This app has crashed because it attempted to access privacy-sensitive data
without a usage description.
```

**Cause**: Missing `NSCameraUsageDescription` in Info.plist

**Fix**:

```xml
<!-- CardShowPro/Info.plist -->
<key>NSCameraUsageDescription</key>
<string>CardShow Pro uses your camera to scan trading cards for quick price lookups and inventory management.</string>
```

Rebuild and run. Same applies to:
- `NSPhotoLibraryUsageDescription`
- `NSPhotoLibraryAddUsageDescription`

---

### Issue: "SwiftData 'model container not found' Crash"

**Symptoms**:
```
Thread 1: Fatal error: failed to find a currently active container for ModelContext
```

**Cause**: `.modelContainer()` modifier missing or placed incorrectly

**Fix**:

```swift
// ✅ Correct placement - at app root
@main
struct CardShowProApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(for: [
                    InventoryCard.self,
                    SalesHistory.self,
                    TradeHistory.self
                ])
        }
    }
}

// ❌ Wrong - don't place on nested views
struct ContentView: View {
    var body: some View {
        NavigationStack {
            DashboardView()
                .modelContainer(...)  // ❌ Too late
        }
    }
}
```

---

## API & Network Issues

### Issue: "API Requests Timing Out"

**Symptoms**:
- Price lookups never complete
- Loading spinner runs indefinitely
- Console shows `URLSession timeout`

**Diagnosis**:

```bash
# Test API endpoint manually
curl -I https://api.pokemontcg.io/v2/cards

# Should return:
# HTTP/2 200
# If not, API may be down
```

**Solutions**:

**1. Check Network Reachability**:

```swift
import Network

actor NetworkMonitor {
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")

    var isConnected: Bool {
        monitor.currentPath.status == .satisfied
    }

    func startMonitoring() {
        monitor.start(queue: queue)
    }
}
```

**2. Increase Timeout**:

```swift
// Default timeout might be too short
let configuration = URLSessionConfiguration.default
configuration.timeoutIntervalForRequest = 30  // 30 seconds
configuration.timeoutIntervalForResource = 60  // 1 minute

let session = URLSession(configuration: configuration)
```

**3. Implement Retry Logic**:

```swift
func fetchWithRetry<T>(
    maxAttempts: Int = 3,
    request: @Sendable () async throws -> T
) async throws -> T {
    var lastError: Error?

    for attempt in 1...maxAttempts {
        do {
            return try await request()
        } catch {
            lastError = error
            if attempt < maxAttempts {
                try await Task.sleep(for: .seconds(2 * attempt))  // Exponential backoff
            }
        }
    }

    throw lastError!
}
```

---

### Issue: "API Returns 401 Unauthorized"

**Symptoms**:
```
Error: The operation couldn't be completed. (HTTP 401)
```

**Causes**:
1. API key missing or invalid
2. API key not included in request headers
3. API key expired

**Solutions**:

**1. Verify API Key is Set**:

```swift
let keychain = KeychainManager()
do {
    let apiKey = try await keychain.retrieve(key: "pokemontcg_api_key")
    print("API Key found: \(String(apiKey.prefix(8)))...")  // Print first 8 chars only
} catch {
    print("API Key not found: \(error)")
}
```

**2. Verify Headers**:

```swift
var request = URLRequest(url: url)
request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

// Log request (dev only)
#if DEBUG
print("Request URL: \(request.url!)")
print("Headers: \(request.allHTTPHeaderFields ?? [:])")
#endif
```

**3. Test API Key Manually**:

```bash
# Test with curl
curl -H "Authorization: Bearer YOUR_API_KEY" \
  https://api.pokemontcg.io/v2/cards?q=name:charizard

# If this returns 401, API key is invalid
```

---

### Issue: "Rate Limit Exceeded"

**Symptoms**:
```
HTTP 429 Too Many Requests
```

**Causes**:
- Exceeded API rate limit (e.g., 20,000 requests/day for PokemonTCG.io)
- Rapid-fire requests without throttling

**Solutions**:

**1. Implement Request Throttling**:

```swift
actor RequestThrottler {
    private var lastRequestTime: Date?
    private let minimumInterval: TimeInterval = 0.1  // 100ms between requests

    func throttle() async {
        if let last = lastRequestTime {
            let elapsed = Date().timeIntervalSince(last)
            if elapsed < minimumInterval {
                try? await Task.sleep(for: .seconds(minimumInterval - elapsed))
            }
        }
        lastRequestTime = Date()
    }
}

// Usage
await throttler.throttle()
let data = try await fetchData()
```

**2. Cache Aggressively**:

```swift
// Check cache first, only fetch if needed
if let cached = await cache.get(cardId: id) {
    return cached
}

// Cache has 24-hour expiration built in (see PriceCacheRepository)
```

**3. Handle 429 Gracefully**:

```swift
func handleAPIError(_ error: Error) -> APIError {
    if let urlError = error as? URLError,
       urlError.code == .badServerResponse {
        // Check if 429
        return .rateLimitExceeded
    }
    return .networkError
}

// Show user-friendly message
enum APIError: LocalizedError {
    case rateLimitExceeded

    var errorDescription: String? {
        switch self {
        case .rateLimitExceeded:
            return "Too many requests. Please try again in a few minutes."
        }
    }
}
```

---

### Issue: "JSON Decoding Failed"

**Symptoms**:
```
DecodingError: keyNotFound / typeMismatch
```

**Causes**:
- API response schema changed
- Malformed JSON from API
- Wrong Codable model definition

**Solutions**:

**1. Log Raw Response**:

```swift
#if DEBUG
if let jsonString = String(data: data, encoding: .utf8) {
    print("Raw JSON: \(jsonString)")
}
#endif

// Then attempt decode
let decoded = try JSONDecoder().decode(CardResponse.self, from: data)
```

**2. Use Optional Properties**:

```swift
// ❌ Fragile - crashes if API omits field
struct Card: Codable {
    let name: String
    let rarity: String  // Crash if API doesn't include rarity
}

// ✅ Resilient - handles missing fields
struct Card: Codable {
    let name: String
    let rarity: String?  // Optional - won't crash if missing
}
```

**3. Implement Fallback Decoding**:

```swift
do {
    return try JSONDecoder().decode(CardResponse.self, from: data)
} catch {
    // Log the error
    Logger.api.error("Decode failed: \(error)")

    // Try alternate model
    if let fallback = try? JSONDecoder().decode(CardResponseV2.self, from: data) {
        return convertV2ToV1(fallback)
    }

    throw error
}
```

---

## SwiftData & Persistence Issues

### Issue: "Data Not Saving"

**Symptoms**:
- User adds cards but they disappear after restart
- Changes to inventory don't persist

**Causes**:
1. `context.save()` never called
2. Model container not configured
3. Simulator/device storage full

**Solutions**:

**1. Explicit Save**:

```swift
@Environment(\.modelContext) private var context

func addCard(_ card: InventoryCard) {
    context.insert(card)

    // Save immediately
    do {
        try context.save()
    } catch {
        print("Save failed: \(error)")
    }
}
```

**2. Auto-Save on Background**:

```swift
.onReceive(NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)) { _ in
    try? context.save()
}
```

**3. Check Storage**:

```bash
# On simulator
xcrun simctl get_app_container booted com.cardshowpro.app data

# Navigate to that path and check disk usage
du -sh /path/to/container/Library/Application\ Support
```

---

### Issue: "Query Returns Empty Results"

**Symptoms**:
```swift
@Query private var cards: [InventoryCard]
// cards.count is 0 even after adding data
```

**Causes**:
- Predicate filtering out all results
- Model container not shared across views
- Data in different container instance

**Solutions**:

**1. Verify Predicate**:

```swift
// ❌ Too restrictive - might exclude all cards
@Query(filter: #Predicate<InventoryCard> { card in
    card.name.contains("Charizard") && card.setName == "Base Set"
})
var cards: [InventoryCard]

// ✅ Start with no filter, add later
@Query var cards: [InventoryCard]
```

**2. Check Model Container Scope**:

```swift
// ✅ Container at root
@main
struct CardShowProApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(for: InventoryCard.self)  // ✅ Shared across all views
        }
    }
}
```

**3. Manual Fetch to Debug**:

```swift
@Environment(\.modelContext) private var context

func debugFetch() {
    let descriptor = FetchDescriptor<InventoryCard>()
    let results = try? context.fetch(descriptor)
    print("Total cards in DB: \(results?.count ?? 0)")
}
```

---

### Issue: "Migration Failed - Data Loss"

**Symptoms**:
```
Thread 1: Fatal error: Unable to create ModelContainer: ...migration required
```

**Causes**:
- Changed SwiftData model schema without versioning
- Added/removed properties on @Model class
- Changed property types

**Solutions**:

**1. Lightweight Migration (For Simple Changes)**:

SwiftData handles this automatically IF changes are additive:
- ✅ Adding optional properties
- ✅ Adding new models
- ❌ Removing properties (data loss)
- ❌ Changing property types (crash)

**2. Schema Versioning (For Breaking Changes)**:

```swift
import SwiftData

enum SchemaV1: VersionedSchema {
    static var versionIdentifier = Schema.Version(1, 0, 0)

    static var models: [any PersistentModel.Type] {
        [InventoryCard.self]
    }

    @Model
    final class InventoryCard {
        var name: String
        var marketValue: Double

        init(name: String, marketValue: Double) {
            self.name = name
            self.marketValue = marketValue
        }
    }
}

enum SchemaV2: VersionedSchema {
    static var versionIdentifier = Schema.Version(2, 0, 0)

    static var models: [any PersistentModel.Type] {
        [InventoryCard.self]
    }

    @Model
    final class InventoryCard {
        var name: String
        var marketValue: Double
        var purchaseCost: Double?  // Added in V2

        init(name: String, marketValue: Double, purchaseCost: Double? = nil) {
            self.name = name
            self.marketValue = marketValue
            self.purchaseCost = purchaseCost
        }
    }
}

// Migration plan
let migrationPlan = SchemaMigrationPlan(
    schemas: [SchemaV1.self, SchemaV2.self],
    stages: [
        MigrationStage.lightweight(fromVersion: SchemaV1.self, toVersion: SchemaV2.self)
    ]
)

// Use in app
.modelContainer(for: InventoryCard.self, migrationPlan: migrationPlan)
```

**3. Nuclear Option (Dev Only)**:

```bash
# Delete app data and start fresh (LOSES ALL USER DATA)
xcrun simctl uninstall booted com.cardshowpro.app
```

---

## UI & SwiftUI Issues

### Issue: "View Not Updating"

**Symptoms**:
- Data changes but UI doesn't reflect it
- Need to force quit app to see changes

**Causes**:
1. Missing `@Observable` macro
2. Updating state from background thread
3. Not using `@State` or `@Environment` correctly

**Solutions**:

**1. Ensure @Observable is Used**:

```swift
// ❌ Won't trigger UI updates
class MyModel {
    var count = 0
}

// ✅ Triggers UI updates
@Observable
final class MyModel {
    var count = 0
}
```

**2. Update on Main Thread**:

```swift
// ❌ Updates from background thread - UI won't update
Task {
    let data = await fetchData()
    self.cards = data  // ❌ Off main thread
}

// ✅ Ensure main thread updates
Task {
    let data = await fetchData()
    await MainActor.run {
        self.cards = data  // ✅ On main thread
    }
}

// Or mark class @MainActor
@Observable
@MainActor
final class MyViewModel {
    var cards: [Card] = []

    func load() async {
        cards = await fetchData()  // ✅ Already on main thread
    }
}
```

**3. Use Correct State Wrapper**:

```swift
// For local view state
@State private var isLoading = false

// For observable objects
@State private var viewModel = MyViewModel()

// For environment dependencies
@Environment(MyService.self) private var service

// For passing state down
@Binding var selectedCard: Card?
```

---

### Issue: "NavigationStack Crashes"

**Symptoms**:
```
Thread 1: Fatal error: Failed to construct NavigationPath
```

**Causes**:
- Non-hashable types in navigation path
- Circular navigation

**Solutions**:

**1. Ensure Hashable Conformance**:

```swift
// ❌ Crash - InventoryCard not Hashable
NavigationLink(value: card) {
    Text(card.name)
}

// ✅ Fix - Add Hashable
@Model
final class InventoryCard: Hashable {
    // SwiftData models are automatically Hashable via @Model
}
```

**2. Use Stable Navigation**:

```swift
// ✅ Type-safe navigation
struct ContentView: View {
    @State private var path = NavigationPath()

    var body: some View {
        NavigationStack(path: $path) {
            List(cards) { card in
                NavigationLink(value: card) {
                    CardRow(card: card)
                }
            }
            .navigationDestination(for: InventoryCard.self) { card in
                CardDetailView(card: card)
            }
        }
    }
}
```

---

### Issue: "List Performance Degraded"

**Symptoms**:
- Scrolling is janky/stuttering
- List takes long time to load
- App freezes when displaying large lists

**Solutions**:

**1. Use LazyVStack Instead of List**:

```swift
// ❌ Renders all 10,000 cards upfront
ScrollView {
    VStack {
        ForEach(cards) { card in
            CardRow(card: card)
        }
    }
}

// ✅ Only renders visible cards
ScrollView {
    LazyVStack {
        ForEach(cards) { card in
            CardRow(card: card)
        }
    }
}
```

**2. Implement Pagination**:

```swift
@Query(sort: \InventoryCard.name, limit: 50)
private var firstBatch: [InventoryCard]

// Load more when user scrolls to bottom
```

**3. Optimize Row Views**:

```swift
// ❌ Heavy row - lots of computation
struct CardRow: View {
    let card: InventoryCard

    var body: some View {
        VStack {
            // Complex calculations in body
            Text("Profit: \(calculateComplexProfit())")
        }
    }

    func calculateComplexProfit() -> String {
        // Expensive calculation on every render
    }
}

// ✅ Lightweight row - precomputed values
struct CardRow: View {
    let card: InventoryCard

    var body: some View {
        VStack {
            Text("Profit: \(card.profit)")  // Computed property cached
        }
    }
}
```

---

## Camera & Image Issues

### Issue: "Camera Not Initializing"

**Symptoms**:
- Black screen when opening camera
- "Camera unavailable" error

**Solutions**:

**1. Check Permissions**:

```swift
import AVFoundation

func checkCameraPermission() async -> Bool {
    switch AVCaptureDevice.authorizationStatus(for: .video) {
    case .authorized:
        return true
    case .notDetermined:
        return await AVCaptureDevice.requestAccess(for: .video)
    case .denied, .restricted:
        return false
    @unknown default:
        return false
    }
}
```

**2. Verify Info.plist**:

```xml
<key>NSCameraUsageDescription</key>
<string>CardShow Pro uses your camera to scan trading cards.</string>
```

**3. Check Simulator Limitations**:

Simulator doesn't have a real camera. Use:
- Photo Library as camera source
- Test on physical device

---

### Issue: "Image Recognition Not Working"

**Symptoms**:
- Camera captures image but doesn't recognize card
- Returns "Card not found"

**Causes**:
- Poor lighting
- Blurry image
- Card not fully visible
- API issue

**Solutions**:

**1. Image Quality Checks**:

```swift
func validateImageQuality(_ image: UIImage) -> Bool {
    // Check resolution
    guard image.size.width >= 640 && image.size.height >= 480 else {
        return false  // Too low resolution
    }

    // Check brightness (pseudo-code)
    let brightness = calculateAverageBrightness(image)
    guard brightness > 0.3 && brightness < 0.9 else {
        return false  // Too dark or too bright
    }

    return true
}
```

**2. Provide Manual Fallback**:

```swift
// If image recognition fails, offer manual search
if recognitionFailed {
    showManualSearchPrompt()
}
```

---

## Performance Issues

### Issue: "App Launch Slow"

**Symptoms**:
- Takes >5 seconds to launch
- Splash screen shows for extended time

**Solutions**:

**1. Profile with Instruments**:

```bash
# Launch Time Profiler
instruments -t "Time Profiler" -D trace.trace -l 10000 CardShowPro.app

# Look for long-running tasks in application:didFinishLaunching
```

**2. Defer Non-Critical Work**:

```swift
@main
struct CardShowProApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .task {
                    // Defer analytics, sync, etc.
                    try? await Task.sleep(for: .seconds(2))
                    await initializeAnalytics()
                    await syncWithCloud()
                }
        }
    }
}
```

**3. Lazy Loading**:

```swift
// ❌ Load everything at launch
@State private var allData = loadAllData()  // Slow!

// ✅ Load on-demand
@State private var data: [Card] = []

var body: some View {
    List(data) { card in
        CardRow(card: card)
    }
    .task {
        data = await loadData()  // Load when view appears
    }
}
```

---

### Issue: "High Memory Usage"

**Symptoms**:
- App uses >500 MB RAM
- Crashes with memory warnings on older devices

**Solutions**:

**1. Profile with Instruments**:

```bash
instruments -t "Leaks" CardShowPro.app
instruments -t "Allocations" CardShowPro.app
```

**2. Release Large Objects**:

```swift
// ❌ Holds onto large images
@State private var cardImages: [UIImage] = []

// ✅ Use image cache with size limit
actor ImageCache {
    private var cache: NSCache<NSString, UIImage> = {
        let cache = NSCache<NSString, UIImage>()
        cache.totalCostLimit = 50 * 1024 * 1024  // 50 MB
        return cache
    }()
}
```

**3. Downscale Images**:

```swift
func downscale(_ image: UIImage, to maxDimension: CGFloat) -> UIImage {
    let scale = maxDimension / max(image.size.width, image.size.height)
    let newSize = CGSize(
        width: image.size.width * scale,
        height: image.size.height * scale
    )

    return UIGraphicsImageRenderer(size: newSize).image { _ in
        image.draw(in: CGRect(origin: .zero, size: newSize))
    }
}
```

---

## Simulator Issues

### Issue: "Simulator Keyboard Not Appearing"

**Symptoms**:
- Tap text field but keyboard doesn't show
- Can't type in text fields

**Solutions**:

```bash
# Option 1: Toggle hardware keyboard off
# Simulator → I/O → Keyboard → Connect Hardware Keyboard (uncheck)

# Option 2: Keyboard shortcut
# Press Cmd+K to toggle keyboard

# Option 3: Restart simulator
xcrun simctl shutdown all
xcrun simctl boot "iPhone 16"
```

---

### Issue: "Simulator Can't Connect to Internet"

**Symptoms**:
- API requests fail with "no internet"
- Works on device but not simulator

**Solutions**:

```bash
# 1. Check macOS internet connection (simulator uses host network)

# 2. Reset network settings in simulator
# Simulator → Reset Content and Settings

# 3. Restart simulator
xcrun simctl shutdown all
xcrun simctl boot "iPhone 16"

# 4. Check ATS settings (Info.plist)
# Make sure you're using HTTPS, not HTTP
```

---

## TestFlight & App Store Issues

### Issue: "TestFlight Build Stuck in Processing"

**Symptoms**:
- Uploaded build days ago
- Still shows "Processing" in App Store Connect

**Causes**:
- Large binary size (>500 MB)
- App Store backend issues
- Invalid binary (will eventually fail)

**Solutions**:

```bash
# 1. Check build size
ls -lh ~/Library/Developer/Xcode/Archives/*.xcarchive/Products/Applications/CardShowPro.app

# If >200 MB, optimize:
# - Enable bitcode
# - Strip debug symbols (already in Release config)
# - Remove unused assets

# 2. Check for rejection email
# Apple sends email if binary rejected

# 3. Wait 24-48 hours
# Processing can take time for first build

# 4. Re-upload if >48 hours
# May have failed silently
```

---

### Issue: "App Rejected - Missing Privacy Policy"

**Symptoms**:
```
Guideline 5.1.1 - We noticed your app requires users to register but does not
appear to have a privacy policy.
```

**Solution**:

1. Create privacy policy (see SECURITY.md)
2. Host at `https://cardshowpro.com/privacy`
3. Add URL to App Store Connect:
   - App Information → Privacy Policy URL
4. Add link in app:
   - Settings → Privacy Policy (opens URL)
5. Resubmit

---

### Issue: "App Rejected - Crashes on Launch"

**Symptoms**:
```
Guideline 2.1 - Your app crashed on launch on iPhone 16 Pro running iOS 17.2.
```

**Solutions**:

**1. Test on ALL Devices**:

```bash
# Test on multiple simulators
xcrun simctl list devices | grep "iPhone"

# Run on each:
xcodebuild test -workspace CardShowPro.xcworkspace \
  -scheme CardShowPro \
  -destination 'platform=iOS Simulator,name=iPhone SE (3rd generation)'
```

**2. Crash Log Analysis**:

Apple provides crash logs in App Store Connect:
- App Store Connect → TestFlight → Build → Crashes
- Download .crash file
- Symbolicate and analyze

**3. Add Crash Reporting**:

```swift
// V2: Add Crashlytics or similar
// For now, thorough testing is key
```

---

## User-Reported Issues

### Issue: "My inventory disappeared!"

**Diagnosis Questions**:
1. Did you recently update the app?
2. Did you delete and reinstall?
3. Are you signed into the same iCloud account?

**Common Causes**:
- Reinstalled app (clears local data)
- Switched iCloud accounts
- Device restored from backup

**Solutions**:

```swift
// Implement data export BEFORE major updates
// Users can backup and restore inventory

// V2: Implement iCloud sync
// Automatically backup to iCloud
```

**User Workaround**:
- Go to Settings → Export Data → Save CSV
- Reinstall app
- Go to Settings → Import Data → Upload CSV

---

### Issue: "Prices are wrong / outdated"

**Diagnosis**:
- Check "Last Updated" timestamp
- Verify internet connection
- Check API status

**Solutions**:

1. **Manual Refresh**:
   - Pull down on price lookup screen
   - Forces immediate refresh

2. **Clear Cache**:
   - Settings → Clear Price Cache
   - Re-fetches all prices

3. **Check API Status**:
   ```bash
   curl https://api.pokemontcg.io/v2/cards/base1-4
   # Verify price data is current
   ```

---

### Issue: "Camera won't focus on card"

**User Instructions**:

1. Tap on the card in camera view to focus
2. Ensure good lighting (natural light best)
3. Hold phone 6-12 inches from card
4. Keep card flat and parallel to phone
5. Clean camera lens

**Alternative**:
Use Manual Search instead of camera.

---

## Known Bugs & Workarounds

### Bug: "Trade Analyzer Percentages Reset"

**Status**: Known issue, fix in V1.1
**Workaround**: Re-enter percentages before calculating

---

### Bug: "First Card Add Slow on Fresh Install"

**Status**: Expected behavior (SwiftData initialization)
**Workaround**: First add takes 2-3 seconds, subsequent adds are instant

---

### Bug: "Simulator Camera Shows Pink/Purple Screen"

**Status**: iOS 17 Simulator bug (Apple issue)
**Workaround**: Test camera on physical device only

---

## Logging & Debugging

### Enable Verbose Logging

```swift
// Add to scheme environment variables
// SWIFT_VERBOSE_LOGGING = 1

#if DEBUG
import os.log

extension Logger {
    static let debug = Logger(
        subsystem: Bundle.main.bundleIdentifier!,
        category: "Debug"
    )
}

// Usage
Logger.debug.debug("Card added: \(card.name)")
#endif
```

### Capture Console Logs

```bash
# For simulator
xcrun simctl spawn booted log stream --level debug | grep CardShowPro

# For device (connected via USB)
idevicesyslog | grep CardShowPro
```

### SwiftData Debugging

```swift
// Print all data in database
@Environment(\.modelContext) private var context

func debugPrintAllData() {
    let descriptor = FetchDescriptor<InventoryCard>()
    let cards = try? context.fetch(descriptor)
    print("Total cards: \(cards?.count ?? 0)")
    cards?.forEach { print("- \($0.name)") }
}
```

---

## Escalation Path

If issue can't be resolved:

1. **Check GitHub Issues**: https://github.com/cardshowpro/ios/issues
2. **Search Documentation**: All .md files in repo
3. **Contact Support**: support@cardshowpro.com
4. **Emergency Contact**: developer@cardshowpro.com

**Include in Report**:
- iOS version
- Device model
- App version
- Steps to reproduce
- Console logs (if available)
- Screenshots/screen recording

---

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | January 2026 | Initial troubleshooting guide |

---

**Remember: Most issues can be resolved by restarting the app, clearing cache, or reinstalling. Always try the simple fixes first!**
