# Weight Tracker App

A Flutter application for tracking weight measurements with interactive charts and running averages.

## Features

- **Weight Entry**: Add weight measurements with date selection
- **Interactive Chart**: 14-day rolling chart showing individual measurements and 5-day running average
- **Data Management**: Edit and delete weight entries
- **Cross-Platform**: Works on Android, iOS, Web, Windows, macOS, and Linux
- **Sample Data**: Includes realistic sample data for testing (debug mode only)
- **Responsive Design**: Adapts to different screen sizes

## Screenshots

The app includes:
- Clean weight entry form with date picker
- Interactive chart with blue dots for measurements and red line for running average
- Comprehensive data table with edit/delete functionality
- Sample data generation for testing

## Technical Features

- **Database**: SQLite with platform-specific implementations
  - Mobile: `sqflite` package
  - Desktop: `sqflite_common_ffi` package  
  - Web: `shared_preferences` package
- **Charts**: `fl_chart` package for interactive visualizations
- **State Management**: Flutter's built-in StatefulWidget
- **Platform Detection**: Automatic platform-specific database initialization

## Getting Started

### Prerequisites

- Flutter SDK (latest stable version)
- Dart SDK
- Android Studio / VS Code with Flutter extensions

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
# For Android
flutter run

# For Web (Chrome)
flutter run -d chrome

# For Desktop
flutter run -d windows  # Windows
flutter run -d macos    # macOS
flutter run -d linux    # Linux
```

## Project Structure

```
lib/
├── main.dart                    # App entry point
├── models/
│   └── weight_entry.dart        # Weight entry data model
├── database/
│   └── database_helper.dart    # Database operations
├── services/
│   ├── storage_service.dart    # Web storage implementation
│   └── sample_data_service.dart # Sample data generation
├── screens/
│   └── weight_tracking_app.dart # Main app screen
└── widgets/
    ├── weight_entry_form.dart   # Weight input form
    └── weight_chart.dart        # Chart visualization
```

## Key Components

### Weight Entry Form
- Single-row layout with weight input, date picker, and add button
- Form validation for weight values
- Date selection with proper constraints

### Chart Visualization
- 14-day rolling window ending at latest measurement
- Blue dots for individual measurements
- Red line for 5-day running average
- Responsive design that scales to window width
- DD/MM date format on x-axis

### Data Management
- Complete CRUD operations (Create, Read, Update, Delete)
- Platform-aware database implementation
- Edit functionality with popup dialog
- Delete confirmation dialog

## Sample Data

In debug mode, the app automatically generates realistic sample data:
- 40 days of weight measurements
- Linear progression from 85kg to 80kg
- Random variance of ±0.5kg
- Skipped days and multiple measurements per day
- Regeneration capability for testing

## Dependencies

- `sqflite`: SQLite database for mobile platforms
- `sqflite_common_ffi`: SQLite database for desktop platforms
- `shared_preferences`: Web storage implementation
- `fl_chart`: Chart visualization library
- `intl`: Date formatting utilities
- `path`: File path utilities

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

- Flutter team for the excellent framework
- fl_chart package for beautiful chart visualizations
- SQLite team for the robust database engine