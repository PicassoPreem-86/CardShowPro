# CardShow Pro - Development Roadmap

**Last Updated**: 2026-01-09

This file tracks all planned features, improvements, and known issues. Items are organized by priority and status.

## Legend
- 🔴 **High Priority** - Critical for core functionality
- 🟡 **Medium Priority** - Important but not blocking
- 🟢 **Low Priority** - Nice to have, future enhancement
- ✅ **Completed** - Done and tested
- 🚧 **In Progress** - Currently being worked on
- 📝 **Planned** - Not started, ready for implementation
- 🤔 **Needs Discussion** - Requires decision or clarification

---

## Phase 1: Core Functionality (Foundational Features)

### 🔴 Card Recognition & AI Integration
**Status**: 📝 Planned
**Priority**: CRITICAL - Without this, app cannot scan cards

**Tasks**:
- [ ] Research and select card recognition API (TCGPlayer, eBay, or custom ML model)
- [ ] Integrate chosen API with CameraView
- [ ] Replace mock data in `performCapture()` with real API calls
- [ ] Handle API errors gracefully (network failure, invalid card, etc.)
- [ ] Add loading states while API processes image
- [ ] Implement retry logic for failed recognitions
- [ ] Add confidence threshold configuration
- [ ] Store API keys securely in Keychain

**Dependencies**: None
**Estimated Effort**: 2-3 days
**Notes**:
- Current code uses mock `ScannedCard` objects
- API selection impacts pricing, accuracy, and card database coverage
- Consider offline fallback or cached card database

---

### 🔴 Data Persistence with SwiftData
**Status**: 📝 Planned
**Priority**: HIGH - Users need to save scanned cards

**Tasks**:
- [ ] Create SwiftData models for:
  - [ ] `InventoryCard` (scanned/added cards)
  - [ ] `ScanningSession` (historical scan sessions)
  - [ ] `CardEvent` (card show events)
  - [ ] `Contact` (customers/vendors)
- [ ] Add ModelContainer to app entry point
- [ ] Migrate `ScanSession` to persist to SwiftData
- [ ] Update `CardListView` to read from SwiftData
- [ ] Implement search and filtering
- [ ] Add bulk edit/delete operations
- [ ] Implement data export (CSV/JSON)

**Dependencies**: None
**Estimated Effort**: 2 days
**Notes**:
- Start with basic InventoryCard model
- Add relationships later (e.g., Card → Event)
- Consider iCloud sync for future versions

---

### 🔴 Inventory Management (CardListView)
**Status**: 📝 Planned
**Priority**: HIGH - Core feature for card dealers

**Tasks**:
- [ ] Design inventory list UI (card grid or list)
- [ ] Implement search functionality
- [ ] Add filter options (by value, date, card type, set)
- [ ] Add sort options (name, value, date added)
- [ ] Build card detail view with edit capability
- [ ] Implement bulk actions (delete, export, tag)
- [ ] Add image viewer for card photos
- [ ] Show statistics (total count, total value, average value)
- [ ] Implement pagination for large inventories

**Dependencies**: Data Persistence
**Estimated Effort**: 3 days
**Notes**:
- Should feel like a professional inventory system
- Consider barcode scanning for faster bulk entry

---

### 🔴 Error Handling & User Feedback
**Status**: 📝 Planned
**Priority**: HIGH - App crashes are unacceptable

**Tasks**:
- [ ] Add error states to all async operations
- [ ] Create reusable error alert component
- [ ] Handle camera permission denied gracefully
- [ ] Handle network errors with retry options
- [ ] Add loading indicators for API calls
- [ ] Implement toast/banner for success messages
- [ ] Add empty states for all views
- [ ] Log errors for debugging (OSLog)

**Dependencies**: None
**Estimated Effort**: 1-2 days
**Notes**:
- Use SwiftUI `.alert()` modifier
- Consider custom error types for better messages

---

## Phase 2: Essential Tools

### 🟡 Trade Analyzer Tool
**Status**: 📝 Planned
**Priority**: MEDIUM - Key differentiator for dealers

**Tasks**:
- [ ] Design UI for comparing two sets of cards
- [ ] Allow adding cards to "my side" and "their side"
- [ ] Calculate total values for each side
- [ ] Show value difference and percentage
- [ ] Add notes field for trade context
- [ ] Save trade history
- [ ] Generate trade summary report

**Dependencies**: Inventory Management
**Estimated Effort**: 2 days
**Notes**:
- Should support scanning cards directly into trade
- Consider suggesting fair trades based on values

---

### 🟡 Sales Calculator Tool
**Status**: 📝 Planned
**Priority**: MEDIUM - Helps users price correctly

**Tasks**:
- [ ] Create calculator UI
- [ ] Add fields for:
  - [ ] Card price
  - [ ] Platform fees (eBay, TCGPlayer, etc.)
  - [ ] Shipping costs
  - [ ] Payment processing fees (PayPal, Stripe)
  - [ ] Taxes
- [ ] Show net profit calculation
- [ ] Save presets for common platforms
- [ ] Compare multiple platforms side-by-side

**Dependencies**: None
**Estimated Effort**: 1 day
**Notes**:
- Fee structures change, make them configurable
- Add popular marketplace templates

---

### 🟡 Analytics Dashboard
**Status**: 📝 Planned
**Priority**: MEDIUM - Business insights

**Tasks**:
- [ ] Create analytics view with charts
- [ ] Show total inventory value over time
- [ ] Display sales statistics (if sales tracking added)
- [ ] Show most valuable cards
- [ ] Show card acquisition trends
- [ ] Add date range filters
- [ ] Export analytics reports

**Dependencies**: Data Persistence
**Estimated Effort**: 2-3 days
**Notes**:
- Use Swift Charts framework (iOS 16+)
- Start simple, add complexity later

---

### 🟡 Settings & Preferences
**Status**: 📝 Planned
**Priority**: MEDIUM - User customization

**Tasks**:
- [ ] Expand current SettingsView
- [ ] Add app preferences:
  - [ ] Default currency
  - [ ] Measurement units
  - [ ] Auto-capture settings
  - [ ] Notification preferences
- [ ] Add account management (if cloud sync added)
- [ ] Add data export/import
- [ ] Add about screen with version info
- [ ] Add privacy policy and terms

**Dependencies**: None
**Estimated Effort**: 1 day
**Notes**:
- Use UserDefaults for preferences
- Consider Settings.bundle for system settings

---

## Phase 3: Advanced Features

### 🟢 Pro Market Agent (AI Pricing)
**Status**: 🤔 Needs Discussion
**Priority**: LOW - Cool feature, not essential

**Tasks**:
- [ ] Research AI/ML approaches for price prediction
- [ ] Integrate price history API
- [ ] Build prediction model or use third-party service
- [ ] Show price trends and predictions
- [ ] Add "Best time to sell" recommendations
- [ ] Track prediction accuracy

**Dependencies**: Card Recognition, API Integration
**Estimated Effort**: 5+ days
**Notes**:
- Complex feature, may require backend service
- Consider partnering with pricing data provider

---

### 🟢 Grading ROI Calculator
**Status**: 📝 Planned
**Priority**: LOW - Niche but useful

**Tasks**:
- [ ] Create calculator UI
- [ ] Add grading service options (PSA, BGS, CGC)
- [ ] Input fields:
  - [ ] Raw card value
  - [ ] Grading cost
  - [ ] Estimated grade
  - [ ] Graded card value
- [ ] Calculate break-even and profit
- [ ] Show recommendation (grade or don't grade)

**Dependencies**: None
**Estimated Effort**: 1 day
**Notes**:
- Grading costs and premiums change frequently
- Make values configurable

---

### 🟢 Vendor Mode (Card Show Management)
**Status**: 📝 Planned
**Priority**: LOW - For serious dealers

**Tasks**:
- [ ] Create event management system
- [ ] Allow creating "events" (card shows)
- [ ] Associate cards with events
- [ ] Track sales during events
- [ ] Generate end-of-show reports
- [ ] Calculate profits per event
- [ ] Export tax documentation

**Dependencies**: Data Persistence
**Estimated Effort**: 3-4 days
**Notes**:
- Could be a premium feature
- Consider offline mode for shows without WiFi

---

### 🟢 Contacts Management
**Status**: 📝 Planned
**Priority**: LOW - Relationship management

**Tasks**:
- [ ] Create contact model (name, email, phone, notes)
- [ ] Build contact list view
- [ ] Add contact creation/editing
- [ ] Link contacts to trades or sales
- [ ] Add communication history
- [ ] Integration with iOS Contacts (optional)

**Dependencies**: Data Persistence
**Estimated Effort**: 2 days
**Notes**:
- Start simple, avoid over-engineering
- Privacy implications - handle data carefully

---

### 🟢 Listing Generator (Auto-Descriptions)
**Status**: 🤔 Needs Discussion
**Priority**: LOW - Convenience feature

**Tasks**:
- [ ] Research AI text generation APIs
- [ ] Create template system for listings
- [ ] Generate descriptions based on card data
- [ ] Support multiple platforms (eBay, TCGPlayer, etc.)
- [ ] Allow manual editing before posting
- [ ] Save templates for reuse

**Dependencies**: Card Recognition
**Estimated Effort**: 2-3 days
**Notes**:
- Could use OpenAI API or similar
- Template-based approach may be simpler

---

## Phase 4: Quality & Polish

### 🟡 Testing & Quality Assurance
**Status**: 📝 Planned
**Priority**: MEDIUM - Essential for production

**Tasks**:
- [ ] Write unit tests for all models
- [ ] Write unit tests for business logic
- [ ] Add UI tests for critical flows
- [ ] Test on multiple iOS versions (17, 18+)
- [ ] Test on multiple device sizes (SE, Pro Max, iPad)
- [ ] Test in dark mode and light mode
- [ ] Test with VoiceOver enabled
- [ ] Test with slow network conditions
- [ ] Fix all crashes and warnings

**Dependencies**: All features implemented
**Estimated Effort**: Ongoing
**Notes**:
- Aim for >80% code coverage
- Use Test Plans for different configurations

---

### 🟡 Accessibility Support
**Status**: 📝 Planned
**Priority**: MEDIUM - Legal requirement in some regions

**Tasks**:
- [ ] Add accessibility labels to all interactive elements
- [ ] Add accessibility hints where needed
- [ ] Test with VoiceOver
- [ ] Support Dynamic Type (text scaling)
- [ ] Ensure minimum touch target sizes (44x44)
- [ ] Add accessibility identifiers for UI testing
- [ ] Support reduce motion preference
- [ ] Test color contrast ratios

**Dependencies**: Features complete
**Estimated Effort**: 2 days
**Notes**:
- Use Xcode Accessibility Inspector
- Follow Human Interface Guidelines

---

### 🟡 Performance Optimization
**Status**: 📝 Planned
**Priority**: MEDIUM - User experience

**Tasks**:
- [ ] Optimize camera frame processing (throttle to 10-15 FPS)
- [ ] Add image caching for card photos
- [ ] Optimize SwiftData queries with predicates
- [ ] Reduce memory usage during scanning
- [ ] Profile with Instruments (Time Profiler, Allocations)
- [ ] Optimize app launch time
- [ ] Reduce bundle size if needed
- [ ] Test on older devices (iPhone SE)

**Dependencies**: Features complete
**Estimated Effort**: 1-2 days
**Notes**:
- Measure before optimizing (don't guess)
- Target: < 1 second app launch, < 100ms frame processing

---

### 🟢 Localization
**Status**: 📝 Planned
**Priority**: LOW - International markets

**Tasks**:
- [ ] Extract all strings to Localizable.strings
- [ ] Translate to target languages (Spanish, French, etc.)
- [ ] Test layouts with different languages
- [ ] Support right-to-left languages (Arabic, Hebrew)
- [ ] Localize number and currency formats
- [ ] Localize date formats

**Dependencies**: Features complete
**Estimated Effort**: 2-3 days per language
**Notes**:
- Start with major markets (US, UK, EU)
- Use professional translation services

---

### 🟢 Onboarding Experience
**Status**: 📝 Planned
**Priority**: LOW - Better first impression

**Tasks**:
- [ ] Create welcome screen
- [ ] Add feature highlights carousel
- [ ] Show camera permission explanation
- [ ] Add quick tutorial for first scan
- [ ] Show tips for getting best scan results
- [ ] Allow skipping onboarding
- [ ] Remember if user completed onboarding

**Dependencies**: Core features complete
**Estimated Effort**: 1 day
**Notes**:
- Keep it short (3-5 screens max)
- Make it optional to skip

---

## Known Issues & Bugs

### 🔴 Critical Bugs
- None currently identified

### 🟡 Medium Priority Bugs
- None currently identified

### 🟢 Minor Issues
- Camera preview may not initialize on first launch (requires app restart)
- Detection frame overlay sometimes lags behind actual card position
- No feedback when scanner reaches max cards per session

---

## Technical Debt

### Code Quality
- [ ] Remove all force unwraps (!) and replace with safe handling
- [ ] Add proper error types instead of generic errors
- [ ] Extract reusable components from large view files
- [ ] Add documentation comments for public APIs

### Architecture
- [ ] Consider extracting camera logic into separate service
- [ ] Consider adding repository pattern for data access
- [ ] Add dependency injection for testability

### Performance
- [ ] Throttle Vision framework requests (currently 60 FPS)
- [ ] Cache card images to reduce memory usage
- [ ] Optimize SwiftData queries with indexes

---

## Future Ideas (Backlog)

These are ideas for future consideration, not committed features:

- **Cloud Sync**: Sync inventory across devices via iCloud or custom backend
- **Web Dashboard**: Companion web app for managing inventory from desktop
- **Barcode Scanning**: Support UPC/barcode scanning for sealed products
- **Price Alerts**: Notify users when card values change significantly
- **Community Features**: Share trade offers with other users
- **Augmented Reality**: AR card viewer showing 3D card models
- **Bulk Import**: Import existing inventory from CSV or spreadsheet
- **Integration with Marketplaces**: Auto-list cards on eBay/TCGPlayer
- **Tax Reporting**: Generate tax documents for card sales
- **Insurance Valuation**: Generate insurance reports for valuable collections

---

## Decisions & Considerations

### API Selection for Card Recognition
**Status**: 🤔 Needs Discussion

**Options**:
1. **TCGPlayer API**: Good for Pokemon/Magic, requires partnership
2. **eBay API**: Broad coverage, complex pricing
3. **Custom ML Model**: Full control, requires training data
4. **Hybrid Approach**: Use multiple sources, compare results

**Decision**: TBD

---

### Monetization Strategy
**Status**: 🤔 Needs Discussion

**Options**:
1. **One-time purchase**: $19.99-$29.99
2. **Subscription**: $4.99/month or $39.99/year
3. **Freemium**: Free basic features, premium add-ons
4. **Free with ads**: Ad-supported free version

**Decision**: TBD

---

### Cloud Sync Strategy
**Status**: 🤔 Needs Discussion

**Options**:
1. **iCloud (CloudKit)**: Native, easy to implement, iOS-only
2. **Firebase**: Cross-platform, realtime sync
3. **Custom Backend**: Full control, more work
4. **No sync**: Keep it local (simplest)

**Decision**: Start local-only, add sync in v2.0

---

## Notes for Future Development

### When Adding Features
1. Update PROJECT_STATUS.md with implementation details
2. Update this TODO.md to mark items complete
3. Add tests for new functionality
4. Update ARCHITECTURE.md if patterns change
5. Consider accessibility from the start

### When Fixing Bugs
1. Write a failing test first (if possible)
2. Fix the bug
3. Verify test passes
4. Document the fix in git commit message
5. Update PROJECT_STATUS.md if it was a known issue

### When Making Architectural Changes
1. Discuss in team (or document decision)
2. Update ARCHITECTURE.md
3. Update CLAUDE.md if coding patterns change
4. Refactor incrementally
5. Ensure tests still pass

---

**Last Review**: 2026-01-09
**Next Review**: After Phase 1 completion or as needed

**Remember**: This is a living document. Update it as priorities change, features are completed, and new ideas emerge.
