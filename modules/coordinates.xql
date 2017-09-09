xquery version "3.1" encoding "UTF-8";

module namespace coord = "https://www.betamasaheft.uni-hamburg.de/BetMas/coord";

declare namespace t = "http://www.tei-c.org/ns/1.0";
declare namespace dcterms = "http://purl.org/dc/terms";
declare namespace saws = "http://purl.org/saws/ontology";
declare namespace cmd = "http://www.clarin.eu/cmd/";
declare namespace skos = "http://www.w3.org/2004/02/skos/core#";
declare namespace rdf = "http://www.w3.org/1999/02/22-rdf-syntax-ns#";
declare namespace s = "http://www.w3.org/2005/xpath-functions";
declare namespace sparql = "http://www.w3.org/2005/sparql-results#";

import module namespace config = "https://www.betamasaheft.uni-hamburg.de/BetMas/config" at "config.xqm";
import module namespace console = "http://exist-db.org/xquery/console";
import module namespace http = "http://expath.org/ns/http-client";
import module namespace xqjson = "http://xqilla.sourceforge.net/lib/xqjson";


(:gives priority to places where to look for coordinates
first looks at what the id is, then if it is one of ours, looks for coordinates
1. take ours if we have them, if not look for a sameAs and check there for coordinates:)
declare function coord:getCoords($placenameref as xs:string) {
    if (starts-with($placenameref, 'LOC') or starts-with($placenameref, 'INS')) then
        let $pRec := collection($config:data-rootPl, $config:data-rootIn)//id($placenameref)
        return
            if ($pRec//t:geo/text()) then
                replace(normalize-space($pRec//t:geo), ' ', ',')
            else
                if ($pRec//@sameAs) then
                    coord:GNorWD($pRec//@sameAs)
                else
                    console:log("no coordinates for" || $placenameref)
    else
        coord:GNorWD($placenameref)
};

(:get inverted coordinates for leaflet from wikidata:)
declare function coord:invertCoord($coords) {
    
    let $invert := substring-after($coords, ',') || ',' || substring-before($coords, ',')
    return
        replace($invert, ' ', '')
};

(:if the id of a place is not one of ours, then is a Q item in wikidata or a geonames id:)
declare function coord:GNorWD($placeexternalid as xs:string) {
    if (starts-with($placeexternalid, 'gn:')) then
        coord:invertCoord(coord:getGeoNamesCoord($placeexternalid))
    else
        if (starts-with($placeexternalid, 'pleiades:')) then
            coord:getPleiadesCoord($placeexternalid)
        
        else
            if (starts-with($placeexternalid, 'Q')) then
                coord:invertCoord(coord:getWikiDataCoord($placeexternalid))
            else
                console:log("no valid external id" || $placeexternalid)
};


(:retrives coordinates from geonames:)
declare function coord:getGeoNamesCoord($string as xs:string) {
    let $gnid := substring-after($string, 'gn:')
    let $xml-url := concat('http://api.geonames.org/get?geonameId=', $gnid, '&amp;username=betamasaheft')
    let $data := httpclient:get(xs:anyURI($xml-url), true(), <Headers/>)
    let $string := $data//lng/text() || ',' || $data//lat/text()
    return
    normalize-space($string)
        
};


(:retrives coordinates from wikidata:)
declare function coord:getWikiDataCoord($Qid as xs:string) {
    let $sparql := 'SELECT ?coord ?coordLabel WHERE {
   wd:' || $Qid || ' wdt:P625 ?coord .
   SERVICE wikibase:label { 
    bd:serviceParam wikibase:language "en" .
   }
 }'
    let $query := 'https://query.wikidata.org/sparql?query=' || xmldb:encode-uri($sparql)
    let $req := httpclient:get(xs:anyURI($query), false(), <headers/>)
    let $removePoint := replace($req//sparql:result/sparql:binding[@name = "coordLabel"], 'Point\(', '')
    let $removetrailing := replace($removePoint, '\)', '')
    return
        normalize-space(replace($removetrailing, ' ', ','))

};


declare function coord:getPleiadesCoord($string as xs:string) {
    let $plid := substring-after($string, 'pleiades:')
    let $url := concat('http://pleiades.stoa.org/places/', $plid, '/json')
    let $req :=
    <http:request
        href="{xs:anyURI($url)}"
        method="GET">
    </http:request>
    let $file := http:send-request($req)[2]
    let $file-info :=
    let $payload := util:base64-decode($file)
    let $parse-payload := xqjson:parse-json($payload)
    return
        $parse-payload
    let $coords := $file-info//*:pair[@name = "reprPoint"]/*:item/text()
    return
        string-join($coords, ',')

};
