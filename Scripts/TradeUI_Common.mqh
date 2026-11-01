//+--------------------------------------------------------------------------------+
//|                                                                                |
//|    __  __     _   _         ____          _      _                    _        |
//|   |  \/  |   | | | |       / ___|   __ _ | |__  | |__    __ _   __ _ | |__     |
//|   | |\/| |   | |_| |       \___ \  / _` || '_ \ | '_ \  / _` | / _` || '_ \    |
//|   | |  | | _ |  _  | _      ___) || (_| || |_) || |_) || (_| || (_| || | | |   |
//|   |_|  |_|(_)|_| |_|(_)    |____/  \__,_||_.__/ |_.__/  \__,_| \__, ||_| |_|   |
//|                                                                |___/           |
//|                                                                                |
//|   Trade Panel EA  -  TradeUI_Common.mqh                                        |
//|   Shared chart-object helpers: object creation, prefix cleanup,                |
//|   button reset and number parsing. Used by every window and by                 |
//|   the panel buttons.                                                           | 
//|                                                                                |
//|                                                                                |
//|   Author  : M.H. Sabbagh.                                                      |
//|   Year    : 2026                                                               |
//|   GitHub  : github.com/sabbaghmh/Trade_Panel                                   |
//|   Version : 1.0.0            License : MIT License.                            |
//|                                                                                |
//+--------------------------------------------------------------------------------+



#ifndef __TRADE_UI_COMMON_MQH__
#define __TRADE_UI_COMMON_MQH__

// This header is included by several other headers; its include guard
// prevents duplicate function definitions in the main EA.

// Creates (or re-creates) a chart object with the common panel
// properties. Objects whose name starts with a dialog prefix get a
// higher z-order so that they receive clicks before the panel buttons.
bool TradeUI_CreateObject(const string name,
                          const ENUM_OBJECT objectType,
                          const int x,
                          const int y,
                          const int width,
                          const int height,
                          const string text,
                          const color background,
                          const color foreground,
                          const int fontSize,
                          const long zOrder)
{
   if(ObjectFind(0, name) >= 0)
      ObjectDelete(0, name);

   if(!ObjectCreate(0, name, objectType, 0, 0, 0))
   {
      Print("TradeUI: ObjectCreate failed for '", name,
            "'. Error: ", GetLastError());
      return false;
   }

   ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
   ObjectSetInteger(0, name, OBJPROP_HIDDEN, true);
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, name, OBJPROP_SELECTED, false);
   ObjectSetInteger(0, name, OBJPROP_BACK, false);
   // Chart objects with the HIGHER z-order receive the click. Main buttons
   // use 100, so every object of a dialog window is lifted above them;
   // otherwise a main button lying under the window would steal the click
   // meant for the window's own controls (Auto/Manual, edit fields, OK...).
   long z = zOrder;
   if(StringFind(name, "SLTP_DLG_")  == 0 ||
      StringFind(name, "LOT_DLG_")   == 0 ||
      StringFind(name, "PRICE_DLG_") == 0 ||
      StringFind(name, "INFO_DLG_")  == 0)
      z += 1000;
   ObjectSetInteger(0, name, OBJPROP_ZORDER, z);

   if(objectType == OBJ_RECTANGLE_LABEL ||
      objectType == OBJ_BUTTON ||
      objectType == OBJ_EDIT)
   {
      ObjectSetInteger(0, name, OBJPROP_XSIZE, width);
      ObjectSetInteger(0, name, OBJPROP_YSIZE, height);
   }

   if(objectType == OBJ_RECTANGLE_LABEL)
   {
      ObjectSetInteger(0, name, OBJPROP_BGCOLOR, background);
      ObjectSetInteger(0, name, OBJPROP_COLOR, foreground);
      ObjectSetInteger(0, name, OBJPROP_BORDER_TYPE, BORDER_FLAT);
   }
   else if(objectType == OBJ_BUTTON)
   {
      ObjectSetInteger(0, name, OBJPROP_BGCOLOR, background);
      ObjectSetInteger(0, name, OBJPROP_COLOR, foreground);
      ObjectSetInteger(0, name, OBJPROP_FONTSIZE, fontSize);
      ObjectSetInteger(0, name, OBJPROP_STATE, false);
   }
   else if(objectType == OBJ_EDIT)
   {
      ObjectSetInteger(0, name, OBJPROP_BGCOLOR, background);
      ObjectSetInteger(0, name, OBJPROP_COLOR, foreground);
      ObjectSetInteger(0, name, OBJPROP_FONTSIZE, fontSize);
      ObjectSetInteger(0, name, OBJPROP_READONLY, false);
      ObjectSetInteger(0, name, OBJPROP_ALIGN, ALIGN_LEFT);
   }
   else if(objectType == OBJ_LABEL)
   {
      ObjectSetInteger(0, name, OBJPROP_COLOR, foreground);
      ObjectSetInteger(0, name, OBJPROP_FONTSIZE, fontSize);
   }

   if(objectType != OBJ_RECTANGLE_LABEL)
      ObjectSetString(0, name, OBJPROP_TEXT, text);

   return true;
}

// Delete every chart object whose name begins with the given prefix.
void TradeUI_DeleteByPrefix(const string prefix)
{
   int total = ObjectsTotal(0, -1, -1);

   for(int i = total - 1; i >= 0; i--)
   {
      string name = ObjectName(0, i, -1, -1);
      if(StringFind(name, prefix) == 0)
         ObjectDelete(0, name);
   }
}

void TradeUI_ResetButton(const string name)
{
   if(ObjectFind(0, name) >= 0)
   {
      ObjectSetInteger(0, name, OBJPROP_STATE, false);
      ChartRedraw(0);   // Without a redraw the button stays visibly pressed.
   }
}

// Remove objects created by the previous CAppDialog implementation.
// This is deliberately limited to distinctive names from the old files;
// it does not delete unrelated drawings or trading objects from the chart.
void TradeUI_DeleteLegacyDialogObjects(void)
{
   string legacyFragments[9];
   legacyFragments[0] = "SLTPDialog";
   legacyFragments[1] = "LotDialogWindow";
   legacyFragments[2] = "Lot_AutoCheck";
   legacyFragments[3] = "Lot_ManualCheck";
   legacyFragments[4] = "Lot_Label";
   legacyFragments[5] = "Lot_Edit";
   legacyFragments[6] = "Lot_Status";
   legacyFragments[7] = "Lot_OK";
   legacyFragments[8] = "Lot_Cancel";

   int total = ObjectsTotal(0, -1, -1);
   for(int i = total - 1; i >= 0; i--)
   {
      string name = ObjectName(0, i, -1, -1);
      bool isLegacy = false;

      for(int j = 0; j < ArraySize(legacyFragments); j++)
      {
         if(StringFind(name, legacyFragments[j]) >= 0)
         {
            isLegacy = true;
            break;
         }
      }

      if(isLegacy)
         ObjectDelete(0, name);
   }
}

bool TradeUI_ParseNonNegativeNumber(const string sourceText,
                                    double &result)
{
   // `input` is a reserved MQL5 keyword, so this parameter is sourceText.
   // StringTrimLeft/Right modify the string variable in place.
   string value = sourceText;
   StringTrimLeft(value);
   StringTrimRight(value);

   int length = StringLen(value);
   if(length <= 0)
      return false;

   bool hasDigit = false;
   bool hasDot   = false;

   for(int i = 0; i < length; i++)
   {
      ushort ch = StringGetCharacter(value, i);

      if(ch >= '0' && ch <= '9')
      {
         hasDigit = true;
      }
      else if(ch == '.' && !hasDot)
      {
         hasDot = true;
      }
      else
      {
         return false;
      }
   }

   if(!hasDigit)
      return false;

   result = StringToDouble(value);
   if(!MathIsValidNumber(result) || result < 0.0)
      return false;

   return true;
}

#endif // __TRADE_UI_COMMON_MQH__
