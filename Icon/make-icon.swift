import AppKit
import CoreGraphics

// Draws the Monty Workout icon: a stick figure pressing a kettlebell overhead.
// Usage: make-icon <style: coral|dark> <out.png>

let style = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "coral"
let outPath = CommandLine.arguments.count > 2 ? CommandLine.arguments[2] : "icon.png"

let S: CGFloat = 1024
let cs = CGColorSpaceCreateDeviceRGB()
guard let ctx = CGContext(data: nil, width: Int(S), height: Int(S), bitsPerComponent: 8, bytesPerRow: 0,
                          space: cs, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { fatalError() }

func rgb(_ hex: UInt32, _ a: CGFloat = 1) -> CGColor {
    CGColor(red: CGFloat((hex >> 16) & 0xFF) / 255, green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255, alpha: a)
}

// Squircle (macOS-style continuous corners)
func squircle(_ r: CGRect, n: CGFloat = 5) -> CGPath {
    let p = CGMutablePath()
    let a = r.width / 2, b = r.height / 2, cx = r.midX, cy = r.midY
    let steps = 360
    for i in 0...steps {
        let t = CGFloat(i) / CGFloat(steps) * 2 * .pi
        let c = cos(t), s = sin(t)
        let x = cx + a * (c < 0 ? -1 : 1) * pow(abs(c), 2 / n)
        let y = cy + b * (s < 0 ? -1 : 1) * pow(abs(s), 2 / n)
        i == 0 ? p.move(to: CGPoint(x: x, y: y)) : p.addLine(to: CGPoint(x: x, y: y))
    }
    p.closeSubpath()
    return p
}

let tile = CGRect(x: 100, y: 100, width: 824, height: 824)
let shape = squircle(tile)

// Drop shadow under the tile
ctx.saveGState()
ctx.setShadow(offset: CGSize(width: 0, height: -14), blur: 28, color: rgb(0x000000, 0.45))
ctx.addPath(shape); ctx.setFillColor(rgb(0x000000)); ctx.fillPath()
ctx.restoreGState()

// Tile fill
ctx.saveGState()
ctx.addPath(shape); ctx.clip()
let coral = style == "coral"
let top = coral ? rgb(0xFF9070) : rgb(0x24242B)
let bottom = coral ? rgb(0xFF5A3C) : rgb(0x0C0C0F)
let grad = CGGradient(colorsSpace: cs, colors: [top, bottom] as CFArray, locations: [0, 1])!
ctx.drawLinearGradient(grad, start: CGPoint(x: 0, y: tile.maxY), end: CGPoint(x: 0, y: tile.minY), options: [])
if !coral {
    // soft coral glow behind the figure
    let glow = CGGradient(colorsSpace: cs, colors: [rgb(0xFF7A5C, 0.35), rgb(0xFF7A5C, 0)] as CFArray, locations: [0, 1])!
    ctx.drawRadialGradient(glow, startCenter: CGPoint(x: 512, y: 470), startRadius: 0,
                           endCenter: CGPoint(x: 512, y: 470), endRadius: 420, options: [])
} else {
    // gentle top sheen
    let sheen = CGGradient(colorsSpace: cs, colors: [rgb(0xFFFFFF, 0.22), rgb(0xFFFFFF, 0)] as CFArray, locations: [0, 1])!
    ctx.drawLinearGradient(sheen, start: CGPoint(x: 0, y: tile.maxY), end: CGPoint(x: 0, y: tile.midY), options: [])
}

// --- Figure: front view, one-arm kettlebell press ---
let pose = Pose(t: 180, h: 178,
                an: Limb(140, 172), af: Limb(-52, -62),
                ln: Limb(15, 15), lf: Limb(-15, -15))
let j = placed(pose, anchor: .pelvis)

// Kettlebell balanced above the near hand (unit space, y up = negative)
let bellR = 0.10
let bellC = CGPoint(x: Double(j.handN.x) + 0.005, y: Double(j.handN.y) - bellR * 1.05 - 0.01)
let handleTop = Double(bellC.y) - bellR * 1.62

// Fit everything (figure + bell + floor) into a 610 px box, centred in the tile.
let minX = min(Double(j.handF.x), Double(j.footF.x), Double(j.footN.x), Double(j.head.x) - Bones.headR) - 0.03
let maxX = max(Double(j.footN.x), Double(j.footF.x), Double(bellC.x) + bellR, Double(j.handN.x)) + 0.03
let minY = handleTop - 0.02
let maxY = 0.02
let scale = 640.0 / max(maxX - minX, maxY - minY)
let cx = 512.0, cy = 500.0
let midX = (minX + maxX) / 2, midY = (minY + maxY) / 2
func P(_ p: CGPoint) -> CGPoint {
    CGPoint(x: cx + (Double(p.x) - midX) * scale, y: cy - (Double(p.y) - midY) * scale)
}

let figureColor = coral ? rgb(0x17171B) : rgb(0xF4F4F6)
let accentColor = coral ? rgb(0xFFFFFF) : rgb(0xFF7A5C)
let lw = CGFloat(0.058 * scale)

ctx.setLineCap(.round); ctx.setLineJoin(.round)
ctx.setStrokeColor(figureColor)
ctx.setLineWidth(lw)
func line(_ a: CGPoint, _ b: CGPoint) { ctx.move(to: P(a)); ctx.addLine(to: P(b)); ctx.strokePath() }
line(j.pelvis, j.neck)
line(j.neck, j.elbowF); line(j.elbowF, j.handF)
line(j.neck, j.elbowN); line(j.elbowN, j.handN)
line(j.pelvis, j.kneeN); line(j.kneeN, j.footN)
line(j.pelvis, j.kneeF); line(j.kneeF, j.footF)

// Head (solid, a touch larger than the skeleton's)
let hc = P(j.head), hr = CGFloat(Bones.headR * scale * 1.25)
ctx.setFillColor(figureColor)
ctx.fillEllipse(in: CGRect(x: hc.x - hr, y: hc.y - hr, width: hr * 2, height: hr * 2))

// Kettlebell: ball + arched handle
let bc = P(bellC)
let br = CGFloat(bellR * scale)
ctx.setFillColor(accentColor)
ctx.fillEllipse(in: CGRect(x: bc.x - br, y: bc.y - br, width: br * 2, height: br * 2))
ctx.setStrokeColor(accentColor)
ctx.setLineWidth(CGFloat(0.036 * scale))
let hw = br * 0.66
let handle = CGMutablePath()
handle.move(to: CGPoint(x: bc.x - hw, y: bc.y + br * 0.62))
handle.addCurve(to: CGPoint(x: bc.x + hw, y: bc.y + br * 0.62),
                control1: CGPoint(x: bc.x - hw * 1.15, y: bc.y + br * 1.75),
                control2: CGPoint(x: bc.x + hw * 1.15, y: bc.y + br * 1.75))
ctx.addPath(handle); ctx.strokePath()

// Floor line
ctx.setStrokeColor(coral ? rgb(0x17171B, 0.30) : rgb(0xFFFFFF, 0.16))
ctx.setLineWidth(10)
let f0 = P(CGPoint(x: minX + 0.03, y: 0.012)), f1 = P(CGPoint(x: maxX - 0.03, y: 0.012))
ctx.move(to: f0); ctx.addLine(to: f1); ctx.strokePath()

ctx.restoreGState()

// Thin inner highlight on the tile edge
ctx.saveGState()
ctx.addPath(shape)
ctx.setStrokeColor(rgb(0xFFFFFF, coral ? 0.25 : 0.10))
ctx.setLineWidth(3)
ctx.strokePath()
ctx.restoreGState()

let rep = NSBitmapImageRep(cgImage: ctx.makeImage()!)
try! rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: outPath))
print("wrote \(outPath)")
