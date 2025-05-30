import Foundation
import UIKit
import SwiftUI

/// A thread-safe service for providing haptic feedback throughout the app
@MainActor
final class HapticService {
    // MARK: - Singleton
    
    /// Shared instance for app-wide access
    static let shared = HapticService()
    
    // MARK: - Private Properties
    
    /// Feedback generator for selection changes
    /// - Note: Selection generators can be long-lived (Apple recommendation)
    private let selectionGenerator = UISelectionFeedbackGenerator()
    
    /// Feedback generator for notifications
    /// - Note: Notification generators can be long-lived (Apple recommendation)
    private let notificationGenerator = UINotificationFeedbackGenerator()
    
    // MARK: - Initialization
    
    private init() {
        // Prepare long-lived generators for lower latency on first use
        prepareGenerators()
    }
    
    // MARK: - Public Methods
    
    /// Triggers a selection haptic feedback
    /// - Note: Ideal for UI interactions like tab changes, item selection
    func selection() {
        selectionGenerator.prepare()
        selectionGenerator.selectionChanged()
    }
    
    /// Triggers an impact haptic feedback with specified intensity
    /// - Parameter style: The impact style to use
    /// - Note: Following Apple's recommendation, we create a new generator for each impact
    ///         as UIImpactFeedbackGenerator instances should be short-lived
    func impact(style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        // Create a new generator each time (Apple recommendation for impact generators)
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred()
    }
    
    /// Triggers a notification haptic feedback
    /// - Parameter type: The notification type (success, warning, error)
    func notification(type: UINotificationFeedbackGenerator.FeedbackType) {
        notificationGenerator.prepare()
        notificationGenerator.notificationOccurred(type)
    }
    
    /// Triggers a success notification haptic feedback
    func success() {
        notification(type: .success)
    }
    
    /// Triggers an error notification haptic feedback
    func error() {
        notification(type: .error)
    }
    
    /// Triggers a warning notification haptic feedback
    func warning() {
        notification(type: .warning)
    }
    
    // MARK: - Private Methods
    
    /// Prepares long-lived generators for lower latency on first use
    private func prepareGenerators() {
        selectionGenerator.prepare()
        notificationGenerator.prepare()
        // Impact generators are created on demand
    }
}

// MARK: - SwiftUI Extensions

/// SwiftUI extension for triggering haptics from view modifiers
extension View {
    /// Adds haptic feedback when a button is pressed
    /// - Parameter style: The impact style to use
    /// - Returns: A view with haptic feedback added
    func hapticFeedback(style: UIImpactFeedbackGenerator.FeedbackStyle = .light) -> some View {
        self.simultaneousGesture(TapGesture().onEnded { _ in
            HapticService.shared.impact(style: style)
        })
    }
    
    /// Adds selection haptic feedback
    /// - Returns: A view with selection haptic feedback added
    func selectionHaptic() -> some View {
        self.simultaneousGesture(TapGesture().onEnded { _ in
            HapticService.shared.selection()
        })
    }
    
    /// Adds success haptic feedback
    /// - Returns: A view with success haptic feedback added
    func successHaptic() -> some View {
        self.simultaneousGesture(TapGesture().onEnded { _ in
            HapticService.shared.success()
        })
    }
    
    /// Adds error haptic feedback
    /// - Returns: A view with error haptic feedback added
    func errorHaptic() -> some View {
        self.simultaneousGesture(TapGesture().onEnded { _ in
            HapticService.shared.error()
        })
    }
}
