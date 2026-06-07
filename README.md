# WeightGraph: Moving Average Chart

A Flutter application for tracking weight measurements with interactive charts, configurable running averages, and CSV import/export.

## Features

- **Weight Entry**: Add measurements with a date picker and form validation
- **Interactive Chart**: Pan and zoom a time-series chart of individual measurements and a running average
- **Entry Table**: Browse, edit, and delete entries with running averages shown per row
- **Settings**: Configure weight unit label, date format, and average period
- **Import / Export**: Back up and restore data as CSV files
- **Cross-Platform**: Android, iOS, Web, Windows, macOS, and Linux
- **Sample Data**: Realistic debug-only sample data when the database is empty
- **Responsive Design**: Layout adapts to different screen sizes

## Technical Features

- **Database**: Platform-aware persistence
  - Mobile: `sqflite`
  - Desktop: `sqflite_common_ffi`
  - Web: `shared_preferences` via `StorageService`
- **Settings Storage**: `shared_preferences` (all platforms)
- **Charts**: `fl_chart` with a custom `fl_chart_viewport` module for pan/zoom and axis scaling
- **State Management**: `provider` with `SettingsProvider`; screen-level state in `StatefulWidget`
- **Import / Export**: `file_picker` for CSV file selection and save dialogs

## Getting Started

### Prerequisites

- Flutter SDK (latest stable version)
- Dart SDK (^3.8.1)
- Android Studio or VS Code with Flutter extensions

### Installation

1. Clone the repository:

```bash
git clone https://github.com/moh-mhtech/Weight-Tracker-App.git
cd Weight-Tracker-App
```

2. Install dependencies:

```bash
flutter pub get
```

3. Run the app:

```bash
# Default device
flutter run

# Web (Chrome)
flutter run -d chrome

# Desktop
flutter run -d windows   # Windows
flutter run -d macos     # macOS
flutter run -d linux     # Linux
```

4. Build the app:

```bash
# Android debug APK
flutter build apk --debug

# Release (Including fast copy)
flutter build apk --release --target-platform android-arm64 --no-tree-shake-icons; Copy-Item build\app\outputs\flutter-apk\app-release.apk "C:\Users\mlhil\Dropbox\Apps\weightgraph.apk"

# Android App Bundle
flutter build appbundle --release
```

### Running Tests

```bash
flutter test
```

## Project Structure

```
lib/
├── main.dart                          # App entry point and theme
├── models/
│   └── weight_entry.dart              # Weight entry data model
├── database/
│   └── database_helper.dart           # CRUD and platform-aware storage
├── providers/
│   └── settings_provider.dart         # User settings (Provider)
├── services/
│   ├── storage_service.dart           # Web storage implementation
│   ├── sample_data_service.dart       # Debug sample data generation
│   ├── average_calculation_service.dart  # Running average logic
│   ├── chart_viewport_service.dart    # Chart axis and tick helpers
│   ├── csv_service.dart               # CSV parsing and export
│   └── import_export_service.dart     # File picker import/export
├── screens/
│   ├── home_screen.dart               # Main screen
│   └── settings_screen.dart           # Settings, import/export, clear data
├── widgets/
│   ├── weight_entry_form.dart         # Weight input form
│   ├── weight_chart.dart              # Chart visualization
│   ├── weight_entry_table.dart        # Entry list with edit/delete
│   └── axis_chart_scaffold_widget.dart
└── fl_chart_viewport/                 # Custom pan/zoom chart viewport
    ├── axis_chart_view_controller.dart
    ├── viewport_line_chart.dart
    └── ...
test/                                  # Unit and widget tests
```

## Key Components

### Weight Entry Form

- Single-row layout with weight input, date picker, and Add button
- Validation for positive numeric weight values
- Respects the selected weight unit label and date format from settings

### Chart Visualization

- Default 24-day visible time window ending at the latest measurement
- Green dots for individual measurements; orange curved line for the running average
- Horizontal pan and pinch-to-zoom
- Y-axis auto-scales to the visible date range
- X-axis labels use `dd MMM` format; tooltips show weight values
- Average line segments break across gaps longer than the configured average period

### Entry Table

- Newest entries first, paginated in batches of 15 with a Load More control
- Each row shows date, weight, running average, and edit/delete actions
- Edit and delete use confirmation dialogs

### Settings

- **Weight Unit**: Display label for `kg` or `lbs` (values are stored as entered)
- **Date Format**: `dd/MM/yyyy`, `MM/dd/yyyy`, or `yyyy-MM-dd`
- **Average Period**: Number of days used for the running average (default: 7)
- **Export Data**: Save all entries to CSV (`Date,Weight,Average` columns)
- **Import Data**: Add entries from a CSV file, with row-level error reporting
- **Clear All Data**: Delete all weight entries

## Sample Data

In debug mode, sample data is generated automatically when the database is empty:

- ~80 days of measurements spanning 90 kg to 80 kg
- Random variance of ±0.5 kg
- Skipped days, a multi-day gap, and multiple measurements on some days
- A `SAMPLES` badge appears in the app bar when 30+ entries are present

`SampleDataService.regenerateSampleData()` can replace existing sample data during development.

## Dependencies

| Package | Purpose |
|---------|---------|
| `sqflite` | SQLite on mobile |
| `sqflite_common_ffi` | SQLite on desktop |
| `shared_preferences` | Web weight storage and app settings |
| `fl_chart` | Chart rendering |
| `vector_math` | Chart transformation math |
| `provider` | Settings state management |
| `file_picker` | CSV import/export file dialogs |
| `intl` | Date formatting |
| `path` | Database file paths |

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## Acknowledgments

- Flutter team for the excellent framework
- `fl_chart` for chart visualizations
- SQLite for robust local storage
