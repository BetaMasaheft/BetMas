xquery version "3.1" encoding "UTF-8";

(:~
 : clavis matching related funtions.
 :
 : @author Pietro Liuzzo
 :)
module namespace clavis = "https://www.betamasaheft.uni-hamburg.de/BetMasApi/clavis";

(: namespaces of data used :)

declare namespace t = "http://www.tei-c.org/ns/1.0";
declare namespace json = "http://www.json.org";

import module namespace log = "http://www.betamasaheft.eu/log" at "xmldb:exist:///db/apps/BetMasWeb/modules/log.xqm";
import module namespace exptit = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/exptit" at "xmldb:exist:///db/apps/BetMasWeb/modules/exptit.xqm";
import module namespace config = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/config" at "xmldb:exist:///db/apps/BetMasWeb/modules/config.xqm";

(:~
 : returns a JSON object with the aligned known clavis ids
 :)
declare function clavis:ClavisbyID($request as map(*)) {
	let $id as xs:string* := $request?parameters?id
	return (: results from PAThs
results from BM interroga bibl con id clavis e titolo.
se interrogato da titolo da gli id, altrimenti per id da gli altri id e il titolo

 :) let $log := log:add-log-message("/api/clavis/" || $id, sm:id()//sm:real/sm:username/string(), "REST")
		let $root := $exptit:col//id($id)[self::t:TEI]
		let $id := string($root/@xml:id)
		let $title := exptit:printTitleID($id)
		let $clavisBibl := $root//t:listBibl[@type eq "clavis"]
		let $CC := $clavisBibl/t:bibl[@type eq "CC"]/t:citedRange/text()
		let $CPG := $clavisBibl/t:bibl[@type eq "CPG"]/t:citedRange/text()
		let $CANT := $clavisBibl/t:bibl[@type eq "CANT"]/t:citedRange/text()
		let $CAVT := $clavisBibl/t:bibl[@type eq "CAVT"]/t:citedRange/text()
		let $BHO := $clavisBibl/t:bibl[@type eq "BHO"]/t:citedRange/text()
		let $BHL := $clavisBibl/t:bibl[@type eq "BHL"]/t:citedRange/text()
		let $syriaca := $clavisBibl/t:bibl[@type eq "syriaca"]/t:citedRange/text()
		let $clavisIDS := map {
			"CC": $CC,
			"CPG": $CPG,
			"CANT": $CANT,
			"CAVT": $CAVT,
			"BHO": $BHO,
			"BHL": $BHL,
			"syriaca": $syriaca
		}

		return (map {"CAe": $id, "title": $title, "clavis": $clavisIDS})
};

(:~
 : returns a JSON object with the aligned known clavis ids
 :)
declare function clavis:ClavisALL($request as map(*)) {
	let $id as xs:string* := $request?parameters?id
	let $type as xs:string* := $request?parameters?type
	(: results from PAThs
results from BM interroga bibl con id clavis e titolo.
se interrogato da titolo da gli id, altrimenti per id da gli altri id e il titolo

 :)
	let $path := $exptit:col//t:listBibl[@type eq "clavis"]
	(: If we are given a type, also filter by type. :)
	let $path := if ($type) then
		$path[t:bibl[@type = $type]]
	else
		$path
	let $results :=
		for $work in $path
		let $root := root($work)
		let $id := string($root/t:TEI/@xml:id)
		let $title := exptit:printTitleID($id)
		let $CC := $work/t:bibl[@type eq "CC"]/t:citedRange/text()
		let $CPG := $work/t:bibl[@type eq "CPG"]/t:citedRange/text()
		let $CANT := $work/t:bibl[@type eq "CANT"]/t:citedRange/text()
		let $CAVT := $work/t:bibl[@type eq "CAVT"]/t:citedRange/text()
		let $BHO := $work/t:bibl[@type eq "BHO"]/t:citedRange/text()
		let $BHL := $work/t:bibl[@type eq "BHL"]/t:citedRange/text()
		let $syriaca := $work/t:bibl[@type eq "syriaca"]/t:citedRange/text()
		let $clavisIDS := map {
			"CC": $CC,
			"CPG": $CPG,
			"CANT": $CANT,
			"CAVT": $CAVT,
			"BHO": $BHO,
			"BHL": $BHL,
			"syriaca": $syriaca
		}

		return map {
			"CAe": $id,
			"CAeN": substring($id, 4, 4),
			"CAeURL": "https://betamasaheft.eu/works/" || $id || "/main",
			"title": $title,
			"clavis": $clavisIDS
		}

	return (map {"results": $results, "total": count($results)})
};

(: results from PAThs
results from BM interroga bibl con id clavis e titolo.
se interrogato da titolo da gli id, altrimenti per id da gli altri id e il titolo

 :)
declare function clavis:Clavis($request as map(*)) {
	let $q as xs:string+ := $request?parameters?q

	let $log := log:add-log-message("/api/clavis?q=" || $q, sm:id()//sm:real/sm:username/string(), "REST")
	let $hits := collection($config:data-rootW)//t:TEI[ft:query(., $q)]
	let $hi :=
		for $hit in $hits
		let $root := root($hit)
		let $id := string($root//t:TEI/@xml:id)
		group by $id := $id
		let $title := exptit:printTitleID($id)
		let $hitCount := count($hit)
		let $clavisBibl := $root//t:listBibl[@type eq "clavis"]
		let $CC := $clavisBibl/t:bibl[@type eq "CC"]/t:citedRange/text()
		let $CPG := $clavisBibl/t:bibl[@type eq "CPG"]/t:citedRange/text()
		let $CANT := $clavisBibl/t:bibl[@type eq "CANT"]/t:citedRange/text()
		let $CAVT := $clavisBibl/t:bibl[@type eq "CAVT"]/t:citedRange/text()
		let $BHO := $clavisBibl/t:bibl[@type eq "BHO"]/t:citedRange/text()
		let $BHL := $clavisBibl/t:bibl[@type eq "BHL"]/t:citedRange/text()
		let $syriaca := $clavisBibl/t:bibl[@type eq "syriaca"]/t:citedRange/text()
		let $clavisIDS := map {
			"CC": $CC,
			"CPG": $CPG,
			"CANT": $CANT,
			"CAVT": $CAVT,
			"BHO": $BHO,
			"BHL": $BHL,
			"syriaca": $syriaca
		}

		return map {"CAe": $id, "title": $title, "clavis": $clavisIDS, "hits": $hitCount}
	let $c := count($hits)
	return if (count($hits) gt 0) then (
		map {"items": $hi, "totalhits": $c}
	) else (
		<json:value><json:value json:array="true"><info>No results, sorry</info></json:value></json:value>
	)
};
