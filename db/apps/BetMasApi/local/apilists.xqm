xquery version "3.1" encoding "UTF-8";

(:~
 : lists from API
 :
 : @author Pietro Liuzzo
 :)
module namespace apiL = "https://www.betamasaheft.uni-hamburg.de/BetMasApi/apiLists";

(: namespaces of data used :)
declare namespace t = "http://www.tei-c.org/ns/1.0";
declare namespace json = "http://www.w3.org/2013/XSL/json";
declare namespace test = "http://exist-db.org/xquery/xqsuite";
(: For REST annotations :)
declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";

import module namespace log = "http://www.betamasaheft.eu/log" at "xmldb:exist:///db/apps/BetMasWeb/modules/log.xqm";
import module namespace exptit = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/exptit" at "xmldb:exist:///db/apps/BetMasWeb/modules/exptit.xqm";
import module namespace config = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/config" at "xmldb:exist:///db/apps/BetMasWeb/modules/config.xqm";
import module namespace switch2 = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/switch2" at "xmldb:exist:///db/apps/BetMasWeb/modules/switch2.xqm";

(:~
 : returns a json object with an array of object one for each resource in the specified collection
 :)
declare function apiL:collectionJSON($request as map(*)) {
	let $collection as xs:string* := $request?parameters?collection
	let $start as xs:integer* := $request?parameters?start
	let $perpage as xs:integer* := $request?parameters?perpage
	let $term as xs:string* := $request?parameters?term
	let $repo as xs:string* := $request?parameters?repo
	return let $log := log:add-log-message(
			"/api/" || $collection || "/list/json",
			sm:id()//sm:real/sm:username/string(),
			"REST"
		)
		(: logs into the collection :)
		let $login := xmldb:login($config:data-root, $config:ADMIN, $config:ppw)
		return (
			let $term := if ($term != "") then (
				"[descendant::t:term/@key eq '" || $term || "' ]"
			) else
				""
			let $repo := if ($repo != "") then (
				"[descendant::t:repository/@ref eq '" || $repo || "' ]"
			) else
				""
			let $collecPath := switch2:collection($collection)

			let $path := concat($collecPath, "//t:TEI", $repo, $term)

			let $hits := util:eval($path)

			return <json:value>
				<items>
					{
						for $resource in subsequence($hits, $start, $perpage)
						let $rid := $resource/@xml:id
						let $rids := string($rid)
						let $title := exptit:printTitleID($rid)
						order by $title[1] descending
						return <json:value json:array="true">
							<id>{ $rids }</id>
							<title>{ $title }</title>
							{
								element item {
									element uri { base-uri($resource) },
									element name { util:unescape-uri(replace(base-uri($resource), ".+/(.+)$", "$1"), "UTF-8") },
									element type { string($resource/@type) },
									switch ($resource/@type)
										case "mss" return
											(
												element support {
													for $r in $resource//@form
													return <json:value json:array="true"><value>{ string($r) }</value></json:value>
												},
												element institution {
													for $r in $resource//t:repository/@ref
													return <json:value json:array="true"><id>{ string($r) }</id></json:value>
												},
												element script {
													for $r in $resource//@script
													return <json:value json:array="true"><value>{ string($r) }</value></json:value>
												},
												element material {
													for $r in $resource//t:support/t:material/@key
													return <json:value json:array="true"><value>{ string($r) }</value></json:value>
												},
												element keyword {
													for $r in $resource//t:term/@key
													return <json:value json:array="true"><value>{ string($r) }</value></json:value>
												},
												element language {
													for $r in $resource//t:language
													return <json:value json:array="true"><value>{ string($r) }</value></json:value>
												},
												element content {
													for $r in $resource//t:title/@ref
													return <json:value json:array="true"><value>{ string($r) }</value></json:value>
												},
												element scribe {
													for $r in
														$resource//t:persName[@role eq "scribe"]/@ref[not(. eq "PRS00000") and not(. = "PRS0000")]
													return <json:value json:array="true"><id>{ string($r) }</id></json:value>
												},
												element donor {
													for $r in
														$resource//t:persName[@role eq "donor"]/@ref[not(. eq "PRS00000") and not(. eq "PRS0000")]
													return <json:value json:array="true"><id>{ string($r) }</id></json:value>
												},
												element patron {
													for $r in
														$resource//t:persName[@role eq "patron"]/@ref[not(. eq "PRS00000") and not(. eq "PRS0000")]
													return <json:value json:array="true"><id>{ string($r) }</id></json:value>
												}
											)
										case "pers" return
											(
												element occupation {
													for $r in $resource//t:occupation
													return replace(normalize-space($r), " ", "_") || " "
												},
												element role {
													for $r in $resource//t:person/t:persName/t:roleName
													return replace(normalize-space($r), " ", "_") || " "
												},
												element gender { $resource//t:person/@sex }
											)
										case "place" return
											(
												element placeType {
													for $r in $resource//t:place/@type
													return <json:value json:array="true"><id>{ string($r) }</id></json:value>
												},
												element tabot {
													for $r in $resource//t:ab[@type eq "tabot"]/t:persName/@ref
													return <json:value json:array="true"><id>{ string($r) }</id></json:value>
												}
											)
										case "ins" return
											(
												element placeType {
													for $r in $resource//t:place/@type
													return <json:value json:array="true"><id>{ string($r) }</id></json:value>
												},
												element tabot {
													for $r in $resource//t:ab[@type eq "tabot"]/t:persName/@ref
													return <json:value json:array="true"><value>{ string($r) }</value></json:value>
												}
											)
										case "work" return
											(
												element keyword {
													for $r in $resource//t:term/@key
													return <json:value json:array="true"><value>{ string($r) }</value></json:value>
												},
												element language {
													for $r in $resource//t:language
													return <json:value json:array="true"><value>{ string($r) }</value></json:value>
												},
												element author {
													for $r in
														(
															$resource//t:relation[@name eq "saws:isAttributedToAuthor"]/@passive,
															$resource//t:relation[@name eq "dcterms:creator"]/@passive
														)
													return <json:value json:array="true"><id>{ string($r) }</id></json:value>
												},
												element witness {
													for $r in $resource//t:witness/@corresp
													return <json:value json:array="true"><id>{ string($r) }</id></json:value>
												}
											)
										case "nar" return
											(
												element keyword {
													for $r in $resource//t:term/@key
													return <json:value json:array="true"><value>{ string($r) }</value></json:value>
												},
												element language {
													for $r in $resource//t:language
													return <json:value json:array="true"><value>{ string($r) }</value></json:value>
												},
												element author {
													for $r in
														(
															$resource//t:relation[@name eq "saws:isAttributedToAuthor"]/@passive,
															$resource//t:relation[@name eq "dcterms:creator"]/@passive
														)
													return <json:value json:array="true"><id>{ string($r) }</id></json:value>
												}
											)
										default return
											()
								}
							}
						</json:value>
					}
				</items>
				<total>{ count($hits) }</total>
			</json:value>
		)
};

(:~
 : returns a json object with an array of object one for each resource in the specified repository with id and title
 :)
declare function apiL:listRepoJSON($request as map(*)) {
	let $repo as xs:string* := $request?parameters?repo
	return let $log := log:add-log-message(
			"/api/manuscripts/" || $repo || "/list/ids/json",
			sm:id()//sm:real/sm:username/string(),
			"REST"
		)
		(: logs into the collection :)
		let $login := xmldb:login($config:data-root, $config:ADMIN, $config:ppw)
		return (
			let $msfromrepo := collection($config:data-rootMS)//t:TEI[descendant::t:repository[@ref eq $repo]]
			let $total := count($msfromrepo)
			let $items :=
				for $resource in $msfromrepo
				let $id := string($resource/@xml:id)
				let $title := exptit:printTitleID($id)
				return map {"id": $id, "title": $title}
			return map {"items": $items, "total": $total}
		)
};
