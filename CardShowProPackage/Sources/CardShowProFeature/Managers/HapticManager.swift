import SwiftUI

#if canImport(UIKit)
import UIKit
#endif

/// Centralized manager for all haptic feedback in the app
///
/// Provides consistent haptic feedback across all features with proper
/// generator preparation for optimal response time.
///
/// ## Haptic Types
/// - **Selection**: Tab switches, mode changes
/// - **Light**: Subtle feedback (tutorial pulses, camera ready)
/// - **Medium**: Standard actions (capture button)
/// - **Heavy**: Impactful moments (rarely used)
/// - **Success**: Positive confirmation (card saved, trade fair)
/// - **Warning**: Caution states (low light, review trade)
/// - **Error**: Failed operations (card not found, camera error)
///
/// ## Usage
/// ```swift
/// // Singleton access
/// HapticManager.shared.selection()
/// HapticManager.shared.success()
///
/// // Prepare for upcoming haptic (optional, for best timing)
/// HapticManager.shared.prepare()
/// ```
#if canImport(UIKit)
@MainActor
final class HapticManager {
    // MARK: - Singleton
    static let shared = HapticManager()

    // MARK: - Generators (lazy to avoid blocking during initialization)
    private lazy var selectionGenerator = UISelectionFeedbackGenerator()
    private lazy var impactLightGenerator = UIImpactFeedbackGenerator(style: .light)
    private lazy var impactMediumGenerator = UIImpactFeedbackGenerator(style: .medium)
    private lazy var impactHeavyGenerator = UIImpactFeedbackGenerator(style: .heavy)
    private lazy var notificationGenerator = UINotificationFeedbackGenerator()

    // MARK: - Initialization
    private init() {
        // Generators are created lazily when first accessed to avoid blocking
    }

    // MARK: - Selection Feedback
    /// Haptic for UI selection changes (tab switches, segmented controls)
    func selection() {
        selectionGenerator.selectionChanged()
    }

    // MARK: - Impact Feedback
    /// Light impact for subtle feedback (tutorial pulses, gentle notifications)
    func light() {
        impactLightGenerator.impactOccurred()
    }

    /// Medium impact for standard actions (button taps, captures)
    func medium() {
        impactMediumGenerator.impactOccurred()
    }

    /// Heavy impact for significant moments (rarely used, reserved for dramatic effect)
    func heavy() {
        impactHeavyGenerator.impactOccurred()
    }

    // MARK: - Notification Feedback
    /// Success notification for positive confirmations
    func success() {
        notificationGenerator.notificationOccurred(.success)
    }

    /// Warning notification for caution states
    func warning() {
        notificationGenerator.notificationOccurred(.warning)
    }

    /// Error notification for failed operations
    func error() {
        notificationGenerator.notificationOccurred(.error)
    }

    // MARK: - Preparation
    /// Prepares all generators for immediate response
    ///
    /// Call this before a sequence of haptic events to eliminate latency.
    /// Typically called when entering a feature that will use haptics.
    func prepare() {
        selectionGenerator.prepare()
        impactLightGenerator.prepare()
        impactMediumGenerator.prepare()
        impactHeavyGenerator.prepare()
        notificationGenerator.prepare()
    }

    /// Prepares specific generator for a known upcoming haptic
    func prepareSelection() {
        selectionGenerator.prepare()
    }

    func prepareLight() {
        impactLightGenerator.prepare()
    }

    func prepareMedium() {
        impactMediumGenerator.prepare()
    }

    func prepareHeavy() {
        impactHeavyGenerator.prepare()
    }

    func prepareNotification() {
        notificationGenerator.prepare()
    }
}
#endif
