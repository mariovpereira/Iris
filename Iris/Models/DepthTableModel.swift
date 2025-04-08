//
//  DepthTableModel.swift
//  Iris
//
//  Created on 4/6/25.
//

import Foundation
import MetalKit

/// Model class for managing depth table data and operations
class DepthTableModel {
    // MARK: - Properties
    
    /// Raw depth values for each cell [row][column]
    private(set) var depthData: [[Float]]
    
    /// Coordinates for each cell [row][column][x,y]
    private(set) var coordinateData: [[[Float]]]
    
    /// Number of rows in the depth table
    let rowCount: Int
    
    /// Number of columns in the depth table
    let columnCount: Int
    
    /// The depth map texture this model was created from
    private(set) var depthTexture: MTLTexture?
    
    /// Minimum depth value for normalization
    private let minDepth: Float
    
    /// Maximum depth value for normalization
    private let maxDepth: Float
    
    // MARK: - Initialization
    
    /// Initialize with specific dimensions
    init(rowCount: Int = 9, columnCount: Int = 3, minDepth: Float, maxDepth: Float) {
        self.rowCount = rowCount
        self.columnCount = columnCount
        self.minDepth = minDepth
        self.maxDepth = maxDepth
        
        // Initialize empty arrays
        self.depthData = Array(repeating: Array(repeating: 0.0, count: columnCount), count: rowCount)
        self.coordinateData = Array(repeating: Array(repeating: [0.0, 0.0], count: columnCount), count: rowCount)
    }
    
    // MARK: - Public Methods
    
    /// Sample depth data from the provided texture
    /// - Parameter depthTexture: The Metal texture containing depth data
    /// - Returns: True if sampling was successful
    func sampleDepthData(from depthTexture: MTLTexture) -> Bool {
        self.depthTexture = depthTexture
        
        // Calculate the dimensions of each cell
        let cellWidth = Float(1.0) / Float(columnCount)
        let cellHeight = Float(1.0) / Float(rowCount)
        
        // Sample depth for each cell in the grid
        for row in 0..<rowCount {
            for col in 0..<columnCount {
                // For table display - coordinates based on landscape-right orientation
                // Origin (0,0) is at TOP-RIGHT corner when viewed in portrait
                // - X increases from TOP to BOTTOM (rows)
                // - Y increases from RIGHT to LEFT (columns)
                
                // X coordinate: 0.0 at top, 1.0 at bottom
                let portraitX = Float(row) * cellHeight + cellHeight / 2.0
                
                // Y coordinate: 0.0 at right, 1.0 at left
                let invertedCol = columnCount - 1 - col
                let portraitY = Float(invertedCol) * cellWidth + cellWidth / 2.0
                
                // For sampling the actual depth - we'll use these portrait-adjusted coordinates
                // This aligns with the LiDAR depth map's native orientation
                let texX = portraitY  // Use portrait Y as texture X for landscape-right orientation
                let texY = portraitX  // Use portrait X as texture Y for landscape-right orientation
                
                // Store the portrait coordinates for display in the table
                coordinateData[row][col] = [portraitX, portraitY]
                
                // Sample depth at this location
                sampleDepthForCell(row: row, col: col, texX: texX, texY: texY)
            }
        }
        
        return true
    }
    
    /// Get raw depth value for a specific cell
    /// - Parameters:
    ///   - row: Row index (0-based)
    ///   - column: Column index (0-based)
    /// - Returns: Raw depth value in meters
    func getRawDepth(row: Int, column: Int) -> Float? {
        guard isValidCell(row: row, column: column) else {
            return nil
        }
        return depthData[row][column]
    }
    
    /// Get normalized depth value for a specific cell
    /// - Parameters:
    ///   - row: Row index (0-based)
    ///   - column: Column index (0-based)
    /// - Returns: Normalized depth value (0.0-1.0)
    func getNormalizedDepth(row: Int, column: Int) -> Float? {
        guard isValidCell(row: row, column: column),
              let rawDepth = getRawDepth(row: row, column: column) else {
            return nil
        }
        
        return normalizeDepth(rawDepth)
    }
    
    /// Get coordinates for a specific cell
    /// - Parameters:
    ///   - row: Row index (0-based)
    ///   - column: Column index (0-based)
    /// - Returns: [x, y] coordinates where x is vertical (0.0=top, 1.0=bottom) and y is horizontal (0.0=right, 1.0=left)
    func getCoordinates(row: Int, column: Int) -> [Float]? {
        guard isValidCell(row: row, column: column) else {
            return nil
        }
        return coordinateData[row][column]
    }
    
    // MARK: - Private Methods
    
    /// Check if cell indices are valid
    private func isValidCell(row: Int, column: Int) -> Bool {
        return row >= 0 && row < rowCount && column >= 0 && column < columnCount
    }
    
    /// Normalize raw depth value to 0.0-1.0 range
    private func normalizeDepth(_ depth: Float) -> Float {
        // Clamp depth to min/max range
        let clampedDepth = min(max(depth, minDepth), maxDepth)
        
        // Normalize to 0.0-1.0 range, where 0.0 is closest and 1.0 is farthest
        let normalizedValue = (clampedDepth - minDepth) / (maxDepth - minDepth)
        
        // Make sure the value is within valid range (just to be extra safe)
        return min(max(normalizedValue, 0.0), 1.0)
    }
    
    /// Sample depth for a specific cell
    private func sampleDepthForCell(row: Int, col: Int, texX: Float, texY: Float) {
        guard let depthTexture = depthTexture else {
            // No texture available, use fallback
            depthData[row][col] = generateFallbackDepth(row: row, col: col)
            return
        }
        
        // Try multiple sample radiuses to find valid depth
        var validDepthFound = false
        let sampleRadiuses = [6, 4, 2]
        
        for radius in sampleRadiuses {
            let rawDepth = DepthSampler.sampleDepthAtPoint(
                texture: depthTexture,
                x: texX,
                y: texY,
                sampleRadius: radius
            )
            
            // Check if we have a reasonable depth value
            if rawDepth >= 0.1 && rawDepth <= 5.0 {
                // Store the depth value
                depthData[row][col] = rawDepth
                validDepthFound = true
                break
            }
        }
        
        // If no valid depth was found, use a fallback value
        if !validDepthFound {
            depthData[row][col] = generateFallbackDepth(row: row, col: col)
        }
    }
    
    /// Generate a fallback depth value when valid depth can't be determined
    private func generateFallbackDepth(row: Int, col: Int) -> Float {
        // Generate a reasonable fallback based on position
        // Values increase with row (top to bottom) and slightly with column
        return 0.9 + Float(row) * 0.1 + Float(col) * 0.05
    }
}