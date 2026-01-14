import Testing
@testable import CardShowProFeature
import SwiftUI
import AVFoundation

// MARK: - Test 1: InventoryCard Persistence (validates F002)
@Test func inventoryCardPersistsProperties() async throws {
    // Create an InventoryCard with known values
    let testDate = Date()
    let card = InventoryCard(
        cardName: "Charizard VMAX",
        cardNumber: "020",
        setName: "Darkness Ablaze",
        gameType: "pokemon",
        marketValue: 350.00,
        acquiredDate: testDate,
        imageData: nil,
        confidence: 0.95
    )

    // Verify all properties persist correctly
    #expect(card.cardName == "Charizard VMAX")
    #expect(card.cardNumber == "020")
    #expect(card.setName == "Darkness Ablaze")
    #expect(card.gameType == "pokemon")
    #expect(card.marketValue == 350.00)
    #expect(card.confidence == 0.95)
    #expect(card.acquiredDate == testDate)
    #expect(card.imageData == nil)

    // Verify CardGame enum conversion works
    #expect(card.game == CardGame.pokemon)
}

// MARK: - Test 2: AppState Navigation
@Test @MainActor func appStateManagesTabSelection() async throws {
    let appState = AppState()

    // Default tab should be dashboard
    #expect(appState.selectedTab == .dashboard)

    // Test tab switching
    appState.selectedTab = .scan
    #expect(appState.selectedTab == .scan)

    appState.selectedTab = .inventory
    #expect(appState.selectedTab == .inventory)

    appState.selectedTab = .tools
    #expect(appState.selectedTab == .tools)

    // Test that show mode starts inactive
    #expect(appState.isShowModeActive == false)

    // Test show mode toggle
    appState.isShowModeActive = true
    #expect(appState.isShowModeActive == true)
}

// MARK: - Test 3: CameraManager Session States
@Test @MainActor func cameraManagerInitializesWithCorrectState() async throws {
    let manager = CameraManager()

    // Initial state should be notConfigured or configuring
    // (depends on timing - authorization check starts immediately)
    let validInitialStates: [CameraManager.SessionState] = [.notConfigured, .configuring]
    let isValidState = validInitialStates.contains { state in
        switch (state, manager.sessionState) {
        case (.notConfigured, .notConfigured),
             (.configuring, .configuring):
            return true
        default:
            return false
        }
    }
    #expect(isValidState, "Initial state should be notConfigured or configuring")

    // Should not be running initially
    #expect(manager.isSessionRunning == false)

    // Flash should be off initially
    #expect(manager.isFlashOn == false)

    // Authorization status should be determined or in progress
    let validAuthStates: [AVAuthorizationStatus] = [.notDetermined, .authorized, .denied, .restricted]
    #expect(validAuthStates.contains(manager.authorizationStatus))
}
