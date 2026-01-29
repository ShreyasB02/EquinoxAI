//
//  MemoryManager.swift
//  Equinox_AI
//
//  Created by Shreyas Battula on 1/18/26.
//


import SwiftData
import SwiftUI

@MainActor
class MemoryManager {
    private var modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // 1. Save a new fact
    func remember(_ text: String) {
        let cleanText = text.replacingOccurrences(of: "Remember ", with: "")
        let newMemory = MemoryItem(content: cleanText)
        modelContext.insert(newMemory)
        
        do {
            try modelContext.save()
            print("Saved memory: \(cleanText)")
        } catch {
            print("Failed to save memory: \(error)")
        }
    }
    
    // 2. Recall all facts (In a real app, you'd filter this by relevance)
    func recallAll() -> String {
        let descriptor = FetchDescriptor<MemoryItem>(sortBy: [SortDescriptor(\.dateAdded)])
        let memories = (try? modelContext.fetch(descriptor)) ?? []
        
        if memories.isEmpty { return "" }
        
        // Format them as a list for the LLM
        let memoryList = memories.map { "- \($0.content)" }.joined(separator: "\n")
        return "HERE IS WHAT YOU KNOW ABOUT THE USER:\n\(memoryList)\n\n"
    }
    
    // 3. Clear memory (Debug tool)
    func forgetAll() {
        try? modelContext.delete(model: MemoryItem.self)
    }
}