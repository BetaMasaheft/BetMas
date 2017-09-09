xquery version "3.1" encoding "UTF-8";

module namespace api = "https://www.betamasaheft.uni-hamburg.de/BetMas/api";
import module namespace all="https://www.betamasaheft.uni-hamburg.de/BetMas/all" at "all.xqm";
import module namespace titles="https://www.betamasaheft.uni-hamburg.de/BetMas/titles" at "titles.xqm";
import module namespace config = "https://www.betamasaheft.uni-hamburg.de/BetMas/config" at "config.xqm";
import module namespace console = "http://exist-db.org/xquery/console";
import module namespace kwic = "http://exist-db.org/xquery/kwic"
    at "resource:org/exist/xquery/lib/kwic.xql"; 


import module namespace xqjson="http://xqilla.sourceforge.net/lib/xqjson";
    
(: namespaces of data used :)
declare namespace t = "http://www.tei-c.org/ns/1.0";
declare namespace dcterms = "http://purl.org/dc/terms";
declare namespace saws = "http://purl.org/saws/ontology";
declare namespace cmd = "http://www.clarin.eu/cmd/";
declare namespace skos = "http://www.w3.org/2004/02/skos/core#";
declare namespace rdf = "http://www.w3.org/1999/02/22-rdf-syntax-ns#";
declare namespace s = "http://www.w3.org/2005/xpath-functions";
declare namespace sparql = "http://www.w3.org/2005/sparql-results#";

import module namespace http="http://expath.org/ns/http-client";

(: For REST annotations :)
declare namespace rest = "http://exquery.org/ns/restxq";
declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace json = "http://www.json.org";

declare variable $api:response200 := $config:response200;

declare variable $api:response200Json := $config:response200Json;
        
declare variable $api:response200XML := $config:response200XML;

declare variable $api:response400 := $config:response400;
        
declare variable $api:response400XML := $config:response400XML;

declare function api:editorKey($key as xs:string){
switch ($key)
                        case "ES" return 'Eugenia Sokolinski'
                        case "DN" return 'Denis Nosnitsin'
                        case "MV" return 'Massimo Villa'
                        case "DR" return 'Dorothea Reule'
                        case "SG" return 'Solomon Gebreyes'
                        case "PL" return 'Pietro Maria Liuzzo'
                        case "SA" return 'Stéphane Ancel'
                        case "SD" return 'Sophia Dege'
                        case "VP" return 'Vitagrazia Pisani'
                        case "IF" return 'Iosif Fridman'
                        case "SH" return 'Susanne Hummel'
                        case "FP" return 'Francesca Panini'
                        case "DE" return 'Daria Elagina'
                        case "MK" return 'Magdalena Krzyzanowska'
                        case "VR" return 'Veronika Roth'
                        case "AA" return 'Abreham Adugna'
                        case "EG" return 'Ekaterina Gusarova'
                        case "IR" return 'Irene Roticiani'
                        case "MB" return 'Maria Bulakh'
                        case "NV" return 'Nafisa Valieva'
                        case "RHC" return 'Ran HaCohen'
                        case "SS" return 'Sisay Sahile'
                        default return 'Alessandro Bausi'};

declare function api:switchcol($type){
    
    switch($type)
        case 'work' return 'works'
        case 'narr' return 'narratives'
        case 'pers' return 'persons'
        case 'place' return 'places'
        case 'ins' return 'institutions'
        case 'auth' return 'authority-files'
        default return 'manuscripts'
    
};

declare
%rest:GET
%rest:path("/BetMas/api/additions/{$id}/addition/{$addID}")
%output:method("xml")
function api:additiontext($id as xs:string*, $addID as xs:string*){
    let $c := collection($config:data-root)
let $entity := $c//id($id)
let $a := $entity//t:item[@xml:id = $addID]
return
transform:transform($a,  'xmldb:exist:///db/apps/BetMas/xslt/q.xsl', ())

    
};

declare function api:restWhatPointsHere($id as xs:string, $c){
            let $witnesses := $c//t:witness[@corresp = $id]
let $placeNames := $c//t:placeName[@ref = $id]
let $persNames := $c//t:persName[@ref = $id]
let $titles := $c//t:title[@ref = $id]
let $active := $c//t:relation[@active = $id]
let $passive := $c//t:relation[@passive = $id]
let $allrefs := ($witnesses, 
        $placeNames,  
        $persNames, 
        $titles, 
        $active, 
        $passive)
return
for $corr in $allrefs
        return 
            $corr
            
            };

declare
%rest:GET
%rest:path("/BetMas/api/relations/{$id}")
%output:method("json")
function api:relNodes($id as xs:string*){

let $c := collection($config:data-root)
let $entity := $c//id($id)
let $type := $entity/@type
let $collection := api:switchcol($type)

let $localId := $id
let $thisMap := map {
        "id" := $id, 
        "label" := titles:printTitleID($id), 
        "group" := string($type)
        }

let $whatpointshere := api:restWhatPointsHere($localId, $c)

let $refs := ($entity//@ref[not(./ancestor::t:respStmt)], $entity//@active, $entity//@passive)
let $secondaryrelations := 
for $id in distinct-values($refs[.!=$localId]) return 
(:exclude empty values :)
if($id ='') then () else if(contains($id,' ')) then () else api:restWhatPointsHere($id, $c)

(:looks for any person with a role and a ref, excluding the ES placeholders:)


let $wph := 
    let $ids := for $pointerRoot in ($whatpointshere, $secondaryrelations)
                let $refid := root($pointerRoot)/t:TEI/@xml:id
                return $refid
    let $allids :=($ids, $refs)
    for $I in distinct-values($allids)
    let $thisI := $c//id($I)[name()='TEI']
    let $rootype := $thisI[1]/@type
    let $title := try{titles:printTitleID($I)} catch * {$I}
    let $titleN := if(count($title) gt 1) then normalize-space(string-join($title, ' ')) else normalize-space($title)
    return 
      (:first return the root of the referring entity and the id in the corresp, active, passive, mutual, etc. there.:)
     map {
        "id" := $I, 
        "label" := $titleN, 
        "group" := string($rootype)
        }

let $here := 
    (: from the current item to the entities it points to :)
    for $id in $refs 
    let $elem := $id/parent::t:*
    let $pN := name($elem)
        let $name := if($pN = 'relation') then string($elem/@name) else $pN
        return
    map {'from':=$localId, 
      'to':=$id/string(), 
      'label':=$name, 
      'value':=1, 
      'font':= map {'align':= 'top'}}
      let $there :=
 (:from what points here to the current item:)
      for $id in $secondaryrelations 
      let $r := root($id)/t:TEI/@xml:id
      let $refname := name($id)
      let $test := console:log($refname)
      let $name := if($refname = 'relation') then string($id/@name) else $refname
      let $R := if($refname = 'witness') then string($id/@corresp) else if($refname = 'relation') then if($refs = $id/@active) then  string($id/@active) else string($id/@passive) else string($id/@ref)
        return
    map {'from':= string($r), 
      'to':=$R, 
      'label' := $name,
      'value':= 1, 
      'font':= map {'align':= 'top'}}
  let $tohere :=
 (:from what points here to the current item:)
      for $id in $whatpointshere 
      let $r := root($id)/t:TEI/@xml:id
      let $refname := name($id)
      let $test := console:log($refname)
      let $name := if($refname = 'relation') then string($id/@name) else $refname
     
        return
    map {'from':= string($r), 
      'to':=$localId, 
      'label' := $name,
      'value':= 1, 
      'font':= map {'align':= 'top'}}
      
      let $edges := ($here, $there, $tohere)
      let $idswph :=  for $x in $wph return $x('id')
      let $nodes := if($idswph = $id) then $wph else ($thisMap, $wph)
return
(:returns the title and id of the entities referring to this entity or entity referring to those pointing to the entity:)
  ($api:response200Json,
 map {'nodes' :=  $nodes,
 'edges' :=  $edges,
     'cN' := count($nodes),
     'cE' := count($edges)
 })
};

declare
%rest:GET
%rest:path("/BetMas/api/sharedKeyword/{$keyword}")
%rest:query-param("element", "{$element}", "persName")
%output:method("json")
function api:SharedKeyword(
$keyword as xs:string*, $element as xs:string*) {
let $attr := switch($element) 
                            case 'persName' return 'ref' 
                            case 'keywords' return 'key'
                            case 'material' return 'key'
                            case 'script' return 'script'
                            case 'form' return 'form'
                            case 'attributed author' return 'active'
                            case 'author' return 'passive'
                            case 'larger places' return 'ref'
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
                            case 'larger places' return 'settlement'
                            case 'type' return 'place'
                            case 'role' return 'roleName'
                            case 'faith' return 'faith'
                            case 'occupation' return 'occupation'
                            default return 'persName'
let $buildQuery := 'collection($config:data-root)//t:TEI[descendant::t:' || $elementName ||'[@' || $attr || "='" || $keyword || "']]"
let $query :=  util:eval($buildQuery)
let $total := count($query)
let $hits := for $hit in $query
                let $id := string($hit/@xml:id)
                let $title := try{titles:printTitleID($id)} catch * {('no title for ' || $id)}
               
          return
            map {
                'id' : $id,
                'title' : $title
                    }

return 
($api:response200Json,
map {
'hits' := $hits,
'total' := $total
})
};

declare function api:decidePlaceNameSource($pRef){
if (contains($pRef, 'gn:')) then (api:getGeoNames($pRef)) 
else if (starts-with($pRef, 'pleiades')) then (api:getPleiadesNames($pRef)) 
else if (starts-with($pRef, 'Q')) then (api:getwikidataNames($pRef)) 
else titles:printTitleID($pRef) 
                                            };

(:get inverted coordinates:)
declare function api:invertCoord($coords) {
    
    let $invert := substring-after($coords, ',') || ',' || substring-before($coords, ',')
    return
        replace($invert, ' ', '')
};

(:gives priority to places where to look for coordinates
first looks at what the id is, then if it is one of ours, looks for coordinates
1. take ours if we have them, if not look for a sameAs and check there for coordinates:)
declare function api:getCoords($placenameref as xs:string){
if(starts-with($placenameref, 'LOC') or starts-with($placenameref, 'INS')) then 
let $pRec := collection($config:data-rootPl, $config:data-rootIn)//id($placenameref)
        return
        if (starts-with($placenameref, 'INS') and $pRec//t:geo/text()) then concat(substring-after($pRec//t:geo, ' '), ',', substring-before($pRec//t:geo, ' '))
        else if($pRec//@sameAs) then api:GNorWD($pRec//@sameAs) 
        else if($pRec//t:geo/text()) then concat(substring-after($pRec//t:geo, ' '), ',', substring-before($pRec//t:geo, ' '))
        else console:log("no coordinates for" || $placenameref)
else api:GNorWD($placenameref)
};

(:if the id of a place is not one of ours, then is a Q item in wikidata or a geonames id:)
declare function api:GNorWD($placeexternalid as xs:string){
if(starts-with($placeexternalid, 'gn:')) then api:getGeoNamesCoord($placeexternalid)
else if(starts-with($placeexternalid, 'pleiades:')) then api:getPleiadesCoord($placeexternalid)
else if(starts-with($placeexternalid, 'Q')) then api:getWikiDataCoord($placeexternalid)
else console:log("no valid external id" || $placeexternalid)
};

(:for the annotations in pelagios, decide based on id how to format the uri:)
declare function api:getannotationbody($placeid as xs:string){
if(starts-with($placeid, 'INS')) then 'http://betamasaheft.aai.uni-hamburg.de/institutions/' || $placeid
else if(starts-with($placeid, 'LOC')) then 'http://betamasaheft.aai.uni-hamburg.de/places/' || $placeid
else if(starts-with($placeid, 'pleiades:')) then 'https://pleiades.stoa.org/places/' || substring-after($placeid, 'pleiades:')
else if(starts-with($placeid, 'Q')) then 'https://www.wikidata.org/wiki/' || $placeid
else 'http://sws.geonames.org/' || substring-after($placeid, 'gn:')
};


(: used by functions in coordinates and map modules to gather place representative points and labels :)
declare function api:getGeoNames($string as xs:string) {
    let $gnid := substring-after($string, 'gn:')
    let $xml-url := concat('http://api.geonames.org/get?geonameId=', $gnid, '&amp;username=betamasaheft')
    let $data := httpclient:get(xs:anyURI($xml-url), true(), <Headers/>)
   
    return
        $data//toponymName/text()
};

declare function api:getPleiadesNames($string as xs:string) {
   let $plid := substring-after($string, 'pleiades:')
   let $url := concat('http://pelagios.org/peripleo/places/http:%2F%2Fpleiades.stoa.org%2Fplaces%2F', $plid)
  let $file := httpclient:get(xs:anyURI($url), true(), <Headers/>)
  
let $file-info := 
    let $payload := util:base64-decode($file) 
    let $parse-payload := xqjson:parse-json($payload)
    return $parse-payload 
    return $file-info/*:pair[@name="title"]/text()

};

declare function api:getwikidataNames($pRef){
let $sparql := 'SELECT * WHERE {
  wd:' || $pRef || ' rdfs:label ?label . 
  FILTER (langMatches( lang(?label), "EN-GB" ) )  
}'


let $query := 'https://query.wikidata.org/sparql?query='|| xmldb:encode-uri($sparql)

let $req := httpclient:get(xs:anyURI($query), false(), <headers/>)
return
$req//sparql:result/sparql:binding[@name="label"]/sparql:literal[@xml:lang='en-gb']/text()
};

declare function api:getGeoNamesCoord($string as xs:string) {
    let $gnid := substring-after($string, 'gn:')
    let $xml-url := concat('http://api.geonames.org/get?geonameId=', $gnid, '&amp;username=betamasaheft')
    let $data := httpclient:get(xs:anyURI($xml-url), true(), <Headers/>)
   let $test :=   $data
    return
        $data//lng/text() || ',' ||$data//lat/text()
};

declare function api:getWikiDataCoord($Qid as xs:string){
let $sparql := 'SELECT ?coord ?coordLabel WHERE {
   wd:' || $Qid || ' wdt:P625 ?coord .
   SERVICE wikibase:label { 
    bd:serviceParam wikibase:language "en" .
   }
 }'

let $query := 'https://query.wikidata.org/sparql?query='|| xmldb:encode-uri($sparql)
let $req := httpclient:get(xs:anyURI($query), false(), <headers/>)
let $removePoint := replace($req//sparql:result/sparql:binding[@name="coordLabel"], 'Point\(', '')
let $removetrailing := replace($removePoint, '\)', '')
return
replace($removetrailing, ' ', ',')

};

declare function api:getPleiadesCoord($string as xs:string) {
   let $plid := substring-after($string, 'pleiades:')
   let $url := concat('http://pelagios.org/peripleo/places/http:%2F%2Fpleiades.stoa.org%2Fplaces%2F', $plid)
  let $file := httpclient:get(xs:anyURI($url), true(), <Headers/>)
  
let $file-info := 
    let $payload := util:base64-decode($file) 
    let $parse-payload := xqjson:parse-json($payload)
    return $parse-payload 
let $coords := if ($file-info//*:pair[@name="geo_bounds"]/*:pair[1]/text() = $file-info//*:pair[@name="geo_bounds"]/*:pair[2]/text())
then ($file-info//*:pair[@name="geo_bounds"]/*:pair[1]/text(), $file-info//*:pair[@name="geo_bounds"]/*:pair[3]/text()) else $file-info//*:pair[@name="geo_bounds"]/*:pair/text()
    return 
    string-join($coords, ',')

};


declare 
%rest:GET
%rest:path("/BetMas/api/idlookup")
%rest:query-param("id", "{$id}", "")
%output:method("json")
function api:IDSlookup($id as xs:string*) {<rest:response>
            <http:response
                status="200">
                <http:header
                    name="Content-Type"
                    value="application/json; charset=utf-8"/>
            </http:response>
        </rest:response>,
let $query := (
collection('/db/apps/BetMas/data/')/t:TEI[contains(@xml:id, $id)],
collection('/db/apps/BetMas/data/')//t:msPart[contains(@xml:id, $id)],
collection('/db/apps/BetMas/data/')//t:msItem[contains(@xml:id, $id)],
collection('/db/apps/BetMas/data/')//t:title[contains(@xml:id, $id)],
collection('/db/apps/BetMas/data/')//t:div[contains(@xml:id, $id)])
 let $results := for $hit in $query
 let $i := string($hit/@xml:id)
(: let $rootID := string(root($hit)/t:TEI/@xml:id):)
(: let $title := if ($i = $rootID) then titles:printTitleID($i) else api:printSubtitle(root($hit),$i):)
        return
        map {'id' := $i}
     
let $c := count($query)
return
    if (count($query) gt 0) then
        ($api:response200Json,
        map {
            'items' : $results,
           'total' : $c
        })
    else
        ($api:response200Json,
        <json:value>
            <json:value
                json:array="true">
                <info>No results, sorry</info>
            </json:value>
        </json:value>)

};


declare 
%rest:GET
%rest:path("/BetMas/api/{$id}/author")
%output:method("xml")
function api:getauthorfromrelation($id as xs:string*) {
let $item := collection('/db/apps/BetMas/data/works/')//id($id)
return 

if($item//t:relation[@name = 'saws:isAttributedToAuthor']) then (
$api:response200XML,
        $item//t:relation[@name = 'saws:isAttributedToAuthor']
        )
        else 
        (
        $api:response400XML,
        <sorry>no info</sorry>
        )
};



declare
%rest:GET
%rest:path("/BetMas/api/clavis/{$id}")
%output:method("json")
function api:ClavisbyID($id as xs:string*) {

(:results from PAThs
results from BM interroga bibl con id clavis e titolo.
se interrogato da titolo da gli id, altrimenti per id da gli altri id e il titolo

:)

    
                    let $root := api:get-tei-by-ID($id)
                    let $id := string($root/@xml:id)
                    let $title := titles:printTitleID($id)
                    let $clavisBibl := $root//t:listBibl[@type='clavis']
                    let $CC := $clavisBibl/t:bibl[@type='CC']/t:citedRange/text()
                    let $CPG := $clavisBibl/t:bibl[@type='CPG']/t:citedRange/text()
                    let $CANT := $clavisBibl/t:bibl[@type='CANT']/t:citedRange/text()
                    let $CAVT := $clavisBibl/t:bibl[@type='CAVT']/t:citedRange/text()
                    let $BHO := $clavisBibl/t:bibl[@type='BHO']/t:citedRange/text()
                    let $BHL := $clavisBibl/t:bibl[@type='BHL']/t:citedRange/text()
                    let $syriaca := $clavisBibl/t:bibl[@type='syriaca']/t:citedRange/text()
                    let $clavisIDS := map {
                    "CC":=  $CC,
                    "CPG":=  $CPG,
                    "CANT":=  $CANT,
                    "CAVT":=  $CAVT,
                    "BHO":=  $BHO,
                    "BHL":=  $BHL,
                    "syriaca":=  $syriaca
                    }
                    
                    return
                        ( $api:response200Json,
                        map {
                            "CAe" := $id,
                            "title" := $title,
                            "clavis" := $clavisIDS                
                        })
                        
};

declare
%rest:GET
%rest:path("/BetMas/api/clavis")
%rest:query-param("q", "{$q}", "")
%output:method("json")
function api:Clavis($q as xs:string*) {

(:results from PAThs
results from BM interroga bibl con id clavis e titolo.
se interrogato da titolo da gli id, altrimenti per id da gli altri id e il titolo

:)
  
let $eval-string := concat("collection('", $config:data-rootW, "')//t:title",
"[ft:query(.,'", $q, "')]")
let $hits := util:eval($eval-string)
let $hi :=   for $hit in $hits
                    let $root := root($hit)
                    let $id := string($root//t:TEI/@xml:id)
                    group by $id := $id
                    let $title := titles:printTitleID($id)
                    let $hitCount := count($hit)
                    let $clavisBibl := $root//t:listBibl[@type='clavis']
                    let $CC := $clavisBibl/t:bibl[@type='CC']/t:citedRange/text()
                    let $CPG := $clavisBibl/t:bibl[@type='CPG']/t:citedRange/text()
                    let $CANT := $clavisBibl/t:bibl[@type='CANT']/t:citedRange/text()
                    let $CAVT := $clavisBibl/t:bibl[@type='CAVT']/t:citedRange/text()
                    let $BHO := $clavisBibl/t:bibl[@type='BHO']/t:citedRange/text()
                    let $BHL := $clavisBibl/t:bibl[@type='BHL']/t:citedRange/text()
                    let $syriaca := $clavisBibl/t:bibl[@type='syriaca']/t:citedRange/text()
                    let $clavisIDS := map {
                    "CC":=  $CC,
                    "CPG":=  $CPG,
                    "CANT":=  $CANT,
                    "CAVT":=  $CAVT,
                    "BHO":=  $BHO,
                    "BHL":=  $BHL,
                    "syriaca":=  $syriaca
                    }
                    
                    return
                        map {
                            "CAe" := $id,
                            "title" := $title,
                            "clavis" := $clavisIDS,
                            "hits" := $hitCount                    
                        }
let $c := count($hits)
return
    if (count($hits) gt 0) then
         ( $api:response200Json,
       map {
            "items" := $hi,
            "totalhits":= $c
        
        })
    else
         ( $api:response200Json,
        <json:value>
            <json:value
                json:array="true">
                <info>No results, sorry</info>
            </json:value>
        </json:value>)
};

declare
%rest:GET
%rest:path("/BetMas/api/hasrole/{$role}")
%output:method("json")
function api:role($role as xs:string*) {
let $cp := collection($config:data-rootPr)
let $path :=  collection($config:data-root)//t:persName[@ref != 'PRS00000'][@ref != 'PRS0000'][@role = $role]
let $total := count($path)
let $hits := for $pwl in $path
                    let $id := string($pwl/@ref)
                    let $title := titles:printTitleID($id)
                    let $sortkey := normalize-space($title[1])
                   
                    group by $ID := $id
                    order by $sortkey[1]
            
        return
            map {
                'pwl' : $ID,
                'title' : titles:printTitleID($ID),
                'sorting' : $sortkey[1],
                'hasthisrole' : for $x in $pwl 
                                    let $root := string(root($x)/t:TEI/@xml:id)
                                    group by $r := $root
                                    return
                                         map {
                                                    'source' : $r,
                                                    'sourceTitle' : titles:printTitleID($r)
                                                    }
                    }

return 
     ( $api:response200Json,
map {
'role' := $role,
'hits' := $hits,
'total' := $total
})
};



declare function api:BuildSearchQuery($element as xs:string, $query as xs:string){
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


declare
%rest:GET
%rest:path("/BetMas/api/kwicsearch")
%rest:query-param("q", "{$q}", "")
%rest:query-param("element", "{$element}", "")
%output:method("json")
function api:kwicSearch($element as xs:string*, $q as xs:string*) {
    
 let $hits :=  
 let $elements : =
     for $e in $element
    return 
    api:BuildSearchQuery($e, all:substitutionsInQuery($q))
let $allels := string-join($elements, ' or ')
let $eval-string := concat("collection('", $config:data-root, "')//t:TEI[",$allels, "]")

return
util:eval($eval-string)

let $hi :=   for $hit in $hits
                    let $expanded := kwic:expand($hit)
                    let $id := string($hit/@xml:id)
                    let $collection := switch($hit/@type) case 'mss' return 'manuscripts'case 'place' return 'places' case 'work' return 'works' case 'narr' return 'narratives' case 'ins' return 'institutions' case 'pers' return 'persons' default return 'authority-files'
                   let $ptest := titles:printTitleID($id)
                   let $title := if ($ptest) then ($ptest) else (console:log('problem printing title of ' || $id), $id)
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
        ($api:response200Json,
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




declare
%rest:GET
%rest:path("/BetMas/api/search")
%rest:query-param("q", "{$q}", "")
%rest:query-param("element", "{$element}", "title")
%rest:query-param("collection", "{$collection}", "")
%rest:query-param("script", "{$script}", "")
%rest:query-param("material", "{$material}", "")
%output:method("json")
function api:search($element as xs:string+,
$q as xs:string*,
$collection as xs:string*,
$script as xs:string*,
$material as xs:string*,
$term as xs:string*) {
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
let $query-string := all:substitutionsInQuery($q)
         
let $hits := 
for $e in $element 
let $eval-string := concat("collection('", $config:data-root, "')//t:"
, $e, "[ft:query(.,'", $query-string, "',",serialize($SearchOptions),")]", $collection, $script, $material, $term)
return util:eval($eval-string)


let $results := 
                    for $hit in $hits
                    let $id := string($hit/ancestor::t:TEI/@xml:id)
                     let $t := normalize-space(titles:printTitleID($id))
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
        ($api:response200Json,
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


declare
%rest:GET
%rest:path("/BetMas/api/dts")
%output:method("json")
function api:dtsmain() {

  ( $api:response200Json,
         <json:value>
         <collectionsAPI>http://betamasaheft.aai.uni-hamburg.de/api/dts/collections</collectionsAPI>
         <passagesAPI>http://betamasaheft.aai.uni-hamburg.de/api/dts/text</passagesAPI>
         <citationsAPI>http://betamasaheft.aai.uni-hamburg.de/api/dts/cit</citationsAPI>
         <documentation>http://betamasaheft.aai.uni-hamburg.de/api/</documentation>
         </json:value>)
         
};



declare
%rest:GET
%rest:path("/BetMas/api/dts/text")
%output:method("json")
function api:dtsTexts() {
  ( $api:response200Json,
         <json:value>
         <documentation>http://betamasaheft.aai.uni-hamburg.de/api/</documentation>
         </json:value>)
         
         
};





declare
%rest:GET
%rest:path("/BetMas/api/{$collection}/list/json")
%rest:query-param("start", "{$start}", 1)
%rest:query-param("perpage", "{$perpage}", 25)
%rest:query-param("term", "{$term}", "")
%output:method("json")
function api:collectionJSON($collection as xs:string*, $start as xs:integer*, $perpage as xs:integer*, $term as xs:string*) {
    
    (: logs into the collection :)
         ( $api:response200Json,
    
    let $term := if ($term != '') then
        ("[descendant::t:term/@key = '" || $term || "' ]")
    else
        ''
    let $collecPath := switch ($collection)
        case 'works'
            return
                $config:data-rootW
        case 'persons'
            return
                $config:data-rootPr
        case 'institutions'
            return
                $config:data-rootIn
        case 'manuscripts'
            return
                $config:data-rootMS
        case 'narratives'
            return
                $config:data-rootN
        case 'authority-files'
            return
                $config:data-rootA
        case 'places'
            return
                $config:data-rootPl
        default return
            $config:data-root

let $path := concat("collection('",
$collecPath
, "')//t:TEI", $term)

let $hits := util:eval($path)

return
    <json:value>
        <items>
            {
                for $resource in subsequence($hits, $start, $perpage)
                let $rid := $resource/@xml:id
                let $rids := string($rid)
                let $title := titles:printTitleID($rid)
                order by $title[1] descending
                return
                    <json:value
                        json:array="true">
                        <id>{$rids}</id>
                        <title>{$title}</title>
                        {
                        element item {
                                element uri {base-uri($resource)},
                                element name {util:unescape-uri(replace(base-uri($resource), ".+/(.+)$", "$1"), "UTF-8")},
                                element type {string($resource/@type)},
                                switch ($resource/@type)
                                    case 'mss'
                                        return
                                            (
                                            element support {
                                                for $r in $resource//@form
                                                return
                                                    <json:value
                                                        json:array="true"><value>{string($r)}</value></json:value>
                                            },
                                            element institution {
                                                for $r in $resource//t:repository/@ref
                                                return
                                                    <json:value
                                                        json:array="true"><id>{string($r)}</id></json:value>
                                            },
                                            element script {
                                                for $r in $resource//@script
                                                return
                                                    <json:value
                                                        json:array="true"><value>{string($r)}</value></json:value>
                                            },
                                            element material {
                                                for $r in $resource//t:support/t:material/@key
                                                return
                                                    <json:value
                                                        json:array="true"><value>{string($r)}</value></json:value>
                                            },
                                            element keyword {
                                                for $r in $resource//t:term/@key
                                                return
                                                    <json:value
                                                        json:array="true"><value>{string($r)}</value></json:value>
                                            },
                                            element language {
                                                for $r in $resource//t:language
                                                return
                                                    <json:value
                                                        json:array="true"><value>{string($r)}</value></json:value>
                                            },
                                            element content {
                                                for $r in $resource//t:title/@ref
                                                return
                                                    <json:value
                                                        json:array="true"><value>{string($r)}</value></json:value>
                                            },
                                            element scribe {
                                                for $r in $resource//t:persName[@role = 'scribe']/@ref[not(. = 'PRS00000') and not(. = 'PRS0000')]
                                                return
                                                    <json:value
                                                        json:array="true"><id>{string($r)}</id></json:value>
                                            },
                                            element donor {
                                                for $r in $resource//t:persName[@role = 'donor']/@ref[not(. = 'PRS00000') and not(. = 'PRS0000')]
                                                return
                                                    <json:value
                                                        json:array="true"><id>{string($r)}</id></json:value>
                                            },
                                            element patron {
                                                for $r in $resource//t:persName[@role = 'patron']/@ref[not(. = 'PRS00000') and not(. = 'PRS0000')]
                                                return
                                                    <json:value
                                                        json:array="true"><id>{string($r)}</id></json:value>
                                            })
                                    case 'pers'
                                        return
                                            (element occupation {
                                                for $r in $resource//t:occupation
                                                return
                                                    replace(normalize-space($r), ' ', '_') || ' '
                                            },
                                            element role {
                                                for $r in $resource//t:person/t:persName/t:roleName
                                                return
                                                    replace(normalize-space($r), ' ', '_') || ' '
                                            },
                                            element gender {$resource//t:person/@sex})
                                    case 'place'
                                        return
                                            (element placeType {
                                                for $r in $resource//t:place/@type
                                                return
                                                    <json:value
                                                        json:array="true"><id>{string($r)}</id></json:value>
                                            },
                                            element tabot {
                                                for $r in $resource//t:ab[@type = 'tabot']/t:persName/@ref
                                                return
                                                    <json:value
                                                        json:array="true"><id>{string($r)}</id></json:value>
                                            })
                                    
                                    case 'ins'
                                        return
                                            (element placeType {
                                                for $r in $resource//t:place/@type
                                                return
                                                    <json:value
                                                        json:array="true"><id>{string($r)}</id></json:value>
                                            },
                                            element tabot {
                                                for $r in $resource//t:ab[@type = 'tabot']/t:persName/@ref
                                                return
                                                    <json:value
                                                        json:array="true"><value>{string($r)}</value></json:value>
                                            })
                                    case 'work'
                                        return
                                            (element keyword {
                                                for $r in $resource//t:term/@key
                                                return
                                                    <json:value
                                                        json:array="true"><value>{string($r)}</value></json:value>
                                            },
                                            element language {
                                                for $r in $resource//t:language
                                                return
                                                    <json:value
                                                        json:array="true"><value>{string($r)}</value></json:value>
                                            },
                                            element author {
                                                for $r in ($resource//t:relation[@name = "saws:isAttributedToAuthor"]/@passive, $resource//t:relation[@name = "dcterms:creator"]/@passive)
                                                return
                                                    <json:value
                                                        json:array="true"><id>{string($r)}</id></json:value>
                                            },
                                            element witness {
                                                for $r in $resource//t:witness/@corresp
                                                return
                                                    <json:value
                                                        json:array="true"><id>{string($r)}</id></json:value>
                                            })
                                    case 'narr'
                                        return
                                            (element keyword {
                                                for $r in $resource//t:term/@key
                                                return
                                                    <json:value
                                                        json:array="true"><value>{string($r)}</value></json:value>
                                            },
                                            element language {
                                                for $r in $resource//t:language
                                                return
                                                    <json:value
                                                        json:array="true"><value>{string($r)}</value></json:value>
                                            },
                                            element author {
                                                for $r in ($resource//t:relation[@name = "saws:isAttributedToAuthor"]/@passive, $resource//t:relation[@name = "dcterms:creator"]/@passive)
                                                return
                                                    <json:value
                                                        json:array="true"><id>{string($r)}</id></json:value>
                                            })
                                    default return
                                        ()
                        }
                    }
                </json:value>
        }
    
    </items>
    <total>{count($hits)}</total>
</json:value>)
};

declare
%rest:GET
%rest:path("/BetMas/api/{$collection}/list")
%rest:query-param("start", "{$start}", 1)
%rest:query-param("perpage", "{$perpage}", 25)
%rest:query-param("term", "{$term}", "")
%output:method("xml")
function api:collection($collection as xs:string*, $start as xs:integer*, $perpage as xs:integer*, $term as xs:string*) {
    
    (: logs into the collection :)
        ( $api:response200XML,
    
    let $term := if ($term != '') then
        ("[descendant::t:term/@key = '" || $term || "' ]")
    else
        ''
    let $collecPath := switch ($collection)
        case 'works'
            return
                $config:data-rootW
        case 'persons'
            return
                $config:data-rootPr
        case 'institutions'
            return
                $config:data-rootIn
        case 'manuscripts'
            return
                $config:data-rootMS
        case 'narratives'
            return
                $config:data-rootN
        case 'authority-files'
            return
                $config:data-rootA
        case 'places'
            return
                $config:data-rootPl
        default return
            $config:data-root

let $path := concat("collection('",
$collecPath
, "')//t:TEI", $term)

let $hits := util:eval($path)

return
    
    
    <items>
        {
            for $resource in subsequence($hits, $start, $perpage)
            let $title := titles:printTitleID(string($resource/@xml:id))
            order by $title[1] descending
            return
                
                element item {
                    attribute uri {base-uri($resource)},
                    attribute name {util:unescape-uri(replace(base-uri($resource), ".+/(.+)$", "$1"), "UTF-8")},
                    attribute id {string($resource/@xml:id)},
                    attribute type {string($resource/@type)},
                    switch ($resource/@type)
                        case 'mss'
                            return
                                (
                                attribute support {
                                    for $r in $resource//@form
                                    return
                                        string($r) || ' '
                                },
                                attribute institution {
                                    for $r in $resource//t:repository/@ref
                                    return
                                        string($r) || ' '
                                },
                                attribute script {
                                    for $r in $resource//@script
                                    return
                                        string($r) || ' '
                                },
                                attribute material {
                                    for $r in $resource//t:support/t:material/@key
                                    return
                                        string($r) || ' '
                                },
                                attribute keyword {
                                    for $r in $resource//t:term/@key
                                    return
                                        string($r) || ' '
                                },
                                attribute language {
                                    for $r in $resource//t:language
                                    return
                                        string($r) || ' '
                                },
                                attribute content {
                                    for $r in $resource//t:title/@ref
                                    return
                                        string($r) || ' '
                                },
                                attribute scribe {
                                    for $r in $resource//t:persName[@role = 'scribe']/@ref[not(. = 'PRS00000') and not(. = 'PRS0000')]
                                    return
                                        string($r) || ' '
                                },
                                attribute donor {
                                    for $r in $resource//t:persName[@role = 'donor']/@ref[not(. = 'PRS00000') and not(. = 'PRS0000')]
                                    return
                                        string($r) || ' '
                                },
                                attribute patron {
                                    for $r in $resource//t:persName[@role = 'patron']/@ref[not(. = 'PRS00000') and not(. = 'PRS0000')]
                                    return
                                        string($r) || ' '
                                })
                        case 'pers'
                            return
                                (attribute occupation {
                                    for $r in $resource//t:occupation
                                    return
                                        replace(normalize-space($r), ' ', '_') || ' '
                                },
                                attribute role {
                                    for $r in $resource//t:person/t:persName/t:roleName
                                    return
                                        replace(normalize-space($r), ' ', '_') || ' '
                                },
                                attribute gender {$resource//t:person/@sex})
                        case 'place'
                            return
                                (attribute placeType {
                                    for $r in $resource//t:place/@type
                                    return
                                        string($r) || ' '
                                },
                                attribute tabot {
                                    for $r in $resource//t:ab[@type = 'tabot']/t:persName/@ref
                                    return
                                        string($r) || ' '
                                })
                        case 'ins'
                            return
                                (attribute placeType {
                                    for $r in $resource//t:place/@type
                                    return
                                        string($r) || ' '
                                },
                                attribute tabot {
                                    for $r in $resource//t:ab[@type = 'tabot']/t:persName/@ref
                                    return
                                        string($r) || ' '
                                })
                        case 'work'
                            return
                                (attribute keyword {
                                    for $r in $resource//t:term/@key
                                    return
                                        string($r) || ' '
                                },
                                attribute language {
                                    for $r in $resource//t:language
                                    return
                                        string($r) || ' '
                                },
                                attribute author {
                                    for $r in ($resource//t:relation[@name = "saws:isAttributedToAuthor"]/@passive, $resource//t:relation[@name = "dcterms:creator"]/@passive)
                                    return
                                        string($r) || ' '
                                },
                                attribute witness {
                                    for $r in $resource//t:witness/@corresp
                                    return
                                        string($r) || ' '
                                })
                        case 'narr'
                            return
                                (attribute keyword {
                                    for $r in $resource//t:term/@key
                                    return
                                        string($r) || ' '
                                },
                                attribute language {
                                    for $r in $resource//t:language
                                    return
                                        string($r) || ' '
                                },
                                attribute author {
                                    for $r in ($resource//t:relation[@name = "saws:isAttributedToAuthor"]/@passive, $resource//t:relation[@name = "dcterms:creator"]/@passive)
                                    return
                                        string($r) || ' '
                                })
                        default return
                            (),
                $title
            }
    }
    <total>{count($hits)}</total>
</items>)

};

declare
%rest:GET
%rest:path("/BetMas/api/otherMssText/{$id}/{$SUBid}")
%rest:query-param("element", "{$element}", "")
%output:method("xml")
function api:get-othertext($id as xs:string, $SUBid as xs:string, $element as xs:string*) {
        
         ( $api:response200XML,
        let $collection := 'manuscripts'
        let $item := api:get-tei-rec-by-ID($id)
        return
            if ($item//t:*[(name() = $element) or (@xml:id = $SUBid)]//text())
            then
                let $match := $item//t:*[@xml:id = $SUBid]//name()
                return
                    <othermsselement>
                        <id>{$id}</id>
                        <element>{$match} #{$SUBid}</element>
                        <url>http://betamasaheft.aai.uni-hamburg.de/manuscripts/{$id}#{$SUBid}</url>
                        {
                            for $q in $item//t:*[@xml:id = $SUBid]/t:q
                            return
                                <text
                                    lang="{$q/@xml:lang}">{$q/text()}</text>
                        }
                        
                        {
                            
                            for $type in $item//t:*[@xml:id = $SUBid]/t:*[@type]
                            return
                                <type>{string($type/@type)}</type>
                        }
                        {
                            if ($match = 'msPart') then
                                <contains>
                                    {
                                        for $e in $item//t:*[@xml:id = $SUBid]//child::*
                                        return
                                            element {$e/name()} {$e/text()}
                                    }
                                </contains>
                            else
                                if ($match = 'msItem') then
                                    (<is>{string($item//t:*[@xml:id = $SUBid]/t:title/@corresp)}</is>,
                                    <contains>
                                        {
                                            for $e in $item//t:*[@xml:id = $SUBid]//child::*
                                            return
                                                element {$e/name()} {$e/text()}
                                        }</contains>)
                                
                                else
                                    ()
                        }
                    </othermsselement>
            else
                let $call := 'http://betamasaheft.aai.uni-hamburg.de/api/extra/' || $id || '/' || $SUBid
                return
                    api:noresults($call)
        )
};

(:
 : The following function retrive the text of the selected work and returns
: it with basic informations for next and following into a small XML tree

:)

declare
%rest:GET
%rest:path("/BetMas/api/xml/{$id}")
%output:method("xml")
function api:get-workXML($id as xs:string) {
        
        ($api:response200XML,
        let $collection := 'works'
        let $item := api:get-tei-rec-by-ID($id)
        let $recordid := $item/t:TEI/@xml:id
        return
            if ($item//t:div[@type = 'edition'])
            then
                <work>
                    <id>{data($recordid)}</id>
                    <text>{$item//t:div[@type = 'edition']//text()}</text>
                    <contains>
                        {
                            for $subtype in $item//t:div[@type = 'edition']/t:div[@subtype]
                            return
                                
                                element {string($subtype/@subtype)} {('http://betamasaheft.aai.uni-hamburg.de/api/xml/' || $id || '/' || $subtype/@n)}
                        }
                    </contains>
                
                
                </work>
            
            else
                let $call := 'http://betamasaheft.aai.uni-hamburg.de/api/xml/' || $id
                return
                    api:noresults($call)
        )
};

declare function api:citation($item as node()){
if($item//t:titleStmt/t:title[@type='short']) then $item//t:titleStmt/t:title[@type='short']/text() else $item//t:titleStmt/t:title[@xml:id = 't1']/text()};
(:returns the full first level subdivision

Ex. 1 

:)
declare
%rest:GET
%rest:path("/BetMas/api/xml/{$id}/{$level1}")
%output:method("xml")
function api:get-level1XML($id as xs:string, $level1 as xs:string*) {
    ($api:response200XML,
    let $collection := 'works'
    let $item := api:get-tei-rec-by-ID($id)
    let $recordid := $item/@xml:id
    
    return
        if ($item//t:div[@type = 'edition']/t:div[@n = $level1][t:ab])
        then
            <work>
                
                <id>{data($recordid)}</id>
                <citation>{(api:citation($item) || ' ' || $level1)}</citation>
                <title>{$item//t:titleStmt/t:title[@xml:id = 't1']/text()}</title>
                <text>{$item//t:div[@type = 'edition']/t:div[@n = $level1]//text()}</text>
                
                {
                    if (number($level1) > 1)
                    then
                        <previous>http://betamasaheft.aai.uni-hamburg.de/api/xml/{$id}/{number($level1) - 1}</previous>
                    else
                        ()
                }
                
                {
                    if (number($level1) = count($item//t:div[@type = 'edition']/t:div))
                    then
                        ()
                    else
                        if ($item//t:div[@type = 'edition']/t:div[@n = (number($level1) + 1)])
                        then
                            <next>http://betamasaheft.aai.uni-hamburg.de/api/xml/{$id}/{number($level1) + 1}</next>
                        else
                            ()
                }
                
                <partofwork>http://betamasaheft.aai.uni-hamburg.de/api/xml/{$id}</partofwork>
                <contains>
                    {
                        for $subtype in $item//t:div[@type = 'edition']/t:div[@subtype]
                        return
                            
                            element {string($subtype/@subtype)} {('http://betamasaheft.aai.uni-hamburg.de/api/xml/' || $id || '/' || $subtype/@n)}
                    }
                </contains>
            </work>
        else
            let $call := 'http://betamasaheft.aai.uni-hamburg.de/api/xml/' || $id || '/' || $level1
            return
                api:noresults($call)
    )
};


(:returns the lines of the first level subdivision

Ex. 2,4

Ex. 2, 4-7

:)
declare
%rest:GET
%rest:path("/BetMas/api/xml/{$id}/{$level1}/{$line}")
%output:method("xml")
function api:get-level1LineXML($id as xs:string, $level1 as xs:string*, $line as xs:string*) {
    ($api:response200XML,
    let $collection := 'works'
    let $item := api:get-tei-rec-by-ID($id)
    
    let $recordid := $item/@xml:id
    let $L1 := $item//t:div[@type = 'edition']/t:div[@n = $level1]
    return
        if (contains($line, '-'))
        then
            <work>
                <id>{data($recordid)}</id>
                <citation>{(api:citation($item) || ' ' || $level1 || ', ' || $line)}</citation>
                <title>{$item//t:titleStmt/t:title[@xml:id = 't1']/text()}</title>
                <text>{
                        for $l in (xs:integer(substring-before($line, '-')) to xs:integer(substring-after($line, '-')))
                        return
                            normalize-space($L1//t:l[@n = $l]//text())
                    }</text>
                {
                    if (number(substring-before($line, '-')) > 1)
                    then
                        <previous>http://betamasaheft.aai.uni-hamburg.de/api/xml/{$id}/{$level1}/{number(substring-before($line, '-')) - 1}</previous>
                    else
                        ()
                }
                {
                    if (number($line) = count($L1//t:l[@n = substring-after($line, '-')]))
                    then
                        ()
                    else
                        if ($L1//t:l[@n = (number(substring-after($line, '-')) + 1)])
                        then
                            <next>http://betamasaheft.aai.uni-hamburg.de/api/xml/{$id}/{$level1}/{number(substring-after($line, '-')) + 1}</next>
                        else
                            ()
                }<partOf>
                    {element {string($L1/@subtype)} {'http://betamasaheft.aai.uni-hamburg.de/api/xml/' || $id || '/' || $level1}}
                    
                    {element {'work'} {'http://betamasaheft.aai.uni-hamburg.de/api/xml/' || $id}}
                
                </partOf>
                <contains>
                    {
                        for $subtype in $L1/t:div[@subtype]
                        return
                            
                            element {string($subtype/@subtype)} {('http://betamasaheft.aai.uni-hamburg.de/api/xml/' || $id || '/' || $subtype/@n)}
                    }
                </contains>
            </work>
        else
            if ($L1//t:l[@n = $line])
            then
                <work>
                    
                    <id>{data($recordid)}</id>
                    <citation>{(api:citation($item) || ' ' || $level1 || ', ' || $line)}</citation>
                    <title>{$item//t:titleStmt/t:title[@xml:id = 't1']/text()}</title>
                    
                    <text>{normalize-space($L1//t:l[@n = $line]//text())}</text>
                    {
                        if (number($line) > 1)
                        then
                            <previous>http://betamasaheft.aai.uni-hamburg.de/api/xml/{$id}/{$level1}/{number($line) - 1}</previous>
                        else
                            ()
                    }
                    {
                        if (number($line) = count($L1//t:l[@n = $line]))
                        then
                            ()
                        else
                            if ($L1//t:l[@n = (number($line) + 1)])
                            then
                                <next>http://betamasaheft.aai.uni-hamburg.de/api/xml/{$id}/{$level1}/{number($line) + 1}</next>
                            else
                                ()
                    }<partOf>
                        {element {string($L1/@subtype)} {'http://betamasaheft.aai.uni-hamburg.de/api/xml/' || $id || '/' || $level1}}
                        
                        {element {'work'} {'http://betamasaheft.aai.uni-hamburg.de/api/xml/' || $id}}
                    
                    </partOf>
                    <contains>
                        {
                            for $subtype in $L1/t:div[@subtype]
                            return
                                
                                element {string($subtype/@subtype)} {('http://betamasaheft.aai.uni-hamburg.de/api/xml/' || $id || '/' || $subtype/@n)}
                        }
                    </contains>
                </work>
            else
                let $call := 'http://betamasaheft.aai.uni-hamburg.de/api/xml/' || $id || '/' || $level1 || '/' || $line
                return
                    api:noresults($call)
    )
};




(:returns the lines of the second level of subdivision (subchapters)

XXX. 1 2,4

XXX. 1 2, 4-7

:)


declare
%rest:GET
%rest:path("/BetMas/api/xml/{$id}/{$level1}/{$level2}/{$line}")
%output:method("xml")
function api:get-level2lineXML($id as xs:string, $level1 as xs:string*, $level2 as xs:string*, $line as xs:string*) {
    ($api:response200XML,
    let $collection := 'works'
    let $item := api:get-tei-rec-by-ID($id)
    let $recordid := $item/@xml:id
    let $L1 := $item//t:div[@type = 'edition']/t:div[@n = $level1]
    let $L2 := $L1/t:div[@n = $level2]
    
    return
        if (contains($line, '-'))
        then
            <work>
                <id>{data($recordid)}</id>
                <citation>{(api:citation($item) || ' ' || $level2 || ', ' || $line)}</citation>
                <title>{$item//t:titleStmt/t:title[@xml:id = 't1']/text()}</title>
                <text>{
                        for $l in (xs:integer(substring-before($line, '-')) to xs:integer(substring-after($line, '-')))
                        return
                            normalize-space($L2//t:l[@n = $l]//text())
                    }</text>
                {
                    if (number(substring-before($line, '-')) > 1)
                    then
                        <previous>http://betamasaheft.aai.uni-hamburg.de/api/xml/{$id}/{$level1}/{$level2}/{number(substring-before($line, '-')) - 1}</previous>
                    else
                        ()
                }
                {
                    if (number($line) = count($L2//t:l[@n = substring-after($line, '-')]))
                    then
                        ()
                    else
                        if ($L2//t:l[@n = (number(substring-after($line, '-')) + 1)])
                        then
                            <next>http://betamasaheft.aai.uni-hamburg.de/api/xml/{$id}/{$level1}/{$level2}/{number(substring-after($line, '-')) + 1}</next>
                        else
                            ()
                }<partOf>
                    
                    {element {string($L2/@subtype)} {'http://betamasaheft.aai.uni-hamburg.de/api/xml/' || $id || '/' || $level1 || '/' || $level2}}
                    {element {string($L1/@subtype)} {'http://betamasaheft.aai.uni-hamburg.de/api/xml/' || $id || '/' || $level1}}
                    
                    {element {'work'} {'http://betamasaheft.aai.uni-hamburg.de/api/xml/' || $id}}
                
                </partOf>
                <contains>
                    {
                        for $subtype in $L2/t:div[@subtype]
                        return
                            
                            element {string($subtype/@subtype)} {('http://betamasaheft.aai.uni-hamburg.de/api/xml/' || $id || '/' || $subtype/@n)}
                    }
                </contains>
            
            </work>
        else
            if ($item//t:div[@type = 'edition']/t:div[@n = $level1]/t:div[@n = $level2]//t:*[@n = $line])
            then
                <work>
                    
                    <id>{data($recordid)}</id>
                    <citation>{(api:citation($item) || ' ' || $level1 || ' ' || $level2 || ', ' || $line)}</citation>
                    <title>{$item//t:titleStmt/t:title[@xml:id = 't1']/text()}</title>
                    
                    <text>{normalize-space($L2//t:l[@n = $line]//text())}</text>
                    {
                        if (number($line) > 1)
                        then
                            <previous>http://betamasaheft.aai.uni-hamburg.de/api/xml/{$id}/{$level1}/{$level2}/{number($line) - 1}</previous>
                        else
                            ()
                    }
                    {
                        if (number($line) = count($L2//t:l[@n = $line]))
                        then
                            ()
                        else
                            if ($L2//t:l[@n = (number($line) + 1)])
                            then
                                <next>http://betamasaheft.aai.uni-hamburg.de/api/xml/{$id}/{$level1}/{$level2}/{number($line) + 1}</next>
                            else
                                ()
                    }<partOf>
                        
                        {element {string($L2/@subtype)} {'http://betamasaheft.aai.uni-hamburg.de/api/xml/' || $id || '/' || $level1 || '/' || $level2}}
                        {element {string($L1/@subtype)} {'http://betamasaheft.aai.uni-hamburg.de/api/xml/' || $id || '/' || $level1}}
                        
                        {element {'work'} {'http://betamasaheft.aai.uni-hamburg.de/api/xml/' || $id}}
                    
                    </partOf>
                    <contains>
                        {
                            for $subtype in $L2/t:div[@subtype]
                            return
                                
                                element {string($subtype/@subtype)} {('http://betamasaheft.aai.uni-hamburg.de/api/xml/' || $id || '/' || $subtype/@n)}
                        }
                    </contains>
                
                </work>
            else
                let $call := 'http://betamasaheft.aai.uni-hamburg.de/api/xml/' || $id || '/' || $level1 || '/' || $level2 || '/' || $line
                return
                    api:noresults($call)
    )
};


declare
%rest:GET
%rest:path("/BetMas/api/{$id}/tei")
%output:media-type("text/xml")
%output:method("xml")
function api:get-tei-by-ID($id as xs:string) {
    
        ($api:response200XML,
        api:get-tei-rec-by-ID($id)
        )
};

declare
%rest:GET
%rest:path("/BetMas/api/{$id}/json")
%output:method("json")
function api:get-tei2json-by-ID($id as xs:string) {
    
        ($api:response200Json,
        <json:value>{api:get-tei-rec-by-ID($id)}</json:value>
        )
};


(:api CDMI :)

declare
%rest:GET
%rest:path("/BetMas/api/cdmi")
%rest:query-param("id", "{$id}", "")
%output:media-type("text/xml")
%output:method("xml")
function api:get-cdmi($id as xs:string*) {
    ($api:response200XML,
    
    <cmd:CMD
        xmlns:cmd="http://www.clarin.eu/cmd/"
        xmlns:dcr="http://www.isocat.org/ns/dcr"
        xmlns:ann="http://www.clarin.eu"
        xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
        xsi:schemaLocation="http://www.clarin.eu/cmd/ file:/Users/pietro/Desktop/TextCorpusProfile.xsd"
        CMDVersion="1.1">
        <cmd:Header>
            <cmd:MdCreator>Beta maṣāḥǝft: Manuscripts of Ethiopia and Eritrea</cmd:MdCreator>
            <cmd:MdCreationDate>{current-date()}</cmd:MdCreationDate>
            <cmd:MdSelfLink>http://betamasaheft.aai.uni-hamburg.de/</cmd:MdSelfLink>
            <cmd:MdCollectionDisplayName>ERC Advanced Grant TraCES (Grant Agreement 338756)</cmd:MdCollectionDisplayName>
        </cmd:Header>
        <cmd:Components>
            <cmd:TextCorpusProfile>
                <cmd:GeneralInfo
                    ComponentId="clarin.eu:cr1:c_1422885449330"
                    ref="">
                    <cmd:Name
                        xml:lang="en">TraCES</cmd:Name>
                    <cmd:Title
                        xml:lang="en">From Translation to Creation: Changes in Ethiopic Style and Lexicon from Late Antiquity to the Middle Ages</cmd:Title>
                    <cmd:Description
                        xml:lang="en">An area of ancient written culture from the first millennium BCE, the Ethiopian highlands have been home to a complex literary tradition (predominantly in Ge‘ez) that has no parallel in sub-Saharan Africa. Its emergence was determined by Late Antique culture (Byzantium including Egypt, Pales-tine, Syria, and the Red Sea), Mediterranean cultural encounters, and the African background. The earliest known texts were translations from Greek, later works were adopted from Christian Arabic (esp. Copto-Arabic) literary tradition, in addition to a rich local written production. The complexity of literary history is fully reflected in the changes in grammar, lexicon and stylistic means of the Ge‘ez language. TraCES will for the first time analyze in detail the lexical, morphological and sty-listic features of texts depending on their origins using the achievements of linguistics, philology, and digital humanities. An annotated digital text corpus of critically established texts will be cre-ated. Frequency and collocation analysis will reveal changes in grammatical and lexical choices across centuries. Novel ways of visualization of textual features and intertextual relationships will be offered to provide insights into the structure, history and evolution of texts. The resulting new understanding of the history of the Ge‘ez language and of the Ethiopian creativity and literary activity will help establish features and criteria that may be helpful in determining the origins of texts when the direct ‘Vorlage’ is missing. The literary transmission and dissemination processes will be analyzed by contrasting and connecting Ethiopian Late Antique and medieval heritage with its parallels and antecedents in Near East and Mediterranean, contributing to our understanding of the cultural networks of the Christian Orient. A number of valuable research tools will emerge as by-products of the project.</cmd:Description>
                    <cmd:Keyword
                        xml:lang="en">Ge‘ez, Ethiopic, Literature</cmd:Keyword>
                    <cmd:Creators
                        ComponentId="clarin.eu:cr1:c_1271859438134"
                        ref=""
                        xmlns:cmd="http://www.clarin.eu/cmd/">
                        
                        <cmd:Description
                            ComponentId="clarin.eu:cr1:c_1271859438118"
                            ref=""
                            xmlns:cmd="http://www.clarin.eu/cmd/">
                            <cmd:Description
                                xml:lang="en"
                                LanguageID="">Alessandro Bausi</cmd:Description>
                        </cmd:Description>
                        <cmd:Creator
                            ComponentId="clarin.eu:cr1:c_1271859438129"
                            ref=""
                            xmlns:cmd="http://www.clarin.eu/cmd/">
                            <cmd:Role
                                xml:lang="">Principal Investigator</cmd:Role>
                            <cmd:Contact
                                ComponentId="clarin.eu:cr1:c_1271859438113"
                                ref=""
                                xmlns:cmd="http://www.clarin.eu/cmd/">
                                <cmd:Email>alessandro.bausi@uni-hamburg.de</cmd:Email>
                                <cmd:Organisation
                                    xml:lang="de">UNIVERSITAET HAMBURG</cmd:Organisation>
                                <cmd:Telephone>+49 40 42838 9074</cmd:Telephone>
                            </cmd:Contact>
                        </cmd:Creator>
                    </cmd:Creators>
                    <cmd:Contributors
                        ComponentId="clarin.eu:cr1:c_1422885449340"
                        ref="">
                        <cmd:Contributor
                            Role="lead">Alessandro Bausi</cmd:Contributor>
                        <cmd:Contributor
                            Role="manager">Eugenia Sokolinski</cmd:Contributor>
                        <cmd:Contributor
                            Role="editor">Vitagrazia Pisani</cmd:Contributor>
                        <cmd:Contributor
                            Role="editor">Wolfgang Dickhut</cmd:Contributor>
                        <cmd:Contributor
                            Role="editor">Daria Elagina</cmd:Contributor>
                        <cmd:Contributor
                            Role="editor">Andreas Ellwardt</cmd:Contributor>
                        <cmd:Contributor
                            Role="editor">Hiruie Ermias</cmd:Contributor>
                        <cmd:Contributor
                            Role="editor">Susanne Hummel</cmd:Contributor>
                        <cmd:Contributor
                            Role="IT">Cristina Vertan</cmd:Contributor>
                    
                    </cmd:Contributors>
                </cmd:GeneralInfo>
                <cmd:CorpusInfo
                    ComponentId="clarin.eu:cr1:c_1422885449333"
                    ref="">
                    <cmd:CorpusContext
                        ComponentId="clarin.eu:cr1:c_1290431694491"
                        ref=""
                        xmlns:cmd="http://www.clarin.eu/cmd/">
                        <cmd:CorpusType>specialised corpus</cmd:CorpusType>
                        <cmd:TemporalClassification>diachronic</cmd:TemporalClassification>
                        <cmd:Descriptions
                            ComponentId="clarin.eu:cr1:c_1290431694486"
                            ref=""
                            xmlns:cmd="http://www.clarin.eu/cmd/">
                            <cmd:Description
                                xml:lang="en"
                                type="simple">Annotated Texts</cmd:Description>
                        </cmd:Descriptions>
                    </cmd:CorpusContext>
                    <cmd:Coverage
                        ComponentId="clarin.eu:cr1:c_1422885449339"
                        ref=""
                        xmlns:cmd="http://www.clarin.eu/cmd/">
                        <cmd:TimeCoverage>Late Antiquity to the Middle Ages</cmd:TimeCoverage>
                        <cmd:Location
                            ComponentId="clarin.eu:cr1:c_1271859438112"
                            ref=""
                            xmlns:cmd="http://www.clarin.eu/cmd/">
                            <cmd:Address>Alsterterrasse 1</cmd:Address>
                            <cmd:Region>Hamburg</cmd:Region>
                            <cmd:Country
                                ComponentId="clarin.eu:cr1:c_1271859438104"
                                ref=""
                                xmlns:cmd="http://www.clarin.eu/cmd/">
                                <cmd:Code>DE</cmd:Code>
                            </cmd:Country>
                            <cmd:Continent
                                ComponentId="clarin.eu:cr1:c_1271859438105"
                                ref=""
                                xmlns:cmd="http://www.clarin.eu/cmd/">
                                <cmd:Code>EU</cmd:Code>
                            </cmd:Continent>
                        </cmd:Location>
                        
                        <cmd:GeoLocalization
                            ComponentId="clarin.eu:cr1:c_1361876010667"
                            ref=""
                            xmlns:cmd="http://www.clarin.eu/cmd/">
                            <cmd:Vertex
                                ref=""
                                xmlns:cmd="http://www.clarin.eu/cmd/">
                                <cmd:Latitude>53.5623874</cmd:Latitude>
                                <cmd:Longitude>9.9918637</cmd:Longitude>
                            </cmd:Vertex>
                        </cmd:GeoLocalization>
                        <cmd:dc-coverage
                            ComponentId="clarin.eu:cr1:c_1271859438215"
                            ref=""
                            xmlns:cmd="http://www.clarin.eu/cmd/">
                            <cmd:coverage>Ethiopic Literature</cmd:coverage>
                        </cmd:dc-coverage>
                    </cmd:Coverage>
                    
                    <cmd:Multilinguality
                        ComponentId="clarin.eu:cr1:c_1271859438121"
                        ref=""
                        xmlns:cmd="http://www.clarin.eu/cmd/">
                        <cmd:Multilinguality>Monolingual</cmd:Multilinguality>
                    </cmd:Multilinguality>
                    <cmd:Content
                        ComponentId="clarin.eu:cr1:c_1422885449347"
                        ref=""
                        xmlns:cmd="http://www.clarin.eu/cmd/">
                        <cmd:Descriptions
                            ComponentId="clarin.eu:cr1:c_1290431694486"
                            ref=""
                            xmlns:cmd="http://www.clarin.eu/cmd/">
                            {
                                for $i in $id
                                return
                                    let $item := api:get-tei-rec-by-ID($i)
                                    let $name := $item//t:title[@xml:id = 't1']
                                    return
                                        <cmd:Description
                                            xml:lang="en"
                                            type="simple">
                                            {string($name)}</cmd:Description>
                            }
                        
                        </cmd:Descriptions>
                    </cmd:Content>
                
                </cmd:CorpusInfo>
                
                <cmd:TextCorpusInfo
                    ComponentId="clarin.eu:cr1:c_1422885449345"
                    ref=""
                    xmlns:cmd="http://www.clarin.eu/cmd/">
                    <cmd:SourceType
                        xml:lang="">GETA annotation tool</cmd:SourceType>
                    <cmd:TextTechnical
                        ComponentId="clarin.eu:cr1:c_1290431694512"
                        ref="">...</cmd:TextTechnical>
                    <cmd:Descriptions
                        ComponentId="clarin.eu:cr1:c_1290431694486"
                        ref="">
                        <cmd:Description
                            xml:lang="en"
                            type="simple">....</cmd:Description>
                    </cmd:Descriptions>
                </cmd:TextCorpusInfo>
                <cmd:Keys
                    ComponentId="clarin.eu:cr1:c_1302702320447"
                    ref="">
                    <cmd:key
                        name="ethiopic"/>
                    <cmd:key
                        name="literature"/>
                    <cmd:key
                        name="morphological"/>
                </cmd:Keys>
                <cmd:Documentation
                    ComponentId="clarin.eu:cr1:c_1342181139641"
                    ref=""
                    xmlns:cmd="http://www.clarin.eu/cmd/">
                    <cmd:DocumentationType
                        xml:lang="">...</cmd:DocumentationType>
                    <cmd:FileName
                        xml:lang="">...</cmd:FileName>
                    <cmd:Url>...</cmd:Url>
                    <cmd:Descriptions
                        ComponentId="clarin.eu:cr1:c_1290431694486"
                        ref="">
                        <cmd:Description
                            xml:lang="en"
                            type="simple">....</cmd:Description>
                    </cmd:Descriptions>
                </cmd:Documentation>
                <cmd:BibliographicCitations
                    ComponentId="clarin.eu:cr1:c_1422885449335"
                    ref=""> .... </cmd:BibliographicCitations>
            </cmd:TextCorpusProfile>
        
        </cmd:Components>
    </cmd:CMD>
    )
};


declare
%rest:GET
%rest:path("/BetMas/api/{$id}/title")
%output:method("text")
function api:get-FormattedTitle($id as xs:string) {
    ($api:response200,
    titles:printTitleID($id)
    
    )
};

declare
%rest:GET
%rest:path("/BetMas/api/{$id}/{$SUBid}/title")
%output:method("text")
function api:get-FormattedTitleandID($id as xs:string, $SUBid as xs:string) {
    ($api:response200, 
    let $resource := api:get-tei-rec-by-ID($id)
    return
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
    let $m := titles:printTitleID($id) 
    let $s := titles:printSubtitle($resource, $SUBid)
    return
        (:    apply general rules for titles of records:)
        ($m, ', ', $s)
    )
};



(:~
 : Returns tei record
:)
declare function api:get-tei-rec($collection as xs:string, $id as xs:string) as node()* {
    let $uri := concat($config:data-root, '/', $collection, '/', $id, '.xml')
    return
        doc($uri)
};

declare function api:get-tei-rec-by-ID($id as xs:string) as node()* {
    collection($config:data-root)//id($id)
};



(:a test export of pelagios annotations. not suitable for the complete data set, but parametrizable to filter a more reasonable dataset.:)
declare 
%rest:GET
%rest:path("/BetMas/api/pelagios/places/all")
%output:method("text")
function api:placesttl() {
let $data := subsequence(collection('/db/apps/OEDUc/data/'), 1, 20)
return
($api:response200, '
        @prefix cnt: &lt;http://www.w3.org/2011/content#&gt; . 
        @prefix dcterms: &lt;http://purl.org/dc/terms/&gt; .
        @prefix foaf: &lt;http://xmlns.com/foaf/0.1/&gt; .
        @prefix oa: &lt;http://www.w3.org/ns/oa#&gt; .
        @prefix pelagios: &lt;http://pelagios.github.io/vocab/terms#&gt; .
        @prefix relations: &lt;http://pelagios.github.io/vocab/relations#&gt; .
        @prefix xsd: &lt;http://www.w3.org/2001/XMLSchema&gt; .',
for $d in $data return transform:transform($d, 'xmldb:exist:///db/apps/OEDUc/xslt/pelagios.xsl', ()))
};

declare 
%rest:GET
%rest:path("/BetMas/api/pelagios/places/all/void")
%output:method("text")
function api:voidttl() {
$api:response200, 
        '
@prefix : &lt;http://betamasaheft.aai.uni-hamburg.de:8080/exist/apps/BetMas&gt; .
        @prefix void: &lt;http://rdfs.org/ns/void#&gt; .
        @prefix dcterms: &lt;http://purl.org/dc/terms/&gt; .
        @prefix foaf: &lt;http://xmlns.com/foaf/0.1/&gt; .
        
        :"Beta maṣāḥǝft: Manuscripts of Ethiopia and Eritrea (Schriftkultur des christlichen Äthiopiens: eine multimediale Forschungsumgebung) " a void:Dataset;
        dcterms:title "Beta maṣāḥǝft: Manuscripts of Ethiopia and Eritrea (Schriftkultur des christlichen Äthiopiens: eine multimediale Forschungsumgebung) ";
        dcterms:publisher "Academies Programme (coordinated by the Union of the German Academies of Sciences and Humanities)";
        foaf:homepage &lt;http://betamasaheft.aai.uni-hamburg.de:8080/exist/apps/OEDUc/index.html&gt;;
        dcterms:description "a test app bringing together resources from the workshop held on 15 May 2017 in London";
        dcterms:license &lt;http://opendatacommons.org/licenses/odbl/1.0/&gt;;
        void:dataDump &lt;http://betamasaheft.aai.uni-hamburg.de/api/OEDUc/places/all&gt; ;
        .'};

(:this is the feedback in case no result is found:)
declare function api:noresults($call) {
    <html
        xmlns="http://www.w3.org/1999/xhtml">
        <head></head>
        <body>
            <h1>No results for {$call}, sorry!</h1>
            <br/>
            <p>Trouble shooting:
                <ul>
                    <li>The api documentation is <a
                            href="http://betamasaheft.aai.uni-hamburg.de/apidoc.html">here.</a></li>
                    <li>Check the correct id exists <a
                            href="http://betamasaheft.aai.uni-hamburg.de/works/">here.</a></li>
                    <li>Your requested uri should look something like this
                        <blockquote>http://betamasaheft.aai.uni-hamburg.de/api/xml/{{id}}/{{level}}/{{level2}}/{{line}}</blockquote>
                        <blockquote>http://betamasaheft.aai.uni-hamburg.de/api/xml/LIT1367Exodus/2/4</blockquote>
                        <blockquote>http://betamasaheft.aai.uni-hamburg.de/api/xml/LIT1367Exodus/2/4-7</blockquote>
                        if not, see above! The first example will not work, the second and third will.
                        Why: if you ask for an extra level of structure which we don't have, you will not get results.</li>
                </ul>
            </p>
        </body>
    </html>
};
