xquery version "3.1" encoding "UTF-8";

(:~
 : module with all the main functions which can be called by the API.
 :
 : @author Pietro Liuzzo
 :)
module namespace api = "https://www.betamasaheft.uni-hamburg.de/BetMasApi/api";

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
declare namespace json = "http://www.json.org";

import module namespace roaster = "http://e-editiones.org/roaster";
import module namespace log = "http://www.betamasaheft.eu/log" at "xmldb:exist:///db/apps/BetMasWeb/modules/log.xqm";
import module namespace dts = "https://www.betamasaheft.uni-hamburg.de/BetMasApi/dts" at "../specifications/dts.xqm";
import module namespace editors = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/editors" at "xmldb:exist:///db/apps/BetMasWeb/modules/editors.xqm";
import module namespace exptit = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/exptit" at "xmldb:exist:///db/apps/BetMasWeb/modules/exptit.xqm";
import module namespace config = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/config" at "xmldb:exist:///db/apps/BetMasWeb/modules/config.xqm";
import module namespace viewItem = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/viewItem" at "xmldb:exist:///db/apps/BetMasWeb/modules/viewItem.xqm";
import module namespace string = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/string" at "xmldb:exist:///db/apps/BetMasWeb/modules/tei2string.xqm";

declare %private function api:namedEntityTitleNoLink($entity) {
	let $id := replace($entity/@ref, "https://betamasaheft.eu/", "")
	return (
		concat(substring(string-join($entity//text()), 1, 30), "..."),
		(
			" (" ||
				"CAe " ||
				substring($id, 4, 4) ||
				(
					if (contains($id, "#")) then
						(" " || substring-after($id, "#")) || ")"
					else (
					)
				) ||
				" "
		),
		if ($entity/@evidence) then
			concat(" (", $entity/@evidence, ")")
		else (
		),
		" ",
		if ($entity/@cert = "low") then
			"?"
		else (
		),
		" / "
	)
};

declare %private function api:msItem($mainID, $msItem) {
	let $id := string($msItem/@xml:id)
	let $msItemsCount := count($msItem/ancestor::t:TEI//t:msItem)
	let $trimid := if ($msItem/parent::t:msContents) then
		concat(replace($id, "\.", "-"), "N", $msItem/position())
	else
		replace($id, "\.", "-")
	return <div
		class="w3-container msItem"
		id="mi{ $id }"
		resource="https://betamasaheft.eu/{ $mainID }/msitem/{ $id }"
		typeof="https://betamasaheft.eu/msitem https://w3id.org/sdc/ontology#UniCont"
	>
		<button
			class="w3-button w3-gray contentItem "
			onclick="openAccordion('item{ $trimid }')"
			resource="https://betamasaheft.eu/{ $mainID }/msitem/{ $id }"
			style="max-width:100%"
		>
			{ api:namedEntityTitleNoLink($msItem/t:title) } Item { $id }
			{
				if ($msItem/t:msItem) then
					<span
						about="https://betamasaheft.eu/{ $mainID }/msitem/{ $id }"
						class="w3-badge w3-margin-left"
						property="http://www.cidoc-crm.org/cidoc-crm/P57_has_number_of_parts"
					>{ count($msItem/t:msItem) }</span>
				else (
				)
			}
		</button>
		<div class="w3-hide msItemContent" id="item{ $trimid }">
			<div class="w3-container">
				<hr align="left" class="msItems" />
				{
					let $anchor := concat("#", $id)
					return if ($msItem//ancestor::t:TEI//t:div[@corresp = $anchor]) then
						let $number := if ($msItem/ancestor::t:TEI//t:div[@corresp = $anchor]/@n) then
							$msItem/ancestor::t:TEI//t:div[@corresp = $anchor]/@n
						else
							1
						return <a
							class="w3-button w3-gray w3-small"
							href="/manuscripts/{ $mainID }/text?per-page=1&amp;start={ $number }"
							role="button"
						>Transcription</a>
					else (
					)
				}
				{
					let $allChildren := $msItem/t:msItem
					let $countChildren := count($allChildren)
					return if (($msItemsCount gt 100) and ($countChildren gt 10)) then (
						<div>
							<a
								class="w3-button msitemloader w3-yellow"
								data-mainid="{ $mainID }"
								data-msitem="{ replace($msItem/@xml:id, "\.", "-") }"
								data-start="1"
							>
                                       Click here to load the first 10 of {
									$countChildren
								} items.
                                   </a>
							<div id="msitemloadcontainer{ replace($msItem/@xml:id, "\.", "-") }" />
						</div>
					) else if ($countChildren gt 0) then (
						viewItem:TEI2HTML($msItem/node()[not(name() = "msItem")]),
						for $m in $msItem/t:msItem
						let $innerMsItem := api:msItem($mainID, $m)
						return <div class="w3-container" id="contentItem{ $trimid }" rel="http://purl.org/dc/terms/hasPart">
							{ $innerMsItem }
						</div>
					) else
						viewItem:TEI2HTML($msItem/node())
				}
			</div>
		</div>
	</div>
};

declare function api:loadmsItems($request as map(*)) {
	let $mainid as xs:string* := $request?parameters?mainid
	let $msItem as xs:string* := $request?parameters?msItem
	let $start as xs:integer* := $request?parameters?start
	let $limit as xs:integer* := $request?parameters?limit
	return let $item := collection($config:data-rootMS)/id($mainid)
		let $msItemID := replace($msItem, "-", ".")
		let $msItem := $item/id($msItemID)
		let $allChildren := $msItem/t:msItem
		let $countChildren := count($allChildren)
		let $subset := subsequence($allChildren, $start, $limit)
		let $next := $start + $limit
		let $items :=
			for $ms in $subset
			return api:msItem($mainid, $ms)
		let $loader := if ($next le $countChildren) then
			<a
				class="w3-button msitemloader w3-yellow"
				data-mainid="{ $mainid }"
				data-msitem="{ replace($msItem/@xml:id, "\.", "-") }"
				data-start="{ $next }"
			>
         Load more items...
    </a>
		else (
		)
		return map {
			"msitems": $items,
			"hasMore": $next le $countChildren,
			"next":
				if ($next le $countChildren) then
					$next
				else (
				)
		}
};

declare function api:listRepositoriesName($request as map(*)) {
	for $i in doc("/db/apps/lists/institutions.xml")//t:item
	let $name := $i/text()
	order by $name
	return <option value="{ string($i/@xml:id) }">{ $name }</option>
};

declare function api:getcataloguesZotero($request as map(*)) {
	for $catalogue in doc("/db/apps/lists/catalogues.xml")//t:item
	let $sorting := $catalogue//text()[1]
	order by $sorting
	return <option value="{ replace(string($catalogue/@xml:id), "bm_", "") }">{ $catalogue//text() }</option>
};

(: given a work id returns the witnesses of works in which this is contained :)
declare function api:witnessesOfContainerWork($request as map(*)) {
	let $id as xs:string* := $request?parameters?id
	return let $id := if (starts-with($id, $config:baseURI)) then
			string($id)
		else
			$config:baseURI || string($id)
		let $corresps := $dts:collection-rootW//t:div[@type eq "textpart"][@corresp eq $id]
		for $c in $corresps
		let $workid := string(root($c)/t:TEI/@xml:id)
		let $witnesses := $dts:collection-rootMS//t:title[contains(@ref, $workid)]
		let $witnessesID :=
			for $w in $witnesses
			let $wid := string(root($w)/t:TEI/@xml:id)
			return exptit:printTitle($wid)
		let $tit := exptit:printTitle($workid)
		return map {"containerWork": $tit, "witnesses": config:distinct-values($witnessesID)}
};

(: displayes on the hompage the totals of the portal :)
declare function api:count($request as map(*)) {
	(
		let $total := count($exptit:col)
		let $totalMS := count($exptit:col/t:TEI[@type = "mss"])
		let $totalInstitutions := count($exptit:col/t:TEI[@type = "ins"])
		let $totalWorks := (
			count($exptit:col/t:TEI[@type = "work"]) +
				count($exptit:col/t:TEI[@type = "nar"]) +
				count($exptit:col/t:TEI[@type = "studies"])
		)
		let $totalPersons := count($exptit:col/t:TEI[@type = "pers"])
		return map {
			"total": $total,
			"totalMS": $totalMS,
			"totalInstitutions": $totalInstitutions,
			"totalWorks": $totalWorks,
			"totalPersons": $totalPersons
		}
	)
};

(: displaies on the hompage the totals of the portal :)
declare function api:latest($request as map(*)) {
	(
		let $twoweekago := current-date() - xs:dayTimeDuration("P15D")
		let $coll := collection($config:data-root)//t:TEI
		for $doc in subsequence(xmldb:find-last-modified-since($coll, $twoweekago), 1, 20)
		let $id := string($doc/@xml:id)
		let $filename := ($id || ".xml")
		let $baseUri := base-uri($doc)
		let $docColl := substring-before($baseUri, $filename)
		let $latest :=
			for $c in $doc//t:change
			return $c
		return map {
			"id": $id,
			"title": exptit:printTitle($id),
			"when": xmldb:last-modified($docColl, $filename),
			"who": editors:editorKey(substring-after($latest[1]/@who, "#")),
			"what": $latest[1]/text()
		}
	)
};

(:~
 : transforms into string text a single part of a tei file, e.g. a single node which contains many references to persons, places etc.
 :)
declare function api:teiNode2string($request as map(*)) {
	let $id as xs:string := $request?parameters?id
	let $element as xs:string* := $request?parameters?element
	return (
		let $file := api:get-tei-by-ID($id)
		let $string :=
			for $e in $file//t:*[name() = $element]
			return string:tei2string($e/node())
		return normalize-space(string-join($string, ""))
	)
};

(:~
 : retrives a single part of a tei file, e.g. a single node
 :)
declare %test:args("BNFet102", "additions") %test:assertXPath("//*:item") function api:teipart($request as map(*)) {
	let $id as xs:string := $request?parameters?id
	let $element as xs:string* := $request?parameters?element
	return (
		let $file := api:get-tei-by-ID($id)
		for $e in $file//t:*[name() = $element]
		return <fragment>{ $e/node() }</fragment>
	)
};

(:~
 : retrives a single part of a tei file given a URI as formatted in the RDF, e.g. a single node
 :)
declare %test:args("BNFet102", "addition", "e1") %test:assertXPath("//*:item") function api:teipartbyURI(
	$request as map(*)
) {
	let $id as xs:string := $request?parameters?id
	let $type as xs:string := $request?parameters?type
	let $subid as xs:string := $request?parameters?subid
	return let $element := switch ($type)
			case "addition" return
				"item"
			case "msitem" return
				"msItem"
			case "mspart" return
				"msPart"
			case "msfrag" return
				"msFrag"
			case "quire" return
				"item"
			case "hand" return
				"handDesc"
			case "layout" return
				"layout"
			case "binding" return
				"decoNote"
			case "decoration" return
				"decoNote"
			default return
				"nomatch"
		return if ($element = "nomatch") then (
			roaster:response(404, ())
		) else (
			let $file := api:get-tei-by-ID($id)
			for $e in $file//id($subid)[name() = $element]
			return <fragment xmlns="https://betamasaheft.eu/" source="https://betamasaheft.eu/{ $id }">{ $e }</fragment>
		)
};

(:~
 : gets the formatted content of an addition in an item, given the id of the file and that of the addition item
 :)
declare %test:args("BAVet1", "a4") %test:assertExists function api:additiontext($request as map(*)) {
	let $id as xs:string* := $request?parameters?id
	let $addID as xs:string* := $request?parameters?addID
	return let $log := log:add-log-message(
			"/api/additions/" || $id || "/addition/" || $addID,
			sm:id()//sm:real/sm:username/string(),
			"REST"
		)
		let $entity := $exptit:col/id($id)
		let $a := $entity//t:item[@xml:id = $addID]
		return <div xmlns="https://www.w3.org/1999/xhtml">{ viewItem:q($a) }</div>
};

(:~
 : returns the relation element with the author attribution
 :)

declare
	%test:arg("id", "LIT1032Agains") %test:assertXPath("//@name[. = 'saws:isAttributedToAuthor']")
function api:getauthorfromrelation($request as map(*)) {
	let $id as xs:string* := $request?parameters?id
	return let $item := $dts:collection-rootW/id($id)
		return if ($item//t:relation[@name eq "saws:isAttributedToAuthor"]) then (
			log:add-log-message("/api/" || $id || "/author", sm:id()//sm:real/sm:username/string(), "REST"),
			$item//t:relation[@name eq "saws:isAttributedToAuthor"]
		) else (
			roaster:response(400, <sorry>no info</sorry>)
		)
};

(:~
 : returns a xml fragment with the element in a resource which has the given anchor
 :)
declare %test:args("IVefiopsk1", "a1", "item") %test:assertXPath("//element") function api:get-othertext(
	$request as map(*)
) {
	let $id as xs:string := $request?parameters?id
	let $SUBid as xs:string := $request?parameters?SUBid
	let $element as xs:string* := $request?parameters?element
	return let $log := log:add-log-message(
			"/api/otherMssText/" || $id || "/" || $SUBid,
			sm:id()//sm:real/sm:username/string(),
			"REST"
		)
		let $login := xmldb:login($config:data-root, $config:ADMIN, $config:ppw)
		return (
			let $collection := "manuscripts"
			let $item := api:get-tei-rec-by-ID($id)
			return if ($item//t:*[(name() = $element) or (@xml:id = $SUBid)]//text()) then
				let $match := $item//t:*[@xml:id = $SUBid]//name()
				return <othermsselement>
					<id>{ $id }</id>
					<element>{ $match } #{ $SUBid }</element>
					<url>{ $config:appUrl }/manuscripts/{ $id }#{ $SUBid }</url>
					{
						for $q in $item//t:*[@xml:id = $SUBid]/t:q
						return <text lang="{ $q/@xml:lang }">{ $q/text() }</text>
					}
					{
						for $type in $item//t:*[@xml:id = $SUBid]/t:*[@type]
						return <type>{ string($type/@type) }</type>
					}
					{
						if ($match = "msPart") then
							<contains>
								{
									for $e in $item//t:*[@xml:id = $SUBid]//child::*
									return element {$e/name()} { $e/text() }
								}
							</contains>
						else if ($match = "msItem") then (
							<is>{ string($item//t:*[@xml:id = $SUBid]/t:title/@corresp) }</is>,
							<contains>
								{
									for $e in $item//t:*[@xml:id = $SUBid]//child::*
									return element {$e/name()} { $e/text() }
								}
							</contains>
						) else (
						)
					}
				</othermsselement>
			else
				let $call := $config:appUrl || "/api/extra/" || $id || "/" || $SUBid
				return api:noresults($call)
		)
};

(:~
 : The following function retrive the text of the selected work and returns
 : it with basic informations for next and following into a small XML tree
 :
 :)
declare %test:arg("id", "LIT1367Exodus") %test:assertXPath("//contains") function api:get-workXML($request as map(*)) {
	let $id as xs:string := $request?parameters?id
	return let $log := log:add-log-message("/api/xml/" || $id, sm:id()//sm:real/sm:username/string(), "REST")
		let $login := xmldb:login($config:data-root, $config:ADMIN, $config:ppw)
		return (
			let $collection := "works"
			let $item := api:get-tei-rec-by-ID($id)
			let $recordid := $item/t:TEI/@xml:id
			return if ($item//t:div[@type eq "edition"]) then
				<work>
					<id>{ data($recordid) }</id>
					<text>{ $item//t:div[@type eq "edition"]//text() }</text>
					<contains>
						{
							for $subtype in $item//t:div[@type eq "edition"]/t:div[@subtype]
							return element {string($subtype/@subtype)} {
								($config:appUrl || "/api/xml/" || $id || "/" || $subtype/@n)
							}
						}
					</contains>
				</work>

			else
				let $call := $config:appUrl || "/api/xml/" || $id
				return api:noresults($call)
		)
};

declare function api:citation($item as node()) {
	if ($item//t:titleStmt/t:title[@type eq "short"]) then
		$item//t:titleStmt/t:title[@type eq "short"]/text()
	else
		$item//t:titleStmt/t:title[@xml:id eq "t1"]/text()
};

(:~
 : given the file id, returns the source TEI xml
 :)
declare function api:get-tei-by-ID($id as xs:string) {
	let $log := log:add-log-message("/api/" || $id || "/tei", sm:id()//sm:real/sm:username/string(), "REST")
	let $login := xmldb:login($config:data-root, $config:ADMIN, $config:ppw)
	return (api:get-tei-rec-by-ID($id))
};

declare %test:arg("id", "LIT1367Exodus") %test:assertXPath("//*:text") function api:get-tei-by-ID-route(
	$request as map(*)
) {
	api:get-tei-by-ID($request?parameters?id)
};

(:~
 : given the file id, returns the source TEI xml
 :)
declare %test:arg("id", "LIT1367Exodus") %test:assertXPath("//*:text") function api:get-POSTPROCESSED-tei-by-ID(
	$request as map(*)
) {
	let $id as xs:string := $request?parameters?id
	return let $log := log:add-log-message("/api/post/" || $id || "/tei", sm:id()//sm:real/sm:username/string(), "REST")
		let $doc := api:get-tei-rec-by-ID($id)
		return ($doc)
};

(:~
 : given the file id, returns the source TEI in a json serialization
 :)
declare function api:get-tei2json-by-ID($request as map(*)) {
	let $id as xs:string := $request?parameters?id
	return let $log := log:add-log-message("/api/" || $id || "/json", sm:id()//sm:real/sm:username/string(), "REST")
		let $login := xmldb:login($config:data-root, $config:ADMIN, $config:ppw)
		return (<json:value>{ api:get-tei-rec-by-ID($id) }</json:value>)
};

(:~
 : Returns tei record
 :)
declare function api:get-tei-rec($collection as xs:string, $id as xs:string) as node()* {
	let $uri := concat($config:data-root, "/", $collection, "/", $id, ".xml")
	return doc($uri)
};

declare function api:get-tei-rec-by-ID($id as xs:string) as node()* {
	$exptit:col/id($id)
};

(:~
 : this is the feedback in case no result is found
 :)
declare function api:noresults($call) {
	<html xmlns="http://www.w3.org/1999/xhtml">
		<head />
		<body>
			<h1>No results for { $call }, sorry!</h1>
			<br />
			<p>Trouble shooting:
                <ul>
					<li>The api documentation is <a href="/apidoc.html">here.</a></li>
					<li>Check the correct id exists <a href="/works/list">here.</a></li>
					<li>Your requested uri should look something like this
                        <blockquote>
							{ $config:appUrl }/api/xml/{{id}}/{{level}}/{{level2}}/{{line}}</blockquote>
						<blockquote>{ $config:appUrl }/api/xml/LIT1367Exodus/2/4</blockquote>
						<blockquote>
							{
								$config:appUrl
							}/api/xml/LIT1367Exodus/2/4-7</blockquote>
                        if not, see above! The first example will not work, the second and third will.
                        Why: if you ask for an extra level of structure which we don't have, you will not get results.</li>
				</ul>
			</p>
		</body>
	</html>
};
