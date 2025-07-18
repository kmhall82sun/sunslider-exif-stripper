# EXIFStripper

**Privacy-first EXIF metadata removal for iOS**

A lightweight, comprehensive Swift library that strips sensitive EXIF metadata from images while preserving essential display properties. Perfect for apps that prioritize user privacy.

## 🔒 Why EXIFStripper?

When users share photos through your app, those images often contain sensitive metadata:
- **📍 GPS coordinates** - Exact location where photo was taken
- **📱 Device information** - Camera make, model, software version
- **⏰ Timestamps** - When the photo was created and modified
- **🎛️ Camera settings** - Detailed technical information

EXIFStripper removes this sensitive data while keeping your images looking perfect.

## ✨ Features

- **🛡️ Complete privacy protection** - Strips GPS, device info, timestamps, and IPTC data
- **🖼️ Preserves image quality** - No visual degradation
- **📐 Maintains orientation** - Images display correctly after processing
- **📊 Privacy analysis** - Understand what sensitive data was removed
- **⚡ High performance** - Optimized for batch processing
- **🧪 Batch processing** - Handle multiple images efficiently
- **📱 iOS native** - Pure Swift, no external dependencies

## 🚀 Quick Start

### Swift Package Manager

Add to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/kmhall82sun/sunslider-exif-stripper.git", from: "1.0.0")
]
```

### Basic Usage

```swift
import EXIFStripper

// Strip sensitive metadata from a UIImage
let cleanImage = EXIFStripper.stripSensitiveMetadata(from: originalImage)

// Or from image data
let cleanImage = EXIFStripper.stripSensitiveMetadata(from: imageData)
```

### Analyze Privacy Data

```swift
// See what sensitive data will be removed
let analysis = EXIFStripper.analyzePrivacyData(in: imageData)

print(analysis.removedDataDescription)
// Output: "Removed: location data, device information, timestamps"

if analysis.privacyRiskLevel == .high {
    print("⚠️ This image contains exact GPS coordinates")
}
```

### Batch Processing

```swift
// Process multiple images at once
let images = [image1, image2, image3]
let result = EXIFStripper.processBatch(images)

for (index, processedImage) in result.processedImages.enumerated() {
    let analysis = result.analyses[index]
    print("Image \(index): \(analysis.removedDataDescription)")
}
```

## 🎯 Use Cases

- **📷 Photo sharing apps** - Protect user privacy automatically
- **💬 Social media platforms** - Strip metadata before upload
- **🏢 Enterprise apps** - Ensure sensitive location data isn't leaked
- **📊 Image processing pipelines** - Clean metadata as part of your workflow
- **🔐 Privacy-focused apps** - Demonstrate commitment to user privacy

## 📋 What Gets Removed

| Metadata Type | Examples | Privacy Risk |
|---------------|----------|--------------|
| **GPS Data** | Latitude, longitude, altitude | 🔴 High |
| **Device Info** | Camera make/model, software version | 🟡 Medium |
| **Timestamps** | Creation date, modification date | 🟡 Medium |
| **IPTC Data** | Keywords, descriptions, copyright | 🟡 Medium |
| **Camera Settings** | ISO, focal length, exposure | 🟢 Low |

## ✅ What Gets Preserved

- **Image orientation** - Photos display correctly
- **Color profiles** - Images look the same
- **Image dimensions** - Size information maintained
- **Visual quality** - No compression or degradation

## 🔬 Privacy Analysis

The `PrivacyAnalysis` struct provides detailed insights:

```swift
let analysis = EXIFStripper.analyzePrivacyData(in: imageData)

// Check specific types of sensitive data
if analysis.hasExactLocation {
    print("🚨 Contains GPS coordinates")
}

if analysis.hasDeviceInfo {
    print("📱 Contains device information")
}

// Get overall risk assessment
switch analysis.privacyRiskLevel {
case .high:    print("🔴 High privacy risk")
case .medium:  print("🟡 Medium privacy risk") 
case .low:     print("🟢 Low privacy risk")
case .none:    print("✅ No privacy risk detected")
}
```

## 🧪 Example Integration

```swift
import UIKit
import EXIFStripper

class ImageUploadService {
    func uploadImage(_ image: UIImage) {
        // Always strip sensitive metadata before upload
        guard let cleanImage = EXIFStripper.stripSensitiveMetadata(from: image) else {
            print("Failed to process image")
            return
        }
        
        // Now safely upload the clean image
        performUpload(cleanImage)
    }
    
    func showPrivacyInfo(for imageData: Data) {
        let analysis = EXIFStripper.analyzePrivacyData(in: imageData)
        
        let alert = UIAlertController(
            title: "Privacy Protection",
            message: analysis.removedDataDescription,
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        // Present alert...
    }
}
```

## 🏗️ Technical Details

- **iOS 13.0+** - Minimum deployment target
- **Swift 5.0+** - Modern Swift support
- **No dependencies** - Pure Swift implementation
- **Memory efficient** - Streams image data without loading everything into memory
- **Thread safe** - Use from any queue

## 📄 License

MIT License - See [LICENSE](LICENSE) file for details.

## 🤝 Contributing

Contributions welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 🛠️ Built By

Created by the [Sunslider](https://sunslider.social) team as part of our commitment to privacy-first social media.

---

**Privacy is a fundamental right.** Help us build a more private internet, one image at a time. 🔒
