xquery version "3.1";

(:~
 : App-image build step. Generates the Phase 5 perf artifacts from the live
 : expanded data through the same catalog.xqm functions the serving path
 : falls back to, so artifact == fallback output. Runs once, as admin, in the
 : embedded eXist started by docker/app.Dockerfile — never on the serving path.
 :)

declare namespace t = "http://www.tei-c.org/ns/1.0";

import module namespace catalog = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/catalog" at "xmldb:exist:///db/apps/BetMasWeb/modules/catalog.xqm";

declare variable $local:catalogs := "/db/apps/catalogs";

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

if (not(xmldb:collection-available($local:catalogs))) then
	error(xs:QName("gen:NO_CATALOGS"), $local:catalogs || " missing")
else

let $sha := local:expanded-sha()

(: Remove stale copies first so catalog:institutions("catalog") recomputes. :)
let $_ := for $name in ("institutions.xml", "labels.xml")
	where doc-available($local:catalogs || "/" || $name)
	return xmldb:remove($local:catalogs, $name)

let $institutions :=
	<list xmlns="http://www.tei-c.org/ns/1.0">{ catalog:institutions("catalog") }</list>

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
	"OK institutions=" || $n-ins || " labels=" || $n-lab
)[last()]
