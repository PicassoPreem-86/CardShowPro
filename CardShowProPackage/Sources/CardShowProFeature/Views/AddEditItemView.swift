import SwiftUI
import SwiftData
import PhotosUI

struct AddEditItemView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    // Edit mode - if provided, we're editing; if nil, we're adding
    let cardToEdit: InventoryCard?

    // Form state
    @State private var selectedCategory: CardCategory = .rawSingles
    @State private var cardName = ""
    @State private var setName = ""
    @State private var cardNumber = ""
    @State private var condition: CardCondition = .nearMint
    @State private var purchasePrice = ""
    @State private var marketValue = ""
    @State private var quantity = 1
    @State private var notes = ""
    @State private var selectedImage: UIImage?
    @State private var showImagePicker = false
    @State private var imagePickerSource: ImagePickerSource = .camera

    // Validation
    @State private var showValidationErrors = false

    private var isEditMode: Bool {
        cardToEdit != nil
    }

    private var isValid: Bool {
        !cardName.trimmingCharacters(in: .whitespaces).isEmpty &&
        !marketValue.isEmpty &&
        (Double(marketValue) ?? 0) > 0
    }

    var body: some View {
        NavigationStack {
            Form {
                // Photo Section (MOVED TO TOP)
                Section {
                    if let image = selectedImage {
                        // Show selected image
                        HStack {
                            Spacer()
                            Image(uiImage: image)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(height: 200)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            Spacer()
                        }

                        Button(role: .destructive) {
                            selectedImage = nil
                        } label: {
                            HStack {
                                Image(systemName: "trash")
                                Text("Remove Photo")
                            }
                        }
                    } else {
                        // Photo picker buttons with enhanced CTAs
                        Button {
                            imagePickerSource = .camera
                            showImagePicker = true
                        } label: {
                            HStack {
                                Image(systemName: "camera.fill")
                                    .foregroundStyle(.cyan)
                                VStack(alignment: .leading) {
                                    Text("Take Photo")
                                        .foregroundStyle(.primary)
                                    Text("Best for accurate card recognition")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }

                        Button {
                            imagePickerSource = .photoLibrary
                            showImagePicker = true
                        } label: {
                            HStack {
                                Image(systemName: "photo.fill")
                                    .foregroundStyle(.cyan)
                                VStack(alignment: .leading) {
                                    Text("Choose from Library")
                                        .foregroundStyle(.primary)
                                    Text("Select an existing photo from your device")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                } header: {
                    Text("PHOTO")
                } footer: {
                    Text("Adding a photo helps with card identification and value tracking")
                        .font(.caption)
                }

                // Card Details Section (MOVED TO SECOND)
                Section {
                    TextField("Card Name", text: $cardName)
                        .autocorrectionDisabled()
                        .overlay(alignment: .trailing) {
                            if showValidationErrors && cardName.isEmpty {
                                Image(systemName: "exclamationmark.circle.fill")
                                    .foregroundStyle(.red)
                            }
                        }

                    TextField("Set Name", text: $setName)
                        .autocorrectionDisabled()

                    TextField("Card Number (e.g. #044)", text: $cardNumber)
                        .autocorrectionDisabled()

                    Picker("Condition", selection: $condition) {
                        ForEach(CardCondition.allCases, id: \.self) { condition in
                            Text(condition.rawValue).tag(condition)
                        }
                    }
                } header: {
                    Text("CARD DETAILS")
                } footer: {
                    if showValidationErrors && cardName.isEmpty {
                        Text("Card name is required")
                            .foregroundStyle(.red)
                    }
                }

                // Category Section (MOVED TO THIRD)
                Section {
                    Picker("Category", selection: $selectedCategory) {
                        ForEach(CardCategory.allCases, id: \.self) { category in
                            HStack {
                                Image(systemName: category.icon)
                                    .foregroundStyle(category.color)
                                Text(category.rawValue)
                            }
                            .tag(category)
                        }
                    }
                    .pickerStyle(.navigationLink)
                } header: {
                    Text("CATEGORY")
                }

                // Pricing Section (MOVED TO FOURTH)
                Section {
                    HStack {
                        Text("$")
                            .foregroundStyle(.secondary)
                        TextField("0.00", text: $purchasePrice)
                            .keyboardType(.decimalPad)
                    }
                    .overlay(alignment: .leading) {
                        Text("Purchase Price")
                            .foregroundStyle(.clear)
                    }

                    HStack {
                        Text("$")
                            .foregroundStyle(.secondary)
                        TextField("0.00", text: $marketValue)
                            .keyboardType(.decimalPad)
                            .overlay(alignment: .trailing) {
                                if showValidationErrors && (Double(marketValue) ?? 0) <= 0 {
                                    Image(systemName: "exclamationmark.circle.fill")
                                        .foregroundStyle(.red)
                                }
                            }
                    }
                    .overlay(alignment: .leading) {
                        Text("Market Value")
                            .foregroundStyle(.clear)
                    }

                    Stepper("Quantity: \(quantity)", value: $quantity, in: 1...999)
                } header: {
                    Text("PRICING")
                } footer: {
                    if showValidationErrors && (Double(marketValue) ?? 0) <= 0 {
                        Text("Market value must be greater than $0")
                            .foregroundStyle(.red)
                    }
                }

                // Notes Section (MOVED TO FIFTH)
                Section {
                    TextField("Optional notes about this card...", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                } header: {
                    Text("NOTES")
                }
            }
            .navigationTitle(isEditMode ? "Edit Card" : "Add Card")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button(isEditMode ? "Save" : "Add") {
                        saveCard()
                    }
                    .fontWeight(.semibold)
                    .disabled(!isValid && !isEditMode)
                }
            }
            .sheet(isPresented: $showImagePicker) {
                ImagePicker(image: $selectedImage, sourceType: imagePickerSource == .camera ? .camera : .photoLibrary)
            }
            .onAppear {
                loadCardData()
            }
        }
    }

    // MARK: - Functions
    private func loadCardData() {
        guard let card = cardToEdit else { return }

        // Load existing card data for editing
        cardName = card.cardName
        setName = card.setName
        cardNumber = card.cardNumber
        marketValue = String(format: "%.2f", card.marketValue)
        selectedImage = card.image

        // Mock values - will be real fields later
        purchasePrice = String(format: "%.2f", card.marketValue * 0.65)
        notes = "Card imported from scan"

        // Mock category based on confidence
        if card.confidence > 0.9 {
            selectedCategory = .graded
        } else if card.marketValue > 200 {
            selectedCategory = .rawSingles
        } else {
            selectedCategory = .rawSingles
        }
    }

    private func saveCard() {
        // Validate
        guard isValid else {
            showValidationErrors = true
            return
        }

        let marketVal = Double(marketValue) ?? 0

        if let existingCard = cardToEdit {
            // Edit existing card
            existingCard.cardName = cardName.trimmingCharacters(in: .whitespaces)
            existingCard.setName = setName.trimmingCharacters(in: .whitespaces)
            existingCard.cardNumber = cardNumber.trimmingCharacters(in: .whitespaces)
            existingCard.marketValue = marketVal
            if let image = selectedImage {
                existingCard.imageData = image.pngData()
            }
        } else {
            // Create new card
            let newCard = InventoryCard(
                cardName: cardName.trimmingCharacters(in: .whitespaces),
                cardNumber: cardNumber.trimmingCharacters(in: .whitespaces),
                setName: setName.trimmingCharacters(in: .whitespaces),
                estimatedValue: marketVal,
                confidence: 1.0, // Manual entry = 100% confidence
                imageData: selectedImage?.pngData()
            )
            modelContext.insert(newCard)
        }

        // Save context
        do {
            try modelContext.save()
            dismiss()
        } catch {
            print("Error saving card: \(error)")
        }
    }
}

// MARK: - Supporting Types
enum CardCategory: String, CaseIterable {
    case allProduct = "All"
    case rawSingles = "Raw Singles"
    case graded = "Graded"
    case sealed = "Sealed"
    case misc = "Misc"

    var icon: String {
        switch self {
        case .allProduct: return "square.grid.2x2.fill"
        case .rawSingles: return "rectangle.portrait.fill"
        case .graded: return "shield.checkered"
        case .sealed: return "shippingbox.fill"
        case .misc: return "ellipsis.circle.fill"
        }
    }

    var color: Color {
        switch self {
        case .allProduct: return .cyan
        case .rawSingles: return .purple
        case .graded: return .yellow
        case .sealed: return .orange
        case .misc: return .gray
        }
    }
}

enum ImagePickerSource {
    case camera
    case photoLibrary
}

// MARK: - Image Picker
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    let sourceType: UIImagePickerController.SourceType
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = context.coordinator
        picker.allowsEditing = true
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker

        init(_ parent: ImagePicker) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let editedImage = info[.editedImage] as? UIImage {
                parent.image = editedImage
            } else if let originalImage = info[.originalImage] as? UIImage {
                parent.image = originalImage
            }
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}
