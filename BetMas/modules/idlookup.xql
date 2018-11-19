xquery version "3.1" encoding "UTF-8";
(:~
 : returns entities which share a same keyword
 : 
 : @author Pietro Liuzzo <pietro.liuzzo@uni-hamburg.de'>
 :)
module namespace lookID = "https://www.betamasaheft.uni-hamburg.de/BetMas/lookID";
import module namespace rest = "http://exquery.org/ns/restxq";
import module namespace switch = "https://www.betamasaheft.uni-hamburg.de/BetMas/switch"  at "xmldb:exist:///db/apps/BetMas/modules/switch.xqm";
import module namespace log="http://www.betamasaheft.eu/log" at "xmldb:exist:///db/apps/BetMas/modules/log.xqm";
import module namespace titles="https://www.betamasaheft.uni-hamburg.de/BetMas/titles" at "xmldb:exist:///db/apps/BetMas/modules/titles.xqm";
import module namespace config = "https://www.betamasaheft.uni-hamburg.de/BetMas/config" at "xmldb:exist:///db/apps/BetMas/modules/config.xqm";

(: namespaces of data used :)

declare namespace t = "http://www.tei-c.org/ns/1.0";

import module namespace http="http://expath.org/ns/http-client";

(: For REST annotations :)
declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace json = "http://www.json.org";

declare namespace test="http://exist-db.org/xquery/xqsuite";
(:~ searches the content of the ids and returns a JSON object containing an array of objects with possible matches. id here can be a full id or any part of it. :)
declare 
%rest:GET
%rest:path("/BetMas/api/idlookup")
%rest:query-param("id", "{$id}", "")
%output:method("json")
%test:arg('id', 'dsapdsjapo') %test:assertEquals('<rest:response xmlns:rest="http://exquery.org/ns/restxq"><http:response xmlns:http="http://expath.org/ns/http-client" status="200"><http:header name="Content-Type" value="application/json; charset=utf-8"/><http:header name="Access-Control-Allow-Origin" value="*"/></http:response></rest:response>','<json:value xmlns:json="http://www.json.org"><json:value json:array="true"><info>No results, sorry</info></json:value></json:value>')
function lookID:IDSlookup($id as xs:string*) {
log:add-log-message('/api/idlookup?id=' || $id, xmldb:get-current-user(), 'REST'),

let $query := (
collection($config:data-root)/t:TEI[contains(@xml:id, $id)],
collection($config:data-root)//t:msPart[contains(@xml:id, $id)],
collection($config:data-root)//t:msItem[contains(@xml:id, $id)],
collection($config:data-root)//t:title[contains(@xml:id, $id)],
collection($config:data-root)//t:div[contains(@xml:id, $id)])
 let $results := for $hit in $query
 let $i := string($hit/@xml:id)
(: let $rootID := string(root($hit)/t:TEI/@xml:id):)
(: let $title := if ($i = $rootID) then titles:printTitleID($i) else api:printSubtitle(root($hit),$i):)
        return
        map {'id' := $i}
     
let $c := count($query)
return
    if (count($query) gt 0) then
        ($config:response200Json,
        map {
            'items' : $results,
           'total' : $c
        })
    else
        ($config:response200Json,
        <json:value>
            <json:value
                json:array="true">
                <info>No results, sorry</info>
            </json:value>
        </json:value>)

};
