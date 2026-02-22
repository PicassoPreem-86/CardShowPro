import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct CSVImportView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var importState: ImportState = .selectFile
    @State private var parsedRows: [[String]] = []
    @State private var headers: [String] = []
    @State private var columnMapping: [Int: MappableField] = [:]
    @State private var importErrors: [String] = []
    @State private var importedCount = 0
    @State private var skippedCount = 0
    @State private var showFileImporter = false
    @State private var showSaveError = false

    enum ImportState {
        case selectFile
        case preview
        case mapping
        case importing
        case result
    }

    enum MappableField: String, CaseIterable {
        case skip = "Skip"
        case cardName = "Card Name"
        case setName = "Set"
        case cardNumber = "Number"
        case category = "Category"
        case condition = "Condition"
        case estimatedValue = "Market Value"
        case purchaseCost = "Purchase Cost"
        case quantity = "Quantity"
        case variant = "Variant"
        case tags = "Tags"
        case storageLocation = "Storage Location"
        case notes = "Notes"
        case status = "Status"
        case platform = "Platform"
        case grade = "Grade"
        case gradingService = "Grading Service"

        var isRequired: Bool {
            self == .cardName || self == .estimatedValue
        }
    }

    // Known header aliases for auto-mapping
    private static let headerAliases: [String: MappableField] = [
        "card name": .cardName, "name": .cardName, "product name": .cardName,
        "set": .setName, "set name": .setName, "expansion": .setName,
        "number": .cardNumber, "card number": .cardNumber, "#": .cardNumber, "collector number": .cardNumber,
        "category": .category, "type": .category,
        "condition": .condition,
        "market value": .estimatedValue, "price": .estimatedValue, "value": .estimatedValue,
        "market price": .estimatedValue, "total price": .estimatedValue,
        "purchase cost": .purchaseCost, "cost": .purchaseCost, "buy price": .purchaseCost,
        "quantity": .quantity, "qty": .quantity,
        "variant": .variant, "printing": .variant, "rarity": .variant,
        "tags": .tags,
        "storage": .storageLocation, "storage location": .storageLocation, "location": .storageLocation,
        "notes": .notes, "description": .notes,
        "status": .status,
        "platform": .platform,
        "grade": .grade,
        "grading service": .gradingService, "grader": .gradingService,
    ]

    private var requiredFieldsMapped: Bool {
        let mapped = Set(columnMapping.values)
        return mapped.contains(.cardName) && mapped.contains(.estimatedValue)
    }

    private var dataRowCount: Int {
        parsedRows.count
    }

    var body: some View {
        NavigationStack {
            ZStack {
                DesignSystem.Colors.backgroundPrimary.ignoresSafeArea()

                switch importState {
                case .selectFile:
                    selectFileContent
                case .preview:
                    previewContent
                case .mapping:
                    mappingContent
                case .importing:
                    importingContent
                case .result:
                    resultContent
                }
            }
            .navigationTitle("Import CSV")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(DesignSystem.Colors.cyan)
                }
            }
            .fileImporter(
                isPresented: $showFileImporter,
                allowedContentTypes: [UTType.commaSeparatedText, UTType.plainText],
                allowsMultipleSelection: false
            ) { result in
                handleFileSelection(result)
            }
            .alert("Import Error", isPresented: $showSaveError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Failed to save imported cards. Please try again.")
            }
        }
    }

    // MARK: - Select File

    private var selectFileContent: some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            Spacer()

            Image(systemName: "doc.text.fill")
                .font(.system(size: 60))
                .foregroundStyle(DesignSystem.Colors.cyan)

            Text("Import Cards from CSV")
                .font(DesignSystem.Typography.heading3)
                .foregroundStyle(DesignSystem.Colors.textPrimary)

            Text("Supports TCGPlayer exports and custom CSV files with flexible column mapping.")
                .font(DesignSystem.Typography.body)
                .foregroundStyle(DesignSystem.Colors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, DesignSystem.Spacing.lg)

            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                formatHint(icon: "checkmark.circle.fill", text: "Required: Card Name, Market Value")
                formatHint(icon: "arrow.triangle.2.circlepath", text: "Auto-detects common column names")
                formatHint(icon: "tablecells", text: "Handles quoted fields and commas")
            }
            .padding(DesignSystem.Spacing.md)
            .background(DesignSystem.Colors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md))
            .padding(.horizontal, DesignSystem.Spacing.md)

            Button {
                showFileImporter = true
            } label: {
                HStack(spacing: DesignSystem.Spacing.xxs) {
                    Image(systemName: "folder.fill")
                        .font(.headline)
                    Text("Select CSV File")
                        .font(DesignSystem.Typography.heading4)
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(DesignSystem.Spacing.sm)
                .background(DesignSystem.Colors.cyan)
                .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md))
            }
            .padding(.horizontal, DesignSystem.Spacing.md)

            Spacer()
        }
    }

    private func formatHint(icon: String, text: String) -> some View {
        HStack(spacing: DesignSystem.Spacing.xs) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(DesignSystem.Colors.cyan)
                .frame(width: 20)
            Text(text)
                .font(DesignSystem.Typography.body)
                .foregroundStyle(DesignSystem.Colors.textSecondary)
        }
    }

    // MARK: - Preview

    private var previewContent: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            HStack {
                Image(systemName: "tablecells")
                    .foregroundStyle(DesignSystem.Colors.cyan)
                Text("\(dataRowCount) rows detected")
                    .font(DesignSystem.Typography.heading4)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)
                Spacer()
            }
            .padding(.horizontal, DesignSystem.Spacing.md)
            .padding(.top, DesignSystem.Spacing.sm)

            // Preview table - first 5 rows
            ScrollView(.horizontal, showsIndicators: true) {
                VStack(alignment: .leading, spacing: 0) {
                    // Header row
                    HStack(spacing: 0) {
                        ForEach(headers.indices, id: \.self) { i in
                            Text(headers[i])
                                .font(DesignSystem.Typography.captionBold)
                                .foregroundStyle(DesignSystem.Colors.cyan)
                                .frame(width: 120, alignment: .leading)
                                .padding(DesignSystem.Spacing.xxs)
                        }
                    }
                    .background(DesignSystem.Colors.backgroundTertiary)

                    // Data rows (up to 5)
                    ForEach(Array(parsedRows.prefix(5).enumerated()), id: \.offset) { _, row in
                        HStack(spacing: 0) {
                            ForEach(row.indices, id: \.self) { i in
                                Text(row[i])
                                    .font(DesignSystem.Typography.caption)
                                    .foregroundStyle(DesignSystem.Colors.textPrimary)
                                    .frame(width: 120, alignment: .leading)
                                    .padding(DesignSystem.Spacing.xxs)
                                    .lineLimit(1)
                            }
                        }
                        Divider().overlay(DesignSystem.Colors.borderPrimary)
                    }

                    if dataRowCount > 5 {
                        Text("... and \(dataRowCount - 5) more rows")
                            .font(DesignSystem.Typography.caption)
                            .foregroundStyle(DesignSystem.Colors.textTertiary)
                            .padding(DesignSystem.Spacing.xs)
                    }
                }
            }
            .padding(.horizontal, DesignSystem.Spacing.md)
            .background(DesignSystem.Colors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md))
            .padding(.horizontal, DesignSystem.Spacing.md)

            Spacer()

            Button {
                withAnimation { importState = .mapping }
            } label: {
                HStack(spacing: DesignSystem.Spacing.xxs) {
                    Image(systemName: "arrow.right.circle.fill")
                        .font(.headline)
                    Text("Configure Mapping")
                        .font(DesignSystem.Typography.heading4)
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(DesignSystem.Spacing.sm)
                .background(DesignSystem.Colors.cyan)
                .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md))
            }
            .padding(.horizontal, DesignSystem.Spacing.md)
            .padding(.bottom, DesignSystem.Spacing.md)
        }
    }

    // MARK: - Mapping

    private var mappingContent: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            if !requiredFieldsMapped {
                HStack(spacing: DesignSystem.Spacing.xs) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(DesignSystem.Colors.warning)
                    Text("Map required fields: Card Name and Market Value")
                        .font(DesignSystem.Typography.caption)
                        .foregroundStyle(DesignSystem.Colors.warning)
                }
                .padding(DesignSystem.Spacing.sm)
                .background(DesignSystem.Colors.warning.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.sm))
                .padding(.horizontal, DesignSystem.Spacing.md)
            }

            List {
                ForEach(headers.indices, id: \.self) { index in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(headers[index])
                                .font(DesignSystem.Typography.labelLarge)
                                .foregroundStyle(DesignSystem.Colors.textPrimary)

                            if let firstRow = parsedRows.first, index < firstRow.count {
                                Text("e.g. \"\(firstRow[index].prefix(30))\"")
                                    .font(DesignSystem.Typography.captionSmall)
                                    .foregroundStyle(DesignSystem.Colors.textTertiary)
                            }
                        }

                        Spacer()

                        Picker("", selection: Binding(
                            get: { columnMapping[index] ?? .skip },
                            set: { columnMapping[index] = $0 }
                        )) {
                            ForEach(MappableField.allCases, id: \.self) { field in
                                HStack {
                                    Text(field.rawValue)
                                    if field.isRequired {
                                        Text("*")
                                            .foregroundStyle(DesignSystem.Colors.error)
                                    }
                                }
                                .tag(field)
                            }
                        }
                        .tint(DesignSystem.Colors.cyan)

                        if let mapped = columnMapping[index], mapped != .skip {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(DesignSystem.Colors.success)
                                .font(.caption)
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)

            Button {
                performImport()
            } label: {
                HStack(spacing: DesignSystem.Spacing.xxs) {
                    Image(systemName: "square.and.arrow.down.fill")
                        .font(.headline)
                    Text("Import \(dataRowCount) Cards")
                        .font(DesignSystem.Typography.heading4)
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(DesignSystem.Spacing.sm)
                .background(requiredFieldsMapped ? DesignSystem.Colors.success : DesignSystem.Colors.success.opacity(0.3))
                .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md))
            }
            .disabled(!requiredFieldsMapped)
            .padding(.horizontal, DesignSystem.Spacing.md)
            .padding(.bottom, DesignSystem.Spacing.md)
        }
    }

    // MARK: - Importing

    private var importingContent: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            Spacer()
            ProgressView()
                .scaleEffect(1.5)
                .tint(DesignSystem.Colors.cyan)
            Text("Importing cards...")
                .font(DesignSystem.Typography.heading4)
                .foregroundStyle(DesignSystem.Colors.textPrimary)
            Spacer()
        }
    }

    // MARK: - Result

    private var resultContent: some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            Spacer()

            Image(systemName: importedCount > 0 ? "checkmark.circle.fill" : "xmark.circle.fill")
                .font(.system(size: 60))
                .foregroundStyle(importedCount > 0 ? DesignSystem.Colors.success : DesignSystem.Colors.error)

            Text(importedCount > 0 ? "Import Complete" : "Import Failed")
                .font(DesignSystem.Typography.heading2)
                .foregroundStyle(DesignSystem.Colors.textPrimary)

            VStack(spacing: DesignSystem.Spacing.xs) {
                resultRow(label: "Cards Imported", value: "\(importedCount)", color: DesignSystem.Colors.success)
                if skippedCount > 0 {
                    resultRow(label: "Skipped (errors)", value: "\(skippedCount)", color: DesignSystem.Colors.warning)
                }
            }
            .padding(DesignSystem.Spacing.md)
            .background(DesignSystem.Colors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md))
            .padding(.horizontal, DesignSystem.Spacing.md)

            if !importErrors.isEmpty {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxs) {
                    Text("ERRORS")
                        .font(DesignSystem.Typography.captionBold)
                        .foregroundStyle(DesignSystem.Colors.textSecondary)

                    ScrollView {
                        VStack(alignment: .leading, spacing: 4) {
                            ForEach(importErrors.prefix(10), id: \.self) { error in
                                Text(error)
                                    .font(DesignSystem.Typography.captionSmall)
                                    .foregroundStyle(DesignSystem.Colors.error)
                            }
                            if importErrors.count > 10 {
                                Text("... and \(importErrors.count - 10) more errors")
                                    .font(DesignSystem.Typography.captionSmall)
                                    .foregroundStyle(DesignSystem.Colors.textTertiary)
                            }
                        }
                    }
                    .frame(maxHeight: 150)
                }
                .padding(DesignSystem.Spacing.sm)
                .background(DesignSystem.Colors.error.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md))
                .padding(.horizontal, DesignSystem.Spacing.md)
            }

            Spacer()

            Button {
                dismiss()
            } label: {
                Text("Done")
                    .font(DesignSystem.Typography.heading4)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(DesignSystem.Spacing.sm)
                    .background(DesignSystem.Colors.cyan)
                    .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md))
            }
            .padding(.horizontal, DesignSystem.Spacing.md)
            .padding(.bottom, DesignSystem.Spacing.md)
        }
    }

    private func resultRow(label: String, value: String, color: Color) -> some View {
        HStack {
            Text(label)
                .font(DesignSystem.Typography.body)
                .foregroundStyle(DesignSystem.Colors.textSecondary)
            Spacer()
            Text(value)
                .font(DesignSystem.Typography.labelLarge.monospacedDigit())
                .foregroundStyle(color)
        }
    }

    // MARK: - File Handling

    private func handleFileSelection(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            guard url.startAccessingSecurityScopedResource() else { return }
            defer { url.stopAccessingSecurityScopedResource() }

            do {
                let content = try String(contentsOf: url, encoding: .utf8)
                let lines = parseCSVLines(content)
                guard lines.count >= 2 else {
                    importErrors = ["File must have at least a header row and one data row."]
                    importState = .result
                    return
                }

                headers = lines[0]
                parsedRows = Array(lines.dropFirst())

                // Auto-map columns
                autoMapColumns()

                withAnimation { importState = .preview }
            } catch {
                importErrors = ["Could not read file: \(error.localizedDescription)"]
                importState = .result
            }

        case .failure(let error):
            importErrors = ["File selection failed: \(error.localizedDescription)"]
            importState = .result
        }
    }

    // MARK: - CSV Parsing

    private func parseCSVLines(_ content: String) -> [[String]] {
        var results: [[String]] = []
        var currentField = ""
        var currentRow: [String] = []
        var insideQuotes = false

        let chars = Array(content)
        var i = 0

        while i < chars.count {
            let c = chars[i]

            if insideQuotes {
                if c == "\"" {
                    // Check for escaped quote
                    if i + 1 < chars.count && chars[i + 1] == "\"" {
                        currentField.append("\"")
                        i += 2
                        continue
                    } else {
                        insideQuotes = false
                        i += 1
                        continue
                    }
                } else {
                    currentField.append(c)
                    i += 1
                    continue
                }
            }

            switch c {
            case "\"":
                insideQuotes = true
            case ",":
                currentRow.append(currentField.trimmingCharacters(in: .whitespaces))
                currentField = ""
            case "\r":
                // Handle \r\n
                if i + 1 < chars.count && chars[i + 1] == "\n" {
                    i += 1
                }
                currentRow.append(currentField.trimmingCharacters(in: .whitespaces))
                currentField = ""
                if !currentRow.allSatisfy({ $0.isEmpty }) {
                    results.append(currentRow)
                }
                currentRow = []
            case "\n":
                currentRow.append(currentField.trimmingCharacters(in: .whitespaces))
                currentField = ""
                if !currentRow.allSatisfy({ $0.isEmpty }) {
                    results.append(currentRow)
                }
                currentRow = []
            default:
                currentField.append(c)
            }
            i += 1
        }

        // Handle last field/row
        if !currentField.isEmpty || !currentRow.isEmpty {
            currentRow.append(currentField.trimmingCharacters(in: .whitespaces))
            if !currentRow.allSatisfy({ $0.isEmpty }) {
                results.append(currentRow)
            }
        }

        return results
    }

    private func autoMapColumns() {
        columnMapping = [:]
        var usedFields = Set<MappableField>()

        for (index, header) in headers.enumerated() {
            let normalized = header.trimmingCharacters(in: .whitespaces).lowercased()
            if let field = Self.headerAliases[normalized], !usedFields.contains(field) {
                columnMapping[index] = field
                usedFields.insert(field)
            }
        }
    }

    // MARK: - Import

    private func performImport() {
        withAnimation { importState = .importing }

        importedCount = 0
        skippedCount = 0
        importErrors = []

        // Build reverse mapping: field -> column index
        var fieldToColumn: [MappableField: Int] = [:]
        for (col, field) in columnMapping {
            if field != .skip {
                fieldToColumn[field] = col
            }
        }

        for (rowIndex, row) in parsedRows.enumerated() {
            func value(for field: MappableField) -> String? {
                guard let col = fieldToColumn[field], col < row.count else { return nil }
                let val = row[col].trimmingCharacters(in: .whitespaces)
                return val.isEmpty ? nil : val
            }

            guard let name = value(for: .cardName) else {
                skippedCount += 1
                importErrors.append("Row \(rowIndex + 2): Missing card name")
                continue
            }

            guard let valueStr = value(for: .estimatedValue),
                  let estValue = parseNumber(valueStr) else {
                skippedCount += 1
                importErrors.append("Row \(rowIndex + 2): Missing or invalid market value for \"\(name)\"")
                continue
            }

            let card = InventoryCard(
                cardName: name,
                cardNumber: value(for: .cardNumber) ?? "",
                setName: value(for: .setName) ?? "",
                estimatedValue: estValue,
                confidence: 1.0,
                purchaseCost: value(for: .purchaseCost).flatMap { parseNumber($0) },
                category: value(for: .category) ?? CardCategory.rawSingles.rawValue,
                condition: value(for: .condition) ?? CardCondition.nearMint.rawValue,
                notes: value(for: .notes) ?? "",
                quantity: value(for: .quantity).flatMap { Int($0) } ?? 1,
                status: value(for: .status) ?? CardStatus.inStock.rawValue
            )

            // Optional fields
            if let v = value(for: .variant) { card.variant = v }
            if let t = value(for: .tags) { card.tags = t }
            if let s = value(for: .storageLocation) { card.storageLocation = s }
            if let p = value(for: .platform) { card.platform = p }
            if let g = value(for: .grade) { card.grade = g }
            if let gs = value(for: .gradingService) { card.gradingService = gs }

            modelContext.insert(card)
            importedCount += 1
        }

        do {
            try modelContext.save()
            HapticManager.shared.success()
        } catch {
            #if DEBUG
            print("Failed to save imported cards: \(error)")
            #endif
            showSaveError = true
        }

        withAnimation { importState = .result }
    }

    private func parseNumber(_ string: String) -> Double? {
        // Strip currency symbols and whitespace
        let cleaned = string
            .replacingOccurrences(of: "$", with: "")
            .replacingOccurrences(of: ",", with: "")
            .trimmingCharacters(in: .whitespaces)
        return Double(cleaned)
    }
}
