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
            Section {
                SourceButton(sourceSymbol: L10n.phone.sourceUnicode(isWatch: false), label: L10n.phone)
                SourceButton(sourceSymbol: L10n.watch.sourceUnicode(isWatch: true), label: L10n.watch)
            } footer: {
                Text(L10n.watchSourceMsg)
                    .font(.footnote)
                    .multilineTextAlignment(.leading)
                    .foregroundStyle(.gray)
            }
            Section {
                MenuRow(label: L10n.watchSourceRefreshData, icon: "retry")
            } footer: {
                Text(L10n.profileLastAppRefresh(L10n.timeFormatNever))
                    .font(.footnote)
                    .multilineTextAlignment(.leading)
            }
            Section {
                MenuRow(label: L10n.signedOut, icon: "profile-free")
                    .listRowBackground(Color.clear)
            } footer: {
                Text(L10n.watchSourceSignInInfo)
                    .font(.footnote)
            }
            Section {
                MenuRow(label: L10n.watchSourceRefreshAccount, icon: "profile-refresh")
            } footer: {
                VStack {
                    Text(L10n.watchSourceRefreshAccountInfo)
                    Image("plus-logo")
                    Text(L10n.watchSourcePlusInfo)
                }
            }
        }
    }
}

#Preview {
    SourceInterfaceForm()
}
