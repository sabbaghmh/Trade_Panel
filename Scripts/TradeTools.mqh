//+--------------------------------------------------------------------------------+
//|                                                                                |
//|    __  __     _   _         ____          _      _                    _        |
//|   |  \/  |   | | | |       / ___|   __ _ | |__  | |__    __ _   __ _ | |__     |
//|   | |\/| |   | |_| |       \___ \  / _` || '_ \ | '_ \  / _` | / _` || '_ \    |
//|   | |  | | _ |  _  | _      ___) || (_| || |_) || |_) || (_| || (_| || | | |   |
//|   |_|  |_|(_)|_| |_|(_)    |____/  \__,_||_.__/ |_.__/  \__,_| \__, ||_| |_|   |
//|                                                                |___/           |
//|                                                                                |
//|   Trade Panel EA  -  TradeTools.mqh                                            |
//|   Trading helpers: account / price helpers, order execution                    |
//|   (MPositions).                                                                |
//|                                                                                |
//|   Contents                                                                     |
//|   GetBalance(), LotCalc(),                                                     |
//|   GetBid(), GetAsk(),                                                          |
//|   class MPositions                                                             |
//|       Buy_p(), Sell_p()            market orders                               |
//|       Buy_Limit(), Sell_Limit()    pending orders                              |
//|       CloseAll()                   closing                                     | 
//|                                                                                |
//|                                                                                |
//|   Author  : M.H. Sabbagh.                                                      |
//|   Year    : 2026                                                               |
//|   GitHub  : github.com/sabbaghmh/Trade_Panel                                   |
//|   Version : 1.0.0            License : MIT License.                            |
//|                                                                                |
//+--------------------------------------------------------------------------------+


#ifndef __TRADE_TOOLS_MQH__
#define __TRADE_TOOLS_MQH__

#include <Trade\Trade.mqh>
#include "TradeUI_Common.mqh"   // TradeUI_CreateObject()

//+------------------------------------------------------------------+
//| Settings                                                         |
//+------------------------------------------------------------------+

// Maximum number of open positions: Buy_p() / Sell_p() open a new
// position only while PositionsTotal() is below this value.
#ifndef MAX_POSITIONS
#define MAX_POSITIONS 2
#endif

// Maximum number of pending orders allowed at the same time.
#ifndef MAX_PENDING_ORDERS
#define MAX_PENDING_ORDERS 2
#endif

// Shared trade object used by every order function in this file.
CTrade trade;

//+------------------------------------------------------------------+
//| Account and price helpers                                        |
//+------------------------------------------------------------------+

double GetBalance()
{
   return AccountInfoDouble(ACCOUNT_BALANCE);
}

// Automatic lot size: 0.01 lot for every 50 units of account balance.
// The Balance parameter is ignored; the balance is always read from
// the account.
double LotCalc(double Balance)
{
   Balance = AccountInfoDouble(ACCOUNT_BALANCE);
   Balance = Balance / 50;

   return MathFloor(Balance) * 0.01;
}

double GetBid()
{
   return NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_BID), _Digits);
}

double GetAsk()
{
   return NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_ASK), _Digits);
}

//+------------------------------------------------------------------+
//| MPositions: market orders, pending orders and closing            |
//|                                                                  |
//| slPoints / tpPoints are distances in points from the entry       |
//| price. A value of 0 means "no stop loss" / "no take profit".     |
//+------------------------------------------------------------------+
class MPositions
{
public:

   // Market Buy at the Ask price.
   bool Buy_p(double Lot, double Ask, double slPoints, double tpPoints)
   {
      if(PositionsTotal() >= MAX_POSITIONS)
         return false;

      double sl = (slPoints > 0.0) ? NormalizeDouble(Ask - slPoints * _Point, _Digits) : 0.0;
      double tp = (tpPoints > 0.0) ? NormalizeDouble(Ask + tpPoints * _Point, _Digits) : 0.0;

      return trade.Buy(Lot, _Symbol, Ask, sl, tp, "Buy");
   }

   // Market Sell at the Bid price.
   bool Sell_p(double Lot, double Bid, double slPoints, double tpPoints)
   {
      if(PositionsTotal() >= MAX_POSITIONS)
         return false;

      double sl = (slPoints > 0.0) ? NormalizeDouble(Bid + slPoints * _Point, _Digits) : 0.0;
      double tp = (tpPoints > 0.0) ? NormalizeDouble(Bid - tpPoints * _Point, _Digits) : 0.0;

      return trade.Sell(Lot, _Symbol, Bid, sl, tp, "Sell");
   }

   // Buy Limit at price HLP (must be below the current Ask).
   bool Buy_Limit(double Lot, double HLP, double slPoints, double tpPoints)
   {
      if(OrdersTotal() >= MAX_PENDING_ORDERS)
         return false;

      double sl = (slPoints > 0.0) ? NormalizeDouble(HLP - slPoints * _Point, _Digits) : 0.0;
      double tp = (tpPoints > 0.0) ? NormalizeDouble(HLP + tpPoints * _Point, _Digits) : 0.0;

      return trade.BuyLimit(Lot, NormalizeDouble(HLP, _Digits), _Symbol, sl, tp, ORDER_TIME_DAY);
   }

   // Sell Limit at price HLP (must be above the current Bid).
   bool Sell_Limit(double Lot, double HLP, double slPoints, double tpPoints)
   {
      if(OrdersTotal() >= MAX_PENDING_ORDERS)
         return false;

      double sl = (slPoints > 0.0) ? NormalizeDouble(HLP + slPoints * _Point, _Digits) : 0.0;
      double tp = (tpPoints > 0.0) ? NormalizeDouble(HLP - tpPoints * _Point, _Digits) : 0.0;

      return trade.SellLimit(Lot, NormalizeDouble(HLP, _Digits), _Symbol, sl, tp, ORDER_TIME_DAY);
   }

   // Closes every open position and deletes every pending order (orders
   // that are placed but not yet triggered). Returns true only if
   // everything was closed / deleted. The counters report what was done.
   bool CloseAll(int &closedPositions, int &deletedOrders, int &failed)
   {
      closedPositions = 0;
      deletedOrders   = 0;
      failed          = 0;

      // Open positions. Loop backwards because the list shrinks as
      // positions are closed.
      for(int i = PositionsTotal() - 1; i >= 0; i--)
      {
         ulong ticket = PositionGetTicket(i);
         if(ticket == 0)
            continue;

         if(trade.PositionClose(ticket))
            closedPositions++;
         else
         {
            failed++;
            Print("CloseAll: failed to close position #", ticket,
                  ". Retcode = ", trade.ResultRetcode(),
                  " (", trade.ResultRetcodeDescription(), ")");
         }
      }

      // Pending orders (Buy/Sell Limit, Buy/Sell Stop, Stop Limit).
      for(int i = OrdersTotal() - 1; i >= 0; i--)
      {
         ulong ticket = OrderGetTicket(i);
         if(ticket == 0)
            continue;

         if(trade.OrderDelete(ticket))
            deletedOrders++;
         else
         {
            failed++;
            Print("CloseAll: failed to delete pending order #", ticket,
                  ". Retcode = ", trade.ResultRetcode(),
                  " (", trade.ResultRetcodeDescription(), ")");
         }
      }

      return (failed == 0);
   }
};

#endif // __TRADE_TOOLS_MQH__
