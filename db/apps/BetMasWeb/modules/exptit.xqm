xquery version "3.1" encoding "UTF-8";

(:titles.xqm uses existing lists maintained on upload of the source data. it will update the lists when needed.
only the gitsync.xqm and the expanded.xqm modules, which deal with the data as entered in the db, should use titles.xqm
the expanded TEI will include those titles and names.
The views do not need to use this, and should instead get the information straight from the context of the expanded file, without checking lists or other files again :)

module namespace exptit = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/exptit";
import module namespace config = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/config" at "xmldb:exist:///db/apps/BetMasWeb/modules/config.xqm";

declare namespace t = "http://www.tei-c.org/ns/1.0";
declare namespace http = "http://expath.org/ns/http-client";
declare namespace test="http://exist-db.org/xquery/xqsuite";
declare namespace sparql = "http://www.w3.org/2005/sparql-results#";

declare variable $exptit:col := collection($config:data-root);
declare variable $exptit:placeNamesList := doc('/db/apps/lists/placeNamesLabels.xml');
declare variable $exptit:institutionsList := doc('/db/apps/lists/institutions.xml');
declare variable $exptit:persNamesList := doc('/db/apps/lists/persNamesLabels.xml');
declare variable $exptit:TUList := doc('/db/apps/lists/textpartstitles.xml');
declare variable $exptit:deleted := doc('/db/apps/lists/deleted.xml');
declare variable $exptit:prefixDef := doc('/db/apps/lists/listPrefixDef.xml');

(: The entry point function of the module. Establishes the different rules and priority to print a title referring to a record. can start from any node in the document. :)
declare function exptit:printTitle($titleMe) {
if(count($titleMe) = 0 or $titleMe = "" ) then () else
    (:titleable could a node or a string, and the string could be anything...:)
    typeswitch ($titleMe)
        case element()
        (:        could be TEI or any other node, just go back to the top:)
            return
                let $resource := root($titleMe)
                return
                    (:                this is added by expanded.xql exptit relies on that :)
                    $resource//t:title[@type = 'full']/text()
        default
            return
                (:            the string could be really just anything, but in the expanded data, it will often be a URI.:)
                if (starts-with($titleMe, $config:appUrl)) then
                    (:                check if it is a local URI :)
                    let $id := substring-after($titleMe, concat($config:appUrl, '/'))
                    return
                        exptit:printTitleID($id)
                else
                    if (contains($titleMe, 'betmas:')) then
(:                    it is a prefixed http thing, replace and treat it accordingly :)
let $id := substring-after($titleMe, 'betmas:')
                    return
                        exptit:printTitleID($id)
                else
                    if (starts-with($titleMe, 'http')) then
                        (:                it is a URI, but not ours, best guess is just return it as is   :)
                        $titleMe
                        (:                perhaps it is just an identifier.... try to get the full title and if you do not find it, return what was submitted:)
                    else
                        let $title := exptit:printTitleID($titleMe)
                        return
                            if (string-length(string-join($title)) ge 1) then
                                $title
                            else
                                $titleMe
};



(:this is now a switch function, deciding if to go ahead with simple print title or subtitles:)
declare 
%test:arg('id', 'sdc:UniCont1') %test:assertEquals('La Synthaxe du Codex UniCont1')
%test:arg('id', 'LIT2317Senodo#') %test:assertEquals('Senodos')
%test:arg('id', '#') %test:assertEquals('&lt;span class="w3-tag w3-red"&gt;no item yet with id #&lt;/span&gt;')
%test:arg('id', '') %test:assertEquals('&lt;span class="w3-tag w3-red"&gt;no id&lt;/span&gt;')
%test:arg('id', 'BNFet32') %test:assertEquals('Paris, Bibliothèque nationale de France, BnF Éthiopien 32')
%test:arg('id', 'LIT1367Exodus') %test:assertEquals('Exodus')
%test:arg('id', 'PRS11160HabtaS') %test:assertEquals(' Habta Śǝllāse')
%test:arg('id', 'LOC1001Aallee') %test:assertEquals('Aallee')
%test:arg('id', 'BNFet32#a2') %test:assertEquals('Paris, Bibliothèque nationale de France, BnF Éthiopien 32, Donation Note a2')
%test:arg('id', 'BNFet32#e1') %test:assertEquals('Paris, Bibliothèque nationale de France, BnF Éthiopien 32, no id e1')
%test:arg('id', 'LIT1367Exodus#Ex1') %test:assertEquals('Exodus, Exodus 1')
%test:arg('id', 'PRS5684JesusCh#n2') %test:assertEquals('Jesus Christ, Krǝstos')
function exptit:printTitleID($id as xs:string)
{ if ($exptit:deleted//t:item[.=$id]) then
      let $del := $exptit:deleted//t:item[.=$id]
      let $formerly := $exptit:col//t:relation[@name eq 'betmas:formerlyAlsoListedAs'][@passive eq $id]
              return
              if($formerly) then
                exptit:printTitleID($formerly/@active) || ' [now '||string($formerly/@active)||', formerly also listed as '||$id||', which was requested here but has been deleted on '||string($del/@change)||']'
                else $id || ' was permanently deleted' 
   else if (starts-with($id, 'sdc:')) then 'La Synthaxe du Codex ' || substring-after($id, 'sdc:' )
    (: another hack for things like ref="#" :) 
    else if ($id = '#') then <span class="w3-tag w3-red">{ 'no item yet with id ' || $id }</span>
    (: hack to avoid the bad usage of # at the end of an id like <title type="complete" ref="LIT2317Senodo#" xml:lang="gez"> :) 
    else if ($exptit:TUList//t:item[@corresp eq  $id]) then ($exptit:TUList//t:item[@corresp eq  $id][1]/node())
    else if ($exptit:persNamesList//t:item[@corresp eq  $id]) then ($exptit:persNamesList//t:item[@corresp eq  $id][1]/node())
    else if (ends-with($id, '#')) then (
                                let $newid := replace($id, '#', '') 
                                return exptit:printTitleID($newid) )
    else if (matches($id, 'wd:Q\d+') or starts-with($id, 'gn:') or starts-with($id, 'pleiades:')) 
            then exptit:decidePlaceNameSource($id)
    else if ($id = '') then <span class="w3-tag w3-red">{ 'no id' }</span>
    (: if the id has a subid, than split it :) 
    else if (contains($id, '#')) then
    (   let $mainIDstart := substring-before($id, '#')
        let $mainID := if(starts-with($mainIDstart, $config:baseURI)) then substring-after($mainIDstart, $config:baseURI) else $mainIDstart
        let $SUBid := substring-after($id, '#')
        let $node := $exptit:col//id($mainID)
        return
            if($node) then(
             if (starts-with($SUBid, 't')) then
                    (let $subtitles:=$node//t:title[contains(@corresp, $SUBid)]
                       let $subtitlemain := $subtitles[@type eq  'main']/text()
                       let $subtitlenorm := $subtitles[@type eq  'normalized']/text()
                         let $tit := $node//t:title[@xml:id = $SUBid]
                        return
                             if ($subtitlemain) then $subtitlemain
                            else if ($subtitlenorm) then $subtitlenorm
                            else $tit/text()
                 ) 
            else
(:            format the title, add it to the list and pass again to this function, which will have something to match now:)
                (let $subtitle := exptit:printSubtitle($node[1], $SUBid)
                 let $name := (exptit:printTitleID($mainID)|| ', '||$subtitle)   
                 let $addit := exptit:updateTUList($name, $id)
                    return
                        $exptit:col/id($id)//t:title[@type = 'full']/text()
                )
    )
    
    (: if no node could be found with the main id, that has a problem :)
     else 
        (<span class="w3-tag w3-red">{ 'No item: ' || $mainID 
            || ', could not check for ' || $SUBid
        }</span>)
    )    
       (: if not, procede to main title printing :)
    else
        $exptit:col/id($id)//t:title[@type = 'full']/text()
};

declare function exptit:updateTUList($name, $pRef){
let $TUlist := $exptit:TUList//t:list
return update insert <item 
xmlns="http://www.tei-c.org/ns/1.0" 
change="entryAddedAt{current-dateTime()}"
corresp="{$pRef}">{$name}</item> into  $TUlist
};

(:looks for different possible locations of anchor and where to pick the correct label:)   
declare function exptit:printSubtitle($node as node(), $SUBid as xs:string) as xs:string {
    if( starts-with($SUBid, 'tr')) then 'transformation ' ||  $SUBid
else if( starts-with($SUBid, 'Uni')) then $SUBid 
else
    let $item := $node//id($SUBid)
    return
       if ($item/name() = 'title') then
             (string($item/@xml:lang) || (if($item/text()) then $item/text() else ' ... empty, sorry!'))
        else
        if ($item/name() = 'persName') then
            
            (let $r := root($item)
            return
            if($r//t:persName[@type eq  'normalized'][contains(@corresp,$SUBid)]) 
            then string-join($r//t:persName[@type eq  'normalized'][contains(@corresp,$SUBid)]//text(), '')
            else normalize-space(string-join($item, ''))
            )
        else if ($item/name() = 'msItem') then
            (if ($item/t:title/@ref)
                then
                    (exptit:printTitleID(string($item/t:title/@ref)) || ' (in ' || $SUBid || ')')
                else
                    normalize-space(string-join($item/t:title/text(), ''))
                    )
            else if ($item/t:label) then
                let $sameAs := if ($item/@corresp) then (' (same as ' ||string($item/@corresp) || ')') else ()
                return
                   (normalize-space(string-join($item/t:label/text(), '')) || $sameAs)
            else if ($item[not(t:label)]/@corresp) then
                   normalize-space(string-join(exptit:printTitleID($item/@corresp), ''))
            else if ($item/t:desc) then
                    (exptit:printTitleID(string($item/t:desc/@type)) || ' ' || $SUBid)
            else if (($item/@subtype eq  'Monday' or $item/@subtype eq  'Tuesday' or $item/@subtype eq  'Wednesday' or $item/@subtype eq  'Thursday' or $item/@subtype eq  'Friday' or $item/@subtype eq  'Saturday' or $item/@subtype eq  'Sunday'    )and not($item/node())) then
                    (' for '|| $SUBid)
            else if ($item/@subtype) then
                    (exptit:printTitleID(string($item/@subtype)) || ': ' || $SUBid)
            else ($item/name() || ' ' || $SUBid)
};


(:Given an id, decides if it is one of BM or from another source and gets the name accordingly:)
declare function exptit:decidePlaceNameSource($pRef as xs:string){
if ($exptit:placeNamesList//t:item[@corresp =  $pRef]) 
    then $exptit:placeNamesList//t:item[@corresp = $pRef][1]/text()
else if (starts-with($pRef, 'gn:')) then (
        let $name := exptit:getGeoNames($pRef) 
        let $addit := exptit:updatePlaceList($name, $pRef) 
        return
             exptit:decidePlaceNameSource($pRef)) 
else if (starts-with($pRef, 'pleiades:')) then (
        let $name := exptit:getPleiadesNames($pRef) 
        let $addit := exptit:updatePlaceList($name, $pRef) 
        return
            exptit:decidePlaceNameSource($pRef)) 
else if (matches($pRef, 'wd:Q\d+')) then (
        let $name := exptit:getwikidataNames($pRef) 
        let $addit := exptit:updatePlaceList($name, $pRef) 
        return
            exptit:decidePlaceNameSource($pRef)) 
else  $exptit:col/id($pRef)//t:title[@type = 'full']/text()
};

declare function exptit:updatePlaceList($name, $pRef){
let $placeslist := $exptit:placeNamesList//t:list
return 
update insert <item 
xmlns="http://www.tei-c.org/ns/1.0" 
change="entryAddedAt{current-dateTime()}"
corresp="{$pRef}">{$name}</item> into  $placeslist
};

declare function exptit:getGeoNames ($string as xs:string){
let $gnid:= substring-after($string, 'gn:')
let $xml-url := concat('http://api.geonames.org/get?geonameId=',$gnid,'&amp;username=betamasaheft')
let $data := try{let $request := <http:request href="{xs:anyURI($xml-url)}" method="GET"/>
    return http:send-request($request)[2]} catch *{$err:description}
return
if ($data//toponymName) then
$data//toponymName/text()
else 'no data from geonames'
};

declare function exptit:getPleiadesNames($string as xs:string) {

   let $plid := substring-after($string, 'pleiades:')
   let $url := concat('http://pelagios.org/peripleo/places/http:%2F%2Fpleiades.stoa.org%2Fplaces%2F', $plid)
  let $file := try{let $request := <http:request href="{xs:anyURI($url)}" method="GET"/>
    return http:send-request($request)[2]} catch *{$err:description}
  
let $file-info := 
    let $payload := util:base64-decode($file) 
    let $parse-payload := parse-json($payload)
    return $parse-payload 
    return $file-info?title

};

declare function exptit:getwikidataNames($pRef as xs:string){
let $pRef := substring-after($pRef, 'wd:')
let $sparql := 'SELECT * WHERE {
  wd:' || $pRef || ' rdfs:label ?label . 
  FILTER (langMatches( lang(?label), "EN" ) )  
}'


let $query := 'https://query.wikidata.org/sparql?query='|| xmldb:encode-uri($sparql)

let $req := try{let $request := <http:request href="{xs:anyURI($query)}" method="GET"/>
    return http:send-request($request)[2]} catch * {$err:description}
return
$req//sparql:result/sparql:binding[@name eq "label"]/sparql:literal[@xml:lang='en']/text()
};

