# Badminton Stringing Operations

This is a native SwiftUI iPhone app for badminton stringing records, product stock, purchase in, sales out, payment tracking, and daily operating data.

The warehouse business data starts empty. Add your own inventory, purchase orders, sales orders, and cashflow records inside the app; changes are saved locally on the device.

## Requirements

- Xcode 16 or newer is recommended.
- iOS 16.0 or newer.
- SwiftUI.

## How To Run

1. Open `StringingRecords.xcodeproj` in Xcode.
2. Select the `StringingRecords` scheme.
3. Choose an iPhone simulator or a connected iPhone.
4. Press Run.

For a physical iPhone, Xcode may ask you to select a Development Team under Signing & Capabilities.

## Main Modules

### Stringing Ops Home

The app opens with these modules:

- 经营驾驶舱
- 穿线记录工具
- 进货管理
- 销售管理
- 库存管理
- 钱流管理
- 信息中心
- 系统维护

On iPhone, each row opens as a navigation page. On iPad, the app uses a split-view layout.

### 经营驾驶舱 Dashboard

The dashboard calculates operating data from saved app data:

- 今日销售额
- 本月销售额
- 今日销售单数
- 本月销售单数
- 应收合计
- 应付合计
- 低库存预警数
- 今日库存流水数

It also provides quick entry buttons for sales out, purchase in, inventory, low-stock warnings, receive payment, and make payment.

### 穿线记录工具

The stringing record tool supports:

- Add, edit, and delete stringing records
- Track work status, payment status, and pickup status
- Search by customer, racket, string, tension, note, or record ID
- Filter by work, payment, and pickup status
- Export JSON backup
- Export CSV
- Import JSON backup

### 进货管理

Use this page to add purchase orders.

When a purchase order is saved:

- The purchase order is saved locally.
- The purchased quantity is added to inventory.
- A stock movement is created.
- If `已付款` is greater than zero, a payment record is created.
- Any unpaid balance appears in `待付款`.

### 销售管理

Use this page to add sales orders.

When a sales order is saved:

- The app checks that the product exists in inventory.
- The app checks that stock is enough.
- The sold quantity is deducted from inventory.
- A stock movement is created.
- If `已收款` is greater than zero, a payment record is created.
- Any unpaid balance appears in `应收款`.

### 库存管理

Use this page to maintain product and stock data:

- Add inventory items
- Edit product code, product name, category, brand, sale price, cost price, quantity, warning threshold, and location
- Adjust stock quantity
- Delete inventory items
- View low-stock warnings
- View inventory movements

### 钱流管理

Use this page to add incoming and outgoing money records.

If you enter a related order ID:

- `收款` updates the matching sales order's paid amount.
- `付款` updates the matching purchase order's paid amount.
- The app prevents payment from exceeding the order total.

Leave the related order ID blank for standalone cashflow notes.

### 信息中心

The information center shows saved product data. Product data is created from inventory and purchase records, then can be edited from the inventory page.

### 系统维护

The maintenance page shows local save status and includes a button to clear warehouse business data. This clears purchase, sales, inventory, cashflow, product, movement, and notice data. It does not delete stringing records.

## How To Modify Inventory

There are three normal ways to change inventory:

1. Open `库存管理`, tap the `+` button, and add an inventory item manually.
2. Open `进货管理`, tap the `+` button, and save a purchase order. The purchased quantity is added automatically.
3. Open `销售管理`, tap the `+` button, and save a sales order. The sold quantity is deducted automatically after the stock check passes.

For an existing item, use the `...` menu in `库存管理`:

- `库存调整`: increase or decrease stock quantity and create an inventory movement.
- `编辑商品`: edit product and inventory details.
- `删除`: remove the item from inventory.

All changes are saved after tapping `Save`.

## Local Data

Warehouse business data is saved in the app sandbox:

`Application Support/StringingRecords/warehouse-data.json`

Stringing records are saved separately by `RecordStore`.

## Important Source Files

- `StringingRecords/Views/AppShellView.swift`
  - Main app navigation shell.

- `StringingRecords/Views/DashboardView.swift`
  - Business dashboard and quick entry buttons.

- `StringingRecords/Views/BusinessModulePages.swift`
  - Purchase, sales, inventory, cashflow, information center, and maintenance pages.

- `StringingRecords/Views/InventoryEditorViews.swift`
  - Inventory item forms, stock adjustment view, and inventory row controls.

- `StringingRecords/Views/TransactionEditorViews.swift`
  - Purchase order, sales order, and money record forms.

- `StringingRecords/Views/ContentView.swift`
  - Stringing records page.

- `StringingRecords/Views/RecordFormView.swift`
  - Add/edit stringing record form.

- `StringingRecords/Models/BusinessModels.swift`
  - Business data models and form drafts.

- `StringingRecords/Stores/BusinessStore.swift`
  - Loads, saves, and updates warehouse business data.

- `StringingRecords/Data/InitialBusinessData.swift`
  - Empty initial warehouse business dataset.

## Build Cache

`DerivedData/` is local build cache and can be deleted safely.
