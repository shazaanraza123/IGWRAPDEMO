import Foundation

/// Maya's finished card strings. Views print these. They do not rebuild sentences.
enum MayaOpening {
    static let handle = "maya.lens"
    static let photos = ["tile-1", "tile-2", "tile-3", "tile-4", "tile-5"]
    static let headline = "2026 looked good on you."
    static let support = "Built from your own posts and Stories, Jan 1 to Nov 15."
}

struct MayaMonth: Identifiable, Equatable {
    var month: Int
    var photo: String
    var shortName: String

    var id: Int { month }
    var isTop: Bool { month == MayaYear.topMonth }
    var chip: String { isTop ? "\(shortName) · TOP MONTH" : shortName }
}

enum MayaYear {
    static let headline = "You had quite a year."
    static let support = "August was your busiest month: 9 posts, 61 Stories."
    static let playLabel = "PLAY YOUR YEAR · 0:15"
    static let topMonth = 8
    static let montageSeconds = 15
    static let months: [MayaMonth] = [
        MayaMonth(month: 1, photo: "m-01", shortName: "JAN"),
        MayaMonth(month: 2, photo: "m-02", shortName: "FEB"),
        MayaMonth(month: 3, photo: "m-03", shortName: "MAR"),
        MayaMonth(month: 4, photo: "m-04", shortName: "APR"),
        MayaMonth(month: 5, photo: "m-05", shortName: "MAY"),
        MayaMonth(month: 6, photo: "m-06", shortName: "JUN"),
        MayaMonth(month: 7, photo: "m-07", shortName: "JUL"),
        MayaMonth(month: 8, photo: "m-08", shortName: "AUG"),
        MayaMonth(month: 9, photo: "m-09", shortName: "SEP"),
        MayaMonth(month: 10, photo: "m-10", shortName: "OCT"),
        MayaMonth(month: 11, photo: "m-11", shortName: "NOV")
    ]
}

struct MayaSwatch: Identifiable, Equatable {
    var hex: String
    var percent: String
    var id: String { hex }
}

enum MayaFeed {
    static let headline = "Your feed had a color."
    static let paletteName = "Midnight Camel"
    static let footnote = "% = main color in each of 1,840 liked posts"
    static let domination = "of liked posts where this color dominates"
    static let swatches: [MayaSwatch] = [
        MayaSwatch(hex: "#1F2A44", percent: "31%"),
        MayaSwatch(hex: "#C8A27C", percent: "24%"),
        MayaSwatch(hex: "#8B3A3A", percent: "19%"),
        MayaSwatch(hex: "#E9E1D3", percent: "15%"),
        MayaSwatch(hex: "#4E6B4A", percent: "11%")
    ]
}

struct MayaTopic: Identifiable, Equatable {
    var index: String
    var name: String
    var title: String
    var undercut: Bool
    var id: String { name }
}

enum MayaAlgorithm {
    static let headline = "Your algorithm thinks you're into..."
    static let note = "Your taps tune Explore. Undo in Settings."
    static let undercut = "63 watched. No judgment."
    static let topics: [MayaTopic] = [
        MayaTopic(index: "01", name: "Streetwear drops", title: "Streetwear drops", undercut: false),
        MayaTopic(index: "02", name: "Film cameras", title: "Film cameras", undercut: false),
        MayaTopic(index: "03", name: "Ceramic frogs", title: "...ceramic frogs?", undercut: true)
    ]
}

enum FeedbackKind {
    static let moreOfThis = "more_of_this"
    static let notMe = "not_me"
    static let guilty = "guilty"
}
