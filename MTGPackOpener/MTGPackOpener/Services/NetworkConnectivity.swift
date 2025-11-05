//
//  NetworkConnectivity.swift
//  MTGPackOpener
//
//  Created by Ethan Christman on 9/25/25.
//

import Foundation
import Network
import UIKit

final class NetworkMonitor: ObservableObject {
    static let shared = NetworkMonitor()

    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitorQueue")

    @Published private(set) var isConnected: Bool = false   // start false
    @Published private(set) var usesWiFi: Bool = false
    @Published private(set) var usesCellular: Bool = false
    @Published private(set) var isConstrained: Bool = false // Low Data Mode
    @Published private(set) var isExpensive: Bool = false   // e.g., cellular

    private init() {
        monitor.pathUpdateHandler = { [weak self] path in
            guard let self else { return }
            DispatchQueue.main.async {
                self.isConnected  = (path.status == .satisfied)
                self.usesWiFi     = path.usesInterfaceType(.wifi)
                self.usesCellular = path.usesInterfaceType(.cellular)
                self.isConstrained = path.isConstrained
                self.isExpensive   = path.isExpensive
            }
        }
        monitor.start(queue: queue)
    }

    static func openSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }
}
