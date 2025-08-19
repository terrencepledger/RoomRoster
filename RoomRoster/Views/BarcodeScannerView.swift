#if canImport(AVFoundation) && !targetEnvironment(macCatalyst)
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
        private var legacyScanRequested = false

        init(onScan: @escaping (String) -> Void) {
            self.onScan = onScan
        }

        func requestLegacyScan() {
            legacyScanRequested = true
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
            guard !didScan, legacyScanRequested,
                  let buffer = CMSampleBufferGetImageBuffer(sampleBuffer)
            else { return }

            legacyScanRequested = false

            let request = VNRecognizeTextRequest { [weak self] request, error in
                guard
                    let self = self,
                    !self.didScan,
                    let results = request.results as? [VNRecognizedTextObservation]
                else { return }

                for observation in results {
                    guard let candidate = observation.topCandidates(1).first else { continue }
                    let text = candidate.string.trimmingCharacters(in: .whitespacesAndNewlines)
                    if text.range(of: "^A\\d{4}$", options: .regularExpression) != nil {
                        self.didScan = true
                        self.onScan(text)
                        break
                    }
                }
            }
            request.recognitionLevel = .fast

            let handler = VNImageRequestHandler(cvPixelBuffer: buffer, orientation: .up, options: [:])
            try? handler.perform([request])
        }
    }

    final class ScannerViewController: UIViewController {
        var coordinator: Coordinator?
        private let session = AVCaptureSession()

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

            let doubleTap = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap))
            doubleTap.numberOfTapsRequired = 2
            view.addGestureRecognizer(doubleTap)
        }

        override func viewDidAppear(_ animated: Bool) {
            super.viewDidAppear(animated)
            session.startRunning()
        }

        override func viewWillDisappear(_ animated: Bool) {
            super.viewWillDisappear(animated)
            session.stopRunning()
        }

        @objc private func handleDoubleTap() {
            coordinator?.requestLegacyScan()
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

