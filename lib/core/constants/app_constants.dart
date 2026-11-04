/// Application-wide constants for Stark Group VMS branding and responsive layout breakpoints.
class AppConstants {
  AppConstants._();

  static const String appName = 'Vehicle Management System';
  static const String companyBrand = 'STARK GROUP';
  static const String appSubtitle = 'Fleet Operations Console';
  static const String appVersion = 'v1.0.0-PROD';

  // Responsive breakpoints (in pixels)
  static const double mobileBreakpoint = 650.0;
  static const double tabletBreakpoint = 1024.0;

  // Maximum content width for desktop layout
  static const double maxContentWidth = 1280.0;
  static const double maxFormWidth = 840.0;

  // Standard Stark Group companies
  static const List<String> defaultCompanies = [
    'Stark Logistics',
    'Stark Security',
    'Stark Industries',
    'Stark Fleet Solutions',
    'Stark Aviation Support',
  ];
}
