import Foundation

// MARK: - Selling Platform

enum SellingPlatform: String, CaseIterable, Identifiable, Sendable {
    case ebay = "eBay"
    case tcgplayer = "TCGPlayer"
    case facebookMarketplace = "Facebook Marketplace"
    case stockx = "StockX"
    case whatnot = "Whatnot"
    case mercari = "Mercari"
    case heritageAuctions = "Heritage Auctions"
    case cardmarket = "Cardmarket"
    case inPerson = "In-Person Sale"
    case custom = "Custom Fees"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .ebay: return "bag.fill"
        case .tcgplayer: return "creditcard.fill"
        case .facebookMarketplace: return "person.2.fill"
        case .stockx: return "chart.line.uptrend.xyaxis"
        case .whatnot: return "video.fill"
        case .mercari: return "shippingbox.fill"
        case .heritageAuctions: return "building.columns.fill"
        case .cardmarket: return "globe.europe.africa.fill"
        case .inPerson: return "hand.raised.fill"
        case .custom: return "slider.horizontal.3"
        }
    }

    var feeStructure: PlatformFees {
        switch self {
        case .ebay:
            return PlatformFees(
                platformFeePercentage: 0.1295,
                paymentFeePercentage: 0.029,
                paymentFeeFixed: 0.30,
                description: "eBay Managed Payments"
            )
        case .tcgplayer:
            return PlatformFees(
                platformFeePercentage: 0.1285,
                paymentFeePercentage: 0.029,
                paymentFeeFixed: 0.30,
                description: "TCGPlayer Mid-Tier"
            )
        case .facebookMarketplace:
            return PlatformFees(
                platformFeePercentage: 0.05,
                paymentFeePercentage: 0.00,
                paymentFeeFixed: 0.40,
                description: "Facebook Checkout"
            )
        case .stockx:
            return PlatformFees(
                platformFeePercentage: 0.095,
                paymentFeePercentage: 0.03,
                paymentFeeFixed: 0.00,
                description: "StockX Transaction Fee"
            )
        case .whatnot:
            return PlatformFees(
                platformFeePercentage: 0.08,
                paymentFeePercentage: 0.029,
                paymentFeeFixed: 0.30,
                description: "Whatnot Live Sales"
            )
        case .mercari:
            return PlatformFees(
                platformFeePercentage: 0.10,
                paymentFeePercentage: 0.00,
                paymentFeeFixed: 0.00,
                description: "Mercari Flat Fee"
            )
        case .heritageAuctions:
            return PlatformFees(
                platformFeePercentage: 0.15,
                paymentFeePercentage: 0.00,
                paymentFeeFixed: 0.00,
                description: "Heritage Seller Fee (approx)"
            )
        case .cardmarket:
            return PlatformFees(
                platformFeePercentage: 0.05,
                paymentFeePercentage: 0.029,
                paymentFeeFixed: 0.35,
                description: "Cardmarket EU Marketplace"
            )
        case .inPerson:
            return PlatformFees(
                platformFeePercentage: 0.00,
                paymentFeePercentage: 0.00,
                paymentFeeFixed: 0.00,
                description: "Cash Sale"
            )
        case .custom:
            return PlatformFees(
                platformFeePercentage: 0.10,
                paymentFeePercentage: 0.029,
                paymentFeeFixed: 0.30,
                description: "Custom Fee Structure"
            )
        }
    }
}

// MARK: - Platform Fees

struct PlatformFees: Codable, Sendable, Equatable {
    var platformFeePercentage: Double
    var paymentFeePercentage: Double
    var paymentFeeFixed: Double
    var description: String

    var totalEffectiveRate: Double {
        platformFeePercentage + paymentFeePercentage
    }

    func totalFees(for salePrice: Double) -> Double {
        (salePrice * platformFeePercentage) + (salePrice * paymentFeePercentage) + paymentFeeFixed
    }
}

// MARK: - User Platform Preferences

@MainActor
@Observable
final class UserPlatformPreferences {
    private static let defaultPlatformKey = "UserPlatformPreferences.defaultPlatform"
    private static let customFeesKey = "UserPlatformPreferences.customFeeOverrides"
    private static let customPlatformsKey = "UserPlatformPreferences.customPlatforms"

    var defaultPlatform: String? {
        didSet { UserDefaults.standard.set(defaultPlatform, forKey: Self.defaultPlatformKey) }
    }

    var customFeeOverrides: [String: PlatformFees] {
        didSet { saveOverrides() }
    }

    var customPlatforms: [CustomPlatform] {
        didSet { saveCustomPlatforms() }
    }

    init() {
        self.defaultPlatform = UserDefaults.standard.string(forKey: Self.defaultPlatformKey)

        if let data = UserDefaults.standard.data(forKey: Self.customFeesKey),
           let overrides = try? JSONDecoder().decode([String: PlatformFees].self, from: data) {
            self.customFeeOverrides = overrides
        } else {
            self.customFeeOverrides = [:]
        }

        if let data = UserDefaults.standard.data(forKey: Self.customPlatformsKey),
           let platforms = try? JSONDecoder().decode([CustomPlatform].self, from: data) {
            self.customPlatforms = platforms
        } else {
            self.customPlatforms = []
        }
    }

    func getEffectiveFees(for platform: String) -> PlatformFees {
        if let override = customFeeOverrides[platform] {
            return override
        }
        if let builtIn = SellingPlatform(rawValue: platform) {
            return builtIn.feeStructure
        }
        if let custom = customPlatforms.first(where: { $0.name == platform }) {
            return custom.fees
        }
        return PlatformFees(
            platformFeePercentage: 0.10,
            paymentFeePercentage: 0.029,
            paymentFeeFixed: 0.30,
            description: "Default Estimated Fees"
        )
    }

    func saveOverride(for platform: String, fees: PlatformFees) {
        customFeeOverrides[platform] = fees
    }

    func removeOverride(for platform: String) {
        customFeeOverrides.removeValue(forKey: platform)
    }

    func resetToDefaults() {
        customFeeOverrides = [:]
        customPlatforms = []
    }

    func addCustomPlatform(name: String, fees: PlatformFees) {
        let platform = CustomPlatform(name: name, fees: fees)
        customPlatforms.append(platform)
    }

    func removeCustomPlatform(at index: Int) {
        guard customPlatforms.indices.contains(index) else { return }
        let name = customPlatforms[index].name
        customPlatforms.remove(at: index)
        customFeeOverrides.removeValue(forKey: name)
    }

    /// All available platform names (built-in + custom)
    var allPlatformNames: [String] {
        let builtIn = SellingPlatform.allCases.map(\.rawValue)
        let custom = customPlatforms.map(\.name)
        return builtIn + custom
    }

    // MARK: - Persistence

    private func saveOverrides() {
        if let data = try? JSONEncoder().encode(customFeeOverrides) {
            UserDefaults.standard.set(data, forKey: Self.customFeesKey)
        }
    }

    private func saveCustomPlatforms() {
        if let data = try? JSONEncoder().encode(customPlatforms) {
            UserDefaults.standard.set(data, forKey: Self.customPlatformsKey)
        }
    }
}

// MARK: - Custom Platform

struct CustomPlatform: Codable, Identifiable, Sendable {
    var id: UUID = UUID()
    var name: String
    var fees: PlatformFees
}
