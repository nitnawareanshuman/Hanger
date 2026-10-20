//
//  GarmentCategory.swift
//  Hanger
//
//  Created by Anshuman Nitnaware on 20/10/26.
//

import Foundation

enum GarmentCategory: String, CaseIterable, Codable, Identifiable {
    case tops
    case bottoms
    case dresses
    case outerwear
    case shoes
    case accessories
    case bags

    var id: String { rawValue }

    var title: String {
        switch self {
        case .tops: "Tops"
        case .bottoms: "Bottoms"
        case .dresses: "Dresses"
        case .outerwear: "Outerwear"
        case .shoes: "Shoes"
        case .accessories: "Accessories"
        case .bags: "Bags"
        }
    }
}
