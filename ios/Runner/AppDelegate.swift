import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  private var screenshotPreventionView: UIView?
  
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let controller = window?.rootViewController as! FlutterViewController
    let screenshotChannel = FlutterMethodChannel(
      name: "com.campusbound.app/screenshot",
      binaryMessenger: controller.binaryMessenger
    )
    
    screenshotChannel.setMethodCallHandler { (call: FlutterMethodCall, result: @escaping FlutterResult) in
      switch call.method {
      case "disableScreenshots":
        self.disableScreenshots()
        print("✅ Screenshots disabled")
        result(nil)
      case "enableScreenshots":
        self.enableScreenshots()
        print("✅ Screenshots enabled")
        result(nil)
      case "getScreenshotStatus":
        let isDisabled = self.screenshotPreventionView != nil
        print("📸 Screenshot status: \(isDisabled ? "disabled" : "enabled")")
        result(["screenshotsEnabled": !isDisabled])
      default:
        result(FlutterMethodNotImplemented)
      }
    }
    
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
  
  private func disableScreenshots() {
    DispatchQueue.main.sync {
      guard let window = self.window else { return }
      
      // Create a secure field to prevent screenshots
      let secureField = UITextField()
      secureField.isSecureTextEntry = true
      window.addSubview(secureField)
      window.layer.superlayer?.addSublayer(secureField.layer)
      secureField.layer.sublayers?.first?.removeFromSuperlayer()
      
      // Store reference to prevent garbage collection
      self.screenshotPreventionView = secureField
      print("✅ Screenshots disabled immediately")
    }
  }
  
  private func enableScreenshots() {
    DispatchQueue.main.sync {
      // Remove the screenshot prevention view
      self.screenshotPreventionView?.removeFromSuperview()
      self.screenshotPreventionView = nil
      print("✅ Screenshots enabled immediately")
    }
  }
}
