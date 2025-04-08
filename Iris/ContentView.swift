import SwiftUI
import UIKit

// Custom orientation-fixing UIHostingController 
class PortraitHostingController<Content: View>: UIHostingController<Content> {
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }
    
    override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
        return .portrait
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Force portrait orientation
        let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene
        windowScene?.requestGeometryUpdate(.iOS(interfaceOrientations: .portrait))
        
        // Backup approach using UIDevice
        UIDevice.current.setValue(UIInterfaceOrientation.portrait.rawValue, forKey: "orientation")
    }
}

struct ContentView: View {
    @StateObject private var manager = CameraManager()
    
    // Default values as per requirements
    @State private var maxDepth = Float(1.8)  // 1.8 meters is the default max depth value
    @State private var minDepth = Float(0.0)  // 0.0 meters is the default min depth value
    @State private var isPowerSavingMode = false
    @State private var updateTimer: Timer? = nil
    @State private var needsRefresh = true
    
    var body: some View {
        VStack {
            if manager.dataAvailable {
                ZStack {
                    // Only refresh the depth view when needed to save resources
                    if needsRefresh {
                        DepthOverlay(manager: manager,
                                    maxDepth: $maxDepth,
                                    minDepth: $minDepth)
                        .aspectRatio(calcAspect(orientation: viewOrientation, texture: manager.capturedData.depth), contentMode: .fit)
                    }
                    
                    // Add main iris view with all modes and gestures
                    IrisMainView(manager: manager,
                               maxDepth: $maxDepth,
                               minDepth: $minDepth)
                    
                    // Power saving mode indicator
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            Text(isPowerSavingMode ? "🔋" : "⚡")
                                .font(.system(size: 18))
                                .foregroundColor(.white)
                                .padding(8)
                                .background(Color.black.opacity(0.5))
                                .clipShape(Circle())
                                .onTapGesture {
                                    isPowerSavingMode.toggle()
                                    setupUpdateTimer()
                                }
                                .padding(.trailing, 8)
                                .padding(.bottom, 8)
                        }
                    }
                }
                .onAppear {
                    setupUpdateTimer()
                }
                .onDisappear {
                    updateTimer?.invalidate()
                    updateTimer = nil
                }
            } else {
                Text("Initializing Camera...")
                    .font(.title)
                    .padding()
            }
        }
        .statusBar(hidden: true)
        .edgesIgnoringSafeArea(.all)
        .background(Color.black)
    }
    
    private func setupUpdateTimer() {
        updateTimer?.invalidate()
        
        // In power saving mode, refresh less frequently
        let interval = isPowerSavingMode ? 1.0 : 0.25
        
        updateTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { _ in
            needsRefresh = true
            
            // Only keep the view refreshed briefly to save resources
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                if isPowerSavingMode {
                    needsRefresh = false
                }
            }
        }
    }
}

#Preview {
    ContentView()
}