//
//  EXIFStripper.swift
//  Sunslider Privacy Tools
//
//  Privacy-first EXIF metadata removal utility
//  Open Source - MIT License
//  SIMPLIFIED: Only strips sensitive data, preserves orientation for backend processing
//

import UIKit
import ImageIO
import UniformTypeIdentifiers

// MARK: - EXIF Stripper Core

public class EXIFStripper {
    
    // MARK: - Public Interface
    
    /// Strips sensitive EXIF metadata from UIImage while preserving orientation
    /// Backend will handle final orientation processing and complete EXIF removal
    /// - Parameter image: Original UIImage with potential metadata
    /// - Returns: UIImage with sensitive metadata removed, orientation preserved
    public static func stripSensitiveMetadata(from image: UIImage) -> UIImage? {
        guard let imageData = image.jpegData(compressionQuality: 1.0) else {
            return image
        }
        
        return stripSensitiveMetadata(from: imageData)
    }
    
    /// Strips sensitive EXIF metadata from image data while preserving orientation
    /// - Parameter data: Original image data with potential metadata
    /// - Returns: Clean UIImage with sensitive metadata removed, orientation preserved
    public static func stripSensitiveMetadata(from data: Data) -> UIImage? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
              let type = CGImageSourceGetType(source) else {
            return UIImage(data: data)
        }
        
        // Get original properties to extract safe data
        guard let originalProperties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [String: Any] else {
            return UIImage(data: data)
        }
        
        // Create destination data
        let destinationData = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(
            destinationData,
            type,
            1,
            nil
        ) else {
            return UIImage(data: data)
        }
        
        // Get the image
        guard let cgImage = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
            return UIImage(data: data)
        }
        
        // Create safe metadata dictionary - preserve orientation, strip sensitive data
        let safeProperties = createSafeMetadata(from: originalProperties)
        
        // Add the image with safe metadata only
        CGImageDestinationAddImage(destination, cgImage, safeProperties as CFDictionary)
        
        // Finalize the destination
        guard CGImageDestinationFinalize(destination) else {
            return UIImage(data: data)
        }
        
        return UIImage(data: destinationData as Data)
    }
    
    /// Analyzes what metadata would be removed (for user education)
    /// - Parameter data: Original image data
    /// - Returns: Privacy analysis showing what sensitive data was found
    public static func analyzePrivacyData(in data: Data) -> PrivacyAnalysis {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
              let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [String: Any] else {
            return PrivacyAnalysis()
        }
        
        var analysis = PrivacyAnalysis()
        
        // Check for GPS data
        if let gpsData = properties[kCGImagePropertyGPSDictionary as String] as? [String: Any] {
            analysis.hasGPSData = !gpsData.isEmpty
            if gpsData[kCGImagePropertyGPSLatitude as String] != nil,
               gpsData[kCGImagePropertyGPSLongitude as String] != nil {
                analysis.hasExactLocation = true
            }
        }
        
        // Check for TIFF data (device info)
        if let tiffData = properties[kCGImagePropertyTIFFDictionary as String] as? [String: Any] {
            analysis.hasDeviceInfo = tiffData[kCGImagePropertyTIFFMake as String] != nil ||
                                   tiffData[kCGImagePropertyTIFFModel as String] != nil ||
                                   tiffData[kCGImagePropertyTIFFSoftware as String] != nil
        }
        
        // Check for EXIF data (timestamps, camera settings)
        if let exifData = properties[kCGImagePropertyExifDictionary as String] as? [String: Any] {
            analysis.hasTimestamps = exifData[kCGImagePropertyExifDateTimeOriginal as String] != nil ||
                                    exifData[kCGImagePropertyExifDateTimeDigitized as String] != nil
            
            analysis.hasCameraSettings = exifData[kCGImagePropertyExifLensModel as String] != nil ||
                                       exifData[kCGImagePropertyExifISOSpeedRatings as String] != nil
        }
        
        // Check for IPTC data (often contains personal info)
        if let iptcData = properties[kCGImagePropertyIPTCDictionary as String] as? [String: Any] {
            analysis.hasIPTCData = !iptcData.isEmpty
        }
        
        return analysis
    }
    
    // MARK: - Private Implementation
    
    /// Creates safe metadata dictionary - preserves orientation and basic display data,
    /// strips all sensitive privacy data
    private static func createSafeMetadata(from originalProperties: [String: Any]) -> [String: Any] {
        var safeProperties: [String: Any] = [:]
        
        // Preserve orientation (needed for backend processing)
        if let orientation = originalProperties[kCGImagePropertyOrientation as String] {
            safeProperties[kCGImagePropertyOrientation as String] = orientation
        } else {
            safeProperties[kCGImagePropertyOrientation as String] = 1 // Default to up
        }
        
        // Preserve basic color and image properties
        safeProperties[kCGImagePropertyColorModel as String] = kCGImagePropertyColorModelRGB
        
        if let pixelWidth = originalProperties[kCGImagePropertyPixelWidth as String] {
            safeProperties[kCGImagePropertyPixelWidth as String] = pixelWidth
        }
        
        if let pixelHeight = originalProperties[kCGImagePropertyPixelHeight as String] {
            safeProperties[kCGImagePropertyPixelHeight as String] = pixelHeight
        }
        
        // Create minimal TIFF data with safe properties only
        var safeTiffDict: [String: Any] = [:]
        
        // Preserve orientation in TIFF as well
        if let orientation = originalProperties[kCGImagePropertyOrientation as String] {
            safeTiffDict[kCGImagePropertyTIFFOrientation as String] = orientation
        }
        
        // Basic resolution data (not sensitive)
        safeTiffDict[kCGImagePropertyTIFFResolutionUnit as String] = 2 // Inches
        safeTiffDict[kCGImagePropertyTIFFXResolution as String] = 72.0
        safeTiffDict[kCGImagePropertyTIFFYResolution as String] = 72.0
        
        safeProperties[kCGImagePropertyTIFFDictionary as String] = safeTiffDict
        
        // NOTE: We deliberately exclude:
        // - kCGImagePropertyGPSDictionary (GPS location data)
        // - kCGImagePropertyExifDictionary (camera settings, timestamps, device info)
        // - kCGImagePropertyIPTCDictionary (personal metadata)
        // - TIFF Make, Model, Software (device identification)
        
        return safeProperties
    }
}

// MARK: - Privacy Analysis Result

public struct PrivacyAnalysis {
    public var hasGPSData: Bool = false
    public var hasExactLocation: Bool = false
    public var hasDeviceInfo: Bool = false
    public var hasTimestamps: Bool = false
    public var hasCameraSettings: Bool = false
    public var hasIPTCData: Bool = false
    
    public var hasSensitiveData: Bool {
        return hasGPSData || hasDeviceInfo || hasTimestamps || hasIPTCData
    }
    
    public var privacyRiskLevel: PrivacyRiskLevel {
        if hasExactLocation { return .high }
        if hasGPSData || hasDeviceInfo { return .medium }
        if hasTimestamps || hasIPTCData { return .low }
        return .none
    }
    
    public var removedDataDescription: String {
        var removed: [String] = []
        
        if hasGPSData { removed.append("location data") }
        if hasDeviceInfo { removed.append("device information") }
        if hasTimestamps { removed.append("timestamps") }
        if hasIPTCData { removed.append("embedded metadata") }
        
        if removed.isEmpty {
            return "No sensitive metadata detected"
        } else {
            return "Removed: " + removed.joined(separator: ", ")
        }
    }
}

public enum PrivacyRiskLevel {
    case none, low, medium, high
    
    public var description: String {
        switch self {
        case .none: return "No privacy risk detected"
        case .low: return "Low privacy risk"
        case .medium: return "Medium privacy risk"
        case .high: return "High privacy risk - exact location included"
        }
    }
    
    public var color: UIColor {
        switch self {
        case .none: return .systemGreen
        case .low: return .systemYellow
        case .medium: return .systemOrange
        case .high: return .systemRed
        }
    }
}

// MARK: - Batch Processing Extension

public extension EXIFStripper {
    
    /// Process multiple images for upload (like your carousel feature)
    /// - Parameter images: Array of UIImages to process
    /// - Returns: Array of processed images and overall privacy analysis
    static func processBatch(_ images: [UIImage]) -> BatchProcessingResult {
        var processedImages: [UIImage] = []
        var analyses: [PrivacyAnalysis] = []
        var processingErrors: [Int] = [] // Track which images failed
        
        for (index, image) in images.enumerated() {
            // Analyze privacy data first
            if let imageData = image.jpegData(compressionQuality: 1.0) {
                let analysis = analyzePrivacyData(in: imageData)
                analyses.append(analysis)
            } else {
                analyses.append(PrivacyAnalysis())
            }
            
            // Strip sensitive metadata only (preserve orientation)
            if let cleanImage = stripSensitiveMetadata(from: image) {
                processedImages.append(cleanImage)
            } else {
                processingErrors.append(index)
                processedImages.append(image) // Fallback to original
            }
        }
        
        return BatchProcessingResult(
            processedImages: processedImages,
            analyses: analyses,
            processingErrors: processingErrors
        )
    }
}

public struct BatchProcessingResult {
    public let processedImages: [UIImage]
    public let analyses: [PrivacyAnalysis]
    public let processingErrors: [Int]
    
    public var overallPrivacyAnalysis: PrivacyAnalysis {
        var combined = PrivacyAnalysis()
        
        for analysis in analyses {
            combined.hasGPSData = combined.hasGPSData || analysis.hasGPSData
            combined.hasExactLocation = combined.hasExactLocation || analysis.hasExactLocation
            combined.hasDeviceInfo = combined.hasDeviceInfo || analysis.hasDeviceInfo
            combined.hasTimestamps = combined.hasTimestamps || analysis.hasTimestamps
            combined.hasCameraSettings = combined.hasCameraSettings || analysis.hasCameraSettings
            combined.hasIPTCData = combined.hasIPTCData || analysis.hasIPTCData
        }
        
        return combined
    }
    
    public var hasProcessingErrors: Bool {
        return !processingErrors.isEmpty
    }
}
