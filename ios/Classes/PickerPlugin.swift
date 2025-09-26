import Flutter
import UIKit
import MobileCoreServices
import UniformTypeIdentifiers
//import AVFoundation

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
            guard let args = call.arguments as? [String: Any],
                  let mediaType = args["mediaType"] as? String else {
                result(FlutterError(code: "INVALID_ARGS", message: "Missing mediaType", details: nil))
                return
            }
            presentDocumentPicker(mediaType: mediaType)

//        case "compressFile":
//            print("📦 compressFile called")
//            self.flutterResult = result
//            guard let args = call.arguments as? [String: Any],
//                  let inputPath = args["inputPath"] as? String,
//                  let outputPath = args["outputPath"] as? String else {
//                result(FlutterError(code: "INVALID_ARGS", message: "Missing input or output path", details: nil))
//                return
//            }
//
//            print("📦 Compressing file from: \(inputPath) to: \(outputPath)")
//
//            let ext = URL(fileURLWithPath: inputPath).pathExtension.lowercased()
//
//            switch ext {
//            case "jpg", "jpeg", "png", "webp":
//                compressImage(at: inputPath, to: outputPath, result: result)
//
//            case "mp4", "mov", "mkv", "3gp":
//                let inputURL = URL(fileURLWithPath: inputPath)
//                let outputURL = URL(fileURLWithPath: outputPath)
//                compressVideo(inputURL: inputURL, outputURL: outputURL) { success in
//                    if success {
//                        result(outputPath)
//                    } else {
//                        result(FlutterError(code: "COMPRESSION_FAILED", message: "Video compression failed", details: nil))
//                    }
//                }
//
//            default:
//                result(FlutterError(code: "UNSUPPORTED_TYPE", message: "Unsupported file extension: \(ext)", details: nil))
//            }

        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private func presentDocumentPicker(mediaType: String) {
        let documentPicker: UIDocumentPickerViewController

        if #available(iOS 14.0, *) {
            let supportedTypes: [UTType]

            if mediaType == "audio" {
                supportedTypes = [UTType.audio]
            } else {
                supportedTypes = [UTType.pdf, UTType.text, UTType.rtf, UTType.content, UTType.data]
            }

            documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: supportedTypes)
        } else {
            let supportedTypes: [String]

            if mediaType == "audio" {
                supportedTypes = [kUTTypeAudio as String]
            } else {
                supportedTypes = [kUTTypePDF as String, kUTTypeText as String, kUTTypeRTF as String, kUTTypeContent as String, kUTTypeData as String]
            }

            documentPicker = UIDocumentPickerViewController(documentTypes: supportedTypes, in: .import)
        }

        documentPicker.delegate = self
        documentPicker.allowsMultipleSelection = false
        viewController?.present(documentPicker, animated: true, completion: nil)
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

//    func compressVideo(inputURL: URL, outputURL: URL, completion: @escaping (Bool) -> Void) {
//        let asset = AVURLAsset(url: inputURL)
//        guard let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetMediumQuality) else {
//            completion(false)
//            return
//        }
//
//        exportSession.outputURL = outputURL
//        exportSession.outputFileType = .mp4
//        exportSession.exportAsynchronously {
//            completion(exportSession.status == .completed)
//        }
//    }
//
//    func compressImage(at inputPath: String, to outputPath: String, result: @escaping FlutterResult) {
//        guard let image = UIImage(contentsOfFile: inputPath) else {
//            result(FlutterError(code: "IMAGE_LOAD_FAILED", message: "Cannot load image", details: nil))
//            return
//        }
//
//        let size = CGSize(width: image.size.width * 0.5, height: image.size.height * 0.5)
//        UIGraphicsBeginImageContextWithOptions(size, false, 1.0)
//        image.draw(in: CGRect(origin: .zero, size: size))
//        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
//        UIGraphicsEndImageContext()
//
//        if let jpegData = resizedImage?.jpegData(compressionQuality: 0.6) {
//            do {
//                try jpegData.write(to: URL(fileURLWithPath: outputPath))
//                result(outputPath)
//            } catch {
//                result(FlutterError(code: "WRITE_FAILED", message: "Could not write image", details: error.localizedDescription))
//            }
//        } else {
//            result(FlutterError(code: "COMPRESSION_FAILED", message: "Could not compress image", details: nil))
//        }
//    }
}
