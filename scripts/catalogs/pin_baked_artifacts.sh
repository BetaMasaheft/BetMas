#!/bin/sh
# Align catalogs artifacts with the expanded commit baked into this image.
#
# retired-ids.xml is a copy of expanded/config/retired-ids.xml at EXPANDED_REF.
# bibl-exceptions.xml is a hand list; its pin is set to that same ref so the
# stale gate does not drop it whenever expanded moves.
# place-labels.xml keeps the pin from the last scan.
#
# Usage: pin_baked_artifacts.sh EXPANDED_REF EXPANDED_ROOT CATALOGS_DIR
set -eu

sha=${1:?EXPANDED_REF}
expanded_root=${2:?EXPANDED_ROOT}
catalogs_dir=${3:?CATALOGS_DIR}
retired_src="${expanded_root}/config/retired-ids.xml"
manifest="${catalogs_dir}/manifest.xml"

if [ ! -f "$retired_src" ]; then
	echo "pin_baked_artifacts: missing ${retired_src}" >&2
	exit 1
fi
if [ ! -f "$manifest" ]; then
	echo "pin_baked_artifacts: missing ${manifest}" >&2
	exit 1
fi

cp "$retired_src" "${catalogs_dir}/retired-ids.xml"

SHA=$sha awk '
	BEGIN { sha = ENVIRON["SHA"]; inart = 0 }
	/<artifact[[:space:]]+name="(bibl-exceptions|retired-ids)\.xml"/ { inart = 1 }
	inart && /expanded-sha="/ {
		sub(/expanded-sha="[^"]*"/, "expanded-sha=\"" sha "\"")
		inart = 0
	}
	{ print }
' "$manifest" > "${manifest}.tmp"
mv "${manifest}.tmp" "$manifest"
