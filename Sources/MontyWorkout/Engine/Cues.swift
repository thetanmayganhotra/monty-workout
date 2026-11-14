import Foundation

/// Rotating spoken lines (Hinglish) — short motivation and form reminders that
/// come after the step-by-step instructions. A per-key index is persisted, so
/// every time you do an exercise you get the next line, cycling over the days.
enum CueBank {

    // MARK: Per-movement pools (keyed by ExerciseStep.cueKey)

    static let pools: [String: [String]] = [
        "press": [
            "Seedha upar. Aaj kandhe bolenge — tum bas sun lena.",
            "Pet tight, glutes tight. Kamar peeche mat mudne do.",
            "Upar lock, neeche control. Bas itna hi.",
            "Ye wahi kandhe hain jo stage par chaude dikhenge. Dabao.",
            "Jhatka nahi, control. Har rep saaf.",
        ],
        "row": [
            "Kohni peeche, shoulder blade squeeze. Peeth se kheencho, haath se nahi.",
            "Peeth flat, table ki tarah. Kamar mat ghumao.",
            "Ek second upar ruko. Muscle wahin sunta hai.",
            "Lawnmower start kar rahe ho — par tameez se.",
        ],
        "highpull": [
            "Kulhon se dhakka, haath to bas saath chal rahe hain.",
            "Kohni upar aur bahar. Bell seene ke paas.",
            "Tez upar, dheere neeche. Yahi formula hai.",
            "Explosive! Par form ke saath.",
        ],
        "swing": [
            "Kulhe aage dhakelo — jaise peeche se car ka darwaza band kar rahe ho.",
            "Haath nahi uthate, kulhe uthate hain. Bell to bas jhool rahi hai.",
            "Seena upar, glutes patthar. Ekdum solid.",
            "Ye free cardio bhi hai, peeth bhi mazboot. Do kaam ek mein.",
        ],
        "tgu": [
            "Dheere dheere. Ye photo nahi, poori film hai.",
            "Nazar bell par. Ek ek joint ka control.",
            "Boring lag raha hai? Matlab sahi kar rahe ho.",
            "Jaldi kuch nahi. Slow motion mein.",
        ],
        "lateral": [
            "Kohni pehle, haath baad mein — jaise jug se paani daal rahe ho.",
            "Halka weight, zero swing. Pandrah rep ko pachaas jaisa banao.",
            "Kandhe jalne chahiye. Wahi to maqsad hai.",
            "Upar ek second ruko, neeche dheere.",
        ],
        "plank": [
            "Sar se edi tak ek line. Sab kuch tight.",
            "Koi nahi dekh raha ki tum kitna brace kar rahe ho. Phir bhi zyada karo.",
            "Zameen ke ek point ko ghoorte raho. Staring contest — jeetna hai.",
            "Phone scroll karne mein isse zyada time lagta hai. Ruko.",
        ],
        "sideplank": [
            "Kandha haath ke upar, kamar upar. Ek seedhi line.",
            "Hip neeche mat girne do. Saans lete raho.",
            "Kaanp raha hai? Wo muscle contract sign kar raha hai.",
        ],
        "pushup": [
            "Sar se edi tak ek line. Seena zameen tak, poora upar.",
            "Kohni 45 degree. Bahar phailaoge to kandhe shikayat karenge.",
            "Kamar latki to core ne chhutti le li. Wapas tight karo.",
            "Purani cheez hai, par kaam karti hai.",
        ],
        "grip": [
            "Poori taakat se band karo, ek second hold, dheere chhodo.",
            "Forearms bhi utne hi zaroori hain jitne biceps. Squeeze pura karo.",
            "Jaldi mat karo — poora range, poora control.",
            "Ye wahi grip hai jo agli kettlebell set mein kaam aayegi.",
        ],
        "curl": [
            "Kohni pasliyon se chipki. Sirf forearm chalega.",
            "Peeth ki madad li to weight zyada hai. Bicep se karo.",
            "Upar squeeze, neeche dheere. Neeche wali journey double count hoti hai.",
            "Saaf rep. Aaina optional, ego bilkul nahi.",
        ],
        "mtnclimber": [
            "Tez ghutne, hips neeche aur shaant.",
            "Jagah par daud rahe ho, zameen ko peeche dhakelte hue.",
            "Kandhe haathon ke upar. Hips uchhalna nahi.",
        ],
        "boat": [
            "Seena upar, shins parallel. Peeth gol mat karo.",
            "Kaanp rahe ho? Bilkul normal. Saans mat roko.",
            "V ki tarah ekdum tight. Bas thodi der ki baat hai.",
        ],
        "treadmill": [
            "Ek pace pakdo, phone pe kuch laga lo, aur chalte raho.",
            "Railing mat pakdo. Insaan ki tarah daudo, kaidi ki tarah nahi.",
            "Naak se saans jitni der le sako. Koi race nahi hai.",
            "Nazar upar, kandhe dheele. Show dekho, pair apne aap chalenge.",
        ],
        "jokes": [
            "Phone uthao. Do-teen joke ideas — kaccha bhi chalega.",
            "Jo daudte hue socha, wahi likh do. Polish baad mein.",
            "Sirf keywords. Baad mein tum inhe bit bana lena.",
            "Kuch nahi aaya? Aaj jo cheez irritate kar gayi, wahi likh do. Aksar wahi joke hoti hai.",
        ],
        "savasana": [
            "Bilkul shaant. Zameen tumhe sambhal legi. Bas saans.",
            "Kuch karna nahi. Kahin jaana nahi.",
            "Ye bhi training hai — jab sab kuch andar sink hota hai.",
        ],
        "sunsal": [
            "Saans ke saath chalo. Andar — upar, bahar — neeche.",
            "Ek saans, ek movement. Flow banao, march nahi.",
            "Dheere dheere garmi aayegi. Bas saans ka saath mat chhodna.",
        ],
        "warriors": [
            "Pair jame hue, kandhe hips ke upar, nazar aage. Yoddha ki tarah.",
            "Aage ka ghutna edi ke upar. Peeche ka pair dabaye rakho.",
            "Haath lambe, seena khula. Saans lete raho.",
        ],
        "halfmoon": [
            "Balance koi talent nahi, practice hai. Hilo, sambhalo, saans lo.",
            "Neeche wala haath dabao, upar wala tan do.",
            "Nazar neeche rakho to balance aasan, upar rakho to challenge. Tumhari marzi.",
        ],
        "camel": [
            "Seena aasman ki taraf. Haath kamar ko sahara dein.",
            "Backbend ko dheemi saans pasand hai. Saans mat roko.",
            "Utna hi jao jitne mein saans chalti rahe.",
        ],
        "childs": [
            "Reset button. Lambi saans, peeth phailne do.",
            "Haath aage ya side mein — jo aaram de wahi sahi.",
            "Har saans ke saath thoda aur dheela.",
        ],
        "vinyasa": [
            "Koi script nahi. Saans ke saath chalo.",
            "Ruk jao to saans par wapas aa jao.",
            "Ye tumhara flow hai. Isse achha bana lo.",
        ],
        "kapalabhati": [
            "Naak se tez saans bahar — pet pump kar raha hai, saans andar apne aap.",
            "Jaise chheenk rahe ho, ek lay mein. Tees baar.",
            "Chakkar aaye to ruk jao. Koi hero points nahi.",
        ],
        "backbend": [
            "Pehle spine ko garam karo. Haath dabao, seena upar.",
            "Lambai pehle, gehrai baad mein. Peeth ko todo nahi.",
            "Andar lete hue upar, bahar chhodte hue sambhal ke.",
        ],
        "warmup": [
            "Halke se shuru. Joint ko jagao, thakao mat.",
            "Ye workout nahi, on-ramp hai. Dheere dheere.",
        ],
        "cooldown": [
            "Lambi saans. Kandhe kaanon se door.",
            "Kaam ho gaya. Ab bas apne aap ke saath achhe se pesh aao.",
        ],
    ]

    // MARK: Generic fallbacks by kind

    static let byKind: [StepKind: [String]] = [
        .warmup:   pools["warmup"] ?? [],
        .cooldown: pools["cooldown"] ?? [],
        .cardio:   pools["treadmill"] ?? [],
        .strength: [
            "Saaf rep. Form toote to set khatam.",
            "Weight ko control karo, weight tumhe nahi.",
            "Yahi wo jagah hai jahan kaam hota hai. Tight raho.",
            "Har rep ek jama. Jodte jao.",
        ],
        .hold: [
            "Position pakdo aur bachao. Saans lete raho.",
            "Yahan thehrav hi kaam hai. Hilo mat.",
        ],
        .flow: [
            "Saans pace set karti hai. Uske saath chalo.",
            "Flow karo, zabardasti nahi.",
        ],
    ]

    // MARK: Moment pools

    static let starts = [
        "Chalo.", "Shuru karte hain.", "Ye wala tumhara hai.", "Lock in.",
        "Jao, kar do.", "Bhai, chalo.", "Bas ye set.",
    ]

    static let restFlavour = [
        "Saans lo. Haath jhatak do.",
        "Badhiya. Kandhe dheele karo.",
        "Aaram karo, agla wala aa raha hai.",
        "Ek ghoont paani pi lo.",
        "Thoda tehal lo, garmi bani rahe.",
    ]

    static let setDone = [
        "Ek set jama.", "Ho gaya.", "Badhiya rep tha.", "Bank mein daal diya.",
        "Shabash.", "Aur ek nipta diya.",
    ]

    static let finishes = [
        "Workout khatam. Kal phir wahi energy.",
        "Ho gaya. Aaj ka kaam pakka.",
        "Shabash bhai. Pani pi lo.",
        "Poora kar diya. Ab thoda hass lo.",
        "Aaj ka session done. Comedy set ke liye tayyar.",
    ]

    // MARK: Rotation

    private static func nextIndex(_ key: String, count: Int) -> Int {
        guard count > 0 else { return 0 }
        let k = "cue.rot.\(key)"
        let i = UserDefaults.standard.integer(forKey: k)
        UserDefaults.standard.set((i + 1) % max(count, 1), forKey: k)
        return i % count
    }

    /// The next rotating line for a movement.
    static func line(forKey key: String?, kind: StepKind) -> String {
        let pool = (key.flatMap { pools[$0] }) ?? byKind[kind] ?? []
        guard !pool.isEmpty else { return "" }
        return pool[nextIndex(key ?? "kind.\(kind.rawValue)", count: pool.count)]
    }

    static func start() -> String { starts[nextIndex("moment.start", count: starts.count)] }
    static func rest() -> String { restFlavour[nextIndex("moment.rest", count: restFlavour.count)] }
    static func setComplete() -> String { setDone[nextIndex("moment.setdone", count: setDone.count)] }
    static func finish() -> String { finishes[nextIndex("moment.finish", count: finishes.count)] }
}
