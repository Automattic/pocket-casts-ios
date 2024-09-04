import SwiftUI
import Combine

struct ShareButton: View {
    @Binding var isExporting: Bool
    @Binding var shareTask: Task<Void, Error>?
    @Binding var progress: Float?

    let option: SharingModal.Option
    let destination: ShareDestination
    let style: ShareImageStyle
    let clipTime: ClipTime
    let clipUUID: String
    let source: AnalyticsSource

    var frame: CurrentValueSubject<CGRect, Never> = .init(.zero)

    private let frameID = UUID()

    var body: some View {
        Button {
            isExporting = true
            shareTask = Task.detached { @MainActor in
                do {
                    try await destination.share(option, style: style, clipTime: clipTime, clipUUID: clipUUID, progress: $progress, presentFrom: frame, source: source)
                } catch let error {
                    if Task.isCancelled { return }
                    await MainActor.run {
                        Toast.show("Failed clip export: \(error.localizedDescription)")
                    }
                }
            }
        } label: {
            view(for: destination)
        }
        .measureFrame(in: .global, id: frameID)
        .onPreferenceChange(FrameKey.self, perform: { value in
            let rect = value[frameID] ?? .zero
            let sourceRect = CGRect(origin: rect.origin, size: CGSize(width: rect.width, height: -rect.height))
            frame.value = sourceRect
        })
    }

    @ViewBuilder func view(for destination: ShareDestination) -> some View {
        VStack {
            destination.icon
                .renderingMode(.template)
                .font(size: 20, style: .body, weight: .bold)
                .frame(width: 24, height: 24)
                .padding(15)
                .background {
                    Circle()
                        .foregroundStyle(.white.opacity(0.1))
                }
            Text(destination.name)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

struct FrameKey: PreferenceKey {
    static var defaultValue: [UUID: CGRect] { [:] }

    static func reduce(value: inout [UUID: CGRect], nextValue: () -> [UUID: CGRect]) {
        value.merge(nextValue(), uniquingKeysWith: { $1 })
    }
}

extension View {
    func measureFrame(in coordinateSpace: CoordinateSpace, id: UUID) -> some View {
        background(GeometryReader { proxy in
            Color.clear.preference(key: FrameKey.self, value: [id: proxy.frame(in: coordinateSpace)])
        })
    }
}
