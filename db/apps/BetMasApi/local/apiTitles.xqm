xquery version "3.1" encoding "UTF-8";
(:~
 : titles from API
 : 
 : @author Pietro Liuzzo 
 :)
 
module namespace apiTit = "https://www.betamasaheft.uni-hamburg.de/BetMas/apiTitles";
import module namespace rest = "http://exquery.org/ns/restxq";
import module namespace api = "https://www.betamasaheft.uni-hamburg.de/BetMasApi/api"  at "xmldb:exist:///db/apps/BetMasApi/local/rest.xqm";
import module namespace all="https://www.betamasaheft.uni-hamburg.de/BetMasWeb/all" at "xmldb:exist:///db/apps/BetMasWeb/modules/all.xqm";
import module namespace log="http://www.betamasaheft.eu/log" at "xmldb:exist:///db/apps/BetMasWeb/modules/log.xqm";
import module namespace exptit="https://www.betamasaheft.uni-hamburg.de/BetMasWeb/exptit" at "xmldb:exist:///db/apps/BetMasWeb/modules/exptit.xqm";
import module namespace config = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/config" at "xmldb:exist:///db/apps/BetMasWeb/modules/config.xqm";
(: namespaces of data used :)
declare namespace t = "http://www.tei-c.org/ns/1.0";
import module namespace http="http://expath.org/ns/http-client";

declare namespace test="http://exist-db.org/xquery/xqsuite";

(: For REST annotations :)
declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";

declare variable $apiTit:TUList := doc(concat($config:app-root, '/lists/textpartstitles.xml'));

(:~ given the file id, returns the main title:)
declare
%rest:GET
%rest:path("/api/{$id}/title")
%output:method("text")
function apiTit:get-FormattedTitle($id as xs:string) {
    ($config:response200,
    let $id := replace($id, '_', ':') 
    
    return
    if (not(contains($id, ':'))) then
   normalize-space(string-join(exptit:printTitleID($id)))
   else if (starts-with($id, 'wd:') or starts-with($id, 'pleaides:') or starts-with($id, 'sdc:') or starts-with($id, 'gn:')   )
   then
   normalize-space(exptit:printTitleID($id))
    else $id
    )
};


(:~ given the file id, returns the main title:)
declare
%rest:GET
%rest:path("/api/{$id}/title/json")
%output:method("json")
function apiTit:get-FormattedTitleJson($id as xs:string) {
    ($config:response200Json,
    let $id := replace($id, '_', ':') 
   let $titletext :=  if (not(contains($id, ':'))) then
normalize-space(string-join(exptit:printTitleID($id))) 
   else if (starts-with($id, 'wd:') or starts-with($id, 'pleaides:') or starts-with($id, 'sdc:') or starts-with($id, 'gn:')   )
   then
   normalize-space(exptit:printTitleID($id))
    else $id
    
    return map {'title':$titletext}
    )
};

(:~ given the file id and an anchor, returns the formatted main title and the title of the reffered section:)
declare
%rest:GET
%rest:path("/api/{$id}/{$SUBid}/title")
%output:method("text")
function apiTit:get-FormattedTitleandID($id as xs:string, $SUBid as xs:string) {
    ($config:response200, 
    let $fullid := ($id||'#'||$SUBid)
    return
    if ($apiTit:TUList//t:item[@corresp eq $fullid]) then ($apiTit:TUList//t:item[@corresp eq $fullid]/node()) else (
    exptit:printTitleID($fullid)    
    )
    )
};
