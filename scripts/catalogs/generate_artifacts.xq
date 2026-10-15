xquery version "3.1";

(:~
 : App-image build step. Generates the Phase 5 perf artifacts from the live
 : expanded data through the same catalog.xqm functions the serving path
 : falls back to, so artifact == fallback output. Runs once, as admin, in the
 : embedded eXist started by docker/app.Dockerfile — never on the serving path.
 :
 : Also installs db/apps/catalogs/collection.xconf into
 : /db/system/config/db/apps/catalogs/ (copied to /tmp by app.Dockerfile) and
 : reindexes /db/apps/catalogs so @corresp range indexes apply without waiting
 : for a data-image catalogs.xar rebuild.
 :)

declare namespace t = "http://www.tei-c.org/ns/1.0";

import module namespace catalog = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/catalog" at "xmldb:exist:///db/apps/BetMasWeb/modules/catalog.xqm";

declare variable $local:catalogs := "/db/apps/catalogs";
declare variable $local:xconf-src := "/tmp/catalogs-collection.xconf";
declare variable $local:config-coll := "/db/system/config/db/apps/catalogs";

declare function local:expanded-sha() as xs:string {
	let $path := $local:catalogs || "/expanded-sha.txt"
	let $raw := if (util:binary-doc-available($path)) then
		util:binary-to-string(util:binary-doc($path))
	else if (unparsed-text-available($path)) then
		unparsed-text($path)
	else
		error(xs:QName("gen:NO_SHA"), "missing " || $path)
	return normalize-space(normalize-unicode($raw, "NFC"))
};

declare function local:store($name as xs:string, $doc as element()) as xs:string {
	let $stored := xmldb:store($local:catalogs, $name, $doc)
	let $_ := sm:chmod(xs:anyURI($stored), "rw-r--r--")
	return $stored
};

declare function local:manifest-with($sha as xs:string, $names as xs:string*) as element(catalog-manifest) {
	let $manifest := doc($local:catalogs || "/manifest.xml")/catalog-manifest
	return
		<catalog-manifest version="{ ($manifest/@version, "1")[1] }">{
			$manifest/artifact[not(@name = $names)],
			for $name in $names
			return <artifact name="{ $name }" required="true" expanded-sha="{ $sha }"/>
		}</catalog-manifest>
};

(:~ Ensure /db/system/config/db/apps/catalogs exists (same parent-walk style as InitInstance). :)
declare function local:ensure-config-coll() {
	if (xmldb:collection-available($local:config-coll)) then (
	) else (
		if (xmldb:collection-available("/db/system/config/db")) then (
		) else
			xmldb:create-collection("/db/system/config", "db"),
		if (xmldb:collection-available("/db/system/config/db/apps")) then (
		) else
			xmldb:create-collection("/db/system/config/db", "apps"),
		xmldb:create-collection("/db/system/config/db/apps", "catalogs")
	)
};

(:~
 : Install range-index collection.xconf for labels.xml @corresp lookups.
 : Source file is copied by app.Dockerfile; keep in sync with
 : db/apps/catalogs/collection.xconf (also packaged into catalogs.xar on data builds).
 :)
declare function local:collection-xconf-doc() as element() {
	if (file:exists($local:xconf-src)) then
		parse-xml(file:read($local:xconf-src))/*
	else if (doc-available($local:catalogs || "/collection.xconf")) then
		doc($local:catalogs || "/collection.xconf")/*
	else
		error(
			xs:QName("gen:NO_XCONF"),
			"missing " || $local:xconf-src || " and " || $local:catalogs || "/collection.xconf"
		)
};

declare function local:install-collection-xconf() as xs:string {
	let $_ := local:ensure-config-coll()
	let $xconf := local:collection-xconf-doc()
	let $stored := xmldb:store($local:config-coll, "collection.xconf", $xconf)
	let $_ := sm:chmod(xs:anyURI($stored), "rw-r--r--")
	let $_ := xmldb:reindex($local:catalogs)
	return $stored
};

if (not(xmldb:collection-available($local:catalogs))) then
	error(xs:QName("gen:NO_CATALOGS"), $local:catalogs || " missing")
else

(: Admin bake / local regenerate: package mode is often rwxr-xr-x. :)
let $_ := sm:chmod(xs:anyURI($local:catalogs), "rwxrwxr-x")

let $sha := local:expanded-sha()

(: Remove stale copies first so catalog:institutions("catalog") recomputes. :)
let $_ := for $name in ("institutions.xml", "labels.xml")
	where doc-available($local:catalogs || "/" || $name)
	return xmldb:remove($local:catalogs, $name)

let $institutions :=
	<list xmlns="http://www.tei-c.org/ns/1.0">{
		for $item in catalog:institutions("catalog")
		where normalize-space($item) ne ""
		return $item
	}</list>

let $labels :=
	<list xmlns="http://www.tei-c.org/ns/1.0">{
		for $id in collection("/db/apps/expanded")/t:TEI/@xml:id/string()
		let $title := catalog:full-title($id)
		where normalize-space($title) ne ""
		return <item corresp="{ $id }">{ $title }</item>
	}</list>

let $n-ins := count($institutions/t:item)
let $n-lab := count($labels/t:item)
return if ($n-ins = 0 or $n-lab = 0) then
	error(xs:QName("gen:EMPTY"), "institutions=" || $n-ins || " labels=" || $n-lab)
else (
	local:store("institutions.xml", $institutions),
	local:store("labels.xml", $labels),
	local:store("manifest.xml", local:manifest-with($sha, ("institutions.xml", "labels.xml"))),
	local:install-collection-xconf(),
	"OK institutions=" || $n-ins || " labels=" || $n-lab
)[last()]
