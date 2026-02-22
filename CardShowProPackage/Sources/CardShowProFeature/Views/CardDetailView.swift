import SwiftUI
import SwiftData

struct CardDetailView: View {
    let card: InventoryCard
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var showEditSheet = false
    @State private var showDeleteAlert = false
    @State private var showShareSheet = false
    @State private var showZoomView = false
    @State private var showSellSheet = false
    @State private var showListedSheet = false
    @State private var showSaveError = false
    @State private var showPriceAlert = false
    @State private var priceInput = ""
    @State private var isEditingNotes = false
    @State private var editedNotes = ""
    @State private var showReturnSheet = false
    @State private var showShippedSheet = false

    private var purchasePrice: Double {
        card.purchaseCost ?? 0
    }

    private var profit: Double {
        card.profit
    }

    private var roi: Double {
        card.roi
    }

    private var category: CardCategory { card.cardCategory }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Hero Card Image
                heroImage

                // Content Sections
                VStack(spacing: 20) {
                    // Value & Pricing
                    valueSectionCard

                    // Grading (only if graded)
                    if card.isGraded {
                        gradingSectionCard
                    }

                    // Details
                    detailsSectionCard

                    // Acquisition Info
                    acquisitionSectionCard

                    // Tags
                    if !card.tagsArray.isEmpty {
                        tagsSectionCard
                    }

                    // Storage Location
                    if let location = card.storageLocation, !location.isEmpty {
                        storageSectionCard(location: location)
                    }

                    // Lifecycle status & actions
                    lifecycleSection

                    // Shipping/Tracking (when shipped)
                    if card.cardStatus == .shipped || card.cardStatus == .sold {
                        if card.trackingNumber != nil {
                            shippingSectionCard
                        }
                    }

                    // Return Info (if returned)
                    if card.isReturned {
                        returnSectionCard
                    }

                    // Activity Timeline
                    timelineSectionCard

                    // Notes
                    notesSectionCard

                    // Actions
                    actionsSection
                }
                .padding()
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(card.cardName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showEditSheet = true
                } label: {
                    Text("Edit")
                        .fontWeight(.semibold)
                        .foregroundStyle(.cyan)
                }
            }
        }
        .sheet(isPresented: $showEditSheet) {
            AddEditItemView(cardToEdit: card)
        }
        .alert("Delete Card", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deleteCard()
            }
        } message: {
            Text("Are you sure you want to delete \(card.cardName)? This action cannot be undone.")
        }
        .sheet(isPresented: $showSellSheet) {
            SellCardView(card: card)
        }
        .sheet(isPresented: $showListedSheet) {
            MarkAsListedView(card: card)
        }
        .sheet(isPresented: $showReturnSheet) {
            ReturnCardView(card: card)
        }
        .sheet(isPresented: $showShippedSheet) {
            MarkAsShippedView(card: card)
        }
        .fullScreenCover(isPresented: $showZoomView) {
            if let image = card.image {
                ZoomableImageView(image: image)
            }
        }
        .alert("Save Failed", isPresented: $showSaveError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("The change could not be saved. Please try again.")
        }
        .alert("Update Market Value", isPresented: $showPriceAlert) {
            TextField("Price", text: $priceInput)
                .keyboardType(.decimalPad)
            Button("Cancel", role: .cancel) { }
            Button("Update") {
                if let newPrice = Double(priceInput), newPrice > 0 {
                    card.marketValue = newPrice
                    do {
                        try modelContext.save()
                        HapticManager.shared.light()
                    } catch {
                        showSaveError = true
                    }
                }
            }
        } message: {
            Text("Enter the new market value for this card.")
        }
    }

    // MARK: - Hero Image
    private var heroImage: some View {
        ZStack(alignment: .bottomTrailing) {
            if let image = card.image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: 400)
                    .clipped()
                    .onTapGesture {
                        showZoomView = true
                    }
                    .accessibilityLabel("Card image")
                    .accessibilityHint("Double tap to view full screen")

                // Tap to expand badge
                HStack(spacing: 6) {
                    Image(systemName: "arrow.up.left.and.arrow.down.right")
                        .font(DesignSystem.Typography.captionSmall)
                    Text("Tap to expand")
                        .font(DesignSystem.Typography.caption)
                }
                .foregroundStyle(.white)
                .padding(.horizontal, DesignSystem.Spacing.xs)
                .padding(.vertical, 6)
                .background(.black.opacity(0.6))
                .clipShape(Capsule())
                .padding(DesignSystem.Spacing.sm)
            } else {
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(.systemGray6),
                                Color(.systemGray5)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(height: 400)
                    .overlay {
                        VStack(spacing: 12) {
                            Image(systemName: "photo")
                                .font(.system(size: 60))
                                .foregroundStyle(.secondary)
                            Text("No Image Available")
                                .font(.headline)
                                .foregroundStyle(.secondary)
                        }
                    }
            }
        }
    }

    // MARK: - Value Section
    private var valueSectionCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("VALUE & PRICING")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)

            VStack(spacing: 16) {
                // Market Value - Hero (tappable for quick update)
                Button {
                    priceInput = String(format: "%.2f", card.marketValue)
                    showPriceAlert = true
                } label: {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Market Value")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Image(systemName: "pencil.circle")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Text("$\(String(format: "%.2f", card.marketValue))")
                            .font(.system(size: 42, weight: .bold, design: .rounded))
                            .foregroundStyle(.cyan)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.plain)

                Divider()

                // Purchase Price & Profit
                HStack(spacing: 24) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Purchase Price")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("$\(String(format: "%.2f", purchasePrice))")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundStyle(.white)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Profit")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("$\(String(format: "%.2f", profit))")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundStyle(.green)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                // ROI Badge
                HStack {
                    Spacer()
                    HStack(spacing: 6) {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .font(.caption)
                        Text("ROI: \(String(format: "%.0f", roi))%")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }
                    .foregroundStyle(.green)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(Color.green.opacity(0.15))
                    )
                    Spacer()
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: .black.opacity(0.05), radius: 5)
        }
    }

    // MARK: - Grading Section
    private var gradingSectionCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("GRADING")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)

            VStack(spacing: 12) {
                // Service + Grade badge
                HStack {
                    if let display = card.gradeDisplay {
                        Text(display)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                    }
                    Spacer()
                    if let service = card.gradingService {
                        Text(service)
                            .font(DesignSystem.Typography.captionBold)
                            .foregroundStyle(DesignSystem.Colors.thunderYellow)
                            .padding(.horizontal, DesignSystem.Spacing.xxs)
                            .padding(.vertical, 4)
                            .background(DesignSystem.Colors.thunderYellow.opacity(0.15))
                            .clipShape(Capsule())
                    }
                }

                Divider()

                // Cert Number
                if let cert = card.certNumber, !cert.isEmpty {
                    HStack(spacing: 16) {
                        Image(systemName: "number.circle.fill")
                            .font(.title3)
                            .foregroundStyle(DesignSystem.Colors.thunderYellow)
                            .frame(width: 28)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Cert Number")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(cert)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundStyle(.white)
                        }

                        Spacer()

                        Button {
                            UIPasteboard.general.string = cert
                            HapticManager.shared.light()
                        } label: {
                            Image(systemName: "doc.on.doc")
                                .font(.caption)
                                .foregroundStyle(.cyan)
                        }
                    }
                }

                // Grading Cost
                if let cost = card.gradingCost {
                    HStack(spacing: 16) {
                        Image(systemName: "dollarsign.circle.fill")
                            .font(.title3)
                            .foregroundStyle(.orange)
                            .frame(width: 28)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Grading Cost")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text("$\(String(format: "%.2f", cost))")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundStyle(.white)
                        }

                        Spacer()
                    }
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: .black.opacity(0.05), radius: 5)
        }
    }

    // MARK: - Details Section
    private var detailsSectionCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("DETAILS")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)

            VStack(spacing: 12) {
                DetailRow(
                    icon: "square.stack.3d.up.fill",
                    iconColor: categoryColor,
                    label: "Category",
                    value: category.rawValue
                )

                Divider()
                    .padding(.leading, 44)

                DetailRow(
                    icon: "rectangle.stack.fill",
                    iconColor: .blue,
                    label: "Set",
                    value: card.setName
                )

                Divider()
                    .padding(.leading, 44)

                DetailRow(
                    icon: "number",
                    iconColor: .purple,
                    label: "Card Number",
                    value: card.cardNumber
                )

                // Condition badge
                Divider()
                    .padding(.leading, 44)

                HStack(spacing: 16) {
                    Image(systemName: "star.fill")
                        .font(.title3)
                        .foregroundStyle(.yellow)
                        .frame(width: 28)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Condition")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(card.condition)
                            .font(DesignSystem.Typography.captionBold)
                            .foregroundStyle(conditionColor(for: card.cardCondition))
                            .padding(.horizontal, DesignSystem.Spacing.xxs)
                            .padding(.vertical, 3)
                            .background(conditionColor(for: card.cardCondition).opacity(0.15))
                            .clipShape(Capsule())
                    }

                    Spacer()
                }

                // Variant badge
                if let variantType = card.variantType {
                    Divider()
                        .padding(.leading, 44)

                    HStack(spacing: 16) {
                        Image(systemName: "sparkles")
                            .font(.title3)
                            .foregroundStyle(variantColor(for: variantType))
                            .frame(width: 28)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Variant")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(variantType.displayName)
                                .font(DesignSystem.Typography.captionBold)
                                .foregroundStyle(variantColor(for: variantType))
                                .padding(.horizontal, DesignSystem.Spacing.xxs)
                                .padding(.vertical, 3)
                                .background(variantColor(for: variantType).opacity(0.15))
                                .clipShape(Capsule())
                        }

                        Spacer()
                    }
                }

                Divider()
                    .padding(.leading, 44)

                DetailRow(
                    icon: "calendar",
                    iconColor: .orange,
                    label: "Date Added",
                    value: formatDate(card.acquiredDate)
                )

                Divider()
                    .padding(.leading, 44)

                HStack(spacing: 16) {
                    Image(systemName: confidenceIcon(for: card.confidence))
                        .font(.title3)
                        .foregroundStyle(confidenceColor(for: card.confidence))
                        .frame(width: 28)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Confidence")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        HStack(spacing: 8) {
                            Text("\(Int(card.confidence * 100))%")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundStyle(.white)

                            // Confidence badge
                            Text(confidenceLevel(for: card.confidence))
                                .font(DesignSystem.Typography.captionBold)
                                .foregroundStyle(confidenceColor(for: card.confidence))
                                .padding(.horizontal, DesignSystem.Spacing.xxs)
                                .padding(.vertical, 2)
                                .background(confidenceColor(for: card.confidence).opacity(0.15))
                                .clipShape(Capsule())
                        }
                    }

                    Spacer()
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: .black.opacity(0.05), radius: 5)
        }
    }

    // MARK: - Acquisition Section
    private var acquisitionSectionCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("ACQUISITION")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)

            VStack(spacing: 12) {
                // Source
                if let source = card.cardAcquisitionSource {
                    HStack(spacing: 16) {
                        Image(systemName: acquisitionIcon(for: source))
                            .font(.title3)
                            .foregroundStyle(.cyan)
                            .frame(width: 28)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Acquired via")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(source.rawValue)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundStyle(.white)
                        }

                        Spacer()
                    }
                }

                // Acquisition date
                if let acqDate = card.acquisitionDate {
                    Divider()
                        .padding(.leading, 44)

                    DetailRow(
                        icon: "calendar.badge.clock",
                        iconColor: .orange,
                        label: "Acquisition Date",
                        value: formatDate(acqDate)
                    )
                }

                Divider()
                    .padding(.leading, 44)

                // Days in inventory
                HStack(spacing: 16) {
                    Image(systemName: "clock.fill")
                        .font(.title3)
                        .foregroundStyle(daysColor(card.daysInInventory))
                        .frame(width: 28)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Days in Inventory")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("\(card.daysInInventory)")
                            .font(DesignSystem.Typography.captionBold)
                            .foregroundStyle(daysColor(card.daysInInventory))
                            .padding(.horizontal, DesignSystem.Spacing.xxs)
                            .padding(.vertical, 3)
                            .background(daysColor(card.daysInInventory).opacity(0.15))
                            .clipShape(Capsule())
                    }

                    Spacer()
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: .black.opacity(0.05), radius: 5)
        }
    }

    // MARK: - Tags Section
    private var tagsSectionCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("TAGS")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(card.tagsArray, id: \.self) { tag in
                        Text(tag)
                            .font(DesignSystem.Typography.captionBold)
                            .foregroundStyle(.cyan)
                            .padding(.horizontal, DesignSystem.Spacing.xs)
                            .padding(.vertical, 6)
                            .background(Color.cyan.opacity(0.12))
                            .clipShape(Capsule())
                    }
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: .black.opacity(0.05), radius: 5)
        }
    }

    // MARK: - Storage Location Section
    private func storageSectionCard(location: String) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("STORAGE")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)

            HStack(spacing: 16) {
                Image(systemName: "mappin.circle.fill")
                    .font(.title3)
                    .foregroundStyle(.orange)
                    .frame(width: 28)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Location")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(location)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.white)
                }

                Spacer()
            }
            .padding()
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: .black.opacity(0.05), radius: 5)
        }
    }

    // MARK: - Notes Section
    private var notesSectionCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("NOTES")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
                Spacer()
                Button {
                    if isEditingNotes {
                        // Save
                        card.notes = editedNotes
                        do {
                            try modelContext.save()
                            HapticManager.shared.light()
                        } catch {
                            showSaveError = true
                        }
                        isEditingNotes = false
                    } else {
                        editedNotes = card.notes
                        isEditingNotes = true
                    }
                } label: {
                    Text(isEditingNotes ? "Done" : "Edit")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.cyan)
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                if isEditingNotes {
                    TextEditor(text: $editedNotes)
                        .font(.subheadline)
                        .foregroundStyle(.white)
                        .scrollContentBackground(.hidden)
                        .frame(minHeight: 100)
                } else {
                    if card.notes.isEmpty {
                        Text("No notes added. Tap Edit to add notes.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .italic()
                    } else {
                        Text(card.notes)
                            .font(.subheadline)
                            .foregroundStyle(.white)
                            .lineSpacing(4)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: .black.opacity(0.05), radius: 5)
        }
    }

    // MARK: - Shipping Section
    private var shippingSectionCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("SHIPPING & TRACKING")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)

            VStack(spacing: 12) {
                // Tracking number
                if let tracking = card.trackingNumber, !tracking.isEmpty {
                    HStack(spacing: 16) {
                        Image(systemName: "barcode.viewfinder")
                            .font(.title3)
                            .foregroundStyle(.cyan)
                            .frame(width: 28)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Tracking Number")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(tracking)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundStyle(.white)
                        }

                        Spacer()

                        Button {
                            UIPasteboard.general.string = tracking
                            HapticManager.shared.light()
                        } label: {
                            Image(systemName: "doc.on.doc")
                                .font(.caption)
                                .foregroundStyle(.cyan)
                        }
                    }
                }

                // Carrier
                if let carrierType = card.carrierType {
                    Divider()
                        .padding(.leading, 44)

                    DetailRow(
                        icon: "shippingbox.fill",
                        iconColor: .blue,
                        label: "Carrier",
                        value: carrierType.displayName
                    )
                }

                // Ship date
                if let shipDate = card.shippedDate {
                    Divider()
                        .padding(.leading, 44)

                    DetailRow(
                        icon: "calendar.badge.checkmark",
                        iconColor: .green,
                        label: "Ship Date",
                        value: formatDate(shipDate)
                    )
                }

                // Track Package button
                if let carrierType = card.carrierType,
                   let tracking = card.trackingNumber,
                   !tracking.isEmpty,
                   !carrierType.trackingUrlTemplate.isEmpty {
                    Divider()

                    let urlString = carrierType.trackingUrlTemplate.replacingOccurrences(of: "{tracking}", with: tracking)
                    if let url = URL(string: urlString) {
                        Link(destination: url) {
                            HStack(spacing: DesignSystem.Spacing.xxs) {
                                Image(systemName: "safari.fill")
                                    .font(.headline)
                                Text("Track Package")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                            }
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(DesignSystem.Spacing.sm)
                            .background(DesignSystem.Colors.electricBlue)
                            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md))
                        }
                    }
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: .black.opacity(0.05), radius: 5)
        }
    }

    // MARK: - Return Section
    private var returnSectionCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("RETURN INFO")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(DesignSystem.Colors.error)
                Spacer()
                Image(systemName: "arrow.uturn.backward.circle.fill")
                    .foregroundStyle(DesignSystem.Colors.error)
            }

            VStack(spacing: 12) {
                if let reason = card.returnReason, !reason.isEmpty {
                    HStack(spacing: 16) {
                        Image(systemName: "exclamationmark.bubble.fill")
                            .font(.title3)
                            .foregroundStyle(DesignSystem.Colors.error)
                            .frame(width: 28)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Reason")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(reason)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundStyle(.white)
                        }

                        Spacer()
                    }
                }

                if let refund = card.refundAmount {
                    Divider()
                        .padding(.leading, 44)

                    HStack(spacing: 16) {
                        Image(systemName: "dollarsign.arrow.circlepath")
                            .font(.title3)
                            .foregroundStyle(DesignSystem.Colors.error)
                            .frame(width: 28)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Refund Amount")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text("$\(String(format: "%.2f", refund))")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundStyle(DesignSystem.Colors.error)
                        }

                        Spacer()
                    }
                }

                if let refundDate = card.refundDate {
                    Divider()
                        .padding(.leading, 44)

                    DetailRow(
                        icon: "calendar.badge.exclamationmark",
                        iconColor: DesignSystem.Colors.error,
                        label: "Refund Date",
                        value: formatDate(refundDate)
                    )
                }
            }
            .padding()
            .background(DesignSystem.Colors.error.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(DesignSystem.Colors.error.opacity(0.2), lineWidth: 1)
            )
        }
    }

    // MARK: - Activity Timeline
    private var timelineSectionCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("ACTIVITY TIMELINE")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 0) {
                // Added
                TimelineEntry(
                    icon: "plus.circle.fill",
                    color: .cyan,
                    title: "Added to Inventory",
                    subtitle: formatDate(card.acquiredDate),
                    showLine: card.listedDate != nil || card.soldDate != nil || card.shippedDate != nil
                )

                // Listed
                if let listedDate = card.listedDate {
                    TimelineEntry(
                        icon: "tag.fill",
                        color: DesignSystem.Colors.electricBlue,
                        title: "Listed\(card.platform.map { " on \($0)" } ?? "")\(card.listingPrice.map { " at $\(String(format: "%.2f", $0))" } ?? "")",
                        subtitle: formatDate(listedDate),
                        showLine: card.soldDate != nil || card.shippedDate != nil
                    )
                }

                // Sold
                if let soldDate = card.soldDate {
                    TimelineEntry(
                        icon: "dollarsign.circle.fill",
                        color: DesignSystem.Colors.success,
                        title: "Sold\(card.soldPrice.map { " for $\(String(format: "%.2f", $0))" } ?? "")\(card.platform.map { " on \($0)" } ?? "")",
                        subtitle: formatDate(soldDate),
                        showLine: card.shippedDate != nil
                    )
                }

                // Shipped
                if let shippedDate = card.shippedDate {
                    TimelineEntry(
                        icon: "paperplane.fill",
                        color: DesignSystem.Colors.textSecondary,
                        title: "Shipped\(card.carrierType.map { " via \($0.displayName)" } ?? "")",
                        subtitle: formatDate(shippedDate),
                        showLine: card.refundDate != nil
                    )
                }

                // Returned
                if let refundDate = card.refundDate {
                    TimelineEntry(
                        icon: "arrow.uturn.backward.circle.fill",
                        color: DesignSystem.Colors.error,
                        title: "Returned\(card.refundAmount.map { " - $\(String(format: "%.2f", $0)) refunded" } ?? "")",
                        subtitle: formatDate(refundDate),
                        showLine: false
                    )
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: .black.opacity(0.05), radius: 5)
        }
    }

    // MARK: - Lifecycle Section

    private var lifecycleSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Current Status Header
            HStack {
                Text("STATUS")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
                Spacer()
                StatusBadge(status: card.cardStatus)
            }

            VStack(spacing: 12) {
                switch card.cardStatus {
                case .inStock:
                    inStockActions
                case .listed:
                    listedInfo
                    listedActions
                case .sold:
                    soldDetails
                    soldActions
                case .shipped:
                    shippedDetails
                case .returned:
                    returnedStatusInfo
                case .disputed:
                    disputedStatusInfo
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: .black.opacity(0.05), radius: 5)
        }
    }

    // MARK: - In Stock Actions

    private var inStockActions: some View {
        VStack(spacing: DesignSystem.Spacing.xs) {
            Button {
                showListedSheet = true
            } label: {
                HStack(spacing: DesignSystem.Spacing.xxs) {
                    Image(systemName: "tag.fill")
                        .font(.headline)
                    Text("Mark as Listed")
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(DesignSystem.Spacing.sm)
                .background(DesignSystem.Colors.electricBlue)
                .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md))
            }

            Button {
                showSellSheet = true
            } label: {
                HStack(spacing: DesignSystem.Spacing.xxs) {
                    Image(systemName: "dollarsign.circle.fill")
                        .font(.headline)
                    Text("Mark as Sold")
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(DesignSystem.Spacing.sm)
                .background(DesignSystem.Colors.success)
                .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md))
            }
        }
    }

    // MARK: - Listed Info

    private var listedInfo: some View {
        VStack(spacing: 8) {
            if let platform = card.platform {
                HStack {
                    Text("Platform")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(platform)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.white)
                }
            }

            if let listingPrice = card.listingPrice {
                HStack {
                    Text("Listing Price")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("$\(String(format: "%.2f", listingPrice))")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundStyle(DesignSystem.Colors.electricBlue)
                }
            }

            if let listedDate = card.listedDate {
                HStack {
                    Text("Listed On")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(formatDate(listedDate))
                        .font(.subheadline)
                        .foregroundStyle(.white)
                }
            }

            Divider()
        }
    }

    // MARK: - Listed Actions

    private var listedActions: some View {
        VStack(spacing: DesignSystem.Spacing.xs) {
            Button {
                showSellSheet = true
            } label: {
                HStack(spacing: DesignSystem.Spacing.xxs) {
                    Image(systemName: "dollarsign.circle.fill")
                        .font(.headline)
                    Text("Mark as Sold")
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(DesignSystem.Spacing.sm)
                .background(DesignSystem.Colors.success)
                .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md))
            }

            Button {
                returnToStock()
            } label: {
                HStack(spacing: DesignSystem.Spacing.xxs) {
                    Image(systemName: "arrow.uturn.backward")
                        .font(.subheadline)
                    Text("Return to Stock")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
                .foregroundStyle(DesignSystem.Colors.textSecondary)
                .frame(maxWidth: .infinity)
                .padding(DesignSystem.Spacing.xs)
                .background(DesignSystem.Colors.backgroundTertiary)
                .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md))
            }
        }
    }

    // MARK: - Sold Details

    private var soldDetails: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "checkmark.seal.fill")
                    .foregroundStyle(DesignSystem.Colors.success)
                Text("SOLD")
                    .font(DesignSystem.Typography.captionBold)
                    .foregroundStyle(DesignSystem.Colors.success)
                Spacer()
                if let soldDate = card.soldDate {
                    Text(formatDate(soldDate))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Divider()

            if let soldPrice = card.soldPrice {
                HStack {
                    Text("Sold Price")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("$\(String(format: "%.2f", soldPrice))")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundStyle(DesignSystem.Colors.success)
                }
            }

            if let platform = card.platform {
                HStack {
                    Text("Platform")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(platform)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.white)
                }
            }

            if let saleProfit = card.saleProfit {
                Divider()
                HStack {
                    Text("Profit")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(saleProfit >= 0 ? "+$\(String(format: "%.2f", saleProfit))" : "-$\(String(format: "%.2f", abs(saleProfit)))")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundStyle(saleProfit >= 0 ? DesignSystem.Colors.success : DesignSystem.Colors.error)
                }
            }
        }
    }

    // MARK: - Sold Actions

    private var soldActions: some View {
        VStack(spacing: DesignSystem.Spacing.xxs) {
            Button {
                showShippedSheet = true
            } label: {
                HStack(spacing: DesignSystem.Spacing.xxs) {
                    Image(systemName: "paperplane.fill")
                        .font(.headline)
                    Text("Mark as Shipped")
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(DesignSystem.Spacing.sm)
                .background(DesignSystem.Colors.textSecondary)
                .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md))
            }

            Button {
                showReturnSheet = true
            } label: {
                HStack(spacing: DesignSystem.Spacing.xxs) {
                    Image(systemName: "arrow.uturn.backward.circle.fill")
                        .font(.subheadline)
                    Text("Process Return")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
                .foregroundStyle(DesignSystem.Colors.error)
                .frame(maxWidth: .infinity)
                .padding(DesignSystem.Spacing.xs)
                .background(DesignSystem.Colors.error.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md))
            }
        }
    }

    // MARK: - Shipped Details

    private var shippedDetails: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "paperplane.fill")
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
                Text("SHIPPED")
                    .font(DesignSystem.Typography.captionBold)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
                Spacer()
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(DesignSystem.Colors.success)
                Text("Complete")
                    .font(DesignSystem.Typography.captionBold)
                    .foregroundStyle(DesignSystem.Colors.success)
            }

            Divider()

            if let soldPrice = card.soldPrice {
                HStack {
                    Text("Sold Price")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("$\(String(format: "%.2f", soldPrice))")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundStyle(DesignSystem.Colors.success)
                }
            }

            if let platform = card.platform {
                HStack {
                    Text("Platform")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(platform)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.white)
                }
            }

            if let soldDate = card.soldDate {
                HStack {
                    Text("Sold Date")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(formatDate(soldDate))
                        .font(.subheadline)
                        .foregroundStyle(.white)
                }
            }

            if let saleProfit = card.saleProfit {
                Divider()
                HStack {
                    Text("Profit")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(saleProfit >= 0 ? "+$\(String(format: "%.2f", saleProfit))" : "-$\(String(format: "%.2f", abs(saleProfit)))")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundStyle(saleProfit >= 0 ? DesignSystem.Colors.success : DesignSystem.Colors.error)
                }
            }

            Divider()

            Button {
                showReturnSheet = true
            } label: {
                HStack(spacing: DesignSystem.Spacing.xxs) {
                    Image(systemName: "arrow.uturn.backward.circle.fill")
                        .font(.subheadline)
                    Text("Process Return")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
                .foregroundStyle(DesignSystem.Colors.error)
                .frame(maxWidth: .infinity)
                .padding(DesignSystem.Spacing.xs)
                .background(DesignSystem.Colors.error.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md))
            }
        }
    }

    // MARK: - Returned Status Info

    private var returnedStatusInfo: some View {
        VStack(spacing: DesignSystem.Spacing.xs) {
            HStack {
                Image(systemName: "arrow.uturn.backward.circle.fill")
                    .foregroundStyle(DesignSystem.Colors.error)
                Text("This card has been returned")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
            }

            if let reason = card.returnReason {
                HStack {
                    Text("Reason")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(reason)
                        .font(.subheadline)
                        .foregroundStyle(.white)
                }
            }

            if let refund = card.refundAmount {
                HStack {
                    Text("Refund")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("$\(String(format: "%.2f", refund))")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundStyle(DesignSystem.Colors.error)
                }
            }

            Button {
                returnToStock()
            } label: {
                HStack(spacing: DesignSystem.Spacing.xxs) {
                    Image(systemName: "shippingbox.fill")
                        .font(.subheadline)
                    Text("Return to Stock")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
                .foregroundStyle(.cyan)
                .frame(maxWidth: .infinity)
                .padding(DesignSystem.Spacing.xs)
                .background(Color.cyan.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md))
            }
        }
    }

    // MARK: - Disputed Status Info

    private var disputedStatusInfo: some View {
        VStack(spacing: DesignSystem.Spacing.xs) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(DesignSystem.Colors.warning)
                Text("This card is under dispute")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
            }

            if let reason = card.returnReason {
                HStack {
                    Text("Reason")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(reason)
                        .font(.subheadline)
                        .foregroundStyle(.white)
                }
            }

            HStack(spacing: DesignSystem.Spacing.xxs) {
                Button {
                    showReturnSheet = true
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.uturn.backward.circle.fill")
                            .font(.caption)
                        Text("Process Refund")
                            .font(.caption)
                            .fontWeight(.semibold)
                    }
                    .foregroundStyle(DesignSystem.Colors.error)
                    .frame(maxWidth: .infinity)
                    .padding(DesignSystem.Spacing.xs)
                    .background(DesignSystem.Colors.error.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md))
                }

                Button {
                    returnToStock()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "shippingbox.fill")
                            .font(.caption)
                        Text("Restock")
                            .font(.caption)
                            .fontWeight(.semibold)
                    }
                    .foregroundStyle(.cyan)
                    .frame(maxWidth: .infinity)
                    .padding(DesignSystem.Spacing.xs)
                    .background(Color.cyan.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md))
                }
            }
        }
    }

    // MARK: - Actions Section
    private var actionsSection: some View {
        VStack(spacing: 12) {
            // Share Button
            Button {
                showShareSheet = true
            } label: {
                HStack {
                    Image(systemName: "square.and.arrow.up")
                        .font(.headline)
                    Text("Share Card Details")
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.cyan)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            // Delete Button
            Button(role: .destructive) {
                showDeleteAlert = true
            } label: {
                HStack {
                    Image(systemName: "trash.fill")
                        .font(.headline)
                    Text("Delete Card")
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.red)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding(.top, 8)
    }

    // MARK: - Helper Views
    private var categoryColor: Color { category.color }

    // MARK: - Helper Functions
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }

    private func returnToStock() {
        card.status = CardStatus.inStock.rawValue
        card.platform = nil
        card.listingPrice = nil
        card.listedDate = nil

        do {
            try modelContext.save()
            HapticManager.shared.light()
        } catch {
            #if DEBUG
            print("Failed to save return to stock: \(error)")
            #endif
            showSaveError = true
        }
    }

    private func deleteCard() {
        modelContext.delete(card)
        do {
            try modelContext.save()
            dismiss()
        } catch {
            #if DEBUG
            print("Failed to save after delete: \(error)")
            #endif
            showSaveError = true
        }
    }

    // MARK: - Confidence Helpers
    private func confidenceLevel(for confidence: Double) -> String {
        switch confidence {
        case 0.9...1.0: return "Very High"
        case 0.75..<0.9: return "High"
        case 0.5..<0.75: return "Medium"
        default: return "Low"
        }
    }

    private func confidenceColor(for confidence: Double) -> Color {
        switch confidence {
        case 0.9...1.0: return DesignSystem.Colors.success
        case 0.75..<0.9: return DesignSystem.Colors.electricBlue
        case 0.5..<0.75: return DesignSystem.Colors.warning
        default: return DesignSystem.Colors.error
        }
    }

    private func confidenceIcon(for confidence: Double) -> String {
        switch confidence {
        case 0.9...1.0: return "checkmark.seal.fill"
        case 0.75..<0.9: return "checkmark.circle.fill"
        case 0.5..<0.75: return "exclamationmark.triangle.fill"
        default: return "xmark.octagon.fill"
        }
    }

    private func conditionColor(for condition: CardCondition) -> Color {
        switch condition {
        case .mint: return DesignSystem.Colors.thunderYellow
        case .nearMint: return DesignSystem.Colors.success
        case .excellent: return DesignSystem.Colors.electricBlue
        case .good: return DesignSystem.Colors.warning
        case .played: return .orange
        case .poor: return DesignSystem.Colors.error
        }
    }

    private func variantColor(for variant: InventoryCardVariant) -> Color {
        switch variant {
        case .normal: return DesignSystem.Colors.textSecondary
        case .holofoil, .reverseHolofoil: return .cyan
        case .firstEdition: return DesignSystem.Colors.thunderYellow
        case .unlimited: return DesignSystem.Colors.textSecondary
        case .secretRare, .hyperRare, .goldRare: return DesignSystem.Colors.thunderYellow
        case .fullArt, .altArt, .specialArtRare: return .purple
        case .illustrationRare: return .pink
        }
    }

    private func acquisitionIcon(for source: AcquisitionSource) -> String {
        switch source {
        case .localPickup: return "mappin.and.ellipse"
        case .onlinePurchase: return "cart.fill"
        case .trade: return "arrow.left.arrow.right"
        case .eventShow: return "ticket.fill"
        case .consignment: return "person.2.fill"
        case .personalCollection: return "heart.fill"
        case .other: return "ellipsis.circle.fill"
        }
    }

    private func daysColor(_ days: Int) -> Color {
        switch days {
        case 0..<30: return DesignSystem.Colors.success
        case 30..<90: return DesignSystem.Colors.warning
        default: return DesignSystem.Colors.error
        }
    }
}

// MARK: - Detail Row Component
struct DetailRow: View {
    let icon: String
    let iconColor: Color
    let label: String
    let value: String

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(iconColor)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.white)
            }

            Spacer()
        }
    }
}

// MARK: - Timeline Entry Component
struct TimelineEntry: View {
    let icon: String
    let color: Color
    let title: String
    let subtitle: String
    let showLine: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // Icon + connecting line
            VStack(spacing: 0) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundStyle(color)
                    .frame(width: 28, height: 28)
                    .background(color.opacity(0.15))
                    .clipShape(Circle())

                if showLine {
                    Rectangle()
                        .fill(color.opacity(0.3))
                        .frame(width: 2, height: 32)
                }
            }

            // Content
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.white)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.bottom, showLine ? 12 : 0)

            Spacer()
        }
    }
}
