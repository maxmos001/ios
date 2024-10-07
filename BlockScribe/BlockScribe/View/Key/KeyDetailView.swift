//
//  KeyDetail.swift
//  BlockScribe
//
//  Created by Alex Lin on 15/7/24.
//

import SwiftUI

struct KeyDetailView: View {
    @State private var sharedKeys: [Key] = []
    @State private var qrImage: Image?
    @State private var showClipboardIcon = false
    
    var body: some View {
        GeometryReader { geometry in
            VStack {
                Text("Your shared key will be\nused by another shared key\nholder to decrypt shared artefact\n\nYou can tap the QR code\nto copy and paste the shared key")
                    .font(.title3)
                    .frame(maxWidth: geometry.size.width)
                    .multilineTextAlignment(.center)
                    .padding(.top, 20)
                    .padding(.leading, 10)
                    .padding(.bottom, 10)
                Spacer()
                ZStack{
                    VStack{
                        qrImage?
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: 250, maxHeight: 250)
                            .padding([.leading, .trailing], 20)
                            .padding(.bottom, 20)
                            .onTapGesture {
                                UIPasteboard.general.string = sharedKeys[0].text
                                withAnimation {
                                    showClipboardIcon = true
                                }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                    withAnimation {
                                        showClipboardIcon = false
                                    }
                                }
                            }
                    }
                    VStack{
                        Spacer()
                        if showClipboardIcon {
                            Image(systemName: "doc.on.clipboard")
                                .font(.title)
                                .foregroundColor(.purple)
                                .transition(.opacity)
                                .animation(.easeInOut(duration: 0.5), value: showClipboardIcon)
                                .padding(.bottom, 10)
                        }
                    }
                }
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarTitle("Key Detail")
            .onAppear() {
                Task {
                    await loadSharedKeys()
                }
            }
        }
    }
}

struct KeyDetailView_Previews: PreviewProvider {
    static var previews: some View {
        KeyDetailView()
    }
}

extension KeyDetailView {
    func loadSharedKeys() async {
        if let retrievedData = BSUtil.shared.retrieveFromKeychain(key: Constants.KEY_KEYS) {
            if let retrievedList: [Key] = BSUtil.shared.convertDataToList(retrievedData) {
                self.sharedKeys = retrievedList
                self.qrImage = BSUtil.shared.generateQRCode(from: sharedKeys[0].text)
            }
        }
    }
}
