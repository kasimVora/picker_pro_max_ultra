import Flutter
import UIKit
import MobileCoreServices
import UniformTypeIdentifiers

public class PickerPlugin: NSObject, FlutterPlugin, UIDocumentPickerDelegate {
  var flutterResult: FlutterResult?
  var viewController: UIViewController?

  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "untitled2", binaryMessenger: registrar.messenger())
    let instance = PickerPlugin()
    instance.viewController = UIApplication.shared.delegate?.window??.rootViewController
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "getPlatformVersion":
      result("iOS " + UIDevice.current.systemVersion)

    case "getDoc":
      self.flutterResult = result
      presentDocumentPicker()

    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func presentDocumentPicker() {
    if #available(iOS 14.0, *) {
      let supportedTypes: [UTType] = [UTType.data]
      let documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: supportedTypes)
      documentPicker.delegate = self
      documentPicker.allowsMultipleSelection = false
      viewController?.present(documentPicker, animated: true, completion: nil)
    } else {
      let supportedTypes: [String] = [kUTTypeData as String]
      let documentPicker = UIDocumentPickerViewController(documentTypes: supportedTypes, in: .import)
      documentPicker.delegate = self
      documentPicker.allowsMultipleSelection = false
      viewController?.present(documentPicker, animated: true, completion: nil)
    }
  }

  public func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
    var copiedPaths: [String] = []

    for url in urls {
      let canAccess = url.startAccessingSecurityScopedResource()
      defer {
        if canAccess {
          url.stopAccessingSecurityScopedResource()
        }
      }

      do {
        let fileName = url.lastPathComponent
        let destURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)

        if FileManager.default.fileExists(atPath: destURL.path) {
          try FileManager.default.removeItem(at: destURL)
        }

        try FileManager.default.copyItem(at: url, to: destURL)
        copiedPaths.append(destURL.path)
      } catch {
        flutterResult?(FlutterError(code: "FILE_ERROR", message: "Failed to copy file: \(error.localizedDescription)", details: nil))
        flutterResult = nil
        return
      }
    }

    if copiedPaths.isEmpty {
      flutterResult?(FlutterError(code: "NO_FILE", message: "No document was picked", details: nil))
    } else {
      flutterResult?(copiedPaths)
    }

    flutterResult = nil
  }

  public func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
    flutterResult?(FlutterError(code: "CANCELLED", message: "User cancelled document picker", details: nil))
    flutterResult = nil
  }
}
