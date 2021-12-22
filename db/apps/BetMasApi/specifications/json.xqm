xquery version "3.1" encoding "UTF-8";
(: 
implementation of 
https://jsonapi.org/format/ 
for 
https://github.com/BetaMasaheft/Documentation/issues/1109
:)
module namespace jsonapi="https://www.betamasaheft.uni-hamburg.de/BetMas/jsonapi";

declare namespace output="http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace t="http://www.tei-c.org/ns/1.0";
declare namespace exist = "http://exist.sourceforge.net/NS/exist";
declare namespace s = "http://www.w3.org/2005/xpath-functions";
declare namespace http = "http://expath.org/ns/http-client";
declare namespace json = "http://www.json.org";
declare namespace cx ="http://interedition.eu/collatex/ns/1.0";
declare namespace sr="http://www.w3.org/2005/sparql-results#";
declare namespace test="http://exist-db.org/xquery/xqsuite";

import module namespace functx="http://www.functx.com";
import module namespace rest = "http://exquery.org/ns/restxq";
import module namespace log="http://www.betamasaheft.eu/log" at "xmldb:exist:///db/apps/BetMasWeb/modules/log.xqm";
import module namespace exptit="https://www.betamasaheft.uni-hamburg.de/BetMasWeb/exptit" at "xmldb:exist:///db/apps/BetMasWeb/modules/exptit.xqm";
import module namespace config="https://www.betamasaheft.uni-hamburg.de/BetMasWeb/config" at "xmldb:exist:///db/apps/BetMasWeb/modules/config.xqm";
import module namespace sparql="http://exist-db.org/xquery/sparql" at "java:org.exist.xquery.modules.rdf.SparqlModule";
import module namespace switch2 = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/switch2" at "xmldb:exist:///db/apps/BetMasWeb/modules/switch2.xqm";
import module namespace editors = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/editors" at "xmldb:exist:///db/apps/BetMasWeb/modules/editors.xqm";
import module namespace what = "https://www.betamasaheft.uni-hamburg.de/BetMasApi/what" at "xmldb:exist:///db/apps/BetMasApi/local/whatpointshere.xqm";

declare variable $jsonapi:response200Json := <rest:response>
            <http:response
                status="200">
                <http:header
                    name="Content-Type"
                    value="application/vnd.api+json; charset=utf-8"/>
                <http:header
                    name="Access-Control-Allow-Origin"
                    value="*"
                    />
            </http:response>
        </rest:response>;
        
declare
%rest:GET
%rest:path("/json/api/{$id}")
%output:method("json")
function jsonapi:maintest($id as xs:string+) {
let $type := switch2:switchPrefix($id)
let $file := $exptit:col//id($id)
let $title := exptit:printTitleID($id)
let $auths := ($file//t:editor/@key , $file//t:change/@who)
let $authors := for $a in distinct-values($auths) return editors:editorKey($a)
let $funder := normalize-space($file//t:funder/node())
let $publisher:= normalize-space($file//t:publisher/node())
let $authority:= normalize-space($file//t:authority/node())
let $availability := normalize-space(string-join($file//t:availability//text()))
let $langs := for $language in $file//t:language/@ident return string($language)
let $ptrs := ($file//t:*/@ref, $file//t:*/@passive)
let $pointers := for $p in distinct-values($ptrs) let $t := switch2:switchPrefix($p) return map { "type": $t, "id": string($p) }
let $pointhere := let $attestations:= what:PointsHere($id, $exptit:col)
                                for $att in $attestations
                                let $rootID := string(root($att)/t:TEI/@xml:id) 
                                group by $MAINID := $rootID
                                return
                                    if($MAINID = $id) then () else map { "type": switch2:switchPrefix($MAINID), "id": $MAINID }
let $keywords := for $k in $file//t:term/@key return map { "type": "auth", "id": string($k) }
return
(
 $jsonapi:response200Json,
  map {
  "jsonapi" : map{"version": "1.0", 
                            "description": 'test implementation of spec https://jsonapi.org/format/ '},
"meta": map {
    "copyright": $availability,
    "funder" : $funder,
    "publisher" : $publisher,
    "authority" : $authority,
    "authors": $authors,
    "sources" : map{'TEI': 'https://betamasaheft.eu/'||$id||'.xml',
                                  'TEIserializedJSON' : 'https://betamasaheft.eu/api/'||$id||'/json',
                                  'VoID': 'https://betamasaheft.eu/api/void/' || $id}
  },
"data" : [map {
    "type": $type,
    "id": $id,
    "attributes": map {
      "title": $title,
      "languages" : ($langs, 'en')
    },
    "relationships": map {
      "pointers": map {
        "data": $pointers
      },
      "pointhere": map {
        "data": $pointhere
      },
      "keywords": map {
        "data": $keywords
      }
    }
  }]
}    
)
};
