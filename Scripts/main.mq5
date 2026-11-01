//+--------------------------------------------------------------------------------+
//|                                                                                |
//|    __  __     _   _         ____          _      _                    _        |
//|   |  \/  |   | | | |       / ___|   __ _ | |__  | |__    __ _   __ _ | |__     |
//|   | |\/| |   | |_| |       \___ \  / _` || '_ \ | '_ \  / _` | / _` || '_ \    |
//|   | |  | | _ |  _  | _      ___) || (_| || |_) || |_) || (_| || (_| || | | |   |
//|   |_|  |_|(_)|_| |_|(_)    |____/  \__,_||_.__/ |_.__/  \__,_| \__, ||_| |_|   |
//|                                                                |___/           |
//|                                                                                |
//|   Trade Panel EA  -  main.mq5                                                  |
//|   Chart buttons for market orders, limit orders, SL/TP, lot size and price,    |
//|   plus Close_All, Info and Exit.                                               |
//|                                                                                |
//|   Button layout (x, y) on the chart:                                           |
//|                                                                                |
//|   +--------------+--------------+--------------+--------------+                |
//|   | Setting      | SL/TP        | Lot          | Reset        |                |
//|   | (20,20)      | (100,20)     | (180,20)     | (260,20)     |                |
//|   +--------------+--------------+--------------+--------------+                |
//|   | Mar_Exe      | Buy          | Sell         |              |                |
//|   | (20,65)      | (100,65)     | (180,65)     |              |                |
//|   +--------------+--------------+--------------+--------------+                |
//|   | Pen_Or       | Price        | Buy_Li       | Sell_Li      |                |
//|   | (20,110)     | (100,110)    | (180,110)    | (260,110)    |                |
//|   +--------------+--------------+--------------+--------------+                |
//|   | Info         | Close_All    | Exit         |              |                |
//|   | (20,155)     | (100,155)    | (180,155)    |              |                |
//|   +--------------+--------------+--------------+--------------+                |
//|                                                                                |
//|   Author  : M.H. Sabbagh.                                                      |
//|   Year    : 2026                                                               |
//|   GitHub  : github.com/sabbaghmh/Trade_Panel                                   |
//|   Version : 1.0.0            License : MIT License.                            |
//|                                                                                |
//+--------------------------------------------------------------------------------+


#include "SLTP_Dialog.mqh"
#include "Lot_Dialog.mqh"
#include "TradeTools.mqh"
#include "Price_Dialog.mqh"

//+------------------------------------------------------------------+
//| Global state                                                     |
//+------------------------------------------------------------------+

MPositions mp;

// Values accepted by the user (0 = not set).
double g_slPoints = 0.0;     // Stop loss in points
double g_tpPoints = 0.0;     // Take profit in points
double UserPrice  = 0.0;     // Price for limit orders
double g_lot      = 0.0;     // Manual lot, or LotCalc() when Auto was accepted
bool   g_lotAuto  = true;    // true = automatic lot, false = manual lot

// Button names
string m_setting         = "Setting";
string m_reset           = "Reset";
string m_MarketExecution = "Mar_Exe";
string buy_button        = "Buy";
string sell_button       = "Sell";
string m_PendingOrder    = "Pen_Or";
string m_BuyLimit        = "Buy_Li";
string m_SellLimit       = "Sell_Li";
string m_CloseAll        = "Close_All";
string m_Info            = "Info";
string m_Exit            = "Exit";

// Name prefix of every object in the Info window.
string g_infoPrefix = "INFO_DLG_";

// Toggle states
bool g_settingOn         = false;   // Setting: SL/TP, Lot and Reset buttons shown
bool g_MarketExecutionOn = false;   // Mar_Exe: Buy and Sell buttons shown
bool g_PendingOrderOn    = false;   // Pen_Or: Price, Buy_Li and Sell_Li shown

// Limit button that is waiting for the user to enter a price ("" = none).
string g_awaitPriceFor = "";

//+------------------------------------------------------------------+
//| Expert initialization                                            |
//+------------------------------------------------------------------+
int OnInit()
{
   Setting_OnInit();
   MarketExecution_OnInit();
   PendingOrder_OnInit();
   Info_OnInit();
   CloseAll_OnInit();
   Exit_OnInit();

   return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Expert deinitialization: removes every chart object              |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   PriceDialog.Cleanup();
   ObjectsDeleteAll(0);
   ChartRedraw(0);
}

//+------------------------------------------------------------------+
//| Tick handler (trading is driven by the buttons, not by ticks)    |
//+------------------------------------------------------------------+
void OnTick()
{
   // The accepted values can be read here with:
   //   g_slPoints, g_tpPoints, g_lot, g_lotAuto, UserPrice
}

//+------------------------------------------------------------------+
//| Chart event dispatcher (an EA can have only one OnChartEvent)    |
//+------------------------------------------------------------------+
void OnChartEvent(const int id,
                  const long &lparam,
                  const double &dparam,
                  const string &sparam)
{
   if(id == CHARTEVENT_OBJECT_CLICK)
   {
      // A button hidden behind an open window must not react to clicks.
      if(IsCoveredByOpenWindow(sparam))
      {
         TradeUI_ResetButton(sparam);
         return;
      }

      if(sparam == m_setting)
      {
         Setting_OnChartEvent();
         return;
      }

      if(sparam == m_MarketExecution)
      {
         MarketExecution_OnChartEvent();
         return;
      }

      if(sparam == m_PendingOrder)
      {
         PendingOrder_OnChartEvent();
         return;
      }

      if(sparam == m_CloseAll)
      {
         CloseAll_OnChartEvent(id, sparam);
         return;
      }

      if(sparam == m_Exit)
      {
         Exit_OnChartEvent(id, sparam);
         return;
      }

      // Info button and the X button of its window.
      if(sparam == m_Info || sparam == g_infoPrefix + "CLOSE")
      {
         Info_OnChartEvent(id, sparam);
         return;
      }

      // Opening any settings window closes the Info window.
      if(sparam == "SLTP_MAIN_BUTTON" || sparam == "LotButton" || sparam == "PriceButton")
         Info_Close();

      // Limit orders exist only while Pen_Or is ON.
      if(g_PendingOrderOn && sparam == m_BuyLimit)
      {
         BuyLimit_OnChartEvent(id, sparam);
         return;
      }

      if(g_PendingOrderOn && sparam == m_SellLimit)
      {
         SellLimit_OnChartEvent(id, sparam);
         return;
      }

      // Buy / Sell buttons exist only while Mar_Exe is ON.
      if(g_MarketExecutionOn && sparam == buy_button)
      {
         Buy_OnChartEvent(id, sparam);
         return;
      }

      if(g_MarketExecutionOn && sparam == sell_button)
      {
         Sell_OnChartEvent(id, sparam);
         return;
      }

      // The Price button AND the Price window's own controls (X, OK,
      // Cancel) are forwarded while Pen_Or is ON; the handler ignores
      // anything that does not belong to the Price UI.
      if(g_PendingOrderOn)
         Price_OnChartEvent(id, lparam, dparam, sparam);
   }

   // The SL/TP and Lot buttons and dialogs exist only while Setting is ON.
   if(!g_settingOn)
      return;

   Reset_OnChartEvent(id, sparam);
   SLTP_Lot_OnChartEvent(id, lparam, dparam, sparam);
}

//+------------------------------------------------------------------+
//| Shared helpers                                                   |
//+------------------------------------------------------------------+

// Creates one of the 70 x 35 buttons of the panel.
void UI_CreateButton(const string name,
                     const int x,
                     const int y,
                     const color background,
                     const int width = 70)
{
   if(TradeUI_CreateObject(name, OBJ_BUTTON, x, y, width, 35, name,
                           background, clrWhite, 12, 100))
      ChartRedraw(0);
}

// Closes every dialog window (without saving unconfirmed edits).
void CloseAllDialogs()
{
   SLTPDialog.CloseWithoutSaving();
   LotDialog.CloseWithoutSaving();
   PriceDialog.CloseWithoutSaving();
}

// True when the object is a button lying under an open window (SL/TP,
// Lot, Price or Info). The window's own controls and buttons outside
// the window area are never reported as covered.
bool IsCoveredByOpenWindow(const string name)
{
   string prefixes[4];
   prefixes[0] = "SLTP_DLG_";
   prefixes[1] = "LOT_DLG_";
   prefixes[2] = "PRICE_DLG_";
   prefixes[3] = g_infoPrefix;

   // Controls that belong to a window are always allowed.
   for(int i = 0; i < 4; i++)
      if(StringFind(name, prefixes[i]) == 0)
         return false;

   if(ObjectFind(0, name) < 0 ||
      ObjectGetInteger(0, name, OBJPROP_TYPE) != OBJ_BUTTON)
      return false;

   long bx = ObjectGetInteger(0, name, OBJPROP_XDISTANCE);
   long by = ObjectGetInteger(0, name, OBJPROP_YDISTANCE);
   long bw = ObjectGetInteger(0, name, OBJPROP_XSIZE);
   long bh = ObjectGetInteger(0, name, OBJPROP_YSIZE);

   for(int i = 0; i < 4; i++)
   {
      string bg = prefixes[i] + "BG";
      if(ObjectFind(0, bg) < 0)
         continue;

      long wx = ObjectGetInteger(0, bg, OBJPROP_XDISTANCE);
      long wy = ObjectGetInteger(0, bg, OBJPROP_YDISTANCE);
      long ww = ObjectGetInteger(0, bg, OBJPROP_XSIZE);
      long wh = ObjectGetInteger(0, bg, OBJPROP_YSIZE);

      bool overlap = (bx < wx + ww) && (bx + bw > wx) &&
                     (by < wy + wh) && (by + bh > wy);
      if(overlap)
         return true;
   }

   return false;
}

// Lot used for a new trade: calculated by LotCalc() in Auto mode,
// otherwise the manual lot accepted in the Lot dialog. The result is
// adjusted to the symbol's min / max / step. Returns 0 when no valid
// lot is available; the caller then refuses the order.
double GetTradeLot()
{
   double lot = g_lotAuto ? LotCalc(0.0) : g_lot;

   double minLot  = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   double maxLot  = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
   double stepLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);

   if(lot <= 0.0)
      return 0.0;

   if(stepLot > 0.0)
      lot = MathFloor(lot / stepLot + 1e-8) * stepLot;

   if(lot < minLot)
      return 0.0;

   if(maxLot > 0.0 && lot > maxLot)
      lot = maxLot;

   return NormalizeDouble(lot, 8);
}

//+------------------------------------------------------------------+
//| Setting button: shows / hides SL/TP, Lot and Reset               |
//+------------------------------------------------------------------+

void Setting_OnInit()
{
   g_settingOn = false;
   UI_CreateButton(m_setting, 20, 20, clrDodgerBlue);
}

void Setting_OnChartEvent()
{
   // Release the pressed look of the toggle button.
   ObjectSetInteger(0, m_setting, OBJPROP_STATE, false);

   if(!g_settingOn)
   {
      // 1st click: create the buttons.
      g_settingOn = true;
      ObjectSetInteger(0, m_setting, OBJPROP_BGCOLOR, clrGreen);

      SLTP_Lot_OnInit();
      Reset_OnInit();
      
   }
   else
   {
      // 2nd click: remove everything except the Setting button.
      g_settingOn = false;
      ObjectSetInteger(0, m_setting, OBJPROP_BGCOLOR, clrDodgerBlue);

      SLTP_Lot_CleanUp();
      ObjectDelete(0, m_reset);
   }

   ChartRedraw(0);
}

//+------------------------------------------------------------------+
//| SL/TP and Lot dialogs                                            |
//+------------------------------------------------------------------+

int SLTP_Lot_OnInit()
{
   // Clean stale objects from a previous run, including the old
   // CAppDialog implementation. These names are reserved for this UI.
   TradeUI_DeleteByPrefix("SLTP_DLG_");
   TradeUI_DeleteByPrefix("LOT_DLG_");
   TradeUI_DeleteLegacyDialogObjects();

   if(!SLTPDialog.CreateMainButton())
   {
      Print("EA: Failed to create SL/TP button.");
      SLTPDialog.Cleanup();
      LotDialog.Cleanup();
      return INIT_FAILED;
   }

   if(!LotDialog.CreateMainButton())
   {
      Print("EA: Failed to create Lot button.");
      SLTPDialog.Cleanup();
      LotDialog.Cleanup();
      return INIT_FAILED;
   }

   ChartRedraw(0);
   Print("EA: SL/TP, Lot, and Reset dialogs initialized.");
   return INIT_SUCCEEDED;
}

void SLTP_Lot_CleanUp()
{
   SLTPDialog.Cleanup();
   LotDialog.Cleanup();
}

void SLTP_Lot_OnChartEvent(const int id,
                           const long &lparam,
                           const double &dparam,
                           const string &sparam)
{
   // Main SL/TP button: close every other window, then toggle SL/TP.
   if(id == CHARTEVENT_OBJECT_CLICK && sparam == "SLTP_MAIN_BUTTON")
   {
      TradeUI_ResetButton("SLTP_MAIN_BUTTON");

      if(SLTPDialog.IsOpen())
         SLTPDialog.CloseWithoutSaving();
      else
      {
         LotDialog.CloseWithoutSaving();
         PriceDialog.CloseWithoutSaving();
         SLTPDialog.OpenDialog();
      }

      ChartRedraw(0);
      return;
   }

   // Main Lot button: close every other window, then toggle Lot.
   if(id == CHARTEVENT_OBJECT_CLICK && sparam == "LotButton")
   {
      TradeUI_ResetButton("LotButton");

      if(LotDialog.IsOpen())
         LotDialog.CloseWithoutSaving();
      else
      {
         SLTPDialog.CloseWithoutSaving();
         PriceDialog.CloseWithoutSaving();
         LotDialog.OpenDialog();
      }

      ChartRedraw(0);
      return;
   }

   // Let the dialogs handle clicks on their own child objects.
   SLTPDialog.OnChartEvent(id, lparam, dparam, sparam);
   LotDialog.OnChartEvent(id, lparam, dparam, sparam);

   // Read the SL/TP values after the SL/TP OK handler has accepted them.
   double newSL = 0.0;
   double newTP = 0.0;
   if(SLTPDialog.GetValues(newSL, newTP))
   {
      g_slPoints = newSL;
      g_tpPoints = newTP;
      Print("EA: SL/TP accepted: SL = ", DoubleToString(g_slPoints, 1),
            ", TP = ", DoubleToString(g_tpPoints, 1));
   }

   // Read the Lot settings after the Lot OK handler has accepted them.
   double newLot  = 0.0;
   bool   newAuto = true;
   if(LotDialog.GetValues(newLot, newAuto))
   {
      g_lotAuto = newAuto;
      g_lot     = newAuto ? LotCalc(0.0) : newLot;
      Print("EA: Lot accepted: ", (g_lotAuto ? "auto" : "manual"),
            ", lot = ", DoubleToString(g_lot, 2));
   }
}

//+------------------------------------------------------------------+
//| Price dialog                                                     |
//+------------------------------------------------------------------+

int Price_OnInit()
{
   // Create the main chart button labelled "Price".
   if(!PriceDialog.CreateMainButton())
   {
      Print("ERROR: Could not create the Price button.");
      return INIT_FAILED;
   }

   UserPrice = PriceDialog.GetPrice();
   ChartRedraw(0);

   
   return INIT_SUCCEEDED;
}

void Price_OnChartEvent(const int id,
                        const long &lparam,
                        const double &dparam,
                        const string &sparam)
{
   if(id != CHARTEVENT_OBJECT_CLICK)
      return;

   // Main Price button: close every other window, then toggle Price.
   if(sparam == "PriceButton")
   {
      TradeUI_ResetButton("PriceButton");
      g_awaitPriceFor = "";   // The user is entering the price by hand.

      if(PriceDialog.IsOpen())
         PriceDialog.CloseWithoutSaving();
      else
      {
         SLTPDialog.CloseWithoutSaving();
         LotDialog.CloseWithoutSaving();
         PriceDialog.OpenDialog();
      }

      ChartRedraw(0);
      return;
   }

   // Forward dialog events (OK, Cancel and X) to the dialog class.
   double oldPrice = PriceDialog.GetPrice();
   PriceDialog.OnChartEvent(id, lparam, dparam, sparam);

   // Read the accepted value after processing the event.
   UserPrice = PriceDialog.GetPrice();

   if(UserPrice != oldPrice)
   {
      // OK has accepted a new price.
      Print("EA: New accepted price = ", DoubleToString(UserPrice, _Digits));

      // A Limit button was waiting for this price: place its order now.
      string waiting = g_awaitPriceFor;
      g_awaitPriceFor = "";
      if(waiting == m_BuyLimit)
         PlaceBuyLimit();
      else if(waiting == m_SellLimit)
         PlaceSellLimit();
   }
   else if(!PriceDialog.IsOpen())
   {
      // Cancel / X: forget the waiting order so a later price entry
      // cannot trigger it unexpectedly.
      g_awaitPriceFor = "";
   }
}

// Opens the Price window because a Limit button was pressed before any
// price was entered. The order is placed after the price is accepted.
void AskPriceThenPlace(const string limitButton)
{
   Info_Close();
   SLTPDialog.CloseWithoutSaving();
   LotDialog.CloseWithoutSaving();
   PriceDialog.OpenDialog();
   g_awaitPriceFor = limitButton;
   ChartRedraw(0);
}

//+------------------------------------------------------------------+
//| Reset button: sets Price, Lot, SL and TP back to zero            |
//+------------------------------------------------------------------+

void Reset_OnInit()
{
   UI_CreateButton(m_reset, 260, 20, clrRed);
}

void Reset_OnChartEvent(const int id, const string &sparam)
{
   if(id != CHARTEVENT_OBJECT_CLICK || sparam != m_reset)
      return;

   TradeUI_ResetButton(m_reset);

   SLTPDialog.Reset();
   LotDialog.Reset();
   PriceDialog.Reset();

   g_slPoints = 0.0;
   g_tpPoints = 0.0;
   g_lot      = 0.0;
   UserPrice  = 0.0;

   Print("EA: Reset - Price, Lot, SL and TP set to 0.");

   // If the Info window is open, refresh the values it shows.
   if(Info_IsOpen())
      Info_Open();

   ChartRedraw(0);
}

//+------------------------------------------------------------------+
//| Market execution: Mar_Exe shows the Buy and Sell buttons         |
//+------------------------------------------------------------------+

void MarketExecution_OnInit()
{
   UI_CreateButton(m_MarketExecution, 20, 65, clrDodgerBlue);
}

void MarketExecution_OnChartEvent()
{
   // Release the pressed look of the toggle button.
   ObjectSetInteger(0, m_MarketExecution, OBJPROP_STATE, false);

   if(!g_MarketExecutionOn)
   {
      // 1st click: create the Buy and Sell buttons.
      g_MarketExecutionOn = true;
      ObjectSetInteger(0, m_MarketExecution, OBJPROP_BGCOLOR, clrGreen);

      BuySell_OnInit();
      Print("EA: Buy and Sell dialogs initialized.");
   }
   else
   {
      // 2nd click: remove the Buy and Sell buttons.
      g_MarketExecutionOn = false;
      ObjectSetInteger(0, m_MarketExecution, OBJPROP_BGCOLOR, clrDodgerBlue);

      ObjectDelete(0, buy_button);
      ObjectDelete(0, sell_button);
   }

   ChartRedraw(0);
}

void BuySell_OnInit()
{
   UI_CreateButton(buy_button,  100, 65, clrDodgerBlue);
   UI_CreateButton(sell_button, 180, 65, clrDodgerBlue);
}

void Buy_OnChartEvent(const int id, const string &sparam)
{
   if(id != CHARTEVENT_OBJECT_CLICK || sparam != buy_button)
      return;

   TradeUI_ResetButton(buy_button);

   double lot = GetTradeLot();
   if(lot <= 0.0)
   {
      Alert("Buy: invalid lot. Set a lot in the Lot window (or check the balance in Auto mode).");
      return;
   }

   if(mp.Buy_p(lot, GetAsk(), g_slPoints, g_tpPoints))
      Print("EA: Buy opened. Lot = ", DoubleToString(lot, 2),
            ", SL = ", DoubleToString(g_slPoints, 1),
            ", TP = ", DoubleToString(g_tpPoints, 1));
   else
      Print("EA: Buy was not opened. The position limit may be reached, or the order failed. Retcode = ",
            trade.ResultRetcode(), " (", trade.ResultRetcodeDescription(), ")");
}

void Sell_OnChartEvent(const int id, const string &sparam)
{
   if(id != CHARTEVENT_OBJECT_CLICK || sparam != sell_button)
      return;

   TradeUI_ResetButton(sell_button);

   double lot = GetTradeLot();
   if(lot <= 0.0)
   {
      Alert("Sell: invalid lot. Set a lot in the Lot window (or check the balance in Auto mode).");
      return;
   }

   if(mp.Sell_p(lot, GetBid(), g_slPoints, g_tpPoints))
      Print("EA: Sell opened. Lot = ", DoubleToString(lot, 2),
            ", SL = ", DoubleToString(g_slPoints, 1),
            ", TP = ", DoubleToString(g_tpPoints, 1));
   else
      Print("EA: Sell was not opened. The position limit may be reached, or the order failed. Retcode = ",
            trade.ResultRetcode(), " (", trade.ResultRetcodeDescription(), ")");
}

//+------------------------------------------------------------------+
//| Pending orders: Pen_Or shows Price, Buy_Li and Sell_Li          |
//+------------------------------------------------------------------+

void PendingOrder_OnInit()
{
   UI_CreateButton(m_PendingOrder, 20, 110, clrDodgerBlue);
}

void PendingOrder_OnChartEvent()
{
   // Release the pressed look of the toggle button.
   ObjectSetInteger(0, m_PendingOrder, OBJPROP_STATE, false);

   if(!g_PendingOrderOn)
   {
      // 1st click: create the buttons.
      g_PendingOrderOn = true;
      ObjectSetInteger(0, m_PendingOrder, OBJPROP_BGCOLOR, clrGreen);

      Price_OnInit();
      BuyLimit_OnInit();
      SellLimit_OnInit();
      Print("EA: Price, BuyLimit, and SellLimit dialogs initialized.");
   }
   else
   {
      // 2nd click: remove the buttons and the Price window.
      g_PendingOrderOn = false;
      ObjectSetInteger(0, m_PendingOrder, OBJPROP_BGCOLOR, clrDodgerBlue);

      g_awaitPriceFor = "";
      PriceDialog.Cleanup();
      ObjectDelete(0, m_BuyLimit);
      ObjectDelete(0, m_SellLimit);
   }

   ChartRedraw(0);
}

//+------------------------------------------------------------------+
//| Buy Limit                                                        |
//+------------------------------------------------------------------+

void BuyLimit_OnInit()
{
   UI_CreateButton(m_BuyLimit, 180, 110, clrDodgerBlue);
}

// Buy_Li button: place a Buy Limit at the price entered with the Price
// button. The values can be set in any order: if no price has been
// entered yet, the Price window opens and the order is placed as soon
// as OK is pressed.
void BuyLimit_OnChartEvent(const int id, const string &sparam)
{
   if(id != CHARTEVENT_OBJECT_CLICK || sparam != m_BuyLimit)
      return;

   TradeUI_ResetButton(m_BuyLimit);

   if(UserPrice <= 0.0)
   {
      AskPriceThenPlace(m_BuyLimit);
      return;
   }

   PlaceBuyLimit();
}

// Places the Buy Limit using the values currently set (price, lot, SL, TP).
void PlaceBuyLimit()
{
   if(OrdersTotal() >= MAX_PENDING_ORDERS)
   {
      Alert("Buy Limit: at most ", MAX_PENDING_ORDERS,
            " pending orders are allowed. Delete one first (or use Close_All).");
      return;
   }

   double price = NormalizeDouble(UserPrice, _Digits);

   // A Buy Limit must be placed below the current Ask price.
   if(price >= GetAsk())
   {
      Alert("Buy Limit: the price (", DoubleToString(price, _Digits),
            ") must be below the current Ask (", DoubleToString(GetAsk(), _Digits), ").");
      return;
   }

   double lot = GetTradeLot();
   if(lot <= 0.0)
   {
      Alert("Buy Limit: invalid lot. Set a lot in the Lot window (or check the balance in Auto mode).");
      return;
   }

   if(mp.Buy_Limit(lot, price, g_slPoints, g_tpPoints))
      Print("EA: Buy Limit placed. Price = ", DoubleToString(price, _Digits),
            ", Lot = ", DoubleToString(lot, 2),
            ", SL = ", DoubleToString(g_slPoints, 1),
            ", TP = ", DoubleToString(g_tpPoints, 1));
   else
      Print("EA: Buy Limit failed. Retcode = ", trade.ResultRetcode(),
            " (", trade.ResultRetcodeDescription(), ")");
}

//+------------------------------------------------------------------+
//| Sell Limit                                                       |
//+------------------------------------------------------------------+

void SellLimit_OnInit()
{
   UI_CreateButton(m_SellLimit, 260, 110, clrDodgerBlue);
}

// Sell_Li button: place a Sell Limit at the price entered with the Price
// button (see BuyLimit_OnChartEvent for the "price not set yet" case).
void SellLimit_OnChartEvent(const int id, const string &sparam)
{
   if(id != CHARTEVENT_OBJECT_CLICK || sparam != m_SellLimit)
      return;

   TradeUI_ResetButton(m_SellLimit);

   if(UserPrice <= 0.0)
   {
      AskPriceThenPlace(m_SellLimit);
      return;
   }

   PlaceSellLimit();
}

// Places the Sell Limit using the values currently set (price, lot, SL, TP).
void PlaceSellLimit()
{
   if(OrdersTotal() >= MAX_PENDING_ORDERS)
   {
      Alert("Sell Limit: at most ", MAX_PENDING_ORDERS,
            " pending orders are allowed. Delete one first (or use Close_All).");
      return;
   }

   double price = NormalizeDouble(UserPrice, _Digits);

   // A Sell Limit must be placed above the current Bid price.
   if(price <= GetBid())
   {
      Alert("Sell Limit: the price (", DoubleToString(price, _Digits),
            ") must be above the current Bid (", DoubleToString(GetBid(), _Digits), ").");
      return;
   }

   double lot = GetTradeLot();
   if(lot <= 0.0)
   {
      Alert("Sell Limit: invalid lot. Set a lot in the Lot window (or check the balance in Auto mode).");
      return;
   }

   if(mp.Sell_Limit(lot, price, g_slPoints, g_tpPoints))
      Print("EA: Sell Limit placed. Price = ", DoubleToString(price, _Digits),
            ", Lot = ", DoubleToString(lot, 2),
            ", SL = ", DoubleToString(g_slPoints, 1),
            ", TP = ", DoubleToString(g_tpPoints, 1));
   else
      Print("EA: Sell Limit failed. Retcode = ", trade.ResultRetcode(),
            " (", trade.ResultRetcodeDescription(), ")");
}

//+------------------------------------------------------------------+
//| Close_All                                                        |
//+------------------------------------------------------------------+

void CloseAll_OnInit()
{
   UI_CreateButton(m_CloseAll, 100, 155, clrDodgerBlue);
}

// Close_All button: close every open position and delete every pending
// order that has not been triggered yet.
void CloseAll_OnChartEvent(const int id, const string &sparam)
{
   if(id != CHARTEVENT_OBJECT_CLICK || sparam != m_CloseAll)
      return;

   TradeUI_ResetButton(m_CloseAll);

   int closed = 0, deleted = 0, failed = 0;
   bool ok = mp.CloseAll(closed, deleted, failed);

   Print("EA: Close_All - positions closed: ", closed,
         ", pending orders deleted: ", deleted,
         ", failed: ", failed);

   if(!ok)
      Alert("Close_All: ", failed, " item(s) could not be closed. See the Experts log.");
}

//+------------------------------------------------------------------+
//| Info window: shows the current SL, TP, Lot and Price             |
//+------------------------------------------------------------------+

void Info_OnInit()
{
   UI_CreateButton(m_Info, 20, 155, clrDodgerBlue);
}

bool Info_IsOpen()
{
   return (ObjectFind(0, g_infoPrefix + "BG") >= 0);
}

void Info_Close()
{
   TradeUI_DeleteByPrefix(g_infoPrefix);
   ChartRedraw(0);
}

// Builds the window below the Info button.
void Info_Open()
{
   TradeUI_DeleteByPrefix(g_infoPrefix);

   // The window opens below the Info button, aligned to its left edge.
   int ox = 20;
   int oy = 200;
   if(ObjectFind(0, m_Info) >= 0)
   {
      ox = (int)ObjectGetInteger(0, m_Info, OBJPROP_XDISTANCE);
      oy = (int)ObjectGetInteger(0, m_Info, OBJPROP_YDISTANCE)
         + (int)ObjectGetInteger(0, m_Info, OBJPROP_YSIZE) + 5;
   }

   string p = g_infoPrefix;

   string slText    = DoubleToString(g_slPoints, 1) + " points";
   string tpText    = DoubleToString(g_tpPoints, 1) + " points";
   string lotText   = g_lotAuto
                      ? DoubleToString(LotCalc(0.0), 2) + "  (Auto)"
                      : DoubleToString(g_lot, 2) + "  (Manual)";
   string priceText = DoubleToString(UserPrice, _Digits);

   bool ok = true;

   // Frame, title bar and close button
   ok = ok && TradeUI_CreateObject(p + "BG", OBJ_RECTANGLE_LABEL,
                                   ox, oy, 330, 175, "",
                                   clrWhiteSmoke, clrSilver, 10, 1);
   ok = ok && TradeUI_CreateObject(p + "TOP", OBJ_RECTANGLE_LABEL,
                                   ox, oy, 330, 32, "",
                                   clrDarkSlateBlue, clrDarkSlateBlue, 10, 2);
   ok = ok && TradeUI_CreateObject(p + "TITLE", OBJ_LABEL,
                                   ox + 12, oy + 8, 0, 0, "Current Settings",
                                   clrNONE, clrWhite, 11, 10);
   ok = ok && TradeUI_CreateObject(p + "CLOSE", OBJ_BUTTON,
                                   ox + 290, oy + 3, 30, 25, "X",
                                   clrFireBrick, clrWhite, 10, 20);

   // Stop loss
   ok = ok && TradeUI_CreateObject(p + "L_SL", OBJ_LABEL,
                                   ox + 15, oy + 48, 0, 0, "Stop Loss:",
                                   clrNONE, clrBlack, 10, 10);
   ok = ok && TradeUI_CreateObject(p + "V_SL", OBJ_LABEL,
                                   ox + 120, oy + 48, 0, 0, slText,
                                   clrNONE, clrBlack, 10, 10);

   // Take profit
   ok = ok && TradeUI_CreateObject(p + "L_TP", OBJ_LABEL,
                                   ox + 15, oy + 78, 0, 0, "Take Profit:",
                                   clrNONE, clrBlack, 10, 10);
   ok = ok && TradeUI_CreateObject(p + "V_TP", OBJ_LABEL,
                                   ox + 120, oy + 78, 0, 0, tpText,
                                   clrNONE, clrBlack, 10, 10);

   // Lot
   ok = ok && TradeUI_CreateObject(p + "L_LOT", OBJ_LABEL,
                                   ox + 15, oy + 108, 0, 0, "Lot:",
                                   clrNONE, clrBlack, 10, 10);
   ok = ok && TradeUI_CreateObject(p + "V_LOT", OBJ_LABEL,
                                   ox + 120, oy + 108, 0, 0, lotText,
                                   clrNONE, clrBlack, 10, 10);

   // Price
   ok = ok && TradeUI_CreateObject(p + "L_PRICE", OBJ_LABEL,
                                   ox + 15, oy + 138, 0, 0, "Price:",
                                   clrNONE, clrBlack, 10, 10);
   ok = ok && TradeUI_CreateObject(p + "V_PRICE", OBJ_LABEL,
                                   ox + 120, oy + 138, 0, 0, priceText,
                                   clrNONE, clrBlack, 10, 10);

   if(!ok)
   {
      Print("Info: failed to create the window objects. Cleaning up.");
      TradeUI_DeleteByPrefix(p);
   }

   ChartRedraw(0);
}

// Info button: toggles the window. The X button closes it.
void Info_OnChartEvent(const int id, const string &sparam)
{
   if(id != CHARTEVENT_OBJECT_CLICK)
      return;

   if(sparam == m_Info)
   {
      TradeUI_ResetButton(m_Info);

      if(Info_IsOpen())
         Info_Close();
      else
      {
         // Only one window at a time.
         CloseAllDialogs();
         Info_Open();
      }
      return;
   }

   if(sparam == g_infoPrefix + "CLOSE")
      Info_Close();
}

//+------------------------------------------------------------------+
//| Exit                                                             |
//+------------------------------------------------------------------+

void Exit_OnInit()
{
   UI_CreateButton(m_Exit, 180, 155, clrDodgerBlue);
}

// Exit button: delete every chart object and remove the EA from the
// chart. Open positions and pending orders are NOT touched (use
// Close_All first if you want them closed).
void Exit_OnChartEvent(const int id, const string &sparam)
{
   if(id != CHARTEVENT_OBJECT_CLICK || sparam != m_Exit)
      return;

   Print("EA: Exit pressed. Removing the EA and all its objects.");

   CloseAllDialogs();
   Info_Close();
   ObjectsDeleteAll(0);
   ChartRedraw(0);

   // OnDeinit() runs after this and cleans up once more.
   ExpertRemove();
}
