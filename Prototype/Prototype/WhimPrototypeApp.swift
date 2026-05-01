//
//  WhimPrototypeApp.swift
//  Prototype
//
//  Created by Marija Zdravic on 01.05.2026..
//

import SwiftUI

@main
struct WhimPrototypeApp: App {
    var body: some Scene {
        WindowGroup {
            EntryListPrototypeView(state: .loaded(EntryListPrototypeItem.samples))
        }
    }
}
