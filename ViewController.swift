//
//  ViewController.swift
//  HandPoseDetection
//
//  Created by Sam McGarry on 1/28/21.
//

import UIKit
import AVFoundation
import Vision

class ViewController: UIViewController{
    
    
    //MARK: - Properties
    
    var cameraView : CameraView!
    let emojiLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.font = label.font.withSize(50)
        return label
    }()
    
    //MARK: - Init
    override func loadView() {
        view = UIView()
        
        addCameraView()
        addEmojiLabel()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    private let videoDataOutputQueue = DispatchQueue(label: "CameraFeedDataOutput", qos: .userInteractive)
    private var cameraFeedSession: AVCaptureSession?
    private var handPoseRequest = VNDetectHumanHandPoseRequest()
    let message = UILabel()
    
    func addEmojiLabel(){
        view.addSubview(emojiLabel)
        
        emojiLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            emojiLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emojiLabel.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -50),
            emojiLabel.widthAnchor.constraint(equalToConstant: 80),
            emojiLabel.heightAnchor.constraint(equalToConstant: 80)
        ])
    }
    
    func addCameraView(){
        cameraView = CameraView()
        view.addSubview(cameraView)
        
        cameraView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            cameraView.topAnchor.constraint(equalTo: view.topAnchor),
            cameraView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            cameraView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            cameraView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        do {
            if cameraFeedSession == nil {
                cameraView.previewLayer.videoGravity = .resizeAspectFill
                try setupAVSession()
                cameraView.previewLayer.session = cameraFeedSession
            }
            cameraFeedSession?.startRunning()
        } catch {
            AppError.display(error, inViewController: self)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        cameraFeedSession?.stopRunning()
        super.viewWillDisappear(animated)
    }
    
    func setupAVSession() throws {
        // Select a front facing camera, make an input.
        guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) else {
            throw AppError.captureSessionSetup(reason: "Could not find a front facing camera.")
        }
        
        guard let deviceInput = try? AVCaptureDeviceInput(device: videoDevice) else {
            throw AppError.captureSessionSetup(reason: "Could not create video device input.")
        }
        
        let session = AVCaptureSession()
        session.beginConfiguration()
        session.sessionPreset = AVCaptureSession.Preset.high
        
        // Add a video input.
        guard session.canAddInput(deviceInput) else {
            throw AppError.captureSessionSetup(reason: "Could not add video device input to the session")
        }
        session.addInput(deviceInput)
        
        let dataOutput = AVCaptureVideoDataOutput()
        if session.canAddOutput(dataOutput) {
            session.addOutput(dataOutput)
            // Add a video data output.
            dataOutput.alwaysDiscardsLateVideoFrames = true
            dataOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_420YpCbCr8BiPlanarFullRange)]
            dataOutput.setSampleBufferDelegate(self, queue: videoDataOutputQueue)
        } else {
            throw AppError.captureSessionSetup(reason: "Could not add video data output to the session")
        }
        session.commitConfiguration()
        cameraFeedSession = session
    }
    
    var restingHand = true
    
    func processPoints(_ points: [CGPoint?]) {
        
        // Convert points from AVFoundation coordinates to UIKit coordinates.
        let previewLayer = cameraView.previewLayer
        var pointsConverted: [CGPoint] = []
        for point in points {
            pointsConverted.append(previewLayer.layerPointConverted(fromCaptureDevicePoint: point!))
        }

        let thumbTip = pointsConverted[0]
        let indexTip = pointsConverted[1]
        let middleTip = pointsConverted[2]
        let ringTip = pointsConverted[3]
        let littleTip = pointsConverted[4]
        let wrist = pointsConverted[pointsConverted.count - 1]
        
        //let xDistance  = thumbTip.x - wrist.x
        let thumbYDistance  = thumbTip.y - wrist.y
        let indexYDistance = indexTip.y - wrist.y
        let middleYDistance = middleTip.y - wrist.y
        let ringYDistance = ringTip.y - wrist.y
        let littleYDistance = littleTip.y - wrist.y
        
        if(indexYDistance < -200) && (thumbYDistance > -150) && (middleYDistance > -100) && (ringYDistance > -100) && (littleYDistance > -100){
            print("👆")
            DispatchQueue.main.async {
                self.emojiLabel.text = "👆"
            }
        }
        
        if(indexYDistance < -190) && (thumbYDistance > -100) && (middleYDistance < -200) && (ringYDistance > -100) && (littleYDistance > -50){
            print("✌️")
            DispatchQueue.main.async {
                self.emojiLabel.text = "✌️"
            }
        }
        
        if(indexYDistance < -200) && (thumbYDistance > -70) && (middleYDistance < -220) && (ringYDistance < -220) && (littleYDistance < -200){
            print("🖐")
            DispatchQueue.main.async {
                self.emojiLabel.text = "🖐"
            }
        }
        
        if(indexYDistance > -90) && (thumbYDistance < -100) && (middleYDistance > -90) && (ringYDistance > -90) && (littleYDistance > -90){
            print("👊")
            DispatchQueue.main.async {
                self.emojiLabel.text = "👊"
            }
        }
        
        if(indexYDistance > -70) && (thumbYDistance < -100) && (middleYDistance > -50) && (ringYDistance > -50) && (littleYDistance < -140){
            print("🤙")
            DispatchQueue.main.async {
                self.emojiLabel.text = "🤙"
            }
        }

        cameraView.showPoints(pointsConverted)
    }
    
}


extension ViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    public func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
        var thumbTip: CGPoint?
        var indexTip: CGPoint?
        var middleTip: CGPoint?
        var ringTip: CGPoint?
        var littleTip: CGPoint?
        var wrist: CGPoint?

        let handler = VNImageRequestHandler(cmSampleBuffer: sampleBuffer, orientation: .up, options: [:])
        do {
            
            // Perform VNDetectHumanHandPoseRequest
            try handler.perform([handPoseRequest])
            guard let observation = handPoseRequest.results?.first else {
                cameraView.showPoints([])
                return
            }
            
            // Get points for all fingers
            let thumbPoints = try observation.recognizedPoints(.thumb)
            let wristPoints = try observation.recognizedPoints(.all)
            let indexFingerPoints = try observation.recognizedPoints(.indexFinger)
            let middleFingerPoints = try observation.recognizedPoints(.middleFinger)
            let ringFingerPoints = try observation.recognizedPoints(.ringFinger)
            let littleFingerPoints = try observation.recognizedPoints(.littleFinger)
            
            // Extract individual points from Point groups.
            guard let thumbTipPoint = thumbPoints[.thumbTip],
                  let indexTipPoint = indexFingerPoints[.indexTip],
                  let middleTipPoint = middleFingerPoints[.middleTip],
                  let ringTipPoint = ringFingerPoints[.ringTip],
                  let littleTipPoint = littleFingerPoints[.littleTip],
                  let wristPoint = wristPoints[.wrist]
            else {
                cameraView.showPoints([])
                return
            }
            
            let confidenceThreshold: Float = 0.3
            guard   thumbTipPoint.confidence > confidenceThreshold &&
                    indexTipPoint.confidence > confidenceThreshold &&
                    middleTipPoint.confidence > confidenceThreshold &&
                    ringTipPoint.confidence > confidenceThreshold &&
                    littleTipPoint.confidence > confidenceThreshold &&
                    wristPoint.confidence > confidenceThreshold
            
            else {
                cameraView.showPoints([])
                return
            }
            
            // Convert points from Vision coordinates to AVFoundation coordinates.
            thumbTip = CGPoint(x: thumbTipPoint.location.x, y: 1 - thumbTipPoint.location.y)
            indexTip = CGPoint(x: indexTipPoint.location.x, y: 1 - indexTipPoint.location.y)
            middleTip = CGPoint(x: middleTipPoint.location.x, y: 1 - middleTipPoint.location.y)
            ringTip = CGPoint(x: ringTipPoint.location.x, y: 1 - ringTipPoint.location.y)
            littleTip = CGPoint(x: littleTipPoint.location.x, y: 1 - littleTipPoint.location.y)
            wrist = CGPoint(x: wristPoint.location.x, y: 1 - wristPoint.location.y)
            
            DispatchQueue.main.async {
                self.processPoints([thumbTip, indexTip, middleTip, ringTip, littleTip, wrist])
            }
        } catch {
            cameraFeedSession?.stopRunning()
            let error = AppError.visionError(error: error)
            DispatchQueue.main.async {
                error.displayInViewController(self)
            }
        }
    }
}

