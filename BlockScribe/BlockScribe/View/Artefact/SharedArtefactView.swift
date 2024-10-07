//
//  SharedArtefactView.swift
//  BlockScribe
//
//  Created by Alex Lin on 12/7/24.
//

import SwiftUI

struct SharedArtefactView: View {
    @State private var showingScanView = false
    @State private var sharedKeys: [Key] = []
    @State private var decryptText: String?
    @State private var showShareSheet = false
    
    var body: some View {
        GeometryReader { geometry in
            VStack{
                Text("Decrypt your shared artefact\nwith your shared key and another\nkey shared by the artefact owner")
                    .font(.title3)
                    .frame(maxWidth: geometry.size.width)
                    .multilineTextAlignment(.center)
                    .padding(.top, 20)
                    .padding(.leading, 10)
                    .padding(.bottom, 10)
                HStack{
                    Text("Scan another shared key")
                        .font(.title2)
                        .padding()
                    Spacer()
                    Button(action: {
                        print("scan button tapped")
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
                            print(qrcode)
                            Task {
                                await decryptFile(text: qrcode)
                            }
                        }
                    }
                    .padding()
                }
                Spacer()
                VStack {
                    ZStack{
                        VStack{
                            Spacer()
                            Text("Scan another shared key\nand decrypt the shared artefact")
                                .font(.body)
                                .multilineTextAlignment(.center)
                                .padding()
                            Spacer()
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color("MainBgColor"))
                        .opacity(decryptText == nil ? 1 : 0)
                        .border(Color.gray, width: 1)
                        
                        VStack{
                            ScrollView{
                                Text(decryptText ?? "")
                            }
                            .padding()
                        }
                    }
                }
                Spacer()
            }
            .navigationBarTitle("Decrypt Artefact")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        self.showShareSheet = true
                    }) {
                        Image(systemName: "square.and.arrow.up")
                            .foregroundColor(self.decryptText == nil ? .gray : .purple)
                    }
                    .disabled(self.decryptText == nil)
                    .sheet(isPresented: $showShareSheet) {
                        let fileManager = FileManager.default
                        if let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first {
                            let decryptFileURL = documentsDirectory.appendingPathComponent(Constants.KEY_FILE_NAME_DECRYPTED_ARTEFACTS)
                            ShareActivityView(activityItems: [decryptFileURL], applicationActivities: nil)
                        }
                    }
                }
            }
        }
    }
}

struct SharedArtefactView_Previews: PreviewProvider {
    static var previews: some View {
        SharedArtefactView()
    }
}

extension SharedArtefactView {
    func decryptFile(text: String) async {
        if let retrievedData = BSUtil.shared.retrieveFromKeychain(key: Constants.KEY_KEYS) {
            if let retrievedList: [Key] = BSUtil.shared.convertDataToList(retrievedData) {
                sharedKeys = retrievedList
                self.decryptText = try? BSUtil.shared.decryptFileWithSharedKeys(withSharedKeys: [sharedKeys[0].text, text])
                
                if (self.decryptText != nil) {
                    let fileManager = FileManager.default
                    if let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first {
                        let decryptFileURL = documentsDirectory.appendingPathComponent(Constants.KEY_FILE_NAME_DECRYPTED_ARTEFACTS)
                        let content = self.decryptText!
                        try? content.write(to: decryptFileURL, atomically: true, encoding: .utf8)
                    }
                }
            }
        }
    }
}
