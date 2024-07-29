//+------------------------------------------------------------------+
//|                                                     Stoc-3MA.mq4 |
//|                                                   Ali Samanipour |
//|                                                                  |
//+------------------------------------------------------------------+
#property copyright "Ali Samanipour"
#property link      ""
#property version   "1.00"
#property strict
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
#include <Trade\Trade.mqh>

input double  TK = 380;
input double  SL = 450;

input int maNormPeriod = 34;
input int belowOverBuyLine = 75;
input int aboveOverSoldLine = 19;

input int relativeSellLoss = 420;
input int relativeBuyLoss = 430;


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double autoCloseBuyLimit = -1 * (relativeBuyLoss/100);
double autoCloseSellLimit = -1 * (relativeSellLoss/100);

//input double maSellMinGrad = 1.0;

input double num_lots = 0.01;


input double trailingSellProfitStopLossLimit = 230;
input double trailingSellStopLossSteps = 59;

input double trailingBuyProfitStopLossLimit = 350;
input double trailingBuyStopLossSteps = 72;

int maHigh_Handle;
double maHigh_buffer[];

int maNorm_Handle;
double maNorm_buffer[];

int maLow_Handle;
double maLow_buffer[];

int stoc_Handle;
double stoc_Main_buffer[];
double stoc_Signal_buffer[];

//int cci_Handle;
//double cci_buffer[];

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
   maHigh_Handle = iMA(_Symbol,_Period,4,0,MODE_LWMA,PRICE_HIGH);
   maNorm_Handle = iMA(_Symbol,_Period,maNormPeriod,0,MODE_SMA,PRICE_CLOSE);
   maLow_Handle = iMA(_Symbol,_Period,4,0,MODE_LWMA,PRICE_LOW);

   stoc_Handle = iStochastic(_Symbol,_Period,5,3,3,MODE_SMA,STO_LOWHIGH);
   
   //cci_Handle = iCCI(_Symbol,_Period,21,PRICE_CLOSE);

   if(maHigh_Handle <0 || maNorm_Handle<0|| maLow_Handle<0|| stoc_Handle<0)
     {
      Alert("Err on Handles ",GetLastError());
      return(-1);
     }

   CopyRates(_Symbol,_Period,0,5,candle);

   ChartIndicatorAdd(0,0,maHigh_Handle);
   ChartIndicatorAdd(0,0,maNorm_Handle);
   ChartIndicatorAdd(0,0,maLow_Handle);

   ChartIndicatorAdd(0,1,stoc_Handle);

   //ChartIndicatorAdd(0,1,cci_Handle);
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---
   IndicatorRelease(maHigh_Handle);
   IndicatorRelease(maNorm_Handle);
   IndicatorRelease(maLow_Handle);

   IndicatorRelease(stoc_Handle);
   //IndicatorRelease(cci_Handle);
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---

   ArraySetAsSeries(stoc_Main_buffer,true);
   ArraySetAsSeries(stoc_Signal_buffer,true);

   ArraySetAsSeries(maHigh_buffer,true);
   ArraySetAsSeries(maNorm_buffer,true);
   ArraySetAsSeries(maLow_buffer,true);

   //ArraySetAsSeries(cci_buffer,true);

   CopyBuffer(stoc_Handle,0,0,candleIndexRange,stoc_Main_buffer);
   CopyBuffer(stoc_Handle,1,0,candleIndexRange,stoc_Signal_buffer);

   CopyBuffer(maHigh_Handle,0,0,candleIndexRange,maHigh_buffer);
   CopyBuffer(maNorm_Handle,0,0,candleIndexRange,maNorm_buffer);
   CopyBuffer(maLow_Handle,0,0,candleIndexRange,maLow_buffer);

   //CopyBuffer(cci_Handle,0,0,candleIndexRange,cci_buffer);

   CopyRates(_Symbol,_Period,0,candleIndexRange,candle);


   ArraySetAsSeries(candle,true);
   SymbolInfoTick(_Symbol,tick);

//+------------------------------------------------------------------+
//|                          Sell Operations                        |
//+------------------------------------------------------------------+

   if(PositionSelect(_Symbol)==false && sellSignal())
     {
      //Print("buff[2] > ma5 : ",ma5_buffer[2], " ma20 : ",ma20_buffer[2],"buff[0] > ma5 : ",ma5_buffer[0], " ma20 : ",ma20_buffer[0]);
      //drawVerticalLine("Sell "+candle[currentCandleIndex].time,candle[currentCandleIndex].time,clrBlue);
      Alert("Take >>Sell<< Postion");
      drawSellSign("Sell "+candle[currentCandleIndex].time,candle[currentCandleIndex].time,candle[currentCandleIndex].open,sellSignscolor);
      sellMarket();
     }

   if(
      PositionSelect(_Symbol)==true
      &&(ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE)== POSITION_TYPE_SELL
      &&(
         (checkForSellCloseSignal()&& PositionGetDouble(POSITION_PROFIT)<autoCloseSellLimit)
         ||
         (isOnSellTrend()== false && PositionGetDouble(POSITION_PROFIT) < autoCloseSellLimit)

      )
   )
     {
      //drawVerticalLine("Sell Close Signal "+candle[0].time,candle[0].time,clrYellow);
      drawStopSign("Sell Close Signal "+candle[currentCandleIndex].time,candle[currentCandleIndex].time,candle[currentCandleIndex].high,sellSignscolor);
      Alert("Close Your Sell Position");
      closeAllSellPositions();
     }

   if(
      PositionSelect(_Symbol)==true
      &&(ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE)== POSITION_TYPE_SELL)
     {
      double Bid = NormalizeDouble(SymbolInfoDouble(_Symbol,SYMBOL_BID),_Digits);
      modifySellStopLoss(Bid);
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
      buyMarket();
     }

   if(PositionSelect(_Symbol)==true
      &&(ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE)== POSITION_TYPE_BUY
      &&
      (
         (checkForBuyCloseSignal()&& PositionGetDouble(POSITION_PROFIT) < autoCloseBuyLimit)
         ||
         (isOnBuyTrend()== false && PositionGetDouble(POSITION_PROFIT) < autoCloseSellLimit)
      )
     )
     {
      drawStopSign("Buy Close Signal "+candle[currentCandleIndex].time,candle[currentCandleIndex].time,candle[currentCandleIndex].low,buySignscolor);
      Alert("Close Your Buy Position");
      closeAllBuyPositions();
     }
     
   if(
      PositionSelect(_Symbol)==true
      &&(ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE)== POSITION_TYPE_BUY)
     {
      double Ask = NormalizeDouble(SymbolInfoDouble(_Symbol,SYMBOL_ASK),_Digits);
      modifyBuyStopLoss(Ask);
     }

  }
//+------------------------------------------------------------------+
bool buySignal()
  {
   bool shouldBuy = false;
   if(stocBuySig()
      &&
      maBuySignal()
      //&&
      //isStocBuyTrend()

//&&
//isOnBuyTrend()
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
bool sellSignal()
  {
   bool shouldSell = false;
   if(stocSellSig()
      &&
      maSellSignal()
      //&&
      //isStocSellTrend()
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
bool stocBuySig()
  {
   bool shouldbuy = false;

   bool belowOverBuy = stoc_Main_buffer[0] < belowOverBuyLine && stoc_Main_buffer[1]<belowOverBuyLine
                       && 
                       stoc_Signal_buffer[0] < belowOverBuyLine && stoc_Signal_buffer[1]<belowOverBuyLine;

   bool stocBuyCross = stoc_Main_buffer[0] > stoc_Signal_buffer[0] && stoc_Main_buffer[1] < stoc_Signal_buffer[1];

   if(stocBuyCross
      //&& belowOverBuy
     )
     {
      shouldbuy = true;
     }
   else
     {
      shouldbuy = false;
     }
   return shouldbuy;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool isStocBuyTrend()
  {
   bool isbuyTrend = false;

   bool stocMainTrend = (stoc_Main_buffer[0] > stoc_Main_buffer[1] && stoc_Main_buffer[1] > stoc_Main_buffer[2])?true:false;
   if(stocMainTrend)
     {
      isbuyTrend = true;
     }
   else
     {
      isbuyTrend = false;
     }
   return isbuyTrend;
  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool isStocSellTrend()
  {
   bool issellTrend = false;

   bool stocMainTrend = (stoc_Main_buffer[0] < stoc_Main_buffer[1] && stoc_Main_buffer[1] < stoc_Main_buffer[2])?true:false;
   if(stocMainTrend)
     {
      issellTrend = true;
     }
   else
     {
      issellTrend = false;
     }
   return issellTrend;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool stocSellSig()
  {
   bool shouldsell = false;

   bool aboveOversold = stoc_Main_buffer[0] > aboveOverSoldLine && stoc_Main_buffer[1]>aboveOverSoldLine
                        && stoc_Signal_buffer[0] >aboveOverSoldLine && stoc_Signal_buffer[1]>aboveOverSoldLine;

   bool stocSellCross = stoc_Main_buffer[0] < stoc_Signal_buffer[0] && stoc_Main_buffer[1] > stoc_Signal_buffer[1];

   bool isOpenAbove = (candle[0].open > NormalizeDouble(maLow_buffer[0],5))  ? true:false;

   if(stocSellCross
      //&&aboveOversold

     )
     {
      shouldsell = true;
     }
   else
     {
      shouldsell = false;
     }
   return shouldsell;
  }



//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool maSellSignal()
  {

   bool shouldSell = false;

   bool isDownWard =
      (maHigh_buffer[0] < maHigh_buffer[1])
      &&(maLow_buffer[0]< maLow_buffer[1])
//&&(maNorm_buffer[0]< maNorm_buffer[1])
      ;


   int closeUpCanIndex = 1;

   bool isCloseDown =
      ((candle[closeUpCanIndex].close > candle[closeUpCanIndex].open)
       &&(candle[closeUpCanIndex].open < NormalizeDouble(maHigh_buffer[closeUpCanIndex],5))) ?true:false;

   bool isOpenBelow = (candle[0].open < NormalizeDouble(maHigh_buffer[0],5)) ? true:false;

   bool masOrder = (maHigh_buffer[0] < maNorm_buffer[0]) && (maLow_buffer[0] < maNorm_buffer[0]);
   if(
      isDownWard
      //&&masOrder
   )
     {
      //Print("MA By Sig true");
      shouldSell = true;
     }
   else
     {
      //Print("MA By Sig false");
      shouldSell = false;
     }
   return shouldSell;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool maBuySignal()
  {

   bool shouldBuy = false;

   bool isUpWard =
      (maHigh_buffer[0] > maHigh_buffer[1])
      &&(maLow_buffer[0]  > maLow_buffer[1])
//&&(maNorm_buffer[0] > maNorm_buffer[1])
      ;


   int closeUpCanIndex = 1;

   bool isCloseUp =
      ((candle[closeUpCanIndex].close < candle[closeUpCanIndex].open)
       &&(candle[closeUpCanIndex].close > NormalizeDouble(maLow_buffer[closeUpCanIndex],5))) ?true:false;

   bool masOrder = (maHigh_buffer[0] > maNorm_buffer[0]) && (maLow_buffer[0] > maNorm_buffer[0]);
   if(
      isUpWard
      //&&masOrder
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
bool checkForBuyCloseSignal()
  {
   bool shoulClose = false;

   bool stocSellCross = stoc_Main_buffer[0] < stoc_Signal_buffer[0] && stoc_Main_buffer[1] > stoc_Signal_buffer[1];
   bool reversBaseOnStoc = (stocSellCross)?true:false;
   bool reversBaseOnMas  = ((maHigh_buffer[0] < maHigh_buffer[1])&&(maLow_buffer[0]< maLow_buffer[1]))?true:false;
   if(
      (
         reversBaseOnStoc
         ||
         reversBaseOnMas
//||
//(isOnBuyTrend()==false)
      )
   )
     {
      shoulClose = true;
      //Print("Buy Close Signal : checkBuyCloseSignalFunction");
     }
   else
     {
      shoulClose=false;
     }

   return shoulClose;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool checkForSellCloseSignal()
  {
   bool shoulClose = false;

   bool stocBuyCross = stoc_Main_buffer[0] > stoc_Signal_buffer[0] && stoc_Main_buffer[1] < stoc_Signal_buffer[1];
   bool reversBaseOnStoc = (stocBuyCross)?true:false;
   bool reversBaseOnMas  = ((maHigh_buffer[0] > maHigh_buffer[1])&&(maLow_buffer[0]> maLow_buffer[1]))?true:false;
   if(
      (
         reversBaseOnStoc
         ||
         reversBaseOnMas
//||
//(isOnSellTrend() == false)
      )

//&&
//(cci_buffer[0]<cci_buffer[1] && cci_buffer[1]<cci_buffer[2])
   )
     {
      shoulClose = true;
      //Print("Buy Close Signal : checkBuyCloseSignalFunction");
     }
   else
     {
      shoulClose=false;
     }

   return shoulClose;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void closeAllBuyPositions()
  {
   if(PositionSelect(_Symbol)==true)
     {
      for(int i=PositionsTotal()-1; i>=0; i--)
        {

         int ticket = PositionGetTicket(i);
         if((ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE)== POSITION_TYPE_BUY)
           {
            //Print("Close Buy because of reversal : ",ticket);
            trade.PositionClose(ticket);

           }

        }
     }

  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void closeAllSellPositions()
  {
   if(PositionSelect(_Symbol)==true)
     {
      for(int i=PositionsTotal()-1; i>=0; i--)
        {

         int ticket = PositionGetTicket(i);
         if((ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE)== POSITION_TYPE_SELL)
           {
            //Print("Close Sell because of reversal : ",ticket);
            trade.PositionClose(ticket);

           }
        }
     }

  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void modifySellStopLoss(double Bid)
  {

   double trailingStopLoss = NormalizeDouble(Bid+(trailingSellProfitStopLossLimit*_Point),_Digits);

   if(PositionSelect(_Symbol)==true)
     {
      for(int i=PositionsTotal()-1; i>=0; i--)
        {

         ulong ticket = PositionGetTicket(i);
         if((ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE)== POSITION_TYPE_SELL)
           {

            double currentStopLoss = PositionGetDouble(POSITION_SL);
            double currentTakeProfit = PositionGetDouble(POSITION_TP);
            double currentPositionProfit = PositionGetDouble(POSITION_PROFIT);
            
            if(currentStopLoss > trailingStopLoss && currentPositionProfit > NormalizeDouble(trailingSellProfitStopLossLimit/100,_Digits) )
              {
               //trade.PositionModify(ticket,(currentStopLoss - trailingSellStopLossSteps*_Point));
               //double newStopLoss = currentStopLoss-trailingSellStopLossSteps*_Point;
               double newStopLoss = currentStopLoss - trailingSellStopLossSteps*_Point;
               trade.PositionModify(ticket,newStopLoss,currentTakeProfit);
              }
           }
        }
     }
  }
  
  
void modifyBuyStopLoss(double Ask)
  {
  
   double trailingStopLoss = NormalizeDouble(Ask-(trailingBuyProfitStopLossLimit*_Point),_Digits);
   if(PositionSelect(_Symbol)==true)
     {
      for(int i=PositionsTotal()-1; i>=0; i--)
        {

         ulong ticket = PositionGetTicket(i);
         if((ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE)== POSITION_TYPE_BUY)
           {

            double currentStopLoss = PositionGetDouble(POSITION_SL);
            double currentTakeProfit = PositionGetDouble(POSITION_TP);
            double currentPositionProfit = PositionGetDouble(POSITION_PROFIT);
            
            if(currentStopLoss < trailingStopLoss && currentPositionProfit > NormalizeDouble(trailingBuyProfitStopLossLimit/100,_Digits) )
              {
               double newStopLoss = currentStopLoss + trailingBuyStopLossSteps*_Point;
               trade.PositionModify(ticket,newStopLoss,currentTakeProfit);
              }
           }
        }
     }
  }
//+------------------------------------------------------------------+
bool isOnBuyTrend()
  {
   bool buyTrend = false;

   bool buyTrendBaseOnStoc = ((stoc_Main_buffer[0]>stoc_Main_buffer[1])
//&& (stoc_Main_buffer[1]>stoc_Main_buffer[2])
                             )? true:false;

   if(buyTrendBaseOnStoc)
     {
      buyTrend = true;
     }
   else
     {
      buyTrend=false;
     }

   return buyTrend;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool isOnSellTrend()
  {
   bool sellTrend = false;

   bool sellTrendBaseOnStoc = ((stoc_Main_buffer[0]<stoc_Main_buffer[1])
//&& (stoc_Main_buffer[1]<stoc_Main_buffer[2])
                              )? true:false;

   if(sellTrendBaseOnStoc)
     {
      sellTrend = true;
     }
   else
     {
      sellTrend=false;
     }

   return sellTrend;
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+

//bool maGradiantSellSig()
//  {
//   bool shouldSell = false;
//   double  minGradSell= maSellMinGrad;
//
//   if(getMAGrad()>minGradSell)
//
//     {
//      shouldSell = true;
//     }
//   else
//     {
//      shouldSell = false;
//     }
//   return shouldSell;
//  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
//bool maGradiantSellCloseSig()
//  {
//   bool shouldSell = false;
//   double  minGradSell= maSellMinGrad;
//
//   if(getMAGrad()<minGradSell)
//
//     {
//      shouldSell = true;
//     }
//   else
//     {
//      shouldSell = false;
//     }
//   return shouldSell;
//  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double getMAGrad()
  {
   int x1 = 3;
   int x2 = 1;
   double y2 = NormalizeDouble(maNorm_buffer[x2],6)*100000;
   double y1 = NormalizeDouble(maNorm_buffer[x1],6)*100000;
   double gradiant = (y2-y1)/(x2-x1);
   return MathAbs(gradiant);

  }

void buyMarket()
  {
   if(PositionSelect(_Symbol)==false)
     {
      double ASK = NormalizeDouble(SymbolInfoDouble(_Symbol,SYMBOL_ASK),_Digits);
      trade.Buy(num_lots,_Symbol,ASK,(ASK-SL*_Point),(ASK+TK*_Point),NULL);
     }

  }

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
