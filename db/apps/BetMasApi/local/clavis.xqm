xquery version "3.1" encoding "UTF-8";
(:~
 : clavis matching related funtions.
 : 
 : @author Pietro Liuzzo 
 :)
module namespace clavis = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/clavis";
import module namespace rest = "http://exquery.org/ns/restxq";
import module namespace switch2 = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/switch2"  at "xmldb:exist:///db/apps/BetMasWeb/modules/switch2.xqm";
import module namespace log="http://www.betamasaheft.eu/log" at "xmldb:exist:///db/apps/BetMasWeb/modules/log.xqm";
import module namespace exptit="https://www.betamasaheft.uni-hamburg.de/BetMasWeb/exptit" at "xmldb:exist:///db/apps/BetMasWeb/modules/exptit.xqm";
import module namespace config = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/config" at "xmldb:exist:///db/apps/BetMasWeb/modules/config.xqm";
import module namespace http="http://expath.org/ns/http-client";

(: namespaces of data used :)

declare namespace t = "http://www.tei-c.org/ns/1.0";

declare namespace test="http://exist-db.org/xquery/xqsuite";

(: For REST annotations :)
declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace json = "http://www.json.org";



(:~ returns a JSON object with the aligned known clavis ids :)
declare
%rest:GET
%rest:path("/api/clavis/{$id}")
%output:method("json")
function clavis:ClavisbyID($id as xs:string*) {

(:results from PAThs
results from BM interroga bibl con id clavis e titolo.
se interrogato da titolo da gli id, altrimenti per id da gli altri id e il titolo

:)

    let $log := log:add-log-message('/api/clavis/' || $id , sm:id()//sm:real/sm:username/string() , 'REST')
                    let $root := $exptit:col//id($id)[self::t:TEI]
                    let $id := string($root/@xml:id)
                    let $title := exptit:printTitleID($id)
                    let $clavisBibl := $root//t:listBibl[@type eq 'clavis']
                    let $CC := $clavisBibl/t:bibl[@type eq 'CC']/t:citedRange/text()
                    let $CPG := $clavisBibl/t:bibl[@type eq 'CPG']/t:citedRange/text()
                    let $CANT := $clavisBibl/t:bibl[@type eq 'CANT']/t:citedRange/text()
                    let $CAVT := $clavisBibl/t:bibl[@type eq 'CAVT']/t:citedRange/text()
                    let $BHO := $clavisBibl/t:bibl[@type eq 'BHO']/t:citedRange/text()
                    let $BHL := $clavisBibl/t:bibl[@type eq 'BHL']/t:citedRange/text()
                    let $syriaca := $clavisBibl/t:bibl[@type eq 'syriaca']/t:citedRange/text()
                    let $clavisIDS := map {
                    "CC":  $CC,
                    "CPG":  $CPG,
                    "CANT":  $CANT,
                    "CAVT":  $CAVT,
                    "BHO":  $BHO,
                    "BHL":  $BHL,
                    "syriaca":  $syriaca
                    }
                    
                    return
                        ( $config:response200Json,
                        map {
                            "CAe" : $id,
                            "title" : $title,
                            "clavis" : $clavisIDS                
                        })
                        
};


(:~ returns a JSON object with the aligned known clavis ids :)
declare
%rest:GET
%rest:path("/api/clavis/all")
%rest:query-param("type", "{$type}", "")
%output:method("json")
function clavis:ClavisALL($id as xs:string*, $type as xs:string*) {

(:results from PAThs
results from BM interroga bibl con id clavis e titolo.
se interrogato da titolo da gli id, altrimenti per id da gli altri id e il titolo

:)
(:
    let $log := log:add-log-message('/api/clavis/' || $id , sm:id()//sm:real/sm:username/string() , 'REST')
               :)  
               let $bibl := if ($type != '') then "[t:bibl[@type = '" ||$type||"']]" else ()
               let $path := util:eval("$exptit:col//t:listBibl[@type eq 'clavis']" || $bibl)
              let $results := for $work in $path
                    let $root := root($work)
                    let $id := string($root/t:TEI/@xml:id)
                    let $title := exptit:printTitleID($id)
                    let $CC := $work/t:bibl[@type eq 'CC']/t:citedRange/text()
                    let $CPG := $work/t:bibl[@type eq 'CPG']/t:citedRange/text()
                    let $CANT := $work/t:bibl[@type eq 'CANT']/t:citedRange/text()
                    let $CAVT := $work/t:bibl[@type eq 'CAVT']/t:citedRange/text()
                    let $BHO := $work/t:bibl[@type eq 'BHO']/t:citedRange/text()
                    let $BHL := $work/t:bibl[@type eq 'BHL']/t:citedRange/text()
                    let $syriaca := $work/t:bibl[@type eq 'syriaca']/t:citedRange/text()
                    let $clavisIDS := map {
                    "CC":  $CC,
                    "CPG":  $CPG,
                    "CANT":  $CANT,
                    "CAVT":  $CAVT,
                    "BHO":  $BHO,
                    "BHL":  $BHL,
                    "syriaca":  $syriaca
                    }
                    
                    return
                        map {
                            "CAe" : $id,
                            "CAeN" : substring($id, 4,4),
                            "CAeURL" : 'https://betamasaheft.eu/works/' || $id || '/main',
                            "title" : $title,
                            "clavis" : $clavisIDS                
                        }
                        
                        return
                         ( $config:response200Json,
                          map {'results' : $results, 'total' : count($results)}
                         )
                       
};


(:results from PAThs
results from BM interroga bibl con id clavis e titolo.
se interrogato da titolo da gli id, altrimenti per id da gli altri id e il titolo

:) 
declare
%rest:GET
%rest:path("/api/clavis")
%rest:query-param("q", "{$q}", "")
%output:method("json")
function clavis:Clavis($q as xs:string*) {

let $eval-string := concat("collection($config:data-rootW)//t:title",
"[ft:query(.,'", $q, "')]")

let $log := log:add-log-message('/api/clavis?q=' || $q, sm:id()//sm:real/sm:username/string() , 'REST')
let $hits := util:eval($eval-string)
let $hi :=   for $hit in $hits
                    let $root := root($hit)
                    let $id := string($root//t:TEI/@xml:id)
                    group by $id := $id
                    let $title := exptit:printTitleID($id)
                    let $hitCount := count($hit)
                    let $clavisBibl := $root//t:listBibl[@type eq 'clavis']
                    let $CC := $clavisBibl/t:bibl[@type eq 'CC']/t:citedRange/text()
                    let $CPG := $clavisBibl/t:bibl[@type eq 'CPG']/t:citedRange/text()
                    let $CANT := $clavisBibl/t:bibl[@type eq 'CANT']/t:citedRange/text()
                    let $CAVT := $clavisBibl/t:bibl[@type eq 'CAVT']/t:citedRange/text()
                    let $BHO := $clavisBibl/t:bibl[@type eq 'BHO']/t:citedRange/text()
                    let $BHL := $clavisBibl/t:bibl[@type eq 'BHL']/t:citedRange/text()
                    let $syriaca := $clavisBibl/t:bibl[@type eq 'syriaca']/t:citedRange/text()
                    let $clavisIDS := map {
                    "CC":  $CC,
                    "CPG":  $CPG,
                    "CANT":  $CANT,
                    "CAVT":  $CAVT,
                    "BHO":  $BHO,
                    "BHL":  $BHL,
                    "syriaca":  $syriaca
                    }
                    
                    return
                        map {
                            "CAe" : $id,
                            "title" : $title,
                            "clavis" : $clavisIDS,
                            "hits" : $hitCount                    
                        }
let $c := count($hits)
return
    if (count($hits) gt 0) then
         ( $config:response200Json,
       map {
            "items" : $hi,
            "totalhits": $c
        
        })
    else
         ( $config:response200Json,
        <json:value>
            <json:value
                json:array="true">
                <info>No results, sorry</info>
            </json:value>
        </json:value>)
};

