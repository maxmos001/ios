//
//  ArtefactView.swift
//  BlockScribe
//
//  Created by Alex Lin on 3/7/24.
//

import SwiftUI
import Foundation
import Security

struct Artefact: Identifiable & Codable {
    let id: Int
    let fileName: String
    let fileURL: URL
}

struct ArtefactView: View {
    @EnvironmentObject var sessionData: SessionData
    @Environment(\.colorScheme) var colorScheme
    
    @State private var showFilePicker = false
    @State private var fileName: String?
    @State private var fileURL: URL?
    @State private var fileSize: Int = 0;
    
    @State private var showSharedFilePicker = false
    @State private var sharedFileName: String?
    @State private var sharedFileURL: URL?
    @State private var sharedFileSize: Int = 0;
    
    @State private var items: [Artefact] = []
    @State private var sharedItems: [Artefact] = []
    
    @State private var isShowingProfileView = false
    @State private var isSheetPresented = true
    
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
                        Text("An Artefact is an encrypted document with your important personal data. This should be a Plain Text file completed on a PC/laptop then sent to your phone. See welcome email for details.")
                            .font(.title3)
                            .frame(maxWidth: geometry.size.width)
                            .multilineTextAlignment(.center)
                            .minimumScaleFactor(0.5)
                            .padding()
                    }
                    Spacer()
                    VStack{
                        HStack{
                            Text("Your Artefact")
                                .font(.title)
                                .padding()
                            Spacer()
                            Button(action: {
                                showFilePicker.toggle()
                            }) {
                                Image(systemName: "plus.circle")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 30, height: 30)
                                    .foregroundColor(.purple)
                            }
                            .background(.clear)
                            .buttonStyle(PlainButtonStyle())
                            .sheet(isPresented: $showFilePicker) {
                                FilePickerView(onFileSelected: { URL in
                                    sessionData.fileURL = URL
                                    fileURL = URL
                                    fileName = fileURL?.lastPathComponent
                                    fileSize = BSUtil.shared.fileSize(forURL: fileURL!) ?? 0
                                    do {
                                        //                                        let fileData = try Data(contentsOf: fileURL!)
                                        //                                        let base64Data = fileData.base64EncodedString()
                                        try BSUtil.shared.encryptFile(at: fileURL!)
                                        let item = Artefact(id: items.count+1, fileName: fileName!, fileURL: fileURL!);
                                        items = [item]
                                        if let data = BSUtil.shared.convertListToData(items) {
                                            let success = BSUtil.shared.saveToKeychain(data: data, for: Constants.KEY_ARTEFACTS)
                                        }
                                    } catch {
                                        print("Failed to read file data: \(error)")
                                    }
                                })
                            }
                            .padding()
                        }
                        Spacer()
                        List(items) { item in
                            NavigationLink(destination: ArtefactKeyView()) {
                                HStack{
                                    Text(item.fileName)
                                }
                                .frame(height: 60)
                            }
                        }
                        .listStyle(PlainListStyle())
                        Spacer()
                    }
                    Text("The curent version only supports one Artefact. If you require a new Artefact, new keys will need to be distributed.")
                        .font(.body)
                        .frame(maxWidth: geometry.size.width)
                        .multilineTextAlignment(.center)
                        .minimumScaleFactor(0.5)
                        .padding()
                    VStack{
                        HStack{
                            Text("Shared with you")
                                .font(.title)
                                .padding()
                            Spacer()
                            Button(action: {
                                showSharedFilePicker.toggle()
                            }) {
                                Image(systemName: "plus.circle")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 30, height: 30)
                                    .foregroundColor(.purple)
                            }
                            .background(.clear)
                            .buttonStyle(PlainButtonStyle())
                            .sheet(isPresented: $showSharedFilePicker) {
                                FilePickerView(onFileSelected: { URL in
                                    sessionData.sharedFileURL = URL
                                    sharedFileURL = URL
                                    sharedFileName = sharedFileURL?.lastPathComponent
                                    sharedFileSize = BSUtil.shared.fileSize(forURL: sharedFileURL!) ?? 0
                                    do {
                                        // Read the data from the file
                                        let fileData = try Data(contentsOf: sharedFileURL!)
                                        let item = Artefact(id: sharedItems.count+1, fileName: sharedFileName!, fileURL: sharedFileURL!);
                                        sharedItems = [item];
                                        if let data = BSUtil.shared.convertListToData(sharedItems) {
                                            _ = BSUtil.shared.saveToKeychain(data: data, for: Constants.KEY_SHARED_ARTEFACTS)
                                        }
                                        _ = BSUtil.shared.saveToKeychain(data: fileData, for: Constants.KEY_SHARED_ENCRYPTED_ARTEFACTS)
                                    } catch {
                                        print("Failed to read file data: \(error)")
                                    }
                                })
                            }
                            .padding()
                        }
                        Spacer()
                        List(sharedItems) { item in
                            NavigationLink(destination: SharedArtefactView()) {
                                HStack{
                                    Text(item.fileName)
                                }
                                .frame(height: 60)
                            }
                        }
                        .listStyle(PlainListStyle())
                        Spacer()
                    }
                    Spacer()
                }
                .navigationTitle("Artefacts")
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
                .sheet(isPresented: $isSheetPresented) {
                    VStack{
                        Image("bs-logo")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 120, height: 120, alignment: .center)
                        Image("how-it-works")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    }
                    .background(.white)
                }
            }
        }
        .onAppear() {
            BSUtil.shared.updateColorScheme(colorScheme)
            Task {
                await loadArtefacts()
            }
        }
    }
}

struct ArtefactView_Previews: PreviewProvider {
    static var previews: some View {
        ArtefactView()
    }
}

extension ArtefactView {
    func loadArtefacts() async {
        if let retrievedData = BSUtil.shared.retrieveFromKeychain(key: Constants.KEY_ARTEFACTS) {
            if let retrievedList: [Artefact] = BSUtil.shared.convertDataToList(retrievedData) {
                self.items = retrievedList
            }
        }
        
        if let retrievedData = BSUtil.shared.retrieveFromKeychain(key: Constants.KEY_SHARED_ARTEFACTS) {
            if let retrievedList: [Artefact] = BSUtil.shared.convertDataToList(retrievedData) {
                sharedItems = retrievedList
            }
        }
    }
}
