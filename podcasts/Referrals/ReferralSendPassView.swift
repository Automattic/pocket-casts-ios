import SwiftUI

class ReferralSendPassModel: NSObject {
    let offerInfo: ReferralsOfferInfo
    var onShareGuestPassTap: (() -> ())?
    var onCloseTap: (() -> ())?

    init(offerInfo: ReferralsOfferInfo, onShareGuestPassTap: (() -> ())? = nil, onCloseTap: (() -> ())? = nil) {
        self.offerInfo = offerInfo
        self.onShareGuestPassTap = onShareGuestPassTap
        self.onCloseTap = onCloseTap
    }

    var title: String {
        L10n.referralsTipMessage(offerInfo.localizedOfferDurationNoun)
    }

    var buttonTitle: String {
        L10n.referralsShareGuestPass
    }
}

extension ReferralSendPassModel: UIActivityItemSource {
    func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any {
        return "Hey! Use the link below to claim your 2-month guest pass for Pocket Casts Plus and enjoy podcasts across all your devices!"
    }

    func activityViewController(_ activityViewController: UIActivityViewController, itemForActivityType activityType: UIActivity.ActivityType?) -> Any? {
        return URL(string: "http://pocketcasts.com")
    }

    func activityViewController(_ activityViewController: UIActivityViewController, subjectForActivityType activityType: UIActivity.ActivityType?) -> String {
        return "Hey! Use the link below to claim your 2-month guest pass for Pocket Casts Plus and enjoy podcasts across all your devices!"
    }
}

struct ReferralSendPassView: View {
    let viewModel: ReferralSendPassModel

    @State var showShareView: Bool = false

    var body: some View {
        VStack(alignment: .leading) {
            Button(action: {
                viewModel.onCloseTap?()
            }, label: {
                Image("close").foregroundColor(Color.white)
            })
            VStack(spacing: Constants.verticalSpacing) {
                SubscriptionBadge(tier: .plus, displayMode: .gradient, foregroundColor: .black)
                Text(viewModel.title)
                    .font(size: 31, style: .title, weight: .bold)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.white)
                ZStack {
                    ForEach(0..<Constants.numberOfPasses, id: \.self) { i in
                        ReferralCardView(offerDuration: viewModel.offerInfo.localizedOfferDurationAdjective)
                            .frame(width: Constants.defaultCardSize.width - (CGFloat(Constants.numberOfPasses-1-i) * Constants.cardInset.width), height: Constants.defaultCardSize.height)
                            .offset(CGSize(width: 0, height: CGFloat(Constants.numberOfPasses * i) * Constants.cardInset.height))
                    }
                }
            }
            Spacer()
            Button(viewModel.buttonTitle) {
                showShareView.toggle()
            }.buttonStyle(PlusGradientFilledButtonStyle(isLoading: false, plan: .plus))
        }
        .padding()
        .background(.black)
        .sheet(isPresented: $showShareView) {
            viewModel.onShareGuestPassTap?()
        } content: {
            ActivityView([viewModel])
        }

    }

    enum Constants {
        static let verticalSpacing = CGFloat(24)
        static let defaultCardSize = ReferralCardView.Constants.defaultCardSize
        static let cardInset = CGSize(width: 40, height: 5)
        static let numberOfPasses: Int = 3
    }
}

#Preview("With Passes") {
    Group {
        ReferralSendPassView(viewModel: ReferralSendPassModel(offerInfo: ReferralsOfferInfoMock()))
    }
}
