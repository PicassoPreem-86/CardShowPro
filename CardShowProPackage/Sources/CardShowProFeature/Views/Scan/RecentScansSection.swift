import SwiftUI

/// Collapsible section showing recent scans from current session
/// Features running total of prices for bulk scanning scenarios
/// Designed to work as a sliding overlay panel
struct RecentScansSection: View {
    @Binding var isExpanded: Bool
    @State private var recentScansManager = RecentScansManager.shared

    let onLoadPrevious: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Section header (always visible)
            sectionHeader

            // Content
            if isExpanded {
                // Expanded: Full scrollable list
                if recentScansManager.hasScans {
                    ScrollView {
                        scansList
                    }
                } else {
                    expandedEmptyState
                }
            } else {
                // Collapsed: Just a hint
                collapsedHint
            }
        }
    }

    // MARK: - Collapsed Hint

    private var collapsedHint: some View {
        Text(recentScansManager.hasScans
             ? "Tap to view \(recentScansManager.count) scanned card\(recentScansManager.count == 1 ? "" : "s")"
             : "Scanned cards will appear here")
            .font(.system(size: 13))
            .foregroundStyle(.gray)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
    }

    // MARK: - Expanded Empty State

    private var expandedEmptyState: some View {
        VStack(spacing: 12) {
            Spacer()

            Image(systemName: "viewfinder")
                .font(.system(size: 44))
                .foregroundStyle(.gray.opacity(0.5))

            Text("No scans yet")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(.white)

            Text("Tap the camera area above to scan a card")
                .font(.system(size: 14))
                .foregroundStyle(.gray)
                .multilineTextAlignment(.center)

            Spacer()
        }
        .padding(.horizontal, 32)
    }

    // MARK: - Section Header

    private var sectionHeader: some View {
        HStack {
            Text("Recent scans")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.white)

            Spacer()

            // Running total badge
            Text(recentScansManager.formattedTotal + " total")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Color(red: 0.5, green: 1.0, blue: 0.0)) // Green
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    // MARK: - Scans List (for expanded state)

    private var scansList: some View {
        LazyVStack(spacing: 0) {
            ForEach(recentScansManager.scans) { scan in
                scanRow(scan)

                if scan.id != recentScansManager.scans.last?.id {
                    Divider()
                        .background(Color.white.opacity(0.1))
                }
            }

            // Clear all button
            if recentScansManager.count > 0 {
                Button {
                    withAnimation {
                        recentScansManager.clearAll()
                    }
                    HapticManager.shared.light()
                } label: {
                    Text("Clear All")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.red.opacity(0.8))
                        .padding(.vertical, 16)
                }
            }

            // Bottom padding for safe area
            Spacer()
                .frame(height: 20)
        }
        .padding(.horizontal, 16)
    }

    private func scanRow(_ scan: RecentScan) -> some View {
        HStack(spacing: 12) {
            // Thumbnail
            if let url = scan.thumbnailURL {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 40, height: 56)
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                    case .failure, .empty:
                        placeholderThumbnail
                    @unknown default:
                        placeholderThumbnail
                    }
                }
            } else {
                placeholderThumbnail
            }

            // Card info
            VStack(alignment: .leading, spacing: 2) {
                Text(scan.cardName)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.white)
                    .lineLimit(1)

                Text(scan.setName)
                    .font(.system(size: 12))
                    .foregroundStyle(.gray)
                    .lineLimit(1)
            }

            Spacer()

            // Price and time
            VStack(alignment: .trailing, spacing: 2) {
                Text(scan.formattedPrice)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color(red: 0.5, green: 1.0, blue: 0.0)) // Green

                Text(scan.timeAgo)
                    .font(.system(size: 11))
                    .foregroundStyle(.gray)
            }
        }
        .padding(.vertical, 10)
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) {
                withAnimation {
                    recentScansManager.removeScan(id: scan.id)
                }
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }

    private var placeholderThumbnail: some View {
        RoundedRectangle(cornerRadius: 4)
            .fill(Color.white.opacity(0.1))
            .frame(width: 40, height: 56)
            .overlay(
                Image(systemName: "photo")
                    .font(.system(size: 14))
                    .foregroundStyle(.gray)
            )
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 8) {
            Text("Scanned cards will appear here")
                .font(.system(size: 14))
                .foregroundStyle(.gray)

            Button(action: onLoadPrevious) {
                Text("Tap to load previous scans.")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color(red: 0.5, green: 1.0, blue: 0.0)) // Green
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(white: 0.12))
        )
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
    }
}

// MARK: - Preview

#Preview("Empty State") {
    ZStack {
        Color.black.ignoresSafeArea()

        VStack {
            Spacer()
            RecentScansSection(
                isExpanded: .constant(true),
                onLoadPrevious: {}
            )
        }
    }
}

#Preview("With Scans") {
    ZStack {
        Color.black.ignoresSafeArea()

        VStack {
            Spacer()

            RecentScansSection(
                isExpanded: .constant(true),
                onLoadPrevious: {}
            )
            .onAppear {
                let manager = RecentScansManager.shared
                manager.addScan(
                    cardName: "Charizard VMAX",
                    setName: "Shining Fates",
                    price: 125.00
                )
                manager.addScan(
                    cardName: "Pikachu V",
                    setName: "Vivid Voltage",
                    price: 15.50
                )
            }
        }
    }
}
