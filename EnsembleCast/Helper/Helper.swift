//
//  File.swift
//  EnsembleCast
//
//  Created by Mohi Farhand on 2025-02-25.
//

import UIKit
import Kingfisher

extension UIFont {
    
    static func CDFontExtraBold(size: CGFloat) -> UIFont {
        return UIFont(name: "Poppins-ExtraBold", size: size) ?? UIFont.systemFont(ofSize: size)
    }
    static func CDFontBold(size: CGFloat) -> UIFont {
        return UIFont(name: "Poppins-Bold", size: size) ?? UIFont.boldSystemFont(ofSize: size)
    }
    
    static func CDFontSemiBold(size: CGFloat) -> UIFont {
        return UIFont(name: "Poppins-SemiBold", size: size) ?? UIFont.boldSystemFont(ofSize: size)
    }
    
    static func CDFontMedium(size: CGFloat) -> UIFont {
        return UIFont(name: "Poppins-Medium", size: size) ?? UIFont.boldSystemFont(ofSize: size)
    }

    
    static func CDFontRegular(size: CGFloat) -> UIFont {
        return UIFont(name: "Poppins-Regular", size: size) ?? UIFont.systemFont(ofSize: size)
    }
    
    static func CDFontLight(size: CGFloat) -> UIFont {
        return UIFont(name: "Poppins-Light", size: size) ?? UIFont.systemFont(ofSize: size)
    }
}


extension UIViewController {
    
    func updateRootViewController(to viewController: UIViewController) {
        // Ensure we are running on the main thread
        guard Thread.isMainThread else {
            DispatchQueue.main.async {
                self.updateRootViewController(to: viewController)
            }
            return
        }
        
        // Get the active window scene
        if let windowScene = UIApplication.shared.connectedScenes
            .filter({ $0.activationState == .foregroundActive })
            .compactMap({ $0 as? UIWindowScene })
            .first,
           let window = windowScene.windows.first {
            
            guard window.rootViewController != nil else {
                window.rootViewController = nil
                window.rootViewController = viewController
                window.makeKeyAndVisible()
                return
            }
            
            // Set the new rootViewController of the window.
            // Calling "UIView.transition" below will animate the swap.
            window.rootViewController = nil
            window.rootViewController = viewController
            
            // A mask of options indicating how you want to perform the animations.
            let options: UIView.AnimationOptions = .transitionCrossDissolve
            
            // The duration of the transition animation, measured in seconds.
            let duration: TimeInterval = 0.4
            
            // Creates a transition animation.
            // Though `animations` is optional, the documentation tells us that it must not be nil. ¯\_(ツ)_/¯
            UIView.transition(with: window, duration: duration, options: options, animations: {}, completion:
                                { completed in
                // maybe do something on completion here
            })
        } else {
            print("No active window scene found. Retrying in 0.5 seconds.")
            // Retry after a small delay if no active window scene
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.updateRootViewController(to: viewController)
            }
        }
    }
    
}

enum Section {
    case main
}

func enableCachePolicy() {
    let cache = ImageCache.default
    cache.diskStorage.config.sizeLimit = 100 * 1024 * 1024 // 100 MB
    cache.memoryStorage.config.totalCostLimit = 50 * 1024 * 1024 // 50 MB
    cache.diskStorage.config.expiration = .days(7) // Keep images for 7 days
}


import CoreHaptics

class Haptic {
    
    // Store haptic capability result once to avoid redundant calls
    private static let supportsHaptics: Bool = CHHapticEngine.capabilitiesForHardware().supportsHaptics

    // Reuse feedback generators to improve performance
    private static let notificationGenerator = UINotificationFeedbackGenerator()
    private static let impactLightGenerator = UIImpactFeedbackGenerator(style: .light)
    private static let impactHeavyGenerator = UIImpactFeedbackGenerator(style: .heavy)
    
    /// Plays a success notification haptic.
    static func play() {
        guard supportsHaptics else { return }
        notificationGenerator.prepare()
        notificationGenerator.notificationOccurred(.success)
    }
    
    /// Plays a light vibration (general feedback).
    static func vibrating() {
        guard supportsHaptics else { return }
        impactLightGenerator.prepare()
        impactLightGenerator.impactOccurred(intensity: 1.0)
    }
    
    /// Plays an intense vibration.
    static func intenseVibrating() {
        guard supportsHaptics else { return }
        impactHeavyGenerator.prepare()
        impactHeavyGenerator.impactOccurred(intensity: 1.0)
    }

}
