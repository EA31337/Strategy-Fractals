/*
 * @file
 * Defines default strategy parameter values for the given timeframe.
 */

// Defines indicator's parameter values for the given pair symbol and timeframe.
struct Indi_Fractals_Params_M15 : Indi_Fractals_Params {
  Indi_Fractals_Params_M15() : Indi_Fractals_Params(indi_fractals_defaults, PERIOD_M15) {
    shift = 0;
  }
} indi_fractals_m15;

// Defines strategy's parameter values for the given pair symbol and timeframe.
struct Stg_Fractals_Params_M15 : StgParams {
  // Struct constructor.
  Stg_Fractals_Params_M15() : StgParams(stg_fractals_defaults) {
    lot_size = 0;
    signal_open_method = 0;
    signal_open_filter = 1;
    signal_open_level = (float)0;
    signal_open_boost = 0;
    signal_close_method = 0;
    signal_close_level = (float)0;
    price_stop_method = 0;
    price_stop_level = 2;
    tick_filter_method = 1;
    max_spread = 0;
  }
} stg_fractals_m15;
