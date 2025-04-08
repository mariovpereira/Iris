//
//  FullUpScan.swift
//  Iris
//
//  Created on 4/6/25.
//

import SwiftUI
import MetalKit

/// Component that handles the full up scan functionality
/// Plays notes for all columns in each row simultaneously, moving from bottom to top
struct FullUpScan: View {
    // MARK: - Properties
    let manager: CameraManager
    let depthTable: DepthTableModel
    
    /// Duration of the scan in seconds
    let scanDuration: Double = IrisConstants.fullUpScanDuration
    
    /// Current active row being played (nil if not playing)
    @Binding var activeRow: Int?
    
    /// Current cell highlight intensity (0.0-1.0)
    @Binding var highlightIntensity: Float
    
    /// Function to call when scan completes
    var onScanComplete: (() -> Void)?
    
    /// Audio engine for playing sounds
    private let audioEngine = AudioEngine.shared
    
    // MARK: - Body
    var body: some View {
        // This view doesn't have visual elements, it just handles the scan logic
        Color.clear
            .frame(width: 0, height: 0)
            .onAppear {
                startScan()
            }
    }
    
    // MARK: - Methods
    
    /// Start the scan animation from bottom to top
    private func startScan() {
        // Stop any currently playing audio
        audioEngine.stopAllNotes()
        
        // Calculate timing for each row
        let rowDuration = scanDuration / Double(depthTable.rowCount)
        
        // Play notes from bottom to top (reverse order of rows)
        for i in 0..<depthTable.rowCount {
            // Calculate row index (starting from bottom)
            let rowIndex = depthTable.rowCount - 1 - i
            
            // Schedule notes for this row
            let delay = rowDuration * Double(i)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                playNotesForRow(rowIndex: rowIndex)
                
                // Update the active row for highlighting
                activeRow = rowIndex
            }
        }
        
        // End the scan after duration
        DispatchQueue.main.asyncAfter(deadline: .now() + scanDuration) {
            // Clear highlighting
            activeRow = nil
            
            // Stop all audio
            audioEngine.stopAllNotes()
            
            // Notify completion
            onScanComplete?()
        }
    }
    
    /// Play notes for all sectors in a specific row
    private func playNotesForRow(rowIndex: Int) {
        // Stop any currently playing notes
        audioEngine.stopAllNotes()
        
        // Play notes for each column in the row
        for column in 0..<depthTable.columnCount {
            if let normalizedDepth = depthTable.getNormalizedDepth(row: rowIndex, column: column) {
                // Calculate note velocity based on depth (closer objects have higher velocity)
                let velocity = 0.5 + (0.5 * (1.0 - normalizedDepth))
                
                // Play note for this sector
                audioEngine.playNoteForDepth(
                    normalizedDepth: normalizedDepth,
                    sector: column,
                    velocity: velocity
                )
                
                // Use highest velocity for highlighting intensity
                if velocity > highlightIntensity {
                    highlightIntensity = velocity
                }
            }
        }
    }
}