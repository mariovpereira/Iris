//
//  Note.swift
//  Iris
//
//  Created for Iris on 4/4/25.
//

import Foundation

/// Represents a musical note with a name and octave
struct Note: Identifiable, Equatable, Hashable {
    /// Unique identifier for the note
    var id: String { "\(name)\(octave)" }
    
    /// The name of the note (e.g., "C", "F#")
    let name: String
    
    /// The octave number (e.g., 4 for middle C)
    let octave: Int
    
    /// The frequency of the note in Hz
    var frequency: Double {
        // A4 = 440Hz
        // Each semitone is a factor of 2^(1/12)
        // C4 is 9 semitones below A4
        
        // Calculate semitones from A4
        let semitonesFromA4 = semitonesFrom(referenceName: "A", referenceOctave: 4)
        
        // Calculate frequency using the formula: f = 440 * 2^(n/12)
        // where n is the number of semitones from A4
        return 440.0 * pow(2.0, Double(semitonesFromA4) / 12.0)
    }
    
    /// The MIDI note number (0-127)
    var midiNoteNumber: UInt8 {
        // C4 (middle C) is MIDI note 60
        // Each octave is 12 semitones
        return UInt8((octave + 1) * 12 + semitoneOffset)
    }
    
    /// The display name of the note (e.g., "C4")
    var displayName: String {
        return "\(name)\(octave)"
    }
    
    /// The semitone offset of the note from C
    private var semitoneOffset: Int {
        switch name {
        case "C": return 0
        case "C#", "Db": return 1
        case "D": return 2
        case "D#", "Eb": return 3
        case "E": return 4
        case "F": return 5
        case "F#", "Gb": return 6
        case "G": return 7
        case "G#", "Ab": return 8
        case "A": return 9
        case "A#", "Bb": return 10
        case "B": return 11
        default: return 0
        }
    }
    
    /// Calculate the number of semitones from a reference note
    /// - Parameters:
    ///   - referenceName: The name of the reference note
    ///   - referenceOctave: The octave of the reference note
    /// - Returns: The number of semitones from the reference note (positive or negative)
    private func semitonesFrom(referenceName: String, referenceOctave: Int) -> Int {
        // Calculate the semitone offset of the reference note from C
        var referenceSemitoneOffset = 0
        switch referenceName {
        case "C": referenceSemitoneOffset = 0
        case "C#", "Db": referenceSemitoneOffset = 1
        case "D": referenceSemitoneOffset = 2
        case "D#", "Eb": referenceSemitoneOffset = 3
        case "E": referenceSemitoneOffset = 4
        case "F": referenceSemitoneOffset = 5
        case "F#", "Gb": referenceSemitoneOffset = 6
        case "G": referenceSemitoneOffset = 7
        case "G#", "Ab": referenceSemitoneOffset = 8
        case "A": referenceSemitoneOffset = 9
        case "A#", "Bb": referenceSemitoneOffset = 10
        case "B": referenceSemitoneOffset = 11
        default: referenceSemitoneOffset = 0
        }
        
        // Calculate the absolute semitone positions
        let referenceSemitones = referenceOctave * 12 + referenceSemitoneOffset
        let thisSemitones = octave * 12 + semitoneOffset
        
        // Return the difference
        return thisSemitones - referenceSemitones
    }
}

/// Extension to create common notes
extension Note {
    /// Create a C note with the specified octave
    /// - Parameter octave: The octave number
    /// - Returns: A C note in the specified octave
    static func C(_ octave: Int) -> Note {
        return Note(name: "C", octave: octave)
    }
    
    /// Create all C notes from C1 to C8
    /// - Returns: An array of C notes from C1 to C8
    static func allCNotes() -> [Note] {
        return (1...8).map { Note(name: "C", octave: $0) }
    }
}
