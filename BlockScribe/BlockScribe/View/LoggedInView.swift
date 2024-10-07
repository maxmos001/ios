//
//  LoggedInView.swift
//  BlockScribe
//
//  Created by Alex Lin on 9/3/24.
//

import Foundation
import SwiftUI
import KindeSDK
import Stripe
import StripePaymentSheet

struct LoggedInView: View {
    @Environment(\.colorScheme) var colorScheme

    @Binding var user: UserProfile?
    @State private var selectedTab = 0
    
    private let logger: Logger?
    private let onLoggedOut: () -> Void
    
    init(user: Binding<UserProfile?>, logger: Logger?, onLoggedOut: @escaping () -> Void) {
        self.logger = logger
        self.onLoggedOut = onLoggedOut
        _user = user
    }
    
    var body: some View {
        TabView(selection: $selectedTab) {
//            HomeView(logger: self.logger, onLoggedOut: {self.onLoggedOut()})
//                .tabItem {
//                    Image(systemName: "house.fill")
//                    Text("Home")
//                }
//                .tag(0)
            ArtefactView()
                .tabItem {
                    Image(systemName: "square.and.pencil")
                    Text("Artefacts")
                }
                .tag(0)
            KeyView()
                .tabItem {
                    Image(systemName: "key")
                    Text("Keys")
                }
                .tag(1)
//            ArchiveView()
//                .tabItem {
//                    Image(systemName: "archivebox")
//                    Text("Inscriptions")
//                }
//                .tag(2)
            ProfileView(logger: logger, onLoggedOut: onLoggedOut)
                .tabItem {
                    Image(systemName: "person")
                    Text("Profile")
                }
                .tag(2)
        }
        .onAppear(){
            UITabBar.appearance().backgroundColor = UIColor(named: "MainBgColor")
        }
        .accentColor(.purple)
    }
}

struct LoggedInView_Previews: PreviewProvider {
    static var previews: some View {
        LoggedInView(user: .constant(UserProfile(id: "id",
                                                 providedId: "providedId",
                                                 name: "Bob",
                                                 givenName: "Bob",
                                                 familyName: "Dylan",
                                                 updatedAt: 12345 )),
                     logger: nil) {}
    }
}

struct HomeView: View {
    @EnvironmentObject var sessionData: SessionData
    @State private var presentAlert = false
    @State private var alertMessage = ""
    @State private var isShowingProfileView = false
    @State private var isButtonDisabled: Bool = true
    @State private var isPaymentButtonDisabled: Bool = true
    @State private var paymentSheet: PaymentSheet?
    @State private var nextButtonText = "Start"
    @State private var backButtonOpacity: Double = 0
    
    var logger: Logger?
    var onLoggedOut: () -> Void
    
    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                ScrollViewReader { proxy in
                    VStack{
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 0) {
                                StartView(next: {
                                    withAnimation{
                                        proxy.scrollTo(1, anchor: .center)
                                    }
                                })
                                    .frame(width: geometry.size.width)
                                    .id(0)
                                PickFileView(back: {
                                    withAnimation{
                                        proxy.scrollTo(0, anchor: .center)
                                    }
                                }, next: {
                                    withAnimation{
                                        proxy.scrollTo(2, anchor: .center)
                                    }
                                })
                                    .frame(width: geometry.size.width)
                                    .id(1)
                                PayView(back: {
                                    withAnimation{
                                        proxy.scrollTo(1, anchor: .center)
                                    }
                                }, next: {
                                    withAnimation{
                                        proxy.scrollTo(3, anchor: .center)
                                    }
                                })
                                    .frame(width: geometry.size.width)
                                    .id(2)
                                GenerateKeyView(back: {
                                    withAnimation{
                                        proxy.scrollTo(2, anchor: .center)
                                    }
                                }, next: {
                                    withAnimation{
                                        proxy.scrollTo(4, anchor: .center)
                                    }
                                })
                                    .frame(width: geometry.size.width)
                                    .id(3)
                                InscribeView(back: {
                                    withAnimation{
                                        proxy.scrollTo(3, anchor: .center)
                                    }
                                }, next: {
                                    withAnimation{
                                        proxy.scrollTo(5, anchor: .center)
                                    }
                                })
                                    .frame(width: geometry.size.width)
                                    .id(4)
                            }
                        }
                        .frame(width: geometry.size.width)
                        .onAppear {
                            proxy.scrollTo(0, anchor: .center)
                        }
                        //                        .disabled(!sessionData.isScrollEnabled)
                    }
                }
            }
            //            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Image("bs-logo-horizontal")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 200, height: 44, alignment: .topLeading)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        print("logout button tapped")
                        onLoggedOut()
                    }) {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                            .foregroundColor(.purple)
                    }
                }
                //                ToolbarItem(placement: .navigationBarTrailing) {
                //                    Button(action: {
                //                        print("scan button tapped")
                //                    }) {
                //                        Image(systemName: "qrcode.viewfinder")
                //                            .foregroundColor(.purple)
                //                    }
                //                }
                //                ToolbarItem(placement: .navigationBarTrailing) {
                //                    Button(action: {
                //                        print("Leading button tapped")
                //                        isShowingProfileView = true
                //                    }) {
                //                        Image(systemName: "person.crop.circle")
                //                            .foregroundColor(.purple)
                //                    }
                //                    .background(
                //                        NavigationLink(
                //                            destination: ProfileView(logger: self.logger, onLoggedOut: onLoggedOut),
                //                            isActive: $isShowingProfileView
                //                        ) {
                //                            EmptyView()
                //                        }
                //                    )
                //                }
            }
        }
    }
}

struct OrdinalPrice {
    var chainFee = 0
    var serviceFee = 0
    var baseFee = 0
    var rareSatsFee = 0
    var additionalFee = 0
    var postage = 0
    var amount = 0
    var totalFee = 0
}

struct StartView: View {
    var next: () -> Void
    var body: some View {
        VStack{
            Spacer()
            Text("Click Start to select your document")
            Spacer()
            Button(action: {
                next()
            }) {
                ButtonTextView(text: "Start")
            }
            .padding()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct PickFileView: View {
    @EnvironmentObject var sessionData: SessionData
    @State private var showFilePicker = false
    @State private var fileName: String?
    @State private var fileURL: URL?
    @State private var fileSize: Int = 0;
    
    var back: () -> Void
    var next: () -> Void
    var body: some View {
        VStack {
            Spacer()
            Button(action: {
                showFilePicker.toggle()
            }) {
                ButtonTextView(text: "Select Document")
            }
            .sheet(isPresented: $showFilePicker) {
                FilePickerView(onFileSelected: { URL in
                    sessionData.fileURL = URL
                    fileURL = URL
                    fileName = fileURL?.lastPathComponent
                    fileSize = BSUtil.shared.fileSize(forURL: fileURL!) ?? 0
                })
            }
            .padding(.top, 20)
            Text("File name: \(fileName ?? "")")
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom, 20)
            Text("File size: \(fileSize) Bytes")
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom, 20)
            Spacer()
            Text("Click next to pay your service fee")
                .padding(.bottom, 20)
            
            Spacer()
            BackNextView(back: {back()}, next: {next()})
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct PayView: View {
    @State private var isPresentingPaymentSheet = false
    var back: () -> Void
    var next: () -> Void
    var body: some View {
        VStack{
            Spacer()
            Text("You will pay $300 for BlockScribe service")
            Button(action: {
                isPresentingPaymentSheet.toggle()
            }) {
                ButtonTextView(text: "Make payment")
            }
            .sheet(isPresented: $isPresentingPaymentSheet) {
                CheckoutView()
            }
            .padding()
            Spacer()
            BackNextView(back: {back()}, next: {next()})
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct GenerateKeyView: View {
    @State private var isButtonDisabled: Bool = false
    
    var back: () -> Void
    var next: () -> Void
    var body: some View {
        VStack {
            Text("Click share key button to generate key")
                .padding(.top, 20)
            Spacer()
            QRCodeView(isDisabled: $isButtonDisabled, sharedKeys:[]){}
            Spacer()
            BackNextView(back: {back()}, next: {next()})
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct InscribeView: View {
    @EnvironmentObject var sessionData: SessionData
    @State private var priceSats: Int = 0;
    
    var back: () -> Void
    var next: () -> Void
    var body: some View {
        VStack{
            Spacer()
            Button(action: {
                Task {
                    guard let fileURL = sessionData.fileURL else {return}
                    guard let fileSize = BSUtil.shared.fileSize(forURL: fileURL) else { return}
                    let data = try await BSUtil.shared.apiGet(from: "https://api.ordinalsbot.com/price?size=\(fileSize)&fee=2&type=direct")
                    if let jsonString = String(data: data, encoding: .utf8) {
                        print(jsonString)
                        do {
                            // Deserialize JSON data to JSON object
                            if let jsonObject = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                                // Access the JSON object
                                if let amount = jsonObject["amount"] as? Int {
                                    self.priceSats = amount
                                    print(amount)
                                }
                            }
                        } catch {
                            print("Error deserializing JSON: \(error.localizedDescription)")
                        }
                    }
                }
            }) {
                ButtonTextView(text: "Check price")
            }
            .padding(.bottom, 20)
            Text("Estimate insribe price: \(priceSats) Sats")
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom, 20)
            Button(action: {}) {
                ButtonTextView(text: "Inscribe")
            }
            Spacer()
            BackNextView(back: {back()}, next: {next()}, nextText: "Finish")
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct ButtonTextView: View {
    var text: String = ""
    var body: some View {
        Text("\(text)")
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.purple)
            .foregroundColor(.white)
            .cornerRadius(8)
    }
}

struct BackNextView: View {
    var back: () -> Void
    var next: () -> Void
    var nextText: String = "Next"
    var body: some View {
        HStack{
            Button(action: {
                back()
            }) {
                Text("Back")
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.purple)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            .padding()
            Button(action: {
                next()
            }) {
                Text("\(nextText)")
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.purple)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            .padding()
        }
    }
}
