//+------------------------------------------------------------------+
//|                                                      Support.mqh |
//|                                                     Орешкин А.В. |
//|                                      https://vk.com/tradingisfun |
//+------------------------------------------------------------------+
#property copyright "Орешкин А.В."
#property link      "https://vk.com/tradingisfun"
#property version   "1.00"
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+

struct refArrXY {
    double val[];
};

class CSupport
  {
private:
   double _arr_x[], _arr_c[];
   refArrXY _arr_xy[];
public:
                     CSupport();
                    ~CSupport();
                    
      uchar          NumberCount(double numer);    //Возвращаем количество знаков после запятой в десятичной цифре
      int            ArrAdd(double &arr[], int max_sz, double val);
      double         coeff(double &data[]);
  };
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
CSupport::CSupport()
  {
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
CSupport::~CSupport()
  {
  }
//+------------------------------------------------------------------+
uchar CSupport::NumberCount(double numer)
   {
      uchar i=0;
      numer=MathAbs(numer);
      for(i=0;i<=8;i++) if (MathAbs(NormalizeDouble(numer,i)-numer)<=DBL_EPSILON) break;
      return(i);   
   }
   

//========================================================================
int CSupport::ArrAdd(double &arr[], int max_sz, double val) {

        if (ArraySize(arr) >= max_sz) {
            for(int i = 0; i < ArraySize(arr)-1; i++) arr[i] = arr[i+1];
            arr[ArraySize(arr)-1] = val;
            }
        else {
            ArrayResize(arr, ArraySize(arr)+1);
            arr[ArraySize(arr)-1] = val;
        } 
return ArraySize(arr);
}



//========================================================================
double CSupport::coeff(double &data[]) {
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
   