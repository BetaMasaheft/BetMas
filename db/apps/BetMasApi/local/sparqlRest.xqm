xquery version "3.1" encoding "UTF-8";

(:~
 : module with all the main functions which can be called by the API.
 :
 : @author Pietro Liuzzo
 :)
module namespace apisparql = "https://www.betamasaheft.uni-hamburg.de/BetMasApi/apisparql";

(: namespaces of data used :)
declare namespace test = "http://exist-db.org/xquery/xqsuite";
declare namespace t = "http://www.tei-c.org/ns/1.0";
declare namespace dcterms = "http://purl.org/dc/terms";
declare namespace saws = "http://purl.org/saws/ontology";
declare namespace cmd = "http://www.clarin.eu/cmd/";
declare namespace skos = "http://www.w3.org/2004/02/skos/core#";
declare namespace rdf = "http://www.w3.org/1999/02/22-rdf-syntax-ns#";
declare namespace s = "http://www.w3.org/2005/xpath-functions";
declare namespace sr = "http://www.w3.org/2005/sparql-results#";
(: For REST annotations :)
declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";

import module namespace exptit = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/exptit" at "xmldb:exist:///db/apps/BetMasWeb/modules/exptit.xqm";
import module namespace config = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/config" at "xmldb:exist:///db/apps/BetMasWeb/modules/config.xqm";
import module namespace editors = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/editors" at "xmldb:exist:///db/apps/BetMasWeb/modules/editors.xqm";
import module namespace fusekisparql = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/sparqlfuseki" at "xmldb:exist:///db/apps/BetMasWeb/fuseki/fuseki.xqm";
import module namespace console = "http://exist-db.org/xquery/console";

declare variable $apisparql:prefixes := $config:sparqlPrefixes;

declare function apisparql:constructURIid($request as map(*)) {
	let $id as xs:string* := $request?parameters?id
	return (
		let $uri := $config:baseURI || $id
		let $q := (
			$apisparql:prefixes ||
				"CONSTRUCT {<" ||
				$uri ||
				"> ?p1 ?o1 .
?s2 ?p2 <" ||
				$uri ||
				"> .}
WHERE {{<" ||
				$uri ||
				"> ?p1 ?o1 .}UNION{?s2 ?p2 <" ||
				$uri ||
				"> .}}"
		)
		let $xml := fusekisparql:query("betamasaheft", $q)
		return $xml
	)
};

declare function apisparql:constructURIsubid($request as map(*)) {
	let $id as xs:string* := $request?parameters?id
	let $class as xs:string* := $request?parameters?class
	let $subid as xs:string* := $request?parameters?subid
	return let $uri := $config:appUrl || "/" || $id || "/" || $class || "/" || $subid
		let $q := (
			$apisparql:prefixes ||
				"CONSTRUCT {<" ||
				$uri ||
				"> ?p1 ?o1 .
?s2 ?p2 <" ||
				$uri ||
				"> .}
WHERE {{<" ||
				$uri ||
				"> ?p1 ?o1 .}UNION{?s2 ?p2 <" ||
				$uri ||
				"> .}}"
		)
		let $xml := fusekisparql:query("betamasaheft", $q)
		return ($xml)
};

(: https://betamasaheft.eu/BNFet32/person/annotation/95
https://betamasaheft.eu/BNFet32/place/annotation/1
 :)
declare function apisparql:constructURIannotation($request as map(*)) {
	let $id as xs:string* := $request?parameters?id
	let $class as xs:string* := $request?parameters?class
	let $n as xs:string* := $request?parameters?n
	return let $uri := $config:appUrl || "/" || $id || "/" || $class || "/annotation/" || $n
		let $q := (
			$apisparql:prefixes ||
				"CONSTRUCT {<" ||
				$uri ||
				"> ?p1 ?o1 .
?s2 ?p2 <" ||
				$uri ||
				"> .}
WHERE {{<" ||
				$uri ||
				"> ?p1 ?o1 .}UNION{?s2 ?p2 <" ||
				$uri ||
				"> .}}"
		)
		let $xml := fusekisparql:query("betamasaheft", $q)
		return ($xml)
};

(: https://betamasaheft.eu/bond/snap:GrandfatherOf-PRS1854Amdase :)
declare function apisparql:constructURIbond($request as map(*)) {
	let $bond as xs:string* := $request?parameters?bond
	return let $uri := $config:appUrl || "/bond/" || $bond
		let $q := (
			$apisparql:prefixes ||
				"CONSTRUCT {<" ||
				$uri ||
				"> ?p1 ?o1 .
?s2 ?p2 <" ||
				$uri ||
				"> .}
WHERE {{<" ||
				$uri ||
				"> ?p1 ?o1 .}UNION{?s2 ?p2 <" ||
				$uri ||
				"> .}}"
		)
		let $xml := fusekisparql:query("betamasaheft", $q)
		return ($xml)
};

declare function apisparql:sparqlQuery($request as map(*)) {
	let $query as xs:string* := $request?parameters?query
	return let $q := (
			(
				if (starts-with($query, "PREFIX")) then (
				) else
					$apisparql:prefixes
			) ||
				normalize-space($query)
		)
		let $xml := fusekisparql:query("betamasaheft", $q)
		return $xml
};

declare function apisparql:sparqlITEMgraph($request as map(*)) {
	let $collection as xs:string := $request?parameters?collection
	let $id as xs:string := $request?parameters?id
	return let $xml := doc("/db/rdf/" || $collection || "/" || $id || ".rdf")//rdf:RDF
		return ($xml)
};

declare function apisparql:sparqlITEMgraphJson($request as map(*)) {
	let $collection as xs:string := $request?parameters?collection
	let $id as xs:string := $request?parameters?id
	return let $xml := doc("/db/rdf/" || $collection || "/" || $id || ".rdf")
		let $json := apisparql:xml2json($xml/rdf:RDF)
		return ($json)
};

declare function apisparql:sparqljsonQuery($request as map(*)) {
	let $query as xs:string* := $request?parameters?query
	return (: let $t := console:log($query) :) let $q := (
			(
				if (starts-with($query, "PREFIX")) then (
				) else
					$apisparql:prefixes
			) ||
				normalize-space($query)
		)
		let $xml := fusekisparql:query("betamasaheft", $q)
		let $json := try { apisparql:xml2json($xml[2]/node()) } catch * { console:log($err:description) }
		return ($json)
};

declare function apisparql:xml2json($nodes as node()*) {
	for $node in $nodes
	return typeswitch ($node)
		case element(rdf:RDF) return
			(: add to the map one key / value pair for each statement of the same kind :)
			map:merge(
				for $description in
					$node/element()
					(: key :)
				let $n := count($description/preceding-sibling::*)
				order by $n
				let $rdfabout := string($description/@rdf:about)
				group by $about := $rdfabout
				order by $about
					(: value is an object :)
				let $rels := map:merge(
					for $property in $description/element()
					let $n := count($property/preceding-sibling::*)
					order by $n
					let $pName := $property/name()
					let $label := namespace-uri($property)
					let $pNlocal := substring-after($pName, ":")
					let $pN := ($label || $pNlocal)
					group by $PropName := $pN
					return let $thepairs :=
							for $pair in $property
							let $type := if ($pair/@rdf:resource) then
								"uri"
							else if ($pair/element()) then
								"bnode"
							else
								"literal"
							let $value := if ($pair/@rdf:resource) then
								string($pair/@rdf:resource)
							else if ($pair/element()) then (
								"another node"
							) else
								normalize-space($pair/text())
							let $pairmap := map {"type": $type, "value": $value}
							let $withxmllang := if ($pair/@xml:lang) then
								map:put($pairmap, "xml:lang", string($pair/@xml:lang))
							else
								$pairmap
							let $withtype := if ($pair/@*:datatype) then
								map:put($withxmllang, "datatype", string($pair/@*:datatype))
							else
								$withxmllang
							return $withtype
						let $pairs := if (count($thepairs) > 1) then
							$thepairs
						else
							[$thepairs]
						return map:entry($PropName, $pairs)
				)
				return map:entry($about, $rels)
			)
		(: add to main map the about and its value :)

		case element(sr:sparql) return
			let $vars :=
				for $var in $node/sr:head/sr:variable
				return $var/@*:name
			return map {
				"head":
					map {
						"vars":
							if (count($vars) = 1) then
								[$vars]
							else
								$vars
					},
				"results": apisparql:xml2json($node/sr:results)
			}
		case element(sr:results) return
			map {"bindings": apisparql:xml2json($node/node())}
		case element(sr:result) return
			map:merge(
				for $x in $node/sr:binding
				let $binding := apisparql:xml2json($x/node())
				return map {$x!@*:name: $binding}
			)
		case element(sr:bnode) return
			map {"type": "bnode", "value": $node/text()}
		case element(sr:uri) return
			let $uri := map {"type": "uri", "value": $node/text()}
			let $withxmllang := if ($node/@xml:lang) then
				map:put($uri, "xml:lang", $node/@xml:lang)
			else
				$uri
			let $withtype := if ($node/@*:datatype) then
				map:put($withxmllang, "datatype", $node/@*:datatype)
			else
				$withxmllang
			return $withtype
		case element(sr:literal) return
			let $literal := map {"type": "literal", "value": $node/text()}
			let $withxmllang := if ($node/@xml:lang) then
				map:put($literal, "xml:lang", $node/@xml:lang)
			else
				$literal
			let $withtype := if ($node/@*:datatype) then
				map:put($withxmllang, "datatype", $node/@*:datatype)
			else
				$withxmllang
			return $withtype
		case element() return
			()

		default return
			()
};

declare function apisparql:sparqlQueryJSON($request as map(*)) {
	let $id as xs:string* := $request?parameters?id
	return let $query := (
			$apisparql:prefixes || "
SELECT ?x ?r ?y
WHERE {?x ?r bm:" || $id || " .
?x crm:P48_has_preferred_identifier ?y}"
		)
		let $sparqlresults := fusekisparql:query("betamasaheft", $query)
		let $results := $sparqlresults//sr:result
		return if (count($results) >= 1) then (
			for $result in $results
			let $id := $result//sr:binding[1]//sr:uri/text()
			let $r := $result//sr:binding[2]//sr:uri/text()
			let $y := $result//sr:binding[3]//sr:literal/text()
			let $title := exptit:printTitleID($y)
			return map {"relation": $r, "id": $id, "title": $title}
		) else (
			map {"info": "sorry, no relations available in our RDF data"}
		)
};

declare function apisparql:SdCunits($request as map(*)) {
	let $type as xs:string* := $request?parameters?type
	return let $query := ($apisparql:prefixes || "
SELECT *
WHERE {?x a sdc:Uni" || $type || "}")
		let $sparqlresults := fusekisparql:query("betamasaheft", $query)
		let $results := $sparqlresults//sr:result
		return if (count($results) >= 1) then (
			let $rs :=
				for $result in $results
				return $result//sr:binding//text()
			let $rsarray := if (count($rs) = 1) then
				[$rs]
			else
				$rs
			return map {"results": $rsarray, "total": count($results)}
		) else (
			map {"info": "sorry, no relations available in our RDF data"}
		)
};

declare function apisparql:sparqlQueryVersions($request as map(*)) {
	let $id as xs:string* := $request?parameters?id
	let $chapterID as xs:string* := $request?parameters?chapterID
	return let $query := (
			$apisparql:prefixes ||
				"
SELECT ?otherVersionid
WHERE {
   {bm:" ||
				$id ||
				" saws:isVersionOf ?MAIN .
   ?MAIN crm:P48_has_preferred_identifier ?MAINid .
   ?otherVersion saws:isVersionOf ?MAIN .
   ?otherVersion crm:P48_has_preferred_identifier ?otherVersionid}
   UNION
   { ?version saws:isVersionOf bm:" ||
				$id ||
				" .
   ?version crm:P48_has_preferred_identifier ?otherVersionid }
   }"
		)

		let $sparqlresults := fusekisparql:query("betamasaheft", $query)
		let $results := $sparqlresults//sr:result
		return if (count($results) >= 1) then (
			let $versions :=
				for $result in $sparqlresults//sr:literal/text()[. != $id]
				let $version := collection($config:data-rootW)/id($result)
				let $resTit := exptit:printTitleID($result)
				let $texts := if ($version//t:div[contains(@corresp, $chapterID)]) then (
					for $edition in $version//t:div[@corresp[contains(., $chapterID)]]
					let $respsource := string($edition/parent::t:div[@type eq "edition"]/@resp)
					let $resp := if (starts-with($respsource, "#")) then (
						let $biblID := substring-after($respsource, "#")
						let $bibl := $version//id($biblID)
						return string($bibl/t:ptr/@target)
					) else
						editors:editorKey($respsource)
					let $source := map {"id": $result, "title": $resTit, "ed": $resp}
					let $text := normalize-space(string-join($edition//t:ab/text(), " "))
					let $version := map {"source": $source, "text": $text}
					return map {"version": $version}
				) else if (count($version//t:witness) eq 1) then (
					let $wit := string($version//t:witness/@corresp)
					let $uniqueWitness := collection($config:data-rootMS)/id($wit)
					let $titWit := exptit:printTitleID($wit)
					let $source := map {"id": $result, "title": $resTit, "uniqueWitness": $titWit}
					let $edition := $uniqueWitness//t:div[@corresp[contains(., $chapterID)]]
					return if ($edition) then (
						let $text := normalize-space(string-join($edition//t:ab/text(), " "))
						let $version := map {"source": $source, "text": $text}
						return map {"version": $version}
					) else (
						let $text := "no text available for " ||
							$resTit ||
							" (" ||
							$result ||
							")" ||
							" unique witness " ||
							$titWit ||
							" (" ||
							$wit ||
							")"
						let $version := map {"source": $source, "text": $text}
						return map {"version": $version}
					)
				) else (
					let $source := map {"id": $result, "title": $resTit}
					let $text := "no text available for " || $resTit || " (" || $result || ")"
					let $version := map {"source": $source, "text": $text}
					return map {"version": $version}
				)
				return $texts
			return map {"versions": $versions, "total": count($versions)}
		) else (
			map {"info": "sorry, no relations available in our RDF data"}
		)
};
