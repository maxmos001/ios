//
//  ArtefactDetailView.swift
//  BlockScribe
//
//  Created by Alex Lin on 12/7/24.
//

import SwiftUI
import UIKit

struct ShareActivityView: UIViewControllerRepresentable {
    var activityItems: [Any]
    var applicationActivities: [UIActivity]? = nil
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: activityItems, applicationActivities: applicationActivities)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

struct ArtefactDetailView: View {
    @State private var showShareSheet = false
    @State private var decryptText: String?
    
    var body: some View {
        VStack{
            ScrollView{
                Text(decryptText ?? "")
                    .padding()
            }
            .padding()
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarTitle("Artefact detail")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    self.showShareSheet = true
                }) {
                    Image(systemName: "square.and.arrow.up")
                        .foregroundColor(.purple)
                }
                .sheet(isPresented: $showShareSheet) {
                    let fileManager = FileManager.default
                    if let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first {
                        let encryptFileURL = documentsDirectory.appendingPathComponent(Constants.KEY_FILE_NAME_ENCRYPTED_ARTEFACTS)
                        ShareActivityView(activityItems: [encryptFileURL], applicationActivities: nil)
                        //                            if let data = try? Data(contentsOf: encryptFileURL) {
                        //                                ShareActivityView(activityItems: [encryptFileURL], applicationActivities: nil)
                        //                            }
                        
                    }
                }
            }
        }
        .onAppear() {
            Task {
                await decryptFile()
            }
        }
    }
}

struct ArtefactDetailView_Previews: PreviewProvider {
    static var previews: some View {
        ArtefactDetailView()
    }
}

extension ArtefactDetailView {
    func decryptFile() async {
        self.decryptText = try? BSUtil.shared.decryptFile()
    }
}
