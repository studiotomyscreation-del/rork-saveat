//
//  SAVEATApp.swift
//  SAVEAT
//
//  Created by Rork on August 25, 2026.
//

import SwiftUI

@main
struct SAVEATApp: App {
    init() {
        // Configured once, at launch — never in `onAppear` or `.task`.
        PurchasesBootstrap.configure()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
