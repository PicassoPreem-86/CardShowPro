import SwiftUI

struct ManagePlatformsView: View {
    @State private var platformPreferences = UserPlatformPreferences()
    @State private var showAddPlatform = false
    @State private var editingPlatform: String?
    @State private var showResetAlert = false

    var body: some View {
        List {
            builtInPlatformsSection
            customPlatformsSection
            defaultPlatformSection
            resetSection
        }
        .navigationTitle("Manage Platforms")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: editingPlatformBinding) { item in
            EditPlatformFeesSheet(
                platformName: item.name,
                fees: item.fees,
                onSave: { newFees in
                    platformPreferences.saveOverride(for: item.name, fees: newFees)
                }
            )
        }
        .sheet(isPresented: $showAddPlatform) {
            AddCustomPlatformSheet { name, fees in
                platformPreferences.addCustomPlatform(name: name, fees: fees)
            }
        }
        .alert("Reset to Defaults", isPresented: $showResetAlert) {
            Button("Reset", role: .destructive) {
                platformPreferences.resetToDefaults()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This will remove all custom fee overrides and custom platforms.")
        }
    }

    // MARK: - Binding wrapper for sheet

    private var editingPlatformBinding: Binding<PlatformEditItem?> {
        Binding(
            get: {
                guard let name = editingPlatform else { return nil }
                let fees = platformPreferences.getEffectiveFees(for: name)
                return PlatformEditItem(name: name, fees: fees)
            },
            set: { newValue in
                editingPlatform = newValue?.name
            }
        )
    }

    // MARK: - Built-in Platforms

    private var builtInPlatformsSection: some View {
        Section {
            ForEach(SellingPlatform.allCases, id: \.rawValue) { platform in
                let effectiveFees = platformPreferences.getEffectiveFees(for: platform.rawValue)
                let hasOverride = platformPreferences.customFeeOverrides[platform.rawValue] != nil

                Button {
                    editingPlatform = platform.rawValue
                } label: {
                    HStack(spacing: DesignSystem.Spacing.xs) {
                        Image(systemName: platform.icon)
                            .font(.title3)
                            .foregroundStyle(DesignSystem.Colors.cyan)
                            .frame(width: 28)

                        VStack(alignment: .leading, spacing: 2) {
                            HStack(spacing: 6) {
                                Text(platform.rawValue)
                                    .font(DesignSystem.Typography.labelLarge)
                                    .foregroundStyle(DesignSystem.Colors.textPrimary)
                                if hasOverride {
                                    Text("Custom")
                                        .font(DesignSystem.Typography.captionSmall)
                                        .foregroundStyle(DesignSystem.Colors.warning)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(DesignSystem.Colors.warning.opacity(0.15))
                                        .clipShape(Capsule())
                                }
                            }
                            Text(feesSummary(effectiveFees))
                                .font(DesignSystem.Typography.caption)
                                .foregroundStyle(DesignSystem.Colors.textSecondary)
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(DesignSystem.Colors.textTertiary)
                    }
                }
                .swipeActions(edge: .trailing) {
                    if hasOverride {
                        Button("Reset") {
                            platformPreferences.removeOverride(for: platform.rawValue)
                        }
                        .tint(.orange)
                    }
                }
            }
        } header: {
            Text("Built-in Platforms")
        }
        .listRowBackground(DesignSystem.Colors.cardBackground)
    }

    // MARK: - Custom Platforms

    private var customPlatformsSection: some View {
        Section {
            ForEach(platformPreferences.customPlatforms) { platform in
                Button {
                    editingPlatform = platform.name
                } label: {
                    HStack(spacing: DesignSystem.Spacing.xs) {
                        Image(systemName: "star.fill")
                            .font(.title3)
                            .foregroundStyle(DesignSystem.Colors.electricBlue)
                            .frame(width: 28)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(platform.name)
                                .font(DesignSystem.Typography.labelLarge)
                                .foregroundStyle(DesignSystem.Colors.textPrimary)
                            Text(feesSummary(platform.fees))
                                .font(DesignSystem.Typography.caption)
                                .foregroundStyle(DesignSystem.Colors.textSecondary)
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(DesignSystem.Colors.textTertiary)
                    }
                }
            }
            .onDelete { indexSet in
                for index in indexSet {
                    platformPreferences.removeCustomPlatform(at: index)
                }
            }

            Button {
                showAddPlatform = true
            } label: {
                HStack(spacing: DesignSystem.Spacing.xs) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                        .foregroundStyle(DesignSystem.Colors.success)
                        .frame(width: 28)
                    Text("Add Custom Platform")
                        .font(DesignSystem.Typography.body)
                        .foregroundStyle(DesignSystem.Colors.success)
                }
            }
        } header: {
            Text("Custom Platforms")
        }
        .listRowBackground(DesignSystem.Colors.cardBackground)
    }

    // MARK: - Default Platform

    private var defaultPlatformSection: some View {
        Section {
            if let defaultPlatform = platformPreferences.defaultPlatform {
                HStack {
                    Text("Default Platform")
                        .font(DesignSystem.Typography.body)
                        .foregroundStyle(DesignSystem.Colors.textPrimary)
                    Spacer()
                    Text(defaultPlatform)
                        .font(DesignSystem.Typography.body)
                        .foregroundStyle(DesignSystem.Colors.cyan)
                }

                Button("Clear Default") {
                    platformPreferences.defaultPlatform = nil
                }
                .foregroundStyle(DesignSystem.Colors.error)
            } else {
                Text("No default platform set. Your last-used platform will be remembered automatically.")
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
            }
        } header: {
            Text("Default Platform")
        }
        .listRowBackground(DesignSystem.Colors.cardBackground)
    }

    // MARK: - Reset Section

    private var resetSection: some View {
        Section {
            Button("Reset All to Defaults") {
                showResetAlert = true
            }
            .foregroundStyle(DesignSystem.Colors.error)
        }
        .listRowBackground(DesignSystem.Colors.cardBackground)
    }

    // MARK: - Helpers

    private func feesSummary(_ fees: PlatformFees) -> String {
        let parts = [
            fees.platformFeePercentage > 0 ? "\(String(format: "%.1f", fees.platformFeePercentage * 100))% platform" : nil,
            fees.paymentFeePercentage > 0 ? "\(String(format: "%.1f", fees.paymentFeePercentage * 100))% payment" : nil,
            fees.paymentFeeFixed > 0 ? "$\(String(format: "%.2f", fees.paymentFeeFixed)) fixed" : nil
        ].compactMap { $0 }

        return parts.isEmpty ? "No fees" : parts.joined(separator: " + ")
    }
}

// MARK: - Platform Edit Item

struct PlatformEditItem: Identifiable {
    var id: String { name }
    let name: String
    let fees: PlatformFees
}

// MARK: - Edit Platform Fees Sheet

struct EditPlatformFeesSheet: View {
    let platformName: String
    let fees: PlatformFees
    let onSave: (PlatformFees) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var platformFeeText: String = ""
    @State private var paymentFeeText: String = ""
    @State private var fixedFeeText: String = ""

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        Text("Platform Fee %")
                        Spacer()
                        TextField("0.0", text: $platformFeeText)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                        Text("%")
                            .foregroundStyle(.secondary)
                    }

                    HStack {
                        Text("Payment Fee %")
                        Spacer()
                        TextField("0.0", text: $paymentFeeText)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                        Text("%")
                            .foregroundStyle(.secondary)
                    }

                    HStack {
                        Text("Fixed Fee")
                        Spacer()
                        Text("$")
                            .foregroundStyle(.secondary)
                        TextField("0.00", text: $fixedFeeText)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                    }
                } header: {
                    Text("Fee Structure")
                }

                Section {
                    let total = (Double(platformFeeText) ?? 0) + (Double(paymentFeeText) ?? 0)
                    let fixed = Double(fixedFeeText) ?? 0
                    HStack {
                        Text("Total Rate")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("\(String(format: "%.1f", total))% + $\(String(format: "%.2f", fixed))")
                            .fontWeight(.semibold)
                            .foregroundStyle(DesignSystem.Colors.cyan)
                    }
                } header: {
                    Text("Summary")
                }
            }
            .navigationTitle(platformName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let newFees = PlatformFees(
                            platformFeePercentage: (Double(platformFeeText) ?? 0) / 100.0,
                            paymentFeePercentage: (Double(paymentFeeText) ?? 0) / 100.0,
                            paymentFeeFixed: Double(fixedFeeText) ?? 0,
                            description: "\(platformName) (Custom)"
                        )
                        onSave(newFees)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
            .onAppear {
                platformFeeText = String(format: "%.1f", fees.platformFeePercentage * 100)
                paymentFeeText = String(format: "%.1f", fees.paymentFeePercentage * 100)
                fixedFeeText = String(format: "%.2f", fees.paymentFeeFixed)
            }
        }
    }
}

// MARK: - Add Custom Platform Sheet

struct AddCustomPlatformSheet: View {
    let onSave: (String, PlatformFees) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var platformName: String = ""
    @State private var platformFeeText: String = "10.0"
    @State private var paymentFeeText: String = "2.9"
    @State private var fixedFeeText: String = "0.30"

    private var canSave: Bool {
        !platformName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Platform Name", text: $platformName)
                } header: {
                    Text("Platform")
                }

                Section {
                    HStack {
                        Text("Platform Fee %")
                        Spacer()
                        TextField("0.0", text: $platformFeeText)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                        Text("%")
                            .foregroundStyle(.secondary)
                    }

                    HStack {
                        Text("Payment Fee %")
                        Spacer()
                        TextField("0.0", text: $paymentFeeText)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                        Text("%")
                            .foregroundStyle(.secondary)
                    }

                    HStack {
                        Text("Fixed Fee")
                        Spacer()
                        Text("$")
                            .foregroundStyle(.secondary)
                        TextField("0.00", text: $fixedFeeText)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                    }
                } header: {
                    Text("Fee Structure")
                }
            }
            .navigationTitle("Add Platform")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        let fees = PlatformFees(
                            platformFeePercentage: (Double(platformFeeText) ?? 0) / 100.0,
                            paymentFeePercentage: (Double(paymentFeeText) ?? 0) / 100.0,
                            paymentFeeFixed: Double(fixedFeeText) ?? 0,
                            description: platformName.trimmingCharacters(in: .whitespacesAndNewlines)
                        )
                        onSave(platformName.trimmingCharacters(in: .whitespacesAndNewlines), fees)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .disabled(!canSave)
                }
            }
        }
    }
}
