//
//  ArtefactKeyView.swift
//  BlockScribe
//
//  Created by Alex Lin on 5/7/24.
//

import SwiftUI

struct ArtefactKeyView: View {
    @State private var isButtonDisabled: Bool = false
    @State private var isLinkActive: Bool = false
    @State private var sharedKeys: [String] = []

    var body: some View {
        GeometryReader { geometry in
            VStack {
                Text("You can now share your encrypted Artefact and keys with two trusted people.")
                    .font(.title3)
                    .frame(maxWidth: geometry.size.width)
                    .multilineTextAlignment(.center)
                    .padding(.top, 20)
                    .padding(.leading, 10)
                    .padding(.bottom, 10)
                VStack{
                    HStack {
                        Button(action: {
                            BSUtil.shared.openURL("https://apps.apple.com/app/id6502850931")
                        }){
                            HStack{
                                Text("Share the App first with two trusted people - ")
                                    .font(.system(size: 14))
                                Text("here")
                                    .font(.system(size: 14))
                                    .foregroundColor(.blue)
                            }
                        }
                        .frame(maxWidth: geometry.size.width)
                        .background(.clear)
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                Spacer()
                QRCodeView(isDisabled: $isButtonDisabled, sharedKeys: self.sharedKeys, onShareArtefact: onShareArtefact)
                    .padding(.bottom, 20)
                Spacer()
                
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarTitle("Share Key")
//            .toolbar {
//                ToolbarItem(placement: .navigationBarTrailing) {
//                    Button(action: {
//                        self.isLinkActive = true
//                    }) {
//                        Image(systemName: "doc.text")
//                            .foregroundColor(.purple)
//                    }
//                    .background(
//                        NavigationLink(destination: ArtefactDetailView(), isActive: $isLinkActive) {
//                            EmptyView()
//                        }
//                    )
//                }
//            }
            .onAppear() {
                Task {
                    await loadSharedEncryptKeys()
                }
            }
        }
    }
}

struct ArtefactKeyView_Previews: PreviewProvider {
    static var previews: some View {
        ArtefactKeyView()
    }
}

extension ArtefactKeyView {
    func loadSharedEncryptKeys() async {
        if let retrievedData = BSUtil.shared.retrieveFromKeychain(key: Constants.KEY_SHARED_ENCRYPT_KEYS) {
            if let retrievedList: [String] = BSUtil.shared.convertDataToList(retrievedData) {
                self.sharedKeys = retrievedList
                if (self.sharedKeys.isEmpty) {
                    self.sharedKeys = BSUtil.shared.shareKeySecret()
                }
            }
        } else {
            self.sharedKeys = BSUtil.shared.shareKeySecret()
        }
    }
    
    func onShareArtefact() {
        
    }
}
