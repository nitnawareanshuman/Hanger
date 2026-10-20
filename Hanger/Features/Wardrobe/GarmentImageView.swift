import SwiftUI

/// Shows the captured cut-out when one exists, otherwise the SF Symbol illustration.
struct GarmentImageView: View {
    let garment: Garment
    var padding: CGFloat = 8

    var body: some View {
        if let image = GarmentImageStore.load(filename: garment.imageFilename) {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .padding(padding)
        } else {
            GarmentIllustration(garment: garment)
        }
    }
}
