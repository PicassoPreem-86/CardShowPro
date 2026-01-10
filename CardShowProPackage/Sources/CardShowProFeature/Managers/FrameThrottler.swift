import Foundation

/// Actor that throttles Vision framework processing to 15 FPS
///
/// Reduces processing from 60 FPS to 15 FPS to improve performance:
/// - Reduces CPU usage by 75%
/// - Reduces thermal load
/// - Still responsive enough for smooth card detection
/// - Prevents Vision framework from overwhelming the device
///
/// ## Usage
/// ```swift
/// private let frameThrottler = FrameThrottler()
///
/// func captureOutput(...) {
///     Task {
///         guard await frameThrottler.shouldProcess() else { return }
///         // Continue with Vision processing
///     }
/// }
/// ```
actor FrameThrottler {
    // MARK: - Properties
    private var lastProcessedTime: Date = .distantPast
    private let minimumInterval: TimeInterval

    // MARK: - Initialization
    init(fps: Double = 15.0) {
        self.minimumInterval = 1.0 / fps
    }

    // MARK: - Throttling
    /// Returns true if enough time has passed since last processing
    func shouldProcess() -> Bool {
        let now = Date()
        guard now.timeIntervalSince(lastProcessedTime) >= minimumInterval else {
            return false
        }
        lastProcessedTime = now
        return true
    }

    /// Resets the throttle timer (useful when starting/stopping camera)
    func reset() {
        lastProcessedTime = .distantPast
    }
}
