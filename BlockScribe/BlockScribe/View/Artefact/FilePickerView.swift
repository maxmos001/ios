//
//  FilePickerView.swift
//  BlockScribe
//
//  Created by Alex Lin on 17/5/24.
//

import SwiftUI
import UniformTypeIdentifiers

struct FilePickerView: UIViewControllerRepresentable {
    private let onFileSelected: (_ fileUrl: URL) -> Void
    
    init(onFileSelected: @escaping (URL) -> Void) {
        self.onFileSelected = onFileSelected;
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: [UTType.data])
        documentPicker.delegate = context.coordinator
        return documentPicker
    }
    
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {
        // No update needed
    }
    
    class Coordinator: NSObject, UIDocumentPickerDelegate {
        var parent: FilePickerView

        init(_ parent: FilePickerView) {
            self.parent = parent
        }

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let selectedFileURL = urls.first else { return }
            print("Selected file URL: \(selectedFileURL)")
            guard let size = BSUtil.shared.fileSize(forURL: selectedFileURL) else { return }
            print("Selected file size: \(size)")
            self.parent.onFileSelected(selectedFileURL);
            // Handle the selected file URL here
        }
    }
}
