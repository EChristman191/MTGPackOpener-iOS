//
//  Notifications.swift
//  MTGPackOpener
//
//  Created by Ethan Christman on 10/14/25.
//

import Foundation

extension Notification.Name {
    static let cardsCollectionChanged = Notification.Name("cards.collection.changed")
    static let profilesActiveChanged  = Notification.Name("profiles.active.changed")
    static let profilesRequestCreate  = Notification.Name("profiles.request.create")
}
