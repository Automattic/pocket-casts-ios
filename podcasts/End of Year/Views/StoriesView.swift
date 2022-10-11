import SwiftUI

struct StoriesView: View {
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        VStack {
            ZStack {
                fakeStory
                header
                Spacer()
            }

            ZStack {}
                .frame(height: 15)

            shareButton
        }
        .background(Color.black)
    }

    // Header containing the close button and the rectangles
    var header: some View {
        ZStack {
            VStack {
                HStack {
                    storyIndicator
                    storyIndicator
                }
                .frame(height: 2)
                Spacer()
            }
            .padding(.leading, 13)
            .padding(.trailing, 13)

            closeButton
        }
        .padding(.top, 5)
    }

    var fakeStory: some View {
        ZStack {
            Color.purple
        }
        .cornerRadius(15)
    }

    var closeButton: some View {
            VStack {
                HStack {
                    Spacer()
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .foregroundColor(.white)
                            .padding(13)
                    }
                }
                .padding(.top, 5)
                Spacer()
            }
        }

    var storyIndicator: some View {
        GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .foregroundColor(Color.white.opacity(0.3))
                        .cornerRadius(5)

                    Rectangle()
                        .foregroundColor(Color.white.opacity(0.9))
                        .cornerRadius(5)
                }
            }
    }

    var shareButton: some View {
        Button(action: {

        }) {
            HStack {
                Spacer()
                Image(systemName: "square.and.arrow.up")
                    .foregroundColor(.white)
                Text("Share")
                    .foregroundColor(.white)
                Spacer()
            }
        }
        .contentShape(Rectangle())
        .padding(.top, 10)
        .padding(.bottom, 10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(.white, style: StrokeStyle(lineWidth: 1))
        )
        .padding(.leading, 5)
        .padding(.trailing, 5)
    }
}

struct StoriesView_Previews: PreviewProvider {
    static var previews: some View {
        StoriesView()
    }
}
