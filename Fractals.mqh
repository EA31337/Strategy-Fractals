//+------------------------------------------------------------------+
//|                 EA31337 - multi-strategy advanced trading robot. |
//|                       Copyright 2016-2017, 31337 Investments Ltd |
//|                                       https://github.com/EA31337 |
//+------------------------------------------------------------------+

/*
    This file is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

// Properties.
#property strict

/**
 * @file
 * Implementation of Fractals Strategy based on the Average True Range indicator (Fractals).
 *
 * @docs
 * - https://docs.mql4.com/indicators/iFractals
 * - https://www.mql5.com/en/docs/indicators/iFractals
 */

// Includes.
#include <EA31337-classes\Strategy.mqh>
#include <EA31337-classes\Strategies.mqh>

// User inputs.
#ifdef __input__ input #endif string __Fractals_Parameters__ = "-- Settings for the Fractals indicator --"; // >>> FRACTALS <<<
/* @todo #ifdef __input__ input #endif */ int Fractals_SignalLevel = 0; // Signal level
#ifdef __input__ input #endif int Fractals_SignalMethod = 3; // Signal method for M1 (-3-3)

class Fractals: public Strategy {
protected:

  double fractals[H4][FINAL_ENUM_INDICATOR_INDEX][FINAL_LINE_ENTRY];
  int       open_method = EMPTY;    // Open method.
  double    open_level  = 0.0;     // Open level.

public:

  /**
   * Update indicator values.
   */
  bool Update(int tf = EMPTY) {
    // Calculates the Fractals indicator.
    for (i = 0; i < FINAL_ENUM_INDICATOR_INDEX; i++) {
      fractals[index][i][LOWER] = iFractals(symbol, tf, LOWER, i);
      fractals[index][i][UPPER] = iFractals(symbol, tf, UPPER, i);
    }
    if (VerboseDebug) PrintFormat("Fractals M%d: %s", tf, Arrays::ArrToString3D(fractals, ",", Digits));
  }

  /**
   * Check if Fractals indicator is on buy or sell.
   *
   * @param
   *   cmd (int) - type of trade order command
   *   period (int) - period to check for
   *   signal_method (int) - signal method to use by using bitwise AND operation
   *   signal_level (double) - signal level to consider the signal
   */
  bool Signal(int cmd, ENUM_TIMEFRAMES tf = PERIOD_M1, int signal_method = EMPTY, double signal_level = EMPTY) {
    bool result = FALSE; int index = Timeframe::TfToIndex(tf);
    UpdateIndicator(S_FRACTALS, tf);
    if (signal_method == EMPTY) signal_method = GetStrategySignalMethod(S_FRACTALS, tf, 0);
    if (signal_level  == EMPTY) signal_level  = GetStrategySignalLevel(S_FRACTALS, tf, 0.0);
    bool lower = (fractals[index][CURR][LOWER] != 0.0 || fractals[index][PREV][LOWER] != 0.0 || fractals[index][FAR][LOWER] != 0.0);
    bool upper = (fractals[index][CURR][UPPER] != 0.0 || fractals[index][PREV][UPPER] != 0.0 || fractals[index][FAR][UPPER] != 0.0);
    switch (cmd) {
      case OP_BUY:
        result = lower;
        if ((signal_method &   1) != 0) result &= Open[CURR] > Close[PREV];
        if ((signal_method &   2) != 0) result &= Bid > Open[CURR];
        // if ((signal_method &   1) != 0) result &= !Trade_Fractals(Convert::NegateOrderType(cmd), PERIOD_M30);
        // if ((signal_method &   2) != 0) result &= !Trade_Fractals(Convert::NegateOrderType(cmd), Convert::IndexToTf(fmax(index + 1, M30)));
        // if ((signal_method &   4) != 0) result &= !Trade_Fractals(Convert::NegateOrderType(cmd), Convert::IndexToTf(fmax(index + 2, M30)));
        // if ((signal_method &   2) != 0) result &= !Fractals_On_Sell(tf);
        // if ((signal_method &   8) != 0) result &= Fractals_On_Buy(M30);
        break;
      case OP_SELL:
        result = upper;
        if ((signal_method &   1) != 0) result &= Open[CURR] < Close[PREV];
        if ((signal_method &   2) != 0) result &= Ask < Open[CURR];
        // if ((signal_method &   1) != 0) result &= !Trade_Fractals(Convert::NegateOrderType(cmd), PERIOD_M30);
        // if ((signal_method &   2) != 0) result &= !Trade_Fractals(Convert::NegateOrderType(cmd), Convert::IndexToTf(fmax(index + 1, M30)));
        // if ((signal_method &   4) != 0) result &= !Trade_Fractals(Convert::NegateOrderType(cmd), Convert::IndexToTf(fmax(index + 2, M30)));
        // if ((signal_method &   2) != 0) result &= !Fractals_On_Buy(tf);
        // if ((signal_method &   8) != 0) result &= Fractals_On_Sell(M30);
        break;
    }
    result &= signal_method <= 0 || Convert::ValueToOp(curr_trend) == cmd;
    if (VerboseTrace && result) {
      PrintFormat("%s:%d: Signal: %d/%d/%d/%g", __FUNCTION__, __LINE__, cmd, tf, signal_method, signal_level);
    }
    return result;
  }
};
