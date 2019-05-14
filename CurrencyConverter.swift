//
//  CurrencyConverter.swift
//
//  Created by Thiago Martins on 26/03/19.
//

import Foundation

// Global Enumerations:
enum Currency : String, CaseIterable {
    
    case AUD = "AUD"; case INR = "INR"; case TRY = "TRY"
    case BGN = "BGN"; case ISK = "ISK"; case USD = "USD"
    case BRL = "BRL"; case JPY = "JPY"; case ZAR = "ZAR"
    case CAD = "CAD"; case KRW = "KRW"
    case CHF = "CHF"; case MXN = "MXN"
    case CNY = "CNY"; case MYR = "MYR"
    case CZK = "CZK"; case NOK = "NOK"
    case DKK = "DKK"; case NZD = "NZD"
    case EUR = "EUR"; case PHP = "PHP"
    case GBP = "GBP"; case PLN = "PLN"
    case HKD = "HKD"; case RON = "RON"
    case HRK = "HRK"; case RUB = "RUB"
    case HUF = "HUF"; case SEK = "SEK"
    case IDR = "IDR"; case SGD = "SGD"
    case ILS = "ILS"; case THB = "THB"
    
    // Public Static Methods:
    static func nameWithFlag(for currency : Currency) -> String {
        return (Currency.flagsByCurrencies[currency] ?? "?") + " " + currency.rawValue
    }
    
    // Public Properties:
    static let allNamesWithFlags : [String] = {
        var namesWithFlags : [String] = []
        for currency in Currency.allCases {
            namesWithFlags.append(Currency.nameWithFlag(for: currency))
        }
        return namesWithFlags
    }()
    
    static let flagsByCurrencies : [Currency : String] = [
        .AUD : "🇦🇺", .INR : "🇮🇳", .TRY : "🇹🇷",
        .BGN : "🇧🇬", .ISK : "🇮🇸", .USD : "🇺🇸",
        .BRL : "🇧🇷", .JPY : "🇯🇵", .ZAR : "🇿🇦",
        .CAD : "🇨🇦", .KRW : "🇰🇷",
        .CHF : "🇨🇭", .MXN : "🇲🇽",
        .CNY : "🇨🇳", .MYR : "🇲🇾",
        .CZK : "🇨🇿", .NOK : "🇳🇴",
        .DKK : "🇩🇰", .NZD : "🇳🇿",
        .EUR : "🇪🇺", .PHP : "🇵🇭",
        .GBP : "🇬🇧", .PLN : "🇵🇱",
        .HKD : "🇭🇰", .RON : "🇷🇴",
        .HRK : "🇭🇷", .RUB : "🇷🇺",
        .HUF : "🇭🇺", .SEK : "🇸🇪",
        .IDR : "🇮🇩", .SGD : "🇸🇬",
        .ILS : "🇮🇱", .THB : "🇹🇭",
    ]
}

// Global Classes:
class CurrencyConverter {
    
    // Private Properties:
    private var exchangeRates : [Currency : Double] = [:]
    private let xmlParser = CurrencyXMLParser()
    
    // Initialization:
    init() {
        updateExchangeRates {}
    }
    
    // Public Methods:
    public func updateExchangeRates(completion : @escaping () -> Void = {}) {
        xmlParser.parse(completion: {
            self.exchangeRates = self.xmlParser.getExchangeRates()
            CurrencyConverterLocalData.saveMostRecentExchangeRates(self.exchangeRates)
            completion()
        }, errorCompletion: { // No internet access/network error:
            self.exchangeRates = CurrencyConverterLocalData.loadMostRecentExchangeRates()
            completion()
        })
    }
    
    public func convert(_ value : Double, valueCurrency : Currency, outputCurrency : Currency) -> Double? {
        guard let valueRate = exchangeRates[valueCurrency] else { return nil }
        guard let outputRate = exchangeRates[outputCurrency] else { return nil }
        let multiplier = outputRate/valueRate
        return value * multiplier
    }
    
    public func convertAndFormat(_ value : Double, valueCurrency : Currency, outputCurrency : Currency, decimalPlaces : Int) -> String? {
        guard let doubleOutput = convert(value, valueCurrency: valueCurrency, outputCurrency: outputCurrency) else {
            return nil
        }
        return format(doubleOutput, decimalPlaces: decimalPlaces)
    }
    
    public func format(_ value : Double, decimalPlaces : Int) -> String? {
        let formatter = NumberFormatter()
        formatter.numberStyle = NumberFormatter.Style.decimal
        formatter.maximumFractionDigits = decimalPlaces
        return formatter.string(from: NSNumber(value: value))
    }
    
}

// Private Classes:
private class CurrencyXMLParser : NSObject, XMLParserDelegate {
    
    // Private Properties:
    private let xmlURL = "https://www.ecb.europa.eu/stats/eurofxref/eurofxref-daily.xml"
    private var exchangeRates : [Currency : Double] = [
        .EUR : 1.0 // Base currency
    ]
    
    // Public Methods:
    public func getExchangeRates() -> [Currency : Double] {
        return exchangeRates
    }
    
    public func parse(completion : @escaping () -> Void, errorCompletion : @escaping () -> Void) {
        guard let url = URL(string: xmlURL) else { return }
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data, error == nil else {
                print("Failed to parse the XML!")
                print(error ?? "Unknown error")
                errorCompletion()
                return
            }
            let parser = XMLParser(data: data)
            parser.delegate = self
            if parser.parse() {
                completion()
            } else {
                errorCompletion()
            }
        }
        task.resume()
    }
    
    // Private Methods:
    private func makeExchangeRate(currency : String, rate : String) -> (currency : Currency, rate : Double)? {
        guard let currency = Currency(rawValue: currency) else { return nil }
        guard let rate = Double(rate) else { return nil }
        return (currency, rate)
    }
    
    // XML Parse Methods (from XMLParserDelegate):
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        if elementName == "Cube"{
            guard let currency = attributeDict["currency"] else { return }
            guard let rate = attributeDict["rate"] else { return }
            guard let exchangeRate = makeExchangeRate(currency: currency, rate: rate) else { return }
            exchangeRates.updateValue(exchangeRate.rate, forKey: exchangeRate.currency)
        }
    }
    
}

// Private Classes:
private class CurrencyConverterLocalData {
    
    // Structs:
    struct Keys {
        static let mostRecentExchangeRates = "CurrencyConverterLocalData.Keys.mostRecentExchangeRates"
    }
    
    // Static Properties:
    // Updated in: 04/15/2019.
    // ps: Only used if the method CurrencyConverter.updateExchangeRates() was
    // never called with internet access.
    static let fallBackExchangeRates : [Currency : Double] = [
        .USD : 1.1321,
        .JPY : 126.76,
        .BGN : 1.9558,
        .CZK : 25.623,
        .DKK : 7.4643,
        .GBP : 0.86290,
        .HUF : 321.90,
        .PLN : 4.2796,
        .RON : 4.7598,
        .SEK : 10.4788,
        .CHF : 1.1326,
        .ISK : 135.20,
        .NOK : 9.6020,
        .HRK : 7.4350,
        .RUB : 72.6133,
        .TRY : 6.5350,
        .AUD : 1.5771,
        .BRL : 4.3884,
        .CAD : 1.5082,
        .CNY : 7.5939,
        .HKD : 8.8788,
        .IDR : 15954.12,
        .ILS : 4.0389,
        .INR : 78.2915,
        .KRW : 1283.00,
        .MXN : 21.2360,
        .MYR : 4.6580,
        .NZD : 1.6748,
        .PHP : 58.553,
        .SGD : 1.5318,
        .THB : 35.955,
        .ZAR : 15.7631,
    ]
    
    // Static Methods:
    static func saveMostRecentExchangeRates(_ exchangeRates : [Currency : Double]) {
        let convertedExchangeRates = convertExchangeRatesForUserDefaults(exchangeRates)
        UserDefaults.standard.set(convertedExchangeRates, forKey: Keys.mostRecentExchangeRates)
    }
    
    static func loadMostRecentExchangeRates() -> [Currency : Double] {
        if let userDefaultsExchangeRates = UserDefaults.standard.dictionary(forKey: Keys.mostRecentExchangeRates) as? [String : Double] {
            return convertExchangeRatesFromUserDefaults(userDefaultsExchangeRates)
        } else {            
            // Fallback:
            return fallBackExchangeRates
        }
    }
    
    // Private Static Methods:
    private static func convertExchangeRatesFromUserDefaults(_ userDefaultsExchangeRates : [String : Double]) -> [Currency : Double] {
        var exchangeRates : [Currency : Double] = [:]
        for userDefaultExchangeRate in userDefaultsExchangeRates {
            if let currency = Currency(rawValue: userDefaultExchangeRate.key) {
                exchangeRates.updateValue(userDefaultExchangeRate.value, forKey: currency)
            }
        }
        return exchangeRates
    }
    
    private static func convertExchangeRatesForUserDefaults(_ exchangeRates : [Currency : Double]) -> [String : Double] {
        var userDefaultsExchangeRates : [String : Double] = [:]
        for exchangeRate in exchangeRates {
            userDefaultsExchangeRates.updateValue(exchangeRate.value, forKey: exchangeRate.key.rawValue)
        }
        return userDefaultsExchangeRates
    }
    
}
