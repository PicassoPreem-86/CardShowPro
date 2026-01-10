import SwiftUI

/// View for confirming and editing scanned card details before saving
struct CardConfirmationView: View {
    @Environment(\.dismiss) private var dismiss

    let cardImage: UIImage
    let recognitionResult: RecognitionResult
    let pricing: CardPricing?
    let slabResult: SlabRecognitionResult?

    var onConfirm: (RecognitionResult, CardPricing?) -> Void
    var onRescan: () -> Void

    @State private var cardName: String
    @State private var setName: String
    @State private var cardNumber: String
    @State private var estimatedValue: Double

    init(
        cardImage: UIImage,
        recognitionResult: RecognitionResult,
        pricing: CardPricing?,
        slabResult: SlabRecognitionResult? = nil,
        onConfirm: @escaping (RecognitionResult, CardPricing?) -> Void,
        onRescan: @escaping () -> Void
    ) {
        self.cardImage = cardImage
        self.recognitionResult = recognitionResult
        self.pricing = pricing
        self.slabResult = slabResult
        self.onConfirm = onConfirm
        self.onRescan = onRescan

        // Initialize state
        _cardName = State(initialValue: recognitionResult.cardName)
        _setName = State(initialValue: recognitionResult.setName)
        _cardNumber = State(initialValue: recognitionResult.cardNumber)
        _estimatedValue = State(initialValue: pricing?.estimatedValue ?? 0)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Card Image
                    cardImageSection

                    // Confidence Badge
                    confidenceBadge

                    // Grading Section (for graded slabs)
                    if let slabResult = slabResult, slabResult.isGraded {
                        gradingSection
                    }

                    // Card Details
                    cardDetailsSection

                    // Pricing Section
                    pricingSection

                    // Action Buttons
                    actionButtons
                }
                .padding()
            }
            .navigationTitle("Confirm Card")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }

    // MARK: - Card Image Section

    private var cardImageSection: some View {
        Image(uiImage: cardImage)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(maxWidth: 300)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
    }

    // MARK: - Confidence Badge

    private var confidenceBadge: some View {
        VStack(spacing: DesignSystem.Spacing.xs) {
            // Main confidence badge
            HStack(spacing: 8) {
                Image(systemName: confidenceIcon)
                    .font(.subheadline)
                    .foregroundStyle(confidenceColor)

                Text("Confidence: \(Int(recognitionResult.confidence * 100))%")
                    .font(DesignSystem.Typography.labelLarge)
                    .fontWeight(.semibold)

                Text("(\(recognitionResult.confidenceLevel.rawValue))")
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
            }
            .padding(.horizontal, DesignSystem.Spacing.sm)
            .padding(.vertical, DesignSystem.Spacing.xxs)
            .background(confidenceColor.opacity(0.15))
            .clipShape(Capsule())

            // Warning message for low confidence
            if recognitionResult.confidence < 0.75 {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(DesignSystem.Typography.captionSmall)
                    Text(confidenceWarningMessage)
                        .font(DesignSystem.Typography.caption)
                }
                .foregroundStyle(confidenceColor)
                .padding(.horizontal, DesignSystem.Spacing.sm)
                .padding(.vertical, DesignSystem.Spacing.xxs)
                .background(confidenceColor.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.sm))
            }
        }
    }

    private var confidenceIcon: String {
        switch recognitionResult.confidenceLevel {
        case .veryHigh: return "checkmark.seal.fill"
        case .high: return "checkmark.circle.fill"
        case .medium: return "exclamationmark.triangle.fill"
        case .low: return "xmark.octagon.fill"
        }
    }

    private var confidenceColor: Color {
        switch recognitionResult.confidenceLevel {
        case .veryHigh: return DesignSystem.Colors.success
        case .high: return DesignSystem.Colors.electricBlue
        case .medium: return DesignSystem.Colors.warning
        case .low: return DesignSystem.Colors.error
        }
    }

    private var confidenceWarningMessage: String {
        switch recognitionResult.confidenceLevel {
        case .medium: return "Please verify card details before adding"
        case .low: return "Low confidence - review all information carefully"
        default: return ""
        }
    }

    // MARK: - Grading Section

    private var gradingSection: some View {
        VStack(spacing: 16) {
            // Grading Header
            HStack {
                Image(systemName: "seal.fill")
                    .font(.headline)
                    .foregroundStyle(gradingCompanyColor)

                Text("Graded Card")
                    .font(.headline)

                Spacer()

                if let company = slabResult?.gradingCompany {
                    Text(company.displayName)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(gradingCompanyColor)
                        .clipShape(Capsule())
                }
            }

            VStack(spacing: 12) {
                // Grade
                if let grade = slabResult?.grade {
                    ConfirmationDetailRow(label: "Grade", icon: "star.fill") {
                        HStack {
                            Text(grade)
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundStyle(gradingCompanyColor)

                            Spacer()

                            // Grade badge
                            gradeQualityBadge(for: grade)
                        }
                    }
                }

                // Certification Number
                if let certNumber = slabResult?.certificationNumber {
                    ConfirmationDetailRow(label: "Certification #", icon: "number.circle.fill") {
                        HStack {
                            Text(certNumber)
                                .font(.body)
                                .fontWeight(.medium)
                                .textSelection(.enabled)

                            Spacer()

                            Button {
                                UIPasteboard.general.string = certNumber
                            } label: {
                                Image(systemName: "doc.on.doc")
                                    .font(.caption)
                                    .foregroundStyle(.blue)
                            }
                        }
                    }
                }

                // Sub-grades (BGS only)
                if let subGrades = slabResult?.subGrades {
                    Divider()

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Sub-Grades")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(.secondary)

                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 8) {
                            if let centering = subGrades.centering {
                                subGradeCard(label: "Centering", grade: centering)
                            }
                            if let corners = subGrades.corners {
                                subGradeCard(label: "Corners", grade: corners)
                            }
                            if let edges = subGrades.edges {
                                subGradeCard(label: "Edges", grade: edges)
                            }
                            if let surface = subGrades.surface {
                                subGradeCard(label: "Surface", grade: surface)
                            }
                        }
                    }
                }
            }
            .padding()
            .background(Color(uiColor: .secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    private var gradingCompanyColor: Color {
        guard let company = slabResult?.gradingCompany else {
            return .blue
        }

        switch company {
        case .psa: return Color(red: 0.85, green: 0.15, blue: 0.15) // PSA Red
        case .bgs: return Color(red: 0.0, green: 0.4, blue: 0.8) // BGS Blue
        case .cgc: return Color(red: 0.95, green: 0.6, blue: 0.0) // CGC Orange
        }
    }

    private func gradeQualityBadge(for grade: String) -> some View {
        let qualityText: String
        let qualityColor: Color

        // Parse numeric grade
        let numericGrade = Double(grade.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()) ?? 0

        switch numericGrade {
        case 10:
            qualityText = "GEM MINT"
            qualityColor = .green
        case 9.5:
            qualityText = "MINT+"
            qualityColor = .green
        case 9:
            qualityText = "MINT"
            qualityColor = .blue
        case 8.5:
            qualityText = "NM/MT+"
            qualityColor = .blue
        case 8:
            qualityText = "NM/MT"
            qualityColor = .blue
        case 7...7.5:
            qualityText = "NM"
            qualityColor = .orange
        default:
            qualityText = "GRADED"
            qualityColor = .gray
        }

        return Text(qualityText)
            .font(.caption2)
            .fontWeight(.bold)
            .foregroundStyle(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(qualityColor)
            .clipShape(RoundedRectangle(cornerRadius: 4))
    }

    private func subGradeCard(label: String, grade: Double) -> some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)

            Text(String(format: "%.1f", grade))
                .font(.body)
                .fontWeight(.bold)
                .foregroundStyle(subGradeColor(for: grade))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(Color(uiColor: .tertiarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private func subGradeColor(for grade: Double) -> Color {
        switch grade {
        case 10: return .green
        case 9.5: return .blue
        case 9: return .blue
        case 8...8.5: return .orange
        default: return .gray
        }
    }

    // MARK: - Card Details Section

    private var cardDetailsSection: some View {
        VStack(spacing: 16) {
            Text("Card Details")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)

            VStack(spacing: 12) {
                ConfirmationDetailRow(label: "Card Name", icon: "star.fill") {
                    TextField("Card Name", text: $cardName)
                        .textFieldStyle(.roundedBorder)
                }

                ConfirmationDetailRow(label: "Set Name", icon: "square.stack.3d.up.fill") {
                    TextField("Set Name", text: $setName)
                        .textFieldStyle(.roundedBorder)
                }

                ConfirmationDetailRow(label: "Card Number", icon: "number") {
                    TextField("Card Number", text: $cardNumber)
                        .textFieldStyle(.roundedBorder)
                }

                if let rarity = recognitionResult.rarity {
                    ConfirmationDetailRow(label: "Rarity", icon: "sparkles") {
                        Text(rarity)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    // MARK: - Pricing Section

    private var pricingSection: some View {
        VStack(spacing: 16) {
            Text("Pricing")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)

            VStack(spacing: 12) {
                if let pricing = pricing {
                    ConfirmationDetailRow(label: "Market Price", icon: "dollarsign.circle.fill") {
                        if let market = pricing.marketPrice {
                            Text("$\(String(format: "%.2f", market))")
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundStyle(.green)
                        } else {
                            Text("N/A")
                                .foregroundStyle(.secondary)
                        }
                    }

                    if let low = pricing.lowPrice, let high = pricing.highPrice {
                        ConfirmationDetailRow(label: "Price Range", icon: "chart.line.uptrend.xyaxis") {
                            Text("$\(String(format: "%.2f", low)) - $\(String(format: "%.2f", high))")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }

                    ConfirmationDetailRow(label: "Source", icon: "globe") {
                        Text(pricing.source.rawValue)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } else {
                    ConfirmationDetailRow(label: "Estimated Value", icon: "dollarsign.circle") {
                        HStack {
                            Text("$")
                            TextField("0.00", value: $estimatedValue, format: .number)
                                .keyboardType(.decimalPad)
                                .textFieldStyle(.roundedBorder)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        VStack(spacing: 12) {
            // Confirm Button
            Button {
                confirmCard()
            } label: {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                    Text("Add to Collection")
                }
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.green)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            // Rescan Button
            Button {
                onRescan()
                dismiss()
            } label: {
                HStack {
                    Image(systemName: "camera.fill")
                    Text("Rescan Card")
                }
                .font(.headline)
                .foregroundStyle(.blue)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding(.top, 8)
    }

    // MARK: - Actions

    private func confirmCard() {
        // Create updated recognition result with edited values
        let updatedResult = RecognitionResult(
            cardName: cardName,
            setName: setName,
            cardNumber: cardNumber,
            confidence: recognitionResult.confidence,
            game: recognitionResult.game,
            rarity: recognitionResult.rarity,
            cardType: recognitionResult.cardType,
            subtype: recognitionResult.subtype,
            supertype: recognitionResult.supertype
        )

        // Create updated pricing if manually edited
        let updatedPricing = pricing ?? CardPricing(
            marketPrice: estimatedValue,
            lowPrice: nil,
            midPrice: nil,
            highPrice: nil,
            directLowPrice: nil,
            source: .unknown,
            lastUpdated: Date()
        )

        onConfirm(updatedResult, updatedPricing)
        dismiss()
    }
}

// MARK: - Confirmation Detail Row Component

private struct ConfirmationDetailRow<Content: View>: View {
    let label: String
    let icon: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundStyle(.blue)

                Text(label)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
            }

            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Preview

#Preview {
    CardConfirmationView(
        cardImage: UIImage(systemName: "photo")!,
        recognitionResult: RecognitionResult(
            cardName: "Charizard VMAX",
            setName: "Darkness Ablaze",
            cardNumber: "020",
            confidence: 0.94,
            game: .pokemon,
            rarity: "Rare Holo VMAX",
            cardType: "Pokemon",
            subtype: nil,
            supertype: "Pokemon"
        ),
        pricing: CardPricing(
            marketPrice: 125.99,
            lowPrice: 98.50,
            midPrice: 115.00,
            highPrice: 145.00,
            directLowPrice: 105.00,
            source: .tcgPlayer,
            lastUpdated: Date()
        ),
        onConfirm: { _, _ in },
        onRescan: { }
    )
}
