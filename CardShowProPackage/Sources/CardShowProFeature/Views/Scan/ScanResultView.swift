import SwiftUI
import SwiftData

/// View displaying OCR results with editable fields and lookup action
/// Shows captured image, extracted card info, and allows user to search for prices
struct ScanResultView: View {
    let capturedImage: UIImage
    let ocrResult: CardOCRService.OCRResult
    let onRetake: () -> Void
    let onLookupComplete: (CardMatch) -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var cardName: String
    @State private var cardNumber: String
    @State private var isSearching = false
    @State private var searchResults: [CardMatch] = []
    @State private var errorMessage: String?
    @State private var showMatchSelection = false

    private let pokemonService = PokemonTCGService.shared

    init(
        capturedImage: UIImage,
        ocrResult: CardOCRService.OCRResult,
        onRetake: @escaping () -> Void,
        onLookupComplete: @escaping (CardMatch) -> Void
    ) {
        self.capturedImage = capturedImage
        self.ocrResult = ocrResult
        self.onRetake = onRetake
        self.onLookupComplete = onLookupComplete
        self._cardName = State(initialValue: ocrResult.cardName ?? "")
        self._cardNumber = State(initialValue: ocrResult.cardNumber ?? "")
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: DesignSystem.Spacing.lg) {
                    // Captured Image Preview
                    imagePreview

                    // OCR Confidence Indicator
                    if ocrResult.confidence < 0.7 && ocrResult.hasValidData {
                        confidenceWarning
                    }

                    // Editable Fields
                    editableFields

                    // Search Results or Action Buttons
                    if isSearching {
                        loadingView
                    } else if !searchResults.isEmpty {
                        resultsSection
                    } else {
                        actionButtons
                    }

                    // Error Message
                    if let errorMessage {
                        errorView(errorMessage)
                    }

                    // All Detected Text (Debug/Help)
                    if !ocrResult.allText.isEmpty {
                        detectedTextSection
                    }
                }
                .padding(DesignSystem.Spacing.md)
            }
            .background(DesignSystem.Colors.backgroundPrimary)
            .navigationTitle("Scan Result")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Retake") {
                        onRetake()
                        dismiss()
                    }
                    .foregroundStyle(DesignSystem.Colors.thunderYellow)
                }
            }
            .sheet(isPresented: $showMatchSelection) {
                matchSelectionSheet
            }
        }
    }

    // MARK: - Subviews

    private var imagePreview: some View {
        Image(uiImage: capturedImage)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(maxHeight: 280)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg))
            .shadow(color: .black.opacity(0.3), radius: 8, y: 4)
    }

    private var confidenceWarning: some View {
        HStack(spacing: DesignSystem.Spacing.sm) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(DesignSystem.Colors.warning)
            Text("Low confidence - please verify the text below")
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(DesignSystem.Colors.textSecondary)
        }
        .padding(DesignSystem.Spacing.sm)
        .background(DesignSystem.Colors.warning.opacity(0.15))
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.sm))
    }

    private var editableFields: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            // Card Name Field
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                Text("Card Name")
                    .font(DesignSystem.Typography.labelLarge)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)

                TextField("Enter card name", text: $cardName)
                    .font(DesignSystem.Typography.body)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)
                    .padding(DesignSystem.Spacing.sm)
                    .background(DesignSystem.Colors.backgroundTertiary)
                    .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md))
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                            .stroke(DesignSystem.Colors.borderSecondary, lineWidth: 1)
                    )
                    .autocorrectionDisabled()
                    .textContentType(.name)
            }

            // Card Number Field
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                Text("Card Number (Optional)")
                    .font(DesignSystem.Typography.labelLarge)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)

                TextField("e.g., 25 or 25/102", text: $cardNumber)
                    .font(DesignSystem.Typography.body)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)
                    .padding(DesignSystem.Spacing.sm)
                    .background(DesignSystem.Colors.backgroundTertiary)
                    .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md))
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                            .stroke(DesignSystem.Colors.borderSecondary, lineWidth: 1)
                    )
                    .keyboardType(.numbersAndPunctuation)
            }
        }
    }

    private var actionButtons: some View {
        VStack(spacing: DesignSystem.Spacing.sm) {
            // Look Up Price Button
            Button {
                performLookup()
            } label: {
                HStack(spacing: DesignSystem.Spacing.sm) {
                    Image(systemName: "magnifyingglass")
                    Text("Look Up Price")
                }
                .font(DesignSystem.Typography.labelLarge)
                .fontWeight(.semibold)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(DesignSystem.Spacing.md)
                .background(canLookup ? DesignSystem.Colors.thunderYellow : Color.gray)
                .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md))
            }
            .disabled(!canLookup)

            // Retake Photo Button
            Button {
                onRetake()
                dismiss()
            } label: {
                HStack(spacing: DesignSystem.Spacing.sm) {
                    Image(systemName: "camera.fill")
                    Text("Retake Photo")
                }
                .font(DesignSystem.Typography.body)
                .foregroundStyle(DesignSystem.Colors.textSecondary)
                .frame(maxWidth: .infinity)
                .padding(DesignSystem.Spacing.md)
                .background(DesignSystem.Colors.backgroundTertiary)
                .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md))
            }
        }
    }

    private var loadingView: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            ProgressView()
                .tint(DesignSystem.Colors.thunderYellow)
            Text("Searching for cards...")
                .font(DesignSystem.Typography.body)
                .foregroundStyle(DesignSystem.Colors.textSecondary)
        }
        .padding(DesignSystem.Spacing.lg)
    }

    private var resultsSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            Text("Found \(searchResults.count) match\(searchResults.count == 1 ? "" : "es")")
                .font(DesignSystem.Typography.labelLarge)
                .foregroundStyle(DesignSystem.Colors.textPrimary)

            ForEach(searchResults.prefix(5)) { result in
                resultCard(result)
            }

            if searchResults.count > 5 {
                Button("Show all \(searchResults.count) results") {
                    showMatchSelection = true
                }
                .font(DesignSystem.Typography.body)
                .foregroundStyle(DesignSystem.Colors.thunderYellow)
            }

            // New Search Button
            Button {
                searchResults = []
                errorMessage = nil
            } label: {
                Text("New Search")
                    .font(DesignSystem.Typography.body)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
            }
        }
    }

    private func resultCard(_ result: CardMatch) -> some View {
        Button {
            onLookupComplete(result)
            dismiss()
        } label: {
            HStack(spacing: DesignSystem.Spacing.md) {
                // Card Image
                if let imageURL = result.imageURL {
                    AsyncImage(url: imageURL) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                        case .failure, .empty:
                            cardPlaceholder
                        @unknown default:
                            cardPlaceholder
                        }
                    }
                    .frame(width: 60, height: 84)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                } else {
                    cardPlaceholder
                }

                // Card Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(result.cardName)
                        .font(DesignSystem.Typography.labelLarge)
                        .fontWeight(.semibold)
                        .foregroundStyle(DesignSystem.Colors.textPrimary)

                    Text(result.setName)
                        .font(DesignSystem.Typography.caption)
                        .foregroundStyle(DesignSystem.Colors.textSecondary)

                    Text("#\(result.cardNumber)")
                        .font(DesignSystem.Typography.caption)
                        .foregroundStyle(DesignSystem.Colors.textTertiary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundStyle(DesignSystem.Colors.textTertiary)
            }
            .padding(DesignSystem.Spacing.sm)
            .background(DesignSystem.Colors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md))
        }
    }

    private var cardPlaceholder: some View {
        RoundedRectangle(cornerRadius: 6)
            .fill(DesignSystem.Colors.backgroundTertiary)
            .frame(width: 60, height: 84)
            .overlay {
                Image(systemName: "photo")
                    .foregroundStyle(DesignSystem.Colors.textTertiary)
            }
    }

    private func errorView(_ message: String) -> some View {
        HStack(spacing: DesignSystem.Spacing.sm) {
            Image(systemName: "exclamationmark.circle.fill")
                .foregroundStyle(DesignSystem.Colors.error)
            Text(message)
                .font(DesignSystem.Typography.body)
                .foregroundStyle(DesignSystem.Colors.textSecondary)
        }
        .padding(DesignSystem.Spacing.md)
        .background(DesignSystem.Colors.error.opacity(0.15))
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md))
    }

    private var detectedTextSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
            Text("All Detected Text")
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(DesignSystem.Colors.textTertiary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: DesignSystem.Spacing.xs) {
                    ForEach(ocrResult.allText, id: \.self) { text in
                        Text(text)
                            .font(DesignSystem.Typography.caption)
                            .foregroundStyle(DesignSystem.Colors.textSecondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(DesignSystem.Colors.backgroundTertiary)
                            .clipShape(Capsule())
                            .onTapGesture {
                                // Allow user to tap to use this text
                                if cardName.isEmpty {
                                    cardName = text
                                } else {
                                    cardNumber = text
                                }
                                HapticManager.shared.light()
                            }
                    }
                }
            }
        }
        .padding(.top, DesignSystem.Spacing.md)
    }

    private var matchSelectionSheet: some View {
        NavigationStack {
            List(searchResults) { result in
                Button {
                    showMatchSelection = false
                    onLookupComplete(result)
                    dismiss()
                } label: {
                    HStack(spacing: DesignSystem.Spacing.md) {
                        if let imageURL = result.imageURL {
                            AsyncImage(url: imageURL) { phase in
                                if case .success(let image) = phase {
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                }
                            }
                            .frame(width: 50, height: 70)
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text(result.cardName)
                                .font(.headline)
                            Text("\(result.setName) • #\(result.cardNumber)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Select Card")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        showMatchSelection = false
                    }
                }
            }
        }
    }

    // MARK: - Computed Properties

    private var canLookup: Bool {
        !cardName.trimmingCharacters(in: .whitespaces).isEmpty
    }

    // MARK: - Actions

    private func performLookup() {
        guard canLookup else { return }

        isSearching = true
        errorMessage = nil
        searchResults = []

        Task {
            do {
                let results = try await pokemonService.searchCard(
                    name: cardName.trimmingCharacters(in: .whitespaces),
                    number: cardNumber.isEmpty ? nil : cardNumber.trimmingCharacters(in: .whitespaces)
                )

                await MainActor.run {
                    isSearching = false
                    searchResults = results

                    if results.isEmpty {
                        errorMessage = "No cards found matching '\(cardName)'. Try adjusting the name."
                    } else if results.count == 1 {
                        // Auto-select single match
                        onLookupComplete(results[0])
                        dismiss()
                    }
                }
            } catch {
                await MainActor.run {
                    isSearching = false
                    errorMessage = "Search failed: \(error.localizedDescription)"
                }
            }
        }
    }
}
