# Stark Group - Vehicle Management System (VMS)

A professional desktop-first administrative frontend for managing corporate fleet vehicles, built with **Flutter Web** and **Material 3** in the signature **Stark Group** industrial tech visual style. This project is strictly frontend-only at this stage, operating with in-memory reactive mock data and zero external API/database dependencies.

---

## 🚘 Fleet Asset Data Model

Every vehicle record contains the required 6 core fields:
1. **Vehicle Number**: Unique corporate identifier code (e.g., `STK-1001`, `STK-1002`).
2. **Company**: Assigned operating division (e.g., *Stark Logistics*, *Stark Security*, *Stark Industries*, *Stark Fleet Solutions*, *Stark Aviation Support*).
3. **Type**: Vehicle category (*Sedan*, *SUV*, *Truck*, *Van*, *Electric*).
4. **Brand**: Manufacturer / Make (e.g., *Audi*, *Tesla*, *Ford*, *Mercedes-Benz*, *BMW*, *Rivian*, *Porsche*, *Volvo*).
5. **Model**: Model designation (e.g., *e-tron GT*, *Model X Plaid*, *F-150 Lightning*, *Sprinter 3500*).
6. **Status**: Operational dispatch readiness (*Active*, *Maintenance*, *Inactive*).

---

## 🎨 Stark Group Visual Style & Architecture

- **Visual Aesthetics**: Deep slate navies (`#0F172A`), crisp white cards with 1px slate borders (`#E2E8F0`), electric Stark cyan-blue accents (`#0284C7`), and high-contrast typography. Full Dark Mode support is included.
- **Login Screen**: Centered responsive card with Stark brand emblem, accessible labels, clear validation, and a one-click demo credentials button.
- **Application Shell**:
  - Persistent 260px desktop sidebar with live fleet count badges and system status indicators.
  - Adaptive layout that gracefully collapses into a drawer on tablet and bottom navigation on mobile.
  - Top navigation bar with live theme switcher, user profile badge (*Tony Stark / Fleet Director*), and sign out modal.
- **Vehicle List Screen**:
  - Executive KPI cards (*Total Fleet*, *Active Fleet*, *Maintenance*, *Inactive*).
  - Search across Vehicle Number, Brand, Model, and Company.
  - Multi-dimensional filters by Status, Type, and Company.
  - Desktop `DataTable` with highlighted monospace Vehicle Number badges, status pills, and clear Edit/Delete actions.
  - Polished empty state with search reset actions.
- **Register / Edit Vehicle Form**:
  - 3 logically grouped cards: *Fleet Identification & Allocation*, *Vehicle Specifications*, and *Operational Status*.
  - Clean 2-column responsive grid on desktop/tablet, collapsing to 1 column on mobile.
  - Comprehensive form validation and floating feedback notifications.

---

## 📁 Directory Structure

```text
vms_frontend/
├── lib/
│   ├── core/
│   │   ├── constants/
│   │   │   └── app_constants.dart       # Stark Group branding, default companies, breakpoints
│   │   └── theme/
│   │       └── app_theme.dart           # Stark Group Material 3 light and dark theme specs
│   ├── data/
│   │   └── mock_vehicles.dart           # 10 realistic Stark Group fleet vehicle records
│   ├── models/
│   │   ├── user.dart                    # AppUser model & roles
│   │   └── vehicle.dart                 # Vehicle model (6 core fields), enums, JSON helpers
│   ├── screens/
│   │   ├── auth/
│   │   │   └── login_screen.dart        # Stark Group administrative login portal
│   │   ├── shell/
│   │   │   └── app_shell.dart           # Responsive navigation shell with sidebar & topbar
│   │   └── vehicles/
│   │       ├── vehicle_form_screen.dart # Grouped 2-column register & edit vehicle form
│   │       └── vehicle_list_screen.dart # Fleet directory table, filters, KPIs, and actions
│   ├── services/
│   │   ├── auth_service.dart            # In-memory reactive authentication state
│   │   └── vehicle_service.dart         # In-memory CRUD operations and fleet metrics
│   ├── widgets/
│   │   ├── confirmation_dialog.dart     # Modal confirmation for delete actions
│   │   ├── responsive_layout.dart       # Responsive breakpoint utilities
│   │   ├── stat_card.dart               # Executive metric cards
│   │   └── vehicle_status_badge.dart    # High-contrast Active, Maintenance, Inactive chips
│   └── main.dart                        # Application entrypoint & theme routing
└── test/
    ├── vehicle_model_test.dart          # Unit tests for domain models & JSON serialization
    ├── vehicle_service_test.dart        # Unit tests for in-memory fleet operations & filtering
    └── widget_test.dart                 # UI smoke tests for login and navigation shell
```

---

## 🚀 Running and Verifying

### Run Locally
```bash
cd vms_frontend

# Connect to local Spring Boot backend (default: http://localhost:8080)
flutter run -d chrome

# Or customize the API backend URL:
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:8080

# Or test with a local web server:
flutter run -d web-server --web-port=8082
```

### Build for Production Web
```bash
# Production web build with custom API URL:
flutter build web --dart-define=API_BASE_URL=https://api.yourdomain.com
```

### Run Static Analysis and Test Suite
```bash
flutter analyze
flutter test
```

### Demo Credentials
- **Email**: `admin@starkgroup.com`
- **Password**: `stark123`
*(Or click "Use Stark Demo Credentials" directly on the login screen)*
