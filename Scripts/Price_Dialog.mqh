//+--------------------------------------------------------------------------------+
//|                                                                                |
//|    __  __     _   _         ____          _      _                    _        |
//|   |  \/  |   | | | |       / ___|   __ _ | |__  | |__    __ _   __ _ | |__     |
//|   | |\/| |   | |_| |       \___ \  / _` || '_ \ | '_ \  / _` | / _` || '_ \    |
//|   | |  | | _ |  _  | _      ___) || (_| || |_) || |_) || (_| || (_| || | | |   |
//|   |_|  |_|(_)|_| |_|(_)    |____/  \__,_||_.__/ |_.__/  \__,_| \__, ||_| |_|   |
//|                                                                |___/           |
//|                                                                                |
//|   Trade Panel EA  -  Price_Dialog.mqh                                          |
//|   Price window: price entry for limit orders. Opens below the                  |
//|   Price button. Instance: PriceDialog.                                         |
//|                                                                                |
//|                                                                                |
//|   Author  : M.H. Sabbagh.                                                      |
//|   Year    : 2026                                                               |
//|   GitHub  : github.com/sabbaghmh/Trade_Panel                                   |
//|   Version : 1.0.0            License : MIT License.                            |
//|                                                                                |
//+--------------------------------------------------------------------------------+


#ifndef __PRICE_DIALOG_MQH__
#define __PRICE_DIALOG_MQH__

#include "TradeUI_Common.mqh"

// Price input dialog. Uses the same visual style and helper functions
// as the Lot dialog.
class CPriceDialog
{
private:
   double m_priceValue;       // Last price accepted with OK
   double m_tempPriceValue;   // Temporary value while dialog is open
   bool   m_open;

   string m_prefix;
   string m_mainButton;

   bool CreateDialogObjects(void)
   {
      string p = m_prefix;

      // The window opens directly below the Price button, with its left
      // edge aligned to the button. Offsets below are relative to that
      // origin (ox, oy).
      int ox = 100;
      int oy = 150;
      if(ObjectFind(0, m_mainButton) >= 0)
      {
         ox = (int)ObjectGetInteger(0, m_mainButton, OBJPROP_XDISTANCE);
         oy = (int)ObjectGetInteger(0, m_mainButton, OBJPROP_YDISTANCE)
            + (int)ObjectGetInteger(0, m_mainButton, OBJPROP_YSIZE) + 5;
      }

      if(!TradeUI_CreateObject(p + "BG", OBJ_RECTANGLE_LABEL,
                               ox, oy, 330, 175, "",
                               clrWhiteSmoke, clrSilver, 10, 1))
         return false;

      if(!TradeUI_CreateObject(p + "TOP", OBJ_RECTANGLE_LABEL,
                               ox, oy, 330, 32, "",
                               clrDarkSlateBlue, clrDarkSlateBlue, 10, 2))
         return false;

      if(!TradeUI_CreateObject(p + "TITLE", OBJ_LABEL,
                               ox + 12, oy + 8, 0, 0, "Price Settings",
                               clrNONE, clrWhite, 11, 10))
         return false;

      if(!TradeUI_CreateObject(p + "CLOSE", OBJ_BUTTON,
                               ox + 290, oy + 3, 30, 25, "X",
                               clrFireBrick, clrWhite, 10, 20))
         return false;

      if(!TradeUI_CreateObject(p + "LABEL_PRICE", OBJ_LABEL,
                               ox + 15, oy + 55, 0, 0, "Price:",
                               clrNONE, clrBlack, 10, 10))
         return false;

      if(!TradeUI_CreateObject(p + "EDIT_PRICE", OBJ_EDIT,
                               ox + 80, oy + 47, 210, 28,
                               DoubleToString(m_tempPriceValue, _Digits),
                               clrWhite, clrBlack, 10, 15))
         return false;

      if(!TradeUI_CreateObject(p + "STATUS", OBJ_LABEL,
                               ox + 15, oy + 88, 0, 0, "Enter a price and press OK",
                               clrNONE, clrBlack, 9, 10))
         return false;

      if(!TradeUI_CreateObject(p + "OK", OBJ_BUTTON,
                               ox + 55, oy + 125, 85, 30, "OK",
                               clrSeaGreen, clrWhite, 10, 20))
         return false;

      if(!TradeUI_CreateObject(p + "CANCEL", OBJ_BUTTON,
                               ox + 170, oy + 125, 85, 30, "Cancel",
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
   CPriceDialog(void)
   {
      m_priceValue     = 0.0;
      m_tempPriceValue = 0.0;
      m_open           = false;
      m_prefix         = "PRICE_DLG_";
      m_mainButton     = "PriceButton";
   }

   // Creates the main chart button labelled "Price".
   bool CreateMainButton(void)
   {
      return TradeUI_CreateObject(m_mainButton, OBJ_BUTTON,
                                  100, 110, 70, 35, "Price",
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
   double GetPrice(void) const { return m_priceValue; }

   void OpenDialog(void)
   {
      TradeUI_DeleteByPrefix(m_prefix);
      m_open = false;

      // Show the previously accepted price, without changing it yet.
      m_tempPriceValue = m_priceValue;

      if(!CreateDialogObjects())
      {
         Print("Price: Failed to create dialog objects. Cleaning up.");
         TradeUI_DeleteByPrefix(m_prefix);
         ChartRedraw(0);
         return;
      }

      m_open = true;
      ChartRedraw(0);
   }

   // Set the accepted price back to zero and close the window.
   void Reset(void)
   {
      m_priceValue     = 0.0;
      m_tempPriceValue = 0.0;
      CloseWithoutSaving();
   }

   void CloseWithoutSaving(void)
   {
      if(m_open)
         m_tempPriceValue = m_priceValue;

      RemoveDialogObjects();
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

      string priceText = ObjectGetString(0, m_prefix + "EDIT_PRICE",
                                         OBJPROP_TEXT);
      double newPrice = 0.0;

      if(!TradeUI_ParseNonNegativeNumber(priceText, newPrice) ||
         newPrice <= 0.0)
      {
         Alert("Please enter a valid price greater than zero.");
         return;
      }

      // Normalize to the current symbol's displayed precision.
      newPrice = NormalizeDouble(newPrice, _Digits);

      // Save only after the user presses OK and the value is valid.
      m_priceValue     = newPrice;
      m_tempPriceValue = newPrice;

      Print("Price accepted: ", DoubleToString(m_priceValue, _Digits));
      RemoveDialogObjects();
   }
};

// Single instance of the Price dialog.
CPriceDialog PriceDialog;

#endif // __PRICE_DIALOG_MQH__
