//
//  SoundManager.swift
//  MTGPackOpener
//
//  Created by J.E.D. on 10/6/25.
//

import AVFoundation
import UIKit

// MARK: - SoundManager
final class SoundManager {
    static let shared = SoundManager()

    struct Keys {
        static let sfxEnabled   = "settings.sfxEnabled"
        static let musicEnabled = "settings.musicEnabled"
    }

    private(set) var currentMusicName = "background_music" // match your file name
    private(set) var currentMusicExt  = "mp3"

    private init() {
        UserDefaults.standard.register(defaults: [
            Keys.sfxEnabled: true,
            Keys.musicEnabled: true
        ])
        try? configureSession(respectSilentSwitch: true)

        // Auto-start music at app launch if enabled
        if UserDefaults.standard.bool(forKey: Keys.musicEnabled) {
            // small defer helps avoid edge cases during app bootstrap
            DispatchQueue.main.async {
                self.startMusic(self.currentMusicName, self.currentMusicExt, volume: 1.0)
            }
        }
    }

    private var players: [String: [AVAudioPlayer]] = [:]   // SFX pools
    private let queue = DispatchQueue(label: "sfx.queue", qos: .userInitiated)

    private var musicPlayer: AVAudioPlayer?

    // MARK: Session
    @discardableResult
    func configureSession(respectSilentSwitch: Bool, mixWithOthers: Bool = true) throws {
        let session = AVAudioSession.sharedInstance()
        let category: AVAudioSession.Category = respectSilentSwitch ? .ambient : .playback
        let options: AVAudioSession.CategoryOptions = mixWithOthers ? [.mixWithOthers] : []
        try session.setCategory(category, options: options)
        try session.setActive(true)
    }

    // MARK: Settings accessors
    private var isSFXEnabled: Bool { UserDefaults.standard.bool(forKey: Keys.sfxEnabled) }
    private var isMusicEnabled: Bool { UserDefaults.standard.bool(forKey: Keys.musicEnabled) }

    // MARK: Preload SFX
    func preload(_ files: [(name: String, ext: String)]) {
        queue.sync {
            for (name, ext) in files {
                let k = key(name, ext)
                if players[k]?.isEmpty == false { continue }
                if let p = try? makePlayer(name, ext) {
                    players[k, default: []].append(p)
                }
            }
        }
    }

    // MARK: Play SFX (respects toggle)
    @discardableResult
    func play(_ name: String, ext: String = "mp3", volume: Float = 0.70, loop: Int = 0) -> Bool {
        guard isSFXEnabled else { return false }
        return queue.sync {
            let k = key(name, ext)
            let chosen: AVAudioPlayer
            if let pool = players[k], let idle = pool.first(where: { !$0.isPlaying }) {
                chosen = idle
            } else if let newP = try? makePlayer(name, ext) {
                players[k, default: []].append(newP)
                chosen = newP
            } else {
                print("Could not init SFX \(name).\(ext)")
                return false
            }
            chosen.currentTime = 0
            chosen.volume = volume
            chosen.numberOfLoops = loop
            chosen.play()
            return true
        }
    }

    // MARK: Music controls
    func setMusicEnabled(_ enabled: Bool, track: String? = nil, ext: String = "mp3", volume: Float = 0.6) {
        UserDefaults.standard.set(enabled, forKey: Keys.musicEnabled)
        if let t = track { currentMusicName = t }
        currentMusicExt = ext
        if enabled {
            startMusic(currentMusicName, currentMusicExt, volume: volume)
        } else {
            stopMusic()
        }
    }

    func startMusic(_ name: String? = nil, _ ext: String = "mp3", volume: Float = 0.6) {
        guard isMusicEnabled else { return }
        if let mp = musicPlayer, mp.isPlaying { return }
        let trackName = name ?? currentMusicName
        currentMusicName = trackName
        currentMusicExt  = ext
        do {
            let p = try makePlayer(trackName, ext)
            p.numberOfLoops = -1
            p.volume = volume
            p.play()
            musicPlayer = p
        } catch {
            print("Could not start music \(trackName).\(ext): \(error)")
        }
    }

    func stopMusic() {
        musicPlayer?.stop()
        musicPlayer = nil
    }

    // NEW: Pause/Resume
    func pauseMusic() {
        musicPlayer?.pause()
    }

    func resumeMusic() {
        guard isMusicEnabled else { return }
        musicPlayer?.play()
    }

    // MARK: Stop SFX
    func stop(_ name: String, ext: String = "mp3") {
        queue.sync { players[key(name, ext)]?.forEach { $0.stop() } }
    }

    func stopAll() {
        queue.sync { players.values.flatMap { $0 }.forEach { $0.stop() } }
    }

    // MARK: Internals (Bundle file or Data Asset)
    private func makePlayer(_ name: String, _ ext: String) throws -> AVAudioPlayer {
        if let url = Bundle.main.url(forResource: name, withExtension: ext) {
            let p = try AVAudioPlayer(contentsOf: url); p.prepareToPlay(); return p
        }
        if let dataAsset = NSDataAsset(name: name) {
            let p = try AVAudioPlayer(data: dataAsset.data); p.prepareToPlay(); return p
        }
        throw NSError(domain: "SoundManager", code: -1,
                      userInfo: [NSLocalizedDescriptionKey: "Missing sound: \(name).\(ext)"])
    }

    private func key(_ name: String, _ ext: String) -> String { "\(name).\(ext)" }
}
