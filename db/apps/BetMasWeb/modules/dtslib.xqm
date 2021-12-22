xquery version "3.1" encoding "UTF-8";
(:~
 : test implementation of the https://github.com/distributed-text-services
 : SERVER
 : @author Pietro Liuzzo 
 :
 : to do 
 : if I want to retrive 1ra@ወወልድ[1]-3vb, should the  @ወወልድ[1] piece also be in the passage/start/end parameter 
: 
: add possibility of having a collection grouping by institution or catalogue for the manuscripts
: 
: urn:dtslib:betmasMS:INS0012bla:BLorient12314
:
: urn:dtslib:betmasMS:Zotemberg1234:BLorient12314
 :)

module namespace dtslib="https://www.betamasaheft.uni-hamburg.de/BetMasWeb/dtslib";

declare namespace t="http://www.tei-c.org/ns/1.0";
declare namespace exist = "http://exist.sourceforge.net/NS/exist";
declare namespace s = "http://www.w3.org/2005/xpath-functions";
declare namespace http = "http://expath.org/ns/http-client";
declare namespace json = "http://www.json.org";
declare namespace cx ="http://interedition.eu/collatex/ns/1.0";
declare namespace sr="http://www.w3.org/2005/sparql-results#";
declare namespace test="http://exist-db.org/xquery/xqsuite";
import module namespace functx="http://www.functx.com";
import module namespace log="http://www.betamasaheft.eu/log" at "xmldb:exist:///db/apps/BetMasWeb/modules/log.xqm";
import module namespace exptit="https://www.betamasaheft.uni-hamburg.de/BetMasWeb/exptit" at "xmldb:exist:///db/apps/BetMasWeb/modules/exptit.xqm";
import module namespace config="https://www.betamasaheft.uni-hamburg.de/BetMasWeb/config" at "xmldb:exist:///db/apps/BetMasWeb/modules/config.xqm";
import module namespace fusekisparql = 'https://www.betamasaheft.uni-hamburg.de/BetMasWeb/sparqlfuseki' at "xmldb:exist:///db/apps/BetMasWeb/fuseki/fuseki.xqm";
import module namespace string = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/string" at "xmldb:exist:///db/apps/BetMasWeb/modules/tei2string.xqm";
import module namespace switch2 = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/switch2" at "xmldb:exist:///db/apps/BetMasWeb/modules/switch2.xqm";
import module namespace editors = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/editors" at "xmldb:exist:///db/apps/BetMasWeb/modules/editors.xqm";
import module namespace console="http://exist-db.org/xquery/console";

declare variable $dtslib:context := map{
        "@vocab": "https://www.w3.org/ns/hydra/core#",
        "dc": "http://purl.org/dc/terms/",
        "dts": "https://w3id.org/dts/api#",
        "tei": "http://www.tei-c.org/ns/1.0",
        "saws": "http://purl.org/saws/ontology#",
        "crm": "http://www.cidoc-crm.org/cidoc-crm/",
        "ecrm": "http://erlangen-crm.org/current/",
        "fabio": "http://purl.org/spar/fabio",
        "lawd": "http://lawd.info/ontology/",
        "edm": "http://www.europeana.eu/schemas/edm/",
        "svcs": "http://rdfs.org/sioc/services#",
        "doap": "http://usefulinc.com/ns/doap#",
        "foaf": "http://xmlns.com/foaf/0.1/",
        "sc": "http://iiif.io/api/presentation/2#"
  };
  declare variable $dtslib:publisher := map {
        "dc:publisher": ["Akademie der Wissenschaften in Hamburg", "Hiob-Ludolf-Zentrum für Äthiopistik"],
        "dc:description": [
            map {
                "@lang": "en",
                "@value": "The project Beta maṣāḥǝft: Manuscripts of Ethiopia and Eritrea (Schriftkultur des christlichen Äthiopiens: eine multimediale Forschungsumgebung) is a long-term project funded within the framework of the Academies' Programme (coordinated by the Union of the German Academies of Sciences and Humanities) under survey of the Akademie der Wissenschaften in Hamburg. The funding will be provided for 25 years, from 2016–2040. The project is hosted by the Hiob Ludolf Centre for Ethiopian Studies at the University of Hamburg. It aims at creating a virtual research environment that shall manage complex data related to predominantly Christian manuscript tradition of the Ethiopian and Eritrean Highlands."
            }
        ]
    };
  declare variable $dtslib:regexCol := "(https://betamasaheft.eu/)(textualunits|narrativeunits|transcriptions)?";
  declare variable $dtslib:regexID := "([a-zA-Z\d]+)?(_(ED|TR)_([a-zA-Z0-9]+)?)?(\.)?(((\d+)(\w)?(\w)?((@)([\p{L}]+)(\[(\d+|last)\])?)?)?(\-)?((\d+)(\w)?(\w)?((@)([\p{L}]+)(\[(\d+|last)\])?)?)?)";
   
  declare variable $dtslib:collection-rootMS  := collection($config:data-rootMS); 
  declare variable $dtslib:collection-rootW  := collection($config:data-rootW); 
  declare variable $dtslib:collection-rootN  := collection($config:data-rootN); 
  declare variable $dtslib:collection-rootS  := collection($config:data-rootS); 
  declare variable $dtslib:collection-root  := $exptit:col;
   
   declare %private function dtslib:capitalize-first ( $arg as xs:string? )  as xs:string? {
   concat(upper-case(substring($arg,1,1)),
             substring($arg,2))
 } ;
 
  declare function dtslib:fileingitCommits($id, $bmID, $apitype){
  let $file := $exptit:col/id($bmID)[self::t:TEI]
let $collection := if($file/@type eq 'mss') then 'Manuscripts' else if($file/@type eq 'nar') then 'Narrative' else 'Works'
let $permapath := replace(dtslib:capitalize-first(substring-after(base-uri($file), '/db/apps/BetMasData/')), $collection, '')
let $url := 'https://api.github.com/repos/BetaMasaheft/' || $collection || '/commits?path=' || $permapath
  let $request := <http:request href="{xs:anyURI($url)}" method="GET"/>
    let $file := try{http:send-request($request)[2]} catch * {$err:code}
  
let $file-info := 
    let $payload := util:base64-decode($file) 
    let $parse-payload := parse-json($payload)
    return $parse-payload 
    
for $sha in $file-info?*
return 
 '/permanent/'||$sha?sha||'/api/dts/'||$apitype||'?id='||$id
  
};
  
  (:~ Takes a  node cx:apparatus which have TEI apparatus criticus tags (app, rdg) typically the result of a collatex request for tei. It returns a string with the minimal contents and formatting :)
declare %private function dtslib:apparatus2string($apparatus as node()*){
 for $node in $apparatus
    return
        typeswitch ($node)
        case element(cx:apparatus)
                return <div>{dtslib:apparatus2string($node/node())}</div>
        case element(t:app)
                return <div class="row">{dtslib:apparatus2string($node/node())}</div>
        case element(t:rdg)
                return <div>{string($node/@wit)}{dtslib:apparatus2string($node/node())}</div>
        case text()
                return if ($node/parent::cx:apparatus) then <div class="row">{dtslib:apparatus2string($node/node())}</div> else $node
        case element()
                return
                    dtslib:apparatus2string($node/node())
        default
                return
                    $node
};

(:~ Given a dts URI  parse with analyse string the urn to split it into its components. :)
declare function dtslib:parseDTS($dts){
let $regex := ($dtslib:regexCol || $dtslib:regexID)
return
analyze-string($dts,$regex)
};

(:~ Given a dts URI resource part only (without domain) 
parse with analyse string the urn to split it into its components. :)
declare %private function dtslib:parseDTSid($dts){
analyze-string($dts,$dtslib:regexID)
};


(:~ Xpath to select the text nodes requested from a manuscript given the transcription nodes in div[@type eq 'edition'] starting page break and column break :)
declare %private function dtslib:passageSelector($text, $pb, $cb){
if($cb='') then  $text//t:ab//text()[preceding::t:pb[position()=1][@n = $pb]]
else $text//t:ab//text()[preceding::t:pb[position()=1][@n = $pb] and preceding::t:cb[position()=1][@n = $cb]]
};

(:~ Xpath to select the nodes requested  from a manuscript given the transcription nodes in div[@type eq 'edition'] :)
declare %private function dtslib:TranscriptionPassageNodes($text, $pb, $cb){
if($cb='') then 
$text//t:ab//node()[preceding::t:pb[position()=1][@n = string($pb)]]

else
$text//t:ab//node()[preceding::t:pb[position()=1][@n = $pb] and preceding::t:cb[position()=1][@n = $cb]]
};

declare %private function dtslib:TranscriptionPassageNodesLB($text, $lb){
$text//t:ab//node()[preceding::t:lb[position()=1][@n = string($lb)]]
};

(:~ Xpath to select the nodes requested from a work given passage with two levels :)
declare %private function dtslib:EditionPassageNodes($text, $level1, $level2){
if($level2='') then 
$text//t:*[number(@n)= $level2][parent::t:*[@n=$level1]]

else
$text//t:*[number(@n)=$level1][parent::t:*[@type eq 'edition']]
};

(:~ Xpath to select the nodes requested from a work given passage with two levels. If a part of the content of a div is requested, then the div will be reproduced with the @n only and used to wrap the relevant subparts:)
declare %private function dtslib:EditionPassageNodesRange($text, $level1, $level2, $startOrEnd){

if($level2='') then 
<div xmlns="http://www.tei-c.org/ns/1.0" n="{$level1}">{
if($startOrEnd = 'start') 
then 
(:it is the beginning of the range:)
$text//t:*[number(@n) ge $level2][parent::t:*[@n=$level1]]
else 
(:it is the end of the range:)
$text//t:*[number(@n) le $level2][parent::*[@n=$level1]]
}</div>
else
$text/t:*[number(@n)= $level1]

};

(:~ Gets the selected text nodes and checks p1 and p2 in the parsed dts urn which are respectively the @ sign which might be there if there is a text anchor and the actual text of the anchor, to further limit the text selected. parsedURN parameter expects nodes result of fn:analyze-string prefixed with s::)
declare %private function dtslib:TranscriptionPassageText ($parsedURN, $p1, $p2, $text, $pb, $cb){
let $nodes := dtslib:passageSelector($text, $pb, $cb) 

let $join := string-join($nodes, '')
return
if($parsedURN//s:group[@nr=$p1] = '@') 
    then 
    let $position := 
                    if(matches($parsedURN//s:group[@nr=$p2], '\d+')) 
                    then $parsedURN//s:group[@nr=$p2]/text() 
                    else if ($parsedURN//s:group[@nr=$p2]= 'last') 
                    then 'last()' 
                    else '1'
    let $term := $parsedURN//s:group[@nr=12]/text()
    let $indexposition := functx:index-of-string($join,$term) 
    let $index := if(count($indexposition) = 1) then $indexposition else util:eval('$indexposition[' || $position || ']')
            return normalize-space(substring($join, $index))
(:otherways the entire:)
    else normalize-space($join)};



declare %private function dtslib:nodes($text, $path, $ref){
(:let $test := util:log("info",$text):)
for $selector in util:eval($path)
(:let $t2 := util:log("info",$selector):)
                        return 
                        if(matches($ref, '(\d+[r|v][a-z]?(\[\w+\])?|\d+[r|v]?[a-z]?(\[\w+\]))'))
                        then 
(:let $t2 := util:log("info",$ref):)
                        let $r := dtslib:parseRef($ref)
(:                        let $t := util:log("info",$r):)
                        let $pb := $r//*:part[@type eq 'pb']/text()
                        let $cb := $r//*:part[@type eq 'cb']
                        let $lb := $r//*:part[@type eq 'lb']
                        let $corr := $r//*:part[@type eq 'corr']
(:                        $selector//node()[name()!='cb' and  name()!='pb'][preceding-sibling::t:pb[1][@n='1r']][preceding-sibling::t:cb[1][@n='a']]
did not work, emailed exist db, Magdalena Turska very kindly provided this alternative approach.
:)                     let $pbstart := if($corr/text()) then $selector//t:pb[@n=$pb][contains(@corresp, $corr)] else $selector//t:pb[@n=$pb]
                       let $start := 
                                         if($lb/text()) then 
                                               $pbstart/following-sibling::t:lb[@n=$lb/text()]
                                         else if($cb/text()) then 
                                            $pbstart/following-sibling::t:cb[@n=$cb/text()]
                                        else    $pbstart
                        let $next := 
                        if($corr/text()) then 
                                       if($lb/text()) then ($start/following-sibling::*[self::t:lb or self::t:cb or self::t:pb[contains(@corresp, $corr)]])[1]  
                                        else if($cb/text()) then  ($start/following-sibling::*[self::t:cb or self::t:pb[contains(@corresp, $corr)]])[1]  
                                        else ($start/following-sibling::*[self::t:pb[contains(@corresp, $corr)]])[1]
                           else
                                        if($lb/text()) then ($start/following-sibling::*[self::t:lb or self::t:cb or self::t:pb])[1]  
                                        else if($cb/text()) then  ($start/following-sibling::*[self::t:cb or self::t:pb])[1]  
                                        else ($start/following-sibling::*[self::t:pb])[1]
                        
(:                           let $t2 := util:log("info",$next):)
                           return
                       if ($next) then   
(:                        let $t2 := util:log("info",$start):)
(:                         let $t2 := util:log("info",$start/following-sibling::node()[. << $next]):)
(:                        return:)
                       $start/following-sibling::node()[. << $next]
                        else     
(:                        let $t2 := util:log("info",$start/following-sibling::node()):)
(:                        return:)
                        $start/following-sibling::node()
                        else if ($selector/name() = 'pb')
                                          then dtslib:TranscriptionPassageNodes($text, $selector/@n, '')
                        else if ($selector/name()='lb') 
                        
                                          then
                                         (: let $t2 := util:log("info",$ref)
                                          return:)
                                          dtslib:TranscriptionPassageNodesLB($text, $selector/@n)
                       else $selector
                       };

(:Should take any format of reference, like 5.3.2 and return, depending on the 
prev or next parameter, 5.3.1 or 5.3.3 or whatever is relevant for that document... 
which requires the document itself to be checked!:)
declare function dtslib:PrevNextRef($text, $ref, $prevornext){
let $l := if(contains($ref, '.')) then count(tokenize($ref, '.')) else 1
let $parseRef := dtslib:parseRef($ref)
let $l :=$parseRef//ref[1]/xs:integer(@l)
let $list := dtslib:listRefs($l, $text)
return if ($prevornext = 'next') then $list[index-of($list,$ref)+1] else $list[index-of($list,$ref)[1]-1]
};

declare function dtslib:redirectToCollections (){

<rest:response>
  <http:response status="302">
    <http:header name="location" value="/api/dts/collections?id=https://betamasaheft.eu"/>
    <http:header
                    name="Access-Control-Allow-Origin"
                    value="*"/>
  </http:response>
</rest:response>};



declare function dtslib:redirectToRDF($id){

<rest:response>
  <http:response status="302">
    <http:header name="location" value="/{$id}"/>
    <http:header
                    name="Access-Control-Allow-Origin"
                    value="*"/>
  </http:response>
</rest:response>};


declare function dtslib:redirectToPDF($id){

<rest:response>
  <http:response status="302">
    <http:header name="location" value="/{$id}.pdf"/>
    <http:header
                    name="Access-Control-Allow-Origin"
                    value="*"/>
  </http:response>
</rest:response>};


declare function dtslib:redirectToHTML($id, $ref, $start){

<rest:response>
  <http:response status="302">
    <http:header name="location" value="/{switch2:col(switch2:switchPrefix($id))}/{$id}/text?start={if($ref != '') then $ref else if($start  != '') then $start else '1'}"/>
    <http:header
                    name="Access-Control-Allow-Origin"
                    value="*"/>
  </http:response>
</rest:response>
};


declare function dtslib:docs($id as xs:string*, $ref as xs:string*, $start, $end, $Content-Type){
(:redirect if id not specified:)
if ($id = '') then dtslib:redirectToCollections() 
else
 let $parsedURN := dtslib:parseDTS($id)
 let $thisid := $parsedURN//s:group[@nr=3]/text()
 let $edition := $parsedURN//s:group[@nr=4]
 
(: let $t2 := util:log("info",$thisid):)
 let $file := $dtslib:collection-root/id($thisid)
(: let $t2 := util:log("info",count($file)):)
 let $text := if($edition/node()) then dtslib:pickDivText($file, $edition)  else $file//t:div[@type eq 'edition']
 
(: let $t := console:log($parsedURN):)
(: let $t2 := console:log($start):)
(: let $t3 := console:log($end):)
 return
if($ref != '' and (($start != '') or ($end != ''))) then ($config:response400XML, 
<error statusCode="400" xmlns="https://w3id.org/dts/api#">
  <title>Bad Request</title>
  <description>You should use start and end, or passage only</description>
</error>) 
else if (($start = '' and $end != '') or ($start != '' and $end = '') ) then ($config:response400XML, 
<error statusCode="400" xmlns="https://w3id.org/dts/api#">
  <title>Bad Request</title>
  <description>You cannot use start and end disjunted</description>
</error>) 
else 

let $links := if ($ref = '') then () 
else if ($start != '') then <http:header
                    name="Link"
                    value="&lt;/api/dts/document?id={$id}&amp;ref={dtslib:PrevNextRef($text, $start, 'prev')}&gt; ; rel='prev', &lt;/api/dts/document/?id={$id}&amp;ref={dtslib:PrevNextRef($text, $end, 'next')}&gt; ; rel='next'"/>

else <http:header
                    name="Link"
                    value="&lt;/api/dts/document?id={$id}&amp;ref={dtslib:PrevNextRef($text, $ref, 'prev')}&gt; ; rel='prev', &lt;/api/dts/document/?id={$id}&amp;ref={dtslib:PrevNextRef($text, $ref, 'next')}&gt; ; rel='next'"/>
                    
 return
(:we need a restxq redirect in case the id contains already the passage. 
it should redirect the urn with passage to one which splits it and 
redirect it to a parametrized query:)
 if(count($parsedURN//s:group[@nr=8]//text()) ge 1) then 
 let $location := if($parsedURN//s:group[@nr=18]/text() = '-') 
                    then ('/api/dts/document?id='||$parsedURN//s:group[@nr=1]//text()||$parsedURN//s:group[@nr=2]//text()||$parsedURN//s:group[@nr=3]//text()|| '&amp;start=' ||$parsedURN//s:group[@nr=9]//text()|| '&amp;end=' ||$parsedURN//s:group[@nr=19]//text()) 
                    else ('/api/dts/document?id='||$parsedURN//s:group[@nr=1]//text()||$parsedURN//s:group[@nr=2]//text()||$parsedURN//s:group[@nr=3]//text()|| '&amp;ref=' ||$parsedURN//s:group[@nr=8]//text())
 return
 <rest:response>
  <http:response status="302">
    <http:header name="location" value="{ $location }"/>
    <http:header
                    name="Access-Control-Allow-Origin"
                    value="*"/>
  </http:response>
</rest:response>
 else
 let $doc := dtslib:fragment($file, $edition, $ref, $start, $end, $text)
                       
 return
 
  switch($Content-Type) 
  
  case 'application/rdf+xml' return dtslib:redirectToRDF($thisid)
  case 'application/pdf' return dtslib:redirectToPDF($thisid)
  case 'text/html' return  dtslib:redirectToHTML($thisid, $ref, $start)
  case 'text/plain' return  ( <rest:response>
  <http:response
                status="200">
                <http:header
                    name="Content-Type"
                    value="{$Content-Type}; charset=utf-8"/>
                <http:header
                    name="Access-Control-Allow-Origin"
                    value="*"/>
                   {$links}
            </http:response>
        </rest:response>,
string:tei2string($doc/node()[not(name()='teiHeader')]))
(:  default is on XML TEI :)
  default return  ( <rest:response>
  <http:response
                status="200">
                <http:header
                    name="Content-Type"
                    value="{$Content-Type}; charset=utf-8"/>
                <http:header
                    name="Access-Control-Allow-Origin"
                    value="*"/>
                   {$links}
            </http:response>
        </rest:response>,$doc)
  

};

declare %private function dtslib:fragment($file, $edition, $ref, $start, $end, $text){
(: in case there is passage, then look for that place:)
  if ($edition/node() and $ref = '' and $start='') then 
(:  let $t4 := console:log('edition')
  return:)
  <TEI xmlns="http://www.tei-c.org/ns/1.0" >
        <dts:fragment xmlns:dts="https://w3id.org/dts/api#">
          {$text}
        </dts:fragment>
   </TEI>
  else if ($ref != '' ) then 
  (:fetch narrative unit passage:)
            if (starts-with($ref, 'NAR')) then (
                (:will match the content of any div with a corresp corresponding to that narrative unit, if any:)
    
      let $narrative := $text//t:*[@corresp =$ref]
            return
                        <TEI xmlns="http://www.tei-c.org/ns/1.0" >
                            <dts:fragment xmlns:dts="https://w3id.org/dts/api#">
                                {$narrative}
                            </dts:fragment>
                       </TEI> )
(:otherwise go for a passage in the standard structure:)
 else (
                    let $path := dtslib:selectorRef(1, $text,$ref,'no')
(:                    let $t := util:log("info",$path):)
                        let $entirepart := dtslib:nodes($text, $path, $ref)
(:                        let $t2:=util:log("info",$entirepart):)
                        return
(:                        util:log("info", "breakpoint"):)
                        <TEI xmlns="http://www.tei-c.org/ns/1.0" >
                            <dts:fragment xmlns:dts="https://w3id.org/dts/api#">
                                {$entirepart}
                            </dts:fragment>
                       </TEI>
                    
         )
(:         if there are start and end, look for a range:)
else if($start != '' or $end != '') then (

 let $l := count(tokenize($start, '\.'))
 let $possibleRefs := dtslib:listRefs($l, $text)
(:a folio side and eventually column has been requested
the full list of possible references will look (correctly) like
1.1r - 1.1ra - 1.1rb - 1.1v - 1.1va - 1.1vb - 2.2r - 2.2ra - 2.2rb - 2.2v - 2.2va - 2.2vb - 3.3r - 3.3ra - 3.3rb 
so 1ra will never match anything. Also, several double references are present.
the cleaned list has no folio redundancy and removes references which are not in full
:)
(: let $test := console:log(string-join($possibleRefs, ' - ')):)

let $cleanMSrefs := if(matches($start, '\d+[r|v][a-z]'))
                                        then(for $p in $possibleRefs return 
                                        if(matches($p,'\d+[r|v][a-z]')) then  $p else () )
                                    else if (matches($start, '\d+[r|v]'))
                                        then (for $p in $possibleRefs return 
                                        if(matches($p,'\d+[r|v]$')) then $p else ())
                                    else $possibleRefs
(: let $test := console:log(string-join($cleanMSrefs, ' - ')):)

 let $startP := index-of($cleanMSrefs,$start)
 let $endP := index-of($cleanMSrefs,$end)
 let $selectors := for $r in $startP to $endP 
   return 
   <s><ref>{$cleanMSrefs[$r]}</ref><path>{dtslib:selectorRef($l, $text,$cleanMSrefs[$r], 'no')}</path></s>
 let $nodes := 
 for $selector in $selectors 
 return dtslib:nodes($text, $selector/*:path/text(), $selector/*:ref/text())
return 
<TEI xmlns="http://www.tei-c.org/ns/1.0">
    <dts:fragment xmlns:dts="https://w3id.org/dts/api#">
        {$nodes}
    </dts:fragment>
</TEI>
)
                       
else $file 

};

declare %private function dtslib:passageIIIFrange($text, $manifest, $type, $id){
switch ($type)
case 'work' return (
(:if in the element passed to the function there is a facs, use it:)
if($text/@facs) then <iiifRange>{string($text/@facs)}</iiifRange>
(:if there are more than one withness then add a reference for each:)
else if($text/@xml:id and (count($manifest) ge 1)) then 
                let $corresp := $id||'#'||string($text/@xml:id)
                for $m in $manifest return 
                (:if it is a manifest external to the project, we cannot go in much more details:)
                    if(starts-with($m, 'http')) then $m else 
                    (:if it is one of ours, we can provide a range related to the msItem containg the referred textual unit:)
                    let $w := $dtslib:collection-rootMS/id($m)
                    return 
                
                    if ($w//t:msItem[t:title[@ref=$corresp]]/@xml:id) then
                        ( let $msitem := $w//t:msItem[t:title[@ref=$corresp]]
                        for $mi in $msitem return <iiifRange>{$config:appUrl||'/api/iiif/'||$m||'/range/'||string($mi/@xml:id)}</iiifRange>
                        )
                   else     <iiifRange>{( $config:appUrl||'/api/iiif/'||$m||'/manifest') }</iiifRange>
                      
else()
)
(:default is manuscript:)
default return
(: ONLY DEALS WITH IMAGES WE SERVE, DOING ON TOP A LOT OF ASSUMPTIONS:)
(:  if it is a container div, check if there are images linked and a msItem referred to from 
the transcription and point to a range. the range will point, looking at locus/@facs in the iiif module will contain the correct range of canvases :)
 if(starts-with($text/@corresp, '#') and not(starts-with($manifest, 'http'))) 
 then <iiifRange>{$config:appUrl}/api/iiif/{$id}/range/{substring-after($text/@corresp, '#')}</iiifRange>
(:  if it is s div with n and no corresp, than all that can be taken are the two images which contain representations of that folio. two images:) 
 else if ($text/name() = 'div' and not($text/@corresp) and $text/@n) then for $rectoandverso in (string(translate($text/@n, 'rv', '')), string(number(translate($text/@n, 'rv', '')) + 1)) return <iiifRange>{$config:appUrl}/api/iiif/{$id}/canvas/p{$rectoandverso}</iiifRange>
(: if it is a page, then only the relevant image of an opening is linked. one image, needs @facs! :)
else if ($text/@facs) then <iiifRange>{$text/@facs}</iiifRange>
(: if it is a page, then only the relevant image of an opening is linked. one image:)
else if ($text/name() = 'pb') then <iiifRange>{$config:appUrl}/api/iiif/{$id}/canvas/p{if(ends-with($text/@n, 'r')) then string(substring-before($text/@n, 'r')) else string(number(substring-before($text/@n, 'v')) + 1)}</iiifRange>
(: if it is a column, then only the relevant image of an opening is linked. one image :)
else if ($text/name() = 'cb') then <iiifRange>{$config:appUrl}/api/iiif/{$id}/canvas/p{if(ends-with($text/preceding-sibling::t:pb[1]/@n, 'r')) then string(translate($text/preceding-sibling::t:pb[1]/@n, 'rv', '')) else string(number(translate($text/preceding-sibling::t:pb[1]/@n, 'rv', '')) + 1)}</iiifRange>
 else ()
 };
 
 declare function dtslib:citeDepth($text){
 if($text/ancestor::t:TEI/@type eq 'mss' and not($text/ancestor::t:TEI//t:objectDesc/@form ='Inscription')) then 

    (if($text/t:div[@subtype !='folio']) then 
(:    determine the maximum possible levels of descendence for div, pb and cb
https://stackoverflow.com/questions/5694759/how-do-you-calculate-the-number-of-levels-of-descendants-of-a-nokogiri-node
:)
let $nodes := $text/descendant::node()[name()='div' or name()='l' or name()='lb' or name()='pb' or name()='cb']
return
    max(for $leaf in $nodes,
        $depth in count($leaf/ancestor::node()[name()='div' or name()='l' or name()='lb' or name()='pb' or name()='cb'])
      return
        if($leaf/name()='lb') then ($depth +1) else $depth
        ) else 4) 
                                else 
                                       ( let $counts := for $div in ($text//t:div[@type eq 'textpart'], $text//t:l, $text//t:lb) 
                                        return count(($div/ancestor::t:div, $div/preceding::t:pb))
                                        return
                                        max($counts)
                                        )
                                        };
               
(:~  
given a formatted $ref as string parses it in parts
for use in other functions
returns a node in analyze-string-result, e.g. 
<analyze-string-result xmlns="http://www.w3.org/2005/xpath-functions">
    <match>
        <group nr="1">
            <group nr="3">3</group>
        </group>
        <group nr="4">.</group>
    </match>
    <match>
        <group nr="1">
            <group nr="2">Gen</group>
            <group nr="3">1</group>
        </group>
        <group nr="4">.</group>
    </match>
    <match>
        <group nr="1">
            <group nr="2">month</group>
            <group nr="3">1</group>
        </group>
        <group nr="4">.</group>
    </match>
    <match>
        <group nr="1">NAR0069Gabreel</group>
        <group nr="4">.</group>
    </match>
    <match>
        <group nr="1">
            <group nr="2">day</group>
            <group nr="3">30</group>
        </group>
        <group nr="4">.</group>
    </match>
    <match>
        <group nr="1">
            <group nr="3">1</group>
        </group>
    </match>
</analyze-string-result>
:)
declare %private function dtslib:parseRef($ref){
(:dtslib:ref can be constructed as a series of dotted sub references
each level is separated by a dot, each level can be the value of either 
    - a @n
    - a @xml:id
    - a @corresp
    - a concatenation of @subtype and @n
    
   the total number of position in ref cannot be greater than citeDepth
   and must be coherent with it.

e.g.
1 (div[@type eq 'folio']/@n)
1r (pb/@n)
1va ((pb/@n),(cb/@n))
2ra1 (((pb/@n),(cb/@n)),(lb/@n))
1  (@n)
1.1 (@n.@n)
Gen1.1 (@xml:id.@n)
1.verse1 (@n.@xml:id)
Gen1.verse1 (@xml:id.@xml:id)
month1.day3 ((@subtype,@n).(@subtype,@n))
1.30.NAR0069Gabreel (@n.@n.@corresp)
month1.day30.NAR0069Gabreel ((@subtype,@n).(@subtype,@n).(@corresp))
 :)
let $parseRef := analyze-string($ref, 
               '(NAR[0-9A-Za-z]+|((\d+[r|v])([a-z]?)(\[\w+\])?(\.)?(\d+)?)|([A-Za-z]+)?([0-9]+))(\.)?')
let $refs := for $m at $p in $parseRef//s:match 
                    let $t := $m/s:group[@nr=1]//text()
                    return
                     if(matches($m, '\d+[r|v][a-z]?(\d+)?')) 
(:           the normal reference to the folio, is to be found split in pb and cb          :)
                                then <ref type='folio' l="{$p}">
                                        <part type="pb">{$m//s:group[@nr=3]/text()}</part>
                                        <part type="cb">{$m//s:group[@nr=4]/text()}</part>
                                        <part type="corr">{$m//s:group[@nr=6]/text()}</part>
                                        <part type="lb">{$m//s:group[@nr=7]/text()}</part>
                                        </ref>
                     else if(matches($m, 'NAR[0-9A-Za-z]+')) 
                                then <ref type='nar' l="{$p}">{$t}</ref>
                     else if(matches($m, '([A-Za-z]+)([0-9]+)')) 
(:                     this is an ambiguous type, because it may refer to 
a subtype and a n as well as referring simply an xmlid :)
                                then <ref type='subtypeNorXMLid'  l="{$p}">
                                           <option type="subtype">
                                           <part type="subtype">{$m//s:group[@nr=8]/text()}</part>
                                           <part type="n">{$m//s:group[@nr=9]/text()}</part>
                                           </option>
                                           <option type="xmlid">{$t}</option>
                                        </ref>
                     else if(matches($m, '([A-Za-z]+)')) 
                                then <ref type='subtype'  l="{$p}">{$t}</ref>
                     else (<ref type='n' l="{$p}">{$t}</ref>)
return <refs>{$refs}</refs>
 };
               
(:~  called by dtslib:pas to format and select the references :)
declare function dtslib:refname($n){
(:has to recurs each level of ancestor of the node which 
   has a valid position in the text structure:)
let $refname:=  dtslib:rn($n)
let $this := normalize-space($refname)
let $ancestors := for $a in $n/ancestor::t:div[@xml:id or @n or @corresp][ancestor::t:div[@type]]
return dtslib:rn($a)
let $all := ($ancestors , $this)
return if( $n/name()='pb' or $n/name()='cb' or $n/name()='lb') then $this else string-join($all,'.')
};

(:~  called by dtslib:refname to format a single reference :)
declare function dtslib:rn($n){
  if ($n/name()='lb') then 
         (string($n/preceding::t:pb[@n][1]/@n)||string($n/preceding::t:cb[@n][1]/@n)||string($n/@n)) 
 else if ($n/name()='cb') then 
         (string($n/preceding::t:pb[@n][1]/@n)||string($n/@n)) 
 else if ($n/name()='pb' and $n/@corresp) then 
         (string($n/@n) || '[' ||substring-after($n/@corresp, '#')||']') 
    else if($n/@n) then string($n/@n)
    else if($n/@xml:id) then string($n/@xml:id)
    else if($n/@subtype) then string($n/@subtype)
    else 'tei:' ||$n/name() ||'['|| $n/position() || ']'
    };
        
(:~  called by dtslib:pas to select the title of a passage:)
declare function dtslib:reftitle($n){
if($n/@corresp) then 
             (if(starts-with($n/@corresp, '#')) 
                 then <title>{normalize-space(exptit:printSubtitle($n, substring-after($n/@corresp, '#')))}</title>
              else if(starts-with($n/@corresp, 'LIT')) 
              then <title>{normalize-space(exptit:printTitleID($n/@corresp))}</title>
              else if(starts-with($n/@corresp, 'NAR')) 
              then <title>{normalize-space(exptit:printTitleID($n/@corresp))}</title>
              else <title>{string($n/@corresp)}</title>)
 else if ($n/t:label) then <title>{string:tei2string($n/t:label)}</title>
 else if ($n/@subtye) then <title>{string($n/@subtye)} {if($n/@n) then string($n/@n) else $n/position()}</title>
 else ()
              };
              
(:~  called by dtslib:pas to select the type name:)
declare %private function dtslib:typename($n, $fallback){
<type>{if(string($n/@subtype)) then string($n/@subtype)
else if($n/name() = 'l') then 'verse'
else if($n/name() = 'lb') then 'line'
else if($n/name() = 'pb') then 'page'
else if($n/name() = 'cb') then 'column'
else $fallback}</type>
};

(:~ fetches all available computed or declared witnesses and
flattens this distinction building one list of 
computed and declared witnesses, 
as well as the eventual nesting of witnesses for each edition:)
declare function dtslib:wits($mydoc, $BMid){
let $computedWitnesses := 
     if($mydoc/@type eq  'mss') then ()
     else if($mydoc/@type eq  'nar') then (
              for $witness in $dtslib:collection-rootMS//t:*[starts-with(@corresp, $BMid)]
               let $root := root($witness)/t:TEI/@xml:id
                group by $groupkey := $root
                return string($groupkey))
    else (for $witness in $dtslib:collection-rootMS//t:title[starts-with(@ref, $BMid)]
                    let $root := root($witness)/t:TEI/@xml:id
                    group by $groupkey := $root
                    return string($groupkey))
let $declaredWitnesses := if($mydoc/@type eq  'mss') then () else 
                            for $witness in $mydoc//t:witness/@corresp return string($witness)
(: flattens the distinction between computed and declared witnesses, as well as the eventual nesting of witnesses for each edition:)
return ($computedWitnesses, $declaredWitnesses)
};

(:~  given a passage node calls the functions to add to it relevant information:)
declare %private function dtslib:pas($n, $fallback, $type, $manifest, $BMid){
<p>{dtslib:refname($n)}{dtslib:typename($n, $fallback)}{dtslib:reftitle($n)}{dtslib:passageIIIFrange($n, $manifest, $type, $BMid)}</p>
};

(:~  given a passage node calls the functions to add to it relevant information,
starting from a given refname, not building it from a node:)
declare %private function dtslib:pasCombo($n, $reftext, $type, $manifest, $BMid){
<p>{$n}{dtslib:passageIIIFrange($reftext, $manifest, $type, $BMid)}</p>
};

(:~  calls for all relevant nodes in a selection the builder for the passage node:)
declare function dtslib:pasS($selector, $fallback, $type, $manifest, $BMid){
for $n in $selector
 return dtslib:pas($n, $fallback, $type, $manifest, $BMid)
};

declare function dtslib:pasLev($level, $text, $fallback, $type, $manifest, $BMid){
let $levs := string-join((for $i in 1 to xs:integer($level) 
                     return "/(t:div|t:cb|t:pb|t:lb|t:l)/(t:ab|.)"))
let $path := '$text' || $levs
(:let $t:= console:log($path):)
  return  dtslib:pasS(util:eval($path), $fallback, $type, $manifest, $BMid)
};

declare %private function dtslib:listRefs($level, $text){
if($text/ancestor-or-self::t:TEI//t:citeStructure) then
(:(util:log("info", "citestruct"),:)
$text/ancestor::t:TEI//t:citeStructure//t:item/text()
(:):)
else 
let $levs := string-join((for $i in 1 to xs:integer($level) 
                     return "/(t:div|t:lg|t:l)/(t:ab|.)/(.|t:cb|t:pb|t:lb)"))
let $path := '$text' || $levs 
 for $ref in util:eval($path)
 return
 dtslib:refname($ref)  
};

declare function dtslib:selectorRef($level, $text, $ref, $children){
(:the children parameter is there because the selection is the same, but if selecting for references, then we want the children nodes, if selecting for nodes, we want the nodes and stop there:)
let $refs := dtslib:parseRef($ref)
(:let $t := console:log($refs):)
let $count := if ($level=1) then count($refs/*:ref) else $level
(:returns one <ref> for each level of the ref separated by a dot :)
 let $levs := 
(: matches the correct level with the correct part of the ref:)
 string-join((for $i in 1 to $count 
(: level 1 will always be edition. 
References will be available for level 2, so 
first level/part of a ref will point to level 2:)
                    let $r := $refs/*:ref[@l=($i)]
(:                    let $t1 := console:log($r):)
                    let $ty := $r/@type
(:  this path will be ok to look for id or n, but will fail for composed refs, i.e. where the ref
is built from pb and cb or from subtype and n. :)
 let $partpath := (switch($ty)
                                case 'nar' return "/t:div[@corresp='"||$r/text()||"']"
                                case 'n' return "/(t:div|t:lb|t:l)[@n='"||$r/text()||"']"
                                case 'subtype' return "/t:div[@subtype='"||$r/text()||"']"
                                (:it is folio reference a normal ref to a manuscript transcription will have the shape of a folio reference
like 1ra or 34vb or 35 or 67v , which is stored in <pb n='1r'> and <cb n='a'>
where pb will never have the column and the column will never have the pb...
in this case match the partent div and return all combinations 
of pbs and cbs available within it.   :)   
                                case 'folio' return "//t:pb[@n='"||
                                                                   $r/*:part[@type eq 'pb']/text()||"']"||
                                                                   (if($r/*:part[@type eq 'corr']/text()) 
                                                                   then "[contains(@corresp, "||$r/*:part[@type eq 'corr']/text()
                                                                   ||")]" else ())||
                                                                   (if($r/*:part[@type eq 'cb']/text()) 
                                                                   then ("[following-sibling::t:cb[@n='"||
                                                                   $r/*:part[@type eq 'cb']/text()||"']"||
                                                                   (if($r/*:part[@type eq 'lb']/text()) 
                                                                   then ("[following-sibling::t:lb[@n='"||
                                                                   $r/*:part[@type eq 'lb']/text()||"']]") 
                                                                   else ())||"]") 
                                                                   else ())||"/ancestor::t:div[1]"
                               case 'subtypeNorXMLid' return "/(t:div[@subtype='"||
                                                                   $r/*:option[@type eq 'subtype']/*:part[@type eq 'subtype']/text()||"']"||
                                                                   (if($r/*:option[@type eq 'subtype']/*:part[@type eq 'n']/text()) 
                                                                   then ("[@n='"||
                                                                   $r/*:option[@type eq 'subtype']/*:part[@type eq 'n']/text()||"']") 
                                                                   else ()) || " | " ||"t:div[@xml:id='"||
                                                                   $r/*:option[@type eq 'xmlid']/text()||"']"|| ")"
                                default return
                            "/(t:div|t:cb|t:pb|t:lb|t:l)[(@xml:id|@n)='"||
                                $r/text()||"' or contains(@corresp,'"||$r/text()||"')]"
                                )
       (:  always think there may be an ab... :)
                                ||(if($children='no' and $i = $count) then "" else '/(t:ab|.)') 
(: let $t1 := console:log($partpath):)
 return $partpath))   
 let $kids := if($children='yes') then '/(t:div|t:lb|t:l|t:pb|t:cb)' else ''
(: navigation shows options available for a given reference, so, selected a level or reference
it returns the possible children:)
 return
 '$text' || $levs ||$kids
};

(:~  calls for all relevant nodes in a selection the builder for the passage node:)
declare function dtslib:pasRef($level, $text, $ref, $fallback, $type, $manifest, $BMid){
let $path := dtslib:selectorRef($level, $text, $ref, 'yes')
(: let $t4 := console:log($path):)
     for $n in util:eval($path)  
     return dtslib:pas($n, $fallback, $type, $manifest, $BMid)
};

declare function dtslib:ctype($mydoc, $text, $level, $cdepth){
 if($mydoc/@type eq 'mss' 
                      and not($text/ancestor::t:TEI//t:objectDesc/@form ='Inscription')) 
                    then  (
                    if($cdepth gt 3) 
                                then  'textpart' 
                   else if(($level = '') and $cdepth=3) 
                                then 
                                        if($text/t:div[@subtype]) 
                                        then config:distinct-values($text/t:div/@subtype) 
                                        else 'folio' 
                  else if($level='2' and $cdepth=3) then 'page'  
                  else 'column'
                    )
else (if($level = '') 
                then (let $types := for $t in ($text/t:div, $text//t:lb)
                                                        let $typ := if($t/name() = 'lb') then 'line' 
                                                            else if($t/@subtype) then string($t/@subtype)
                                                            else if($t/@corresp) then string($t/@corresp) 
                                                            else 'textpart'
                                                        group by $T := $typ 
                                                        let $count := count($T)
                                                     return <t tot="{$count}">{$T}</t>
                                         return $types[max(@tot)]/text())
                            else  if($level = '2') then (
                                 if($text/t:div/t:ab/t:l) then 'verse'
                                 else if($text/t:div/t:ab/t:lb) then 'line'
                                 else
                                 let $types :=  for $t in $text/t:div/t:div
                                            let $typ := if($t/@subtype) then string($t/@subtype)
                                                            else if($t/@corresp) then string($t/@corresp) 
                                                            else 'textpart'
                                               group by $T := $typ 
                                             let $count := count($T)
                                                                    return <t tot="{$count}">{$T}</t>
                                  return $types[max(@tot)]/text()                        
                                                                    )
                             else 'textpart')
};

declare function dtslib:startend($level, $text, $start, $end, $fallback, $type, $manifest, $BMid){
 let $l := if ($level != '') then $level else count(tokenize($start, '\.'))
 let $possibleRefs := dtslib:listRefs($l, $text)
(: dtslib:listRefs returns a list of the most standardizable refs. 
this means that, while an alternative ref will work singularly, for a range the most canonical ones will have to be used
start=month1.day4&end=month1.day6
will not work although in principle equivalent to
start=1.4&end=1.6
which will return the correct set of passage references contained in this range
:)
 let $startP := index-of($possibleRefs,$start)
 let $endP := index-of($possibleRefs,$end)
 for $r in $startP to $endP 
   return dtslib:pasRef($l, $text, $possibleRefs[$r], $fallback, $type, $manifest, $BMid)
                };

declare function dtslib:pickDivText($doc, $parsedID){
(:let $t := console:log($parsedID):)
let $type := if($parsedID/s:group[@nr=5] = 'ED') then 'edition' else 'translation'
let $xmlid := if($parsedID/s:group[@nr=6]) then $parsedID/s:group[@nr=6]/text()[1] else ''
     return
          if($xmlid = '') then $doc//t:div[@type eq $type][not(@xml:id)]
          else $doc//t:div[@type eq $type][@xml:id=$xmlid]
};

(:~ given the URN in the id parameter and the plain Beta Masahaeft id if any, produces the list of members of the collection filtering only the entities which do have a div[@type eq 'edition'] :)
declare function dtslib:CollMember($id, $edition, $bmID, $page, $nav, $version){
let $doc := $exptit:col//id($bmID) 
let $eds := if($edition/node()) then
                                dtslib:pickDivText($doc, $edition)
                    else ($doc//t:div[@type eq 'edition'], $doc//t:div[@type eq 'translation'])
return
if(count($doc) eq 1) then (
$config:response200JsonLD,
(:let $t := console:log($id):)
let $memberInfo := dtslib:member($bmID,$edition,$eds, $version)
let $addcontext := map:put($memberInfo, "@context", $dtslib:context)
let $addnav := if($nav = 'parent') then 
let $parent :=if($doc/@type eq 'mss') then 
        map{
             "@id" : "https://betamasaheft.eu/transcriptions",
             "title" : "Beta maṣāḥǝft Manuscripts",
             "description": "Collection of Ethiopic Manuscript trasncriptions",
             "@type" : "Collection",
             "totalItems" : count(collection($config:data-rootMS)//t:div[@type eq 'edition'][descendant::t:ab[text()]])
        }
       else if($doc/@type eq 'nar') then 
        map{
             "@id" : "https://betamasaheft.eu/narrativeunits",
             "title" : "Beta maṣāḥǝft Manuscripts",
             "description": "Collection of narrative units of the Ethiopic tradition",
             "@type" : "Collection",
             "totalItems" : count(collection($config:data-rootN)//t:div[@type eq 'edition'][descendant::t:ab[text()]])
        }
        else map {
             "@id" : "https://betamasaheft.eu/textualunits",
             "title" : "Beta maṣāḥǝft Textual Units",
             "description": "Collection of literary textual units of the Ethiopic tradition",
             "@type" : "Collection",
             "totalItems" : count($dtslib:collection-rootW//t:div[@type eq 'edition'][descendant::t:ab[text()]])
        }
return
map:put($addcontext, "member", $parent) 
else $addcontext
return 
$addnav
) 
else
($config:response400JsonLD ,
map {
  "@context": "http://www.w3.org/ns/hydra/context.jsonld",
  "@type": "Status",
  "statusCode": 400,
  "title": "Bad Request",
  "description": "There is none or too many "||$bmID
}
)

};

(:~ called if the collection api path is requested without an indication of a precise betamasaheft id. returns either the main collection 
: entry point or one of the three main collections, manuscripts transcriptions, textual units or narrativa units in which case it will call dtslib:mainColl :)
declare  function dtslib:Coll($id, $page, $nav, $version){
let $availableCollectionIDs := ('https://betamasaheft.eu', 'https://betamasaheft.eu/textualunits', 'https://betamasaheft.eu/narrativeunits', 'https://betamasaheft.eu/transcriptions')
let $ms := $dtslib:collection-rootMS//t:div[@type eq 'edition'][descendant::t:ab[text()]]
let $w := $dtslib:collection-rootW//t:div[@type eq 'edition'][descendant::t:ab[text()]]
let $n := $dtslib:collection-rootN
  let $countMS := count($ms)
  let $countW := count($w)
  let $countN := count($n)
    return
       (
 if($id = $availableCollectionIDs) then (
 $config:response200JsonLD,
 switch($id) 
 case 'https://betamasaheft.eu/textualunits' return
dtslib:mainColl($id, $countW, $w, $page, $nav)
 case 'https://betamasaheft.eu/narrativeunits' return
dtslib:mainColl($id, $countN, $n, $page, $nav)
case 'https://betamasaheft.eu/transcriptions' return
dtslib:mainColl($id, $countMS, $ms, $page, $nav)
default return
map {
    "@context": $dtslib:context,
    "@id": $id,
    "@type": "Collection",
    "totalItems": 3,
    "title": "Beta maṣāḥǝft",
    "description" : "The project Beta maṣāḥǝft: Manuscripts of Ethiopia and Eritrea (Schriftkultur des christlichen Äthiopiens: eine multimediale Forschungsumgebung) is a long-term project funded within the framework of the Academies' Programme (coordinated by the Union of the German Academies of Sciences and Humanities) under survey of the Akademie der Wissenschaften in Hamburg. The funding will be provided for 25 years, from 2016–2040. The project is hosted by the Hiob Ludolf Centre for Ethiopian Studies at the University of Hamburg. It aims at creating a virtual research environment that shall manage complex data related to predominantly Christian manuscript tradition of the Ethiopian and Eritrean Highlands.",
    "dtslib:dublincore": $dtslib:publisher,
    "member": [
        map {
             "@id" : "https://betamasaheft.eu/textualunits",
             "title" : "Beta maṣāḥǝft Textual Units",
             "description": "Collection of textual units of the Ethiopic tradition",
             "@type" : "Collection",
             "totalItems" : $countW
        },
         map {
             "@id" : "https://betamasaheft.eu/narrativeunits",
             "title" : "Beta maṣāḥǝft Narrative Units",
             "description": "Collection of narrative units of the Ethiopic tradition",
             "@type" : "Collection",
             "totalItems" : $countN
        },
        map{
             "@id" : "https://betamasaheft.eu/transcriptions",
             "title" : "Beta maṣāḥǝft Manuscripts",
             "description": "Collection of Ethiopic Manuscript trasncriptions",
             "@type" : "Collection",
             "totalItems" : $countMS
        }
    ]
})
 else (
$config:response404JsonLD ,
map {
  "@context": "http://www.w3.org/ns/hydra/context.jsonld",
  "@type": "Status",
  "statusCode": 404,
  "title": "Not Found",
  "description": "Unknown Collection"
})
)
};

(:~ If the requested collection is manuscripts or works, this produces the response for one of the two:)
declare function dtslib:mainColl($collURN, $count, $items, $page, $nav){  

let $title :=  if(contains($collURN, 'transcriptions')) then 'Beta maṣāḥǝft Manuscripts' 
                    else if(contains($collURN, 'narrative')) then 'Beta maṣāḥǝft Narrative Units' 
                    else 'Beta maṣāḥǝft Textual Units'
let $pg := "/api/dts/collections?id="||$collURN||"&amp;page="
let $perpage := 10
let $lastpg := ceiling($count div $perpage)
let $pageid:=  $pg|| string($page)
let $firstpage := $pg ||'1'
let $lastpage:=  $pg ||$lastpg
let $prevpage:= if($page = 1) then () else $pg ||string($page - 1)
let $nextpage :=if($page = $lastpg) then () else $pg ||string($page + 1)

let $end := $page * $perpage
let $start := ($end - $perpage) +1
let $members :=  for $document in subsequence($items , $start, $end) 
                                 let $edition := ''
                                        return
                                      dtslib:member($collURN, $edition, $document, 'no')
    return
    map {
    "@context": $dtslib:context,
    "@id": $collURN,
    "@type": "Collection",
    "totalItems": $count,
    "title": $title,
    "dtslib:dublincore": $dtslib:publisher,
    "member": $members,
    "view": map{
        "@id": $pageid,
        "@type": "PartialCollectionView",
        "first": $firstpage,
        "previous": $prevpage,
        "next": $nextpage,
        "last": $lastpage
    }
}
    };

declare %private function dtslib:nestedDivs($edition as node()*){
for $node in ($edition/t:div[@type eq 'textpart'], $edition/t:ab/t:l, $edition/t:ab/t:lb)
 let $typ := if($node/@subtype) then string($node/@subtype) else if ($node/name() = 'l') then 'verse 'else if ($node/name() = 'lb') then 'line' else 'textpart'
 group by $T := $typ
let $citType :=  map {
                 "dtslib:citeType": $T
                 }
let $citStr : =if($node/child::t:div) then let $subType := dtslib:nestedDivs($node/child::t:div) return map:put($citType, 'dtslib:citeStructure', $subType)
else if($node/t:ab/t:l) then let $subType := dtslib:nestedDivs($node) return map:put($citType, 'dtslib:citeStructure', $subType)
else if($node/t:ab/t:lb) then let $subType := dtslib:nestedDivs($node) return map:put($citType, 'dtslib:citeStructure', $subType)
else $citType
    return
    $citStr
    
};

declare %private function dtslib:manifest($doc, $id){
 if($doc//t:idno[@facs[not(starts-with(.,'http'))]]) 
                    then 
                        (:from europeana data model specification, taken from nomisma, not sure if this is correct in json LD:)
                        ( map {'@id' : ($config:appUrl ||"/manuscript/"|| $id || '/viewer'),
                                        '@type' : 'edm:WebResource',
                                        "svcs:has_service" : map{'@id' : "https://betamasaheft.eu/api/iiif/"||$id||"/manifest",
                                                                                            '@type' : 'svcs:Service',
                                                                                            "dcterms:conformsTo": "http://iiif.io/api/image",
                                                                                            "doap:implements": "http://iiif.io/api/image/2/level1.json"
                                                                                             }
                                      }
                        )
                       else if($doc//t:idno[@facs[starts-with(.,'http')]]) 
                    then 
                        (:from europeana data model specification, taken from nomisma, not sure if this is correct in json LD:)
                        ( map {'@id' : string($doc//t:idno/@facs),
                                        '@type' : 'edm:WebResource',
                                        "svcs:has_service" : map{'@id' : string($doc//t:idno/@facs),
                                                                                            '@type' : 'svcs:Service',
                                                                                            "dcterms:conformsTo": "http://iiif.io/api/image",
                                                                                            "doap:implements": "http://iiif.io/api/image/2/level1.json"
                                                                                             }
                                      }
                        )
                        else ()
};

(:~ produces the information needed for each member of a collection :)
declare function dtslib:member($collURN,$edition,$document, $vers, $nosparql){
if(not($document))
then <rest:response>
        <http:response
            status="204">
                
            <http:header
                    name="Access-Control-Allow-Origin"
                    value="*"
                    />
        </http:response>
    </rest:response>
else if(count($document) = 1) then
dtslib:membercontent($document, $edition, $vers, $nosparql)
(:     if there are more editions, then this has to be treated as a collection resource, and each
edition or translation gets its own identifier:)
else ( 
(:any is fine, they all come from a selection, this is just to have the ID:)
let $doc := root($document[1]) 
let $id := string($doc//t:TEI/@xml:id)
let $title := exptit:printTitleID($id)
let $description := if($doc//t:TEI/@type eq  'nar') 
                                 then 'The narrative unit '||$title||
                                 ' in Beta maṣāḥǝft ' 
                                 else if($doc//t:TEI/@type eq  'mss') 
                                 then 'The transcription of manuscript '||
                                 $title||' in Beta maṣāḥǝft ' 
                                 else 'The abstract textual unit '||$title||
                                 ' in Beta maṣāḥǝft. '  || 
                                 normalize-space(string-join(string:tei2string($doc//t:abstract), ''))
let $resourceURN := 'https://betamasaheft.eu/' || $id
let $members := for $d in $document 
                                        let $divuri := ($resourceURN || '_' ||upper-case(substring(string($d/@type),1,2))|| '_' ||string($d/@xml:id))
                                        return dtslib:editioncontent($divuri,string($d/@type),string($d/@xml:id),$d, $vers, $nosparql)
    return
map{"@id" : $resourceURN,
             "title" : "Editions and Translations of " || $title,
             "description": $description,
             "@type" : "Collection",
             "totalItems" : count($document),
              "dtslib:totalParents": 1,
             "dtslib:totalChildren": count($document),
             "member" :   $members    
             }         
          
       )
};

(:~ produces the information needed for each member of a collection :)
declare function dtslib:member($collURN,$edition,$document, $vers){
if(not($document))
then <rest:response>
        <http:response
            status="204">
                
            <http:header
                    name="Access-Control-Allow-Origin"
                    value="*"
                    />
        </http:response>
    </rest:response>
else if(count($document) = 1) then
dtslib:membercontent($document, $edition, $vers)
(:     if there are more editions, then this has to be treated as a collection resource, and each
edition or translation gets its own identifier:)
else ( 
(:any is fine, they all come from a selection, this is just to have the ID:)
let $doc := root($document[1]) 
let $id := string($doc//t:TEI/@xml:id)
let $title := exptit:printTitleID($id)
let $description := if($doc//t:TEI/@type eq  'nar') 
                                 then 'The narrative unit '||$title||
                                 ' in Beta maṣāḥǝft ' 
                                 else if($doc//t:TEI/@type eq  'mss') 
                                 then 'The transcription of manuscript '||
                                 $title||' in Beta maṣāḥǝft ' 
                                 else 'The abstract textual unit '||$title||
                                 ' in Beta maṣāḥǝft. '  || 
                                 normalize-space(string-join(string:tei2string($doc//t:abstract), ''))
let $resourceURN := 'https://betamasaheft.eu/' || $id
let $members := for $d in $document 
                                        let $divuri := ($resourceURN || '_' ||upper-case(substring(string($d/@type),1,2))|| '_' ||string($d/@xml:id))
                                        return dtslib:editioncontent($divuri,string($d/@type),string($d/@xml:id),$d, $vers)
    return
map{"@id" : $resourceURN,
             "title" : "Editions and Translations of " || $title,
             "description": $description,
             "@type" : "Collection",
             "totalItems" : count($document),
              "dtslib:totalParents": 1,
             "dtslib:totalChildren": count($document),
             "member" :   $members    
             }         
          
       )
};

declare %private function dtslib:computedWit($doc, $id){
if($doc//t:TEI/@type eq  'mss') then ()
                              else if($doc//t:TEI/@type eq  'nar') then (
                              for $witness in $dtslib:collection-rootMS//t:*[@corresp = $id]
                            let $root := root($witness)/t:TEI/@xml:id
                                group by $groupkey := $root
                            return string($groupkey))
                              else 
                            (for $witness in $dtslib:collection-rootMS//t:title[@ref = $id]
                            let $root := root($witness)/t:TEI/@xml:id
                                group by $groupkey := $root
                            return string($groupkey))
                            };
                            
declare %private function dtslib:distinctW($witnesses){
for $w in config:distinct-values($witnesses) return 
                            map { "fabio:isManifestationOf" : if(starts-with($w, 'http')) then $w else ($config:appUrl || "/" || $w),
                                        "@id" : if(starts-with($w, 'http')) then $w else ("https://betamasaheft.eu/" || $w),
                                        "@type" : "lawd:AssembledWork",
                                        "dc:title": exptit:printTitleID($w)}
                                        };

declare %private function dtslib:membercontent($document, $edition, $vers, $nosparql){
let $doc := root($document)
let $id := string($doc//t:TEI/@xml:id)
let $title := exptit:printTitleID($id)
let $description := dtslib:docDesc($doc, $title)
let $dc := map{
                "dc:title": $title
               }
let $computed := dtslib:computedWit($doc, $id)
let $declared := if($doc//t:TEI/@type eq  'mss') then () else 
                            for $witness in $doc//t:witness/@corresp return string($witness)
(: flattens the distinction between computed and declared witnesses, as well as the eventual nesting of witnesses for each edition:)
let $witnesses := ($computed, $declared)
let $distinctW := dtslib:distinctW($witnesses)
let $manifests := dtslib:manifests($witnesses, $id)
 let $worksAndManifests := ($distinctW, $manifests)                                     
let $dcAndWitnesses := if(count($distinctW) gt 0) then map:put($dc, 'dc:source', $worksAndManifests) else $dc
let $DcSelector := 
if($doc//t:TEI/@type eq  'mss') then $dc else $dcAndWitnesses
(:$dc:)
let $resourceURN := 'https://betamasaheft.eu/' || $id || $edition
let $versions := if($vers = 'yes') then dtslib:fileingitCommits($resourceURN, $id, 'collections') else ()
let $DcWithVersions :=  if($vers = 'yes') then map:put($DcSelector, "dc:hasVersion", $versions) else $DcSelector
let $manifest :=dtslib:manifest($doc, $id)
let $addmanifest := if (count($manifest) ge 1) then map{"foaf:depiction": $manifest} else ()
let $parts := $addmanifest
let $dtsPass := "/api/dts/document?id=" || $resourceURN
let $dtsNav := "/api/dts/navigation?id=" || $resourceURN
let $download := "https://betamasaheft.eu/tei/" || $id || '.xml'
let $citeDepth :=  if($doc/@type eq  'mss' and not($doc//t:objectDesc/@form ='Inscription')) then 3 
else let $counts := for $div in ($document//t:div[@type eq 'textpart'], $document//t:l, $document//t:lb) return count($div/ancestor::t:div)
return max($counts)
let $teirefdecl := if($doc/@type eq  'mss' and not($doc//t:objectDesc/@form ='Inscription')) then 
[ map{
                 "dtslib:citeType": "folio",
                    "dtslib:citeStructure": [
                       map {
                            "dtslib:citeType": "page",
                             "dtslib:citeStructure": [
                       map {
                            "dtslib:citeType": "column"
                        }
                  ]
             }
          ]
     }
]
else if ($doc/@type eq 'nar') then ()
else
[
dtslib:nestedDivs($document)
            ]
let $c := count($document//t:ab//text())
let $all := map{
             "@id" : $resourceURN,
              (:  "ecrm:P1_is_identified_by": map { "rdfs:label": $resourceURN},:)
             "title" : $title,
             "description": $description,
             "@type" : "Resource",
             "totalItems": 0,
             "dtslib:dublincore": $DcWithVersions ,
            "dtslib:download": $download,
            "dtslib:citeDepth": $citeDepth,
            "dtslib:citeStructure": $teirefdecl
        }
let $ext :=         if(count($parts) ge 1) then  map:put($all,"dtslib:extensions",$parts) else $all
let $pass :=  if($c le 1) then $ext else map:put($ext, "dtslib:passage", $dtsPass) 
let $nav := if($c le 1) then $pass else map:put($pass, "dtslib:references", $dtsNav)
        return
        $nav
};

declare %private function dtslib:membercontent($document, $edition, $vers){
let $doc := root($document)
let $id := string($doc//t:TEI/@xml:id)
let $title := exptit:printTitleID($id)
let $description := dtslib:docDesc($doc, $title)
let $dc := dtslib:dublinCore($id)
let $computed := dtslib:computedWit($doc, $id)
let $declared := if($doc//t:TEI/@type eq  'mss') then () else 
                            for $witness in $doc//t:witness/@corresp return string($witness)
(: flattens the distinction between computed and declared witnesses, as well as the eventual nesting of witnesses for each edition:)
let $witnesses := ($computed, $declared)
let $distinctW := dtslib:distinctW($witnesses)
let $manifests := dtslib:manifests($witnesses, $id)
 let $worksAndManifests := ($distinctW, $manifests)                                     
let $dcAndWitnesses := if(count($distinctW) gt 0) then map:put($dc, 'dc:source', $worksAndManifests) else $dc
let $DcSelector := 
if($doc//t:TEI/@type eq  'mss') then $dc else $dcAndWitnesses
(:$dc:)
let $resourceURN := 'https://betamasaheft.eu/' || $id || $edition
let $versions := if($vers = 'yes') then dtslib:fileingitCommits($resourceURN, $id, 'collections') else ()
let $DcWithVersions :=  if($vers = 'yes') then map:put($DcSelector, "dc:hasVersion", $versions) else $DcSelector
let $ext := dtslib:extension($id)
let $haspart := dtslib:haspart($id)
let $manifest :=dtslib:manifest($doc, $id)
let $addmanifest := if ((count($ext) ge 1) and (count($manifest) ge 1)) then map:put($ext, "foaf:depiction", $manifest) else $ext
let $parts := if(count($haspart) ge 1) then map:put($addmanifest, 'dc:hasPart', $haspart) else $addmanifest
let $dtsPass := "/api/dts/document?id=" || $resourceURN
let $dtsNav := "/api/dts/navigation?id=" || $resourceURN
let $download := "https://betamasaheft.eu/tei/" || $id || '.xml'
let $citeDepth :=  if($doc/@type eq  'mss' and not($doc//t:objectDesc/@form ='Inscription')) then 3 
else let $counts := for $div in ($document//t:div[@type eq 'textpart'], $document//t:l, $document//t:lb) return count($div/ancestor::t:div)
return max($counts)
let $teirefdecl := if($doc/@type eq  'mss' and not($doc//t:objectDesc/@form ='Inscription')) then 
[ map{
                 "dtslib:citeType": "folio",
                    "dtslib:citeStructure": [
                       map {
                            "dtslib:citeType": "page",
                             "dtslib:citeStructure": [
                       map {
                            "dtslib:citeType": "column"
                        }
                  ]
             }
          ]
     }
]
else if ($doc/@type eq 'nar') then ()
else
[
dtslib:nestedDivs($document)
            ]
let $c := count($document//t:ab//text())
let $all := map{
             "@id" : $resourceURN,
              (:  "ecrm:P1_is_identified_by": map { "rdfs:label": $resourceURN},:)
             "title" : $title,
             "description": $description,
             "@type" : "Resource",
             "totalItems": 0,
             "dtslib:dublincore": $DcWithVersions ,
            "dtslib:download": $download,
            "dtslib:citeDepth": $citeDepth,
            "dtslib:citeStructure": $teirefdecl
        }
let $ext :=         if(count($parts) ge 1) then  map:put($all,"dtslib:extensions",$parts) else $all
let $pass :=  if($c le 1) then $ext else map:put($ext, "dtslib:passage", $dtsPass) 
let $nav := if($c le 1) then $pass else map:put($pass, "dtslib:references", $dtsNav)
        return
        $nav
};

declare %private function dtslib:docDesc($doc, $title){
if($doc//t:TEI/@type eq  'nar') 
  then 'The narrative unit '||$title||' in Beta maṣāḥǝft ' 
else if($doc//t:TEI/@type eq  'mss') 
   then 'The transcription of manuscript '|| $title||' in Beta maṣāḥǝft ' 
else 'The abstract textual unit '||$title|| ' in Beta maṣāḥǝft. '  || 
                                 normalize-space(string-join(string:tei2string($doc//t:abstract), ''))
};

declare %private function dtslib:manifests($witnesses, $id){
for $w in config:distinct-values($witnesses)
                               let $witness := $exptit:col/id($w)
                               return 
                                             if ($witness//t:idno[@facs]) then 
                                                 let $facs := string(string-join($witness//t:idno[1]/@facs))
                                                 return
                                                 if(starts-with($facs, 'http')) 
(:                                                 external manifest:)
                                                        then map {"@id": $facs,  "@type": "sc:Manifest", "dc:title":  ("IIIF Manifest for images of " || exptit:printTitleID($w))} 
                                                  else 
(:                                                  our manifest, we can point to a specific range:)
                                             ( if($witness//t:msItem[t:title[@ref=$id]]) then for $x in $witness//t:msItem[t:title[@ref=$id]] return map {"@id": "https://betamasaheft.eu/api/iiif/"||$w||"/range/" || string($x/@xml:id),  
                                                                                                                                "@type": "sc:Range", "dc:title":  ("IIIF Range for images of " || exptit:printTitleID(concat($w, '#', string($x/@xml:id))))} 
                                               else
                                                map {"@id": "https://betamasaheft.eu/api/iiif/"||$w||"/manifest",  "@type": "sc:Manifest", "dc:title":  ("IIIF Manifest for images of " || exptit:printTitleID($w))})
                                    else ()
};

declare %private function dtslib:editioncontent($divuri, $type, $xmlid, $document, $vers, $nosparql){
let $doc := root($document)
let $id := string($doc//t:TEI/@xml:id)
let $title := exptit:printTitleID($id)
let $edtitle := functx:capitalize-first($type) || ' of ' || $title || (if($xmlid='') then '' else (' with ID ' || $xmlid))
let $description := dtslib:docDesc($doc, $title)
let $dc := map{'dc:title':$title}
let $computed := dtslib:computedWit($doc, $id)
let $declared := if($doc//t:TEI/@type eq  'mss') then () else 
                            for $witness in $doc//t:witness/@corresp return string($witness)
(: flattens the distinction between computed and declared witnesses, as well as the eventual nesting of witnesses for each edition:)
let $witnesses := ($computed, $declared)
let $distinctW := dtslib:distinctW($witnesses)
let $manifests := dtslib:manifests($witnesses, $id)
 let $worksAndManifests := ($distinctW, $manifests)                                     
let $dcAndWitnesses := if(count($distinctW) gt 0) then map:put($dc, 'dc:source', $worksAndManifests) else $dc
let $DcSelector := 
if($doc//t:TEI/@type eq  'mss') then $dc else $dcAndWitnesses
(:$dc:)
let $resourceURN := 'https://betamasaheft.eu/' || $id
let $versions := if($vers = 'yes') then dtslib:fileingitCommits($resourceURN, $id, 'collections') else ()
let $DcWithVersions :=  if($vers = 'yes') then map:put($DcSelector, "dc:hasVersion", $versions) else $DcSelector
let $manifest :=dtslib:manifest($doc, $id)
let $addmanifest := if (count($manifest) ge 1) then map{ "foaf:depiction": $manifest} else ()
let $parts := $addmanifest
let $dtsPass := "/api/dts/document?id=" || $divuri
let $dtsNav := "/api/dts/navigation?id=" || $divuri
let $download := "https://betamasaheft.eu/tei/" || $id || '.xml'
let $citeDepth :=  if($doc/@type eq  'mss' and not($doc//t:objectDesc/@form ='Inscription')) then 3 
else let $counts := for $div in ($document//t:div[@type eq 'textpart'], $document//t:l, $document//t:lb) return count($div/ancestor::t:div)
return max($counts)
let $teirefdecl := if($doc/@type eq  'mss' and not($doc//t:objectDesc/@form ='Inscription')) then 
[ map{
                 "dtslib:citeType": "folio",
                    "dtslib:citeStructure": [
                       map {
                            "dtslib:citeType": "page",
                             "dtslib:citeStructure": [
                       map {
                            "dtslib:citeType": "column"
                        }
                  ]
             }
          ]
     }
]
else if ($doc/@type eq 'nar') then ()
else
[
dtslib:nestedDivs($document//t:div[@type eq $type][@xml:id=$xmlid])
            ]
let $c := count($document//t:div[@type eq $type][@xml:id=$xmlid]//t:ab//text())
let $all := map{
             "@id" : $divuri,
              (:  "ecrm:P1_is_identified_by": map { "rdfs:label": $resourceURN},:)
             "title" : $edtitle,
             "description": $description,
             "@type" : "Resource",
             "totalItems": 0,
             "dtslib:dublincore": $DcWithVersions ,
            "dtslib:download": $download,
            "dtslib:citeDepth": $citeDepth,
            "dtslib:citeStructure": $teirefdecl
        }
let $ext :=         if(count($parts) ge 1) then  map:put($all,"dtslib:extensions",$parts) else $all
let $pass :=  if($c le 1) then $ext else map:put($ext, "dtslib:passage", $dtsPass) 
let $nav := if($c le 1) then $pass else map:put($pass, "dtslib:references", $dtsNav)
        return
        $nav
};

declare %private function dtslib:editioncontent($divuri, $type, $xmlid, $document, $vers){
let $doc := root($document)
let $id := string($doc//t:TEI/@xml:id)
let $title := exptit:printTitleID($id)
let $edtitle := functx:capitalize-first($type) || ' of ' || $title || (if($xmlid='') then '' else (' with ID ' || $xmlid))
let $description := dtslib:docDesc($doc, $title)
let $dc := dtslib:dublinCore($id)
let $computed := dtslib:computedWit($doc, $id)
let $declared := if($doc//t:TEI/@type eq  'mss') then () else 
                            for $witness in $doc//t:witness/@corresp return string($witness)
(: flattens the distinction between computed and declared witnesses, as well as the eventual nesting of witnesses for each edition:)
let $witnesses := ($computed, $declared)
let $distinctW := dtslib:distinctW($witnesses)
let $manifests := dtslib:manifests($witnesses, $id)
 let $worksAndManifests := ($distinctW, $manifests)                                     
let $dcAndWitnesses := if(count($distinctW) gt 0) then map:put($dc, 'dc:source', $worksAndManifests) else $dc
let $DcSelector := 
if($doc//t:TEI/@type eq  'mss') then $dc else $dcAndWitnesses
(:$dc:)
let $resourceURN := 'https://betamasaheft.eu/' || $id
let $versions := if($vers = 'yes') then dtslib:fileingitCommits($resourceURN, $id, 'collections') else ()
let $DcWithVersions :=  if($vers = 'yes') then map:put($DcSelector, "dc:hasVersion", $versions) else $DcSelector
let $ext := dtslib:extension($id)
let $haspart := dtslib:haspart($id)
let $manifest :=dtslib:manifest($doc, $id)
let $addmanifest := if (count($manifest) ge 1) then map:put($ext, "foaf:depiction", $manifest) else $ext
let $parts := if(count($haspart) ge 1) then map:put($addmanifest, 'dc:hasPart', $haspart) else $addmanifest
let $dtsPass := "/api/dts/document?id=" || $divuri
let $dtsNav := "/api/dts/navigation?id=" || $divuri
let $download := "https://betamasaheft.eu/tei/" || $id || '.xml'
let $citeDepth :=  if($doc/@type eq  'mss' and not($doc//t:objectDesc/@form ='Inscription')) then 3 
else let $counts := for $div in ($document//t:div[@type eq 'textpart'], $document//t:l, $document//t:lb) return count($div/ancestor::t:div)
return max($counts)
let $teirefdecl := if($doc/@type eq  'mss' and not($doc//t:objectDesc/@form ='Inscription')) then 
[ map{
                 "dtslib:citeType": "folio",
                    "dtslib:citeStructure": [
                       map {
                            "dtslib:citeType": "page",
                             "dtslib:citeStructure": [
                       map {
                            "dtslib:citeType": "column"
                        }
                  ]
             }
          ]
     }
]
else if ($doc/@type eq 'nar') then ()
else
[
dtslib:nestedDivs($document//t:div[@type eq $type][@xml:id=$xmlid])
            ]
let $c := count($document//t:div[@type eq $type][@xml:id=$xmlid]//t:ab//text())
let $all := map{
             "@id" : $divuri,
              (:  "ecrm:P1_is_identified_by": map { "rdfs:label": $resourceURN},:)
             "title" : $edtitle,
             "description": $description,
             "@type" : "Resource",
             "totalItems": 0,
             "dtslib:dublincore": $DcWithVersions ,
            "dtslib:download": $download,
            "dtslib:citeDepth": $citeDepth,
            "dtslib:citeStructure": $teirefdecl
        }
let $ext :=         if(count($parts) ge 1) then  map:put($all,"dtslib:extensions",$parts) else $all
let $pass :=  if($c le 1) then $ext else map:put($ext, "dtslib:passage", $dtsPass) 
let $nav := if($c le 1) then $pass else map:put($pass, "dtslib:references", $dtsNav)
        return
        $nav
};

declare %private function dtslib:haspart($id){
(:the query starts from the part statements, that is it flattens the nesting of parts which is actually available in the XML:)
let $querytext := 
if(starts-with($id, 'LIT')) then (
$config:sparqlPrefixes ||  "
 SELECT ?part
 WHERE {?partID dcterms:hasPart ?subpart ; 
                   dcterms:isPartOf bm:" || $id || " .
                             ?subpart dc:relation ?part . 
                              ?part a lawd:ConceptualWork}"
) 
else (
(:this lists the contents of a manuscript, where the connection to a msitem is also flattened in one dcterms:hasPart step :)
$config:sparqlPrefixes || 
"SELECT ?part
 WHERE {{bm:" || $id || "  dcterms:hasPart ?item . 
                              ?item a sdc:UniCont .
                ?item dcterms:hasPart ?part . }
                UNION
                {?partID dcterms:hasPart ?subpart ; 
                   dcterms:isPartOf bm:" || $id || " .
                             ?subpart dc:relation ?part . }
                              ?part a lawd:ConceptualWork . }"

                              )
let $query := dtslib:callfuseki($querytext)
for $result in $query//sr:binding
return
$result/sr:uri/text()

};

(:~ called by dtslib:dublinCore it expects a dc property name without prefix, and the id of the instance about which the property is stated. sends a sparql query to the triple store and returns the value requested :)
declare %private function dtslib:DCsparqls($id, $property){
if ($property = 'title') then

let $querytext := $config:sparqlPrefixes ||  "SELECT ?"||$property||" ?language 
WHERE {bm:" || $id || " dc:"||$property||" ?"||$property||".
 BIND (lang(?title) AS ?language )
}"
(:let $t := console:log($querytext):)
let $query := dtslib:callfuseki($querytext)
return if (count($query//sr:result) = 0) then map {'@value' : 'No title'} else
for $result in $query//sr:result
let $val := $result/sr:binding[@*:name=$property]/sr:literal/text()
let $lang := $result/sr:binding[@*:name='language']/sr:literal/text()
let $t := map {'@value' : $val}
return 
if($lang !='') then map:put($t, '@lang', $lang) else $t


else 
let $querytext := $config:sparqlPrefixes ||  "SELECT ?"||$property||" 
WHERE {bm:" || $id || " dc:"||$property||" ?"||$property||"}"
let $query := dtslib:callfuseki($querytext)
return 
$query//sr:binding[@*:name=$property]/sr:literal/text()
};

(:~ retrives and adds to a map/array the values needed for the dc values in the member property dtslib:dublinCore() :)
declare function dtslib:dublinCore($id){
let $creator := dtslib:DCsparqls($id, 'creator')
let $contributor := dtslib:DCsparqls($id, 'contributor')
let $language := dtslib:DCsparqls($id, 'language')
let $title := if(starts-with($id, 'LIT')) then dtslib:DCsparqls($id, 'title') else map{'@value' : exptit:printTitleID($id), '@lang' : 'en'}
let $relation := dtslib:DCsparqls($id, 'relation')
let $listChange := for $change in $exptit:col/id($id)//t:change return editors:editorKey($change/@who)
let $contributors := ($contributor, $listChange)
let $all := map{
                "dc:title": $title,
                "dc:creator": [if(count($creator) ge 1) then $contributor else 'Beta maṣāḥǝft Team'],
                "dc:contributor": config:distinct-values($contributors),
                "dc:language": $language
            }
            return
            if(count($relation) ge 1) then  map:put($all,"dc:relation",$relation) else $all
};

(:~ called by dtslib:mapconstructor it expects a property name with prefix, and the id of the instance about 
which the property is stated. Sends a sparql query to the triple store and returns the value requested :)

declare function dtslib:sparqls($id, $property){
let $querytext := $config:sparqlPrefixes ||  "SELECT ?x 
WHERE {bm:" || $id || ' '|| $property||" ?x }"
let $query := dtslib:callfuseki($querytext)
return 
$query//sr:binding[@*:name='x']/sr:*/text()
};

declare function dtslib:sparqlsInverse($id, $property){
let $querytext := $config:sparqlPrefixes ||  "SELECT ?x 
WHERE {?x "|| $property||" bm:"|| $id || " }"
let $query := dtslib:callfuseki($querytext)
return 
$query//sr:binding[@*:name='x']/sr:*/text()
};

declare %private function dtslib:callfuseki($querytext){try{fusekisparql:query('betamasaheft', $querytext)} catch * {console:log('there is a problem calling fuseki')}};
(:~ utility function which takes a map and a list of properties together with a series of indexes to produce a map by recursively 
: being called on successive entries of the list which is carried on until its end. the value in the list is sent to the dtslib:sparql function which runs a sparql querz using the current value
: in the list as property :)
declare %private function dtslib:mapconstructor($id, $currentmap as map()?, $candidateproperty, $index as xs:integer, $listofcandidateproperties){
 if($index = count($listofcandidateproperties)) then $currentmap else
let $next := $listofcandidateproperties[$index]
let $candidatevalue := dtslib:sparqls($id, $candidateproperty)
let $inversestatement := dtslib:sparqlsInverse($id, $candidateproperty)
let $inverseOFcandidateproperty := switch ($candidateproperty)
                                                                            case 'saws:isVersionOf' return 'saws:hasVersion'
                                                                            case 'saws:contains' return 'saws:formsPartOf'
                                                                            case 'saws:formsPartOf' return 'saws:contains'
                                                                            case 'ecrm:CLP46i_may_form_part_of' return 'ecrm:CLP46_should_be_composed_of'
                                                                            case 'saws:isVersionInAnotherLanguageOf' return 'saws:hasVersionInAnotherLanguage'
                                                                            case 'saws:isShorterVersionOf' return 'saws:hasShorterVersion'
                                                                            case 'crm:P129_is_about' return 'P129i_is_subject_of'
                                                                            case 'saws:isDirectCopyOf' return 'saws:hasDirectCopy'
                                                                            case 'saws:isAncestorOf' return 'saws:hasAncestor'
                                                                            case 'saws:isCommentOn' return 'saws:hasComment'
                                                                            default return $candidateproperty
return
if(count($candidatevalue) = 0 and count($inversestatement) = 0) 
then dtslib:mapconstructor($id, $currentmap, $next, $index+1, $listofcandidateproperties) 
else let $updatedmap := if(count($candidatevalue) = 0) then $currentmap else map:put($currentmap, $candidateproperty, $candidatevalue) 
let $updatedmapINV := if(count($inversestatement) = 0) then $updatedmap else map:put($updatedmap, $inverseOFcandidateproperty, $inversestatement) 
return dtslib:mapconstructor($id, $updatedmapINV, $next, $index+1, $listofcandidateproperties)
};

(:~  passes to dtslib:mapconstructor function a list of property names to build a map which only has relevant key-value pair and returns this map. :)
declare %private function dtslib:extension($id){
let $map := map {}
let $list := (
                        'crm:P1_is_identified_by',
                        'crm:P102_has_title',
                        'saws:isAttributedToAuthor', 
                        'saws:contains', 
                        'saws:formsPartOf', 
                        'ecrm:CLP46i_may_form_part_of', 
                        'saws:isDifferentTo', 
                        'saws:isShorterVersionOf', 
                        'saws:isRelatedTo', 
                        'saws:follows', 
                        'saws:isVersionInAnotherLanguageOf', 
                        'saws:isVersionOf', 
                        'crm:P129_is_about',
                        'saws:isDirectCopyOf',
                        'saws:isAncestorOf',
                        'saws:isCommentOn'
                        )
let $START := $list[1]
let $etcmap := dtslib:mapconstructor($id, $map, $START, 2, $list)
return
if (map:size($etcmap) = 0) then () else $etcmap
};

declare  function dtslib:indexEntriesAttestations($id, $indexName, $indexEntries, $page){
let $perpage:=10
let $end := xs:integer($page) * $perpage
let $start := ($end - $perpage) +1
let $refs := for $a in $indexEntries
   let $ref := switch($indexName)
                                    case 'loci' return $a/@cRef
                                    case 'keywords' return $a/@key
                                    default return $a/@ref
   group by $ref
   order by $ref
   let $members := for $att in $a return 
                                    let $closestreference := if($att/preceding-sibling::t:*[@n]) 
                                                                                        then $att/preceding-sibling::t:*[@n][1] 
                                                                                 else if($att/ancestor::t:*[@n]) 
                                                                                        then $att/ancestor::t:*[@n][1] 
                                                                                 else if ($att/ancestor::t:*[@xml:id][name() != 'TEI'])
                                                                                       then $att/ancestor::t:*[@xml:id][name() != 'TEI'][1]
                                                                                 else $att
                                    let $anchor := if($closestreference/name() != 'pb' and 
                                    $closestreference/name() != 'cb' and 
                                    $closestreference/name() != 'lb' and 
                                    $closestreference/name() != 'l' and 
                                    $closestreference/name() != 'div' 
                                    ) then '#' else ()
                                    let $r := $anchor || dtslib:refname($closestreference)
                                    let $t := dtslib:reftitle($closestreference)
                                     let $refmap :=  map {"dtslib:ref": $r}
                                     let $reftit := if($t) then map:put($refmap, 'title', $t) else $refmap
                                     let $refval := if ($att/text()) then map:put($reftit,"@value", normalize-space(string-join($att//text()))) else $reftit
                                     let $reflang := if ($att/text()) then map:put($refval,"@lang", string($att/ancestor-or-self::t:*[@xml:lang][1]/@xml:lang)) else $refval
                                 return $reflang
   return 
                map {"@id" : "https://betamasaheft.eu/" || $ref,
                "title" : exptit:printTitleID($ref),
                            "member": $members}
return                          
subsequence($refs, $start, $end)
};

declare  function dtslib:indexEntriesView($id, $indexName, $indexEntries, $page){
let $refs := for $ref in $indexEntries 
                    let $r := switch($indexName)
                                    case 'loci' return $ref/@cRef
                                    case 'keywords' return $ref/@key
                                    default return $ref/@ref
                    group by $r 
                    return $r
let $count := count($refs)
let $pg := "/api/dts/indexes?id="||$id||"&amp;page="
let $p := xs:integer($page)
let $perpage := 10
let $lastpg := ceiling($count div $perpage)
let $pageid:=  $pg|| string($page)
let $firstpage := $pg ||'1'
let $lastpage:=  $pg ||$lastpg
let $prevpage:= if($p = 1) then () else $pg ||string($p - 1)
let $nextpage :=if($p = $lastpg) then () else $pg ||string($p + 1)
let $end := $p * $perpage
let $start := ($end - $perpage) +1
return
map{
        "@id": $pageid,
        "@type": "PartialIndexView",
        "first": $firstpage,
        "previous": $prevpage,
        "next": $nextpage,
        "last": $lastpage,
        "totalItems": $count,
    "title" : dtslib:indextitle($indexName),
     "name" : $indexName
    }};
    
declare  function dtslib:indexentries($id, $name){
let $file := $exptit:col/id($id)
return
switch($name) 
                            case 'places' return $file//t:placeName[@ref]
                            case 'persons' return $file//t:persName[@ref[. !='PRS00000' and . !='PRS0000']]
                            case 'works' return $file//t:title[@ref]
                            case 'loci' return $file//t:ref[@cRef]
                            case 'keywords' return $file//t:term[@key]
                            default return ()
};

declare function dtslib:indexentriesFile($file, $id, $name){
if ($id='') then 
switch($name) 
                            case 'places' return $file//t:placeName[@ref]
                            case 'persons' return $file//t:persName[@ref]
                            case 'works' return $file//t:title[@ref]
                            case 'loci' return $file//t:ref[@cRef]
                            case 'keywords' return $file//t:term[@key][not(parent::t:keywords)]
                            default return ()
else 
let $cleanid := replace($id, 'https://betamasaheft.eu/', '')
return
switch($name) 
                            case 'places' return $file//t:placeName[@ref =$cleanid]
                            case 'persons' return $file//t:persName[@ref = $cleanid]
                            case 'works' return $file//t:title[@ref = $cleanid]
                            case 'loci' return $file//t:ref[@cRef = $cleanid]
                            case 'keywords' return $file//t:term[@key = $cleanid][not(parent::t:keywords)]
                            default return ()
};

declare function dtslib:indexentriesColl($id, $coll, $name){
(:let $t := console:log($id):)
let $files := dtslib:switchContext($coll)
return
if($id!='') then
(:let $t := console:log($id)
return:)
switch($name)
    case 'persons' return $files//t:persName[@ref = $id]
    case 'places' return $files//t:placeName[@ref=$id]
    case 'works' return $files//t:title[@ref=$id]
    case 'loci' return $files//t:ref[@cRef=$id]
    case 'keywords' return $files//t:term[@key=$id][not(parent::t:keywords)]
    default return ()
    else 
    switch($name)
    case 'places' return $files//t:placeName[@ref]
    case 'persons' return $files//t:persName[@ref[. !='PRS00000' and . !='PRS0000']]
    case 'works' return $files//t:title[@ref]
    case 'loci' return $files//t:ref[@cRef]
    case 'keywords' return $files//t:term[@key][not(parent::t:keywords)]
    default return ()
};

declare %private function dtslib:indextitle($name){
switch($name) 
                            case 'persons' return 'Index of persons'
                            case 'places' return 'Index of places'
                            case 'works' return 'Index of textual units'
                            case 'loci' return 'Index locorum'
                            case 'keywords' return 'Index of keywords'
                            default return ()
};

declare  function dtslib:CollIndex($id, $page, $version){
[
      map {"name": "persons"},
      map {"name": "places"},
      map {"name": "works"},
      map {"name": "loci"},
      map {"name": "keywords"}
    ]};
    
declare  function dtslib:CollIndexMember($id, $edition, $specificID, $page, $version){
let $file := $exptit:col/id($specificID)
let $pl:= if ($file//t:placeName[@ref]) then map{"name": "places"} else ()
let $pr:= if ($file//t:persName[@ref]) then map{"name": "persons"} else ()
let $w:= if ($file//t:title[@ref]) then map{"name": "works"} else ()
let $loci:= if ($file//t:ref[@cRef]) then map{"name": "loci"} else ()
let $key:= if ($file//t:term[@key][not(parent::t:keywords)]) then map{"name": "places"} else ()
return ($pl, $pr, $w, $loci, $key)
};




declare function dtslib:AnnoItems($coll){
let $context:= dtslib:switchContext($coll)
return $context//t:TEI[descendant::t:persName[@ref[. !='PRS00000' and . !='PRS0000']] or descendant::t:placeName[@ref] or descendant::t:title[@ref] or descendant::t:term[@key][not(parent::t:keywords)] or descendant::t:ref[@cRef]]
};

(:~ print the annotations for an id (content of ref as http://webannotation.org/)
after the example by Thibault Clérice in DTS 
https://github.com/distributed-text-services/specifications/issues/167
:)
declare  function dtslib:WebAnn($id, $indexEntries, $page){
(:let $t := console:log($id):)
let $perpage:=10
let $end := xs:integer($page) * $perpage
let $start := ($end - $perpage) +1
for $wa in subsequence($indexEntries, $start, $end)
let $sourceID := $config:appUrl || '/'|| string($wa/ancestor::t:TEI/@xml:id)
let $t := normalize-space(string-join($wa//text()))
let $lang := string($wa/ancestor-or-self::t:*[@xml:lang][1]/@xml:lang)
let $xpath :=  functx:path-to-node-with-pos($wa)
let $closestreference := if($wa/preceding-sibling::t:*[@n]) 
                                             then $wa/preceding-sibling::t:*[@n][1] 
                                               else if($wa/ancestor::t:*[@n]) 
                                             then $wa/ancestor::t:*[@n][1] 
                                                 else if ($wa/ancestor::t:*[@xml:id][name() != 'TEI'])
                                             then $wa/ancestor::t:*[@xml:id][name() != 'TEI'][1]
                                                  else $wa
let $anchor := if($closestreference/name() != 'pb' and 
                                    $closestreference/name() != 'cb' and 
                                    $closestreference/name() != 'lb' and 
                                    $closestreference/name() != 'l' and 
                                    $closestreference/name() != 'div' 
                                    ) then '#' else ()
let $r := $anchor || dtslib:refname($closestreference)
let $doc := if(starts-with($r, '#')) 
                    then ( '/api/dts/document'|| '?id='|| $sourceID) 
                    else ( '/api/dts/document'|| '?id='|| $sourceID||'&amp;ref=' || $r)
let $nav := '/api/dts/navigation'|| '?id='|| $sourceID||'&amp;ref=' || $r
let $dtslinks := if(starts-with($r, '#')) 
                            then map{"dtslib:passage" : $doc} 
                            else map {"dtslib:passage" : $doc, "dtslib:references" : $nav}
let $separator := if(starts-with($r, '#')) then () else '.'
let $tit := if(starts-with($r, '#')) 
                  then exptit:printSubtitle($closestreference, $r) 
                  else dtslib:reftitle($closestreference)
let $level := if (contains($r, '\.')) then string(count(tokenize($r, '\.'))) else '1'
let $cdepth := dtslib:citeDepth($closestreference/ancestor::t:div[@type eq 'edition'])
let $ctype := dtslib:typename($closestreference, 'textpart')
let $basesource := map{"type": "Resource",
			 "dtslib:ref": $r,
			 "dtslib:citeType": $ctype/text(),
			 "dtslib:level": $level,
                                            "dtslib:citeDepth": $cdepth,
			 "id": $sourceID,
			 "link" : ($sourceID ||$separator || $r)}
let $source := map:merge(($dtslinks, $basesource))
   return
map {
		  "@context": "http://www.w3.org/ns/anno.jsonld",
		  "type": "Annotation",
		  "body": [
		   map {
		      "role": $wa/name(),
		      "text": $t ,
		      "id": $id,
		      "@lang" : $lang
		    }
		  ],  
		  "target": map {
		    "source": $source,
		    "selector": map{
		      "type": "XPathSelector",
		      "value" :$xpath
		      }
		  }
		}

};


(:~ given the collection name and the count of children collections and partens
returns an object to be merged into a response:)
declare function dtslib:annotationCollection($collname, $indexesCount, $parents){
map {
    "@type" : 'AnnotationCollection',
    "title": "Annotations of "||$collname||" Root Collection",
    "@id": $config:appUrl || '/api/dts/annotations/' ||$collname,
    "totalItems": $indexesCount,
    "dtslib:totalParents": $parents,
    "dtslib:totalChildren": $indexesCount
    }};
    
(:~ given the collection name and the count of parents
returns an object to be merged into a response which contains the 
special annotation collection with one collection for each item
the count of parents must be provided but the number of child collection is
computer to retrieve the number of actually available indexes for that item
i.e. if there is no persName[@ref] there is no need for an index of persons for that item:)
declare function dtslib:ItemAnnotationCollection($collname, $parents){
    let $c := dtslib:ItemAnnotationsEntries($collname)
    return
map {
    "@type" : 'AnnotationCollection',
    "title": "Annotations of each item in "||$collname,
    "@id": $config:appUrl || '/api/dts/annotations/' ||$collname ||'/items',
    "totalItems": $c,
    "dtslib:totalParents": $parents,
    "dtslib:totalChildren": $c
    }};

(:~ given the collection name and the count of children
returns an object to be merged into a response which contains the 
special annotation collection with one collection for each item
the count of parents is set to 2:)
declare function dtslib:ItemsAnnotationsCollections($collname, $c){
map {
    "@type" : 'AnnotationCollection',
    "title": "Annotations of each item in "||$collname,
    "@id": $config:appUrl || '/api/dts/annotations/' ||$collname ||'/items',
    "totalItems": $c,
    "dtslib:totalParents": 2,
    "dtslib:totalChildren": $c
    }};
    
(:~ This is used by the special Annotation Collection of EACH ITEM.
given the collection name and the index entries (which in this case will be a list of TEI nodes) 
and the page parameter
returns a sequence of objects, which are annotations collections for each item 
to be merged into a response :)    
declare  function dtslib:AnnoItemInfo($collname, $indexEntries, $page){
let $perpage:=10
let $end := xs:integer($page) * $perpage
let $start := ($end - $perpage) +1
for $item in subsequence($indexEntries, $start, $end)
let $id := string($item/@xml:id)
   let $indexes := ('persons', 'places', 'works', 'loci', 'keywords')
   let $file := $exptit:col/id($id)
 let $availableIndexesForItem :=   for $index in $indexes 
let $count := dtslib:ItemAnnotationsEntries($file, $index)
return if($count=0) then () else 'yes'
let $c := count($availableIndexesForItem)
    let $title := exptit:printTitleID($id)
    return
map {
    "@type" : 'AnnotationCollection',
    "title": "Annotations of "||$title||" in "||$collname,
    "@id": $config:appUrl || '/api/dts/annotations/' ||$collname ||'/items/' || $id,
    "totalItems": $c,
    "dtslib:totalParents": 3,
    "dtslib:totalChildren": $c
    }};
    
    

declare  function dtslib:AnnoEntriesAttestations($indexName, $indexEntries, $page){
let $perpage:=10
let $end := xs:integer($page) * $perpage
let $start := ($end - $perpage) +1
let $refs := for $a in $indexEntries
   let $ref := switch($indexName)
                                    case 'loci' return $a/@cRef
                                    case 'keywords' return $a/@key
                                    default return $a/@ref
   group by $ref
   let $c := count($a)
   order by $c descending
   return <ref><id>{string($ref)}</id><count>{$c}</count></ref>
   
   for $r in subsequence($refs, $start, $end)
   let $c := $r//*:count/text()
   let $i := $r//*:id/text()
return    
                dtslib:refannocol($i, $c, $indexName)
 };
 
 declare function dtslib:AnnoEntriesAttestationsItem($BMid, $title, $indexName, $indexEntries, $page){
let $perpage:=10
let $end := xs:integer($page) * $perpage
let $start := ($end - $perpage) +1
let $refs := for $a in $indexEntries
                     let $ref := switch($indexName)
                                    case 'loci' return $a/@cRef
                                    case 'keywords' return $a/@key
                                    default return $a/@ref
                    group by $ref
                        let $c := count($a)
                        let $tit :=  if(contains($ref, 'urn:')) 
                                            then $ref 
                                            else    
                                                    try{exptit:printTitleID($ref)} 
                                                    catch*{console:log($err:description)}
                    order by $c descending
                    return 
                        <ref>
                        <title>{$tit}</title>
                        <id>{string($ref)}</id>
                        <count>{$c}</count>
                        </ref>
   let $orderedRefs := for $r in $refs 
                                        let $sortingkey := dtslib:sortingkey($r/*:title)
                                        order by $sortingkey
                                        return $r
   for $r in subsequence($orderedRefs, $start, $end)
   let $c := $r//*:count/text()
   let $i := $r//*:id/text()
   let $entityorlocus := $r//*:title/text()
   
return    
                dtslib:refannocolItem($BMid, $title, $i, $c, $indexName, $entityorlocus)
 };

declare function dtslib:refannocol($i, $c, $indexName){
(:let $t:= console:log($i):)
let $entityorlocus := if(matches($i, 'urn') or matches($i, 'betmas:')) then $i else exptit:printTitleID($i)
let $IDentityorlocus := if(matches($i, 'urn') or matches($i, 'betmas:')) then $i else  "https://betamasaheft.eu/" || $i
return
map {"@id" : $IDentityorlocus,
                "title" : 'Annotations of ' || $entityorlocus || ' in ' || $indexName || ' index.',
                   "totalItems" : $c,
             "@type" : "AnnotationCollection",
             "dtslib:totalParents": 3,
             "dtslib:totalChildren": $c}
};

declare function dtslib:refannocolItem($BMid, $title, $i, $c, $indexName, $entityorlocus){

let $IDentityorlocus := if(contains($i, 'urn:')) then $i 
                                            else if(starts-with($i, 'wd:')) then  replace($i, 'wd:', 'https://www.wikidata.org/entity/')
                                            else if(starts-with($i, 'pleiades:')) then  replace($i, 'pleaides:', 'https://pleiades.stoa.org/places/')
                                            else  "https://betamasaheft.eu/" || $i
return
map {"@id" : $IDentityorlocus,
            "shortTitle" : $entityorlocus,
           "title" : 'Annotations of ' || $entityorlocus|| ' in ' || $indexName || ' index of ' || $title || ' (' ||$BMid||')',
           "totalItems" : $c,
             "@type" : "AnnotationCollection",
             "dtslib:totalParents": 3,
             "dtslib:totalChildren": $c}
};

declare function dtslib:AnnoEntriesView($path, $id, $indexName, $indexEntries, $page){
let $refs := for $ref in $indexEntries 
                    let $r := switch($indexName)
                                    case 'loci' return $ref/@cRef
                                    case 'keywords' return $ref/@key
                                    default return $ref/@ref
                    group by $r 
                    return $r 
let $count := if($id!='' or $indexName='items') then count($indexEntries) else count($refs)
let $pg := $path || (if($id = '') then "?page=" else '?id=' || $id ||"&amp;page=")
let $p := xs:integer($page)
let $perpage := 10
let $lastpg := ceiling($count div $perpage)
let $pageid:=  $pg|| string($page)
let $firstpage := $pg ||'1'
let $lastpage:=  $pg ||$lastpg
let $prevpage:= if($p = 1) then () else $pg ||string($p - 1)
let $nextpage :=if($p = $lastpg) then () else $pg ||string($p + 1)
let $end := $p * $perpage
let $start := ($end - $perpage) +1
return
map{
        "@id": $pageid,
        "@type": "PartialIndexView",
        "first": $firstpage,
        "previous": $prevpage,
        "next": $nextpage,
        "last": $lastpage,
        "totalItems": $count,
    "title" : dtslib:indextitle($indexName),
     "name" : $indexName
    }};

declare function dtslib:annotationsEntries($files, $name){
switch($name) 
                            case 'persons' return count($files//t:TEI[descendant::t:persName[@ref[. !='PRS00000' and . !='PRS0000']]])
                            case 'places' return count($files//t:TEI[descendant::t:placeName[@ref]])
                            case 'works' return count($files//t:TEI[descendant::t:title[@ref]])
                            case 'loci' return count($files//t:TEI[descendant::t:ref[@cRef]])
                            case 'keywords' return count($files//t:TEI[descendant::t:term[@key][not(parent::t:keywords)]])
                            default return ()
};

declare function dtslib:ItemAnnotationsEntries($files, $name){
switch($name) 
                            case 'persons' return count($files//t:persName[@ref[. !='PRS00000' and . !='PRS0000']])
                            case 'places' return count($files//t:placeName[@ref])
                            case 'works' return count($files//t:title[@ref])
                            case 'loci' return count($files//t:ref[@cRef])
                            case 'keywords' return count($files//t:term[@key][not(parent::t:keywords)])
                            default return ()
};

declare function dtslib:ItemAnnotationsEntries($name){
switch($name) 
                            case 'mss' return count($dtslib:collection-rootMS//t:TEI[descendant::t:persName[@ref[. !='PRS00000' and . !='PRS0000']] or descendant::t:placeName[@ref] or descendant::t:title[@ref] or descendant::t:term[@key][not(parent::t:keywords)] or descendant::t:ref[@cRef]])
                            case 'works' return count($dtslib:collection-rootW//t:TEI[descendant::t:persName[@ref] or descendant::t:placeName[@ref] or descendant::t:title[@ref] or descendant::t:term[@key][not(parent::t:keywords)] or descendant::t:ref[@cRef]])
                            case 'nar' return count($dtslib:collection-rootN//t:TEI[descendant::t:persName[@ref] or descendant::t:placeName[@ref] or descendant::t:title[@ref] or descendant::t:term[@key][not(parent::t:keywords)] or descendant::t:ref[@cRef]])
                            default return count(($dtslib:collection-rootMS,$dtslib:collection-rootW,$dtslib:collection-rootN)//t:TEI[descendant::t:persName[@ref] or descendant::t:placeName[@ref] or descendant::t:title[@ref] or descendant::t:term[@key][not(parent::t:keywords)] or descendant::t:ref[@cRef]])
};

declare %private function dtslib:ItemAnnoCount($id){
count($exptit:col//id($id)[descendant::t:persName[@ref[. !='PRS00000' and . !='PRS0000']] or descendant::t:placeName[@ref] or descendant::t:title[@ref] or descendant::t:term[@key][not(parent::t:keywords)] or descendant::t:ref[@cRef]])
};

declare %private function dtslib:MainAnnotationCollections($context, $index, $count){
map {
             "@id" : $config:appUrl ||"/api/dts/annotations/"||$context ||'/'|| $index,
             "title" : "Index of " || $index ||' for ' || $context,
             "@type" : "AnnotationCollection",
             "totalItems" : $count,
             "dtslib:totalParents": 1,
             "dtslib:totalChildren": $count
        }
        };
        
declare function dtslib:ItemAnnotationCollections($coll, $BMid, $title, $index, $count, $parents){
map {
             "@id" : $config:appUrl ||"/api/dts/annotations/"||$coll ||'/items/'||$BMid ||'/'|| $index,
             "title" : "Index of " || $index ||' for ' || $title || ' in ' || $coll,
             "@type" : "AnnotationCollection",
             "totalItems" : $count,
             "dtslib:totalParents": $parents,
             "dtslib:totalChildren": $count
        }
        };

declare function dtslib:switchContext($context){
switch ($context)
case 'mss' return $dtslib:collection-rootMS
case 'works' return $dtslib:collection-rootW
case 'nar' return $dtslib:collection-rootN
(:default is value 'all':)
default return ($dtslib:collection-rootMS, $dtslib:collection-rootW, $dtslib:collection-rootN)
};

declare  function dtslib:CollAnno($context, $indexes){
let $c := dtslib:switchContext($context)
for $index in $indexes 
let $count := dtslib:annotationsEntries($c, $index)
return if($count=0) then () else dtslib:MainAnnotationCollections($context, $index, $count)
};
    
declare %private function dtslib:CollAnnoMember($id, $edition, $specificID, $page, $version){
let $file := $exptit:col/id($specificID)
let $pl:= if ($file//t:placeName[@ref]) then map{"name": "places"} else ()
let $pr:= if ($file//t:persName[@ref[. !='PRS00000' and . !='PRS0000']]) then map{"name": "persons"} else ()
let $w:= if ($file//t:title[@ref]) then map{"name": "works"} else ()
let $loci:= if ($file//t:ref[@cRef]) then map{"name": "loci"} else ()
let $key:= if ($file//t:term[@key][not(parent::t:keywords)]) then map{"name": "places"} else ()
return ($pl, $pr, $w, $loci, $key)
};

declare function dtslib:sortingkey($input){ string-join($input//text())
             => replace('ʾ', '')
             =>replace('ʿ','')
             =>replace('\s','')
             =>translate('ƎḤḪŚṢṣŠǦḫḥǝʷāṖ','EHHSSsSGhhewaP') 
             => lower-case()};