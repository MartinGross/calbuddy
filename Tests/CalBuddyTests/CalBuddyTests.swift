import XCTest
@testable import CalBuddyLib

final class ParseArgsTests: XCTestCase {

    func testSimpleCommands() {
        XCTAssertEqual(parseArgs(["eventsToday"]).command, "eventsToday")
        XCTAssertEqual(parseArgs(["eventsTomorrow"]).command, "eventsTomorrow")
        XCTAssertEqual(parseArgs(["eventsNow"]).command, "eventsNow")
        XCTAssertEqual(parseArgs(["calendars"]).command, "calendars")
        XCTAssertEqual(parseArgs(["help"]).command, "help")
    }

    func testEmptyArgs() {
        let result = parseArgs([])
        XCTAssertEqual(result.command, "")
    }

    func testEventsRange() {
        let result = parseArgs(["eventsFrom:2024-06-01", "to:2024-06-30"])
        XCTAssertEqual(result.command, "eventsRange")
        XCTAssertNotNil(result.startDate)
        XCTAssertNotNil(result.endDate)
    }

    func testEventsRangeInvalidDates() {
        let result = parseArgs(["eventsFrom:not-a-date", "to:also-bad"])
        XCTAssertEqual(result.command, "eventsRange")
        XCTAssertNil(result.startDate)
        XCTAssertNil(result.endDate)
    }

    func testIncludeCals() {
        let result = parseArgs(["eventsToday", "-ic", "Work,Personal"])
        XCTAssertEqual(result.config.includeCals, ["Work", "Personal"])
    }

    func testIncludeCalsLongForm() {
        let result = parseArgs(["eventsToday", "--include-cals", "Work"])
        XCTAssertEqual(result.config.includeCals, ["Work"])
    }

    func testExcludeCals() {
        let result = parseArgs(["eventsToday", "-ec", "Birthdays,Holidays"])
        XCTAssertEqual(result.config.excludeCals, ["Birthdays", "Holidays"])
    }

    func testSeparateByCalendar() {
        let result = parseArgs(["eventsToday", "-sc"])
        XCTAssertTrue(result.config.separateByCalendar)
    }

    func testSeparateByDate() {
        let result = parseArgs(["eventsToday", "--separate-by-date"])
        XCTAssertTrue(result.config.separateByDate)
    }

    func testExcludeAllDay() {
        let result = parseArgs(["eventsToday", "-ea"])
        XCTAssertFalse(result.config.includeAllDayEvents)
    }

    func testNoCalendarNames() {
        let result = parseArgs(["eventsToday", "--no-calendar-names"])
        XCTAssertTrue(result.config.noCalendarNames)
    }

    func testNoPropNames() {
        let result = parseArgs(["eventsToday", "-np"])
        XCTAssertTrue(result.config.noPropNames)
    }

    func testBullet() {
        let result = parseArgs(["eventsToday", "-b", "→ "])
        XCTAssertEqual(result.config.bulletPoint, "→ ")
    }

    func testDateFormat() {
        let result = parseArgs(["eventsToday", "--date-format", "dd.MM.yyyy"])
        XCTAssertEqual(result.config.dateFormat, "dd.MM.yyyy")
    }

    func testTimeFormat() {
        let result = parseArgs(["eventsToday", "-tf", "h:mm a"])
        XCTAssertEqual(result.config.timeFormat, "h:mm a")
    }

    func testLimit() {
        let result = parseArgs(["eventsToday", "-n", "5"])
        XCTAssertEqual(result.config.limitItems, 5)
    }

    func testLimitInvalid() {
        let result = parseArgs(["eventsToday", "--limit", "abc"])
        XCTAssertEqual(result.config.limitItems, 0)
    }

    func testFormatJSON() {
        let result = parseArgs(["eventsToday", "-f", "json"])
        XCTAssertEqual(result.config.output, .json)
    }

    func testFormatPlain() {
        let result = parseArgs(["eventsToday", "--format", "plain"])
        XCTAssertEqual(result.config.output, .plain)
    }

    func testFormatInvalid() {
        let result = parseArgs(["eventsToday", "-f", "xml"])
        XCTAssertEqual(result.config.output, .plain)
    }

    func testMultipleOptions() {
        let result = parseArgs(["eventsToday", "-ea", "-nc", "-sc", "-n", "3", "-f", "json"])
        XCTAssertFalse(result.config.includeAllDayEvents)
        XCTAssertTrue(result.config.noCalendarNames)
        XCTAssertTrue(result.config.separateByCalendar)
        XCTAssertEqual(result.config.limitItems, 3)
        XCTAssertEqual(result.config.output, .json)
    }

    func testMissingOptionValue() {
        // -ic at the end without a value should not crash
        let result = parseArgs(["eventsToday", "-ic"])
        XCTAssertEqual(result.config.includeCals, [])
    }
}

final class ConfigTests: XCTestCase {

    func testDefaults() {
        let config = Config()
        XCTAssertFalse(config.separateByCalendar)
        XCTAssertFalse(config.separateByDate)
        XCTAssertTrue(config.includeCals.isEmpty)
        XCTAssertTrue(config.excludeCals.isEmpty)
        XCTAssertTrue(config.includeAllDayEvents)
        XCTAssertFalse(config.noCalendarNames)
        XCTAssertEqual(config.bulletPoint, "• ")
        XCTAssertEqual(config.dateFormat, "yyyy-MM-dd")
        XCTAssertEqual(config.timeFormat, "HH:mm")
        XCTAssertEqual(config.limitItems, 0)
        XCTAssertFalse(config.noPropNames)
        XCTAssertEqual(config.output, .plain)
    }
}

final class DateHelperTests: XCTestCase {

    func testStartOfDay() {
        let now = Date()
        let start = startOfDay(now)
        let components = Calendar.current.dateComponents([.hour, .minute, .second], from: start)
        XCTAssertEqual(components.hour, 0)
        XCTAssertEqual(components.minute, 0)
        XCTAssertEqual(components.second, 0)
    }

    func testEndOfDayIsNextDayMidnight() {
        let now = Date()
        let start = startOfDay(now)
        let end = endOfDay(now)
        let diff = Calendar.current.dateComponents([.day], from: start, to: end)
        XCTAssertEqual(diff.day, 1)
    }

    func testStartOfTomorrowIsOneDayAfterToday() {
        let today = startOfDay()
        let tomorrow = startOfTomorrow()
        let diff = Calendar.current.dateComponents([.day], from: today, to: tomorrow)
        XCTAssertEqual(diff.day, 1)
    }

    func testDateByAddingDays() {
        let today = startOfDay()
        let inFiveDays = dateByAddingDays(5, to: today)
        let diff = Calendar.current.dateComponents([.day], from: today, to: inFiveDays)
        XCTAssertEqual(diff.day, 5)
    }

    func testDateByAddingNegativeDays() {
        let today = startOfDay()
        let fiveDaysAgo = dateByAddingDays(-5, to: today)
        let diff = Calendar.current.dateComponents([.day], from: fiveDaysAgo, to: today)
        XCTAssertEqual(diff.day, 5)
    }
}

final class FormattedEventTests: XCTestCase {

    func makeEvent(title: String = "Test", isAllDay: Bool = false,
                   location: String? = nil, notes: String? = nil,
                   url: String? = nil, calendar: String = "Work",
                   startDate: Date? = nil, endDate: Date? = nil) -> FormattedEvent {
        let start = startDate ?? Date()
        let end = endDate ?? start.addingTimeInterval(3600)
        return FormattedEvent(
            title: title, startDate: start, endDate: end,
            isAllDay: isAllDay, location: location, notes: notes,
            url: url, calendarTitle: calendar, calendarColor: nil
        )
    }

    func testFilterAllDayEvents() {
        let events = [
            makeEvent(title: "Regular", isAllDay: false),
            makeEvent(title: "All Day", isAllDay: true),
        ]
        let filtered = events.filter { !$0.isAllDay }
        XCTAssertEqual(filtered.count, 1)
        XCTAssertEqual(filtered.first?.title, "Regular")
    }

    func testSortByStartDate() {
        let now = Date()
        let events = [
            makeEvent(title: "Later", startDate: now.addingTimeInterval(7200)),
            makeEvent(title: "Earlier", startDate: now.addingTimeInterval(3600)),
            makeEvent(title: "First", startDate: now),
        ]
        let sorted = events.sorted { $0.startDate < $1.startDate }
        XCTAssertEqual(sorted.map(\.title), ["First", "Earlier", "Later"])
    }

    func testLimitEvents() {
        let now = Date()
        let events = (0..<10).map { i in
            makeEvent(title: "Event \(i)", startDate: now.addingTimeInterval(Double(i) * 3600))
        }
        let limited = Array(events.prefix(3))
        XCTAssertEqual(limited.count, 3)
    }

    func testNotesTruncation() {
        let longNotes = String(repeating: "a", count: 300)
        let truncated = longNotes.count > 200 ? String(longNotes.prefix(200)) + "..." : longNotes
        XCTAssertEqual(truncated.count, 203) // 200 chars + "..."
        XCTAssertTrue(truncated.hasSuffix("..."))
    }

    func testShortNotesNotTruncated() {
        let shortNotes = "Quick meeting notes"
        let result = shortNotes.count > 200 ? String(shortNotes.prefix(200)) + "..." : shortNotes
        XCTAssertEqual(result, shortNotes)
    }
}

final class CalendarTypeStringTests: XCTestCase {

    func testAllTypes() {
        let buddy = CalBuddy()
        XCTAssertEqual(buddy.calendarTypeString(.local), "Local")
        XCTAssertEqual(buddy.calendarTypeString(.calDAV), "CalDAV")
        XCTAssertEqual(buddy.calendarTypeString(.exchange), "Exchange")
        XCTAssertEqual(buddy.calendarTypeString(.subscription), "Subscription")
        XCTAssertEqual(buddy.calendarTypeString(.birthday), "Birthday")
    }
}
