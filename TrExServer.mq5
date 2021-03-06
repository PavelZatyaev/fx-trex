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
  
  double total_profit = 0;
  int profit_cnt = 0;
  int loss_cnt = 0;
  
  if (TrExTotalProfit() > 5*MIN_PROFIT) {
     TrExCloseAll();
     //TrExCloseProfitMore(0.10); // снимаем сливки...
  }
  return;
  
  //TrExClose(total_profit, profit_cnt, loss_cnt);
  //Print("TP ", total_profit);
  //if (total_profit > 5*MIN_PROFIT) {
  //   while(TrExCloseMaxProfit(-100*MIN_PROFIT)); // закрываем все, что больше MIN_PROFIT
  //}
  
  return;
  
  // закрываемся и оцениваем тек. состояние
  while (TrExClose(total_profit, profit_cnt, loss_cnt)) {
  // если убытки, пытаемся как-то компенсировать
   // if(!TrExCloseMaxProfit(0.5*MIN_PROFIT))
    //   Print("Error - нечем ответить((");
  }
  
  if (total_profit > MIN_PROFIT) {     // TUZEMUN ...
     Print("TUZEMUN ...");
     while(TrExCloseMaxProfit(MIN_PROFIT)); // закрываем все, что больше MIN_PROFIT
     return;
  }
  
  if (profit_cnt > loss_cnt && loss_cnt > 0 && total_profit > 0) {
     Print("lite TUZEMUN ...");
     TrExCloseMaxProfit(MIN_PROFIT);
  }
  
  fnInfo();
  
  }
//+------------------------------------------------------------------+
//| Timer function                                                   |
//+------------------------------------------------------------------+
void OnTimer()  {
  }
//+------------------------------------------------------------------+
