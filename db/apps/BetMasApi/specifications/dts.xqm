xquery version "3.1" encoding "UTF-8";

(:~
 : test implementation of the https://github.com/distributed-text-services
 : SERVER
 : @author Pietro Liuzzo
 :
 : to do
 : if I want to retrive 1ra@ወወልድ[1]-3vb, should the  @ወወልድ[1] piece also be in the passage/start/end parameter
 :
 : add possibility of having a collection grouping by institution or catalogue for the manuscripts
 :
 : urn:dts:betmasMS:INS0012bla:BLorient12314
 :
 : urn:dts:betmasMS:Zotemberg1234:BLorient12314
 :)
module namespace dts = "https://www.betamasaheft.uni-hamburg.de/BetMasApi/dts";

declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace t = "http://www.tei-c.org/ns/1.0";
declare namespace s = "http://www.w3.org/2005/xpath-functions";
declare namespace http = "http://expath.org/ns/http-client";

import module namespace roaster = "http://e-editiones.org/roaster";
import module namespace dtslib = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/dtslib" at "xmldb:exist:///db/apps/BetMasWeb/modules/dtslib.xqm";
import module namespace log = "http://www.betamasaheft.eu/log" at "xmldb:exist:///db/apps/BetMasWeb/modules/log.xqm";
import module namespace exptit = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/exptit" at "xmldb:exist:///db/apps/BetMasWeb/modules/exptit.xqm";
import module namespace config = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/config" at "xmldb:exist:///db/apps/BetMasWeb/modules/config.xqm";

(:~
 : Main access point to DTS style API returning passages from text
 :)
declare function dts:dtsmain($request as map(*)) {
	(
		map {
			"@context": "api/dts/contexts/EntryPoint.jsonld",
			"@id": "/api/dts",
			"@type": "EntryPoint",
			"collections": "/api/dts/collections",
			"document": "/api/dts/document",
			"navigation": "/api/dts/navigation",
			"indexes": "/api/dts/indexes",
			"annotations": "/api/dts/annotations"
		}
	)
};

declare variable $dts:context := map {
	"@vocab": "https://www.w3.org/ns/hydra/core#",
	"dc": "http://purl.org/dc/terms/",
	"dts": "https://w3id.org/dts/api#",
	"tei": "http://www.tei-c.org/ns/1.0",
	"saws": "http://purl.org/saws/ontology#",
	"crm": "http://www.cidoc-crm.org/cidoc-crm/",
	"ecrm": "http://erlangen-crm.org/current/",
	"fabio": "http://purl.org/spar/fabio",
	"lawd": "http://lawd.info/ontology/",
	"edm": "http://www.europeana.eu/schemas/edm/",
	"svcs": "http://rdfs.org/sioc/services#",
	"doap": "http://usefulinc.com/ns/doap#",
	"foaf": "http://xmlns.com/foaf/0.1/",
	"sc": "http://iiif.io/api/presentation/2#"
};

declare variable $dts:publisher := map {
	"dc:publisher": ["Akademie der Wissenschaften in Hamburg", "Hiob-Ludolf-Zentrum für Äthiopistik"],
	"dc:description":
		[
			map {
				"@lang": "en",
				"@value":
					"The project Beta maṣāḥǝft: Manuscripts of Ethiopia and Eritrea (Schriftkultur des christlichen Äthiopiens: eine multimediale Forschungsumgebung) is a long-term project funded within the framework of the Academies' Programme (coordinated by the Union of the German Academies of Sciences and Humanities) under survey of the Akademie der Wissenschaften in Hamburg. The funding will be provided for 25 years, from 2016–2040. The project is hosted by the Hiob Ludolf Centre for Ethiopian Studies at the University of Hamburg. It aims at creating a virtual research environment that shall manage complex data related to predominantly Christian manuscript tradition of the Ethiopian and Eritrean Highlands."
			}
		]
};

declare variable $dts:regexCol := "(https://betamasaheft.eu/)(textualunits|narrativeunits|transcriptions)?";

declare variable $dts:regexID :=
	"([a-zA-Z\d]+)?(_(ED|TR)_([a-zA-Z0-9]+)?)?(\.)?(((\d+)(\w)?(\w)?((@)([\p{L}]+)(\[(\d+|last)\])?)?)?(\-)?((\d+)(\w)?(\w)?((@)([\p{L}]+)(\[(\d+|last)\])?)?)?)";

declare variable $dts:collection-rootMS := collection($config:data-rootMS);

declare variable $dts:collection-rootW := collection($config:data-rootW);

declare variable $dts:collection-rootN := collection($config:data-rootN);

declare variable $dts:collection-root := collection($config:data-root);

declare function dts:capitalize-first($arg as xs:string?) as xs:string? {
	concat(upper-case(substring($arg, 1, 1)), substring($arg, 2))
};

(:~
 : dts/collection https://github.com/distributed-text-services/specifications/blob/master/Collection-Endpoint.md
 :)
declare function dts:Collection($request as map(*)) {
	let $id as xs:string* := $request?parameters?id
	let $page as xs:integer* := $request?parameters?page
	let $nav as xs:string* := $request?parameters?nav
	let $version as xs:string* := $request?parameters?version
	return if ($id = "") then (
		roaster:response(302, (), (), map {"Location": "/api/dts/collections?id=https://betamasaheft.eu"})
	) else if (
		matches(
			$id,
			"(https://betamasaheft.eu/)?(textualunits/|narrativeunits/|transcriptions/)?([a-zA-Z\d]+)?(:)?(((\d+)(\w)?(\w)?((@)([\p{L}]+)(\[(\d+|last)\])?)?)?(\-)?((\d+)(\w)?(\w)?((@)([\p{L}]+)(\[(\d+|last)\])?)?)?)"
		)
	) then
		let $parsedURN := dtslib:parseDTS($id)
		return if (matches($parsedURN//s:group[@nr = 2], "(textualunits|narrativeunits|transcriptions)")) then (
			dtslib:Coll($id, $page, $nav, $version)
		) else if (matches($parsedURN//s:group[@nr = 3], "[a-zA-Z\d]+")) then (
			let $specificID := $parsedURN//s:group[@nr = 3]/text()
			let $edition := $parsedURN//s:group[@nr = 4]
			return dtslib:CollMember($id, $edition, $specificID, $page, $nav, $version)
		) else
			dtslib:Coll($id, $page, $nav, $version)
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

declare function dts:anyDocumentDEFAULT($request as map(*)) {
	let $id as xs:string* := $request?parameters?id
	let $ref as xs:string* := $request?parameters?ref
	let $start := $request?parameters?start
	let $end := $request?parameters?end
	return (: console:log('got to default'), :) dtslib:docs($id, $ref, $start, $end, "application/tei+xml")
};

(:~
 : dts/navigation https://github.com/distributed-text-services/specifications/blob/master/Navigation-Endpoint.md
 :)
declare function dts:Cit($request as map(*)) {
	let $id as xs:string* := $request?parameters?id
	let $ref as xs:string* := $request?parameters?ref
	let $level as xs:string* := $request?parameters?level
	let $start as xs:string* := $request?parameters?start
	let $end as xs:string* := $request?parameters?end
	let $groupBy as xs:string* := $request?parameters?groupBy
	let $page as xs:string* := $request?parameters?page
	let $max as xs:string* := $request?parameters?max
	let $version as xs:string* := $request?parameters?version
	return if ($id = "") then (
		roaster:response(302, (), (), map {"Location": "/api/dts/collections?id=https://betamasaheft.eu"})
	) else
		let $parsedURN := dtslib:parseDTS($id)
		let $BMid := $parsedURN//s:group[@nr = 3]/text()
		let $mydoc := $exptit:col/id($BMid)
		let $edition := $parsedURN//s:group[@nr = 4]
		let $text := if ($edition/node()) then
			dtslib:pickDivText($mydoc, $edition)
		else
			$mydoc//t:div[@type eq "edition"]
		(: there may be more edition and translations how are these fetched?
                LIT1709Kebran, LIT1758Lefafa multiple editions
                LIT2170Peripl multiple pb and divs + images

                there needs to be evidence of multiple editions and a possibility to
                switch based on @xml:id
                with fallback on div[@type eq 'edition']
                multiple values for navigation api provided in Collection

                LIT4915PhysA_ED_ed1.1.1.1
                LIT4915PhysA_ED_ed2.1.1
                LIT2170Peripl_ED_
                LIT2170Peripl_TR_
                :)
		let $textType := $mydoc//t:objectDesc/@form
		let $manifest := $mydoc//t:idno/@facs
		let $allwits := dtslib:wits($mydoc, $BMid)
		let $witnesses :=
			for $witness in distinct-values($allwits)
			(: filters out the witnesses which do not have images available :)
			return if (starts-with($witness, "http")) then
				$witness
			else
				let $mss := $dtslib:collection-rootMS/id($witness)
				return if ($mss//t:idno/@facs) then
					$witness
				else (
				)
		let $cdepth := dtslib:citeDepth($text)
		let $passage := if ($mydoc/@type eq "mss" and not($textType = "Inscription")) then (
			(: manuscripts :)

			(: THERE IS A REF :)
			if ($ref != "") then
				let $l := if ($level = "") then
					1
				else
					$level
				return dtslib:pasRef($l, $text, $ref, "unit", "mss", $manifest, $BMid)
			(: $ref can be a NAR, but how does one know that this is a possibility within this text? :)

			(: start and end :)
			else if ($start != "") then
				dtslib:startend($level, $text, $start, $end, "part", "mss", $manifest, $BMid)
			(: no ref specified, list all main divs, assuming by the guidelines they are folios :)
			else if ($ref = "" and $level = "" and $start = "" and $end = "" and $groupBy = "" and $max = "") then
				dtslib:pasS($text/t:div[@n], "folio", "mss", $manifest, $BMid)
			(: if the level is not empty, than it has been specified to be either the second or third level, pages and columns :)
			else if (($level != "") and ($cdepth gt 3)) then
				(: the citation depth is higer than 3 :)
				(: let $t := console:log($level) return :)
				dtslib:pasLev($level, $text, "unit", "mss", $manifest, $BMid)
			else if (($level != "") and ($cdepth = 3)) then (
				if ($level = "2") (: the pages of folios have been requested :) then
					dtslib:pasS($text//t:pb[@n], "page", "mss", $manifest, $BMid)
				else if ($level = "3") (: the columns of a pages have been requested :) then
					dtslib:pasS($text//(t:cb[@n]), "column", "mss", $manifest, $BMid)
				else if ($level = "4") (: the columns of a pages have been requested :) then
					dtslib:pasS($text//(t:lb[@n]), "line", "mss", $manifest, $BMid)
				(: in theory there is no such case which will not be matched by cdepth gt 3... :)
				else (
				)
			) (: no other option taken into consideration :) else (
			)
		) else (: works and inscriptions.
                        textual units have different structures
                        some are encoded with a basic nested divs structure, some instaed, especially bible texts use l, while inscriptions have lb :) if (
			$ref = "" and $level = "" and $start = "" and $end = "" and $groupBy = "" and $max = ""
		) (: if no  parameter is specified, go through the child elements of div type edition, whatever they are :) then
			dtslib:pasS($text/(t:ab | .)/t:*, "unit", "work", $witnesses, $BMid)
		(: if a ref is specified show that navigation point :)
		else if ($ref != "" and $start = "") (: e.g. LIT1546Genesi&ref=2.3 :) then
			dtslib:pasRef(1, $text, $ref, "unit", "work", $witnesses, $BMid)
		(: if a level is specified that use that information, and check for ref
e.g. LIT1546Genesi&level=2
 :)
		else if ($level != "" and $start = "") then
			(: e.g. LIT1546Genesi&level=2&ref=4 :)
			if ($ref != "") then
				dtslib:pasRef($level, $text, $ref, "unit", "work", $witnesses, $BMid)
			(: e.g. LIT1546Genesi&level=2 (max level is value of citeDepth!) :)
			else
				dtslib:pasLev($level, $text, "unit", "work", $witnesses, $BMid)
		else if ($start != "" and $end != "") (: needs to make a sequence of possible
refs at the given level and limit it by the positions in $start and $end
LIT1546Genesi&start=3&end=4 :) then
			dtslib:startend($level, $text, $start, $end, "texpart", "work", $witnesses, $BMid)
		else (
		)

		(: the following step should take the list of results and format it using the chunksize and max parameters :)
		let $CS := number($groupBy)
		let $M := number($max)
		let $ctype := dtslib:ctype($mydoc, $text, $level, $cdepth)
		let $chunkedpassage := if (string($groupBy) != "") then (
			for $p in $passage/text()
			let $l1 := substring-before($p, ".")
			let $l2 := number(substring-after($p, ".")) - 1
			let $L := $l2 - ($l2 mod $CS)
			group by $g := $L
			order by $g
			let $rangeStart := if ($g = 0) then
				1
			else
				$g + 1
			let $ceiling := $g + $CS
			let $sequenceN :=
				for $p in $passage
				return number(substring-after($p, "."))
			let $end := max($sequenceN)
			let $rangeEnd := if ($ceiling gt $end) then
				$end
			else
				$ceiling
			let $chunck := map {"dts:start": $passage[$rangeStart]/text()[1], "dts:end": $passage[$rangeEnd]/text()[1]}
			return $chunck
		) else
			for $p in $passage
			let $refonly := map {"dts:ref": $p/text()[1]}
			let $refandtype := if ((count($p/*:type) eq 1) and ($p/*:type/text() != $ctype)) then
				map:put($refonly, "dts:citeType", $p/*:type/text())
			else
				$refonly
			let $refTypeTitle := if (count($p/*:title) eq 1 or count($p/*:iiifRange) ge 1) then
				let $dublincore := map {}
				let $parttitle := if ($p/*:title) then
					map:put($dublincore, "dc:title", $p/*:title/text())
				else
					$dublincore
				let $iiifreference :=
					for $i in $p/*:iiifRange
					return map {
						"@id": $i/text(),
						"@type":
							(
								if (contains($i/text(), "canvas")) then
									"sc:Canvas"
								else
									"sc:Range"
							)
					}
				let $parttitlewithmanifest := if (count($iiifreference) ge 1) then
					map:put($parttitle, "dc:source", $iiifreference)
				else
					$parttitle
				return map:put($refandtype, "dts:dublincore", $parttitlewithmanifest)
			else
				$refandtype
			return $refTypeTitle

		(: regardless of passages sequence type (ranges as maps or items as strings) the following steps limits the number of results :)
		let $maximized := if (string($max) != "") then
			for $p in subsequence($chunkedpassage, 1, $M)
			return $p
		else
			$chunkedpassage
		let $array := array { $maximized }
		let $l := if ($level = "") then
			1
		else
			number($level)
		let $versions := if ($version = "yes") then
			dtslib:fileingitCommits($id, $BMid, "navigation")
		else (
			"version set to " || $version || ", no version links retrieved from GitHub."
		)

		return if (count($text//text()) lt 1) then (
			roaster:response(
				404,
				map {
					"@context": "http://www.w3.org/ns/hydra/context.jsonld",
					"@type": "Status",
					"statusCode": 404,
					"title": "Not Found",
					"description": "Sorry, there is no text here to navigate."
				}
			)
		) else (
			log:add-log-message("/api/dts/cit/" || $id, sm:id()//sm:real/sm:username/string(), "dts"),
			map {
				"@context":
					map {
						"@vocab": "https://www.w3.org/ns/hydra/core#",
						"dc": "http://purl.org/dc/terms/",
						"dts": "https://w3id.org/dts/api#"
					},
				"@base": "/api/dts/navigation",
				"@id": ("/api/dts/navigation?id=" || $id),
				"dts:citeDepth": $cdepth,
				"dts:level": $l,
				"dts:citeType": $ctype,
				"dc:hasVersion": $versions,
				"dts:passage": ("/api/dts/document?id=" || $id),
				"member": $array
			}
		)
};

(:~
 : not being sure about what to do with the URI templates in the documentation draft, the templates answer to this call, and can be thus retrived
 :)
declare function dts:URItemplates($request as map(*)) {
	let $api as xs:string* := $request?parameters?api
	return switch ($api)
		case "navigation" return
			(
				map {
					"@context":
						map {
							"@vocab": "https://www.w3.org/ns/hydra/core#",
							"dc": "http://purl.org/dc/terms/",
							"dts": "https://w3id.org/dts/api#",
							"tei": "http://www.tei-c.org/ns/1.0"
						},
					"@type": "IriTemplate",
					"template":
						"/api/dts/navigation/?id={collection_id}&amp;passage={passage}&amp;level={level}&amp;start={start}&amp;end={end}&amp;page={page}",
					"variableRepresentation": "BasicRepresentation",
					"mapping":
						[
							map {"@type": "IriTemplateMapping", "variable": "collection_id", "required": true()},
							map {"@type": "IriTemplateMapping", "variable": "passage", "required": false()},
							map {"@type": "IriTemplateMapping", "variable": "page", "required": false()},
							map {"@type": "IriTemplateMapping", "variable": "level", "required": false()},
							map {"@type": "IriTemplateMapping", "variable": "start", "required": false()},
							map {"@type": "IriTemplateMapping", "variable": "end", "required": false()}
						]
				}
			)
		case "document" return
			(
				map {
					"@context":
						map {
							"@vocab": "https://www.w3.org/ns/hydra/core#",
							"dc": "http://purl.org/dc/terms/",
							"dts": "https://w3id.org/dts/api#",
							"tei": "http://www.tei-c.org/ns/1.0"
						},
					"@type": "IriTemplate",
					"template":
						"/api/dts/document/?id={collection_id}&amp;passage={passage}&amp;level={level}&amp;start={start}&amp;end={end}&amp;page={page}",
					"variableRepresentation": "BasicRepresentation",
					"mapping":
						[
							map {"@type": "IriTemplateMapping", "variable": "collection_id", "required": true()},
							map {"@type": "IriTemplateMapping", "variable": "passage", "required": false()},
							map {"@type": "IriTemplateMapping", "variable": "start", "required": false()},
							map {"@type": "IriTemplateMapping", "variable": "end", "required": false()}
						]
				}
			)
		case "collection" return
			(
				map {
					"@context":
						map {
							"@vocab": "https://www.w3.org/ns/hydra/core#",
							"dc": "http://purl.org/dc/terms/",
							"dts": "https://w3id.org/dts/api#",
							"tei": "http://www.tei-c.org/ns/1.0"
						},
					"@type": "IriTemplate",
					"template": "/api/dts/collection/?id={collection_id}&amp;page={page}",
					"variableRepresentation": "BasicRepresentation",
					"mapping":
						[
							map {"@type": "IriTemplateMapping", "variable": "collection_id", "required": false()},
							map {"@type": "IriTemplateMapping", "variable": "page", "required": false()}
						]
				}
			)
		default return
			roaster:response(
				400,
				map {"info": ("You can have collection, document or navigation UIR templates, " || $api || " is none of them.")}
			)
};

(:
test implementation of
https://github.com/distributed-text-services/specifications/issues/167

indexes
this looks not only in div[@type eq 'edition'] but also in tei:teiHeader,
using xml:id and xpath to point to parts of the description

(index of named persons) persName[@ref]
(index of named places) placeName[@ref]
(index of keywords) term[@key]
(index of named textual units) title[@ref]
(index locorum) refs[@cRef]

 :)

declare function dts:Indexes($request as map(*)) {
	let $id as xs:string* := $request?parameters?id
	let $indexName as xs:string* := $request?parameters?indexName
	let $ref as xs:string* := $request?parameters?ref
	let $level as xs:string* := $request?parameters?level
	let $begin as xs:integer* := $request?parameters?begin
	let $start as xs:string* := $request?parameters?start
	let $end as xs:string* := $request?parameters?end
	let $groupBy as xs:string* := $request?parameters?groupBy
	let $page as xs:integer* := $request?parameters?page
	let $max as xs:string* := $request?parameters?max
	let $version as xs:string* := $request?parameters?version
	return let $id := if ($id = "") then
			"http://betamasaheft.eu"
		else
			$id
		let $parsedURN := dtslib:parseDTS($id)
		let $specificID := $parsedURN//s:group[@nr = 3]/text()
		let $edition := $parsedURN//s:group[@nr = 4]
		let $indexes := if (matches($parsedURN//s:group[@nr = 2], "(textualunits|narrativeunits|transcriptions)")) then (
			dtslib:CollIndex($id, $page, $version)
		) else if (matches($specificID, "[a-zA-Z\d]+")) then (
			dtslib:CollIndexMember($id, $edition, $specificID, $page, $version)
		) else (
			dtslib:CollIndex($id, $page, $version)
		)

		let $response := if ($indexName = "") then
			map {
				"@context": $dts:context,
				"@id": $id,
				"member": $indexes,
				"dts:collection": "/api/dts/collections?id=" || $id
			}
		else
			(: an index is named :)
			let $indexEntries := dtslib:indexentries($specificID, $indexName)
			return map {
				"@context": $dts:context,
				"@id": $id,
				"view": dtslib:indexEntriesView($id, $indexName, $indexEntries, $page),
				"dts:attestations": dtslib:indexEntriesAttestations($id, $indexName, $indexEntries, $page),
				"dts:collection": "/api/dts/collections?id=" || $id
			}
		let $dtsPass := "/api/dts/documents?id=" || $id
		let $dtsNav := "/api/dts/navigation?id=" || $id
		let $resultPass := if (matches($parsedURN//s:group[@nr = 3], "[a-zA-Z\d]+")) then
			map:put($response, "dts:passage", $dtsPass)
		else
			$response
		let $resultNav := if (matches($parsedURN//s:group[@nr = 3], "[a-zA-Z\d]+")) then
			map:put($resultPass, "dts:references", $dtsNav)
		else
			$resultPass

		return ($resultNav)
};

(:~
 : annotations main collection, returns a list of collections of annotations, one for each
 : resource type and one for all items in the db with indexable terms
 :)
declare function dts:WebAnnotationsMain($request as map(*)) {
	let $version as xs:string* := $request?parameters?version
	return let $topmembers :=
			for $topcol in ("works", "mss", "narr", "all")
			return dtslib:annotationCollection($topcol, 7, 1)
		return (
			map {
				"@context": $dts:context,
				"@type": "AnnotationCollection",
				"@id": $config:appUrl || "/api/dts/annotations",
				"totalItems": 4,
				"dts:totalParents": 0,
				"dts:totalChildren": 4,
				"member": $topmembers,
				"title": "Annotations Root Collection",
				"dts:dublincore": $dts:publisher
			}
		)
};

(:~
 : annotations collection for a type of items (manuscripts, works or narrative units),
 : returns a list of collections of annotations, one for which available index types
 : 'persons', 'places','keywords', 'loci', 'works' if there are all indexable terms for that index,
 : from items in that resources collection.
 : An additiona Annotation Collaction for
 : each item is added whcih is instead an annotation collection of annotation collections.
 :)
declare function dts:WebAnnotationsColl($request as map(*)) {
	let $coll as xs:string* := $request?parameters?coll
	let $version as xs:string* := $request?parameters?version
	return let $indexnames := ("persons", "places", "keywords", "loci", "works")
		let $indexes := dtslib:CollAnno($coll, $indexnames)
		let $itemsIndex := dtslib:ItemAnnotationCollection($coll, 1)
		let $all := ($indexes, $itemsIndex)
		let $topinfo := dtslib:annotationCollection($coll, count($all), 1)
		let $contents := map {"@context": $dts:context, "member": $all, "dts:dublincore": $dts:publisher}
		return (map:merge(($topinfo, $contents)))
};

(:~
 : annotations collection for a type of items (manuscripts, works or narrative units), and a
 : specific index type among
 : 'persons', 'places','keywords', 'loci', 'works' and 'items'.
 : Indexed passages are grouped by their reference and one annotation collection with that id
 : is provided. the annotations in the single reference  annotation collation are retrieved by
 : adding an $id parameter with the full reference
 :)
declare function dts:WebAnnotationsIndex($request as map(*)) {
	let $coll as xs:string* := $request?parameters?coll
	let $id as xs:string* := $request?parameters?id
	let $indexName as xs:string* := $request?parameters?indexName
	let $begin as xs:integer* := $request?parameters?begin
	let $page as xs:integer* := $request?parameters?page
	let $version as xs:string* := $request?parameters?version
	return let $parsedURN := dtslib:parseDTS($id)
		let $BMid := if (matches($id, "https://betamasaheft.eu")) then
			$parsedURN//s:group[@nr = 3]//text()
		else
			$id
		(: if $indexName is items then list each item in the collection as annotation collection
else print all paginated values for that index in the collection :)
		let $indexEntries := if ($indexName = "items") then
			dtslib:AnnoItems($coll)
		else
			dtslib:indexentriesColl($BMid, $coll, $indexName)
		let $c := count($indexEntries)
		let $indexes := if ($indexName = "items") then
			dtslib:AnnoItemInfo($coll, $indexEntries, $page)
		else if ($id = "") then
			dtslib:AnnoEntriesAttestations($indexName, $indexEntries, $page)
		else
			dtslib:WebAnn($id, $indexEntries, $page)
		let $path := "/api/dts/annotations/" || $coll || "/" || $indexName
		let $v := dtslib:AnnoEntriesView($path, $id, $indexName, $indexEntries, $page)
		let $topinfo := if ($indexName = "items") then
			dtslib:ItemsAnnotationsCollections($coll, $c)
		else if ($id != "") then
			dtslib:refannocol($BMid, $c, $indexName)
		else
			dtslib:CollAnno($coll, $indexName)
		let $response := map {"@context": $dts:context, "view": $v, "member": $indexes, "dts:dublincore": $dts:publisher}
		return (map:merge(($topinfo, $response)))
};

(:~
 : annotations collection for a type of items (manuscripts, works or narrative units), and a
 : specific item in that collection of resources. Returns a collection of annotation collections
 : if available annotations are  present in the item for each type
 : 'persons', 'places','keywords', 'loci', 'works'.
 :)
declare function dts:WebAnnotationsItem($request as map(*)) {
	let $coll as xs:string* := $request?parameters?coll
	let $BMid as xs:string* := $request?parameters?BMid
	let $begin as xs:integer* := $request?parameters?begin
	let $page as xs:integer* := $request?parameters?page
	let $version as xs:string* := $request?parameters?version
	return let $indexes := ("persons", "places", "keywords", "loci", "works")
		let $file := dtslib:switchContext($coll)/id($BMid)
		let $title := exptit:printTitleID($BMid)
		let $availableIndexesForItem :=
			for $index in $indexes
			let $count := dtslib:ItemAnnotationsEntries($file, $index)
			return if ($count = 0) then (
			) else
				dtslib:ItemAnnotationCollections($coll, $BMid, $title, $index, $count, 3)
		let $c := count($availableIndexesForItem)
		let $topinfo := map {
			"@type": "AnnotationCollection",
			"title": "Annotations of " || $title || " in " || $coll,
			"@id": $config:appUrl || "/api/dts/annotations/" || $coll || "/items/" || $BMid,
			"totalItems": $c,
			"dts:totalParents": 3,
			"dts:totalChildren": $c
		}

		let $contents := map {
			"@context": $dts:context,
			"member": $availableIndexesForItem,
			"dts:dublincore": $dts:publisher
		}
		return (map:merge(($topinfo, $contents)))
};

(:~
 : annotations collection for a type of items (manuscripts, works or narrative units), and a
 : specific item in that collection of resources and a specific index type among
 : 'persons', 'places','keywords', 'loci', 'works'.
 : The annotations in the single reference  annotation collation are retrieved by
 : adding an $id parameter with the full reference
 : .
 :)
declare function dts:WebAnnotationsItemIndex($request as map(*)) {
	let $coll as xs:string* := $request?parameters?coll
	let $BMid as xs:string* := $request?parameters?BMid
	let $indexName as xs:string* := $request?parameters?indexName
	let $id as xs:string* := $request?parameters?id
	let $begin as xs:integer* := $request?parameters?begin
	let $page as xs:integer* := $request?parameters?page
	let $version as xs:string* := $request?parameters?version
	return let $file := dtslib:switchContext($coll)/id($BMid)
		let $title := exptit:printTitleID($BMid)
		let $count := dtslib:ItemAnnotationsEntries($file, $indexName)
		let $topinfo := dtslib:ItemAnnotationCollections($coll, $BMid, $title, $indexName, $count, 4)
		let $indexEntries := dtslib:indexentriesFile($file, $id, $indexName)
		(: let $test := console:log($indexEntries) :)
		let $indexes := if ($id = "") then
			dtslib:AnnoEntriesAttestationsItem($BMid, $title, $indexName, $indexEntries, $page)
		else
			dtslib:WebAnn($id, $indexEntries, $page)
		let $path := "/api/dts/annotations/" || $coll || "/items/" || $BMid || "/" || $indexName

		let $v := dtslib:AnnoEntriesView($path, $id, $indexName, $indexEntries, $page)
		let $response := map {"@context": $dts:context, "view": $v, "member": $indexes, "dts:dublincore": $dts:publisher}
		return (map:merge(($topinfo, $response)))
};

declare option output:method "json";
declare option output:indent "yes";
