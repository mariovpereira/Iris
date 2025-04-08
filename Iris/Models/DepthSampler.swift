//
//  DepthSampler.swift
//  Iris
//
//  Created for Iris on 4/4/25.
//

import Foundation
import MetalKit

/// Helper class for sampling depth data from Metal textures
class DepthSampler {
    
    /// Sample depth at a specific texture coordinate
    /// - Parameters:
    ///   - texture: The Metal texture containing depth data
    ///   - x: Normalized x coordinate (0.0 to 1.0, left to right)
    ///   - y: Normalized y coordinate (0.0 to 1.0, top to bottom)
    ///   - sampleRadius: Radius for sampling multiple points around the target
    /// - Returns: The average depth value at the specified point
    /// - Note: Using standard texture coordinates with origin (0,0) at the top-left corner
    static func sampleDepthAtPoint(
        texture: MTLTexture,
        x: Float,
        y: Float,
        sampleRadius: Int = 4
    ) -> Float {
        // Calculate actual texture coordinates
        // Clamp to 0.0-1.0 range
        let texX = min(max(x, 0.0), 1.0)
        let texY = min(max(y, 0.0), 1.0)
        
        // Using standard texture coordinates that match Metal's coordinates:
        // - X increases from left (0.0) to right (1.0)
        // - Y increases from top (0.0) to bottom (1.0)
        
        // No conversion needed as we're using the same system as Metal
        let adjustedTexX = texX  // X stays as X
        let adjustedTexY = texY  // Y stays as Y
        
        // Get pixel coordinates
        let pixelX = Int(adjustedTexX * Float(texture.width))
        let pixelY = Int(adjustedTexY * Float(texture.height))
        
        // Sample multiple points around the target for more stable reading
        var sum: Float = 0.0
        var count: Int = 0
        let offset = sampleRadius  // Sample in a grid
        
        for dy in -offset...offset {
            for dx in -offset...offset {
                let x = pixelX + dx
                let y = pixelY + dy
                
                // Check bounds
                if x >= 0 && x < texture.width && y >= 0 && y < texture.height {
                    // Sample depth at this point
                    if let depthValue = sampleDepthTexture(texture: texture, x: x, y: y) {
                        sum += depthValue
                        count += 1
                    }
                }
            }
        }
        
        // Calculate average depth
        if count > 0 {
            return sum / Float(count)
        } else {
            return 0.0
        }
    }
    
    /// Sample a depth texture at a specific pixel
    /// - Parameters:
    ///   - texture: The depth texture to sample
    ///   - x: The x pixel coordinate (in Metal texture coordinates)
    ///   - y: The y pixel coordinate (in Metal texture coordinates)
    /// - Returns: The depth value at the specified pixel, or nil if unavailable
    /// - Note: This function uses the Metal texture coordinate system internally, not our rotated coordinate system
    static func sampleDepthTexture(texture: MTLTexture, x: Int, y: Int) -> Float? {
        let region = MTLRegion(origin: MTLOrigin(x: x, y: y, z: 0),
                               size: MTLSize(width: 1, height: 1, depth: 1))
        
        // The LiDAR depth data is stored as 16-bit float (Float16)
        // We need to handle it properly to get correct depth values
        if texture.pixelFormat == .r16Float {
            var depthValue: Float16 = Float16(0.0)
            let bytesPerRow = MemoryLayout<Float16>.size
            
            texture.getBytes(&depthValue, bytesPerRow: bytesPerRow, from: region, mipmapLevel: 0)
            
            // Convert Float16 to Float and multiply by 1000 to get depth in meters
            // The LiDAR depth is typically in meters but might need scaling
            let depth = Float(depthValue)
            
            // Ensure we have valid depth data (discard very small/invalid values)
            if depth < 0.001 {
                return nil
            }
            
            // The depth may need to be scaled - Apple's LiDAR returns values in meters
            return depth
        } else {
            // Handle standard 32-bit float depth format
            var depthValue: Float = 0.0
            let bytesPerRow = MemoryLayout<Float>.size
            
            texture.getBytes(&depthValue, bytesPerRow: bytesPerRow, from: region, mipmapLevel: 0)
            
            // Ensure we have valid depth data (discard very small/invalid values)
            if depthValue < 0.001 {
                return nil
            }
            
            return depthValue
        }
    }
    
    /// Normalize a depth value based on min and max depth range
    /// - Parameters:
    ///   - depth: The raw depth value in meters
    ///   - minDepth: The minimum depth value (0.0m by default)
    ///   - maxDepth: The maximum depth value (1.8m by default)
    /// - Returns: A normalized depth value between 0.0 and 1.0
    static func normalizeDepth(_ depth: Float, minDepth: Float, maxDepth: Float) -> Float {
        // Normalized depth value between 0.0 and 1.0
        // According to the documentation:
        // 1.0 = farthest distance (maxDepth)
        // 0.0 = closest distance (minDepth)
        
        // We need to clamp depth to the valid range
        let clampedDepth = min(maxDepth, max(minDepth, depth))
        
        // Calculate normalized value from 0.0 to 1.0
        // where 0.0 = minDepth and 1.0 = maxDepth
        let normalizedValue = (clampedDepth - minDepth) / (maxDepth - minDepth)
        
        // Return the normalized value (we don't invert it anymore)
        return normalizedValue
    }
}