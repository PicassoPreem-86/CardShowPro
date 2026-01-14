import SwiftUI

/// Recent searches quick-select component
/// Displays last 10 searches as tappable pills for instant lookup
@MainActor
struct RecentSearchesView: View {
    let searches: [RecentSearch]
    let onSelect: (String) -> Void
    let onClear: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
            // Header
            HStack {
                Image(systemName: "clock.arrow.circlepath")
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)

                Text("Recent Searches")
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)

                Spacer()

                Button {
                    onClear()
                } label: {
                    Text("Clear")
                        .font(DesignSystem.Typography.caption)
                        .foregroundStyle(DesignSystem.Colors.thunderYellow)
                }
                .accessibilityLabel("Clear all recent searches")
            }

            // Horizontal scrolling search pills
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: DesignSystem.Spacing.xs) {
                    ForEach(searches) { search in
                        RecentSearchPill(
                            cardName: search.cardName,
                            timestamp: search.timestamp,
                            onTap: { onSelect(search.cardName) }
                        )
                    }
                }
            }
        }
        .padding(.horizontal)
    }
}

/// Individual search pill component
private struct RecentSearchPill: View {
    let cardName: String
    let timestamp: Date
    let onTap: () -> Void

    private var timeAgo: String {
        let interval = Date().timeIntervalSince(timestamp)
        if interval < 60 {
            return "now"
        } else if interval < 3600 {
            return "\(Int(interval / 60))m"
        } else if interval < 86400 {
            return "\(Int(interval / 3600))h"
        } else {
            return "\(Int(interval / 86400))d"
        }
    }

    var body: some View {
        Button {
            HapticManager.shared.light()
            onTap()
        } label: {
            VStack(alignment: .leading, spacing: 2) {
                Text(cardName)
                    .font(DesignSystem.Typography.label)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)
                    .lineLimit(1)

                Text(timeAgo)
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(DesignSystem.Colors.textTertiary)
            }
            .padding(.horizontal, DesignSystem.Spacing.sm)
            .padding(.vertical, DesignSystem.Spacing.xs)
            .background(DesignSystem.Colors.backgroundTertiary)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md))
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                    .stroke(DesignSystem.Colors.borderSecondary, lineWidth: 1)
            )
        }
        .accessibilityLabel("Recent search: \(cardName), \(timeAgo) ago")
    }
}

// MARK: - Previews

#Preview("Recent Searches - 3 Items") {
    RecentSearchesView(
        searches: [
            RecentSearch(cardName: "Pikachu", timestamp: Date()),
            RecentSearch(cardName: "Charizard", timestamp: Date().addingTimeInterval(-300)),
            RecentSearch(cardName: "Mewtwo", timestamp: Date().addingTimeInterval(-3600))
        ],
        onSelect: { name in print("Selected: \(name)") },
        onClear: { print("Cleared") }
    )
    .padding()
    .background(DesignSystem.Colors.backgroundPrimary)
}

#Preview("Recent Searches - 10 Items") {
    RecentSearchesView(
        searches: [
            RecentSearch(cardName: "Pikachu", timestamp: Date()),
            RecentSearch(cardName: "Charizard", timestamp: Date().addingTimeInterval(-300)),
            RecentSearch(cardName: "Mewtwo", timestamp: Date().addingTimeInterval(-3600)),
            RecentSearch(cardName: "Blastoise", timestamp: Date().addingTimeInterval(-7200)),
            RecentSearch(cardName: "Venusaur", timestamp: Date().addingTimeInterval(-86400)),
            RecentSearch(cardName: "Gyarados", timestamp: Date().addingTimeInterval(-172800)),
            RecentSearch(cardName: "Dragonite", timestamp: Date().addingTimeInterval(-259200)),
            RecentSearch(cardName: "Alakazam", timestamp: Date().addingTimeInterval(-345600)),
            RecentSearch(cardName: "Gengar", timestamp: Date().addingTimeInterval(-432000)),
            RecentSearch(cardName: "Machamp", timestamp: Date().addingTimeInterval(-518400))
        ],
        onSelect: { name in print("Selected: \(name)") },
        onClear: { print("Cleared") }
    )
    .padding()
    .background(DesignSystem.Colors.backgroundPrimary)
}

#Preview("Recent Searches - Long Names") {
    RecentSearchesView(
        searches: [
            RecentSearch(cardName: "Pikachu ex (Full Art)", timestamp: Date()),
            RecentSearch(cardName: "Charizard VMAX", timestamp: Date().addingTimeInterval(-300)),
            RecentSearch(cardName: "Mewtwo & Mew GX", timestamp: Date().addingTimeInterval(-3600))
        ],
        onSelect: { name in print("Selected: \(name)") },
        onClear: { print("Cleared") }
    )
    .padding()
    .background(DesignSystem.Colors.backgroundPrimary)
}
