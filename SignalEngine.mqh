//+------------------------------------------------------------------+
//| RBOT PRO XAU v3.0 - Signal Engine Header File                    |
//| Professional MetaTrader 5 Expert Advisor for XAUUSD Trading      |
//| Motorul de semnale cu sistem de scoring 100 puncte               |
//+------------------------------------------------------------------+
#property copyright "RBOT PRO XAU"
#property version   "3.0"

#ifndef __SIGNAL_ENGINE_MQH__
#define __SIGNAL_ENGINE_MQH__

#include "Config.mqh"
#include "Utils.mqh"
#include "Indicators.mqh"
#include "TrendAnalyzer.mqh"

//+------------------------------------------------------------------+
//| ENUM PENTRU TIPURILE DE SEMNALE                                  |
//+------------------------------------------------------------------+
enum ESignalType
{
    SIGNAL_NONE = 0,     // Fără semnal
    SIGNAL_BUY = 1,      // Semnal de cumpărare
    SIGNAL_SELL = -1     // Semnal de vânzare
};

//+------------------------------------------------------------------+
//| STRUCTURA PENTRU DETALII SEMNAL                                  |
//+------------------------------------------------------------------+
struct SSignalDetails
{
    ESignalType signalType;         // Tipul semnalului
    int score;                      // Scor total (0-100)
    int scoreTrend;                 // Puncte trend
    int scoreEMA;                   // Puncte aliniere EMA
    int scoreADX;                   // Puncte ADX
    int scoreVolume;                // Puncte volum
    int scoreATR;                   // Puncte ATR
    int scoreStructure;             // Puncte structură piață
    int scoreHTF;                   // Puncte confirmă HTF
    int scoreSession;               // Bonus sesiune
    string reason;                  // Motiv detaliat
    bool isAllowed;                 // Intrare permisă?
};

//+------------------------------------------------------------------+
//| CLASA PENTRU GENERAREA SEMNALELOR                                |
//+------------------------------------------------------------------+
class CSignalEngine
{
private:
    string m_symbol;
    CIndicators *m_indicators1;
    CIndicators *m_indicators5;
    CIndicators *m_indicators15;
    CTrendAnalyzer *m_trendM1;
    CTrendAnalyzer *m_trendM5;
    CTrendAnalyzer *m_trendM15;
    
public:
    CSignalEngine(string symbol)
    {
        m_symbol = symbol;
        m_indicators1 = new CIndicators(symbol, PERIOD_M1);
        m_indicators5 = new CIndicators(symbol, PERIOD_M5);
        m_indicators15 = new CIndicators(symbol, PERIOD_M15);
        
        m_trendM1 = new CTrendAnalyzer(symbol, PERIOD_M1);
        m_trendM5 = new CTrendAnalyzer(symbol, PERIOD_M5);
        m_trendM15 = new CTrendAnalyzer(symbol, PERIOD_M15);
    }
    
    ~CSignalEngine()
    {
        if (m_indicators1 != NULL) delete m_indicators1;
        if (m_indicators5 != NULL) delete m_indicators5;
        if (m_indicators15 != NULL) delete m_indicators15;
        if (m_trendM1 != NULL) delete m_trendM1;
        if (m_trendM5 != NULL) delete m_trendM5;
        if (m_trendM15 != NULL) delete m_trendM15;
    }
    
    //+------------------------------------------------------------------+
    //| GENERARE SEMNAL COMPLET CU SCORING                               |
    //+------------------------------------------------------------------+
    SSignalDetails GenerateSignal()
    {
        SSignalDetails details;
        details.score = 0;
        details.scoreTrend = 0;
        details.scoreEMA = 0;
        details.scoreADX = 0;
        details.scoreVolume = 0;
        details.scoreATR = 0;
        details.scoreStructure = 0;
        details.scoreHTF = 0;
        details.scoreSession = 0;
        details.reason = "";
        details.signalType = SIGNAL_NONE;
        details.isAllowed = false;
        
        STrendInfo trendM1 = m_trendM1->AnalyzeTrend();
        STrendInfo trendM5 = m_trendM5->AnalyzeTrend();
        STrendInfo trendM15 = m_trendM15->AnalyzeTrend();
        
        bool trendConfirmed = false;
        ESignalType potentialSignal = SIGNAL_NONE;
        
        if (trendM15.trendType == TREND_UP && trendM5.trendType == TREND_UP && trendM1.trendType == TREND_UP)
        {
            trendConfirmed = true;
            potentialSignal = SIGNAL_BUY;
            details.scoreTrend = SCORE_TREND;
            details.reason = "MULTI-TF UPTREND | ";
        }
        else if (trendM15.trendType == TREND_DOWN && trendM5.trendType == TREND_DOWN && trendM1.trendType == TREND_DOWN)
        {
            trendConfirmed = true;
            potentialSignal = SIGNAL_SELL;
            details.scoreTrend = SCORE_TREND;
            details.reason = "MULTI-TF DOWNTREND | ";
        }
        
        if (!trendConfirmed)
        {
            details.reason += "TREND NOT CONFIRMED";
            return details;
        }
        
        details.signalType = potentialSignal;
        
        double ema20 = m_indicators1->CalculateEMA(PERIOD_EMA_FAST);
        double ema50 = m_indicators1->CalculateEMA(PERIOD_EMA_MID);
        double ema200 = m_indicators1->CalculateEMA(PERIOD_EMA_SLOW);
        double close = m_indicators1->GetClose();
        double rsi = m_indicators1->CalculateRSI(PERIOD_RSI);
        double adx = m_indicators1->CalculateADX(PERIOD_ADX);
        
        bool emaConfirmed = false;
        if (potentialSignal == SIGNAL_BUY)
        {
            if (ema20 > ema50 && ema50 > ema200 && close > ema20)
            {
                emaConfirmed = true;
                details.scoreEMA = SCORE_EMA_ALIGNMENT;
                details.reason += "EMA BULLISH | ";
            }
        }
        else if (potentialSignal == SIGNAL_SELL)
        {
            if (ema20 < ema50 && ema50 < ema200 && close < ema20)
            {
                emaConfirmed = true;
                details.scoreEMA = SCORE_EMA_ALIGNMENT;
                details.reason += "EMA BEARISH | ";
            }
        }
        
        if (!emaConfirmed)
        {
            details.reason += "EMA NOT ALIGNED";
            return details;
        }
        
        if (adx >= ADX_MIN_THRESHOLD)
        {
            details.scoreADX = (int)(SCORE_ADX * (adx / ADX_STRONG_THRESHOLD));
            details.scoreADX = MathMin(SCORE_ADX, details.scoreADX);
            details.reason += "ADX OK | ";
        }
        else
        {
            details.reason += "ADX LOW";
            return details;
        }
        
        if ((potentialSignal == SIGNAL_BUY && rsi < RSI_ENTRY_BUY_MAX && rsi > RSI_OVERSOLD) ||
            (potentialSignal == SIGNAL_SELL && rsi > RSI_ENTRY_SELL_MIN && rsi < RSI_OVERBOUGHT))
        {
            details.reason += "RSI OK | ";
        }
        else
        {
            details.reason += "RSI INVALID";
            return details;
        }
        
        details.score = details.scoreTrend + details.scoreEMA + details.scoreADX + 
                       SCORE_VOLUME + SCORE_ATR + SCORE_MARKET_STRUCT + SCORE_HTF_CONFIRM;
        
        if (details.score >= SCORE_THRESHOLD)
        {
            details.isAllowed = true;
            details.reason += "SCORE: " + IntegerToString(details.score) + "/100 - ALLOWED";
        }
        else
        {
            details.isAllowed = false;
            details.reason += "SCORE: " + IntegerToString(details.score) + "/100 - BLOCKED";
        }
        
        return details;
    }
    
    STrendInfo GetTrendM1() { return m_trendM1->AnalyzeTrend(); }
    STrendInfo GetTrendM5() { return m_trendM5->AnalyzeTrend(); }
    STrendInfo GetTrendM15() { return m_trendM15->AnalyzeTrend(); }
    CIndicators* GetIndicatorsM1() { return m_indicators1; }
};

#endif // __SIGNAL_ENGINE_MQH__
