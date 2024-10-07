//
//  ArchiveView.swift
//  BlockScribe
//
//  Created by Alex Lin on 3/7/24.
//

import SwiftUI

struct Inscription: Identifiable & Codable {
    let id: Int
    let text: String
}

struct InscribeResponse: Codable {
    let status: String
    let charge: InscribeCharge?
    let error: [InscribeResponseError]?
}

struct InscribeResponseError: Codable {
    let msg: String
}

struct InscribeCharge: Codable {
    let lightning_invoice: InscribeLightningInvoice
}

struct InscribeLightningInvoice: Codable {
    let payreq: String
}

struct ActivityIndicator: UIViewRepresentable {
    @Binding var isAnimating: Bool
    let style: UIActivityIndicatorView.Style
    
    func makeUIView(context: Context) -> UIActivityIndicatorView {
        let activityIndicator = UIActivityIndicatorView(style: style)
        activityIndicator.color = UIColor.purple
        return activityIndicator
    }
    
    func updateUIView(_ uiView: UIActivityIndicatorView, context: Context) {
        if isAnimating {
            uiView.startAnimating()
        } else {
            uiView.stopAnimating()
        }
    }
}

struct ArchiveView: View {
    @Environment(\.colorScheme) var colorScheme
    
    @State private var ordinals: [Inscription] = []
    @State private var qrImage: Image?
    @State private var isLoading = false
    @State private var walletAddress = ""
    @State private var presentAlert = false
    @State private var errorMessage = ""
    
    init() {
        UITabBar.appearance().barTintColor = UIColor(.white)
    }
    
    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                ZStack{
                    VStack {
                        Divider()
                            .frame(height: 1)
                            .background(Color.gray)
                            .padding(.horizontal)
                        Text("Inscriptions are where your\nArtefacts will be stored directly\non the Bitcoin Blockchain forever.")
                            .font(.title3)
                            .frame(maxWidth: geometry.size.width)
                            .multilineTextAlignment(.center)
                            .minimumScaleFactor(0.5)
                            .padding(.horizontal)
                            .padding(.top, 20)
                            .padding(.bottom, 5)
                        
                        
                        Button(action: {
                            BSUtil.shared.openURL("https://www.blockscribe.io/how-it-works")
                        }){
                            Text("Find out more.")
                                .font(.system(size: 16))
                                .foregroundColor(.blue)
                        }
                        .frame(maxWidth: geometry.size.width)
                        .background(.clear)
                        .buttonStyle(PlainButtonStyle())
                        
                        
                        HStack{
                            Text("Your Inscriptions")
                                .font(.title)
                                .padding()
                            Spacer()
                            Button(action: {
                                if (self.walletAddress.isEmpty) {
                                    self.presentAlert = true
                                    self.errorMessage = "Please input your wallet address to generate the inscription invoice"
                                } else {
                                    self.isLoading = true
                                    qrImage = nil
                                    BSUtil.shared.createInscribeInvoice(wallet: self.walletAddress, completion: { result in
                                        self.isLoading = false;
                                        
                                        switch result {
                                        case .success(let response):
                                            if let payReq = response.charge?.lightning_invoice.payreq {
                                                print("Pay req: \(payReq)")
                                                qrImage = BSUtil.shared.generateQRCode(from: payReq)
                                            }
                                            if let error = response.error {
                                                self.presentAlert = true
                                                self.errorMessage = error[0].msg
                                            }
                                        case .failure(let error):
                                            print("Error: \(error)")
                                        }
                                    })
                                }
                            }) {
                                Image(systemName: "plus.circle")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 30, height: 30)
                                    .foregroundColor(.gray)
                            }
                            .background(.clear)
                            .buttonStyle(PlainButtonStyle())
                            .padding()
                            .disabled(true)
                        }
                        HStack{
                            TextField("Type your wallet address here...", text: $walletAddress)
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                                .disabled(true)
                            if !walletAddress.isEmpty {
                                Button(action: {
                                    self.walletAddress = ""
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.gray)
                                }
                                .padding(.trailing, 8)
                            }
                        }
                        Spacer()
                        ZStack{
                            VStack{
                                Spacer()
                                //                            Text("Click \"+\" button to\ngenerate the inscription invoice")
                                //                                .font(.body)
                                //                                .multilineTextAlignment(.center)
                                //                                .padding()
//                                Text("Coming\nSoon")
//                                    .font(.largeTitle)
//                                    .multilineTextAlignment(.center)
//                                    .padding()
//                                    .foregroundColor(.purple)
                                Spacer()
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(Color("MainBgColor"))
                            .opacity(qrImage == nil ? 1 : 0)
                            .border(Color.gray, width: 1)
                            
                            VStack{
                                qrImage?
                                    .resizable()
                                    .scaledToFit()
                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                                    .padding()
                            }
                            
                            VStack {
                                ActivityIndicator(isAnimating: $isLoading, style: .large)
                                    .padding()
                            }
                        }
                        Spacer()
                    }
                    VStack {
                        Image("coming-soon")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .rotationEffect(.degrees(-45))
                            .padding()
                    }
                }
                .navigationTitle("Inscriptions")
                .navigationBarTitleDisplayMode(.automatic)
                .background(Color("MainBgColor"))
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Image("bs-logo-horizontal")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 120, alignment: .leading)
                    }
                }
            }
        }
        .onAppear() {
            BSUtil.shared.updateColorScheme(colorScheme)
            Task {
                await loadInscriptions()
            }
        }
        .alert(isPresented: $presentAlert) {
            Alert(
                title: Text("Error"),
                message: Text(errorMessage),
                dismissButton: .default(Text("Yes"))
            )
        }
    }
}

struct ArchiveView_Previews: PreviewProvider {
    static var previews: some View {
        ArchiveView()
    }
}

extension ArchiveView {
    func loadInscriptions() async {
        if let retrievedData = BSUtil.shared.retrieveFromKeychain(key: Constants.KEY_INSCRIPTIONS) {
            if let retrievedList: [Inscription] = BSUtil.shared.convertDataToList(retrievedData) {
                ordinals = retrievedList
            }
        }
    }
}
