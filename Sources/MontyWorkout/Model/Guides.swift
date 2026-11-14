import Foundation
import CoreGraphics

// Step-by-step "how to do it" guides. Each step is a line of spoken-style
// Hinglish plus a stick-figure pose. The same text is shown on screen and read
// aloud, so it's written the way you'd actually say it.

enum GuideScene: Equatable { case floor, wall(Double) }

struct GuideStep {
    let text: String
    let pose: Pose
}

struct Guide {
    let steps: [GuideStep]
    let anchor: Anchor
    let scene: GuideScene
    let box: CGRect

    init(anchor: Anchor = .foot, scene: GuideScene = .floor, _ steps: [GuideStep]) {
        self.steps = steps
        self.anchor = anchor
        self.scene = scene
        var b = unionBounds(steps.map(\.pose), anchor: anchor)
        if case .wall(let x) = scene { b = b.union(CGRect(x: x, y: b.minY - 0.05, width: 0.02, height: b.height + 0.05)) }
        self.box = b
    }

    /// What gets read aloud before the set.
    var spoken: String {
        steps.enumerated().map { i, s in
            let lead = ["Pehle", "Phir", "Uske baad", "Aakhir mein", "Phir", "Aur ab"][min(i, 5)]
            return "\(lead), \(s.text)"
        }.joined(separator: " ")
    }
}

private func S(_ text: String, _ pose: Pose) -> GuideStep { GuideStep(text: text, pose: pose) }

/// Front-facing pose: far limbs mirror the near ones unless overridden.
private func front(t: Double = 180, an: Limb, af: Limb? = nil,
                   ln: Limb = Limb(12, 12), pn: Prop = .none, pf: Prop = .none) -> Pose {
    Pose(t: t, an: an, af: af ?? Limb(-an.a, -an.b),
         ln: ln, lf: Limb(-ln.a, -ln.b), pn: pn, pf: pf)
}

enum GuideBank {
    static func guide(_ key: String?) -> Guide? { key.flatMap { all[$0] } }

    // MARK: shared poses

    private static let plank  = Pose(t: 115, h: 105, ln: Limb(-65, -65))
    private static let pushBottom = Pose(t: 98, h: 95, an: Limb(-80, 64), ln: Limb(-82, -82))
    private static let upDog  = Pose(t: 140, h: 150, an: Limb(0, 0), ln: Limb(-85, -85))
    private static let downDog = Pose(t: 50, h: 50, an: Limb(50, 50), ln: Limb(-30, -30))
    private static let lying  = Pose(t: 270, h: 270, an: Limb(80, 90), ln: Limb(94, 94), lf: Limb(86, 86))
    private static let seated = Pose(t: 180, an: Limb(40, 40), ln: Limb(80, -80), lf: Limb(78, -78))

    // MARK: builders that differ only by prop

    private static func rowGuide(_ prop: Prop) -> Guide {
        let legs = (n: Limb(15, -10), f: Limb(10, -15))
        func r(_ arm: Limb) -> Pose {
            Pose(t: 115, h: 130, an: arm, af: Limb(-45, -45), ln: legs.n, lf: legs.f, pn: prop)
        }
        return Guide(anchor: .foot, [
            S("Ek haath thigh par tikao, doosre mein weight. Kamar se aage jhuko, peeth flat — jaise table ki surface.", r(Limb(0, 0))),
            S("Kohni ko peeche pasliyon ki taraf kheencho, bell kamar ke paas. Shoulder blade ko peeche squeeze karo.", r(Limb(-100, -10))),
            S("Ek second ruko, phir dheere haath seedha neeche. Kamar mat ghumao — sirf haath chalne do.", r(Limb(-40, -5))),
        ])
    }

    // MARK: all guides

    static let all: [String: Guide] = [

        "warmup": Guide(anchor: .pelvis, [
            S("Kandhe goal-goal ghumao — paanch baar aage, paanch baar peeche.",
              front(an: Limb(85, 75))),
            S("Ab bade circles banao haathon se, poora kandha khulne do.",
              front(an: Limb(160, 150))),
            S("Kalaiyan bhi ghuma lo. Phir kamar se halka aage jhuko — hamstring mein halka khinchaav, zabardasti nahi.",
              Pose(t: 60, h: 48, an: Limb(0, 25), ln: Limb(5, -5), lf: Limb(2, -8))),
        ]),

        "grip": Guide(anchor: .pelvis, [
            S("Gripper haath mein pakdo, kohni pet ke paas, forearm thoda upar.",
              front(an: Limb(12, 95))),
            S("Poori taakat se band karo — pura squeeze, ek second hold.",
              front(an: Limb(9, 102))),
            S("Dheere se chhodo. Poora range use karo, jaldi mat karo.",
              front(an: Limb(14, 90))),
        ]),

        "lateral": Guide(anchor: .pelvis, [
            S("Seedhe khade ho jao, pair kandhon jitne khule. Dono haath mein dumbbell, haath jaanghon ke paas.",
              front(an: Limb(12, 6), pn: .dumbbell, pf: .dumbbell)),
            S("Kohni ko halka mod ke, dono haath side se kandhe ki height tak uthao. Kohni pehle upar jaaye — jaise jug se paani pour kar rahe ho.",
              front(an: Limb(92, 75), pn: .dumbbell, pf: .dumbbell)),
            S("Ek second ruko, phir dheere dheere neeche laao. Jhatka nahi, swing nahi — control se.",
              front(an: Limb(45, 40), pn: .dumbbell, pf: .dumbbell)),
        ]),

        "dbpress": Guide(anchor: .pelvis, [
            S("Dumbbell kandhon ke paas pakdo, kohni neeche aur thodi aage. Pair kandhon jitne khule, pet andar, glutes tight.",
              front(an: Limb(35, 170), pn: .dumbbell, pf: .dumbbell)),
            S("Ab seedha upar dabao — jaise chhat ko dhakka de rahe ho. Upar pahunch ke haath seedhe, kaanon ke paas.",
              front(an: Limb(165, 178), pn: .dumbbell, pf: .dumbbell)),
            S("Dheere se wapas kandhon tak laao. Jhatke se nahi — control se.",
              front(an: Limb(40, 168), pn: .dumbbell, pf: .dumbbell)),
        ]),

        "kbpress": Guide(anchor: .pelvis, [
            S("Kettlebell ek haath se rack position mein — kandhe ke paas, kohni pet se chipki. Doosra haath side mein, pair kandhon jitne khule.",
              front(an: Limb(35, 170), af: Limb(-12, -4), pn: .kettlebell)),
            S("Saans bahar chhodte hue seedha upar dabao. Haath kaan ke saath, kamar peeche mat murne do — pet tight.",
              front(an: Limb(165, 178), af: Limb(-12, -4), pn: .kettlebell)),
            S("Dheere se wapas kandhe tak. Har rep control ke saath.",
              front(an: Limb(38, 168), af: Limb(-12, -4), pn: .kettlebell)),
        ]),

        "curl": Guide(anchor: .pelvis, [
            S("Seedhe khade, dono haath mein dumbbell, haath neeche, hathelian aage. Kohni pasliyon se chipki.",
              front(an: Limb(10, 5), pn: .dumbbell, pf: .dumbbell)),
            S("Kohni ko hilaye bina dumbbell ko kandhe ki taraf curl karo. Upar squeeze — bicep tight.",
              front(an: Limb(6, 172), pn: .dumbbell, pf: .dumbbell)),
            S("Ab dheere dheere neeche, poora haath seedha karo. Neeche jaane mein double time lagao.",
              front(an: Limb(8, 110), pn: .dumbbell, pf: .dumbbell)),
        ]),

        "highpull": Guide(anchor: .foot, [
            S("Kettlebell pairon ke beech zameen par. Kamar se aage jhuko, peeth seedhi, ghutne halke mude.",
              Pose(t: 140, h: 150, an: Limb(-15, -25), ln: Limb(20, -15), lf: Limb(15, -10), pn: .kettlebell)),
            S("Ab kamar se tez dhakka do — hips aage — aur bell ko chin tak kheencho. Kohni upar aur bahar, haath kohni se neeche.",
              Pose(t: 178, h: 180, an: Limb(120, 25), af: Limb(115, 20), ln: Limb(2, 0), lf: Limb(-2, 0), pn: .kettlebell)),
            S("Chin ki height par ek pal, phir control se neeche. Bell seene ke paas rahe.",
              Pose(t: 160, h: 165, an: Limb(50, 15), ln: Limb(10, -8), lf: Limb(8, -6), pn: .kettlebell)),
        ]),

        "swing": Guide(anchor: .foot, [
            S("Bell ko pairon ke thoda aage rakho. Kamar se jhuko, peeth seedhi, bell ko pairon ke beech peeche jhoolne do.",
              Pose(t: 135, h: 150, an: Limb(-15, -25), ln: Limb(20, -15), lf: Limb(15, -10), pn: .kettlebell)),
            S("Ab hips tez aage dhakelo, glutes tight. Bell apne aap seene ki height tak uthegi. Haath sirf pakde hain, uthate nahi.",
              Pose(t: 185, h: 185, an: Limb(90, 90), ln: Limb(2, 0), lf: Limb(-2, 0), pn: .kettlebell)),
            S("Bell neeche aaye to phir kamar se peeche jhuko, haath se nahi. Har rep ek naya dhakka.",
              Pose(t: 150, h: 160, an: Limb(30, 20), ln: Limb(15, -10), lf: Limb(12, -8), pn: .kettlebell)),
        ]),

        "kbrow": rowGuide(.kettlebell),
        "dbrow": rowGuide(.dumbbell),

        "pushup": Guide(anchor: .foot, [
            S("Haath kandhon ke neeche, zameen par. Sar se edi tak ek seedhi line — pet andar, glutes tight.", plank),
            S("Kohni 45 degree par mudte hue seena zameen ke paas laao. Kohni bahar phailao mat.", pushBottom),
            S("Zameen ko dhakka do, haath poore seedhe. Body ek line mein rahe, kamar latke nahi.", plank),
        ]),

        "plank": Guide(anchor: .foot, [
            S("Haath kandhon ke neeche zameen par, ghutne neeche. Ye starting position hai.",
              Pose(t: 100, h: 100, ln: Limb(0, -80))),
            S("Ghutne uthao, pair peeche — sar se edi tak ek seedhi line. Kamar latke nahi, hips upar nahi.", plank),
            S("Pet andar, glutes tight, saans chalti rahe. Zameen ke ek point ko dekhte raho.",
              Pose(t: 115, h: 108, ln: Limb(-65, -65))),
        ]),

        "boat": Guide(anchor: .pelvis, [
            S("Zameen par baith jao, ghutne mude, pair zameen par. Peeth seedhi, seena upar.",
              Pose(an: Limb(70, 70), ln: Limb(125, 55), lf: Limb(120, 50))),
            S("Thoda peeche jhuko aur pair uthao — shins zameen ke parallel. Seena khula, peeth gol nahi.",
              Pose(t: 205, h: 200, an: Limb(105, 85), ln: Limb(135, 88), lf: Limb(133, 85))),
            S("Haath aage seedhe, pair halke kaanpe to bhi hold. Saans mat roko.",
              Pose(t: 205, h: 200, an: Limb(90, 90), ln: Limb(135, 88), lf: Limb(133, 85))),
        ]),

        "mtnclimber": Guide(anchor: .hand, [
            S("Plank position — haath kandhon ke neeche, body ek seedhi line.", plank),
            S("Ek ghutna tezi se seene ki taraf. Hips upar mat uthne do.",
              Pose(t: 115, h: 105, ln: Limb(55, -35), lf: Limb(-65, -65))),
            S("Ab pair badlo — jaise jagah par daud rahe ho. Tez, par control mein.",
              Pose(t: 115, h: 105, ln: Limb(-65, -65), lf: Limb(55, -35))),
        ]),

        "tgu": Guide(anchor: .pelvis, [
            S("Peeth ke bal let jao, ek ghutna mudha, pair zameen par. Bell wala haath seedha aasman ki taraf, nazar bell par.",
              Pose(t: 270, h: 270, an: Limb(180, 180), af: Limb(80, 90), ln: Limb(130, 50), lf: Limb(92, 92), pn: .kettlebell)),
            S("Bell par nazar rakhte hue doosri kohni par upar aao. Bell wala haath seedha lock.",
              Pose(t: 217, h: 225, an: Limb(180, 180), af: Limb(0, -90), ln: Limb(130, 50), lf: Limb(92, 92), pn: .kettlebell)),
            S("Ab haath par tik ke baithne ki position — hips ko thoda upar uthao.",
              Pose(t: 195, h: 190, an: Limb(180, 180), af: Limb(2, 0), ln: Limb(130, 50), lf: Limb(92, 92), pn: .kettlebell)),
            S("Pair peeche laake khade ho jao. Bell hamesha upar, nazar bell par. Wapas usi raaste se neeche.",
              Pose(an: Limb(180, 180), af: Limb(75, 75), ln: Limb(3, 0), lf: Limb(-3, 0), pn: .kettlebell)),
        ]),

        "run": Guide(anchor: .pelvis, [
            S("Seedhe khade, nazar saamne, kandhe dheele. Thoda sa aage jhuko — kamar se nahi, poori body se.",
              Pose(t: 174, an: Limb(5, 5), ln: Limb(3, 0), lf: Limb(-3, 0))),
            S("Kohni 90 degree par, haath aage-peeche jhoolne do. Mutthi dheeli — jaise haath mein chips ka packet ho.",
              Pose(t: 172, h: 175, an: Limb(20, 110), af: Limb(-40, 30), ln: Limb(45, -10), lf: Limb(-30, -80))),
            S("Chhote kadam, pair seene ke neeche land karo. Saans lay mein — teen kadam andar, teen bahar.",
              Pose(t: 172, h: 175, an: Limb(-40, 30), af: Limb(20, 110), ln: Limb(-30, -80), lf: Limb(45, -10))),
        ]),

        "sunsal": Guide(anchor: .pelvis, [
            S("Tadasana mein khade ho jao — pair jude, haath seene ke saamne namaste mein. Saans ek dum shaant.",
              Pose(an: Limb(5, 95), ln: Limb(2, 0), lf: Limb(-2, 0))),
            S("Saans andar lete hue haath upar, halke peeche jhuko. Seena khula.",
              Pose(t: 190, h: 200, an: Limb(190, 195), ln: Limb(2, 0))),
            S("Saans bahar chhodte hue aage jhuko, haath zameen ki taraf — ghutne thode mude to koi baat nahi.",
              Pose(t: 58, h: 45, an: Limb(0, 30), ln: Limb(5, -5), lf: Limb(2, -8))),
            S("Pair peeche le jao, plank se neeche — chaturanga. Kohni pasliyon se chipki, body ek line.", pushBottom),
            S("Saans andar, seena aage-upar — upward dog. Kandhe kaanon se door, hips zameen ke paas.", upDog),
            S("Saans bahar, hips upar-peeche — downward dog. Edi zameen ki taraf, haath dabao. Phir flow karte raho.", downDog),
        ]),

        "warrior1": Guide(anchor: .pelvis, [
            S("Pair ek-doosre se teen-chaar foot door. Peeche wala pair 45 degree bahar ghumao, agla pair seedha.",
              Pose(ln: Limb(25, 25), lf: Limb(-25, -25))),
            S("Aage wala ghutna 90 degree tak mudo, ghutna edi ke upar. Peeche wala pair seedha, hips saamne ki taraf square.",
              Pose(ln: Limb(80, 0), lf: Limb(-55, -55))),
            S("Saans andar, dono haath seedhe upar, kaanon ke paas. Seena khula, nazar saamne. Ek minute yahin ruko, phir doosri side.",
              Pose(t: 182, h: 185, an: Limb(178, 178), ln: Limb(80, 0), lf: Limb(-55, -55))),
        ]),

        "warrior2": Guide(anchor: .pelvis, [
            S("Pair chaude — lagbhag teen foot ka gap. Agla pair bahar ki taraf, peeche wala thoda andar.",
              Pose(ln: Limb(28, 28), lf: Limb(-28, -28))),
            S("Aage wala ghutna mudo, seedha edi ke upar. Kandhe hips ke upar, seedhe.",
              Pose(ln: Limb(70, 5), lf: Limb(-48, -48))),
            S("Dono haath zameen ke parallel phailao. Nazar aage wale haath ki ungliyon par. Saans chalti rahe.",
              Pose(an: Limb(90, 90), af: Limb(-90, -90), ln: Limb(70, 5), lf: Limb(-48, -48))),
        ]),

        "halfmoon": Guide(anchor: .foot, [
            S("Ek pair par khade, aage jhuko. Neeche wala haath zameen ya block par, kandhe ke neeche.",
              Pose(t: 140, h: 140, an: Limb(0, 0), af: Limb(150, 150), ln: Limb(0, 0), lf: Limb(-40, -40))),
            S("Peeche ka pair upar uthao, seedha — jaise deewar ko pair se dhakka de rahe ho. Balance dhoondo.",
              Pose(t: 100, h: 100, an: Limb(0, 0), af: Limb(175, 175), ln: Limb(0, 0), lf: Limb(-80, -85))),
            S("Upar wala haath aasman ki taraf, seena khol do — chhati deewar ki taraf. Saans lete hue, phir doosri side.",
              Pose(t: 90, h: 95, an: Limb(0, 0), af: Limb(180, 180), ln: Limb(0, 0), lf: Limb(-90, -90))),
        ]),

        "sideplank": Guide(anchor: .foot, [
            S("Ek haath zameen par, kandhe ke seedhe neeche. Pair ek ke upar ek, body side mein.",
              Pose(t: 116, h: 112, an: Limb(0, 0), af: Limb(80, 20), ln: Limb(-64, -64))),
            S("Kamar upar uthao — sir se edi tak seedhi line. Hips latke nahi.",
              Pose(t: 116, h: 112, an: Limb(0, 0), af: Limb(180, 180), ln: Limb(-64, -64))),
            S("Upar wala haath aasman ki taraf. Pet tight, saans lete raho.",
              Pose(t: 116, h: 112, an: Limb(0, 0), af: Limb(180, 180), ln: Limb(-64, -64), lf: Limb(-100, -100))),
        ]),

        "vinyasa": Guide(anchor: .hand, [
            S("Downward dog — hips upar, haath dabao, edi zameen ki taraf.", downDog),
            S("Aage aake plank — kandhe haathon ke upar, body seedhi line.", plank),
            S("Chaturanga — kohni pasliyon se chipki, aadha push-up neeche.", pushBottom),
            S("Upward dog — seena aage-upar, hips neeche. Phir wapas downward dog. Ye ek round.", upDog),
        ]),

        "childs": Guide(anchor: .pelvis, [
            S("Ghutno par baith jao, pair ke anguthe aapas mein, ghutne thode khule.",
              Pose(an: Limb(5, 5), ln: Limb(0, -88))),
            S("Kulhe edi ki taraf peeche, haath aage phailate hue neeche jhuko.",
              Pose(t: 130, h: 120, an: Limb(100, 95), ln: Limb(45, -88))),
            S("Maatha zameen par. Haath aage phailaye, saans peeth ki taraf bhejo — pasliyon ke andar. Har saans ke saath thoda aur dheela.",
              Pose(t: 85, h: 70, an: Limb(90, 88), ln: Limb(92, -90))),
        ]),

        "backbend": Guide(anchor: .hand, [
            S("Pet ke bal — haath kandhon ke neeche, kohni pasliyon se chipki, pairon ke upar ki taraf zameen par.", pushBottom),
            S("Haath dabao, seena aage aur upar uthao — kulhe zameen ke paas. Kandhe kaanon se door.", upDog),
            S("Nazar thodi upar, gardan lambi — peeth ko mat todo. Saans lete raho. Ho gaya to neeche aa jao, aaram.",
              Pose(t: 135, h: 165, an: Limb(0, 0), ln: Limb(-85, -85))),
        ]),

        "camel": Guide(anchor: .pelvis, [
            S("Ghutno par khade, ghutne kulhon jitne khule. Dono haath kamar ke neeche, ungliyan neeche.",
              Pose(an: Limb(-45, 45), ln: Limb(0, -88))),
            S("Kohniyan peeche khinch ke seena upar uthao. Kulhe aage dabao — glutes tight.",
              Pose(t: 205, h: 225, an: Limb(-30, -30), ln: Limb(0, -88))),
            S("Agar aaraam se ho to haath edi tak, warna kamar par hi rakho. Gardan ko zabardasti peeche mat girao. Saans lete raho.",
              Pose(t: 225, h: 245, an: Limb(-8, -8), ln: Limb(0, -88))),
        ]),

        "savasana": Guide(anchor: .pelvis, [
            S("Seedhe let jao. Pair thode khule, haath side mein, hathelian upar.", lying),
            S("Aankhein band. Poori body ka wazan zameen ko de do. Jabda dheela, maatha dheela.", lying),
            S("Saans ko apne aap chalne do. Kuch nahi karna, kahin nahi jaana.", lying),
        ]),

        "bodyscan": Guide(anchor: .pelvis, [
            S("Seedhe let jao, aankhein band. Do baar gehri saans lo.", lying),
            S("Ab dhyaan pair ki ungliyon se shuru karke dheere dheere upar le jao — ek ek hissa.", lying),
            S("Jahan kasaav ya thakaan mile, bas notice karo. Kuch theek nahi karna, sirf dekhna.", lying),
        ]),

        "seated": Guide(anchor: .pelvis, [
            S("Peeth seedhi karke baith jao — cross-legged ya edi par. Haath ghutnon par, kandhe dheele.", seated),
            S("Aankhein band karo. Jabda dheela, jeebh talu se laga ke chhod do.", seated),
        ]),

        "ujjayi": Guide(anchor: .pelvis, [
            S("Aaram se baith jao, peeth seedhi. Aankhein band, kandhe dheele.", seated),
            S("Naak se saans andar, chaar tak. Gale ko halka sa sankuchit karo — samundar jaisi awaaz aani chahiye.", seated),
            S("Naak se hi bahar, chaar tak — gale mein 'ha' ki awaaz. Aise das baar.", seated),
        ]),

        "boxbreath": Guide(anchor: .pelvis, [
            S("Seedhe let jao ya baith jao. Aankhein band, jabda dheela.", lying),
            S("Chaar tak andar. Chaar tak roko.", lying),
            S("Chaar tak bahar. Chaar tak khaali roko. Paanch baar.", lying),
        ]),

        "breath478": Guide(anchor: .pelvis, [
            S("Peeth ke bal let jao, aankhein band. Jeebh ki nok talu se laga do.", lying),
            S("Naak se chaar tak andar. Saat tak roko.", lying),
            S("Muh se aath tak bahar — 'whoosh' ki awaaz ke saath. Chaar baar.", lying),
        ]),

        "kapalabhati": Guide(anchor: .pelvis, [
            S("Cross-legged ya edi par baith jao. Peeth seedhi, haath ghutnon par.", seated),
            S("Naak se tez tez saans bahar phenko — jaise chheenk rahe ho. Pet andar jaaye. Andar wali saans apne aap aati hai.", seated),
            S("Tees baar. Phir das second aaram, saans normal. Chakkar aaye to ruk jao.", seated),
        ]),

        "nadi": Guide(anchor: .pelvis, [
            S("Seedha baith jao. Daayein haath ki do ungliyan maathe ke beech mein, anguutha daayein naak par, anaamika baayein naak par.",
              Pose(an: Limb(140, 250), af: Limb(35, 35), ln: Limb(80, -80), lf: Limb(78, -78))),
            S("Daayein naak band karo, baayein se andar. Baayein band karke daayein se bahar. Phir daayein se andar, baayein se bahar.",
              Pose(an: Limb(140, 250), af: Limb(35, 35), ln: Limb(80, -80), lf: Limb(78, -78))),
        ]),

        "legswall": Guide(anchor: .pelvis, scene: .wall(0.035), [
            S("Deewar ke paas side se baith jao, phir peeth ke bal let ke dono pair deewar par chadha do.",
              Pose(t: 270, h: 270, an: Limb(85, 90), ln: Limb(180, 180))),
            S("Kulhe deewar ke paas, ghutne aur kulhe 90 degree. Haath side mein, hathelian upar — saans lete raho.",
              Pose(t: 270, h: 270, an: Limb(80, 90), ln: Limb(178, 178))),
        ]),
    ]
}
