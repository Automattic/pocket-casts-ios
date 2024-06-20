//
//  PocketCastsLogoPill.swift
//  podcasts
//
//  Created by Brandon Titus on 4/17/24.
//  Copyright © 2024 Shifty Jelly. All rights reserved.
//

import SwiftUI

struct PocketCastsLogoPill: View {
    var body: some View {
        HStack {
            Image("pocketcasts")
                .resizable()
                .frame(width: 18, height: 18)
            Text("Pocket Casts")
                .padding(.trailing, 7)
                .font(Font.system(size: 12, weight: .semibold))
        }
        .padding(4)
        .foregroundStyle(.white)
        .background(Theme(previewTheme: .classic).primaryIcon01)
        .clipShape(Capsule())
    }
}

#Preview {
    PocketCastsLogoPill()
}
