//
//  PhotoItem.swift
//  TestDrive
//

import SwiftUI
import PhotosUI

struct PhotoItem: Identifiable, Hashable {
    let id = UUID()
    let image: UIImage
    let filename: String
    var rank: Int = 0

    init(image: UIImage, filename: String = "Untitled Photo") {
        self.image = image
        self.filename = filename
        self.rank = 0
    }
}
