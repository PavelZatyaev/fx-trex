//проверяем отдельно взятый символ на корректность
#include "head.mqh"

bool fnSmbCheck(string smb)
   {
      
      // треугольник можно составитьь только из валютных пар
      if(SymbolInfoInteger(smb,SYMBOL_TRADE_CALC_MODE)!=SYMBOL_CALC_MODE_FOREX) return(false);
      
      // если есть ограничения на торговлю то пропускаем этот символ
      if(SymbolInfoInteger(smb,SYMBOL_TRADE_MODE)!=SYMBOL_TRADE_MODE_FULL) return(false);   
      
      // если есть дата начала и окончания контракта то тоже пропускаем, у валют данный параметр не используется
      // нужно т.к. некоторые брокеры для срочных инструментов указывают метод расчёта форекс. так мы их отсеим
      if(SymbolInfoInteger(smb,SYMBOL_START_TIME)!=0)return(false);
      if(SymbolInfoInteger(smb,SYMBOL_EXPIRATION_TIME)!=0) return(false);
      
      // доступность на типы ордеров. хотя робот торгует только маркетами, всё же ограничений быть не должно
      int som=(int)SymbolInfoInteger(smb,SYMBOL_ORDER_MODE);
      int order_mode = SYMBOL_ORDER_MARKET ||
                       SYMBOL_ORDER_LIMIT  ||
                       SYMBOL_ORDER_STOP   ||
                       SYMBOL_ORDER_STOP_LIMIT ||
                       SYMBOL_ORDER_SL ||
                       SYMBOL_ORDER_TP
                       ;
      
      //if((SYMBOL_ORDER_MARKET&som)    != SYMBOL_ORDER_MARKET)  return(false);
      //if((SYMBOL_ORDER_LIMIT&som)     != SYMBOL_ORDER_LIMIT)   return(false);
      //if((SYMBOL_ORDER_STOP&som)      != SYMBOL_ORDER_STOP)    return(false);
      //if((SYMBOL_ORDER_STOP_LIMIT&som)!= SYMBOL_ORDER_STOP_LIMIT) return(false);
      //if((SYMBOL_ORDER_SL&som)        != SYMBOL_ORDER_SL)      return(false);
      //if((SYMBOL_ORDER_TP&som)        != SYMBOL_ORDER_TP)      return(false);
      
      if((order_mode&som) != order_mode) {     
         Print("Error: " + smb);
         return(false);
         }
       
      // проверка стандартной библиотекой на достуность данных         
      if(!csmb.Name(smb)) return(false);
      
      // проверка ниже нужна только в реальной работе так как иногда почему то бываем что SymbolInfoTick работает и цены как-бы 
      // получены а по факту аск или бид=0.
      // в тестере отключаем так как там цены могут появится позже
      if(!(bool)MQLInfoInteger(MQL_TESTER))
      {
         MqlTick tk;      
         if(!SymbolInfoTick(smb,tk)) return(false);
         if(tk.ask<=0 ||  tk.bid<=0) return(false);      
         //if(long(TimeCurrent())*1000 - tk.time_msc > 60000) {  //pz время по паре отстает от времени сервера на 1 мин
         //   Print(smb, ", отставание = ", TimeCurrent(), " ", tk.time_msc, " = ", TimeCurrent()*1000-tk.time_msc);
         //   return(false);
         //   }
      }

      return(true);
   }
