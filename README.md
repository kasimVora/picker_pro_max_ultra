# 📦 picker_pro_max_ultra

[![pub package](https://img.shields.io/pub/v/picker_pro_max_ultra.svg)](https://pub.dev/packages/picker_pro_max_ultra)

A powerful and customizable media picker for Flutter, built with performance and ease of use in mind.

Easily pick images and videos from device storage or capture new ones with camera support. Comes with advanced features like folder browsing, multi-selection, capture image from camera, and custom UI using GetX.

---

|             | Android | iOS     | Web  | Windows | macOS | Linux |
|-------------|---------|---------|------|---------|-------|-------|
| **Support** | SDK 21+ | iOS 12+ | ❌   | ❌      | ❌    | ❌    |

---

## ✨ Features

- 📸 Capture image using the camera
- 🖼 Pick images & videos from the gallery
- 📂 Folder-based media browsing
- 🔁 Multi-selection support
- ⚡ Fast loading with optimized performance
- 📉 Automatic image compression
- 🎨 Customizable UI with GetX

---

## 🛠 Installation

Add this to your `pubspec.yaml`:

```yaml
dependencies:
  picker_pro_max_ultra: ^<latest_version>
```

Replace `<latest_version>` with the latest version on [pub.dev](https://pub.dev/packages/picker_pro_max_ultra).

---

## ⚙️ Setup

### ✅ Android

Add the following permissions to your `AndroidManifest.xml` (`android/app/src/main/AndroidManifest.xml`):

```xml
<!-- Media Access -->
<uses-permission android:name="android.permission.READ_MEDIA_IMAGES" />
<uses-permission android:name="android.permission.READ_MEDIA_VIDEO" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" android:maxSdkVersion="32" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />

<!-- Camera Access -->
<uses-permission android:name="android.permission.CAMERA" />
```

### 🍏 iOS

Add the following entries to your `ios/Runner/Info.plist`:

```xml
<key>NSPhotoLibraryUsageDescription</key>
<string>This app requires access to your photo library.</string>

<key>NSCameraUsageDescription</key>
<string>This app requires access to the camera.</string>

<key>NSMicrophoneUsageDescription</key>
<string>This app requires access to the microphone.</string>
```

---

## 🧪 Example Usage

```dart

// Pick media
final List<MediaFile> files =  await  MediaPicker(
context: context,maxLimit: 5 ?? 1,mediaType: MediaType.image
).showPicker();

// Capture from camera
final MediaFile? captured = await MediaPicker(context: context).capturedFile();
```

For a full example, check out the [example folder](https://github.com/kasimVora/picker_pro_max_ultra/tree/MAIN/example).

---

## 📸 Screenshots

<p float="left">
  <img src="https://github.com/kasimVora/picker_pro_max_ultra/blob/MAIN/screenshots/OCPhoto.765690179.842269.jpeg" width="30%" alt="Screenshot 1" />
  <img src="https://res.cloudinary.com/dythkcsup/image/upload/v1744020357/OCPhoto.765690179.63493_chvqhz.jpg" width="30%" alt="Screenshot 2" />
  <img src="https://github.com/kasimVora/picker_pro_max_ultra/blob/MAIN/screenshots/OCPhoto.765690180.079217.jpeg" width="30%" alt="Screenshot 3" />
  <img src="https://github.com/kasimVora/picker_pro_max_ultra/blob/video_capture/screenshots/OCPhoto.765691778.497244.jpeg" width="30%" alt="Screenshot 3" />
</p>

---

## 🧩 Contributions

Contributions, issues, and feature requests are welcome!  
Feel free to check [issues page](https://github.com/kasimVora/picker_pro_max_ultra/issues).

---

## 📄 License

This project is licensed under the [MIT License](LICENSE).
