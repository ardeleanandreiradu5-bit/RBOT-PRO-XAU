//+------------------------------------------------------------------+
//| RBOT PRO XAU v3.0 - Trend Analyzer Header File                   |
//| Professional MetaTrader 5 Expert Advisor for XAUUSD Trading      |
//| Analiză multi-timeframe a trendului                               |
//+------------------------------------------------------------------+
#property copyright "RBOT PRO XAU"
#property version   "3.0"

#ifndef __TREND_ANALYZER_MQH__
#define __TREND_ANALYZER_MQH__

#include "Config.mqh"
#include "Utils.mqh"
#include "Indicators.mqh"

//+------------------------------------------------------------------+
//| ENUM PENTRU TIPURI DE TREND                                      |
//+------------------------------------------------------------------+
enum ETrendType
{
    TREND_UP = 1,        // Trend crescător (bullish)
    TREND_DOWN = -1,     // Trend descrescător (bearish)
    TREND_RANGE = 0      // Consolidare / Range
};

//+------------------------------------------------------------------+
//| ENUM PENTRU STRUCTURA PIEȚEI                                     |
//+------------------------------------------------------------------+
enum EMarketStructure
{
    STRUCT_HH_HL = 1,    // Higher High - Higher Low (BULLISH)
    STRUCT_LH_LL = -1,   // Lower High - Lower Low (BEARISH)
    STRUCT_RANGE = 0,    // Consolidare
    STRUCT_BOS = 2,      // Break Of Structure
    STRUCT_CHOCH = 3,    // Change Of Character
    STRUCT_UNKNOWN = 99  // Necunoscut
};

//+------------------------------------------------------------------+
//| STRUCTURA PENTRU INFORMAȚII DE TREND                             |
//+------------------------------------------------------------------+
struct STrendInfo
{
    ETrendType trendType;           // Tipul trendului
    double trendStrength;           // Forța trendului (0-100)
    EMarketStructure structure;     // Structura pieței
    double distanceFromEMA20;       // Distanța până la EMA20
    double distanceFromEMA50;       // Distanța până la EMA50
    double distanceFromEMA200;      // Distanța până la EMA200
    int swingBarsHigh;              // Bare de la ultimul swing high
    int swingBarsLow;               // Bare de la ultimul swing low
    bool isBreakout;                // Detectat breakout?
};

//+------------------------------------------------------------------+
//| CLASA PENTRU ANALIZA TRENDULUI                                   |
//+------------------------------------------------------------------+
class CTrendAnalyzer
{
private:
    string m_symbol;
    CIndicators *m_indicators;
    double m_lastSwingHigh;
    double m_lastSwingLow;
    int m_lastSwingHighBar;
    int m_lastSwingLowBar;
    
public:
    CTrendAnalyzer(string symbol, ENUM_TIMEFRAMES timeframe)
    {
        m_symbol = symbol;
        m_indicators = new CIndicators(symbol, timeframe);
        m_lastSwingHigh = 0.0;
        m_lastSwingLow = 0.0;
        m_lastSwingHighBar = 0;
        m_lastSwingLowBar = 0;
    }
    
    ~CTrendAnalyzer()
    {
        if (m_indicators != NULL)
            delete m_indicators;
    }
    
    //+------------------------------------------------------------------+
    //| ANALIZĂ TREND PRINCIPAL                                          |
    //+------------------------------------------------------------------+
    STrendInfo AnalyzeTrend()
    {
        STrendInfo info;
        
        double ema20 = m_indicators->CalculateEMA(PERIOD_EMA_FAST);
        double ema50 = m_indicators->CalculateEMA(PERIOD_EMA_MID);
        double ema200 = m_indicators->CalculateEMA(PERIOD_EMA_SLOW);
        double adx = m_indicators->CalculateADX(PERIOD_ADX);
        double close = m_indicators->GetClose();
        
        info.distanceFromEMA20 = close - ema20;
        info.distanceFromEMA50 = close - ema50;
        info.distanceFromEMA200 = close - ema200;
        
        if (ema20 > ema50 && ema50 > ema200)
        {
            if (close > ema20 && close > ema50 && close > ema200)
            {
                info.trendType = TREND_UP;
                info.trendStrength = MathMin(100.0, adx);
            }
            else
            {
                info.trendType = TREND_RANGE;
                info.trendStrength = 50.0;
            }
        }
        else if (ema20 < ema50 && ema50 < ema200)
        {
            if (close < ema20 && close < ema50 && close < ema200)
            {
                info.trendType = TREND_DOWN;
                info.trendStrength = MathMin(100.0, adx);
            }
            else
            {
                info.trendType = TREND_RANGE;
                info.trendStrength = 50.0;
            }
        }
        else
        {
            info.trendType = TREND_RANGE;
            info.trendStrength = 30.0 + (adx / 2.0);
        }
        
        info.structure = AnalyzeMarketStructure();
        DetectSwingPoints();
        info.swingBarsHigh = m_lastSwingHighBar;
        info.swingBarsLow = m_lastSwingLowBar;
        
        return info;
    }
    
    //+------------------------------------------------------------------+
    //| ANALIZA STRUCTURII PIEȚEI                                        |
    //+------------------------------------------------------------------+
    EMarketStructure AnalyzeMarketStructure()
    {
        double high1, high2, low1, low2;
        int bar1 = 0, bar2 = 0, bar3 = 0;
        
        high1 = m_indicators->GetHigh(bar1);
        
        for (int i = 1; i <= SWING_LOOKBACK * 2; i++)
        {
            double h = m_indicators->GetHigh(i);
            if (i > SWING_LOOKBACK && h > high1)
            {
                high2 = h;
                bar2 = i;
                break;
            }
        }
        
        low1 = m_indicators->GetLow(bar1);
        
        for (int i = 1; i <= SWING_LOOKBACK * 2; i++)
        {
            double l = m_indicators->GetLow(i);
            if (i > SWING_LOOKBACK && l < low1)
            {
                low2 = l;
                bar3 = i;
                break;
            }
        }
        
        if (high1 > high2 && low1 > low2)
            return STRUCT_LH_LL;
        else if (high1 > high2 && low1 < low2)
            return STRUCT_BOS;
        else if (high1 < high2 && low1 > low2)
            return STRUCT_HH_HL;
        else if (high1 < high2 && low1 < low2)
            return STRUCT_CHOCH;
        
        return STRUCT_RANGE;
    }
    
    //+------------------------------------------------------------------+
    //| DETECTARE SWING POINTS                                           |
    //+------------------------------------------------------------------+
    void DetectSwingPoints()
    {
        MqlRates rates[];
        ArraySetAsSeries(rates, true);
        
        if (CopyRates(m_symbol, Period(), 0, SWING_LOOKBACK * 3, rates) <= 0)
            return;
        
        for (int i = SWING_LOOKBACK; i < ArraySize(rates) - SWING_LOOKBACK; i++)
        {
            bool isSwingHigh = true;
            for (int j = 1; j <= SWING_LOOKBACK; j++)
            {
                if (rates[i].high <= rates[i + j].high || rates[i].high <= rates[i - j].high)
                {
                    isSwingHigh = false;
                    break;
                }
            }
            if (isSwingHigh)
            {
                m_lastSwingHigh = rates[i].high;
                m_lastSwingHighBar = i;
                break;
            }
        }
        
        for (int i = SWING_LOOKBACK; i < ArraySize(rates) - SWING_LOOKBACK; i++)
        {
            bool isSwingLow = true;
            for (int j = 1; j <= SWING_LOOKBACK; j++)
            {
                if (rates[i].low >= rates[i + j].low || rates[i].low >= rates[i - j].low)
                {
                    isSwingLow = false;
                    break;
                }
            }
            if (isSwingLow)
            {
                m_lastSwingLow = rates[i].low;
                m_lastSwingLowBar = i;
                break;
            }
        }
    }
    
    //+------------------------------------------------------------------+
    //| VERIFICARE CONFIRMĂ TREND DIRECTĂ (EMA CHECK)                    |
    //+------------------------------------------------------------------+
    bool ConfirmTrendByEMA(ETrendType trend)
    {
        double ema20 = m_indicators->CalculateEMA(PERIOD_EMA_FAST);
        double ema50 = m_indicators->CalculateEMA(PERIOD_EMA_MID);
        double ema200 = m_indicators->CalculateEMA(PERIOD_EMA_SLOW);
        double close = m_indicators->GetClose();
        
        if (trend == TREND_UP)
        {
            return (close > ema20 && ema20 > ema50 && ema50 > ema200);
        }
        else if (trend == TREND_DOWN)
        {
            return (close < ema20 && ema20 < ema50 && ema50 < ema200);
        }
        
        return false;
    }
    
    //+------------------------------------------------------------------+
    //| VERIFICARE ADX PRAG                                              |
    //+------------------------------------------------------------------+
    bool IsADXAboveThreshold(int threshold = ADX_MIN_THRESHOLD)
    {
        double adx = m_indicators->CalculateADX(PERIOD_ADX);
        return (adx >= threshold);
    }
    
    //+------------------------------------------------------------------+
    //| OBȚIN ULTIMUL SWING HIGH/LOW                                     |
    //+------------------------------------------------------------------+
    double GetLastSwingHigh() { return m_lastSwingHigh; }
    double GetLastSwingLow() { return m_lastSwingLow; }
    int GetLastSwingHighBar() { return m_lastSwingHighBar; }
    int GetLastSwingLowBar() { return m_lastSwingLowBar; }
    
    //+------------------------------------------------------------------+
    //| VERIFICARE BREAK OF STRUCTURE                                    |
    //+------------------------------------------------------------------+
    bool IsBreakOfStructure(ETrendType trend)
    {
        double close = m_indicators->GetClose();
        
        if (trend == TREND_UP)
        {
            return (close > m_lastSwingHigh);
        }
        else if (trend == TREND_DOWN)
        {
            return (close < m_lastSwingLow);
        }
        
        return false;
    }
    
    //+------------------------------------------------------------------+
    //| OBȚI ACCESUL LA INDICATORI                                       |
    //+------------------------------------------------------------------+
    CIndicators* GetIndicators() { return m_indicators; }
};

#endif // __TREND_ANALYZER_MQH__
