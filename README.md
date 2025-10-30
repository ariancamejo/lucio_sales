# Lucio Sales

A Flutter-based sales and inventory management application with Supabase backend.

## Features

- 📦 **Product Management**: Track products with stock levels, prices, and measurement units
- 📊 **Stock Entries**: Record incoming stock with detailed history
- 📤 **Outputs/Sales**: Manage product outputs and sales transactions
- 📈 **Reports**: Sales reports and IPV (Inventory Product Value) reports
- 🔄 **Real-time Sync**: Automatic synchronization with Supabase
- 🌓 **Dark Mode**: Support for light and dark themes
- 📱 **Responsive**: Works on mobile, tablet, and desktop

## Tech Stack

- **Flutter** - Cross-platform UI framework
- **Supabase** - Backend as a Service (PostgreSQL database, Authentication, Real-time)
- **BLoC** - State management pattern
- **Get_it** - Dependency injection
- **Freezed** - Code generation for immutable classes

## Prerequisites

- Flutter SDK (3.0 or higher)
- Dart SDK
- Supabase account and project

## Setup

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd lucio_sales
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure environment variables**

   Copy `.env.example` to `.env` and fill in your Supabase credentials:
   ```bash
   cp .env.example .env
   ```

   Edit `.env` with your values:
   ```
   SUPABASE_URL=your_supabase_project_url
   SUPABASE_ANON_KEY=your_supabase_anon_key
   ```

4. **Generate required files**

   This step is **required** as generated files (*.g.dart, *.freezed.dart) are not committed to the repository:
   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```

5. **Run the app**
   ```bash
   flutter run
   ```

## Project Structure

```
lib/
├── core/                   # Core functionality
│   ├── di/                # Dependency injection
│   ├── errors/            # Error handling
│   ├── services/          # Services (auth, sync)
│   └── utils/             # Utilities
├── data/                  # Data layer
│   ├── datasources/       # Remote and local data sources
│   ├── models/            # Data models
│   └── repositories/      # Repository implementations
├── domain/                # Domain layer
│   ├── entities/          # Business entities
│   └── repositories/      # Repository interfaces
└── presentation/          # Presentation layer
    ├── blocs/             # BLoC state management
    ├── screens/           # UI screens
    └── widgets/           # Reusable widgets
```

## Database Schema

The app uses Supabase PostgreSQL with the following main tables:
- `measurement_units` - Units of measurement (kg, liters, etc.)
- `products` - Product catalog
- `product_entries` - Stock incoming history
- `output_types` - Types of outputs (sales, waste, etc.)
- `outputs` - Product outgoing transactions

## Building for Production

### Android
```bash
flutter build apk --release
```

### iOS
```bash
flutter build ios --release
```

### macOS
```bash
flutter build macos --release
```

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## Security

⚠️ **Important**: Never commit sensitive information like API keys, passwords, or credentials.
- Use `.env` files for secrets (already in `.gitignore`)
- Use `.env.example` to document required environment variables
- Review changes before committing

## License

This project is private and proprietary.

## Support

For support, please contact the development team.
