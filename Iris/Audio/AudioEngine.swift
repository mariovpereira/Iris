//
//  AudioEngine.swift
//  Iris
//
//  Created for Iris on 4/4/25.
//

import Foundation
import AVFoundation

/// Central manager for all audio functionality in Iris
class AudioEngine {
    /// Shared instance for global access (Singleton pattern)
    static let shared = AudioEngine()
    
    // AVFoundation components
    private var avEngine: AVAudioEngine
    private var samplers: [AVAudioUnitSampler] = [AVAudioUnitSampler(), AVAudioUnitSampler(), AVAudioUnitSampler()]
    
    // Separate mixer nodes for each position to create stereo effect
    private var leftMixer: AVAudioMixerNode  // For left sector
    private var centerMixer: AVAudioMixerNode  // For center sector
    private var rightMixer: AVAudioMixerNode  // For right sector
    private var finalMixer: AVAudioMixerNode
    
    private var soundFontManager: SoundFontManager
    
    // Track active notes for each sector
    private var activeNotes: [Int: [UInt8]] = [0: [], 1: [], 2: []]
    
    // Using the instruments defined in IrisConstants
    private var sectorInstruments: [Int: Instrument] {
        return IrisConstants.sectorInstruments
    }
    
    /// Map normalized depth to note (C1-C8)
    private func mapDepthToNote(normalizedDepth: Float) -> (note: Note, proximity: Float) {
        // Depth to note mapping table
        // According to documentation:
        // 1.00 = farthest (maxDepth, 1.8m)
        // 0.00 = closest (minDepth, 0.0m)
        let depthToNoteMap: [(depth: Float, note: Note)] = [
            (1.00, Note(name: "C", octave: 1)),  // Farthest (1.8m)
            (0.85, Note(name: "C", octave: 2)),
            (0.70, Note(name: "C", octave: 3)),
            (0.55, Note(name: "C", octave: 4)),
            (0.40, Note(name: "C", octave: 5)),
            (0.25, Note(name: "C", octave: 6)),
            (0.10, Note(name: "C", octave: 7)),
            (0.00, Note(name: "C", octave: 8))   // Closest (0.0m)
        ]
        
        // Check for exact matches first
        for (depth, note) in depthToNoteMap {
            if normalizedDepth == depth {
                return (note, 1.0)  // Exact match, full volume
            }
        }
        
        // Find the two closest depth values
        var lowerIndex = 0
        var upperIndex = 0
        
        for i in 0..<depthToNoteMap.count-1 {
            if normalizedDepth <= depthToNoteMap[i].depth && normalizedDepth > depthToNoteMap[i+1].depth {
                lowerIndex = i
                upperIndex = i+1
                break
            }
        }
        
        // Calculate how close we are to the lower depth value (proximity)
        let lowerDepth = depthToNoteMap[lowerIndex].depth
        let upperDepth = depthToNoteMap[upperIndex].depth
        let depthRange = lowerDepth - upperDepth
        
        // Avoid division by zero
        if depthRange == 0 {
            return (depthToNoteMap[lowerIndex].note, 1.0)
        }
        
        // Calculate proximity to the lower depth (1.0 means exactly at lower depth, 0.0 means exactly at upper depth)
        let proximity = (normalizedDepth - upperDepth) / depthRange
        
        // Return the note and proximity
        return (depthToNoteMap[lowerIndex].note, proximity)
    }
    
    /// Private initializer to enforce singleton pattern
    private init() {
        // Initialize AVFoundation components
        avEngine = AVAudioEngine()
        
        // Create mixer nodes for each position
        leftMixer = AVAudioMixerNode()
        centerMixer = AVAudioMixerNode()
        rightMixer = AVAudioMixerNode()
        finalMixer = AVAudioMixerNode()
        
        soundFontManager = SoundFontManager()
        
        setupAudioEngine()
    }
    
    /// Set up the audio engine and configure audio session
    private func setupAudioEngine() {
        print("🔄 Setting up audio engine with stereo panning...")
        
        // Configure audio session
        #if os(iOS)
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
            print("✅ iOS Audio session configured successfully")
        } catch {
            print("❌ Error configuring audio session: \(error.localizedDescription)")
        }
        #endif
        
        // Attach all nodes to the engine
        avEngine.attach(leftMixer)
        avEngine.attach(centerMixer)
        avEngine.attach(rightMixer)
        avEngine.attach(finalMixer)
        
        for sampler in samplers {
            avEngine.attach(sampler)
        }
        
        // Set up stereo panning for each mixer
        leftMixer.pan = -0.7  // Left
        centerMixer.pan = 0.0 // Center
        rightMixer.pan = 0.7  // Right
        
        print("🔊 Stereo panning configuration:")
        print("- Left mixer pan: \(leftMixer.pan)")
        print("- Center mixer pan: \(centerMixer.pan)")
        print("- Right mixer pan: \(rightMixer.pan)")
        
        // Connect samplers to their respective position mixers
        avEngine.connect(samplers[0], to: leftMixer, format: nil)
        avEngine.connect(samplers[1], to: centerMixer, format: nil)
        avEngine.connect(samplers[2], to: rightMixer, format: nil)
        
        // Connect all position mixers to the final mixer
        avEngine.connect(leftMixer, to: finalMixer, format: nil)
        avEngine.connect(centerMixer, to: finalMixer, format: nil)
        avEngine.connect(rightMixer, to: finalMixer, format: nil)
        
        // Connect final mixer to output
        avEngine.connect(finalMixer, to: avEngine.outputNode, format: nil)
        
        // Set volume levels
        leftMixer.volume = 1.0
        centerMixer.volume = 1.0
        rightMixer.volume = 1.0
        finalMixer.volume = 0.8  // Slightly lower master volume to avoid clipping
        
        print("🔊 Audio routing: Samplers → Position Mixers (L/C/R) → Final Mixer → Output")
        
        // Start the engine
        do {
            try avEngine.start()
            print("✅ Audio engine started successfully. Running: \(avEngine.isRunning)")
        } catch {
            print("❌ Error starting audio engine: \(error.localizedDescription)")
            
            // Try alternative setup
            print("🔄 Attempting alternative engine setup...")
            do {
                // Reset connections
                for sampler in samplers {
                    avEngine.disconnectNodeOutput(sampler)
                }
                avEngine.disconnectNodeOutput(leftMixer)
                avEngine.disconnectNodeOutput(centerMixer)
                avEngine.disconnectNodeOutput(rightMixer)
                
                // Create explicit format
                let format = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 2)
                
                // Reconnect with explicit format
                avEngine.connect(samplers[0], to: leftMixer, format: format)
                avEngine.connect(samplers[1], to: centerMixer, format: format)
                avEngine.connect(samplers[2], to: rightMixer, format: format)
                
                avEngine.connect(leftMixer, to: finalMixer, format: format)
                avEngine.connect(centerMixer, to: finalMixer, format: format)
                avEngine.connect(rightMixer, to: finalMixer, format: format)
                
                avEngine.connect(finalMixer, to: avEngine.outputNode, format: format)
                
                // Try starting again
                try avEngine.start()
                print("✅ Audio engine started with alternative setup. Running: \(avEngine.isRunning)")
            } catch {
                print("❌ Alternative setup also failed: \(error.localizedDescription)")
            }
        }
        
        // Load default SoundFont and instruments
        loadDefaultSoundFont()
    }
    
    /// Load the default SoundFont and set up default instruments for each sector
    private func loadDefaultSoundFont() {
        do {
            for sector in 0..<samplers.count {
                try soundFontManager.loadMainSoundFont(sampler: samplers[sector])
                
                if let instrument = sectorInstruments[sector] {
                    print("Setting default instrument for sector \(sector): \(instrument.rawValue)")
                    changeInstrument(instrument: instrument, forSector: sector)
                }
            }
        } catch {
            print("❌ Failed to complete initial SoundFont loading: \(error.localizedDescription)")
        }
    }
    
    /// Play a note based on normalized depth for a specific sector
    /// - Parameters:
    ///   - normalizedDepth: The normalized depth value (0.0 - 1.0)
    ///   - sector: The sector (0 = left, 1 = center, 2 = right)
    ///   - velocity: The velocity factor (0.0 - 1.0, default 0.7) that scales the note's volume
    func playNoteForDepth(normalizedDepth: Float, sector: Int, velocity: Float = 0.7) {
        guard sector >= 0 && sector < 3 else {
            print("⚠️ Invalid sector: \(sector). Must be 0, 1, or 2.")
            return
        }
        
        // Stop any currently playing notes in this sector
        stopAllNotesInSector(sector)
        
        // Map the normalized depth to a note and proximity
        let (note, proximity) = mapDepthToNote(normalizedDepth: normalizedDepth)
        
        // Calculate velocity for the main note based on proximity and provided velocity factor
        // Convert from 0.0-1.0 scale to MIDI velocity (0-127)
        let baseVelocity = UInt8(min(127, max(40, velocity * 127.0)))
        let mainVelocity = UInt8(min(127, max(40, Float(baseVelocity) * proximity)))
        
        // Get the MIDI note number
        let midiNote = note.midiNoteNumber
        
        // Get description of the sector
        let sectorDescription = ["left", "center", "right"][sector]
        
        print("🎵 Playing \(note.displayName) with velocity \(mainVelocity) on \(sectorDescription) sector, normalized depth: \(normalizedDepth)")
        
        // Ensure audio engine is running
        if !avEngine.isRunning {
            print("⚠️ Audio engine not running! Attempting to restart...")
            do {
                try avEngine.start()
                print("✅ Audio engine restarted")
            } catch {
                print("❌ Failed to restart audio engine: \(error.localizedDescription)")
                return
            }
        }
        
        // Play the note
        samplers[sector].startNote(midiNote, withVelocity: mainVelocity, onChannel: 0)
        activeNotes[sector]?.append(midiNote)
        
        // If the proximity is not close to 1.0 (not an exact match), play a nearby note as well
        if proximity < 0.8 {
            // Determine if we need the note above or below based on proximity
            let secondNote: UInt8 = proximity < 0.5 ? midiNote + 12 : midiNote - 12
            // The second note is quieter, with volume inversely proportional to proximity
            let secondVelocity = UInt8(min(100, max(30, Float(baseVelocity) * (1.0 - proximity))))
            
            // Only play if in valid MIDI range (0-127)
            if secondNote >= 0 && secondNote <= 127 {
                print("🎵 Playing chord with second note \(secondNote) at velocity \(secondVelocity)")
                samplers[sector].startNote(secondNote, withVelocity: secondVelocity, onChannel: 0)
                activeNotes[sector]?.append(secondNote)
            }
        }
    }
    
    /// Stop all playing notes in a specific sector
    /// - Parameter sector: The sector (0 = left, 1 = center, 2 = right)
    func stopAllNotesInSector(_ sector: Int) {
        guard sector >= 0 && sector < 3 else { return }
        
        for note in activeNotes[sector] ?? [] {
            samplers[sector].stopNote(note, onChannel: 0)
        }
        activeNotes[sector]?.removeAll()
    }
    
    /// Stop all playing notes across all sectors
    func stopAllNotes() {
        for sector in 0..<3 {
            stopAllNotesInSector(sector)
        }
    }
    
    /// Change the instrument for a specific sector
    /// - Parameters:
    ///   - instrument: The instrument to use
    ///   - sector: The sector to change (0 = left, 1 = center, 2 = right)
    func changeInstrument(instrument: Instrument, forSector sector: Int) {
        guard sector >= 0 && sector < 3 else { return }
        
        let category = instrument.category.rawValue
        let instrumentName = instrument.rawValue
        
        let programNumber = soundFontManager.getMIDIProgramNumber(category: category, instrument: instrumentName)
        let bankNumbers = soundFontManager.getMIDIBankNumbers(category: category)
        
        print("Changing instrument on sector \(sector): Category=\(category), Instrument=\(instrumentName)")
        print("Bank MSB=\(bankNumbers.msb), LSB=\(bankNumbers.lsb), Program=\(programNumber)")
        
        if let soundFontURL = soundFontManager.getSoundFontURL() {
            do {
                try samplers[sector].loadSoundBankInstrument(
                    at: soundFontURL,
                    program: programNumber,
                    bankMSB: bankNumbers.msb,
                    bankLSB: bankNumbers.lsb
                )
                print("Successfully loaded instrument from SoundFont for sector \(sector)")
            } catch {
                print("Error loading instrument from SoundFont: \(error.localizedDescription)")
            }
        }
    }
}