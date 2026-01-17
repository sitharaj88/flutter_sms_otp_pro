import Flutter
import UIKit

/// SMS OTP Plugin for iOS
///
/// On iOS, OTP autofill is handled natively by the system when using
/// TextFields with the `.oneTimeCode` content type. This plugin provides
/// a minimal implementation to maintain API compatibility with Android.
public class SmsOtpPlugin: NSObject, FlutterPlugin, FlutterStreamHandler {
    
    private var eventSink: FlutterEventSink?
    
    // MARK: - FlutterPlugin
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let instance = SmsOtpPlugin()
        
        // Method channel for commands
        let methodChannel = FlutterMethodChannel(
            name: "sms_otp",
            binaryMessenger: registrar.messenger()
        )
        registrar.addMethodCallDelegate(instance, channel: methodChannel)
        
        // Event channel for OTP events
        let eventChannel = FlutterEventChannel(
            name: "sms_otp/events",
            binaryMessenger: registrar.messenger()
        )
        eventChannel.setStreamHandler(instance)
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "getPlatformVersion":
            result("iOS " + UIDevice.current.systemVersion)
            
        case "startListening":
            // iOS handles OTP autofill natively via TextField content type
            // We just acknowledge the request
            result(true)
            
        case "stopListening":
            // No-op on iOS as there's no active listener to stop
            result(nil)
            
        case "getAppSignature":
            // App signature is Android-specific (SMS Retriever API)
            result(nil)
            
        case "requestPermissions":
            // iOS doesn't require special permissions for OTP autofill
            result("not_required")
            
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    // MARK: - FlutterStreamHandler
    
    public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        self.eventSink = events
        return nil
    }
    
    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        self.eventSink = nil
        return nil
    }
    
    // MARK: - Helper Methods
    
    /// Send an event to the Flutter side
    private func sendEvent(_ data: [String: Any?]) {
        DispatchQueue.main.async {
            self.eventSink?(data)
        }
    }
}

// MARK: - iOS OTP Autofill Information
/*
 * iOS OTP Autofill Requirements:
 *
 * 1. Use TextField with textContentType: .oneTimeCode
 *    In Flutter: TextField(autofillHints: [AutofillHints.oneTimeCode])
 *
 * 2. SMS Format Guidelines:
 *    - Include the OTP code prominently
 *    - Use keywords like "code", "OTP", "verification"
 *    - Avoid special characters around the code
 *    - Keep the message simple and clear
 *
 * 3. Example SMS formats that work well:
 *    - "Your verification code is 123456"
 *    - "123456 is your OTP"
 *    - "Code: 123456"
 *
 * 4. The code is automatically detected by iOS and offered
 *    as a keyboard suggestion for 3 minutes after receipt.
 *
 * 5. No special permissions or entitlements are required.
 */
