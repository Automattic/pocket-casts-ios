import SwiftUI

struct QRCodeDigits: View {

    let digits: [String]

    var body: some View {
        Group {
            if digits.isEmpty {
                ProgressView()
            } else {
                HStack(spacing: 8) {
                    ForEach(Array(digits.enumerated()), id: \.offset) { _, code in
                        Text(code)
                            .font(.caption2)
                            .foregroundStyle(Color.pcTextSecondary)
                            .padding(32)
                            .background(Color.pcBackgroundActive20)
                            .clipShape(Circle())
                    }
                }
            }
        }
    }
}
