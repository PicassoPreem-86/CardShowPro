# CardShowPro Design System

A comprehensive Pokemon-inspired design system providing consistent visual language throughout the CardShowPro iOS application.

## Overview

The design system is implemented in `/CardShowProPackage/Sources/CardShowProFeature/DesignSystem/` and provides:
- Color palette with Thunder Yellow and Electric Blue accents
- 4pt spacing system
- Corner radius scale
- Shadow/elevation system (levels 0-5)
- Typography hierarchy using SF Pro
- Animation timing constants
- Reusable component styles
- View modifiers for common patterns

## Color Palette

### Primary Colors
- **Thunder Yellow** (#FFD700) - Primary brand color
- **Electric Blue** (#00A8E8) - Secondary brand color
- **Cyan** (#00D9FF) - Interactive elements

### Background Colors
- **Background Primary** (#0A0E27) - Rich dark background
- **Background Secondary** (#121629) - Alternate dark background
- **Background Tertiary** (#1A1F3A) - Component backgrounds
- **Card Background** (#1E2442) - Standard card background
- **Premium Card Background** (#2A2F4A) - Premium cards

### Text Colors
- **Text Primary** (#FFFFFF) - High contrast white
- **Text Secondary** (#8E94A8) - Medium contrast gray
- **Text Tertiary** (#5A5F73) - Low contrast gray
- **Text Disabled** (#3E4359) - Disabled state

### Accent Colors
- **Success** (#34C759)
- **Warning** (#FF9500)
- **Error** (#FF3B30)

### Rarity Colors
- **Common** (#C0C0C0)
- **Uncommon** (#5CB85C)
- **Rare** (#5BC0DE)
- **Ultra Rare** (#D9534F)
- **Secret Rare** (#FFD700)

## Spacing System (4pt base)

```swift
DesignSystem.Spacing.xxxs  // 4pt
DesignSystem.Spacing.xxs   // 8pt
DesignSystem.Spacing.xs    // 12pt
DesignSystem.Spacing.sm    // 16pt
DesignSystem.Spacing.md    // 20pt
DesignSystem.Spacing.lg    // 24pt
DesignSystem.Spacing.xl    // 32pt
DesignSystem.Spacing.xxl   // 40pt
DesignSystem.Spacing.xxxl  // 48pt
```

## Corner Radius Scale

```swift
DesignSystem.CornerRadius.xs   // 4pt
DesignSystem.CornerRadius.sm   // 8pt
DesignSystem.CornerRadius.md   // 12pt
DesignSystem.CornerRadius.lg   // 16pt
DesignSystem.CornerRadius.xl   // 20pt
DesignSystem.CornerRadius.xxl  // 24pt
DesignSystem.CornerRadius.pill // Fully rounded
```

## Shadow/Elevation Levels

- **Level 0** - No shadow
- **Level 1** - Subtle elevation (radius: 2pt, opacity: 0.05)
- **Level 2** - Light elevation (radius: 4pt, opacity: 0.1)
- **Level 3** - Medium elevation (radius: 8pt, opacity: 0.15)
- **Level 4** - High elevation (radius: 12pt, opacity: 0.2)
- **Level 5** - Maximum elevation (radius: 20pt, opacity: 0.3)

## Typography

### Display Styles
- **Display Large** - 48pt Bold Rounded
- **Display Medium** - 40pt Bold Rounded
- **Display Small** - 32pt Bold Rounded

### Heading Styles
- **Heading 1** - 28pt Semibold
- **Heading 2** - 24pt Semibold
- **Heading 3** - 20pt Semibold
- **Heading 4** - 18pt Semibold

### Body Styles
- **Body Large** - 17pt Regular
- **Body** - 15pt Regular
- **Body Small** - 13pt Regular

### Label Styles
- **Label Large** - 15pt Medium
- **Label** - 13pt Medium
- **Label Small** - 11pt Medium

### Caption Styles
- **Caption** - 12pt Regular
- **Caption Bold** - 12pt Semibold
- **Caption Small** - 10pt Regular

## Animation Timings

```swift
DesignSystem.Animation.instant     // 0.1s
DesignSystem.Animation.fast        // 0.2s
DesignSystem.Animation.normal      // 0.3s
DesignSystem.Animation.moderate    // 0.4s
DesignSystem.Animation.slow        // 0.5s
DesignSystem.Animation.deliberate  // 0.7s
```

### Spring Presets
- **Spring Bouncy** - response: 0.3, damping: 0.6
- **Spring Smooth** - response: 0.3, damping: 0.8
- **Spring Snappy** - response: 0.2, damping: 0.7

## Components

### Buttons

#### Primary Button
```swift
PrimaryButton("Submit") {
    // Action
}

// With icon
PrimaryButton("Submit", icon: "checkmark") {
    // Action
}
```

**Styling:**
- Background: Thunder Yellow
- Foreground: Dark background
- Press scale: 0.95
- Press opacity: 0.8
- Shadow: Level 3

#### Secondary Button
```swift
SecondaryButton("Cancel") {
    // Action
}

// With icon
SecondaryButton("Cancel", icon: "xmark") {
    // Action
}
```

**Styling:**
- Background: Background Tertiary
- Foreground: White
- Border: Electric Blue (2pt)
- Press scale: 0.97
- Shadow: Level 2

### Cards

#### Standard Card
```swift
VStack {
    // Content
}
.cardStyle()
```

**Styling:**
- Background: Card Background
- Corner radius: 16pt
- Padding: 20pt
- Shadow: Level 2

#### Premium Card
```swift
PremiumCard {
    VStack {
        // Content
    }
}
```

**Styling:**
- Background: Premium Card Background
- Corner radius: 20pt
- Border: Thunder Yellow (1pt)
- Padding: 24pt
- Shadow: Level 4

### Badges

#### Rarity Badge
```swift
RarityBadge(rarity: .ultraRare)
RarityBadge(rarity: .secretRare)
```

**Available Rarities:**
- `.common` - Silver with circle icon
- `.uncommon` - Green with diamond icon
- `.rare` - Blue with star icon
- `.ultraRare` - Red with sparkles icon
- `.secretRare` - Gold with crown icon

### Loading States

#### Skeleton View
```swift
// Show skeleton during loading
Text("Loading content")
    .skeletonLoader(isLoading: viewModel.isLoading)

// Or use directly
SkeletonView()
```

#### Shimmer Effect
```swift
Text("Loading...")
    .shimmer(isActive: true)
```

## View Modifiers

### Button Styles
```swift
Text("Primary")
    .primaryButtonStyle()

Text("Secondary")
    .secondaryButtonStyle()
```

### Card Styles
```swift
VStack { }
    .cardStyle()

VStack { }
    .premiumCardStyle()
```

### Shadow Elevation
```swift
VStack { }
    .shadowElevation(3) // Levels 0-5
```

### Loading States
```swift
Text("Content")
    .skeletonLoader(isLoading: true)

Text("Loading")
    .shimmer(isActive: true)
```

## File Structure

```
DesignSystem/
├── DesignSystem.swift              # Core tokens and styles
├── ViewModifiers.swift             # Reusable view modifiers
└── Components/
    ├── PrimaryButton.swift         # Primary action button
    ├── SecondaryButton.swift       # Secondary action button
    ├── PremiumCard.swift           # Premium card wrapper
    ├── RarityBadge.swift          # Card rarity badge
    ├── SkeletonView.swift         # Skeleton loader
    └── ShimmerModifier.swift      # Shimmer effect
```

## Usage Examples

### Basic Button with Design System
```swift
Button {
    // Action
} label: {
    Text("Save")
        .primaryButtonStyle()
}
```

### Card with Elevation
```swift
VStack(spacing: DesignSystem.Spacing.md) {
    Text("Title")
        .font(DesignSystem.Typography.heading2)
        .foregroundStyle(DesignSystem.Colors.textPrimary)

    Text("Description")
        .font(DesignSystem.Typography.body)
        .foregroundStyle(DesignSystem.Colors.textSecondary)
}
.cardStyle()
.shadowElevation(3)
```

### Loading State
```swift
VStack {
    if isLoading {
        SkeletonView()
            .frame(height: 200)
    } else {
        ContentView()
    }
}
```

## Best Practices

1. **Always use design system tokens** instead of hardcoded values
2. **Prefer view modifiers** over manual styling for consistency
3. **Use appropriate elevation levels** - don't overuse high shadows
4. **Follow spacing system** - multiples of 4pt only
5. **Use semantic colors** - choose based on meaning, not appearance
6. **Test in both light and dark modes** (design system optimized for dark mode)
7. **Leverage reusable components** before creating custom ones
8. **Apply animations consistently** using predefined timing constants

## Accessibility

All design system components support:
- Dynamic Type (text scaling)
- VoiceOver compatibility
- High contrast text colors
- Adequate touch target sizes (44pt minimum)
- Clear visual hierarchy

## Future Enhancements

Potential additions to the design system:
- Light mode color variants
- Additional component styles (inputs, dropdowns, modals)
- Icon library integration
- Haptic feedback patterns
- Sound effect system
- Custom transitions and animations
- Responsive layout breakpoints
- Accessibility contrast checker utilities

## Contributing

When adding new design system components:
1. Place in appropriate DesignSystem subdirectory
2. Follow existing naming conventions
3. Include comprehensive documentation comments
4. Add usage examples to this document
5. Test across different screen sizes
6. Verify accessibility compliance
7. Update CHANGELOG with additions
