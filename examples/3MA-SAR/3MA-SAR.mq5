//+------------------------------------------------------------------+
//|                                                      3MA-SAR.mq5 |
//|                                                   Ali Samanipour |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Ali Samanipour"
#property link      ""
#property version   "1.00"
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+

#include <Trade\Trade.mqh>


input double  TK = 300;
input double  SL = 200;
input int fastNormMAInterval = 8;
input double num_lots = 0.01;

int maFast_Handle;
double maFast_buffer[];

int maNorm_Handle;
double maNorm_buffer[];

int maSlow_Handle;
double maSlow_buffer[];

int cci_Handle;
double cci_buffer[];

int sar_Handle;
double sar_buffer[];

int candleIndexRange = 5;
int currentCandleIndex = 0;
int lastCandleIndex = 3;

color sellSignscolor = clrRed;
color buySignscolor = clrAqua;

MqlRates candle[];
MqlTick tick;
CTrade trade;
int magic_number=123456;

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   maFast_Handle = iMA(_Symbol,_Period,8,0,MODE_SMA,PRICE_CLOSE);
   maNorm_Handle = iMA(_Symbol,_Period,17,0,MODE_SMA,PRICE_CLOSE);
   maSlow_Handle = iMA(_Symbol,_Period,44,0,MODE_SMA,PRICE_CLOSE);

   cci_Handle = iCCI(_Symbol,_Period,21,PRICE_CLOSE);
   sar_Handle = iSAR(_Symbol,_Period,0.02,0.2);


   if(maFast_Handle <0 || maNorm_Handle<0|| maSlow_Handle<0|| sar_Handle<0|| cci_Handle<0)
     {
      Alert("Err on Handles ",GetLastError());
      return(-1);
     }

   CopyRates(_Symbol,_Period,0,5,candle);

   ChartIndicatorAdd(0,0,maFast_Handle);
   ChartIndicatorAdd(0,0,maNorm_Handle);
   ChartIndicatorAdd(0,0,maSlow_Handle);

   ChartIndicatorAdd(0,0,sar_Handle);
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
   IndicatorRelease(maFast_Handle);
   IndicatorRelease(maNorm_Handle);
   IndicatorRelease(maSlow_Handle);

   IndicatorRelease(sar_Handle);
   IndicatorRelease(cci_Handle);

  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---
   CopyBuffer(maFast_Handle,0,0,candleIndexRange,maFast_buffer);
   CopyBuffer(maNorm_Handle,0,0,candleIndexRange,maNorm_buffer);
   CopyBuffer(maSlow_Handle,0,0,candleIndexRange,maSlow_buffer);

   CopyBuffer(sar_Handle,0,0,candleIndexRange,sar_buffer);
   CopyBuffer(cci_Handle,0,0,candleIndexRange,cci_buffer);

   CopyRates(_Symbol,_Period,0,candleIndexRange,candle);

   ArraySetAsSeries(maFast_buffer,true);
   ArraySetAsSeries(maNorm_buffer,true);
   ArraySetAsSeries(maSlow_buffer,true);

   ArraySetAsSeries(sar_buffer,true);
   ArraySetAsSeries(cci_buffer,true);

   ArraySetAsSeries(candle,true);
   SymbolInfoTick(_Symbol,tick);


   if(PositionSelect(_Symbol)==false && sellSignal())
     {
      //Print("buff[2] > ma5 : ",ma5_buffer[2], " ma20 : ",ma20_buffer[2],"buff[0] > ma5 : ",ma5_buffer[0], " ma20 : ",ma20_buffer[0]);
      //drawVerticalLine("Sell "+candle[currentCandleIndex].time,candle[currentCandleIndex].time,clrBlue);
      Alert("Take >>Sell<< Postion");
      drawSellSign("Sell "+candle[currentCandleIndex].time,candle[currentCandleIndex].time,candle[currentCandleIndex].open,sellSignscolor);
      //sellMarket();
     }

//+------------------------------------------------------------------+
//|                           Buy Operations                        |
//+------------------------------------------------------------------+



   if(PositionSelect(_Symbol)==false && buySignal())
     {
      //Print("buff[2] > ma5 : ",ma5_buffer[2], " ma20 : ",ma20_buffer[2],"buff[0] > ma5 : ",ma5_buffer[0], " ma20 : ",ma20_buffer[0]);
      //drawVerticalLine("Buy "+candle[currentCandleIndex].time,candle[currentCandleIndex].time,clrGreen);
      Alert("Take >>Buy<< Postion");
      drawBuySign("Buy "+candle[currentCandleIndex].time,candle[currentCandleIndex].time,candle[currentCandleIndex].low,buySignscolor);
      //buyMarket();
     }

   //if(PositionSelect(_Symbol)==true && buySignal())
   //  {
   //   drawStopSign(">Possible Reversion Point< "+candle[currentCandleIndex].time,candle[currentCandleIndex].time,candle[currentCandleIndex].high,buySignscolor);
   //  }

  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool buySignal()
  {
   bool shouldBuy = false;
   if(maBuySignal()
      && sarBuySignal()
      && cciBuySignal() 

     )
     {
      shouldBuy = true;
     }
   else
     {
      shouldBuy = false;
     }
   return shouldBuy;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool maBuySignal()
  {

   bool shouldBuy = false;

   bool isUpWard =
      (maFast_buffer[0] > maFast_buffer[1])
      &&(maNorm_buffer[0]> maNorm_buffer[1])
      ;

   bool fastNormInterval = (((maFast_buffer[0] - maNorm_buffer[0])*10000)>fastNormMAInterval);

   int closeUpCanIndex =1;

   
   bool isCloseUp =
      ((candle[closeUpCanIndex].close < candle[closeUpCanIndex].open)
       &&(candle[closeUpCanIndex].close > NormalizeDouble(maFast_buffer[closeUpCanIndex],5)))?true:false;

   bool masOrder = ((maFast_buffer[0] > maNorm_buffer[0]) && (maNorm_buffer[0] > maSlow_buffer[0]))?true:false;
   if(
      isUpWard
      &&
      fastNormInterval
      &&
      isCloseUp
      &&
      masOrder
   )
     {
      //Print("MA By Sig true");
      shouldBuy = true;
     }
   else
     {
      //Print("MA By Sig false");
      shouldBuy = false;
     }
   return shouldBuy;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool sarBuySignal()
  {
   bool shouldBuy = false;
   if(
      NormalizeDouble(sar_buffer[0],5)<candle[0].low
//&& NormalizeDouble(sar_buffer[0],5)>candle[0].high

   )
     {
      //Print("SAR By Sig true");
      shouldBuy = true;
     }
   else
     {
      //Print("SAR By Sig false");
      shouldBuy = false;
     }

   return shouldBuy;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool cciBuySignal()
  {
   bool shouldBuy = false;
   if(cci_buffer[0]>cci_buffer[1])
     {
      shouldBuy = true;
     }
   else
     {
      shouldBuy = false;
     }

   return shouldBuy;
  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool sellSignal()
  {
   bool shouldSell = false;
   if(maSellSignal()
      && sarSellSignal()
      && cciSellSignal()
     )
     {
      shouldSell = true;
     }
   else
     {
      shouldSell = false;
     }
   return shouldSell;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool maSellSignal()
  {

   bool shouldBuy = false;

   bool isDownWard =
      (maFast_buffer[0] < maFast_buffer[1])
      &&(maNorm_buffer[0]< maNorm_buffer[1]);

   bool fastNormInterval = (((maNorm_buffer[0] - maFast_buffer[0])*10000)>fastNormMAInterval);

   int closeUpCanIndex =1;
   
   bool isCloseDown =
      ((candle[closeUpCanIndex].close > candle[closeUpCanIndex].open)
       && (candle[closeUpCanIndex].open < NormalizeDouble(maFast_buffer[closeUpCanIndex],5))) ?true:false;

   bool masOrder = (maFast_buffer[0] < maNorm_buffer[0]) && (maNorm_buffer[0] < maSlow_buffer[0]);
   if(
      isDownWard
      &&
      fastNormInterval
      &&
      isCloseDown
      &&
      masOrder
   )
     {
      //Print("MA By Sig true");
      shouldBuy = true;
     }
   else
     {
      //Print("MA By Sig false");
      shouldBuy = false;
     }
   return shouldBuy;
  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool cciSellSignal()
  {
   bool shouldSell = false;
   if(cci_buffer[0]<cci_buffer[1])
     {
      shouldSell = true;
     }
   else
     {
      shouldSell = false;
     }

   return shouldSell;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool sarSellSignal()
  {
   bool shouldSell = false;

   bool onTrend = NormalizeDouble(sar_buffer[0],5)>candle[0].high;

   bool beforTrend =
      (NormalizeDouble(sar_buffer[0],5)>candle[0].high)
      ;
   if(
      onTrend || beforTrend
   )
     {
      shouldSell = true;
     }
   else
     {
      shouldSell = false;
     }

   return shouldSell;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
void drawSellSign(string name,datetime dt,double atPrice,color cor = clrAliceBlue)
  {
   ObjectCreate(0,name,OBJ_ARROW_DOWN,0,dt,atPrice);
   ObjectSetInteger(0,name,OBJPROP_COLOR,cor);
   ObjectSetInteger(0,name,OBJPROP_ANCHOR,ANCHOR_BOTTOM);
   ObjectSetInteger(0,name,OBJPROP_WIDTH,6);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void drawBuySign(string name,datetime dt,double atPrice,color cor = clrAliceBlue)
  {
   ObjectCreate(0,name,OBJ_ARROW_UP,0,dt,atPrice);
   ObjectSetInteger(0,name,OBJPROP_COLOR,cor);
   ObjectSetInteger(0,name,OBJPROP_ANCHOR,ANCHOR_TOP);
   ObjectSetInteger(0,name,OBJPROP_WIDTH,6);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void drawStopSign(string name,datetime dt,double atPrice,color cor = clrAliceBlue)
  {
   ObjectCreate(0,name,OBJ_ARROW_STOP,0,dt,atPrice);
   ObjectSetInteger(0,name,OBJPROP_COLOR,cor);
   ObjectSetInteger(0,name,OBJPROP_ANCHOR,ANCHOR_CENTER);
   ObjectSetInteger(0,name,OBJPROP_WIDTH,6);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void buyMarket()
  {
   if(PositionSelect(_Symbol)==false)
     {
      double ASK = NormalizeDouble(SymbolInfoDouble(_Symbol,SYMBOL_ASK),_Digits);
      trade.Buy(num_lots,_Symbol,ASK,(ASK-SL*_Point),(ASK+TK*_Point),NULL);
     }

  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void sellMarket()
  {
   if(PositionSelect(_Symbol)==false)
     {
      //Print(">>>> Semd SELL <<<<" );
      double Bid = NormalizeDouble(SymbolInfoDouble(_Symbol,SYMBOL_BID),_Digits);
      trade.Sell(num_lots,NULL,Bid,(Bid+SL*_Point),(Bid-TK*_Point),NULL);
     }

  }
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool checkForBuyCloseSignal()
  {
   bool shoulClose = false;

   if(
   (
      (cci_buffer[0]<100 && cci_buffer[2]>100)
      ||(cci_buffer[0]<0 && cci_buffer[2]>0)
      )
      
      //&&
      //(cci_buffer[0]<cci_buffer[1] && cci_buffer[1]<cci_buffer[2])
     )
     {
      shoulClose = true;
      Print("Buy Close Signal : checkBuyCloseSignalFunction");
     }
   else
     {
      shoulClose=false;
     }

   return shoulClose;
  }

//+------------------------------------------------------------------+
