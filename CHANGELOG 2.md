# Changelog

All notable changes to CardShow Pro will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### To Be Added
- Card recognition API integration
- SwiftData persistence
- Full inventory management
- Trade analyzer tool
- Sales calculator
- Analytics dashboard
- Pro Market Agent (AI pricing)

See [TODO.md](./TODO.md) for complete roadmap.

## [0.1.0] - 2026-01-09

### Added
- **Initial project scaffold** with workspace + SPM architecture
- **Dashboard view** with quick actions, stats, and top items
- **Camera scanning system** with Vision framework integration
  - Real-time card detection using rectangle recognition
  - Three scan modes: Negotiator, Inventory, Sell
  - Auto-capture with confidence-based detection
  - Manual capture fallback
  - Detection state indicators (searching, found, ready, capturing)
  - Scanned cards carousel with running total
- **Tab-based navigation** (Dashboard, Inventory, Scan, Tools)
- **State management** using @Observable pattern
  - AppState for app-wide state
  - ScanSession for scan-specific state
- **Placeholder views** for inventory, tools, settings, analytics
- **XCConfig-based build configuration**
- **Entitlements management** with camera permissions
- **Git repository** initialized with proper .gitignore
- **Comprehensive documentation**:
  - README.md - Project overview
  - CLAUDE.md - AI coding standards
  - PROJECT_STATUS.md - Current state tracking
  - ARCHITECTURE.md - Architecture documentation
  - DEVELOPMENT.md - Development guide
  - TODO.md - Development roadmap
  - CONTRIBUTING.md - Contribution guidelines
  - CHANGELOG.md - Version history

### Technical Details
- **Platform**: iOS 17.0+
- **Language**: Swift 6.1+
- **UI Framework**: SwiftUI
- **State Management**: @Observable (MV pattern, no ViewModels)
- **Concurrency**: Swift Concurrency (async/await, actors)
- **Testing**: Swift Testing framework
- **Architecture**: Workspace + Swift Package Manager
- **Camera**: AVFoundation + Vision framework

### Known Limitations
- Card recognition uses mock data (API integration pending)
- No data persistence (all data lost on app restart)
- No error handling for camera/network failures
- No accessibility support yet
- No tests implemented yet
- Inventory view is placeholder only
- Most tools are non-functional placeholders

### Fixed
- [2026-01-09] Dashboard card styling: Changed from `.systemGray6` to `.systemBackground` for better dark mode appearance
- [2026-01-09] Added subtle shadows to dashboard cards for depth

## Version History Summary

### Version 0.1.0 (2026-01-09)
**First development build** - Basic scaffold with dashboard and camera scanning UI. Not production-ready.

---

## Upcoming Releases

### [0.2.0] - Planned
**Focus**: Core functionality

**Expected Changes**:
- Card recognition API integration
- SwiftData persistence
- Functional inventory management
- Error handling
- Basic testing

**Breaking Changes**: TBD

### [0.3.0] - Planned
**Focus**: Essential tools

**Expected Changes**:
- Trade Analyzer
- Sales Calculator
- Analytics dashboard
- Enhanced settings

### [1.0.0] - Planned
**Focus**: Production release

**Expected Changes**:
- All core features complete
- Comprehensive testing
- Accessibility support
- Performance optimization
- App Store submission

---

## Change Categories

We use these categories for changes:

- **Added**: New features
- **Changed**: Changes to existing functionality
- **Deprecated**: Soon-to-be removed features
- **Removed**: Removed features
- **Fixed**: Bug fixes
- **Security**: Security improvements

## Migration Guides

### Migrating from 0.1.0 to 0.2.0 (when released)

Migration guide will be added when 0.2.0 is released.

---

## Links

- [Project Status](./PROJECT_STATUS.md) - Current state and known issues
- [Architecture Docs](./ARCHITECTURE.md) - Technical architecture
- [Development Guide](./DEVELOPMENT.md) - How to develop
- [TODO List](./TODO.md) - Planned features and roadmap
- [Contributing](./CONTRIBUTING.md) - How to contribute

---

**Note**: This changelog is maintained manually. All notable changes should be documented here before each release.
