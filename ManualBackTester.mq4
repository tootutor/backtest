//+------------------------------------------------------------------+
//|                                             ManualBackTester.mq4 |
//|                                        Copyright 2017, Witoon S. |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Copyright 2017, Witoon S."
#property link      ""
#property version   "1.00"
#property strict

#include <WinUser32.mqh>

// External Parameter
extern string EAName = "ManualBackTester";

enum LOGMODE {
   LOGMODE_PRINT,
   LOGMODE_NOTIFY,
   LOGMODE_BOTH
};

// Global variables
int ticket = 0;
double price = 0;
int slip = 10;
string comment = "";
double lot = 0.01;
double tp = 0;
double sl = 0;
datetime lastTime;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---
   
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---
      string message;
      LoadAndProcessAction();
      ClearActionFile();
      if (Time[0] == lastTime) {
         // Do nothing
      } else {
         lastTime = Time[0];
         message = "lastTime = " + TimeToString(lastTime);
         NotifyAndLog("ALL", 0, message, LOGMODE_PRINT);
         ReportActiveOrder();
         ReportHistoryOrder();
         ReportAccount();
         BreakPoint();
      }
  }
//+------------------------------------------------------------------+

void BreakPoint() {
   if(IsVisualMode()) {
      keybd_event(19,0,0,0);
      Sleep(10);
      keybd_event(19,0,2,0);
   }
}

void LoadAndProcessAction() {
   int filehandle=FileOpen("ManualBackTesterAction.csv", FILE_READ|FILE_CSV, ",");
   string message;
   string dummy;
   string active;
   string action;
   string parms;
   
   if(filehandle!=INVALID_HANDLE) { 
      //message = "Loading trade action";
      //NotifyAndLog("ALL", 0, message, LOGMODE_PRINT);
      //Dummy read header row
      dummy = FileReadString(filehandle);
      dummy = FileReadString(filehandle);
      dummy = FileReadString(filehandle);
      while(!FileIsEnding(filehandle)) { 
         active = FileReadString(filehandle);
         action = FileReadString(filehandle);
         parms = FileReadString(filehandle);
         //message = "  active=" + active
         //        + "  action=" + action
         //        + "; parms=" + parms
         //;
         //NotifyAndLog("ALL", 0, message, LOGMODE_PRINT);
         if (active == "Y") {
            //NotifyAndLog("ALL", 0, "Processing active trade action");
            ProcessAction(action, parms);
         } else {
            //NotifyAndLog("ALL", 0, "Bypass process non-active");
         }
      } 
      FileClose(filehandle); 
   } else {
      NotifyAndLog("ALL", 0, "Error load trade action file");
   }
}

string OrderTypeName(int orderType) {
   switch (orderType) {
      case OP_BUY:
         return "BUY";
         break;
      case OP_SELL:
         return "SELL";
         break;
      case OP_BUYSTOP:
         return "BUY STOP";
         break;
      case OP_SELLSTOP:
         return "SELL STOP";
         break;
      case OP_BUYLIMIT:
         return "BUY LIMIT";
         break;
      case OP_SELLLIMIT:
         return "SELL LIMIT";
         break;
   }
   return "N/A";
}

void ClearActionFile() {
   int filehandle=FileOpen("ManualBackTesterAction.csv", FILE_WRITE|FILE_CSV, ",");
   int totalOrder = OrdersTotal();
   FileWrite(
      filehandle,
      "Active",
      "Action",
      "Parameters"
   );
   FileClose(filehandle);
}

void ReportAccount() {
   int filehandle=FileOpen("ManualBackTesterAccount.csv", FILE_WRITE|FILE_CSV, ",");
   int totalOrder = OrdersTotal();
   FileWrite(
      filehandle,
      "Balance",
      "Credit",
      "Equity",
      "FreeMargin",
      "Margin",
      "Profit"
   );
   FileWrite(
      filehandle,
      AccountBalance(),
      AccountCredit(),
      AccountEquity(),
      AccountFreeMargin(),
      AccountMargin(),
      AccountProfit()
   );
   FileClose(filehandle);
}


void ReportActiveOrder() {
   int filehandle=FileOpen("ManualBackTesterActiveOrder.csv", FILE_WRITE|FILE_CSV, ",");
   int totalOrder = OrdersTotal();
   FileWrite(
      filehandle,
      "Symbol",
      "Ticket",
      "OrderType",
      "OpenTime",
      "OpenPrice",
      "Lot",
      "SL",
      "TP",
      "Profit",
      "Magic",
      "Comment"
   );
   for ( int j=totalOrder-1; j>=0; j-- ) {
      if ( OrderSelect(j, SELECT_BY_POS, MODE_TRADES) ) {
         FileWrite(
            filehandle,
            OrderSymbol(),
            IntegerToString(OrderTicket()),
            OrderTypeName(OrderType()),
            TimeToString(OrderOpenTime()),
            DoubleToString(OrderOpenPrice()),
            DoubleToString(OrderLots()),
            DoubleToString(OrderStopLoss()),
            DoubleToString(OrderTakeProfit()),
            DoubleToString(OrderProfit()),
            IntegerToString(OrderMagicNumber()),
            OrderComment()
         );
      }
   }
   FileClose(filehandle);
}

void ReportHistoryOrder() {
   int filehandle=FileOpen("ManualBackTesterHistoryOrder.csv", FILE_WRITE|FILE_CSV, ",");
   int totalOrder = OrdersHistoryTotal();
   FileWrite(
      filehandle,
      "Symbol",
      "Ticket",
      "OrderType",
      "OpenTime",
      "OpenPrice",
      "CloseTime",
      "ClosePrice",
      "Lot",
      "SL",
      "TP",
      "Profit",
      "Magic",
      "Comment"
   );
   for ( int j=totalOrder-1; j>=0; j-- ) {
      if ( OrderSelect(j, SELECT_BY_POS, MODE_HISTORY) ) {
         FileWrite(
            filehandle,
            OrderSymbol(),
            IntegerToString(OrderTicket()),
            OrderTypeName(OrderType()),
            TimeToString(OrderOpenTime()),
            DoubleToString(OrderOpenPrice()),
            TimeToString(OrderCloseTime()),
            DoubleToString(OrderClosePrice()),
            DoubleToString(OrderLots()),
            DoubleToString(OrderStopLoss()),
            DoubleToString(OrderTakeProfit()),
            DoubleToString(OrderProfit()),
            IntegerToString(OrderMagicNumber()),
            OrderComment()
         );
      }
   }
   FileClose(filehandle);
}

void ProcessAction(string action, string parms) {
   NotifyAndLog("ALL", 0, "Processing action " + action);
   SetUpParms(parms);
   if (action == "BUY") {ProcessBuy();}
   if (action == "SELL") {ProcessSell();}
   if (action == "BUYSTOP") {ProcessBuyStop();}
   if (action == "SELLSTOP") {ProcessSellStop();}
   if (action == "BUYLIMIT") {ProcessBuyLimit();}
   if (action == "SELLLIMIT") {ProcessSellLimit();}
   if (action == "MODIFYTP") {ProcessModifyTP();}
   if (action == "MODIFYSL") {ProcessModifySL();}
   if (action == "DELETE") {ProcessDelete();}
   if (action == "CLOSE") {ProcessClose();}
}

void SetUpParms(string parms) {
   ushort parmSep = StringGetCharacter(";", 0);
   string parmArray[];
   int i;
   int parmCnt = StringSplit(parms, parmSep, parmArray);

   // Initialize global variables
   ticket = 0;
   price = 0;
   lot = 0.01;
   sl = 0;
   tp = 0;
   comment = "";
   
   for (i=0; i<parmCnt; i++) {
      NotifyAndLog("ALL", 0, "Parm = " + parmArray[i]);
      SetUpParmValue(parmArray[i]);
   }
}

void SetUpParmValue(string parm) {
   ushort parmValSep = StringGetCharacter("=", 0);
   string parmValArray[];
   int parmValCnt = StringSplit(parm, parmValSep, parmValArray);

   if (parmValArray[0] == "ticket") {
      ticket = StringToInteger(parmValArray[1]);
   }
   if (parmValArray[0] == "price") {
      price = StringToDouble(parmValArray[1]);
   }
   if (parmValArray[0] == "slip") {
      slip = StringToInteger(parmValArray[1]);
   }
   if (parmValArray[0] == "lot") {
      lot = StringToDouble(parmValArray[1]);
   }
   if (parmValArray[0] == "sl") {
      sl = StringToDouble(parmValArray[1]);
   }
   if (parmValArray[0] == "tp") {
      tp = StringToDouble(parmValArray[1]);
   }
   if (parmValArray[0] == "comment") {
      comment = parmValArray[1];
   }
}

void ProcessBuy() {
   int newTicket = OrderSend(Symbol(), OP_BUY, lot, Ask, slip, sl, tp, comment);
   if (newTicket < 0) {
      NotifyAndLog("ALL", 0, "Can't open new order");
   }
}

void ProcessSell() {
   int newTicket = OrderSend(Symbol(), OP_SELL, lot, Bid, slip, sl, tp, comment);
   if (newTicket < 0) {
      NotifyAndLog("ALL", 0, "Can't open new order");
   }
};

void ProcessBuyStop() {
   int newTicket = OrderSend(Symbol(), OP_BUYSTOP, lot, price, slip, sl, tp, comment);
   if (newTicket < 0) {
      NotifyAndLog("ALL", 0, "Can't open new order");
   }
};

void ProcessSellStop() {
   int newTicket = OrderSend(Symbol(), OP_SELLSTOP, lot, price, slip, sl, tp, comment);
   if (newTicket < 0) {
      NotifyAndLog("ALL", 0, "Can't open new order");
   }
};

void ProcessBuyLimit() {
   int newTicket = OrderSend(Symbol(), OP_BUYLIMIT, lot, price, slip, sl, tp, comment);
   if (newTicket < 0) {
      NotifyAndLog("ALL", 0, "Can't open new order");
   }
};

void ProcessSellLimit() {
   int newTicket = OrderSend(Symbol(), OP_SELLLIMIT, lot, price, slip, sl, tp, comment);
   if (newTicket < 0) {
      NotifyAndLog("ALL", 0, "Can't open new order");
   }
};

void ProcessModify() {
   if (OrderSelect(ticket,SELECT_BY_TICKET)) {
      if (OrderModify(OrderTicket(), OrderOpenPrice(), sl, tp, 0)) {
         NotifyAndLog("ALL", 0, "Can't modify ticket " + IntegerToString(ticket));
      };
   } else {
      NotifyAndLog("ALL", 0, "Not found ticket " + IntegerToString(ticket));
   }
};

void ProcessModifyTP() {
   if (OrderSelect(ticket,SELECT_BY_TICKET)) {
      if (OrderModify(OrderTicket(), OrderOpenPrice(), OrderStopLoss(), tp, 0)) {
         NotifyAndLog("ALL", 0, "Can't modify ticket " + IntegerToString(ticket));
      }
   } else {
      NotifyAndLog("ALL", 0, "Not found ticket " + IntegerToString(ticket));
   }
};

void ProcessModifySL() {
   if (OrderSelect(ticket,SELECT_BY_TICKET)) {
      if (OrderModify(OrderTicket(), OrderOpenPrice(), sl, OrderTakeProfit(), 0)) {
         NotifyAndLog("ALL", 0, "Can't modify ticket " + IntegerToString(ticket));
      }
   } else {
      NotifyAndLog("ALL", 0, "Not found ticket " + IntegerToString(ticket));
   }
}

void ProcessDelete() {
   if (OrderSelect(ticket,SELECT_BY_TICKET)) {
      if (OrderDelete(OrderTicket())) {
         NotifyAndLog("ALL", 0, "Can't delete ticket " + IntegerToString(ticket));
      }
   } else {
      NotifyAndLog("ALL", 0, "Not found ticket " + IntegerToString(ticket));
   }
};

void ProcessClose() {
   if (OrderSelect(ticket,SELECT_BY_TICKET)) {
      if (OrderType() == OP_BUY) {
         if (OrderClose(OrderTicket(), OrderLots(), Bid, slip)) {
            NotifyAndLog("ALL", 0, "Can't close ticket " + IntegerToString(ticket));
         }
      } else {
         if (OrderClose(OrderTicket(), OrderLots(), Ask, slip)) {
            NotifyAndLog("ALL", 0, "Can't close ticket " + IntegerToString(ticket));
         }
      }
   } else {
      NotifyAndLog("ALL", 0, "Not found ticket " + IntegerToString(ticket));
   }
};

void NotifyAndLog(string symbol, int timeframe, string Message, int logMode = LOGMODE_BOTH) {
   string HeadText = EAName + ": Symbol= " + symbol + "; Timeframe=" + IntegerToString(timeframe) + "; ";
   switch (logMode) {
      case LOGMODE_PRINT:
         Print(HeadText + Message);
         break;
      case LOGMODE_NOTIFY:
         SendNotification(HeadText + Message);
         break;
      case LOGMODE_BOTH:
         Print(HeadText + Message);
         SendNotification(HeadText + Message);
         break;
   }
}

