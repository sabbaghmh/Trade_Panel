# Trade Panel EA (MQL5)

A MetaTrader 5 Expert Advisor that puts a small button panel on the chart.
You set **SL, TP, Lot and Price** in pop-up windows (in any order) and then
open market orders or place limit orders with a single click.

> **Disclaimer:** This software places real trades. Test it on a demo
> account first. Use it at your own risk; no warranty is provided.

## Features

- Market **Buy** / **Sell** with the configured SL, TP and lot
- **Buy Limit** / **Sell Limit** at a price entered by the user
- Lot size: **Auto** (0.01 lot per 50 units of balance) or **Manual** (0.01 - 50.00)
- **Close_All**: closes every open position and deletes every pending order
- **Info** window showing the current SL, TP, Lot and Price
- **Reset** sets Price, Lot, SL and TP back to zero
- **Exit** removes all chart objects and the EA from the chart
- Safety limits: at most **2 open positions** and **2 pending orders**

## Button layout

| Row | Buttons |
|-----|---------|
| 1 | `Setting` shows / hides `SL/TP`, `Lot`, `Reset` |
| 2 | `Mar_Exe` shows / hides `Buy`, `Sell` |
| 3 | `Pen_Or` shows / hides `Price`, `Buy_Li`, `Sell_Li` |
| 4 | `Info`, `Close_All`, `Exit` |

Main buttons are toggles: the first click shows the related buttons (the
toggle turns green), the second click hides them.

## How it works

- **SL/TP**: values are in **points**, distance from the entry price.
  `0` means "no SL" / "no TP".
- **Lot**: in Auto mode the lot is calculated at the moment of the click from
  the account balance. It is always adjusted to the symbol's min / max / step.
  Manual mode uses the value accepted in the Lot window.
- **Price**: used by `Buy_Li` and `Sell_Li`. If you press one of them before a
  price has been entered, the Price window opens and the order is placed as
  soon as you press **OK**.
- Buy Limit must be **below** the current Ask; Sell Limit must be **above** the
  current Bid.
- Limit orders are placed with `ORDER_TIME_DAY` (they expire at the end of the
  trading day).
- Only one window (SL/TP, Lot, Price, Info) is open at a time. Buttons hidden
  behind an open window do not react to clicks.
- Values are only applied when you press **OK** in a window. **Cancel** or
  **X** discards the edits.

## Installation

1. In MetaTrader 5 open **File > Open Data Folder**.
2. Copy the `Code` folder into `MQL5/Experts/` (for example
   `MQL5/Experts/TradePanel/`).
3. Open `main.mq5` in MetaEditor and press **Compile** (F7).
4. Drag the compiled EA onto a chart and enable **Algo Trading**.

## Project structure

| File | Purpose |
|------|---------|
| `Code/main.mq5` | EA entry point, button wiring, order logic |
| `Code/TradeTools.mqh` | Account / price helpers and the `MPositions` class (orders, closing) |
| `Code/TradeUI_Common.mqh` | Shared chart-object helpers |
| `Code/SLTP_Dialog.mqh` | SL/TP window |
| `Code/Lot_Dialog.mqh` | Lot window |
| `Code/Price_Dialog.mqh` | Price window |

## Configuration

Limits are defined at the top of `Code/TradeTools.mqh`:

```mql5
#define MAX_POSITIONS      2   // maximum open positions
#define MAX_PENDING_ORDERS 2   // maximum pending orders
```

The automatic lot formula is `LotCalc()` in the same file.

## Known behaviour

- `Close_All` closes **all** positions and pending orders of the account, not
  only those of the chart symbol or of this EA.
- `Exit` and removing the EA delete **all** objects on the chart, including
  your own drawings. Open positions and pending orders are not touched.
- `MAX_POSITIONS` and `MAX_PENDING_ORDERS` count orders of the whole account.


## License

MIT, see `LICENSE`.

