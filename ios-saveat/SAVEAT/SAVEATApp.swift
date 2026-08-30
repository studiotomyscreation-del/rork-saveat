//
//  SAVEATApp.swift
//  SAVEAT
//
//  Created by Rork on August 25, 2026.
//

import SwiftUI
import UserNotifications

@main
struct SAVEATApp: App {
    init() {
        // Configured once, at launch — never in `onAppear` or `.task`.
        PurchasesBootstrap.configure()

        // Reminder taps must reach the app even from a cold start.
        UNUserNotificationCenter.current().delegate = SaveatNotificationDelegate.shared
        NotificationService.shared.configure()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
