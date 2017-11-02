//+------------------------------------------------------------------+
//|                                                   TrExServer.mq5 |
//|                        Copyright 2017, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2017, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"

#include "TrExUtil.mqh"
#include "TrExLib.mqh"

//const string sCurrencySet="EUR,USD,GBP";
//const string sCurrencySet="EUR,USD,GBP,AUD";
//const string sCurrencySet="EUR,USD,GBP,AUD,JPY";
const string sCurrencySet="EUR,USD,GBP,AUD,JPY,CAD";

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
  
  ResetLastError();

   if (!TrExInit(sCurrencySet))
      return(INIT_FAILED);

   TrExGetTicks(true); 

   EventSetTimer(1);
      
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)  {
//--- destroy timer
   EventKillTimer();
   TrExDeinit();
      
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---
  TrExGetTicks(false); // обновляем матрицу коэффициентов...
  TrExOpen();          // открываемся...
  if (TrExClose() > MIN_PROFIT) {     // и закрываемся
     TrExCloseAll(0);
  }
  
  }
//+------------------------------------------------------------------+
//| Timer function                                                   |
//+------------------------------------------------------------------+
void OnTimer()
  {
//  TrExGetTicks(false); 
//  Print("...");
//  for(int i = 0; i < ArraySize(oServer.oStream); i++) {
//    Print(oServer.oStream[i].pair
//        ," ",oServer.oStream[i].data_bid[ArraySize(oServer.oStream[i].data_bid)-1]
//        ," ",oServer.oStream[i].data_ask[ArraySize(oServer.oStream[i].data_ask)-1]
//        ," ",oServer.oStream[i].data_vol[ArraySize(oServer.oStream[i].data_vol)-1]
//        
//        );
//}

//        Print(oServer.oStream[i].pair);
//        ArrayPrint(oServer.oStream[i].data_ask);
//    
//    break;
  }
//+------------------------------------------------------------------+
