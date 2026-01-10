# CardShow Pro - Development Guide

## Getting Started

### Prerequisites

- **Xcode**: 16.0 or later
- **macOS**: Sonoma (14.0) or later
- **iOS Simulator**: iOS 17.0+ (or physical device for camera testing)
- **Swift**: 6.1+ (included with Xcode)
- **Git**: For version control

### First Time Setup

1. **Clone the repository** (if not already done)
   ```bash
   git clone <repository-url>
   cd CardshowPro
   ```

2. **Open the workspace**
   ```bash
   open CardShowPro.xcworkspace
   ```

   **Important**: Always open `.xcworkspace`, NOT `.xcodeproj`

3. **Verify the project structure**
   - Workspace should contain: CardShowPro (app) and CardShowProPackage (package)
   - If package is missing, add it: File → Add Package Dependencies → Add Local...

4. **Select a simulator**
   - Product → Destination → Choose iPhone 15 Pro or similar
   - For camera testing, use a physical device

5. **Build and run**
   - Press `Cmd+R` or Product → Run
   - First build may take 1-2 minutes

### Using XcodeBuildMCP Tools

This project is optimized for AI-assisted development using XcodeBuildMCP tools:

#### Discover Project
```javascript
mcp__xcodebuild__discover_projs({
    workspaceRoot: "/Users/preem/Desktop/CardshowPro"
})
```

#### Build for Simulator
```javascript
mcp__xcodebuild__build_sim({
    workspacePath: "/Users/preem/Desktop/CardshowPro/CardShowPro.xcworkspace",
    scheme: "CardShowPro",
    simulatorName: "iPhone 16"
})
```

#### Run Tests
```javascript
mcp__xcodebuild__test_sim({
    workspacePath: "/Users/preem/Desktop/CardshowPro/CardShowPro.xcworkspace",
    scheme: "CardShowPro",
    simulatorName: "iPhone 16"
})
```

## Development Workflow

### Daily Development

1. **Pull latest changes**
   ```bash
   git pull origin main
   ```

2. **Create a feature branch**
   ```bash
   git checkout -b feature/card-recognition
   ```

3. **Make changes in CardShowProPackage**
   - All features go in `CardShowProPackage/Sources/CardShowProFeature/`
   - Never modify files in `CardShowPro/` app target (except assets)

4. **Test your changes**
   - Run tests: `Cmd+U`
   - Manual testing on simulator or device
   - Verify dark mode: Settings → Developer → Dark Appearance

5. **Commit and push**
   ```bash
   git add .
   git commit -m "Add card recognition using Vision framework"
   git push origin feature/card-recognition
   ```

### Adding a New View

1. **Create Swift file in package**
   - Location: `CardShowProPackage/Sources/CardShowProFeature/Views/`
   - Name: `MyNewView.swift`

2. **Make it public** (required for app target to see it)
   ```swift
   import SwiftUI

   public struct MyNewView: View {
       public init() {}

       public var body: some View {
           Text("My New View")
               .navigationTitle("My Feature")
       }
   }
   ```

3. **Add to navigation**
   - Update `ContentView.swift` or parent view to show your new view

4. **Write tests**
   ```swift
   import Testing
   @testable import CardShowProFeature

   @Test func myNewViewDisplaysCorrectly() async throws {
       let view = MyNewView()
       // Test view logic
   }
   ```

### Adding a New Model

1. **Create in Models directory**
   - Location: `CardShowProPackage/Sources/CardShowProFeature/Models/`

2. **Use @Observable for shared state**
   ```swift
   import SwiftUI

   @Observable
   @MainActor
   final class MyFeatureState {
       var items: [Item] = []
       var isLoading = false

       func loadItems() async throws {
           isLoading = true
           defer { isLoading = false }

           // Load data
           items = try await fetchItems()
       }
   }
   ```

3. **Inject via environment**
   ```swift
   // In parent view
   @State private var featureState = MyFeatureState()

   var body: some View {
       MyFeatureView()
           .environment(featureState)
   }
   ```

### Integrating an API

1. **Add API client**
   ```swift
   // CardShowProPackage/Sources/CardShowProFeature/Services/CardAPIClient.swift

   actor CardAPIClient {
       private let session = URLSession.shared
       private let baseURL = URL(string: "https://api.example.com")!

       func search(query: String) async throws -> [CardResult] {
           let url = baseURL.appendingPathComponent("search")
           var request = URLRequest(url: url)
           request.setValue("application/json", forHTTPHeaderField: "Content-Type")

           let (data, response) = try await session.data(for: request)

           guard let httpResponse = response as? HTTPURLResponse,
                 (200...299).contains(httpResponse.statusCode) else {
               throw APIError.invalidResponse
           }

           return try JSONDecoder().decode([CardResult].self, from: data)
       }
   }

   enum APIError: Error {
       case invalidResponse
       case networkError(Error)
   }
   ```

2. **Use in view**
   ```swift
   struct SearchView: View {
       @State private var apiClient = CardAPIClient()
       @State private var results: [CardResult] = []

       var body: some View {
           List(results) { result in
               Text(result.name)
           }
           .task {
               do {
                   results = try await apiClient.search(query: "Charizard")
               } catch {
                   // Handle error
               }
           }
       }
   }
   ```

### Adding SwiftData Persistence

1. **Define model**
   ```swift
   import SwiftData

   @Model
   final class InventoryCard {
       var name: String
       var price: Double
       var dateAdded: Date
       var imageData: Data?

       init(name: String, price: Double) {
           self.name = name
           self.price = price
           self.dateAdded = Date()
       }
   }
   ```

2. **Configure in app**
   ```swift
   // CardShowPro/CardShowProApp.swift
   @main
   struct CardShowProApp: App {
       var body: some Scene {
           WindowGroup {
               ContentView()
                   .modelContainer(for: InventoryCard.self)
           }
       }
   }
   ```

3. **Use in views**
   ```swift
   struct InventoryView: View {
       @Query private var cards: [InventoryCard]
       @Environment(\.modelContext) private var context

       var body: some View {
           List(cards) { card in
               Text(card.name)
           }
           .toolbar {
               Button("Add") {
                   let newCard = InventoryCard(name: "New Card", price: 100)
                   context.insert(newCard)
               }
           }
       }
   }
   ```

## Testing

### Running Tests

**From Xcode**:
- All tests: `Cmd+U`
- Single test: Click diamond icon next to @Test
- Test plan: Product → Test Plan → CardShowPro

**From Command Line** (XcodeBuildMCP):
```javascript
mcp__xcodebuild__test_sim({
    workspacePath: "/Users/preem/Desktop/CardshowPro/CardShowPro.xcworkspace",
    scheme: "CardShowPro",
    simulatorName: "iPhone 16"
})
```

### Writing Tests (Swift Testing Framework)

```swift
import Testing
@testable import CardShowProFeature

// Basic test
@Test func cardSessionAddsCards() async throws {
    let session = ScanSession()
    let card = ScannedCard(
        image: UIImage(),
        cardName: "Test",
        estimatedValue: 100
    )

    session.addCard(card)

    #expect(session.cardCount == 1)
    #expect(session.totalValue == 100)
}

// Test with parameters
@Test(
    "Card values sum correctly",
    arguments: [(10, 20, 30), (100, 200, 300)]
)
func testCardValueSum(val1: Double, val2: Double, expected: Double) {
    let session = ScanSession()
    session.addCard(ScannedCard(image: UIImage(), estimatedValue: val1))
    session.addCard(ScannedCard(image: UIImage(), estimatedValue: val2))

    #expect(session.totalValue == expected)
}

// Test error handling
@Test func invalidCardThrowsError() async throws {
    await #expect(throws: CardError.invalid) {
        try validateCard(nil)
    }
}
```

### UI Testing

```swift
// CardShowProUITests/CardShowProUITests.swift
import XCTest

final class CardShowProUITests: XCTestCase {
    func testDashboardDisplays() throws {
        let app = XCUIApplication()
        app.launch()

        XCTAssertTrue(app.navigationBars["CardShow Pro"].exists)
        XCTAssertTrue(app.tabBars.buttons["Dashboard"].exists)
    }

    func testNavigationToCamera() throws {
        let app = XCUIApplication()
        app.launch()

        app.tabBars.buttons["Scan"].tap()

        XCTAssertTrue(app.otherElements["Camera View"].exists)
    }
}
```

## Debugging

### Common Issues

#### 1. Build Fails: "No such module 'CardShowProFeature'"

**Solution**: Clean build folder
```
Product → Clean Build Folder (Cmd+Shift+K)
Then rebuild (Cmd+B)
```

#### 2. Camera Not Working in Simulator

**Solution**: Camera requires physical device
- Run on iPhone connected via USB
- Or use mock camera manager for development

#### 3. Tests Not Running

**Solution**: Check test plan includes package tests
- Open CardShowPro.xctestplan
- Verify CardShowProFeatureTests is enabled

#### 4. SwiftUI Previews Not Working

**Solution**: Previews don't work well with packages yet
- Use simulator for live previews
- Or add preview code directly in view file

### Using Xcode Instruments

1. **Profile app**: `Cmd+I`
2. **Choose template**:
   - Time Profiler: Find slow code
   - Allocations: Memory leaks
   - Leaks: Memory leaks
   - Energy Log: Battery usage

3. **Run and record**
4. **Analyze results**

### Print Debugging

```swift
// Development logging (remove before committing)
print("DEBUG: Card detected with confidence \(confidence)")

// Better approach with OSLog
import OSLog

extension Logger {
    static let camera = Logger(subsystem: "com.cardshowpro.app", category: "camera")
}

Logger.camera.debug("Card detected: \(cardName)")
Logger.camera.error("Failed to process frame: \(error)")
```

## Code Review Checklist

Before committing code, verify:

### Functionality
- [ ] Feature works as intended
- [ ] Edge cases handled (empty states, errors)
- [ ] No crashes or warnings

### Code Quality
- [ ] Follows MV pattern (no ViewModels)
- [ ] Uses @Observable for shared state
- [ ] Uses Swift Concurrency (async/await)
- [ ] Proper @MainActor isolation
- [ ] No force unwraps (!) unless absolutely necessary

### Tests
- [ ] Unit tests added for new logic
- [ ] Tests pass locally
- [ ] Coverage for happy path and error cases

### Performance
- [ ] No excessive re-renders
- [ ] Expensive operations run in background
- [ ] Images optimized for size

### Accessibility
- [ ] Accessibility labels for interactive elements
- [ ] VoiceOver navigation works
- [ ] Dynamic Type supported

### Documentation
- [ ] Public APIs documented with ///
- [ ] Complex logic explained in comments
- [ ] PROJECT_STATUS.md updated if needed

## Configuration Management

### Build Configurations

Managed via XCConfig files in `Config/`:

- **Shared.xcconfig**: Common settings (bundle ID, version, deployment target)
- **Debug.xcconfig**: Debug-specific (inherits from Shared)
- **Release.xcconfig**: Release-specific (inherits from Shared)

### Changing App Settings

**Bundle Identifier**:
```
// Config/Shared.xcconfig
PRODUCT_BUNDLE_IDENTIFIER = com.cardshowpro.app
```

**Version Number**:
```
// Config/Shared.xcconfig
MARKETING_VERSION = 1.0.0
CURRENT_PROJECT_VERSION = 1
```

**Deployment Target**:
```
// Config/Shared.xcconfig
IPHONEOS_DEPLOYMENT_TARGET = 17.0
```

### Adding Entitlements

Edit `Config/CardShowPro.entitlements` to add capabilities:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "...">
<plist version="1.0">
<dict>
    <!-- Example: Add HealthKit -->
    <key>com.apple.developer.healthkit</key>
    <true/>

    <!-- Example: Add CloudKit -->
    <key>com.apple.developer.icloud-services</key>
    <array>
        <string>CloudKit</string>
    </array>

    <!-- Example: Add Push Notifications -->
    <key>aps-environment</key>
    <string>development</string>
</dict>
</plist>
```

## Deployment

### TestFlight Beta

1. **Archive the app**
   - Product → Archive
   - Organizer opens with archive

2. **Validate**
   - Click "Validate App"
   - Fix any warnings or errors

3. **Distribute**
   - Click "Distribute App"
   - Choose "App Store Connect"
   - Upload to TestFlight

4. **Submit for review**
   - Log into App Store Connect
   - Add beta testers
   - Submit for TestFlight review

### App Store Release

1. **Prepare marketing materials**
   - Screenshots (required sizes: 6.7", 6.5", 5.5")
   - App preview videos (optional)
   - App description and keywords
   - Privacy policy URL

2. **Create App Store listing**
   - App Store Connect → My Apps → New App
   - Fill in all required information

3. **Submit for review**
   - Upload build from TestFlight
   - Answer questionnaire
   - Submit for review
   - Wait 1-3 days for approval

## Git Workflow

### Branch Strategy

- **main**: Production-ready code
- **develop**: Integration branch for features
- **feature/**: New features (`feature/card-recognition`)
- **bugfix/**: Bug fixes (`bugfix/camera-crash`)
- **hotfix/**: Urgent production fixes

### Commit Messages

Follow conventional commits:

```
feat: Add card recognition API integration
fix: Resolve camera crash on iPhone 15
docs: Update ARCHITECTURE.md with new patterns
test: Add unit tests for ScanSession
refactor: Simplify CameraManager detection logic
```

### Pull Request Template

```markdown
## Description
Brief description of changes

## Type of Change
- [ ] New feature
- [ ] Bug fix
- [ ] Documentation
- [ ] Refactoring

## Testing
- [ ] Unit tests pass
- [ ] Manual testing completed
- [ ] Tested on device

## Screenshots (if applicable)
Add before/after screenshots

## Checklist
- [ ] Code follows project style
- [ ] Tests added/updated
- [ ] Documentation updated
- [ ] No breaking changes
```

## Resources

### Apple Documentation
- [SwiftUI Documentation](https://developer.apple.com/documentation/swiftui)
- [Swift Concurrency](https://docs.swift.org/swift-book/LanguageGuide/Concurrency.html)
- [Swift Testing](https://developer.apple.com/documentation/testing)
- [Vision Framework](https://developer.apple.com/documentation/vision)

### Project Documentation
- [README.md](./README.md) - Project overview
- [CLAUDE.md](./CLAUDE.md) - AI coding standards
- [PROJECT_STATUS.md](./PROJECT_STATUS.md) - Current state
- [ARCHITECTURE.md](./ARCHITECTURE.md) - Architecture details

### External Resources
- [Swift.org](https://swift.org) - Swift language resources
- [Swift Forums](https://forums.swift.org) - Community help
- [Hacking with Swift](https://www.hackingwithswift.com) - Tutorials

---

**Questions?** Check PROJECT_STATUS.md for current state and known issues.

**Contributing?** Read this guide fully and follow the code review checklist.

**AI Agent?** Read CLAUDE.md for coding standards and patterns to follow.
