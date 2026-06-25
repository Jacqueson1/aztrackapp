# AZTracking Flutter App

Welcome to the **AZTracking** Flutter application! This is the frontend mobile and web application for the AZTracking ecosystem, designed to interface seamlessly with the AZTracking Laravel backend API.

## Features

- **Role & Permission Management**: Comprehensive admin dashboard to create, view, edit, and safely delete roles with fine-grained permissions.
- **Customer Management**: Robust tools for viewing and managing customer data securely.
- **Order Tracking**: View, track, and update order statuses dynamically.
- **Feedback System**: Integrated feedback submission and reviewing for improved customer experience.
- **Dynamic API Integration**: Switch easily between local development (Laragon/localhost) and production environments.

## Project Structure

- `lib/screens/` - Contains all the UI screens for different features (Admin, Customer, Login, Splash, etc.).
- `lib/service/` - Contains services like `api_service.dart` for centralized handling of HTTP requests, tokens, and errors.
- `lib/theme/` - Contains app-wide theme definitions, typography, and color palettes.
- `lib/widgets/` - Reusable UI components and modals.

## Technical Details

- **Framework**: Flutter
- **Backend Architecture**: RESTful API via Laravel (utilizing Spatie for Roles/Permissions)
- **Networking**: Dart `http` package managed through a custom singleton `ApiService` to automate auth headers and base routing.

## Development Notes

- **API Requests**: Always use the `ApiService` for backend communication to ensure your bearer tokens are attached automatically.
- **Permissions**: The app's frontend dynamically adapts to the Spatie permissions returned by the backend API. Ensure your backend user has the appropriate roles (`admin`, `worker`, etc.) when testing features locally.

## Helpful Resources

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Flutter API Reference](https://docs.flutter.dev/reference/)
