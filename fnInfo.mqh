#include "head.mqh"
#include "TrExLib.mqh"

void fnInfo() {
   string txt = "";
   double total_profit = 0;
   double profit;
   string position_type;
   int buy_count = 0;
   int sell_count = 0;
   int profit_count = 0;
   
   for(int i=0; i<ArraySize(oServer.oStream); i++)   {
      if(!PositionSelect(oServer.oStream[i].pair))
         continue;
      profit=PositionGetDouble(POSITION_PROFIT);
      if (profit) 
         profit_count++;

      if(PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_SELL) {
         position_type = "SELL";
         sell_count ++;
         }
      if(PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_BUY) {
         position_type = "BUY";
         buy_count ++;
         }
      
      total_profit += profit;
      txt += oServer.oStream[i].pair + ", " + position_type + ": " + DoubleToString(profit) + 
         ", B/S: " + IntegerToString(oServer.oStream[i].buy_count) + "/" + IntegerToString(oServer.oStream[i].sell_count) + "\n";
     }    
     txt += "TOTAL: " + IntegerToString(sell_count + buy_count) + ", PROFIT POS: " + IntegerToString(profit_count) + ", PROFIT" + DoubleToString(total_profit);
 
  
  Comment(txt);
}