xquery version "3.1" encoding "UTF-8";

(:~
 : kwic and simple search from API
 :
 : @author Pietro Liuzzo
 :)
module namespace apiS = "https://www.betamasaheft.uni-hamburg.de/BetMasApi/apiSearch";

declare namespace test = "http://exist-db.org/xquery/xqsuite";
declare namespace t = "http://www.tei-c.org/ns/1.0";
(: For REST annotations :)
declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace json = "http://www.json.org";

import module namespace config = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/config" at "xmldb:exist:///db/apps/BetMasWeb/modules/config.xqm";
import module namespace kwic = "http://exist-db.org/xquery/kwic" at "resource:org/exist/xquery/lib/kwic.xql";
import module namespace all = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/all" at "xmldb:exist:///db/apps/BetMasWeb/modules/all.xqm";
import module namespace log = "http://www.betamasaheft.eu/log" at "xmldb:exist:///db/apps/BetMasWeb/modules/log.xqm";
import module namespace exptit = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/exptit" at "xmldb:exist:///db/apps/BetMasWeb/modules/exptit.xqm";

(: declare variable $apiS:col := collection('/db/apps/expanded'); :)

(:~
 : builds XPath as string to be added to string which will be evaluated by API search.
 :)
declare function apiS:BuildSearchQuery($element as xs:string, $query as xs:string) {
	let $SearchOptions := <options>
		<default-operator>or</default-operator>
		<phrase-slop>0</phrase-slop>
		<leading-wildcard>yes</leading-wildcard>
		<filter-rewrite>yes</filter-rewrite>
	</options>
	return concat("descendant::t:", $element, "[ft:query(., '", $query, "', ", serialize($SearchOptions), ")]")
};

(:~
 : builds XPath as string to be added to string which will be evaluated by API search.
 :)
declare function apiS:BuildSearchQuery2($element as xs:string, $query as xs:string) {
	let $SearchOptions := <options>
		<default-operator>or</default-operator>
		<phrase-slop>0</phrase-slop>
		<leading-wildcard>yes</leading-wildcard>
		<filter-rewrite>yes</filter-rewrite>
	</options>
	return concat("t:", $element, "[ft:query(., '", $query, "', ", serialize($SearchOptions), ")]")
};

declare function apiS:titleTest($request as map(*)) {
	let $id := $request?parameters?id
	return map {"title": exptit:printTitleID($id)}
};

(:~
 : returns a map containing the KWIC hits from the evaluation of an xpath containing lucene full text index queries for the API search.
 :)
declare function apiS:kwicSearch($request as map(*)) {
	let $q as xs:string* := $request?parameters?q
	return if ($q = "" or $q = " ") then (
		<json:value>
			<json:value json:array="true">
				<info>you have to specify a query string and a list or elements, sorry</info>
			</json:value>
		</json:value>
	) else
		let $log := log:add-log-message("/api/kwicsearch?q=" || $q, sm:id()//sm:real/sm:username/string(), "REST")
		let $login := xmldb:login($config:data-root, $config:ADMIN, $config:ppw)

		let $hits := collection($config:data-root)/t:TEI[ft:query(., $q)]
		let $hi :=
			for $hit in $hits
			let $expanded := kwic:expand($hit)
			let $root := root($hit)/t:TEI
			group by $R := $root
			let $id := string($R/@xml:id)
			let $title := exptit:printTitleID($id)
			let $collection := switch ($R/@type)
				case "mss" return
					"manuscripts"
				case "place" return
					"places"
				case "work" return
					"works"
				case "nar" return
					"narratives"
				case "studies" return
					"studies"
				case "ins" return
					"institutions"
				case "pers" return
					"persons"
				default return
					"authority-files"
			let $count := count($expanded//exist:match)
			let $results :=
				for $ex in $expanded
				for $match in subsequence($ex//exist:match, 1, 3)
				return kwic:get-summary($ex, $match, <config width="40" />)
			let $pname := $expanded//exist:match[ancestor::t:div[@type eq "edition"]]
			let $text := if ($pname) then
				"text"
			else
				"main"
			let $textpart := if ($text = "text") then
				let $tpart := $expanded//exist:match[ancestor::t:div[@type eq "edition"]][1]/ancestor::t:div[@type eq
					"textpart"][1]/@n
				return if ($tpart[1]) then
					string($tpart[1])
				else if ($tpart = "") then
					"1"
				else
					"1"
			else (
				"1"
			)

			return map {
				"id": $id,
				"text": $text,
				"textpart": $textpart,
				"collection": $collection,
				"title": $title,
				"hitsCount": $count,
				"results": $results
			}
		let $c := count($hits)
		return if (count($hits) gt 0) then (
			map {"items": $hi, "total": $c}
		) else
			<json:value><json:value json:array="true"><info>No results, sorry</info></json:value></json:value>
};

(:~
 : returns a json object containing the hits from the evaluation of an xpath containing lucene full text index queries for the API search.
 :)
declare function apiS:search($request as map(*)) {
	let $element as xs:string+ := $request?parameters?element
	let $q as xs:string* := $request?parameters?q
	let $collection as xs:string* := $request?parameters?collection
	let $script as xs:string* := $request?parameters?script
	let $material as xs:string* := $request?parameters?material
	let $term as xs:string* := $request?parameters?term
	let $homophones as xs:string* := $request?parameters?homophones
	let $descendants as xs:string* := $request?parameters?descendants
	return if ($q = "" or $q = " " or $element = "") then (
		<json:value>
			<json:value json:array="true">
				<info>you have to specify a query string and a list or elements, sorry</info>
			</json:value>
		</json:value>
	) else
		let $log := log:add-log-message("/api/search?q=" || $q, sm:id()//sm:real/sm:username/string(), "REST")
		let $login := xmldb:login($config:data-root, $config:ADMIN, $config:ppw)
		let $SearchOptions := <options>
			<default-operator>or</default-operator>
			<phrase-slop>0</phrase-slop>
			<leading-wildcard>yes</leading-wildcard>
			<filter-rewrite>yes</filter-rewrite>
		</options>
		let $script := if ($script != "") then (
			"[descendant::t:handNote/@script eq '" || $script || "' ]"
		) else
			""
		let $material := if ($material != "") then (
			"[descendant::t:TEI//t:material/@key eq '" || $material || "' ]"
		) else
			""
		let $term := if ($term != "") then (
			"[descendant::t:TEI//t:term/@key eq '" || $term || "' ]"
		) else
			""

		let $collection := switch ($collection)
			case "manuscripts" return
				$config:data-rootMS
			case "works" return
				$config:data-rootW
			case "places" return
				($config:data-rootPl, $config:data-rootIn)
			case "institutions" return
				$config:data-rootIn
			case "narratives" return
				$config:data-rootN
			case "studies" return
				$config:data-rootS
			case "authority-files" return
				$config:data-rootA
			case "persons" return
				$config:data-rootPr
			default return
				$config:data-root

		let $query-string := if ($homophones = "true") then
			if (contains($q, "AND")) then
				(
					let $parts :=
						for $qpart in tokenize($q, "AND")
						return all:substitutionsInQuery($qpart)
					return "(" || string-join($parts, ") AND (")
				) ||
					")"
			else if (contains($q, "OR")) then
				(
					let $parts :=
						for $qpart in tokenize($q, "OR")
						return all:substitutionsInQuery($qpart)
					return "(" || string-join($parts, ") OR (")
				) ||
					")"
			else
				all:substitutionsInQuery($q)
		else (
			$q
		)

		let $queryhits := "collection($collection)/t:TEI[ft:query(.,$query-string, $SearchOptions)]" ||
			$material ||
			$script ||
			$term
		let $hits := util:eval($queryhits)

		let $results :=
			for $hit in $hits
			let $expanded := kwic:expand($hit)
			let $id := string($hit/ancestor-or-self::t:TEI/@xml:id)
			let $t := normalize-space(exptit:printTitleID($id))
			let $r :=
				for $x in $expanded//exist:match/parent::t:*
				return normalize-space(string-join($x//text(), " "))
			return map {"id": $id, "title": $t, "result": $r}

		let $c := count($hits)
		return if (count($hits) gt 0) then (
			map {"items": $results, "total": $c}
		) else
			<json:value><json:value json:array="true"><info>No results, sorry</info></json:value></json:value>
};
