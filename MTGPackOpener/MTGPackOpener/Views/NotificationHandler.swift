//
//  NotificationHandler.swift
//  MTGPackOpener
//
//  Created by Ethan Christman on 9/25/25.
//

import Foundation
import UserNotifications
import UIKit   // for UIApplication.openSettingsURLString
// SwiftUI import not required here unless you want it

/// Centralized local-notification manager for MTG Pack Opener.
final class NotificationHandler: NSObject, ObservableObject {
    static let shared = NotificationHandler()

    fileprivate let center = UNUserNotificationCenter.current()
    private let dailyId = "daily-noon-crack-pack"
    fileprivate let categoryId = "CRACK_PACK_CATEGORY"
    private let openActionId = "OPEN_PACKS_ACTION"

    private override init() { super.init() }

    // Call once at app start (sets delegate and registers categories).
    func configure() {
        center.delegate = self
    }

    // Ask for permission and, if granted, ensure the daily reminder exists.
    func requestAuthorizationAndScheduleDailyNoonReminder() {
        center.requestAuthorization(options: [.alert, .badge, .sound]) { [weak self] granted, _ in
            guard let self else { return }
            if granted { self.ensureDailyReminderScheduled() }
            else { /* optionally: self.openNotificationSettings() */ }
        }
    }

    // Re-create if missing.
    func ensureDailyReminderScheduled() {
        center.getPendingNotificationRequests { [weak self] requests in
            guard let self else { return }
            if !requests.contains(where: { $0.identifier == self.dailyId }) {
                self.scheduleDailyNoonReminder()
            }
        }
    }

    // Remove and re-add the repeating reminder.
    func refreshDailyNoonReminder() {
        center.removePendingNotificationRequests(withIdentifiers: [dailyId])
        scheduleDailyNoonReminder()
    }

    func cancelDailyNoonReminder() {
        center.removePendingNotificationRequests(withIdentifiers: [dailyId])
    }

    // MARK: - Private
    private func scheduleDailyNoonReminder() {
        scheduleDailyReminder(hour: 12, minute: 0,
                              id: dailyId,
                              body: "Hey! It’s time to crack a pack!")
    }

    private func scheduleDailyReminder(hour: Int, minute: Int, id: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = "MTG Pack Opener"
        content.body = body
        content.sound = .default
        content.threadIdentifier = "daily-crack-pack"
        content.categoryIdentifier = categoryId

        var components = DateComponents()
        components.hour = hour     // local time
        components.minute = minute

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)

        center.add(request) { error in
            #if DEBUG
            if let error { print("Failed to schedule daily reminder:", error) }
            #endif
        }
    }

    fileprivate func openNotificationSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        DispatchQueue.main.async {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }
}

// MARK: - Delegate conformance (needed if you set center.delegate = self)
extension NotificationHandler: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .list, .sound])  // ⬅️ show while foregrounded
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        // handle quick actions if you want
        completionHandler()
    }
}


// MARK: - Test fire helpers
extension NotificationHandler {
    /// Fires a local notification shortly (default 1.5s) for testing.
    func sendTestNotification(after seconds: TimeInterval = 1.5) {
        center.getNotificationSettings { [weak self] settings in
            guard let self else { return }
            let authorized: Bool = {
                switch settings.authorizationStatus {
                case .authorized, .provisional, .ephemeral: return true
                default: return false
                }
            }()
            if authorized {
                self._enqueueTestNotification(after: seconds)
            } else {
                self.center.requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
                    if granted { self._enqueueTestNotification(after: seconds) }
                    else { self.openNotificationSettings() }
                }
            }
        }
    }

    private func _enqueueTestNotification(after seconds: TimeInterval) {
        let content = UNMutableNotificationContent()
        content.title = "MTG Pack Opener"
        content.body  = "(Test) Hey! It’s time to crack a pack!"
        content.sound = .default
        content.categoryIdentifier = categoryId
        content.threadIdentifier   = "test-crack-pack"

        let delay = max(1.0, seconds) // ⬅️ IMPORTANT: iOS requires ≥ 1s
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: delay, repeats: false)

        let request = UNNotificationRequest(
            identifier: "test-now-crack-pack-\(UUID().uuidString)",
            content: content,
            trigger: trigger
        )

        center.add(request) { error in
            #if DEBUG
            if let error { print("Test notification error:", error) }
            else { print("Scheduled test notification in \(delay)s") }
            #endif
        }
    }
}
