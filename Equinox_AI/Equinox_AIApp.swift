//
//  Equinox_AIApp.swift
//  Equinox_AI
//
//  Created by Shreyas Battula on 1/14/26.
//

import SwiftUI
import SwiftData

@main
struct Equinox_AIApp: App {
    var body: some Scene {
        WindowGroup {
            ChatView()
        }.modelContainer(for:MemoryItem.self)
    }
}
