xquery version "3.1" encoding "UTF-8";
(:~
 : module with helper functions for dealing with the place data in Beta Masaheft. 
 : decides names on the bases of ids,
 : decides where and how to get coordinates for an entry based on the id
 : 
 : @author Pietro Liuzzo 
 :)
module namespace coord = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/coord";

declare namespace t = "http://www.tei-c.org/ns/1.0";
declare namespace dcterms = "http://purl.org/dc/terms";
declare namespace saws = "http://purl.org/saws/ontology";
declare namespace cmd = "http://www.clarin.eu/cmd/";
declare namespace skos = "http://www.w3.org/2004/02/skos/core#";
declare namespace rdf = "http://www.w3.org/1999/02/22-rdf-syntax-ns#";
declare namespace s = "http://www.w3.org/2005/xpath-functions";
declare namespace sparql = "http://www.w3.org/2005/sparql-results#";
declare namespace http = "http://expath.org/ns/http-client";

import module namespace config = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/config" at "xmldb:exist:///db/apps/BetMasWeb/modules/config.xqm";

declare namespace test="http://exist-db.org/xquery/xqsuite";

(:~
 : tries to decide type of coordinate from content:)
declare function coord:coordType($placenameref as xs:string) {
let $data := <coord>{coord:getCoords($placenameref)}</coord>
let $seq := for $point in tokenize($data//coord, ' ') return $point
 return
 if((count($seq) gt 1) and ($seq[last()] eq $seq[1])) then('polygon') else ('point')
};

(:~
 : tries to decide type of coordinate from the coordinates content as string:)
declare function coord:coordType($coord as item()*, $string) {
let $seq := for $point in tokenize($coord, ' ') return $point
 return
 if((count($seq) gt 1) and ($seq[last()] eq $seq[1])) then('polygon') else ('point')
};



(:~
 : gives priority to places where to look for coordinates
 : first looks at what the id is, then if it is one of ours, looks for coordinates
 : 1. take ours if we have them, if not look for a sameAs and check there for coordinates:)
declare function coord:getCoords($placenameref as xs:string) {
    if (starts-with($placenameref, 'LOC') or starts-with($placenameref, 'INS')) then
        let $pRec := collection($config:data-rootPl,$config:data-rootIn)/id($placenameref)
         return
         if ($pRec//t:geo[@rend eq 'polygon']/text()) then
                for $point in tokenize($pRec//t:geo[@rend eq 'polygon'], '\n')
                let $p := normalize-space($point)
                return
                concat(substring-before($p, ' '), ',', substring-after($p, ' '))
            else
            if ($pRec//t:geo[not(@rend eq 'polygon')]/text()) then
(:                replace(normalize-space($pRec//t:geo), ' ', ','):)
                concat(substring-before($pRec//t:geo, ' '), ',', substring-after($pRec//t:geo, ' '))
            else
                if ($pRec//@sameAs) then
                    coord:GNorWD(($pRec//@sameAs)[1])
            else
            if ($pRec//t:relation[@name eq 'skos:exactMatch']) then
            let $passive := string($pRec//t:relation[@name eq 'skos:exactMatch']/@passive)
            return
                coord:getCoords($passive)
           
                else
                    ("no coordinates for" || $placenameref)
    else
        coord:GNorWD($placenameref)
};

(:~get inverted coordinates for leaflet from wikidata
: if it is a polygon do nothing
:)
declare function coord:invertCoord($coords as xs:string*) {
    if(count($coords) gt 1) then () else
   if(coord:coordType($coords, 'string') = 'polygon') then () else
   if($coords = ' ') then () else
     if($coords = ',') then () else
    let $invert := substring-after($coords, ',') || ',' || substring-before($coords, ',')
    return
        replace($invert, ' ', '')
};

(:~if the id of a place is not one of ours, then is a Q item in wikidata or a geonames id:)
declare function coord:GNorWD($placeexternalid as xs:string) {
    if (starts-with($placeexternalid, 'gn:')) then
        coord:invertCoord(coord:getGeoNamesCoord($placeexternalid))
    else
        if (starts-with($placeexternalid, 'pleiades:')) then
            coord:getPleiadesCoord($placeexternalid)
        
        else
            if (starts-with($placeexternalid, 'wd:')) then
                coord:invertCoord(coord:getWikiDataCoord($placeexternalid))
            else
                ("no valid external id" || $placeexternalid)
};


(:~retrives coordinates from geonames:)
declare function coord:getGeoNamesCoord($string as xs:string) {
    let $gnid := substring-after($string, 'gn:')
    let $xml-url := concat('http://api.geonames.org/get?geonameId=', $gnid, '&amp;username=betamasaheft')
    let $request := <http:request href="{xs:anyURI($xml-url)}" method="GET"/>
    let $data := http:send-request($request)[2]
    let $string := $data//lng/text() || ',' || $data//lat/text()
    return
    normalize-space($string)
        
};


(:~retrives coordinates from wikidata:)
declare function coord:getWikiDataCoord($Qid as xs:string) {
 let $Qid := substring-after($Qid, 'wd:')
    let $sparql := 'SELECT ?coord ?coordLabel WHERE {
   wd:' || $Qid || ' wdt:P625 ?coord .
   SERVICE wikibase:label { 
    bd:serviceParam wikibase:language "en" .
   }
 }'
    let $query := 'https://query.wikidata.org/sparql?query=' || xmldb:encode-uri($sparql)
     let $request := <http:request href="{xs:anyURI($query)}" method="GET"/>
    let $req := http:send-request($request)[2]
    let $removePoint := replace(($req//sparql:result/sparql:binding[@name eq "coordLabel"])[1], 'Point\(', '')
    let $removetrailing := replace($removePoint, '\)', '')
    return
        normalize-space(replace($removetrailing, ' ', ','))

};

(:~The function queries pelagios rather than pleiades directly. 
 : the function below queries pleiades but gets an handshake failure :)
declare function coord:getPleiadesCoord($string as xs:string) {
   let $plid := substring-after($string, 'pleiades:')
   let $url := concat('http://peripleo.pelagios.org/peripleo/places/http:%2F%2Fpleiades.stoa.org%2Fplaces%2F', $plid)
 let $request := <http:request href="{xs:anyURI($url)}" method="GET"/>
    let $file := http:send-request($request)[2]
  
let $file-info := 
    let $payload := util:base64-decode($file) 
    let $parse-payload := parse-json($payload)
    return $parse-payload 
    
    let $gb := $file-info?geo_bounds
let $coords := if ($gb(1) = $gb(2))
then ($gb(1), $gb(3)) else for $g in $gb?* return $g
    return 
    string-join($coords, ',')

};


