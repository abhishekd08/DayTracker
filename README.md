# Tracker

A single-screen SwiftUI workout tracker for iOS 18. Log each exercise with sets, reps, and optional weight. History cards can be edited inline, filtered by date, and exported as JSON for backups.

## Features
- Fast entry form with exercise suggestions from a predefined list
- Workout history displayed as tappable cards you can edit or delete
- Date filter with a compact calendar picker
- JSON export via the iOS share sheet (e.g., Files, AirDrop)

## Requirements
- Xcode 16.4 or later
- iOS 18.0 deployment target

## Getting Started
1. Open `Tracker.xcodeproj` in Xcode.
2. Select the `Tracker` scheme and build/run on an iOS 18 simulator or device.
3. Use the add form to log exercises, filter history using the calendar button, and export with the share button in the navigation bar.

## Notes
- Data is saved locally under the app's Application Support directory. Removing the app will delete the log; export it first if you need a backup.
- Customize the exercise suggestions by editing `ExerciseCatalog.swift`.
