//
//  IrisMainView.swift
//  Iris
//
//  Created on 4/6/25.
//

import SwiftUI
import MetalKit

/// Constants for the Iris application
struct IrisConstants {
    // Table dimensions
    static let tableRowCount = 9
    static let tableColumnCount = 3
    
    // Scan durations
    static let singleUpScanDuration = 5.0 // seconds
    static let fullUpScanDuration = 5.0 // seconds
    
    // UI constants
    static let scanRectHeight: CGFloat = 0.05  // 5% of screen height
    static let borderColor = Color.white
    static let borderWidth: CGFloat = 1.0
    
    // Depth thresholds
    static let depthChangeThreshold: Float = 0.1 // Minimum change to trigger new note
    
    // Instrument mapping for sectors
    static let sectorInstruments: [Int: Instrument] = [
        0: .harp,         // Left sector uses Harp
        1: .piano,        // Center sector uses Piano
        2: .synthPad      // Right sector uses Synth Pad
    ]
}

/// Main view controller for Iris app
struct IrisMainView: View {
    // MARK: - Properties
    
    // Camera and depth data
    @ObservedObject var manager: CameraManager
    @Binding var maxDepth: Float
    @Binding var minDepth: Float
    
    // App mode state
    @State private var mode: AppMode = .whiteCane
    
    // Depth data
    @State private var centerDepth: Float = 0.0
    @State private var normalizedCenterDepth: Float = 0.0
    
    // Scan state
    @State private var updateTimer: Timer? = nil
    @State private var activeRow: Int? = nil
    @State private var highlightIntensity: Float = 0.0
    
    // Depth table model
    @State private var depthTable: DepthTableModel
    
    // MARK: - Initialization
    
    init(manager: CameraManager, maxDepth: Binding<Float>, minDepth: Binding<Float>) {
        self.manager = manager
        self._maxDepth = maxDepth
        self._minDepth = minDepth
        
        // Initialize depth table model
        self._depthTable = State(initialValue: DepthTableModel(
            rowCount: IrisConstants.tableRowCount,
            columnCount: IrisConstants.tableColumnCount,
            minDepth: minDepth.wrappedValue,
            maxDepth: maxDepth.wrappedValue
        ))
    }
    
    // MARK: - Body
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background - transparent to show depth view
                Color.clear
                
                // Show different UI based on current mode
                switch mode {
                case .whiteCane:
                    whiteCaneView(geometry: geometry)
                    
                case .depthTable:
                    DepthTableView(
                        manager: manager,
                        depthTable: depthTable,
                        highlightCell: activeRow.map { (row: $0, column: depthTable.columnCount / 2, intensity: highlightIntensity) }
                    )
                    .overlay(
                        // Instructions
                        VStack {
                            Spacer()
                            Text("Single tap for vertical scan\nDouble tap for full scan\nSwipe down to return to White Cane mode")
                                .font(.system(size: 12))
                                .foregroundColor(.white)
                                .padding(8)
                                .background(Color.black.opacity(0.5))
                                .cornerRadius(5)
                                .padding(.bottom, 20)
                        }
                    )
                
                case .singleUpScan:
                    // Show the depth table during single up scan
                    DepthTableView(
                        manager: manager,
                        depthTable: depthTable,
                        highlightCell: activeRow.map { (row: $0, column: depthTable.columnCount / 2, intensity: highlightIntensity) }
                    )
                    
                    // Add the scan controller (invisible)
                    SingleUpScan(
                        manager: manager,
                        depthTable: depthTable,
                        activeRow: $activeRow,
                        highlightIntensity: $highlightIntensity,
                        onScanComplete: {
                            // Return to white cane mode when scan completes
                            mode = .whiteCane
                        }
                    )
                    
                case .fullUpScan:
                    // Show the depth table during full up scan
                    DepthTableView(
                        manager: manager,
                        depthTable: depthTable,
                        highlightCell: activeRow.map { (row: $0, column: 0, intensity: highlightIntensity) },
                        highlightEntireRow: true
                    )
                    
                    // Add the scan controller (invisible)
                    FullUpScan(
                        manager: manager,
                        depthTable: depthTable,
                        activeRow: $activeRow,
                        highlightIntensity: $highlightIntensity,
                        onScanComplete: {
                            // Return to white cane mode when scan completes
                            mode = .whiteCane
                        }
                    )
                }
            }
            // Gesture handling
            .contentShape(Rectangle())
            .onTapGesture {
                handleTapGesture()
            }
            .onTapGesture(count: 2) {
                handleDoubleTapGesture()
            }
            .gesture(
                DragGesture(minimumDistance: 20, coordinateSpace: .local)
                    .onEnded { value in
                        handleDragGesture(value)
                    }
            )
        }
    }
    
    // MARK: - Mode Views
    
    /// White Cane Mode view
    private func whiteCaneView(geometry: GeometryProxy) -> some View {
        let sectorWidth = geometry.size.width / CGFloat(IrisConstants.tableColumnCount)
        
        return Rectangle()
            .strokeBorder(IrisConstants.borderColor, lineWidth: IrisConstants.borderWidth)
            .frame(width: sectorWidth, height: geometry.size.height * IrisConstants.scanRectHeight)
            .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
            .overlay(
                Text("White Cane Mode\nDepth: \(String(format: "%.2f", centerDepth))m\nNorm: \(String(format: "%.2f", normalizedCenterDepth))")
                    .font(.system(size: 10))
                    .foregroundColor(.white)
            )
            .onAppear {
                startContinuousDepthSampling(geometry: geometry)
            }
            .onDisappear {
                stopContinuousDepthSampling()
            }
    }
    
    // MARK: - Gesture Handling
    
    /// Handle tap gesture based on current mode
    private func handleTapGesture() {
        switch mode {
        case .whiteCane:
            // White cane mode: Tap to directly start single up scan
            captureDepthTable()
            mode = .singleUpScan
            print("🎵 Starting Single Up Scan from White Cane mode")
            
        case .depthTable:
            // Depth table mode: Tap to start single up scan
            mode = .singleUpScan
            print("🎵 Starting Single Up Scan from Depth Table mode")
            
        case .singleUpScan, .fullUpScan:
            // Scan modes: Do nothing (scan is in progress)
            break
        }
    }
    
    /// Handle double tap gesture
    private func handleDoubleTapGesture() {
        switch mode {
        case .whiteCane:
            // White cane mode: Double tap to directly start full up scan
            captureDepthTable()
            mode = .fullUpScan
            print("🎵 Starting Full Up Scan from White Cane mode")
            
        case .depthTable:
            // Depth table mode: Double tap to start full up scan
            mode = .fullUpScan
            print("🎵 Starting Full Up Scan from Depth Table mode")
            
        case .singleUpScan, .fullUpScan:
            // Scan modes: Do nothing (scan is in progress)
            break
        }
    }
    
    /// Handle drag gesture based on direction
    private func handleDragGesture(_ value: DragGesture.Value) {
        let verticalDistance = value.location.y - value.startLocation.y
        
        if verticalDistance < -50 {  // Upward swipe
            if mode == .whiteCane {
                // White cane mode: Up swipe to show depth table
                captureDepthTable()
                mode = .depthTable
            }
        } else if verticalDistance > 50 {  // Downward swipe
            if mode == .depthTable || mode == .singleUpScan || mode == .fullUpScan {
                // Depth table or scan modes: Down swipe to return to white cane
                AudioEngine.shared.stopAllNotes() // Stop any playing notes
                mode = .whiteCane
            }
        }
    }
    
    // MARK: - Depth Sampling Methods
    
    /// Start continuous depth sampling for White Cane mode
    private func startContinuousDepthSampling(geometry: GeometryProxy) {
        // Sample depth at center immediately
        sampleCenterDepth()
        
        // Set up a timer to update the depth value periodically
        updateTimer?.invalidate()
        
        updateTimer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: true) { _ in
            if mode == .whiteCane {
                sampleCenterDepth()
            }
        }
        
        // Make sure the timer is added to the common run loop modes
        // so it continues updating even during scrolling or interactions
        if let timer = updateTimer {
            RunLoop.current.add(timer, forMode: .common)
        }
    }
    
    /// Stop continuous depth sampling
    private func stopContinuousDepthSampling() {
        updateTimer?.invalidate()
        updateTimer = nil
    }
    
    /// Sample depth at the center of the screen
    private func sampleCenterDepth() {
        guard manager.dataAvailable, let depthTexture = manager.capturedData.depth else {
            return
        }
        
        // Sample the center point (0.5, 0.5) in texture coordinates
        // Try multiple sample radiuses for more stable readings
        let samplePoints: [(x: Float, y: Float)] = [
            (0.5, 0.5),  // Center
            (0.55, 0.5), // Slightly right
            (0.45, 0.5), // Slightly left
            (0.5, 0.45), // Slightly up
            (0.5, 0.55)  // Slightly down
        ]
        
        let sampleRadiuses = [8, 6, 4, 2]
        var validDepthFound = false
        let previousDepth = centerDepth
        
        for point in samplePoints {
            for radius in sampleRadiuses {
                let depth = DepthSampler.sampleDepthAtPoint(
                    texture: depthTexture,
                    x: point.x,
                    y: point.y,
                    sampleRadius: radius
                )
                
                // Check if we have a reasonable depth value
                if depth >= 0.1 && depth <= 5.0 {
                    // Store the depth value
                    centerDepth = depth
                    normalizedCenterDepth = DepthSampler.normalizeDepth(depth, minDepth: minDepth, maxDepth: maxDepth)
                    
                    // Play note if depth changed significantly
                    if abs(depth - previousDepth) > IrisConstants.depthChangeThreshold {
                        AudioEngine.shared.playNoteForDepth(
                            normalizedDepth: normalizedCenterDepth,
                            sector: 1  // Center sector uses Piano
                        )
                    }
                    
                    validDepthFound = true
                    break
                }
            }
            
            if validDepthFound { break }
        }
        
        // Use fallback if no valid depth found
        if !validDepthFound {
            centerDepth = 0.9  // 0.9 meters (mid-range)
            normalizedCenterDepth = DepthSampler.normalizeDepth(centerDepth, minDepth: minDepth, maxDepth: maxDepth)
        }
    }
    
    /// Capture depth data for the table
    private func captureDepthTable() {
        guard manager.dataAvailable, let depthTexture = manager.capturedData.depth else {
            return
        }
        
        // Update the table model with current depth texture
        _ = depthTable.sampleDepthData(from: depthTexture)
    }
}

// MARK: - App Mode Enum

/// Different modes of the Iris app
enum AppMode {
    case whiteCane    // Center rectangle with depth feedback
    case depthTable   // Table showing depth values for multiple points
    case singleUpScan // Playing notes for center column from bottom to top
    case fullUpScan   // Future: Playing notes for all columns from bottom to top
}