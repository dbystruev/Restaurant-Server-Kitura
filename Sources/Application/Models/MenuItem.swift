//
//  MenuItem.swift
//  Application
//
//  Created by Denis Bystruev on 02/09/2019.
//

import Foundation
import SwiftKueryORM

struct MenuItem: Codable {
    var id: Int?
    var name: String?
    var detailText: String?
    var price: Double?
    var category: String?
    var imageURL: URL?
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case detailText = "description"
        case price
        case category
        case imageURL = "image_url"
    }
}

extension MenuItem: Equatable {
    static func == (lhs: MenuItem, rhs: MenuItem) -> Bool {
        return lhs.id == rhs.id
    }
}

extension MenuItem: Model {}
