import UIKit
import Flutter
import MobileCoreServices
import UniformTypeIdentifiers

@main
@objc class AppDelegate: FlutterAppDelegate, UIDocumentPickerDelegate {

  var flutterResult: FlutterResult?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {

    let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
    let channel = FlutterMethodChannel(name: "untitled2", binaryMessenger: controller.binaryMessenger)

    channel.setMethodCallHandler { [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) in
      guard call.method == "getDoc" else {
        result(FlutterMethodNotImplemented)
        return
      }
      self?.flutterResult = result
      self?.presentDocumentPicker()
    }

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func presentDocumentPicker() {
    var types: [String] = [
      "com.adobe.pdf",
      "com.microsoft.word.doc",
      "org.openxmlformats.wordprocessingml.document",
      "com.microsoft.excel.xls",
      "org.openxmlformats.spreadsheetml.sheet",
      "public.plain-text",
      "com.pkware.zip-archive"
    ]

    if #available(iOS 14.0, *) {
      let utTypes = types.compactMap { UTType($0) }
      let picker = UIDocumentPickerViewController(forOpeningContentTypes: utTypes, asCopy: true)
      picker.delegate = self
      picker.allowsMultipleSelection = true
      window?.rootViewController?.present(picker, animated: true, completion: nil)
    } else {
      let picker = UIDocumentPickerViewController(documentTypes: types, in: .import)
      picker.delegate = self
      picker.allowsMultipleSelection = true
      window?.rootViewController?.present(picker, animated: true, completion: nil)
    }
  }

  func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
    var filePaths: [String] = []
    for url in urls {
      filePaths.append(url.path)
      print("📄 Picked file path: \(url.path)")
    }
    flutterResult?(filePaths)
  }

  func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
    flutterResult?([])
  }
}
