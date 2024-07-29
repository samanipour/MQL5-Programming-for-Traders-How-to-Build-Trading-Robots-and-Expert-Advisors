//+------------------------------------------------------------------+
//|                                                  SAR-CCI-3MA.mq5 |
//|                                                   Ali Samanipour |
//|                                                                  |
//+------------------------------------------------------------------+
#include <Trade\Trade.mqh>

#property copyright "Ali Samanipour"
#property link      ""
#property version   "1.00"
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
input double num_lots = 0.01;
input double  TK = 10;
input double  SL = 20;

int ma5_Handle;
double ma5_buffer[];

int ma20_Handle;
double ma20_buffer[];

int ma50_Handle;
double ma50_buffer[];

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
   ma5_Handle = iMA(_Symbol,_Period,5,0,MODE_EMA,PRICE_CLOSE);
   ma20_Handle = iMA(_Symbol,_Period,17,0,MODE_EMA,PRICE_CLOSE);
   ma50_Handle = iMA(_Symbol,_Period,55,0,MODE_EMA,PRICE_CLOSE);

   cci_Handle = iCCI(_Symbol,_Period,21,PRICE_CLOSE);
   sar_Handle = iSAR(_Symbol,_Period,0.02,0.2);


   if(ma5_Handle <0 || ma20_Handle<0|| ma50_Handle<0|| sar_Handle<0|| cci_Handle<0)
     {
      Alert("Err on Handles ",GetLastError());
      return(-1);
     }

   CopyRates(_Symbol,_Period,0,5,candle);

   ChartIndicatorAdd(0,0,ma5_Handle);
   ChartIndicatorAdd(0,0,ma20_Handle);
   ChartIndicatorAdd(0,0,ma50_Handle);

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
   IndicatorRelease(ma5_Handle);
   IndicatorRelease(ma20_Handle);
   IndicatorRelease(ma50_Handle);

   IndicatorRelease(sar_Handle);
   IndicatorRelease(cci_Handle);
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---

   CopyBuffer(ma5_Handle,0,0,5,ma5_buffer);
   CopyBuffer(ma20_Handle,0,0,5,ma20_buffer);
   CopyBuffer(ma50_Handle,0,0,5,ma50_buffer);

   CopyBuffer(sar_Handle,0,0,5,sar_buffer);
   CopyBuffer(cci_Handle,0,0,5,cci_buffer);

   CopyRates(_Symbol,_Period,0,5,candle);

   ArraySetAsSeries(ma5_buffer,true);
   ArraySetAsSeries(ma20_buffer,true);
   ArraySetAsSeries(ma50_buffer,true);

   ArraySetAsSeries(sar_buffer,true);
   ArraySetAsSeries(cci_buffer,true);


   ArraySetAsSeries(candle,true);

   SymbolInfoTick(_Symbol,tick);

//NormalizeDouble(sar_buffer[0],5);


//+------------------------------------------------------------------+
//|                           Sell Operations                        |
//+------------------------------------------------------------------+


   if(PositionSelect(_Symbol)==false && sellSignal())
     {
      //Print("buff[2] > ma5 : ",ma5_buffer[2], " ma20 : ",ma20_buffer[2],"buff[0] > ma5 : ",ma5_buffer[0], " ma20 : ",ma20_buffer[0]);
      //drawVerticalLine("Sell "+candle[currentCandleIndex].time,candle[currentCandleIndex].time,clrBlue);
      Alert("Take >>Sell<< Postion");
      drawSellSign("Sell "+candle[currentCandleIndex].time,candle[currentCandleIndex].time,candle[currentCandleIndex].open,sellSignscolor);
      //sellMarket();
     }


//   if(checkForSellCloseSignal()
////&&(ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE)== POSITION_TYPE_SELL
////&& PositionSelect(_Symbol)==true
//     )
//     {
//      //drawVerticalLine("Sell Close Signal "+candle[0].time,candle[0].time,clrYellow);
//      drawStopSign("Sell Close Signal "+candle[currentCandleIndex].time,candle[currentCandleIndex].time,candle[currentCandleIndex].high,sellSignscolor);
//      Alert("Close Your Sell Position");
//     }

//if(checkForSellRevers()
//  //&&PositionSelect(_Symbol)==true
//  //&&(ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE)== POSITION_TYPE_SELL
//  )
//  {
//   //drawVerticalLine(">Possible Reversion Point<"+candle[0].time,candle[0].time,clrOrange);
//   drawStopSign(">Possible Reversion Point< "+candle[currentCandleIndex].time,candle[currentCandleIndex].time,candle[currentCandleIndex].high,clrOrange);
//   Alert(">>Possible Reversion Point<<<");
//   //closeAllSellPositions();
//  }
//---//---//---


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


//   if(checkForBuyRevers()
//      &&PositionSelect(_Symbol)==true
//      &&(ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE)== POSITION_TYPE_BUY
//     )
//     {
//      drawVerticalLine(">Possible Reversion Point<"+candle[0].time,candle[0].time,clrOrange);
//      Alert(">>Possible Reversion Point<<<");
//      //closeAllBuyPositions();
//     }
//
//   if(checkForBuyCloseSignal()
//      &&(ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE)== POSITION_TYPE_BUY
//      && PositionSelect(_Symbol)==true
//     )
//     {
//      drawVerticalLine("Buy Close Signal "+candle[0].time,candle[0].time,clrAqua);
//      Alert("Close Your Buy Position");
//     }

//---
//---
//---


  }
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool sellSignal()
  {
   bool shouldSell = false;
   if(maSellSignal() && cciSellSignal()&& sarSellSignal())
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
   bool shouldSell = false;

   bool isDownWard =
      (ma5_buffer[0]<ma5_buffer[1] && ma5_buffer[1] < ma5_buffer[2])
      &&(ma20_buffer[0]<ma20_buffer[1] && ma20_buffer[1] < ma20_buffer[2])
      &&(ma50_buffer[0]<= ma50_buffer[1]);

   bool fastmedCross =
      (ma5_buffer[2] > ma20_buffer[2] && ma5_buffer[0] < ma20_buffer [0]);

   bool isFastUpSlow =
      (ma5_buffer[0] > ma50_buffer[0] && ma5_buffer[1] > ma50_buffer[1] && ma5_buffer[2] > ma50_buffer[2]);

   bool isMedUpSlow =
      (ma20_buffer[0] > ma50_buffer[0] && ma20_buffer[1] > ma50_buffer[1] && ma20_buffer[2] > ma50_buffer[2]);
   
   bool medSlowCross = (ma20_buffer[2] > ma50_buffer[2] && ma20_buffer[0] < ma50_buffer [0]);
      
   if(
      isDownWard
      && 
      ((fastmedCross && isFastUpSlow && isMedUpSlow)||(medSlowCross))
    //&&(ma5_buffer[0] < ma50_buffer[0] && ma20_buffer [0] < ma50_buffer[0])
    //&&(ma5_buffer[0] < ma5_buffer[2] && ma20_buffer[0] < ma20_buffer[2] && ma50_buffer[0] < ma50_buffer[2] )
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
bool cciSellSignal()
  {
   bool shouldSell = false;
   if(cci_buffer[0]<cci_buffer[2] && cci_buffer[1] < cci_buffer[3])
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
      (NormalizeDouble(sar_buffer[0],5)>candle[0].high && NormalizeDouble(sar_buffer[1],5)<candle[1].low)
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
void closeAllSellPositions()
  {
   if(PositionSelect(_Symbol)==true)
     {
      for(int i=PositionsTotal()-1; i>=0; i--)
        {

         int ticket = PositionGetTicket(i);
         if((ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE)== POSITION_TYPE_SELL)
           {
            Print("Close Sell because of reversal : ",ticket);
            trade.PositionClose(ticket);
            drawVerticalLine("Sell Close By Reverse "+candle[0].time,candle[0].time,clrRed);
           }
        }
     }

  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool checkForSellRevers()
  {
   bool isTrednRevers = false;
   if(
      ((NormalizeDouble(sar_buffer[0],5)<candle[0].low && NormalizeDouble(sar_buffer[1],5)>candle[1].high)
       ||(cci_buffer[0]>cci_buffer[1] && cci_buffer[2]> cci_buffer[1]
//&& cci_buffer[3]>cci_buffer[2]
         ))
   )
     {
      isTrednRevers=true;
     }
   else
      if((NormalizeDouble(sar_buffer[0],5)>candle[0].high && NormalizeDouble(sar_buffer[1],5)<candle[1].low)
         ||(cci_buffer[0]<cci_buffer[1] && cci_buffer[2]< cci_buffer[1]
            //&& cci_buffer[3]>cci_buffer[2]
           )
        )
        {
         isTrednRevers=true;
        }
      else
        {
         isTrednRevers=false;
        }

   return isTrednRevers;
  }
//+------------------------------------------------------------------+
bool checkForSellCloseSignal()
  {
   bool shoulClose = false;

   bool sarReversion = NormalizeDouble(sar_buffer[0],5)<candle[0].low
                       && NormalizeDouble(sar_buffer[1],5)>candle[1].high;
   bool cciReversion = cci_buffer[0] >  cci_buffer[1] && cci_buffer[1] >  cci_buffer[2];
   if(
      cciReversion
      || sarReversion
   )
     {
      shoulClose = true;
      Print("Sell Close Signal : checkSellCloseSignalFunction");
     }
   else
     {
      shoulClose=false;
     }

   return shoulClose;
  }

//---
//---
//////////////////////////////Buy Methods//////////////////////////////
//---
//---


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool buySignal()
  {
   bool shouldBuy = false;
   if(maBuySignal() && cciBuySignal()&& sarBuySignal())
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
        (ma5_buffer[0] > ma5_buffer[1] && ma5_buffer[1] > ma5_buffer[2])
      &&(ma20_buffer[0]> ma20_buffer[1] && ma20_buffer[1] > ma20_buffer[2])
      &&(ma50_buffer[0]>= ma50_buffer[1]);

   bool fastmedCross =
   (ma5_buffer[2] < ma20_buffer[2] && ma5_buffer[0] > ma20_buffer [0]);

   bool isFastBelowSlow =
      (ma5_buffer[0] < ma50_buffer[0] && ma5_buffer[1] < ma50_buffer[1] && ma5_buffer[2] < ma50_buffer[2]);

   bool isMedBelowSlow =
      (ma20_buffer[0] < ma50_buffer[0] && ma20_buffer[1] < ma50_buffer[1] && ma20_buffer[2] < ma50_buffer[2]);
      
   bool medSlowCross = 
   (ma20_buffer[2] < ma50_buffer[2] && ma20_buffer[0] > ma50_buffer [0]);
   
   bool fastmedcrossBeforTrend = (ma5_buffer[4] < ma20_buffer[4] && ma5_buffer[2] > ma20_buffer [2]);
   
   if(
   isUpWard
   &&
   ((fastmedCross && isFastBelowSlow && isMedBelowSlow)
   ||(medSlowCross)
   ||(isFastBelowSlow && isMedBelowSlow && fastmedcrossBeforTrend))
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
bool cciBuySignal()
  {
   bool shouldBuy = false;
   if(cci_buffer[0]>cci_buffer[2] && cci_buffer[1] > cci_buffer[3])
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
bool sarBuySignal()
  {
   bool shouldBuy = false;
   if(
      NormalizeDouble(sar_buffer[0],5)<candle[1].low
//&& NormalizeDouble(sar_buffer[0],5)>candle[0].high

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
void closeAllBuyPositions()
  {
   if(PositionSelect(_Symbol)==true)
     {
      for(int i=PositionsTotal()-1; i>=0; i--)
        {

         int ticket = PositionGetTicket(i);
         if((ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE)== POSITION_TYPE_BUY)
           {
            Print("Close Buy because of reversal : ",ticket);
            trade.PositionClose(ticket);
            drawVerticalLine("Buy Close By Reverse "+candle[0].time,candle[0].time,clrRed);//---
           }

        }
     }

  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool checkForBuyRevers()
  {
   bool isTrednRevers = false;
   if(cci_buffer[0]<cci_buffer[1] && cci_buffer[1]< cci_buffer[2]
      && cci_buffer[3]<cci_buffer[2]
      && NormalizeDouble(sar_buffer[0],5)>candle[0].high
      && NormalizeDouble(sar_buffer[1],5)<candle[1].low
     )
     {
      isTrednRevers=true;
     }
   else
     {
      isTrednRevers=false;
     }

   return isTrednRevers;
  }
//+------------------------------------------------------------------+
bool checkForBuyCloseSignal()
  {
   bool shoulClose = false;

   if(NormalizeDouble(sar_buffer[0],5)>candle[0].high
      && NormalizeDouble(sar_buffer[1],5)<candle[1].low
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
//|                                                                  |
//+------------------------------------------------------------------+
void buyMarket()
  {
//   MqlTradeRequest request;
//   MqlTradeResult response;
//
//   ZeroMemory(request);
//   ZeroMemory(response);
//
//   request.action = TRADE_ACTION_DEAL;
//   request.magic = magic_number;
//   request.symbol = _Symbol;
//   request.volume = num_lots;
//   request.price  = NormalizeDouble(tick.ask,_Digits);
//   request.sl = NormalizeDouble(tick.ask - SL*_Point,_Digits);
//   request.tp = NormalizeDouble(tick.ask + TK*_Point,_Digits);
//   request.deviation = 0;
//   request.type = ORDER_TYPE_BUY;
//   request.type_filling = ORDER_FILLING_FOK;
//
//   OrderSend(request,response);
//
//   if(response.retcode == 10008 || response.retcode == 10009)
//   {
//    Print("Order buy Exec Successfullty !!");
//   }
//
//   else
//   {
//    Print("Order buy Exec ERR : ",GetLastError());
//    ResetLastError();
//   }

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
//   MqlTradeRequest request;
//   MqlTradeResult response;
//
//   ZeroMemory(request);
//   ZeroMemory(response);
//
//   request.action = TRADE_ACTION_DEAL;
//   request.magic = magic_number;
//   request.symbol = _Symbol;
//   request.volume = num_lots;
//   request.price  = NormalizeDouble(tick.ask,_Digits);
//   request.sl = NormalizeDouble(tick.bid + SL*_Point,_Digits);
//   request.tp = NormalizeDouble(tick.bid - TK*_Point,_Digits);
//   request.deviation = 0;
//   request.type = ORDER_TYPE_SELL;
//   request.type_filling = ORDER_FILLING_FOK;
//
//   OrderSend(request,response);
//
//   if(response.retcode == 10008 || response.retcode == 10009)
//   {
//    Print("Order sell Exec Successfullty !!");
//   }
//
//   else
//   {
//    Print("Order sell Exec ERR : ",GetLastError());
//    ResetLastError();
//   }
//Print(">>>> IN SELL <<<<" );
   if(PositionSelect(_Symbol)==false)
     {
      //Print(">>>> Semd SELL <<<<" );
      double Bid = NormalizeDouble(SymbolInfoDouble(_Symbol,SYMBOL_BID),_Digits);
      trade.Sell(num_lots,NULL,Bid,(Bid+SL*_Point),(Bid-TK*_Point),NULL);
     }

  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void drawVerticalLine(string name,datetime dt,color cor = clrAliceBlue)
  {
//ObjectDelete(0,name);
   ObjectCreate(0,name,OBJ_VLINE,0,dt,0);
   ObjectSetInteger(0,name,OBJPROP_COLOR,cor);
  }
//+------------------------------------------------------------------+
//|                                                                  |
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
