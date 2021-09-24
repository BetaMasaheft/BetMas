
xquery version "3.1" encoding "UTF-8";
(:~
 : kwic and simple search from API
 : 
 : @author Pietro Liuzzo 
 :)
module namespace apiS = "https://www.betamasaheft.uni-hamburg.de/BetMas/apiSearch";
import module namespace config = "https://www.betamasaheft.uni-hamburg.de/BetMas/config" at "xmldb:exist:///db/apps/BetMas/modules/config.xqm";
import module namespace rest = "http://exquery.org/ns/restxq";
import module namespace kwic = "http://exist-db.org/xquery/kwic" at "resource:org/exist/xquery/lib/kwic.xql";
import module namespace all="https://www.betamasaheft.uni-hamburg.de/BetMas/all" at "xmldb:exist:///db/apps/BetMas/modules/all.xqm";
import module namespace log="http://www.betamasaheft.eu/log" at "xmldb:exist:///db/apps/BetMas/modules/log.xqm";
import module namespace titles="https://www.betamasaheft.uni-hamburg.de/BetMas/titles" at "xmldb:exist:///db/apps/BetMas/modules/titles.xqm";
(: namespaces of data used :)
import module namespace http="http://expath.org/ns/http-client";
import module namespace console="http://exist-db.org/xquery/console";

declare namespace test="http://exist-db.org/xquery/xqsuite";
declare namespace t = "http://www.tei-c.org/ns/1.0";
(: For REST annotations :)
declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace json = "http://www.json.org";



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

(:~ builds XPath as string to be added to string which will be evaluated by API search. :)
declare function apiS:BuildSearchQuery2($element as xs:string, $query as xs:string){
let $SearchOptions :=
    <options>
        <default-operator>or</default-operator>
        <phrase-slop>0</phrase-slop>
        <leading-wildcard>yes</leading-wildcard>
        <filter-rewrite>yes</filter-rewrite>
    </options>
    return
concat("t:", $element, "[ft:query(., '" , $query, "', ", serialize($SearchOptions) ,")]")
};

declare
%rest:GET
%rest:path("/api/titleTest")
%rest:query-param("id", "{$id}", "")
%output:method("json")
function apiS:titleTest($id) {
   map{ 'title' : titles:printTitleMainID($id) }
};

(:~ returns a map containing the KWIC hits from the evaluation of an xpath containing lucene full text index queries for the API search. :)
declare
%rest:GET
%rest:path("/api/kwicsearch")
%rest:query-param("q", "{$q}", "")
%rest:query-param("element", "{$element}", "")
%output:method("json")
function apiS:kwicSearch($element as xs:string*, $q as xs:string*) {
if ($q = '' or $q = ' ' or $element = '') then (<json:value>
            <json:value
                json:array="true">
                <info>you have to specify a query string and a list or elements, sorry</info>
            </json:value>
        </json:value>) else
let $log := log:add-log-message('/api/kwicsearch?q=' || $q, sm:id()//sm:real/sm:username/string() , 'REST')
    let $login := xmldb:login($config:data-root, $config:ADMIN, $config:ppw)
    
  let $elements : =
     for $e in $element
     let $elQ :=    apiS:BuildSearchQuery2($e, all:substitutionsInQuery($q))
    let $string := concat("collection($config:data-root)//",$elQ)
   return
    util:eval($string)

let $hits := ($elements)
let $hi :=  for $hit in $hits
            let $expanded := kwic:expand($hit)
            let $root := root($hit)/t:TEI
            group by $R := $root
            let $id := string($R/@xml:id)
            let $title := titles:printTitleMainID($id)
            let $collection := switch($R/@type) 
                                case 'mss' return 'manuscripts'
                                case 'place' return 'places' 
                                case 'work' return 'works' 
                                case 'nar' return 'narratives' 
                                case 'ins' return 'institutions' 
                                case 'pers' return 'persons' 
                                default return 'authority-files'
            let $count := count($expanded//exist:match)
            let $results := for $ex in $expanded
                            for $match in subsequence($ex//exist:match, 1, 3) 
                            return  kwic:get-summary($ex, $match,<config width="40"/>)
            let $test := console:log($results)
            let $pname := $expanded//exist:match[ancestor::t:div[@type eq 'edition']]
            let $text := if($pname) then 'text' else 'main'
            let $textpart := if($text = 'text') then 
            let $tpart := $expanded//exist:match[ancestor::t:div[@type eq 'edition']][1]/ancestor::t:div[@type eq 'textpart'][1]/@n
            return
                if($tpart[1]) then  string($tpart[1]) 
                else if ($tpart ='') then '1' else '1'
                else ('1')
                          
        return map {
                    "id" : $id,
                    "text" : $text,
                    "textpart" : $textpart,
                    "collection" : $collection,
                    "title" : $title,
                    "hitsCount" : $count,
                    "results" : $results                        
                        }
let $c := count($hits)
return
    if (count($hits) gt 0) then
        ($config:response200Json,
       map {
            "items" : $hi,
            "total": $c
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
%rest:path("/api/search")
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
if ($q = '' or $q = ' ' or $element = '') then (<json:value>
            <json:value
                json:array="true">
                <info>you have to specify a query string and a list or elements, sorry</info>
            </json:value>
        </json:value>) else
let $log := log:add-log-message('/api/search?q=' || $q, sm:id()//sm:real/sm:username/string() , 'REST')
    let $login := xmldb:login($config:data-root, $config:ADMIN, $config:ppw)
    let $SearchOptions :=
    <options>
        <default-operator>or</default-operator>
        <phrase-slop>0</phrase-slop>
        <leading-wildcard>yes</leading-wildcard>
        <filter-rewrite>yes</filter-rewrite>
    </options>
    let $script := if ($script != '') then
        ("[ancestor::t:TEI//@script eq '" || $script || "' ]")
    else
        ''
    let $material := if ($material != '') then
        ("[ancestor::t:TEI//t:material/@key eq '" || $material || "' ]")
    else
        ''
    let $term := if ($term != '') then
        ("[ancestor::t:TEI//t:term/@key eq '" || $term || "' ]")
    else
        ''
    
    let $collection := switch ($collection)
        case 'manuscripts'
            return
                "[ancestor::t:TEI/@type eq 'mss']"
        case 'works'
            return
                "[ancestor::t:TEI/@type eq 'work']"
        case 'places'
            return
                "[(ancestor::t:TEI/@type eq 'place') or (ancestor::t:TEI/@type eq 'ins')]"
        case 'institutions'
            return
                "[ancestor::t:TEI/@type eq 'ins']"
        case 'narratives'
            return
                "[ancestor::t:TEI/@type eq 'nar']"
        case 'authority-files'
            return
                "[ancestor::t:TEI/@type eq 'auth']"
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
concat(" collection($config:data-root)//t:persName[parent::t:person or parent::t:personGrp]"
, "[ft:query(.,'", $query-string, "',",serialize($SearchOptions),")]", $collection, $script, $material, $term)
else if($e = 'placeName'  and $descendants = 'false')  then
concat(" collection($config:data-root)//t:place/t:placeName"
, "[ft:query(.,'", $query-string, "',",serialize($SearchOptions),")]", $collection, $script, $material, $term)
else concat("collection($config:data-root)//t:"
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

