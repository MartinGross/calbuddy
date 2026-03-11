# calbuddy

A modern replacement for [icalBuddy](https://github.com/ali-rantakari/icalBuddy) built with Swift and EventKit.

Solves the common "No calendars" error on modern macOS by using Apple's EventKit framework, which correctly handles calendar permissions.

## What is CalBuddy?

CalBuddy is a command-line tool that gives you direct access to your macOS calendars from the terminal. It reads events from all configured calendar accounts (iCloud, Google, Exchange, etc.) and displays them in a clean, readable format.

### Why is this useful?

- **Quick overview** — Check your schedule right from the terminal without opening the Calendar app
- **Scripting & automation** — Integrate calendar data into shell scripts, cron jobs, or workflow automations
- **AI integration** — With `--format json`, CalBuddy outputs structured calendar data that works perfectly as context for AI assistants (e.g. Claude, ChatGPT, or custom agents). This lets an AI know your schedule and help with planning
- **Status bars & dashboards** — Display upcoming events in tools like Raycast, BetterTouchTool, or tmux

## Usage

```bash
# Show today's events
calbuddy today

# Show tomorrow's events
calbuddy tomorrow

# Show currently ongoing events
calbuddy now

# Show events in a date range
calbuddy eventsFrom:2024-01-01 to:2024-01-31

# List all calendars
calbuddy calendars

# JSON output
calbuddy today --format json

# Filter by calendar
calbuddy today --include-cals "Work,Personal"
calbuddy today --exclude-cals "Birthdays"

# Group by date or calendar
calbuddy today --separate-by-date
calbuddy today --separate-by-calendar

# Exclude all-day events
calbuddy today --exclude-all-day

# Limit number of events
calbuddy today --limit 5
```

> **Note:** The longer forms `eventsToday`, `eventsTomorrow`, and `eventsNow` also work for backward compatibility.
## Install

### Homebrew

```bash
brew tap MartinGross/tap
brew install calbuddy
```

### From Source

Requires macOS 13+, Swift 5.9+, and Xcode Command Line Tools.

```bash
# Build release version
make release

# Install to /usr/local/bin
sudo make install

# Or install to custom location
make install PREFIX=~/.local
```

## Migrating from icalBuddy

| icalBuddy | calbuddy |
|-----------|----------|
| `icalBuddy eventsToday` | `calbuddy today` |
| `icalBuddy eventsToday+3` | `calbuddy eventsFrom:2024-01-01 to:2024-01-04` |
| `icalBuddy calendars` | `calbuddy calendars` |
| `-ic "Work"` | `--include-cals "Work"` |
| `-ec "Birthdays"` | `--exclude-cals "Birthdays"` |
| `-eep "notes"` | *(use property order)* |

## Calendar Permissions

On first run, macOS will prompt you to grant calendar access. You can also manage this in:

**System Settings → Privacy & Security → Calendars**

This is the key advantage over icalBuddy — EventKit handles the permission flow correctly on modern macOS.
