//+------------------------------------------------------------------+
//| RBOT PRO XAU v3.0 - Indicators Header File                       |
//| Professional MetaTrader 5 Expert Advisor for XAUUSD Trading      |
//| Implementare nativă MQL5 a tuturor indicatorilor                  |
//+------------------------------------------------------------------+
#property copyright "RBOT PRO XAU"
#property version   "3.0"

#ifndef __INDICATORS_MQH__
#define __INDICATORS_MQH__

#include "Config.mqh"
#include "Utils.mqh"

//+------------------------------------------------------------------+
//| CLASA PENTRU CALCULUL INDICATORILOR                              |
//+------------------------------------------------------------------+
class CIndicators
{
private:
    string m_symbol;
    ENUM_TIMEFRAMES m_timeframe;
    
public:
    CIndicators(string symbol, ENUM_TIMEFRAMES timeframe)
    {
        m_symbol = symbol;
        m_timeframe = timeframe;
    }
    
    //+------------------------------------------------------------------+
    //| MEDIA MOBILĂ EXPONENȚIALĂ (EMA)                                  |
    //+------------------------------------------------------------------+
    double CalculateEMA(int period, int shift = 0)
    {
        double ema = 0.0;
        double multiplier = 2.0 / (period + 1.0);
        
        MqlRates rates[];
        ArraySetAsSeries(rates, true);
        
        if (CopyRates(m_symbol, m_timeframe, shift, period + 100, rates) <= 0)
            return 0.0;
        
        ema = rates[period + 99].close;
        
        for (int i = period + 98; i >= shift; i--)
        {
            ema = (rates[i].close - ema) * multiplier + ema;
        }
        
        return ema;
    }
    
    //+------------------------------------------------------------------+
    //| RSI - RELATIVE STRENGTH INDEX                                    |
    //+------------------------------------------------------------------+
    double CalculateRSI(int period, int shift = 0)
    {
        MqlRates rates[];
        ArraySetAsSeries(rates, true);
        
        if (CopyRates(m_symbol, m_timeframe, shift, period + 1, rates) <= 0)
            return 50.0;
        
        double sumGains = 0.0;
        double sumLosses = 0.0;
        
        for (int i = period; i > 0; i--)
        {
            double change = rates[i - 1].close - rates[i].close;
            
            if (change > 0)
                sumGains += change;
            else
                sumLosses += -change;
        }
        
        double avgGains = sumGains / period;
        double avgLosses = sumLosses / period;
        
        if (avgLosses == 0.0)
            return (avgGains > 0.0) ? 100.0 : 50.0;
        
        double rs = avgGains / avgLosses;
        double rsi = 100.0 - (100.0 / (1.0 + rs));
        
        return rsi;
    }
    
    //+------------------------------------------------------------------+
    //| ADX - AVERAGE DIRECTIONAL INDEX                                  |
    //+------------------------------------------------------------------+
    double CalculateADX(int period, int shift = 0)
    {
        MqlRates rates[];
        ArraySetAsSeries(rates, true);
        
        if (CopyRates(m_symbol, m_timeframe, shift, period + 10, rates) <= 0)
            return 0.0;
        
        double sumPlusDM = 0.0;
        double sumMinusDM = 0.0;
        double sumTR = 0.0;
        
        for (int i = period + 9; i > 0; i--)
        {
            double tr = MathMax(rates[i - 1].high - rates[i - 1].low,
                       MathMax(MathAbs(rates[i - 1].high - rates[i].close),
                               MathAbs(rates[i - 1].low - rates[i].close)));
            sumTR += tr;
            
            double upMove = rates[i - 1].high - rates[i].high;
            if (upMove > 0 && upMove > (rates[i].low - rates[i - 1].low))
                sumPlusDM += upMove;
            
            double downMove = rates[i].low - rates[i - 1].low;
            if (downMove > 0 && downMove > upMove)
                sumMinusDM += downMove;
        }
        
        double avgTR = sumTR / period;
        double avgPlusDM = sumPlusDM / period;
        double avgMinusDM = sumMinusDM / period;
        
        if (avgTR == 0.0)
            return 0.0;
        
        double plusDI = (avgPlusDM / avgTR) * 100.0;
        double minusDI = (avgMinusDM / avgTR) * 100.0;
        double dx = MathAbs(plusDI - minusDI) / (plusDI + minusDI) * 100.0;
        double adx = dx;
        
        return MathMax(0.0, MathMin(100.0, adx));
    }
    
    //+------------------------------------------------------------------+
    //| ATR - AVERAGE TRUE RANGE                                         |
    //+------------------------------------------------------------------+
    double CalculateATR(int period, int shift = 0)
    {
        MqlRates rates[];
        ArraySetAsSeries(rates, true);
        
        if (CopyRates(m_symbol, m_timeframe, shift, period + 1, rates) <= 0)
            return 0.0;
        
        double sumTR = 0.0;
        
        for (int i = period; i > 0; i--)
        {
            double tr = MathMax(rates[i - 1].high - rates[i - 1].low,
                       MathMax(MathAbs(rates[i - 1].high - rates[i].close),
                               MathAbs(rates[i - 1].low - rates[i].close)));
            sumTR += tr;
        }
        
        return sumTR / period;
    }
    
    //+------------------------------------------------------------------+
    //| MOMENTUM                                                         |
    //+------------------------------------------------------------------+
    double CalculateMomentum(int period, int shift = 0)
    {
        MqlRates rates[];
        ArraySetAsSeries(rates, true);
        
        if (CopyRates(m_symbol, m_timeframe, shift, period + 1, rates) <= 0)
            return 0.0;
        
        return rates[shift].close - rates[shift + period].close;
    }
    
    //+------------------------------------------------------------------+
    //| VOLATILITATE                                                     |
    //+------------------------------------------------------------------+
    double CalculateVolatility(int period, int shift = 0)
    {
        MqlRates rates[];
        ArraySetAsSeries(rates, true);
        
        if (CopyRates(m_symbol, m_timeframe, shift, period, rates) <= 0)
            return 0.0;
        
        double average = 0.0;
        for (int i = 0; i < period; i++)
        {
            average += rates[i].close;
        }
        average /= period;
        
        double variance = 0.0;
        for (int i = 0; i < period; i++)
        {
            double diff = rates[i].close - average;
            variance += diff * diff;
        }
        variance /= period;
        
        return MathSqrt(variance);
    }
    
    //+------------------------------------------------------------------+
    //| VOLUM MEDIU                                                      |
    //+------------------------------------------------------------------+
    double CalculateAverageVolume(int period, int shift = 0)
    {
        MqlRates rates[];
        ArraySetAsSeries(rates, true);
        
        if (CopyRates(m_symbol, m_timeframe, shift, period, rates) <= 0)
            return 0.0;
        
        double sumVolume = 0.0;
        for (int i = 0; i < period; i++)
        {
            sumVolume += rates[i].tick_volume;
        }
        
        return sumVolume / period;
    }
    
    //+------------------------------------------------------------------+
    //| VERIFICARE SPIKE ATR                                             |
    //+------------------------------------------------------------------+
    bool IsATRSpike(double currentATR, double averageATR, double multiplier = ATR_SPIKE_MULTIPLIER)
    {
        return (currentATR > averageATR * multiplier);
    }
    
    //+------------------------------------------------------------------+
    //| OBȚINERE PREȚ INCHIDERE                                          |
    //+------------------------------------------------------------------+
    double GetClose(int shift = 0)
    {
        MqlRates rates[];
        ArraySetAsSeries(rates, true);
        
        if (CopyRates(m_symbol, m_timeframe, shift, 1, rates) <= 0)
            return 0.0;
        
        return rates[shift].close;
    }
    
    //+------------------------------------------------------------------+
    //| OBȚINERE MAXIM/MINIM                                             |
    //+------------------------------------------------------------------+
    double GetHigh(int shift = 0)
    {
        MqlRates rates[];
        ArraySetAsSeries(rates, true);
        
        if (CopyRates(m_symbol, m_timeframe, shift, 1, rates) <= 0)
            return 0.0;
        
        return rates[shift].high;
    }
    
    double GetLow(int shift = 0)
    {
        MqlRates rates[];
        ArraySetAsSeries(rates, true);
        
        if (CopyRates(m_symbol, m_timeframe, shift, 1, rates) <= 0)
            return 0.0;
        
        return rates[shift].low;
    }
    
    //+------------------------------------------------------------------+
    //| OBȚINERE VOLUM                                                    |
    //+------------------------------------------------------------------+
    long GetVolume(int shift = 0)
    {
        MqlRates rates[];
        ArraySetAsSeries(rates, true);
        
        if (CopyRates(m_symbol, m_timeframe, shift, 1, rates) <= 0)
            return 0;
        
        return rates[shift].tick_volume;
    }
};

#endif // __INDICATORS_MQH__
