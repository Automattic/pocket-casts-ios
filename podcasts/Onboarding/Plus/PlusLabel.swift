//
//  PlusLabel.swift
//  podcasts
//
//  Created by Brandon Titus on 1/11/24.
//  Copyright © 2024 Shifty Jelly. All rights reserved.
//

import SwiftUI

struct PlusLabel: View {
    enum PlusLabelStyle {
        case title
        case title2
        case subtitle
        case featureTitle
        case featureDescription
    }

    let text: String
    let labelStyle: PlusLabelStyle
    let maxSizeCategory: UIContentSizeCategory

    init(_ text: String, for style: PlusLabelStyle, maxSizeCategory: UIContentSizeCategory = .accessibilityExtraExtraExtraLarge) {
        self.text = text
        self.labelStyle = style
        self.maxSizeCategory = maxSizeCategory
    }

    var body: some View {
        Text(text)
            .foregroundColor(.white)
            .fixedSize(horizontal: false, vertical: true)
            .modifier(LabelFont(labelStyle: labelStyle, maxSizeCategory: maxSizeCategory))
    }

    private struct LabelFont: ViewModifier {
        let labelStyle: PlusLabelStyle
        let maxSizeCategory: UIContentSizeCategory

        func body(content: Content) -> some View {
            switch labelStyle {
            case .title:
                return content.font(size: 30, style: .title, weight: .bold, maxSizeCategory: maxSizeCategory)
            case .title2:
                return content.font(style: .title2, weight: .bold, maxSizeCategory: maxSizeCategory)
            case .subtitle:
                return content.font(size: 18, style: .body, weight: .regular, maxSizeCategory: maxSizeCategory)
            case .featureTitle:
                return content.font(style: .footnote, maxSizeCategory: maxSizeCategory)
            case .featureDescription:
                return content.font(style: .footnote, maxSizeCategory: maxSizeCategory)
            }
        }
    }
}
