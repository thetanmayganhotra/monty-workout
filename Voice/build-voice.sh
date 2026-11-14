#!/bin/bash
# Regenerates the phrase list from the app code, then renders the neural-voice clips.
#   ./build-voice.sh          only missing clips
#   ./build-voice.sh --force  everything
set -euo pipefail
cd "$(dirname "$0")"
./build-lines.sh
VENV="${VOICE_VENV:-.venv}"
if [ ! -x "$VENV/bin/python" ]; then
  python3 -m venv "$VENV"
  "$VENV/bin/pip" install -q edge-tts
fi
"$VENV/bin/python" tools/generate.py "$@"
