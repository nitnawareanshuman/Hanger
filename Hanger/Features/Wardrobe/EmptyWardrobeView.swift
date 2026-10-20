//
//  EmptyWardrobeView.swift
//  Hanger
//
//  Created by Anshuman Nitnaware on 20/10/26.
//

import SwiftUI

struct EmptyWardrobeView: View {
    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: "hanger")
                .font(.system(size: 36))
                .foregroundStyle(Color.wardrobeAccent)

            Text("Your wardrobe is waiting")
                .font(.system(size: 20, weight: .bold, design: .rounded))

            Text("Capture or import your first garment to get started.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Image(systemName: "camera.fill")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 48, height: 48)
                .background(
                    Color.wardrobeAccent,
                    in: RoundedRectangle(cornerRadius: 15)
                )
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 36)
        .padding(.horizontal, 20)
        .background(
            Color.wardrobeChip,
            in: RoundedRectangle(cornerRadius: 22)
        )
    }
}

