import SwiftUI

struct EndOfYearCard: View {
    var body: some View {
        ZStack {
            HStack {
                VStack(alignment: .leading) {
                    Text("Your Year in Podcasts")
                        .foregroundColor(.white)
                    Text("See your top podcasts, categories, listening stats and more.")
                        .foregroundColor(.white)
                }
                .padding()
                Spacer()
            }
            .background(Color.black)
            .cornerRadius(15)
        }
        .padding()
    }
}

struct EndOfYearCard_Previews: PreviewProvider {
    static var previews: some View {
        EndOfYearCard()
    }
}
