xquery version "3.1" encoding "UTF-8";

(:~
 : texts from API
 :
 : @author Pietro Liuzzo
 :)
module namespace apiT = "https://www.betamasaheft.uni-hamburg.de/BetMasApi/apiTexts";

(: namespaces of data used :)
declare namespace t = "http://www.tei-c.org/ns/1.0";
declare namespace test = "http://exist-db.org/xquery/xqsuite";
(: For REST annotations :)
declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";

import module namespace api = "https://www.betamasaheft.uni-hamburg.de/BetMasApi/api" at "./rest.xqm";
import module namespace log = "http://www.betamasaheft.eu/log" at "xmldb:exist:///db/apps/BetMasWeb/modules/log.xqm";
import module namespace config = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/config" at "xmldb:exist:///db/apps/BetMasWeb/modules/config.xqm";

(: ~ returns the full first level subdivision

e.g. Ex. 1

 :)
declare %test:args("LIT1367Exodus", "1") %test:assertXPath("//partofwork") function apiT:get-level1XML(
	$request as map(*)
) {
	let $id as xs:string := $request?parameters?id
	let $level1 as xs:string* := $request?parameters?level1
	return (
		let $log := log:add-log-message("/api/xml/" || $id || "/" || $level1, sm:id()//sm:real/sm:username/string(), "REST")
		let $collection := "works"
		let $item := api:get-tei-rec-by-ID($id)
		let $recordid := $item/@xml:id

		return if ($item//t:div[@type = "edition"]/t:div[@n eq $level1][t:ab]) then
			<work>
				<id>{ data($recordid) }</id>
				<citation>{ (api:citation($item) || " " || $level1) }</citation>
				<title>{ $item//t:titleStmt/t:title[@xml:id eq "t1"]/text() }</title>
				<text>{ $item//t:div[@type = "edition"]/t:div[@n eq $level1]//text() }</text>
				{
					if (number($level1) > 1) then
						<previous>{ $config:appUrl }/api/xml/{ $id }/{ number($level1) - 1 }</previous>
					else (
					)
				}
				{
					if (number($level1) = count($item//t:div[@type eq "edition"]/t:div)) then (
					) else if ($item//t:div[@type eq "edition"]/t:div[@n = (number($level1) + 1)]) then
						<next>{ $config:appUrl }/api/xml/{ $id }/{ number($level1) + 1 }</next>
					else (
					)
				}
				<partofwork>{ $config:appUrl }/api/xml/{ $id }</partofwork>
				<contains>
					{
						for $subtype in $item//t:div[@type eq "edition"]/t:div[@subtype]
						return element {string($subtype/@subtype)} { ($config:appUrl || "/api/xml/" || $id || "/" || $subtype/@n) }
					}
				</contains>
			</work>
		else
			let $call := $config:appUrl || "/api/xml/" || $id || "/" || $level1
			return api:noresults($call)
	)
};

(:~
 : returns the lines of the first level subdivision
 :
 : Ex. 2,4
 :
 : Ex. 2, 4-7
 :
 :)
declare %test:args("LIT1367Exodus", "1", "1-2") %test:assertXPath("//partOf") function apiT:get-level1LineXML(
	$request as map(*)
) {
	let $id as xs:string := $request?parameters?id
	let $level1 as xs:string* := $request?parameters?level1
	let $line as xs:string* := $request?parameters?line
	return (
		let $log := log:add-log-message(
			"/api/xml/" || $id || "/" || $level1 || "/" || $line,
			sm:id()//sm:real/sm:username/string(),
			"REST"
		)
		let $collection := "works"
		let $item := api:get-tei-rec-by-ID($id)

		let $recordid := $item/@xml:id
		let $L1 := $item//t:div[@type eq "edition"]/t:div[@n eq $level1]
		return if (contains($line, "-")) then
			<work>
				<id>{ data($recordid) }</id>
				<citation>{ (api:citation($item) || " " || $level1 || ", " || $line) }</citation>
				<title>{ $item//t:titleStmt/t:title[@xml:id eq "t1"]/text() }</title>
				<text>
					{
						for $l in (xs:integer(substring-before($line, "-")) to xs:integer(substring-after($line, "-")))
						let $textnodes := $L1//t:l[@n eq string($l)]
						let $onlytext := string-join($textnodes//text(), "")
						return normalize-space($onlytext)
					}
				</text>
				{
					if (number(substring-before($line, "-")) > 1) then
						<previous>
							{ $config:appUrl }/api/xml/{ $id }/{ $level1 }/{ number(substring-before($line, "-")) - 1 }
						</previous>
					else (
					)
				}
				{
					if (number($line) = count($L1//t:l[@n eq substring-after($line, "-")])) then (
					) else if ($L1//t:l[@n = (number(substring-after($line, "-")) + 1)]) then
						<next>{ $config:appUrl }/api/xml/{ $id }/{ $level1 }/{ number(substring-after($line, "-")) + 1 }</next>
					else (
					)
				}
				<partOf>
					{ element {string($L1/@subtype)} { $config:appUrl || "/api/xml/" || $id || "/" || $level1 } }
					{ element {"work"} { $config:appUrl || "/api/xml/" || $id } }
				</partOf>
				<contains>
					{
						for $subtype in $L1/t:div[@subtype]
						return element {string($subtype/@subtype)} { ($config:appUrl || "/api/xml/" || $id || "/" || $subtype/@n) }
					}
				</contains>
			</work>
		else if ($L1//t:l[@n eq $line]) then
			<work>
				<id>{ data($recordid) }</id>
				<citation>{ (api:citation($item) || " " || $level1 || ", " || $line) }</citation>
				<title>{ $item//t:titleStmt/t:title[@xml:id eq "t1"]/text() }</title>
				<text>
					{
						let $textnodes := $L1//t:l[@n eq $line]//text()
						let $onlytext := string-join($textnodes, "")
						return normalize-space($onlytext)
					}
				</text>
				{
					if (number($line) > 1) then
						<previous>{ $config:appUrl }/api/xml/{ $id }/{ $level1 }/{ number($line) - 1 }</previous>
					else (
					)
				}
				{
					if (number($line) = count($L1//t:l[@n eq $line])) then (
					) else if ($L1//t:l[@n = (number($line) + 1)]) then
						<next>{ $config:appUrl }/api/xml/{ $id }/{ $level1 }/{ number($line) + 1 }</next>
					else (
					)
				}
				<partOf>
					{ element {string($L1/@subtype)} { $config:appUrl || "/api/xml/" || $id || "/" || $level1 } }
					{ element {"work"} { $config:appUrl || "/api/xml/" || $id } }
				</partOf>
				<contains>
					{
						for $subtype in $L1/t:div[@subtype]
						return element {string($subtype/@subtype)} { ($config:appUrl || "/api/xml/" || $id || "/" || $subtype/@n) }
					}
				</contains>
			</work>
		else
			let $call := $config:appUrl || "/api/xml/" || $id || "/" || $level1 || "/" || $line
			return api:noresults($call)
	)
};

(:~
 : returns the lines of the second level of subdivision (subchapters)
 :
 : XXX. 1 2,4
 :
 : XXX. 1 2, 4-7
 :
 :)

declare function apiT:get-level2lineXML($request as map(*)) {
	let $id as xs:string := $request?parameters?id
	let $level1 as xs:string* := $request?parameters?level1
	let $level2 as xs:string* := $request?parameters?level2
	let $line as xs:string* := $request?parameters?line
	return (
		let $log := log:add-log-message(
			"/api/xml/" || $id || "/" || $level1 || "/" || $level2 || "/" || $line,
			sm:id()//sm:real/sm:username/string(),
			"REST"
		)

		let $collection := "works"
		let $item := api:get-tei-rec-by-ID($id)
		let $recordid := $item/@xml:id
		let $L1 := $item//t:div[@type eq "edition"]/t:div[@n eq $level1]
		let $L2 := $L1/t:div[@n eq $level2]

		return if (contains($line, "-")) then
			<work>
				<id>{ data($recordid) }</id>
				<citation>{ (api:citation($item) || " " || $level2 || ", " || $line) }</citation>
				<title>{ $item//t:titleStmt/t:title[@xml:id eq "t1"]/text() }</title>
				<text>
					{
						for $l in (xs:integer(substring-before($line, "-")) to xs:integer(substring-after($line, "-")))
						let $textnodes := $L2//t:l[@n eq string($l)]
						let $onlytext := string-join($textnodes//text(), "")
						return normalize-space($onlytext)
					}
				</text>
				{
					if (number(substring-before($line, "-")) > 1) then
						<previous>
							{ $config:appUrl }/api/xml/{ $id }/{ $level1 }/{ $level2 }/{ number(substring-before($line, "-")) - 1 }
						</previous>
					else (
					)
				}
				{
					if (number($line) = count($L2//t:l[@n eq substring-after($line, "-")])) then (
					) else if ($L2//t:l[@n = (number(substring-after($line, "-")) + 1)]) then
						<next>
							{ $config:appUrl }/api/xml/{ $id }/{ $level1 }/{ $level2 }/{ number(substring-after($line, "-")) + 1 }
						</next>
					else (
					)
				}
				<partOf>
					{
						element {string($L2/@subtype)} { $config:appUrl || "/api/xml/" || $id || "/" || $level1 || "/" || $level2 }
					}
					{ element {string($L1/@subtype)} { $config:appUrl || "/api/xml/" || $id || "/" || $level1 } }
					{ element {"work"} { $config:appUrl || "/api/xml/" || $id } }
				</partOf>
				<contains>
					{
						for $subtype in $L2/t:div[@subtype]
						return element {string($subtype/@subtype)} { ($config:appUrl || "/api/xml/" || $id || "/" || $subtype/@n) }
					}
				</contains>
			</work>
		else if ($item//t:div[@type eq "edition"]/t:div[@n eq $level1]/t:div[@n eq $level2]//t:*[@n eq $line]) then
			<work>
				<id>{ data($recordid) }</id>
				<citation>{ (api:citation($item) || " " || $level1 || " " || $level2 || ", " || $line) }</citation>
				<title>{ $item//t:titleStmt/t:title[@xml:id eq "t1"]/text() }</title>
				<text>
					{
						let $textnodes := $L2//t:l[@n eq $line]//text()
						let $onlytext := string-join($textnodes, "")
						return normalize-space($onlytext)
					}
				</text>
				{
					if (number($line) > 1) then
						<previous>{ $config:appUrl }/api/xml/{ $id }/{ $level1 }/{ $level2 }/{ number($line) - 1 }</previous>
					else (
					)
				}
				{
					if (number($line) = count($L2//t:l[@n eq $line])) then (
					) else if ($L2//t:l[@n = (number($line) + 1)]) then
						<next>{ $config:appUrl }/api/xml/{ $id }/{ $level1 }/{ $level2 }/{ number($line) + 1 }</next>
					else (
					)
				}
				<partOf>
					{
						element {string($L2/@subtype)} { $config:appUrl || "/api/xml/" || $id || "/" || $level1 || "/" || $level2 }
					}
					{ element {string($L1/@subtype)} { $config:appUrl || "/api/xml/" || $id || "/" || $level1 } }
					{ element {"work"} { $config:appUrl || "/api/xml/" || $id } }
				</partOf>
				<contains>
					{
						for $subtype in $L2/t:div[@subtype]
						return element {string($subtype/@subtype)} { ($config:appUrl || "/api/xml/" || $id || "/" || $subtype/@n) }
					}
				</contains>
			</work>
		else
			let $call := $config:appUrl || "/api/xml/" || $id || "/" || $level1 || "/" || $level2 || "/" || $line
			return api:noresults($call)
	)
};
