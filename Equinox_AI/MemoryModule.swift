//
//  MemoryModule.swift
//  Equinox_AI
//
//  Created by Shreyas Battula on 1/18/26.
//

import Foundation
import SwiftData

@Model
class MemoryItem {
    var content: String
    var dateAdded: Date
    
    init(content: String) {
        self.content = content
        self.dateAdded = Date()
    }
}
