#!/bin/sh
set -eu

root=$(CDPATH= cd -- "$(dirname "$0")" && pwd)
script="${root}/pin_baked_artifacts.sh"
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

mkdir -p "$tmp/expanded/config" "$tmp/catalogs"
cat > "$tmp/expanded/config/retired-ids.xml" <<'EOF'
<retired-ids xmlns="https://betamasaheft.eu/betmas-id-manager">
  <issued-id id="FROM-EXPANDED"/>
</retired-ids>
EOF
cat > "$tmp/catalogs/retired-ids.xml" <<'EOF'
<retired-ids xmlns="https://betamasaheft.eu/betmas-id-manager">
  <issued-id id="STALE"/>
</retired-ids>
EOF
cat > "$tmp/catalogs/manifest.xml" <<'EOF'
<catalog-manifest version="1">
  <artifact name="retired-ids.xml"
    required="true"
    expanded-sha="old"/>
  <artifact name="place-labels.xml"
    required="true"
    expanded-sha="scan-pin"/>
  <artifact name="bibl-exceptions.xml"
    required="true"
    expanded-sha="old"/>
</catalog-manifest>
EOF

"$script" abc123 "$tmp/expanded" "$tmp/catalogs"

grep -q 'FROM-EXPANDED' "$tmp/catalogs/retired-ids.xml"
grep -q 'name="retired-ids.xml"' "$tmp/catalogs/manifest.xml"
awk '
	/<artifact[[:space:]]+name="retired-ids.xml"/ { a=1 }
	/<artifact[[:space:]]+name="bibl-exceptions.xml"/ { a=1 }
	/<artifact[[:space:]]+name="place-labels.xml"/ { a=2 }
	a==1 && /expanded-sha="abc123"/ { ok++; a=0 }
	a==2 && /expanded-sha="scan-pin"/ { ok++; a=0 }
	END { if (ok != 3) exit 1 }
' "$tmp/catalogs/manifest.xml"

if "$script" abc123 "$tmp/missing" "$tmp/catalogs" 2>/dev/null; then
	echo "expected missing expanded retired-ids to fail" >&2
	exit 1
fi

echo "pin_baked_artifacts_test: ok"
