//
//  InstrumentType.swift
//  Iris
//
//  Created for Iris on 4/4/25.
//

import Foundation

/// Represents an instrument category
enum InstrumentCategory: String, CaseIterable, Identifiable {
    case string = "String"
    case wind = "Wind"
    case brass = "Brass"
    case keyboard = "Keyboard"
    case synthetic = "Synthetic"
    
    var id: String { rawValue }
    
    /// Get all instruments in this category
    var instruments: [Instrument] {
        Instrument.allCases.filter { $0.category == self }
    }
    
    /// Get the display name for this category
    var displayName: String {
        rawValue
    }
}

/// Represents a specific instrument
enum Instrument: String, CaseIterable, Identifiable {
    // String instruments
    case violin = "Violin"
    case viola = "Viola"
    case cello = "Cello"
    case contrabass = "Contrabass"
    case harp = "Harp"
    
    // Wind instruments
    case flute = "Flute"
    case clarinet = "Clarinet"
    case oboe = "Oboe"
    case frenchHorn = "French Horn"
    case bassoon = "Bassoon"
    
    // Brass instruments
    case trumpet = "Trumpet"
    case trombone = "Trombone"
    case tuba = "Tuba"
    
    // Keyboard instruments
    case piano = "Piano"
    case organ = "Organ"
    case electricPiano = "Electric Piano"
    
    // Synthetic instruments
    case synthPad = "Synth Pad"
    case synthStrings = "Synth Strings"
    case ambientPad = "Ambient Pad"
    case warmPad = "Warm Pad"
    case choir = "Choir"
    
    var id: String { rawValue }
    
    /// Get the category for this instrument
    var category: InstrumentCategory {
        switch self {
        case .violin, .viola, .cello, .contrabass, .harp:
            return .string
        case .flute, .clarinet, .oboe, .frenchHorn, .bassoon:
            return .wind
        case .trumpet, .trombone, .tuba:
            return .brass
        case .piano, .organ, .electricPiano:
            return .keyboard
        case .synthPad, .synthStrings, .ambientPad, .warmPad, .choir:
            return .synthetic
        }
    }
    
    /// Get the display name for this instrument
    var displayName: String {
        rawValue
    }
    
    /// Get the MIDI program number for this instrument
    var midiProgramNumber: UInt8 {
        switch self {
        // Piano family (0-7)
        case .piano: return 0 // Acoustic Grand Piano
        case .electricPiano: return 4 // Electric Piano 1
        case .organ: return 16 // Hammond Organ
            
        // String family (40-47)
        case .violin: return 40
        case .viola: return 41
        case .cello: return 42
        case .contrabass: return 43
        case .harp: return 46
            
        // Wind family
        case .flute: return 73
        case .clarinet: return 71
        case .oboe: return 68
        case .frenchHorn: return 60
        case .bassoon: return 70
            
        // Brass family
        case .trumpet: return 56
        case .trombone: return 57
        case .tuba: return 58
            
        // Synthetic family
        case .synthPad: return 88
        case .synthStrings: return 51
        case .ambientPad: return 89
        case .warmPad: return 89
        case .choir: return 52
        }
    }
}

/// Extension to provide helper methods for working with instruments
extension Instrument {
    /// Get all instruments in a specific category
    /// - Parameter category: The category to filter by
    /// - Returns: An array of instruments in the specified category
    static func instruments(in category: InstrumentCategory) -> [Instrument] {
        return allCases.filter { $0.category == category }
    }
    
    /// Get the default instrument for a specific category
    /// - Parameter category: The category to get the default instrument for
    /// - Returns: The default instrument for the specified category
    static func defaultInstrument(for category: InstrumentCategory) -> Instrument {
        switch category {
        case .string: return .violin
        case .wind: return .flute
        case .brass: return .trumpet
        case .keyboard: return .piano
        case .synthetic: return .synthPad
        }
    }
}
