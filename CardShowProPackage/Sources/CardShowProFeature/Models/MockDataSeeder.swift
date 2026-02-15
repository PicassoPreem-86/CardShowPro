import Foundation
import SwiftData

/// Seeds the database with sample inventory and transaction data for demo/testing.
/// Only runs once per install (tracked via UserDefaults).
@MainActor
public enum MockDataSeeder {

    private static let seededKey = "com.cardshowpro.mockDataSeeded"

    public static var hasSeeded: Bool {
        UserDefaults.standard.bool(forKey: seededKey)
    }

    /// Call from app launch. Inserts sample data if not already seeded.
    public static func seedIfNeeded(context: ModelContext) {
        guard !hasSeeded else { return }

        let calendar = Calendar.current
        let now = Date()

        // MARK: - In Stock Cards (Raw Singles)

        let charizardVSTAR = InventoryCard(
            cardName: "Charizard VSTAR",
            cardNumber: "014/172",
            setName: "Stellar Crown",
            estimatedValue: 485.00,
            confidence: 0.98,
            timestamp: calendar.date(byAdding: .day, value: -45, to: now)!,
            purchaseCost: 320.00,
            category: "Raw Singles",
            condition: "Near Mint",
            notes: "Pulled from booster box. Centering looks PSA 9+",
            acquisitionSource: AcquisitionSource.personalCollection.rawValue
        )

        let umbreonVMAX = InventoryCard(
            cardName: "Umbreon VMAX",
            cardNumber: "215/203",
            setName: "Evolving Skies",
            estimatedValue: 342.00,
            confidence: 0.96,
            timestamp: calendar.date(byAdding: .day, value: -30, to: now)!,
            purchaseCost: 225.00,
            category: "Raw Singles",
            condition: "Near Mint",
            notes: "Alt art. Clean corners.",
            acquisitionSource: AcquisitionSource.onlinePurchase.rawValue
        )

        let mewVMAX = InventoryCard(
            cardName: "Mew VMAX",
            cardNumber: "114/159",
            setName: "Crown Zenith",
            estimatedValue: 298.50,
            confidence: 0.94,
            timestamp: calendar.date(byAdding: .day, value: -60, to: now)!,
            purchaseCost: 180.00,
            category: "Raw Singles",
            condition: "Lightly Played",
            notes: "Small whitening on back edge. Priced accordingly.",
            acquisitionSource: AcquisitionSource.localPickup.rawValue
        )

        let pikachuIR = InventoryCard(
            cardName: "Pikachu Illustration Rare",
            cardNumber: "172/165",
            setName: "151",
            estimatedValue: 195.00,
            confidence: 0.97,
            timestamp: calendar.date(byAdding: .day, value: -15, to: now)!,
            purchaseCost: 140.00,
            category: "Raw Singles",
            condition: "Near Mint",
            acquisitionSource: AcquisitionSource.eventShow.rawValue
        )

        let lugiaVSTAR = InventoryCard(
            cardName: "Lugia VSTAR",
            cardNumber: "186/195",
            setName: "Silver Tempest",
            estimatedValue: 65.00,
            confidence: 0.92,
            timestamp: calendar.date(byAdding: .day, value: -90, to: now)!,
            purchaseCost: 42.00,
            category: "Raw Singles",
            condition: "Near Mint",
            notes: "Rainbow rare. Solid condition.",
            acquisitionSource: AcquisitionSource.trade.rawValue
        )

        let rayquazaVMAX = InventoryCard(
            cardName: "Rayquaza VMAX",
            cardNumber: "218/203",
            setName: "Evolving Skies",
            estimatedValue: 178.00,
            confidence: 0.95,
            timestamp: calendar.date(byAdding: .day, value: -20, to: now)!,
            purchaseCost: 120.00,
            category: "Raw Singles",
            condition: "Near Mint",
            notes: "Alt art. Perfect for grading submission.",
            acquisitionSource: AcquisitionSource.onlinePurchase.rawValue
        )

        let gengarVMAX = InventoryCard(
            cardName: "Gengar VMAX",
            cardNumber: "271/264",
            setName: "Fusion Strike",
            estimatedValue: 85.00,
            confidence: 0.93,
            timestamp: calendar.date(byAdding: .day, value: -75, to: now)!,
            purchaseCost: 55.00,
            category: "Raw Singles",
            condition: "Near Mint",
            acquisitionSource: AcquisitionSource.localPickup.rawValue
        )

        let eeveePromo = InventoryCard(
            cardName: "Eevee",
            cardNumber: "SWSH236",
            setName: "SWSH Promos",
            estimatedValue: 12.00,
            confidence: 0.88,
            timestamp: calendar.date(byAdding: .day, value: -120, to: now)!,
            purchaseCost: 5.00,
            category: "Raw Singles",
            condition: "Moderately Played",
            notes: "Dead stock. Been sitting forever.",
            acquisitionSource: AcquisitionSource.localPickup.rawValue
        )

        // MARK: - Graded Cards

        let charizardPSA10 = InventoryCard(
            cardName: "Charizard EX",
            cardNumber: "006/165",
            setName: "151",
            estimatedValue: 750.00,
            confidence: 1.0,
            timestamp: calendar.date(byAdding: .day, value: -10, to: now)!,
            purchaseCost: 280.00,
            category: "Graded",
            condition: "Mint",
            notes: "Got back from PSA. Perfect 10!",
            acquisitionSource: AcquisitionSource.personalCollection.rawValue
        )
        charizardPSA10.gradingService = GradingService.psa.rawValue
        charizardPSA10.grade = "10"
        charizardPSA10.certNumber = "92847561"
        charizardPSA10.gradingCost = 50.00

        let mewtwoGX_BGS = InventoryCard(
            cardName: "Mewtwo GX",
            cardNumber: "31/68",
            setName: "Hidden Fates",
            estimatedValue: 420.00,
            confidence: 1.0,
            timestamp: calendar.date(byAdding: .day, value: -25, to: now)!,
            purchaseCost: 200.00,
            category: "Graded",
            condition: "Mint",
            notes: "BGS 9.5 Gem Mint. Sub grades: C9.5, E10, S9.5, Cnr9",
            acquisitionSource: AcquisitionSource.onlinePurchase.rawValue
        )
        mewtwoGX_BGS.gradingService = GradingService.bgs.rawValue
        mewtwoGX_BGS.grade = "9.5"
        mewtwoGX_BGS.certNumber = "48271639"
        mewtwoGX_BGS.gradingCost = 65.00

        let blastoiseCGC = InventoryCard(
            cardName: "Blastoise",
            cardNumber: "009/165",
            setName: "151",
            estimatedValue: 185.00,
            confidence: 1.0,
            timestamp: calendar.date(byAdding: .day, value: -40, to: now)!,
            purchaseCost: 90.00,
            category: "Graded",
            condition: "Near Mint",
            acquisitionSource: AcquisitionSource.eventShow.rawValue
        )
        blastoiseCGC.gradingService = GradingService.cgc.rawValue
        blastoiseCGC.grade = "9"
        blastoiseCGC.certNumber = "3928471650"
        blastoiseCGC.gradingCost = 30.00

        // MARK: - Sealed Products

        let boosterBox = InventoryCard(
            cardName: "Stellar Crown Booster Box",
            cardNumber: "BOX-001",
            setName: "Stellar Crown",
            estimatedValue: 135.00,
            confidence: 1.0,
            timestamp: calendar.date(byAdding: .day, value: -5, to: now)!,
            purchaseCost: 95.00,
            category: "Sealed",
            condition: "Mint",
            notes: "Factory sealed. Holding for appreciation.",
            quantity: 3,
            acquisitionSource: AcquisitionSource.onlinePurchase.rawValue
        )

        let etb = InventoryCard(
            cardName: "Paldean Fates ETB",
            cardNumber: "ETB-001",
            setName: "Paldean Fates",
            estimatedValue: 65.00,
            confidence: 1.0,
            timestamp: calendar.date(byAdding: .day, value: -35, to: now)!,
            purchaseCost: 45.00,
            category: "Sealed",
            condition: "Mint",
            notes: "Pokemon Center exclusive.",
            quantity: 2,
            acquisitionSource: AcquisitionSource.onlinePurchase.rawValue
        )

        // MARK: - Listed Cards

        let dragoniteAlt = InventoryCard(
            cardName: "Dragonite V Alt Art",
            cardNumber: "192/203",
            setName: "Evolving Skies",
            estimatedValue: 125.00,
            confidence: 0.95,
            timestamp: calendar.date(byAdding: .day, value: -50, to: now)!,
            purchaseCost: 75.00,
            category: "Raw Singles",
            condition: "Near Mint",
            status: CardStatus.listed.rawValue,
            acquisitionSource: AcquisitionSource.trade.rawValue
        )
        dragoniteAlt.platform = "eBay"
        dragoniteAlt.listingPrice = 130.00
        dragoniteAlt.listedDate = calendar.date(byAdding: .day, value: -3, to: now)

        let espeonVMAX = InventoryCard(
            cardName: "Espeon VMAX",
            cardNumber: "270/264",
            setName: "Fusion Strike",
            estimatedValue: 95.00,
            confidence: 0.94,
            timestamp: calendar.date(byAdding: .day, value: -55, to: now)!,
            purchaseCost: 60.00,
            category: "Raw Singles",
            condition: "Near Mint",
            status: CardStatus.listed.rawValue,
            acquisitionSource: AcquisitionSource.localPickup.rawValue
        )
        espeonVMAX.platform = "TCGPlayer"
        espeonVMAX.listingPrice = 99.99
        espeonVMAX.listedDate = calendar.date(byAdding: .day, value: -7, to: now)

        // MARK: - Sold Cards

        let sylveonVMAX = InventoryCard(
            cardName: "Sylveon VMAX",
            cardNumber: "212/203",
            setName: "Evolving Skies",
            estimatedValue: 155.00,
            confidence: 0.96,
            timestamp: calendar.date(byAdding: .day, value: -65, to: now)!,
            purchaseCost: 90.00,
            category: "Raw Singles",
            condition: "Near Mint",
            status: CardStatus.sold.rawValue,
            acquisitionSource: AcquisitionSource.eventShow.rawValue
        )
        sylveonVMAX.soldPrice = 160.00
        sylveonVMAX.soldDate = calendar.date(byAdding: .day, value: -2, to: now)
        sylveonVMAX.platform = "eBay"

        let glaceonVSTAR = InventoryCard(
            cardName: "Glaceon VSTAR",
            cardNumber: "196/195",
            setName: "Silver Tempest",
            estimatedValue: 45.00,
            confidence: 0.91,
            timestamp: calendar.date(byAdding: .day, value: -80, to: now)!,
            purchaseCost: 22.00,
            category: "Raw Singles",
            condition: "Lightly Played",
            status: CardStatus.shipped.rawValue,
            acquisitionSource: AcquisitionSource.onlinePurchase.rawValue
        )
        glaceonVSTAR.soldPrice = 48.00
        glaceonVSTAR.soldDate = calendar.date(byAdding: .day, value: -8, to: now)
        glaceonVSTAR.platform = "TCGPlayer"

        let arceusVSTAR = InventoryCard(
            cardName: "Arceus VSTAR",
            cardNumber: "176/172",
            setName: "Brilliant Stars",
            estimatedValue: 72.00,
            confidence: 0.93,
            timestamp: calendar.date(byAdding: .day, value: -100, to: now)!,
            purchaseCost: 35.00,
            category: "Raw Singles",
            condition: "Near Mint",
            status: CardStatus.sold.rawValue,
            acquisitionSource: AcquisitionSource.localPickup.rawValue
        )
        arceusVSTAR.soldPrice = 75.00
        arceusVSTAR.soldDate = calendar.date(byAdding: .day, value: -12, to: now)
        arceusVSTAR.platform = "Facebook Marketplace"

        // MARK: - Insert All Cards

        let allCards = [
            charizardVSTAR, umbreonVMAX, mewVMAX, pikachuIR, lugiaVSTAR,
            rayquazaVMAX, gengarVMAX, eeveePromo,
            charizardPSA10, mewtwoGX_BGS, blastoiseCGC,
            boosterBox, etb,
            dragoniteAlt, espeonVMAX,
            sylveonVMAX, glaceonVSTAR, arceusVSTAR
        ]

        for card in allCards {
            context.insert(card)
        }

        // MARK: - Transactions

        // Sale transactions (matching sold cards)
        let saleSylveon = Transaction(
            type: .sale,
            date: calendar.date(byAdding: .day, value: -2, to: now)!,
            amount: 160.00,
            platform: "eBay",
            platformFees: 20.96,
            shippingCost: 4.50,
            notes: "Quick sale, buyer paid asking price",
            cardId: sylveonVMAX.id,
            cardName: "Sylveon VMAX",
            cardSetName: "Evolving Skies",
            contactName: "Jake M.",
            costBasis: 90.00
        )

        let saleGlaceon = Transaction(
            type: .sale,
            date: calendar.date(byAdding: .day, value: -8, to: now)!,
            amount: 48.00,
            platform: "TCGPlayer",
            platformFees: 5.42,
            shippingCost: 1.25,
            notes: "Standard TCGPlayer sale",
            cardId: glaceonVSTAR.id,
            cardName: "Glaceon VSTAR",
            cardSetName: "Silver Tempest",
            costBasis: 22.00
        )

        let saleArceus = Transaction(
            type: .sale,
            date: calendar.date(byAdding: .day, value: -12, to: now)!,
            amount: 75.00,
            platform: "Facebook Marketplace",
            platformFees: 0,
            shippingCost: 0,
            notes: "Local meetup, cash deal",
            cardId: arceusVSTAR.id,
            cardName: "Arceus VSTAR",
            cardSetName: "Brilliant Stars",
            contactName: "Mike R.",
            costBasis: 35.00
        )

        // Additional past sales (cards no longer in inventory)
        let saleOldCharizard = Transaction(
            type: .sale,
            date: calendar.date(byAdding: .day, value: -22, to: now)!,
            amount: 220.00,
            platform: "eBay",
            platformFees: 28.82,
            shippingCost: 5.99,
            notes: "Great margin on this one",
            cardName: "Charizard V Alt Art",
            cardSetName: "Brilliant Stars",
            contactName: "Sarah K.",
            costBasis: 130.00
        )

        let saleOldMewtwo = Transaction(
            type: .sale,
            date: calendar.date(byAdding: .day, value: -35, to: now)!,
            amount: 85.00,
            platform: "TCGPlayer",
            platformFees: 9.60,
            shippingCost: 1.25,
            notes: "",
            cardName: "Mewtwo V Alt Art",
            cardSetName: "Pokemon GO",
            costBasis: 50.00
        )

        // Purchase transactions
        let purchaseUmbreon = Transaction(
            type: .purchase,
            date: calendar.date(byAdding: .day, value: -30, to: now)!,
            amount: 225.00,
            platform: "eBay",
            notes: "Won auction under market price",
            cardId: umbreonVMAX.id,
            cardName: "Umbreon VMAX",
            cardSetName: "Evolving Skies",
            costBasis: 225.00
        )

        let purchaseBoxes = Transaction(
            type: .purchase,
            date: calendar.date(byAdding: .day, value: -5, to: now)!,
            amount: 285.00,
            platform: "Distributor",
            notes: "3x Stellar Crown BBs at $95 each",
            cardId: boosterBox.id,
            cardName: "Stellar Crown Booster Box",
            cardSetName: "Stellar Crown",
            contactName: "Pacific Trading Co.",
            costBasis: 285.00
        )

        let purchaseRayquaza = Transaction(
            type: .purchase,
            date: calendar.date(byAdding: .day, value: -20, to: now)!,
            amount: 120.00,
            platform: "TCGPlayer",
            notes: "Good price, NM condition confirmed",
            cardId: rayquazaVMAX.id,
            cardName: "Rayquaza VMAX",
            cardSetName: "Evolving Skies",
            costBasis: 120.00
        )

        // Trade transaction
        let tradeGengar = Transaction(
            type: .trade,
            date: calendar.date(byAdding: .day, value: -75, to: now)!,
            amount: 55.00,
            notes: "Traded 3 bulk holos + $20 cash",
            cardId: gengarVMAX.id,
            cardName: "Gengar VMAX",
            cardSetName: "Fusion Strike",
            contactName: "Dave at local show",
            eventName: "Sunday Card Show",
            costBasis: 55.00
        )

        // Event sale
        let saleEventPika = Transaction(
            type: .sale,
            date: calendar.date(byAdding: .day, value: -18, to: now)!,
            amount: 45.00,
            platformFees: 0,
            shippingCost: 0,
            notes: "Cash sale at table",
            cardName: "Pikachu V Full Art",
            cardSetName: "Lost Origin",
            contactName: "Walk-in customer",
            eventName: "Metro Card Show Feb 2025",
            costBasis: 18.00
        )

        let allTransactions = [
            saleSylveon, saleGlaceon, saleArceus,
            saleOldCharizard, saleOldMewtwo,
            purchaseUmbreon, purchaseBoxes, purchaseRayquaza,
            tradeGengar, saleEventPika
        ]

        for transaction in allTransactions {
            context.insert(transaction)
        }

        // Save and mark as seeded
        do {
            try context.save()
            UserDefaults.standard.set(true, forKey: seededKey)
        } catch {
            #if DEBUG
            print("MockDataSeeder failed to save: \(error)")
            #endif
        }
    }

    /// Reset the seed flag so data can be re-seeded (for testing)
    public static func reset() {
        UserDefaults.standard.removeObject(forKey: seededKey)
    }
}
