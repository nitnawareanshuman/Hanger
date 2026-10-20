//
//  Season.swift
//  Hanger
//
//  Created by Anshuman Nitnaware on 20/10/26.
//

import Foundation

enum Season: String, CaseIterable, Codable, Identifiable {
    case spring
    case summer
    case autumn
    case winter
    case allSeason

    var id: String { rawValue }

    var title: String {
        switch self {
        case .spring: "Spring"
        case .summer: "Summer"
        case .autumn: "Autumn"
        case .winter: "Winter"
        case .allSeason: "All Season"
        }
    }
}
