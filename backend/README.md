# RentKeeper Backend Server

A REST API server for rental business management, built with pure Dart (`dart:io` HttpServer). Zero external dependencies.

## Quick Start

```powershell
cd backend
dart run server.dart
```

The server starts on port 8080 and stores data in JSON files under `backend/data/`.

## API Endpoints

All endpoints are prefixed with `/api/v1`.

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/dashboard` | KPI metrics, revenue, active challans |
| GET | `/shop` | Get shop profile |
| PUT | `/shop` | Update shop profile |
| GET | `/items` | List items (filters: `?category=`, `?status=`, `?query=`) |
| POST | `/items` | Create new item |
| PUT | `/items/{id}` | Update item |
| DELETE | `/items/{id}` | Delete item |
| GET | `/customers` | List all customers |
| POST | `/customers` | Create new customer |
| PUT | `/customers/{id}` | Update customer |
| DELETE | `/customers/{id}` | Delete customer |
| GET | `/challans` | List all challans |
| POST | `/challans` | Create/dispatch new challan |
| POST | `/challans/{id}/return` | Check-in return (body: `lateFee`, `damageFee`, `notes`) |
| POST | `/challans/{id}/payment` | Record payment (body: `amount`) |
| POST | `/challans/{id}/whatsapp-alert` | Queue WhatsApp alert |
| POST | `/sync/push` | Push sync mutations |
| GET | `/sync/pull` | Pull all data (full sync) |

## Connecting from Flutter

- **Android Emulator**: `http://10.0.2.2:8080/api/v1`
- **Physical Device (same network)**: `http://<your-ip>:8080/api/v1`
- **Localhost**: `http://localhost:8080/api/v1`

## Data Storage

Data is stored as JSON files in `backend/data/`:
- `items.json`
- `customers.json`
- `challans.json`
- `shop.json`
