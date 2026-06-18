# Badminton Stringing Records

This is a native SwiftUI iPhone app for a personal badminton stringing home service.

The app keeps the original stringing record tool and adds a simple string inventory, stock-in log, and monthly profit/loss overview. It is intentionally not a full purchase/sales/cashflow warehouse system.

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

### 经营概览

The overview reads existing stringing records from `RecordStore.records` and combines them with string inventory cost data.

It shows:

- 本月穿线收入
- 本月线材使用成本
- 本月毛利润
- 本月进货支出
- 本月净利润 / 亏损
- 本月穿线单数
- 低库存提醒
- 未匹配成本

Profit logic:

- Single-job profit = stringing record `price` - matched string `costPerPack`
- Monthly stringing revenue = prices from current-month records whose payment status is `Paid`
- Monthly string cost = matched string costs from current-month records whose work status is `Completed`
- Monthly gross profit = monthly revenue - monthly string cost
- Monthly stock-in expense = total cost of current-month stock-in records
- Monthly net cash result = monthly gross profit - monthly stock-in expense

The app matches string cost by name:

- Stringing record `stringName`
- String inventory item display name (`name - color`)

If a stringing record cannot find a matching inventory item, its string cost is counted as `0` and the overview marks it as unmatched.

Dashboard statistic cards can be opened to view their corresponding monthly records, costs, profit, stock-in expense, net result, completed jobs, and low-stock items.

### 穿线记录工具

The original stringing record tool is preserved.

It supports:

- Add, edit, and delete stringing records
- Track work status, payment status, and pickup status
- Search by customer, racket, string, tension, note, or record ID
- Filter by work, payment, and pickup status
- Export JSON backup
- Export CSV
- Import JSON backup

### 线材库存

Use this page to maintain string inventory:

- Add a string
- Edit string name, brand, color, cost per pack, quantity, low-stock threshold, and note
- Delete a string
- View current quantity
- View cost per pack
- See low-stock warnings
- Export inventory JSON
- Import inventory JSON

Low stock is shown when quantity is less than or equal to the low-stock threshold.
Different colors of the same string are stored as separate inventory items. New stringing records select the exact inventory display name, such as `Yonex BG80 - White`.

### 入库记录

Use this page to record string purchases and stock-ins.

Each stock-in record saves:

- Date
- String name
- Brand
- Color
- Quantity
- Cost per pack
- Total cost
- Note

When a stock-in record is saved:

- The stock-in record is saved locally.
- Total cost is calculated as `quantity x costPerPack`.
- Matching string inventory quantity increases automatically.
- If the string does not exist in inventory, the app creates it.
- If the string already exists, the latest cost per pack is used.

Deleting a stock-in record tries to subtract that quantity from matching inventory. If that would make inventory negative, the app blocks the delete.

### 系统维护

The maintenance page can clear:

- String inventory only
- Stock-in records only
- Both string inventory and stock-in records

These actions do not delete stringing records.

## Local Data

Stringing records are saved separately by `RecordStore`:

`Application Support/StringingRecords/records.json`

String inventory and stock-in records are saved by `BusinessStore`:

`Application Support/StringingRecords/string-business-data.json`

## Important Source Files

- `StringingRecords/Views/AppShellView.swift`
  - Main navigation shell.

- `StringingRecords/Views/ContentView.swift`
  - Original stringing records page.

- `StringingRecords/Views/RecordFormView.swift`
  - Add/edit stringing record form.

- `StringingRecords/Models/StringingRecord.swift`
  - Stringing record model and draft validation.

- `StringingRecords/Stores/RecordStore.swift`
  - Saves and loads stringing records.

- `StringingRecords/Views/DashboardView.swift`
  - Monthly profit/loss overview.

- `StringingRecords/Views/BusinessModulePages.swift`
  - String inventory, stock-in records, and maintenance pages.

- `StringingRecords/Views/InventoryEditorViews.swift`
  - Add/edit string inventory forms and inventory rows.

- `StringingRecords/Views/TransactionEditorViews.swift`
  - Stock-in record form and rows.

- `StringingRecords/Models/BusinessModels.swift`
  - String inventory, stock-in, and profit summary models.

- `StringingRecords/Stores/BusinessStore.swift`
  - Loads, saves, and updates string inventory and stock-in data.

## Build Cache

`DerivedData/` is local build cache and can be deleted safely.
