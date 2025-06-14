//
//  UIImage.swift
//  AIApp
//
//  Created by Carlos Xavier Carvajal Villegas on 9/6/25.
//

import SwiftUI
import CoreImage
import CoreImage.CIFilterBuiltins

extension UIImage {
    var pixelBuffer: CVPixelBuffer? {
        let attrs = [kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue,
                     kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue] as CFDictionary
        var pixelBuffer: CVPixelBuffer?
        let status = CVPixelBufferCreate(kCFAllocatorDefault,
                                         Int(self.size.width),
                                         Int(self.size.height),
                                         kCVPixelFormatType_32ARGB,
                                         attrs, &pixelBuffer)
        
        guard status == kCVReturnSuccess,
              let pixelBuffer else {
            return nil
        }
    
        CVPixelBufferLockBaseAddress(pixelBuffer, CVPixelBufferLockFlags(rawValue: 0))
        let pixelData = CVPixelBufferGetBaseAddress(pixelBuffer)
        let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
        guard let context = CGContext(data: pixelData,
                                      width: Int(self.size.width),
                                      height: Int(self.size.height),
                                      bitsPerComponent: 8,
                                      bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer),
                                      space: rgbColorSpace,
                                      bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue) else {
            return nil
        }
        context.translateBy(x: 0, y: self.size.height)
        context.scaleBy(x: 1.0, y: -1.0)
        
        UIGraphicsPushContext(context)
        self.draw(in: CGRect(x: 0, y: 0, width: self.size.width, height: self.size.height))
        UIGraphicsPopContext()
        CVPixelBufferUnlockBaseAddress(pixelBuffer, CVPixelBufferLockFlags(rawValue: 0))
        return pixelBuffer
    }

    //Qué es CG? Core Graphics
    func resizeImage(width: CGFloat, height: CGFloat) -> UIImage? {
        let scaleSize = CGSize(width: width, height: height)
        let buffer = UIGraphicsImageRenderer(size: scaleSize)
        let newImage = buffer.image { context in
            draw(in: CGRect(origin: .zero, size: scaleSize))
        }
        return newImage
    }
    
    //Algoritmo de reescalado más eficiente que existe (hasta la fecha)
    func resizeLanczos(width: CGFloat) -> UIImage? {
        let filter = CIFilter.lanczosScaleTransform()
        filter.inputImage = self.ciImage
        filter.scale = Float(width / size.width)
        filter.aspectRatio = 1.0
        let context = CIContext() //Core Image
        return if let output = filter.outputImage,
           let cgImg = context.createCGImage(output, from: output.extent) {
            UIImage(cgImage: cgImg)
        } else {
            nil
        }
    }
    
    convenience init?(pixelBuffer: CVPixelBuffer) {
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        let context = CIContext()
        let size = CGSize(width: CVPixelBufferGetWidth(pixelBuffer),
                          height: CVPixelBufferGetHeight(pixelBuffer))
        let cgImage = context.createCGImage(ciImage, from: CGRect(origin: .zero, size: size))
        if let cgImage {
            self.init(cgImage: cgImage)
        } else {
            return nil
        }
    }
}

extension CGRect {
    func convertFromObservation(to size: CGSize) -> CGRect {
        let scale = CGAffineTransform.identity.scaledBy(x: size.width, y: size.height)
        let invertY = CGAffineTransform(scaleX: 1.0, y: -1.0).translatedBy(x: 0, y: -size.height)
        return self.applying(scale).applying(invertY)
    }
    
    func mirrored(in width: CGFloat) -> CGRect {
         var mirroredRect = self
         mirroredRect.origin.x = width - self.origin.x - self.width
         return mirroredRect
     }
}

extension CGPoint {
    static func + (p1: CGPoint, p2: CGPoint) -> CGPoint {
        CGPoint(x: p1.x + p2.x, y: p1.y + p2.y)
    }

    func convertFromObservation(to size: CGSize) -> CGPoint {
        let scale = CGAffineTransform.identity.scaledBy(x: size.width, y: size.height)
        let invertY = CGAffineTransform(scaleX: 1.0, y: -1.0).translatedBy(x: 0, y: -size.height)
        return self.applying(scale).applying(invertY)
    }
    
    func mirrored(in width: CGFloat) -> CGPoint {
        var mirroredRect = self
        mirroredRect.x = width - self.x
        return mirroredRect
    }
}

extension URL {
    static let bunny = URL(string: "http://distribution.bbb3d.renderfarming.net/video/mp4/bbb_sunflower_1080p_60fps_normal.mp4")!
}

extension View {
    @ViewBuilder func applyIf<T: View>(_ condition: Bool, transform: (Self) -> T) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}
