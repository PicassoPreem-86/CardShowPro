import Foundation
import SwiftUI

/// State machine for auto-capture with proper timing and cooldown
@MainActor
@Observable
final class AutoCaptureStateMachine {
    // MARK: - State
    enum State: Equatable {
        case idle                   // Not detecting anything
        case detecting              // Card found but unstable
        case stable(since: Date)    // Card stable, counting time
        case capturing              // Photo capture in progress
        case cooldown(until: Date)  // Post-capture cooldown

        var displayMessage: String {
            switch self {
            case .idle:
                return "Position card in frame"
            case .detecting:
                return "Hold steady..."
            case .stable:
                return "Perfect! Auto-scanning..."
            case .capturing:
                return "Captured!"
            case .cooldown:
                return "Ready for next card..."
            }
        }

        var displayColor: Color {
            switch self {
            case .idle:
                return .red
            case .detecting:
                return .yellow
            case .stable:
                return .green
            case .capturing:
                return .blue
            case .cooldown:
                return .gray
            }
        }
    }

    // MARK: - Configuration
    private let stabilityDuration: TimeInterval = 1.0  // 1 second stability required
    private let cooldownDuration: TimeInterval = 3.0   // 3 second cooldown after capture

    // MARK: - Published State
    var state: State = .idle
    var isEnabled = true  // Can be toggled by user settings

    // MARK: - State Transitions
    func handleDetectionResult(isDetected: Bool, isHighConfidence: Bool, isProcessing: Bool, showingSheet: Bool) {
        // Never transition during processing or when sheet is visible
        guard !isProcessing, !showingSheet, isEnabled else {
            if state != .capturing && state != .cooldown(until: Date()) {
                state = .idle
            }
            return
        }

        // Check cooldown expiry
        if case .cooldown(let until) = state {
            if Date() >= until {
                state = .idle
            } else {
                return  // Still in cooldown
            }
        }

        // State machine logic
        switch state {
        case .idle:
            if isDetected && isHighConfidence {
                state = .stable(since: Date())
            } else if isDetected {
                state = .detecting
            }

        case .detecting:
            if isHighConfidence {
                state = .stable(since: Date())
            } else if !isDetected {
                state = .idle
            }

        case .stable(let since):
            if !isHighConfidence {
                // Lost stability, go back to detecting or idle
                if isDetected {
                    state = .detecting
                } else {
                    state = .idle
                }
            } else {
                // Check if stability duration met
                if Date().timeIntervalSince(since) >= stabilityDuration {
                    // Ready to capture - external caller should call beginCapture()
                }
            }

        case .capturing:
            // Wait for external call to finishCapture()
            break

        case .cooldown:
            // Handled above
            break
        }
    }

    // MARK: - Capture Control
    func canAttemptCapture() -> Bool {
        if case .stable(let since) = state {
            return Date().timeIntervalSince(since) >= stabilityDuration
        }
        return false
    }

    func beginCapture() {
        guard canAttemptCapture() else { return }
        state = .capturing
    }

    func finishCapture() {
        let cooldownUntil = Date().addingTimeInterval(cooldownDuration)
        state = .cooldown(until: cooldownUntil)
    }

    func reset() {
        state = .idle
    }

    // MARK: - Query Methods
    var isInCooldown: Bool {
        if case .cooldown(let until) = state {
            return Date() < until
        }
        return false
    }

    var canTransition: Bool {
        switch state {
        case .capturing:
            return false
        case .cooldown(let until):
            return Date() >= until
        case .idle, .detecting, .stable:
            return true
        }
    }
}
