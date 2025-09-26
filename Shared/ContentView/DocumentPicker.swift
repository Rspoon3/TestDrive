//
//  DocumentPicker.swift
//  TestDrive
//

import SwiftUI
import UIKit
import UniformTypeIdentifiers

/// A document picker for selecting image files from the file system.
struct DocumentPicker: UIViewControllerRepresentable {
    let completion: ([URL]) -> Void

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [UTType.image], asCopy: true)
        picker.delegate = context.coordinator
        picker.allowsMultipleSelection = true
        return picker
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let parent: DocumentPicker

        // MARK: - Initializer

        init(_ parent: DocumentPicker) {
            self.parent = parent
        }

        // MARK: - UIDocumentPickerDelegate

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            parent.completion(urls)
        }

        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            parent.completion([])
        }
    }
}