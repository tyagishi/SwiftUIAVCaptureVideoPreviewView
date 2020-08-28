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
    
    public func updateOutputOrientation(orientation: UIDeviceOrientation) {
        guard let connection = self.photoOutput.connection(with: .video) else { return }
        switch orientation {
        case .portrait:
            connection.videoOrientation = .portrait
        case .portraitUpsideDown:
            connection.videoOrientation = .portraitUpsideDown
        case .landscapeLeft:
            connection.videoOrientation = .landscapeRight
        case .landscapeRight:
            connection.videoOrientation = .landscapeLeft
        default:
            connection.videoOrientation = .portrait
        }

        return
    }

    
    public func takePhoto() {
        // setup photo output orientation
        if let photoOutputConnection = self.photoOutput.connection(with: .video) {
            switch UIDevice.current.orientation {
            case .portrait:
                photoOutputConnection.videoOrientation = .portrait
            case .portraitUpsideDown:
                photoOutputConnection.videoOrientation = .portraitUpsideDown
            case .landscapeLeft:
                photoOutputConnection.videoOrientation = .landscapeRight
            case .landscapeRight:
                photoOutputConnection.videoOrientation = .landscapeLeft
            default:
                break
            }
        }
        let photoSetting = AVCapturePhotoSettings()
        photoSetting.flashMode = .auto
        photoSetting.isHighResolutionPhotoEnabled = false
        photoOutput.capturePhoto(with: photoSetting, delegate: self)
        return
    }
    
    public func photoImageSize() -> CGSize {
        guard let image = self.image else { return .zero }
        return image.size
    }
    
    public func photoImageScaledSize( maxframeSize: CGSize ) -> CGSize {
        guard let image = self.image else { return .zero }
        switch image.imageOrientation {
        case .up:
            print("up")
        case .down:
            print("down")
        case .left:
            print("left")
        case .right:
            print("right")
        default:
            print("unknown")
        }
        if image.imageOrientation == .up || image.imageOrientation == .down {
            let photoSize = photoImageSize()
            let scaleValue = min(maxframeSize.width / photoSize.width, maxframeSize.height / photoSize.height)
            let size = CGSize(width: photoSize.width * scaleValue, height: photoSize.height * scaleValue)
            print("prefered size: \(size)")
            return size
        } else if image.imageOrientation == .left || image.imageOrientation == .right {
            let photoSize = photoImageSize()
            let scaleValue = min(maxframeSize.width / photoSize.width, maxframeSize.height / photoSize.height)
            let tmpsize = CGSize(width: photoSize.width * scaleValue, height: photoSize.height * scaleValue)
            let size = CGSize(width: tmpsize.height, height: tmpsize.width)
            print("prefered size: \(tmpsize) \(size)")
            return tmpsize
        }
        print("unknown photo orientation")
        return .zero
    }
    
    public func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        let imageData = photo.fileDataRepresentation()
        self.image = UIImage(data: imageData!)
        print("taken photo size: \(self.image!.size)")
        
//        print("save into album")
//        UIImageWriteToSavedPhotosAlbum(self.image!, nil, nil, nil)
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

