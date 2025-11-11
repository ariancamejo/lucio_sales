# Lucio Sales

A Flutter-based sales and inventory management application with Supabase backend and offline-first architecture.

## 🌐 Live Demo

**Web App**: [https://ariancamejo.github.io/lucio_sales/](https://ariancamejo.github.io/lucio_sales/)

## ✨ Features

- 📦 **Product Management**: Track products with stock levels, prices, and measurement units
- 📊 **Stock Entries**: Record incoming stock with detailed history
- 📤 **Outputs/Sales**: Manage product outputs and sales transactions
- 📈 **Advanced Reports**:
  - Sales reports with trends and analytics
  - IPV (Inventory Product Value) reports
  - Low stock alerts and dead stock detection
- 🔄 **Offline-First**: Works without internet on native platforms (mobile/desktop)
- 🔐 **Row Level Security**: Multi-tenant architecture with user isolation
- 🔑 **Authentication**: Email/password and Google OAuth sign-in
- 🌓 **Dark Mode**: Support for light and dark themes
- 📱 **Cross-Platform**: Web, iOS, Android, macOS, Windows, Linux
- 🎨 **Responsive Design**: Optimized for all screen sizes

## 🛠️ Tech Stack

### Frontend
- **Flutter 3.24+** - Cross-platform UI framework
- **BLoC Pattern** - State management with flutter_bloc
- **Go Router** - Declarative routing
- **Freezed** - Code generation for immutable classes
- **Drift** - Local SQLite database (native platforms)

### Backend
- **Supabase** - Backend as a Service
  - PostgreSQL database
  - Authentication (Email/Password, OAuth)
  - Row Level Security (RLS)
  - Real-time subscriptions

### Architecture
- **Clean Architecture** - Separation of concerns
- **Offline-First** - Local database with automatic sync
- **Repository Pattern** - Abstract data sources
- **Dependency Injection** - Get_it for DI

## 📋 Prerequisites

- Flutter SDK (3.24 or higher)
- Dart SDK (3.5 or higher)
- Supabase account and project
- Git

## 🚀 Quick Start

1. **Clone the repository**
   ```bash
   git clone https://github.com/ariancamejo/lucio_sales.git
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
   ```env
   SUPABASE_URL=https://your-project.supabase.co
   SUPABASE_ANON_KEY=your_supabase_anon_key
   ```

4. **Generate code**

   This step is **required** as generated files (*.g.dart, *.freezed.dart) are not committed:
   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```

5. **Configure Supabase (Required for Authentication)**

   See the [Supabase Setup](#-supabase-setup) section below.

6. **Run the app**

   For web (with custom port):
   ```bash
   flutter run -d chrome --web-port 8080
   ```

   For native platforms:
   ```bash
   flutter run -d macos  # or windows, linux
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

## 🗄️ Database Schema

The app uses Supabase PostgreSQL with the following main tables:
- `measurement_units` - Units of measurement (kg, liters, etc.)
- `products` - Product catalog with pricing and stock
- `product_entries` - Stock incoming history
- `output_types` - Types of outputs (sales, waste, etc.)
- `outputs` - Product outgoing transactions
- `user_history` - Audit trail for user actions

All tables include Row Level Security (RLS) policies for multi-tenant isolation.

## 🔐 Supabase Setup

### 1. Create Database Tables

Run the SQL migrations in the `supabase/migrations` directory or manually create the tables:
- `measurement_units` - Units of measurement (kg, liters, etc.)
- `products` - Product catalog with pricing and stock
- `product_entries` - Stock incoming history
- `output_types` - Types of outputs (sales, waste, etc.)
- `outputs` - Product outgoing transactions
- `user_history` - Audit trail for user actions

### 2. Configure Row Level Security (RLS)

**CRITICAL**: Enable RLS to ensure users only see their own data.

Go to **SQL Editor** in your Supabase dashboard and run:

```sql
-- Enable RLS on all tables
ALTER TABLE measurement_units ENABLE ROW LEVEL SECURITY;
ALTER TABLE products ENABLE ROW LEVEL SECURITY;
ALTER TABLE product_entries ENABLE ROW LEVEL SECURITY;
ALTER TABLE output_types ENABLE ROW LEVEL SECURITY;
ALTER TABLE outputs ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_history ENABLE ROW LEVEL SECURITY;

-- Policies for measurement_units
CREATE POLICY "Users can view their own measurement units"
  ON measurement_units FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can create their own measurement units"
  ON measurement_units FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own measurement units"
  ON measurement_units FOR UPDATE
  USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own measurement units"
  ON measurement_units FOR DELETE
  USING (auth.uid() = user_id);

-- Similar policies for other tables (products, product_entries, output_types, outputs, user_history)
-- See DEPLOYMENT.md for the complete RLS setup script
```

**Benefits of RLS:**
- Database-level security (cannot be bypassed)
- Multi-tenant data isolation
- Defense in depth with application-level filtering

### 3. Configure OAuth Redirect URLs

For Google Sign-In to work, add these URLs in **Authentication → URL Configuration**:

**Site URL:**
```
https://ariancamejo.github.io/lucio_sales/
```

**Redirect URLs:**
```
http://localhost:8080
http://localhost:8080/
http://localhost:8080/auth/callback
http://localhost:8080/login-callback
https://ariancamejo.github.io/lucio_sales/
https://ariancamejo.github.io/lucio_sales/auth/callback
https://ariancamejo.github.io/lucio_sales/login-callback
```

## 🏗️ Building for Production

### Web
```bash
flutter build web --release
```

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

### Windows
```bash
flutter build windows --release
```

### Linux
```bash
flutter build linux --release
```

## 🚀 Deployment

### GitHub Pages (Automatic)

The app automatically deploys to GitHub Pages on every push to `main`.

**Live URL**: https://ariancamejo.github.io/lucio_sales/

See [DEPLOYMENT.md](DEPLOYMENT.md) for detailed deployment instructions including:
- Configuring GitHub Secrets
- Setting up GitHub Pages
- Configuring Supabase URLs

### Manual Deployment

Build for web and deploy to any static hosting:
```bash
flutter build web --release --base-href "/your-app-path/"
```

Then upload the `build/web` directory to your hosting provider.

## 🔄 Offline-First Architecture

### Native Platforms (Mobile/Desktop)
- Uses **Drift** (SQLite) for local storage
- Automatic background sync when online
- Works completely offline
- Conflict resolution with last-write-wins

### Web Platform
- Online-only (no local database)
- Direct connection to Supabase
- All features available (including statistics)

## 📝 Development Workflow

### Running Code Generation

After modifying any models or entities:
```bash
dart run build_runner build --delete-conflicting-outputs
```

### Development Best Practices

1. **Code Generation**: Run build_runner after modifying any `@freezed` or `@JsonSerializable` classes
2. **Testing**: Test on both web and native platforms as they have different implementations
3. **Sync Testing**: Test offline-first functionality on native platforms
4. **Security**: Always filter data by `user_id` in remote datasources
5. **RLS**: Ensure Row Level Security policies are in place before deploying

## 🔒 Security

⚠️ **Important**: Never commit sensitive information like API keys, passwords, or credentials.

**Security Measures:**
- `.env` files for secrets (already in `.gitignore`)
- Row Level Security (RLS) policies on all Supabase tables
- User-based data filtering in all remote datasources
- Authentication required for all data operations
- PKCE flow for OAuth authentication

## 🤝 Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Make your changes and run code generation if needed
4. Test on both web and native platforms
5. Commit your changes (`git commit -m 'Add some amazing feature'`)
6. Push to the branch (`git push origin feature/amazing-feature`)
7. Open a Pull Request

## License

This project is private and proprietary.

## Support

For support, please contact the development team.
