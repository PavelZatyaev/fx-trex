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
/*
struct refArrXY {
    double val[];
};

double _arr_x[], _arr_c[];
refArrXY _arr_xy[];
//========================================================================
double coeff(double &data[]) {
    if(ArraySize(_arr_x) == 0) {
        ArrayResize(_arr_x,  ArraySize(data));
        ArrayResize(_arr_xy, ArraySize(data));
        ArrayResize(_arr_c,  ArraySize(data));
        
       for(int i = 0; i < ArraySize(data); i++) {
           _arr_x[i]  = i;
           ArrayResize(_arr_xy[i].val,  ArraySize(data));
           }
       }
   Gram(_arr_x, data, _arr_xy);
   Gauss (_arr_xy,_arr_c);
   return(_arr_c[1]);
   }

//========================================================================
void Gram(double &x[], double &f[], refArrXY &a[]) {
int n, m;
double p, q, r, s;

   n = ArraySize(x)-1; m = 1;
   
   for(int j = 0; j <= m; j++) {
       s=0.0; r=0.0; q=0.0;
       for(int i = 0; i <= n; i++) {
           p = (j == 1) ? x[i] : 1.0;
           s += p; r += p*f[i]; q += p*x[i];
           }
       a[0].val[j] = s; a[j].val[m] = q; a[j].val[m+1] = r;
       }
   for(int i = 1; i <= m; i++) {
       for(int j = 0; j <= m-1; j++) a[i].val[j] = a[i-1].val[j+1];
       }
}

//========================================================================
void Gauss(refArrXY &a[], double &x[]) {
int n, n1, k1;
double s, r;

    n = 1; n1 = n+1;

    for(int k = 0; k <= n; k++) {
       k1 = k+1;
       s = a[k].val[k];
       for(int i = k1; i <= n1; i++) a[k].val[i] /= s;
       for(int i = k1; i <= n; i++) {
           r = a[i].val[k];
           for(int j = k1; j <= n1; j++) a[i].val[j] -= a[k].val[j]*r;
           }
       }
    for(int i = n; i >= 0; i--) {
       s = a[i].val[n1];
       for(int j = i+1; j <= n; j++) s -= a[i].val[j]*x[j];
       x[i] = s;
       }
}
*/
//========================================================================
void CreateSymbolList00(string &Symbols[])
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

void CreateSymbolList(string &Symbols[]) {
      for(int i=SymbolsTotal(true)-1;i>=0;i--)
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
