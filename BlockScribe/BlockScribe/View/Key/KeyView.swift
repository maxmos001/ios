//
//  KeyView.swift
//  BlockScribe
//
//  Created by Alex Lin on 3/7/24.
//

import SwiftUI

struct Key: Identifiable & Codable {
    let id: Int
    let text: String
    let created: String
}

struct KeyView: View {
    @Environment(\.colorScheme) var colorScheme
    
    @State private var keys: [Key] = []
    @State private var showingScanView = false
    @State private var sharedKeys: [Key] = []
    @State private var showingSharedScanView = false
    @State private var sharedKeyQrCode = ""
    @State private var presentAlert = false
    
    init() {
        UITabBar.appearance().barTintColor = UIColor(.white)
    }
    
    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                VStack{
                    VStack {
                        Divider()
                            .frame(height: 1)
                            .background(Color.gray)
                            .padding(.horizontal)
                        Text("Keys are where all your\nshared keys are securely stored")
                            .font(.title3)
                            .frame(maxWidth: geometry.size.width)
                            .multilineTextAlignment(.center)
                            .minimumScaleFactor(0.5)
                            .padding()
                        HStack{
                            Text("Shared with you")
                                .font(.title)
                                .padding()
                            Spacer()
                            Button(action: {
                                showingScanView = true
                            }) {
                                Image(systemName: "qrcode.viewfinder")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 30, height: 30)
                                    .foregroundColor(.purple)
                            }
                            .background(.clear)
                            .buttonStyle(PlainButtonStyle())
                            .sheet(isPresented: $showingScanView) {
                                // Content of the sheet goes here
                                ScanView { qrcode in
                                    addSharedKey(qrcode)
                                }
                            }
                            .padding()
                        }
                        HStack{
                            TextField("Paste your shared key here...", text: $sharedKeyQrCode)
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                            
                            if !sharedKeyQrCode.isEmpty {
                                Button(action: {
                                    self.sharedKeyQrCode = ""
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.purple)
                                }
                            }
                        }
                        Button(action: {
                            self.presentAlert = true
                        }) {
                            HStack{
                                Image(systemName: "qrcode")
                                    .foregroundColor(.purple)
                                Text("Add shared key")
                                    .padding(.vertical)
                                    .background(Color.clear)
                                    .foregroundColor(.purple)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .background(.clear)
                        .buttonStyle(PlainButtonStyle())
                        .border(Color.purple, width: 1)
                        .padding(.vertical, 5)
                        Spacer()
                        List(keys) { item in
                            NavigationLink(destination: KeyDetailView()) {
                                HStack {
                                    Text("Shared key")
                                    Spacer()
                                    Text("\(item.created)")
                                        .font(.system(size: 14))
                                }
                                .frame(maxWidth: geometry.size.width)
                                .frame(height: 60)
                            }
                        }
                        .listStyle(PlainListStyle())
                        Spacer()
                    }
                    Spacer()
                    //                    VStack{
                    //                        HStack{
                    //                            Text("Shared keys")
                    //                                .font(.title)
                    //                                .padding()
                    //                            Spacer()
                    //                            Button(action: {
                    //                                print("scan button tapped")
                    //                                                                showingSharedScanView = true
                    //                            }) {
                    //                                Image(systemName: "qrcode.viewfinder")
                    //                                    .resizable()
                    //                                    .aspectRatio(contentMode: .fit)
                    //                                    .frame(width: 40, height: 40)
                    //                                    .foregroundColor(.purple)
                    //                            }
                    //                            .background(.clear)
                    //                            .buttonStyle(PlainButtonStyle())
                    //                            .sheet(isPresented: $showingSharedScanView) {
                    //                                // Content of the sheet goes here
                    //                                ScanView { qrcode in
                    //                                    let item = Key(id: sharedKeys.count+1, text: qrcode);
                    //                                    sharedKeys = [item]
                    //                                    if let data = BSUtil.shared.convertListToData(sharedKeys) {
                    //                                        let success = BSUtil.shared.saveToKeychain(data: data, for: Constants.KEY_SHARED_KEYS)
                    //                                    }
                    //                                }
                    //                            }
                    //                            .padding()
                    //                        }
                    //                        Spacer()
                    //                        List(sharedKeys) { item in
                    //                            HStack {
                    //                                Text(item.text)
                    //                                Spacer()
                    //                                Button(action: {
                    //                                }) {}
                    //                            }
                    //                            .frame(height: 44)
                    //                            .padding(.bottom, 10)
                    //                        }
                    //                        .listStyle(PlainListStyle())
                    //                        Spacer()
                    //                    }
                }
                .navigationTitle("Keys")
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
                await loadKeys()
            }
        }
        .alert(isPresented: $presentAlert) {
            createAlert()
        }
    }
}

struct KeyView_Previews: PreviewProvider {
    static var previews: some View {
        KeyView()
    }
}

extension KeyView {
    func loadKeys() async {
        if let retrievedData = BSUtil.shared.retrieveFromKeychain(key: Constants.KEY_KEYS) {
            if let retrievedList: [Key] = BSUtil.shared.convertDataToList(retrievedData) {
                keys = retrievedList
            }
        }
        
        if let retrievedData = BSUtil.shared.retrieveFromKeychain(key: Constants.KEY_SHARED_KEYS) {
            if let retrievedList: [Key] = BSUtil.shared.convertDataToList(retrievedData) {
                sharedKeys = retrievedList
            }
        }
    }
    
    func today() -> String {
        let currentDate = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let formattedDate = formatter.string(from: currentDate)
        return formattedDate
    }
    
    func addSharedKey(_ qrCode: String) {
        let item = Key(id: keys.count+1, text: qrCode, created: today());
        self.keys = [item]
        if let data = BSUtil.shared.convertListToData(keys) {
            let success = BSUtil.shared.saveToKeychain(data: data, for: Constants.KEY_KEYS)
        }
    }
    
    func createAlert() -> Alert {
        if (self.sharedKeyQrCode.isEmpty){
            return Alert(
                title: Text("Error"),
                message: Text("Please input your new shared key."),
                dismissButton: .default(Text("Yes"))
            )
        } else {
            return Alert(
                title: Text("Add Shared Key"),
                message: Text("You will add a new shared key.\nAre you sure you want to proceed?"),
                primaryButton: .default(Text("Yes"), action: {
                    addSharedKey(self.sharedKeyQrCode)
                    self.sharedKeyQrCode = ""
                }),
                secondaryButton: .cancel(Text("No"))
            )
        }
    }
}
