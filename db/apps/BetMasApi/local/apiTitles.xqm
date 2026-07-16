xquery version "3.1" encoding "UTF-8";

(:~
 : titles from API
 :
 : @author Pietro Liuzzo
 :)

module namespace apiTit = "https://www.betamasaheft.uni-hamburg.de/BetMasApi/apiTitles";

(: namespaces of data used :)
declare namespace t = "http://www.tei-c.org/ns/1.0";
(: For REST annotations :)
declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";

import module namespace exptit = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/titles" at "xmldb:exist:///db/apps/BetMasWeb/modules/titles.xqm";
import module namespace config = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/config" at "xmldb:exist:///db/apps/BetMasWeb/modules/config.xqm";

declare variable $apiTit:TUList := doc("/db/apps/lists/textpartstitles.xml");

(:~
 : given the file id, returns the main title
 :)
declare function apiTit:get-FormattedTitle($request as map(*)) {
	let $id as xs:string := $request?parameters?id
	return (
		let $id := replace($id, "_", ":")

		return if (not(contains($id, ":"))) then
			normalize-space(string-join(exptit:printTitleMainID($id)))
		else if (
			starts-with($id, "wd:") or starts-with($id, "pleaides:") or starts-with($id, "sdc:") or starts-with($id, "gn:")
		) then
			normalize-space(exptit:printTitleMainID($id))
		else
			$id
	)
};

(:~
 : given the file id, returns the main title
 :)
declare function apiTit:get-FormattedTitleJson($request as map(*)) {
	let $id as xs:string := $request?parameters?id
	return (
		let $id := replace($id, "_", ":")
		let $titletext := if (not(contains($id, ":"))) then
			normalize-space(string-join(exptit:printTitleMainID($id)))
		else if (
			starts-with($id, "wd:") or starts-with($id, "pleaides:") or starts-with($id, "sdc:") or starts-with($id, "gn:")
		) then
			normalize-space(exptit:printTitleMainID($id))
		else
			$id

		return map {"title": $titletext}
	)
};

(:~
 : given the file id and an anchor, returns the formatted main title and the title of the reffered section
 :)
declare function apiTit:get-FormattedTitleandID($request as map(*)) {
	let $id as xs:string := $request?parameters?id
	let $SUBid as xs:string := $request?parameters?SUBid
	return (
		let $fullid := ($id || "#" || $SUBid)
		return if ($apiTit:TUList//t:item[@corresp eq $fullid]) then (
			$apiTit:TUList//t:item[@corresp eq $fullid]/node()
		) else (
			exptit:printTitleID($fullid)
		)
	)
};
