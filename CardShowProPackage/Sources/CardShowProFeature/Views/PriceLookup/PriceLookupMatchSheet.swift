import SwiftUI

struct PriceLookupMatchSheet: View {
    let matches: [CardMatch]
    let onSelect: (CardMatch) -> Void
    let onCancel: () -> Void

    var body: some View {
        NavigationStack {
            List {
                ForEach(matches) { match in
                    Button {
                        onSelect(match)
                    } label: {
                        HStack(spacing: DesignSystem.Spacing.md) {
                            // Larger Card Image (100x140)
                            if let imageURL = match.imageURL {
                                AsyncImage(url: imageURL) { phase in
                                    switch phase {
                                    case .empty:
                                        ProgressView()
                                            .tint(DesignSystem.Colors.cyan)
                                            .frame(width: 100, height: 140)
                                            .background(DesignSystem.Colors.backgroundTertiary)
                                            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.sm))

                                    case .success(let image):
                                        image
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                            .frame(width: 100, height: 140)
                                            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.sm))
                                            .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)

                                    case .failure:
                                        VStack(spacing: DesignSystem.Spacing.xxxs) {
                                            Image(systemName: "photo")
                                                .font(.system(size: 24))
                                                .foregroundStyle(DesignSystem.Colors.textTertiary)

                                            Text("No Image")
                                                .font(DesignSystem.Typography.caption)
                                                .foregroundStyle(DesignSystem.Colors.textTertiary)
                                        }
                                        .frame(width: 100, height: 140)
                                        .background(DesignSystem.Colors.backgroundTertiary)
                                        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.sm))

                                    @unknown default:
                                        EmptyView()
                                    }
                                }
                            }

                            // Enhanced Card Info
                            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                                // Card Name - Larger and more prominent
                                Text(match.cardName)
                                    .font(DesignSystem.Typography.heading4)
                                    .foregroundStyle(DesignSystem.Colors.textPrimary)
                                    .lineLimit(2)
                                    .fixedSize(horizontal: false, vertical: true)

                                // Set Name - Better spacing
                                Text(match.setName)
                                    .font(DesignSystem.Typography.caption)
                                    .foregroundStyle(DesignSystem.Colors.textSecondary)
                                    .lineLimit(1)

                                // Card Number - Clear display
                                Text("#\(match.cardNumber)")
                                    .font(DesignSystem.Typography.caption)
                                    .foregroundStyle(DesignSystem.Colors.textTertiary)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding(.vertical, DesignSystem.Spacing.xs)
                    }
                    .listRowBackground(DesignSystem.Colors.backgroundSecondary)
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(DesignSystem.Colors.backgroundPrimary)
            .navigationTitle("Select Card")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        onCancel()
                    }
                }
            }
        }
    }
}
