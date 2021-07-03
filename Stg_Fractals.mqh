/**
 * @file
 * Implements Fractals strategy.
 */

// User input params.
INPUT string __Fractals_Parameters__ = "-- Fractals strategy params --";  // >>> FRACTALS <<<
INPUT float Fractals_LotSize = 0;                                         // Lot size
INPUT int Fractals_SignalOpenMethod = 2;                                  // Signal open method (-127-127)
INPUT float Fractals_SignalOpenLevel = 0.0f;                              // Signal open level
INPUT int Fractals_SignalOpenFilterMethod = 32;                            // Signal open filter method
INPUT int Fractals_SignalOpenBoostMethod = 0;                             // Signal open boost method
INPUT int Fractals_SignalCloseMethod = 2;                                 // Signal close method (-127-127)
INPUT float Fractals_SignalCloseLevel = 0.0f;                             // Signal close level
INPUT int Fractals_PriceStopMethod = 1;                                   // Price stop method
INPUT float Fractals_PriceStopLevel = 0;                                  // Price stop level
INPUT int Fractals_TickFilterMethod = 1;                                  // Tick filter method
INPUT float Fractals_MaxSpread = 4.0;                                     // Max spread to trade (pips)
INPUT short Fractals_Shift = 0;                                           // Shift
INPUT int Fractals_OrderCloseTime = -20;                                  // Order close time in mins (>0) or bars (<0)
INPUT string __Fractals_Indi_Fractals_Parameters__ =
    "-- Fractals strategy: Fractals indicator params --";  // >>> Fractals strategy: Fractals indicator <<<
INPUT int Fractals_Indi_Fractals_Shift = 0;                // Shift

// Structs.

// Defines struct with default user indicator values.
struct Indi_Fractals_Params_Defaults : FractalsParams {
  Indi_Fractals_Params_Defaults() : FractalsParams(::Fractals_Indi_Fractals_Shift) {}
} indi_fractals_defaults;

// Defines struct to store indicator parameter values.
struct Indi_Fractals_Params : public FractalsParams {
  // Struct constructors.
  void Indi_Fractals_Params(FractalsParams &_params, ENUM_TIMEFRAMES _tf) : FractalsParams(_params, _tf) {}
};

// Defines struct with default user strategy values.
struct Stg_Fractals_Params_Defaults : StgParams {
  Stg_Fractals_Params_Defaults()
      : StgParams(::Fractals_SignalOpenMethod, ::Fractals_SignalOpenFilterMethod, ::Fractals_SignalOpenLevel,
                  ::Fractals_SignalOpenBoostMethod, ::Fractals_SignalCloseMethod, ::Fractals_SignalCloseLevel,
                  ::Fractals_PriceStopMethod, ::Fractals_PriceStopLevel, ::Fractals_TickFilterMethod,
                  ::Fractals_MaxSpread, ::Fractals_Shift, ::Fractals_OrderCloseTime) {}
} stg_fractals_defaults;

// Struct to define strategy parameters to override.
struct Stg_Fractals_Params : StgParams {
  StgParams sparams;

  // Struct constructors.
  Stg_Fractals_Params(Indi_Fractals_Params &_iparams, StgParams &_sparams) : sparams(stg_fractals_defaults) {
    sparams = _sparams;
  }
};

// Loads pair specific param values.
#include "config/EURUSD_H1.h"
#include "config/EURUSD_H4.h"
#include "config/EURUSD_H8.h"
#include "config/EURUSD_M1.h"
#include "config/EURUSD_M15.h"
#include "config/EURUSD_M30.h"
#include "config/EURUSD_M5.h"

class Stg_Fractals : public Strategy {
 public:
  Stg_Fractals(StgParams &_sparams, TradeParams &_tparams, ChartParams &_cparams, string _name = "")
      : Strategy(_sparams, _tparams, _cparams, _name) {}

  static Stg_Fractals *Init(ENUM_TIMEFRAMES _tf = NULL, long _magic_no = NULL, ENUM_LOG_LEVEL _log_level = V_INFO) {
    // Initialize strategy initial values.
    StgParams _stg_params(stg_fractals_defaults);
#ifdef __config__
    SetParamsByTf<StgParams>(_stg_params, _tf, stg_fractals_m1, stg_fractals_m5, stg_fractals_m15, stg_fractals_m30,
                             stg_fractals_h1, stg_fractals_h4, stg_fractals_h8);
#endif
    // Initialize indicator.
    FractalsParams _indi_params(_tf);
    _stg_params.SetIndicator(new Indi_Fractals(_indi_params));
    // Initialize Strategy instance.
    ChartParams _cparams(_tf, _Symbol);
    TradeParams _tparams(_magic_no, _log_level);
    Strategy *_strat = new Stg_Fractals(_stg_params, _tparams, _cparams, "Fractals");
    return _strat;
  }

  /**
   * Check if Fractals indicator is on buy or sell.
   *
   * @param
   *   _cmd (int) - type of trade order command
   *   period (int) - period to check for
   *   _method (int) - signal method to use by using bitwise AND operation
   *   _level (double) - signal level to consider the signal
   */
  bool SignalOpen(ENUM_ORDER_TYPE _cmd, int _method = 0, float _level = 0.0f, int _shift = 0) {
    Chart *_chart = trade.GetChart();
    Indi_Fractals *_indi = GetIndicator();
    bool _is_valid = _indi[CURR].IsValid() && _indi[PREV].IsValid() && _indi[PPREV].IsValid();
    bool _result = _is_valid;
    if (!_result) {
      // Returns false when indicator data is not valid.
      return false;
    }
    double level = _level * Chart().GetPipSize();
    bool lower = (_indi[CURR][(int)LINE_LOWER] != 0.0 || _indi[PREV][(int)LINE_LOWER] != 0.0 ||
                  _indi[PPREV][(int)LINE_LOWER] != 0.0);
    bool upper = (_indi[CURR][(int)LINE_UPPER] != 0.0 || _indi[PREV][(int)LINE_UPPER] != 0.0 ||
                  _indi[PPREV][(int)LINE_UPPER] != 0.0);
    switch (_cmd) {
      case ORDER_TYPE_BUY:
        _result = lower;
        if (METHOD(_method, 0)) _result &= _indi[CURR][(int)LINE_LOWER] != 0.0;
        if (METHOD(_method, 1)) _result &= _indi[PREV][(int)LINE_LOWER] != 0.0;
        if (METHOD(_method, 2)) _result &= _indi[PPREV][(int)LINE_LOWER] != 0.0;
        break;
      case ORDER_TYPE_SELL:
        _result = upper;
        if (METHOD(_method, 0)) _result &= _indi[CURR][(int)LINE_UPPER] != 0.0;
        if (METHOD(_method, 1)) _result &= _indi[PREV][(int)LINE_UPPER] != 0.0;
        if (METHOD(_method, 2)) _result &= _indi[PPREV][(int)LINE_UPPER] != 0.0;
        break;
    }
    return _result;
  }
};
