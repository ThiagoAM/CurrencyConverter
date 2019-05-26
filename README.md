# CurrencyConverter (Swift 5.0)
A simple currency converter written in Swift 5.<br/>
The exchange rates are fetched from the following XML file: https://www.ecb.europa.eu/stats/eurofxref/eurofxref-daily.xml<br/>
This Currency Converter is used in the Objective Calculator app. Check it out: http://itunes.apple.com/app/id1287000522<br/>

**How to use:** <br />
• Add the "CurrencyConverter.swift" file to your project <br />
• Create a `CurrencyConverter` instance <br />
• Call the `updateExchangeRates` method <br />
• After it updates the exchange rates, call the `convert` method <br />
• That's it! <br />

# Example
```swift
class ViewController: UIViewController {

    // Creates the Currency Converter instance:
    let currencyConverter = CurrencyConverter()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Updates the exchange rates:
        currencyConverter.updateExchangeRates(completion: {
            // The code inside here runs after all the data is fetched.
            
            // Now you can convert any currency:
            // • Example_1 (USD to EUR):
            let doubleResult = self.currencyConverter.convert(10, valueCurrency: .USD, outputCurrency: .EUR)
            print("••• 10 USD = \(doubleResult!) EUR •••")
            
            // • Example_2 (EUR to GBP) - Returning a formatted String:
            let formattedResult = self.currencyConverter.convertAndFormat(10, valueCurrency: .EUR, outputCurrency: .GBP, numberStyle: .decimal, decimalPlaces: 4)
            print("••• Formatted Result (10 EUR to GBP): \(formattedResult!) •••")
        })
    }

}
```

# License
InfiniteScrollingBackground project is licensed under MIT License ([MIT-License](MIT-License) or https://opensource.org/licenses/MIT)
