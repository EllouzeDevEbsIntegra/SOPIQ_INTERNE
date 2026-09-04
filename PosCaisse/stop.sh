#!/usr/bin/env bash
cd "$(dirname "$0")"
for f in backend.pid frontend.pid; do [ -f $f ] && kill $(cat $f) 2>/dev/null; rm -f $f; done
pkill -f "PosCaisseApplicatio[n]" 2>/dev/null; pkill -f "vite --hos[t]" 2>/dev/null
echo "PosCaisse arrêté."
