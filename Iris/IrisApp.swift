//
//  IrisApp.swift
//  Iris
//
//  Created by Mario Pereira on 4/3/25.
//

import SwiftUI
import UIKit

// Lock app to portrait orientation only
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        return .portrait
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        // Force portrait orientation when app becomes active
        AppDelegate.forcePortraitOrientation()
        
        // Add observer for orientation changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(orientationDidChange),
            name: UIDevice.orientationDidChangeNotification,
            object: nil
        )
    }
    
    @objc func orientationDidChange() {
        // Force back to portrait if device orientation changes
        if UIDevice.current.orientation != .portrait {
            AppDelegate.forcePortraitOrientation()
        }
    }
    
    // Static method to force portrait orientation that can be called from anywhere
    static func forcePortraitOrientation() {
        // Force interface orientation via scene
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            windowScene.requestGeometryUpdate(.iOS(interfaceOrientations: .portrait))
            print("🔒 Requested portrait orientation via windowScene")
            
            // Apply to all windows in the scene
            for window in windowScene.windows {
                if let rootVC = window.rootViewController {
                    // Set preferred orientation for presented view controllers
                    if let presented = rootVC.presentedViewController {
                        if !(presented is UIAlertController) {
                            presented.dismiss(animated: false)
                        }
                    }
                }
            }
        }
    }
}

@main
struct IrisApp: App {
    // Register app delegate for orientation lock
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @Environment(\.scenePhase) private var scenePhase
    
    init() {
        // Force portrait orientation at launch
        print("🔒 Application launched with portrait orientation lock")
        // UIDevice.setValue is deprecated - orientation will be set when scene activates
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                // This uses our custom hosting controller for extra orientation control
                .background {
                    PortraitControllerRepresentable()
                        .frame(width: 0, height: 0)
                }
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            switch newPhase {
            case .active:
                // Enforce portrait orientation when scene becomes active
                AppDelegate.forcePortraitOrientation()
                print("🔒 Scene active: forcing portrait orientation")
            case .inactive:
                print("Scene inactive")
            case .background:
                print("Scene in background")
            @unknown default:
                print("Unknown scene phase")
            }
        }
    }
}

// Helper to integrate our PortraitHostingController into SwiftUI
struct PortraitControllerRepresentable: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UIViewController {
        let controller = PortraitForceController()
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}

// Force portrait orientation
class PortraitForceController: UIViewController {
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Force portrait orientation
        AppDelegate.forcePortraitOrientation()
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }
    
    override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
        return .portrait
    }
}
