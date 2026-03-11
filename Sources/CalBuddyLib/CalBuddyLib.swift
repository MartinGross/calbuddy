import EventKit
import Foundation

// MARK: - Configuration

public struct Config {
    public var separateByCalendar = false
    public var separateByDate = false
    public var includeCals: [String] = []
    public var excludeCals: [String] = []
    public var includeAllDayEvents = true
    public var noCalendarNames = false
    public var bulletPoint = "• "
    public var dateFormat = "yyyy-MM-dd"
    public var timeFormat = "HH:mm"
    public var limitItems = 0
    public var propertyOrder: [String] = ["title", "datetime", "location", "notes", "url", "calendar"]
    public var noPropNames = false
    public var output: OutputFormat = .plain

    public enum OutputFormat: String {
        case plain
        case json
    }

    public init() {}
}

// MARK: - Event Formatting

public struct FormattedEvent {
    public let title: String
    public let startDate: Date
    public let endDate: Date
    public let isAllDay: Bool
    public let location: String?
    public let notes: String?
    public let url: String?
    public let calendarTitle: String
    public let calendarColor: String?

    public init(title: String, startDate: Date, endDate: Date, isAllDay: Bool,
                location: String?, notes: String?, url: String?,
                calendarTitle: String, calendarColor: String?) {
        self.title = title
        self.startDate = startDate
        self.endDate = endDate
        self.isAllDay = isAllDay
        self.location = location
        self.notes = notes
        self.url = url
        self.calendarTitle = calendarTitle
        self.calendarColor = calendarColor
    }
}

// MARK: - CalBuddy

public class CalBuddy {
    public let store = EKEventStore()
    public var config = Config()

    public init() {}

    public func requestAccess() async -> Bool {
        do {
            if #available(macOS 14.0, *) {
                return try await store.requestFullAccessToEvents()
            } else {
                return try await store.requestAccess(to: .event)
            }
        } catch {
            printError("Failed to request calendar access: \(error.localizedDescription)")
            return false
        }
    }

    public func calendars() -> [EKCalendar] {
        var cals = store.calendars(for: .event)

        if !config.includeCals.isEmpty {
            cals = cals.filter { cal in
                config.includeCals.contains(where: {
                    cal.title.localizedCaseInsensitiveContains($0)
                })
            }
        }

        if !config.excludeCals.isEmpty {
            cals = cals.filter { cal in
                !config.excludeCals.contains(where: {
                    cal.title.localizedCaseInsensitiveContains($0)
                })
            }
        }

        return cals
    }

    public func fetchEvents(from startDate: Date, to endDate: Date) -> [FormattedEvent] {
        let cals = calendars()
        guard !cals.isEmpty else { return [] }

        let predicate = store.predicateForEvents(withStart: startDate, end: endDate, calendars: cals)
        let events = store.events(matching: predicate)

        var formatted = events.map { event in
            FormattedEvent(
                title: event.title ?? "(No title)",
                startDate: event.startDate,
                endDate: event.endDate,
                isAllDay: event.isAllDay,
                location: event.location,
                notes: event.notes,
                url: event.url?.absoluteString,
                calendarTitle: event.calendar.title,
                calendarColor: nil
            )
        }

        if !config.includeAllDayEvents {
            formatted = formatted.filter { !$0.isAllDay }
        }

        formatted.sort { $0.startDate < $1.startDate }

        if config.limitItems > 0 {
            formatted = Array(formatted.prefix(config.limitItems))
        }

        return formatted
    }

    // MARK: - Output

    public func printEvents(_ events: [FormattedEvent]) {
        guard !events.isEmpty else {
            print("No events.")
            return
        }

        switch config.output {
        case .json:
            printJSON(events)
        case .plain:
            printPlain(events)
        }
    }

    public func printPlain(_ events: [FormattedEvent]) {
        let df = DateFormatter()
        df.dateFormat = config.dateFormat
        let tf = DateFormatter()
        tf.dateFormat = config.timeFormat

        if config.separateByDate {
            let grouped = Dictionary(grouping: events) { df.string(from: $0.startDate) }
            for date in grouped.keys.sorted() {
                print("\n\(date):")
                for event in grouped[date]! {
                    printSingleEvent(event, dateFormatter: df, timeFormatter: tf)
                }
            }
        } else if config.separateByCalendar {
            let grouped = Dictionary(grouping: events) { $0.calendarTitle }
            for cal in grouped.keys.sorted() {
                print("\n\(cal):")
                for event in grouped[cal]! {
                    printSingleEvent(event, dateFormatter: df, timeFormatter: tf)
                }
            }
        } else {
            for event in events {
                printSingleEvent(event, dateFormatter: df, timeFormatter: tf)
            }
        }
    }

    public func printSingleEvent(_ event: FormattedEvent, dateFormatter df: DateFormatter, timeFormatter tf: DateFormatter) {
        var parts: [String] = []

        for prop in config.propertyOrder {
            switch prop {
            case "title":
                parts.append(event.title)
            case "datetime":
                if event.isAllDay {
                    parts.append(config.noPropNames ? df.string(from: event.startDate) : "date: \(df.string(from: event.startDate)) (all day)")
                } else {
                    let timeStr = "\(tf.string(from: event.startDate)) - \(tf.string(from: event.endDate))"
                    parts.append(config.noPropNames ? timeStr : "time: \(timeStr)")
                }
            case "location":
                if let loc = event.location, !loc.isEmpty {
                    parts.append(config.noPropNames ? loc : "location: \(loc)")
                }
            case "notes":
                if let notes = event.notes, !notes.isEmpty {
                    let truncated = notes.count > 200 ? String(notes.prefix(200)) + "..." : notes
                    parts.append(config.noPropNames ? truncated : "notes: \(truncated)")
                }
            case "url":
                if let url = event.url {
                    parts.append(config.noPropNames ? url : "url: \(url)")
                }
            case "calendar":
                if !config.noCalendarNames {
                    parts.append(config.noPropNames ? event.calendarTitle : "calendar: \(event.calendarTitle)")
                }
            default:
                break
            }
        }

        let title = parts.isEmpty ? event.title : parts.removeFirst()
        print("\(config.bulletPoint)\(title)")
        for part in parts {
            print("    \(part)")
        }
    }

    public func printJSON(_ events: [FormattedEvent]) {
        let df = ISO8601DateFormatter()
        let items = events.map { event -> [String: Any] in
            var dict: [String: Any] = [
                "title": event.title,
                "startDate": df.string(from: event.startDate),
                "endDate": df.string(from: event.endDate),
                "isAllDay": event.isAllDay,
                "calendar": event.calendarTitle
            ]
            if let loc = event.location { dict["location"] = loc }
            if let notes = event.notes { dict["notes"] = notes }
            if let url = event.url { dict["url"] = url }
            return dict
        }

        if let data = try? JSONSerialization.data(withJSONObject: items, options: .prettyPrinted),
           let str = String(data: data, encoding: .utf8) {
            print(str)
        }
    }

    public func printCalendars() {
        let cals = store.calendars(for: .event)
        guard !cals.isEmpty else {
            printError("No calendars found. Check calendar permissions in System Settings → Privacy & Security → Calendars.")
            return
        }

        switch config.output {
        case .json:
            let items = cals.map { ["title": $0.title, "type": calendarTypeString($0.type), "source": $0.source.title] }
            if let data = try? JSONSerialization.data(withJSONObject: items, options: .prettyPrinted),
               let str = String(data: data, encoding: .utf8) {
                print(str)
            }
        case .plain:
            for cal in cals.sorted(by: { $0.title < $1.title }) {
                print("\(config.bulletPoint)\(cal.title) (\(calendarTypeString(cal.type)), \(cal.source.title))")
            }
        }
    }

    public func calendarTypeString(_ type: EKCalendarType) -> String {
        switch type {
        case .local: return "Local"
        case .calDAV: return "CalDAV"
        case .exchange: return "Exchange"
        case .subscription: return "Subscription"
        case .birthday: return "Birthday"
        @unknown default: return "Unknown"
        }
    }
}

// MARK: - Date Helpers

public func startOfDay(_ date: Date = Date()) -> Date {
    Calendar.current.startOfDay(for: date)
}

public func endOfDay(_ date: Date = Date()) -> Date {
    Calendar.current.date(byAdding: .day, value: 1, to: startOfDay(date))!
}

public func startOfTomorrow() -> Date {
    Calendar.current.date(byAdding: .day, value: 1, to: startOfDay())!
}

public func dateByAddingDays(_ days: Int, to date: Date = Date()) -> Date {
    Calendar.current.date(byAdding: .day, value: days, to: startOfDay(date))!
}

// MARK: - CLI

public func printError(_ message: String) {
    FileHandle.standardError.write("error: \(message)\n".data(using: .utf8)!)
}

public func printUsage() {
    let usage = """
    calbuddy - a modern replacement for icalBuddy using EventKit

    USAGE:
        calbuddy <command> [options]

    COMMANDS:
        eventsToday                 Show today's events
        eventsTomorrow              Show tomorrow's events
        eventsFrom:<start> to:<end> Show events in date range (yyyy-MM-dd)
        eventsNow                   Show currently ongoing events
        calendars                   List available calendars
        help                        Show this help

    OPTIONS:
        -ic, --include-cals <cal1,cal2>   Only show events from these calendars
        -ec, --exclude-cals <cal1,cal2>   Exclude events from these calendars
        -sc, --separate-by-calendar       Group events by calendar
        -sd, --separate-by-date           Group events by date
        -ea, --exclude-all-day            Exclude all-day events
        -nc, --no-calendar-names          Hide calendar names
        -np, --no-prop-names              Hide property labels
        -b,  --bullet <string>            Set bullet point string (default: "• ")
        -df, --date-format <format>       Date format (default: yyyy-MM-dd)
        -tf, --time-format <format>       Time format (default: HH:mm)
        -n,  --limit <number>             Limit number of events shown
        -f,  --format <plain|json>        Output format (default: plain)

    EXAMPLES:
        calbuddy eventsToday
        calbuddy eventsToday --format json
        calbuddy eventsFrom:2024-01-01 to:2024-01-31
        calbuddy calendars
        calbuddy eventsToday -ic "Work,Personal" --exclude-all-day
    """
    print(usage)
}

public func parseArgs(_ args: [String]) -> (command: String, startDate: Date?, endDate: Date?, config: Config) {
    var config = Config()
    var command = ""
    var startDate: Date? = nil
    var endDate: Date? = nil

    var i = 0
    while i < args.count {
        let arg = args[i]

        switch arg {
        case "eventsToday", "eventsTomorrow", "eventsNow", "calendars", "help":
            command = arg

        case _ where arg.hasPrefix("eventsFrom:"):
            command = "eventsRange"
            let dateStr = String(arg.dropFirst("eventsFrom:".count))
            let df = DateFormatter()
            df.dateFormat = "yyyy-MM-dd"
            startDate = df.date(from: dateStr)

        case _ where arg.hasPrefix("to:"):
            let dateStr = String(arg.dropFirst("to:".count))
            let df = DateFormatter()
            df.dateFormat = "yyyy-MM-dd"
            if let d = df.date(from: dateStr) {
                endDate = Calendar.current.date(byAdding: .day, value: 1, to: d)
            }

        case "-ic", "--include-cals":
            i += 1
            if i < args.count {
                config.includeCals = args[i].split(separator: ",").map(String.init)
            }

        case "-ec", "--exclude-cals":
            i += 1
            if i < args.count {
                config.excludeCals = args[i].split(separator: ",").map(String.init)
            }

        case "-sc", "--separate-by-calendar":
            config.separateByCalendar = true

        case "-sd", "--separate-by-date":
            config.separateByDate = true

        case "-ea", "--exclude-all-day":
            config.includeAllDayEvents = false

        case "-nc", "--no-calendar-names":
            config.noCalendarNames = true

        case "-np", "--no-prop-names":
            config.noPropNames = true

        case "-b", "--bullet":
            i += 1
            if i < args.count { config.bulletPoint = args[i] }

        case "-df", "--date-format":
            i += 1
            if i < args.count { config.dateFormat = args[i] }

        case "-tf", "--time-format":
            i += 1
            if i < args.count { config.timeFormat = args[i] }

        case "-n", "--limit":
            i += 1
            if i < args.count { config.limitItems = Int(args[i]) ?? 0 }

        case "-f", "--format":
            i += 1
            if i < args.count { config.output = Config.OutputFormat(rawValue: args[i]) ?? .plain }

        default:
            if !arg.hasPrefix("-") && command.isEmpty {
                command = arg
            }
        }

        i += 1
    }

    return (command, startDate, endDate, config)
}
