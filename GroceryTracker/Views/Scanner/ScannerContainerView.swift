import SwiftUI

/// Full-screen camera scanner interface with mode toggling, reticle overlay, and product lookup.
public struct ScannerContainerView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var store: InventoryStore
    
    @State private var scanMode: LiveScannerView.ScanMode = .barcode
    @State private var isTorchOn: Bool = false
    @State private var scannedBarcode: String = ""
    @State private var recognizedProductName: String = ""
    @State private var recognizedBrand: String = ""
    @State private var recognizedCategory: ItemCategory = .other
    @State private var detectedExpiryDate: Date?
    @State private var detectedDateString: String = ""
    @State private var isLookingUpBarcode: Bool = false
    @State private var showReviewSheet: Bool = false
    @State private var statusMessage: String = "Point camera at barcode"
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            ZStack {
                // MARK: - Live Camera View
                LiveScannerView(
                    scanMode: scanMode,
                    isTorchOn: isTorchOn,
                    onBarcodeRecognized: handleBarcodeScanned,
                    onTextRecognized: handleTextScanned
                )
                .edgesIgnoringSafeArea(.all)
                
                // MARK: - Viewfinder Reticle Overlay
                viewfinderOverlay
                
                // MARK: - Controls & Status Banner
                VStack {
                    // Top Mode Selector
                    modePicker
                        .padding(.top, 10)
                    
                    Spacer()
                    
                    // Status & Detection Card
                    detectionCard
                    
                    // Bottom Control Buttons
                    bottomControls
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 20)
            }
            .navigationTitle("Scan Grocery")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        isTorchOn.toggle()
                    } label: {
                        Image(systemName: isTorchOn ? "flashlight.on.fill" : "flashlight.off.fill")
                            .foregroundColor(.white)
                    }
                }
            }
            .sheet(isPresented: $showReviewSheet) {
                AddEditItemView(
                    prefilledName: recognizedProductName,
                    prefilledBrand: recognizedBrand,
                    prefilledBarcode: scannedBarcode,
                    prefilledCategory: recognizedCategory,
                    prefilledExpiryDate: detectedExpiryDate ?? Calendar.current.date(byAdding: .day, value: 7, to: Date())!,
                    onSaved: {
                        dismiss()
                    }
                )
            }
        }
    }
    
    // MARK: - Mode Picker
    private var modePicker: some View {
        Picker("Scan Mode", selection: $scanMode) {
            Text("📦 Barcode").tag(LiveScannerView.ScanMode.barcode)
            Text("📅 Expiry Date").tag(LiveScannerView.ScanMode.text)
        }
        .pickerStyle(.segmented)
        .background(Color.black.opacity(0.5))
        .cornerRadius(8)
        .onChange(of: scanMode) { _, newMode in
            switch newMode {
            case .barcode:
                statusMessage = "Point camera at grocery barcode"
            case .text:
                statusMessage = "Point camera at printed expiration date"
            }
        }
    }
    
    // MARK: - Viewfinder Overlay
    private var viewfinderOverlay: some View {
        VStack {
            Spacer()
            ZStack {
                RoundedRectangle(cornerRadius: 18)
                    .stroke(Color.white.opacity(0.8), lineWidth: 2)
                    .frame(width: 280, height: scanMode == .barcode ? 180 : 120)
                
                // Laser line indicator
                Rectangle()
                    .fill(Color.accentColor.opacity(0.7))
                    .frame(width: 260, height: 2)
            }
            Spacer()
        }
        .allowsHitTesting(false)
    }
    
    // MARK: - Detection Card
    private var detectionCard: some View {
        VStack(spacing: 8) {
            if isLookingUpBarcode {
                HStack(spacing: 10) {
                    ProgressView()
                        .tint(.white)
                    Text("Looking up product in Open Food Facts...")
                        .font(.subheadline)
                        .foregroundColor(.white)
                }
            } else if !recognizedProductName.isEmpty || detectedExpiryDate != nil {
                VStack(spacing: 6) {
                    if !recognizedProductName.isEmpty {
                        HStack {
                            Image(systemName: "checkmark.seal.fill")
                                .foregroundColor(.green)
                            Text(recognizedProductName)
                                .font(.headline.bold())
                                .foregroundColor(.white)
                                .lineLimit(1)
                        }
                    }
                    if let date = detectedExpiryDate {
                        HStack {
                            Image(systemName: "calendar.badge.clock")
                                .foregroundColor(.orange)
                            Text("Date Found: \(formattedDate(date))")
                                .font(.subheadline.bold())
                                .foregroundColor(.white)
                        }
                    }
                }
            } else {
                Text(statusMessage)
                    .font(.subheadline)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.black.opacity(0.75))
        )
    }
    
    // MARK: - Bottom Controls
    private var bottomControls: some View {
        HStack(spacing: 14) {
            // Manual Add / Skip Scan
            Button {
                showReviewSheet = true
            } label: {
                HStack {
                    Image(systemName: "pencil")
                    Text("Manual Entry")
                }
                .font(.subheadline.bold())
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color.white.opacity(0.2))
                )
            }
            
            // Continue / Confirm
            Button {
                showReviewSheet = true
            } label: {
                HStack {
                    Image(systemName: "arrow.right.circle.fill")
                    Text("Save Item")
                }
                .font(.subheadline.bold())
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color.accentColor)
                )
            }
        }
    }
    
    // MARK: - Recognition Handlers
    
    private func handleBarcodeScanned(_ barcode: String) {
        guard barcode != scannedBarcode else { return }
        self.scannedBarcode = barcode
        self.isLookingUpBarcode = true
        
        Task {
            if let result = await OpenFoodFactsService.shared.lookupProduct(barcode: barcode) {
                await MainActor.run {
                    self.recognizedProductName = result.name
                    self.recognizedBrand = result.brand
                    self.recognizedCategory = result.suggestedCategory
                    self.isLookingUpBarcode = false
                    self.statusMessage = "Found \(result.name)! Now scan date or tap Save."
                }
            } else {
                await MainActor.run {
                    self.isLookingUpBarcode = false
                    self.statusMessage = "Barcode \(barcode) detected. Enter details manually."
                }
            }
        }
    }
    
    private func handleTextScanned(_ text: String) {
        if let parsedDate = DateParserService.shared.extractBestExpiryDate(from: text) {
            self.detectedExpiryDate = parsedDate
            self.detectedDateString = text
        }
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}
