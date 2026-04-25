import SwiftUI
import UIKit
import AVFoundation
import PhotosUI
import Vision

struct CameraSection: View {
    @State private var captureOn = false
    @State private var galleryOn = false
    @State private var qrOn = false
    @State private var ocrOn = false

    @State private var showCamera = false
    @State private var showQR = false
    @State private var showPicker = false
    @State private var pickedImage: UIImage?
    @State private var lastQR: String?
    @State private var ocrText: String?
    @State private var ocrInProgress = false

    var body: some View {
        VStack(spacing: 16) {
            FeatureCard(titleKey: "camera_capture", symbol: "camera.fill", tint: .blue, isOn: $captureOn) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("camera_capture_desc").font(.callout).foregroundStyle(.secondary)
                    ActionButton(titleKey: "camera_open", systemImage: "camera.aperture", tint: .blue) {
                        showCamera = true
                    }
                    if let img = pickedImage {
                        Image(uiImage: img).resizable().scaledToFit().frame(maxHeight: 180).clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
            }
            .sheet(isPresented: $showCamera) {
                ImagePicker(sourceType: .camera) { image in pickedImage = image }
                    .ignoresSafeArea()
            }

            FeatureCard(titleKey: "camera_gallery", symbol: "photo.on.rectangle.angled", tint: .blue, isOn: $galleryOn) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("camera_gallery_desc").font(.callout).foregroundStyle(.secondary)
                    ActionButton(titleKey: "camera_pick", systemImage: "photo.fill", tint: .blue) { showPicker = true }
                    if let img = pickedImage {
                        Image(uiImage: img).resizable().scaledToFit().frame(maxHeight: 180).clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
            }
            .sheet(isPresented: $showPicker) {
                PhotoPickerView(image: $pickedImage)
            }

            FeatureCard(titleKey: "camera_qr", symbol: "qrcode.viewfinder", tint: .blue, isOn: $qrOn) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("camera_qr_desc").font(.callout).foregroundStyle(.secondary)
                    ActionButton(titleKey: "camera_scan", systemImage: "qrcode.viewfinder", tint: .blue) { showQR = true }
                    if let qr = lastQR {
                        Text(qr).font(.callout.monospaced()).textSelection(.enabled)
                    }
                }
            }
            .sheet(isPresented: $showQR) {
                QRScannerView { code in
                    lastQR = code; showQR = false
                }
                .ignoresSafeArea()
            }

            FeatureCard(titleKey: "camera_ocr", symbol: "doc.text.viewfinder", tint: .blue, isOn: $ocrOn) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("camera_ocr_desc").font(.callout).foregroundStyle(.secondary)
                    ActionButton(titleKey: "camera_recognize", systemImage: "text.viewfinder", tint: .blue) {
                        runOCR()
                    }
                    if ocrInProgress { ProgressView() }
                    if let t = ocrText {
                        Text(t).font(.callout).textSelection(.enabled)
                    }
                }
            }
        }
    }

    private func runOCR() {
        guard let img = pickedImage, let cg = img.cgImage else { return }
        ocrInProgress = true
        let request = VNRecognizeTextRequest { req, _ in
            let res = req.results as? [VNRecognizedTextObservation] ?? []
            let text = res.compactMap { $0.topCandidates(1).first?.string }.joined(separator: "\n")
            DispatchQueue.main.async {
                ocrText = text.isEmpty ? "—" : text
                ocrInProgress = false
            }
        }
        request.recognitionLevel = .accurate
        request.recognitionLanguages = ["ru-RU", "en-US"]
        DispatchQueue.global(qos: .userInitiated).async {
            try? VNImageRequestHandler(cgImage: cg).perform([request])
        }
    }
}

struct ImagePicker: UIViewControllerRepresentable {
    var sourceType: UIImagePickerController.SourceType = .camera
    var onPick: (UIImage) -> Void

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let p = UIImagePickerController()
        p.sourceType = UIImagePickerController.isSourceTypeAvailable(sourceType) ? sourceType : .photoLibrary
        p.delegate = context.coordinator
        return p
    }
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    func makeCoordinator() -> Coord { Coord(self) }

    final class Coord: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        init(_ p: ImagePicker) { parent = p }
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let img = info[.originalImage] as? UIImage { parent.onPick(img) }
            picker.dismiss(animated: true)
        }
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) { picker.dismiss(animated: true) }
    }
}

struct PhotoPickerView: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var cfg = PHPickerConfiguration(); cfg.filter = .images; cfg.selectionLimit = 1
        let p = PHPickerViewController(configuration: cfg); p.delegate = context.coordinator; return p
    }
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}
    func makeCoordinator() -> Coord { Coord(self) }

    final class Coord: NSObject, PHPickerViewControllerDelegate {
        let parent: PhotoPickerView
        init(_ p: PhotoPickerView) { parent = p }
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)
            guard let r = results.first else { return }
            if r.itemProvider.canLoadObject(ofClass: UIImage.self) {
                r.itemProvider.loadObject(ofClass: UIImage.self) { obj, _ in
                    DispatchQueue.main.async {
                        if let img = obj as? UIImage { self.parent.image = img }
                    }
                }
            }
        }
    }
}

struct QRScannerView: UIViewControllerRepresentable {
    var onCode: (String) -> Void
    func makeUIViewController(context: Context) -> UIViewController {
        let vc = QRController(); vc.onCode = onCode; return vc
    }
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}

final class QRController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    var onCode: ((String) -> Void)?
    private let session = AVCaptureSession()
    private var preview: AVCaptureVideoPreviewLayer!

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        guard let device = AVCaptureDevice.default(for: .video),
              let input = try? AVCaptureDeviceInput(device: device),
              session.canAddInput(input) else { return }
        session.addInput(input)
        let output = AVCaptureMetadataOutput()
        if session.canAddOutput(output) {
            session.addOutput(output)
            output.setMetadataObjectsDelegate(self, queue: .main)
            output.metadataObjectTypes = [.qr, .ean13, .ean8, .pdf417, .code128, .code39, .code93, .upce, .aztec, .dataMatrix]
        }
        preview = AVCaptureVideoPreviewLayer(session: session)
        preview.frame = view.bounds
        preview.videoGravity = .resizeAspectFill
        view.layer.addSublayer(preview)
        DispatchQueue.global(qos: .userInitiated).async { [session] in session.startRunning() }
    }
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        preview.frame = view.bounds
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        session.stopRunning()
    }
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        guard let obj = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
              let str = obj.stringValue else { return }
        session.stopRunning()
        onCode?(str)
    }
}
