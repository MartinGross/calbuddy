import Foundation
import CalBuddyLib

let buddy = CalBuddy()

let args = Array(CommandLine.arguments.dropFirst())

if args.isEmpty {
    printUsage()
    exit(0)
}

let parsed = parseArgs(args)
buddy.config = parsed.config

let semaphore = DispatchSemaphore(value: 0)

Task {
    let granted = await buddy.requestAccess()
    guard granted else {
        printError("Calendar access denied. Grant access in System Settings → Privacy & Security → Calendars.")
        exit(1)
    }

    switch parsed.command {
    case "eventsToday", "today":
        let events = buddy.fetchEvents(from: startOfDay(), to: endOfDay())
        buddy.printEvents(events)

    case "eventsTomorrow", "tomorrow":
        let start = startOfTomorrow()
        let end = endOfDay(start)
        let events = buddy.fetchEvents(from: start, to: end)
        buddy.printEvents(events)

    case "eventsNow", "now":
        let now = Date()
        let events = buddy.fetchEvents(from: startOfDay(), to: endOfDay())
            .filter { !$0.isAllDay && $0.startDate <= now && $0.endDate >= now }
        buddy.printEvents(events)

    case "eventsRange":
        guard let start = parsed.startDate, let end = parsed.endDate else {
            printError("Invalid date range. Use: eventsFrom:yyyy-MM-dd to:yyyy-MM-dd")
            exit(1)
        }
        let events = buddy.fetchEvents(from: start, to: end)
        buddy.printEvents(events)

    case "calendars":
        buddy.printCalendars()

    case "help":
        printUsage()

    default:
        printError("Unknown command: \(parsed.command)")
        printUsage()
        exit(1)
    }

    semaphore.signal()
}

semaphore.wait()
