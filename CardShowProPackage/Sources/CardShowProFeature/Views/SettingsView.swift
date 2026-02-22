import SwiftUI
import SwiftData

// MARK: - Share Sheet

/// Minimal UIActivityViewController wrapper for sharing exported text.
private struct ShareSheetView: UIViewControllerRepresentable {
    let text: String
    let fileName: String

    func makeUIViewController(context: Context) -> UIActivityViewController {
        // Write text to a temporary file so the share sheet offers "Save to Files"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        try? text.write(to: url, atomically: true, encoding: .utf8)

        let controller = UIActivityViewController(
            activityItems: [url],
            applicationActivities: nil
        )
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Platform Options

private enum SalesPlatform: String, CaseIterable, Identifiable {
    case eBay = "eBay"
    case tcgPlayer = "TCGPlayer"
    case facebook = "Facebook"
    case mercari = "Mercari"
    case other = "Other"

    var id: String { rawValue }
}

// MARK: - Settings View

struct SettingsView: View {
    @Binding var isShowModeActive: Bool
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @Query private var cards: [InventoryCard]
    @Query private var transactions: [Transaction]

    // Business profile
    @AppStorage("businessName") private var businessName: String = ""
    @AppStorage("defaultPlatform") private var defaultPlatform: String = SalesPlatform.eBay.rawValue
    @AppStorage("defaultShippingCost") private var defaultShippingCost: Double = 5.00

    // Export state
    @State private var exportText: String?
    @State private var exportFileName: String = "export.csv"
    @State private var showingShare = false

    // Notification settings
    @State private var notificationSettings = NotificationService.shared.settings
    @State private var notificationsAuthorized = false

    // Confirmation alerts
    @State private var showResetAlert = false
    @State private var showDeleteAlert = false
    @State private var showClearCacheAlert = false
    @State private var cachedPriceCount: Int = 0

    var body: some View {
        NavigationStack {
            Form {
                businessProfileSection
                notificationSection
                showModeSection
                cacheManagementSection
                dataExportSection
                dataManagementSection
                aboutSection
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingShare) {
                if let text = exportText {
                    ShareSheetView(text: text, fileName: exportFileName)
                        .presentationDetents([.medium, .large])
                }
            }
            .alert("Reset Sample Data?", isPresented: $showResetAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Reset", role: .destructive) {
                    resetSampleData()
                }
            } message: {
                Text("This will delete all existing data and re-seed with sample cards and transactions.")
            }
            .alert("Clear Price Cache?", isPresented: $showClearCacheAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Clear", role: .destructive) {
                    clearPriceCache()
                }
            } message: {
                Text("This will remove all cached card prices. Prices will be re-fetched on next lookup.")
            }
            .task {
                notificationsAuthorized = await NotificationService.shared.isAuthorized()
            }
            .alert("Delete All Data?", isPresented: $showDeleteAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Delete Everything", role: .destructive) {
                    deleteAllData()
                }
            } message: {
                Text("This will permanently remove all inventory cards and transactions. This action cannot be undone.")
            }
        }
    }

    // MARK: - Business Profile

    private var businessProfileSection: some View {
        Section {
            HStack(spacing: DesignSystem.Spacing.xs) {
                Image(systemName: "building.2.fill")
                    .foregroundStyle(DesignSystem.Colors.cyan)
                    .frame(width: 24)
                TextField("Business Name", text: $businessName)
            }

            HStack(spacing: DesignSystem.Spacing.xs) {
                Image(systemName: "storefront.fill")
                    .foregroundStyle(DesignSystem.Colors.cyan)
                    .frame(width: 24)
                Picker("Default Platform", selection: $defaultPlatform) {
                    ForEach(SalesPlatform.allCases) { platform in
                        Text(platform.rawValue).tag(platform.rawValue)
                    }
                }
            }

            HStack(spacing: DesignSystem.Spacing.xs) {
                Image(systemName: "shippingbox.fill")
                    .foregroundStyle(DesignSystem.Colors.cyan)
                    .frame(width: 24)
                Text("Default Shipping")
                Spacer()
                TextField("$0.00", value: $defaultShippingCost, format: .currency(code: "USD"))
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 80)
            }
        } header: {
            Text("Business Profile")
        }
    }

    // MARK: - Show Mode

    private var showModeSection: some View {
        Section {
            Toggle(isOn: $isShowModeActive) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Image(systemName: "bolt.fill")
                            .foregroundStyle(.orange)
                        Text("Show Mode")
                            .font(.headline)
                    }
                    Text("Camera-first mode for live events")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .tint(.orange)

            if isShowModeActive {
                HStack {
                    Image(systemName: "clock.fill")
                        .foregroundStyle(.blue)
                    Text("Event Started")
                    Spacer()
                    Text("Active")
                        .font(.caption)
                        .foregroundStyle(.green)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.green.opacity(0.1))
                        .clipShape(Capsule())
                }
            }
        } header: {
            Text("Show Mode")
        }
    }

    // MARK: - Notifications

    private var notificationSection: some View {
        Section {
            // System authorization status
            if !notificationsAuthorized {
                HStack(spacing: DesignSystem.Spacing.xs) {
                    Image(systemName: "bell.slash.fill")
                        .foregroundStyle(DesignSystem.Colors.warning)
                        .frame(width: 24)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Notifications Disabled")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Text("Enable in iOS Settings to receive alerts")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Button("Open Settings") {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    }
                    .font(.caption)
                    .fontWeight(.semibold)
                }
            }

            // Category toggles
            ForEach(NotificationCategory.allCases, id: \.rawValue) { category in
                Toggle(isOn: Binding(
                    get: { notificationSettings.isEnabled(category) },
                    set: { _ in
                        notificationSettings.toggle(category)
                        NotificationService.shared.updateSettings(notificationSettings)
                        if !notificationSettings.isEnabled(category) {
                            NotificationService.shared.cancelCategory(category)
                        }
                    }
                )) {
                    HStack(spacing: DesignSystem.Spacing.xs) {
                        Image(systemName: category.icon)
                            .foregroundStyle(DesignSystem.Colors.cyan)
                            .frame(width: 24)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(category.title)
                                .font(.subheadline)
                            Text(category.description)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .tint(DesignSystem.Colors.cyan)
            }

            // Stale listing threshold
            if notificationSettings.isEnabled(.staleListings) {
                HStack(spacing: DesignSystem.Spacing.xs) {
                    Image(systemName: "calendar.badge.clock")
                        .foregroundStyle(DesignSystem.Colors.warning)
                        .frame(width: 24)
                    Text("Stale After")
                    Spacer()
                    Picker("", selection: Binding(
                        get: { notificationSettings.staleListingDays },
                        set: {
                            notificationSettings.staleListingDays = $0
                            NotificationService.shared.setStaleListingDays($0)
                        }
                    )) {
                        Text("7 days").tag(7)
                        Text("14 days").tag(14)
                        Text("30 days").tag(30)
                    }
                    .pickerStyle(.menu)
                }
            }

            // Slow inventory threshold
            if notificationSettings.isEnabled(.slowInventory) {
                HStack(spacing: DesignSystem.Spacing.xs) {
                    Image(systemName: "clock.arrow.circlepath")
                        .foregroundStyle(DesignSystem.Colors.warning)
                        .frame(width: 24)
                    Text("Slow After")
                    Spacer()
                    Picker("", selection: Binding(
                        get: { notificationSettings.slowInventoryDays },
                        set: {
                            notificationSettings.slowInventoryDays = $0
                            NotificationService.shared.setSlowInventoryDays($0)
                        }
                    )) {
                        Text("30 days").tag(30)
                        Text("60 days").tag(60)
                        Text("90 days").tag(90)
                    }
                    .pickerStyle(.menu)
                }
            }
        } header: {
            Text("Notifications")
        } footer: {
            Text("Max 3 alerts per day. Scheduled reminders (events, follow-ups) are always delivered.")
        }
    }

    // MARK: - Data Export

    private var dataExportSection: some View {
        Section {
            Button {
                exportText = DataExportService.exportInventoryCSV(cards: Array(cards))
                exportFileName = "CardShowPro_Inventory.csv"
                showingShare = true
            } label: {
                Label("Export Inventory (CSV)", systemImage: "tablecells")
            }
            .disabled(cards.isEmpty)

            Button {
                exportText = DataExportService.exportTransactionsCSV(transactions: Array(transactions))
                exportFileName = "CardShowPro_Transactions.csv"
                showingShare = true
            } label: {
                Label("Export Transactions (CSV)", systemImage: "list.bullet.rectangle")
            }
            .disabled(transactions.isEmpty)

            Button {
                exportText = DataExportService.exportPLReport(
                    cards: Array(cards),
                    transactions: Array(transactions)
                )
                exportFileName = "CardShowPro_PL_Report.txt"
                showingShare = true
            } label: {
                Label("Export P&L Report", systemImage: "chart.bar.doc.horizontal")
            }
            .disabled(cards.isEmpty && transactions.isEmpty)
        } header: {
            Text("Data Export")
        } footer: {
            Text("Exports are shared as files you can save, email, or AirDrop.")
        }
    }

    // MARK: - Data Management

    private var dataManagementSection: some View {
        Section {
            Button {
                showResetAlert = true
            } label: {
                Label("Reset Sample Data", systemImage: "arrow.counterclockwise")
            }

            Button(role: .destructive) {
                showDeleteAlert = true
            } label: {
                Label("Delete All Data", systemImage: "trash")
                    .foregroundStyle(.red)
            }
        } header: {
            Text("Data Management")
        }
    }

    // MARK: - Cache Management

    private var cacheManagementSection: some View {
        Section {
            HStack {
                Label("Price Cache", systemImage: "cylinder.split.1x2.fill")
                Spacer()
                Text("\(cachedPriceCount) cards cached")
                    .foregroundStyle(.secondary)
            }
            .task {
                let repo = PriceCacheRepository(modelContext: modelContext)
                cachedPriceCount = repo.persistedEntryCount()
            }

            Button(role: .destructive) {
                showClearCacheAlert = true
            } label: {
                Label("Clear Price Cache", systemImage: "trash")
                    .foregroundStyle(.red)
            }
        } header: {
            Text("Cache")
        } footer: {
            Text("Cached prices speed up lookups and work offline. Prices auto-refresh after 24 hours.")
        }
    }

    // MARK: - About

    private var aboutSection: some View {
        Section {
            HStack {
                Image(systemName: "sparkles")
                    .foregroundStyle(DesignSystem.Colors.thunderYellow)
                Text("CardShowPro")
                    .font(.headline)
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text("v\(appVersion)")
                        .foregroundStyle(.secondary)
                    Text("Build \(buildNumber)")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
        } header: {
            Text("About")
        } footer: {
            Text("Built for card dealers who hustle.")
                .font(.caption2)
                .frame(maxWidth: .infinity)
                .padding(.top, DesignSystem.Spacing.xxs)
        }
    }

    // MARK: - Actions

    private func resetSampleData() {
        // Delete existing data
        do {
            try modelContext.delete(model: InventoryCard.self)
            try modelContext.delete(model: Transaction.self)
            try modelContext.save()
        } catch {
            #if DEBUG
            print("Failed to clear data for reset: \(error)")
            #endif
        }

        // Reset the seed flag and re-seed
        MockDataSeeder.reset()
        MockDataSeeder.seedIfNeeded(context: modelContext)
    }

    private func clearPriceCache() {
        let repo = PriceCacheRepository(modelContext: modelContext)
        repo.clearCache()
        cachedPriceCount = 0
    }

    private func deleteAllData() {
        do {
            try modelContext.delete(model: InventoryCard.self)
            try modelContext.delete(model: Transaction.self)
            try modelContext.save()
        } catch {
            #if DEBUG
            print("Failed to delete all data: \(error)")
            #endif
        }
    }

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }

    private var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }
}
