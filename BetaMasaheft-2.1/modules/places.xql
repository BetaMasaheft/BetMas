xquery version "3.1" encoding "UTF-8";

module namespace places = "https://www.betamasaheft.uni-hamburg.de/BetMas/places";
import module namespace api="https://www.betamasaheft.uni-hamburg.de/BetMas/api" at "rest.xql";
import module namespace titles="https://www.betamasaheft.uni-hamburg.de/BetMas/titles" at "titles.xqm";
import module namespace all="https://www.betamasaheft.uni-hamburg.de/BetMas/all" at "all.xqm";
import module namespace config = "https://www.betamasaheft.uni-hamburg.de/BetMas/config" at "config.xqm";
import module namespace console = "http://exist-db.org/xquery/console";
import module namespace kwic = "http://exist-db.org/xquery/kwic"
    at "resource:org/exist/xquery/lib/kwic.xql";
  
import module namespace error = "https://www.betamasaheft.uni-hamburg.de/BetMas/error" at "error.xqm";  
(: namespaces of data used :)
declare namespace t = "http://www.tei-c.org/ns/1.0";
declare namespace dcterms = "http://purl.org/dc/terms";
declare namespace saws = "http://purl.org/saws/ontology";
declare namespace cmd = "http://www.clarin.eu/cmd/";
declare namespace skos = "http://www.w3.org/2004/02/skos/core#";
declare namespace rdf = "http://www.w3.org/1999/02/22-rdf-syntax-ns#";
declare namespace s = "http://www.w3.org/2005/xpath-functions";
declare namespace sparql = "http://www.w3.org/2005/sparql-results#";
(: For REST annotations :)
declare namespace rest = "http://exquery.org/ns/restxq";
(:http requests:)

declare namespace http = "http://expath.org/ns/http-client";


declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace json = "http://www.json.org";

declare variable $places:prefixes as xs:string := '
        @prefix cnt: &lt;http://www.w3.org/2011/content#&gt; . 
        @prefix dcterms: &lt;http://purl.org/dc/terms/&gt; .
        @prefix foaf: &lt;http://xmlns.com/foaf/0.1/&gt; .
        @prefix gn: &lt;http://www.geonames.org/&gt; .
        @prefix pleiades: &lt;https://pleiades.stoa.org/&gt; .
        @prefix oa: &lt;http://www.w3.org/ns/oa#&gt; .
        @prefix lawd: <http://lawd.info/ontology/> .
        @prefix pelagios: &lt;http://pelagios.github.io/vocab/terms#&gt; .
        @prefix relations: &lt;http://pelagios.github.io/vocab/relations#&gt; .
        @prefix rdfs: &lt;http://www.w3.org/2000/01/rdf-schema#&gt; .
        @prefix skos: &lt;http://www.w3.org/2004/02/skos/core#&gt; .
        @prefix geo: &lt;http://www.w3.org/2003/01/geo/wgs84_pos#&gt; .
        @prefix xsd: &lt;http://www.w3.org/2001/XMLSchema&gt; .' ;

declare variable $places:response200 := $config:response200;
        
        
declare variable $places:response200xml := $config:response200XML;
        
declare variable $places:response200json := $config:response200Json;

declare variable $places:bmurl := $config:appUrl;


declare function places:JSONfile($item as node(), $id as xs:string){
let $regions := if($item//t:region[@ref])   then  for $region in $item//t:region[@ref] return api:getannotationbody($region/@ref)   else ()
        let $settlements := if($item//t:settlement[@ref]) then for $settl in $item//t:settlement[@ref] return api:getannotationbody($settl/@ref) else ()
        let $connects := ($regions, $settlements, "https://pleiades.stoa.org/places/39274")
        let $creators := for $c in distinct-values($item//t:revisionDesc/t:change[contains(., 'created')]/@who) return map {"name" := api:editorKey($c)}
        let $contributors := for $c in distinct-values($item//t:revisionDesc/t:change/@who) return map {"name" := api:editorKey($c)}
        let $names := for $name in $item//t:placeName return 
            map {"association_certainty": "certain",
                "attested": normalize-space($name/text()[1]),
                "romanized": for $corr in $item//t:placeName[substring-after(@corresp, '#') = $name/@xml:id] return normalize-space($corr/text()[1]),
                "transcription_accuracy": "accurate",
                "transcription_completeness": "complete",
                "uri": if($name/@xml:id) then ($places:bmurl ||'/' || $id || '#' || $name/@xml:id) else ()
                 }
                 let $pt := $item//t:place/@type
          let $types := if(contains($pt, ' ')) then for $t in tokenize($pt, ' ') return normalize-space($t) else string($pt)
        let $bibls := for $b in $item//t:bibl return map {  "reference_type": "evidence",
                "work_uri": concat('https://www.zotero.org/groups/ethiostudies/items/tag/',$b/t:ptr/@target)
                }
                let $title := titles:printTitleID($id)
                let $uri := ($places:bmurl ||'/' || $id)
return 
    
      map {"@context": map {
            "geojson": "http://ld.geojson.org/vocab#",
            "Feature": "geojson:Feature",
            "FeatureCollection": "geojson:FeatureCollection",
            "GeometryCollection": "geojson:GeometryCollection",
            "LineString": "geojson:LineString",
            "MultiLineString": "geojson:MultiLineString",
            "MultiPoint": "geojson:MultiPoint",
            "MultiPolygon": "geojson:MultiPolygon",
            "Point": "geojson:Point",
            "Polygon": "geojson:Polygon",
            "bbox": map {
            "@container": "@list",
            "@id": "geojson:bbox"
            },
            "connectsWith": "_:n8",
            "coordinates": "geojson:coordinates",
            "description": "http://purl.org/dc/terms/description",
            "features": map {
            "@container": "@set",
            "@id": "geojson:features"
            },
            "geometry": "geojson:geometry",
            "id": "@id",
            "link": "_:n6",
            "location_precision": "_:n7",
            "names": "_:n9",
            "properties": "geojson:properties",
            "recent_changes": "_:n10",
            "reprPoint": "_:n11",
            "snippet": "http://purl.org/dc/terms/abstract",
            "title": "http://purl.org/dc/terms/title",
            "type": "@type"
            }, "bbox": [
            normalize-space(api:getCoords($id)),            
            normalize-space(api:getCoords($id))
            ],
            "citation": "Location based on Encyclopaedia Aethiopica, from the Beta maṣāḥǝft: Manuscripts of Ethiopia and Eritrea project",
             "connectsWith": [
            $connects
            ],
            "creators":  $creators,
            "contributors":  $contributors,
            "description" : if ($item//t:desc[@type='foundation']) then normalize-space($item//t:desc[@type='foundation']) else (),
            "details" : if ($item//t:ab[@type='history']) then normalize-space($item//t:ab[@type='history']) else (),
             "features": [
            map {
            "geometry": map {    
                "coordinates": normalize-space(api:getCoords($id)),
                "type": "Point"
                },
            "id": $id,
            "properties": map {
            "description": "Location based on Encyclopaedia Aethiopica",
            "link": $uri,
            "location_precision": "precise",
            "snippet": if ($item//t:ab[@type='foundation']) then normalize-space($item//t:ab[@type='foundation']) else (),
            "title": $title},
            "type": "Feature"
            }
            ],
            "history": [
            map {
            "comment": "Mapped to Json from TEI xml",
            "modified": current-dateTime(),
            "principal": "pliuzzo"
            }
            ],
            "id" : $id,
            "names": $names,
             "place_types": $types,
             "provenance": "Encyclopedia Aethiopica",
             "references": $bibls,
             "reprPoint": normalize-space(api:getCoords($id)),
              "title": $title, 
              "type": "FeatureCollection",
              "uri": $uri
            }
};

declare 
%rest:GET
%rest:path("/BetMas/api/geoJson/places/{$id}")
%output:method("json")
function places:json($id as xs:string*) {
$places:response200json,
       let $item := collection($config:data-rootPl)//id($id)[name() = 'TEI']
       return
      places:JSONfile($item, $id)
};


declare 
%rest:GET
%rest:path("/BetMas/api/geoJson/institutions")
%rest:query-param("start", "{$start}", 1)
%output:method("json")
function places:alljsonIns($start as xs:integer*) {
$places:response200json,
let $ps := collection( $config:data-rootIn)//t:TEI[descendant::t:place[@sameAs] or descendant::t:place[descendant::t:geo/text()]]

let $places := 

for $item in subsequence($ps, $start, 20)
let $id := string($item/@xml:id)
     return try {places:JSONfile($item, $id)} catch * {map{'info': ('error with' || $id) }}
            return
            map { 'institutions' : $places,
            'total' : count($ps),
            'offset' : 20}
};

declare 
%rest:GET
%rest:path("/BetMas/api/geoJson/places")
%rest:query-param("start", "{$start}", 1)
%output:method("json")
function places:alljsonPl($start as xs:integer*) {
$places:response200json,
let $ps := collection( $config:data-rootPl)//t:TEI[descendant::t:place[@sameAs] or descendant::t:place[descendant::t:geo/text()]]

let $places := 
for $item in subsequence($ps, $start, 100)
let $id := string($item/@xml:id)
     return try {places:JSONfile($item, $id)} catch * {map{'info': ('error with' || $id) }}
            return
            map { 'places' : $places,
            'total' : count($ps),
            'offset' : 100}
};


(:get places mentioned in one item:)
declare 
%rest:GET
%rest:path("/BetMas/api/KML/places/{$id}")
%output:method("xml")
function places:kmlattestation($id as xs:string*) {
$places:response200xml,
       let $items := collection($config:data-root)//id($id)
return 
       places:kmlplacesm($items)
};


(:get for one date all places attestated with a link to it:)
(:does not work TODO need to implement error code for problem with parameter conversion!: exerr:ERROR :)
declare 
%rest:GET
%rest:path("/BetMas/api/KML/date/{$d}")
%output:method("xml")
function places:kmlDateswithPlacesatts($d as xs:date) {
  let $items := (collection('/db/apps/BetMas/data/')//t:date[(@when | @notBefore | @notAfter)[contains(., $d)]][@corresp[contains(., '#P')]], collection('/db/apps/BetMas/data/')//t:creation[(@when | @notBefore | @notAfter)[contains(., $d)]][@corresp[contains(., '#P')]])
return 
     
if($items >= 1)
then(
$places:response200xml,
       <kml>
       {for $place in $items
       return
      places:datePlaceMark($place)
       }
       </kml>
       )
       else <info>Sorry! no date element with date "{$d}" has been found! </info>
};

(:get for one place all its attestations with date:)
declare 
%rest:GET
%rest:path("/BetMas/api/KML/place/{$placeid}")
%output:method("xml")
function places:kmlPlaceAttestation($placeid as xs:string*) {
if(starts-with($placeid, 'LOC') or starts-with($placeid, 'INS') or starts-with($placeid, 'Q') or starts-with($placeid, 'gn:'))
then(
$places:response200xml,
       let $items := collection('/db/apps/BetMas/data/')//t:placeName[@ref = $placeid]
return 
       <kml>
       {for $place in $items
       return
      places:placeMark($place)
       }
       </kml>
       )
       else <info>Sorry! {$placeid} is not a valid id! We use our own place ids, which start with LOC or INS, Q items in Wikidata like Q115, Ethiopia or geonames id in the format gn:000000.</info>
};

(:get all places mentioned in a collection:)
declare 
%rest:GET
%rest:path("/BetMas/api/KML/{$collection}/places")
%output:method("xml")
function places:kmltextALL($collection as xs:string) {

$places:response200xml,
       let $items := collection('/db/apps/BetMas/data/' || $collection ||'/')
return 
      places:kmlplacesm($items)
};

(:get all places mentioned in a collection:)
declare 
%rest:GET
%rest:path("/BetMas/api/KML/{$collection}/origPlaces")
%output:method("xml")
function places:kmltextALLorig($collection as xs:string) {

$places:response200xml,
       let $items := collection('/db/apps/BetMas/data/' || $collection ||'/')
return 
      places:kmlOrigplacesm($items)
};

declare function places:kmlplacesm($items){
<kml>
       {for $place in ($items//t:placeName[@ref])
       return
      places:placeMark($place)
       }
       </kml>
};

declare function places:kmlOrigplacesm($items){
<kml>
       {for $place in distinct-values($items//t:origPlace/t:placeName/@ref)
       return
      places:SimplifiedPlaceMark($place)
       }
       </kml>
};

(:get dates related to places about one item (metadata):)
declare 
%rest:GET
%rest:path("/BetMas/api/KML/datePlace/{$id}")
%output:method("xml")
function places:kmlmetadata($id as xs:string*) {

$places:response200xml,
       let $items := collection('/db/apps/BetMas/data/')//id($id)
return 
       places:kmldataplaces($items)
};



(:get all dates related to places mentioned in a collection:)
declare 
%rest:GET
%rest:path("/BetMas/api/KML/{$collection}/datePlace")
%output:method("xml")
function places:kmlmetadataALL($collection as xs:string) {

$places:response200xml,
       let $items := collection('/db/apps/BetMas/data/' || $collection ||'/')
return 
       places:kmldataplaces($items)
};


declare function places:kmldataplaces($items){
<kml>
       {for $place in ($items//t:date[@when | @notBefore | @notAfter][@corresp[contains(., '#P')]], $items//t:creation[@when | @notBefore | @notAfter][@corresp[contains(., '#P')]])
       return
      places:datePlaceMark($place)
       }
       </kml>
};


declare function places:SimplifiedPlaceMark($place as xs:string){
 let $pId := $place
       return 
(:       if($pRec//t:coord) then:)
       <Placemark>
        <address>{ api:decidePlaceNameSource($pId)}</address>
        <description>a place of origin of manuscripts</description>
        <name>{api:getannotationbody($pId)}</name>
        <Point>
            <coordinates>{if(starts-with($pId, 'INS') or starts-with($pId, 'LOC')) then api:getCoords($pId) else api:getCoords($pId)}</coordinates>
        </Point>
    </Placemark>      
(:handling of when is at the moment nonsensical, as it just takes a maximum. needs to check quality and format the date correctly
see geobrowser data specification:)
    
};


declare function places:placeMark($place as node()){
 let $pId := string($place/@ref)
  let $root := root($place)
       return 
(:       if($pRec//t:coord) then:)
       <Placemark>
        <address>{ api:decidePlaceNameSource($pId)}</address>
        <description>A {$place/name()} in {titles:printTitleID(string($root//t:TEI/@xml:id))}</description>
        <name>{api:getannotationbody($pId)}</name>
        <Point>
            <coordinates>{if(starts-with($pId, 'INS') or starts-with($pId, 'LOC')) then api:getCoords($pId) else api:getCoords($pId)}</coordinates>
        </Point>
        <TimeStamp>
  
            <when>{let $dates := ($place/@when, $place/@notBefore, $place/@notAfter)
            return max($dates)}
             </when>
        </TimeStamp>
    </Placemark>      
(:handling of when is at the moment nonsensical, as it just takes a maximum. needs to check quality and format the date correctly
see geobrowser data specification:)
    
};

declare function places:datePlaceMark($datePlace as node()){
 let $corresp := if(contains($datePlace/@corresp, ' ')) then for $c in tokenize($datePlace/@corresp, ' ') return string($c) else $datePlace/@corresp
 let $pId := substring-after($corresp[starts-with(., '#P')], '#')
 let $root := root($datePlace)
 let $place := $root/id($pId)
 let $pRef := string($place/@ref)
       let $pRec := collection($config:data-rootPl, $config:data-rootIn)//id($pRef)
      
       return 
(:       if($pRec//t:coord) then:)
       <Placemark>
        <address>{api:decidePlaceNameSource($pRef)}</address>
        <description>{$datePlace/name()} of {string($root//t:TEI/@xml:id)}{if($corresp[starts-with(.,'#t')]) then $corresp[starts-with(.,'#t')] else ()}</description>
        <name>{$pRef}</name>
        <Point>
            <coordinates>{api:getCoords($pRef)}</coordinates>
        </Point>
        <TimeStamp>
  
            <when>{let $dates := ($datePlace/@when, $datePlace/@notBefore, $datePlace/@notAfter)
            let $years := for $date in $dates return  substring-before($date, '-')
            return max($years)}
             </when>
        </TimeStamp>
    </Placemark>      
(:handling of when is at the moment nonsensical, as it just takes a maximum. needs to check quality and format the date correctly
see geobrowser data specification:)
    
};


(:a test export of pelagios annotations. not suitable for the complete data set, but parametrizable to filter a more reasonable dataset.:)

declare 
%rest:GET
%rest:path("/BetMas/api/gazetteer")
%rest:query-param("start", "{$start}", 1)
%output:method("text")
function places:placesGazetteer($start as xs:integer*) {
let $data := subsequence(collection($config:data-rootPl, $config:data-rootIn)//t:place, $start,100)
 let $annotations :=
 for $d in $data 
 let $r := root($d)//t:TEI/@xml:id
let $tit := try{titles:printTitleID(string($r))} catch *{root($d)//t:titleStmt/t:title/text()}
 order by $tit
 return
 
 places:annotatedThing($d, $tit, $r)
 

return
($places:response200,
       
               $places:prefixes
        || string-join($annotations//text(), ' ')
)
};

declare 
%rest:GET
%rest:path("/BetMas/api/gazetteer/all")
%output:method("text")
function places:placesGazetteer() {
let $data := collection($config:data-rootPl, $config:data-rootIn)//t:place
 let $annotations :=
 for $d in $data 
 let $r := root($d)//t:TEI/@xml:id
let $tit := try{titles:printTitleID(string($r))} catch *{root($d)//t:titleStmt/t:title/text()}
 order by $tit
 return
 
 places:annotatedThing($d, $tit, $r)
 

return
($places:response200,
       
               $places:prefixes
        || string-join($annotations//text(), ' ')
)
};

declare 
%rest:GET
%rest:path("/BetMas/api/gazetteer/place/{$id}")
%output:method("text")
function places:placesGazetteerOneplace($id as xs:string*) {
let $data := collection($config:data-rootPl, $config:data-rootIn)//t:TEI/id($id)//t:place
return
if ($data) then
let $tit := titles:printTitleID($id)
let $annotations :=
places:annotatedThing($data, $tit, $id)
return
($places:response200,
       $places:prefixes|| string-join($annotations//text(), ' ')
)
else ('Sorry, the item you have requested does not exist in our places and repositories collections.')
};


declare function places:annotatedThing($node, $tit, $id){
let $d := $node
let $r := $id
let $lang := if($d/t:placeName[.= $tit[1]]/@xml:lang) then '@' || $d/t:placeName[.= $tit[1]]/@xml:lang else ()
let $temporal := if($d//t:state[@type='existence'][@from or @to]) then for $existence in $d//t:state[@type='existence'][@from or @to] return let $from := string($existence/@from) let $to := string($existence/@to) return ('dcterms:temporal "' ||$from||'/'||$to||'";
 ') else ()
let $PeriodO := if($d//t:state[@type='existence'][@ref]) then for $periodExistence in  $d//t:state[@type='existence'][@ref]  let $periodid := string($periodExistence/@ref) let $period := collection($config:data-root)//id($periodid) return ('dcterms:temporal <' || string($period//t:sourceDesc//t:ref/@target)|| '>;
 ') else ()
let $sameAs := if($d//@sameAs) then
' skos:exactMatch <' || api:getannotationbody($d//@sameAs) ||'> ;
'else ()
let $names := for $name in $d/t:placeName
let $l := if($name/@xml:lang) then '@' || string($name/@xml:lang) else ()
return 
if($name/@xml:id = 'n1') 
then '
lawd:hasName [ lawd:primaryForm "'||$name||'"' ||$l|| ' ];'
else '
lawd:hasName [ lawd:variantForm "'||$name||'"' ||$l|| ' ];'

let $partof := if($d/t:settlement[@ref]) then let $setts := for $s in $d/t:settlement/@ref return 'dcterms:isPartOf <' || api:getannotationbody($s) || '>; 
'  return string-join($setts, ' 
')
else if ($d/t:region[@ref]) then let $regs := for $s in $d/t:region/@ref return 'dcterms:isPartOf <' || api:getannotationbody($s ) || '>;
'  return string-join($regs, ' 
')
else if ($d/t:country[@ref]) then let $countries := for $s in $d/t:country/@ref return  'dcterms:isPartOf <' || api:getannotationbody($s) || '>;
'  return string-join($countries, ' 
')
else ()
let $geo := if($d//t:geo/text()) then '
geo:location [ geo:lat '||substring-before($d//t:geo/text(), ' ')|| ' ;  geo:long '||substring-after($d//t:geo/text(), ' ')|| ' ] ;' else if($d//@sameAs) then let $geoid := string($d//@sameAs) let $coordinates := api:GNorWD($geoid)  return '
geo:location [ geo:lat '||substring-before($coordinates, ',')|| ' ;  geo:long '||substring-after($coordinates, ',')|| ' ] ;' else ()
        
 return
 
 <annotatedThing id="{$r}">
 
             {'
             
             &lt;'||$config:appUrl || '/places/'||
 string($r)||'&gt; a lawd:Place ;
  rdfs:label "' || 
 $tit[1] || '"' ||$lang ||';
 dcterms:description "A place in Ethiopia"@en ;
 '||string-join($temporal, '
') ||string-join($PeriodO, '
') ||$sameAs ||string-join($names, ' 
 ')||
 $geo||
 ' 
 foaf:primaryTopicOf &lt;'||$config:appUrl || '/places/' || 
                string($r) || '&gt; ;
                ' ||
                $partof
                ||'
                .
                
                '}
   
   
 </annotatedThing>
 
 (: this should go into the <annotatedThing/> but I am not sure how to do it... 

<annotations>
 {for $thisd at $x in collection($config:data-rootW, $config:data-rootMS)//t:placeName[@ref = $r]
 return
 <annotation>{
' <http://betamasaheft.aai.uni-hamburg.de/att/'||$x||'> a lawd:Attestation ;
  dcterms:publisher <http://betamasaheft.aai.uni-hamburg.de/places/list/> ;
  cito:citesAsEvidence
    <http://www.mygazetteer.org/documents/01234> ;
  cnt:chars "Αθήνα" 
  .
 '
 }
 </annotation>
 }
 </annotations>:)
};



declare function places:annotation($this, $r, $x, $mode){
 <annotation>{
 '
 &lt;'||$config:appUrl || '/api/placeNames/'||$mode||'/all#'||
  string($r) || 
  '/annotations/'||
  string($x)||
  '&gt;
                a oa:Annotation ;
                oa:hasTarget &lt;'||$config:appUrl || '/api/placeNames/'||$mode||'/all#' ||
                string($r)|| '&gt; ;
                oa:hasBody &lt;' || api:getannotationbody(string($this/@ref)) || '&gt; ;
                oa:annotatedAt "' ||current-dateTime()||  '"^^xsd:date ;
                
                .
                '
 }
 </annotation>
};

declare function places:ThisAnnotatedThing($r, $tit, $mode as xs:string){

 
             '
             
             &lt;'||$config:appUrl || '/api/placeNames/'||$mode||'/all#'||
 string($r)||'&gt;
 a pelagios:AnnotatedThing ;
 dcterms:description "' || 
 (if($r//t:abstract) 
 then $r//t:abastract else ('no description')) || '";
 dcterms:source &lt;'||$config:appUrl || '/tei/' || 
                string($r) || '.xml&gt;' || ';
  dcterms:title "' || 
 $tit || '";
 foaf:homepage' ||
                '&lt;'||$config:appUrl || '/'||$mode||'/' || 
                string($r) || '&gt; ;
                dcterms:language "' ||
                $r/parent::t:TEI/@xml:lang||'";
                .
                
                '
   
};

declare 
%rest:GET
%rest:path("/BetMas/api/placeNames/works/all")
%rest:query-param("start", "{$start}", 1)
%output:method("text")
function places:placesInWorksTTL($start as xs:integer*) {
let $data := subsequence(collection($config:data-rootW)//t:placeName[@ref], $start, 100)
 let $annotations :=
 for $d in $data 
 group by $r := root($d)//t:TEI/@xml:id
let $tit := titles:printTitleID(string($r))
 order by $r
 return
 
 <annotatedThing id="{$r}">
 
             {places:ThisAnnotatedThing($r, $tit, 'works')}
   
   <annotations>
 {for $thisd at $x in $d
 return
 places:annotation($thisd, $r, $x, 'works')
 }
 </annotations>
 </annotatedThing>

return
($places:response200,
       $places:prefixes
        || string-join($annotations//text(), ' ')
)
};



declare 
%rest:GET
%rest:path("/BetMas/api/placeNames/manuscripts/all")
%rest:query-param("start", "{$start}", 1)
%output:method("text")
function places:placesInManuscriptsTTL($start as xs:integer*) {
let $data := subsequence(collection($config:data-rootMS)//t:placeName[@ref], $start, 100)
 let $annotations :=
 for $d in $data 
 group by $r := root($d)//t:TEI/@xml:id
let $tit := titles:printTitleID(string($r))
 order by $r
 return
 
 <annotatedThing id="{$r}">
 
            
             {places:ThisAnnotatedThing($r, $tit, 'manuscripts')}
   
   <annotations>
 {for $thisd at $x in $d
 return
 places:annotation($thisd, $r, $x, 'manuscripts')
 }
 </annotations>
 </annotatedThing>

return
($places:response200,
       $places:prefixes
        || string-join($annotations//text(), ' ')
)
};



declare 
%rest:GET
%rest:path("/BetMas/api/placeNames/works/{$id}")
%output:method("text")
function places:placesInOneWorkTTL($id as xs:string) {
let $file := collection($config:data-rootW)//id($id)
let $sid :=  string($id)
return
if($file) then
let $data := $file//t:placeName[@ref]
let $abstract := if($file//t:abstract) then $file//t:abstract else ('no description available')
let $url :=  $config:appUrl|| '/api/placeNames/works/' 
let $baseUrl :=  $config:appUrl||'/api/placeNames/works/' || $id || '#'
 let $annotations :=
let $tit := api:decidePlaceNameSource(string($id))
 return
 
 <annotatedThing id="{$id}">
 
             {'
             
             &lt;'||$url||
 string($id)||'&gt;
 a pelagios:AnnotatedThing ;
  dcterms:title "' || 
 $tit || '";
 dcterms:description "' || 
 $abstract || '";
 dcterms:source &lt;'||$config:appUrl||'/tei/' || 
                $sid || '.xml&gt;' || ';
 foaf:homepage' ||
                '&lt;'||$config:appUrl||'/works/' || 
                $sid || '/main&gt; ;
                dcterms:language "' ||
                string($file/@xml:lang)||'";
                .
                
                '}
   
   <annotations>
 {for $thisd at $x in $data
 return
 <annotation>{
 '
 &lt;'||$url||
  string($id) || 
  '/annotations/'||
  string($x)||
  '&gt;
                a oa:Annotation ;
                oa:hasTarget &lt;' || $url ||
                string($id)|| '&gt; ;
                oa:hasBody &lt;' || api:getannotationbody(string($thisd/@ref)) || '&gt; ;
                oa:annotatedAt "' ||current-dateTime()||  '"^^xsd:date ;
                
                .
                '
 }
 </annotation>
 }
 </annotations>
 </annotatedThing>

return
($places:response200,
       $places:prefixes
        || string-join($annotations//text(), ' ')
)

else ('Sorry, the id you provided is not a valid work record id.')
};

declare 
%rest:GET
%rest:path("/BetMas/api/placeNames/manuscripts/{$id}")
%output:method("text")
function places:placesInOneManuscriptTTL($id as xs:string) {
let $file := collection($config:data-rootMS)//id($id)
let $sid := string($id)
return
if($file) then
let $data := $file//t:placeName[@ref]
let $abstract := if($file//t:abstract) then $file//t:abstract else ('no description available')

let $url :=  $config:appUrl||'/api/placeNames/manuscripts/' 
let $baseUrl := $config:appUrl || 'http://betamasaheft.aai.uni-hamburg.de/api/placeNames/manuscripts/' || $id || '#'
 let $annotations :=
let $tit := api:decidePlaceNameSource(string($id))
 return
 
 <annotatedThing id="{$id}">
 
             {'
             
             &lt;'||$url||
 $sid||'&gt;
 a pelagios:AnnotatedThing ;
  dcterms:title "' || 
 $tit || '";
 dcterms:description "' || 
 $abstract || '";
 dcterms:source &lt;'||$config:appUrl||'/tei/' || 
                $sid || '.xml&gt;' || ';
 foaf:homepage' ||
                '&lt;'||$config:appUrl||'/manuscripts/' || 
                string($id) || '&gt; ;
                dcterms:language "' ||
                string($file/@xml:lang)||'";
                .
                
                '}
   
   <annotations>
 {for $thisd at $x in $data
 return
 <annotation>{
 '
 &lt;'||$url||
  string($id) || 
  '/annotations/'||
  string($x)||
  '&gt;
                a oa:Annotation ;
                oa:hasTarget &lt;' || $url ||
                string($id)|| '&gt; ;
                oa:hasBody &lt;' || api:getannotationbody(string($thisd/@ref)) || '&gt; ;
                oa:annotatedAt "' ||current-dateTime()||  '"^^xsd:date ;
                
                .
                '
 }
 </annotation>
 }
 </annotations>
 </annotatedThing>

return
($places:response200,
       
               $places:prefixes
        || string-join($annotations//text(), ' ')
)

else ('Sorry, the id you provided is not a valid manuscript record id.')
};

declare 
%rest:GET
%rest:path("/BetMas/api/placeNames/works")
%output:method("text")
function places:placesInWorksTTLVoid() {
$places:response200, 
        '
@prefix : &lt;'||$config:appUrl||'&gt; .
        @prefix void: &lt;http://rdfs.org/ns/void#&gt; .
        @prefix dcterms: &lt;http://purl.org/dc/terms/&gt; .
        @prefix foaf: &lt;http://xmlns.com/foaf/0.1/&gt; .
        
        :"RESTXQ export of annotatated places in Beta maṣāḥǝft: Manuscripts of Ethiopia and Eritrea" a void:Dataset;
        dcterms:title "Die Schriftkultur des christlichen Äthiopiens: Eine multimediale Forschungsumgebung / beta maṣāḥǝft";
        dcterms:publisher "Akademie der Wissenschaften in Hamburg";
        dcterms:publisher "Hiob Ludolf Zentrum für Äthiopistik";
        foaf:homepage &lt;'||$config:appUrl||'&gt;;
        dcterms:description "The project Beta maṣāḥǝft: Manuscripts of Ethiopia and Eritrea (Schriftkultur des christlichen 
        Äthiopiens: eine multimediale Forschungsumgebung) is a long-term project funded 
        within the framework of the Academies Programme (coordinated by the Union of the German 
        Academies of Sciences and Humanities) under survey of the Akademie der Wissenschaften in Hamburg. 
        The funding will be provided for 25 years, from 2016–2040. The project is hosted by the Hiob Ludolf 
        Centre for Ethiopian Studies at the University of Hamburg. It aims at creating a virtual research 
        environment that shall manage complex data related to predominantly Christian manuscript 
        tradition of the Ethiopian and Eritrean Highlands.";
        dcterms:license &lt;http://opendatacommons.org/licenses/odbl/1.0/&gt;;
        void:dataDump &lt;'||$config:appUrl||'/api/placeNames/works/all&gt; ;
        void:dataDump &lt;'||$config:appUrl||'/api/placeNames/manuscripts/all&gt; ;
        .'};

