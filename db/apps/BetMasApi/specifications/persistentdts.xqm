xquery version "3.1" encoding "UTF-8";

(:~
 : test implementation of the https://github.com/distributed-text-services
 :
 : @author Pietro Liuzzo
 : to do
 : if I want to retrive 1ra@ወወልድ[1]-3vb, should the  @ወወልድ[1] piece also be in the passage/start/end parameter
 :
 : add Hydra navigation instead of the header links
 :
 : "view": {
 : "@id": "/api/dts/document/?id=lettres_de_poilus&passage=19",
 : "@type": "PartialDocumentView",
 : "first": "/api/dts/document/?id=lettres_de_poilus&passage=1",
 : "previous": "/api/dts/document/?id=lettres_de_poilus&passage=18",
 : "next": "/api/dts/document/?id=lettres_de_poilus&passage=20",
 : "last": "/api/dts/docuemtn/?id=lettres_de_poilus&passage=500"
 : }
 :
 : add possibility of having a collection grouping by institution or catalogue for the manuscripts
 :
 : urn:dts:betmasMS:INS0012bla:BLorient12314
 :
 : urn:dts:betmasMS:Zotemberg1234:BLorient12314
 :)

module namespace persdts = "https://www.betamasaheft.uni-hamburg.de/BetMasApi/persdts";

declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace t = "http://www.tei-c.org/ns/1.0";
declare namespace s = "http://www.w3.org/2005/xpath-functions";

import module namespace roaster = "http://e-editiones.org/roaster";
import module namespace exptit = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/exptit" at "xmldb:exist:///db/apps/BetMasWeb/modules/exptit.xqm";
import module namespace config = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/config" at "xmldb:exist:///db/apps/BetMasWeb/modules/config.xqm";
import module namespace string = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/string" at "xmldb:exist:///db/apps/BetMasWeb/modules/tei2string.xqm";
import module namespace dts = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/dts" at "xmldb:exist:///db/apps/BetMasWeb/modules/dts.xqm";

declare variable $persdts:collection-rootMS := collection($config:data-rootMS);

declare variable $persdts:collection-root := $exptit:col;

declare function persdts:capitalize-first($arg as xs:string?) as xs:string? {
	concat(upper-case(substring($arg, 1, 1)), substring($arg, 2))
};

(:~
 : Main access point to DTS style API returning passages from text
 :)
declare function persdts:dtsmain($request as map(*)) {
	let $sha as xs:string+ := $request?parameters?sha
	return let $perma := ("/permanent/" || $sha || "/api/dts/")
		let $col := $perma || "collections"
		let $doc := $perma || "document"
		let $nav := $perma || "navigation"
		return (
			map {
				"@context": "/dts/api/contexts/EntryPoint.jsonld",
				"@id": "/api/dts/",
				"@type": "EntryPoint",
				"documents": $doc,
				"navigation": $nav
			}
		)
};

declare function persdts:Collection($request as map(*)) {
	let $id as xs:string* := $request?parameters?id
	let $page as xs:integer* := $request?parameters?page
	let $nav as xs:string* := $request?parameters?nav
	let $sha as xs:string* := $request?parameters?sha
	return if ($id = "") then (
		roaster:response(
			302,
			(),
			(),
			map {"Location": "/permanent/" || $sha || "/api/dts/collections?id=https://betamasaheft.eu"}
		)
	) else if (
		matches(
			$id,
			"(https://betamasaheft.eu/)?(textualunits/|narrativeunits/|transcriptions/)?([a-zA-Z\d]+)?(:)?(((\d+)(\w)?(\w)?((@)([\p{L}]+)(\[(\d+|last)\])?)?)?(\-)?((\d+)(\w)?(\w)?((@)([\p{L}]+)(\[(\d+|last)\])?)?)?)"
		)
	) then
		let $parsedURN := dts:parseDTS($id)
		return if (matches($parsedURN//s:group[@nr eq 3], "[a-zA-Z\d]+")) then (
			let $specificID := $parsedURN//s:group[@nr eq 3]/text()
			return persdts:CollMember($id, $specificID, $page, $nav, $sha)
		) else (
			roaster:response(
				400,
				map {
					"@context": "http://www.w3.org/ns/hydra/context.jsonld",
					"@type": "Status",
					"statusCode": 400,
					"title": "Not Found",
					"description": " Resource requested is not available (versioned collection)"
				}
			)
		)

	else (
		roaster:response(
			400,
			let $error := $id || "is not a valid URN pattern"
			return map {
				"@context": "http://www.w3.org/ns/hydra/context.jsonld",
				"@type": "Status",
				"statusCode": 400,
				"title": "Not Found",
				"description": " Resource requested is not found ",
				"error": $error
			}
		)
	)
};

declare function persdts:CollMember($id, $bmID, $page, $nav, $sha) {
	let $doc := persdts:fileingit($id, $bmID, $sha)
	let $eds := $doc//t:div[@type eq "edition"]
	let $document := if (count($eds) gt 1) then (
		if ($eds[@xml:id = "traces"]) then
			$eds[@xml:id = "traces"]
		else
			$eds[1]
	) else
		$doc//t:div[@type eq "edition"]
	return if (count($doc) eq 1) then (
		let $shortid := substring-before($id, concat(":", $bmID))
		let $memberInfo := persdts:member($shortid, $document, $sha)
		let $addcontext := map:put($memberInfo, "@context", $dts:context)
		let $addnav := if ($nav = "parent") then
			let $parent := if ($doc/@type eq "mss") then
				map {
					"@id": "https://betamasaheft.eu/transcriptions",
					"title": "Beta maṣāḥǝft Manuscripts",
					"description": "Collection of Ethiopic Manuscript trasncriptions",
					"@type": "Collection"
				}
			else if ($doc/@type eq "nar") then
				map {
					"@id": "https://betamasaheft.eu/narrativeunits",
					"title": "Beta maṣāḥǝft Narrative Units",
					"description": "Collection of narrative units of the Ethiopic tradition",
					"@type": "Collection"
				}
			else
				map {
					"@id": "https://betamasaheft.eu/textualunits",
					"title": "Beta maṣāḥǝft Textual Units",
					"description": "Collection of literary textual units of the Ethiopic tradition",
					"@type": "Collection"
				}
			return map:put($addcontext, "member", $parent)
		else
			$addcontext
		return $addnav
	) else (
		roaster:response(
			400,
			map {
				"@context": "http://www.w3.org/ns/hydra/context.jsonld",
				"@type": "Status",
				"statusCode": 400,
				"title": "Bad Request",
				"description": "There is none or too many " || $bmID
			}
		)
	)
};

(:~
 : produces the information needed for each member of a collection
 :)
declare function persdts:member($collURN, $document, $sha) as map(*) {
	if (not($document)) then
		roaster:response(204, ())
	else
		let $doc := root($document)
		let $id := string($doc//t:TEI/@xml:id)
		let $title := exptit:printTitleID($id)
		let $description := if (contains($collURN, "MS")) then
			"The transcription of manuscript " || $title || " in Beta maṣāḥǝft "
		else
			"The abstract textual unit " ||
				$title ||
				" in Beta maṣāḥǝft. " ||
				normalize-space(string-join(string:tei2string($doc//t:abstract), ""))
		let $dc := dts:dublinCore($id)
		let $computed := if (contains($collURN, "MS")) then (
		) else (
			for $witness in $persdts:collection-rootMS//t:title[@ref eq $id]
			let $root := root($witness)/t:TEI/@xml:id
			group by $groupkey := $root
			return string($groupkey)
		)
		let $declared := if (contains($collURN, "MS")) then (
		) else
			for $witness in $doc//t:witness/@corresp
			return string($witness)
		let $witnesses := ($computed, $declared)
		let $distinctW :=
			for $w in config:distinct-values($witnesses)
			return map {
				"fabio:isManifestationOf": "https://betamasaheft.eu/" || $w,
				"@id":
					if (starts-with($w, "http")) then
						$w
					else (
						"https://betamasaheft.eu/" || $w
					),
				"@type": "lawd:AssembledWork"
			}

		let $dcAndWitnesses := if (count($distinctW) gt 0) then
			map:put($dc, "dc:source", $distinctW)
		else
			$dc
		let $DcSelector := if (contains($collURN, "MS")) then
			$dc
		else
			$dcAndWitnesses
		(: $dc :)
		let $resourceURN := $collURN || ":" || $id
		let $versions := dts:fileingitCommits($resourceURN, $id, "collections")
		let $DcWithVersions := map:put($DcSelector, "dc:hasVersion", $versions)
		let $ext := dts:extension($id)
		let $haspart := dts:haspart($id)
		let $manifest := if (
			$doc//t:idno[@facs[not(starts-with(., "http"))]]
		) then (: from europeana data model specification, taken from nomisma, not sure if this is correct in json LD :) (
			map {
				"@id": ($config:appUrl || "/manuscript/" || $id || "/viewer"),
				"@type": "edm:WebResource",
				"svcs:has_service":
					map {
						"@id": "https://betamasaheft.eu/api/iiif/" || $id || "/manifest",
						"@type": "svcs:Service",
						"dcterms:conformsTo": "http://iiif.io/api/image",
						"doap:implements": "http://iiif.io/api/image/2/level1.json"
					}
			}
		) else if (
			$doc//t:idno[@facs[starts-with(., "http")]]
		) then (: from europeana data model specification, taken from nomisma, not sure if this is correct in json LD :) (
			map {
				"@id": string($doc//t:idno/@facs),
				"@type": "edm:WebResource",
				"svcs:has_service":
					map {
						"@id": string($doc//t:idno/@facs),
						"@type": "svcs:Service",
						"dcterms:conformsTo": "http://iiif.io/api/image",
						"doap:implements": "http://iiif.io/api/image/2/level1.json"
					}
			}
		) else (
		)
		let $addmanifest := if (count($manifest) ge 1) then
			map:put($ext, "foaf:depiction", $manifest)
		else
			$ext
		let $parts := if (count($haspart) ge 1) then
			map:put($addmanifest, "dcterms:hasPart", $haspart)
		else
			$addmanifest

		let $dtsPass := "/permanent/" || $sha || "/api/dts/document?id=" || $resourceURN
		let $dtsNav := "/permanent/" || $sha || "/api/dts/navigation?id=" || $resourceURN
		let $download := "https://betamasaheft.eu/tei/" || $id || ".xml"
		let $citeDepth := if (contains($collURN, "MS")) then
			3
		else
			let $counts :=
				for $div in ($document//t:div[@type eq "textpart"], $document//t:l)
				return count($div/ancestor::t:div)
			return max($counts)
		let $teirefdecl := if (contains($collURN, "MS")) then
			[
				map {
					"dts:citeType": "folio",
					"dts:citeStructure": [map {"dts:citeType": "page", "dts:citeStructure": [map {"dts:citeType": "column"}]}]
				}
			]

		else
			[dts:nestedDivs($document//t:div[@type eq "edition"])]
		let $c := count($document//t:div[@type eq "edition"]//t:ab//text())
		let $all := map {
			"@id": $resourceURN,
			"ecrm:P1_is_identified_by": map {"rdfs:label": $resourceURN, "ecrm:P2_has_type": "DTS URN"},
			"title": $title,
			"description": $description,
			"@type": "Resource",
			"totalItems": 0,
			"dts:dublincore": $DcWithVersions,
			"dts:download": $download,
			"dts:citeDepth": $citeDepth,
			"dts:citeStructure": $teirefdecl
		}
		let $ext := if (count($parts) ge 1) then
			map:put($all, "dts:extensions", $parts)
		else
			$all
		let $pass := map:put($ext, "dts:passage", $dtsPass)
		let $nav := map:put($pass, "dts:references", $dtsNav)
		return $nav
};

declare function persdts:fileingit($id, $bmID, $sha) {
	let $collection := if (contains($id, "betmasMS")) then
		"Manuscripts"
	else
		"Works"
	let $permapath := replace(
		persdts:capitalize-first(
			substring-after(base-uri($persdts:collection-root/id($bmID)[self::t:TEI]), "/db/apps/BetMasData/")
		),
		$collection,
		""
	)
	return doc(
		"https://raw.githubusercontent.com/BetaMasaheft/" || $collection || "/" || $sha || "/" || $permapath
	)//t:TEI
};

declare option output:method "json";
declare option output:indent "yes";
