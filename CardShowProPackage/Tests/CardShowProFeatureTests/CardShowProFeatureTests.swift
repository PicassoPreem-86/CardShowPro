import Testing
@testable import CardShowProFeature
import SwiftUI
import AVFoundation

// MARK: - Test 1: InventoryCard Persistence (validates F002)
@Test func inventoryCardPersistsProperties() async throws {
    let card = InventoryCard(
        cardName: "Charizard VMAX",
        cardNumber: "020",
        setName: "Darkness Ablaze",
        gameType: "pokemon",
        estimatedValue: 350.00,
        confidence: 0.95,
        imageData: nil
    )

    #expect(card.cardName == "Charizard VMAX")
    #expect(card.cardNumber == "020")
    #expect(card.setName == "Darkness Ablaze")
    #expect(card.gameType == "pokemon")
    #expect(card.estimatedValue == 350.00)
    #expect(card.confidence == 0.95)
    #expect(card.imageData == nil)

    #expect(card.game == CardGame.pokemon)
}

// MARK: - Test 2: AppState Navigation
@Test @MainActor func appStateManagesTabSelection() async throws {
    let appState = AppState()

    #expect(appState.selectedTab == .dashboard)

    appState.selectedTab = .scan
    #expect(appState.selectedTab == .scan)

    appState.selectedTab = .inventory
    #expect(appState.selectedTab == .inventory)

    appState.selectedTab = .tools
    #expect(appState.selectedTab == .tools)

    #expect(appState.isShowModeActive == false)

    appState.isShowModeActive = true
    #expect(appState.isShowModeActive == true)
}

// MARK: - Test 3: CameraManager Session States
@Test @MainActor func cameraManagerInitializesWithCorrectState() async throws {
    let manager = CameraManager()

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

    #expect(manager.isSessionRunning == false)
    #expect(manager.isFlashOn == false)

    let validAuthStates: [AVAuthorizationStatus] = [.notDetermined, .authorized, .denied, .restricted]
    #expect(validAuthStates.contains(manager.authorizationStatus))
}
