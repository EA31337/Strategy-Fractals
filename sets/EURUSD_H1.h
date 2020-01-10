//+------------------------------------------------------------------+
//|                  EA31337 - multi-strategy advanced trading robot |
//|                       Copyright 2016-2020, 31337 Investments Ltd |
//|                                       https://github.com/EA31337 |
//+------------------------------------------------------------------+

// Defines strategy's parameter values for the given pair symbol and timeframe.
struct Stg_Fractals_EURUSD_H1_Params : Stg_Fractals_Params {
  Stg_Fractals_EURUSD_H1_Params() {
    symbol = "EURUSD";
    tf = PERIOD_H1;
    Fractals_Period = 2;
    Fractals_Applied_Price = 3;
    Fractals_Shift = 0;
    Fractals_TrailingStopMethod = 6;
    Fractals_TrailingProfitMethod = 11;
    Fractals_SignalOpenLevel = 36;
    Fractals_SignalBaseMethod = 0;
    Fractals_SignalOpenMethod1 = 195;
    Fractals_SignalOpenMethod2 = 0;
    Fractals_SignalCloseLevel = 36;
    Fractals_SignalCloseMethod1 = 1;
    Fractals_SignalCloseMethod2 = 0;
    Fractals_MaxSpread = 6;
  }
};