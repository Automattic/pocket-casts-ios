import Foundation

public extension Double {
    var seconds: TimeInterval {
        self
    }

    var second: TimeInterval {
        seconds
    }

    var minutes: TimeInterval {
        self * 60
    }

    var minute: TimeInterval {
        minutes
    }

    var hours: TimeInterval {
        minutes * 60
    }

    var hour: TimeInterval {
        hours
    }

    var days: TimeInterval {
        hours * 24
    }

    var day: TimeInterval {
        days
    }

    var weeks: TimeInterval {
        days * 7
    }

    var week: TimeInterval {
        weeks
    }
}
