//
//  SingleUpScan.swift
//  Iris
//
//  Created on 4/6/25.
//

import SwiftUI
import MetalKit

/// Component that handles the single up scan functionality
struct SingleUpScan: View {
    // MARK: - Properties
    let manager: CameraManager
    let depthTable: DepthTableModel
    
    /// Duration of the scan in seconds
    let scanDuration: Double = 5.0
    
    /// Current active cell row being played (nil if not playing)
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
        // Center column index
        let columnIndex = depthTable.columnCount / 2
        
        // Stop any currently playing audio
        audioEngine.stopAllNotes()
        
        // Calculate timing for each cell
        let cellDuration = scanDuration / Double(depthTable.rowCount)
        
        // Play notes from bottom to top (reverse order of rows)
        for i in 0..<depthTable.rowCount {
            // Calculate row index (starting from bottom)
            let rowIndex = depthTable.rowCount - 1 - i
            
            // Schedule note for this cell
            let delay = cellDuration * Double(i)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                if let normalizedDepth = depthTable.getNormalizedDepth(row: rowIndex, column: columnIndex) {
                    // Calculate note velocity (0.5-1.0) based on normalized depth
                    // Closer objects (smaller depth) have higher velocity
                    let velocity = 0.5 + (0.5 * (1.0 - normalizedDepth))
                    
                    // Update the active row and highlight intensity
                    activeRow = rowIndex
                    highlightIntensity = velocity
                    
                    // Play the note
                    audioEngine.playNoteForDepth(normalizedDepth: normalizedDepth, 
                                                sector: columnIndex, 
                                                velocity: velocity)
                }
            }
        }
        
        // End the scan after duration
        DispatchQueue.main.asyncAfter(deadline: .now() + scanDuration) {
            // Clear highlighting
            activeRow = nil
            highlightIntensity = 0
            
            // Stop all audio
            audioEngine.stopAllNotes()
            
            // Notify completion
            onScanComplete?()
        }
    }
}