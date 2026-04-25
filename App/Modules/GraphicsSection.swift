import SwiftUI

struct GraphicsSection: View {
    @State private var animOn = false
    @State private var gestureOn = false
    @State private var arOn = false
    @State private var showAR = false

    var body: some View {
        VStack(spacing: 16) {
            FeatureCard(titleKey: "gfx_anim", symbol: "sparkles", tint: .purple, isOn: $animOn) {
                AnimationDemo()
            }
            FeatureCard(titleKey: "gfx_gestures", symbol: "hand.draw.fill", tint: .purple, isOn: $gestureOn) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("gfx_gestures_desc").font(.callout).foregroundStyle(.secondary)
                    GestureDemo()
                }
            }
            FeatureCard(titleKey: "gfx_ar", symbol: "arkit", tint: .purple, isOn: $arOn) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("gfx_ar_desc").font(.callout).foregroundStyle(.secondary)
                    Text("requires_real_device").font(.caption).foregroundStyle(.orange)
                    ActionButton(titleKey: "gfx_open_ar", systemImage: "arkit", tint: .purple) { showAR = true }
                }
            }
            .sheet(isPresented: $showAR) {
                ARDemoView().ignoresSafeArea()
            }
        }
    }
}

struct AnimationDemo: View {
    @State private var t: CGFloat = 0
    var body: some View {
        VStack(spacing: 12) {
            Text("gfx_anim_desc").font(.callout).foregroundStyle(.secondary)
            ZStack {
                ForEach(0..<6) { i in
                    Circle()
                        .fill(Color(hue: Double(i) / 6, saturation: 0.6, brightness: 1).opacity(0.7))
                        .frame(width: 28, height: 28)
                        .offset(x: 60 * cos(t + CGFloat(i) * .pi / 3),
                                y: 60 * sin(t + CGFloat(i) * .pi / 3))
                        .blur(radius: 0.5)
                }
            }
            .frame(height: 160)
            .onAppear {
                withAnimation(.linear(duration: 4).repeatForever(autoreverses: false)) {
                    t = .pi * 2
                }
            }
            ActionButton(titleKey: "gfx_play", systemImage: "play.fill", tint: .purple) {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.5)) {
                    t += .pi
                }
            }
        }
    }
}

struct GestureDemo: View {
    @State private var offset: CGSize = .zero
    @State private var scale: CGFloat = 1
    @State private var angle: Angle = .zero
    @State private var taps = 0

    var body: some View {
        VStack {
            Text("Taps: \(taps)").font(.caption.monospaced())
            ZStack {
                RoundedRectangle(cornerRadius: 22)
                    .fill(LinearGradient(colors: [.purple, .pink], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 160, height: 160)
                    .rotationEffect(angle)
                    .scaleEffect(scale)
                    .offset(offset)
                    .gesture(
                        DragGesture()
                            .onChanged { offset = $0.translation }
                            .onEnded { _ in withAnimation(.spring()) { offset = .zero } }
                    )
                    .gesture(MagnificationGesture().onChanged { scale = $0 }.onEnded { _ in withAnimation { scale = 1 } })
                    .gesture(RotationGesture().onChanged { angle = $0 }.onEnded { _ in withAnimation { angle = .zero } })
                    .onTapGesture { taps += 1 }
                    .shadow(color: .purple.opacity(0.4), radius: 15)
            }
            .frame(height: 220)
        }
    }
}

#if canImport(ARKit)
import ARKit
import RealityKit

struct ARDemoView: UIViewRepresentable {
    func makeUIView(context: Context) -> ARView {
        let v = ARView(frame: .zero)
        let cfg = ARWorldTrackingConfiguration()
        cfg.planeDetection = [.horizontal]
        v.session.run(cfg)
        let mesh = MeshResource.generateBox(size: 0.1)
        let mat = SimpleMaterial(color: .purple, isMetallic: true)
        let entity = ModelEntity(mesh: mesh, materials: [mat])
        let anchor = AnchorEntity(plane: .horizontal)
        anchor.addChild(entity)
        v.scene.addAnchor(anchor)
        return v
    }
    func updateUIView(_ uiView: ARView, context: Context) {}
}
#else
struct ARDemoView: View { var body: some View { Text("AR unavailable").padding() } }
#endif
