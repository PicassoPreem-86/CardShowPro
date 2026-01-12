# CardShow Pro

**AI-Powered Trading Card Scanner & Inventory Management for iOS**

CardShow Pro is a professional-grade iOS application designed for trading card dealers and collectors. It combines AI-powered card recognition with comprehensive inventory management, pricing tools, and analytics to help you manage your card business efficiently.

**Current Status**: v0.1.0 - Early development (scaffold complete, core features in progress)

## Features

### Completed
- Dashboard with inventory statistics and quick actions
- Tab-based navigation (Dashboard, Inventory, Scan, Tools)
- Dark mode optimized UI
- Modern SwiftUI architecture
- Manual card entry flow (Search → Set Selection → Card Entry → Success)
- PokemonTCG.io API integration (free, no API key required)

### In Development
- End-to-end manual entry testing
- Data persistence with SwiftData
- Inventory management system
- Trade analyzer
- Sales calculator
- Analytics dashboard

See [ai/FEATURES.json](./ai/FEATURES.json) for complete feature roadmap.

## AI Assistant Rules Files

This template includes **opinionated rules files** for popular AI coding assistants. These files establish coding standards, architectural patterns, and best practices for modern iOS development using the latest APIs and Swift features.

### Included Rules Files
- **Claude Code**: `CLAUDE.md` - Claude Code rules
- **Cursor**: `.cursor/*.mdc` - Cursor-specific rules
- **GitHub Copilot**: `.github/copilot-instructions.md` - GitHub Copilot rules

### Customization Options
These rules files are **starting points** - feel free to:
- ✅ **Edit them** to match your team's coding standards
- ✅ **Delete them** if you prefer different approaches
- ✅ **Add your own** rules for other AI tools
- ✅ **Update them** as new iOS APIs become available

### What Makes These Rules Opinionated
- **No ViewModels**: Embraces pure SwiftUI state management patterns
- **Swift 6+ Concurrency**: Enforces modern async/await over legacy patterns
- **Latest APIs**: Recommends iOS 18+ features with optional iOS 26 guidelines
- **Testing First**: Promotes Swift Testing framework over XCTest
- **Performance Focus**: Emphasizes @Observable over @Published for better performance

**Note for AI assistants**: You MUST read the relevant rules files before making changes to ensure consistency with project standards.

## Project Architecture

```
CardShowPro/
├── CardShowPro.xcworkspace/              # Open this file in Xcode
├── CardShowPro.xcodeproj/                # App shell project
├── CardShowPro/                          # App target (minimal)
│   ├── Assets.xcassets/                # App-level assets (icons, colors)
│   ├── CardShowProApp.swift              # App entry point
│   └── CardShowPro.xctestplan            # Test configuration
├── CardShowProPackage/                   # 🚀 Primary development area
│   ├── Package.swift                   # Package configuration
│   ├── Sources/CardShowProFeature/       # Your feature code
│   └── Tests/CardShowProFeatureTests/    # Unit tests
└── CardShowProUITests/                   # UI automation tests
```

## Key Architecture Points

### Workspace + SPM Structure
- **App Shell**: `CardShowPro/` contains minimal app lifecycle code
- **Feature Code**: `CardShowProPackage/Sources/CardShowProFeature/` is where most development happens
- **Separation**: Business logic lives in the SPM package, app target just imports and displays it

### Buildable Folders (Xcode 16)
- Files added to the filesystem automatically appear in Xcode
- No need to manually add files to project targets
- Reduces project file conflicts in teams

## Development Notes

### Code Organization
Most development happens in `CardShowProPackage/Sources/CardShowProFeature/` - organize your code as you prefer.

### Public API Requirements
Types exposed to the app target need `public` access:
```swift
public struct NewView: View {
    public init() {}
    
    public var body: some View {
        // Your view code
    }
}
```

### Adding Dependencies
Edit `CardShowProPackage/Package.swift` to add SPM dependencies:
```swift
dependencies: [
    .package(url: "https://github.com/example/SomePackage", from: "1.0.0")
],
targets: [
    .target(
        name: "CardShowProFeature",
        dependencies: ["SomePackage"]
    ),
]
```

### Test Structure
- **Unit Tests**: `CardShowProPackage/Tests/CardShowProFeatureTests/` (Swift Testing framework)
- **UI Tests**: `CardShowProUITests/` (XCUITest framework)
- **Test Plan**: `CardShowPro.xctestplan` coordinates all tests

## Configuration

### XCConfig Build Settings
Build settings are managed through **XCConfig files** in `Config/`:
- `Config/Shared.xcconfig` - Common settings (bundle ID, versions, deployment target)
- `Config/Debug.xcconfig` - Debug-specific settings  
- `Config/Release.xcconfig` - Release-specific settings
- `Config/Tests.xcconfig` - Test-specific settings

### Entitlements Management
App capabilities are managed through a **declarative entitlements file**:
- `Config/CardShowPro.entitlements` - All app entitlements and capabilities
- AI agents can safely edit this XML file to add HealthKit, CloudKit, Push Notifications, etc.
- No need to modify complex Xcode project files

### Asset Management
- **App-Level Assets**: `CardShowPro/Assets.xcassets/` (app icon, accent color)
- **Feature Assets**: Add `Resources/` folder to SPM package if needed

### SPM Package Resources
To include assets in your feature package:
```swift
.target(
    name: "CardShowProFeature",
    dependencies: [],
    resources: [.process("Resources")]
)
```

## Quick Start

### Prerequisites
- Xcode 16.0 or later
- macOS Sonoma (14.0) or later
- iOS 17.0+ device or simulator

### Running the App

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd CardshowPro
   ```

2. **Open the workspace** (not the project!)
   ```bash
   open CardShowPro.xcworkspace
   ```

3. **Select a simulator** or connect a device
   - For camera testing: Use a physical iOS device (camera doesn't work in simulator)
   - For UI testing: Any iPhone simulator (iPhone 15 Pro recommended)

4. **Build and run**
   - Press `Cmd+R` or click the Run button
   - First build may take 1-2 minutes

## Documentation

This project includes comprehensive documentation for developers and AI coding assistants:

### For Developers
- **[DEVELOPMENT.md](./DEVELOPMENT.md)** - Complete development guide with workflows, patterns, and best practices
- **[CONTRIBUTING.md](./CONTRIBUTING.md)** - How to contribute to this project
- **[ai/FEATURES.json](./ai/FEATURES.json)** - Development roadmap with all planned features
- **[CHANGELOG.md](./CHANGELOG.md)** - Version history and release notes

### For Understanding the Project
- **[PROJECT_STATUS.md](./PROJECT_STATUS.md)** - Current state, completed features, and known issues
- **[ARCHITECTURE.md](./ARCHITECTURE.md)** - Technical architecture, design patterns, and data flow

### For AI Coding Assistants
- **[CLAUDE.md](./CLAUDE.md)** - Claude Code rules and standards
- **[.github/copilot-instructions.md](./.github/copilot-instructions.md)** - GitHub Copilot rules

**Important**: Future agents MUST read PROJECT_STATUS.md and ARCHITECTURE.md before making changes to understand the current state and design patterns.

## Technology Stack

- **Language**: Swift 6.1+ with strict concurrency
- **UI Framework**: SwiftUI (iOS 17.0+)
- **Architecture**: MV (Model-View) pattern using @Observable
- **Concurrency**: Swift Concurrency (async/await, actors, @MainActor)
- **Testing**: Swift Testing framework (@Test, #expect)
- **Package Management**: Swift Package Manager (SPM)
- **Build System**: Workspace + SPM architecture
- **Camera**: AVFoundation + Vision framework

## Project Structure

```
CardShowPro/
├── CardShowPro.xcworkspace/          # Main workspace (OPEN THIS)
├── CardShowPro.xcodeproj/            # App shell project
├── CardShowPro/                      # App target
│   ├── Assets.xcassets/             # App icon, colors
│   └── CardShowProApp.swift         # App entry point
├── CardShowProPackage/               # 🚀 ALL DEVELOPMENT HERE
│   ├── Package.swift                # Package configuration
│   ├── Sources/CardShowProFeature/
│   │   ├── ContentView.swift        # Main tab view
│   │   ├── Models/                  # Data models
│   │   │   ├── AppState.swift       # App-wide state
│   │   │   ├── ScannedCard.swift    # Card models
│   │   │   └── CameraManager.swift  # Camera logic
│   │   └── Views/                   # SwiftUI views
│   │       ├── DashboardView.swift  # ✓ Complete
│   │       ├── CameraView.swift     # ✓ Complete
│   │       ├── CardListView.swift   # ○ Placeholder
│   │       ├── ToolsView.swift      # ○ Placeholder
│   │       └── ...
│   └── Tests/CardShowProFeatureTests/
├── CardShowProUITests/               # UI automation tests
├── Config/                           # Build configuration
│   ├── Shared.xcconfig              # Common settings
│   ├── Debug.xcconfig               # Debug config
│   ├── Release.xcconfig             # Release config
│   └── CardShowPro.entitlements     # App capabilities
└── Documentation/
    ├── README.md                    # This file
    ├── PROJECT_STATUS.md            # Current state
    ├── ARCHITECTURE.md              # Architecture docs
    ├── DEVELOPMENT.md               # Development guide
    ├── ai/FEATURES.json             # Feature roadmap
    ├── CONTRIBUTING.md              # Contribution guide
    ├── CHANGELOG.md                 # Version history
    └── CLAUDE.md                    # AI coding standards
```

Legend: ✓ Complete, ○ Placeholder

## License

[Add license information here]

## Credits

- Scaffolded using [XcodeBuildMCP](https://github.com/cameroncooke/XcodeBuildMCP)
- Built with SwiftUI and modern Swift practices

---

**For detailed development information, see [DEVELOPMENT.md](./DEVELOPMENT.md)**

**For current project status, see [PROJECT_STATUS.md](./PROJECT_STATUS.md)**

**For architecture details, see [ARCHITECTURE.md](./ARCHITECTURE.md)**