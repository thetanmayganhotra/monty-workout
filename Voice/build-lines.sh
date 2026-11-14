#!/bin/bash
# Dumps every spoken phrase from the app's own code into Voice/lines.json.
set -euo pipefail
cd "$(dirname "$0")"
S="../Sources/MontyWorkout"
TMP="$(mktemp -d)"
swiftc -parse-as-library -O -o "$TMP/dump" tools/dump-lines.swift \
  "$S/Model/Schedule.swift" "$S/Model/Guides.swift" "$S/Model/StickFigure.swift" \
  "$S/Engine/Cues.swift" "$S/Engine/Phrases.swift" "$S/Engine/WorkoutSession.swift" \
  "$S/Engine/Announcer.swift" "$S/Engine/HistoryStore.swift" "$S/Theme.swift"
"$TMP/dump" > lines.json
rm -rf "$TMP"
python3 -c "import json;d=json.load(open('lines.json'));print('▸ lines.json:',len(d),'phrases,',sum(1 for x in d if x['calm']),'calm')"
