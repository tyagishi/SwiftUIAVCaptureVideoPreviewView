//
//  AVCaputureModel.swift
//  CameraWithAVFoundation
//
//  Created by Tomoaki Yagishita on 2020/08/11.
//

import Foundation
import AVFoundation
import UIKit

public class AVCaptureModel : NSObject, AVCapturePhotoCaptureDelegate, ObservableObject {
    public var captureSession: AVCaptureSession
    public var videoInput: AVCaptureDeviceInput!
    public var photoOutput: AVCapturePhotoOutput
    @Published public var image: UIImage?
    
    public override init() {
        self.captureSession = AVCaptureSession()
        self.photoOutput = AVCapturePhotoOutput()
    }
    
    public func setupSession() {
        captureSession.beginConfiguration()
        guard let videoCaputureDevice = AVCaptureDevice.default(for: .video) else { return }

//        videoCaputureDevice.ramp(toVideoZoomFactor: <#T##CGFloat#>, withRate: <#T##Float#>)

        guard let videoInput = try? AVCaptureDeviceInput(device: videoCaputureDevice) else { return }
        self.videoInput = videoInput
        guard captureSession.canAddInput(videoInput) else { return }
        captureSession.addInput(videoInput)

        guard captureSession.canAddOutput(photoOutput) else { return }
        captureSession.sessionPreset = .photo
        captureSession.addOutput(photoOutput)
        
        captureSession.commitConfiguration()
    }
    
    public func updateInputOrientation(orientation: UIDeviceOrientation) {
        for conn in captureSession.connections {
            conn.videoOrientation = ConvertUIDeviceOrientationToAVCaptureVideoOrientation(deviceOrientation: orientation)
        }
    }
    
    
    public func takePhoto() {
        let photoSetting = AVCapturePhotoSettings()
        photoSetting.flashMode = .auto
        photoSetting.isHighResolutionPhotoEnabled = false
        photoOutput.capturePhoto(with: photoSetting, delegate: self)
        return
    }
    
    public func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        let imageData = photo.fileDataRepresentation()
        self.image = UIImage(data: imageData!)
    }
    
    func getImageFromSampleBuffer(sampleBuffer: CMSampleBuffer) ->UIImage? {
         guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
             return nil
         }
         CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
         let baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer)
         let width = CVPixelBufferGetWidth(pixelBuffer)
         let height = CVPixelBufferGetHeight(pixelBuffer)
         let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)
         let colorSpace = CGColorSpaceCreateDeviceRGB()
         let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue)
         guard let context = CGContext(data: baseAddress, width: width, height: height, bitsPerComponent: 8, bytesPerRow: bytesPerRow, space: colorSpace, bitmapInfo: bitmapInfo.rawValue) else {
             return nil
         }
         guard let cgImage = context.makeImage() else {
             return nil
         }
         let image = UIImage(cgImage: cgImage, scale: 1, orientation:.right)
         CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly)
         return image
     }
}

public func ConvertUIDeviceOrientationToAVCaptureVideoOrientation(deviceOrientation: UIDeviceOrientation) -> AVCaptureVideoOrientation {
    switch deviceOrientation {
    case .portrait:
        return .portrait
    case .portraitUpsideDown:
        return .portraitUpsideDown
    case .landscapeLeft:
        return .landscapeRight
    case .landscapeRight:
        return .landscapeLeft
    default:
        return .portrait
    }
}

