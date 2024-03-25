//
//  SourceInterfaceForm.swift
//  Pocket Casts Watch App
//
//  Created by Sérgio Estêvão on 25/03/2024.
//  Copyright © 2024 Shifty Jelly. All rights reserved.
//

import SwiftUI

struct SourceButton: View {
    let sourceSymbol: String
    let label: String

    var body: some View {
        Button(action: {
            
        }, label: {
            HStack {
                Text(sourceSymbol)
                Text(label)
                Spacer()
                Image("now-playing-small")
            }
        })
    }
}

struct SourceInterfaceForm: View {
    var body: some View {
        List {
            SourceButton(sourceSymbol: L10n.phone.sourceUnicode(isWatch: false), label: L10n.phone)
            SourceButton(sourceSymbol: L10n.watch.sourceUnicode(isWatch: true), label: L10n.watch)
            Text(L10n.watchSourceMsg)
                .font(.footnote)
                .multilineTextAlignment(.leading)
                .foregroundStyle(.gray)
                .background(.clear)
            MenuRow(label: L10n.watchSourceRefreshData, icon: "retry")
            Text(L10n.profileLastAppRefresh(L10n.timeFormatNever))
                .font(.footnote)
                .multilineTextAlignment(.leading)
            MenuRow(label: L10n.name, icon: "profile-free")
            Text(L10n.watchSourceSignInInfo)
                .font(.footnote)
        }
    }
}

#Preview {
    SourceInterfaceForm()
}
