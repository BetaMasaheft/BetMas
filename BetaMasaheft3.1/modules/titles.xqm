xquery version "3.1" encoding "UTF-8";

module namespace titles="https://www.betamasaheft.uni-hamburg.de/BetMas/titles";

declare namespace t="http://www.tei-c.org/ns/1.0";

declare namespace test="http://exist-db.org/xquery/xqsuite";
declare namespace sparql = "http://www.w3.org/2005/sparql-results#";
import module namespace config="https://www.betamasaheft.uni-hamburg.de/BetMas/config" at "config.xqm";

(:establishes the different rules and priority to print a title referring to a record:)
declare function titles:printTitle($node as element()) {
(:always look at the root of the given node parameter of the function and then switch :)
   let $resource := root($node)
   return
   switch($resource//t:TEI/@type)
            case "mss"
                    return
                        if ($resource//t:objectDesc[@form = 'Inscription']) then
                            ($resource//t:msIdentifier/t:idno/text())
                        else
                            (
                                if($resource//t:repository/text() = 'Lost')
                                then ('Lost. ' || $resource//t:msIdentifier/t:idno/text())
                            else if ($resource//t:repository/@ref and $resource//t:msDesc/t:msIdentifier/t:idno/text())
                            then
                                let $repoid := $resource//t:repository/@ref
                                let $r := collection($config:data-rootIn)//id($repoid)
                                let $repo := if ($r) then
                                    ($r)
                                else
                                    'No Institution record'
                                
                                let $repoPlace :=
                                if ($repo = 'No Institution record') then
                                    $repo
                                else
                                    (if ($repo[not(.//t:settlement)][not(.//t:country)]) then ()
                                    else if ($repo//t:settlement[1]/@ref)
                                    then
                                         let $plaID := string($repo//t:settlement[1]/@ref)
                                         return 
                                              titles:decidePlName($plaID)
                                    else
                                        if ($repo//t:settlement[1]/text()) then
                                            $repo//t:settlement[1]/text()
                                        else
                                            if ($repo//t:country/@ref) then
                                                let $plaID := string($repo//t:country[1]/@ref) 
                                                return 
                                              titles:decidePlName($plaID)
                                        else if ($repo//t:country/text()) then
                                                $repo//t:country/text()
                                            else
                                                'No location record')
                                
                                return
                                    
                            string-join($repoPlace,' ') || ', ' ||
                                    (if ($repo = 'No Institution record') then
                                        $repo
                                    else
                                        (titles:placeNameSelector($repo[1]))) || ', ' ||
                                    
                                        $resource//t:msDesc/t:msIdentifier/t:idno/text()
                            else
                                'no repository data for ' || string($resource/@xml:id)
                                
                                )
             case "place"  return  titles:placeNameSelector($resource)
             case "ins" return  titles:placeNameSelector($resource)
            case "pers"  return titles:persNameSelector($resource)
            case "work"  return titles:worknarrTitleSelector($resource)
            case "narr"  return titles:worknarrTitleSelector($resource)
(:            this should do also auths:)
            default return $resource//t:titleStmt/t:title[1]/text()
            
   };
   
   
declare function titles:printSubtitle($node as node(), $SUBid as xs:string) as xs:string {
    if( starts-with($SUBid, 'tr')) then 'transformation ' ||  $SUBid
else if( starts-with($SUBid, 'Uni')) then $SUBid 
else
    let $item := $node//id($SUBid)
    return
       if ($item/name() = 'title') then
            ($item/@xml:lang || $item)
        else
        if ($item/name() = 'persName') then
            
            (let $r := root($item)
            return
            if($r//t:persName[@type = 'normalized'][contains(@corresp,$SUBid)]) 
            then string-join($r//t:persName[@type = 'normalized'][contains(@corresp,$SUBid)]//text(), '')
            else normalize-space(string-join($item, ''))
            )
        else
            if ($item/name() = 'msItem') then
                (if ($item/t:title/@ref)
                then
                    (titles:printTitleID(string($item/t:title/@ref)) || ' (in ' || $SUBid || ')')
                else
                    normalize-space(string-join(titles:tei2string($item/t:title), ''))
                    )
            else 
            if ($item/t:label) then
                   normalize-space(string-join(titles:tei2string($item/t:label), ''))
      
           else
                    if ($item/t:desc) then
                        (titles:printTitleID(string($item/t:desc/@type)) || ' ' || $SUBid)
             else
                        if ($item/@subtype) then
                            (titles:printTitleID(string($item/@subtype)) || ': ' || $SUBid)
             else
                            ($item/name() || ' ' || $SUBid)
};

(:this is now a switch function, deciding if to go ahead with simple print title or subtitles:)
declare 
%test:arg('id', 'BNFet32#a1') %test:assertEquals('Paris, Bibliothèque nationale de France, Éthiopien 32, Scribal Note Completing a1')
%test:arg('id', 'LIT1367Exodus#Ex1') %test:assertEquals('Exodus, Exodus 1')
%test:arg('id', 'PRS5684JesusCh#n2') %test:assertEquals('Jesus Christ - Krǝstos')
function titles:printTitleID($id as xs:string)
{  if (starts-with($id, 'SdC:')) then 'La Synthaxe du Codex ' || substring-after($id, 'SdC:' )
               else
    (: hack to avoid the bad usage of # at the end of an id like <title type="complete" ref="LIT2317Senodo#"
     : xml:lang="gez"> :) if (ends-with($id, '#')) then
        titles:printTitleMainID(substring-before($id, '#'))
    (: another hack for things like ref="#" :) else if ($id = '#') then
                         <span class="label label-warning">{ 'no item yet with id' || $id }</span>
    else if ($id = '') then
                        <span class="label label-warning">{ 'no id' }</span>
    (: if the id has a subid, than split it :) else if (contains($id, '#')) then
        let $mainID := substring-before($id, '#')
        let $SUBid := substring-after($id, '#')
        let $node := collection($config:data-root)//id($mainID)
        return
        if (starts-with($SUBid, 't'))
    then
        (let $subtitles:=$node//t:title[contains(@corresp, $SUBid)]
        let $subtitlemain := $subtitles[@type = 'main']/text()
        let $subtitlenorm := $subtitles[@type = 'normalized']/text()
        let $tit := $node//t:title[@xml:id = $SUBid]
        return
            if ($subtitlemain)
            then
                $subtitlemain
            else
                if ($subtitlenorm)
                then
                    $subtitlenorm
                else
                    $tit/text()
                    )
                    else
        let $subtitle :=   if( starts-with($SUBid, 'tr')) then 'transformation ' ||  $SUBid
else if( starts-with($SUBid, 'Uni')) then $SUBid 

else titles:printSubtitle($node, $SUBid)
        return
            (titles:printTitleMainID($mainID)|| ', '||$subtitle)
    (: if not, procede to main title printing :) else
        titles:printTitleMainID($id)
};



declare function titles:printTitleMainID($id as xs:string, $c)
   {
       if (matches($id, 'Q\d+') or starts-with($id, 'gn:') or starts-with($id, 'pleiades:')) then
           (titles:decidePlaceNameSource($id))
       else (: always look at the root of the given node parameter of the function and then switch :)
           let $resource := collection($c)//id($id)
           return
               if (count($resource) = 0) then
           <span class="label label-warning">{ 'No item: ' || $id }</span>
               else if (count($resource) > 1) then
           <span class="label label-warning">{ 'More then 1 ' || $id }</span>
               else
                   switch ($resource/@type)
                       case "mss"
                           return if ($resource//objectDesc[@form = 'Inscription']) then
                               ($resource//t:msIdentifier/t:idno/text())
                           else
                               (if ($resource//t:repository/text() = 'Lost') then
                                   ('Lost. ' || $resource//t:msIdentifier/t:idno/text())
                               else if ($resource//t:repository/@ref and $resource//t:msDesc/t:msIdentifier/t:idno/text())
                                   then
                                   let $repoid := $resource//t:repository/@ref
                                   let $r := collection($config:data-rootIn)//id($repoid)
                                   let $repo :=
                                       if ($r) then
                                           ($r)
                                       else
                                           'No Institution record'
                                   let $repoPlace :=
                                       if ($repo = 'No Institution record') then
                                           $repo
                                       else
                                           (if ($repo//t:settlement[1]/@ref) then
                                               let $plaID := string($repo//t:settlement[1]/@ref)
                                               return
                                                   titles:decidePlName($plaID)
                                           else if ($repo//t:settlement[1]/text()) then
                                               $repo//t:settlement[1]/text()
                                           else if ($repo//t:country/@ref) then
                                               let $plaID := string($repo//t:country/@ref)
                                               return
                                                   titles:decidePlName($plaID)
                                           else if ($repo//t:country/text()) then
                                               $repo//t:country/text()
                                           else
                                               'No location record'
                                           )
                                   return
                                       string-join($repoPlace, ' ') || ', ' || (if ($repo = 'No Institution record') then
                                           $repo
                                       else
                                           (titles:placeNameSelector($repo))
                                       ) || ', ' || 
                                           $resource//t:msDesc/t:msIdentifier/t:idno/text()
                                       
                               else
                                   'no repository data for ' || string($resource/@xml:id)
                               )
                   case "place"
                           return titles:placeNameSelector($resource)
                       case "ins"
                           return titles:placeNameSelector($resource)
                       case "pers"
                           return titles:persNameSelector($resource)
                       case "work"
                           return titles:worknarrTitleSelector($resource)
                       case "narr"
                           return titles:worknarrTitleSelector($resource) (: this should do also auths :)
                       default
                           return $resource//t:titleStmt/t:title[1]/text()
   };
   
   
   
 declare 
      %test:arg('id', 'BNFet32') %test:assertEquals('Paris, Bibliothèque nationale de France, Éthiopien 32')
      %test:arg('id', 'LIT1367Exodus') %test:assertEquals('Exodus')
      %test:arg('id', 'PRS11160HabtaS') %test:assertEquals(' Habta Śǝllāse')
      %test:arg('id', 'LOC1001Aallee') %test:assertEquals('Aallee')
      function titles:printTitleMainID($id as xs:string)
   {
       if (matches($id, 'Q\d+') or starts-with($id, 'gn:') or starts-with($id, 'pleiades:')) then
           (titles:decidePlaceNameSource($id))
       else (: always look at the root of the given node parameter of the function and then switch :)
           let $resource := collection($config:data-root)//id($id)
           return
               if (count($resource) = 0) then
           <span class="label label-warning">{ 'No item: ' || $id }</span>
               else if (count($resource) > 1) then
           <span class="label label-warning">{ 'More then 1 ' || $id }</span>
               else
                   switch ($resource/@type)
                       case "mss"
                           return if ($resource//objectDesc[@form = 'Inscription']) then
                               ($resource//t:msIdentifier/t:idno/text())
                           else
                               (if ($resource//t:repository/text() = 'Lost') then
                                   ('Lost. ' || $resource//t:msIdentifier/t:idno/text())
                               else if ($resource//t:repository/@ref and $resource//t:msDesc/t:msIdentifier/t:idno/text())
                                   then
                                   let $repoid := $resource//t:repository/@ref
                                   let $r := collection($config:data-rootIn)//id($repoid)
                                   let $repo :=
                                       if ($r) then
                                           ($r)
                                       else
                                           'No Institution record'
                                   let $repoPlace :=
                                       if ($repo = 'No Institution record') then
                                           $repo
                                       else
                                           (if ($repo//t:settlement[1]/@ref) then
                                               let $plaID := string($repo//t:settlement[1]/@ref)
                                               return
                                                   titles:decidePlName($plaID)
                                           else if ($repo//t:settlement[1]/text()) then
                                               $repo//t:settlement[1]/text()
                                           else if ($repo//t:country/@ref) then
                                               let $plaID := string($repo//t:country/@ref)
                                               return
                                                   titles:decidePlName($plaID)
                                           else if ($repo//t:country/text()) then
                                               $repo//t:country/text()
                                           else
                                               'No location record'
                                           )
                                   return
                                       string-join($repoPlace, ' ') || ', ' || (if ($repo = 'No Institution record') then
                                           $repo
                                       else
                                           (titles:placeNameSelector($repo))
                                       ) || ', ' || 
                                           $resource//t:msDesc/t:msIdentifier/t:idno/text()
                                       
                               else
                                   'no repository data for ' || string($resource/@xml:id)
                               )
                   case "place"
                           return titles:placeNameSelector($resource)
                       case "ins"
                           return titles:placeNameSelector($resource)
                       case "pers"
                           return titles:persNameSelector($resource)
                       case "work"
                           return titles:worknarrTitleSelector($resource)
                       case "narr"
                           return titles:worknarrTitleSelector($resource) (: this should do also auths :)
                       default
                           return $resource//t:titleStmt/t:title[1]/text()
   };
   

declare function titles:placeNameSelector($resource as node()){
      let $pl := $resource//t:place
let $pnorm := $pl/t:placeName[@corresp = '#n1'][@type = 'normalized']
let $pEN := $pl/t:placeName[@corresp = '#n1'][@xml:lang='en']
return
 if ($pnorm)
                        then
                            normalize-space(string-join($pnorm/text(), ' '))
 else if ($pEN)
                        then
                            normalize-space(string-join($pEN/text(), ' '))
                        else
                            if ($pl/t:placeName[@xml:id])
                            then
                            let $pn := $pl/t:placeName[@xml:id = 'n1']
                            return
                                normalize-space($pn/text())
                            else
                                if ($pl/t:placeName[text()][position() = 1]/text())
                                then
                                    normalize-space($pl/t:placeName[text()][position() = 1]/text())
                                else
                                    $resource//t:titleStmt/t:title[text()]/text()
};

declare function titles:persNameSelector($resource as node()){
    let $p := $resource//t:person
    let $pg := $resource//t:personGrp
let $Maintitle := $p/t:persName[@type = 'main']
let $twonames:= $p/t:persName[t:forename or t:surname]
let $namegez := $p/t:persName[@corresp = '#n1'][@xml:lang = 'gez']
let $nameennorm := $p/t:persName[@corresp = '#n1'][@xml:lang = 'en'][@type = 'normalized']
let $nameen := $p/t:persName[@corresp = '#n1'][@xml:lang = 'en']
let $nameOthers := $p/t:persName[@corresp = '#n1'][@xml:lang[not(. = 'en')][not(. = 'gez')]]
let $group := $pg/t:persName
let $groupgez := $pg/t:persName[@corresp = '#n1'][@xml:lang = 'gez']
let $groupennorm := $pg/t:persName[@corresp = '#n1'][@xml:lang = 'en'][@type = 'normalized']

return
 (:            first check for persons with two names:)
                        if ($twonames) then
                            (
                            if ($namegez)
                            then
                                ($namegez/t:forename/text()
                                || ' ' || $namegez/t:surname/text())
                            
                           
                            else
                                if ($nameennorm)
                                then
                                    ($nameennorm/t:forename/text()
                                    || ' ' || $nameennorm/t:surname/text())
                             else
                                if ($nameOthers)
                                then
                                    ($nameOthers[1]/t:forename/text()
                                    || ' ' || $nameOthers[1]/t:surname/text())
                                
                                else
                                    if ($resource//t:person/t:persName[@xml:id])
                                    then
                                    let $name := $resource//t:person/t:persName[@xml:id = 'n1']
                                    return
                                        ($name/t:forename/text()
                                        || ' '
                                        || $name/t:surname/text())
                                    
                                    else
                                        ($p/t:persName[position() = 1]/t:forename[1]/text() || ' '
                                        || $p/t:persName[position() = 1]/t:surname[1]/text()))
                            
                            (:       then check if it is a personGrp:)
                        else
                            if ($group) then
                                (
                                if ($groupgez)
                                then
                                    $groupgez/text()
                                
                                
                                else
                                    if ($pg/t:persName[t:orgName])
                                    then
                                        let $gname:=$pg/t:persName[@xml:id = 'n1']
                                        return $gname/t:orgName/text()
                                    
                                    
                                    else
                                        if ($groupennorm)
                                        then
                                            $groupennorm
                                        
                                        else
                                            if ($pg/t:persName[@xml:id])
                                            then
                                                let $gname:=$pg/t:persName[@xml:id = 'n1']
                                                return string-join($gname/text())
                                            
                                            else
                                                ($pg/t:persName[position() = 1]//text()))
                                
                                (:       otherways is just a normal person:)
                                 else
                            if ($Maintitle)
                        then
                            string-join($Maintitle/text())
                            else
                                (
                                if ($namegez)
                                then
                                    string-join($namegez//text())
                                
                                else
                                    if ($nameennorm)
                                    then
                                        string-join($nameennorm//text())
                                    
                                    else
                                        if ($nameen)
                                        then
                                            string-join($nameen//text())
                                    else
                                      if ($nameOthers)
                                        then
                                    string-join($nameOthers[1]/text())
                                   
                                        
                                        else
                                            if ($p/t:persName[@xml:id])
                                            then
                                                let $name := $p/t:persName[@xml:id = 'n1']
                                                return string-join($name//text())
                                            
                                            else
                                                string-join($p/t:persName[position() = 1][text()]//text())
                                )
};

declare function titles:worknarrTitleSelector($resource as node()){
    let $W := $resource//t:titleStmt
let $Maintitle := $W/t:title[@type = 'main'][@corresp = '#t1']
                    let $amarictitle := $W/t:title[@corresp = '#t1'][@xml:lang = 'am']
                    let $geztitle := $W/t:title[@corresp = '#t1'][@xml:lang = 'gez']
                    let $entitle := $W/t:title[@corresp = '#t1'][@xml:lang = 'en']
                    return
                        if ($Maintitle)
                        then
                            $Maintitle[1]/text()
                        else
                            if ($amarictitle)
                            then
                                $amarictitle[1]/text()
                            else
                                if ($geztitle)
                                then
                                    $geztitle[1]/text()
                                else
                                    if ($entitle)
                                    then
                                        $entitle[1]/text()
                                    else
                                        if ($W/t:title[@xml:id])
                                        then
                                            let $tit := $W/t:title[@xml:id = 't1']
                                            return $tit/text()
                                        else
                                            $W/t:title[1]/text()
};


declare function titles:decidePlName($plaID){
    if (starts-with($plaID, 'Q'))
        then titles:getwikidataNames($plaID) 
    else if (starts-with($plaID, 'gn:'))
        then titles:getGeoNames($plaID)
    else
        let $placefile := collection($config:data-rootPl)//id($plaID)
        return
            titles:placeNameSelector($placefile[1])
};

(:Given an id, decides if it is one of BM or from another source and gets the name accordingly:)
declare function titles:decidePlaceNameSource($pRef as xs:string){
if (starts-with($pRef, 'gn:')) then (titles:getGeoNames($pRef)) 
else if (starts-with($pRef, 'pleiades:')) then (titles:getPleiadesNames($pRef)) 
else if (matches($pRef, 'Q\d+')) then (titles:getwikidataNames($pRef)) 
else titles:printTitleID($pRef) 
};

declare function titles:getGeoNames ($string as xs:string){
let $gnid:= substring-after($string, 'gn:')
let $xml-url := concat('http://api.geonames.org/get?geonameId=',$gnid,'&amp;username=betamasaheft')
let $data := httpclient:get(xs:anyURI($xml-url), true(), <Headers/>)
return
if ($data//toponymName) then
$data//toponymName/text()
else 'no data from geonames'
};

declare function titles:getPleiadesNames($string as xs:string) {
   let $plid := substring-after($string, 'pleiades:')
   let $url := concat('http://pelagios.org/peripleo/places/http:%2F%2Fpleiades.stoa.org%2Fplaces%2F', $plid)
  let $file := httpclient:get(xs:anyURI($url), true(), <Headers/>)
  
let $file-info := 
    let $payload := util:base64-decode($file) 
    let $parse-payload := parse-json($payload)
    return $parse-payload 
    return $file-info?title

};

declare function titles:getwikidataNames($pRef as xs:string){
let $sparql := 'SELECT * WHERE {
  wd:' || $pRef || ' rdfs:label ?label . 
  FILTER (langMatches( lang(?label), "EN-GB" ) )  
}'


let $query := 'https://query.wikidata.org/sparql?query='|| xmldb:encode-uri($sparql)

let $req := httpclient:get(xs:anyURI($query), false(), <headers/>)
return
$req//sparql:result/sparql:binding[@name="label"]/sparql:literal[@xml:lang='en-gb']/text()
};



(:takes a node as argument and loops through each element it contains. if it matches one of the definitions it does that, otherways checkes inside it. This actually reproduces the logic of the apply-templates function in  xslt:)
declare function titles:tei2string($nodes as node()*) {
    
    for $node in $nodes
    return
        typeswitch ($node)
        case element(t:title)
                return
                    titles:printTitleMainID($node/@ref)
                             
            case element()
                return
                    titles:tei2string($node/node())
            default
                return
                    $node
};
