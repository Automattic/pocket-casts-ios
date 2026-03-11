import SwiftUI

/// Allows for easy proportional scaling of the given value based on the size of the view its contained in (usually the full height)
/// This is useful when you need to position and/or size a view consistently across device sizes
///
///
/// Basic usage is: @ProportionalValue(with: .width) var scaledSize = 0.5
/// You can also specify a custom arithmetic operator (+, -, /, *) *to use in the calculations, the default is *
///
/// See the ExampleView in the PreviewProvider below for usage
@propertyWrapper public struct ProportionalValue<Value>: DynamicProperty where Value: BinaryFloatingPoint {
    // The environment variable we base the calculations off of
    @Environment(\.proportionalValueFrame) var viewFrame

    // A helper type to pass in a math operator: +, -, *, /, etc
    public typealias ArithmeticOperator = (Double, Double) -> Double

    /// Defines the frame values that we can scale the value with
    public enum FrameScaleValue {
        case width, height
        case minX, midX, maxX
        case minY, midY, maxY
    }

    private let scaleOption: FrameScaleValue
    private let mathOperator: ArithmeticOperator
    private var baseValue: Value

    // The public way to get and set the internal value
    public var wrappedValue: Value {
        get { scaledValue }
        set { baseValue = newValue }
    }

    public init(wrappedValue: Value = 1, with option: FrameScaleValue, using mathOperator: @escaping ArithmeticOperator) {
        self.baseValue = wrappedValue
        self.scaleOption = option
        self.mathOperator = mathOperator
    }

    public init(wrappedValue: Value = 1, with option: FrameScaleValue) {
        self.init(wrappedValue: wrappedValue, with: option, using: *)
    }

    /// Calculates the new value based on the scale and math operator we're using
    private var scaledValue: Value {
        let scalingValue: CGFloat
        switch scaleOption {
        case .width:
            scalingValue = viewFrame.width
        case .height:
            scalingValue = viewFrame.height
        case .minX:
            scalingValue = viewFrame.minX
        case .midX:
            scalingValue = viewFrame.midX
        case .maxX:
            scalingValue = viewFrame.maxX
        case .minY:
            scalingValue = viewFrame.minY
        case .midY:
            scalingValue = viewFrame.midY
        case .maxY:
            scalingValue = viewFrame.maxY
        }

        return Value(mathOperator(Double(baseValue), scalingValue))
    }
}

// MARK: - Helper view extension to set the correct environment variables on the view
extension View {
    func enableProportionalValueScaling() -> some View {
        self.modifier(ProportionalValueViewModifier())
    }
}

/// Wrap the view in the calculator to make sure the environment variables are set
private struct ProportionalValueViewModifier: ViewModifier {
    func body(content: Content) -> some View {
        ProportionalValueFrameCalculator {
            content
        }
    }
}

/// Calculates the size of the view its wrapped in
public struct ProportionalValueFrameCalculator<Content: View>: View {
    private var content: () -> Content
    public init(@ViewBuilder _ content: @escaping () -> Content) {
        self.content = content
    }

    public var body: some View {
        GeometryReader { geometry in
            content()
                .environment(\.proportionalValueFrame, geometry.frame(in: .global))
        }
    }
}

/// Defines the custom environment variables to use
private extension EnvironmentValues {
    var proportionalValueFrame: CGRect {
        get { self[ProportionalValueKey.self] }
        set { self[ProportionalValueKey.self] = newValue }
    }

    private struct ProportionalValueKey: EnvironmentKey {
        static let defaultValue: CGRect = .zero
    }
}

// MARK: - Example Preview
struct ScalingValue_Example_Preview: PreviewProvider {
    static var previews: some View {
        ExampleView()
            .previewOnAllDevices()
    }

    struct ExampleView: View {
        var body: some View {
            VStack {
                ExampleScalingView()
            }
            // Make sure the proper environment variables are set on the property wrapper
            .enableProportionalValueScaling()
        }
    }

    private struct ExampleScalingView: View {
        // Returns a value that is a percentage of the height: (view.frame.height * 0.2)
        @ProportionalValue(with: .height) var size = 0.2

        // Returns a value that is half the width: (view.frame.width / 2)
        @ProportionalValue(with: .width, using: /) var x = 2

        // Returns a value that is: (view.frame.midY + 75)
        @ProportionalValue(with: .midY, using: +) var y = 75

        var body: some View {
            ZStack {
                VStack {
                    Text(String(format: "The circle %0.2f and is located at:", size))
                    Text(String(format: "X: %0.2f, Y: %0.2f", x, y))
                    Spacer()
                }

                Circle()
                    .frame(width: size, height: size)
                    .position(x: x, y: y)
            }
        }
    }
}
