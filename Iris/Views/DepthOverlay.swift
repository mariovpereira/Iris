/*
See the LICENSE.txt file for this sample's licensing information.

Abstract:
A view that shows the depth image on top of the color image with a slider
 to adjust the depth layer's opacity.
*/

import SwiftUI

struct DepthOverlay: View {
    
    @ObservedObject var manager: CameraManager
    @State private var opacity = Float(0.90) // Default value set to 0.90 as per requirements
    @Binding var maxDepth: Float
    @Binding var minDepth: Float
    
    // Public initializer
    public init(manager: CameraManager, maxDepth: Binding<Float>, minDepth: Binding<Float>) {
        self.manager = manager
        self._maxDepth = maxDepth
        self._minDepth = minDepth
    }
    
    var body: some View {
        if manager.dataAvailable {
            ZStack {
                MetalTextureViewColor(
                    rotationAngle: rotationAngle,
                    capturedData: manager.capturedData
                )
                MetalTextureDepthView(
                    rotationAngle: rotationAngle,
                    maxDepth: $maxDepth,
                    minDepth: $minDepth,
                    capturedData: manager.capturedData
                )
                .opacity(Double(opacity))
            }
        }
    }
}
