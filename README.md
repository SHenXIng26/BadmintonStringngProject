# Badminton Stringing Operations Prototype

This is a native SwiftUI prototype for managing a small badminton stringing and product sales operation. It started as a stringing record tool and is now being expanded into a lightweight purchase, sales, inventory, cashflow, and business dashboard system.

## Project Status

This project is currently a prototype.

- Stringing records are functional and saved locally on device.
- Inventory and product records are editable in the app and saved locally on device.
- Dashboard, purchase, sales, cashflow, information center, and maintenance pages still use prototype business data.
- Purchase, sales, and cashflow editing screens are not fully persistent yet.

## Requirements

- Xcode 16 or newer is recommended.
- iOS 16.0 or newer.
- SwiftUI.

## How To Run

1. Open `StringingRecords.xcodeproj` in Xcode.
2. Select the `StringingRecords` scheme.
3. Choose an iPhone or iPad simulator, or a connected device.
4. Press Run.

For a physical iPhone, Xcode may ask you to select a Development Team under Signing & Capabilities.

## Main Features

### Stringing Ops Home

The app opens with a module list:

- 经营驾驶舱
- 穿线记录工具
- 进货管理
- 销售管理
- 库存管理
- 钱流管理
- 信息中心
- 系统维护

On iPhone, each row opens as a navigation page. On iPad, the app uses a sidebar-style split view.

### 经营驾驶舱 Dashboard

The dashboard shows current operating data:

- 今日销售额
- 本月销售额
- 今日销售单数
- 本月销售单数
- 应收合计
- 应付合计
- 低库存预警数
- 今日库存流水数

It also includes quick entry buttons for:

- 销售出库
- 采购入库
- 库存状况
- 低库存预警
- 收款登记
- 付款登记

The dashboard also shows this month's hot products and low-stock warnings.

### 穿线记录工具

The stringing record tool supports:

- Add new stringing records
- Edit existing records
- Delete records
- Track work status
- Track payment status
- Track pickup status
- Search by customer, racket, string, tension, note, or record ID
- Filter by work, payment, and pickup status
- Export JSON backup
- Export CSV
- Import JSON backup

Stringing records are stored locally in the app sandbox under Application Support.

### 进货管理

The purchase page currently displays mock purchase orders and unpaid purchase balances.

### 销售管理

The sales page currently displays mock sales orders and receivable balances.

### 库存管理

The inventory page supports:

- Current stock quantity
- Low-stock status
- Storage location
- Recent inventory movements
- Add new inventory items
- Edit product and inventory details
- Adjust stock quantity
- Delete inventory items
- Save inventory changes locally

### 钱流管理

The cashflow page currently displays:

- Receivable total
- Payable total
- Recent incoming and outgoing payment records

### 信息中心

The information center currently displays mock product master data and prototype notes.

### 系统维护

The maintenance page records planned maintenance features such as backup, import, inventory persistence, and low-stock threshold settings.

## How To Modify Inventory

Inventory can now be modified directly inside the app.

1. Open `库存管理`.
2. Tap the `+` button in the top-right corner to add a new inventory item.
3. Use the `...` menu on an existing item to:
   - `库存调整`: increase or decrease stock quantity and create an inventory movement record.
   - `编辑商品`: edit product name, category, brand, price, cost, quantity, low-stock threshold, and location.
   - `删除`: remove the item from inventory.
4. Changes are saved automatically after tapping `Save`.

Saved inventory data is stored locally in the app sandbox:

`Application Support/StringingRecords/business-data.json`

The first app launch uses `StringingRecords/Data/MockBusinessData.swift` as seed data. After the local JSON file exists, the app loads saved data from `business-data.json`.

## Current Data Files

- `StringingRecords/Data/MockBusinessData.swift`
  - Initial seed products, inventory, sales orders, purchase orders, inventory movements, money records, and notices.

- `StringingRecords/Stores/BusinessStore.swift`
  - Loads, saves, and updates business data. Inventory/product changes are persisted here.

- `StringingRecords/Stores/RecordStore.swift`
  - Saves and loads real stringing records locally.

## Important Source Files

- `StringingRecords/Views/AppShellView.swift`
  - Main app navigation shell.

- `StringingRecords/Views/DashboardView.swift`
  - Business dashboard.

- `StringingRecords/Views/BusinessModulePages.swift`
  - Purchase, sales, inventory, cashflow, information center, and maintenance pages.

- `StringingRecords/Views/InventoryEditorViews.swift`
  - Add/edit inventory item forms, stock adjustment view, and inventory row controls.

- `StringingRecords/Views/ContentView.swift`
  - Stringing records page.

- `StringingRecords/Views/RecordFormView.swift`
  - Add/edit stringing record form.

- `StringingRecords/Models/BusinessModels.swift`
  - Business prototype models.

- `StringingRecords/Models/StringingRecord.swift`
  - Stringing record model and draft validation.

## Notes For Future Development

Planned next steps:

- Add persistent editing for purchase orders, sales orders, and cashflow.
- Add forms for purchase入库, sales出库, receive payment, and make payment.
- Connect sales and purchase records to inventory movements automatically.
- Add backup and restore for all business data, not only stringing records.

## Build Cache

`DerivedData/` is local build cache and can be deleted safely.
