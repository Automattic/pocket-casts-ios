import PocketCastsDataModel
import SwiftUI
import WatchKit

struct EffectsView: View {
    @StateObject var viewModel = EffectsViewModel()

    var body: some View {
        ScrollView {
            VStack(spacing: WatchConstants.spacing) {
                HStack(spacing: WatchConstants.spacing) {
                    Button(action: { viewModel.decreasePlaybackSpeed() }) {
                        Image("minus", bundle: Bundle.watchAssets)
                    }
                    .roundIcon()

                    Button(L10n.playbackSpeed(viewModel.playbackSpeed.localized()), action: { viewModel.changeSpeedInterval() })
                        .buttonStyle(.plain)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(viewModel.playbackSpeed == 1 ? Color.background : Color.selectedBackground)
                        .cornerRadius(WatchConstants.cornerRadius)

                    Button(action: { viewModel.increasePlaybackSpeed() }) {
                        Image("plus", bundle: Bundle.watchAssets)
                    }
                    .roundIcon()
                }

                if viewModel.trimSilenceAvailable {
                    Toggle(L10n.trimSilence, isOn: $viewModel.trimSilenceEnabled)
                        .styled()
                }
                if viewModel.volumeBoostAvailable {
                    Toggle(L10n.volumeBoost, isOn: $viewModel.volumeBoostEnabled)
                        .styled()
                }
            }
            .padding(.top, 15)
        }
        .navigationTitle(L10n.watchEffects)
    }
}

// MARK: - Modifiers

private extension Toggle {
    func styled() -> some View {
        padding(.vertical)
            .padding(.horizontal, 15)
            .background(Color.background)
            .cornerRadius(WatchConstants.cornerRadius)
    }
}

private extension Button {
    func roundIcon() -> some View {
        buttonStyle(.plain)
            .clipShape(Circle())
    }
}

// MARK: - Preview

struct EffectsView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            EffectsView()
                .previewDevice(.largeWatch)

            EffectsView()
                .previewDevice(.smallWatch)
        }
    }
}
