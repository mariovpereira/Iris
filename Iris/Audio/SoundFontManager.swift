//
//  SoundFontManager.swift
//  Iris
//
//  Created for Iris on 4/4/25.
//

import Foundation
import AVFoundation

/// Manager class for handling SoundFont files and instrument mappings
class SoundFontManager {
    // Path to the SoundFont file
    private var soundFontURL: URL?
    
    // Mapping from instrument names to General MIDI program numbers
    private let instrumentToMIDIProgram: [String: UInt8] = [
        // Piano family (0-7)
        "Acoustic Grand Piano": 0,
        "Piano": 0, // Alias for Acoustic Grand Piano
        "Electric Piano": 4,
        "Organ": 16,
        
        // String family (40-47)
        "Violin": 40,
        "Viola": 41,
        "Cello": 42,
        "Contrabass": 43,
        "Harp": 46,
        
        // Wind family
        "Flute": 73,
        "Clarinet": 71,
        "Oboe": 68,
        "French Horn": 60,
        "Bassoon": 70,
        
        // Brass family
        "Trumpet": 56,
        "Trombone": 57,
        "Tuba": 58,
        
        // Synthetic family
        "Synth Pad": 88,
        "Synth Strings": 51,
        "Ambient Pad": 89,
        "Warm Pad": 89,
        "Choir": 52
    ]
    
    // Category to MIDI bank mapping (Assuming default melodic bank 0 for GM soundfonts)
    // Note: General MIDI typically uses bank 0 (MSB=0, LSB=0) for standard melodic sounds.
    // Bank selection might be more complex depending on the specific SoundFont.
    private let categoryToMIDIBank: [String: (msb: UInt8, lsb: UInt8)] = [
        "Keyboard": (UInt8(kAUSampler_DefaultMelodicBankMSB), 0),
        "String": (UInt8(kAUSampler_DefaultMelodicBankMSB), 0),
        "Wind": (UInt8(kAUSampler_DefaultMelodicBankMSB), 0),
        "Brass": (UInt8(kAUSampler_DefaultMelodicBankMSB), 0),
        "Synthetic": (UInt8(kAUSampler_DefaultMelodicBankMSB), 0) // Adjust if Synths are on different banks
    ]
    
    /// Load the main SoundFont file from the app bundle by loading the default instrument
    func loadMainSoundFont(sampler: AVAudioUnitSampler) throws {
        var loadedSuccessfully = false
        var firstError: Error? = nil
        
        // Define default bank numbers
        let defaultMSB = UInt8(kAUSampler_DefaultMelodicBankMSB)
        let defaultLSB: UInt8 = 0 // Standard LSB for GM melodic bank
        
        // Function to attempt loading the default instrument (Piano)
        func attemptLoad(sampler: AVAudioUnitSampler, url: URL) -> Bool {
            print("Attempting to load default instrument (Program 0) from: \(url.path)")
            do {
                try sampler.loadSoundBankInstrument(
                    at: url,
                    program: 0, // Default Piano
                    bankMSB: defaultMSB,
                    bankLSB: defaultLSB
                )
                print("Successfully loaded default instrument from \(url.path). SoundFont should now be available.")
                soundFontURL = url // Store the URL of the successfully loaded font
                return true
            } catch {
                print("Error loading default instrument from \(url.path): \(error.localizedDescription)")
                if firstError == nil { firstError = error }
                return false
            }
        }
        
        // List all resources in the bundle to debug
        print("📦 Checking bundle resources for SoundFont files...")
        let resourceURLs = Bundle.main.urls(forResourcesWithExtension: "sf2", subdirectory: nil) ?? []
        print("📋 Found \(resourceURLs.count) .sf2 files in bundle:")
        for url in resourceURLs {
            print("   - \(url.lastPathComponent)")
        }
        
        // Check if the Resources directory exists
        if let resourcesURL = Bundle.main.resourceURL?.appendingPathComponent("Resources") {
            if FileManager.default.fileExists(atPath: resourcesURL.path) {
                print("✅ Resources directory exists at: \(resourcesURL.path)")
                
                // Check if SoundFonts directory exists
                let soundFontsURL = resourcesURL.appendingPathComponent("SoundFonts")
                if FileManager.default.fileExists(atPath: soundFontsURL.path) {
                    print("✅ SoundFonts directory exists at: \(soundFontsURL.path)")
                    
                    // List files in SoundFonts directory
                    do {
                        let soundFontFiles = try FileManager.default.contentsOfDirectory(at: soundFontsURL, includingPropertiesForKeys: nil)
                        print("📋 Found \(soundFontFiles.count) files in SoundFonts directory:")
                        for url in soundFontFiles {
                            print("   - \(url.lastPathComponent)")
                        }
                    } catch {
                        print("❌ Error listing SoundFonts directory: \(error.localizedDescription)")
                    }
                } else {
                    print("❌ SoundFonts directory not found at: \(soundFontsURL.path)")
                }
            } else {
                print("❌ Resources directory not found at: \(resourcesURL.path)")
            }
        }
        
        // Try loading FluidR3_GM.sf2 first
        print("🔍 Searching for FluidR3_GM.sf2...")
        if let soundFontPath = Bundle.main.path(forResource: "FluidR3_GM", ofType: "sf2") {
            print("✅ Found FluidR3_GM.sf2 at: \(soundFontPath)")
            let url = URL(fileURLWithPath: soundFontPath)
            if attemptLoad(sampler: sampler, url: url) {
                loadedSuccessfully = true
            }
        } else {
            // Try looking in Resources/SoundFonts directory
            if let resourcesURL = Bundle.main.resourceURL?.appendingPathComponent("Resources/SoundFonts") {
                let fluidSFPath = resourcesURL.appendingPathComponent("FluidR3_GM.sf2").path
                if FileManager.default.fileExists(atPath: fluidSFPath) {
                    print("✅ Found FluidR3_GM.sf2 in Resources/SoundFonts at: \(fluidSFPath)")
                    let url = URL(fileURLWithPath: fluidSFPath)
                    if attemptLoad(sampler: sampler, url: url) {
                        loadedSuccessfully = true
                    }
                } else {
                    print("❌ SoundFont file FluidR3_GM.sf2 not found in Resources/SoundFonts.")
                }
            } else {
                print("❌ SoundFont file FluidR3_GM.sf2 not found in bundle.")
            }
        }
        
        // If first failed, try ChoriumRevA.sf2
        if !loadedSuccessfully {
            print("🔍 Trying alternative SoundFont: ChoriumRevA.sf2")
            if let soundFontPath = Bundle.main.path(forResource: "ChoriumRevA", ofType: "sf2") {
                print("✅ Found ChoriumRevA.sf2 at: \(soundFontPath)")
                let url = URL(fileURLWithPath: soundFontPath)
                if attemptLoad(sampler: sampler, url: url) {
                    loadedSuccessfully = true
                }
            } else {
                print("❌ Alternative SoundFont ChoriumRevA.sf2 not found.")
            }
        }
        
        // If both failed, handle the error / fallback
        if !loadedSuccessfully {
            print("Failed to load any SoundFont file.")
            loadFallbackInstrument(sampler: sampler, error: firstError)
            // Re-throw the error if necessary for AudioEngine to know
            if let error = firstError {
                throw error
            } else {
                throw NSError(domain: "SoundFontManager", code: 2, userInfo: [NSLocalizedDescriptionKey: "No suitable SoundFont file found or loaded."])
            }
        }
    }
    
    /// Fallback action if the SoundFont fails to load
    private func loadFallbackInstrument(sampler: AVAudioUnitSampler, error: Error?) {
        if let error = error {
            print("⚠️ SoundFont loading failed: \(error.localizedDescription)")
        } else {
            print("⚠️ No SoundFont file found.")
        }
        
        print("🔄 Attempting to load built-in instrument as fallback...")
        
        // Try to use the built-in instrument sounds
        // Set program to piano (0) and try to use it
        sampler.sendProgramChange(0, bankMSB: UInt8(kAUSampler_DefaultMelodicBankMSB), bankLSB: 0, onChannel: 0)
        print("✅ Set program to piano (0) as fallback.")
    }
    
    /// Get the URL of the currently loaded SoundFont file
    /// - Returns: The URL of the loaded SoundFont file, if available
    func getSoundFontURL() -> URL? {
        return soundFontURL
    }
    
    /// Get the MIDI program number for a specific instrument
    /// - Parameters:
    ///   - category: The instrument category (currently unused for program lookup)
    ///   - instrument: The instrument name (its rawValue from the Instrument enum)
    /// - Returns: The corresponding MIDI program number
    func getMIDIProgramNumber(category: String, instrument: String) -> UInt8 {
        // Get the MIDI program number for the instrument
        return instrumentToMIDIProgram[instrument] ?? 0 // Default to piano if not found
    }
    
    /// Get the MIDI bank numbers (MSB, LSB) for a specific category
    /// - Parameter category: The instrument category (its rawValue from the InstrumentCategory enum)
    /// - Returns: A tuple containing the MIDI bank MSB and LSB numbers
    func getMIDIBankNumbers(category: String) -> (msb: UInt8, lsb: UInt8) {
        // Get the MIDI bank number for the category
        return categoryToMIDIBank[category] ?? (UInt8(kAUSampler_DefaultMelodicBankMSB), 0) // Default to bank 0 if not found
    }
}
