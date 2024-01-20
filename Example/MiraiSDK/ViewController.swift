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
    
    var faceScreeningConfig = Mirai.shareInstance.defaultFaceScreeningConfig()
    var initFirstFaceStage: Bool = false
    var initSecondFaceStage: Bool = false
    var extectedAction: FaceScreeningStage = .UP
    let ACTIONS: [FaceScreeningStage] = [.UP, .DOWN, .RIGHT, .LEFT, .BLINK, .MOUTHOPEN, .UP_DOWN, .LEFT_RIGHT]
    
    @IBOutlet var lbl: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        Mirai.shareInstance.initialize(apiKey: "ajMbRHTFPtUo9RzpSAMd")
        configure()
        let labelTap = UITapGestureRecognizer(target: self, action: #selector(self.resetFaceScreening(_:)))
        self.lbl.isUserInteractionEnabled = true
        self.lbl.addGestureRecognizer(labelTap)
    }

    @objc func resetFaceScreening(_ sender: UITapGestureRecognizer) {
        Mirai.shareInstance.initFaceScreeningState()
        self.extectedAction = ACTIONS.randomElement()!
//        self.extectedAction = .LEFT_RIGHT
        initFirstFaceStage = true
        initSecondFaceStage = false
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
        
//        currentDevice = backFacingCamera
        currentDevice = frontFacingCamera
        
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
        
        if (currentDevice == frontFacingCamera) {
            cameraPreviewLayer?.connection?.automaticallyAdjustsVideoMirroring = false;
            cameraPreviewLayer?.connection?.isVideoMirrored = false;
        }
        
        
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
        
        if (currentDevice == backFacingCamera) {
            let cardResult = Mirai.shareInstance.scanIDCardSync(sampleBuffer: sampleBuffer, cameraPosition: self.currentDevice.position)
            if cardResult.error != nil {
                print(cardResult.error!)
            }
            else if (cardResult.confidence >= 0.4) {
                print("================Result==================")
                print("-----------------Card-------------------")
                print("Confidence: \(cardResult.confidence)")
                print("Front side: \(cardResult.isFrontSide)")
                print("Front side full: \(String(describing: cardResult.isFrontCardFull))")
                if (cardResult.texts != nil) {
                    print(cardResult.texts!)
                }
                if (cardResult.isFrontCardFull == true) {
                    // available if isFrontCardFull is true
                    // print(result.croppedImage)
                    if (cardResult.classificationResult?.error == nil) {
                        print(cardResult.classificationResult?.mlConfidence as Any)
                    }
                    
                }
            }
        } else if (currentDevice == frontFacingCamera) {
            if (!initFirstFaceStage) {
                Mirai.shareInstance.initFaceScreeningState()
                initFirstFaceStage = true
                extectedAction = ACTIONS.randomElement()!
            }
            
            
//            print("-----------------Face Screening: \(String(describing: extectedAction))-------------------")
            let state = Mirai.shareInstance.twoStageCheckFace(sampleBuffer: sampleBuffer, cameraPosition: self.currentDevice.position, expectedAction: extectedAction, idCardResult: nil, config: faceScreeningConfig)
            if (ACTIONS.contains(state.stage) && !initSecondFaceStage) {
                Mirai.shareInstance.initFaceScreeningSecondStage()
                initSecondFaceStage = true
            }
//            print("- Current required action: \(String(describing: state.stage))")
            DispatchQueue.main.async {
                self.lbl.layer.zPosition = 20000
                let timePassed = NSDate().timeIntervalSince1970 - state.timestamp
                var a = ""
                a += "- Current required action: \(String(describing: state.stage))"
                a += "\n-- Time pass: \(String(format: "%.2f", timePassed)) s."
                a += "\n-- Success: \(String(describing: state.successCount)) Loss: \(String(describing: state.faceLossCount)) Incorrect: \(String(describing: state.faceWrongActionCount))"
                if let faceResult = state.curFaceDetectionResult {
                    a += "\n\n-- Selfie Good size: \(String(describing: faceResult.selfieFace?.isGoodSize))"
                    a += "\n\n-- Selfie Face Full: \(String(describing: faceResult.selfieFace?.isFaceFull))"
                    a += "\n-- Selfie Face Overlap: \(String(describing: faceResult.selfieFace?.faceCardOverlap))"
                    a += "\n-- Selfie Face Front: \(String(describing: faceResult.selfieFace?.isFrontFacing)) (\(String(describing: faceResult.selfieFace?.rot.rotX)), \(String(describing: faceResult.selfieFace?.rot.rotY)), \(String(describing: faceResult.selfieFace?.rot.rotZ)))"
//                    if let selfie = faceResult.selfieFace {
//                        print("-----------------Face Info-------------------")
//                        print("Selfie Face Full: \(String(describing: selfie.isFaceFull))")
//                        print("Selfie Face Overlap: \(String(describing: faceResult.selfieFace?.faceCardOverlap))")
//                        print("Selfie Face Front: \(String(describing: selfie.isFrontFacing)) (\(String(describing: selfie.rot.rotX)), \(String(describing: selfie.rot.rotY)), \(String(describing: selfie.rot.rotZ)))")
//                    }
                    
                }
                self.lbl.text = a
                self.lbl.lineBreakMode = .byWordWrapping
                self.lbl.numberOfLines = 10
            }
            usleep(100000)
//            print("-----------------Face-------------------")
//            let faceResult = Mirai.shareInstance.detectFaces(sampleBuffer: sampleBuffer, cameraPosition: self.currentDevice.position, idCardResult: nil)
//
//            print("Selfie Face Full: \(String(describing: faceResult.selfieFace?.isFaceFull))")
//            print("Selfie Face Overlap: \(String(describing: faceResult.selfieFace?.faceCardOverlap))")
//            print("Selfie Face Front: \(String(describing: faceResult.selfieFace?.isFrontFacing)) (\(String(describing: faceResult.selfieFace?.rot.rotX)), \(String(describing: faceResult.selfieFace?.rot.rotY)), \(String(describing: faceResult.selfieFace?.rot.rotZ)))")
//            print("========================================")
        }
    }
}
