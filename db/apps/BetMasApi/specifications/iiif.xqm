xquery version "3.1" encoding "UTF-8";
(:~
 : implementation of the http://iiif.io/api/presentation/2.1/ 
 : for images of manuscripts stored in betamasaheft server. extracts manifest, sequence, canvas from the tei data
 : 
 : @author Pietro Liuzzo 
 :)
module namespace iiif = "https://www.betamasaheft.uni-hamburg.de/BetMas/iiif";
import module namespace rest = "http://exquery.org/ns/restxq";
import module namespace log="http://www.betamasaheft.eu/log" at "xmldb:exist:///db/apps/BetMasWeb/modules/log.xqm";
import module namespace all="https://www.betamasaheft.uni-hamburg.de/BetMasWeb/all" at "xmldb:exist:///db/apps/BetMasWeb/modules/all.xqm";
import module namespace exptit="https://www.betamasaheft.uni-hamburg.de/BetMasWeb/exptit" at "xmldb:exist:///db/apps/BetMasWeb/modules/exptit.xqm";
import module namespace api="https://www.betamasaheft.uni-hamburg.de/BetMasApi/api" at "xmldb:exist:///db/apps/BetMasApi/local/rest.xqm";
import module namespace config = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/config" at "xmldb:exist:///db/apps/BetMasWeb/modules/config.xqm";
import module namespace kwic = "http://exist-db.org/xquery/kwic"
    at "resource:org/exist/xquery/lib/kwic.xql";
import module namespace string = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/string" at "xmldb:exist:///db/apps/BetMasWeb/modules/tei2string.xqm";
import module namespace console = "http://exist-db.org/xquery/console";
import module namespace locus = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/locus" at "xmldb:exist:///db/apps/BetMasWeb/modules/locus.xqm";
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
declare namespace http = "http://expath.org/ns/http-client";
declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace json = "http://www.json.org";


(:
produces jsonLD for the ES manuscripts whose images are exposed by our iipimage server
http://iiif.io/api/presentation/2.0/

:)
declare variable $iiif:collection-rootIn  := collection($config:data-rootIn); 
declare variable $iiif:collection-rootMS  := collection($config:data-rootMS); 
declare variable $iiif:collection-rootW  := collection($config:data-rootW); 

declare variable $iiif:response200 := $config:response200Json;

declare variable $iiif:response400 := $config:response400;

(:functions doing microtasks for the structures :)

declare function iiif:manifestsource($item as node()){
            (:ES:)
            if($item//t:collection = 'Ethio-SPaRe' or ($item//t:repository)[1]/@ref = 'INS0339BML') 
            then $config:appUrl ||'/api/iiif/' || string($item/@xml:id) || '/manifest' 
            else if($item//t:collection = 'EMIP') 
            then $config:appUrl ||'/api/iiif/' || string($item/@xml:id) || '/manifest' 
            (:BNF:)
            else if ($item//t:repository[1][@ref  eq 'INS0303BNF']) 
            then replace($item//t:msIdentifier/t:idno/@facs, 'ark:', 'iiif/ark:') || '/manifest.json'
(:           vatican :)
            else if(starts-with($item//t:msIdentifier/t:idno/@facs, 'http://digi.vatlib')) 
            then replace($item//t:msIdentifier/t:idno/@facs, 'http://', 'https://') 
            else string($item//t:msIdentifier/t:idno/@facs)

};

(:for cases in which there is a facsimile with a @facs linked from the idno/@facs:)
declare function iiif:facsSwitch($idnofacs){
if (starts-with($idnofacs/@facs, '#')) 
then (let $facsimileID := substring-after($idnofacs/@facs, '#') 
            return $idnofacs/ancestor::t:TEI//t:facsimile[@xml:id=$facsimileID]/@facs) 
else $idnofacs/@facs 
};

declare function iiif:locus($l as node()){
  if($l[@from][@to]) 
                            then (let $f := locus:folio($l/@from)
                                     let $t := locus:folio($l/@to)
                                     return
                                    if($l/@facs and not($l/ancestor::t:TEI//t:repository/@ref eq 'INS0303BNF')) 
                                    then 
                                            let $facsF := xs:integer(format-number(number($l/@facs), '###'))
                                            let $facsT := ($facsF + (xs:integer($t) - xs:integer($f)))
                                            for $x in $facsF to $facsT return $x
                                    else 
                                            for $x in $f to $t return $x
                                    ) 
   else if($l[@target]) 
                             then (if(contains($l/@target, ' '))
                                                                  then (   
                                                                                if($l/@facs and not($l/ancestor::t:TEI//t:repository/@ref eq 'INS0303BNF')) 
                                                                                then
                                                                                for $t in tokenize(normalize-space($l/@facs), ' ') return format-number(number($t), '###')
                                                                                else
                                                                                for $t in tokenize(normalize-space($l/@target), ' ') return locus:folio($t)
                                                                            )
                                                                  else (if($l/@facs) then format-number(number($l/@facs), '###') else  locus:folio($l/@target))
                                       )
   else if($l[@from][not(@to)]) 
                            then ( if($l/@facs and not($l/ancestor::t:TEI//t:repository/@ref = 'INS0303BNF')) then format-number(number($l/@facs), '###') else locus:folio($l/@from)) 
   else ()};

declare function iiif:range($iiifroot as xs:string, $structure as xs:string, $title as xs:string, $locusrange){
      let $canvases := for $folio in $locusrange return $iiifroot || '/canvas/p'  || $folio
      let $cs := if(count($canvases) eq 1) then 
      let $lastDigit:= let $thislast := substring-after($canvases, '/canvas/p')
                             let $newnum := number($thislast) +1
                               return replace($canvases, '/p\d+$', ('/p' || xs:string($newnum)))
      return ($canvases, $lastDigit) else $canvases
       return
       map {"@context": "http://iiif.io/api/presentation/2/context.json",
      "@id": $structure,
      "@type": "sc:Range",
      "label": $title,
      "canvases": $cs}
};

declare function iiif:rangetype($iiifroot as xs:string, $name as xs:string, $title as xs:string, $seqran as xs:anyAtomicType+){
map {
      "@id":$iiifroot ||"/range/"|| $name,
      "@type":"sc:Range",
      "label": $title,
      "ranges" : if(count($seqran) = 1) then [$seqran] else $seqran
    }
};

declare function iiif:ranges($iiifroot as xs:string, $ranges as node()){
for $r in $ranges/range
 let $desc := if($r/t:decoNote) then string-join(string:tei2string($r/t:decoNote/t:desc), ' ') || (if($r/t/text()) then (' (' || $r/t || ')') else ())
                        else if($r/t:item[starts-with(@xml:id, 'a') or starts-with(@xml:id, 'e')]) then string-join(string:tei2string($r/t:item/t:desc), ' ')  ||(if($r/t/text()) then (' (' || $r/t || ')') else ())
                        else if($r/t:item[starts-with(@xml:id, 'q')]) then (if($r/t/text()) then $r/t else ())
                        else $r/t
       let $locusrange :=  for $l in $r/t:*/t:locus 
       return iiif:locus($l)
       
      return iiif:range($iiifroot, $r/r, $desc, $locusrange)
};


declare function iiif:rangeAndsubrange($iiifroot as xs:string, $ranges as node(), $name as xs:string, $title as xs:string){
let $seqran :=  for $r in $ranges/range return $r/r
       return
  (iiif:rangetype($iiifroot, $name, $title, $seqran),
       iiif:ranges($iiifroot, $ranges)
   )
};


(:parts used by different requests:)

declare function iiif:annotation($id, $image, $resid){
map {"@context":"http://iiif.io/api/presentation/2/context.json",
      "@id": substring-before($id, '/canvas') || "/annotation/p0001-image",
  
      "@type": "oa:Annotation",
      "motivation": "sc:painting",
      "resource": map {
                    "@id": $image,
                    "@type": "dctypes:Image",
                    "format": "image/jpeg",
                    "service": map {
                        "@context": "http://iiif.io/api/image/2/context.json",
                        "@id": $resid,
                        "profile": "http://iiif.io/api/image/2/level1.json"
                    },
                    "height":1500,
                    "width":2000
                },
                "on": $id
              
    }
};

declare function iiif:oneCanvas($id, $name, $image, $resid){

map {"@context": "http://iiif.io/api/presentation/2/context.json",
                   "@id": $id,
                   "@type": "sc:Canvas",
                   "label": $name,
                   "height":7500,
  "width":10000, 
  "images": [
    map {"@context":"http://iiif.io/api/presentation/2/context.json",
      "@id": substring-before($id, '/canvas') || "/annotation/p0001-image",
  
      "@type": "oa:Annotation",
      "motivation": "sc:painting",
      "resource": map {
                    "@id": $image,
                    "@type": "dctypes:Image",
                    "format": "image/jpeg",
                    "service": map {
                        "@context": "http://iiif.io/api/image/2/context.json",
                        "@id": $resid,
                        "profile": "http://iiif.io/api/image/2/level1.json"
                    },
                    "height":1500,
                    "width":2000
                },
                "on": $id
              
    }
  ]
                               }

};


declare function iiif:Canvases($item, $id, $iiifroot, $facsid){
let $tot := $facsid/@n
let $facs := iiif:facsSwitch($facsid)
let $imagesbaseurl := $config:appUrl ||'/iiif/' || $facs
       
       return
 for $graphic at $p in 1 to $tot 
            let $n := $p
             let $imagefile := format-number($graphic, '000') || '.tif'
             let $resid := ($imagesbaseurl || (if($item//t:collection='Ethio-SPaRe') then '_' else ()) || $imagefile )
             let $image := ($imagesbaseurl || (if($item//t:collection='Ethio-SPaRe') then '_'  else ()) || $imagefile || '/full/full/0/default.jpg' )
            let $name := string($n)
            let $id := $iiifroot || '/canvas/p'  || $n
              order by $p 
              return iiif:oneCanvas($id, $name, $image, $resid)
};

declare function iiif:msItemRange($msItem, $iiifroot){
   <range>
    <r>{$iiifroot ||"/range/" || string($msItem/@xml:id)}</r>
    <t>{if ($msItem/t:title[1]/text()) then string($msItem/t:title[1]) else if ($msItem/t:title[1]/@ref) then exptit:printTitleID(substring-after($msItem/t:title[1]/@ref, 'eu/')) else 'item ' || string($msItem/@xml:id)}</t>
    {$msItem}
    </range>};

declare function iiif:collationRange($q, $iiifroot){
    <range>
    <r>{$iiifroot ||"/range/" || string($q/@xml:id)}</r>
    <t>{normalize-space(string-join($q/text(), ' ')|| ' (' ||$q/t:dim/text()||')')}</t>
    {$q}
    </range>};

declare function iiif:additionsRange($a, $iiifroot){
    <range>
    <r>{$iiifroot ||"/range/" || string($a/@xml:id)}</r>
    <t>{string($a/t:desc/@type)}</t>
    {$a}
    </range>};
    
  declare function iiif:decorationsRange($d, $iiifroot){
 <range>
    <r>{$iiifroot ||"/range/" || string($d/@xml:id)}</r>
    <t>{string($d/@type)}</t>
    {$d}
    </range>}; 
   
declare function iiif:makeRanges($nodes, $iiifroot, $elements, $rangetype){
 let $ranges :=  <ranges>{
 for $n in $nodes return 
 switch($elements) 
 case 'quires' return iiif:collationRange($n, $iiifroot) 
 case 'decorations' return iiif:decorationsRange($n, $iiifroot) 
 case 'additions' return iiif:additionsRange($n, $iiifroot) 
(: msitems:)
default return iiif:msItemRange($n, $iiifroot)
}
</ranges>
 return
   iiif:rangeAndsubrange($iiifroot, $ranges, $elements, $rangetype)
   };

declare function iiif:Structures($item, $iiifroot, $facsid){
 let $items := $item//t:msItem[t:locus][t:title[@ref]]
       let $collation := $item//t:collation/t:list/t:item[.//t:locus]
       let $additions := $item//t:additions/t:list/t:item[.//t:locus]
       let $decorations := $item//t:decoNote[.//t:locus]
      
      let  $mainstructure := if ($items or $collation or $additions or $decorations) then (
      let $superRanges := 
      let $its := if ($items) then  $iiifroot || "/range/"|| "msItems" else ()
      let $colls := if ($collation) then  $iiifroot ||"/range/"|| "quires" else ()
      let $adds := if ($additions) then  $iiifroot ||"/range/"|| "additions" else ()
      let $decs := if ($decorations) then  $iiifroot ||"/range/"|| "decorations" else ()
      return ($its, $colls, $adds, $decs)
      return
      map {"@context": "http://iiif.io/api/presentation/2/context.json",
      "@id":$iiifroot ||"/range/"|| "main",
      "@type":"sc:Range",
      "label":"Table of Contents",
      "viewingHint":"top",
      "ranges" : $superRanges
    }) else ()
    
   let $msItemStructures :=  iiif:rangeexistence($items,$iiifroot, 'msItems', 'Contents') 
   let  $quiresStructures :=   iiif:rangeexistence($collation,$iiifroot, 'quires', 'Collation')
   let  $additionsStructures :=  iiif:rangeexistence($additions, $iiifroot, 'additions', 'Additions and Extras') 
   let  $decorationStructures := iiif:rangeexistence($decorations, $iiifroot, 'decorations', 'Decorations') 
  
  return
  ($mainstructure, $msItemStructures, $quiresStructures, $decorationStructures, $additionsStructures)
    
};

(:for multiple manifests:)
declare function iiif:multipleManifests($item as node()) {
  let $mainID := $item//t:msIdentifier/t:idno[@facs]
  let $altIDs := $item//t:altIdentifier/t:idno[@facs]
  let $allIDNos := ($mainID, $altIDs)
  
  return 
    for $idno in $allIDNos
    let $parent := $idno/parent::node()
    let $alt := if ($parent/name() = 'altIdentifier') then if($parent/@xml:id) then
                  ('?alt=' || string($parent/@xml:id)) else ('?alt=alt')
                else ()
   let $label := if ($parent/name() = 'altIdentifier') then concat(exptit:printTitleID($item/@xml:id), ': subset for ',  string($parent/t:idno)) else exptit:printTitleID($item/@xml:id)
    let $facs := iiif:facsSwitch($idno)
    return 
      if ($facs) then 
        map {
          '@id': replace($facs, 'ark:', 'iiif/ark:') || '/manifest.json',
          'label': $label || $alt
        }
      else ()
};

(:switch single or multiple:)
declare function iiif:manifest($this as node()) {
  let $manifest :=
    if (count($this//t:idno[@facs]) = 1) then
      iiif:manifestsource($this)
    else
      iiif:multipleManifests($this/ancestor::t:TEI)
  let $tit := try { exptit:printTitleID($this/@xml:id) } catch * { $err:description }
  return map {
    'label': $tit,
    '@type': 'sc:Manifest',
    '@id': $manifest
  }
};

declare function iiif:placemanifest (){
 let $placesfacs :=$iiif:collection-rootIn//t:desc[@facs]
 return 
 for $facs in $placesfacs
let $id :=$facs/ancestor::t:TEI/@xml:id
let $label :=exptit:printTitleID($id)
let $manifestId:=$config:appUrl || '/api/iiif/' || $id || '/manifest'
return map{
  'label': $label,
  '@type': 'sc:Manifest',
  '@id': $manifestId
}
 };

(:collection of all manifests available. this is called by rest viewer /manuscripts/viewer in the miradorcoll.js:)
        declare 
%rest:GET
%rest:path("/api/iiif/collections")
%output:method("json")
function iiif:allManifests() {
($iiif:response200,
log:add-log-message('/api/iiif/collections', sm:id()//sm:real/sm:username/string() , 'iiif'),
      let $allidno := $iiif:collection-rootMS//t:idno[@facs]
let $EMIP := $allidno[preceding-sibling::t:collection eq 'EMIP'][@n]
let $ES := $allidno[preceding-sibling::t:collection eq 'Ethio-SPaRe'][@n]
let $vat := $allidno[preceding-sibling::t:repository[@ref eq 'INS0003BAV']]
let $bnf := $allidno[preceding-sibling::t:repository[@ref eq 'INS0303BNF']]
let $bml := $allidno[preceding-sibling::t:repository[@ref eq 'INS0339BML']]
let $filtered := ($ES, $EMIP, $vat, $bnf, $bml)
    let $manifests := 
      for $item in $filtered
      let $this := $item/ancestor::t:TEI
      let $cnt := count($this//t:idno[@facs])
      let $manifest := 
        if ($cnt = 1) then
          iiif:manifestsource($this)
        else
          iiif:multipleManifests($this)
      let $tit := if ($parent/name() = 'altIdentifier') then concat(exptit:printTitleID($item/@xml:id), ': subset for ',  string($parent/t:idno)) else  try { exptit:printTitleID($this/@xml:id) } catch * { $err:description }
      return map {
        "label": $tit,
        "@type": "sc:Manifest",
        "@id": $manifest
      }
    let $placeManifests := iiif:placemanifest()
    let $iiifroot := $config:appUrl || "/api/iiif/"
    let $request := $iiifroot || "/collections"

    return map {
      "@context": "http://iiif.io/api/presentation/2/context.json",
      "@id": $request,
      "@type": "sc:Collection",
      "label": "Top Level Collection for " || $config:app-title,
      "viewingHint": "top",
      "description": "All images of Ethiopian Manuscripts available",
      "attribution": "Provided by Bibliothèque nationale de France, The Vatican Library, Ethio-SPaRe, EMIP, Biblioteca Medicea Laurenziana and other IIIF providers",
      "manifests": ($manifests, $placeManifests)
    }
  )
};


(:collection of all manifests available from one institution. this is called by rest viewer /manuscripts/{$repoid}/list/viewer in the miradorcoll.js:)

    declare 
%rest:GET
%rest:path("/api/iiif/collection/{$institutionid}")
%output:method("json")
function iiif:RepoCollection($institutionid as xs:string) {
($iiif:response200,

log:add-log-message('/api/iiif/collections/' || $institutionid, sm:id()//sm:real/sm:username/string() , 'iiif'),
let $repoName := exptit:printTitleID($institutionid)
let $repo := $iiif:collection-rootMS//t:repository[@ref eq $institutionid]
let $mswithimages := 
        if($institutionid='INS0447EMIP') 
        then $repo[following-sibling::t:idno[@facs][@n]] 
        else $repo[following-sibling::t:idno[@facs]]
let $manifests :=
                for $images in $mswithimages
                let $this := $images/ancestor::t:TEI
                let $idno := $images/following-sibling::t:idno[@facs]
                let $manifest := iiif:manifestsource($this)
                    return
                            map {'label' : exptit:printTitleID($this/@xml:id) ,
                                        '@type': "sc:Manifest", 
                                        '@id' : $manifest}

 let $iiifroot := $config:appUrl ||"/api/iiif/"
(:       this is where the manifest is:)
let $request := $iiifroot || "/collections"
 return
        map {
  "@context": "http://iiif.io/api/presentation/2/context.json",
  "@id": $request,
  "@type": "sc:Collection",
  "label": "Ethiopian Manuscripts at "  || $repoName,
  "viewingHint": "top",
  "description": "All images of Ethiopian Manuscripts available",
  "attribution": "Provided by " || $repoName,
  "manifests":  $manifests
   
  
}
      )  };


    declare 
%rest:GET
%rest:path("/api/iiif/witnesses/{$workID}")
%output:method("json")
function iiif:WitnessesCollection($workID as xs:string) {
($iiif:response200,

log:add-log-message('/api/iiif/witnesses/' || $workID, sm:id()//sm:real/sm:username/string() , 'iiif'),
let $workName := exptit:printTitleID($workID)
let $work := $iiif:collection-rootW/id($workID)
let $mswithimages := $work//t:witness[@corresp]
let $externalmswithimages := $work//t:witness[@facs][t:ptr/@target]
let $listmanifests :=
(for $images in $mswithimages
let $msid := $images/@corresp
let $ms := $iiif:collection-rootMS/id($msid)
return
if($ms//t:idno[@facs]) then

let $manifest := iiif:manifestsource($ms)
         return
             map {'label' : exptit:printTitleID($msid)  ,
      "@type": "sc:Manifest", 
      '@id' : $manifest}
   else (),
for $images in $externalmswithimages
let $this := concat($images/t:idno/text(), ': ', string-join($images/text(), ' '), ' [', $images/@facs, ']')
let $manifest := string($images/t:ptr/@target)
         return
             map {'label' : $this ,
      "@type": "sc:Manifest", 
      '@id' : $manifest}
      )
let $manifests := if(count($listmanifests) eq 1) then [$listmanifests] else $listmanifests
 let $iiifroot := $config:appUrl ||"/api/iiif/"
(:       this is where the manifest is:)
       let $request := $iiifroot || "/collections"
 
        
        return
        map {
  "@context": "http://iiif.io/api/presentation/2/context.json",
  "@id": $request,
  "@type": "sc:Collection",
  "label": "Manuscript witnesses of "  || $workName,
  "viewingHint": "top",
  "description": "All available images of witnesses",
  "attribution": "Provided by various institutions, see each manifest",
  "manifests":  $manifests
   
  
}
      )  };


(:manifest for one manuscript, including all ranges and canvases:)
(:IIIF: The manifest response contains sufficient information for the client to initialize itself and begin to display something quickly to the user. The manifest resource represents a single object and any intellectual work or works embodied within that object. In particular it includes the descriptive, rights and linking information for the object. It then embeds the sequence(s) of canvases that should be rendered to the user.:)
declare 
%rest:GET
%rest:path("/api/iiif/{$id}/manifest")
%rest:query-param("alt", "{$alt}", "")
%output:method("json") 
function iiif:manifest($id as xs:string*, $alt as xs:string*) {
let $item := if (starts-with($id, 'ES')) then collection($config:data-rootMS || '/ES')/id($id) 
                    else if (starts-with($id, 'BML')) then collection($config:data-rootMS || '/FlorenceBML')/id($id) 
                    else if (starts-with($id, 'EMIP')) then  collection($config:data-rootMS || '/EMIP')/id($id)
                    else $exptit:col/id($id)
let $facsid := if($alt = '') then ($item//t:msIdentifier/t:idno[@facs], $item//t:place//t:desc[@facs])[1] else ($item//t:altIdentifier[@xml:id eq $alt]/t:idno[@facs], $item//t:place//t:desc[@facs])[1] 
let $facs :=iiif:facsSwitch($facsid) (:returns an attribute @facs:)
return
       if($facs) then
($iiif:response200,

log:add-log-message('/api/iiif/'||$id||'/manifest', sm:id()//sm:real/sm:username/string() , 'iiif'),

       let $institutionID := if ($item//t:repository) then string(($item//t:repository)[1]/@ref) else $id

       let $institution := exptit:printTitleID($institutionID)
let $imagesbaseurl := $config:appUrl ||'/iiif/' || $facs
       let $tot := $facsid/@n
       let $url :=  $config:appUrl ||(if($item/ancestor::t:TEI/@type="ins") then "/institutions/"  else"/manuscripts/") || $id
      (:       this is where the images actually are, in the images server:)
       let $thumbid := $imagesbaseurl ||(if($item//t:collection='Ethio-SPaRe') then '_'  else ()) || '001.tif/full/80,100/0/default.jpg'
       let $objectType := string($item//@form[1])
       let $iiifroot := $config:appUrl ||"/api/iiif/" || $id
       let $image := $config:appUrl ||'/iiif/'||$id||'/'
       let $canvas := iiif:Canvases($item, $id, $iiifroot, $facsid)
       let $structures := iiif:Structures($item, $iiifroot, $facsid)
(:       this is where the manifest is:)
       let $request := $iiifroot || "/manifest" || (if ($facsid/parent::t:altIdentifier/@xml:id) then '?alt=' || string($facsid/parent::t:altIdentifier/@xml:id) else if ($facsid/parent::t:altIdentifier) then '?alt=alt' else ())
       (:       this is where the sequence is:)
       let $attribution := if($item//t:repository[1][@ref eq 'INS0339BML']) then ('The images of the manuscript taken by Antonella Brita, Karsten Helmholz and Susanne Hummel during a mission funded by the Sonderforschungsbereich 950 Manuskriptkulturen in Asien, Afrika und Europa, the ERC Advanced Grant TraCES, From Translation to Creation: Changes in Ethiopic Style and Lexicon from Late Antiquity to the Middle Ages (Grant Agreement no. 338756) and Beta maṣāḥǝft. The images are published in conjunction with this descriptive data about the manuscript with the permission of the https://www.bmlonline.it/la-biblioteca/cataloghi/, prot. 190/28.13.10.01/2.23 of the 24 January 2019 and are available for research purposes.') else "Provided by "||(if ($item//t:collection/text()) then string-join($item//t:collection/text(), ', ') else "Bm") ||" project. " || (if($item//t:editionStmt/t:p) then string-join($item//t:editionStmt/t:p/string()) else ' ')
       let $logo := if($item//t:repository[1][@ref eq 'INS0339BML']) then ('/rest/BetMasWeb/resources/images/logobml.png') else "/rest/BetMasWeb/resources/images/logo"||string-join($item//t:collection[1][not(matches(.,'\s'))]/text())||".png"
       let $sequence := $iiifroot || "/sequence/normal"
    let $parent := $facsid/parent::node()
   let $label := if ($parent/name() = 'altIdentifier') then concat(exptit:printTitleID($item/@xml:id), ': subset for ',  string($parent/@xml:id)) else exptit:printTitleID($item/@xml:id)

     
(:    $mainstructure:)
return 
map {"@context": "http://iiif.io/api/presentation/2/context.json",
  "@id": $request,
  "@type": "sc:Manifest",
  "label": $label,
  "metadata": [
    map {"label": "Repository", 
                "value": [
                  map   {"@value": '<a href="'||$config:appUrl||'/manuscripts/'||$institutionID||'/list">'||$institution ||'</a>' , "@language": "en"}
                            ]
      }, 
      map {"label": "object type", 
                "value": [
                  map   {"@value": $objectType, "@language": "en"}
                            ]
      }, 
      map {"label": "main view", 
                "value": $config:appUrl ||'/'|| $id
      }
      ],
      "description" : "An Ethiopian Manuscript.",
     
      
    "viewingDirection": "left-to-right",
  "viewingHint": "paged",
  "license": "http://creativecommons.org/licenses/by-nc-nd/4.0/",
  "attribution": $attribution,
  "logo": map {
    "@id": $config:appUrl || $logo
    },
"rendering": map {
    "@id": $url,
    "label": "web presentation",
    "format": "text/html"
  },
  "within": $config:appUrl ||"/manuscripts/list",

  "sequences": [ 
   map   {"@context": "http://iiif.io/api/presentation/2/context.json",
        "@id": $sequence,
        "@type": "sc:Sequence",
        "label": "Current Page Order",
  "viewingDirection": "left-to-right",
  "viewingHint": "paged",
  "canvases": $canvas
       }
      ],
  "structures": $structures
    }
    )
    else 
      ($iiif:response400,
       
       map{'info': ('no manifest available for ' || $id )}
   )
};

declare function iiif:rangeexistence($nodes, $iiifroot, $element, $name){
if($nodes) then iiif:makeRanges($nodes,$iiifroot, $element, $name) else ()
};

declare 
%rest:GET
%rest:path("/api/iiif/{$id}/range/{$rangeId}")
%rest:query-param("alt", "{$alt}", "")
%output:method("json") 
function iiif:singerange($id as xs:string*, $rangeId as xs:string*, $alt as xs:string*) {
let $item := if (starts-with($id, 'ES')) then collection($config:data-rootMS || '/ES')/id($id) 
                    else if (starts-with($id, 'BML')) then collection($config:data-rootMS || '/FlorenceBML')/id($id) 
                    else if (starts-with($id, 'EMIP')) then  collection($config:data-rootMS || '/EMIP')/id($id)
                    else $exptit:col/id($id)
let $facsid := if($alt = '') then ($item//t:msIdentifier/t:idno[@facs], $item//t:place//t:desc[@facs])[1] else ($item//t:altIdentifier[@xml:id eq $alt]/t:idno[@facs], $item//t:place//t:desc[@facs])[1] 
let $facs :=iiif:facsSwitch($facsid) (:returns an attribute @facs:)
return
       if($facs) then
($iiif:response200,

log:add-log-message('/api/iiif/'||$id||'/range/'||$rangeId, sm:id()//sm:real/sm:username/string() , 'iiif'),

       let $institutionID := if ($item//t:repository) then string(($item//t:repository)[1]/@ref) else $id

       let $institution := exptit:printTitleID($institutionID)
let $imagesbaseurl := $config:appUrl ||'/iiif/' || string($facs)
       let $tot := $facsid/@n
       let $url :=  $config:appUrl ||(if($item/ancestor::t:TEI/@type="ins") then "/institutions/"  else"/manuscripts/") || $id
      (:       this is where the images actually are, in the images server:)
       let $thumbid := $imagesbaseurl ||(if($item//t:collection='Ethio-SPaRe') then '_'  else ()) || '001.tif/full/80,100/0/default.jpg'
       let $objectType := string($item//@form[1])
       let $iiifroot := $config:appUrl ||"/api/iiif/" || $id
       let $mainranges := ('msItems', 'decorations', 'additions', 'quires')
return
if ($rangeId = $mainranges) then (

(:a superrange:)
        switch ($rangeId)
            case 'decorations' return iiif:rangeexistence($item//t:decoNote[.//t:locus], $iiifroot, 'decorations', 'Decorations')
            case 'additions' return iiif:rangeexistence($item//t:additions/t:list/t:item[.//t:locus], $iiifroot, 'additions', 'Additions and Extras')
            case 'quires' return iiif:rangeexistence($item//t:collation/t:list/t:item[.//t:locus], $iiifroot,  'quires', 'Collation')
            (:default on msItems:)
            default return iiif:rangeexistence($item//t:msItem[t:locus][t:title[@ref]], $iiifroot, 'msItems', 'Contents')
            
)
else if (count($item/id($rangeId)) = 1)
then (
let $singleRange :=  $item/id($rangeId)
let $elements := switch($rangeId)
case starts-with($rangeId, 'a') return 'additions'
case starts-with($rangeId, 'e') return 'additions'
case starts-with($rangeId, 'd') return 'decorations'
case starts-with($rangeId, 'q') return 'quires'
default return 'msItems'

let $rangeType := switch($rangeId)
case starts-with($rangeId, 'a') return 'Additions and Extras'
case starts-with($rangeId, 'e') return 'Additions and Extras'
case starts-with($rangeId, 'd') return 'Decorations'
case starts-with($rangeId, 'q') return 'Collation'
default return 'Contents'
return 
iiif:makeRanges($singleRange, $iiifroot, $elements, $rangeType)
)
else  
($iiif:response400,
       
       map{'info': ('no rage available for ' || $rangeId || ' in '|| $id)}
   )
)
    else 
      ($iiif:response400,
       
       map{'info': ('no manifest available for ' || $id )}
   )
};




(:dereferencable sequence The sequence conveys the ordering of the views of the object.:)
declare 
%rest:GET
%rest:path("/api/iiif/{$id}/sequence/normal")
%rest:query-param("alt", "{$alt}", "")
%output:method("json")
function iiif:sequence($id as xs:string*, $alt as xs:string*) {
($iiif:response200,

log:add-log-message('/api/iiif/'||$id||'/sequence/normal', sm:id()//sm:real/sm:username/string() , 'iiif'),
        let $item := collection($config:data-rootMS || '/ES')/id($id)
let $facsid := if($alt = '') then ($item//t:msIdentifier/t:idno[@facs], $item//t:place//t:desc[@facs])[1] else ($item//t:altIdentifier[@xml:id eq $alt]/t:idno[@facs], $item//t:place//t:desc[@facs])[1] 
let $iiifroot := $config:appUrl ||"/api/iiif/" || $id
let $sequence := $iiifroot || "/sequence/normal"
let $startCanvas := $iiifroot || '/canvas/p1'

let $canvas := iiif:Canvases($item, $id, $iiifroot, $facsid)

       return
       
       map{"@context": "http://iiif.io/api/presentation/2/context.json",
  "@id": $sequence,
  "@type": "sc:Sequence",
  "label": "Current Page Order",
  "viewingDirection": "left-to-right",
  "viewingHint": "paged",
  "startCanvas": $startCanvas,
  "canvases": $canvas}
       )};
       
       
(:   dereference    canvas:)

(:IIIF: The canvas represents an individual page or view and acts as a central point for laying out the different content resources that make up the display. :)
       declare 
%rest:GET
%rest:path("/api/iiif/{$id}/canvas/p{$n}")
%rest:query-param("alt", "{$alt}", "")
%output:method("json")
function iiif:canvas($id as xs:string*, $n as xs:string*, $alt as xs:string*) {
($iiif:response200,

log:add-log-message('/api/iiif/'||$id||'/canvas/p' || $n, sm:id()//sm:real/sm:username/string() , 'iiif'),
let $item := $iiif:collection-rootMS/id($id)
let $facsid := if($alt = '') then ($item//t:msIdentifier/t:idno[@facs], $item//t:place//t:desc[@facs])[1] else ($item//t:altIdentifier[@xml:id eq $alt]/t:idno[@facs], $item//t:place//t:desc[@facs])[1] 
let $facs :=iiif:facsSwitch($facsid) (:returns an attribute @facs:)
let $iiifroot := $config:appUrl ||"/api/iiif/" || $id 
let $imagesbaseurl := $config:appUrl ||'/iiif/' || $facs
 let $imagefile := format-number($n, '000') || '.tif'
let $resid := ($imagesbaseurl || (if($item//t:collection='Ethio-SPaRe') then '_'  else ()) || $imagefile )
 let $image := ($imagesbaseurl || (if($item//t:collection='Ethio-SPaRe') then '_'  else ()) || $imagefile || '/full/full/0/default.jpg' )
let $name := string($n)
let $id := $iiifroot || '/canvas/p'  || $n
       return
       iiif:oneCanvas($id, $name, $image, $resid)
      ) };