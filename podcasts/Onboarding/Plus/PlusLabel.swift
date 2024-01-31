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

    init(_ text: String, for style: PlusLabelStyle) {
        self.text = text
        self.labelStyle = style
    }

    var body: some View {
        Text(text)
            .foregroundColor(.white)
            .fixedSize(horizontal: false, vertical: true)
            .modifier(LabelFont(labelStyle: labelStyle))
    }

    private struct LabelFont: ViewModifier {
        let labelStyle: PlusLabelStyle

        func body(content: Content) -> some View {
            switch labelStyle {
            case .title:
                return content.font(size: 30, style: .title, weight: .bold, maxSizeCategory: .extraExtraLarge)
            case .title2:
                return content.font(style: .title2, weight: .bold, maxSizeCategory: .extraExtraLarge)
            case .subtitle:
                return content.font(size: 18, style: .body, weight: .regular, maxSizeCategory: .extraExtraLarge)
            case .featureTitle:
                return content.font(style: .footnote, maxSizeCategory: .extraExtraLarge)
            case .featureDescription:
                return content.font(style: .footnote, maxSizeCategory: .extraExtraLarge)
            }
        }
    }
}
