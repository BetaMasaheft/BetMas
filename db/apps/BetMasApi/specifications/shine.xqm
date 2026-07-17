xquery version "3.1" encoding "UTF-8";

module namespace shine = "https://www.betamasaheft.uni-hamburg.de/BetMasApi/shine";

declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace t = "http://www.tei-c.org/ns/1.0";
declare namespace exist = "http://exist.sourceforge.net/NS/exist";
declare namespace s = "http://www.w3.org/2005/xpath-functions";
declare namespace http = "http://expath.org/ns/http-client";
declare namespace json = "http://www.json.org";
declare namespace cx = "http://interedition.eu/collatex/ns/1.0";
declare namespace sr = "http://www.w3.org/2005/sparql-results#";
declare namespace test = "http://exist-db.org/xquery/xqsuite";

import module namespace roaster = "http://e-editiones.org/roaster";
import module namespace functx = "http://www.functx.com";
import module namespace log = "http://www.betamasaheft.eu/log" at "xmldb:exist:///db/apps/BetMasWeb/modules/log.xqm";
import module namespace exptit = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/exptit" at "xmldb:exist:///db/apps/BetMasWeb/modules/exptit.xqm";
import module namespace config = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/config" at "xmldb:exist:///db/apps/BetMasWeb/modules/config.xqm";
import module namespace sparql = "http://exist-db.org/xquery/sparql" at "java:org.exist.xquery.modules.rdf.SparqlModule";
import module namespace string = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/string" at "xmldb:exist:///db/apps/BetMasWeb/modules/tei2string.xqm";
import module namespace switch2 = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/switch2" at "xmldb:exist:///db/apps/BetMasWeb/modules/switch2.xqm";
import module namespace editors = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/editors" at "xmldb:exist:///db/apps/BetMasWeb/modules/editors.xqm";
import module namespace dtslib = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/dtslib" at "xmldb:exist:///db/apps/BetMasWeb/modules/dtslib.xqm";

declare variable $shine:TU := collection($config:data-rootW)//t:div[@type = "edition"][descendant::t:ab[text()]];

declare variable $shine:MS := collection($config:data-rootMS)//t:div[@type = "edition"][descendant::t:ab[text()]];

declare variable $shine:all := ($shine:TU, $shine:MS);

declare function shine:main($request as map(*)) {
	(
		(
			map {"uuid": "betmas", "name": "Beta maṣāḥǝft Textual Units", "resourceCount": count($shine:TU)},
			map {"uuid": "betmasMS", "name": "Beta maṣāḥǝft Manuscripts", "resourceCount": count($shine:MS)}
		)
	)
};

declare function shine:collection($request as map(*)) {
	let $uuid as xs:string+ := $request?parameters?uuid
	return if (contains($uuid, "betmas")) then (
		let $collection := if ($uuid = "betmasMS") then
			$shine:MS
		else
			$shine:TU
		for $resource in $collection
		let $r := root($resource)/t:TEI
		let $id := string($r/@xml:id)
		let $title := normalize-space(string-join($r//t:titleStmt/t:title/text(), " / "))
		return map {"uuid": $id, "name": $title}
	) else
		roaster:response(404, ())
};

declare function shine:resMeta($request as map(*)) {
	let $uuid as xs:string+ := $request?parameters?uuid
	return let $TEI := $shine:all[ancestor::t:TEI[@xml:id = $uuid]]
		return if (count($TEI) = 1) then (
			dtslib:dublinCore($uuid)
		) else
			roaster:response(404, ())
};

declare function shine:resSection($request as map(*)) {
	let $uuid as xs:string+ := $request?parameters?uuid
	return let $TEI := $shine:all[ancestor::t:TEI[@xml:id = $uuid]]
		return if ((count($TEI) = 1) and $TEI/t:div) then (
			if (count($TEI/t:div) = 1) then
				[shine:sections($TEI, $uuid)]
			else
				shine:sections($TEI, $uuid)
		) else
			roaster:response(404, ())
};

declare function shine:CU($request as map(*)) {
	let $uuid as xs:string+ := $request?parameters?uuid
	return let $mainID := substring-before($uuid, "_")
		let $nodeID := substring-after($uuid, "_")
		let $TEI := $shine:all[ancestor::t:TEI[@xml:id = $mainID]]
		let $node :=
			for $candidate in $TEI/descendant-or-self::t:div
			let $candidateID := generate-id($candidate)
			return if ($nodeID eq $candidateID) then
				$candidate
			else (
			)
		let $text := if ($node/t:ab) then
			string-join(string:tei2string($node/t:ab), " ")
		else
			for $ab in $node//t:ab
			return string:tei2string($ab)
		return if (count($node) = 1) then (
			let $seq :=
				for $t at $p in $text
				return map {"uuid": ($uuid || "_string" || $p), "content": normalize-space($t)}
			return if (count($seq) = 1) then
				[$seq]
			else
				$seq
		) else
			roaster:response(404, ())
};

declare function shine:sectionName($d, $p, $uuid) {
	let $t := if ($d/t:label) then (
	) else if ($d/@subtype) then
		string($d/@subtype)
	else
		string($d/@type)
	let $n := if ($d/@corresp) then
		let $c := string($d/@corresp)
		return exptit:printTitleID($c)
	else if ($d/t:label) then
		string:tei2string($d/t:label)
	else if ($d/@xml:id) then
		if (contains($d/@xml:id, $t)) then
			replace(string($d/@xml:id), $t, "")
		else
			string($d/@xml:id)
	else
		$p
	let $all := string-join($t, " ") ||
		(
			if ($t) then
				" "
			else (
			)
		) ||
		string-join($n, " ")
	return normalize-space($all)
};

declare function shine:sections($div, $uuid) {
	for $d at $p in $div/t:div
	let $nid := generate-id($d)
	let $parentnode := $d/parent::t:div
	let $name := shine:sectionName($d, $p, $uuid)
	let $all := (
		map {
			"uuid": encode-for-uri($uuid || "_" || $nid),
			"name": $name,
			"uri": $config:appUrl || "/" || $uuid,
			"contentUnitCount": count($d/t:div[t:ab])
		},
		shine:sections($d, $uuid)
	)

	let $parentUuid := if ($d/parent::t:div[@type = "edition"]) then
		$all
	else
		map:put($all, "parentUuid", ($uuid || "_" || generate-id($parentnode)))

	return $parentUuid
};
