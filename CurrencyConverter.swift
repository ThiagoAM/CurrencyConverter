//
//  CurrencyConverter.swift
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
    /** Returns a currency name with it's flag (🇺🇸 USD, for example). */
    static func nameWithFlag(for currency : Currency) -> String {
        return (Currency.flagsByCurrencies[currency] ?? "?") + " " + currency.rawValue
    }
    
    // Public Properties:
    /** Returns an array with all currency names and their respective flags. */
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
    init() { updateExchangeRates {} }
    
    // Public Methods:
    /** Updates the exchange rate and runs the completion afterwards. */
    public func updateExchangeRates(completion : @escaping () -> Void = {}) {
        xmlParser.parse(completion: {
            // Gets the exchange rate from the internet:
            self.exchangeRates = self.xmlParser.getExchangeRates()
            // Saves the updated exchange rate to the device's local storage:
            CurrencyConverterLocalData.saveMostRecentExchangeRates(self.exchangeRates)
            // Runs the completion:
            completion()
        }, errorCompletion: { // No internet access/network error:
            // Loads the most recent exchange rate from the device's local storage:
            self.exchangeRates = CurrencyConverterLocalData.loadMostRecentExchangeRates()
            // Runs the completion:
            completion()
        })
    }
    
    /**
     Converts a Double value based on it's currency (valueCurrency) and the output currency (outputCurrency).
     USD to EUR conversion example: convert(42, valueCurrency: .USD, outputCurrency: .EUR)
     */
    public func convert(_ value : Double, valueCurrency : Currency, outputCurrency : Currency) -> Double? {
        guard let valueRate = exchangeRates[valueCurrency] else { return nil }
        guard let outputRate = exchangeRates[outputCurrency] else { return nil }
        let multiplier = outputRate/valueRate
        return value * multiplier
    }
    
    /**
     Converts a Double value based on it's currency and the output currency, and returns a formatted String.
     Usage example: convertAndFormat(42, valueCurrency: .USD, outputCurrency: .EUR, numberStyle: .currency, decimalPlaces: 4)
     */
    public func convertAndFormat(_ value : Double, valueCurrency : Currency, outputCurrency : Currency, numberStyle : NumberFormatter.Style, decimalPlaces : Int) -> String? {
        guard let doubleOutput = convert(value, valueCurrency: valueCurrency, outputCurrency: outputCurrency) else {
            return nil
        }
        return format(doubleOutput, numberStyle: numberStyle, decimalPlaces: decimalPlaces)
    }
    
    /**
     Returns a formatted string from a double value.
     Usage example: format(42, numberStyle: .currency, decimalPlaces: 4)
     */
    public func format(_ value : Double, numberStyle : NumberFormatter.Style, decimalPlaces : Int) -> String? {
        let formatter = NumberFormatter()
        formatter.numberStyle = numberStyle
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
    // • This will never be used once the method CurrencyConverter.updateExchangeRates is called with internet access.
    // • This is just an emergency callback, in case the user doesn't have internet access the first time running the app.
    // Updated in: 04/15/2019.
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
    /** Saves the most recent exchange rates by locally storing it. */
    static func saveMostRecentExchangeRates(_ exchangeRates : [Currency : Double]) {
        let convertedExchangeRates = convertExchangeRatesForUserDefaults(exchangeRates)
        UserDefaults.standard.set(convertedExchangeRates, forKey: Keys.mostRecentExchangeRates)
    }
    
    /** Loads the most recent exchange rates from the local storage. */
    static func loadMostRecentExchangeRates() -> [Currency : Double] {
        if let userDefaultsExchangeRates = UserDefaults.standard.dictionary(forKey: Keys.mostRecentExchangeRates) as? [String : Double] {
            return convertExchangeRatesFromUserDefaults(userDefaultsExchangeRates)
        } else {            
            // Fallback:
            return fallBackExchangeRates
        }
    }
    
    // Private Static Methods:
    /** Converts the [String : Double] dictionary with the exchange rates to a [Currency : Double] dictionary. */
    private static func convertExchangeRatesFromUserDefaults(_ userDefaultsExchangeRates : [String : Double]) -> [Currency : Double] {
        var exchangeRates : [Currency : Double] = [:]
        for userDefaultExchangeRate in userDefaultsExchangeRates {
            if let currency = Currency(rawValue: userDefaultExchangeRate.key) {
                exchangeRates.updateValue(userDefaultExchangeRate.value, forKey: currency)
            }
        }
        return exchangeRates
    }
    
    /**
     Converts the [Currency : Double] dictionary with the exchange rates to a [String : Double] one so it can be stored locally.
     */
    private static func convertExchangeRatesForUserDefaults(_ exchangeRates : [Currency : Double]) -> [String : Double] {
        var userDefaultsExchangeRates : [String : Double] = [:]
        for exchangeRate in exchangeRates {
            userDefaultsExchangeRates.updateValue(exchangeRate.value, forKey: exchangeRate.key.rawValue)
        }
        return userDefaultsExchangeRates
    }
    
}
