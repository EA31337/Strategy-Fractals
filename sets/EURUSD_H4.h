//+------------------------------------------------------------------+
//|                  EA31337 - multi-strategy advanced trading robot |
//|                       Copyright 2016-2020, 31337 Investments Ltd |
//|                                       https://github.com/EA31337 |
//+------------------------------------------------------------------+

// Defines strategy's parameter values for the given pair symbol and timeframe.
struct Stg_Fractals_EURUSD_H4_Params : Stg_Fractals_Params {
  Stg_Fractals_EURUSD_H4_Params() {
    symbol = "EURUSD";
    tf = PERIOD_H4;
    Fractals_Shift = 0;
    Fractals_SignalOpenMethod = 0;
    Fractals_SignalOpenLevel = 36;
    Fractals_SignalCloseMethod = 1;
    Fractals_SignalCloseLevel = 36;
    Fractals_PriceLimitMethod = 0;
    Fractals_PriceLimitLevel = 0;
    Fractals_MaxSpread = 10;
  }
} stg_fractals_h4;
