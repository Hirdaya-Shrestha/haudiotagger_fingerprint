import Flutter
import UIKit

public class SwiftHaudioFingerprintPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "haudiotagger_fingerprint", binaryMessenger: registrar.messenger())
    let instance = SwiftHaudioFingerprintPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    result("iOS " + UIDevice.current.systemVersion)
  }
}
