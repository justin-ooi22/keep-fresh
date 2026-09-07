import SwiftUI
import VisionKit

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
        label.text = "Camera scanning requires a physical iPhone device.\nUse manual entry or test mock scan below."
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
            label.text = "Camera scanner not available on this device."
            label.textAlignment = .center
            label.textColor = .secondaryLabel
            vc.view = label
            return vc
        }
        
        let recognizedDataTypes: Set<DataScannerViewController.RecognizedDataType>
        switch scanMode {
        case .barcode:
            recognizedDataTypes = [.barcode(symbologies: [.ean13, .ean8, .upce, .code128, .qr])]
        case .text:
            recognizedDataTypes = [.text(languages: ["en"])]
        }
        
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
        if let scanner = uiViewController as? DataScannerViewController {
            // Update torch
            if isTorchOn != context.coordinator.lastTorchState {
                context.coordinator.lastTorchState = isTorchOn
                // VisionKit DataScannerViewController manages torch via AVCaptureDevice
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
            for item in addedItems {
                switch item {
                case .barcode(let barcode):
                    if let payload = barcode.payloadStringValue, payload != lastScannedBarcode {
                        lastScannedBarcode = payload
                        DispatchQueue.main.async {
                            self.parent.onBarcodeRecognized(payload)
                        }
                    }
                case .text(let text):
                    if text.transcript != lastScannedDateString {
                        lastScannedDateString = text.transcript
                        DispatchQueue.main.async {
                            self.parent.onTextRecognized(text.transcript)
                        }
                    }
                @unknown default:
                    break
                }
            }
        }
    }
}
