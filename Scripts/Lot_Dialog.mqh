//+--------------------------------------------------------------------------------+
//|                                                                                |
//|    __  __     _   _         ____          _      _                    _        |
//|   |  \/  |   | | | |       / ___|   __ _ | |__  | |__    __ _   __ _ | |__     |
//|   | |\/| |   | |_| |       \___ \  / _` || '_ \ | '_ \  / _` | / _` || '_ \    |
//|   | |  | | _ |  _  | _      ___) || (_| || |_) || |_) || (_| || (_| || | | |   |
//|   |_|  |_|(_)|_| |_|(_)    |____/  \__,_||_.__/ |_.__/  \__,_| \__, ||_| |_|   |
//|                                                                |___/           |
//|                                                                                |
//|   Trade Panel EA  -  Lot_Dialog.mqh                                            |
//|   Lot window: Auto (LotCalc) or Manual lot size, 0.01 - 50.00.                 |
//|   Instance: LotDialog.                                                         |
//|                                                                                |
//|                                                                                |
//|   Author  : M.H. Sabbagh.                                                      |
//|   Year    : 2026                                                               |
//|   GitHub  : github.com/sabbaghmh/Trade_Panel                                   |
//|   Version : 1.0.0            License : MIT License.                            |
//|                                                                                |
//+--------------------------------------------------------------------------------+


#ifndef __LOT_DIALOG_MQH__
#define __LOT_DIALOG_MQH__

#include "TradeUI_Common.mqh"
#include "TradeTools.mqh"   // LotCalc()

//+------------------------------------------------------------------+
//| Lot dialog                                                       |
//+------------------------------------------------------------------+
class CLotDialog
{
private:
   double m_lotValue;       // Last accepted lot
   bool   m_isAutoMode;     // Last accepted mode
   double m_tempLotValue;   // Current uncommitted lot
   bool   m_tempAutoMode;   // Current uncommitted mode
   bool   m_open;
   bool   m_hasResult;      // OK accepted, not yet read by the EA

   string m_prefix;
   string m_mainButton;

   bool CreateDialogObjects(void)
   {
      string p = m_prefix;

      if(!TradeUI_CreateObject(p + "BG", OBJ_RECTANGLE_LABEL,
                               20, 60, 330, 210, "",
                               clrWhiteSmoke, clrSilver, 10, 1))
         return false;

      if(!TradeUI_CreateObject(p + "TOP", OBJ_RECTANGLE_LABEL,
                               20, 60, 330, 32, "",
                               clrDarkSlateBlue, clrDarkSlateBlue, 10, 2))
         return false;

      if(!TradeUI_CreateObject(p + "TITLE", OBJ_LABEL,
                               32, 68, 0, 0, "Lot Settings",
                               clrNONE, clrWhite, 11, 10))
         return false;

      if(!TradeUI_CreateObject(p + "CLOSE", OBJ_BUTTON,
                               310, 63, 30, 25, "X",
                               clrFireBrick, clrWhite, 10, 20))
         return false;

      if(!TradeUI_CreateObject(p + "AUTO", OBJ_BUTTON,
                               35, 105, 135, 30, "Auto: ON",
                               clrDodgerBlue, clrWhite, 10, 20))
         return false;

      if(!TradeUI_CreateObject(p + "MANUAL", OBJ_BUTTON,
                               185, 105, 135, 30, "Manual: OFF",
                               clrDimGray, clrWhite, 10, 20))
         return false;

      if(!TradeUI_CreateObject(p + "LABEL_LOT", OBJ_LABEL,
                               35, 155, 0, 0, "Lot size:",
                               clrNONE, clrBlack, 10, 10))
         return false;

      if(!TradeUI_CreateObject(p + "EDIT_LOT", OBJ_EDIT,
                               110, 147, 130, 28,
                               DoubleToString(m_tempLotValue, 2),
                               clrWhite, clrBlack, 10, 15))
         return false;

      if(!TradeUI_CreateObject(p + "STATUS", OBJ_LABEL,
                               35, 190, 0, 0, "Automatic lot mode",
                               clrNONE, clrBlack, 9, 10))
         return false;

      if(!TradeUI_CreateObject(p + "OK", OBJ_BUTTON,
                               75, 225, 85, 30, "OK",
                               clrSeaGreen, clrWhite, 10, 20))
         return false;

      if(!TradeUI_CreateObject(p + "CANCEL", OBJ_BUTTON,
                               190, 225, 85, 30, "Cancel",
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

   void UpdateModeControls(void)
   {
      if(!m_open)
         return;

      if(m_tempAutoMode)
      {
         ObjectSetString(0, m_prefix + "AUTO", OBJPROP_TEXT, "Auto: ON");
         ObjectSetInteger(0, m_prefix + "AUTO", OBJPROP_BGCOLOR, clrDodgerBlue);
         ObjectSetInteger(0, m_prefix + "AUTO", OBJPROP_COLOR, clrWhite);

         ObjectSetString(0, m_prefix + "MANUAL", OBJPROP_TEXT, "Manual: OFF");
         ObjectSetInteger(0, m_prefix + "MANUAL", OBJPROP_BGCOLOR, clrDimGray);
         ObjectSetInteger(0, m_prefix + "MANUAL", OBJPROP_COLOR, clrWhite);

         // Auto mode: show the calculated lot in the (disabled) field.
         ObjectSetString(0, m_prefix + "EDIT_LOT", OBJPROP_TEXT,
                         DoubleToString(LotCalc(0.0), 2));
         ObjectSetInteger(0, m_prefix + "EDIT_LOT", OBJPROP_READONLY, true);
         ObjectSetInteger(0, m_prefix + "EDIT_LOT", OBJPROP_BGCOLOR, clrGainsboro);
         ObjectSetString(0, m_prefix + "STATUS", OBJPROP_TEXT,
                         "Automatic lot mode selected");
      }
      else
      {
         ObjectSetString(0, m_prefix + "AUTO", OBJPROP_TEXT, "Auto: OFF");
         ObjectSetInteger(0, m_prefix + "AUTO", OBJPROP_BGCOLOR, clrDimGray);
         ObjectSetInteger(0, m_prefix + "AUTO", OBJPROP_COLOR, clrWhite);

         ObjectSetString(0, m_prefix + "MANUAL", OBJPROP_TEXT, "Manual: ON");
         ObjectSetInteger(0, m_prefix + "MANUAL", OBJPROP_BGCOLOR, clrDarkOrange);
         ObjectSetInteger(0, m_prefix + "MANUAL", OBJPROP_COLOR, clrBlack);

         // Coming from Auto mode: replace the calculated lot with the
         // last manual value. Keep what the user typed if already manual.
         if(ObjectGetInteger(0, m_prefix + "EDIT_LOT", OBJPROP_READONLY))
            ObjectSetString(0, m_prefix + "EDIT_LOT", OBJPROP_TEXT,
                            DoubleToString(m_lotValue, 2));
         ObjectSetInteger(0, m_prefix + "EDIT_LOT", OBJPROP_READONLY, false);
         ObjectSetInteger(0, m_prefix + "EDIT_LOT", OBJPROP_BGCOLOR, clrWhite);
         ObjectSetString(0, m_prefix + "STATUS", OBJPROP_TEXT,
                         "Manual lot: enter 0.01 to 50.00");
      }

      ChartRedraw(0);
   }

public:
   CLotDialog(void)
   {
      m_lotValue     = 0.01;
      m_isAutoMode   = true;
      m_tempLotValue = 0.01;
      m_tempAutoMode = true;
      m_open         = false;
      m_hasResult    = false;
      m_prefix       = "LOT_DLG_";
      m_mainButton   = "LotButton";
   }

   bool CreateMainButton(void)
   {
      return TradeUI_CreateObject(m_mainButton, OBJ_BUTTON,
                                  180, 20, 70, 35, "Lot",
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
   double GetLotValue(void) const { return m_lotValue; }
   bool IsAutoMode(void) const { return m_isAutoMode; }
   bool IsManualMode(void) const { return !m_isAutoMode; }

   void OpenDialog(void)
   {
      TradeUI_DeleteByPrefix(m_prefix);
      m_open = false;

      // Begin with accepted values; edits are temporary until OK.
      m_tempLotValue = m_lotValue;
      m_tempAutoMode = m_isAutoMode;

      if(!CreateDialogObjects())
      {
         Print("Lot: Failed to create dialog objects. Cleaning up.");
         TradeUI_DeleteByPrefix(m_prefix);
         ChartRedraw(0);
         return;
      }

      m_open = true;
      UpdateModeControls();
      ChartRedraw(0);
   }

   // Set the accepted lot back to zero and close the window.
   void Reset(void)
   {
      m_lotValue     = 0.0;
      m_tempLotValue = 0.0;
      m_hasResult    = false;
      CloseWithoutSaving();
   }

   // True once after OK was accepted; returns the accepted settings.
   bool GetValues(double &lot, bool &autoMode)
   {
      if(!m_hasResult)
         return false;

      lot      = m_lotValue;
      autoMode = m_isAutoMode;
      m_hasResult = false;
      return true;
   }

   void CloseWithoutSaving(void)
   {
      if(m_open)
      {
         // Throw away temporary changes and preserve accepted settings.
         m_tempLotValue = m_lotValue;
         m_tempAutoMode = m_isAutoMode;
         RemoveDialogObjects();
      }
      else
      {
         TradeUI_DeleteByPrefix(m_prefix);
         ChartRedraw(0);
      }
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

      if(sparam == m_prefix + "AUTO")
      {
         TradeUI_ResetButton(sparam);
         m_tempAutoMode = true;
         UpdateModeControls();
         return;
      }

      if(sparam == m_prefix + "MANUAL")
      {
         TradeUI_ResetButton(sparam);
         m_tempAutoMode = false;
         UpdateModeControls();
         return;
      }

      if(sparam != m_prefix + "OK")
         return;

      TradeUI_ResetButton(sparam);

      if(m_tempAutoMode)
      {
         m_isAutoMode = true;
         m_tempLotValue = m_lotValue;
         m_hasResult = true;
         Print("Lot settings accepted: automatic mode.");
         RemoveDialogObjects();
         return;
      }

      string lotText = ObjectGetString(0, m_prefix + "EDIT_LOT", OBJPROP_TEXT);
      double newLot = 0.0;

      if(!TradeUI_ParseNonNegativeNumber(lotText, newLot) ||
         newLot < 0.01 || newLot > 50.0)
      {
         Alert("Manual lot must be a decimal number between 0.01 and 50.00.");
         return;
      }

      // Commit the lot and mode only after validation and OK.
      m_lotValue     = newLot;
      m_isAutoMode   = false;
      m_tempLotValue = newLot;
      m_tempAutoMode = false;
      m_hasResult    = true;

      Print("Lot settings accepted: manual mode, lot = ",
            DoubleToString(m_lotValue, 2));

      RemoveDialogObjects();
   }
};

// Single instance of the Lot dialog.
CLotDialog LotDialog;

#endif // __LOT_DIALOG_MQH__
