# DSWD SLP - Sari-Sari Store Management App

A Flutter-based mobile application for the Department of Social Welfare and Development (DSWD) Sustainable Livelihood Program (SLP). This app helps manage sari-sari store (small retail shop) operations including inventory, sales, expenses, and financial reporting.

## Features

### Authentication & Security
- PIN-based login system
- Biometric authentication support
- Account creation and management
- PIN change functionality

### Inventory Management
- Stock-in/Stock-out tracking
- Product catalog with 40+ pre-loaded items
- Product categories
- Low stock indicators

### Sales & Transactions
- Record daily sales
- Transaction history
- Sales reports

### Financial Management
- Income Statement
- Balance Sheet
- Cash Flow tracking
- Capital Management
- Expense tracking

### Customer Credit (Utang) Management
- Customer debt tracking
- Payment recording
- Customer debt summary
- Owner debt tracking (utang sa amo)

### Additional Features
- PDF report generation
- Chart visualizations
- Push notifications
- Region-based customer data (Region 7 - Central Visayas, Philippines)

## Technology Stack

- **Framework**: Flutter 3.9.2+
- **State Management**: Riverpod
- **Navigation**: Go Router
- **Database**: SQLite (sqflite)
- **Charts**: fl_chart
- **PDF Generation**: pdf
- **Authentication**: local_auth

## Project Structure

```
lib/
├── app_router.dart          # Application routing
├── main.dart               # App entry point
├── core/                   # Core utilities
│   ├── app_colors.dart     # Color definitions
│   ├── app_theme.dart      # Theme configuration
│   ├── page_transitions.dart
│   └── product_seed.dart   # Initial product data
├── data/                   # Data files
│   └── region7_psgc.dart   # Region 7 location data
├── models/                 # Data models
├── providers/              # Riverpod providers
├── repositories/           # Data repositories
├── services/               # Services (database, auth)
├── view_models/            # View models
└── views/
    ├── screens/            # UI screens
    └── widgets/            # Reusable widgets
```

## Getting Started

### Prerequisites
- Flutter SDK 3.9.2 or later
- Android SDK
- Xcode (for iOS development)

### Installation

1. Clone the repository
2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Run the app:
   ```bash
   flutter run
   ```

### Building APK

```bash
flutter build apk --debug
```

For release build:
```bash
flutter build apk --release
```

## Screenshots

The app includes the following main screens:
- Login / Create Account
- Home Dashboard
- Profile Management
- Stock In / Inventory
- Record Sales
- Transaction History
- Expenses
- Financial Reports (Income Statement, Balance Sheet, Cash Flow)
- Capital Management
- Customer Utang (Credit) Management
- Reports Generation

## Team Members

- Al Duane Mirasol
- Ashley Mae Tanio
- Jay Suizo
- Kristian Rusiana
- Lawrence Ivan Velchez
- Lhory Hiramis

## License

This project is developed for DSWD Sustainable Livelihood Program purposes.
