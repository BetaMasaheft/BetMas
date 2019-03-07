xquery version "3.1" encoding "UTF-8";
(:~
 : titles from API
 : 
 : @author Pietro Liuzzo <pietro.liuzzo@uni-hamburg.de'>
 :)
module namespace apiTit = "https://www.betamasaheft.uni-hamburg.de/BetMas/apiTitles";
import module namespace rest = "http://exquery.org/ns/restxq";
import module namespace api = "https://www.betamasaheft.uni-hamburg.de/BetMas/api"  at "xmldb:exist:///db/apps/BetMas/modules/rest.xqm";
import module namespace all="https://www.betamasaheft.uni-hamburg.de/BetMas/all" at "xmldb:exist:///db/apps/BetMas/modules/all.xqm";
import module namespace log="http://www.betamasaheft.eu/log" at "xmldb:exist:///db/apps/BetMas/modules/log.xqm";
import module namespace titles="https://www.betamasaheft.uni-hamburg.de/BetMas/titles" at "xmldb:exist:///db/apps/BetMas/modules/titles.xqm";
import module namespace config = "https://www.betamasaheft.uni-hamburg.de/BetMas/config" at "xmldb:exist:///db/apps/BetMas/modules/config.xqm";
(: namespaces of data used :)
declare namespace t = "http://www.tei-c.org/ns/1.0";
import module namespace http="http://expath.org/ns/http-client";

declare namespace test="http://exist-db.org/xquery/xqsuite";

(: For REST annotations :)
declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";



(:~ given the file id, returns the main title:)
declare
%rest:GET
%rest:path("/BetMas/api/{$id}/title")
%output:method("text")
%test:arg('id','LIT1367Exodus') %test:assertEquals('<rest:response><http:response status="200"><http:header name="Access-Control-Allow-Origin" value="*" /></http:response></rest:response>',"Exodus")
function apiTit:get-FormattedTitle($id as xs:string) {
    ($api:response200,
   normalize-space(titles:printTitleMainID($id))
    
    )
};


(:~ given the file id and an anchor, returns the formatted main title and the title of the reffered section:)
declare
%rest:GET
%rest:path("/BetMas/api/{$id}/{$SUBid}/title")
%output:method("text")
%test:args('BNFet32','a1') %test:assertEquals('<rest:response><http:response status="200"><http:header name="Access-Control-Allow-Origin" value="*" /></http:response></rest:response>',"Paris, Bibliothèque nationale de France, Éthiopien 32, Scribal Note Completing a1")
function apiTit:get-FormattedTitleandID($id as xs:string, $SUBid as xs:string) {
    ($api:response200, 
    let $resource := api:get-tei-rec-by-ID($id)
    let $m := titles:printTitleMainID($id) 
    return
    if( starts-with($SUBid, 'tr')) then $m || ', transformation ' ||  $SUBid
else if( starts-with($SUBid, 'Uni')) then $m ||', '||$SUBid 
else
    (:    if pointing to a specific label, print that:)
    if (starts-with($SUBid, 't'))
    then
        (
        let $subtitlemain := $resource//t:title[contains(@corresp, $SUBid)][@type = 'main']
        let $subtitlenorm := $resource//t:title[contains(@corresp, $SUBid)][@type = 'normalized']
        return
            if ($subtitlemain)
            then
                $subtitlemain
            else
                if ($subtitlenorm)
                then
                    $subtitlenorm
                else
                    let $tit := $resource//t:title[@xml:id = $SUBid]
                    return $tit/text()
                    )
    else
    let $s := titles:printSubtitle($resource, $SUBid)
    return
        (:    apply general rules for titles of records:)
        ($m, ', ', $s)
    )
};
