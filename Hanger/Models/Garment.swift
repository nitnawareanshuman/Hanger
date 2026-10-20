//
//  Garment.swift
//  Hanger
//
//  Created by Anshuman Nitnaware on 20/10/26.
//

import Foundation
import SwiftData

@Model
final class Garment {
    @Attribute(.unique)
    var id: UUID

    var name: String
    var categoryRawValue: String
    var colorHex: String
    var seasonRawValue: String

    /// Relative filename inside the app's garment image directory.
    var imageFilename: String

    var wearCount: Int
    var lastWornDate: Date?
    var createdAt: Date
    var tags: [String]
    var isArchived: Bool

    init(
        id: UUID = UUID(),
        name: String,
        category: GarmentCategory,
        colorHex: String,
        season: Season = .allSeason,
        imageFilename: String,
        wearCount: Int = 0,
        lastWornDate: Date? = nil,
        createdAt: Date = .now,
        tags: [String] = [],
        isArchived: Bool = false
    ) {
        self.id = id
        self.name = name
        self.categoryRawValue = category.rawValue
        self.colorHex = colorHex
        self.seasonRawValue = season.rawValue
        self.imageFilename = imageFilename
        self.wearCount = wearCount
        self.lastWornDate = lastWornDate
        self.createdAt = createdAt
        self.tags = tags
        self.isArchived = isArchived
    }

    var category: GarmentCategory {
        get {
            GarmentCategory(rawValue: categoryRawValue) ?? .tops
        }
        set {
            categoryRawValue = newValue.rawValue
        }
    }

    var season: Season {
        get {
            Season(rawValue: seasonRawValue) ?? .allSeason
        }
        set {
            seasonRawValue = newValue.rawValue
        }
    }
}
