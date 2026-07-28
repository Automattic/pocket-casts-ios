import SwiftUI

extension View {
    /// Drop in replacement for `animation` that automatically removes the animation if the user has
    /// the Reduce Motion accessibility setting enabled
    func accessibilityAnimation<Value: Equatable>(_ animation: Animation?, value: Value) -> some View {
        self.modifier(ReducedAnimationModifier(animation: animation, value: value))
    }

    /// Drop in replacement for `transition` that automatically removes the transition if the user has
    /// the Reduce Motion accessibility setting enabled
    func accessibilityTransition(_ transition: AnyTransition) -> some View {
        self.modifier(ReducedTransitionModifier(transition: transition))
    }
}

// MARK: - Global Functions

/// A drop in replacement for `withAnimation` to automatically support the reduced animation accessibility setting
/// If the user has the setting enabled, the animation will be set to none
///
public func withAccessibilityAnimation<Result>(_ animation: Animation? = .default, _ body: () throws -> Result) rethrows -> Result {
    return try withAnimation(UIAccessibility.isReduceMotionEnabled ? .none : animation, body)
}

// MARK: - Internal View Modifiers

/// If the user has the Reduce Motion setting enabled the transition will be ignored
private struct ReducedTransitionModifier: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let transition: AnyTransition

    func body(content: Content) -> some View {
        if reduceMotion {
            content
        } else {
            content.transition(transition)
        }
    }
}

/// If the user has the Reduce Motion setting enabled the animation will be ignored
private struct ReducedAnimationModifier<Value: Equatable>: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let animation: Animation?
    let value: Value

    func body(content: Content) -> some View {
        if reduceMotion {
            content
        } else {
            content.animation(animation, value: value)
        }
    }
}
