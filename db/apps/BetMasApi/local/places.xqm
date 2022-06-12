xquery version "3.1" encoding "UTF-8";
(:~
 : rest XQ module producing geoJSON and KML versions of the placelike items
 : the controller will redirect to the correct path for this module all requests ending in .json
 : the KML is used by the dariah de Geo Browser
 : @author Pietro Liuzzo 
 :)

module namespace places = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/places";
import module namespace rest = "http://exquery.org/ns/restxq";
import module namespace log="http://www.betamasaheft.eu/log" at "xmldb:exist:///db/apps/BetMasWeb/modules/log.xqm";
import module namespace exptit="https://www.betamasaheft.uni-hamburg.de/BetMasWeb/exptit" at "xmldb:exist:///db/apps/BetMasWeb/modules/exptit.xqm";
import module namespace coord = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/coord" at "xmldb:exist:///db/apps/BetMasWeb/modules/coordinates.xqm";
import module namespace editors="https://www.betamasaheft.uni-hamburg.de/BetMasWeb/editors" at "xmldb:exist:///db/apps/BetMasWeb/modules/editors.xqm";
import module namespace ann = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/ann" at "xmldb:exist:///db/apps/BetMasWeb/modules/annotations.xqm";
import module namespace all="https://www.betamasaheft.uni-hamburg.de/BetMasWeb/all" at "xmldb:exist:///db/apps/BetMasWeb/modules/all.xqm";
import module namespace config = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/config" at "xmldb:exist:///db/apps/BetMasWeb/modules/config.xqm";
import module namespace kwic = "http://exist-db.org/xquery/kwic"
    at "resource:org/exist/xquery/lib/kwic.xql";
import module namespace string = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/string" at "xmldb:exist:///db/apps/BetMasWeb/modules/tei2string.xqm";
import module namespace switch2 = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/switch2" at "xmldb:exist:///db/apps/BetMasWeb/modules/switch2.xqm";   
import module namespace error = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/error" at "xmldb:exist:///db/apps/BetMasWeb/modules/error.xqm";  
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

declare variable $places:placeprefixes as xs:string := '
@prefix cnt: &lt;http://www.w3.org/2011/content#&gt; . 
@prefix dcterms: &lt;http://purl.org/dc/terms/&gt; .
@prefix foaf: &lt;http://xmlns.com/foaf/0.1/&gt; .
@prefix geo: &lt;http://www.w3.org/2003/01/geo/wgs84_pos#&gt; .
@prefix geosparql: &lt;http://www.opengis.net/ont/geosparql#&gt; .
@prefix gn: &lt;http://www.geonames.org/&gt; .
@prefix pleiades: &lt;https://pleiades.stoa.org/&gt; .
@prefix oa: &lt;http://www.w3.org/ns/oa#&gt; .
@prefix lawd: <http://lawd.info/ontology/> .
@prefix pelagios: &lt;http://pelagios.github.io/vocab/terms#&gt; .
@prefix relations: &lt;http://pelagios.github.io/vocab/relations#&gt; .
@prefix rdfs: &lt;http://www.w3.org/2000/01/rdf-schema#&gt; .
@prefix lawd: &lt;http://lawd.info/ontology/&gt; .
@prefix skos: &lt;http://www.w3.org/2004/02/skos/core#&gt; .
@prefix xsd: &lt;http://www.w3.org/2001/XMLSchema&gt; .' ;


declare variable $places:response200 := $config:response200;
        
declare variable $places:response200turtle := <rest:response>
            <http:response
                status="200">
                <http:header
                    name="Content-Type"
                    value="text/turtle; charset=utf-8"/>
                <http:header
                    name="Access-Control-Allow-Origin"
                    value="*"
                    />
            </http:response>
        </rest:response>;

declare variable $places:response200xml := $config:response200XML;
        
declare variable $places:response200json := $config:response200Json;

declare variable $places:bmurl := $config:appUrl;

declare variable $places:collection-rootMS := collection($config:data-rootMS);
declare variable $places:collection-rootW := collection($config:data-rootW);
declare variable $places:collection-rootIn := collection($config:data-rootIn);
declare variable $places:collection-rootPlIn := collection($config:data-rootPl,$config:data-rootIn);
declare variable $places:collection-root := $exptit:col;

declare function places:JSONfile($item as node(), $id as xs:string){
let $regions := if($item//t:region[@ref])   then  for $region in $item//t:region[@ref] return ann:getannotationbody($region/@ref)   else ()
        let $settlements := if($item//t:settlement[@ref]) then for $settl in $item//t:settlement[@ref] return ann:getannotationbody($settl/@ref) else ()
        let $connects := ($regions, $settlements, "https://pleiades.stoa.org/places/39274")
        let $creators := for $c in config:distinct-values($item//t:revisionDesc/t:change[contains(., 'created')]/@who) return map {"name" : editors:editorKey($c)}
        let $contributors := for $c in config:distinct-values($item//t:revisionDesc/t:change/@who) return map {"name" : editors:editorKey($c)}
        let $periods := if($item//t:state) then for $c in $item//t:state[@type eq 'existence']/@ref return exptit:printTitleID($c) else ()
        let $names := for $name in $item//t:place/t:placeName 
        let $nID := $name/@xml:id
        return 
            map {"association_certainty": "certain",
                "attested": normalize-space($name/text()[1]),
                "romanized": for $corr in $item//t:placeName[contains(@corresp,$nID)] return normalize-space($corr/text()[1]),
                "transcription_accuracy": "accurate",
                "transcription_completeness": "complete",
                "uri": if($name/@xml:id) then ($places:bmurl ||'/' || $id || '#' || $name/@xml:id) else ()
                 }
                 let $pt := $item//t:place/@type
          let $types := if(contains($pt, ' ')) then for $t in tokenize($pt, ' ') return normalize-space($t) else string($pt)
        let $bibls := for $b in $item//t:bibl return map {  "reference_type": "evidence",
                "work_uri": concat('https://www.zotero.org/groups/ethiostudies/items/tag/',$b/t:ptr/@target)
                }
                let $title := exptit:printTitleID($id)
                let $uri := ($places:bmurl ||'/' || $id)
                let $coords := 
                if($item//t:geo[@rend eq 'polygon']) then 
                (
                                for $latlng in tokenize($item//t:geo[@rend eq 'polygon'], '\n') 
                                return replace(normalize-space($latlng), ' ', ',') 
                                ) else for $c in tokenize(coord:invertCoord(coord:getCoords($id)), ',') return number($c)
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
            }, "bbox": if(count($coords) gt 2) then for $firstandsecond in subsequence($coords, 1, 2) return (for $c in tokenize($firstandsecond, ',') return number($c)) else ($coords, $coords)
            ,
            "citation": "Location based on Encyclopaedia Aethiopica, from the Beta maṣāḥǝft: Manuscripts of Ethiopia and Eritrea project",
             "connectsWith": [
            $connects
            ],
            "creators":  $creators,
            "contributors":  $contributors,
            "description" : if ($item//t:desc[@type eq 'foundation']) then normalize-space(string-join(string:tei2string($item//t:desc[@type eq 'foundation']), '')) else (),
            "details" : if ($item//t:ab[@type eq 'history']) then normalize-space(string-join(string:tei2string($item//t:ab[@type eq 'history']), '')) else (),
           
            "geometry": map {    
                "coordinates": if ($item//t:geo[@rend eq 'polygon']) then array{ array { for $latlng in $coords return let $array := array {for $c in tokenize($latlng, ',') return number($c)} return $array}} else $coords,
                "type": if ($item//t:geo[@rend eq 'polygon']) then 'Polygon' else 'Point'
                },
            "id": $id,
            "properties": map {
            "description": "Location based on Encyclopaedia Aethiopica",
            "link": $uri,
            "location_precision": "precise",
            "snippet": if ($item//t:ab[@type eq 'foundation']) then normalize-space(string-join(string:tei2string($item//t:ab[@type eq 'foundation']), '')) else (),
            "title": $title},
            "type": "Feature",
           "history": [
            map {
            "comment": "Mapped to Json from TEI xml",
            "modified": current-dateTime(),
            "principal": "pliuzzo"
            }
            ],
            "names": $names,
             "place_types": ($types, $periods),
             "provenance": "Encyclopedia Aethiopica",
             "references": $bibls,
             "reprPoint": if ($item//t:geo[@rend eq 'polygon']) then () else $coords,
              "title": $title, 
              "uri": $uri
            }
};

declare 
%rest:GET
%rest:path("/api/geoJson/places/{$id}")
%output:method("json")
function places:json($id as xs:string*) {
if(starts-with($id, 'LOC') or starts-with($id, 'INS') or starts-with($id, 'ETH')) 
then(
$places:response200json,

let $log := log:add-log-message('/api/geoJson/places/'||$id, sm:id()//sm:real/sm:username/string() , 'places')
       let $item := $places:collection-rootPlIn/id($id)[name() = 'TEI']
       return
      places:JSONfile($item, $id))
       else ()
};


declare 
%rest:GET
%rest:path("/api/geoJson/institutions")
%rest:query-param("start", "{$start}", 1)
%output:method("json")
function places:alljsonIns($start as xs:integer*) {
$places:response200json,

let $log := log:add-log-message('/api/geoJson/institutions/', sm:id()//sm:real/sm:username/string() , 'places')
let $ps := $places:collection-rootIn//t:TEI[descendant::t:place[descendant::t:geo/text() or @sameAs]]

let $places := 

for $item in $ps
let $id := string($item/@xml:id)
     return try {places:JSONfile($item, $id)} catch * {map{'info': ('error with' || $id) }}
            return
            map {"type": "FeatureCollection",
                                                    "features":$places}
};

declare 
%rest:GET
%rest:path("/api/geoJson/places")
%rest:query-param("start", "{$start}", 1)
%output:method("json")
function places:alljsonPl($start as xs:integer*) {
$places:response200json,

let $log := log:add-log-message('/api/geoJson/places/', sm:id()//sm:real/sm:username/string() , 'places')
let $ps := $places:collection-rootPl//t:TEI[descendant::t:place[descendant::t:geo/text() or @sameAs]]
let $places := for $item in $ps
                         let $id := string($item/@xml:id)
                       return 
                       try {places:JSONfile($item, $id)} catch * {($id ||' !error! '||$err:code|| ': ' || $err:description)}
  return
            map {"type": "FeatureCollection",
                    "features":$places}
};


(:get places mentioned in one item:)
declare 
%rest:GET
%rest:path("/api/KML/places/{$id}")
%output:method("xml")
function places:kmlattestation($id as xs:string*) {
$places:response200xml,

let $log := log:add-log-message('/api/KML/places/' || $id, sm:id()//sm:real/sm:username/string() , 'places')
       let $items := $places:collection-root/id($id)
return 
       places:kmlplacesm($items)
};


(:get for one date all places attestated with a link to it:)
(:does not work TODO need to implement error code for problem with parameter conversion!: exerr:ERROR :)
(:declare 
%rest:GET
%rest:path("/api/KML/date/{$d}")
%output:method("xml")
function places:kmlDateswithPlacesatts($d as xs:date) {

let $log := log:add-log-message('/api/KML/date/' || $id, sm:id()//sm:real/sm:username/string() , 'places')
  let $items := ($places:collection-root//t:date[(@when | @notBefore | @notAfter)[contains(., $d)]][@corresp[contains(., '#P')]], $places:collection-root//t:creation[(@when | @notBefore | @notAfter)[contains(., $d)]][@corresp[contains(., '#P')]])
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
};:)

(:get for one place all its attestations with date:)
declare 
%rest:GET
%rest:path("/api/KML/place/{$placeid}")
%output:method("xml")
function places:kmlPlaceAttestation($placeid as xs:string*) {
if(starts-with($placeid, 'LOC') or starts-with($placeid, 'INS') or starts-with($placeid, 'wd:') or starts-with($placeid, 'gn:'))
then(
$places:response200xml,

let $log := log:add-log-message('/api/KML/places/' || $placeid, sm:id()//sm:real/sm:username/string() , 'places')
       let $items := $places:collection-root//t:placeName[@ref eq  $placeid]
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
%rest:path("/api/KML/{$collection}/places")
%output:method("xml")
function places:kmltextALL($collection as xs:string) {

$places:response200xml,

let $log := log:add-log-message('/api/KML/'||$collection||'/places', sm:id()//sm:real/sm:username/string() , 'places')
       let $items := switch2:collectionVar($collection)
return 
      places:kmlplacesm($items)
};

(:get all places mentioned in a collection:)
(:declare 
%rest:GET
%rest:path("/api/KML/{$collection}/origPlaces")
%output:method("xml")
function places:kmltextALLorig($collection as xs:string) {

$places:response200xml,

let $log := log:add-log-message('/api/KML/'||$collection||'/origPlaces', sm:id()//sm:real/sm:username/string() , 'places')
let $col := switch2:collectionVar($collection)
       let $items := $col//t:origPlace[descendant::t:placeName/@ref]
return 
      places:kmlOrigplacesm($items)
};
:)
declare function places:kmlplacesm($items){
<kml>
       {for $place in ($items//t:placeName[@ref])
       return
      places:placeMark($place)
       }
       </kml>
};

(:declare function places:kmlOrigplacesm($items){
<kml>
       {for $place in config:distinct-values($items//t:placeName/@ref)
       return
      places:SimplifiedPlaceMark($place)
       }
       </kml>
};
:)
(:get dates related to places about one item (metadata):)
(:declare 
%rest:GET
%rest:path("/api/KML/datePlace/{$id}")
%output:method("xml")
function places:kmlmetadata($id as xs:string*) {

$places:response200xml,

let $log := log:add-log-message('/api/KML/datePlace/'||$id, sm:id()//sm:real/sm:username/string() , 'places')
       let $items := $places:collection-root/id($id)
return 
       places:kmldataplaces($items)
};
:)


(:get all dates related to places mentioned in a collection:)
(:declare 
%rest:GET
%rest:path("/api/KML/{$collection}/datePlace")
%output:method("xml")
function places:kmlmetadataALL($collection as xs:string) {

$places:response200xml,

let $log := log:add-log-message('/api/KML/'||$collection||'/datePlace', sm:id()//sm:real/sm:username/string() , 'places')
    let $items :=   switch2:collectionVar($collection)

return 
       places:kmldataplaces($items)
};
:)
(:
declare function places:kmldataplaces($items){
<kml>
       {for $place in ($items//t:date[@when | @notBefore | @notAfter][@corresp[contains(., '#P')]], $items//t:creation[@when | @notBefore | @notAfter][@corresp[contains(., '#P')]])
       return
      places:datePlaceMark($place)
       }
       </kml>
};
:)

(:handling of when is at the moment nonsensical, as it just takes a maximum. needs to check quality and format the date correctly
see geobrowser data specification:)
declare function places:SimplifiedPlaceMark($place as xs:string){
       <Placemark>
        <address>{try{exptit:decidePlaceNameSource($place)} catch * {$err:description}}</address>
        <description>a place of origin of manuscripts</description>
        <name>{ann:getannotationbody($place)}</name>
        <Point>{
        let $coordinates := coord:invertCoord(coord:getCoords($place))
        return
            <coordinates>{if(matches($coordinates, '\d+\.?\d*,\d+\.?\d*')) then $coordinates else ()}</coordinates>
            }
        </Point>
    </Placemark>      
    
};


declare function places:decidePlaceNameSource($pRef as xs:string){
if ($exptit:placeNamesList//t:item[@corresp =  $pRef]) 
    then $exptit:placeNamesList//t:item[@corresp = $pRef][1]/text()
else if (starts-with($pRef, 'https://pleiades.stoa.org/places/')) then 
         coord:getPleiadesNames($pRef) 
           
else if (matches($pRef, 'https://www.wikidata.org/entity/Q\d+')) then 
            coord:getwikidataNames($pRef) 
else  

 let $onlyId := substring-after($pRef, 'https://betamasaheft.eu/')
 return
$exptit:col/id($onlyId)//t:title[@type = 'full']/text()
};

declare function places:placeMark($place as node()){
 let $pId := string($place/@ref)
 let $onlyId := substring-after($place/@ref, 'https://betamasaheft.eu/')
  let $root := root($place)
       return 
(:       if($pRec//t:coord) then:)
       <Placemark>
        <address>{ places:decidePlaceNameSource($pId)}</address>
        <description>A {$place/name()} in {exptit:printTitleID(string($root//t:TEI/@xml:id))}</description>
        <name>{ann:getannotationbody($onlyId)}</name>
        <Point>
            <coordinates>{coord:invertCoord(coord:getCoords($pId))}</coordinates>
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
       let $pRec := $places:collection-rootPlIn//id($pRef)
      
       return 
(:       if($pRec//t:coord) then:)
       <Placemark>
        <address>{exptit:decidePlaceNameSource($pRef)}</address>
        <description>{$datePlace/name()} of {string($root//t:TEI/@xml:id)}{if($corresp[starts-with(.,'#t')]) then $corresp[starts-with(.,'#t')] else ()}</description>
        <name>{$pRef}</name>
        <Point>
            <coordinates>{coord:getCoords($pRef)}</coordinates>
        </Point>
        
        {if($datePlace/@when) then (
            <TimeStamp>
  
            <when>{$datePlace/@when}
             </when>
        </TimeStamp>
            ) else <TimeSpan><being>{$datePlace/@notBefore}</being><end>{$datePlace/@notAfter}</end></TimeSpan>}
        
    </Placemark>      
(:handling of when is at the moment nonsensical, as it just takes a maximum. needs to check quality and format the date correctly
see geobrowser data specification:)
    
};


(:a test export of pelagios annotations. not suitable for the complete data set, but parametrizable to filter a more reasonable dataset.:)

declare 
%rest:GET
%rest:path("/api/gazetteer")
%rest:query-param("start", "{$start}", 1)
%output:method("text")
function places:placesGazetteer($start as xs:integer*) {

let $log := log:add-log-message('/api/gazetteer', sm:id()//sm:real/sm:username/string() , 'places')
let $data := subsequence($places:collection-rootPlIn//t:place, $start,100)
 let $annotations :=
 for $d in $data 
 let $r := root($d)//t:TEI/@xml:id
let $tit := try{exptit:printTitleID(string($r))} catch *{root($d)//t:titleStmt/t:title/text()}
 order by $tit
 return
 
 ann:annotatedThing($d, $tit, $r)
 

return
($places:response200turtle,
       
               $places:prefixes
        || string-join($annotations//text(), ' ')
)
};

declare 
%rest:GET
%rest:path("/api/gazetteer/all")
%output:method("text")
function places:placesGazetteer() {

let $log := log:add-log-message('/api/gazetteer/all', sm:id()//sm:real/sm:username/string() , 'places')
let $data := $places:collection-rootPlIn//t:place
 let $annotations :=
 for $d in $data 
 let $r := root($d)//t:TEI/@xml:id
let $tit := try{exptit:printTitleID(string($r))} catch *{root($d)//t:titleStmt/t:title/text()}
 order by $tit
 return
 
 ann:annotatedThing($d, $tit, $r)
 

return
($places:response200turtle,
       
               $places:prefixes
        || string-join($annotations//text(), ' ')
)
};

declare 
%rest:GET
%rest:path("/api/gazetteer/place/{$id}")
%output:method("text")
function places:placesGazetteerOneplace($id as xs:string*) {

let $log := log:add-log-message('/api/gazetteer/place/'||$id, sm:id()//sm:real/sm:username/string() , 'places')
let $data := $places:collection-rootPlIn//t:TEI/id($id)//t:place
return
if ($data) then
let $tit := exptit:printTitleID($id)
let $annotations :=
ann:annotatedThing($data, $tit, $id)
return
($places:response200turtle,
       $places:prefixes|| string-join($annotations//text(), ' ')
)
else ('Sorry, the item you have requested does not exist in our places and repositories collections.')
};






declare function places:annotation($this, $r, $x, $mode){
 <annotation>{
 '
 &lt;'||$config:appUrl || '/'||
  string($r) || 
  '/place/annotation/'||
  string($x)||
  '&gt;
                a oa:Annotation ;
                oa:hasTarget &lt;'||$config:appUrl || '/' ||
                string($r)|| '&gt; ;
                oa:hasBody &lt;' || ann:getannotationbody(string($this/@ref)) || '&gt; ;
                oa:annotatedAt "' ||current-dateTime()||  '"^^xsd:date ;
                
                .
                '
 }
 </annotation>
};

declare function places:ThisAnnotatedThing($r, $tit, $mode as xs:string){

 
             '
             
             &lt;'||$config:appUrl||'/'||
 string($r)||'&gt;
 a pelagios:AnnotatedThing ;
 void:inDataset <https://betamasaheft.eu/api/placeNames/void> ;
 dcterms:description "' || 
 (
 if($mode = 'works') then ('A literary work in the Ethiopian tradition (CAe ' || substring($r, 4, 4) || ').') 
 else if($mode = 'manuscripts') then ('A manuscript part of the Ethiopian literary tradition (' || string($r)|| ').') 
 else () 
 
 ) || '";
 dcterms:source &lt;'||$config:appUrl || '/tei/' || 
                string($r) || '.xml&gt;' || ';
  dcterms:title "' || 
 normalize-space($tit)  || '";
 foaf:homepage ' ||
                '&lt;'||$config:appUrl || '/'||$mode||'/' || 
                string($r) || '/main&gt; ;
                dcterms:language "' ||
                $r/parent::t:TEI/@xml:lang||'";
                .
                
                '
   
};

declare 
%rest:GET
%rest:path("/api/placeNames/works/all")
%rest:query-param("start", "{$start}", 1)
%output:method("text")
function places:placesInWorksTTL($start as xs:integer*) {

let $log := log:add-log-message('/api/placeNames/works/all', sm:id()//sm:real/sm:username/string() , 'places')
let $data := $places:collection-rootW//t:placeName[starts-with(@ref, 'http')]
 let $annotations :=
 for $d in $data 
 group by $r := root($d)//t:TEI/@xml:id
let $tit := exptit:printTitleID(string($r))
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
($places:response200turtle,
       $places:prefixes
        || string-join($annotations//text(), ' ')
)
};



declare 
%rest:GET
%rest:path("/api/placeNames/manuscripts/all")
%rest:query-param("start", "{$start}", 1)
%output:method("text")
function places:placesInManuscriptsTTL($start as xs:integer*) {

let $log := log:add-log-message('/api/placeNames/manuscripts/all', sm:id()//sm:real/sm:username/string() , 'places')
let $data := $places:collection-rootW//t:placeName[starts-with(@ref, 'http')]

let $annotations :=
 for $d in $data
 group by $r := root($d)//t:TEI/@xml:id
let $tit := exptit:printTitleID(string($r))
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
($places:response200turtle,
       $places:prefixes
        || string-join($annotations//text(), ' ')
)
};



declare 
%rest:GET
%rest:path("/api/placeNames/works/{$id}")
%output:method("text")
function places:placesInOneWorkTTL($id as xs:string) {
let $log := log:add-log-message('/api/placeNames/works/' || $id, sm:id()//sm:real/sm:username/string() , 'places')
let $file := $places:collection-rootW/id($id)
let $sid :=  string($id)
let $r := $file/@xml:id
return
if($file) then
let $data := $file//t:placeName[@ref]
let $abstract := if($file//t:abstract) then $file//t:abstract else ('no description available')
let $url :=  $config:appUrl ||'/'
let $baseUrl :=  $config:appUrl || $id
 let $annotations :=
let $tit := exptit:printTitleID($sid)
 return
 
 <annotatedThing id="{$id}">
 
             {places:ThisAnnotatedThing($r, $tit, 'works')}
   
   <annotations>
 {for $thisd at $x in $data
 return
 places:annotation($thisd, $r, $x, 'works')
 }
 </annotations>
 </annotatedThing>

return
($places:response200turtle,
       $places:prefixes
        || string-join($annotations//text(), ' ')
)

else ('Sorry, the id you provided is not a valid work record id.')
};

declare 
%rest:GET
%rest:path("/api/placeNames/manuscripts/{$id}")
%output:method("text")
function places:placesInOneManuscriptTTL($id as xs:string) {

let $log := log:add-log-message('/api/placeNames/manuscripts/' || $id, sm:id()//sm:real/sm:username/string() , 'places')
let $file := $places:collection-rootMS/id($id)
let $sid := string($id)
let $r := $file/@xml:id
return
if($file) then
let $data := $file//t:placeName[@ref]

 let $annotations :=

let $tit := exptit:printTitleID($sid)
 return
 
 <annotatedThing id="{$id}">
 
            {places:ThisAnnotatedThing($r, $tit, 'manuscripts')}
   
   <annotations>
 {for $thisd at $x in $data
 return
 places:annotation($thisd, $r, $x, 'manuscripts')
 }
 </annotations>
 </annotatedThing>

return
($places:response200turtle,
       
               $places:prefixes
        || string-join($annotations//text(), ' ')
)

else ('Sorry, the id you provided is not a valid manuscript record id.')
};

declare 
%rest:GET
%rest:path("/api/placeNames/void")
%output:method("text")
function places:placesInWorksTTLVoid() {

$places:response200turtle, 
let $dataMS := $places:collection-rootMS//t:placeName[starts-with(@ref, 'http')]
let $dataW := $places:collection-rootW//t:placeName[starts-with(@ref, 'http')]
let $annotationsMS :=  for $d in $dataMS
 group by $r := root($d)//t:TEI/@xml:id
 return 
 ' void:dataDump <https://betamasaheft.eu/api/placeNames/manuscripts/'||string($r)||'>'
let $annotationsW :=  for $d in $dataW
 group by $r := root($d)//t:TEI/@xml:id
 return 
 ' void:dataDump <https://betamasaheft.eu/api/placeNames/works/'||string($r)||'>'

return 

        '
@prefix : <'||$config:appUrl||'> .
        @prefix void: <http://rdfs.org/ns/void#> .
        @prefix dcterms: <http://purl.org/dc/terms/> .
        @prefix foaf: <http://xmlns.com/foaf/0.1/> .
        
        : a void:Dataset;
        dcterms:title "Beta maṣāḥǝft";
        dcterms:publisher "Akademie der Wissenschaften in Hamburg";
        dcterms:publisher "Hiob-Ludolf-Zentrum für Äthiopistik";
        foaf:homepage <'||$config:appUrl||'>;
        dcterms:description "The project Beta maṣāḥǝft: Manuscripts of Ethiopia and Eritrea (Schriftkultur des christlichen 
        Äthiopiens: eine multimediale Forschungsumgebung) is a long-term project funded 
        within the framework of the Academies Programme (coordinated by the Union of the German 
        Academies of Sciences and Humanities) under survey of the Akademie der Wissenschaften in Hamburg. 
        The funding will be provided for 25 years, from 2016–2040. The project is hosted by the Hiob Ludolf 
        Centre for Ethiopian Studies at the University of Hamburg. It aims at creating a virtual research 
        environment that shall manage complex data related to predominantly Christian manuscript 
        tradition of the Ethiopian and Eritrean Highlands.";
        dcterms:license <http://opendatacommons.org/licenses/odbl/1.0/>;
        ' || string-join($annotationsMS, ';
        ') ||';
        '||string-join($annotationsW, ';
        ') ||';
        void:dataDump <https://raw.githubusercontent.com/BetaMasaheft/Documentation/master/framauro.ttl>;
        void:dataDump <https://raw.githubusercontent.com/BetaMasaheft/Documentation/master/cosmas.ttl>;
        void:dataDump <https://raw.githubusercontent.com/BetaMasaheft/Documentation/master/StraboXVI4.ttl>;
        void:dataDump <https://raw.githubusercontent.com/BetaMasaheft/Documentation/master/SB24_16187.ttl>;
        void:dataDump <https://raw.githubusercontent.com/BetaMasaheft/Documentation/master/PlinyNH6_33_34.ttl>;
        void:dataDump <https://raw.githubusercontent.com/BetaMasaheft/Documentation/master/Pithom.ttl>;
        void:dataDump <https://raw.githubusercontent.com/BetaMasaheft/Documentation/master/Diod3_37_41.ttl>
        .'};



(: ~
 : produces a pelagios dump of the gazetteer of places in the Pelagios Interconnection format and stores it in given directory 
 output should be produced in exide and then validated with http://peripleo.pelagios.org/validator
 :)
declare function places:pelagiosDump(){
   let $pl := $places:collection-rootPl
   let $in := $places:collection-rootIn
   let $plp := $pl//t:place
   let $inp := $in//t:place
   let $data := ($plp, $inp)
   let $txtarchive := '/db/apps/ttl/'
   (: store the filename :)
   let $filename := concat('allplaces', format-dateTime(current-dateTime(), "[Y,4][M,2][D,2][H01][m01][s01]"), '.ttl')
   
   let $filecontent := 
       let $annotations := for $d in $data
              let $r := root($d)//t:TEI/@xml:id
              let $i := string($r)
              let $tit := exptit:printTitleID($i)
              let $annotatedthing := if($tit) then try{ann:annotatedThing($d, $tit[1], $i)} catch * {($i|| $err:description)}  else ()
                order by $tit[1]
                 return
               $annotatedthing 
     return  $places:placeprefixes || string-join($annotations, ' ')
    
    (: create the new file with a still-empty id element :)
    let $store := xmldb:store($txtarchive, $filename, $filecontent)
    return
      'stored ' || $txtarchive || $filename
};