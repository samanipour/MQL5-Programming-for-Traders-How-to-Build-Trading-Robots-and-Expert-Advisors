//+------------------------------------------------------------------+
//|                                                      ProjectName |
//|                                      Copyright 2018, CompanyName |
//|                                       http://www.companyname.net |
//+------------------------------------------------------------------+
#include <Trade\Trade.mqh>
#property copyright "Ali Samanipour"
#property link      ""
#property version   "1.00"
//+------------------------------------------------------------------+
//|                                     Con-Div-Pattern-Detector.mq5 |
//|                                                   Ali Samanipour |
//|                                                                  |
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+

MqlRates candle[];
MqlTick tick;
CTrade trade;


int cci_Handle;
double cci_buffer[];


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   cci_Handle = iCCI(_Symbol,_Period,21,PRICE_CLOSE);
   if(cci_Handle<0)
     {
      Alert("Err on Handles ",GetLastError());
      return(-1);
     }
   CopyRates(_Symbol,_Period,0,5,candle);
   ChartIndicatorAdd(0,1,cci_Handle);

//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---
   IndicatorRelease(cci_Handle);


  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---
   CopyBuffer(cci_Handle,0,0,5,cci_buffer);
   CopyRates(_Symbol,_Period,0,5,candle);
   
   ArraySetAsSeries(cci_buffer,true);


   ArraySetAsSeries(candle,true);
   SymbolInfoTick(_Symbol,tick);
   
   if(divSellSignal())
     {
      drawVerticalLine("Div-Sell Sig ps",candle[0].time,0,clrOrange);
      drawVerticalLine("Div-Sell Sig pe",candle[4].time,0,clrOrange);
      
      drawVerticalLine("Div-Sell Sig cs",candle[0].time,1,clrOrange);
      drawVerticalLine("Div-Sell Sig ce",candle[4].time,1,clrOrange);
     }
     
     if(conSellSignal())
       {
        drawVerticalLine("Con-Sell Sig ps",candle[0].time,0,clrYellow);
      drawVerticalLine("Con-Sell Sig pe",candle[4].time,0,clrYellow);
      
      drawVerticalLine("Con-Sell Sig cs",candle[0].time,1,clrYellow);
      drawVerticalLine("Con-Sell Sig ce",candle[4].time,1,clrYellow);
       }


  }
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool divSellSignal()
  {
   bool divsellsig = false;
   
   bool pricediv = 
        upOfCandle(candle[1]) > upOfCandle(candle[3])
      &&upOfCandle(candle[0]) < upOfCandle(candle[1])
      &&upOfCandle(candle[2]) < upOfCandle(candle[1])
      &&upOfCandle(candle[2]) < upOfCandle(candle[3]);
      
      bool ccidiv = 
           cci_buffer[1] < cci_buffer[3]
         &&cci_buffer[0] < cci_buffer[1]
         &&cci_buffer[2] < cci_buffer[1]
         &&cci_buffer[2] < cci_buffer[3]
         &&cci_buffer[4] < cci_buffer[3];
   if(
   pricediv 
   && 
   ccidiv
   )
     {
      divsellsig = true; 
      Print("DivSell Sig");
     }
   else
     {
      divsellsig = false;
     }

   return divsellsig;
  }

bool conSellSignal()
  {
   bool consellsig = false;
   
   bool pricediv = 
        upOfCandle(candle[1]) < upOfCandle(candle[3])
      &&upOfCandle(candle[0]) < upOfCandle(candle[1])
      &&upOfCandle(candle[2]) < upOfCandle(candle[1])
      &&upOfCandle(candle[2]) < upOfCandle(candle[3]);
      
    bool ccicon = cci_buffer[1] > cci_buffer[3]
         &&cci_buffer[0] < cci_buffer[1]
         &&cci_buffer[2] < cci_buffer[1]
         &&cci_buffer[2] < cci_buffer[3]
         &&cci_buffer[4] < cci_buffer[3];
   if(
   pricediv 
   && 
   ccicon
   )
     {
      consellsig = true; 
      Print("ConSell Sig");
     }
   else
     {
      consellsig = false;
     }

   return consellsig;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void drawVerticalLine(string name,datetime dt,int subwindo,color cor = clrAliceBlue)
  {
//ObjectDelete(0,name);
   ObjectCreate(0,name,OBJ_VLINE,subwindo,dt,0);
   ObjectSetInteger(0,name,OBJPROP_COLOR,cor);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void drawHorizontalLine(string name,datetime dt,int subwindo,color cor = clrAliceBlue)
  {
   ObjectCreate(0,name,OBJ_HLINE,subwindo,dt,0);
  }
//+------------------------------------------------------------------+
double upOfCandle(MqlRates &candle)
{
   return candle.close>candle.open?candle.close:candle.open;
}