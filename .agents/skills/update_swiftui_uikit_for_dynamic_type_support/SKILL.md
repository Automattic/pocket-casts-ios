---
name: update_swiftui_uikit_for_dynamic_type_support
description: Dynamic Type support in Pocket Casts UIKit and SwiftUI code. Use for content size categories, accessibility text sizes, font scaling, UIFontMetrics, or making text, buttons and images follow the user's preferred text size.
---

# Dynamic Type

Every text element, button and scalable image must adapt to the user's preferred text size.

## Fonts

Use Apple's [text styles](https://developer.apple.com/design/human-interface-guidelines/typography#Specifications), matching design specs against the **Large** (default) size. For a custom size, scale it with the style whose default size is closest. These helpers use `UIFontMetrics` and cap at `.accessibilityExtraExtraExtraLarge` by default:

| | UIKit | SwiftUI |
|---|---|---|
| Standard style | `.font(with: .body, weight: .regular)` | `.font(style: .body, weight: .regular)` |
| Custom size | `.font(ofSize: 15, weight: .medium, scalingWith: .subheadline)` | `.font(size: 15, style: .subheadline, weight: .medium)` |
| Button | Same, on `titleLabel` | `.applyButtonFont(size: 18, style: .body, weight: .semibold)`, or a `Text` with a dynamic font |

## UIKit

- **Labels and button titles**: set `numberOfLines = 0` and `adjustsFontForContentSizeCategory = true`. Pin top and bottom to the container and raise vertical hugging and compression resistance so the label drives the height. A multi-line button may need a height constraint tying it to its `titleLabel`.
- **Images**: constrain width and height to the base size. In `traitCollectionDidChange(_:)`, when `preferredContentSizeCategory` changes, set both to `max(base, UIFontMetrics(forTextStyle: .largeTitle).scaledValue(for: base))`.
- **Stack views**: use `distribution = .fill`; `.fillEqually` or fixed distributions fight growing labels.
- **Table views**: `rowHeight = UITableView.automaticDimension` with an `estimatedRowHeight`, and an unbroken chain of constraints from the top to the bottom of the cell's content view. For SwiftUI cells, prefer `UIHostingConfiguration` (resizes automatically, inject `Theme.sharedTheme`); with `themedUIView`/`insertThemedUIView(in:)`, set up the child view controller relationship.

## SwiftUI

- **Text**: add `.fixedSize(horizontal: false, vertical: true)` to any `Text` that should wrap, including attributed text views such as `DescriptiveActionAttributedTextView`.
- **Images**: size them with `@ScaledMetric(relativeTo: .largeTitle)`, or `@ScaledMetricWithMaxSize(wrappedValue: 24, relativeTo: .largeTitle, maxSize: .xxLarge)` to cap the scaling, and apply it with `.frame`.
- **Lists**: `List`, or a `VStack` in a `ScrollView`, size automatically with dynamic fonts.

## Web Views

Set `:root { font: -apple-system-body; }` and size everything else in `rem` or `em`.
