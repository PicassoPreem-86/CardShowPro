import SwiftUI

/// Sheet displayed when card resolution finds multiple possible matches
/// Allows user to pick the correct set, then select the specific card
struct AmbiguousMatchSheet: View {
    let candidates: [LocalCardMatch]
    let suggestedSets: [String]
    let onSelect: (LocalCardMatch) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var searchText = ""
    @State private var selectedSet: String?

    /// Cards filtered by selected set
    private var filteredCandidates: [LocalCardMatch] {
        guard let set = selectedSet else {
            return []
        }
        return candidates.filter { $0.setID == set }
    }

    /// Sets filtered by search text
    private var filteredSets: [String] {
        if searchText.isEmpty {
            return suggestedSets
        }
        return suggestedSets.filter { $0.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "questionmark.circle.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(.yellow)

                    Text("Multiple Cards Found")
                        .font(.title2)
                        .fontWeight(.bold)

                    if let cardNumber = candidates.first?.cardNumber {
                        Text("Found \(candidates.count) cards with #\(cardNumber)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.top)

                // Set picker section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Select a Set")
                        .font(.headline)
                        .padding(.horizontal)

                    // Search field
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(.secondary)
                        TextField("Search sets...", text: $searchText)
                            .textFieldStyle(.plain)
                    }
                    .padding(12)
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    .padding(.horizontal)

                    // Set list
                    ScrollView {
                        LazyVStack(spacing: 8) {
                            ForEach(filteredSets, id: \.self) { setID in
                                SetPickerRow(
                                    setID: setID,
                                    candidateCount: candidates.filter { $0.setID == setID }.count,
                                    isSelected: selectedSet == setID,
                                    onTap: {
                                        withAnimation(.easeInOut(duration: 0.2)) {
                                            selectedSet = setID
                                        }
                                    }
                                )
                            }
                        }
                        .padding(.horizontal)
                    }
                }

                // Card selection section (shown when set is selected)
                if let selected = selectedSet, !filteredCandidates.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Select Your Card")
                            .font(.headline)
                            .padding(.horizontal)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(filteredCandidates, id: \.id) { card in
                                    CardThumbnail(
                                        card: card,
                                        onTap: {
                                            onSelect(card)
                                            dismiss()
                                        }
                                    )
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }

                Spacer()
            }
            .navigationTitle("Choose Card")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

/// Row for selecting a set in the ambiguity sheet
private struct SetPickerRow: View {
    let setID: String
    let candidateCount: Int
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack {
                // Selection indicator
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(isSelected ? .blue : .secondary)
                    .animation(.easeInOut(duration: 0.2), value: isSelected)

                VStack(alignment: .leading, spacing: 4) {
                    Text(setID)
                        .font(.headline)
                        .foregroundStyle(.primary)

                    Text("\(candidateCount) card\(candidateCount == 1 ? "" : "s")")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.blue.opacity(0.1) : Color(.systemGray6))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

/// Thumbnail view for a card in the selection sheet
private struct CardThumbnail: View {
    let card: LocalCardMatch
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                // Card image placeholder
                AsyncImage(url: card.imageURLSmall.flatMap { URL(string: $0) }) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                            .frame(width: 120, height: 168)
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 120, height: 168)
                    case .failure:
                        Image(systemName: "photo")
                            .font(.system(size: 48))
                            .foregroundStyle(.secondary)
                            .frame(width: 120, height: 168)
                    @unknown default:
                        EmptyView()
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)

                // Card info
                VStack(spacing: 2) {
                    Text(card.cardName)
                        .font(.caption)
                        .fontWeight(.medium)
                        .lineLimit(2)
                        .multilineTextAlignment(.center)

                    Text("#\(card.cardNumber)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .frame(width: 120)
            }
            .padding(8)
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    AmbiguousMatchSheet(
        candidates: [
            LocalCardMatch(
                id: "ja_SV9-086",
                cardName: "ホップのバイウールー",
                setName: "Scarlet & Violet 9",
                setID: "SV9",
                cardNumber: "086",
                imageURLSmall: nil,
                rarity: "Common",
                language: .japanese,
                source: .pokemontcg
            ),
            LocalCardMatch(
                id: "ja_SV8-086",
                cardName: "Different Card",
                setName: "Scarlet & Violet 8",
                setID: "SV8",
                cardNumber: "086",
                imageURLSmall: nil,
                rarity: "Common",
                language: .japanese,
                source: .pokemontcg
            ),
            LocalCardMatch(
                id: "ja_neo1-86",
                cardName: "Another Card",
                setName: "Neo Genesis",
                setID: "neo1",
                cardNumber: "086",
                imageURLSmall: nil,
                rarity: "Common",
                language: .japanese,
                source: .pokemontcg
            )
        ],
        suggestedSets: ["SV9", "SV8", "neo1"],
        onSelect: { card in
            print("Selected: \(card.cardName)")
        }
    )
}
