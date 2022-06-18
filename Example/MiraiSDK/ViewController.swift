//
//  ViewController.swift
//  MiraiSDK
//
//  Created by northanapon on 05/07/2022.
//  Copyright (c) 2022 northanapon. All rights reserved.
//

import UIKit
import AVFoundation
import MiraiSDK

class ViewController: UIViewController {

    var backFacingCamera: AVCaptureDevice?
    var frontFacingCamera: AVCaptureDevice?
    var currentDevice: AVCaptureDevice!
    
    var cameraPreviewLayer: AVCaptureVideoPreviewLayer?
    
    let captureSession = AVCaptureSession()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        Mirai.shareInstance.initialize(apiKey: "NDIfT5TihAj7wVZi178O")
        configure()
    }

    override func viewWillDisappear(_ animated: Bool) {
        captureSession.stopRunning()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Helper methods
    private func configure() {
        captureSession.sessionPreset = AVCaptureSession.Preset.hd1280x720
        
        let deviceDiscoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInTelephotoCamera,.builtInWideAngleCamera], mediaType: AVMediaType.video, position: .unspecified)
        
        for device in deviceDiscoverySession.devices {
            if device.position == .back {
                backFacingCamera = device
            } else if device.position == .front {
                frontFacingCamera = device
            }
        }
        
        currentDevice = backFacingCamera
        
        guard let captureDeviceInput = try? AVCaptureDeviceInput(device: currentDevice) else {
            return
        }

        let output = AVCaptureVideoDataOutput()
        let queue = DispatchQueue(label: "myqueue")
        output.alwaysDiscardsLateVideoFrames = true
        output.setSampleBufferDelegate(self, queue: queue)
        
        captureSession.addInput(captureDeviceInput)
        captureSession.addOutput(output)
        
        cameraPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        view.layer.addSublayer(cameraPreviewLayer!)
        cameraPreviewLayer?.videoGravity = AVLayerVideoGravity.resizeAspectFill
        cameraPreviewLayer?.frame = view.layer.frame
        

        captureSession.startRunning()
        
    }
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updatePreview()
      }

      func updatePreview() {
        let orientation: AVCaptureVideoOrientation
        switch UIDevice.current.orientation {
          case .portrait:
            orientation = .portrait
          case .landscapeRight:
            orientation = .landscapeLeft
          case .landscapeLeft:
            orientation = .landscapeRight
          case .portraitUpsideDown:
            orientation = .portraitUpsideDown
          default:
            orientation = .portrait
        }
        if cameraPreviewLayer?.connection?.isVideoOrientationSupported == true {
            cameraPreviewLayer?.connection?.videoOrientation = orientation
        }
          cameraPreviewLayer?.frame = view.bounds
      }
}



extension ViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        let result = Mirai.shareInstance.scanIDCardSync(sampleBuffer: sampleBuffer, cameraPosition: self.currentDevice.position)
        if result.error != nil {
            print(result.error!)
        }
        else if (result.confidence >= 0.5) {
            print("Confidence: \(result.confidence)")
            print("Front side: \(result.isFrontSide)")
            print("Front side full: \(String(describing: result.isFrontCardFull))")
            if (result.texts != nil) {
                print(result.texts!)
            }
            if (result.isFrontCardFull == true) {
                // available if isFrontCardFull is true
                // print(result.croppedImage)
                if (result.classificationResult?.error == nil) {
                    print(result.classificationResult?.mlConfidence as Any)
                }
                
            }
        }
    }
}
