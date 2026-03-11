# calbuddy

A modern replacement for [icalBuddy](https://github.com/ali-rantakari/icalBuddy) built with Swift and EventKit.

Solves the common "No calendars" error on modern macOS by using Apple's EventKit framework, which correctly handles calendar permissions.

## Requirements

- macOS 13 (Ventura) or later
- Swift 5.9+
- Xcode Command Line Tools

## Build & Install

```bash
# Build
swift build

# Build release version
make release

# Install to /usr/local/bin
make install

# Or install to custom location
make install PREFIX=~/.local
```

## Usage

```bash
# Show today's events
calbuddy eventsToday

# Show tomorrow's events
calbuddy eventsTomorrow

# Show currently ongoing events
calbuddy eventsNow

# Show events in a date range
calbuddy eventsFrom:2024-01-01 to:2024-01-31

# List all calendars
calbuddy calendars

# JSON output
calbuddy eventsToday --format json

# Filter by calendar
calbuddy eventsToday --include-cals "Work,Personal"
calbuddy eventsToday --exclude-cals "Birthdays"

# Group by date or calendar
calbuddy eventsToday --separate-by-date
calbuddy eventsToday --separate-by-calendar

# Exclude all-day events
calbuddy eventsToday --exclude-all-day

# Limit number of events
calbuddy eventsToday --limit 5
```

## Migrating from icalBuddy

| icalBuddy | calbuddy |
|-----------|----------|
| `icalBuddy eventsToday` | `calbuddy eventsToday` |
| `icalBuddy eventsToday+3` | `calbuddy eventsFrom:2024-01-01 to:2024-01-04` |
| `icalBuddy calendars` | `calbuddy calendars` |
| `-ic "Work"` | `--include-cals "Work"` |
| `-ec "Birthdays"` | `--exclude-cals "Birthdays"` |
| `-eep "notes"` | *(use property order)* |

## Calendar Permissions

On first run, macOS will prompt you to grant calendar access. You can also manage this in:

**System Settings → Privacy & Security → Calendars**

This is the key advantage over icalBuddy — EventKit handles the permission flow correctly on modern macOS.
