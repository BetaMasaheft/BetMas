xquery version "3.1";
 
(: Utility file used for the static institutions list :)
declare namespace t="http://www.tei-c.org/ns/1.0";
declare namespace http = "http://expath.org/ns/http-client";

import module namespace titles="https://www.betamasaheft.uni-hamburg.de/BetMas/titles" at "xmldb:exist:///db/apps/BetMas/modules/titles.xqm";
import module namespace config = "https://www.betamasaheft.uni-hamburg.de/BetMas/config" at "xmldb:exist:///db/apps/BetMas/modules/config.xqm";

let $cats := $config:collection-rootMS//t:listBibl[@type='catalogue']
   for $catalogue in distinct-values($cats//t:ptr/@target)
   let $zoTag := substring-after($catalogue, 'bm:')
   let $count := count($cats//t:ptr[@target=$catalogue])
	let $xml-url := concat('https://api.zotero.org/groups/358366/items?&amp;tag=', $catalogue, '&amp;format=bib&amp;locale=en-GB&amp;style=hiob-ludolf-centre-for-ethiopian-studies')
let $request := <http:request href="{xs:anyURI($xml-url)}" method="GET"/>
let $data := http:send-request($request)
order by $data
return
<item xml:id="{replace($catalogue, ':','_')}">
{$data//div[@class="csl-bib-body"]/div/node()}
</item>