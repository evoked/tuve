//
//  EyeTrackingManager.swift
//  FocusGuard
//
//  Manages camera access and eye tracking using Vision framework
//

import Foundation
import AVFoundation
import Vision
import AppKit
import Combine

/// Tracks the user's eye/face presence to determine if they are focused on the screen
class EyeTrackingManager: NSObject, ObservableObject {
    static let shared = EyeTrackingManager()

    // MARK: - Published Properties
    @Published var isTracking = false
    @Published var isFaceDetected = false
    @Published var isLookingAtScreen = false
    @Published var eyeConfidence: Float = 0.0
    @Published var cameraPermissionGranted = false
    @Published var errorMessage: String?

    // MARK: - Private Properties
    private var captureSession: AVCaptureSession?
    private var videoOutput: AVCaptureVideoDataOutput?
    private let videoQueue = DispatchQueue(label: "com.focusguard.videoqueue", qos: .userInteractive)

    private var faceDetectionRequest: VNDetectFaceLandmarksRequest?
    private var sequenceHandler = VNSequenceRequestHandler()

    // Tracking state
    private var consecutiveFramesWithFace = 0
    private var consecutiveFramesWithoutFace = 0
    private let faceThreshold = 5 // Frames needed to confirm face presence/absence
    private var lastEyePositions: [(left: CGPoint, right: CGPoint)] = []
    private let eyePositionHistorySize = 10

    // Focus detection parameters
    private var lookAwayStartTime: Date?
    private let lookAwayThreshold: TimeInterval = 3.0 // Seconds before considered distracted

    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization
    private override init() {
        super.init()
        setupFaceDetection()
    }

    // MARK: - Public Methods

    /// Request camera permission and start tracking
    func startTracking() {
        checkCameraPermission { [weak self] granted in
            DispatchQueue.main.async {
                self?.cameraPermissionGranted = granted
                if granted {
                    self?.setupCaptureSession()
                    self?.beginCapture()
                } else {
                    self?.errorMessage = "Camera permission is required for eye tracking. Please enable in System Settings > Privacy & Security > Camera."
                }
            }
        }
    }

    /// Stop eye tracking
    func stopTracking() {
        captureSession?.stopRunning()
        DispatchQueue.main.async {
            self.isTracking = false
            self.isFaceDetected = false
            self.isLookingAtScreen = false
        }
    }

    /// Check if user has been looking away for too long
    func isDistracted() -> Bool {
        guard let startTime = lookAwayStartTime else { return false }
        return Date().timeIntervalSince(startTime) > lookAwayThreshold
    }

    // MARK: - Private Methods

    private func checkCameraPermission(completion: @escaping (Bool) -> Void) {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            completion(true)
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                completion(granted)
            }
        case .denied, .restricted:
            completion(false)
        @unknown default:
            completion(false)
        }
    }

    private func setupCaptureSession() {
        let session = AVCaptureSession()
        session.sessionPreset = .medium

        // Get the built-in camera (FaceTime camera on Mac)
        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front)
                ?? AVCaptureDevice.default(for: .video) else {
            DispatchQueue.main.async {
                self.errorMessage = "No camera found. Eye tracking requires a camera."
            }
            return
        }

        do {
            let input = try AVCaptureDeviceInput(device: camera)
            if session.canAddInput(input) {
                session.addInput(input)
            }

            let output = AVCaptureVideoDataOutput()
            output.setSampleBufferDelegate(self, queue: videoQueue)
            output.alwaysDiscardsLateVideoFrames = true
            output.videoSettings = [
                kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
            ]

            if session.canAddOutput(output) {
                session.addOutput(output)
            }

            self.captureSession = session
            self.videoOutput = output

        } catch {
            DispatchQueue.main.async {
                self.errorMessage = "Failed to setup camera: \(error.localizedDescription)"
            }
        }
    }

    private func beginCapture() {
        guard let session = captureSession, !session.isRunning else { return }

        videoQueue.async { [weak self] in
            session.startRunning()
            DispatchQueue.main.async {
                self?.isTracking = true
                self?.errorMessage = nil
            }
        }
    }

    private func setupFaceDetection() {
        faceDetectionRequest = VNDetectFaceLandmarksRequest { [weak self] request, error in
            self?.handleFaceDetectionResults(request: request, error: error)
        }
        faceDetectionRequest?.revision = VNDetectFaceLandmarksRequestRevision3
    }

    private func handleFaceDetectionResults(request: VNRequest, error: Error?) {
        if let error = error {
            print("Face detection error: \(error)")
            return
        }

        guard let observations = request.results as? [VNFaceObservation] else { return }

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            if let face = observations.first {
                self.processFaceObservation(face)
            } else {
                self.handleNoFaceDetected()
            }
        }
    }

    private func processFaceObservation(_ face: VNFaceObservation) {
        consecutiveFramesWithFace += 1
        consecutiveFramesWithoutFace = 0

        if consecutiveFramesWithFace >= faceThreshold {
            isFaceDetected = true
        }

        // Check eye landmarks for gaze direction
        if let landmarks = face.landmarks {
            let isLooking = analyzeEyeGaze(landmarks: landmarks, faceRect: face.boundingBox)
            updateLookingStatus(isLooking: isLooking)
        }

        // Calculate overall confidence
        eyeConfidence = face.confidence
    }

    private func analyzeEyeGaze(landmarks: VNFaceLandmarks2D, faceRect: CGRect) -> Bool {
        guard let leftEye = landmarks.leftEye,
              let rightEye = landmarks.rightEye,
              let leftPupil = landmarks.leftPupil,
              let rightPupil = landmarks.rightPupil else {
            return false
        }

        // Get normalized positions
        let leftEyePoints = leftEye.normalizedPoints
        let rightEyePoints = rightEye.normalizedPoints
        let leftPupilPoint = leftPupil.normalizedPoints.first ?? .zero
        let rightPupilPoint = rightPupil.normalizedPoints.first ?? .zero

        // Calculate eye centers
        let leftEyeCenter = calculateCenter(of: leftEyePoints)
        let rightEyeCenter = calculateCenter(of: rightEyePoints)

        // Store positions for stability analysis
        lastEyePositions.append((left: leftPupilPoint, right: rightPupilPoint))
        if lastEyePositions.count > eyePositionHistorySize {
            lastEyePositions.removeFirst()
        }

        // Analyze if pupils are roughly centered (looking at screen)
        let leftOffset = distance(from: leftPupilPoint, to: leftEyeCenter)
        let rightOffset = distance(from: rightPupilPoint, to: rightEyeCenter)

        // Check if both eyes are open (eye aspect ratio)
        let leftEyeOpen = isEyeOpen(eyePoints: leftEyePoints)
        let rightEyeOpen = isEyeOpen(eyePoints: rightEyePoints)

        // Consider looking at screen if:
        // 1. Eyes are open
        // 2. Pupils are roughly centered (not looking far left/right)
        // 3. Face is facing forward (based on face rect position)
        let eyesOpen = leftEyeOpen && rightEyeOpen
        let gazeForward = leftOffset < 0.15 && rightOffset < 0.15
        let faceCentered = faceRect.midX > 0.2 && faceRect.midX < 0.8

        return eyesOpen && gazeForward && faceCentered
    }

    private func calculateCenter(of points: [CGPoint]) -> CGPoint {
        guard !points.isEmpty else { return .zero }
        let sumX = points.reduce(0) { $0 + $1.x }
        let sumY = points.reduce(0) { $0 + $1.y }
        return CGPoint(x: sumX / CGFloat(points.count), y: sumY / CGFloat(points.count))
    }

    private func distance(from p1: CGPoint, to p2: CGPoint) -> CGFloat {
        return sqrt(pow(p2.x - p1.x, 2) + pow(p2.y - p1.y, 2))
    }

    private func isEyeOpen(eyePoints: [CGPoint]) -> Bool {
        guard eyePoints.count >= 6 else { return false }
        // Simple eye aspect ratio calculation
        // Points are arranged around the eye, so vertical distance / horizontal distance
        let height = abs(eyePoints[1].y - eyePoints[5].y) + abs(eyePoints[2].y - eyePoints[4].y)
        let width = abs(eyePoints[3].x - eyePoints[0].x) * 2
        let ratio = height / max(width, 0.001)
        return ratio > 0.15 // Eye is considered open if ratio is above threshold
    }

    private func updateLookingStatus(isLooking: Bool) {
        if isLooking {
            isLookingAtScreen = true
            lookAwayStartTime = nil
        } else {
            if lookAwayStartTime == nil {
                lookAwayStartTime = Date()
            }
            // Only mark as not looking after threshold
            if isDistracted() {
                isLookingAtScreen = false
            }
        }
    }

    private func handleNoFaceDetected() {
        consecutiveFramesWithoutFace += 1
        consecutiveFramesWithFace = 0

        if consecutiveFramesWithoutFace >= faceThreshold {
            isFaceDetected = false
            isLookingAtScreen = false

            if lookAwayStartTime == nil {
                lookAwayStartTime = Date()
            }
        }
    }
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate
extension EyeTrackingManager: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

        let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .up, options: [:])

        do {
            if let request = faceDetectionRequest {
                try imageRequestHandler.perform([request])
            }
        } catch {
            print("Failed to perform face detection: \(error)")
        }
    }
}
