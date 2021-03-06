//+------------------------------------------------------------------+
//|                                                      TrExLib.mqh |
//|                        Copyright 2017, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2017, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
//+------------------------------------------------------------------+
//| Фукционал TrEx                                                   |
//+------------------------------------------------------------------+
#include "TrExUtil.mqh"
#include "head.mqh"

//+------------------------------------------------------------------+
//| Структуры данных TrExServer                                      |
//+------------------------------------------------------------------+
#define DEVIATION       1     // Максимально возможное проскальзывание


#define FIBO_START      6     // индекс, начиная с 0, первого числа Фибоначчи 1,2,3,5,8,13,21,34,55,89,144,233,377,610,987
#define FIBO_STOP       FIBO_START+5     // количество усреднений == (FIBO_STOP - FIBO_START)
#define SZ_VECTOR       5     // кол-во точек для расчета вектора

int _szBufferData;            // размер буфера тиков (для инициализации и обработки)
#define SZ_BUFFER_FLOW  10    // размер буфера котировок (для текущее чтение)

#define MIN_PROFIT  2         // размер прибыли/убытка в режиме закрытия 1 (стартовый режим)

double THRESHOLD_LOSS[10];  // пороги потерь в зависимости от тек. профита

const ulong TrMagic=1122;
//CSymbolInfo    csmb;          // Класс CSymbolInfo стандартной библиотеки

struct refStream 
  {
   string            pair;              // имя пары (символ)
   int               currIdx1;             // индекс первой валюты в паре
   int               currIdx2;             // индекс второй валюты в паре
                                           // синхронизированные массивы котировок:
   // значения котировок по всем обрабатываемым символам синхронизированы:
   // т.е. при получении нового тика по любому символу данные записываются в соотв. массив
   // при этом
   double            data_ask[];      // синхронизированный массив котировок 
   double            data_bid[];      // синхронизированный массив котировок bid
   double            data_vol[];      // синхронизированный массив котировок volume 

   double            norm_data[];     // нормированный синхронизированный массив котировок (ask+bid)/2

   MqlTick           ticks[];         // буфер последних SZ_BUFFER тиков  
   int               ticksIdx;        // индекс последнего тика, добаленного в синхр. массив
   long              time_msc;        // время последнего тика, добаленного в синхр. массив

   double            tv;              // Значение SYMBOL_TRADE_TICK_VALUE_PROFIT (Рассчитанная стоимость тика для прибыльной позиции)
   MqlTick           flow_tick;       // значение текущего тика (отдает больше инфы)
   int               Rpoint;          // 1/point, чтобы в формулах на это значение умножать а не делить
   int               digits;          // Количество знаков после запятой в котировке
   double            dev;             // Возможное проскальзывание в поинтах
   uchar             digits_lot;      // Количество знаков после запятой в лоте, для округления

   double            lot;            // Объём торговли для валютной пары    
   double            lot_min;        // Минимальный объём
   double            lot_max;        // Максимальный объём
   double            lot_step;       // Шаг лота
   double            contract;       // Размер контракта
   double            sppoint;        // Спред в целых пунктах
   double            spcost;         // Спред в деньгах на текущий открываемый лот    
   double            pointcost;      // Цена одного пункта
   ulong             ticket;         // тикет ордера которым открыта сделка. нужна только для удобства в хедж счетах
   double            loss_percent;   // макс. процент потерь
   double            profit;         // макс. доход  
   double            prev_profit;    // доход/убыток на пред. шаге
   
   int               buy_count;      // счетчик сигналов BUY
   int               sell_count;     // счетчик сигналов SELL
  };
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
struct refStreamValue 
  {
   int               idx;        // индекс потока
   double            coeff[]; // значения векторов на соотв. уровнях усреднения
  };
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
struct refCurrencyMatrix 
  {
   refStreamValue    oStreamValue[];
  };
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
struct refServer 
  {
   string            asCurrencySet[];   // контролируемый набор валют
   refStream         oStream[];      // данные по соот. парам валют
   refCurrencyMatrix oCurrencyMatrix[]; // таблица индексов валютных пар (потоков)
   uint              sz_series[];                // массив количества элементов в усреднении
   double            series_data[SZ_VECTOR];   // массив для расчета усреднений  
   //void PrintCoeff(int row, int col) {Print (
   //                                        oCurrencyMatrix[row].oStreamValue[col].coeff[0], " ", 
   //                                        oCurrencyMatrix[row].oStreamValue[col].coeff[1], " ", 
   //                                        oCurrencyMatrix[row].oStreamValue[col].coeff[2], " ", 
   //                                        oCurrencyMatrix[row].oStreamValue[col].coeff[3], " "
   //                                        ); }
   string CoeffToStr(int idx) {
   
           int row, col;
           GetMatrixPosition(idx, row, col);

                                         return
                                           DoubleToString(oCurrencyMatrix[row].oStreamValue[col].coeff[0]) + " " +
                                           DoubleToString(oCurrencyMatrix[row].oStreamValue[col].coeff[1]) + " " +
                                           DoubleToString(oCurrencyMatrix[row].oStreamValue[col].coeff[2]) + " " +
                                           DoubleToString(oCurrencyMatrix[row].oStreamValue[col].coeff[3]);
                    }
  };

refServer oServer;
///////////////////////////////////////////////////////////////////////////////////////////////////
void TrExDeinit() 
  {
  }
///////////////////////////////////////////////////////////////////////////////////////////////////
bool TrExInit(string _sCurrencySet) 
  {
   string SymbolList[];

   ResetLastError();

   CreateSymbolList(SymbolList);
   StringSplit(_sCurrencySet,StringGetCharacter(sSeparator,0),oServer.asCurrencySet);

// idx = int((profit /  MIN_PROFIT) -1);

   THRESHOLD_LOSS[0]=0.50;  // 
   THRESHOLD_LOSS[1] = 0.55;
   THRESHOLD_LOSS[2] = 0.60;
   THRESHOLD_LOSS[3] = 0.65;
   THRESHOLD_LOSS[4] = 0.75;
   THRESHOLD_LOSS[5] = 0.80;
   THRESHOLD_LOSS[6] = 0.85;
   THRESHOLD_LOSS[7] = 0.90;
   THRESHOLD_LOSS[8] = 0.92;
   THRESHOLD_LOSS[9] = 0.95;
   
   THRESHOLD_LOSS[0] = 1.0;  // 
   THRESHOLD_LOSS[1] = 1.0;  // 
   THRESHOLD_LOSS[2] = 1.0;  // 
   THRESHOLD_LOSS[3] = 1.0;  // 
   THRESHOLD_LOSS[4] = 1.0;  // 
   THRESHOLD_LOSS[5] = 1.0;  // 
   THRESHOLD_LOSS[6] = 1.0;  // 
   THRESHOLD_LOSS[7] = 1.0;  // 
   THRESHOLD_LOSS[8] = 1.0;  // 
   THRESHOLD_LOSS[9] = 1.0;  // 
   

// инициализируем массив размеров серий усреднений 
   uint val1 = 0;
   uint val2 = 1;
   ArrayResize(oServer.sz_series,FIBO_STOP-FIBO_START);
   for(int i=0; i<FIBO_STOP; i++) 
     {
      uint val=val1+val2;
      if(i>=FIBO_START) 
        {
         oServer.sz_series[i-FIBO_START]=val;
        }
      val1 = val2;
      val2 = val;
     }

   _szBufferData=int(SZ_VECTOR*oServer.sz_series[ArraySize(oServer.sz_series)-1]);
//if (SZ_VECTOR * oServer.sz_series[ArraySize(oServer.sz_series)-1] > _szBufferData) {
//   PrintE("Необходимо увеличить размер буфера до " + IntegerToString(SZ_VECTOR * oServer.sz_series[ArraySize(oServer.sz_series)-1]));
//   return(false);
//}

// проверяем наличие нужных пар на терминале
// и формируем массив торгуемых пар для заданного набора валют
   string arr[];
   ArrayResize(oServer.oCurrencyMatrix,ArraySize(oServer.asCurrencySet));
   for(int i=0; i<ArraySize(oServer.asCurrencySet); i++) 
     {
      ArrayResize(oServer.oCurrencyMatrix[i].oStreamValue,ArraySize(oServer.asCurrencySet));
      for(int j=0; j<ArraySize(oServer.asCurrencySet); j++) 
        {
         if(oServer.asCurrencySet[i]==oServer.asCurrencySet[j])
            continue;
            Print("000 ",oServer.asCurrencySet[i],oServer.asCurrencySet[j]);
         string pair=GetPair(SymbolList,oServer.asCurrencySet[i],oServer.asCurrencySet[j]);
         if(pair=="") 
           {
            Print("Пара "+oServer.asCurrencySet[i]+oServer.asCurrencySet[j]+
                  " ("+oServer.asCurrencySet[j]+oServer.asCurrencySet[i]+") не настроена на терминале");
            return(false);
           }
         ArrAdd(arr,-1,pair,cADD_UNIQUE_STRING);
        }
     }
   ArrayResize(oServer.oStream,ArraySize(arr));

// проверяем соответствие пар и кол-ва валют
   long n=ArraySize(oServer.asCurrencySet)-1;
   n=StringToInteger(DoubleToString(MathRound((((2.0+(n-1))/2.0)*n)),0));
   if(n!=ArraySize(oServer.oStream)) 
     {
      Print("Нет соответствия кол-ва валют и валютных пар в графе "+IntegerToString(n));
      return(false);
     }

// устанавливаем индексы потоков в матрице векторов и инициализируем массивы коэффициентов
   for(int i=0; i<ArraySize(oServer.asCurrencySet); i++) 
     {
      for(int j=0; j<ArraySize(oServer.asCurrencySet); j++) 
        {
         oServer.oCurrencyMatrix[i].oStreamValue[j].idx=-1;
         ArrayResize(oServer.oCurrencyMatrix[i].oStreamValue[j].coeff,ArraySize(oServer.sz_series));
         ArrayInitialize(oServer.oCurrencyMatrix[i].oStreamValue[j].coeff,0);
         if(i==j)
            continue;
         string pair=oServer.asCurrencySet[i]+oServer.asCurrencySet[j];
         int idx= ArrIndex(arr, pair);
         if(idx>=0) 
           {
            oServer.oCurrencyMatrix[i].oStreamValue[j].idx = (idx+1);  // прямой поток
            oServer.oCurrencyMatrix[j].oStreamValue[i].idx = -(idx+1); // реверс
           }
        }
     }

// инициализируем массивы исходных данных
   for(int i=0; i<ArraySize(oServer.oStream); i++) 
     {
      oServer.oStream[i].pair=arr[i];
      oServer.oStream[i].currIdx1 = ArrIndex(oServer.asCurrencySet, StringSubstr(arr[i],0,3));
      oServer.oStream[i].currIdx2 = ArrIndex(oServer.asCurrencySet, StringSubstr(arr[i],3,3));
      oServer.oStream[i].ticksIdx = 0;
      oServer.oStream[i].time_msc = 0;

      ArrayResize(oServer.oStream[i].data_ask, _szBufferData);
      ArrayResize(oServer.oStream[i].data_bid, _szBufferData);
      ArrayResize(oServer.oStream[i].data_vol, _szBufferData);
      ArrayResize(oServer.oStream[i].norm_data, _szBufferData);

      ArrayInitialize(oServer.oStream[i].data_ask, 0);
      ArrayInitialize(oServer.oStream[i].data_bid, 0);
      ArrayInitialize(oServer.oStream[i].data_vol, 0);

      // получаем данные по символу...
      if(!csmb.Name(oServer.oStream[i].pair)) 
        {
         PrintE("нет данных по символу "+oServer.oStream[i].pair);
         return(false);
        }

      oServer.oStream[i].Rpoint=int(NormalizeDouble(1/csmb.Point(),0)); // перевод в пункты
      oServer.oStream[i].digits=csmb.Digits();                          // разрядность
      oServer.oStream[i].dev=csmb.TickSize()*DEVIATION;                 // проскальзывание
      oServer.oStream[i].digits_lot= NumberCount(csmb.LotsStep());      // округление лота

                                                                        // Ограничения по объёмам, сразу нормализованные
      oServer.oStream[i].lot_min=NormalizeDouble(csmb.LotsMin(),3);
      oServer.oStream[i].lot_max=NormalizeDouble(csmb.LotsMax(),3);
      oServer.oStream[i].lot_step=NormalizeDouble(csmb.LotsStep(),3);

      //Размер контракта 
      oServer.oStream[i].contract=csmb.ContractSize();

      // пока так
      oServer.oStream[i].lot= 0.01; //oServer.oStream[i].lot_min;
      
      oServer.oStream[i].pointcost = oServer.oStream[i].contract*oServer.oStream[i].lot * SymbolInfoDouble(oServer.oStream[i].pair, SYMBOL_POINT);
      
    //  oServer.oStream[i].pointcost = SymbolInfoDouble(oServer.oStream[i].pair, SYMBOL_POINT);
      
     }

// создаем слои матриц векторов по количеству вариантов усреднений
//ArrayResize(oServer.oLayerTab, ArraySize(oServer.sz_series));
//// инициализируем...
//for(int i = 0; i < ArraySize(oServer.oLayerTab); i++) {
//    ArrayResize(oServer.oLayerTab[i].Row, ArraySize(oServer.asCurrencySet));
//    for(int j = 0; j < ArraySize(oServer.asCurrencySet); j++) {
//        ArrayResize(oServer.oLayerTab[i].Row[j].Col, ArraySize(oServer.asCurrencySet));
//    }
//}


   return(true);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool TrExGetTicks(bool start) 
  {
   int sz_buff=start? _szBufferData : SZ_BUFFER_FLOW;
// получаем тики по всем символам
   for(int i=0; i<ArraySize(oServer.oStream); i++) 
     {
      //int n = CopyTicks(oServer.oStream[i].pair,oServer.oStream[i].ticks,COPY_TICKS_ALL,0,sz_buff);
      //int n = CopyTicks(oServer.oStream[i].pair,oServer.oStream[i].ticks,COPY_TICKS_TRADE,0,sz_buff);
      int n=CopyTicks(oServer.oStream[i].pair,oServer.oStream[i].ticks,COPY_TICKS_INFO,0,sz_buff);
      if(ArraySize(oServer.oStream[i].ticks)!=sz_buff) 
        {
         PrintE("CopyTicks "+oServer.oStream[i].pair+", "+IntegerToString(n));
         return false;
        }
     }
// определяем начало "свежих" данных в считанных тиках
//Print("+++");
   for(int i=0; i<ArraySize(oServer.oStream); i++) 
     {
      //Print(oServer.oStream[i].pair," ",
      //oServer.oStream[i].ticks[sz_buff-1].bid,
      //" ",
      //oServer.oStream[i].ticks[sz_buff-1].ask
      //);
      oServer.oStream[i].ticksIdx=-1;
      for(int j=0; j<ArraySize(oServer.oStream[i].ticks); j++) 
        {
         if(oServer.oStream[i].time_msc<oServer.oStream[i].ticks[j].time_msc) 
           {
            oServer.oStream[i].time_msc = oServer.oStream[i].ticks[j].time_msc;
            oServer.oStream[i].ticksIdx = j;
            // Print(oServer.oStream[i].pair," ",oServer.oStream[i].time_msc," ",oServer.oStream[i].ticks[j].time," ",oServer.oStream[i].ticks[(start? _szBufferData : SZ_BUFFER_FLOW)-1].time );
            break;
           }
        }
      if(oServer.oStream[i].ticksIdx==-1) 
        {
         if(start) 
           {
            PrintE("Sync 01 "+oServer.oStream[i].pair);
            return false;
           }
         else 
           {
            oServer.oStream[i].ticksIdx = sz_buff-1;
            oServer.oStream[i].time_msc = oServer.oStream[i].ticks[oServer.oStream[i].ticksIdx].time_msc;
           }
        }
     }
// синхронно заполняем массивы ask/bid/vol
   int min_idx=0;  // произвольно индекс потока с самым "старым" тиком
   long min_time=oServer.oStream[min_idx].time_msc; // время самого "старого" тика в этом потоке
                                                    //int debug_cnt = 0;
   bool flag;
   while(true) 
     {
      // найдем поток с самыми "старыми" данными
      flag=false;
      for(int i=0; i<ArraySize(oServer.oStream); i++) 
        {
         if(oServer.oStream[i].ticksIdx>=sz_buff)
            continue;
         if(min_time>=oServer.oStream[i].time_msc) 
           {
            min_idx  = i;
            min_time = oServer.oStream[min_idx].time_msc;
            flag=true;
           }
        }

      //Print(debug_cnt," ",oServer.oStream[min_idx].pair," ", oServer.oStream[min_idx].ticksIdx," ", flag);

      if(!flag) 
        {  // не нашли, проверим - все ли потоки действительно закончились
         for(int i=0; i<ArraySize(oServer.oStream); i++) 
           {
            if(oServer.oStream[i].ticksIdx>=sz_buff)
               continue;
            min_time=oServer.oStream[i].time_msc;
            flag=true;
            break;
           }
         if(flag)
            continue;  // найден незакончившийся поток
         break;
        }

      double val;
      for(int i=0; i<ArraySize(oServer.oStream); i++) 
        {
         if(min_idx==i) 
           {
            // добавляем в синхр. массивы найденной пары данные
            val=oServer.oStream[min_idx].ticks[oServer.oStream[min_idx].ticksIdx].ask;
            ArrAdd(oServer.oStream[min_idx].data_ask,_szBufferData,
                   val,
                   cADD_LIMIT_DOUBLE);

            val=oServer.oStream[min_idx].ticks[oServer.oStream[min_idx].ticksIdx].bid;
            ArrAdd(oServer.oStream[min_idx].data_bid,_szBufferData,
                   val,
                   cADD_LIMIT_DOUBLE);

            val=oServer.oStream[min_idx].ticks[oServer.oStream[min_idx].ticksIdx].last;
            ArrAdd(oServer.oStream[min_idx].data_vol, _szBufferData,
                   val,
                   cADD_LIMIT_DOUBLE);
           }
         else 
           {  // у остальных продублируем последнее значение
            val=oServer.oStream[i].data_ask[_szBufferData-1];
            ArrAdd(oServer.oStream[i].data_ask,_szBufferData,
                   val,
                   cADD_LIMIT_DOUBLE);

            val=oServer.oStream[i].data_bid[_szBufferData-1];
            ArrAdd(oServer.oStream[i].data_bid,_szBufferData,
                   val,
                   cADD_LIMIT_DOUBLE);

            val=oServer.oStream[i].data_vol[_szBufferData-1];
            ArrAdd(oServer.oStream[i].data_vol,_szBufferData,
                   val,
                   cADD_LIMIT_DOUBLE);
           }
        }

      oServer.oStream[min_idx].ticksIdx++;
      if(oServer.oStream[min_idx].ticksIdx<sz_buff) 
        {
         oServer.oStream[min_idx].time_msc=oServer.oStream[min_idx].ticks[oServer.oStream[min_idx].ticksIdx].time_msc;
         min_time=oServer.oStream[min_idx].time_msc;
        }
     }

// return true;

// обновляем нормированный массив по каждому потоку
   double val;
   for(int i=0; i<ArraySize(oServer.oStream); i++) 
     {
      val=(oServer.oStream[i].data_ask[_szBufferData-1]+
           oServer.oStream[i].data_bid[_szBufferData-1]);
      if(val==0)
         continue;
      val=100000/val;
      for(int j=0; j<_szBufferData; j++) 
        {
         oServer.oStream[i].norm_data[j]=100000-(oServer.oStream[i].data_ask[j]+oServer.oStream[i].data_bid[j])*val;
        }
      //Print(val);
      //  ArrayPrint(oServer.oStream[i].norm_data);
     }

// считаем коэффициенты потоков по слоям...
   for(int i=0; i<ArraySize(oServer.sz_series); i++) 
     {
      int sz_seria=int(oServer.sz_series[i]); // размер серии в текущем слое
      for(int j=0; j<ArraySize(oServer.oStream); j++) 
        {
         // считаем среднее, свежие данные ближе к "хвосту"
         for(int k=ArraySize(oServer.oStream[j].norm_data)-sz_seria*ArraySize(oServer.series_data),k1=0;
             k1<ArraySize(oServer.series_data); k+=sz_seria,k1++) 
           {
            oServer.series_data[k1]=_MathMean(oServer.oStream[j].norm_data,k,sz_seria);
           }
         // найдем поток в матрице валют
         flag=false;
         for(int row=0; row<ArraySize(oServer.oCurrencyMatrix); row++) 
           {
            for(int col=0; col<ArraySize(oServer.oCurrencyMatrix[row].oStreamValue); col++) 
              {
               if(oServer.oCurrencyMatrix[row].oStreamValue[col].idx==(j+1)) 
                 {
                  oServer.oCurrencyMatrix[row].oStreamValue[col].coeff[i] = csup.coeff(oServer.series_data);
                  oServer.oCurrencyMatrix[col].oStreamValue[row].coeff[i] = -oServer.oCurrencyMatrix[row].oStreamValue[col].coeff[i];
                  flag=true;
                  break;
                 }
              }
            if(flag)
               break;
           }
        }
     }

   return true;
  }
//=================================================================================================
// выбираем самую перспективную пару и открываемся...
//
void TrExOpen() 
  {
   int idxStream;
   string Direction;

   GetLeadingStream(idxStream,Direction);

   if(idxStream<0)
      return;

   if(PositionSelect(oServer.oStream[idxStream].pair)) 
     {// на паре есть открытая позиция
      bool close=false;
      if(PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_BUY) {
         oServer.oStream[idxStream].buy_count++;
         if(Direction=="SELL")
            close=true;
        }
      if(PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_SELL && Direction=="BUY") {
         oServer.oStream[idxStream].sell_count++;
         if(Direction=="BUY")
            close=true;
        }

      double profit;
close=false;
      if(!PositionGetProfit(profit,idxStream))
         return;

      if(close && profit>0.5*MIN_PROFIT && profit<MIN_PROFIT) 
        {
         Print(oServer.oStream[idxStream].pair+": close change trend: ",profit,", ticket: ", oServer.oStream[idxStream].ticket);
         PositionClose(idxStream);
        }

      return;
     }

   //Print(oServer.oStream[idxStream].pair," ",Direction);

   ctrade.SetExpertMagicNumber(TrMagic);

   if(Direction== "BUY") 
     {
      if(ctrade.Buy(oServer.oStream[idxStream].lot,oServer.oStream[idxStream].pair,0,0,0,"TrEx " + IntegerToString(TrMagic))) {
         Print(oServer.oStream[idxStream].pair + ": OPEN "+ Direction + " " + oServer.CoeffToStr(idxStream));
         oServer.oStream[idxStream].buy_count = 1;
         oServer.oStream[idxStream].sell_count = 0;
         }
     }
   else 
     {
      if(ctrade.Sell(oServer.oStream[idxStream].lot,oServer.oStream[idxStream].pair,0,0,0,"TrEx " + IntegerToString(TrMagic))) {
         Print(oServer.oStream[idxStream].pair + ": OPEN "+ Direction + " " + oServer.CoeffToStr(idxStream));
         oServer.oStream[idxStream].buy_count = 0;
         oServer.oStream[idxStream].sell_count = 1;
         }
     }

   oServer.oStream[idxStream].ticket=-1;
   for(int i=0;i<PositionsTotal(); i++) 
     {
      if(PositionSelectByTicket(PositionGetTicket(i)))
         if(PositionGetInteger(POSITION_MAGIC)==TrMagic)
            if(PositionGetString(POSITION_SYMBOL)==oServer.oStream[idxStream].pair) 
              {
               oServer.oStream[idxStream].ticket = PositionGetTicket(i);
               break;
              }
     }

   if(oServer.oStream[idxStream].ticket<0) 
     {
      Print("Error ticket: "+oServer.oStream[idxStream].pair);
     }

   oServer.oStream[idxStream].loss_percent=THRESHOLD_LOSS[0];
   oServer.oStream[idxStream].profit=0;
   oServer.oStream[idxStream].prev_profit=-2*MIN_PROFIT;
   
   
  }
//=================================================================================================
void GetMaxDeviation1(int &idxCurrPlus,int &idxCurrMinus) 
  {
//   размеры матрицы совпадают с размерами массивов валют
   for(int row=0; row<ArraySize(oServer.asCurrencySet); row++) 
     {
      int direction=0;
      for(int col=0; col<ArraySize(oServer.asCurrencySet); col++) 
        {
         if(col==row)
            continue;
         direction+=(oServer.oCurrencyMatrix[row].oStreamValue[col].coeff[0]>0)? 1 : -1;
        }

      if(MathAbs(direction)==ArraySize(oServer.asCurrencySet)-1) 
        {
         if(direction>0)
            idxCurrPlus=row;
         else
            idxCurrMinus=row;
        }
     }
  }
//=================================================================================================
void GetMaxDeviation2(int &idxCurrPlus,int &idxCurrMinus) 
  {
// найдем валюту с максимальным ростом
   double coeff=-1;
//   размеры матрицы совпадают с размерами массивов валют   
   for(int row=0; row<ArraySize(oServer.asCurrencySet); row++) 
     {
      for(int col=0; col<ArraySize(oServer.asCurrencySet); col++) 
        {
         if(col==row)
            continue;
         if(coeff<oServer.oCurrencyMatrix[row].oStreamValue[col].coeff[0] && oServer.oCurrencyMatrix[row].oStreamValue[col].coeff[0]>0) 
           {
            coeff=oServer.oCurrencyMatrix[row].oStreamValue[col].coeff[0];
            idxCurrPlus=row;
           }
        }
     }
// найдем валюту с максимальным падением
   coeff=1;
   for(int row=0; row<ArraySize(oServer.asCurrencySet); row++) 
     {
      for(int col=0; col<ArraySize(oServer.asCurrencySet); col++) 
        {
         if(col==row)
            continue;
         if(coeff>oServer.oCurrencyMatrix[row].oStreamValue[col].coeff[0] && oServer.oCurrencyMatrix[row].oStreamValue[col].coeff[0]<0) 
           {
            coeff=oServer.oCurrencyMatrix[row].oStreamValue[col].coeff[0];
            idxCurrMinus=row;
           }
        }
     }
  }
//=================================================================================================
// возвращает индекс и направление самого быстроменяющегося потока
void GetLeadingStream(int &idxStream,string &Direction) 
  {
   idxStream=-1;
   double max_speed=0.0;
   int idx=-1;

//1. выбор абсолютно растущей и абсолютно падающей валют на самом динамичном слое
   int idxCurrPlus  = -1;
   int idxCurrMinus = -1;
   GetMaxDeviation1(idxCurrPlus,idxCurrMinus);

// не нашли такой, поищем максимальнорастущую и максимальнопадающую валюты 
   if(idxCurrPlus==-1 || idxCurrMinus==-1) 
     {
      idxCurrPlus  = -1;
      idxCurrMinus = -1;
      //GetMaxDeviation2(idxCurrPlus,idxCurrMinus);
      if(idxCurrPlus==-1 || idxCurrMinus==-1)
         return;
     }

   int _idxStream= GetPairIdx(idxCurrPlus,idxCurrMinus);
   if(_idxStream == -1)
      return;

// 2. если пара выбрана, проверяем тренд (все коэффициенты одного знака)   
   if(IsTrend(_idxStream,Direction,true)) 
     {
      idxStream=_idxStream;
     }
  }
//=================================================================================================
int GetPairIdx(int idxCurrPlus,int idxCurrMinus) 
  {
   int _idxStream=-1;
   for(int i=0; i<ArraySize(oServer.oStream); i++) 
     {
      if(
         (oServer.oStream[i].currIdx1==idxCurrPlus && oServer.oStream[i].currIdx2==idxCurrMinus)
         || 
         (oServer.oStream[i].currIdx2==idxCurrPlus && oServer.oStream[i].currIdx1==idxCurrMinus)
         ) 
        {
         _idxStream=i;
         break;
        }
     }
   return _idxStream;
  }

//=================================================================================================  
void GetMatrixPosition(int idx, int &row, int &col) {
   for(row=0; row<ArraySize(oServer.asCurrencySet); row++) 
     {
      for(col=0; col<ArraySize(oServer.asCurrencySet); col++) 
        {
         if(oServer.oCurrencyMatrix[row].oStreamValue[col].idx==idx) 
           {
            return;
           }
        }
     }
     row = col = -1;
}
//=================================================================================================
bool IsTrend(int _idxStream,string &Direction, bool order = false) 
  {
   for(int row=0; row<ArraySize(oServer.asCurrencySet); row++) 
     {
      for(int col=0; col<ArraySize(oServer.asCurrencySet); col++) 
        {
         if(oServer.oCurrencyMatrix[row].oStreamValue[col].idx==_idxStream) 
           {
            Direction=(oServer.oCurrencyMatrix[row].oStreamValue[col].coeff[0]>0)? "BUY" : "SELL";
            return StreamUnidirectional(row,col,order); // все вектора однонаправлены
           }
        }
     }
   return false;
  }
//=================================================================================================
bool StreamUnidirectional(int row,int col, bool order = false) 
  {
   int sign=(oServer.oCurrencyMatrix[row].oStreamValue[col].coeff[0]>0)? 1 : -1;
   for(int i=1; i<ArraySize(oServer.oCurrencyMatrix[row].oStreamValue[col].coeff); i++) 
     {
      if(((oServer.oCurrencyMatrix[row].oStreamValue[col].coeff[i]>0)? 1 : -1)!=sign)
         return false;
     }
   if (!order)  // упорядоченность не интересует
      return true;
      
   double coeff = MathAbs(oServer.oCurrencyMatrix[row].oStreamValue[col].coeff[0]);
   for(int i=1; i<ArraySize(oServer.oCurrencyMatrix[row].oStreamValue[col].coeff); i++) 
     {
      if(coeff <= MathAbs(oServer.oCurrencyMatrix[row].oStreamValue[col].coeff[i]))
         return false;
      coeff = MathAbs(oServer.oCurrencyMatrix[row].oStreamValue[col].coeff[i]);
     }
  return true;    
  }

//=================================================================================================  
double TrExTotalProfit() {
   double total_profit=0;
   for(int i=0; i<ArraySize(oServer.oStream); i++) 
     {
      if(!PositionSelect(oServer.oStream[i].pair))
         continue;

      total_profit += PositionGetDouble(POSITION_PROFIT);
     }   
  return total_profit;   
}

void TrExCloseAll() {

   bool flag = true;
   while(flag) {
       flag = false;    
       for(int i=0; i<ArraySize(oServer.oStream); i++) 
         {
          if(!PositionSelect(oServer.oStream[i].pair))
             continue;
    
          if(!PositionClose(i)) {
            flag = true;    
            break;
            }
         }   
   }
}
  
//=================================================================================================
// проверка открытых сделок и оценка тек. ситуации...
//=================================================================================================
// режимы закрытия:
// 1. По тренду: стартовый режим, после открытия сделки в предсказанном направлении ждем минимального уровня прибыли или убытка
//    в случае убытка закрываемся, в случае прибыли устанавливаем допустимый процент потерь и переходим ко второму режиму
// 2. по допустимому проценту потерь: с ростом прибыли уменьшается процент потерь, при этом абсолютный размер потерь увеличивается



bool TrExClose(double &total_profit,int &profit_cnt,int &loss_cnt) 
  {
   total_profit=0;
   int open_position=0;
   bool close_loss=false;  // закрытие по убытку, будем пытаться компенсировать
   profit_cnt=0;
   loss_cnt=0;
   
   
//   
   for(int i=0; i<ArraySize(oServer.oStream); i++) 
     {
      if(!PositionSelect(oServer.oStream[i].pair))
         continue;

      double profit;

      if(!PositionGetProfit(profit,i))
         continue;

      open_position++;

      if(profit < -MIN_PROFIT) 
        { // убыток - не угадали, закрываемся((

         Print(oServer.oStream[i].pair+": close loss: ",profit);
         if(!PositionClose(i)) 
            continue;

         close_loss=true;
         break;
        }

      double loss_percent=0;

      if(profit<=MIN_PROFIT && oServer.oStream[i].profit==0) // пока не взлетело, ждем...
         continue;

      // очередной рубеж взят, фиксируем максимально достигнутый профит
      if(oServer.oStream[i].profit<profit) 
        {
         oServer.oStream[i].profit=profit;
         int idx=int((profit/MIN_PROFIT) -1);

         if(idx<0)
            idx=0;

         if(idx>ArraySize(THRESHOLD_LOSS)-1)
            idx=ArraySize(THRESHOLD_LOSS)-1;

         // порог потерь может только увеличиваться...
         if(oServer.oStream[i].loss_percent < THRESHOLD_LOSS[idx])
            oServer.oStream[i].loss_percent=THRESHOLD_LOSS[idx];

         Print(oServer.oStream[i].pair+": threshold = ",oServer.oStream[i].profit*oServer.oStream[i].loss_percent," loss_percent = ",oServer.oStream[i].loss_percent);
        }

      if(oServer.oStream[i].profit*oServer.oStream[i].loss_percent>=profit) 
        {
         Print(oServer.oStream[i].pair+": close profit: ",profit,", max profit: ",oServer.oStream[i].profit," loss_percent = ",oServer.oStream[i].loss_percent);
         if(PositionClose(i))
            profit=0;
        }
      total_profit+=profit;

     }
   total_profit=(open_position>0)?(total_profit/open_position) : -1;
   return close_loss;
  }
  
//
void TrExCloseProfitMore(double threshold) {
   for(int i=0; i<ArraySize(oServer.oStream); i++) 
     {
      if(!PositionSelect(oServer.oStream[i].pair))
         continue;
      
      double profit; //=PositionGetDouble(POSITION_PROFIT);
      
      if(! PositionGetProfit(profit,i) )
        continue;

      if(profit < threshold)
         continue;
         
      while(!PositionClose(i)) {} ;
         
     }
}

bool TrExCloseMaxProfit(double threshold) 
  {
   int idx=-1;
   double max_profit=threshold;
   for(int i=0; i<ArraySize(oServer.oStream); i++) 
     {
      if(!PositionSelect(oServer.oStream[i].pair))
         continue;
      
      double profit; //=PositionGetDouble(POSITION_PROFIT);
      
      if(! PositionGetProfit(profit,i) )
        continue;

      if(profit>threshold)
         continue;

      if(max_profit<threshold) 
        {
         max_profit=threshold;
         idx=i;
        }
     }

   if(idx>=0)      {
      Print("compensation: "+oServer.oStream[idx].pair+": close profit: ",max_profit,", max profit: ",oServer.oStream[idx].profit," loss_percent = ",oServer.oStream[idx].loss_percent);
      if(PositionClose(idx))
         return true;
     }
   return false;
  }

//+------------------------------------------------------------------+
bool PositionGetProfit(double &profit,int idx) 
  {
   profit=PositionGetDouble(POSITION_PROFIT);
   return true;
   
   // сначала проверим на достоверность: 
   if(oServer.oStream[idx].prev_profit != (-2*MIN_PROFIT)) 
     {
     double diff=MathAbs(oServer.oStream[idx].prev_profit-profit);
     
     if(diff > 0.2) {
         Print(oServer.oStream[idx].pair + ": CHECK RUSH ", profit, " ", oServer.oStream[idx].prev_profit-profit, " coeff: ", oServer.CoeffToStr(idx));
         
         // отклонение в плюс, считаем что так и надо         
         if (profit > 0 && profit > oServer.oStream[idx].prev_profit) {
            oServer.oStream[idx].prev_profit=profit;
            return true;
         }
         // отклонение в минус:
         if (profit < 0 && profit < oServer.oStream[idx].prev_profit) {
            // учтем по среднему
            oServer.oStream[idx].prev_profit=oServer.oStream[idx].prev_profit-0.03; //(diff/4);
            if (profit < -MIN_PROFIT)
                Print(oServer.oStream[idx].pair + ": IGNORE LOSS!!!", profit);
                
            // но на закрытие это не повлияет
            return false;
         }
        }
     }

   oServer.oStream[idx].prev_profit=profit;
   return true;
  }

//+------------------------------------------------------------------+
bool PositionClose(int idx) {
   ctrade.PositionClose(oServer.oStream[idx].ticket);
   if(PositionSelect(oServer.oStream[idx].pair)) {
      Print(oServer.oStream[idx].pair + ": ошибка закрытия");
      return false;
   }
   return true;
}