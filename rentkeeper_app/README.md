# RentKeeper — Standalone Flutter Mobile App

An operational rental and dispatch ledger application designed for commercial rental businesses (camera kits, sound/PA, generators, stage lighting, and rigging). Engineered to be 100% offline-first and self-contained with zero external backend dependencies.

---

## 📱 Features

- **Operational Pulse & Dashboard**: Live KPI cards (Asset Base, Ready to Dispatch, Active Challans, Overdue Returns), revenue tracking in Pakistani Rupee (Rs.), and POS quick counter shortcuts.
- **Equipment Inventory**: Manage equipment stock, available/rented counters, daily rental rates, replacement values, barcode/serial numbers, categories, and condition tracking.
- **Rental Challans & Dispatch**:
  - Multi-item dispatch with quantity & rental day calculation.
  - Automatic security deposit calculation (held liability).
  - Advance payment and pending balance tracking.
  - Return date scheduling and overdue tracking.
- **Equipment Return Check-in**:
  - One-tap return check-in with damage fee and late fee recording.
  - Automatic inventory stock restoration.
  - Security deposit release/refund calculation.
- **Client Ledger & Directory**: Customer directory with CNIC, contact phone, active rentals, and outstanding balance ledger. Direct Call and WhatsApp alert shortcuts.
- **Local Persistence**: Stores everything offline on the device via local storage, persisting across app restarts.
- **Enterprise Settings**: Customizable business profile (shop name, city, operator), currency, and one-tap data clear or reset.

---

## 🚀 Running the Mobile App

### Quick Launch (Batch Script):
Simply double-click:
```powershell
.\run_mobile_app.bat
```

### Or Run from Terminal:
```powershell
cd rentkeeper_app

# 1. Fetch dependencies
flutter pub get

# 2. Run on connected Android phone / emulator
flutter run

# 3. Or run mobile preview in Chrome
flutter run -d chrome

# 4. Or build the Android APK
flutter build apk --debug
```
Output APK location:
`rentkeeper_app\build\app\outputs\flutter-apk\app-debug.apk`
