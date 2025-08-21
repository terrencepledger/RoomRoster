#if canImport(AVFoundation) && os(iOS)
import SwiftUI
import AVFoundation
import Vision

struct BarcodeScannerView: UIViewControllerRepresentable {
    var onScan: (String) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onScan: onScan)
    }

    func makeUIViewController(context: Context) -> ScannerViewController {
        let controller = ScannerViewController()
        controller.coordinator = context.coordinator
        return controller
    }

    func updateUIViewController(_ uiViewController: ScannerViewController, context: Context) {}

    final class Coordinator: NSObject, AVCaptureMetadataOutputObjectsDelegate, AVCaptureVideoDataOutputSampleBufferDelegate {
        let onScan: (String) -> Void
        private var didScan = false
        private var legacyBoostFrames = 0
        private var frameCounter = 0

        init(onScan: @escaping (String) -> Void) {
            self.onScan = onScan
        }

        func boostLegacyScan() {
            legacyBoostFrames = 60
        }

        func metadataOutput(
            _ output: AVCaptureMetadataOutput,
            didOutput metadataObjects: [AVMetadataObject],
            from connection: AVCaptureConnection
        ) {
            guard
                !didScan,
                let object = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
                let value = object.stringValue
            else { return }
            didScan = true
            onScan(value)
        }

        func captureOutput(
            _ output: AVCaptureOutput,
            didOutput sampleBuffer: CMSampleBuffer,
            from connection: AVCaptureConnection
        ) {
            guard !didScan,
                  let buffer = CMSampleBufferGetImageBuffer(sampleBuffer)
            else { return }

            frameCounter += 1
            if legacyBoostFrames <= 0 && frameCounter % 15 != 0 { return }
            if legacyBoostFrames > 0 { legacyBoostFrames -= 1 }

            let request = VNRecognizeTextRequest { [weak self] request, error in
                guard
                    let self = self,
                    !self.didScan,
                    let results = request.results as? [VNRecognizedTextObservation]
                else { return }

                for observation in results {
                    guard let candidate = observation.topCandidates(1).first else { continue }
                    let text = candidate.string.trimmingCharacters(in: .whitespacesAndNewlines)
                    if candidate.confidence > 0.8,
                       text.range(of: "^A\\d{4}$", options: .regularExpression) != nil {
                        self.didScan = true
                        self.onScan(text)
                        break
                    }
                }
            }
            request.recognitionLevel = legacyBoostFrames > 0 ? .accurate : .fast
            request.minimumTextHeight = 0.05
            request.recognitionLanguages = ["en-US"]
            request.usesLanguageCorrection = false

            let handler = VNImageRequestHandler(
                cvPixelBuffer: buffer,
                orientation: CGImagePropertyOrientation(UIDevice.current.orientation),
                options: [:]
            )
            try? handler.perform([request])
        }
    }

    final class ScannerViewController: UIViewController {
        var coordinator: Coordinator?
        private let session = AVCaptureSession()
        private var preview: AVCaptureVideoPreviewLayer?

        override func viewDidLoad() {
            super.viewDidLoad()
            guard
                let device = AVCaptureDevice.default(for: .video),
                let input = try? AVCaptureDeviceInput(device: device)
            else { return }
            session.addInput(input)

            let metadataOutput = AVCaptureMetadataOutput()
            session.addOutput(metadataOutput)
            metadataOutput.setMetadataObjectsDelegate(coordinator, queue: .main)
            metadataOutput.metadataObjectTypes = [
                .ean8, .ean13, .pdf417, .code128, .code39, .code39Mod43,
                .code93, .upce, .aztec, .qr
            ]

            let videoOutput = AVCaptureVideoDataOutput()
            videoOutput.setSampleBufferDelegate(coordinator, queue: DispatchQueue(label: "TextScanQueue"))
            session.addOutput(videoOutput)

            let preview = AVCaptureVideoPreviewLayer(session: session)
            preview.videoGravity = .resizeAspectFill
            preview.frame = view.layer.bounds
            view.layer.addSublayer(preview)
            self.preview = preview

            NotificationCenter.default.addObserver(
                self,
                selector: #selector(orientationChanged),
                name: UIDevice.orientationDidChangeNotification,
                object: nil
            )

            let doubleTap = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap))
            doubleTap.numberOfTapsRequired = 2
            view.addGestureRecognizer(doubleTap)
        }

        override func viewDidAppear(_ animated: Bool) {
            super.viewDidAppear(animated)
            session.startRunning()
            updatePreviewOrientation()
        }

        override func viewWillDisappear(_ animated: Bool) {
            super.viewWillDisappear(animated)
            session.stopRunning()
        }

        override func viewDidLayoutSubviews() {
            super.viewDidLayoutSubviews()
            preview?.frame = view.bounds
            updatePreviewOrientation()
        }

        deinit {
            NotificationCenter.default.removeObserver(self)
        }

        @objc private func handleDoubleTap() {
            Logger.action("Double Tapped Scan Preview")
            coordinator?.boostLegacyScan()
        }

        @objc private func orientationChanged() {
            updatePreviewOrientation()
        }

        private func updatePreviewOrientation() {
            guard let connection = preview?.connection,
                  connection.isVideoOrientationSupported,
                  let videoOrientation = AVCaptureVideoOrientation(deviceOrientation: UIDevice.current.orientation)
            else { return }
            connection.videoOrientation = videoOrientation
        }
    }
}

private extension AVCaptureVideoOrientation {
    init?(deviceOrientation: UIDeviceOrientation) {
        switch deviceOrientation {
        case .portrait: self = .portrait
        case .portraitUpsideDown: self = .portraitUpsideDown
        case .landscapeLeft: self = .landscapeRight
        case .landscapeRight: self = .landscapeLeft
        default: return nil
        }
    }
}

private extension CGImagePropertyOrientation {
    init(_ deviceOrientation: UIDeviceOrientation) {
        switch deviceOrientation {
        case .portrait: self = .right
        case .portraitUpsideDown: self = .left
        case .landscapeLeft: self = .up
        case .landscapeRight: self = .down
        default: self = .right
        }
    }
}
#else
import SwiftUI

struct BarcodeScannerView: View {
    var onScan: (String) -> Void

    var body: some View {
        Text("Barcode scanning not available")
            .padding()
    }
}
#endif

