# Hinglish (Roman) -> Devanagari, word by word. Hindi neural voices read Devanagari
# properly; Roman Hinglish comes out as gibberish. Add words here as the script grows.
import re

LEX_TEXT = """
aa आ|aadha आधा|aadhe आधे|aage आगे|aaina आईना|aaj आज|aakhir आख़िर|aakhri आख़िरी|aane आने|aankhein आँखें
aao आओ|aap आप|aapas आपस|aaraam आराम|aaram आराम|aasan आसान|aasman आसमान|aath आठ|aati आती|aaya आया
aaye आए|aayegi आएगी|ab अब|abhi अभी|absurd एब्सर्ड|achha अच्छा|achhe अच्छे|agar अगर|agla अगला|aise ऐसे
ajeeb अजीब|aksar अक्सर|alag अलग|alternate ऑल्टरनेट|anaamika अनामिका|andar अंदर|angles एंगल्स|anguthe अँगूठे
anguutha अँगूठा|apne अपने|asli असली|aur और|awaaz आवाज़|awaazein आवाज़ें|baad बाद|baahein बाहें|baaki बाकी
baar बार|baat बात|baatein बातें|baayan बायाँ|baayein बाएँ|bachao बचाओ|backbend बैकबेंड|backbends बैकबेंड्स
badhiya बढ़िया|badlo बदलो|bahar बाहर|baith बैठ|baithne बैठने|bakwaas बकवास|bal बल|balance बैलेंस|bana बना
banao बनाओ|band बंद|bani बनी|bank बैंक|bas बस|beech बीच|bell बेल|bhaar भार|bhai भाई|bhatakne भटकने
bhejo भेजो|bhi भी|bicep बाइसेप|bilkul बिल्कुल|bina बिना|bit बिट|blade ब्लेड|block ब्लॉक|boat बोट|body बॉडी
bolenge बोलेंगे|boring बोरिंग|box बॉक्स|brace ब्रेस|breath ब्रीद|breathing ब्रीदिंग|button बटन|camel कैमल|car कार
cardio कार्डियो|chaar चार|chadha चढ़ा|chahiye चाहिए|chakkar चक्कर|chal चल|chalega चलेगा|chalenge चलेंगे
chalne चलने|chalo चलो|chalte चलते|chalti चलती|challenge चैलेंज|chaturanga चतुरंग|chaude चौड़े|check चेक
cheez चीज़|cheezein चीज़ें|chehra चेहरा|chhat छत|chhati छाती|chheenk छींक|chhod छोड़|chhodna छोड़ना
chhodte छोड़ते|chhoot छूट|chhote छोटे|chhutti छुट्टी|child's चाइल्ड्स|chin चिन|chipki चिपकी|chips चिप्स
chuno चुनो|climbers क्लाइंबर्स|clips क्लिप्स|comedy कॉमेडी|confident कॉन्फिडेंट|contest कॉन्टेस्ट
contract कॉन्ट्रैक्ट|contradictions कॉन्ट्राडिक्शन्स|control कंट्रोल|core कोर|count काउंट|creative क्रिएटिव
cross क्रॉस|curl कर्ल|curls कर्ल्स|daal डाल|daayan दायाँ|daayein दाएँ|dabao दबाओ|dabaye दबाए|dard दर्द
darwaza दरवाज़ा|das दस|daud दौड़|daudo दौड़ो|daudte दौड़ते|day डे|de दे|deewar दीवार|degree डिग्री|dein दें
dekh देख|dekhna देखना|dekho देखो|dekhte देखते|dena देना|der देर|dhakelo धकेलो|dhakelte धकेलते|dhakka धक्का
dheela ढीला|dheele ढीले|dheeli ढीली|dheemi धीमी|dheere धीरे|dhoondo ढूँढो|dhyaan ध्यान|dikhenge दिखेंगे
dimaag दिमाग़|din दिन|diya दिया|do दो|dobara दोबारा|dog डॉग|done डन|dono दोनों|door दूर|doosra दूसरा
doosre दूसरे|doosri दूसरी|double डबल|downward डाउनवर्ड|dukh दुख|dum दम|dumbbell डम्बल|easy ईज़ी|edi एड़ी
ego ईगो|eight एट|ek एक|ekdum एकदम|energy एनर्जी|exhales बार साँस बाहर|explosive एक्सप्लोसिव|film फ़िल्म
fire फ़ायर|flat फ्लैट|flow फ़्लो|flowing फ़्लोइंग|foot फुट|force फ़ोर्स|forearm फोरआर्म|form फ़ॉर्म
formula फ़ॉर्मूला|four फ़ोर|free फ़्री|full फुल|fully फुली|gale गले|gap गैप|garam गरम|gardan गर्दन
garmi गर्मी|gaya गया|gaye गए|gayi गई|gehrai गहराई|gehri गहरी|get गेट|ghoont घूँट|ghoorte घूरते
ghumao घुमाओ|ghutna घुटना|ghutne घुटने|ghutno घुटनों|ghutnon घुटनों|ginne गिनने|ginti गिनती|gira गिरा
girao गिराओ|girne गिरने|glutes ग्लूट्स|gol गोल|ha हा|haath हाथ|haathon हाथों|hafte हफ़्ते|hai है|hain हैं
half हाफ़|halka हल्का|halke हल्के|halki हल्की|hall हॉल|hamesha हमेशा|hansaa हँसा|hasaa हँसा|hasi हँसी
hass हँस|hathelian हथेलियाँ|height हाइट|hero हीरो|hi ही|high हाई|hilaye हिलाए|hilo हिलो|hip हिप|hips हिप्स
hissa हिस्सा|ho हो|hold होल्ड|holds होल्ड्स|hota होता|hoti होती|hue हुए|i वन|ideas आइडियाज़|ideation आइडिएशन
ii टू|in इन|incline इन्क्लाइन|inhe इन्हें|insaan इंसान|inspiration इंस्पिरेशन|instruction इंस्ट्रक्शन
intensity इंटेंसिटी|irritate इरिटेट|is इस|iske इसके|isse इससे|itna इतना|jaana जाना|jaane जाने
jaanghein जाँघें|jaanghon जाँघों|jaaye जाए|jab जब|jabda जबड़ा|jagah जगह|jagao जगाओ|jahan जहाँ|jaisa जैसा
jaise जैसे|jaisi जैसी|jaldi जल्दी|jalne जलने|jama जमा|jame जमे|jao जाओ|jeebh जीभ|jeet जीत|jeetna जीतना
jhatak झटक|jhatka झटका|jhatke झटके|jhool झूल|jhoolne झूलने|jhuko झुको|jitne जितने|jitni जितनी|jo जो
jodte जोड़ते|jog जॉग|joint जॉइंट|joke जोक|jokes जोक्स|jot जॉट|journey जर्नी|jude जुड़े|judge जज|jug जग
ka का|kaafi काफ़ी|kaam काम|kaan कान|kaano कानों|kaanon कानों|kaanp काँप|kaanpe काँपे|kaccha कच्चा|kadam कदम
kahan कहाँ|kahin कहीं|kaidi क़ैदी|kal कल|kalpana कल्पना|kamar कमर|kandha कंधा|kandhe कंधे|kandhon कंधों
kapalabhati कपालभाति|kar कर|karenge करेंगे|karna करना|karne करने|karo करो|karta करता|karte करते|karti करती
kaunsi कौनसी|ke के|kettlebell केटलबेल|keywords कीवर्ड्स|khaali खाली|khade खड़े|khamoshi ख़ामोशी|khatam ख़त्म
kheencho खींचो|khinch खींच|khol खोल|kholo खोलो|khula खुला|khule खुले|ki की|kitna कितना|kiya किया|ko को
kohni कोहनी|kohniyan कोहनियाँ|koi कोई|koshish कोशिश|kuch कुछ|kulhe कूल्हे|kulhon कूल्हों|kya क्या|laake लाके
laao लाओ|lag लग|laga लगा|lagao लगाओ|lagbhag लगभग|lagi लगी|lagta लगता|lambai लंबाई|lambe लंबे|lambi लंबी
land लैंड|lateral लैटरल|latke लटके|latki लटकी|lawnmower लॉनमोवर|lay लय|le ले|legged लेग्ड|legi लेगी
legs लेग्स|lena लेना|let लेट|lete लेते|li ली|light लाइट|likh लिख|line लाइन|liye लिए|lo लो|lock लॉक
maatha माथा|maathe माथे|madad मदद|maqsad मक़सद|march मार्च|marzi मर्ज़ी|mat मत|material मटेरियल|matlab मतलब
mazboot मज़बूत|meditation मेडिटेशन|mehnat मेहनत|mehsoos महसूस|mein में|memo मेमो|mic माइक|minute मिनट
mod मोड़|mode मोड|moderate मॉडरेट|moon मून|motion मोशन|mountain माउंटेन|movement मूवमेंट|mude मुड़े
mudha मुड़ा|mudne मुड़ने|mudo मुड़ो|mudte मुड़ते|muh मुँह|mukha मुख|murne मुड़ने|muscle मसल|muscles मसल्स
mutthi मुट्ठी|naak नाक|nadi नाड़ी|nahi नहीं|namaste नमस्ते|naya नया|nazar नज़र|ne ने|neeche नीचे
nervous नर्वस|niklega निकलेगा|nipta निपटा|no नो|nok नोक|normal नॉर्मल|nostril नॉस्ट्रिल|notes नोट्स
notice नोटिस|observation ऑब्ज़र्वेशन|observations ऑब्ज़र्वेशन्स|observe ऑब्ज़र्व|of ऑफ़|on ऑन|one वन
optional ऑप्शनल|overhead ओवरहेड|paanch पाँच|paani पानी|paas पास|pace पेस|pachaas पचास|packet पैकेट
pahunch पहुँच|pair पैर|pairon पैरों|pakde पकड़े|pakdo पकड़ो|pakka पक्का|pal पल|pandrah पंद्रह|pani पानी
par पर|parallel पैरेलल|pasand पसंद|pasliyon पसलियों|patthar पत्थर|pe पे|peeche पीछे|peeth पीठ|pehla पहला
pehle पहले|pesh पेश|pet पेट|phailao फैलाओ|phailaoge फैलाओगे|phailne फैलने|phenko फेंको|phir फिर|phone फ़ोन
photo फ़ोटो|pi पी|pichhle पिछले|pindliyan पिंडलियाँ|plank प्लैंक|podcast पॉडकास्ट|point पॉइंट|points पॉइंट्स
polish पॉलिश|poora पूरा|poore पूरे|poori पूरी|pose पोज़|position पोज़िशन|pour पोर|practice प्रैक्टिस
press प्रेस|progress प्रोग्रेस|pulls पुल्स|pump पंप|purani पुरानी|push पुश|raaste रास्ते|race रेस|rack रैक
raha रहा|rahe रहे|rahi रही|raho रहो|railing रेलिंग|raises रेज़िज़|ramp रैंप|recover रिकवर|reels रील्स
relax रिलैक्स|relaxed रिलैक्स्ड|rep रेप|reps रेप्स|reset रीसेट|rest रेस्ट|rokna रोकना|roko रोको|round राउंड
rounds राउंड्स|rows रोज़|ruk रुक|ruko रुको|run रन|sa सा|saaf साफ़|saamne सामने|saans साँस|saat सात|saath साथ
sab सब|sabse सबसे|sahara सहारा|sahi सही|sako सको|salutations सैल्यूटेशन्स|sambhal संभाल|sambhalo संभालो
samundar समंदर|sar सर|saturday सैटरडे|savasana शवासन|sawaal सवाल|scan स्कैन|scene सीन|script स्क्रिप्ट
scroll स्क्रॉल|se से|second सेकंड|seedha सीधा|seedhe सीधे|seedhi सीधी|seena सीना|seene सीने|series सीरीज़
session सेशन|set सेट|seven सेवन|shaant शांत|shabash शाबाश|shikayat शिकायत|shins शिन्स|shodhana शोधन
shoulder शोल्डर|show शो|shuru शुरू|side साइड|sign साइन|sink सिंक|sir सर|sirf सिर्फ़|slow स्लो|socha सोचा
sochein सोचें|sochna सोचना|socho सोचो|solid सॉलिड|specials स्पेशल्स|spine स्पाइन|square स्क्वेयर
squeeze स्क्वीज़|stage स्टेज|stand स्टैंड|staring स्टेयरिंग|start स्टार्ट|starting स्टार्टिंग|steady स्टेडी
sun सन|sunno सुनो|sunta सुनता|surface सर्फ़ेस|svanasana श्वानासन|swing स्विंग|swings स्विंग्स|system सिस्टम
table टेबल|tadasana ताड़ासन|takhne टखने|talent टैलेंट|talu तालु|tameez तमीज़|tan तान|tak तक|taraf तरफ़|tarah तरह
tayyar तैयार|teen तीन|tees तीस|tehal टहल|tez तेज़|tezi तेज़ी|tha था|thakaan थकान|thakao थकाओ|thehrav ठहराव
thigh थाई|thinking थिंकिंग|thoda थोड़ा|thode थोड़े|thodi थोड़ी|tight टाइट|tik टिक|tikao टिकाओ|time टाइम|to तो
todo तोड़ो|toote टूटे|training ट्रेनिंग|treadmill ट्रेडमिल|tum तुम|tumhara तुम्हारा|tumhari तुम्हारी
tumhe तुम्हें|tumpar तुम पर|turant तुरंत|turkish टर्किश|two टू|uchhalna उछलना|ujjayi उज्जायी
ungliyan उँगलियाँ|ungliyon उँगलियों|unhe उन्हें|unlock अनलॉक|up अप|upar ऊपर|ups अप्स|upward अपवर्ड
urdhva ऊर्ध्व|use यूज़|usi उसी|uske उसके|uthao उठाओ|uthate उठाते|uthegi उठेगी|uthne उठने|utna उतना|v वी
vinyasa विन्यास|visualization विज़ुअलाइज़ेशन|voice वॉइस|wahi वही|wahin वहीं|wala वाला|wale वाले|wali वाली
walk वॉक|wall वॉल|wapas वापस|warna वरना|warrior वॉरियर|weight वेट|wo वो|workout वर्कआउट|ya या|yaad याद
yahan यहाँ|yahi यही|yahin यहीं|ye ये|yoddha योद्धा|youtube यूट्यूब|zabardasti ज़बरदस्ती|zameen ज़मीन
zaroorat ज़रूरत|zero ज़ीरो|zyada ज़्यादा
har हर|rakh रख|rakhna रखना|rakho रखो|rakhte रखते
bade बड़े|circles सर्कल्स|ghuma घुमा|goal गोल|hamstring हैमस्ट्रिंग
kalaiyan कलाइयाँ|khinchaav खिंचाव|khulne खुलने|stretch स्ट्रेच|warm वार्म
agli अगली|biceps बाइसेप्स|chhodo छोड़ो|forearms फोरआर्म्स|grip ग्रिप
gripper ग्रिपर|hand हैंड|pura पूरा|range रेंज|strengthener स्ट्रेंथनर
taakat ताक़त|utne उतने|zaroori ज़रूरी
"""

LEX = {}
for chunk in re.split(r"[|\n]", LEX_TEXT):
    chunk = chunk.strip()
    if not chunk:
        continue
    k, v = chunk.split(" ", 1)
    LEX[k] = v.strip()

WORD = re.compile(r"[A-Za-z]+(?:'[A-Za-z]+)?")

def missing(text):
    return sorted({w.lower() for w in WORD.findall(text) if w.lower() not in LEX})

def to_devanagari(text):
    out = WORD.sub(lambda m: LEX.get(m.group(0).lower(), m.group(0)), text)
    out = (out.replace(" — ", ", ").replace("—", ", ").replace("→", ",")
              .replace(" + ", " और ").replace("&", "और").replace(" · ", ", ")
              .replace(" / ", " या ").replace("/", " या "))
    return out
