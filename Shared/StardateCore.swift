import Foundation

/// A transparent, fan-derived interpretation of the TNG-era stardate scale.
enum StardateCalculator {
    /// Stardate 00000 starts at the beginning of 2323 in the usual TNG model.
    static let epochYear = 2323

    /// Contemporary Earth dates are projected 340 years forward so 2024 aligns
    /// with the beginning of TNG's 2364-era stardates.
    static let contemporaryYearOffset = 340

    /// Returns the projected 24th-century year for a contemporary Earth date.
    static func trekYear(for date: Date, calendar: Calendar = utcCalendar) -> Int {
        calendar.component(.year, from: date) + contemporaryYearOffset
    }

    /// Calculates a TNG-style stardate with 1,000 units per projected year.
    /// The fraction uses the exact length of the current Gregorian year,
    /// including leap years, and the calculation is performed in UTC.
    static func stardate(at date: Date, calendar: Calendar = utcCalendar) -> Double {
        let earthYear = calendar.component(.year, from: date)
        let startOfYear = calendar.date(from: DateComponents(year: earthYear, month: 1, day: 1)) ?? date
        let startOfNextYear = calendar.date(from: DateComponents(year: earthYear + 1, month: 1, day: 1)) ?? date.addingTimeInterval(365 * 24 * 60 * 60)
        let yearLength = startOfNextYear.timeIntervalSince(startOfYear)
        let yearFraction = yearLength > 0 ? date.timeIntervalSince(startOfYear) / yearLength : 0
        let projectedYear = trekYear(for: date, calendar: calendar)

        return Double(projectedYear - epochYear) * 1_000 + yearFraction * 1_000
    }

    static func formatted(
        stardate: Double,
        decimalPlaces: Int,
        locale: Locale = Locale(identifier: "en_US_POSIX")
    ) -> String {
        let places = max(0, min(decimalPlaces, 6))
        return String(format: "%.*f", locale: locale, places, stardate)
    }

    static func formatted(
        date: Date,
        decimalPlaces: Int,
        calendar: Calendar = utcCalendar
    ) -> String {
        formatted(stardate: stardate(at: date, calendar: calendar), decimalPlaces: decimalPlaces)
    }

    static var utcCalendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .gmt
        calendar.locale = Locale(identifier: "en_US_POSIX")
        return calendar
    }
}
