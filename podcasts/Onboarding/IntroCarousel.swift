import SwiftUI

struct IntroCarouselView: View {
    @EnvironmentObject var theme: Theme
    @StateObject private var progressModel = CarouselProgressModel()
    @State private var currentPage = 0
    @State private var timer = Timer.publish(every: 0.05, on: .main, in: .common).autoconnect()
    @State private var isAutomaticChange = false

    private let totalDuration: Double = 3.0
    private let timerInterval: Double = 0.05

    private let carouselItems = [
        CarouselItem(title: "The best podcast app out there. By far", description: "Pocket Casts user"),
        CarouselItem(title: "The amount of customization is insane", description: "Pocket Casts user"),
        CarouselItem(title: "Organizing my podcasts by folders is genius", description: "Pocket Casts user")
    ]

    var body: some View {
        VStack(spacing: 0) {
            // Custom progress indicators
            HStack(spacing: 4) {
                ForEach(0..<carouselItems.count, id: \.self) { index in
                    CarouselIndicator(index: index, progressModel: progressModel)
                        .frame(height: 4)
                }
            }
            .padding(.horizontal, 14)
            .padding(.top, 14)
            .padding(.bottom, 20)

            Spacer()

            TabView(selection: $currentPage) {
                ForEach(Array(carouselItems.enumerated()), id: \.offset) { index, item in
                    CarouselSlideView(item: item)
                        .tag(index)
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            .frame(height: 300)
            .animation(.easeInOut(duration: 0.6), value: currentPage)
            .onReceive(timer) { _ in
                progressModel.incrementProgress(interval: timerInterval, totalDuration: totalDuration, itemCount: carouselItems.count) { newPage in
                    if newPage != currentPage {
                        isAutomaticChange = true
                        withAnimation(.easeInOut(duration: 0.6)) {
                            currentPage = newPage
                        }
                        isAutomaticChange = false
                    }
                }
            }
            .onAppear {
                progressModel.startProgress()
            }
            .onChange(of: currentPage) { newPage in
                // Only reset progress on manual swipes, not automatic changes
                if !isAutomaticChange {
                    progressModel.resetProgress(toPage: newPage)
                }
            }

            Spacer()

            VStack(spacing: 16) {
                Button(L10n.eacInformationalViewModalGetStartedButton) {
                    // Handle get started action
                }
                .buttonStyle(RoundedButtonStyle(theme: theme))

                Button(L10n.accountLogin) {
                    // Handle login action
                }
                .foregroundColor(theme.primaryText01)
                .font(.system(size: 16, weight: .medium))
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 50)
        }
        .modifier(DefaultThemeSettings())
    }
}

struct CarouselItem {
    let title: String
    let description: String
}

class CarouselProgressModel: ObservableObject {
    @Published var progress: Double = 0
    private var startTime: Date?

    func startProgress() {
        startTime = Date()
        progress = 0
    }

    func resetProgress(toPage page: Int) {
        startTime = Date()
        progress = Double(page)
    }

    func incrementProgress(interval: Double, totalDuration: Double, itemCount: Int, onPageChange: (Int) -> Void) {
        guard let startTime = startTime else { return }

        let elapsed = Date().timeIntervalSince(startTime)
        let totalCycleDuration = totalDuration * Double(itemCount)
        let cycleProgress = elapsed.truncatingRemainder(dividingBy: totalCycleDuration)

        // Calculate which slide we're currently on and progress within that slide
        let currentSlideIndex = Int(cycleProgress / totalDuration) % itemCount
        let progressWithinCurrentSlide = cycleProgress.truncatingRemainder(dividingBy: totalDuration)

        // Progress should be: currentSlideIndex + (progress within current slide / totalDuration)
        progress = Double(currentSlideIndex) + (progressWithinCurrentSlide / totalDuration)

        // Trigger page change when we're 80% through the current slide
        if progressWithinCurrentSlide >= totalDuration * 0.8 {
            let nextSlideIndex = (currentSlideIndex + 1) % itemCount
            onPageChange(nextSlideIndex)
        } else {
            onPageChange(currentSlideIndex)
        }
    }
}

struct CarouselIndicator: View {
    @EnvironmentObject var theme: Theme
    let index: Int
    @ObservedObject var progressModel: CarouselProgressModel

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background bar
                Rectangle()
                    .fill(theme.primaryInteractive03)
                    //.fill(theme.primaryUi05)
                    .opacity(0.3)
                    .cornerRadius(2)

                // Progress bar
                Rectangle()
                    .fill(theme.secondaryText02)
                    //.fill(theme.primaryUi05Selected)
                    .frame(width: geometry.size.width * progressForIndex)
                    .opacity(0.9)
            }
        }
    }

    private var progressForIndex: CGFloat {
        let currentProgress = progressModel.progress
        let indexFloat = Double(index)

        if currentProgress >= indexFloat + 1 {
            // Completed pages
            return 1.0
        } else if currentProgress >= indexFloat {
            // Current page - show partial progress
            return CGFloat(currentProgress - indexFloat)
        } else {
            // Future pages
            return 0.0
        }
    }
}

struct CarouselSlideView: View {
    @EnvironmentObject var theme: Theme
    let item: CarouselItem

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "waveform.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(ThemeColor.primaryInteractive01(for: theme.activeTheme).color)

            VStack(spacing: 12) {
                Text(item.title)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(ThemeColor.primaryText01(for: theme.activeTheme).color)
                    .multilineTextAlignment(.center)

                Text(item.description)
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(ThemeColor.primaryText02(for: theme.activeTheme).color)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
        }
    }
}

extension Double {
    func clamped(to range: Range<Double>) -> Double {
        return Swift.min(Swift.max(self, range.lowerBound), range.upperBound - 0.001)
    }
}
