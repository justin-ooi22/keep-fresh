import SwiftUI
import VisionKit
import AVFoundation

/// Live camera scanner wrapping Apple's VisionKit DataScannerViewController.
/// Provides live barcode recognition and text/date recognition.
public struct LiveScannerView: UIViewControllerRepresentable {
    public enum ScanMode {
        case barcode
        case text
    }
    
    public var scanMode: ScanMode
    public var isTorchOn: Bool
    public var onBarcodeRecognized: (String) -> Void
    public var onTextRecognized: (String) -> Void
    
    public init(
        scanMode: ScanMode,
        isTorchOn: Bool,
        onBarcodeRecognized: @escaping (String) -> Void,
        onTextRecognized: @escaping (String) -> Void
    ) {
        self.scanMode = scanMode
        self.isTorchOn = isTorchOn
        self.onBarcodeRecognized = onBarcodeRecognized
        self.onTextRecognized = onTextRecognized
    }
    
    public func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    public func makeUIViewController(context: Context) -> UIViewController {
        #if targetEnvironment(simulator)
        // Simulator fallback
        let vc = UIViewController()
        let label = UILabel()
        label.text = String(localized: "Camera scanning requires a physical iPhone device.\nUse manual entry or test mock scan below.")
        label.textAlignment = .center
        label.numberOfLines = 0
        label.textColor = .secondaryLabel
        label.translatesAutoresizingMaskIntoConstraints = false
        vc.view.addSubview(label)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: vc.view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: vc.view.centerYAnchor),
            label.leadingAnchor.constraint(greaterThanOrEqualTo: vc.view.leadingAnchor, constant: 20),
            label.trailingAnchor.constraint(lessThanOrEqualTo: vc.view.trailingAnchor, constant: -20)
        ])
        return vc
        #else
        guard DataScannerViewController.isSupported && DataScannerViewController.isAvailable else {
            let vc = UIViewController()
            let label = UILabel()
            label.text = String(localized: "Camera scanner not available on this device.")
            label.textAlignment = .center
            label.textColor = .secondaryLabel
            vc.view = label
            return vc
        }
        
        // Include both barcode and text types simultaneously so both are continuously recognized
        let recognizedDataTypes: Set<DataScannerViewController.RecognizedDataType> = [
            .barcode(symbologies: [.ean13, .ean8, .upce, .code128, .qr]),
            .text(languages: ["en", "de", "fr", "es", "it"])
        ]
        
        let scanner = DataScannerViewController(
            recognizedDataTypes: recognizedDataTypes,
            qualityLevel: .balanced,
            recognizesMultipleItems: true,
            isHighFrameRateTrackingEnabled: true,
            isHighlightingEnabled: true
        )
        scanner.delegate = context.coordinator
        
        try? scanner.startScanning()
        return scanner
        #endif
    }
    
    public func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        #if !targetEnvironment(simulator)
        if isTorchOn != context.coordinator.lastTorchState {
            context.coordinator.lastTorchState = isTorchOn
            updateTorch(isOn: isTorchOn)
        }
        #endif
    }
    
    /// Controls the camera torch asynchronously on a background thread so AVCaptureDevice hardware lock does not block the main thread or freeze camera preview.
    private func updateTorch(isOn: Bool) {
        DispatchQueue.global(qos: .userInitiated).async {
            guard let device = AVCaptureDevice.default(for: .video), device.hasTorch else { return }
            do {
                try device.lockForConfiguration()
                device.torchMode = isOn ? .on : .off
                device.unlockForConfiguration()
            } catch {
                print("Failed to configure device torch on background thread: \(error.localizedDescription)")
            }
        }
    }
    
    public static func dismantleUIViewController(_ uiViewController: UIViewController, coordinator: Coordinator) {
        #if !targetEnvironment(simulator)
        // Ensure torch is turned off on background thread when leaving scanner
        DispatchQueue.global(qos: .userInitiated).async {
            guard let device = AVCaptureDevice.default(for: .video), device.hasTorch else { return }
            do {
                try device.lockForConfiguration()
                if device.torchMode == .on {
                    device.torchMode = .off
                }
                device.unlockForConfiguration()
            } catch {
                // Ignore error on dismantle
            }
        }
        #endif
    }
    
    public class Coordinator: NSObject, DataScannerViewControllerDelegate {
        let parent: LiveScannerView
        var lastTorchState: Bool = false
        private var lastScannedBarcode: String?
        private var lastScannedDateString: String?
        
        init(_ parent: LiveScannerView) {
            self.parent = parent
        }
        
        public func dataScanner(_ dataScanner: DataScannerViewController, didAdd addedItems: [RecognizedItem], allItems: [RecognizedItem]) {
            processItems(addedItems)
        }
        
        public func dataScanner(_ dataScanner: DataScannerViewController, didUpdate updatedItems: [RecognizedItem], allItems: [RecognizedItem]) {
            processItems(updatedItems)
        }
        
        private func processItems(_ items: [RecognizedItem]) {
            for item in items {
                switch item {
                case .barcode(let barcode):
                    if let payload = barcode.payloadStringValue, payload != lastScannedBarcode {
                        lastScannedBarcode = payload
                        DispatchQueue.main.async {
                            self.parent.onBarcodeRecognized(payload)
                        }
                    }
                case .text(let text):
                    let transcript = text.transcript
                    if transcript != lastScannedDateString {
                        lastScannedDateString = transcript
                        DispatchQueue.main.async {
                            self.parent.onTextRecognized(transcript)
                        }
                    }
                @unknown default:
                    break
                }
            }
        }
    }
}
