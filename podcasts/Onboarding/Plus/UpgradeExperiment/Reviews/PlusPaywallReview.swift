import Foundation

struct PlusPaywallReview: Identifiable {
    let id: UUID = UUID()
    let title: String
    let review: String
    let date: String

    var formattedDate: Date? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd/MM/yy"
        return dateFormatter.date(from: date)
    }
}

extension PlusPaywallReview {
    static let reviews: [PlusPaywallReview] = [
        PlusPaywallReview(
            title: "Best Podcast App By FAR",
            review: "I've been a long time user and the amount of functionality and customization you get with the free version is astounding. I love that it syncs across devices so I can start listening on my phone and then pick up on an Alexa device. It's my recommendation for anyone who listens to podcasts. Also love the stats!",
            date: "10/07/2024"
        ),
        PlusPaywallReview(
            title: "The essential podcast app",
            review: "8 years of excellence and continuous improvement",
            date: "15/06/2024"
        ),
        PlusPaywallReview(
            title: "Best podcasat app out there",
            review: """
            I've been a Pocket Casts user since 2017.

            This is hands down the best app to listen to podcasts. It's feature rich and actively developed. There have been some complaints about the Ul change but I haven't really noticed it too much.

            This app can be as simple or difficult to use as you'd like it to be. So either let it be a plug and play or set up skip outro and intro timers and any other little feature you want to enable.
            """,
            date: "09/06/2024"
        ),
        PlusPaywallReview(
            title: "Fantastic app",
            review: "The sync function is magic. Don't know what special magic this app has going on but it's better than any other app l've used.",
            date: "01/06/2024"
        ),
        PlusPaywallReview(
            title: "Works great and easy to find or add new pods",
            review: "Been using this app for 6 years or better, started on android and now l've been on iOS for almost a year. Works the same on both platforms. Easy to find new podcasts to listen to, very nice Ul, can add podcasts by rss feed url too. The watch app is functional, but I mostly use for my play/pause. Sign in with an account to sync across devices but no requirement to do so.",
            date: "06/05/2024"
        ),
        PlusPaywallReview(
            title: "Go-To Podcast App",
            review: "PC has been my go-to for years. l've tried other podcast apps and always come back to PC for their simplicity, Ul and support. Definitely worth checking it out, especially if you have grown tired of your current podcast app.",
            date: "08/03/2024"
        )
    ]
}
