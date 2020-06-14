xquery version "3.1" encoding "UTF-8";
(:~
 : test implementation of the https://github.com/distributed-text-services
 : SERVER
 : @author Pietro Liuzzo 
 : to do 
 : if I want to retrive 1ra@ወወልድ[1]-3vb, should the  @ወወልድ[1] piece also be in the passage/start/end parameter 
: 
: add Hydra navigation instead of the header links
:
: "view": {
:        "@id": "/api/dts/document/?id=lettres_de_poilus&passage=19",
:        "@type": "PartialDocumentView",
:        "first": "/api/dts/document/?id=lettres_de_poilus&passage=1",
:        "previous": "/api/dts/document/?id=lettres_de_poilus&passage=18",
:       "next": "/api/dts/document/?id=lettres_de_poilus&passage=20",
:       "last": "/api/dts/docuemtn/?id=lettres_de_poilus&passage=500"
:   }
:
: add possibility of having a collection grouping by institution or catalogue for the manuscripts
: 
: urn:dts:betmasMS:INS0012bla:BLorient12314
:
: urn:dts:betmasMS:Zotemberg1234:BLorient12314
 :)

(:
texts
LIT1349EpistlEusebius short text with <l n="2"/>text()
LIT1758Lefafa multiple editions 
LIT1546Genesi div/div/ab/l[@n]/text()
LIT2170Peripl multiple pb and divs + images
LIT1401Physio + versions
LIT2375Synaxa (months/days structure)
LIT5439rie iscription


manuscripts
BLorient718 standard div[folio] with pb + cb
EMIP01859 
divs + pb and cb
        where also corresp with NARR are available NAR0019SBarkisos
level 1 not available, but normal page level and column level are available.

DW03
DabraLibanosHamGG1
IVEf921 letter only mss transcription
RIE 285 multiple text inscription
RIE193 inscription, only divs
:)
module namespace dts="https://www.betamasaheft.uni-hamburg.de/BetMas/dts";

declare namespace output="http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace t="http://www.tei-c.org/ns/1.0";
declare namespace exist = "http://exist.sourceforge.net/NS/exist";
declare namespace s = "http://www.w3.org/2005/xpath-functions";
declare namespace http = "http://expath.org/ns/http-client";
declare namespace json = "http://www.json.org";
declare namespace cx ="http://interedition.eu/collatex/ns/1.0";
declare namespace sr="http://www.w3.org/2005/sparql-results#";
declare namespace test="http://exist-db.org/xquery/xqsuite";
import module namespace functx="http://www.functx.com";
import module namespace rest = "http://exquery.org/ns/restxq";
import module namespace log="http://www.betamasaheft.eu/log" at "xmldb:exist:///db/apps/BetMas/modules/log.xqm";
import module namespace titles="https://www.betamasaheft.uni-hamburg.de/BetMas/titles" at "xmldb:exist:///db/apps/BetMas/modules/titles.xqm";
import module namespace config="https://www.betamasaheft.uni-hamburg.de/BetMas/config" at "xmldb:exist:///db/apps/BetMas/modules/config.xqm";
import module namespace fusekisparql = 'https://www.betamasaheft.uni-hamburg.de/BetMas/sparqlfuseki' at "xmldb:exist:///db/apps/BetMas/fuseki/fuseki.xqm";
import module namespace string = "https://www.betamasaheft.uni-hamburg.de/BetMas/string" at "xmldb:exist:///db/apps/BetMas/modules/tei2string.xqm";
import module namespace switch2 = "https://www.betamasaheft.uni-hamburg.de/BetMas/switch2" at "xmldb:exist:///db/apps/BetMas/modules/switch2.xqm";
import module namespace editors = "https://www.betamasaheft.uni-hamburg.de/BetMas/editors" at "xmldb:exist:///db/apps/BetMas/modules/editors.xqm";
import module namespace console="http://exist-db.org/xquery/console";
declare option output:method "json";
declare option output:indent "yes";
declare variable $dts:context := map{
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
  
    declare function dts:capitalize-first
  ( $arg as xs:string? )  as xs:string? {

   concat(upper-case(substring($arg,1,1)),
             substring($arg,2))
 } ;
 
  declare function dts:fileingitCommits($id, $bmID, $apitype){
  let $file := $config:collection-root/id($bmID)[name()='TEI']
let $collection := if($file/@type='mss') then 'Manuscripts' else if($file/@type='nar') then 'Narrative' else 'Works'
let $permapath := replace(dts:capitalize-first(substring-after(base-uri($file), '/db/apps/BetMasData/')), $collection, '')
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
declare function dts:apparatus2string($apparatus as node()*){
 for $node in $apparatus
    return
        typeswitch ($node)
        case element(cx:apparatus)
                return <div>{dts:apparatus2string($node/node())}</div>
        case element(t:app)
                return <div class="row">{dts:apparatus2string($node/node())}</div>
        case element(t:rdg)
                return <div>{string($node/@wit)}{dts:apparatus2string($node/node())}</div>
        case text()
                return if ($node/parent::cx:apparatus) then <div class="row">{dts:apparatus2string($node/node())}</div> else $node
        case element()
                return
                    dts:apparatus2string($node/node())
        default
                return
                    $node
};

(:~ Given a dts urn distinguish if it is a manuscript or a work and parse with analyse string the urn to split it into its components. :)
declare function dts:parseDTSURN($dts){
if(matches($dts, 'https://betamasaheft.eu/LIT' )) 
then 
let $analyse := analyze-string($dts,"(https://)(betamasaheft.eu/)([a-zA-Z\d]+)(:)(((\d+)((\.)(\d+))?((\.)(\d+))?((@)([\p{L}]+)(\[(\d+|last)\])?)?)?(\-)?((\d+)((\.)(\d+))?((\.)(\d+))?((@)([\p{L}]+)(\[(\d+|last)\])?)?)?)")
return  $analyse
else
let $analyse := analyze-string($dts,"(https://)(betamasaheft.eu/)([a-zA-Z\d]+)(:)(NAR\d+\w+|((\d+)(\w)?(\w)?((@)([\p{L}]+)(\[(\d+|last)\])?)?)?(\-)?((\d+)(\w)?(\w)?((@)([\p{L}]+)(\[(\d+|last)\])?)?)?)")
return $analyse
};

(:~ Given a dts urn distinguish if it is a manuscript or a work and parse with analyse string the urn to split it into its components. :)
declare function dts:parseDTS($dts){
analyze-string($dts,"(https://betamasaheft.eu/)(textualunits|narrativeunits|transcriptions)?([a-zA-Z\d]+)?(_(ED|TR)_([a-zA-Z0-9]+)?)?(((\d+)(\w)?(\w)?((@)([\p{L}]+)(\[(\d+|last)\])?)?)?(\-)?((\d+)(\w)?(\w)?((@)([\p{L}]+)(\[(\d+|last)\])?)?)?)")
};


(:~ Given a  string which is expected to be a dts passage parameter it parses with regex and returns the result 
of an analyze string function to split parts of . this version has a regex matching manuscript transcription references:)
declare function dts:parsePassageMS($passage){
let $parsed := analyze-string($passage, '((\d+)(\w)?)(\w)?((@)([\p{L}]+)(\[(\d+|last)\])?)?')
return
$parsed
};

(:~ Given a  string which is expected to be a dts passage parameter it parses with regex and returns the result of an analyze string function to split parts of . this version has a regex matching two levels in a reference to a work:)
declare function dts:parsePassage($passage){
let $parsed := analyze-string($passage, '(\d+)(.)?(\d+)?((@)([\p{L}]+)(\[(\d+|last)\])?)?')
return
$parsed
};


(:~ Given a string text in fidal, removes punctuation. This function is intended to clean up text in preparation for collatex :)
declare function dts:cleanforcollatex($text){
let $cleantext := $text => replace('\.', '') (:=> replace('፡', '') => replace('።', '') => replace('፨', '') => replace('፤', ''):) 
return
normalize-space($cleantext)
};


(:~ Xpath to select the text nodes requested from a manuscript given the transcription nodes in div[@type='edition'] starting page break and column break :)
declare function dts:passageSelector($text, $pb, $cb){
if($cb='') then  $text//t:ab//text()[preceding::t:pb[position()=1][@n = $pb]]
else $text//t:ab//text()[preceding::t:pb[position()=1][@n = $pb] and preceding::t:cb[position()=1][@n = $cb]]
};

(:~ Xpath to select the nodes requested  from a manuscript given the transcription nodes in div[@type='edition'] :)
declare function dts:TranscriptionPassageNodes($text, $pb, $cb){
if($cb='') then 
$text//t:ab//node()[preceding::t:pb[position()=1][@n = string($pb)]]

else
$text//t:ab//node()[preceding::t:pb[position()=1][@n = $pb] and preceding::t:cb[position()=1][@n = $cb]]
};

declare function dts:TranscriptionPassageNodesLB($text, $lb){
$text//t:ab//node()[preceding::t:lb[position()=1][@n = string($lb)]]
};

(:~ Xpath to select the nodes requested from a work given passage with two levels :)
declare function dts:EditionPassageNodes($text, $level1, $level2){
if($level2='') then 
$text//t:*[number(@n)= $level2][parent::t:*[@n=$level1]]

else
$text//t:*[number(@n)=$level1][parent::t:*[@type='edition']]
};

(:~ Xpath to select the nodes requested from a work given passage with two levels. If a part of the content of a div is requested, then the div will be reproduced with the @n only and used to wrap the relevant subparts:)
declare function dts:EditionPassageNodesRange($text, $level1, $level2, $startOrEnd){

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
declare function dts:TranscriptionPassageText ($parsedURN, $p1, $p2, $text, $pb, $cb){
let $nodes := dts:passageSelector($text, $pb, $cb) 

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


(:~ Produces as string a json object which contains the id of the manuscript witnesses selected and the text passege as of the urn  which can be used to build the body of a post request to collatex:)
declare function dts:getCollatexWitnessText($dtsURN){

let $parsedURN := dts:parseDTSURN($dtsURN)

let $id := $parsedURN//s:group[@nr=3]/text()
let $file := $config:collection-root/id($id)[name()='TEI']
let $passage := $parsedURN//s:group[@nr=5]/text()
return
if (matches($passage, 'NAR')) then (let $text := string-join($file//t:*[@corresp = $passage]//text())
let $cleantext := dts:cleanforcollatex($text) return '{"id" : "' ||$id ||'", "content" : "'||$cleantext||'"}' )
else if ($file/@type='mss')  then
let $frompage := $parsedURN//s:group[@nr=7] ||$parsedURN//s:group[@nr=8]
let $fromcolumn := $parsedURN//s:group[@nr=9] 
let $topage := $parsedURN//s:group[@nr=17] ||$parsedURN//s:group[@nr=18]
let $tocolumn := $parsedURN//s:group[@nr=19] 
let $text := $config:collection-rootMS/id($id)//t:div[@type='edition']
let $content := 
(:if there is - (group 15) it is an inclusive range:)
if($parsedURN//s:group[@nr=15] = '-') then

(
let $div1 := $text//t:pb[@n=$frompage]/ancestor::t:div/@n
let $part1 := dts:TranscriptionPassageText($parsedURN, 11, 14, $text, $frompage, $fromcolumn)

let $div2 := $text//t:pb[@n=$topage]/ancestor::t:div/@n
let $part2 :=  dts:TranscriptionPassageText($parsedURN, 21, 24, $text, $topage, $tocolumn)

let $middle := $text//t:ab[parent::t:div[(number(@n) gt number(string($div1))) and (number(@n) lt number(string($div2)))]]//text()
let $middlepart := normalize-space(string-join($middle, ' '))

let $all := if($frompage = $topage and $fromcolumn = $tocolumn) then (substring-before($part1, $parsedURN//s:group[@nr=22]/text()) ||' ' || $parsedURN//s:group[@nr=22]/text())  else ($part1, $middlepart,$part2)

return
$all

)
else (
let $nodes := dts:passageSelector($text, $frompage, $fromcolumn) 

let $join := string-join($nodes, '')
return
(
(:if there is @ limit:)
if($parsedURN//s:group[@nr=11] = '@') 
then 
let $position := if(matches($parsedURN//s:group[@nr=14], '\d+')) then $parsedURN//s:group[@nr=14]/text() else if ($parsedURN//s:group[@nr=14]= 'last') then 'last()' else '1'
let $term := $parsedURN//s:group[@nr=12]/text()
let $indexposition := functx:index-of-string($join,$term) 
let $index := if(count($indexposition) = 1) then $indexposition else $indexposition[$position]
            return normalize-space(substring($join, $index))
(:otherways the entire:)
else normalize-space($join)
)
)
let $joinAll := string-join($content, ' ')
let $clean := dts:cleanforcollatex($joinAll)
(:limits to a maximum 2000 characters including whitespaces the text passed to collatex:)
let $limit := substring($clean, 1, 2000)
return
 '{"id" : "' ||$id ||'", "content" : "'||$limit||'"}'
else (
(:This function is for manuscript witnesses, and returns the mini format required by collatex. you do not collate editions:)
)
};

(:~ Calls for each witness  dts:getCollatexWitnessText()  and builds the array which can be passed as body of the POST request to collatex:)
declare function dts:getCollatexBody($urns){ 
let $matchingmss := for $ms in $urns
                                            let $witness := dts:getCollatexWitnessText($ms)
                                           return
                                           $witness
                          return
            '{"witnesses" : [' ||string-join($matchingmss, ',') ||']}'
            };
            
(:~ Calls for each witness of a specified narrative builds the array which can be passed as body of the POST request to collatex:)
declare function dts:getnarrUnitWittnesses($nU){ 
let $matchingmss := for $ms in $config:collection-rootMS//t:*[@corresp = $nU]
                                           let $id := string($ms/ancestor::t:TEI/@xml:id)
                                           let $text := string-join($ms//text())
                                            let $cleantext := dts:cleanforcollatex($text)
                                             return
                                         '{"id" : "' ||$id ||'", "content" : "'||$cleantext||'"}' 
                          return
            '{"witnesses" : [' ||string-join($matchingmss, ',') ||']}'
            };

(:~ Main access point to DTS style API returning passages from text :)
declare
%rest:GET
%rest:path("/BetMas/api/dts")
%output:method("json")
function dts:dtsmain() {

  ( $config:response200JsonLD,
  map {
  "@context": "/dts/api/contexts/EntryPoint.jsonld",
  "@id": "/api/dts",
  "@type": "EntryPoint",
  "collections": "/api/dts/collections",
  "documents": "/api/dts/document",
  "navigation" : "/api/dts/navigation",
  "indexes" : "/api/dts/indexes"
})
         
};

(:~ dts/collection https://github.com/distributed-text-services/specifications/blob/master/Collection-Endpoint.md :)
declare
%rest:GET
%rest:path("/BetMas/api/dts/collections")
%rest:query-param("id", "{$id}",  "")
%rest:query-param("version", "{$version}",  "")
%rest:query-param("page", "{$page}", 1)
%rest:query-param("nav", "{$nav}", "children")
%output:method("json")
function dts:Collection($id as xs:string*,$page as xs:integer*,$nav as xs:string*,$version as xs:string*) {
if($id = '') then (
 <rest:response>
  <http:response status="302">
    <http:header name="location" value="/api/dts/collections?id=https://betamasaheft.eu"/>
    <http:header
                    name="Access-Control-Allow-Origin"
                    value="*"/>
  </http:response>
</rest:response>
) else
if(matches($id, '(https://betamasaheft.eu/)?(textualunits/|narrativeunits/|transcriptions/)?([a-zA-Z\d]+)?(:)?(((\d+)(\w)?(\w)?((@)([\p{L}]+)(\[(\d+|last)\])?)?)?(\-)?((\d+)(\w)?(\w)?((@)([\p{L}]+)(\[(\d+|last)\])?)?)?)')) then
let $parsedURN := dts:parseDTS($id)
return
if (matches($parsedURN//s:group[@nr=2], '(textualunits|narrativeunits|transcriptions)'))
then (dts:Coll($id, $page, $nav, $version))
else
if (matches($parsedURN//s:group[@nr=3], '[a-zA-Z\d]+'))
then (
                let $specificID := $parsedURN//s:group[@nr=3]/text() 
                let $edition := $parsedURN//s:group[@nr=4]
                return dts:CollMember($id, $edition, $specificID, $page, $nav, $version))
else
dts:Coll($id, $page, $nav, $version)
else 
(
$config:response400 ,
let $error := $id|| "is not a valid URN pattern"
return
map {
  "@context": "http://www.w3.org/ns/hydra/context.jsonld",
  "@type": "Status",
  "statusCode": 400,
  "title": "Not Found",
  "description": " Resource requested is not found ", "error": $error}
)
};


declare function dts:redirectToCollections (){

<rest:response>
  <http:response status="302">
    <http:header name="location" value="/api/dts/collections?id=https://betamasaheft.eu"/>
    <http:header
                    name="Access-Control-Allow-Origin"
                    value="*"/>
  </http:response>
</rest:response>};

declare function dts:redirectToRDF($id){

<rest:response>
  <http:response status="302">
    <http:header name="location" value="/{$id}"/>
    <http:header
                    name="Access-Control-Allow-Origin"
                    value="*"/>
  </http:response>
</rest:response>};


declare function dts:redirectToPDF($id){

<rest:response>
  <http:response status="302">
    <http:header name="location" value="/{$id}.pdf"/>
    <http:header
                    name="Access-Control-Allow-Origin"
                    value="*"/>
  </http:response>
</rest:response>};


declare function dts:redirectToHTML($id, $ref, $start){

<rest:response>
  <http:response status="302">
    <http:header name="location" value="/{switch2:col(switch2:switchPrefix($id))}/{$id}/text?start={if($ref != '') then $ref else if($start  != '') then $start else '1'}"/>
    <http:header
                    name="Access-Control-Allow-Origin"
                    value="*"/>
  </http:response>
</rest:response>
};

(:(\:~ 
dts/document https://github.com/distributed-text-services/specifications/blob/master/Document-Endpoint.md
:\)
declare
%rest:GET
%rest:path("/BetMas/api/dts/document")
%rest:query-param("id", "{$id}",  "")
%rest:query-param("ref", "{$ref}", "")
%rest:query-param("start", "{$start}", "")
%rest:query-param("end", "{$end}", "")
%rest:consumes("application/xml", "application/tei+xml","text/xml")
%rest:produces("application/xml", "application/tei+xml","text/xml")
%output:method('xml')
%output:omit-xml-declaration("no")
function dts:anyDocumentXML($id as xs:string*, $ref as xs:string*, $start , $end) {
console:log('got to any xml'),
dts:docs($id, $ref, $start, $end, 'application/tei+xml')
};


declare
%rest:GET
%rest:path("/BetMas/api/dts/document")
%rest:query-param("id", "{$id}",  "")
%rest:query-param("ref", "{$ref}", "")
%rest:query-param("start", "{$start}", "")
%rest:query-param("end", "{$end}", "")
%rest:consumes("application/rdf+xml")
%rest:produces("application/rdf+xml")
%output:method('xml')
%output:omit-xml-declaration("no")
function dts:anyDocumentRDF($id as xs:string*, $ref as xs:string*, $start , $end) {
console:log('got to rdf'),
dts:docs($id, $ref, $start, $end, 'application/rdf+xml')
};

declare
%rest:GET
%rest:path("/BetMas/api/dts/document")
%rest:query-param("id", "{$id}",  "")
%rest:query-param("ref", "{$ref}", "")
%rest:query-param("start", "{$start}", "")
%rest:query-param("end", "{$end}", "")
%rest:consumes("application/pdf")
%rest:produces("application/pdf")
%output:method('xml')
%output:omit-xml-declaration("no")
function dts:anyDocumentPDF($id as xs:string*, $ref as xs:string*, $start , $end) {
console:log('got to pdf'),
dts:docs($id, $ref, $start, $end, 'application/pdf')
};


declare
%rest:GET
%rest:path("/BetMas/api/dts/document")
%rest:query-param("id", "{$id}",  "")
%rest:query-param("ref", "{$ref}", "")
%rest:query-param("start", "{$start}", "")
%rest:query-param("end", "{$end}", "")
%rest:consumes("text/plain")
%rest:produces("text/plain")
function dts:anyDocumentTEXT($id as xs:string*, $ref as xs:string*, $start , $end) {
console:log('got to plain text'),
dts:docs($id, $ref, $start, $end, 'text/plain')
};


declare
%rest:GET
%rest:path("/BetMas/api/dts/document")
%rest:query-param("id", "{$id}",  "")
%rest:query-param("ref", "{$ref}", "")
%rest:query-param("start", "{$start}", "")
%rest:query-param("end", "{$end}", "")
%rest:consumes("text/html")
%rest:produces("text/html")
function dts:anyDocumentHTML($id as xs:string*, $ref as xs:string*, $start , $end) {
console:log('got to html'),
dts:docs($id, $ref, $start, $end, 'text/html')
};:)

declare
%rest:GET
%rest:path("/BetMas/api/dts/document")
%rest:query-param("id", "{$id}",  "")
%rest:query-param("ref", "{$ref}", "")
%rest:query-param("start", "{$start}", "")
%rest:query-param("end", "{$end}", "")
function dts:anyDocumentDEFAULT($id as xs:string*, $ref as xs:string*, $start , $end) {
(:console:log('got to default'),:)
dts:docs($id, $ref, $start, $end, 'application/tei+xml')
};

(:declare
%rest:GET
%rest:path("/BetMas/api/dts/document")
%rest:query-param("id", "{$id}",  "")
%rest:query-param("ref", "{$ref}", "")
%rest:query-param("start", "{$start}", "")
%rest:query-param("end", "{$end}", "")
%rest:produces("application/json", "application/ecmascript", "application/javascript" )
function dts:anyDocumentNotAccepted($id as xs:string*, $ref as xs:string*, $start , $end) {
<rest:response>
  <http:response status="406">
    <http:header
                    name="Content-Type"
                    value="application/tei+xml ; application/xml ; application/rdf+xml ; application/pdf ; text/plain ; text/html ; text/xml "/>
  </http:response>
</rest:response>
};
:)

declare function dts:nodes($text, $path){
(:let $t:= console:log($text):)
(:let $t2 := console:log($path):)
for $selector in util:eval($path)
                        return 
                        if ($selector/name() = 'pb')
                                          then dts:TranscriptionPassageNodes($text, $selector/@n, '')
                        else if ($selector/name()='lb') 
                                          then dts:TranscriptionPassageNodesLB($text, $selector/@n)
                       else $selector
                       };
declare function dts:docs($id as xs:string*, $ref as xs:string*, $start, $end, $Content-Type){
(:redirect if id not specified:)
if ($id = '') then dts:redirectToCollections() 
else
 let $parsedURN := dts:parseDTS($id)
(: let $t := console:log($parsedURN):)
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
else if (starts-with($ref, 'NAR')) then ()
else if ($start != '') then <http:header
                    name="Link"
                    value="&lt;/api/dts/document?id={$id}&amp;ref={number($start) - 1}&gt; ; rel='prev', &lt;/api/dts/document/?id={$id}&amp;ref={number($end) + 1}&gt; ; rel='next'"/>

else <http:header
                    name="Link"
                    value="&lt;/api/dts/document?id={$id}&amp;ref={number($ref) - 1}&gt; ; rel='prev', &lt;/api/dts/document/?id={$id}&amp;ref={number($ref) + 1}&gt; ; rel='next'"/>
                    
 return
(:we need a restxq redirect in case the id contains already the passage. 
it should redirect the urn with passage to one which splits it and 
redirect it to a parametrized query:)
 (:if(count($parsedURN//s:group[@nr=8]//text()) ge 1) then 
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
 else:)
 let $thisid := $parsedURN//s:group[@nr=3]/text()
 let $edition := $parsedURN//s:group[@nr=4]
 let $file := $config:collection-root/id($thisid)
 let $text := if($edition/node()) then dts:pickDivText($file, $edition)  else $file//t:div[@type='edition']
 let $doc := 
(: in case there is passage, then look for that place:)
  if ($edition/node() and $ref = '' and $start='') then 
  let $t4 := console:log('edition')
  return
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
                    let $path := dts:selectorRef(1, $text,$ref,'no')
                    let $t := console:log($path)
                        let $entirepart := dts:nodes($text, $path)
(:                        let $t2:=console:log($entirepart):)
                        return
                        <TEI xmlns="http://www.tei-c.org/ns/1.0" >
                            <dts:fragment xmlns:dts="https://w3id.org/dts/api#">
                                {$entirepart}
                            </dts:fragment>
                       </TEI>
                    
         )
(:         if there are start and end, look for a range:)
else if($start != '' or $end != '') then (

 let $l := count(tokenize($start, '\.'))
 let $possibleRefs := dts:listRefs($l, $text)
 let $startP := index-of($possibleRefs,$start)
 let $endP := index-of($possibleRefs,$end)
 let $selectors := for $r in $startP to $endP 
   return 
   dts:selectorRef($l, $text,$possibleRefs[$r], 'no')
 let $nodes := for $selector in $selectors return dts:nodes($text, $selector)
return 
<TEI xmlns="http://www.tei-c.org/ns/1.0">
    <dts:fragment xmlns:dts="https://w3id.org/dts/api#">
        {$nodes}
    </dts:fragment>
</TEI>
)
                       
else $file 

                       
 return
 
  switch($Content-Type) 
  
  case 'application/rdf+xml' return dts:redirectToRDF($thisid)
  case 'application/pdf' return dts:redirectToPDF($thisid)
  case 'text/html' return  dts:redirectToHTML($thisid, $ref, $start)
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


declare function dts:passageIIIFrange($text, $manifest, $type, $id){
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
                    let $w := $config:collection-rootMS/id($m)
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
 
 declare function dts:citeDepth($text){
 if($text/ancestor::t:TEI/@type='mss' and not($text/ancestor::t:TEI//t:objectDesc/@form ='Inscription')) then 

    (if($text/t:div[@subtype !='folio']) then 
(:    determine the maximum possible levels of descendence for div, pb and cb
https://stackoverflow.com/questions/5694759/how-do-you-calculate-the-number-of-levels-of-descendants-of-a-nokogiri-node
:)
let $nodes := $text/descendant::node()[name()='div' or name()='l' or name()='lb' or name()='pb' or name()='cb']
return
    max(for $leaf in $nodes,
        $depth in count($leaf/ancestor::node()[name()='div' or name()='l' or name()='lb' or name()='pb' or name()='cb'])
      return
        $depth
    ) else 3) 
                                else 
                                       ( let $counts := for $div in ($text//t:div[@type='textpart'], $text//t:l, $text//t:lb) 
                                        return count($div/ancestor::t:div)
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
declare function dts:parseRef($ref){
(:dts:ref can be constructed as a series of dotted sub references
each level is separated by a dot, each level can be the value of either 
    - a @n
    - a @xml:id
    - a @corresp
    - a concatenation of @subtype and @n
    
   the total number of position in ref cannot be greater than citeDepth
   and must be coherent with it.

e.g.
1 (div[@type='folio']/@n)
1r (pb/@n)
1va ((pb/@n),(cb/@n))
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
               '(NAR[0-9A-Za-z]+|((\d+[r|v])([a-z]?))|([A-Za-z]+)?([0-9]+))(\.)?')
let $refs := for $m at $p in $parseRef//s:match 
                    let $t := $m/s:group[@nr=1]//text()
                    return
                     if(matches($m, '\d+[r|v][a-z]?')) 
(:           the normal reference to the folio, is to be found split in pb and cb          :)
                                then <ref type='folio' l="{$p}">
                                        <part type="pb">{$m//s:group[@nr=3]/text()}</part>
                                        <part type="cb">{$m//s:group[@nr=4]/text()}</part>
                                        </ref>
                     else if(matches($m, 'NAR[0-9A-Za-z]+')) 
                                then <ref type='nar' l="{$p}">{$t}</ref>
                     else if(matches($m, '([A-Za-z]+)([0-9]+)')) 
(:                     this is an ambiguous type, because it may refer to 
a subtype and a n as well as referring simply an xmlid :)
                                then <ref type='subtypeNorXMLid'  l="{$p}">
                                           <option type="subtype">
                                           <part type="subtype">{$m//s:group[@nr=5]/text()}</part>
                                           <part type="n">{$m//s:group[@nr=6]/text()}</part>
                                           </option>
                                           <option type="xmlid">{$t}</option>
                                        </ref>
                     else if(matches($m, '([A-Za-z]+)')) 
                                then <ref type='subtype'  l="{$p}">{$t}</ref>
                     else (<ref type='n' l="{$p}">{$t}</ref>)
return <refs>{$refs}</refs>
 };
               
(:~  called by dts:pas to format and select the references :)
declare function dts:refname($n){
(:has to recurs each level of ancestor of the node which 
   has a valid position in the text structure:)
let $refname:=  dts:rn($n)
let $this := normalize-space($refname)
let $ancestors := for $a in $n/ancestor::t:div[@xml:id or @n or @corresp][ancestor::t:div[@type='edition']]
return dts:rn($a)
let $all := ($ancestors , $this)
return string-join($all,'.')
};
declare function dts:rn($n){
 if($n/@n) then string($n/@n)
    else if ($n/name()='cb') then 
         (string($n/preceding-sibling::t:pb[@n][1]/@n)||string($n/@n)) 
    else if($n/@xml:id) then string($n/@xml:id)
    else if($n/@subtype) then string($n/@subtype)
    else 'tei:' ||$n/name() ||'['|| $n/position() || ']'
    };
(:~  called by dts:pas to select the title of a passage:)
declare function dts:reftitle($n){
if($n/@corresp) then 
             (if(starts-with($n/@corresp, '#')) 
                 then <title>{normalize-space(titles:printSubtitle($n, substring-after($n/@corresp, '#')))}</title>
              else if(starts-with($n/@corresp, 'LIT')) then <title>{normalize-space(titles:printTitleID($n/@corresp))}</title>
              else if(starts-with($n/@corresp, 'NAR')) then <title>{normalize-space(titles:printTitleID($n/@corresp))}</title>
              else <title>{string($n/@corresp)}</title>)
 else if ($n/t:label) then <title>{string:tei2string($n/t:label)}</title>
 else ()
              };
              
(:~  called by dts:pas to select the type name:)
declare function dts:typename($n, $fallback){
<type>{if(string($n/@subtype)) then string($n/@subtype)
else if($n/name() = 'l') then 'verse'
else if($n/name() = 'lb') then 'line'
else if($n/name() = 'pb') then 'page'
else if($n/name() = 'cb') then 'column'
else $fallback}</type>};

(:~ fetches all available computed or declared witnesses and
flattens this distinction building one list of 
computed and declared witnesses, 
as well as the eventual nesting of witnesses for each edition:)
declare function dts:wits($mydoc, $BMid){
let $computedWitnesses := 
     if($mydoc/@type= 'mss') then ()
     else if($mydoc/@type= 'nar') then (
              for $witness in $config:collection-rootMS//t:*[starts-with(@corresp, $BMid)]
               let $root := root($witness)/t:TEI/@xml:id
                group by $groupkey := $root
                return string($groupkey))
    else (for $witness in $config:collection-rootMS//t:title[starts-with(@ref, $BMid)]
                    let $root := root($witness)/t:TEI/@xml:id
                    group by $groupkey := $root
                    return string($groupkey))
let $declaredWitnesses := if($mydoc/@type= 'mss') then () else 
                            for $witness in $mydoc//t:witness/@corresp return string($witness)
(: flattens the distinction between computed and declared witnesses, as well as the eventual nesting of witnesses for each edition:)
return ($computedWitnesses, $declaredWitnesses)
};

(:~  given a passage node calls the functions to add to it relevant information:)
declare function dts:pas($n, $fallback, $type, $manifest, $BMid){
<p>{dts:refname($n)}{dts:typename($n, $fallback)}{dts:reftitle($n)}{dts:passageIIIFrange($n, $manifest, $type, $BMid)}</p>
};

(:~  given a passage node calls the functions to add to it relevant information,
starting from a given refname, not building it from a node:)
declare function dts:pasCombo($n, $reftext, $type, $manifest, $BMid){
<p>{$n}{dts:passageIIIFrange($reftext, $manifest, $type, $BMid)}</p>
};

(:~  calls for all relevant nodes in a selection the builder for the passage node:)
declare function dts:pasS($selector, $fallback, $type, $manifest, $BMid){
for $n in $selector
 return dts:pas($n, $fallback, $type, $manifest, $BMid)
};

declare function dts:pasLev($level, $text, $fallback, $type, $manifest, $BMid){
let $levs := string-join((for $i in 1 to xs:integer($level) 
                     return "/(t:div|t:cb|t:pb|t:lb|t:l)/(t:ab|.)"))
let $path := '$text' || $levs
(:let $t:= console:log($path):)
  return  dts:pasS(util:eval($path), $fallback, $type, $manifest, $BMid)
};

declare function dts:listRefs($level, $text){
let $levs := string-join((for $i in 1 to xs:integer($level) 
                     return "/(t:div|t:cb|t:pb|t:lb|t:l)/(t:ab|.)"))
let $path := '$text' || $levs 
(:let $t := console:log($path):)
 for $ref in util:eval($path)
 return
 dts:refname($ref)  
};

declare function dts:selectorRef($level, $text,$ref, $children){
(:the children parameter is there because the selection is the same, but if selecting for references, then we want the children nodes, if selecting for nodes, we want the nodes and stop there:)
let $refs := dts:parseRef($ref)
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
                                case 'folio' return "/t:div[t:pb[@n='"||
                                                                   $r/*:part[@type='pb']/text()||"']"||
                                                                   (if($r/*:part[@type='cb']/text()) 
                                                                   then ("[following-sibling::t:cb[@n='"||
                                                                   $r/*:part[@type='cb']/text()||"']]") 
                                                                   else ())||"]"
                               case 'subtypeNorXMLid' return "/(t:div[@subtype='"||
                                                                   $r/*:option[@type='subtype']/*:part[@type='subtype']/text()||"']"||
                                                                   (if($r/*:option[@type='subtype']/*:part[@type='n']/text()) 
                                                                   then ("[@n='"||
                                                                   $r/*:option[@type='subtype']/*:part[@type='n']/text()||"']") 
                                                                   else ()) || " | " ||"t:div[@xml:id='"||
                                                                   $r/*:option[@type='xmlid']/text()||"']"|| ")"
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
declare function dts:pasRef($level, $text, $ref, $fallback, $type, $manifest, $BMid){
let $path := dts:selectorRef($level, $text, $ref, 'yes')
(: let $t4 := console:log($path):)
     for $n in util:eval($path)  
     return dts:pas($n, $fallback, $type, $manifest, $BMid)
};

declare function dts:ctype ($mydoc, $text, $level, $cdepth){
 if($mydoc/@type='mss' 
                      and not($text/ancestor::t:TEI//t:objectDesc/@form ='Inscription')) 
                    then  (
                    if($cdepth gt 3) 
                                then  'textpart' 
                   else if(($level = '') and $cdepth=3) 
                                then 
                                        if($text/t:div[@subtype]) 
                                        then distinct-values($text/t:div/@subtype) 
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

(:citation tree and level
level 1 is div[@type='edition']
level 2 is a div[@type='edition']/(t:div|t:lb|t:l|t:pb|t:cb) 
level 3 is a div[@type='edition']/(t:div|t:lb|t:l|t:pb|t:cb)/(t:div|t:lb|t:l|t:pb|t:cb)

requesting a level will return the options for that level 

e.g. 

request for EMIP01859 or EMIP01859&level=1
returns the months, which are the first divs children of edition
  EMIP01859.1, EMIP01859.2
  because it looks for div[@type='edition']/(t:div|t:lb|t:l|t:pb|t:cb)
  
request for EMIP01859&level=2 
returns the days in each month
   EMIP01859.1.1, EMIP01859.1.2, EMIP01859.1.3, etc.
   because it looks for div[@type='edition']/(t:div|t:lb|t:l|t:pb|t:cb)/(t:div|t:lb|t:l|t:pb|t:cb)
   
request for EMIP01859&level=3 
returns the commemorations in each day
   EMIP01859.1.1.1, EMIP01859.1.1.2, EMIP01859.1.1.3, etc.
   because it looks for div[@type='edition']/(t:div|t:lb|t:l|t:pb|t:cb)/(t:div|t:lb|t:l|t:pb|t:cb)/(t:div|t:lb|t:l|t:pb|t:cb)   
      
request for EMIP01859&level=4 
returns the subdivisions of a commemoration
   EMIP01859.1.1.1.1, EMIP01859.1.1.1.2, EMIP01859.1.1.1.3, etc.
 because it looks for div[@type='edition']/(t:div|t:lb|t:l|t:pb|t:cb)/(t:div|t:lb|t:l|t:pb|t:cb)/(t:div|t:lb|t:l|t:pb|t:cb)/(t:div|t:lb|t:l|t:pb|t:cb)   
  
$ref will limit to a specific reference, and although @n is preferred, also other reference formats will be matched

request for EMIP01859&ref=1 or EMIP01859&level=1&ref=1 or EMIP01859&level&ref=month1
returns as a resource the months, 
which are the first divs children of edition and match that $ref
"list of passage identifiers that are part of the textual Resource identified", i.e. EMIP01859.1, 
  because it looks for div[@type='edition']/(t:div|t:lb|t:l|t:pb|t:cb)[@n=1]/(t:div|t:lb|t:l|t:pb|t:cb)


$ref=1.3 or e.g. EMIP01859&ref=month1.day3
because it looks for div[@type='edition']/(t:div|t:lb|t:l|t:pb|t:cb)[@n=month1]/(t:div|t:lb|t:l|t:pb|t:cb)[@n=day1]/(t:div|t:lb|t:l|t:pb|t:cb)
and returns level 4 references which are passage identifiers that are part of the textual Resource identified month1.day3,
so. e.g. commemorations identified by month1.day1.NAR0019SBarkisos

$ref=1.1.1 or month1.day1.NAR0019SBarkisos
willl not return anything, because there is no level 5. If there will be some passage identifiers part of it it will return them
:)

declare function dts:startend($level, $text, $start, $end, $fallback, $type, $manifest, $BMid){
 let $l := if ($level != '') then $level else count(tokenize($start, '\.'))
 let $possibleRefs := dts:listRefs($l, $text)
(: dts:listRefs returns a list of the most standardizable refs. 
this means that, while an alternative ref will work singularly, for a range the most canonical ones will have to be used
start=month1.day4&end=month1.day6
will not work although in principle equivalent to
start=1.4&end=1.6
which will return the correct set of passage references contained in this range
:)
 let $startP := index-of($possibleRefs,$start)
 let $endP := index-of($possibleRefs,$end)
 for $r in $startP to $endP 
   return dts:pasRef($l, $text, $possibleRefs[$r], $fallback, $type, $manifest, $BMid)
                };

(:~ dts/navigation https://github.com/distributed-text-services/specifications/blob/master/Navigation-Endpoint.md:)
declare
%rest:GET
%rest:path("/BetMas/api/dts/navigation")
%rest:query-param("id", "{$id}",  "")
%rest:query-param("ref", "{$ref}", "")
%rest:query-param("level", "{$level}", "")
%rest:query-param("start", "{$start}", "")
%rest:query-param("end", "{$end}", "")
%rest:query-param("page", "{$page}", "")
%rest:query-param("groupBy", "{$groupBy}", "")
%rest:query-param("max", "{$max}", "")
%rest:query-param("version", "{$version}", "")
%output:method("json")
function dts:Cit($id as xs:string*, $ref as xs:string*, $level as xs:string*, $start as xs:string*, $end as xs:string*, $groupBy as xs:string*, $page as xs:string*, $max as xs:string*, $version as xs:string*) {
if($id = '') then (<rest:response>
  <http:response status="302">
    <http:header name="location" value="/api/dts/collections?id=https://betamasaheft.eu"/>
  </http:response>
</rest:response>) else
let $parsedURN := dts:parseDTS($id)
let $BMid := $parsedURN//s:group[@nr=3]/text()
let $mydoc := $config:collection-root/id($BMid)
let $edition := $parsedURN//s:group[@nr=4]
let $text := if($edition/node()) then dts:pickDivText($mydoc, $edition)  else $mydoc//t:div[@type='edition']
                (: there may be more edition and translations how are these fetched?  
                LIT1709Kebran, LIT1758Lefafa multiple editions 
                LIT2170Peripl multiple pb and divs + images
                
                there needs to be evidence of multiple editions and a possibility to 
                switch based on @xml:id
                with fallback on div[@type='edition']
                multiple values for navigation api provided in Collection 
                
                LIT4915PhysA_ED_ed1.1.1.1
                LIT4915PhysA_ED_ed2.1.1
                LIT2170Peripl_ED_
                LIT2170Peripl_TR_
                :)
let $textType := $mydoc//t:objectDesc/@form
let $manifest := $mydoc//t:idno/@facs
let $allwits := dts:wits($mydoc, $BMid) 
let $witnesses := for $witness in distinct-values($allwits)
(:filters out the witnesses which do not have images available:)
                            return if(starts-with($witness, 'http')) then $witness else let $mss := $config:collection-rootMS/id($witness) return if ($mss//t:idno/@facs) then $witness else ()
let $cdepth := dts:citeDepth($text)
let $passage := 
if ($mydoc/@type='mss' and not($textType='Inscription')) then (
   (:manuscripts:)

(:  THERE IS A REF:)   
    if($ref != '') then 
             let $l := if ($level='') then 1 else $level
           return
          dts:pasRef($l, $text, $ref, 'unit', 'mss', $manifest, $BMid)
(:$ref can be a NAR, but how does one know that this is a possibility within this text?:)

(:start and end:)
     else if($start != '') then
             dts:startend($level, $text, $start, $end, 'part', 'mss', $manifest, $BMid)
   (: no ref specified, list all main divs, assuming by the guidelines they are folios:)
         else if($ref='' and $level = '' and $start ='' and $end = ''and $groupBy = '' and $max = '') 
                then dts:pasS($text/t:div[@n], 'folio', 'mss', $manifest, $BMid)
  (: if the level is not empty, than it has been specified to be either the second or third level, pages and columns                  :)
         else if (($level != '') and ($cdepth gt 3))  then
  (:  the citation depth is higer than 3:)
(:  let $t := console:log($level) return:)
                  dts:pasLev($level, $text, 'unit', 'mss', $manifest, $BMid )
        else if(($level != '') and ($cdepth = 3)) then 
                  (if ($level = '2') 
  (: the pages of folios have been requested:)
                    then dts:pasS($text//t:pb[@n], 'page', 'mss', $manifest, $BMid)
                    else if ($level = '3')
  (: the columns of a pages have been requested:)
                     then dts:pasS($text//t:cb[@n], 'column', 'mss', $manifest, $BMid)
  (:  in theory there is no such case which will not be matched by cdepth gt 3...   :)
                     else()  )         
(:    no other option taken into consideration:)
    else ()
                        ) else 
(:works and inscriptions. 
                        textual units have different structures 
                        some are encoded with a basic nested divs structure, some instaed, especially bible texts use l, while inscriptions have lb :)
                                if($ref='' and $level = '' and $start ='' and $end = ''and $groupBy = '' and $max = '') 
(:   if no  parameter is specified, go through the child elements of div type edition, whatever they are:)
                                then  dts:pasS($text/(t:ab|.)/t:*, 'unit', 'work', $witnesses, $BMid)
(:   if a ref is specified show that navigation point:)
else if($ref != '' and $start = '')  
(:e.g. LIT1546Genesi&ref=2.3 :)
        then dts:pasRef(1, $text, $ref, 'unit', 'work', $witnesses, $BMid)
(:   if a level is specified that use that information, and check for ref
e.g. LIT1546Genesi&level=2
:) 
 else if($level != '' and $start = '') 
                                then 
(:  e.g. LIT1546Genesi&level=2&ref=4:)
                                if($ref != '') then dts:pasRef($level, $text, $ref, 'unit', 'work', $witnesses, $BMid)
(:  e.g. LIT1546Genesi&level=2 (max level is value of citeDepth!):)                               
                               else dts:pasLev($level, $text, 'unit', 'work', $witnesses, $BMid )
 else if($start != '' and $end != '') 
(: needs to make a sequence of possible 
refs at the given level and limit it by the positions in $start and $end
LIT1546Genesi&start=3&end=4 :)
               then 
              dts:startend($level, $text, $start, $end, 'texpart', 'work', $witnesses, $BMid)
else ()
                             
(:                             the following step should take the list of results and format it using the chunksize and max parameters:)
let $CS := number($groupBy)
let $M := number($max)
let $ctype := dts:ctype($mydoc,$text, $level, $cdepth)
let $chunkedpassage := if(string($groupBy) !='') 
                                                then       
                                               (
                                                        for $p in $passage/text() 
                                                        let $l1 := substring-before($p,'.')
                                                        let $l2 := number(substring-after($p, '.')) -1
                                                        let $L := $l2 - ($l2 mod $CS)
                                                        group by $g:= $L 
                                                        order by $g
                                                        let $rangeStart := if($g= 0) then 1 else $g +1
                                                        let $ceiling:= $g+$CS
                                                        let $sequenceN := for $p in $passage return  number(substring-after($p, '.'))
                                                        let $end := max($sequenceN)
                                                        let $rangeEnd := if($ceiling gt $end) then $end else $ceiling
                                                        let $chunck  := map {'dts:start' :  $passage[$rangeStart]/text()[1], 'dts:end' : $passage[$rangeEnd]/text()[1]}
                                                       return 
                                                                    $chunck)
                                                else for $p in $passage 
                                                            let $refonly := map {"dts:ref" : $p/text()[1]}
                                                         let $refandtype := if((count($p/*:type) eq 1) and ($p/*:type/text() !=$ctype)) then map:put($refonly, 'dts:citeType', $p/*:type/text()) else $refonly
                                                         let $refTypeTitle := if(count($p/*:title) eq 1 or count($p/*:iiifRange) ge 1) 
                                                                                        then 
                                                                                                    let $dublincore := map{}
                                                                                                    let $parttitle := if($p/*:title) then map:put($dublincore, 'dc:title', $p/*:title/text()) else $dublincore
                                                                                                    let $iiifreference := for $i in $p/*:iiifRange 
                                                                                                                                    return map {"@id": $i/text(),  
                                                                                                                                                       "@type": (if(contains($i/text(), 'canvas'))  
                                                                                                                                                                                                 then "sc:Canvas" 
                                                                                                                                                                                                 else  "sc:Range")}                                                                                     
                                                                                                    let $parttitlewithmanifest := if(count($iiifreference) ge 1) then map:put($parttitle, 'dc:source', $iiifreference) else $parttitle
                                                                                                    return map:put($refandtype, 'dts:dublincore', $parttitlewithmanifest) 
                                                                                         else   $refandtype
                                                         return 
                                                         $refTypeTitle
                                                 

(: regardless of passages sequence type (ranges as maps or items as strings) the following steps limits the number of results                                                :)
let $maximized :=if(string($max) !='') then for $p in subsequence($chunkedpassage, 1, $M) return $p else $chunkedpassage
let $array := if(count($maximized)=1) then [$maximized] else $maximized
 let $l := if($level = '') then 1 else number($level)
let $versions := if($version='yes') then  dts:fileingitCommits($id, $BMid, 'navigation') else ('version set to '||$version||', no version links retrieved from GitHub.')

return
if(count($text//text()) lt 1) then 
($config:response404JsonLD, 
map {
  "@context": "http://www.w3.org/ns/hydra/context.jsonld",
  "@type": "Status",
  "statusCode": 404,
  "title": "Not Found",
  "description": "Sorry, there is no text here to navigate."
}) 
else
 ($config:response200JsonLD,
 log:add-log-message('/api/dts/cit/' || $id, sm:id()//sm:real/sm:username/string() , 'dts'),
        map {
    "@context": map {
        "@vocab": "https://www.w3.org/ns/hydra/core#",
        "dc": "http://purl.org/dc/terms/",
        "dts": "https://w3id.org/dts/api#"
    },
    "@base": "/dts/api/navigation",
    "@id": ('/api/dts/navigation?id='|| $id),
    "dts:citeDepth" : $cdepth,
    "dts:level" : $l,
    "dts:citeType": $ctype,
    "dc:hasVersion" : $versions,
    "dts:passage" : ('dts/api/document?id=' || $id||'{&amp;ref}{&amp;start}{&amp;end}'),
    "member": $array
})
         
};

declare function dts:pickDivText($doc, $parsedID){
(:let $t := console:log($parsedID):)
let $type := if($parsedID/s:group[@nr=5] = 'ED') then 'edition' else 'translation'
let $xmlid := if($parsedID/s:group[@nr=6]) then $parsedID/s:group[@nr=6]/text()[1] else ''
     return
          if($xmlid = '') then $doc//t:div[@type=$type][not(@xml:id)]
          else $doc//t:div[@type=$type][@xml:id=$xmlid]
};

(:~ given the URN in the id parameter and the plain Beta Masahaeft id if any, produces the list of members of the collection filtering only the entities which do have a div[@type='edition'] :)
declare function dts:CollMember($id, $edition, $bmID, $page, $nav, $version){
let $doc := $config:collection-root//id($bmID) 
let $eds := if($edition/node()) then
                                dts:pickDivText($doc, $edition)
                    else ($doc//t:div[@type='edition'], $doc//t:div[@type='translation'])
return
if(count($doc) eq 1) then (
$config:response200JsonLD,
(:let $t := console:log($id):)
let $memberInfo := dts:member($bmID,$edition,$eds, $version)
let $addcontext := map:put($memberInfo, "@context", $dts:context)
let $addnav := if($nav = 'parent') then 
let $parent :=if($doc/@type='mss') then 
        map{
             "@id" : "https://betamasaheft.eu/transcriptions",
             "title" : "Beta maṣāḥǝft Manuscripts",
             "description": "Collection of Ethiopic Manuscript trasncriptions",
             "@type" : "Collection",
             "totalItems" : count(collection($config:data-rootMS)//t:div[@type='edition'][descendant::t:ab[text()]])
        }
       else if($doc/@type='nar') then 
        map{
             "@id" : "https://betamasaheft.eu/narrativeunits",
             "title" : "Beta maṣāḥǝft Manuscripts",
             "description": "Collection of narrative units of the Ethiopic tradition",
             "@type" : "Collection",
             "totalItems" : count(collection($config:data-rootN)//t:div[@type='edition'][descendant::t:ab[text()]])
        }
        else map {
             "@id" : "https://betamasaheft.eu/textualunits",
             "title" : "Beta maṣāḥǝft Textual Units",
             "description": "Collection of literary textual units of the Ethiopic tradition",
             "@type" : "Collection",
             "totalItems" : count($config:collection-rootW//t:div[@type='edition'][descendant::t:ab[text()]])
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
: entry point or one of the three main collections, manuscripts transcriptions, textual units or narrativa units in which case it will call dts:mainColl :)
declare function dts:Coll($id, $page, $nav, $version){
let $availableCollectionIDs := ('https://betamasaheft.eu', 'https://betamasaheft.eu/textualunits', 'https://betamasaheft.eu/narrativeunits', 'https://betamasaheft.eu/transcriptions')
let $ms := $config:collection-rootMS//t:div[@type='edition'][descendant::t:ab[text()]]
let $w := $config:collection-rootW//t:div[@type='edition'][descendant::t:ab[text()]]
let $n := $config:collection-rootN
  let $countMS := count($ms)
  let $countW := count($w)
  let $countN := count($n)
    return
       (
 if($id = $availableCollectionIDs) then (
 $config:response200JsonLD,
 switch($id) 
 case 'https://betamasaheft.eu/textualunits' return
dts:mainColl($id, $countW, $w, $page, $nav)
 case 'https://betamasaheft.eu/narrativeunits' return
dts:mainColl($id, $countN, $n, $page, $nav)
case 'https://betamasaheft.eu/transcriptions' return
dts:mainColl($id, $countMS, $ms, $page, $nav)
default return
map {
    "@context": $dts:context,
    "@id": $id,
    "@type": "Collection",
    "totalItems": 3,
    "title": "Beta maṣāḥǝft",
    "description" : "The project Beta maṣāḥǝft: Manuscripts of Ethiopia and Eritrea (Schriftkultur des christlichen Äthiopiens: eine multimediale Forschungsumgebung) is a long-term project funded within the framework of the Academies' Programme (coordinated by the Union of the German Academies of Sciences and Humanities) under survey of the Akademie der Wissenschaften in Hamburg. The funding will be provided for 25 years, from 2016–2040. The project is hosted by the Hiob Ludolf Centre for Ethiopian Studies at the University of Hamburg. It aims at creating a virtual research environment that shall manage complex data related to predominantly Christian manuscript tradition of the Ethiopian and Eritrean Highlands.",
    "dts:dublincore": map {
        "dc:publisher": ["Akademie der Wissenschaften in Hamburg", "Hiob-Ludolf-Zentrum für Äthiopistik"],
        "dc:description": [
            map {
                "@lang": "en",
                "@value": "The project Beta maṣāḥǝft: Manuscripts of Ethiopia and Eritrea (Schriftkultur des christlichen Äthiopiens: eine multimediale Forschungsumgebung) is a long-term project funded within the framework of the Academies' Programme (coordinated by the Union of the German Academies of Sciences and Humanities) under survey of the Akademie der Wissenschaften in Hamburg. The funding will be provided for 25 years, from 2016–2040. The project is hosted by the Hiob Ludolf Centre for Ethiopian Studies at the University of Hamburg. It aims at creating a virtual research environment that shall manage complex data related to predominantly Christian manuscript tradition of the Ethiopian and Eritrean Highlands."
            }
        ]
    },
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
declare function dts:mainColl($collURN, $count, $items, $page, $nav){  

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
                                      dts:member($collURN, $edition, $document, 'no')
    return
    map {
    "@context": $dts:context,
    "@id": $collURN,
    "@type": "Collection",
    "totalItems": $count,
    "title": $title,
    "dts:dublincore": map {
        "dc:publisher": ["Akademie der Wissenschaften in Hamburg", "Hiob-Ludolf-Zentrum für Äthiopistik"]
    },
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

declare function dts:nestedDivs($edition as node()*){
for $node in ($edition/t:div[@type='textpart'], $edition/t:ab/t:l, $edition/t:ab/t:lb)
 let $typ := if($node/@subtype) then string($node/@subtype) else if ($node/name() = 'l') then 'verse 'else if ($node/name() = 'lb') then 'line' else 'textpart'
 group by $T := $typ
let $citType :=  map {
                 "dts:citeType": $T
                 }
let $citStr : =if($node/child::t:div) then let $subType := dts:nestedDivs($node/child::t:div) return map:put($citType, 'dts:citeStructure', $subType)
else if($node/t:ab/t:l) then let $subType := dts:nestedDivs($node) return map:put($citType, 'dts:citeStructure', $subType)
else if($node/t:ab/t:lb) then let $subType := dts:nestedDivs($node) return map:put($citType, 'dts:citeStructure', $subType)
else $citType
    return
    $citStr
    
};

declare function dts:manifest($doc, $id){
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
declare function dts:member($collURN,$edition,$document, $vers){
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
dts:membercontent($document, $edition, $vers)
(:     if there are more editions, then this has to be treated as a collection resource, and each
edition or translation gets its own identifier:)
else ( 
(:any is fine, they all come from a selection, this is just to have the ID:)
let $doc := root($document[1]) 
let $id := string($doc//t:TEI/@xml:id)
let $title := titles:printTitleMainID($id)
let $description := if($doc//t:TEI/@type= 'nar') 
                                 then 'The narrative unit '||$title||
                                 ' in Beta maṣāḥǝft ' 
                                 else if($doc//t:TEI/@type= 'mss') 
                                 then 'The transcription of manuscript '||
                                 $title||' in Beta maṣāḥǝft ' 
                                 else 'The abstract textual unit '||$title||
                                 ' in Beta maṣāḥǝft. '  || 
                                 normalize-space(string-join(string:tei2string($doc//t:abstract), ''))
let $resourceURN := 'https://betamasaheft.eu/' || $id
let $members := for $d in $document 
                                        let $divuri := ($resourceURN || '_' ||upper-case(substring(string($d/@type),1,2))|| '_' ||string($d/@xml:id))
                                        return dts:editioncontent($divuri,string($d/@type),string($d/@xml:id),$d, $vers)
    return
map{"@id" : $resourceURN,
             "title" : "Editions and Translations of " || $title,
             "description": $description,
             "@type" : "Collection",
             "totalItems" : count($document),
              "dts:totalParents": 1,
             "dts:totalChildren": count($document),
             "member" :   $members    
             }         
          
       )
};
declare function dts:computedWit($doc, $id){
if($doc//t:TEI/@type= 'mss') then ()
                              else if($doc//t:TEI/@type= 'nar') then (
                              for $witness in $config:collection-rootMS//t:*[@corresp = $id]
                            let $root := root($witness)/t:TEI/@xml:id
                                group by $groupkey := $root
                            return string($groupkey))
                              else 
                            (for $witness in $config:collection-rootMS//t:title[@ref = $id]
                            let $root := root($witness)/t:TEI/@xml:id
                                group by $groupkey := $root
                            return string($groupkey))
                            };
                            
declare function dts:distinctW($witnesses){
for $w in distinct-values($witnesses) return 
                            map { "fabio:isManifestationOf" : if(starts-with($w, 'http')) then $w else ($config:appUrl || "/" || $w),
                                        "@id" : if(starts-with($w, 'http')) then $w else ("https://betamasaheft.eu/" || $w),
                                        "@type" : "lawd:AssembledWork",
                                        "dc:title": titles:printTitleMainID($w)}
                                        };

declare function dts:membercontent($document, $edition, $vers){
let $doc := root($document)
let $id := string($doc//t:TEI/@xml:id)
let $title := titles:printTitleMainID($id)
let $description := dts:docDesc($doc, $title)
let $dc := dts:dublinCore($id)
let $computed := dts:computedWit($doc, $id)
let $declared := if($doc//t:TEI/@type= 'mss') then () else 
                            for $witness in $doc//t:witness/@corresp return string($witness)
(: flattens the distinction between computed and declared witnesses, as well as the eventual nesting of witnesses for each edition:)
let $witnesses := ($computed, $declared)
let $distinctW := dts:distinctW($witnesses)
let $manifests := dts:manifests($witnesses, $id)
 let $worksAndManifests := ($distinctW, $manifests)                                     
let $dcAndWitnesses := if(count($distinctW) gt 0) then map:put($dc, 'dc:source', $worksAndManifests) else $dc
let $DcSelector := 
if($doc//t:TEI/@type= 'mss') then $dc else $dcAndWitnesses
(:$dc:)
let $resourceURN := 'https://betamasaheft.eu/' || $id || $edition
let $versions := if($vers = 'yes') then dts:fileingitCommits($resourceURN, $id, 'collections') else ()
let $DcWithVersions :=  if($vers = 'yes') then map:put($DcSelector, "dc:hasVersion", $versions) else $DcSelector
let $ext := dts:extension($id)
let $haspart := dts:haspart($id)
let $manifest :=dts:manifest($doc, $id)
let $addmanifest := if (count($manifest) ge 1) then map:put($ext, "foaf:depiction", $manifest) else $ext
let $parts := if(count($haspart) ge 1) then map:put($addmanifest, 'dc:hasPart', $haspart) else $addmanifest
let $dtsPass := "/api/dts/document?id=" || $resourceURN
let $dtsNav := "/api/dts/navigation?id=" || $resourceURN
let $download := "https://betamasaheft.eu/tei/" || $id || '.xml'
let $citeDepth :=  if($doc/@type= 'mss' and not($doc//t:objectDesc/@form ='Inscription')) then 3 
else let $counts := for $div in ($document//t:div[@type='textpart'], $document//t:l, $document//t:lb) return count($div/ancestor::t:div)
return max($counts)
let $teirefdecl := if($doc/@type= 'mss' and not($doc//t:objectDesc/@form ='Inscription')) then 
[ map{
                 "dts:citeType": "folio",
                    "dts:citeStructure": [
                       map {
                            "dts:citeType": "page",
                             "dts:citeStructure": [
                       map {
                            "dts:citeType": "column"
                        }
                  ]
             }
          ]
     }
]
else if ($doc/@type='nar') then ()
else
[
dts:nestedDivs($document)
            ]
let $c := count($document//t:ab//text())
let $all := map{
             "@id" : $resourceURN,
              (:  "ecrm:P1_is_identified_by": map { "rdfs:label": $resourceURN},:)
             "title" : $title,
             "description": $description,
             "@type" : "Resource",
             "totalItems": 0,
             "dts:dublincore": $DcWithVersions ,
            "dts:download": $download,
            "dts:citeDepth": $citeDepth,
            "dts:citeStructure": $teirefdecl
        }
let $ext :=         if(count($parts) ge 1) then  map:put($all,"dts:extensions",$parts) else $all
let $pass :=  if($c le 1) then $ext else map:put($ext, "dts:passage", $dtsPass) 
let $nav := if($c le 1) then $pass else map:put($pass, "dts:references", $dtsNav)
        return
        $nav
};

declare function dts:docDesc($doc, $title){
if($doc//t:TEI/@type= 'nar') 
  then 'The narrative unit '||$title||' in Beta maṣāḥǝft ' 
else if($doc//t:TEI/@type= 'mss') 
   then 'The transcription of manuscript '|| $title||' in Beta maṣāḥǝft ' 
else 'The abstract textual unit '||$title|| ' in Beta maṣāḥǝft. '  || 
                                 normalize-space(string-join(string:tei2string($doc//t:abstract), ''))
};

declare function dts:manifests($witnesses, $id){
for $w in distinct-values($witnesses)
                               let $witness := $config:collection-root/id($w)
                               return 
                                             if ($witness//t:idno[@facs]) then 
                                                 let $facs := string($witness//t:idno/@facs)
                                                 return
                                                 if(starts-with($facs, 'http')) 
(:                                                 external manifest:)
                                                        then map {"@id": $facs,  "@type": "sc:Manifest", "dc:title":  ("IIIF Manifest for images of " || titles:printTitleMainID($w))} 
                                                  else 
(:                                                  our manifest, we can point to a specific range:)
                                             ( if($witness//t:msItem[t:title[@ref=$id]]) then for $x in $witness//t:msItem[t:title[@ref=$id]] return map {"@id": "https://betamasaheft.eu/api/iiif/"||$w||"/range/" || string($x/@xml:id),  
                                                                                                                                "@type": "sc:Range", "dc:title":  ("IIIF Range for images of " || titles:printTitleMainID(concat($w, '#', string($x/@xml:id))))} 
                                               else
                                                map {"@id": "https://betamasaheft.eu/api/iiif/"||$w||"/manifest",  "@type": "sc:Manifest", "dc:title":  ("IIIF Manifest for images of " || titles:printTitleMainID($w))})
                                    else ()
};

declare function dts:editioncontent($divuri, $type, $xmlid, $document, $vers){
let $doc := root($document)
let $id := string($doc//t:TEI/@xml:id)
let $title := titles:printTitleMainID($id)
let $edtitle := functx:capitalize-first($type) || ' of ' || $title || (if($xmlid='') then '' else (' with ID ' || $xmlid))
let $description := dts:docDesc($doc, $title)
let $dc := dts:dublinCore($id)
let $computed := dts:computedWit($doc, $id)
let $declared := if($doc//t:TEI/@type= 'mss') then () else 
                            for $witness in $doc//t:witness/@corresp return string($witness)
(: flattens the distinction between computed and declared witnesses, as well as the eventual nesting of witnesses for each edition:)
let $witnesses := ($computed, $declared)
let $distinctW := dts:distinctW($witnesses)
let $manifests := dts:manifests($witnesses, $id)
 let $worksAndManifests := ($distinctW, $manifests)                                     
let $dcAndWitnesses := if(count($distinctW) gt 0) then map:put($dc, 'dc:source', $worksAndManifests) else $dc
let $DcSelector := 
if($doc//t:TEI/@type= 'mss') then $dc else $dcAndWitnesses
(:$dc:)
let $resourceURN := 'https://betamasaheft.eu/' || $id
let $versions := if($vers = 'yes') then dts:fileingitCommits($resourceURN, $id, 'collections') else ()
let $DcWithVersions :=  if($vers = 'yes') then map:put($DcSelector, "dc:hasVersion", $versions) else $DcSelector
let $ext := dts:extension($id)
let $haspart := dts:haspart($id)
let $manifest :=dts:manifest($doc, $id)
let $addmanifest := if (count($manifest) ge 1) then map:put($ext, "foaf:depiction", $manifest) else $ext
let $parts := if(count($haspart) ge 1) then map:put($addmanifest, 'dc:hasPart', $haspart) else $addmanifest
let $dtsPass := "/api/dts/document?id=" || $divuri
let $dtsNav := "/api/dts/navigation?id=" || $divuri
let $download := "https://betamasaheft.eu/tei/" || $id || '.xml'
let $citeDepth :=  if($doc/@type= 'mss' and not($doc//t:objectDesc/@form ='Inscription')) then 3 
else let $counts := for $div in ($document//t:div[@type='textpart'], $document//t:l, $document//t:lb) return count($div/ancestor::t:div)
return max($counts)
let $teirefdecl := if($doc/@type= 'mss' and not($doc//t:objectDesc/@form ='Inscription')) then 
[ map{
                 "dts:citeType": "folio",
                    "dts:citeStructure": [
                       map {
                            "dts:citeType": "page",
                             "dts:citeStructure": [
                       map {
                            "dts:citeType": "column"
                        }
                  ]
             }
          ]
     }
]
else if ($doc/@type='nar') then ()
else
[
dts:nestedDivs($document//t:div[@type=$type][@xml:id=$xmlid])
            ]
let $c := count($document//t:div[@type=$type][@xml:id=$xmlid]//t:ab//text())
let $all := map{
             "@id" : $divuri,
              (:  "ecrm:P1_is_identified_by": map { "rdfs:label": $resourceURN},:)
             "title" : $edtitle,
             "description": $description,
             "@type" : "Resource",
             "totalItems": 0,
             "dts:dublincore": $DcWithVersions ,
            "dts:download": $download,
            "dts:citeDepth": $citeDepth,
            "dts:citeStructure": $teirefdecl
        }
let $ext :=         if(count($parts) ge 1) then  map:put($all,"dts:extensions",$parts) else $all
let $pass :=  if($c le 1) then $ext else map:put($ext, "dts:passage", $dtsPass) 
let $nav := if($c le 1) then $pass else map:put($pass, "dts:references", $dtsNav)
        return
        $nav
};

declare function dts:haspart($id){
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
let $query := fusekisparql:query('betamasaheft', $querytext)
for $result in $query//sr:binding
return
$result/sr:uri/text()

};

(:~ called by dts:dublinCore it expects a dc property name without prefix, and the id of the instance about which the property is stated. sends a sparql query to the triple store and returns the value requested :)
declare function dts:DCsparqls($id, $property){
if ($property = 'title') then

let $querytext := $config:sparqlPrefixes ||  "SELECT ?"||$property||" ?language 
WHERE {bm:" || $id || " dc:"||$property||" ?"||$property||".
 BIND (lang(?title) AS ?language )
}"
(:let $t := console:log($querytext):)
let $query := fusekisparql:query('betamasaheft', $querytext)
for $result in $query//sr:result
let $val := $result/sr:binding[@*:name=$property]/sr:literal/text()
let $lang := $result/sr:binding[@*:name='language']/sr:literal/text()
let $t := map {'@value' : $val}
return 
if($lang !='') then map:put($t, '@lang', $lang) else $t


else 
let $query := $config:sparqlPrefixes ||  "SELECT ?"||$property||" 
WHERE {bm:" || $id || " dc:"||$property||" ?"||$property||"}"
let $query := fusekisparql:query('betamasaheft', $query)
return 
$query//sr:binding[@*:name=$property]/sr:literal/text()
};

(:~ retrives and adds to a map/array the values needed for the dc values in the member property dts:dublinCore() :)

declare function dts:dublinCore($id){
let $creator := dts:DCsparqls($id, 'creator')
let $contributor := dts:DCsparqls($id, 'contributor')
let $language := dts:DCsparqls($id, 'language')
let $title := if(starts-with($id, 'LIT')) then dts:DCsparqls($id, 'title') else map{'@value' : titles:printTitleMainID($id), '@lang' : 'en'}
let $relation := dts:DCsparqls($id, 'relation')
let $listChange := for $change in $config:collection-root/id($id)//t:change return editors:editorKey($change/@who)
let $contributors := ($contributor, $listChange)
let $all := map{
                "dc:title": $title,
                "dc:creator": [if(count($creator) ge 1) then $contributor else 'Beta maṣāḥǝft Team'],
                "dc:contributor": distinct-values($contributors),
                "dc:language": $language
            }
            return
            if(count($relation) ge 1) then  map:put($all,"dc:relation",$relation) else $all
};


(:~ called by dts:mapconstructor it expects a property name with prefix, and the id of the instance about 
which the property is stated. Sends a sparql query to the triple store and returns the value requested :)

declare function dts:sparqls($id, $property){
let $query := $config:sparqlPrefixes ||  "SELECT ?x 
WHERE {bm:" || $id || ' '|| $property||" ?x }"
let $query := fusekisparql:query('betamasaheft', $query)
return 
$query//sr:binding[@*:name='x']/sr:*/text()
};

declare function dts:sparqlsInverse($id, $property){
let $query := $config:sparqlPrefixes ||  "SELECT ?x 
WHERE {?x "|| $property||" bm:"|| $id || " }"
let $query := fusekisparql:query('betamasaheft', $query)
return 
$query//sr:binding[@*:name='x']/sr:*/text()
};

(:~ utility function which takes a map and a list of properties together with a series of indexes to produce a map by recursively 
: being called on successive entries of the list which is carried on until its end. the value in the list is sent to the dts:sparql function which runs a sparql querz using the current value
: in the list as property :)
declare function dts:mapconstructor($id, $currentmap as map()?, $candidateproperty, $index as xs:integer, $listofcandidateproperties){
 if($index = count($listofcandidateproperties)) then $currentmap else
let $next := $listofcandidateproperties[$index]
let $candidatevalue := dts:sparqls($id, $candidateproperty)
let $inversestatement := dts:sparqlsInverse($id, $candidateproperty)
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
then dts:mapconstructor($id, $currentmap, $next, $index+1, $listofcandidateproperties) 
else let $updatedmap := if(count($candidatevalue) = 0) then $currentmap else map:put($currentmap, $candidateproperty, $candidatevalue) 
let $updatedmapINV := if(count($inversestatement) = 0) then $updatedmap else map:put($updatedmap, $inverseOFcandidateproperty, $inversestatement) 
return dts:mapconstructor($id, $updatedmapINV, $next, $index+1, $listofcandidateproperties)
};

(:~  passes to dts:mapconstructor function a list of property names to build a map which only has relevant key-value pair and returns this map. :)
declare function dts:extension($id){
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
let $etcmap := dts:mapconstructor($id, $map, $START, 2, $list)
return
if (map:size($etcmap) = 0) then () else $etcmap
};




(:~ not being sure about what to do with the URI templates in the documentation draft, the templates answer to this call, and can be thus retrived :)
declare
%rest:GET
%rest:path("/BetMas/api/dts/{$api}/template")
%output:method('xml')
function dts:URItemplates($api as xs:string*) {
switch($api)
case 'navigation' return
($config:response200JsonLD,
map {
  "@context": map{
        "@vocab": "https://www.w3.org/ns/hydra/core#",
        "dc": "http://purl.org/dc/terms/",
        "dts": "https://w3id.org/dts/api#",
        "tei": "http://www.tei-c.org/ns/1.0"
  },  
  "@type": "IriTemplate",
  "template": "/dts/api/navigation/?id={collection_id}&amp;passage={passage}&amp;level={level}&amp;start={start}&amp;end={end}&amp;page={page}",
  "variableRepresentation": "BasicRepresentation",
  "mapping": [
    map {
      "@type": "IriTemplateMapping",
      "variable": "collection_id",
      "required": true
    },
    map {
      "@type": "IriTemplateMapping",
      "variable": "passage",
      "required": false
    },
   map {
      "@type": "IriTemplateMapping",
      "variable": "page",
      "required": false
    },
   map {
      "@type": "IriTemplateMapping",
      "variable": "level",
      "required": false
    },
   map {
      "@type": "IriTemplateMapping",
      "variable": "start",
      "required": false
    },
  map  {
      "@type": "IriTemplateMapping",
      "variable": "end",
      "required": false
    }
  ]
})
case 'document' return 
($config:response200JsonLD,

map {
  "@context": map {
        "@vocab": "https://www.w3.org/ns/hydra/core#",
        "dc": "http://purl.org/dc/terms/",
        "dts": "https://w3id.org/dts/api#",
        "tei": "http://www.tei-c.org/ns/1.0"
  },
  "@type": "IriTemplate",
  "template": "/dts/api/document/?id={collection_id}&amp;passage={passage}&amp;level={level}&amp;start={start}&amp;end={end}&amp;page={page}",
  "variableRepresentation": "BasicRepresentation",
  "mapping": [
    map {
      "@type": "IriTemplateMapping",
      "variable": "collection_id",
      "required": true
    },
    map {
      "@type": "IriTemplateMapping",
      "variable": "passage",
      "required": false
    },
     map {
      "@type": "IriTemplateMapping",
      "variable": "start",
      "required": false
    },
  map   {
      "@type": "IriTemplateMapping",
      "variable": "end",
      "required": false
    }
  ]
}
)
case 'collection' return
($config:response200JsonLD,

map {
  "@context": map{
        "@vocab": "https://www.w3.org/ns/hydra/core#",
        "dc": "http://purl.org/dc/terms/",
        "dts": "https://w3id.org/dts/api#",
        "tei": "http://www.tei-c.org/ns/1.0"
  },
  "@type": "IriTemplate",
  "template": "/dts/api/collection/?id={collection_id}&amp;page={page}",
  "variableRepresentation": "BasicRepresentation",
  "mapping": [
    map {
      "@type": "IriTemplateMapping",
      "variable": "collection_id",
      "required": false
    },
   map {
      "@type": "IriTemplateMapping",
      "variable": "page",
      "required": false
    }
  ]
}
)
default return
$config:response400JsonLD,
map{'info': ('You can have collection, document or navigation UIR templates, ' || $api || ' is none of them.')}
};






(:the old ones, still in use. :)

(:~bespoke json format, former dts proposal draft, returns a list:)
declare
%rest:GET
%rest:path("/BetMas/api/dts/collections/{$id}")
%output:method("json")
function dts:CollectionsID($id as xs:string*) {
    let $login := xmldb:login($config:data-root, $config:ADMIN, $config:ppw)
    return
  
        ($config:response200Json,
        
 log:add-log-message('/api/dts/collections/' || $id, sm:id()//sm:real/sm:username/string() , 'dts'),
    <json:value>
        <context>
        <perseus>http://perseus.org/terms</perseus>
   <rdf>http://www.w3.org/1999/02/22-rdf-syntax-ns#</rdf>
    <dts>http://ontology-dts.org/terms</dts>
    <saws>http://purl.org/saws/ontology</saws>
    <snap>http://data.snapdrgn.net/ontology/snap</snap>
    <dcterms>http://purl.org/dc/terms</dcterms>
    <bm>{$config:appUrl}/</bm>
    <ecrm>http://erlangen-crm.org/current/</ecrm>
    <tei>http://www.tei-c.org/ns/1.0</tei>
    </context>
    <graph>{
            let $record := $config:collection-root/id($id)[name()='TEI']
            return
                (
                <id>urn:dts:betmas:{string($record/@xml:id)}</id>,
                <type>{string($record/@type)}</type>,
                <license>http://creativecommons.org/licenses/by-sa/4.0/</license>,
                <size>1</size>,
                <labels>
                            {
                                for $lang in $record//t:language
                                return
                                  <lang>     
                                     {  string($lang/@ident) }
                                 </lang>
                            }
                        <value>{titles:printTitleMainID($id)}</value>
                        <description>{$record//t:abstract//text()}</description>
                    </labels>,
                <vocabulary>http://purl.org/dc/elements/1.1/</vocabulary>,
                <capabilities>
                    <isOrdered>false</isOrdered>
                    <hasRoles>false</hasRoles>
                </capabilities>,
                <metadata>
                {if ($record//t:relation[@name='dcterms:creator']) then (element dcterms:creator{titles:printTitleMainID($record//t:relation[@name='dcterms:creator']/string(@passive))}) 
                else if ($record//t:relation[@name='saws:isAttributedToAuthor']) then (element saws:isAttributedToAuthor{titles:printTitleMainID($record//t:relation[@name='saws:isAttributedToAuthor']/string(@passive))})
                else if ($record//t:author) then <t:author>{$record//t:author/text()}</t:author> 
                else ()}
                </metadata>,
                
                <members>
                <id>{$config:appUrl}/{$id}</id>
                <id>{$config:appUrl}/api/{$id}/tei</id>
                <id>{$config:appUrl}/api/{$id}/json</id>
                   
                                <contents>
                        {  let $members := for $mem in ($record//t:relation/@passive) 
                                                     let $name := string($mem/parent::t:*/@name)
                                                     return 
                                                   
                                                     if (contains($mem, ' ')) then 
                                                      for $m in tokenize(normalize-space($mem), ' ')
                                                       return 
                                                       <rels><id>{$m}</id><n>{$name}</n></rels>
                                                     else
                                                       <rels><id>{data($mem)}</id><n>{$name}</n></rels>
                            for $part in distinct-values($members//id)
                           return
                            <json:value>
                                    <id>urn:dts:betmas:{string($part)}</id>
                                    <type>work</type>
                                    <mappings>
                                    <role>{$members//n[preceding-sibling::id = $part]/text()}</role>
                                    </mappings>
                                    </json:value>
                                  }
                                  </contents>
                </members>,
                
                <version>{
                            max($record//t:change/xs:date(@when))
                    }</version>,
                
                <parents><json:value
                            json:array="true"> {
                       let $parents := for $par in ($record//t:relation[@name = 'saws:formsPartOf']/@passive) 
                                                    return $par
                            for $parent in distinct-values($parents)
                            let $papa := $config:collection-root/id($parent)[name()='TEI']
                            return
                                
                                    (<id>urn:dts:betmas:{string($papa/@xml:id)}</id>,
                                    <type>{string($papa/@type)}</type>,
                                    <labels>
                    
                            {
                                for $lang in $papa//t:language
                                return
                                    
                                 <lang>     {  string($lang/@ident) }</lang>
                            }
                        
                        <value>{titles:printTitleMainID($parent)}</value>
                    
                </labels>
                                    )
                                  
                               
                        } </json:value>
                        
                </parents>
                )
                }</graph>
        
    </json:value>)
};


(:~ returns the short title for citations or the main one:)
declare function dts:citation($item as node()){
if($item//t:titleStmt/t:title[@type='short']) 
then $item//t:titleStmt/t:title[@type='short']/text() 
else $item//t:titleStmt/t:title[@xml:id = 't1']/text()
};


(:~The following function retrive the text of the selected work and returns
: it with basic informations for next and following into a small JSON tree 
returns the lines of the second level of subdivision (subchapters) e.g. 
XXX. 1 
XXX. 1 

:)
declare
%rest:GET
%rest:path("/BetMas/api/dts/text/{$id}")
%output:method("json")
function dts:get-workJSON($id as xs:string) {
    ($config:response200Json,
 log:add-log-message('/api/dts/text/' || $id, sm:id()//sm:real/sm:username/string() , 'dts'),
    let $collection := 'works'
    let $item := $config:collection-root/id($id)[name() ='TEI']
    let $recordid := $item/@xml:id
    return
        if ($item//t:div[@type = 'edition'])
        then
            <json:value
                json:array="true">
                <id>{data($recordid)}</id>
                <citation>{dts:citation($item)}</citation>
                <text>{let $t := string-join($item//t:div[@type = 'edition']//text(), ' ') return normalize-space($t)}</text>
                <contains><json:value
                        json:array="true">
                        {
                            for $subtype in $item//t:div[@type = 'edition']/t:div[@subtype]
                            return
                                
                                element {string($subtype/@subtype)} {($config:appUrl||'/api/dts/' || $id || '/' || $subtype/@n)}
                        }
                    </json:value>
                </contains>
            
            
            </json:value>
        
        else
            <json:value>
                <json:value
                    json:array="true">
                    <info>No results, sorry</info>
                </json:value>
            </json:value>
    )
};


(:~returns the lines of the second level of subdivision (subchapters) e.g.
XXX. 2, 4
XXX. 2, 4-7
:)
declare
%rest:GET
%rest:path("/BetMas/api/dts/text/{$id}/{$level1}")
%output:method("json")
function dts:get-toplevelJSON($id as xs:string, $level1 as xs:string*) {
    ($config:response200Json,
 log:add-log-message('/api/dts/text/'||$id||'/'||$level1, sm:id()//sm:real/sm:username/string() , 'dts'),
    let $collection := 'works'
    let $item := $config:collection-root/id($id)[name() ='TEI']
    let $recordid := $item/@xml:id
    let $L1 := $item//t:div[@type = 'edition']/t:div[@n = $level1]
    return
        if ($L1)
        then
            <json:value
                json:array="true">
                <id>{data($recordid)}</id>
                <citation>{(dts:citation($item) || ' ' || $level1)}</citation>
                <text>{let $t := string-join($L1//text(), ' ') return normalize-space($t)}</text>
                {
                    if (number($level1) > 1 and $item//t:div[@type = 'edition']/t:div[@n = (number($level1) - 1)])
                    then
                        <previous>{$config:appUrl}/api/dts/{$id}/{number($level1) - 1}</previous>
                    else
                        ()
                }
                {
                    if (number($level1) = count($item//t:div[@subtype = 'book']))
                    then
                        ()
                    else
                        if ($item//t:div[@type = 'edition']/t:div[@n = (number($level1) + 1)])
                        then
                            <next>{$config:appUrl}/api/dts/{$id}/{number($level1) + 1}</next>
                        else
                            ()
                }
                <contains><json:value
                        json:array="true">
                        {
                            for $subtype in $L1/t:div[@subtype]
                            return
                                
                                element {string($subtype/@subtype)} {($config:appUrl||'/api/dts/' || $id || '/' || $level1 || '/' || $subtype/@n)}
                        }
                    </json:value>
                </contains>
                <partofwork>{$config:appUrl}/api/dts/{$id}</partofwork>
            </json:value>
        
        else
            <json:value>
                <json:value
                    json:array="true">
                    <info>No results, sorry</info>
                </json:value>
            </json:value>
    )
};

(:~returns the lines of the first level of subdivision (chapters):)
declare
%rest:GET
%rest:path("/BetMas/api/dts/text/{$id}/{$level1}/{$line}")
%output:method("json")
function dts:get-level1JSON($id as xs:string, $level1 as xs:string*, $line as xs:string*) {
    ($config:response200Json,
    
 log:add-log-message('/api/dts/text/'||$id||'/'||$level1||'/'||$line, sm:id()//sm:real/sm:username/string() , 'dts'),
    let $collection := 'works'
    let $item := $config:collection-root/id($id)[name() ='TEI']
    let $recordid := $item/@xml:id
    let $L1 := $item//t:div[@type = 'edition']/t:div[@n = $level1]
    
    return
        if (contains($line, '-'))
        then
            <json:value
                json:array="true">
                <id>{data($recordid)}</id>
                <citation>{(dts:citation($item) || ' ' || $level1 || ', ' || $line)}</citation>
                <title>{$item//t:titleStmt/t:title[@xml:id = 't1']/text()}</title>
                <text>{
                        for $l in (xs:integer(substring-before($line, '-')) to xs:integer(substring-after($line, '-')))
                        let $thisline := $L1//t:l[@n = string($l)]
                        let $t := string-join($thisline//text(), ' ')
                            
                        return
                            normalize-space($t)
                    }</text>
                {
                    if (number(substring-before($line, '-')) > 1)
                    then
                        <previous>{$config:appUrl}/api/dts/{$id}/{$level1}/{number(substring-before($line, '-')) - 1}</previous>
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
                            <next>{$config:appUrl}/api/dts/{$id}/{$level1}/{number(substring-after($line, '-')) + 1}</next>
                        else
                            ()
                }
                <contains><json:value
                        json:array="true">
                        {
                            for $subtype in $L1//t:*[@n]
                            return
                                
                                element {$subtype/name()} {($config:appUrl||'/api/dts/' || $id || '/' || $level1 || '/' || $subtype/@n)}
                        }
                    </json:value>
                </contains>
                <partofchapter>{$config:appUrl}/api/dts/{$id}/{$level1}</partofchapter>
            
            </json:value>
        else 
        let $ltext := $L1//t:l[@n = $line]
        return
            if ($ltext)
            then
           
            let $onlytext := string-join($ltext//text(), '')
            return
                <json:value
                    json:array="true">
                    
                    <id>{data($recordid)}</id>
                    <citation>{(dts:citation($item) || ' ' || $level1 || ', ' || $line)}</citation>
                    <title>{let $t := $item//t:titleStmt return $t/t:title[@xml:id = 't1']/text()}</title>
                    
                    <text>{normalize-space($onlytext)}</text>
                    {
                        if (number($line) > 1)
                        then
                            <previous>{$config:appUrl}/api/dts/{$id}/{$level1}/{number($line) - 1}</previous>
                        else
                            ()
                    }
                    {
                        if (number($line) = count($ltext))
                        then
                            ()
                        else
                            if ($L1//t:l[@n = (number($line) + 1)])
                            then
                                <next>{$config:appUrl}/api/dts/{$id}/{$level1}/{number($line) + 1}</next>
                            else
                                ()
                    }
                    <contains><json:value
                            json:array="true">
                            {
                                for $subtype in $L1//t:*[@n]
                                return
                                    
                                    element {$subtype/name()} {($config:appUrl||'/api/dts/' || $id || '/' || $level1 || '/' || $subtype/@n)}
                            }
                        </json:value>
                    </contains>
                    <partofchapter>{$config:appUrl}/api/dts/{$id}/{$level1}</partofchapter>
                    <partofwork>{$config:appUrl}/api/dts/{$id}</partofwork>
                
                </json:value>
            
            
            else
                <json:value>
                    <json:value
                        json:array="true">
                        <info>No results, sorry</info>
                    </json:value>
                </json:value>
    )
};


(:~returns the lines of the second level of subdivision (chapters):)
declare
%rest:GET
%rest:path("/BetMas/api/dts/text/{$id}/{$level1}/{$level2}/{$line}")
%output:method("json")
function dts:get-level2JSON($id as xs:string, $level1 as xs:string*, $level2 as xs:string*, $line as xs:string*) {
    ($config:response200Json,
    
 log:add-log-message('/api/dts/text/'||$id||'/'||$level1||'/'||$level2||'/'||$line, sm:id()//sm:real/sm:username/string() , 'dts'),
    let $collection := 'works'
    let $item := $config:collection-root/id($id)[name() ='TEI']
    let $recordid := $item/@xml:id
    let $L1 := $item//t:div[@type = 'edition']/t:div[@n = $level1]
    let $L2 := $L1/t:div[@n = $level2]
    return
        if (contains($line, '-'))
        then
            
            <json:value
                json:array="true">
                <id>{data($recordid)}</id>
                <citation>{(dts:citation($item) || ' ' || $level2 || ', ' || $line)}</citation>
                <title>{$item//t:titleStmt/t:title[@xml:id = 't1']/text()}</title>
                <text>{
                        for $l in (xs:integer(substring-before($line, '-')) to xs:integer(substring-after($line, '-')))
                        return
                            normalize-space($L2//t:l[@n = string($l)]//text())
                    }</text>
                {
                    if (number(substring-before($line, '-')) > 1)
                    then
                        <previous>{$config:appUrl}/api/dts/{$id}/{$level1}/{$level2}/{number(substring-before($line, '-')) - 1}</previous>
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
                            <next>{$config:appUrl}/api/dts/{$id}/{$level1}/{$level2}/{number(substring-after($line, '-')) + 1}</next>
                        else
                            ()
                }
                <partofchapter>{$config:appUrl}/api/dts/{$id}/{$level1}/{$level2}</partofchapter>
                <partofbook>{$config:appUrl}/api/dts/{$id}/{$level1}</partofbook>
                
                <partofwork>{$config:appUrl}/api/dts/{$id}</partofwork>
            
            </json:value>
        
        else
            if ($L2//t:l[@n = $line])
            then
                <json:value>
                    {
                        
                        let $recordid := $item/t:TEI/@xml:id
                        
                        return
                            <json:value
                                json:array="true">
                                <id>{data($recordid)}</id>
                                <text>{normalize-space($L2//t:l[@n = $line]//text())}</text>
                                {
                                    if (number($line) > 1)
                                    then
                                        <previous>{$config:appUrl}/api/dts/{$id}/{$level1}/{$level2}/{number($line) - 1}</previous>
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
                                            <next>{$config:appUrl}/api/dts/{$id}/{$level1}/{$level2}/{number($line) + 1}</next>
                                        else
                                            ()
                                }
                                <partofchapter>{$config:appUrl}/api/dts/{$id}/{$level1}/{$level2}</partofchapter>
                                <partofbook>{$config:appUrl}/api/dts/{$id}/{$level1}</partofbook>
                                
                                <partofwork>{$config:appUrl}/api/dts/{$id}</partofwork>
                            
                            </json:value>
                    }
                </json:value>
            else
                <json:value>
                    <json:value
                        json:array="true">
                        <info>No results, sorry</info>
                    </json:value>
                </json:value>
    )
};


