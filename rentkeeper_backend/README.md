# RentKeeper Operational Precision — Dart Backend Server

A production-ready, modular REST API backend written in Dart for **RentKeeper**, engineered for commercial rental enterprises (cameras, generators, banquet infrastructure, PA sound, and stage lighting).

---

## 🚀 Key Features

- **Standard Dart Execution:** High-performance REST service using standard `dart:io` with zero external pub dependencies required.
- **Transactional Persistence:** File-backed persistent storage in `data/rentkeeper_db.json` with ACID-like atomic mutations.
- **Domain Precision:** Built-in support for Pakistani Rupee (`Rs.`), Challan dispatch flows, security deposits held (non-revenue liabilities), and overdue tracking.
- **Offline-First Synchronization:** Endpoints for bi-directional SQLite delta sync (`/api/v1/sync/push` and `/api/v1/sync/pull`).
- **Automated WhatsApp Alerts:** Dedicated trigger endpoint for notifying clients with overdue gear or scheduled return reminders.

---

## 📦 Getting Started

### 1. Run Backend Server
```bash
# Navigate to backend directory
cd rentkeeper_backend

# Run server on default port (8080)
dart run bin/server.dart

# Or specify custom host/port:
dart run bin/server.dart --port=9000 --host=0.0.0.0
```

### 2. Run Automated Test Suite
```bash
dart run test/backend_test.dart
```

---

## 📡 REST API Reference

Base URL: `http://localhost:8080/api/v1`

| Method | Endpoint | Description |
|---|---|---|
| `GET` | `/dashboard` | Overall operational pulse, KPIs, upcoming returns, offline sync status |
| `GET` | `/dashboard/revenue-trend` | 6-month historical revenue (PKR) and +18.4% MoM performance |
| `GET` | `/items` | List inventory items (filter by `category`, `status`, `query`) |
| `GET` | `/items/:id` | Get specific inventory item details |
| `POST`| `/items` | Add new equipment item to inventory |
| `PUT` | `/items/:id` | Update item rates, status, or stock |
| `DELETE` | `/items/:id` | Remove item from inventory |
| `GET` | `/challans` | List dispatches (filter by `status`, `customerId`, `overdue=true`) |
| `GET` | `/challans/:id` | View specific Challan (items, deposit held, balance) |
| `POST`| `/challans` | Create new rental Challan (auto-deducts available stock) |
| `POST`| `/challans/:id/return` | Check-in returned equipment, restore stock, clear deposit |
| `POST`| `/challans/:id/whatsapp-alert` | Trigger WhatsApp notification to customer |
| `GET` | `/customers` | Directory of customers (search by name, CNIC, phone) |
| `GET` | `/customers/:id` | Customer profile with rental history and outstanding dues |
| `POST`| `/customers` | Register new customer with CNIC & phone |
| `POST`| `/sync/push` | Push offline mutations queue from Flutter SQLite |
| `GET` | `/sync/pull` | Pull delta updates since `?since=<iso8601>` timestamp |
| `GET` | `/shop` | Store profile (Al-Rehman Rentals, Lahore) |

---

## 💻 Sample Requests

### 1. Get Dashboard Pulse
```bash
curl http://localhost:8080/api/v1/dashboard
```

### 2. Create Rental Challan
```bash
curl -X POST http://localhost:8080/api/v1/challans \
  -H "Content-Type: application/json" \
  -d '{
    "customerId": "cust_02",
    "customerName": "Bilal Ahmed",
    "customerPhone": "+92 321 4567890",
    "customerCnic": "35202-4412984-3",
    "venue": "DHA Phase 6, Lahore",
    "totalAmount": 17000,
    "securityDepositHeld": 30000,
    "paidAmount": 17000,
    "balancePending": 0,
    "items": [
      {
        "itemId": "item_gen_10k_03",
        "itemName": "10kVA Soundproof Generator",
        "quantity": 1,
        "dailyRate": 8500,
        "days": 2,
        "totalRent": 17000
      }
    ]
  }'
```

### 3. Send WhatsApp Alert for Overdue Challan #RK-8821
```bash
curl -X POST http://localhost:8080/api/v1/challans/chal_8821/whatsapp-alert
```
