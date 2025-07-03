import SwiftUI

struct UpgradeProductsView: View {

    @ObservedObject var model: UpgradeAccountViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(model.products, id: \.self.id) { product in
                HStack(alignment: .center) {
                    Image(systemName: true ? "checkmark" : "circle")
                    VStack(alignment: .leading) {
                        Text(product.price)
                            .font(.subheadline).fontWeight(.bold)
                        Text(product.price)
                            .font(.subheadline).fontWeight(.medium)
                            .foregroundStyle(.gray)
                    }
                    Spacer()
                    Text(product.weeklyPrice)
                        .font(.subheadline).fontWeight(.medium)
                        .foregroundStyle(.gray)
                }
                .padding(16)
                .background(Color(red: 0.98, green: 0.98, blue: 0.98))
                .cornerRadius(12)
                .overlay {
                    if let offer = product.offer {
                        ZStack(alignment: .top) {
                            RoundedRectangle(cornerRadius: 12)
                                .inset(by: 1)
                                .stroke(Color(red: 0.01, green: 0.66, blue: 0.96), lineWidth: 2)
                            badge.offset(x: 0, y: -10)
                        }
                    } else {
                        EmptyView()
                    }
                }
            }
            Spacer().frame(height: 16)
            actionButton
        }
    }

    var badge: some View {
        HStack(alignment: .center, spacing: 0) {
            Text ("Offer")
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 2)
        .background(Color(red: 0.01, green: 0.66, blue: 0.96))
        .cornerRadius(800)
        .overlay(
            RoundedRectangle(cornerRadius: 800)
                .inset(by: 0.5)
                .stroke(.white.opacity(0.08), lineWidth: 1)
        )
    }

    var actionButton: some View {
        Button("Purchase") {

        }
        //        SubscriptionPurchaseButton(viewModel: viewModel) {
        //
        //        }
        //        .frame(maxWidth: 440)
    }
}
