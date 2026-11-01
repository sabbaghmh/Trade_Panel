//+--------------------------------------------------------------------------------+
//|                                                                                |
//|    __  __     _   _         ____          _      _                    _        |
//|   |  \/  |   | | | |       / ___|   __ _ | |__  | |__    __ _   __ _ | |__     |
//|   | |\/| |   | |_| |       \___ \  / _` || '_ \ | '_ \  / _` | / _` || '_ \    |
//|   | |  | | _ |  _  | _      ___) || (_| || |_) || |_) || (_| || (_| || | | |   |
//|   |_|  |_|(_)|_| |_|(_)    |____/  \__,_||_.__/ |_.__/  \__,_| \__, ||_| |_|   |
//|                                                                |___/           |
//|                                                                                |
//|   Trade Panel EA  -  SLTP_Dialog.mqh                                           |
//|   SL/TP window: stop loss and take profit in points.                           |
//|   Instance: SLTPDialog.                                                        |
//|                                                                                |
//|                                                                                |
//|   Author  : M.H. Sabbagh.                                                      |
//|   Year    : 2026                                                               |
//|   GitHub  : github.com/sabbaghmh/Trade_Panel                                   |
//|   Version : 1.0.0            License : MIT License.                            |
//|                                                                                |
//+--------------------------------------------------------------------------------+


#ifndef __SLTP_DIALOG_MQH__
#define __SLTP_DIALOG_MQH__

#include "TradeUI_Common.mqh"

//+------------------------------------------------------------------+
//| SL/TP dialog                                                     |
//+------------------------------------------------------------------+
class CSLTPDialog
{
private:
   double m_slPoints;
   double m_tpPoints;
   bool   m_open;
   bool   m_hasResult;

   string m_prefix;
   string m_mainButton;

   bool CreateDialogObjects(void)
   {
      string p = m_prefix;

      if(!TradeUI_CreateObject(p + "BG", OBJ_RECTANGLE_LABEL,
                               20, 60, 330, 205, "",
                               clrWhiteSmoke, clrSilver, 10, 1))
         return false;

      if(!TradeUI_CreateObject(p + "TOP", OBJ_RECTANGLE_LABEL,
                               20, 60, 330, 32, "",
                               clrSteelBlue, clrSteelBlue, 10, 2))
         return false;

      if(!TradeUI_CreateObject(p + "TITLE", OBJ_LABEL,
                               32, 68, 0, 0, "SL/TP Settings",
                               clrNONE, clrWhite, 11, 10))
         return false;

      if(!TradeUI_CreateObject(p + "CLOSE", OBJ_BUTTON,
                               310, 63, 30, 25, "X",
                               clrFireBrick, clrWhite, 10, 20))
         return false;

      if(!TradeUI_CreateObject(p + "LABEL_SL", OBJ_LABEL,
                               35, 115, 0, 0, "Stop Loss (points):",
                               clrNONE, clrBlack, 10, 10))
         return false;

      if(!TradeUI_CreateObject(p + "EDIT_SL", OBJ_EDIT,
                               180, 106, 140, 28,
                               DoubleToString(m_slPoints, 1),
                               clrWhite, clrBlack, 10, 15))
         return false;

      if(!TradeUI_CreateObject(p + "LABEL_TP", OBJ_LABEL,
                               35, 155, 0, 0, "Take Profit (points):",
                               clrNONE, clrBlack, 10, 10))
         return false;

      if(!TradeUI_CreateObject(p + "EDIT_TP", OBJ_EDIT,
                               180, 146, 140, 28,
                               DoubleToString(m_tpPoints, 1),
                               clrWhite, clrBlack, 10, 15))
         return false;

      if(!TradeUI_CreateObject(p + "OK", OBJ_BUTTON,
                               85, 210, 85, 30, "OK",
                               clrSeaGreen, clrWhite, 10, 20))
         return false;

      if(!TradeUI_CreateObject(p + "CANCEL", OBJ_BUTTON,
                               195, 210, 85, 30, "Cancel",
                               clrDimGray, clrWhite, 10, 20))
         return false;

      return true;
   }

   void RemoveDialogObjects(void)
   {
      TradeUI_DeleteByPrefix(m_prefix);
      m_open = false;
      ChartRedraw(0);
   }

public:
   CSLTPDialog(void)
   {
      m_slPoints  = 0.0;
      m_tpPoints  = 0.0;
      m_open      = false;
      m_hasResult = false;
      m_prefix    = "SLTP_DLG_";
      m_mainButton = "SLTP_MAIN_BUTTON";
   }

   bool CreateMainButton(void)
   {
      return TradeUI_CreateObject(m_mainButton, OBJ_BUTTON,
                                  100, 20, 70, 35, "SL/TP",
                                  clrDodgerBlue, clrWhite, 12, 100);
   }

   void DeleteMainButton(void)
   {
      if(ObjectFind(0, m_mainButton) >= 0)
         ObjectDelete(0, m_mainButton);
   }

   void Cleanup(void)
   {
      TradeUI_DeleteByPrefix(m_prefix);
      DeleteMainButton();
      m_open = false;
      ChartRedraw(0);
   }

   bool IsOpen(void) const { return m_open; }
   double SLPoints(void) const { return m_slPoints; }
   double TPPoints(void) const { return m_tpPoints; }

   void OpenDialog(void)
   {
      // Remove possible leftovers before creating a fresh dialog.
      TradeUI_DeleteByPrefix(m_prefix);
      m_open = false;
      m_hasResult = false;

      if(!CreateDialogObjects())
      {
         Print("SLTP: Failed to create dialog objects. Cleaning up.");
         TradeUI_DeleteByPrefix(m_prefix);
         ChartRedraw(0);
         return;
      }

      m_open = true;
      ChartRedraw(0);
   }

   // When the dialog is already closed, don't erase an accepted result
   // that the EA has not retrieved yet.
   void CloseWithoutSaving(void)
   {
      if(m_open)
      {
         m_hasResult = false;
         RemoveDialogObjects();
      }
      else
      {
         TradeUI_DeleteByPrefix(m_prefix);
         ChartRedraw(0);
      }
   }

   // Set SL and TP back to zero and close the window.
   void Reset(void)
   {
      m_slPoints  = 0.0;
      m_tpPoints  = 0.0;
      m_hasResult = false;
      CloseWithoutSaving();
   }

   bool GetValues(double &slPoints, double &tpPoints)
   {
      if(!m_hasResult)
         return false;

      slPoints = m_slPoints;
      tpPoints = m_tpPoints;
      m_hasResult = false;
      return true;
   }

   bool BuildSLTPPrices(const ENUM_ORDER_TYPE orderType,
                        const double entryPrice,
                        double &slPrice,
                        double &tpPrice)
   {
      slPrice = 0.0;
      tpPrice = 0.0;

      double pointSize = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
      if(entryPrice <= 0.0 || pointSize <= 0.0)
         return false;

      if(orderType == ORDER_TYPE_BUY)
      {
         if(m_slPoints > 0.0)
            slPrice = NormalizeDouble(entryPrice - m_slPoints * pointSize,
                                      _Digits);
         if(m_tpPoints > 0.0)
            tpPrice = NormalizeDouble(entryPrice + m_tpPoints * pointSize,
                                      _Digits);
         return true;
      }

      if(orderType == ORDER_TYPE_SELL)
      {
         if(m_slPoints > 0.0)
            slPrice = NormalizeDouble(entryPrice + m_slPoints * pointSize,
                                      _Digits);
         if(m_tpPoints > 0.0)
            tpPrice = NormalizeDouble(entryPrice - m_tpPoints * pointSize,
                                      _Digits);
         return true;
      }

      return false;
   }

   void OnChartEvent(const int id,
                     const long &lparam,
                     const double &dparam,
                     const string &sparam)
   {
      if(!m_open || id != CHARTEVENT_OBJECT_CLICK)
         return;

      if(sparam == m_prefix + "CLOSE" ||
         sparam == m_prefix + "CANCEL")
      {
         TradeUI_ResetButton(sparam);
         CloseWithoutSaving();
         return;
      }

      if(sparam != m_prefix + "OK")
         return;

      TradeUI_ResetButton(sparam);

      string slText = ObjectGetString(0, m_prefix + "EDIT_SL", OBJPROP_TEXT);
      string tpText = ObjectGetString(0, m_prefix + "EDIT_TP", OBJPROP_TEXT);
      double newSL = 0.0;
      double newTP = 0.0;

      if(!TradeUI_ParseNonNegativeNumber(slText, newSL) ||
         !TradeUI_ParseNonNegativeNumber(tpText, newTP))
      {
         Alert("SL/TP must be non-negative decimal numbers, for example 25 or 25.5.");
         return;
      }

      m_slPoints  = newSL;
      m_tpPoints  = newTP;
      m_hasResult = true;
      RemoveDialogObjects();
   }
};

// Single instance of the SL/TP dialog.
CSLTPDialog SLTPDialog;

#endif // __SLTP_DIALOG_MQH__
