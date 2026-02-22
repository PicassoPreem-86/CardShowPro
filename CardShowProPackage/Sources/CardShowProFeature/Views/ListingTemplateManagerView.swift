import SwiftUI
import SwiftData

/// Manages user-created listing templates: create, edit, delete, set defaults.
struct ListingTemplateManagerView: View {
    @Query(sort: \ListingTemplate.dateCreated, order: .reverse)
    private var templates: [ListingTemplate]

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var showAddTemplate: Bool = false
    @State private var editingTemplate: ListingTemplate?
    @State private var templateToDelete: ListingTemplate?
    @State private var showDeleteConfirmation: Bool = false

    var body: some View {
        NavigationStack {
            ZStack {
                DesignSystem.Colors.backgroundPrimary
                    .ignoresSafeArea()

                if templates.isEmpty {
                    emptyState
                } else {
                    templateList
                }
            }
            .navigationTitle("Listing Templates")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(DesignSystem.Colors.textSecondary)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showAddTemplate = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundStyle(DesignSystem.Colors.cyan)
                    }
                }
            }
            .sheet(isPresented: $showAddTemplate) {
                EditListingTemplateView(mode: .create) { template in
                    modelContext.insert(template)
                    try? modelContext.save()
                }
            }
            .sheet(item: $editingTemplate) { template in
                EditListingTemplateView(mode: .edit(template)) { _ in
                    try? modelContext.save()
                }
            }
            .alert("Delete Template?", isPresented: $showDeleteConfirmation) {
                Button("Delete", role: .destructive) {
                    if let template = templateToDelete {
                        modelContext.delete(template)
                        try? modelContext.save()
                    }
                    templateToDelete = nil
                }
                Button("Cancel", role: .cancel) {
                    templateToDelete = nil
                }
            } message: {
                if let template = templateToDelete {
                    Text("Are you sure you want to delete \"\(template.name)\"?")
                }
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: DesignSystem.Spacing.sm) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 40))
                .foregroundStyle(DesignSystem.Colors.textTertiary)

            Text("No Templates")
                .font(DesignSystem.Typography.heading4)
                .foregroundStyle(DesignSystem.Colors.textSecondary)

            Text("Create custom templates with variables like {cardName}, {setName}, and {condition} to generate listings faster.")
                .font(DesignSystem.Typography.body)
                .foregroundStyle(DesignSystem.Colors.textTertiary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, DesignSystem.Spacing.xl)

            Button {
                showAddTemplate = true
            } label: {
                HStack(spacing: DesignSystem.Spacing.xs) {
                    Image(systemName: "plus.circle.fill")
                    Text("Create Template")
                        .font(DesignSystem.Typography.labelLarge)
                }
                .padding(.horizontal, DesignSystem.Spacing.lg)
                .padding(.vertical, DesignSystem.Spacing.sm)
                .background(DesignSystem.Colors.cyan)
                .foregroundStyle(DesignSystem.Colors.backgroundPrimary)
                .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md))
            }
            .padding(.top, DesignSystem.Spacing.sm)
        }
        .padding(DesignSystem.Spacing.xl)
    }

    // MARK: - Template List

    private var templateList: some View {
        List {
            ForEach(templates) { template in
                TemplateRow(
                    template: template,
                    onEdit: { editingTemplate = template },
                    onToggleDefault: { toggleDefault(template) },
                    onDelete: {
                        templateToDelete = template
                        showDeleteConfirmation = true
                    }
                )
                .listRowBackground(DesignSystem.Colors.cardBackground)
                .listRowSeparatorTint(DesignSystem.Colors.borderPrimary)
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }

    // MARK: - Actions

    private func toggleDefault(_ template: ListingTemplate) {
        if template.isDefault {
            template.isDefault = false
        } else {
            // Clear other defaults
            for t in templates where t.isDefault {
                t.isDefault = false
            }
            template.isDefault = true
        }
        try? modelContext.save()
    }
}

// MARK: - Template Row

private struct TemplateRow: View {
    let template: ListingTemplate
    let onEdit: () -> Void
    let onToggleDefault: () -> Void
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
            HStack {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxxs) {
                    HStack(spacing: DesignSystem.Spacing.xs) {
                        Text(template.name)
                            .font(DesignSystem.Typography.labelLarge)
                            .foregroundStyle(DesignSystem.Colors.textPrimary)

                        if template.isDefault {
                            Text("Default")
                                .font(DesignSystem.Typography.caption)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(DesignSystem.Colors.cyan.opacity(0.2))
                                .foregroundStyle(DesignSystem.Colors.cyan)
                                .clipShape(Capsule())
                        }
                    }

                    if let platform = template.platform {
                        Text(platform)
                            .font(DesignSystem.Typography.bodySmall)
                            .foregroundStyle(DesignSystem.Colors.textSecondary)
                    }
                }

                Spacer()

                Menu {
                    Button { onEdit() } label: {
                        Label("Edit", systemImage: "pencil")
                    }
                    Button { onToggleDefault() } label: {
                        Label(
                            template.isDefault ? "Remove Default" : "Set as Default",
                            systemImage: template.isDefault ? "star.slash" : "star"
                        )
                    }
                    Divider()
                    Button(role: .destructive) { onDelete() } label: {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.body)
                        .foregroundStyle(DesignSystem.Colors.textTertiary)
                }
            }

            // Title format preview
            VStack(alignment: .leading, spacing: 2) {
                Text("Title:")
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(DesignSystem.Colors.textTertiary)
                Text(template.titleFormat)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
                    .lineLimit(1)
            }

            // Description format preview
            VStack(alignment: .leading, spacing: 2) {
                Text("Description:")
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(DesignSystem.Colors.textTertiary)
                Text(template.descriptionFormat)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
                    .lineLimit(2)
            }
        }
        .padding(.vertical, DesignSystem.Spacing.xxxs)
    }
}

// MARK: - Edit/Create Template View

struct EditListingTemplateView: View {
    enum Mode: Identifiable {
        case create
        case edit(ListingTemplate)

        var id: String {
            switch self {
            case .create: return "create"
            case .edit(let t): return t.id.uuidString
            }
        }
    }

    let mode: Mode
    let onSave: (ListingTemplate) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var name: String = ""
    @State private var platform: String = ""
    @State private var titleFormat: String = "{cardName} - {setName} - {condition}"
    @State private var descriptionFormat: String = "{cardName} from {setName}. Condition: {condition}."
    @State private var showVariableHelp: Bool = false

    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
        && !titleFormat.trimmingCharacters(in: .whitespaces).isEmpty
    }

    private var navigationTitle: String {
        switch mode {
        case .create: return "New Template"
        case .edit: return "Edit Template"
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                DesignSystem.Colors.backgroundPrimary
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: DesignSystem.Spacing.lg) {
                        nameSection
                        platformSection
                        variableHelpSection
                        titleSection
                        descriptionSection
                        previewSection
                    }
                    .padding(DesignSystem.Spacing.md)
                }
            }
            .navigationTitle(navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(DesignSystem.Colors.textSecondary)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") { save() }
                        .font(DesignSystem.Typography.labelLarge)
                        .foregroundStyle(isValid ? DesignSystem.Colors.cyan : DesignSystem.Colors.textDisabled)
                        .disabled(!isValid)
                }
            }
            .onAppear { loadExisting() }
        }
    }

    // MARK: - Sections

    private var nameSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
            Text("Template Name")
                .font(DesignSystem.Typography.captionBold)
                .foregroundStyle(DesignSystem.Colors.textSecondary)

            TextField("e.g. eBay Graded Cards", text: $name)
                .font(DesignSystem.Typography.body)
                .foregroundStyle(DesignSystem.Colors.textPrimary)
                .padding(DesignSystem.Spacing.sm)
                .background(DesignSystem.Colors.backgroundTertiary)
                .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md))
        }
    }

    private var platformSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
            Text("Platform (optional)")
                .font(DesignSystem.Typography.captionBold)
                .foregroundStyle(DesignSystem.Colors.textSecondary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: DesignSystem.Spacing.xxs) {
                    ForEach(["", "eBay", "TCGPlayer", "Facebook", "Mercari"], id: \.self) { p in
                        Button {
                            platform = p
                        } label: {
                            Text(p.isEmpty ? "Any" : p)
                                .font(DesignSystem.Typography.label)
                                .padding(.horizontal, DesignSystem.Spacing.sm)
                                .padding(.vertical, DesignSystem.Spacing.xxs)
                                .background(platform == p ? DesignSystem.Colors.cyan.opacity(0.2) : DesignSystem.Colors.backgroundTertiary)
                                .foregroundStyle(platform == p ? DesignSystem.Colors.cyan : DesignSystem.Colors.textSecondary)
                                .clipShape(Capsule())
                        }
                    }
                }
            }
        }
    }

    private var variableHelpSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
            Button {
                withAnimation { showVariableHelp.toggle() }
            } label: {
                HStack {
                    Image(systemName: "info.circle.fill")
                        .foregroundStyle(DesignSystem.Colors.electricBlue)
                    Text("Available Variables")
                        .font(DesignSystem.Typography.captionBold)
                        .foregroundStyle(DesignSystem.Colors.textSecondary)
                    Spacer()
                    Image(systemName: showVariableHelp ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundStyle(DesignSystem.Colors.textTertiary)
                }
            }
            .buttonStyle(.plain)

            if showVariableHelp {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxs) {
                    variableRow("{cardName}", "Card name")
                    variableRow("{setName}", "Set name")
                    variableRow("{cardNumber}", "Card number")
                    variableRow("{condition}", "Card condition")
                    variableRow("{grade}", "Grade (or \"Ungraded\")")
                    variableRow("{variant}", "Variant (or \"Standard\")")
                    variableRow("{price}", "Estimated value")
                }
                .padding(DesignSystem.Spacing.sm)
                .background(DesignSystem.Colors.backgroundTertiary)
                .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md))
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    private func variableRow(_ variable: String, _ desc: String) -> some View {
        HStack(spacing: DesignSystem.Spacing.xs) {
            Text(variable)
                .font(.system(.caption, design: .monospaced))
                .foregroundStyle(DesignSystem.Colors.cyan)
                .frame(width: 100, alignment: .leading)

            Text(desc)
                .font(DesignSystem.Typography.bodySmall)
                .foregroundStyle(DesignSystem.Colors.textSecondary)
        }
    }

    private var titleSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
            Text("Title Format")
                .font(DesignSystem.Typography.captionBold)
                .foregroundStyle(DesignSystem.Colors.textSecondary)

            TextField("{cardName} - {setName} - {condition}", text: $titleFormat, axis: .vertical)
                .font(.system(.footnote, design: .monospaced))
                .foregroundStyle(DesignSystem.Colors.textPrimary)
                .lineLimit(2...4)
                .padding(DesignSystem.Spacing.sm)
                .background(DesignSystem.Colors.backgroundTertiary)
                .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md))
        }
    }

    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
            Text("Description Format")
                .font(DesignSystem.Typography.captionBold)
                .foregroundStyle(DesignSystem.Colors.textSecondary)

            TextField("Enter description template...", text: $descriptionFormat, axis: .vertical)
                .font(.system(.footnote, design: .monospaced))
                .foregroundStyle(DesignSystem.Colors.textPrimary)
                .lineLimit(4...10)
                .padding(DesignSystem.Spacing.sm)
                .background(DesignSystem.Colors.backgroundTertiary)
                .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md))
        }
    }

    private var previewSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
            Text("Preview (sample data)")
                .font(DesignSystem.Typography.captionBold)
                .foregroundStyle(DesignSystem.Colors.textSecondary)

            let sampleTitle = titleFormat
                .replacingOccurrences(of: "{cardName}", with: "Charizard ex")
                .replacingOccurrences(of: "{setName}", with: "Obsidian Flames")
                .replacingOccurrences(of: "{cardNumber}", with: "125/197")
                .replacingOccurrences(of: "{condition}", with: "Near Mint")
                .replacingOccurrences(of: "{grade}", with: "PSA 10")
                .replacingOccurrences(of: "{variant}", with: "Full Art")
                .replacingOccurrences(of: "{price}", with: "45.99")

            let sampleDesc = descriptionFormat
                .replacingOccurrences(of: "{cardName}", with: "Charizard ex")
                .replacingOccurrences(of: "{setName}", with: "Obsidian Flames")
                .replacingOccurrences(of: "{cardNumber}", with: "125/197")
                .replacingOccurrences(of: "{condition}", with: "Near Mint")
                .replacingOccurrences(of: "{grade}", with: "PSA 10")
                .replacingOccurrences(of: "{variant}", with: "Full Art")
                .replacingOccurrences(of: "{price}", with: "45.99")

            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                Text(sampleTitle)
                    .font(DesignSystem.Typography.labelLarge)
                    .foregroundStyle(DesignSystem.Colors.textPrimary)

                Text(sampleDesc)
                    .font(DesignSystem.Typography.bodySmall)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(DesignSystem.Spacing.sm)
            .background(DesignSystem.Colors.backgroundTertiary)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md))
        }
    }

    // MARK: - Actions

    private func loadExisting() {
        if case .edit(let template) = mode {
            name = template.name
            platform = template.platform ?? ""
            titleFormat = template.titleFormat
            descriptionFormat = template.descriptionFormat
        }
    }

    private func save() {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else { return }

        switch mode {
        case .create:
            let template = ListingTemplate(
                name: trimmedName,
                platform: platform.isEmpty ? nil : platform,
                titleFormat: titleFormat,
                descriptionFormat: descriptionFormat
            )
            onSave(template)
        case .edit(let template):
            template.name = trimmedName
            template.platform = platform.isEmpty ? nil : platform
            template.titleFormat = titleFormat
            template.descriptionFormat = descriptionFormat
            onSave(template)
        }
        dismiss()
    }
}
