
xquery version "3.1" encoding "UTF-8";
(:~
 : kwic and simple search from API
 : 
 : @author Pietro Liuzzo <pietro.liuzzo@uni-hamburg.de'>
 :)
module namespace apiS = "https://www.betamasaheft.uni-hamburg.de/BetMas/apiSearch";
import module namespace rest = "http://exquery.org/ns/restxq";
import module namespace kwic = "http://exist-db.org/xquery/kwic" at "resource:org/exist/xquery/lib/kwic.xql";
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




(:~ builds XPath as string to be added to string which will be evaluated by API search. :)
declare function apiS:BuildSearchQuery($element as xs:string, $query as xs:string){
let $SearchOptions :=
    <options>
        <default-operator>or</default-operator>
        <phrase-slop>0</phrase-slop>
        <leading-wildcard>yes</leading-wildcard>
        <filter-rewrite>yes</filter-rewrite>
    </options>
    return
concat("descendant::t:", $element, "[ft:query(., '" , $query, "', ", serialize($SearchOptions) ,")]")
};


(:~ returns a map containing the KWIC hits from the evaluation of an xpath containing lucene full text index queries for the API search. :)
declare
%rest:GET
%rest:path("/BetMas/api/kwicsearch")
%rest:query-param("q", "{$q}", "")
%rest:query-param("element", "{$element}", "")
%output:method("json")
function apiS:kwicSearch($element as xs:string*, $q as xs:string*) {

let $log := log:add-log-message('/api/kwicsearch?q=' || $q, xmldb:get-current-user(), 'REST')
    let $login := xmldb:login('/db/apps/BetMas/data', $config:ADMIN, $config:ppw)
    
 let $hits :=  
 let $elements : =
     for $e in $element
    return 
    apiS:BuildSearchQuery($e, all:substitutionsInQuery($q))
let $allels := string-join($elements, ' or ')
let $eval-string := concat("$config:collection-root//t:TEI[",$allels, "]")

return
util:eval($eval-string)

let $hi :=   for $hit in $hits
                    let $expanded := kwic:expand($hit)
                    let $id := string($hit/@xml:id)
                    let $collection := switch($hit/@type) case 'mss' return 'manuscripts'case 'place' return 'places' case 'work' return 'works' case 'narr' return 'narratives' case 'ins' return 'institutions' case 'pers' return 'persons' default return 'authority-files'
                   let $ptest := titles:printTitleMainID($id)
                   let $title := if ($ptest) then ($ptest) else ()
                    let $count := count($expanded//exist:match)
                    let $results := kwic:summarize($hit,<config width="40"/>)
                   let $pname := $expanded//exist:match[ancestor::t:div[@type='edition']]
                   
                   let $text := if($pname) then 'text' else 'main'
                   
                   let $textpart := if($text = 'text') then 
                          let $tpart := $expanded//exist:match[ancestor::t:div[@type='edition']][1]/ancestor::t:div[@type='textpart'][1]/@n
                         
                          return if($tpart[1]) then  string($tpart[1]) else if ($tpart ='') then '1' else '1'
                          else ('1')
                          
                   return
                        map {
                            "id" := $id,
                            "text" := $text,
                            "textpart" := $textpart,
                            "collection" := $collection,
                            "title" := $title,
                            "hitsCount" := $count,
                            "results" := $results                        
                        }
let $c := count($hits)
return
    if (count($hits) gt 0) then
        ($config:response200Json,
       map {
            "items" := $hi,
            "total":= $c
        
        })
    else
        <json:value>
            <json:value
                json:array="true">
                <info>No results, sorry</info>
            </json:value>
        </json:value>
};


(:~ returns a json object containing the hits from the evaluation of an xpath containing lucene full text index queries for the API search. :)
declare
%rest:GET
%rest:path("/BetMas/api/search")
%rest:query-param("q", "{$q}", "")
%rest:query-param("element", "{$element}", "title")
%rest:query-param("collection", "{$collection}", "")
%rest:query-param("script", "{$script}", "")
%rest:query-param("material", "{$material}", "")
%rest:query-param("homophones", "{$homophones}", "true")
%rest:query-param("descendants", "{$descendants}", "true")
%output:method("json")
function apiS:search($element as xs:string+,
$q as xs:string*,
$collection as xs:string*,
$script as xs:string*,
$material as xs:string*,
$term as xs:string*,
$homophones as xs:string*,
$descendants as xs:string*) {

let $log := log:add-log-message('/api/search?q=' || $q, xmldb:get-current-user(), 'REST')
    let $login := xmldb:login('/db/apps/BetMas/data', $config:ADMIN, $config:ppw)
    let $SearchOptions :=
    <options>
        <default-operator>or</default-operator>
        <phrase-slop>0</phrase-slop>
        <leading-wildcard>yes</leading-wildcard>
        <filter-rewrite>yes</filter-rewrite>
    </options>
    let $script := if ($script != '') then
        ("[ancestor::t:TEI//@script = '" || $script || "' ]")
    else
        ''
    let $material := if ($material != '') then
        ("[ancestor::t:TEI//t:material/@key = '" || $material || "' ]")
    else
        ''
    let $term := if ($term != '') then
        ("[ancestor::t:TEI//t:term/@key = '" || $term || "' ]")
    else
        ''
    
    let $collection := switch ($collection)
        case 'manuscripts'
            return
                "[ancestor::t:TEI/@type = 'mss']"
        case 'works'
            return
                "[ancestor::t:TEI/@type = 'work']"
        case 'places'
            return
                "[ancestor::t:TEI/@type = 'place']"
        case 'institutions'
            return
                "[ancestor::t:TEI/@type = 'ins']"
        case 'narratives'
            return
                "[ancestor::t:TEI/@type = 'narr']"
        case 'authority-files'
            return
                "[ancestor::t:TEI/@type = 'auth']"
        case 'persons'
            return
                "[ancestor::t:TEI/@type = 'pers']"
        default return
            ''
let $query-string := if($homophones = 'true') then   
                                                                    if(contains($q, 'AND')) then 
                                                                                (let $parts:= for $qpart in tokenize($q, 'AND') 
                                                                                return all:substitutionsInQuery($qpart) return 
                                                                                '(' || string-join($parts, ') AND (')) || ')'
                                                                                else if(contains($q, 'OR')) then 
                                                                                (let $parts:= for $qpart in tokenize($q, 'OR') 
                                                                                return all:substitutionsInQuery($qpart) return 
                                                                                '(' || string-join($parts, ') OR (')) || ')'
                                                                                else all:substitutionsInQuery($q)  
                                                                                else ($q)
         
let $hits := 
for $e in $element 
let $eval-string := if($e = 'persName' and $descendants = 'false')  then
concat(" $config:collection-root//t:person/t:persName"
, "[ft:query(.,'", $query-string, "',",serialize($SearchOptions),")]", $collection, $script, $material, $term)
else if($e = 'placeName'  and $descendants = 'false')  then
concat(" $config:collection-root//t:place/t:placeName"
, "[ft:query(.,'", $query-string, "',",serialize($SearchOptions),")]", $collection, $script, $material, $term)
else concat("$config:collection-root//t:"
, $e, "[ft:query(.,'", $query-string, "',",serialize($SearchOptions),")]", $collection, $script, $material, $term)

return util:eval($eval-string)


let $results := 
                    for $hit in $hits
                    let $id := string($hit/ancestor::t:TEI/@xml:id)
                     let $t := normalize-space(titles:printTitleMainID($id))
               let $r := normalize-space(string-join($hit//text(), ' '))
                    return
                       map{
            'id': $id,
            'title' : $t,
            'result' : $r
            }
              
let $c := count($hits)
return
    if (count($hits) gt 0) then
        ($config:response200Json,
        map {
            'items' : $results,
           'total' : $c
        })
    else
        <json:value>
            <json:value
                json:array="true">
                <info>No results, sorry</info>
            </json:value>
        </json:value>
};

