//+------------------------------------------------------------------+
//|                  EA31337 - multi-strategy advanced trading robot |
//|                       Copyright 2016-2020, 31337 Investments Ltd |
//|                                       https://github.com/EA31337 |
//+------------------------------------------------------------------+

/**
 * @file
 * Implements Fractals strategy.
 */

// Includes.
#include <EA31337-classes/Indicators/Indi_Fractals.mqh>
#include <EA31337-classes/Strategy.mqh>

// User input params.
INPUT string __Fractals_Parameters__ = "-- Fractals strategy params --";  // >>> FRACTALS <<<
INPUT int Fractals_Active_Tf = 0;  // Activate timeframes (1-255, e.g. M1=1,M5=2,M15=4,M30=8,H1=16,H2=32...)
INPUT int Fractals_Shift = 0;      // Shift
INPUT ENUM_TRAIL_TYPE Fractals_TrailingStopMethod = 1;     // Trail stop method
INPUT ENUM_TRAIL_TYPE Fractals_TrailingProfitMethod = 21;  // Trail profit method
INPUT int Fractals_SignalOpenLevel = 0;                    // Signal open level
INPUT int Fractals1_SignalBaseMethod = 3;                  // Signal base method (-3-3)
INPUT int Fractals1_OpenCondition1 = 971;                  // Open condition 1 (0-1023)
INPUT int Fractals1_OpenCondition2 = 0;                    // Open condition 2 (0-)
INPUT ENUM_MARKET_EVENT Fractals1_CloseCondition = 11;     // Close condition for M1
INPUT double Fractals_MaxSpread = 6.0;                     // Max spread to trade (pips)

// Struct to define strategy parameters to override.
struct Stg_Fractals_Params : Stg_Params {
  unsigned int Fractals_Period;
  ENUM_APPLIED_PRICE Fractals_Applied_Price;
  int Fractals_Shift;
  ENUM_TRAIL_TYPE Fractals_TrailingStopMethod;
  ENUM_TRAIL_TYPE Fractals_TrailingProfitMethod;
  double Fractals_SignalOpenLevel;
  long Fractals_SignalBaseMethod;
  long Fractals_SignalOpenMethod1;
  long Fractals_SignalOpenMethod2;
  double Fractals_SignalCloseLevel;
  ENUM_MARKET_EVENT Fractals_SignalCloseMethod1;
  ENUM_MARKET_EVENT Fractals_SignalCloseMethod2;
  double Fractals_MaxSpread;

  // Constructor: Set default param values.
  Stg_Fractals_Params()
      : Fractals_Period(::Fractals_Period),
        Fractals_Applied_Price(::Fractals_Applied_Price),
        Fractals_Shift(::Fractals_Shift),
        Fractals_TrailingStopMethod(::Fractals_TrailingStopMethod),
        Fractals_TrailingProfitMethod(::Fractals_TrailingProfitMethod),
        Fractals_SignalOpenLevel(::Fractals_SignalOpenLevel),
        Fractals_SignalBaseMethod(::Fractals_SignalBaseMethod),
        Fractals_SignalOpenMethod1(::Fractals_SignalOpenMethod1),
        Fractals_SignalOpenMethod2(::Fractals_SignalOpenMethod2),
        Fractals_SignalCloseLevel(::Fractals_SignalCloseLevel),
        Fractals_SignalCloseMethod1(::Fractals_SignalCloseMethod1),
        Fractals_SignalCloseMethod2(::Fractals_SignalCloseMethod2),
        Fractals_MaxSpread(::Fractals_MaxSpread) {}
};

// Loads pair specific param values.
#include "sets/EURUSD_H1.h"
#include "sets/EURUSD_H4.h"
#include "sets/EURUSD_M1.h"
#include "sets/EURUSD_M15.h"
#include "sets/EURUSD_M30.h"
#include "sets/EURUSD_M5.h"

class Stg_Fractals : public Strategy {
 public:
  Stg_Fractals(StgParams &_params, string _name) : Strategy(_params, _name) {}

  static Stg_Fractals *Init(ENUM_TIMEFRAMES _tf = NULL, long _magic_no = NULL, ENUM_LOG_LEVEL _log_level = V_INFO) {
    // Initialize strategy initial values.
    Stg_Fractals_Params _params;
    switch (_tf) {
      case PERIOD_M1: {
        Stg_Fractals_EURUSD_M1_Params _new_params;
        _params = _new_params;
      }
      case PERIOD_M5: {
        Stg_Fractals_EURUSD_M5_Params _new_params;
        _params = _new_params;
      }
      case PERIOD_M15: {
        Stg_Fractals_EURUSD_M15_Params _new_params;
        _params = _new_params;
      }
      case PERIOD_M30: {
        Stg_Fractals_EURUSD_M30_Params _new_params;
        _params = _new_params;
      }
      case PERIOD_H1: {
        Stg_Fractals_EURUSD_H1_Params _new_params;
        _params = _new_params;
      }
      case PERIOD_H4: {
        Stg_Fractals_EURUSD_H4_Params _new_params;
        _params = _new_params;
      }
    }
    // Initialize strategy parameters.
    ChartParams cparams(_tf);
    Fractals_Params adx_params(_params.Fractals_Period, _params.Fractals_Applied_Price);
    IndicatorParams adx_iparams(10, INDI_Fractals);
    StgParams sparams(new Trade(_tf, _Symbol), new Indi_Fractals(adx_params, adx_iparams, cparams), NULL, NULL);
    sparams.logger.SetLevel(_log_level);
    sparams.SetMagicNo(_magic_no);
    sparams.SetSignals(_params.Fractals_SignalBaseMethod, _params.Fractals_SignalOpenMethod1,
                       _params.Fractals_SignalOpenMethod2, _params.Fractals_SignalCloseMethod1,
                       _params.Fractals_SignalCloseMethod2, _params.Fractals_SignalOpenLevel,
                       _params.Fractals_SignalCloseLevel);
    sparams.SetStops(_params.Fractals_TrailingProfitMethod, _params.Fractals_TrailingStopMethod);
    sparams.SetMaxSpread(_params.Fractals_MaxSpread);
    // Initialize strategy instance.
    Strategy *_strat = new Stg_Fractals(sparams, "Fractals");
    return _strat;
  }

  /**
   * Check if Fractals indicator is on buy or sell.
   *
   * @param
   *   _cmd (int) - type of trade order command
   *   period (int) - period to check for
   *   _signal_method (int) - signal method to use by using bitwise AND operation
   *   _signal_level1 (double) - signal level to consider the signal
   */
  bool SignalOpen(ENUM_ORDER_TYPE _cmd, long _signal_method = EMPTY, double _signal_level = EMPTY) {
    bool _result = false;
    double fractals_0_lower = ((Indi_Fractals *)this.Data()).GetValue(LINE_LOWER, 0);
    double fractals_0_upper = ((Indi_Fractals *)this.Data()).GetValue(LINE_UPPER, 0);
    double fractals_1_lower = ((Indi_Fractals *)this.Data()).GetValue(LINE_LOWER, 1);
    double fractals_1_upper = ((Indi_Fractals *)this.Data()).GetValue(LINE_UPPER, 1);
    double fractals_2_lower = ((Indi_Fractals *)this.Data()).GetValue(LINE_LOWER, 2);
    double fractals_2_upper = ((Indi_Fractals *)this.Data()).GetValue(LINE_UPPER, 2);
    if (_signal_method == EMPTY) _signal_method = GetSignalBaseMethod();
    if (_signal_level1 == EMPTY) _signal_level1 = GetSignalLevel1();
    if (_signal_level2 == EMPTY) _signal_level2 = GetSignalLevel2();
    bool lower = (fractals_0_lower != 0.0 || fractals_1_lower != 0.0 || fractals_2_lower != 0.0);
    bool upper = (fractals_0_upper != 0.0 || fractals_1_upper != 0.0 || fractals_2_upper != 0.0);
    switch (_cmd) {
      case ORDER_TYPE_BUY:
        _result = lower;
        if (METHOD(_signal_method, 0)) _result &= Open[CURR] > Close[PREV];
        if (METHOD(_signal_method, 1)) _result &= this.Chart().GetBid() > Open[CURR];
        // if (METHOD(_signal_method, 0)) _result &= !Trade_Fractals(Convert::NegateOrderType(_cmd), PERIOD_M30);
        // if (METHOD(_signal_method, 1)) _result &= !Trade_Fractals(Convert::NegateOrderType(_cmd),
        // Convert::IndexToTf(fmax(index + 1, M30))); if (METHOD(_signal_method, 2)) _result &=
        // !Trade_Fractals(Convert::NegateOrderType(_cmd), Convert::IndexToTf(fmax(index + 2, M30))); if
        // (METHOD(_signal_method, 1)) _result &= !Fractals_On_Sell(tf); if (METHOD(_signal_method, 3)) _result &=
        // Fractals_On_Buy(M30);
        break;
      case ORDER_TYPE_SELL:
        _result = upper;
        if (METHOD(_signal_method, 0)) _result &= Open[CURR] < Close[PREV];
        if (METHOD(_signal_method, 1)) _result &= this.Chart().GetAsk() < Open[CURR];
        // if (METHOD(_signal_method, 0)) _result &= !Trade_Fractals(Convert::NegateOrderType(_cmd), PERIOD_M30);
        // if (METHOD(_signal_method, 1)) _result &= !Trade_Fractals(Convert::NegateOrderType(_cmd),
        // Convert::IndexToTf(fmax(index + 1, M30))); if (METHOD(_signal_method, 2)) _result &=
        // !Trade_Fractals(Convert::NegateOrderType(_cmd), Convert::IndexToTf(fmax(index + 2, M30))); if
        // (METHOD(_signal_method, 1)) _result &= !Fractals_On_Buy(tf); if (METHOD(_signal_method, 3)) _result &=
        // Fractals_On_Sell(M30);
        break;
    }
    return _result;
  }

  /**
   * Check strategy's closing signal.
   */
  bool SignalClose(ENUM_ORDER_TYPE _cmd, long _signal_method = EMPTY, double _signal_level = EMPTY) {
    if (_signal_level == EMPTY) _signal_level = GetSignalCloseLevel();
    return SignalOpen(Order::NegateOrderType(_cmd), _signal_method, _signal_level);
  }
};
