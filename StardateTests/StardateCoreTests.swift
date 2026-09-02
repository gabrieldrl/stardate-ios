import XCTest
@testable import Stardate

final class StardateCoreTests: XCTestCase {
    private let calendar = StardateCalculator.utcCalendar

    func testTNGEpochAtStartOf2323() {
        let date = makeDate(year: 1983, month: 1, day: 1)

        XCTAssertEqual(StardateCalculator.stardate(at: date, calendar: calendar), 0, accuracy: 0.000_001)
    }

    func testContemporaryProjectionAligns2024WithTNGYear2364() {
        let date = makeDate(year: 2024, month: 1, day: 1)

        XCTAssertEqual(StardateCalculator.trekYear(for: date, calendar: calendar), 2364)
        XCTAssertEqual(StardateCalculator.stardate(at: date, calendar: calendar), 41_000, accuracy: 0.000_001)
    }

    func testLeapYearUsesLeapYearLength() {
        let date = makeDate(year: 2024, month: 7, day: 2)
        let value = StardateCalculator.stardate(at: date, calendar: calendar)

        XCTAssertEqual(value, 41_500, accuracy: 0.01)
    }

    func testFormattingClampsPrecision() {
        let value = StardateCalculator.formatted(stardate: 41_153.6789, decimalPlaces: 2)

        XCTAssertEqual(value, "41153.68")
    }

    private func makeDate(year: Int, month: Int, day: Int) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day))!
    }
}
