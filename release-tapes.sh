#!/bin/bash

set -euo pipefail

if echo '.status dir running' | bconsole | grep -q 'No Jobs running.'; then
	echo 'release storage=TS3200 drive=0' | bconsole
	echo 'release storage=TS3200 drive=1' | bconsole
fi
