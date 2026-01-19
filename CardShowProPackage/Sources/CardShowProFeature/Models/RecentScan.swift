import Foundation

/// Represents a recently scanned card in the current session
/// Used for the "Recent scans" section in ScanView
struct RecentScan: Identifiable, Codable, Equatable {
    let id: UUID
    let cardName: String
    let setName: String
    let price: Double
    let thumbnailURL: URL?
    let scannedAt: Date

    init(
        id: UUID = UUID(),
        cardName: String,
        setName: String,
        price: Double,
        thumbnailURL: URL? = nil,
        scannedAt: Date = Date()
    ) {
        self.id = id
        self.cardName = cardName
        self.setName = setName
        self.price = price
        self.thumbnailURL = thumbnailURL
        self.scannedAt = scannedAt
    }

    /// Formatted price string
    var formattedPrice: String {
        price.formatted(.currency(code: "USD"))
    }

    /// Time since scan for display
    var timeAgo: String {
        let interval = Date().timeIntervalSince(scannedAt)

        // Handle edge cases (negative time from clock changes)
        guard interval > 0 else { return "Just now" }

        if interval < 60 {
            return "Just now"
        } else if interval < 3600 {
            let minutes = Int(interval / 60)
            return "\(minutes)m ago"
        } else if interval < 86400 {
            let hours = Int(interval / 3600)
            return "\(hours)h ago"
        } else {
            let days = Int(interval / 86400)
            return "\(days)d ago"
        }
    }
}

// MARK: - Session Storage

/// Manages recent scans for the current session
@MainActor
@Observable
final class RecentScansManager {
    static let shared = RecentScansManager()

    private(set) var scans: [RecentScan] = []

    /// Running total of all scanned card prices
    var totalPrice: Double {
        scans.reduce(0) { $0 + $1.price }
    }

    /// Formatted total price
    var formattedTotal: String {
        totalPrice.formatted(.currency(code: "USD"))
    }

    /// Number of scanned cards
    var count: Int {
        scans.count
    }

    /// Whether there are any recent scans
    var hasScans: Bool {
        !scans.isEmpty
    }

    private init() {}

    /// Add a new scan to the session
    func addScan(_ scan: RecentScan) {
        scans.insert(scan, at: 0)
    }

    /// Add a scan from card match data
    func addScan(
        cardName: String,
        setName: String,
        price: Double,
        thumbnailURL: URL? = nil
    ) {
        let scan = RecentScan(
            cardName: cardName,
            setName: setName,
            price: price,
            thumbnailURL: thumbnailURL
        )
        addScan(scan)
    }

    /// Remove a specific scan
    func removeScan(at index: Int) {
        guard scans.indices.contains(index) else { return }
        scans.remove(at: index)
    }

    /// Remove a scan by ID
    func removeScan(id: UUID) {
        scans.removeAll { $0.id == id }
    }

    /// Clear all scans for new session
    func clearAll() {
        scans.removeAll()
    }
}
