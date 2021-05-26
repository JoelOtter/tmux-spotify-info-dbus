#!/bin/bash

function require {
	hash $1 2>/dev/null || {
		echo >&2 "Error: '$1' is required, but was not found."; exit 1;
	}
}

require dbus-send
require grep

function getMeta {
	REPLY="$(
		dbus-send --print-reply --dest="org.mpris.MediaPlayer2.spotify" \
			"/org/mpris/MediaPlayer2" org.freedesktop.DBus.Properties.Get \
			string:"org.mpris.MediaPlayer2.Player" string:'Metadata' 2>/dev/null
	)"
	STATUS=$?
	if [ $STATUS -ne 0 ]; then
		echo ""
	else
		echo "${REPLY}" \
			| grep -Ev "^method"                           `# Ignore the first line.`   \
			| grep -Eo '("(.*)")|(\b[0-9][a-zA-Z0-9.]*\b)' `# Filter interesting fiels.`\
			| sed -E '2~2 a|'                              `# Mark odd fields.`         \
			| tr -d '\n'                                   `# Remove all newlines.`     \
			| sed -E 's/\|/\n/g'                           `# Restore newlines.`        \
			| sed -E 's/(xesam:)|(mpris:)//'               `# Remove ns prefixes.`      \
			| sed -E 's/^"//'                              `# Strip leading...`         \
			| sed -E 's/"$//'                              `# ...and trailing quotes.`  \
			| sed -E 's/"+/|/'                             `# Regard "" as seperator.`  \
			| sed -E 's/ +/ /g'                            `# Merge consecutive spaces.`
	fi
}

META="$(getMeta)"
if [ -z "${META}" ]; then
	echo ""
	exit 0
fi
TITLE="$(echo "${META}" | grep --color=never -E "(title)" | sed 's/^.*|//')"
ARTIST="$(echo "${META}" | grep --color=never -E "(artist)" | sed 's/^.*|//')"

echo "♫ ${TITLE} - ${ARTIST}"
