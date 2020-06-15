xquery version "3.1" encoding "UTF-8";
(:~
 : test implementation of the https://github.com/distributed-text-services
 : CLIENT
 : @author Pietro Liuzzo 
 :
 : can take any number of specified DTS endpoints to parse and display them,
 : so, insted of just calling the functions in the DTS module or directly query the db, it sends
 : http requests and follows the structures of the DTS endpoint.
 :)
 
module namespace dtsc="https://www.betamasaheft.uni-hamburg.de/BetMas/dtsc";
declare namespace http = "http://expath.org/ns/http-client";
declare namespace test="http://exist-db.org/xquery/xqsuite";
declare namespace dts = "https://w3id.org/dts/api#";
declare namespace t="http://www.tei-c.org/ns/1.0";
import module namespace functx="http://www.functx.com";
import module namespace console="http://exist-db.org/xquery/console";


declare function dtsc:text($id, $edition, $ref, $start, $end, $collection){
(:let $t := console:log(string-join(($edition, $ref, $start, $end), ' - ')):)
let $approot:= 
(:'https://betamasaheft.eu':)
'http://localhost:8080/exist/apps/BetMas'
let $APIroot:='/api/dts/'
let $NavAPI:='navigation'
let $ColAPI:='collections'
let $DocAPI:='document'
let $baseid := '?id=https://betamasaheft.eu/' 
let $ps := (if($ref='') then () else 'ref='||$ref , 
                    if($start='') then () else 'start='||$start , 
                    if($end='') then () else 'end='||$end )
let $parm := if(count($ps) ge 1) then '&amp;' || string-join($ps,'&amp;') else ()
let $refstart := if($ref != '') then ('.'||$ref) else if($start != '') then ('.'||$start || '-' || $end) else ()
let $citationuri := ($approot||'/'||$id||$edition||$refstart)
let $uricol := ($approot||$APIroot||$ColAPI||$baseid||$id||$edition)
let $urinav := ($approot||$APIroot||$NavAPI||$baseid||$id||$edition||$parm)
let $uridoc := ($approot||$APIroot||$DocAPI||$baseid||$id||$edition||$parm)
let $DTScol := dtsc:request($uricol)
let $DTSnav := dtsc:request($urinav)
let $DTSdoc := dtsc:requestXML($uridoc)
let $docnode := if($DTSdoc//dts:fragment) then $DTSdoc//dts:fragment else $DTSdoc//t:div[@type='edition']
(:fetch text of the translation if available:)
(:let $translation := if($DTScol?('@type') = 'Collection' and contains($DTScol?member?('@id'), '_TR_')) then () else ():)
let $xslt :=   'xmldb:exist:///db/apps/BetMas/xslt/textfragment.xsl'  
let $xslpars := <parameters><param name="mainID" value="{$id}"/></parameters>
return
<div class="w3-container">
<div class="w3-row">
<div class="w3-bar">
<div class="w3-bar-item w3-small">{for $d in $DTScol?('dts:dublincore')?('dc:title')?*?('@value') return $d}</div>
<button class="w3-bar-item w3-gray w3-small" id="toogleTextBibl">Hide Bibliography</button></div>
{if($DTScol?('@type') = 'Collection') then 
(<div class="w3-bar">
<div class="w3-bar-item w3-red">Editions</div>
{for $ed in $DTScol?member?*
return 
<div class="w3-bar-item w3-red"><a href="{$ed?('@id')}" target="_blank">{$ed?title}</a></div>
}
</div>) else ()}
</div>
<div class="w3-row">
<div class="w3-col" style="width:10%">
<div class="w3-bar-block">
<div class="w3-bar-item w3-black w3-small">
<a target="_blank" href="http://voyant-tools.org/?input={$uridoc}">Voyant</a>
        </div>
{if($ref !='' or $start !='') then 
<div class="w3-bar-item w3-red w3-small">
<a href="/{$collection}/{$id}/text">
Full text view
</a>
</div> 
else ()}
{
for $members in $DTSnav?member
for $member in $members?*
return 
<div class="w3-bar-item w3-gray w3-small">
<span class="w3-tooltip"><a href="/{$id}{$edition}.{$member?('dts:ref')}">
{($member?('dts:citeType')|| ' '|| $member?('dts:ref'))}
</a>
<span class="w3-text w3-tag" style="word-break:break-all;">{$approot}/{$id}{$edition}.{$member?('dts:ref')}</span>
</span>
</div>
}
<button onclick="openAccordion('dtsuris')" class="w3-bar-item w3-black w3-small w3-button">
DTS uris</button>
</div>
<ul id="dtsuris" class="w3-ul w3-border w3-hide" style="word-break:break-word;">
<li><b>Citation URI</b>: {$citationuri}</li>
<li><b>Collection API</b>: {$uricol}</li>
<li><b>Navigation API</b>: {$urinav}</li>
<li><b>Document API</b>: {$uridoc}</li>
</ul>
</div>
<div class="w3-rest">{
try{transform:transform($docnode,$xslt,$xslpars)} catch * {$err:description}
}</div>
</div>
</div>
};


declare function dtsc:request($dtspaths){
 for $dtspath in $dtspaths 
    let $request := <http:request href="{xs:anyURI($dtspath)}" method="GET"/>
    let $file := http:send-request($request)[2]
    let $payload := util:base64-decode($file) 
    let $parse-payload := parse-json($payload)
    return $parse-payload 
}; 

declare function dtsc:requestXML($dtspaths){
 for $dtspath in $dtspaths 
    let $request := <http:request href="{xs:anyURI($dtspath)}" method="GET"/>
    return http:send-request($request)
}; 