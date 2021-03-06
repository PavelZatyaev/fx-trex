//+------------------------------------------------------------------+
//|                                                     TrExUtil.mqh |
//|                        Copyright 2017, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2017, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"

//+------------------------------------------------------------------+
//|  Процедуры общего назначения                                     |
//+------------------------------------------------------------------+

#include "head.mqh"

const string sSeparator = ",";

const int cADD_UNIQUE_STRING = 1; // добавить в массив уникальную строку
const int cADD_LIMIT_DOUBLE = 2;    // добавить в массив с проверкой длины массива
const int cSET_LAST_DOUBLE = 3;     // записать в последний элемент массива

int ArrAdd(string &arr[], int max_sz, string val, int mode) {
    bool flag = false;
    if (mode == cADD_UNIQUE_STRING) {
        for (int j = 0; j < ArraySize(arr); j++) {
            if (arr[j] == val) {
                flag = true;
                break;
                }
            }
        if (!flag) {
            ArrayResize(arr, ArraySize(arr)+1);
            arr[ArraySize(arr)-1] = val;
            }
    }
return ArraySize(arr);
}

//========================================================================
int ArrAdd(double &arr[], int max_sz, double val, int mode) {
    if (mode == cADD_LIMIT_DOUBLE) {
        if (ArraySize(arr) >= max_sz) {
            for(int i = 0; i < ArraySize(arr)-1; i++) arr[i] = arr[i+1];
            arr[ArraySize(arr)-1] = val;
            }
        else {
            ArrayResize(arr, ArraySize(arr)+1);
            arr[ArraySize(arr)-1] = val;
        } 
    }
    
    if (mode == cSET_LAST_DOUBLE) {
        if (ArraySize(arr) == 0)
            ArrayResize(arr, ArraySize(arr)+1);
        arr[ArraySize(arr)-1] = val;
    }
    
return ArraySize(arr);
}

//========================================================================
int ArrIndex(string &arr[], string str) {
    int idx = -1;
    for (int i = 0; i < ArraySize(arr); i++) {
        if (arr[i] == str)
            return i;
        }
    return idx;        
}


//========================================================================
void CreateSymbolList(string &Symbols[])
   {
string Currencies[] = {"AED", "AUD", "BHD", "BRL", "CAD", "CHF", "CNY", 
                       "CYP", "CZK", "DKK", "DZD", "EEK", "EGP", "EUR",
                       "GBP", "HKD", "HRK", "HUF", "IDR", "ILS", "INR",
                       "IQD", "IRR", "ISK", "JOD", "JPY", "KRW", "KWD",
                       "LBP", "LTL", "LVL", "LYD", "MAD", "MXN", "MYR",
                       "NOK", "NZD", "OMR", "PHP", "PLN", "QAR", "RON",
                       "RUB", "SAR", "SEK", "SGD", "SKK", "SYP", "THB",
                       "TND", "TRY", "TWD", "USD", "VEB", "XAG", "XAU",
                       "YER", "ZAR", "_","DJI","DXY","ES","GC","NQ","QG","QM","SI"};    
    int Loop, SubLoop;
    string TempSymbol;
    MqlTick  tick;
    for(Loop = 0; Loop < ArraySize(Currencies); Loop++)
      for(SubLoop = 0; SubLoop < ArraySize(Currencies); SubLoop++)
         {
          TempSymbol = Currencies[Loop] + Currencies[SubLoop];
          if(SymbolInfoTick(TempSymbol, tick))
            {
             ArrayResize(Symbols, ArraySize(Symbols)+1);
             Symbols[ArraySize(Symbols)-1] = TempSymbol;
            }
         }
}

void CreateSymbolList00(string &Symbols[]) {
      for(int i=SymbolsTotal(false)-1;i>=0;i--)
      {
         string smb=SymbolName(i,true);
         
         // функция проверки символа на доступность торговли, также используетсяс при составлении треугольников.
         // там её и рассмотрим более подробно
         if(!fnSmbCheck(smb)) continue;
         
         double cs=SymbolInfoDouble(smb,SYMBOL_TRADE_CONTRACT_SIZE);
         if(cs!=100000) { 
            Alert("Attention: "+smb+", contract size = "+DoubleToString(cs,0));      
            continue;   
            }
            ArrayResize(Symbols, ArraySize(Symbols)+1);
            Symbols[ArraySize(Symbols)-1] = smb;
            Print("ADD " + smb);
      }
}


//========================================================================
string GetPair(string &_SymbolList[], string curr0, string curr1) {
    string pair0 = curr0+curr1;
    string pair1 = curr1+curr0;
    
    int idx = ArrIndex(_SymbolList, pair0);
    if (idx >= 0) return pair0;
    
    idx = ArrIndex(_SymbolList, pair1);
    if (idx >= 0) return pair1;
    return "";
}


//=================================================================================================
string SymbolPosition(string symbol,string position,string side) {
    string val_buy  = StringSubstr(symbol,0,3);
    string val_sell = StringSubstr(symbol,3,3);
    if (position == "SELL") {
        val_buy  = StringSubstr(symbol,3,3);
        val_sell = StringSubstr(symbol,0,3);
        }
   
    return (side == "BUY")?val_buy : val_sell;
}

//=================================================================================================
void PrintE(string msg) {
    Print("Error: " + msg);
}

//=================================================================================================
ulong bits_count(ulong value) {
    return ( value ) ? ( value & 1 ) + bits_count(value >> 1) : 0;
}

//=================================================================================================
uchar NumberCount(double val) {
   val -= MathFloor(val);
   string str = DoubleToString(val,16);
   int count = 0;
   for(int i = StringLen(str)-1; i >= 0; i--) {
     if(StringGetCharacter(str, i) != '0')
        break;
     count++;
   }
   str = StringSubstr(str,0,StringLen(str)-count);
   return uchar(StringLen(str)-2);
}

//=================================================================================================
double _MathMean(double &array[], int start, int size)
  {
   double mean=0.0;
   for(int i=start; i<start+size; mean+=array[i++]);
   return(mean/size);
  }
