//
//  QRCodeView.swift
//  BlockScribe
//
//  Created by Alex Lin on 16/4/24.
//

import SwiftUI

struct QRCodeView: View {
    @Binding private var isButtonDisabled: Bool
    @State private var inputText = ""
    @State private var qrImage: Image?
    @State private var showClipboardIcon = false
    @State private var showShareSheet = false
    @State private var copyButtonText = ""
    @State private var qrCodeText = ""

    private var sharedKeys: [String] = []
    private let onShareArtefact: () -> Void
    
    init(isDisabled: Binding<Bool>, sharedKeys: [String], onShareArtefact: @escaping () -> Void) {
        _isButtonDisabled = isDisabled
        self.sharedKeys = sharedKeys
        self.onShareArtefact = onShareArtefact
    }
    
    var body: some View {
        GeometryReader { geometry in
            VStack {
                VStack {
                    Button(action: {
                        self.showShareSheet = true
                    }) {
                        HStack{
                            Image(systemName: "doc.text")
                                .foregroundColor(.purple)
                            Text("Share Artefact")
                                .padding(.vertical)
                                .background(Color.clear)
                                .foregroundColor(.purple)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .background(.clear)
                    .buttonStyle(PlainButtonStyle())
                    .border(Color.purple, width: 1)
                    .sheet(isPresented: $showShareSheet) {
                        let fileManager = FileManager.default
                        if let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first {
                            let encryptFileURL = documentsDirectory.appendingPathComponent(Constants.KEY_FILE_NAME_ENCRYPTED_ARTEFACTS)
                            ShareActivityView(activityItems: [encryptFileURL], applicationActivities: nil)
                        }
                    }
                    .padding(.bottom, 10)
                    
                    HStack{
                        Button(action: {
                            copyButtonText = "Copy & Paste Key 1"
                            qrCodeText = sharedKeys[0]
                            qrImage = BSUtil.shared.generateQRCode(from: sharedKeys[0])
                        }) {
                            Text("Share Key 1")
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(isButtonDisabled ? Color.gray : Color.clear)
                                .foregroundColor(.purple)
                            //                            .cornerRadius(8)
                        }
                        .background(.clear)
                        .buttonStyle(.plain)
                        .border(Color.purple, width: 1)
                        Button(action: {
                            copyButtonText = "Copy & Paste Key 2"
                            qrCodeText = sharedKeys[1]
                            qrImage = BSUtil.shared.generateQRCode(from: sharedKeys[1])
                        }) {
                            Text("Share Key 2")
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(isButtonDisabled ? Color.gray : Color.clear)
                                .foregroundColor(.purple)
                        }
                        .background(.clear)
                        .buttonStyle(PlainButtonStyle())
                        .border(Color.purple, width: 1)
                    }
                }
                .padding(.bottom, 5)
                Spacer()
                VStack {
                    ZStack{
                        VStack{
                            Spacer()
                            Text("Tap the \"Share Key\" button(s) above to share each key either by QR Code or copy/paste key address.\n\nYour two other trusted people need to download the BlockScribe App first & can either scan the code or enter the copied key address.")
                                .font(.body)
                                .multilineTextAlignment(.center)
                                .padding()
                            Spacer()
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color("MainBgColor"))
                        .opacity(qrImage == nil ? 1 : 0)
                        .border(qrImage == nil ? Color.gray : Color.clear, width: 1)
                        
                        ZStack{
                            VStack{
                                VStack{
                                    qrImage?
                                        .resizable()
                                        .scaledToFit()
                                        .frame(maxWidth: 250, maxHeight:250)
                                        .background(.clear)
                                }
                                .frame(maxWidth: .infinity, maxHeight:.infinity)
                                .border(Color.clear, width: 1)
                                .padding(.bottom, 5)
                                Spacer()
                                Button(action: {
                                    UIPasteboard.general.string = self.qrCodeText
                                    withAnimation {
                                        showClipboardIcon = true
                                    }
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                        withAnimation {
                                            showClipboardIcon = false
                                        }
                                    }
                                }) {
                                    Text(copyButtonText)
                                        .padding()
                                        .frame(maxWidth: .infinity)
                                        .background(Color.clear)
                                        .foregroundColor(.purple)
                                }
                                .background(.clear)
                                .buttonStyle(PlainButtonStyle())
                                .border(Color.purple, width: 1)
                            }
                            VStack{
                                Spacer()
                                if showClipboardIcon {
                                    HStack{
                                        Spacer()
                                    Image(systemName: "doc.on.clipboard")
                                        .font(.body)
                                        .foregroundColor(.purple)
                                        .transition(.opacity)
                                        .animation(.easeInOut(duration: 0.5), value: showClipboardIcon)
                                        .padding(.trailing, 10)
                                        .padding(.bottom, 10)
                                    }
                                }
                            }
                        }
                        .opacity(qrImage == nil ? 0 : 1)
                    }
                }
                Spacer()
            }
            .padding()
        }
    }
}

struct QRCodeView_Previews: PreviewProvider {
    static var previews: some View {
        QRCodeView(isDisabled: .constant(true), sharedKeys: ["Key1", "Key2"]) {}
    }
}

extension QRCodeView {
    
}

