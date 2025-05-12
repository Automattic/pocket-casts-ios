import SwiftUI

struct CancelSubscriptionSurveyRow: View {
    @EnvironmentObject var theme: Theme

    let reason: CancelSubscriptionSurveyViewModel.Reason
    var selected: Bool = false
    let onTap: (CancelSubscriptionSurveyViewModel.Reason) -> Void

    @ViewBuilder
    var tick: some View {
        if selected {
            ZStack {
                Circle()
                    .fill(theme.primaryField03Active)
                Image("small-tick")
                    .resizable()
                    .foregroundColor(theme.primaryInteractive02)
            }
        } else {
            Circle()
                .fill(theme.primaryUi01Active)
                .overlay(
                        Circle()
                            .stroke(theme.primaryInteractive03, lineWidth: 2)
                    )
        }
    }

    var body: some View {
        ZStack {
            Rectangle()
                .foregroundStyle(.clear)
                .background(theme.primaryUi01Active)
                .cornerRadius(8.0)
                .frame(height: 64)
                .overlay(
                    RoundedRectangle(cornerRadius: 8.0)
                        .stroke(theme.primaryField03Active,
                                lineWidth: selected ? 2 : 0)
                )
            HStack(spacing: 16.0) {
                tick
                    .frame(width: 24, height: 24)
                Text(reason.description)
                    .font(size: 18.0, style: .body, weight: .bold)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    .foregroundStyle(theme.primaryText01)
                Spacer()
            }
            .padding(.horizontal, 16.0)
        }
        .padding(.horizontal, 20.0)
        .onTapGesture {
            onTap(reason)
        }
    }
}
