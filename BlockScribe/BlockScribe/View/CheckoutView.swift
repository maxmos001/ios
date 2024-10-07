//
//  CheckoutView.swift
//  BlockScribe
//
//  Created by Alex Lin on 7/6/24.
//

import StripePaymentSheet
import SwiftUI

class MyBackendModel: ObservableObject {
    let backendCheckoutUrl = URL(string: "https://rbawjdqpzl.execute-api.ap-southeast-2.amazonaws.com/dev/paymentIntent")!
    @Published var paymentSheet: PaymentSheet?
    @Published var paymentResult: PaymentSheetResult?
    
    func preparePaymentSheet() {
        // MARK: Fetch the PaymentIntent and Customer information from the backend
        var request = URLRequest(url: backendCheckoutUrl)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "amount": 30000, // amount in cents
            "currency": "aud",
//            "payment_method_id": "pmc_1PTDA1P87XzzGnku8IBp4d9o" // replace with your actual payment method id
        ]
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: body, options: [])
        let task = URLSession.shared.dataTask(with: request, completionHandler: { [weak self] (data, response, error) in
            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String : Any],
                  //            let customerId = json["customer"] as? String,
                  //            let customerEphemeralKeySecret = json["ephemeralKey"] as? String,
                    //            let paymentIntentClientSecret = json["paymentIntent"] as? String,
                  let publishableKey = json["publishableKey"] as? String,
                  let paymentIntentClientSecret = json["clientSecret"] as? String,
                  let self = self else {
                      // Handle error
                      return
                  }
            
            STPAPIClient.shared.publishableKey = publishableKey
            // MARK: Create a PaymentSheet instance
            var configuration = PaymentSheet.Configuration()
            configuration.merchantDisplayName = "Block Scribe Pty Ltd"
            //      configuration.customer = .init(id: customerId, ephemeralKeySecret: customerEphemeralKeySecret)
            // Set `allowsDelayedPaymentMethods` to true if your business can handle payment methods
            // that complete payment after a delay, like SEPA Debit and Sofort.
//            configuration.allowsDelayedPaymentMethods = true
            
            DispatchQueue.main.async {
                self.paymentSheet = PaymentSheet(paymentIntentClientSecret: paymentIntentClientSecret, configuration: configuration)
            }
        })
        task.resume()
    }
    
    func onPaymentCompletion(result: PaymentSheetResult) {
        self.paymentResult = result
    }
}

struct CheckoutView: View {
    @ObservedObject var model = MyBackendModel()
    
    var body: some View {
        VStack {
            if let paymentSheet = model.paymentSheet {
                PaymentSheet.PaymentButton(
                    paymentSheet: paymentSheet,
                    onCompletion: model.onPaymentCompletion
                ) {
                    VStack{
                    Text("The service fee is $300")
                        .padding()
                    Text("Pay")
                        .padding()
                        .frame(maxWidth: 300)
                        .background(Color.purple)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                }
            } else {
                Text("Preparing payment…")
            }
            
            if let result = model.paymentResult {
                switch result {
                case .completed:
                    Text("Payment complete")
                case .failed(let error):
                    Text("Payment failed: \(error.localizedDescription)")
                case .canceled:
                    Text("Payment canceled.")
                }
            }
        }.onAppear { model.preparePaymentSheet() }
    }
}
