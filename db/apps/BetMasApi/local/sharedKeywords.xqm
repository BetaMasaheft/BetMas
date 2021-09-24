xquery version "3.1" encoding "UTF-8";
(:~
 : returns entities which share a same keyword
 : 
 : @author Pietro Liuzzo 
 :)
module namespace SK = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/SK";
import module namespace rest = "http://exquery.org/ns/restxq";
import module namespace switch2 = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/switch2"  at "xmldb:exist:///db/apps/BetMasWeb/modules/switch2.xqm";
import module namespace log="http://www.betamasaheft.eu/log" at "xmldb:exist:///db/apps/BetMasWeb/modules/log.xqm";
import module namespace exptit="https://www.betamasaheft.uni-hamburg.de/BetMasWeb/exptit" at "xmldb:exist:///db/apps/BetMasWeb/modules/exptit.xqm";
import module namespace config = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/config" at "xmldb:exist:///db/apps/BetMasWeb/modules/config.xqm";

(: namespaces of data used :)

declare namespace t = "http://www.tei-c.org/ns/1.0";

import module namespace http="http://expath.org/ns/http-client";

(: For REST annotations :)
declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace json = "http://www.json.org";


(:~gets an array of objects in JSON, containing the id and title of resources in the db which have the same keywords or value for a typed element. :)
declare
%rest:GET
%rest:path("/api/sharedKeyword/{$keyword}")
%rest:query-param("element", "{$element}", "persName")
%output:method("json")
function SK:SharedKeyword(
$keyword as xs:string*, $element as xs:string*) {
let $log := log:add-log-message('/api/sharedKeyword/'||$keyword, sm:id()//sm:real/sm:username/string() , 'REST')

let $attr := switch($element) 
                            case 'persName' return 'ref' 
                            case 'keywords' return 'key'
                            case 'material' return 'key'
                            case 'script' return 'script'
                            case 'form' return 'form'
                            case 'attributed author' return 'active'
                            case 'author' return 'passive'
                            case 'settlement' return 'ref'
                            case 'region' return 'ref'
                            case 'country' return 'ref'
                            case 'type' return 'type'
                            case 'role' return 'type'
                            case 'faith' return 'type'
                            case 'occupation' return 'type'
                            default return 'ref'
let $elementName := switch($element) 
                             case 'persName' return 'persName' 
                            case 'keywords' return 'term'
                            case 'material' return 'supportDesc/t:material'
                            case 'script' return 'handNote'
                            case 'form' return 'objectDesc'
                            case 'attributed author' return 'relation'
                            case 'author' return 'relation'
                            case 'settlement' return 'settlement'
                            case 'region' return 'region'
                            case 'country' return 'country'
                            case 'type' return 'place'
                            case 'role' return 'roleName'
                            case 'faith' return 'faith'
                            case 'occupation' return 'occupation'
                            default return 'persName'
let $buildQuery := '$exptit:col//t:TEI[descendant::t:' || $elementName ||'[@' || $attr || " eq '" || $keyword || "']]"
let $query :=  util:eval($buildQuery)
let $total := count($query)
let $hits := for $hit in $query
                let $id := string($hit/@xml:id)
                let $title := try{exptit:printTitleID($id)} catch * {('no title for ' || $id)}
               
          return
            map {
                'id' : $id,
                'title' : $title
                    }

return 
($config:response200Json,
map {
'hits' : $hits,
'total' : $total
})
};
