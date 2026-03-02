---
name: update_swiftui_uikit_for_dynamic_type_support
description: >
  Expert guidance for Dynamic Type support for Pocket Casts iOS development with Swift, UIKit, and SwiftUI.
  Use this skill when the user asks about Dynamic Type, content size categories, accessibility text size, font scaling, or making text/UI
  elements respond to the user's preferred text size (e.g., using preferredContentSizeCategory, adjustsFontForContentSizeCategory,
  UIFontMetrics, or related APIs in SwiftUI and UIKit).
---

# Dynamic Type

Dynamic Type is a first-class concern. Every text element, button, and scalable image must support it. The goal is for the entire UI to gracefully adapt when users change their preferred text size.

### Fonts

Use the standard text styles defined by Apple (see [Typography Specifications](https://developer.apple.com/design/human-interface-guidelines/typography#Specifications)). Use the **Large** (default) size as the reference when matching design specs.

If you need a custom size that doesn't match a standard style, pick the scaling style whose default size is closest to your custom size, then use the following custom font APIs:

**UIKit:**
```swift
label.font = .font(ofSize: 15, weight: .medium, scalingWith: .subheadline)
```

**SwiftUI:**
```swift
Text("Hello")
    .font(size: 15.0, style: .subheadline, weight: .medium)
```

These APIs use `UIFontMetrics` internally to scale your custom size proportionally with the user's preferred text size, while capping at a sensible maximum (`accessibilityExtraExtraExtraLarge` by default).

For standard sizes where no customization is needed:

**UIKit:**
```swift
label.font = .font(with: .body, weight: .regular)
```

**SwiftUI:**
```swift
Text("Hello")
    .font(style: .body, weight: .regular)
```

### Labels (UIKit)

For `UILabel` or derived classes, three things make Dynamic Type work:

1. **Allow wrapping**: set `.numberOfLines = 0`
2. **Opt into auto-scaling**: set `.adjustsFontForContentSizeCategory = true`
3. **Flexible layout**: set top and bottom constraints to the container so it can grow. Increase content hugging and compression resistance priorities on the vertical axis to let the label drive its container's height.

```swift
let label = UILabel()
label.font = .font(ofSize: 18, weight: .semibold, scalingWith: .headline)
label.adjustsFontForContentSizeCategory = true
label.numberOfLines = 0
```

### Labels (SwiftUI)

For `Text` (including `Text` with `AttributedString` or custom attributed text views such as `DescriptiveActionAttributedTextView`), use a standard Apple style via the custom `.font` modifier. If the size you need doesn't match any reference size, use the custom variant:

```swift
Text("Description")
    .font(size: 15, style: .subheadline, weight: .regular)
    .fixedSize(horizontal: false, vertical: true)
```

The `.fixedSize(horizontal: false, vertical: true)` modifier is important — it tells SwiftUI to let text expand vertically rather than truncating. Use it on any `Text` that should wrap to multiple lines.

### Buttons (UIKit)

Apply the same approach as labels, but to the button's `.titleLabel`:

```swift
button.titleLabel?.font = .font(ofSize: 18, weight: .semibold, scalingWith: .headline)
button.titleLabel?.adjustsFontForContentSizeCategory = true
button.titleLabel?.numberOfLines = 0
```

If button text can span multiple lines, you may need an explicit height constraint between the `titleLabel` and the button to force the button to resize when its label grows beyond a single line.

### Buttons (SwiftUI)

A `Text` label with a dynamic font inside a `Button` is typically sufficient:

```swift
Button(action: { }) {
    Text("Continue")
        .font(size: 18, style: .body, weight: .semibold)
}
```

Or use the convenience modifier:

```swift
Button("Continue") { }
    .applyButtonFont(size: 18, style: .body, weight: .semibold)
```

### Images (UIKit)

For images that should scale with text size:

1. Set height and width constraints to the base size
2. Override `traitCollectionDidChange(_:)` and check for changes on `preferredContentSizeCategory`
3. Use `UIFontMetrics` with the `.largeTitle` style as the scaling reference

```swift
private let baseImageSize: CGFloat = 24

override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
    super.traitCollectionDidChange(previousTraitCollection)
    guard traitCollection.preferredContentSizeCategory != previousTraitCollection?.preferredContentSizeCategory else { return }
    let metric = UIFontMetrics(forTextStyle: .largeTitle)
    let scaledSize = max(baseImageSize, metric.scaledValue(for: baseImageSize))
    imageWidthConstraint.constant = scaledSize
    imageHeightConstraint.constant = scaledSize
}
```

### Images (SwiftUI)

Use the `@ScaledMetric` property wrapper (or the project's `@ScaledMetricWithMaxSize` for capped scaling) to define a size variable, then apply it in a `.frame` modifier:

```swift
@ScaledMetric(relativeTo: .largeTitle) private var imageSize: CGFloat = 24

// or with a max cap:
@ScaledMetricWithMaxSize(wrappedValue: 24, relativeTo: .largeTitle, maxSize: .xxLarge) private var imageSize: CGFloat

var body: some View {
    Image(systemName: "star.fill")
        .frame(width: imageSize, height: imageSize)
}
```

### WebViews

Use CSS with the Apple dynamic font on the root element so all relative sizes scale automatically:

```html
<style>
  :root { font: -apple-system-body; }
  /* All other sizes should use rem or em relative to root */
  h1 { font-size: 1.5rem; }
  p { font-size: 1rem; }
</style>
```

### Stack Views (UIKit)

Set the `distribution` property to `.fill` so the stack view grows with its content. This is critical for Dynamic Type — a `.fillEqually` or fixed distribution will fight against growing labels.

### Table Views (UIKit)

Enable self-sizing rows:

```swift
tableView.rowHeight = UITableView.automaticDimension
tableView.estimatedRowHeight = 60 // use a reasonable estimate or previous fixed height
```

Cells must have an unbroken chain of constraints from top to bottom of the content view so Auto Layout can compute the height.

When embedding SwiftUI content in cells, two approaches work:

- **`UIHostingConfiguration`**: Resizing is automatic. This is the preferred approach for new cells.
- **`themedUIView` / `insertThemedUIView(in:)` helpers with a hosting controller**: Be mindful of adding proper child/parent view controller relationships.

```swift
// UIHostingConfiguration example
cell.contentConfiguration = UIHostingConfiguration {
    MyCellView(viewModel: viewModel)
        .environmentObject(Theme.sharedTheme)
}
.margins(.horizontal, 16)
.margins(.vertical, 8)
```

### Table Views / Lists (SwiftUI)

Use a standard SwiftUI `List`, or a `VStack` inside a `ScrollView` for custom layouts. SwiftUI handles Dynamic Type sizing automatically as long as you use dynamic fonts.

---

## SwiftUI + UIKit Integration

The project is in gradual migration from UIKit to SwiftUI. New features can be SwiftUI-first, but they need to interop cleanly with the existing UIKit shell.

### Embedding SwiftUI in UIKit

Use `UIHostingController` or `UIHostingConfiguration` (for cells). Always inject the theme:

```swift
let hostingController = UIHostingController(rootView:
    MySwiftUIView()
        .environmentObject(Theme.sharedTheme)
)
addChild(hostingController)
view.addSubview(hostingController.view)
hostingController.didMove(toParent: self)
```

### Embedding UIKit in SwiftUI

Use `UIViewControllerRepresentable` or `UIViewRepresentable` when you need to wrap legacy UIKit components.

---

## Quick Reference — Common Patterns

| What you need | UIKit | SwiftUI |
|---|---|---|
| Dynamic font (standard) | `.font(with: .body, weight: .regular)` | `.font(style: .body, weight: .regular)` |
| Dynamic font (custom size) | `.font(ofSize: 15, weight: .medium, scalingWith: .subheadline)` | `.font(size: 15, style: .subheadline, weight: .medium)` |
| Theme color | `ThemeColor.primaryText01()` | `theme.primaryText01` |
| Text wrapping | `label.numberOfLines = 0` | `.fixedSize(horizontal: false, vertical: true)` |
| Auto-scale opt-in | `label.adjustsFontForContentSizeCategory = true` | Automatic with dynamic fonts |
| Scaled metric | `UIFontMetrics(forTextStyle:).scaledValue(for:)` | `@ScaledMetric` or `@ScaledMetricWithMaxSize` |
| Self-sizing cell | `tableView.rowHeight = .automaticDimension` | Automatic in `List` |
| Theme injection | `handleThemeChanged()` override | `@EnvironmentObject var theme: Theme` |
| Localized string | `L10n.myStringKey(arg)` | `L10n.myStringKey(arg)` (not `LocalizedStringKey`) |
