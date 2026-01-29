//
//  PhotoLibraryPicker.swift
//  Equinox_AI
//
//  Created by Shreyas Battula on 1/18/26.
//


import SwiftUI
import PhotosUI

struct PhotoLibraryPicker: View {
    @Binding var selectedImage: UIImage?

    @State private var selectedItem: PhotosPickerItem?

    var body: some View {
        PhotosPicker(selection: $selectedItem, matching: .images) {
            Image(systemName: "photo.on.rectangle")
                .font(.system(size: 28))
        }
        .onChange(of: selectedItem) { _, newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    selectedImage = image
                }
            }
        }
    }
}
