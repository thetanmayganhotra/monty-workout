#!/usr/bin/env python3
"""Renders every phrase in ../lines.json to ../clips/<key>.mp3 with a Hindi neural voice.

Text is converted Roman-Hinglish -> Devanagari first (lexicon.py). Uses the free
Microsoft Edge neural voices via `edge-tts` — needs internet, no API key.

    python3 generate.py            # only what's missing
    python3 generate.py --force    # redo everything
"""
import asyncio, hashlib, json, os, sys
sys.path.insert(0, os.path.dirname(__file__))
import lexicon
import edge_tts

HERE = os.path.dirname(os.path.abspath(__file__))
VOICE_DIR = os.path.dirname(HERE)
CLIPS = os.path.join(VOICE_DIR, "clips")
CFG = json.load(open(os.path.join(VOICE_DIR, "voice.json")))

def key(text, calm):
    return hashlib.sha1(f"{'c' if calm else 'n'}|{text}".encode()).hexdigest()[:16]

async def render(sem, item, force, stats, manifest):
    text, calm = item["text"], item["calm"]
    k = key(text, calm)
    dev = lexicon.to_devanagari(text)
    manifest[k] = {"roman": text, "devanagari": dev, "calm": calm}
    path = os.path.join(CLIPS, k + ".mp3")
    if os.path.exists(path) and not force:
        stats["skipped"] += 1
        return
    cfg = CFG["calm" if calm else "normal"]
    async with sem:
        for attempt in range(4):
            try:
                comm = edge_tts.Communicate(dev, cfg["voice"], rate=cfg.get("rate", "+0%"),
                                            pitch=cfg.get("pitch", "+0Hz"), volume=cfg.get("volume", "+0%"))
                await comm.save(path + ".part")
                os.replace(path + ".part", path)
                stats["done"] += 1
                if stats["done"] % 25 == 0:
                    print(f"  {stats['done']} rendered…", flush=True)
                return
            except Exception as e:
                await asyncio.sleep(1.5 * (attempt + 1))
                err = e
        stats["failed"].append((text, str(err)))

async def main():
    force = "--force" in sys.argv
    os.makedirs(CLIPS, exist_ok=True)
    lines = json.load(open(os.path.join(VOICE_DIR, "lines.json")))
    bad = sorted({w for x in lines for w in lexicon.missing(x["text"])})
    if bad:
        print("⚠ words missing from lexicon (will be read as Roman):", ", ".join(bad))
    sem = asyncio.Semaphore(int(CFG.get("concurrency", 4)))
    stats = {"done": 0, "skipped": 0, "failed": []}
    manifest = {}
    await asyncio.gather(*(render(sem, it, force, stats, manifest) for it in lines))
    json.dump(manifest, open(os.path.join(VOICE_DIR, "manifest.json"), "w"), ensure_ascii=False, indent=1)
    print(f"▸ rendered {stats['done']}, kept {stats['skipped']}, failed {len(stats['failed'])}")
    for t, e in stats["failed"][:10]:
        print("  FAILED:", t[:60], "|", e[:80])
    total = sum(os.path.getsize(os.path.join(CLIPS, f)) for f in os.listdir(CLIPS) if f.endswith(".mp3"))
    print(f"▸ clips: {len(os.listdir(CLIPS))} files, {total/1e6:.1f} MB")

asyncio.run(main())
