//+------------------------------------------------------------------+
//| RBOT PRO XAU v3.0 - Logger Header File                           |
//| Professional MetaTrader 5 Expert Advisor for XAUUSD Trading      |
//| Sistem de logging și debugging                                   |
//+------------------------------------------------------------------+
#property copyright "RBOT PRO XAU"
#property version   "3.0"

#ifndef __LOGGER_MQH__
#define __LOGGER_MQH__

#include "Config.mqh"
#include "Utils.mqh"

//+------------------------------------------------------------------+
//| CLASA PENTRU LOGGING                                             |
//+------------------------------------------------------------------+
class CLogger
{
private:
    string m_logFileName;
    int m_logLevel;
    bool m_enableFileLogging;
    bool m_enablePrintLogging;
    
public:
    // Constructor
    CLogger(string fileName = "RBOT_PRO_XAU.log", 
            int logLevel = LOG_LEVEL_INFO,
            bool fileLogging = true,
            bool printLogging = true)
    {
        m_logFileName = fileName;
        m_logLevel = logLevel;
        m_enableFileLogging = fileLogging;
        m_enablePrintLogging = printLogging;
    }
    
    //+------------------------------------------------------------------+
    //| LOG GENERIC CU NIVEL                                             |
    //+------------------------------------------------------------------+
    void Log(string message, int level = LOG_LEVEL_INFO)
    {
        if (level < m_logLevel)
            return;
        
        string levelStr = GetLevelString(level);
        string timestamp = TimeToString(TimeCurrent(), TIME_DATE|TIME_MINUTES|TIME_SECONDS);
        string fullMessage = "[" + timestamp + "] [" + levelStr + "] " + message;
        
        if (m_enablePrintLogging)
            Print(fullMessage);
        
        if (m_enableFileLogging)
            WriteToFile(fullMessage);
    }
    
    //+------------------------------------------------------------------+
    //| LOG DEBUG                                                        |
    //+------------------------------------------------------------------+
    void Debug(string message)
    {
        Log(message, LOG_LEVEL_DEBUG);
    }
    
    //+------------------------------------------------------------------+
    //| LOG INFO                                                         |
    //+------------------------------------------------------------------+
    void Info(string message)
    {
        Log(message, LOG_LEVEL_INFO);
    }
    
    //+------------------------------------------------------------------+
    //| LOG WARNING                                                      |
    //+------------------------------------------------------------------+
    void Warning(string message)
    {
        Log(message, LOG_LEVEL_WARNING);
    }
    
    //+------------------------------------------------------------------+
    //| LOG ERROR                                                        |
    //+------------------------------------------------------------------+
    void Error(string message)
    {
        Log(message, LOG_LEVEL_ERROR);
    }
    
    //+------------------------------------------------------------------+
    //| LOG TRADE                                                        |
    //+------------------------------------------------------------------+
    void LogTrade(string action, string symbol, double price, double volume,
                 double sl, double tp, string reason = "")
    {
        string message = action + " | Symbol: " + symbol + 
                        " | Price: " + DoubleToString(price, 5) +
                        " | Volume: " + DoubleToString(volume, 2) +
                        " | SL: " + DoubleToString(sl, 5) +
                        " | TP: " + DoubleToString(tp, 5);
        
        if (reason != "")
            message += " | Reason: " + reason;
        
        Info(message);
    }
    
    //+------------------------------------------------------------------+
    //| LOG INDICATORI                                                   |
    //+------------------------------------------------------------------+
    void LogIndicators(string symbol, int timeframe,
                      double ema20, double ema50, double ema200,
                      double rsi, double adx, double atr)
    {
        string tfStr = EnumToString((ENUM_TIMEFRAMES)timeframe);
        string message = symbol + " [" + tfStr + "] | " +
                        "EMA20: " + DoubleToString(ema20, 5) + " | " +
                        "EMA50: " + DoubleToString(ema50, 5) + " | " +
                        "EMA200: " + DoubleToString(ema200, 5) + " | " +
                        "RSI: " + DoubleToString(rsi, 2) + " | " +
                        "ADX: " + DoubleToString(adx, 2) + " | " +
                        "ATR: " + DoubleToString(atr, 5);
        
        Debug(message);
    }
    
    //+------------------------------------------------------------------+
    //| LOG SCORE                                                        |
    //+------------------------------------------------------------------+
    void LogScore(int score, int threshold, bool allowed)
    {
        string message = "SCORE: " + IntegerToString(score) + "/100 | " +
                        "Threshold: " + IntegerToString(threshold) + " | " +
                        "Status: " + (allowed ? "ALLOWED" : "BLOCKED");
        
        Info(message);
    }
    
private:
    //+------------------------------------------------------------------+
    //| SCRIERE ÎN FIȘIER                                                |
    //+------------------------------------------------------------------+
    void WriteToFile(string message)
    {
        int handle = FileOpen(m_logFileName, FILE_READ|FILE_WRITE|FILE_TXT|FILE_ANSI);
        
        if (handle == INVALID_HANDLE)
        {
            handle = FileOpen(m_logFileName, FILE_WRITE|FILE_TXT|FILE_ANSI);
        }
        
        if (handle != INVALID_HANDLE)
        {
            FileSeek(handle, 0, SEEK_END);
            FileWrite(handle, message);
            FileClose(handle);
        }
    }
    
    //+------------------------------------------------------------------+
    //| CONVERSIE NIVEL ÎN STRING                                        |
    //+------------------------------------------------------------------+
    string GetLevelString(int level)
    {
        switch(level)
        {
            case LOG_LEVEL_DEBUG:   return "DEBUG";
            case LOG_LEVEL_INFO:    return "INFO";
            case LOG_LEVEL_WARNING: return "WARNING";
            case LOG_LEVEL_ERROR:   return "ERROR";
            default:                return "UNKNOWN";
        }
    }
};

#endif // __LOGGER_MQH__
