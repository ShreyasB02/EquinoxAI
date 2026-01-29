//
//  EventManager.swift
//  Equinox_AI
//
//  Created by Shreyas Battula on 1/18/26.
//


import Foundation
import EventKit

class EventManager {
    private let store = EKEventStore()
    
    // 1. Request Access (Must happen first)
    func requestAccess() async -> Bool {
        do {
            let calendarAccess = try await store.requestFullAccessToEvents()
            let reminderAccess = try await store.requestFullAccessToReminders()
            return calendarAccess && reminderAccess
        } catch {
            print("Access denied: \(error)")
            return false
        }
    }
    
    // 2. Tool: "What's on my schedule?"
    func fetchEvents() -> String {
        // Get events for the next 3 days
        let startDate = Date()
        let endDate = Calendar.current.date(byAdding: .day, value: 3, to: startDate)!
        
        let predicate = store.predicateForEvents(withStart: startDate, end: endDate, calendars: nil)
        let events = store.events(matching: predicate)
        
        if events.isEmpty { return "No upcoming events found." }
        
        // Format them for the LLM to read
        return events.map { event in
            let date = event.startDate.formatted(date: .abbreviated, time: .shortened)
            return "- [EVENT] \(event.title ?? "Unknown") at \(date)"
        }.joined(separator: "\n")
    }
    
    // 3. Tool: "What do I need to do?" (Reminders)
    func fetchReminders() async -> String {
        return await withCheckedContinuation { continuation in
            let predicate = store.predicateForReminders(in: nil)
            store.fetchReminders(matching: predicate) { reminders in
                guard let reminders = reminders, !reminders.isEmpty else {
                    continuation.resume(returning: "No pending tasks.")
                    return
                }
                
                let list = reminders.prefix(10).map { reminder in
                    "- [TASK] \(reminder.title ?? "Unknown")" + (reminder.isCompleted ? " (Done)" : "")
                }.joined(separator: "\n")
                
                continuation.resume(returning: list)
            }
        }
    }
    
    // 4. Tool: "Schedule a meeting"
    func createEvent(title: String) -> String {
        let newEvent = EKEvent(eventStore: store)
        newEvent.title = title
        newEvent.startDate = Date() // Default to "Now" for simplicity
        newEvent.endDate = Date().addingTimeInterval(3600) // 1 hour long
        newEvent.calendar = store.defaultCalendarForNewEvents
        
        do {
            try store.save(newEvent, span: .thisEvent)
            return "✅ Scheduled '\(title)' for today."
        } catch {
            return "Failed to schedule event: \(error.localizedDescription)"
        }
    }
    
    // 5. Tool: "Remind me to..."
    func createReminder(title: String) -> String {
        let newReminder = EKReminder(eventStore: store)
        newReminder.title = title
        newReminder.calendar = store.defaultCalendarForNewReminders()
        
        do {
            try store.save(newReminder, commit: true)
            return "✅ Added '\(title)' to your tasks."
        } catch {
            return "Failed to add reminder: \(error.localizedDescription)"
        }
    }
}