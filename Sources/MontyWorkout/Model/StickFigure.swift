import Foundation
import CoreGraphics

// A tiny angle-based stick figure. Poses are authored as joint angles, so
// limb lengths never change and poses interpolate smoothly into each other.
//
// Angles are degrees measured from "straight down", rotating toward +x:
//   0 = down · 90 = right · 180 = up · 270 (or -90) = left.

struct Limb: Equatable {
    var a: Double   // upper segment (upper arm / thigh)
    var b: Double   // lower segment (forearm / shin)
    init(_ a: Double, _ b: Double) { self.a = a; self.b = b }
}

enum Prop: Equatable { case none, dumbbell, kettlebell }

struct Pose: Equatable {
    var torso: Double        // pelvis → neck
    var head: Double         // neck → head centre
    var armN: Limb           // "near" limbs are drawn bold, "far" ones dim
    var armF: Limb
    var legN: Limb
    var legF: Limb
    var propN: Prop
    var propF: Prop

    init(t: Double = 180, h: Double? = nil,
         an: Limb = Limb(0, 0), af: Limb? = nil,
         ln: Limb = Limb(2, 0), lf: Limb? = nil,
         pn: Prop = .none, pf: Prop = .none) {
        torso = t
        head = h ?? t
        armN = an
        armF = af ?? an
        legN = ln
        legF = lf ?? ln
        propN = pn
        propF = pf
    }
}

enum Bones {
    static let torso = 0.30, neck = 0.04, headR = 0.06
    static let upperArm = 0.17, foreArm = 0.17
    static let thigh = 0.24, shin = 0.24
}

@inline(__always) func dir(_ deg: Double) -> CGPoint {
    let r = deg * .pi / 180
    return CGPoint(x: sin(r), y: cos(r))
}

private func add(_ p: CGPoint, _ d: CGPoint, _ len: Double) -> CGPoint {
    CGPoint(x: p.x + d.x * len, y: p.y + d.y * len)
}

struct Joints {
    var pelvis = CGPoint.zero, neck = CGPoint.zero, head = CGPoint.zero
    var elbowN = CGPoint.zero, handN = CGPoint.zero
    var elbowF = CGPoint.zero, handF = CGPoint.zero
    var kneeN = CGPoint.zero, footN = CGPoint.zero
    var kneeF = CGPoint.zero, footF = CGPoint.zero
}

func joints(of p: Pose) -> Joints {
    var j = Joints()
    j.neck = add(j.pelvis, dir(p.torso), Bones.torso)
    j.head = add(j.neck, dir(p.head), Bones.neck + Bones.headR)
    j.elbowN = add(j.neck, dir(p.armN.a), Bones.upperArm)
    j.handN  = add(j.elbowN, dir(p.armN.b), Bones.foreArm)
    j.elbowF = add(j.neck, dir(p.armF.a), Bones.upperArm)
    j.handF  = add(j.elbowF, dir(p.armF.b), Bones.foreArm)
    j.kneeN = add(j.pelvis, dir(p.legN.a), Bones.thigh)
    j.footN = add(j.kneeN, dir(p.legN.b), Bones.shin)
    j.kneeF = add(j.pelvis, dir(p.legF.a), Bones.thigh)
    j.footF = add(j.kneeF, dir(p.legF.b), Bones.shin)
    return j
}

// MARK: Interpolation

func lerpAngle(_ a: Double, _ b: Double, _ t: Double) -> Double {
    var d = (b - a).truncatingRemainder(dividingBy: 360)
    if d > 180 { d -= 360 }
    if d < -180 { d += 360 }
    return a + d * t
}

extension Limb {
    func lerp(_ o: Limb, _ t: Double) -> Limb { Limb(lerpAngle(a, o.a, t), lerpAngle(b, o.b, t)) }
}

extension Pose {
    func lerp(to o: Pose, _ t: Double) -> Pose {
        var p = Pose(
            t: lerpAngle(torso, o.torso, t),
            h: lerpAngle(head, o.head, t),
            an: armN.lerp(o.armN, t), af: armF.lerp(o.armF, t),
            ln: legN.lerp(o.legN, t), lf: legF.lerp(o.legF, t)
        )
        p.propN = t < 0.5 ? propN : o.propN
        p.propF = t < 0.5 ? propF : o.propF
        return p
    }
}

// MARK: Placement

/// Which joint stays put horizontally while the pose changes.
enum Anchor { case pelvis, foot, hand }

/// Joints translated so the anchor sits at x = 0 and the lowest point rests on y = 0
/// (up is negative y).
func placed(_ p: Pose, anchor: Anchor) -> Joints {
    var j = joints(of: p)
    let dx: Double
    switch anchor {
    case .pelvis: dx = Double(j.pelvis.x)
    case .foot:   dx = Double(j.footN.x)
    case .hand:   dx = Double(j.handN.x)
    }
    let pts: [CGPoint] = [j.pelvis, j.neck, j.elbowN, j.handN, j.elbowF, j.handF,
                          j.kneeN, j.footN, j.kneeF, j.footF,
                          CGPoint(x: j.head.x, y: j.head.y + Bones.headR)]
    let low = pts.map { Double($0.y) }.max() ?? 0

    func mv(_ q: CGPoint) -> CGPoint { CGPoint(x: q.x - dx, y: q.y - low) }
    j.pelvis = mv(j.pelvis); j.neck = mv(j.neck); j.head = mv(j.head)
    j.elbowN = mv(j.elbowN); j.handN = mv(j.handN)
    j.elbowF = mv(j.elbowF); j.handF = mv(j.handF)
    j.kneeN = mv(j.kneeN); j.footN = mv(j.footN)
    j.kneeF = mv(j.kneeF); j.footF = mv(j.footF)
    return j
}

// MARK: Drawing description (shared by the SwiftUI canvas and the test renderer)

struct StickLine { var a: CGPoint; var b: CGPoint; var far: Bool }
struct PropDraw { var center: CGPoint; var angle: Double; var kind: Prop }

struct StickDrawing {
    var lines: [StickLine]
    var head: CGPoint
    var props: [PropDraw]
    var bounds: CGRect
}

func drawing(for pose: Pose, anchor: Anchor) -> StickDrawing {
    let j = placed(pose, anchor: anchor)
    let lines: [StickLine] = [
        // far limbs first so near ones paint over them
        StickLine(a: j.neck, b: j.elbowF, far: true), StickLine(a: j.elbowF, b: j.handF, far: true),
        StickLine(a: j.pelvis, b: j.kneeF, far: true), StickLine(a: j.kneeF, b: j.footF, far: true),
        StickLine(a: j.pelvis, b: j.neck, far: false),
        StickLine(a: j.neck, b: j.head, far: false),
        StickLine(a: j.neck, b: j.elbowN, far: false), StickLine(a: j.elbowN, b: j.handN, far: false),
        StickLine(a: j.pelvis, b: j.kneeN, far: false), StickLine(a: j.kneeN, b: j.footN, far: false),
    ]
    var props: [PropDraw] = []
    if pose.propN != .none { props.append(PropDraw(center: j.handN, angle: pose.armN.b, kind: pose.propN)) }
    if pose.propF != .none { props.append(PropDraw(center: j.handF, angle: pose.armF.b, kind: pose.propF)) }

    var minX = Double.infinity, maxX = -Double.infinity, minY = Double.infinity, maxY = -Double.infinity
    func grow(_ p: CGPoint, _ r: Double = 0) {
        minX = min(minX, Double(p.x) - r); maxX = max(maxX, Double(p.x) + r)
        minY = min(minY, Double(p.y) - r); maxY = max(maxY, Double(p.y) + r)
    }
    for l in lines { grow(l.a); grow(l.b) }
    grow(j.head, Bones.headR)
    for pr in props { grow(pr.center, 0.09) }
    return StickDrawing(lines: lines, head: j.head, props: props,
                        bounds: CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY))
}

/// A view box that fits every pose of an exercise so the figure doesn't jump around.
func unionBounds(_ poses: [Pose], anchor: Anchor) -> CGRect {
    var r = CGRect.null
    for p in poses { r = r.union(drawing(for: p, anchor: anchor).bounds) }
    return r.isNull ? CGRect(x: -0.5, y: -1, width: 1, height: 1) : r
}

/// Map unit-space → view-space so `box` fits `size` with a margin, centred.
struct FigureFit {
    var scale: Double
    var ox: Double
    var oy: Double
    init(box: CGRect, size: CGSize, margin: Double = 0.12) {
        let w = Double(size.width), h = Double(size.height)
        let bw = max(Double(box.width), 0.2), bh = max(Double(box.height), 0.2)
        let s = min(w * (1 - 2 * margin) / bw, h * (1 - 2 * margin) / bh)
        scale = s
        ox = w / 2 - (Double(box.minX) + bw / 2) * s
        oy = h / 2 - (Double(box.minY) + bh / 2) * s
    }
    func map(_ p: CGPoint) -> CGPoint { CGPoint(x: Double(p.x) * scale + ox, y: Double(p.y) * scale + oy) }
}
