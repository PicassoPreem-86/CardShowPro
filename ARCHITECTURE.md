# CardShow Pro - Architecture Documentation

## Architecture Overview

CardShow Pro uses a **Workspace + Swift Package Manager (SPM)** architecture that separates the app shell from feature code. This design enables:

- Faster compilation through modular packages
- Better code organization and testability
- AI-friendly development (agents can work in packages without touching Xcode project files)
- Team collaboration with fewer merge conflicts

## High-Level Architecture

```
┌─────────────────────────────────────────────┐
│         CardShowPro.xcworkspace             │
│  (Workspace - Open this in Xcode)          │
└─────────────────────────────────────────────┘
           │                    │
           ▼                    ▼
┌──────────────────┐  ┌─────────────────────┐
│  CardShowPro     │  │ CardShowProPackage  │
│  (.xcodeproj)    │  │  (Swift Package)    │
│                  │  │                     │
│  App Shell:      │  │  Feature Code:      │
│  - Entry Point   │  │  - Models           │
│  - Assets        │  │  - Views            │
│  - TabView       │  │  - Business Logic   │
│                  │  │  - Tests            │
└──────────────────┘  └─────────────────────┘
```

## Design Patterns

### 1. MV (Model-View) Pattern

CardShow Pro uses the **Model-View** pattern with SwiftUI's native state management. We explicitly **avoid MVVM** (ViewModels).

#### Why MV Instead of MVVM?

- **SwiftUI is designed for MV**: @Observable, @State, @Environment are built for direct model-to-view binding
- **ViewModels add unnecessary complexity**: Extra layer of indirection with no real benefit in SwiftUI
- **Better performance**: @Observable tracks individual property access, more efficient than @Published
- **Less code**: Fewer files, less boilerplate, clearer data flow

#### State Management Layers

```
┌─────────────────────────────────────────────────┐
│                   View Layer                    │
│  (SwiftUI Views with @State, @Environment)     │
└─────────────────────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────┐
│              Observable Models                   │
│  (@Observable classes for shared state)         │
│  - AppState (app-wide state)                    │
│  - ScanSession (scan-specific state)            │
└─────────────────────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────┐
│              Business Logic                      │
│  (Pure functions, actors, services)             │
│  - CameraManager (camera & detection)           │
│  - Future: PricingService, InventoryService     │
└─────────────────────────────────────────────────┘
```

### 2. State Management Strategy

#### App-Level State (AppState)

```swift
@Observable
@MainActor
final class AppState {
    var scanSession = ScanSession()
    var selectedTab: Tab = .dashboard
    var isShowModeActive: Bool = false
}
```

**Usage**: Injected at app root via `.environment()`, accessed in views via `@Environment(AppState.self)`

**Purpose**:
- Global navigation state
- Cross-feature coordination
- App-wide settings

#### Feature-Level State (ScanSession)

```swift
@Observable
@MainActor
final class ScanSession {
    var scannedCards: [ScannedCard] = []
    var isProcessing: Bool = false

    func addCard(_ card: ScannedCard) { ... }
    func removeCard(_ card: ScannedCard) { ... }
}
```

**Usage**: Created by AppState, passed to relevant views via environment or direct property

**Purpose**:
- Feature-specific state (scanning session)
- Isolated from other features
- Can be reset/cleared independently

#### View-Local State

```swift
struct DashboardView: View {
    @State private var showCamera = false
    @State private var showSettings = false

    var body: some View {
        // View uses local state for UI-only concerns
    }
}
```

**Purpose**:
- Ephemeral UI state (sheet presentation, animations)
- No need to share with other views
- Automatically cleaned up when view disappears

### 3. Concurrency Model

#### Main Actor Isolation

All UI-related code runs on the main actor:

```swift
@MainActor
@Observable
final class AppState {
    // All property access and mutations happen on main thread
}

@MainActor
struct DashboardView: View {
    // View code always on main thread
}
```

#### Background Work

Camera processing and heavy computation use background queues:

```swift
@Observable
final class CameraManager: NSObject, @unchecked Sendable {
    private let sessionQueue = DispatchQueue(label: "com.cardshowpro.camera")

    nonisolated func captureOutput(...) {
        // Runs on sessionQueue
        // Updates to @Observable properties dispatched to @MainActor
    }
}
```

#### Async/Await Pattern

```swift
struct CardListView: View {
    @State private var cards: [Card] = []

    var body: some View {
        List(cards) { card in
            CardRow(card: card)
        }
        .task {  // ✅ Automatically cancels when view disappears
            await loadCards()
        }
    }

    func loadCards() async {
        // Async work here
    }
}
```

**Rules**:
- ✅ Use `.task { }` modifier for async work tied to view lifecycle
- ❌ Never use `Task { }` in `onAppear` - it doesn't cancel automatically
- ✅ Use `async/await` for all asynchronous operations
- ❌ Never use completion handlers or GCD (except for camera session)

## Data Flow

### Read Flow (View to Model)

```
View reads from Model
        │
        ▼
┌────────────────┐
│ DashboardView  │ @Environment(AppState.self) → reads appState.selectedTab
└────────────────┘
        │
        ▼
┌────────────────┐
│   AppState     │ @Observable property access
└────────────────┘
```

### Write Flow (View mutates Model)

```
User interaction
        │
        ▼
┌────────────────┐
│ DashboardView  │ Button action sets appState.selectedTab = .scan
└────────────────┘
        │
        ▼
┌────────────────┐
│   AppState     │ Property mutation triggers SwiftUI update
└────────────────┘
        │
        ▼
┌────────────────┐
│ All Views      │ Automatically re-render (only if they access selectedTab)
└────────────────┘
```

### Binding Flow (Two-Way)

```
┌────────────────┐
│   ParentView   │ @State private var showSettings = false
└────────────────┘
        │
        │ .sheet(isPresented: $showSettings)
        ▼
┌────────────────┐
│   ChildView    │ Reads and writes via binding
└────────────────┘
```

## Module Organization

### CardShowProPackage Structure

```
Sources/CardShowProFeature/
├── ContentView.swift           # Root view with TabView
├── Models/                     # Data models and state
│   ├── AppState.swift         # App-wide observable state
│   ├── ScannedCard.swift      # Card model & ScanSession
│   └── CameraManager.swift    # Camera and Vision logic
└── Views/                      # SwiftUI views
    ├── DashboardView.swift    # Main dashboard
    ├── CameraView.swift       # Scanner interface
    ├── CardListView.swift     # Inventory management
    ├── ToolsView.swift        # Tools menu
    ├── SettingsView.swift     # App settings
    ├── AnalyticsView.swift    # Analytics dashboard
    └── CreateEventView.swift  # Event creation
```

### Dependency Rules

```
Views → Models → Business Logic
  │       │
  └───────┴──────→ Foundation/SwiftUI APIs
```

- Views depend on Models (read state via @Observable)
- Models contain business logic OR delegate to service objects
- Models can depend on Foundation/system frameworks
- Views should NOT contain business logic
- Everything is mockable for testing

## Camera & Vision Integration

### Camera Pipeline

```
AVCaptureSession (camera hardware)
        │
        ▼
AVCaptureVideoDataOutput (frame stream)
        │
        ▼
CMSampleBuffer → CVPixelBuffer
        │
        ▼
Vision Framework (VNDetectRectanglesRequest)
        │
        ▼
VNRectangleObservation (card bounds + confidence)
        │
        ▼
CameraManager @Observable properties (detectedCardFrame, detectionState)
        │
        ▼
CameraView (renders detection overlay)
```

### Detection States

```
┌──────────┐
│ searching│ (no card detected)
└──────────┘
     │
     ▼ confidence > 0.6
┌──────────┐
│cardFound │ (card visible but not stable)
└──────────┘
     │
     ▼ confidence > 0.85
┌────────────────┐
│ readyToCapture │ (perfect position, auto-capture triggers)
└────────────────┘
     │
     ▼ capture triggered
┌──────────┐
│capturing │ (feedback shown to user)
└──────────┘
```

## Testing Strategy

### Unit Tests (Swift Testing)

```swift
@Test func scanSessionAddsCard() async throws {
    let session = ScanSession()
    let card = ScannedCard(
        image: UIImage(),
        cardName: "Test Card",
        estimatedValue: 100.0
    )

    session.addCard(card)

    #expect(session.cardCount == 1)
    #expect(session.totalValue == 100.0)
}
```

**Test Targets**:
- AppState behavior (tab navigation, state changes)
- ScanSession business logic (add/remove/update cards)
- CameraManager detection logic (mocking Vision framework)
- Future: Service layer tests (pricing, API calls)

### UI Tests (XCUITest)

```swift
func testDashboardToScannerFlow() throws {
    let app = XCUIApplication()
    app.launch()

    // Verify dashboard is shown
    XCTAssertTrue(app.navigationBars["CardShow Pro"].exists)

    // Tap Scan tab
    app.tabBars.buttons["Scan"].tap()

    // Verify camera interface
    XCTAssertTrue(app.buttons["Capture"].exists)
}
```

## Performance Considerations

### SwiftUI Optimization

1. **@Observable is more efficient than @Published**
   - Only re-renders views that access changed properties
   - No need for manual @Published on every property

2. **Lazy loading**
   - Use LazyVStack/LazyHStack for long lists
   - Implement pagination for large datasets

3. **View identity**
   - Use `.id()` modifier sparingly (forces full view recreation)
   - Implement Equatable on models to optimize diffing

### Camera Optimization

1. **Frame processing throttling**
   - Currently processes every frame (60 FPS on iPhone)
   - TODO: Throttle to 10-15 FPS for Vision requests

2. **Vision request caching**
   - Reuse VNRequest instances
   - Don't recreate handler for each frame

3. **Image capture**
   - Currently captures full resolution
   - TODO: Resize before sending to API

## Security & Privacy

### Data Protection

- **Camera permissions**: Required, described in Info.plist
- **Photo library**: Required for saving scans
- **No sensitive data storage yet**: Will need Keychain for API keys
- **No analytics or tracking**: Clean app, user privacy first

### Entitlements

Managed via `Config/CardShowPro.entitlements`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "...">
<plist version="1.0">
<dict>
    <!-- Add entitlements as needed -->
    <!-- Example: HealthKit, CloudKit, Push Notifications -->
</dict>
</plist>
```

## Future Architecture Considerations

### When to Add Services

Add dedicated service objects when:
- Business logic becomes too complex for @Observable models
- Need to share logic across multiple features
- Require dependency injection for testing
- Integrating with external APIs

Example future structure:

```swift
@Observable
final class PricingService {
    private let apiClient: APIClient

    func fetchPrice(for card: Card) async throws -> Price {
        // API call, caching, error handling
    }
}

// Inject via environment
.environment(PricingService(apiClient: .shared))
```

### When to Add Persistence

Use SwiftData when:
- Need to save user data across app launches
- Building inventory/collection management
- Offline functionality required

```swift
@Model
final class InventoryItem {
    var name: String
    var price: Double
    var dateAdded: Date
}
```

### When to Add Networking Layer

Build abstraction when:
- Integrating with multiple APIs (TCGPlayer, eBay, etc.)
- Need request/response interceptors
- Complex authentication flows

```swift
protocol CardAPIClient {
    func search(query: String) async throws -> [CardResult]
    func getPrice(cardId: String) async throws -> Price
}

final class TCGPlayerClient: CardAPIClient { ... }
final class EbayClient: CardAPIClient { ... }
```

## Code Style & Conventions

### File Organization

```swift
// 1. Imports
import SwiftUI
import AVFoundation

// 2. Main type
struct DashboardView: View {
    // 3. Properties (grouped by category)
    @Environment(AppState.self) private var appState
    @State private var showCamera = false

    // 4. Body
    var body: some View {
        // View code
    }

    // 5. Private computed properties
    private var quickActionsSection: some View {
        // View component
    }

    // 6. Private methods
    private func handleAction() {
        // Logic
    }
}

// 7. Extensions and helper types
extension DashboardView {
    // Related functionality
}
```

### Naming Conventions

- **Types**: UpperCamelCase (`DashboardView`, `ScanSession`)
- **Properties/Functions**: lowerCamelCase (`showCamera`, `addCard()`)
- **Private members**: `private` keyword + descriptive name
- **State**: `@State private var` for view-local, `@Observable` for shared

### Documentation

- Use `///` for public API documentation
- Add `// MARK: -` to organize code sections
- Explain *why* in comments, not *what* (code should be self-documenting)

---

**This architecture is designed for:**
- Scalability (easy to add features)
- Testability (clear separation of concerns)
- Maintainability (consistent patterns)
- AI-friendly development (clear structure, minimal magic)

**Remember**: Keep it simple. Add complexity only when needed. SwiftUI is powerful enough without overengineering.
