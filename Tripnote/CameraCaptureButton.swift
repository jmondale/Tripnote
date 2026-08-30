//
//  CameraCaptureButton.swift
//  Tripnote
//
//  Created by Jaye Mondale on 8/7/26.
//  Copyright © 2026 Jaye Mondale. All rights reserved.
//

import SwiftUI
import UIKit

/// `PhotosPicker` (PhotosUI) only selects existing library photos — it has no camera mode.
/// For live capture we still need to bridge `UIImagePickerController`.
struct CameraCaptureButton: View {
    let onCapture: (Data) -> Void
    var label: String = "Take Photo"
    var systemImage: String = "camera"

    @State private var isPresentingCamera = false

    var body: some View {
        Button {
            isPresentingCamera = true
        } label: {
            Label(label, systemImage: systemImage)
        }
        .disabled(!UIImagePickerController.isSourceTypeAvailable(.camera))
        .fullScreenCover(isPresented: $isPresentingCamera) {
            CameraPicker(onCapture: onCapture)
                .ignoresSafeArea()
        }
    }
}

struct CameraPicker: UIViewControllerRepresentable {
    let onCapture: (Data) -> Void
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraPicker

        init(_ parent: CameraPicker) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            defer { parent.dismiss() }
            guard let image = info[.originalImage] as? UIImage,
                  let data = image.jpegData(compressionQuality: 0.9)
            else { return }
            parent.onCapture(data)
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}
