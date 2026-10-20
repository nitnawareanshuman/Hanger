//
//  WardrobeRecommendation.swift
//  Hanger
//
//  Created by Anshuman Nitnaware on 20/10/26.
//

import Foundation

struct WardrobeRecommendation: Identifiable {
    enum Kind: String, CaseIterable, Identifiable {
        case rarelyWorn
        case duplicates
        case seasonalMismatch
        case poorPairing

        var id: String { rawValue }

        var title: String {
            switch self {
            case .rarelyWorn: "Rarely Worn"
            case .duplicates: "Similar Items"
            case .seasonalMismatch: "Seasonal Mismatch"
            case .poorPairing: "Pairing Opportunities"
            }
        }
    }

    enum Priority: String {
        case low
        case medium
        case high
    }

    let id: UUID
    let kind: Kind
    let title: String
    let explanation: String
    let garmentIDs: [UUID]
    let priority: Priority

    init(
        id: UUID = UUID(),
        kind: Kind,
        title: String,
        explanation: String,
        garmentIDs: [UUID],
        priority: Priority
    ) {
        self.id = id
        self.kind = kind
        self.title = title
        self.explanation = explanation
        self.garmentIDs = garmentIDs
        self.priority = priority
    }
}
