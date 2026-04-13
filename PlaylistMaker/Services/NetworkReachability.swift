//
//  NetworkReachability.swift
//  PlaylistMaker
//

import Foundation
import Network
import Observation

@MainActor
@Observable
final class NetworkReachability {
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "PlaylistMaker.network")

    private(set) var isConnected = true

    init() {
        monitor.pathUpdateHandler = { path in
            let online = path.status == .satisfied
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.isConnected = online
            }
        }
        monitor.start(queue: queue)
    }

    deinit {
        monitor.cancel()
    }
}
