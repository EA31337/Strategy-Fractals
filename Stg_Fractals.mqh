/**
 * @file
 * Implements Fractals strategy.
 */

// User input params.
INPUT int Fractals_Shift = 0;                   // Shift
INPUT int Fractals_SignalOpenMethod = 3;        // Signal open method (-3-3)
INPUT float Fractals_SignalOpenLevel = 0;      // Signal open level
INPUT int Fractals_SignalOpenFilterMethod = 0;  // Signal open filter method
INPUT int Fractals_SignalOpenBoostMethod = 0;   // Signal open boost method
INPUT int Fractals_SignalCloseMethod = 3;       // Signal close method (-3-3)
INPUT int Fractals_SignalCloseLevel = 0;        // Signal close level
INPUT int Fractals_PriceLimitMethod = 0;        // Price limit method
INPUT float Fractals_PriceLimitLevel = 0;      // Price limit level
INPUT float Fractals_MaxSpread = 6.0;          // Max spread to trade (pips)

// Includes.
#include <EA31337-classes/Indicators/Indi_Fractals.mqh>
#include <EA31337-classes/Strategy.mqh>

// Struct to define strategy parameters to override.
struct Stg_Fractals_Params : StgParams {
  int Fractals_Shift;
  int Fractals_SignalOpenMethod;
  double Fractals_SignalOpenLevel;
  int Fractals_SignalOpenFilterMethod;
  int Fractals_SignalOpenBoostMethod;
  int Fractals_SignalCloseMethod;
  double Fractals_SignalCloseLevel;
  int Fractals_PriceLimitMethod;
  double Fractals_PriceLimitLevel;
  double Fractals_MaxSpread;

  // Constructor: Set default param values.
  Stg_Fractals_Params()
      : Fractals_Shift(::Fractals_Shift),
        Fractals_SignalOpenMethod(::Fractals_SignalOpenMethod),
        Fractals_SignalOpenLevel(::Fractals_SignalOpenLevel),
        Fractals_SignalOpenFilterMethod(::Fractals_SignalOpenFilterMethod),
        Fractals_SignalOpenBoostMethod(::Fractals_SignalOpenBoostMethod),
        Fractals_SignalCloseMethod(::Fractals_SignalCloseMethod),
        Fractals_SignalCloseLevel(::Fractals_SignalCloseLevel),
        Fractals_PriceLimitMethod(::Fractals_PriceLimitMethod),
        Fractals_PriceLimitLevel(::Fractals_PriceLimitLevel),
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
    if (!Terminal::IsOptimization()) {
      SetParamsByTf<Stg_Fractals_Params>(_params, _tf, stg_fractals_m1, stg_fractals_m5, stg_fractals_m15,
                                         stg_fractals_m30, stg_fractals_h1, stg_fractals_h4, stg_fractals_h4);
    }
    // Initialize strategy parameters.
    FractalsParams fractals_params(_tf);
    StgParams sparams(new Trade(_tf, _Symbol), new Indi_Fractals(fractals_params), NULL, NULL);
    sparams.logger.Ptr().SetLevel(_log_level);
    sparams.SetMagicNo(_magic_no);
    sparams.SetSignals(_params.Fractals_SignalOpenMethod, _params.Fractals_SignalOpenMethod,
                       _params.Fractals_SignalOpenFilterMethod, _params.Fractals_SignalOpenBoostMethod,
                       _params.Fractals_SignalCloseMethod, _params.Fractals_SignalCloseMethod);
    sparams.SetPriceLimits(_params.Fractals_PriceLimitMethod, _params.Fractals_PriceLimitLevel);
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
   *   _method (int) - signal method to use by using bitwise AND operation
   *   _level (double) - signal level to consider the signal
   */
  bool SignalOpen(ENUM_ORDER_TYPE _cmd, int _method = 0, float _level = 0.0) {
    Chart *_chart = Chart();
    Indi_Fractals *_indi = Data();
    bool _is_valid = _indi[CURR].IsValid() && _indi[PREV].IsValid() && _indi[PPREV].IsValid();
    bool _result = _is_valid;
    if (!_result) {
      // Returns false when indicator data is not valid.
      return false;
    }
    double level = _level * Chart().GetPipSize();
    bool lower = (_indi[CURR].value[LINE_LOWER] != 0.0 || _indi[PREV].value[LINE_LOWER] != 0.0 ||
                  _indi[PPREV].value[LINE_LOWER] != 0.0);
    bool upper = (_indi[CURR].value[LINE_UPPER] != 0.0 || _indi[PREV].value[LINE_UPPER] != 0.0 ||
                  _indi[PPREV].value[LINE_UPPER] != 0.0);
    switch (_cmd) {
      case ORDER_TYPE_BUY:
        _result = lower;
        if (METHOD(_method, 0)) _result &= _indi[CURR].value[LINE_LOWER] != 0.0;
        if (METHOD(_method, 1)) _result &= _indi[PREV].value[LINE_LOWER] != 0.0;
        if (METHOD(_method, 2)) _result &= _indi[PPREV].value[LINE_LOWER] != 0.0;
        break;
      case ORDER_TYPE_SELL:
        _result = upper;
        if (METHOD(_method, 0)) _result &= _indi[CURR].value[LINE_UPPER] != 0.0;
        if (METHOD(_method, 1)) _result &= _indi[PREV].value[LINE_UPPER] != 0.0;
        if (METHOD(_method, 2)) _result &= _indi[PPREV].value[LINE_UPPER] != 0.0;
        break;
    }
    return _result;
  }

  /**
   * Gets price limit value for profit take or stop loss.
   */
  float PriceLimit(ENUM_ORDER_TYPE _cmd, ENUM_ORDER_TYPE_VALUE _mode, int _method = 0, float _level = 0.0) {
    Chart *_chart = Chart();
    Indi_Fractals *_indi = Data();
    double _trail = _level * Market().GetPipSize();
    int _direction = Order::OrderDirection(_cmd, _mode);
    double _default_value = Market().GetCloseOffer(_cmd) + _trail * _method * _direction;
    double _result = _default_value;
    switch (_method) {
      case 0:
        _result = _direction < 0 ? _indi[PREV].value[LINE_LOWER] - _trail : _indi[PREV].value[LINE_UPPER] + _trail;
        break;
      case 1:
        _result = _direction < 0 ? _indi.GetMinDbl(20) - _trail : _indi.GetMaxDbl(20) + _trail;
        break;
      case 2:
        _result = _direction < 0 ? _indi.GetMinDbl(50) - _trail : _indi.GetMaxDbl(50) + _trail;
        break;
      case 3: {
        int _bar_count = (int)_level * 10;
        _result = _direction > 0 ? _indi.GetPrice(PRICE_HIGH, _indi.GetHighest(_bar_count))
                                 : _indi.GetPrice(PRICE_LOW, _indi.GetLowest(_bar_count));
        break;
      }
    }
    return fmax(_result, 0);
  }
};
