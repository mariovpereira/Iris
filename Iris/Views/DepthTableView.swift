//
//  DepthTableView.swift
//  Iris
//
//  Created on 4/6/25.
//

import SwiftUI
import MetalKit

/// View for displaying the depth table grid
struct DepthTableView: View {
    // MARK: - Properties
    let manager: CameraManager
    let depthTable: DepthTableModel
    
    /// Optional highlight configuration for a specific cell or row
    var highlightCell: (row: Int, column: Int, intensity: Float)?
    
    /// Whether to highlight the entire row instead of just a single cell
    var highlightEntireRow: Bool = false
    
    // MARK: - Body
    var body: some View {
        GeometryReader { tableGeometry in
            // Use let statements to break up calculations
            let aspectRatio = self.calcAspect(orientation: self.viewOrientation, texture: manager.capturedData.depth)
            let displayWidth = tableGeometry.size.width
            let displayHeight = displayWidth / aspectRatio
            
            // Grid layout (maintain the original position to overlay the depth view)
            ZStack {
                // Background for the grid
                Rectangle()
                    .fill(Color.black.opacity(0.2))
                    .frame(width: displayWidth, height: displayHeight)
                
                // Grid rows with depth values
                GridRows(
                    depthTable: depthTable,
                    highlightCell: highlightCell,
                    highlightEntireRow: highlightEntireRow
                )
                .frame(width: displayWidth, height: displayHeight)
            }
            .position(x: tableGeometry.size.width/2, y: tableGeometry.size.height/2)
            .overlay(
                // Dimensions debug text
                VStack {
                    Spacer()
                    Text(String(format: "Grid: %.0f×%.0f", displayWidth, displayHeight))
                        .font(.system(size: 8))
                        .foregroundColor(.yellow)
                        .padding(2)
                        .background(Color.black)
                }
            )
        }
    }
}

// MARK: - Grid Rows

struct GridRows: View {
    let depthTable: DepthTableModel
    var highlightCell: (row: Int, column: Int, intensity: Float)?
    var highlightEntireRow: Bool = false
    
    var body: some View {
        VStack(spacing: 0) {
            ForEach(0..<depthTable.rowCount, id: \.self) { row in
                GridRow(
                    row: row,
                    depthTable: depthTable,
                    highlightCell: highlightCell,
                    highlightEntireRow: highlightEntireRow
                )
            }
        }
    }
}

// MARK: - Grid Row

struct GridRow: View {
    let row: Int
    let depthTable: DepthTableModel
    var highlightCell: (row: Int, column: Int, intensity: Float)?
    var highlightEntireRow: Bool = false
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(0..<depthTable.columnCount, id: \.self) { col in
                GridCell(
                    row: row,
                    col: col,
                    depthTable: depthTable,
                    isHighlighted: highlightEntireRow ? highlightCell?.row == row : (highlightCell?.row == row && highlightCell?.column == col),
                    highlightIntensity: highlightCell?.intensity ?? 0
                )
            }
        }
    }
}

// MARK: - Grid Cell

struct GridCell: View {
    let row: Int
    let col: Int
    let depthTable: DepthTableModel
    let isHighlighted: Bool
    let highlightIntensity: Float
    
    var body: some View {
        Rectangle()
            .strokeBorder(Color.white, lineWidth: 1)
            .background(
                // Highlight the cell if it's the current cell being played
                isHighlighted ? Color.yellow.opacity(Double(highlightIntensity)) : Color.clear
            )
            .overlay(
                VStack {
                    if let depth = depthTable.getRawDepth(row: row, column: col) {
                        Text("D: \(String(format: "%.2f", depth))m")
                            .font(.system(size: 8))
                            .foregroundColor(.white)
                    }
                    
                    if let normalizedDepth = depthTable.getNormalizedDepth(row: row, column: col) {
                        Text("N: \(String(format: "%.2f", normalizedDepth))")
                            .font(.system(size: 8))
                            .foregroundColor(.white)
                    }
                    
                    if let coords = depthTable.getCoordinates(row: row, column: col) {
                        Text("X: \(String(format: "%.2f", coords[0]))")
                            .font(.system(size: 8))
                            .foregroundColor(.white)
                        
                        Text("Y: \(String(format: "%.2f", coords[1]))")
                            .font(.system(size: 8))
                            .foregroundColor(.white)
                    }
                }
            )
    }
}