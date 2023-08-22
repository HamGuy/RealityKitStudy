//
//  ContentView.swift
//  RealityDemo
//
//  Created by HamGuy on 2023/8/22.
//

import SwiftUI
import RealityKit
import ARKit

var arView: ARView!

var robot: Experience.Robot!

struct ContentView : View {
    @State var propId: Int = 0
    
    var body: some View {
        
        
        ZStack(alignment: .bottom) {
            ARViewContainer(propId: $propId).edgesIgnoringSafeArea(.all)
            
            HStack {
                Spacer()
                Button {
                    self.propId = self.propId <= 0 ? 0 : self.propId - 1
                } label: {
                    Image(systemName: "arrow.left")
                        .font(.system(size: 30))
                        .foregroundColor(.black)
                }
                Spacer()
                Button {
                    self.takeSnapShot()
                } label: {
                    Image(systemName: "camera")
                        .font(.system(size: 30))
                        .foregroundColor(.black)
                }
                Spacer()
                Button {
                    self.propId = self.propId >= 3 ? 3: self.propId + 1
                
                } label: {
                    Image(systemName: "arrow.right")
                        .font(.system(size: 30))
                        .foregroundColor(.black)
                
                }

                Spacer()


            }
        }
    }
    
    func takeSnapShot() {
        arView.snapshot(saveToHDR: false) { image in
            let compressedImage = UIImage(data: image!.pngData()!)
            UIImageWriteToSavedPhotosAlbum(compressedImage!, nil, nil, nil)
        }
    }
}

struct ARViewContainer: UIViewRepresentable {
    
    @Binding var propId: Int
    
    func makeUIView(context: Context) -> ARView {
        
        arView = ARView(frame: .zero)
        
        arView.session.delegate = context.coordinator
        
        return arView
        
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {
        let arConfiguration = ARFaceTrackingConfiguration()
        uiView.session.run(arConfiguration, options: [.resetTracking, .removeExistingAnchors])
        
        
        arView.scene.anchors.removeAll()
        
        robot = nil
        
        switch propId {
        case 0:
            let anchor = try! Experience.loadEyes()
            uiView.scene.anchors.append(anchor)
        case 1:
            let anchor = try! Experience.loadGlasses()
            uiView.scene.anchors.append(anchor)
        case 2:
            let anchor = try! Experience.loadMustache()
            uiView.scene.anchors.append(anchor)
        case 3:
            let anchor = try! Experience.loadRobot()
            uiView.scene.anchors.append(anchor)
            robot = anchor
        
        default:
            break
            
        }
    }
    
    
    func makeCoordinator() -> ARDelegateHandler {
        ARDelegateHandler(arViewContainer: self)
    }
    
    class ARDelegateHandler: NSObject, ARSessionDelegate {
        var arViewContainer: ARViewContainer
        
        init(arViewContainer: ARViewContainer) {
            self.arViewContainer = arViewContainer
            super.init()
        }
        
        func session(_ session: ARSession, didUpdate frame: ARFrame) {
            guard let _ = robot else { return }
            
            var faceAnchor: ARFaceAnchor?
            for anchor in frame.anchors {
                if let theAnchor = anchor as? ARFaceAnchor {
                    faceAnchor = theAnchor
                    break
                }
            }
            
            
            let blendshapes = faceAnchor?.blendShapes
            guard let eyeBlinkLeft = blendshapes?[.eyeBlinkLeft]?.floatValue,
            let eyeBlinkRight = blendshapes?[.eyeBlinkRight]?.floatValue,
            
            let browInnerUp = blendshapes?[.browInnerUp]?.floatValue,
            let browLeft = blendshapes?[.browDownLeft]?.floatValue,
            let browRight = blendshapes?[.browDownRight]?.floatValue,
            
                    let jawOpen = blendshapes?[.jawOpen]?.floatValue else {
                return
            }
            
            robot.eyeLidL?.orientation = simd_mul(
                // 2
                simd_quatf(
                    angle: degree2Rad(-120 + (90 * eyeBlinkLeft)),
                    axis: [1, 0, 0]),
                // 3
                simd_quatf(
                    angle: degree2Rad((90 * browLeft) - (30 * browInnerUp)),
                    axis: [0, 0, 1])
            )
            // 4
            robot.eyeLidR?.orientation = simd_mul(
                simd_quatf(
                    angle: degree2Rad(-120 + (90 * eyeBlinkRight)),
                    axis: [1, 0, 0]),
                simd_quatf(
                    angle: degree2Rad((-90 * browRight) - (-30 * browInnerUp)),
                    axis: [0, 0, 1])
            )
            
            robot.jaw?.orientation = simd_quatf(angle: degree2Rad(-100+(60*jawOpen)), axis: [1,0,0])
            
            
        }
        
        
        func degree2Rad(_ degree: Float) -> Float {
            return degree * .pi / 180
        }
        
    }
    
}

#if DEBUG
struct ContentView_Previews : PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
#endif
