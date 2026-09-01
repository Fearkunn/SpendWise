//
//  Item.swift
//  SpendWise
//
//  Created by Richie Daryl Kwenandar on 01/09/26.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
