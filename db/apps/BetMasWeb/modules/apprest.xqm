xquery version "3.1" encoding "UTF-8";
(:~
 : module used by the restXQ modules functions
 : used by the main views for items
 :
 : @author Pietro Liuzzo
 :)

module namespace apprest="https://www.betamasaheft.uni-hamburg.de/BetMasWeb/apprest";

declare namespace t="http://www.tei-c.org/ns/1.0";
declare namespace functx = "http://www.functx.com";
declare namespace exist = "http://exist.sourceforge.net/NS/exist";
declare namespace s = "http://www.w3.org/2005/xpath-functions";
declare namespace http = "http://expath.org/ns/http-client";

import module namespace string = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/string" at "xmldb:exist:///db/apps/BetMasWeb/modules/tei2string.xqm";
import module namespace kwic = "http://exist-db.org/xquery/kwic"   at "resource:org/exist/xquery/lib/kwic.xql";
import module namespace app="https://www.betamasaheft.uni-hamburg.de/BetMasWeb/app" at "xmldb:exist:///db/apps/BetMasWeb/modules/app.xqm";
import module namespace editors="https://www.betamasaheft.uni-hamburg.de/BetMasWeb/editors" at "xmldb:exist:///db/apps/BetMasWeb/modules/editors.xqm";
import module namespace exptit="https://www.betamasaheft.uni-hamburg.de/BetMasWeb/exptit" at "xmldb:exist:///db/apps/BetMasWeb/modules/exptit.xqm";
import module namespace switch2 = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/switch2" at "xmldb:exist:///db/apps/BetMasWeb/modules/switch2.xqm";
import module namespace templates="http://exist-db.org/xquery/templates" ;
import module namespace config="https://www.betamasaheft.uni-hamburg.de/BetMasWeb/config" at "xmldb:exist:///db/apps/BetMasWeb/modules/config.xqm";
import module namespace charts = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/charts" at "xmldb:exist:///db/apps/BetMasWeb/modules/charts.xqm";
import module namespace console = "http://exist-db.org/xquery/console";
import module namespace exreq = "http://exquery.org/ns/request";
import module namespace viewItem = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/viewItem" at "xmldb:exist:///db/apps/BetMasWeb/modules/viewItem.xqm";
import module namespace locus = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/locus" at "xmldb:exist:///db/apps/BetMasWeb/modules/locus.xqm";

declare variable $apprest:languages := doc('/db/apps/lists/languages.xml');
declare variable $apprest:prefixes := doc('https://raw.githubusercontent.com/BetaMasaheft/Documentation/master/prefixDef.xml');
declare variable $apprest:collection-rootMS := collection($config:data-rootMS);
declare variable $apprest:collection-rootPr := collection($config:data-rootPr);
declare variable $apprest:collection-rootW := collection($config:data-rootW);
declare variable $apprest:collection-rootIn := collection($config:data-rootIn);
declare variable $apprest:collection-rootPlIn := collection($config:data-rootPl,$config:data-rootIn);
declare variable $apprest:collection-root := $exptit:col;

declare function apprest:trim( $arg as xs:string? )  as xs:string {

   replace(replace($arg,'\s+$',''),'^\s+','')
 } ;

 (:~ called by restSearch:FormPart() in search.xql used by advances search form as.html and filters.js MANUSCRIPTS FILTERS for CONTEXT:)
 declare
 %templates:default("context", "$apprest:collection-rootMS")
 function apprest:origPlace($context as xs:string*) {
     let $cont := util:eval($context)
     let $scripts := config:distinct-values($cont//t:origPlace/t:placeName/@ref)
   return
   apprest:formcontrol('Place of origin','origPlace', $scripts, 'false', 'rels', $context)

 };

(:~ called by restSearch:FormPart() in search.xql used by advances search form as.html and filters.js MANUSCRIPTS FILTERS for CONTEXT:)
declare
%templates:default("context", "$apprest:collection-rootMS")
function apprest:scripts($context as xs:string*) {
    let $cont := util:eval($context)
    let $scripts := config:distinct-values($cont//@script)
  return
  apprest:formcontrol('Script','script', $scripts, 'false', 'values', $context)

};

(:~ called by restSearch:FormPart() in search.xql used by advances search form as.html and filters.js :)
declare
%templates:default("context", "$apprest:collection-rootMS")
function apprest:support($context as xs:string*) {
     let $cont := util:eval($context)
     let $forms := config:distinct-values($cont//@form)
    return
    apprest:formcontrol('Object Type', 'objectType', $forms, 'false', 'values', $context)

};

(:~ called by restSearch:FormPart() in search.xql used by advances search form as.html and filters.js :)
declare
%templates:default("context", "$apprest:collection-rootMS")
function apprest:material($context as xs:string*) {
      let $cont := util:eval($context)
      let $materials := config:distinct-values($cont//t:support/t:material/@key)
    return
    apprest:formcontrol('Material', 'material', $materials, 'false', 'values', $context)

};

(:~ called by restSearch:FormPart() in search.xql used by advances search form as.html and filters.js :)
declare
%templates:default("context", "$apprest:collection-rootMS")
function apprest:bmaterial($context as xs:string*) {
    let $cont := util:eval($context)
      let $bmaterials := config:distinct-values($cont//t:decoNote[@type eq 'bindingMaterial']/t:material/@key)
    return
        apprest:formcontrol('Binding Material','bmaterial', $bmaterials, 'false', 'values', $context)

};

declare
%templates:default("context", "$apprest:collection-rootMS")
function apprest:bindingtype($context as xs:string*) {
    let $cont := util:eval($context)
      let $bindingtype := config:distinct-values($cont//t:binding/@contemporary)
    return
        apprest:formcontrol('Original binding','bindingtype', $bindingtype, 'false', 'values', $context)

};
(:~ called by restSearch:FormPart() in search.xql used by advances search form as.html and filters.js PLACES FILTERS for CONTEXT:)
declare
%templates:default("context", "$apprest:collection-rootPlIn")
function apprest:placeType($context as xs:string*) {
      let $cont := util:eval($context)
     let $placeTypes := config:distinct-values($cont//t:place/@type/tokenize(., '\s+'))
   return
   apprest:formcontrol('Place Type', 'placeType', $placeTypes, 'false', 'values', $context)

};

(:~ called by restSearch:FormPart() in search.xql used by advances search form as.html and filters.js :)
declare
%templates:default("context", "$apprest:collection-rootPr")
function apprest:personType($context as xs:string*) {
    let $cont := util:eval($context)
      let $persTypes := config:distinct-values($cont//t:person//t:occupation/@type/tokenize(., '\s+'))
    return
    apprest:formcontrol('Person Type', 'persType', $persTypes, 'false', 'values', $context)

};

(:~ called by restSearch:FormPart() in search.xql used by advances search form as.html and filters.js :)
declare
%templates:default("context", "$exptit:col")
function apprest:relationType($node as node(), $model as map(*)) {
    let $cont := util:eval($context)
    let $relTypes := config:distinct-values($cont//t:relation/@name/tokenize(., '\s+'))
 return
 apprest:formcontrol('Relation Type', 'relType', $relTypes, 'false', 'values', $context)

};


(:~ called by restSearch:FormPart() in search.xql used by advances search form as.html and filters.js :)
declare
%templates:default("context", "$apprest:collection-rootMS")
function apprest:languages($context as xs:string*) {
     let $cont := util:eval($context)
     let $keywords := config:distinct-values($cont//t:language/@ident)
    return
    apprest:formcontrol('Language', 'language', $keywords, 'false', 'values', $context)

};

(:~ called by restSearch:FormPart() in search.xql used by advances search form as.html and filters.js :)
declare
%templates:default("context", "$apprest:collection-rootMS")
function apprest:scribes($context as xs:string*) {
     let $cont := util:eval($context)
      let $elements := $cont//t:persName[@role eq 'scribe'][not(@ref eq 'PRS00000')][ not(@ref eq 'PRS0000')]
    let $keywords := config:distinct-values($elements/@ref)
    return
    apprest:formcontrol('Scribe', 'scribe', $keywords, 'false', 'rels', $context)

};

(:~ called by restSearch:FormPart() in search.xql used by advances search form as.html and filters.js :)
declare
%templates:default("context", "$apprest:collection-rootMS")
function apprest:donors($context as xs:string*) {
     let $cont := util:eval($context)
    let $elements := $cont//t:persName[@role eq 'donor'][not(@ref eq 'PRS00000')][ not(@ref eq 'PRS0000')]
    let $keywords := config:distinct-values($elements/@ref)
  return
  apprest:formcontrol('Donor', 'donor', $keywords, 'false', 'rels', $context)

};

(:~ called by restSearch:FormPart() in search.xql used by advances search form as.html and filters.js :)
declare
%templates:default("context", "$apprest:collection-rootMS")
function apprest:patrons($context as xs:string*) {
     let $cont := util:eval($context)
      let $elements := $cont//t:persName[@role eq 'patron'][not(@ref eq 'PRS00000')][ not(@ref eq 'PRS0000')]
    let $keywords := config:distinct-values($elements/@ref)
 return apprest:formcontrol('Patron', 'patron', $keywords, 'false', 'rels', $context)

};

(:~ called by restSearch:FormPart() in search.xql used by advances search form as.html and filters.js :)
declare
%templates:default("context", "$apprest:collection-rootMS")
function apprest:owners($context as xs:string*) {
      let $cont := util:eval($context)
      let $elements := $cont//t:persName[@role eq 'owner'][not(@ref eq 'PRS00000')][ not(@ref eq 'PRS0000')]
      let $keywords := config:distinct-values($elements/@ref)
     return apprest:formcontrol('Owner', 'owner', $keywords, 'false', 'rels', $context)

};

(:~ called by restSearch:FormPart() in search.xql used by advances search form as.html and filters.js :)
declare
%templates:default("context", "$apprest:collection-rootMS")
function apprest:binders($context as xs:string*) {
      let $cont := util:eval($context)
      let $elements := $cont//t:persName[@role eq 'binder'][not(@ref eq  'PRS00000')][ not(@ref eq 'PRS0000')]
    let $keywords := config:distinct-values($elements/@ref)
 return
 apprest:formcontrol('Binder', 'binder', $keywords, 'false', 'rels', $context)

};

(:~ called by restSearch:FormPart() in search.xql used by advances search form as.html and filters.js :)
declare
%templates:default("context", "$apprest:collection-rootMS")
function apprest:parmakers($context as xs:string*) {
    let $cont := util:eval($context)
      let $elements := $cont//t:persName[@role eq 'parchmentMaker'][not(@ref eq 'PRS00000')][ not(@ref eq 'PRS0000')]
    let $keywords := config:distinct-values($elements/@ref)
   return
   apprest:formcontrol('Parchment Maker', 'parchmentMaker', $keywords, 'false', 'rels', $context)

};

(:~ called by restSearch:FormPart() in search.xql used by advances search form as.html and filters.js :)
declare
%templates:default("context", "$apprest:collection-rootMS")
function apprest:contents($context as xs:string*) {
    let $cont := util:eval($context)
    let $elements :=$cont//t:msItem
    let $titles := $elements/t:title/@ref
    let $keywords := config:distinct-values($titles)
  return
   apprest:formcontrol('Contents', 'contents', $keywords, 'false', 'rels', $context)
};


(:~ called by restSearch:FormPart() in search.xql used by advances search form as.html and filters.js :)
declare
%templates:default("context", "$apprest:collection-rootW")
function apprest:WorkAuthors($context as xs:string*) {
let $works := util:eval($context)
let $attributions := for $rel in ($works//t:relation[@name eq "saws:isAttributedToAuthor"], $works//t:relation[@name eq "dcterms:creator"])
let $r := $rel/@passive
                return
                if (contains($r, ' ')) then tokenize($r, ' ') else $r
let $keywords := config:distinct-values($attributions)
  return
   apprest:formcontrol('Authors','authors', $keywords, 'false', 'rels', $context)
};

(:~ called by restSearch:FormPart() in search.xql used by advances search form as.html and filters.js :)
declare
%templates:default("context", "$apprest:collection-rootIn")
function apprest:tabots($context as xs:string*) {
let $cont := util:eval($context)
let $tabots:= $cont//t:ab[@type eq 'tabot']
    let $personTabot := config:distinct-values($tabots//t:persName/@ref)
    let $thingsTabot := config:distinct-values($tabots//t:ref/@corresp)
    let $alltabots := ($personTabot, $thingsTabot)
  return
   apprest:formcontrol('Tabot','tabot', $alltabots, 'false', 'rels', $context)
};


(:test function returns the formatted zotero entry given the unique tag :)
declare function apprest:getZoteroTextData ($ZoteroUniqueBMtag as xs:string){
let $xml-url := concat('https://api.zotero.org/groups/358366/items?tag=',$string,'&amp;format=bib&amp;style=hiob-ludolf-centre-for-ethiopian-studies&amp;linkwrap=1')
let $request := <http:request href="{xs:anyURI($xml-url)}" method="GET"/>
let $data := http:send-request($request)[2]
return
$data//text()
};

declare function apprest:decidelink($link){
if(contains($link, 'http')) then $link
else if (contains($link, ':')) then (
        let $ns := substring-before($link, ':')
        let $prefixDef := $apprest:prefixes//t:prefixDef[@ident eq $ns]
        return replace(substring-after($link, ':'), $prefixDef/@matchPattern, $prefixDef/@replacementPattern)
        )
else concat($config:appUrl,'/',$link)
};

declare function apprest:deciderelation($list){
  <ul class="nodot">{
    for $id in $list
    let $t := util:log('info', $id)
    let $link := apprest:decidelink($id/text())
                return
                  <li>{
                if (starts-with($id/text(), 'sdc:')) then 'La Synthaxe du Codex ' || substring-after($id/text(), 'sdc:' )

               else if (starts-with($id/text(), 'urn:')) then
                   <a target="_blank"  href="/{encode-for-uri($id/text())}">{$id/text()}</a>
     else if (contains($link, 'betamasaheft')) then
                   <a target="_blank"  href="{apprest:decidelink($id)}">{exptit:printTitle($id/text())}</a>
     else
                   <a target="_blank"  href="{apprest:decidelink($id)}">{$link}</a>
                   }</li>
}</ul>
};

(:~used by items.xql to print the relations as a table in the relations view:)
declare function apprest:EntityRelsTable($this, $collection){

let $entity := $this
let $id := string($this/@xml:id)
let $rels := $entity//t:relation[@name][(@active and @passive) or @mutual]
let $otherrelsp := $exptit:col//t:relation[contains(@passive, $id)]
let $otherrelsa := $exptit:col//t:relation[contains(@active, $id)]
let $otherrels := ($otherrelsp, $otherrelsa)
let $oth := $otherrels[ancestor::t:TEI[not(@xml:id eq $id)]][@name]
(:the three variables here assume that there will be relations in the requested file, and that if a relation somewhere else has this id in active it will not have it in passive:)
let $allrels := ($rels, $oth)
return
(<div class="w3-panel w3-small w3-red"><span class="w3-tag w3-gray">{count($allrels)}</span> relations found</div>,
                        <div style="word-break:break-all;">
                        <table class="w3-table-all w3-small"
                        xmlns="http://www.w3.org/1999/xhtml">
                            <thead>
                                <tr>
                                    <th>Subject</th>
                                    <th>Relation</th>
                                    <th>Object</th>
                                    <th>Description</th>
                                </tr>
                            </thead>
                            <tbody>

{for $relation in $allrels
return
                                    <tr>
                                        <td>
                                        {
        for $active in data($relation/@active)
          let $list :=<list>{
              if (contains($active, ' '))
             then
                 for $eachID in tokenize(normalize-space($active), ' ')
                     return
              <id>{

                        $eachID
                }</id>
               else
        (
            <id>{

                        $active
                }</id>)}
              </list>

               return
apprest:deciderelation($list//id)

    }

                                        </td>
                                        <td>
                                            <a href="{apprest:decidelink(data($relation/@name))}">{data($relation/@name)}</a>
                                        </td>
                                        <td>
                                         { for $passive in data($relation/@passive)
          let $list := <list>{
              if (contains($passive, ' '))
             then
                 for $eachID in tokenize(normalize-space($passive), ' ')
                     return
              <id>{

                        $eachID
                }</id>
               else
        (
            <id>{

                        $passive
                }</id>)}
              </list>
                return
      apprest:deciderelation($list//id)

    }

                                        </td>
                                        <td>
{     if($relation/t:desc)   then
viewItem:relations($relation/t:desc)
else ()
}
                                        </td>
                                    </tr>
                                    }
                            </tbody>
                        </table>
</div>)

};

(:~The SEE ALSO section has ready made queries providing related contents,these are all dispalyed in divs with lists of which this is the template:)
declare function apprest:ModalRefsList($id, $string as xs:string, $sameKey){
let $value := if (doc($config:data-rootA || '/taxonomy.xml')//t:catDesc[text() eq $string] )
                           then $exptit:col/id($string)//t:titleStmt/t:title/text()
                           else if (matches($string, 'gn:'))  then exptit:getGeoNames($string)
                           else if (matches($string, '(LOC|INS)(\d+)(\w+)'))
                           then try {exptit:printTitle($apprest:collection-rootPlIn/id($string)//t:place)}
                           catch * {'no record'}
                           else $string
return
    <div class="row-fluid">
     <h4>The following {count($sameKey)} entities also share the <a href="{if (matches($string, 'gn:'))  then ('http://www.geonames.org/'||substring-after($string, 'gn:')) else concat($config:appUrl,'/',$string)}">{$value}</a> tag </h4>
                                      <div id="Samekeyword{$string}">
                                      <ul>{if (matches($string, '(\w{3})(\d+)(\w+)'))
                                            then apprest:referencesList($id, $sameKey, 'link')
                                               else  apprest:referencesList($id, $sameKey, 'name')
                                             }
                                             </ul>
                                             </div>

                        </div>
};

(:~returns items in a  list of results from a references lookup:)
declare function apprest:referencesList($id, $list, $mode as xs:string){

          for $hit in  $list

          let $strid := $hit/ancestor::t:TEI/@xml:id
          group by $stringid := string($strid)
          order by $stringid
      return
         <li class="nodot" xmlns="http://www.w3.org/1999/xhtml" >
         {if ($strid = $id) then ('here') else <a
          href="{concat('/',$stringid)}"
   >{exptit:printTitleID($stringid)}</a>} ({$stringid})
   <ul  class="nodot">
   {for $h in $hit
   let $n := $h/name()
   group by $name := $n
   order by $name
   return
   <li class="nodot">a <code xmlns="http://www.w3.org/1999/xhtml" >{$name}</code> element {count($h)} time{if(count($h) > 1) then 's' else ()}
   {let $ids := for $each in $h return
                      if ($h/ancestor::t:item/@xml:id)
                     then data($h/ancestor::t:item/@xml:id)
                     else if ($h/ancestor::t:msPart/@xml:id)
                      then data($h/ancestor::t:msPart/@xml:id) else ()
      return ' ' || string-join($ids, ', ')}
   </li>
   }
   </ul>
         </li>

};

declare function apprest:institutions(){
<form action="" class="form form-horizontal">
<div class="w3-container">
<label for="GoToRepo">go to repository list</label>
<a role="button" class="w3-button w3-button-secondary" id="loadrepositories">load</a>
<div class="input-group">
<select id="GoToRepo" class="w3-select w3-border">
</select>
<div class="input-group-w3-button"><button id="clickandgotoRepoID" class="w3-button w3-red" disabled="disabled">Go</button></div>
</div>
</div>
</form>
};

declare function apprest:catalogues(){
<form action="" class="form form-horizontal">
<div class="w3-container">
<label for="GoToCatalogue">go to catalogue list</label>
<a role="button" class="w3-button w3-button-secondary" id="loadcatalogues">load</a>
<div class="input-group">
<select id="GoToCatalogue" class="w3-select w3-border">
</select>
<div class="input-group-w3-button"><button id="clickandgotoCatalogueID" class="w3-button w3-red" disabled="disabled">Go</button></div>
</div>
</div>
<img id="loading" src="resources/Loading.gif" style="display: none;"></img>
<script type="application/javascript" src="resources/js/loadcatalogues.js"></script>
</form>
};

declare function apprest:namedentitiescorresps($this, $collection){
let $document := $this
let $id := string($this/@xml:id)
return

let $refs :=

for $r in (
$document//t:persName[not(ancestor::t:listPerson)][@ref],
$document//t:title[@ref],
$document//t:placeName[@ref],
$document//t:region[@ref],
$document//t:country[@ref],
$document//t:settlement[@ref],
$document//t:relation[@name eq 'saws:isAttributedToAuthor'])
return
if($r/@ref = ' ' or $r/@ref = '') then (<ref>no valid id</ref>)
else if($r[name() eq 'relation']) then <ref ref="{$r/@passive}"></ref>
else
                       <ref ref="{if (contains($r/@ref, '#')) then substring-before($r/@ref, '#') else string($r/@ref)}"></ref>
 let $corresps :=

for $r in $document//t:ref[@corresp]

                       return <ref ref="{if (contains($r/@corresp, '#')) then substring-before($r/@corresp, '#') else string($r/@corresp)}"></ref>
let $all := ($refs/@ref, $corresps/@ref)
for $namedEntity in config:distinct-values($all)
return
<div id="{$namedEntity}relations-all" class="hidden">
<div id="{$namedEntity}relations-content">
{apprest:AnyReferences($id, $namedEntity)}
</div>
</div>
};


(:~a list of items pointing to something:)
declare function apprest:AnyReferences($sourceid, $id as xs:string){
let $context := $apprest:collection-root
let $ref := apprest:WhatPointsHere($id, $context)
  return
<ul xmlns="http://www.w3.org/1999/xhtml" class="nodot"><head xmlns="http://www.w3.org/1999/xhtml" >This record, with ID: {string($id)} is mentioned by </head>
    {apprest:referencesList($sourceid, $ref, 'name')}

      </ul>
};

(:~searches an ID in a @corresp, @ref, <relation> and makes a list :)
declare function apprest:WhatPointsHereQuery($id as xs:string){
for $corr in ($exptit:col//t:*[ft:query(@corresp, $id)],
        $exptit:col//t:*[ft:query(@ref, $id)],
        $exptit:col//t:relation[ft:query(., $id)])
        order by ft:score($corr) descending
        return
            $corr

            };

(: ~          used by apprest.xqm and timeline.xqm :)
declare function apprest:WhatPointsHere($id as xs:string, $c){
            let $witnesses := $c//t:witness[@corresp eq $id]
let $placeNames := $c//t:placeName[@ref eq $id]
let $persNames := $c//t:persName[@ref eq $id]
let $ref := $c//t:ref[@corresp eq $id]
let $titles := $c//t:title[@ref eq $id]
let $settlement := $c//t:settlement[@ref eq $id]
let $region := $c//t:region[@ref eq $id]
let $country := $c//t:country[@ref eq $id]
let $active := $c//t:relation[@active eq $id]
let $passive := $c//t:relation[@passive eq $id]
let $locus := $c//t:locus[@corresp eq $id]
let $allrefs := ($witnesses,
        $placeNames,
        $persNames,
        $ref,
        $titles,
        $settlement,
        $region,
        $country,
        $active,
        $passive,
        $locus)
return
for $corr in $allrefs
        return
            $corr

            };



(:~collects bibliographical information for zotero metadata:)
declare function apprest:bibdata ($id, $collection)  as node()*{
let $file := $exptit:col//t:TEI/id($id)
return

(:here I cannot use for the title the javascript titles.js because the content is not exposed:)
<bibl>
{
let $ids := ($file//t:revisionDesc/t:change/@who| $file//t:fileDesc/t:titleStmt/t:editor[not(contains(@role,  'generalEditor'))]/@key| $file//t:respStmt/@xml:id)
let $cleanids := for $i in distinct-values($ids) return replace($i, '#', '')
for $author in distinct-values($cleanids)
let $score := count($file//t:revisionDesc/t:change[@who eq $author]) + count($file//t:fileDesc/t:titleStmt/t:editor[@key eq $author]) + (if($file//t:editor[@key eq $author][@role eq 'cataloguer' or @role eq 'editor']) then 100 else 0)
order by $score descending
                return
<author>{editors:editorKey(string($author))}</author>
}
<title level="a">{exptit:printTitleID($id)}</title>
<title level="j">{$file//t:fileDesc/t:publicationStmt/t:publisher/text()}</title>
<date type="accessed"> [Accessed: {format-date(current-date(), "[Y0001]-[M01]-[D01]")}] </date>
{let $time := max($file//t:revisionDesc/t:change/xs:date(@when))
return
<date type="lastModified">(Last Modified: {format-date($time, '[Y0001]-[M01]-[D01]')}) </date>
}
<idno type="url">
{($config:appUrl||'/' || $collection||'/' ||$id)}
</idno>

</bibl>
};
declare function apprest:bibdata ($id, $this, $collection, $sha)  as node()*{
let $file := $this
return

(:here I cannot use for the title the javascript titles.js because the content is not exposed:)
<bibl>
{
let $ids := ($file//t:revisionDesc/t:change/@who| $file//t:fileDesc/t:titleStmt/t:editor/@key| $file//t:respStmt/@xml:id)
let $cleanids := for $i in distinct-values($ids) return replace($i, '#', '')
for $author in distinct-values($cleanids)
let $count := count($file//t:revisionDesc/t:change[@who eq $author])
order by $count descending
                return
<author>{editors:editorKey(string($author))}</author>
}
<title level="a">{exptit:printTitleID($id)}</title>
<title level="j">{$this//t:fileDesc/t:publicationStmt/t:publisher/text()}</title>
<date type="accessed"> [Accessed: {format-date(current-date(), "[Y0001]-[M01]-[D01]")}] </date>
{let $time := max($file//t:revisionDesc/t:change/xs:date(@when))
return
<date type="lastModified">(Last Modified: {format-date($time, '[Y0001]-[M01]-[D01]')}) </date>
}
<idno type="url">
{($config:appUrl||'/permanent/' ||$sha || '/' || $collection||'/' ||$id || '/main')}
</idno>

</bibl>
};

(:~prints the revision information in buttons:)
declare function apprest:bottom($this, $collection) {
let $document := $this
let $id := string($this/@xml:id)
let $app:bibdata := apprest:bibdata($id, $collection)
return
<div class="w3-container">
<div class="w3-row">

            <button onclick="document.getElementById('cite').style.display='block'" class="w3-button w3-grey" style="vertical-align: top;width:300;">Suggested citation</button>
            <button onclick="document.getElementById('revision').style.display='block'" class="w3-button w3-grey" style="vertical-align: top;width:300;">Revision history</button>
              <button onclick="document.getElementById('att').style.display='block'" class="w3-button w3-grey" style="vertical-align: top;width:300;">Attribution of the content</button>
              <button onclick="document.getElementById('perm').style.display='block'" class="w3-button w3-grey" style="vertical-align: top;width:300;">Permalinks</button>
              <button onclick="document.getElementById('rdf').style.display='block'" class="w3-button w3-grey" style="vertical-align: top;width:300;">RDF/VoID</button>
<div id="cite" class="w3-modal w3-card w3-margin">
 <div class="w3-modal-content">

                    <header class="w3-container w3-red">
                        <span onclick="document.getElementById('cite').style.display='none'" class="w3-button w3-display-topright">CLOSE</span>
                        <h4>Suggested citation of this record</h4>
                    </header>
                    <div class="w3-container" id="citationString">
<p>{for $a in $app:bibdata//author/text()  return ($a|| ', ')} ʻ{$app:bibdata//title[@level eq 'a']/text()} {if (contains($this//t:revisionDesc/t:change, 'PEMM')) then ' (originally prepared for The Princeton Ethiopian, Eritrean, and Egyptian Miracles of Mary (PEMM) project)' else ()} {if ($this//t:additional//t:source/t:listBibl[@type eq 'catalogue']/t:bibl/t:ptr[@target eq 'bm:BmWebsite']) then ' (based on a historical catalogue and considerably enriched by the Bm team)' else if ($this//t:additional//t:source/t:listBibl[@type eq 'catalogue']) then ' (encoded from the catalogue)' else ()}ʼ, in
<i>{($app:bibdata//title[@level eq 'j']/text() || ' ')}</i> {$app:bibdata//date[@type eq 'lastModified']/text()}
<a href="{$app:bibdata/idno/text()}">{$app:bibdata/idno[@type eq 'url']/text()}</a> {$app:bibdata//date[@type eq 'accessed']/text()}</p>
<p>To cite a precise version, please, click on load permalinks and to the desired version (<a href="/pid.html">see documentation on permalinks</a>), then import the metadata or copy the below, with the correct link.</p>
</div>
</div>
</div>


<div id="revision" class="w3-modal w3-card w3-margin">
 <div class="w3-modal-content">

                    <header class="w3-container w3-red">
                        <span onclick="document.getElementById('revision').style.display='none'" class="w3-button w3-display-topright">CLOSE</span>
                        <h4>Revision history</h4>
                    </header>
                    <ul>
                {for $change in $document//t:revisionDesc/t:change
                let $time := $change/@when
                let $author := editors:editorKey(string($change/@who))
                let $collection :=  $change/ancestor::t:TEI//t:collection
                let $ES := if(contains($change/text(), 'Ethio-SPaRe team photographed the manuscript')) then () else if (xs:date($time) ge xs:date('2016-05-10')) then () else if  (not(starts-with($collection/text(), 'Ethio-')))  then () else ' in Ethio-SPaRe '
                let $PEMM := if(contains($change/text(), '(PEMM')) then ' for the PEMM project ' else ()
                order by $time descending
                return
                <li>
                {(if (contains($change/text(), 'Ethio-SPaRe team photographed the manuscript')) then () else <span property="http://purl.org/dc/elements/1.1/contributor">{$author}</span>),
                (' ' || $change/text() || $ES || $PEMM), (if (contains($change/text(), '(PEMM')) then () else ' on ' ||  format-date($time, '[D].[M].[Y]'))}
                </li>
                }

    </ul>
</div>
</div>


 <div id="att" class="w3-modal w3-card w3-margin">
 <div class="w3-modal-content">

                    <header class="w3-container w3-red">
                        <span onclick="document.getElementById('att').style.display='none'" class="w3-button w3-display-topright">CLOSE</span>
                        <h4>Attribution of the content</h4>
                    </header>
                        <div>
                {for $respStmt in $document//t:titleStmt/t:respStmt
                let $action := string-join($respStmt/t:resp, ' ')
              return
              if($respStmt/t:persName) then
            (   let $authors :=
                            for $p in $respStmt/t:persName
                                return
                                    (if($p/@ref) then editors:editorKey(string($p/@ref)) else $p) || (if($p/@from or $p/@to) then (' ('||'from '||$p/@from || ' to ' ||$p/@to||')') else ())


                order by $action descending
                return
                <p>
                {($action || ' by ' || string-join($authors, ', '))}
                </p>)
                else <p>{$respStmt/t:name/text() || ', ' || $respStmt/t:resp/text()}</p>

                }
                </div>
</div>
</div>

<div id="perm" class="w3-modal w3-card w3-margin">
 <div class="w3-modal-content">

                    <header class="w3-container w3-red">
                        <span onclick="document.getElementById('perm').style.display='none'" class="w3-button w3-display-topright">CLOSE</span>
                        <h4>Permalinks</h4>
                    </header>
                      <div id="permanentIDs{$document//t:TEI/@xml:id}" style="max-height:250px;overflow:auto"
   data-path="{viewItem:capitalize-first(substring-after(base-uri($document), '/db/apps/expanded/'))}"
   data-id="{$document//t:TEI/@xml:id}" data-type="{viewItem:capitalize-first($collection)}"><a class="w3-btn" id="LoadPermanentIDs{$document//t:TEI/@xml:id}">Load permalinks to see the revision history on GitHub</a></div>

   <script  type="text/javascript" src="resources/js/permanentID.js"></script>
</div>
</div>

<div id="rdf" class="w3-modal w3-card w3-margin">
 <div class="w3-modal-content">

                    <header class="w3-container w3-red">
                        <span onclick="document.getElementById('revision').style.display='none'" class="w3-button w3-display-topright">CLOSE</span>
                        <h4>RDF and VoID</h4>
                    </header>
                    <div>This page contains RDFa.
   <a href="/rdf/{$collection}/{$document//t:TEI/@xml:id}.rdf">RDF+XML</a> graph of this resource. Alternate representations available via <a href="/api/void/{$document//t:TEI/@xml:id}">VoID</a></div>

</div>
</div>

        </div>
             {if($document//t:editionStmt/node()) then <div class="w3-panel w3-card-4 w3-padding w3-margin w3-red " >{string:tei2string($document//t:editionStmt/node())}</div> else ()}
     {if($document//t:availability/node()) then <div class="w3-panel w3-card-4 w3-padding w3-margin w3-white " >{string:tei2string($document//t:availability/node())}</div> else ()}
     </div>

};

(:~prints the revision informations:)
declare function apprest:authors($this, $collection) {
let $document := $this
let $id := string($this/@xml:id)
let $app:bibdata := apprest:bibdata($id, $collection)
return

<div class="w3-container" id="citations" style="word-break:break-word;">
<div class="w3-third" id="citation">
<div class="w3-panel w3-card-4 w3-padding w3-margin  w3-gray  w3-small" >

<h4>Suggested Citation of this record</h4>
<div class="w3-container" id="citationString">
<p>{for $a in $app:bibdata//author/text()  return ($a|| ', ')} ʻ{$app:bibdata//title[@level eq 'a']/text()} {if (contains($this//t:revisionDesc/t:change, 'PEMM')) then ' (originally prepared for The Princeton Ethiopian, Eritrean, and Egyptian Miracles of Mary (PEMM) project)' else ()} {if ($this//t:additional//t:source/t:listBibl[@type eq 'catalogue']/t:bibl/t:ptr[@target eq 'bm:BmWebsite']) then ' (based on a historical catalogue and considerably enriched by the Bm team)' else if ($this//t:additional//t:source/t:listBibl[@type eq 'catalogue']) then ' (encoded from the catalogue)' else ()}ʼ, in
<i>{($app:bibdata//title[@level eq 'j']/text() || ' ')}</i> {$app:bibdata//date[@type eq 'lastModified']/text()}
<a href="{$app:bibdata/idno/text()}">{$app:bibdata/idno[@type eq 'url']/text()}</a> {$app:bibdata//date[@type eq 'accessed']/text()}</p>
<p>To cite a precise version, please, click on load permalinks and to the desired version (<a href="/pid.html">see documentation on permalinks</a>), then import the metadata or copy the below, with the correct link.</p>

</div>
</div>


</div>
<div class="w3-third" id="revisions">
<div class="w3-panel w3-card-4 w3-padding w3-margin  w3-gray w3-small" >
<h4>Revisions of the data</h4>
                <ul>
                {for $change in $document//t:revisionDesc/t:change
                let $time := $change/@when
                let $author := editors:editorKey(string($change/@who))
                let $collection :=  $change/ancestor::t:TEI//t:collection
                let $ES := if(contains($change/text(), 'Ethio-SPaRe team photographed the manuscript')) then () else if (xs:date($time) ge xs:date('2016-05-10')) then () else if  (not(starts-with($collection/text(), 'Ethio-')))  then () else ' in Ethio-SPaRe '
                order by $time descending
                return
                <li>
                {(if (contains($change/text(), 'Ethio-SPaRe team photographed the manuscript')) then () else <span property="http://purl.org/dc/elements/1.1/contributor">{$author}</span>),
                (' ' || $change/text() || $ES || ' on ' ||  format-date($time, '[D].[M].[Y]'))}
                </li>
                }

    </ul>
    </div>
    </div>
    <div class=" w3-third" id="attributions">
<div class="w3-panel w3-card-4 w3-padding w3-margin w3-gray w3-small" >
<h4>Attributions of the contents</h4>
                <div>
                {for $respStmt in $document//t:titleStmt/t:respStmt
                let $action := string-join($respStmt/t:resp, ' ')
              return
              if($respStmt/t:persName) then
            (   let $authors :=
                            for $p in $respStmt/t:persName
                                return
                                    (if($p/@ref) then editors:editorKey(string($p/@ref)) else $p) || (if($p/@from or $p/@to) then (' ('||'from '||$p/@from || ' to ' ||$p/@to||')') else ())


                order by $action descending
                return
                <p>
                {($action || ' by ' || string-join($authors, ', '))}
                </p>)
                else <p>{$respStmt/t:name/text() || ', ' || $respStmt/t:resp/text()}</p>

                }
                </div>
    </div>
     {if($document//t:editionStmt/node()) then <div class="w3-panel w3-card-4 w3-padding w3-margin w3-red " >{string:tei2string($document//t:editionStmt/node())}</div> else ()}
     {if($document//t:availability/node()) then <div class="w3-panel w3-card-4 w3-padding w3-margin w3-white " >{string:tei2string($document//t:availability/node())}</div> else ()}
    </div>
    </div>

};


(:~prints the revision informations:)
declare function apprest:authorsSHA($id, $this, $collection, $sha) {
let $document := $this
let $app:bibdata := apprest:bibdata($id, $this, $collection, $sha)
return

<div class="w3-container " id="citations">
<div class="w3-third" id="citation">
<div class="w3-panel w3-card-4 w3-padding w3-margin  w3-gray  w3-small" >

<h4>Suggested Citation of this record</h4>
<div class="w3-container" id="citationString">
<p>{for $a in $app:bibdata//author/text()  return ($a|| ', ')} ʻ{$app:bibdata//title[@level eq 'a']/text()} {if (contains($this//t:revisionDesc/t:change, 'PEMM')) then ' (originally prepared for The Princeton Ethiopian, Eritrean, and Egyptian Miracles of Mary (PEMM) project)' else ()} {if ($this//t:additional//t:source/t:listBibl[@type eq 'catalogue']/t:bibl/t:ptr[@target eq 'bm:BmWebsite']) then ' (based on a historical catalogue and considerably enriched by the Bm team)' else if ($this//t:additional//t:source/t:listBibl[@type eq 'catalogue']) then ' (encoded from the catalogue)' else ()}ʼ, in
<i>{($app:bibdata//title[@level eq 'j']/text() || ' ')}</i> {$app:bibdata//date[@type eq 'lastModified']/text()}
<a href="{$app:bibdata/idno/text()}">{$app:bibdata/idno[@type eq 'url']/text()}</a> {$app:bibdata//date[@type eq 'accessed']/text()}</p>
<p>To cite a precise version, please, click on load permalinks and to the desired version (<a href="/pid.html">see documentation on permalinks</a>), then import the metadata or copy the below, with the correct link.</p>

</div>
</div>


</div>
<div class="w3-third" id="revisions">
<div class="w3-panel w3-card-4 w3-padding w3-margin  w3-gray w3-small" >
<h4>Revisions of the data</h4>
                <ul>
                {for $change in $document//t:revisionDesc/t:change
                let $time := $change/@when
                let $author := editors:editorKey(string($change/@who))
                order by $time descending
                return
                <li>
                {<span property="http://purl.org/dc/elements/1.1/contributor">{$author}</span>,
                (' ' || viewItem:TEI2HTML(string($change)) || ' on ' ||  format-date($time, '[D].[M].[Y]'))}
                </li>
                }

    </ul>
    </div>
    </div>
    <div class=" w3-third" id="attributions">
<div class="w3-panel w3-card-4 w3-padding w3-margin w3-gray w3-small" >
<h4>Attributions of the contents</h4>
<div>
                {for $respStmt in $document//t:titleStmt/t:respStmt
                let $task := $respStmt/t:resp
                let $action := string-join($respStmt/t:resp, ' ')
              return
              if($respStmt/t:persName) then
            (   let $authors :=
                            for $p in $respStmt/t:persName
                                return
                                    (if($p/@ref) then editors:editorKey(string($p/@ref)) else $p) || (if($p/@from or $p/@to) then (' ('||'from '||$p/@from || ' to ' ||$p/@to||')') else ())


                order by $action descending
                return
                <ul class="nodot">
                {for $task in $respStmt
                return
                <li class="nodot">{$action || ' by ' || string-join($authors, ', ')}</li>
                }
                </ul>)
               else
               for $task in $respStmt
                return
                <li class="nodot">{$respStmt/t:name/text() || ', ' || $respStmt/t:resp/text()}</li>
                }

                </div>
          </div>
     {if($document//t:editionStmt/node()) then <div class="w3-panel w3-card-4 w3-padding w3-margin w3-red " >{string:tei2string($document//t:editionStmt/node())}</div> else ()}
     {if($document//t:availability/node()) then <div class="w3-panel w3-card-4 w3-padding w3-margin w3-white " >{string:tei2string($document//t:availability/node())}</div> else ()}
    </div>
    </div>

};




(:~ produces the lists and updates the filters :)
declare
%templates:default('start', 1)
%templates:default("per-page", 20)
function apprest:listrest($type,
$collection, $parameters as map(*), $params) {
let $keywords := $parameters('key')
let $names := $parameters('mainname')
let $languages := $parameters('lang')
let $dateRange := $parameters('date')
let $clavisType := $parameters('clavistype')
let $contentProvider := $parameters('cp')
let $clavisID := $parameters('clavisID')
let $CAeID := $parameters('CAeID')
let $numberOfP := $parameters('numberOfParts')
let $Pheight := $parameters('height')
let $Pwidth := $parameters('width')
let $Pdepth := $parameters('depth')
let $PcolumnsNum := $parameters('columnsNum')
let $Ptmargin := $parameters('tmargin')
let $Pbmargin := $parameters('bmargin')
let $Prmargin := $parameters('rmargin')
let $Plmargin := $parameters('lmargin')
let $Pintercolumn := $parameters('intercolumn')
let $Pfolia := $parameters('folia')
let $Pqn := $parameters('qn')
let $Pqcn := $parameters('qcn')
let $PwL := $parameters('wL')
let $Pscript := $parameters('script')
let $Pscribe := $parameters('scribe')
let $Pdonor := $parameters('donor')
let $Ppatron := $parameters('patron')
let $Powner := $parameters('owner')
let $Pbinder := $parameters('binder')
let $PparchmentMaker := $parameters('parchmentMaker')
let $PobjectType := $parameters('objectType')
let $Pmaterial := $parameters('material')
let $Pbmaterial := $parameters('bmaterial')
let $Pcontent := $parameters('contents')
let $PorigPlace := $parameters('origPlace')
let $Ptabot := $parameters('tabot')
let $Pplacetype := $parameters('placetype')
let $Pmss := $parameters('mss')
let $Pauthors := $parameters('authors')
let $Poccupation := $parameters('occupation')
let $Pfaith := $parameters('faith')
let $Pgender := $parameters('gender')
let $Pperiod := $parameters('period')
let $Prestorations := $parameters('restorations')
let $Pbindingtype := $parameters('bindingtype')
let $Pcountry := $parameters('country')
let $Psettlement := $parameters('settlement')

let $allnames :=  if($names = '') then () else
            switch($collection)
                case 'manuscripts' return apprest:ListQueryParam-rest($names, 't:msIdentifier//t:idno', 'any', 'search')
                case 'institutions' return apprest:ListQueryParam-rest($names, 't:place/t:placeName', 'any', 'search')
                case 'places' return apprest:ListQueryParam-rest($names, 't:place/t:placeName', 'any', 'search')
                case 'persons' return apprest:ListQueryParam-rest($names, 't:person/t:persName', 'any', 'search')
                case 'works' return apprest:ListQueryParam-rest($names, 't:title', 'any', 'search')
                case 'narratives' return apprest:ListQueryParam-rest($names, 't:title', 'any', 'search')
           default return ()

let $key := if($keywords = '') then () else
            switch($collection)
                case 'narratives' return ()
                case 'institutions' return apprest:ListQueryParam-rest($keywords, 't:ab[@type eq "tabot"]/t:persName/@ref', 'any', 'list')
                case 'places' return apprest:ListQueryParam-rest($keywords, 't:place/@type', 'any', 'list')
(:                case 'persons' return apprest:ListQueryParam-rest($keywords, 't:occupation/@type', 'any', 'list'):)
           default return apprest:ListQueryParam-rest($keywords, 't:term/@key', 'any', 'list')

let $ContentPr := if ($contentProvider = '') then () else
                    switch($contentProvider)
                        case 'BM' return "[not(starts-with(@xml:id, 'EMIP'))][not(starts-with(@xml:id, 'EMML'))][not(starts-with(@xml:id, 'ES'))][not(contains(@xml:id, 'IHA'))][not(starts-with(@xml:id, 'GG'))]"
                        case 'EMML' return "[starts-with(@xml:id, 'EMML')]"
                        case 'EMIP' return "[starts-with(@xml:id, 'EMIP')]"
                        case 'ES' return "[starts-with(@xml:id, 'ES')]"
                        case 'IHA' return "[contains(@xml:id, 'IHA')]"
                        case 'GG' return "[starts-with(@xml:id, 'GG')]"
                        default return ''

let $CaeIDs := if($CAeID = '') then () else "[contains(@xml:id, '"||string(format-number($CAeID, '0000')) ||"') and not(ends-with(@xml:id, 'IHA'))]"
let $ClavisIDs :=
                if(($clavisID = '') and ($clavisType = '')) then ()
                      else if(($clavisID = '') and (matches($clavisType, '\w+'))) then "[descendant::t:bibl[@type eq '"||$clavisType||"']]"
                      else  "[descendant::t:bibl[@type eq '"||$clavisType||"'][t:citedRange eq '"||$clavisID||"']]"

let $languages := if($languages = '') then () else  apprest:ListQueryParam-rest($languages, 't:language/@ident', 'any', 'list')

let $dR :=  if ($dateRange)
                then (
                let $range := $dateRange
                let $from := substring-before($dateRange, ',')
                let $to := substring-after($dateRange, ',')
                return
                if ($dateRange = '0,2000')
                then ()
                else
                "[descendant::t:origDate
                [xs:integer((if (contains(@notBefore, '-')) then (substring-before(@notBefore, '-')) else @notBefore)[. !='']) ge " || $from || " or
                xs:integer((if (contains(@notAfter, '-')) then    (substring-before(@notAfter, '-')) else    @notAfter)[. != '']) ge " ||$from||"]
                [xs:integer((if (contains(@notBefore, '-')) then (substring-before(@notBefore, '-')) else @notBefore)[. !='']) le " || $to || " or
                xs:integer((if (contains(@notAfter, '-')) then (substring-before(@notAfter, '-')) else @notAfter)[. != '']) le " ||$to ||"]]" ) else ()

let $nOfP := if(empty($numberOfP) or $numberOfP = '') then () else '[count(descendant::t:msPart) ge ' || $numberOfP || ']'
let $opl := if(empty($PorigPlace) or $PorigPlace = '') then () else apprest:ListQueryParam-rest($PorigPlace, 't:origPlace/t:placeName/@ref', 'any', 'search')
let $height :=   if(empty($Pheight) or $Pheight = '') then () else (app:paramrange('height', 'height'))
let $width :=  if(empty($Pwidth) or $Pwidth = '') then () else  (app:paramrange('width', 'width'))
let $depth :=  if(empty($Pdepth) or $Pdepth = '') then () else  (app:paramrange('depth', 'depth'))
let $marginTop :=  if(empty($Ptmargin) or $Ptmargin = '') then () else  (app:paramrange('tmargin', "dimension[@type eq 'margin']/t:dim[@type eq 'top']"))
let $marginBot := if(empty($Pbmargin) or $Pbmargin = '') then () else (app:paramrange('bmargin', "dimension[@type eq 'margin']/t:dim[@type eq 'bottom']"))
let $marginR :=  if(empty($Prmargin) or $Prmargin = '') then () else (app:paramrange('rmargin', "dimension[@type eq 'margin']/t:dim[@type eq 'right']"))
let $marginL :=  if(empty($Plmargin) or $Plmargin = '') then () else (app:paramrange('lmargin', "dimension[@type eq 'margin']/t:dim[@type eq 'left']"))
let $marginIntercolumn :=  if(empty($Pintercolumn) or $Pintercolumn = '') then () else (app:paramrange('intercolumn', "dimension[@type eq 'margin']/t:dim[@type eq 'intercolumn']"))
let $support :=  if(empty($PobjectType) or $PobjectType = '') then () else apprest:ListQueryParam-rest($PobjectType, 't:objectDesc/@form', 'any', 'search')
let $material := if(empty($Pmaterial) or $Pmaterial = '') then () else apprest:ListQueryParam-rest($Pmaterial, 't:support/t:material/@key', 'any', 'search')
let $bmaterial := if(empty($Pbmaterial) or $Pbmaterial = '') then () else apprest:ListQueryParam-rest($Pbmaterial, "t:decoNote[@type eq 'bindingMaterial']/t:material/@key", 'any', 'search')
let $scripts := if(empty($Pscript) or $Pscript = '') then () else apprest:ListQueryParam-rest($Pscript, "t:handNote/@script", 'any',  'search')
let $scribes := if(empty($Pscribe) or $Pscribe = '') then () else apprest:ListQueryParam-rest($Pscribe, "t:persName[@role eq 'scribe']/@ref", 'any',  'search')
let $donors := if(empty($Pdonor) or $Pdonor = '') then () else apprest:ListQueryParam-rest($Pdonor, "t:persName[@role eq 'donor']/@ref", 'any',  'search')
let $patrons := if(empty($Ppatron) or $Ppatron = '') then () else apprest:ListQueryParam-rest($Ppatron, "t:persName[@role eq 'patron']/@ref", 'any', 'search')
let $owners := if(empty($Powner) or $Powner = '') then () else apprest:ListQueryParam-rest($Powner, "t:persName[@role eq 'owner']/@ref", 'any',  'search')
let $parchmentMakers := if(empty($PparchmentMaker) or $PparchmentMaker = '') then () else apprest:ListQueryParam-rest($PparchmentMaker, "t:persName[@role eq 'parchmentMaker']/@ref", 'any',  'search')
let $binders := if(empty($Pbinder) or $Pbinder = '') then () else apprest:ListQueryParam-rest($Pbinder, "t:persName[@role eq 'binder']/@ref", 'any',  'search')
let $contents := if(empty($Pcontent) or $Pcontent= '') then () else apprest:ListQueryParam-rest($Pcontent, "t:title/@ref", 'any', 'search')
let $tabots := if(empty($Ptabot) or $Ptabot= '') then () else apprest:ListQueryParam-rest($Ptabot, "t:ab[@type eq 'tabot']//t:*/@*", 'any', 'search')
let $placetypess := if(empty($Pplacetype) or $Pplacetype= '') then () else apprest:ListQueryParam-rest($Pplacetype, "t:place/@type", 'any', 'search')
let $Allauthors := if(empty($Pauthors) or $Pauthors= '') then () else apprest:ListQueryParam-rest($Pauthors, "t:relation[(@name eq 'saws:isAttributedToAuthor') or (@name eq 'dcterms:creator')]/@passive", 'any', 'search')
let $placetypess := if(empty($Pplacetype) or $Pplacetype= '') then () else apprest:ListQueryParam-rest($Pplacetype, "t:place/@type", 'any', 'search')
let $occupations := if(empty($Poccupation) or $Poccupation= '') then () else apprest:ListQueryParam-rest($Poccupation, "t:occupation/@type", 'any', 'search')
let $faiths := if(empty($Pfaith) or $Pfaith= '') then () else apprest:ListQueryParam-rest($Pfaith, "t:faith/@type", 'any', 'search')
let $genders := if(empty($Pgender) or $Pgender= '') then () else apprest:ListQueryParam-rest($Pgender, "t:person/@sex", 'any', 'list')
let $periods := if(empty($Pperiod) or $Pperiod= '') then () else apprest:ListQueryParam-rest($Pperiod, "t:term/@key", 'any', 'search')
let $restorationss := if(empty($Prestorations) or $Prestorations= '') then () else apprest:ListQueryParam-rest($Prestorations, "t:custEvent/@subtype", 'any', 'list')
let $bindingtype := if(empty($Pbindingtype) or $Pbindingtype= '') then () else apprest:ListQueryParam-rest($Pbindingtype, "t:binding/@contemporary", 'any', 'search')
let $countries := if(empty($Pcountry) or $Pcountry = '') then () else apprest:ListQueryParam-rest($Pcountry, 't:country/@ref', 'any', 'range')
let $settlements := if(empty($Psettlement) or $Psettlement = '') then () else apprest:ListQueryParam-rest($Psettlement, 't:settlement/@ref', 'any', 'range')

let $leaves :=  if(empty($Pfolia) or $Pfolia = '') then () else
                (let $min := substring-before($Pfolia, ',')
                let $max := substring-after($Pfolia, ',')
                return
                if ($Pfolia = '1,1000')
                then ()
                else if (empty($Pfolia))
                then ()
                else
                "[descendant::t:extent/t:measure[@unit='leaf'][not(@type)][xs:integer(.) ge "||$min|| ' ][ xs:integer(.)  le ' || $max ||"]]"
               )
let $wL := if(empty($PwL) or $PwL = '') then () else (
                let $min := substring-before($PwL, ',')
                let $max := substring-after($PwL, ',')
                return
                if ($PwL = '1,100')
                then ()
                else if (empty($PwL))
                then ()
                else
                "[descendant::t:layout[@writtenLines ge "||$min|| '][@writtenLines  le ' || $max ||"]]"
               )
let $quires :=  if(empty($Pqn) or $Pqn = '' or $Pqn = '1,100')
                then () else (
                let $min := substring-before($Pqn, ',')
                let $max := substring-after($Pqn, ',')
                return
                "[descendant::t:extent/t:measure[@unit eq 'quire'][not(@type)][not(.='')][xs:integer(.) ge "||$min|| ' ][xs:integer(.)  le ' || $max ||"]]")
let $quiresComp :=  if(empty($Pqcn) or $Pqcn = '' or $Pqcn = '1,40')
                     then () else  (
                   let $min := substring-before($Pqcn, ',')
                let $max := substring-after($Pqcn, ',')
                return
                "[descendant::t:dim[ancestor::t:collation][@unit eq 'leaf'][not(.='')][. ge "||$min|| ' ][.  le ' || $max ||"]]")


let $allMssFilters := concat($allnames, $support, $opl, $material, $bmaterial, $scripts, $scribes, $donors, $patrons, $owners, $parchmentMakers,
             $binders, $contents, $leaves, $wL,  $quires, $quiresComp,
            $height, $width, $depth, $marginTop, $marginBot, $marginL, $marginR, $marginIntercolumn, $restorationss, $bindingtype)

let $path := switch($type)
                case 'catalogue' return
                      let $catal := "bm:"||$collection
                      let $all := $apprest:collection-rootMS//t:listBibl[@type eq 'catalogue'][descendant::t:ptr[@target eq $catal]]/ancestor::t:TEI
                      let $string := ('$all'|| $key || $languages || $dR || $allMssFilters)
                      return
                util:eval($string)
                case 'repo' return
                    let $all := $apprest:collection-rootMS//t:repository[@ref eq $collection ]/ancestor::t:TEI
                    let $string := ('$all'|| $key || $languages || $dR || $allMssFilters)
                    return   util:eval($string)
                default return
                        (
                        if ($collection = 'places')
                                    then ("$apprest:collection-rootPlIn//t:TEI"  || $countries|| $settlements||$allnames || $key || $languages|| $dR || $tabots||$placetypess )

                       else if ($collection = 'works')
                                    then ("$apprest:collection-rootW//t:TEI"  ||$CaeIDs|| $allnames ||$ContentPr   || $key || $languages|| $ClavisIDs || $dR ||$Allauthors || $periods  )

                       else if ($collection = 'persons')
                                    then ("$apprest:collection-rootPr//t:TEI"   || $allnames||$ContentPr   || $key || $dR ||$occupations || $faiths || $genders  )


                        else let $col := switch2:collection($collection)
                        return $col||"//t:TEI" || $countries|| $settlements|| $allnames ||$ContentPr  || $key || $languages|| $dR || $ClavisIDs || $nOfP  || $allMssFilters ||$Allauthors|| $tabots||$placetypess
                       )

let $context := switch($type)
                case 'catalogue' return ('$apprest:collection-rootMS//t:listBibl[@type eq "catalogue"][descendant::t:ptr[@target eq "bm:'||$collection||'"]]/ancestor::t:TEI' || $key || $languages || $dR || $allMssFilters)
                case 'repo' return  ('$apprest:collection-rootMS//t:repository[@ref eq "'|| $collection||'" ]/ancestor::t:TEI' || $key || $languages || $dR || $allMssFilters)
                default return $path

let $results := switch($type)
                case 'catalogue' return $path
                case 'repo' return $path
                default return util:eval($path)

let $hits := for $item in $results
                             let $recordid := string($item/@xml:id)
                            let $recordtype := string($item/@type)
                            let $sorting :=
                                        if(matches($recordid, 'IHA')) then ('9'||substring($recordid, 4, 4))
                                         else if(matches($recordid, '\w{3}\d+')) then substring($recordid, 4, 4)
                                            else substring($recordid, 0, 3)
                              order by $sorting
                             return
                                       $item
(:let $test2 := console:log($context) :)
 return
            map {
                      'hits' : $hits,
                      'collection' : $collection,
                      'query' : $context
                      }
};


declare function apprest:ListQueryParam-rest($parameter, $context, $mode, $function){
let $keys :=
        if ($parameter = 'keyword')
        then (
        for $k in $parameter

        let $ks := doc($config:data-rootA || '/taxonomy.xml')//t:catDesc[text() eq $k]/following-sibling::t:*/t:catDesc/text()
        let $nestedCats := for $n in $ks return $n
            return
            if ($nestedCats >= 2) then (replace($k, '#', ' ') || ' OR ' || string-join($nestedCats, ' OR ')) else (replace($k, '#', ' '))
        )
        else(
            for $k in $parameter
            return
            replace($k, '#', ' ')
            )

       return
       if ($function = 'list')
       then
     let $all :=  for $k in $keys
       return
       "descendant::" || $context || " eq '" || $k ||"'"
       return
      "[" || string-join($all, ' or ') || "]"
       else if ($function = 'range')
       then
     let $all :=  for $k in $keys
       return
        "descendant::" || $context || "[. = '" || $k ||"']"
       return
      "[" || string-join($all, ' or ') || "]"
       else
       (:search:)
       let $limit := for $k in $parameter
            return
       "descendant::" || $context ||  "[ft:query(.,'" || $k ||"')] "
       return
       "[" || string-join($limit, ' or ') || "]"


};


(:~ the form in the list view which provides also the filters :)
declare function apprest:searchFilter-rest($collection, $model as map(*)) {
let $items-info := $model('hits')
let $context := $model('query')
let $evalContext := util:eval($context)
let $onchange := 'if (this.value) window.location.href=this.value'
return

<form action="" class="w3-container" data-hint="Any of these search filter implies that by searching a certain feature you do not only exclude those who have another value for that, but also all those items which do not carry the information at all.">
<div class="w3-container"><label for="mainname">name</label>
                <input id="mainname" name="mainname" class="w3-input w3-border"></input></div>
<div class="w3-container w3-padding w3-margin-left w3-margin-right">
                <label for="dates">Dates range</label><br/>
                <input id="dates" type="text" class="span2"
                name="date-range"
                data-slider-min="0"
                data-slider-max="2000"
                data-slider-step="10"
                data-slider-value="[0,2000]"/>
                <script type="text/javascript">
                {"$('#dates').bootstrapSlider({});"}
                </script>
            </div>
 {if($items-info = <start/>) then (
(:no selection done yet, provide index value:)
<div class="w3-container" data-hint="On a filtered search you will get for relevant values also the break down in numbers of items with that language">
<label for="language">languages </label>
<select multiple="multiple" name="language" id="language" class="w3-select w3-border">
                            {$evalContext/$app:range-lookup('TEIlanguageIdent', '', function($key, $count) {<option value="{$key}">{$apprest:languages//t:item[@xml:id eq $key]/text()} ({$count[1]})</option>}, 1000)}
                            </select>
                            </div>
(:app:formcontrol('language',  $evalContext//t:language/@ident, 'true', 'values', $context):)
) else
(:form selectors relative to query:)
apprest:formcontrol('language', 'language', $items-info//t:language/@ident, 'true', 'values', $context)}
 <div class="w3-container">
    <label>Data provenance</label>
                <select name="cp" class="w3-select w3-border">
                    <option value="">all</option>
                     <option value="BM">Beta maṣāḥǝft</option>
                    <option value="ES">Ethio-SPaRe</option>
                    <option value="EMML">Ethiopian Manuscript Microfilm Library</option>
                    <option value="GG">Gunda Gunde</option>
                    <option value="EMIP">Ethiopic Manuscript Imaging Project</option>
                    <option value="IHA">Islam in the Horn of Africa</option>
                  </select>
     </div>
{ switch($collection)
case 'narratives' return ()
case 'works' return (
<div class="w3-container" data-hint="Enter here the numeric identifier in Clavis Aethiopica">
    <label>Clavis Aethiopica ID</label>
    <input class="w3-input w3-border" type="number" name="CAeID"/>
</div>
,
<div class="w3-container">
    <label>Other Clavis ID</label>
                <select name="clavistype" class="w3-select w3-border">
                <option value="">no selection</option>
<option value="BHG">BHG</option>
<option value="BHO">BHO</option>
<option value="CAVT">CAVT</option>
<option value="CANT">CANT</option>
<option value="CC">CC</option>
<option value="CPG">CPG</option>
<option value="KRZ">KRZ</option>
<option value="H">H</option>
<option value="PEMM">PEMM</option>

</select>
<input class="w3-input w3-border" type="number" name="clavisID"/>
</div>,
if($items-info = <start/>) then (
(:no selection done yet, provide index value:)
<div class="w3-container" data-hint="On a filtered search you will get for relevant values also the break down in numbers of items with that keyword">
<label for="keyword">keywords </label>
<select multiple="multiple" name="keyword" id="keyword" class="w3-select w3-border">
{$evalContext/$app:range-lookup('termkey', '', function($key, $count) {<option value="{$key}">{exptit:printTitleID($key)} ({$count[1]})</option>},1000)}
</select>
</div>

) else
(:form selectors relative to query:)
apprest:formcontrol('keyword','keyword', $items-info//t:term/@key, 'true', 'titles', $context),
<div class="w3-container">
    <div class="w3-panel w3-red w3-leftbar" style="font-size: smaller;">The period filter will search items which have the appropriate keyword assigned. It is equivalent to selecting that keyword. It is not equivalent to selecting a date range, because in that case we will search the dates, regardless of the attribution or not of one of the period keywords.</div>

    <label>periods</label>
                <select name="period" class="w3-select w3-border">
                <option value="">no selection</option>
<option value="Aks">Aksumite (300-700)</option>
<option value="Paks1">Post-aksumite I (1200-1433)</option>
<option value="Paks2">Post-aksumite II (1434-1632)</option>
<option value="Gon">Gondarine (1632-1769)</option>
<option value="ZaMa">Zamana Masāfǝnt (1769-1855)</option>
<option value="MoPe">Modern Period (1855-1974)</option>
</select>

</div>,
<div class="w3-container">
                            <input class="w3-check" type="checkbox" value="authors" data-context="{$context}"/> Authors<br/>
                              </div>,
                              <script type="text/javascript" src="resources/js/filtersRest.js"></script>,
             <img id="loadingform" src="resources/images/giphy.gif" style="display: none; width: 20%;"/>,
             <div id="AddFilters"/>
)
case 'places' return
if($items-info = <start/>) then (
(:no selection done yet, provide index value:)
<div class="w3-container" data-hint="On a filtered search you will get for relevant values also the break down in numbers of items with that keyword">
<label for="keyword">keywords </label>
<select multiple="multiple" name="keyword" id="keyword" class="w3-select w3-border">
{$evalContext/$app:range-lookup('termkey', '', function($key, $count) {<option value="{$key}">{exptit:printTitleID($key)} ({$count[1]})</option>},1000)}
</select>
</div>,

<div class="w3-container" data-hint="On a filtered search you will get for relevant values also the break down in numbers of items with that place type">
<label for="placetype">place type </label>
<select multiple="multiple" name="placetype" id="placetype" class="w3-select w3-border">
{$evalContext/$app:range-lookup('placetype', '', function($key, $count) {<option value="{$key}">{if(matches($key, '\s' )) then (let $titles:= for $k in tokenize($key, '\s') return exptit:printTitleID($k) return string-join($titles, ', ')) else exptit:printTitleID($key)} ({$count[1]}) </option>},1000)}
</select>
</div>,
<div class="w3-container" data-hint="On a filtered search you will get for relevant values also the break down in numbers of items with that place type">
<label for="placetype">country </label>
<select multiple="multiple" name="country" id="country" class="w3-select w3-border">
{$evalContext/$app:range-lookup('countryref', '', function($key, $count) {<option value="{$key}">{exptit:printTitleID($key)} ({$count[1]}) </option>},1000)}
</select>
</div>,
<div class="w3-container" data-hint="On a filtered search you will get for relevant values also the break down in numbers of items with that place type">
<label for="placetype">settlement </label>
<select multiple="multiple" name="settlement" id="settlement" class="w3-select w3-border">
{$evalContext/$app:range-lookup('settlref', '', function($key, $count) {<option value="{$key}">{exptit:printTitleID($key)} ({$count[1]}) </option>},1000)}
</select>
</div>,
<div class="w3-container">
                            <input  class="w3-check" type="checkbox" value="tabots" data-context="{$context}"/> Tābots<br/>
                              </div>,
                              <script type="text/javascript" src="resources/js/filtersRest.js"></script>,
             <img id="loadingform" src="resources/images/giphy.gif" style="display: none; width: 20%;"/>,
             <div id="AddFilters"/>
) else
(:form selectors relative to query:)
(<div class="w3-container">
<label for="keyword">keywords </label>
<select multiple="multiple" name="keyword" id="keyword" class="w3-select w3-border">
{$evalContext/$app:range-lookup('termkey', '', function($key, $count) {<option value="{$key}">{exptit:printTitleID($key)} ({$count[1]})</option>}, 1000)}
</select>
</div>,
apprest:formcontrol('place type','placetype', $items-info//t:place/@type, 'true', 'values', $context),
apprest:formcontrol('state','country', $items-info//t:country/@ref, 'true', 'values', $context),
apprest:formcontrol('settlement','settlement', $items-info//t:settlement/@ref, 'true', 'values', $context),
<div class="w3-container">
                            <input  class="w3-check" type="checkbox" value="tabots" data-context="{$context}"/> Tābots<br/>
                              </div>,
                              <script type="text/javascript" src="resources/js/filtersRest.js"></script>,
             <img id="loadingform" src="resources/images/giphy.gif" style="display: none; width: 20%;"/>,
             <div id="AddFilters"/>
)

case 'institutions' return
if($items-info = <start/>) then (
(:no selection done yet, provide index value:)
<div class="w3-container" data-hint="On a filtered search you will get for relevant values also the break down in numbers of items with that keyword">
<label for="keyword">keywords </label>
<select multiple="multiple" name="keyword" id="keyword" class="w3-select w3-border">
{$evalContext/$app:range-lookup('termkey', '', function($key, $count) {<option value="{$key}">{exptit:printTitleID($key)} ({$count[1]})</option>},1000)}
</select>
</div>,
<div class="w3-container" data-hint="On a filtered search you will get for relevant values also the break down in numbers of items with that place type">
<label for="placetype">place type </label>
<select multiple="multiple" name="placetype" id="placetype" class="w3-select w3-border">
{$evalContext/$app:range-lookup('placetype', '', function($key, $count) {<option value="{$key}">{exptit:printTitleID($key)} ({$count[1]})</option>},1000)}
</select>
</div>,
<div class="w3-container" data-hint="On a filtered search you will get for relevant values also the break down in numbers of items with that place type">
<label for="placetype">country </label>
<select multiple="multiple" name="country" id="country" class="w3-select w3-border">
{$evalContext/$app:range-lookup('countryref', '', function($key, $count) {<option value="{$key}">{exptit:printTitleID($key)} ({$count[1]}) </option>},1000)}
</select>
</div>,
<div class="w3-container" data-hint="On a filtered search you will get for relevant values also the break down in numbers of items with that place type">
<label for="placetype">settlement </label>
<select multiple="multiple" name="settlement" id="settlement" class="w3-select w3-border">
{$evalContext/$app:range-lookup('settlref', '', function($key, $count) {<option value="{$key}">{exptit:printTitleID($key)}  ({$count[1]})</option>},1000)}
</select>
</div>,
<div class="w3-container">
                            <input  class="w3-check" type="checkbox" value="tabots" data-context="{$context}"/> Tābots<br/>
                              </div>,
                              <script type="text/javascript" src="resources/js/filtersRest.js"></script>,
             <img id="loadingform" src="resources/images/giphy.gif" style="display: none; width: 20%;"/>,
             <div id="AddFilters"/>)
 else(
(:form selectors relative to query:)
apprest:formcontrol('keyword','keyword', $items-info//t:term/@key, 'true', 'titles', $context),
apprest:formcontrol('place type','placetype', $items-info//t:place/@type, 'true', 'values', $context),
apprest:formcontrol('state','country', $items-info//t:country/@ref, 'true', 'values', $context),
apprest:formcontrol('settlement','settlement', $items-info//t:settlement/@ref, 'true', 'values', $context),
<div class="w3-container">
                            <input  class="w3-check" type="checkbox" value="tabots" data-context="{$context}"/> Tābots<br/>
                              </div>,
                              <script type="text/javascript" src="resources/js/filtersRest.js"></script>,
             <img id="loadingform" src="resources/images/giphy.gif" style="display: none; width: 20%;"/>,
             <div id="AddFilters"/>
)
case 'persons' return
(
if($items-info = <start/>) then (
(:no selection done yet, provide index value:)
<div class="w3-container">
<label for="keyword">keywords </label>
<select multiple="multiple" name="keyword" id="keyword" class="w3-select w3-border">
{$evalContext/$app:range-lookup('termkey', '', function($key, $count) {<option value="{$key}">{exptit:printTitleID($key)} ({$count[1]})</option>},1000)}
</select>
</div>,
<div class="w3-container">
<label for="occupation">occupation types </label>
<select multiple="multiple" name="occupation" id="occupation" class="w3-select w3-border">
{$evalContext/$app:range-lookup('occtype', '', function($key, $count) {<option value="{$key}">{$key} </option>},1000)}
</select>
</div>,
<div class="w3-container">
<label for="faith">faiths </label>
<select multiple="multiple" name="faith" id="faith" class="w3-select w3-border">
{$evalContext/$app:range-lookup('faithtype', '', function($key, $count) {<option value="{$key}">{$key} </option>},1000)}
</select>
</div>
) else
(:form selectors relative to query:)
(
apprest:formcontrol('keyword','keyword', $items-info//t:term/@key, 'true', 'titles', $context),
apprest:formcontrol('occupation type','occupation', $items-info//t:occupation/@type, 'true', 'titles', $context),
apprest:formcontrol('faith','faith', $items-info//t:faith/@type, 'true', 'titles', $context),
<div class="w3-container">
            <input  class="w3-check" type="checkbox" name="gender" value="1">Male</input>
            <input   class="w3-check" type="checkbox" name="gender" value="2">Female</input>
    </div>
))
(:default is a manuscript related list view, catalogue, institutions or general view:)
default return
(
if($items-info = <start/>) then (
(:no selection done yet, provide index value:)
<div class="w3-container">
<label for="keyword">keywords </label>
<select multiple="multiple" name="keyword" id="keyword" class="w3-select w3-border">
{$evalContext/$app:range-lookup('termkey', '', function($key, $count) {<option value="{$key}">{exptit:printTitleID($key)} ({$count[1]})</option>},1000)}
</select>
</div>
) else
(:form selectors relative to query:)
apprest:formcontrol('keyword','keyword', $items-info//t:term/@key, 'true', 'titles', $context),
            <div class="w3-container">
            <label for="numberOfP">Limit by minimum number of codicological units</label>
            <input id="numberOfP" class="w3-input w3-border" type="number" name="numberOfParts"></input>
            </div>,
           <div class="w3-container w3-margin-left w3-margin-right">
        <label for="heightslider">Height (mm)</label><br/>
            <input id="heightslider" type="number" class="span2" name="height" data-slider-min="1" data-slider-max="1000" data-slider-step="10" data-slider-value="[1,1000]"/>
            <script type="text/javascript">
                {"$('#heightslider').bootstrapSlider({});"}
            </script>
</div>,
           <div class="w3-container w3-margin-left w3-margin-right">
        <label for="widthslider">Width (mm)</label><br/>
            <input id="widthslider" type="number" class="span2" name="width" data-slider-min="1" data-slider-max="1000" data-slider-step="10" data-slider-value="[1,1000]"/>
            <script type="text/javascript">
                {"$('#widthslider').bootstrapSlider({});"}
            </script></div>,
           <div class="w3-container w3-margin-left w3-margin-right">
        <label for="lmargin">Columns per page</label><br/>
                <input id="NumberOfcolumns" type="number" class="span2" name="columnsNum" data-slider-min="1" data-slider-max="20" data-slider-step="1" data-slider-value="[1,20]"/>
                <script type="text/javascript">
                    {"$('#NumberOfcolumns').bootstrapSlider({});"}
                </script></div>,
           <div class="w3-container w3-margin-left w3-margin-right">
           <label  for="tmargin">Top Margin</label><br/>
                <input id="tMslider" type="number" class="span2" name="tmargin" data-slider-min="1" data-slider-max="100" data-slider-step="1" data-slider-value="[1,100]"/>
                <script type="text/javascript">
                    {"$('#tMslider').bootstrapSlider({});"}
                </script>
        </div>,
           <div class="w3-container w3-margin-left w3-margin-right">
        <label for="bmargin">Bottom Margin</label><br/>
                <input id="bMslider" type="number" class="span2" name="bmargin" data-slider-min="1" data-slider-max="100" data-slider-step="1" data-slider-value="[1,100]"/>
                <script type="text/javascript">
                    {"$('#bMslider').bootstrapSlider({});"}
                </script>
        </div>,
           <div class="w3-container w3-margin-left w3-margin-right">
        <label for="rmargin">Right Margin</label><br/>
                <input id="rMslider" type="number" class="span2" name="rmargin" data-slider-min="1" data-slider-max="100" data-slider-step="1" data-slider-value="[1,100]"/>
                <script type="text/javascript">
                    {"$('#rMslider').bootstrapSlider({});"}
                </script>
        </div>,
           <div class="w3-container w3-margin-left w3-margin-right">
        <label for="lmargin">Left Margin</label><br/>
                <input id="lMslider" type="number" class="span2" name="lmargin" data-slider-min="1" data-slider-max="100" data-slider-step="1" data-slider-value="[1,100]"/>
                <script type="text/javascript">
                    {"$('#lMslider').bootstrapSlider({});"}
                </script>
        </div>,
           <div class="w3-container w3-margin-left w3-margin-right">
        <label  for="intercolumn">Intercolumn</label><br/>
                    <input id="lntercolumnslider" type="number" class="span2" name="intercolumn" data-slider-min="1" data-slider-max="100" data-slider-step="1" data-slider-value="[1,100]"/>
                    <script type="text/javascript">
                        {"$('#lntercolumnslider').bootstrapSlider({});"}
                    </script>
                </div>
        ,
           <div class="w3-container w3-margin-left w3-margin-right">
<label  for="folia">Number of Leafs</label><br/>
            <input id="folia" type="text" class="span2" name="folia" data-slider-min="1.0" data-slider-max="1000.0" data-slider-step="1.0" data-slider-value="[1.0,1000.0]"/>
            <script type="text/javascript">
                {"$('#folia').bootstrapSlider({});"}
            </script>
</div>,
            <div class="w3-container w3-margin-left w3-margin-right">
<label for="qn">Number of quires</label><br/>
                <input id="quires" type="text" class="span2" name="qn" data-slider-min="1" data-slider-max="100" data-slider-step="1" data-slider-value="[1,100]"/>
            <script type="text/javascript">
                {"$('#quires').bootstrapSlider({});"}
            </script>

</div>,
            <div class="w3-container w3-margin-left w3-margin-right">
 <label for="qcn">Quires Composition</label><br/>
                <input id="quiresComp" type="text" class="span2" name="qcn" data-slider-min="1" data-slider-max="40" data-slider-step="1" data-slider-value="[1,40]"/>
            <script type="text/javascript">
                {"$('#quiresComp').bootstrapSlider({});"}
            </script>
</div>,
            <div class="w3-container w3-margin-left w3-margin-right">
<label  for="wL">Number of written lines</label><br/>
            <input id="writtenLines" type="text" class="span2" name="wL" data-slider-min="1" data-slider-max="100" data-slider-step="1" data-slider-value="[1,100]"/>
            <script type="text/javascript">
                {"$('#writtenLines').bootstrapSlider({});"}
            </script>
</div>,

            <div class="w3-container w3-margin-left w3-margin-right">
<label  for="restorations">Restorations</label><br/>
                     <select class="w3-select w3-border" id="restorations" type="text" name="restorations" >
            <option value="">no selection</option>
            <option value="ancient">ancient</option>
            <option value="modern">modern</option>
            <option value="none">none</option>
            </select>
            <small>Only few manuscripts carry this information, selecting this filter you are searching only in those.</small>
</div>,
            <div class="w3-container">
                            <input  class="w3-check" type="checkbox" value="origPlace" data-context="{$context}"/> place of origin<br/>
                            <input  class="w3-check" type="checkbox" value="script" data-context="{$context}"/> script<br/>
                            <input  class="w3-check" type="checkbox" value="scribe" data-context="{$context}"/> scribe<br/>
                            <input  class="w3-check" type="checkbox" value="donor" data-context="{$context}"/> donor<br/>
                            <input  class="w3-check" type="checkbox" value="patron" data-context="{$context}"/> patron<br/>
                            <input  class="w3-check" type="checkbox" value="owner" data-context="{$context}"/> owner<br/>
                            <input  class="w3-check" type="checkbox" value="binder" data-context="{$context}"/> binder<br/>
                            <input  class="w3-check" type="checkbox" value="parchmentMaker" data-context="{$context}"/> parchment maker<br/>
                            <input  class="w3-check" type="checkbox" value="objectType" data-context="{$context}"/> object type<br/>
                            <input  class="w3-check" type="checkbox" value="material" data-context="{$context}"/> material<br/>
                            <input  class="w3-check" type="checkbox" value="bmaterial" data-context="{$context}"/> binding material<br/>
                              <input  class="w3-check" type="checkbox" value="bindingtype" data-context="{$context}"/> original binding<br/>

                            {if((count($items-info) lt 1050) and $items-info/node() ) then (<input type="checkbox"  class="w3-check" value="contents" data-context="{$context}"/>, 'contents',<br/>)
                            else (<div class="w3-panel w3-red w3-leftbar">You will be able to get a filter by contents for a selection of manuscripts with less than 1000 items.</div>)}
                            </div>,
            <script type="text/javascript" src="resources/js/filtersRest.js"></script>,
             <img id="loadingform" src="resources/images/giphy.gif" style="display: none; width: 20%;"/>,
             <div id="AddFilters"/>)}
            <div class="w3-container w3-margin-bottom w3-margin-top">
            <div class="w3-bar ">
                <button type="submit" class="w3-bar-item w3-button w3-red"><i class="fa fa-search" aria-hidden="true"></i>
</button>
                    <a href="/{$collection}/list" class="w3-bar-item w3-button w3-gray"><i class="fa fa-th-list" aria-hidden="true"></i></a>
                <a href="/as.html" role="button" class="w3-bar-item w3-button w3-red"><i class="fa fa-cog" aria-hidden="true"/></a>
                </div>
                </div>
</form>
};

(:~ pagination element for search results :)
declare function apprest:paginate-rest($model as map(*), $parameters as map(*), $start as xs:int, $per-page as xs:int, $min-hits as xs:int, $max-pages as xs:int) {
       <div class="w3-bar w3-border w3-round">{

    if ($min-hits < 0 or count($model("hits")) >= $min-hits) then
        let $count := xs:integer(ceiling(count($model("hits"))) div $per-page) + 1
        let $middle := ($max-pages + 1) idiv 2
        let $paramssingle := for $p in map:keys($parameters) let $key := switch($p) case 'key' return 'keyword' default return $p let $value := $parameters($p) return if($value='') then () else (string($key) || '=' ||$parameters($p) )
        let $params :=string-join($paramssingle, '&amp;')
        return (
            if ($start = 1) then (
                <a class="w3-button w3-disabled"><i class="fa fa-fast-backward"></i></a>,
                <a class="w3-button w3-disabled"><i class="fa fa-backward"></i></a>
            ) else (
                    <a class="w3-button" href="?per-page={$per-page}&amp;start=1&amp;{$params}"><i class="fa fa-fast-backward"></i></a>
                ,
                    <a class="w3-button"  href="?per-page={$per-page}&amp;start={max( ($start - $per-page, 1 ) ) }&amp;{$params}"><i class="fa fa-backward"></i></a>

            ),
            let $startPage := xs:integer(ceiling($start div $per-page))
            let $lowerBound := max(($startPage - ($max-pages idiv 2), 1))
            let $upperBound := min(($lowerBound + $max-pages - 1, $count))
            let $lowerBound := max(($upperBound - $max-pages + 1, 1))
            for $i in $lowerBound to $upperBound
            return
                if ($i = ceiling($start div $per-page)) then
                    <a  class="w3-button" href="?per-page={$per-page}&amp;start={max( (($i - 1) * $per-page + 1, 1) )}&amp;{$params}">{$i}</a>
                else
                    <a class="w3-button"  href="?per-page={$per-page}&amp;start={max( (($i - 1) * $per-page + 1, 1)) }&amp;{$params}">{$i}</a>,
            if ($start + $per-page < count($model("hits"))) then (

                    <a class="w3-button"  href="?per-page={$per-page}&amp;start={$start + $per-page}&amp;{$params}"><i class="fa fa-forward"></i></a>
                ,
                <a class="w3-button"  href="?per-page={$per-page}&amp;start={max( (($count - 1) * $per-page + 1, 1))}&amp;{$params}"><i class="fa fa-fast-forward"></i></a>

            ) else (
                <a class="w3-button w3-disabled"><i class="fa fa-forward"></i></a>,
                <a class="w3-button w3-disabled"><i class="fa fa-fast-forward"></i></a>
            )
        ) else
            ()
            }
   <input id="perpagechange" type="number" class="w3-input w3-bar-item" name="per-page" placeholder="how many per page?"></input>
  { if($model("type") = 'text') then<a href="?per-page={count($model("hits"))}" class="w3-button w3-red w3-bar-item" id="fullText">See full text</a> else ()}

            </div>
};

(:~  builds the form control according to the data specification:)
declare function apprest:formcontrol($label as xs:string*, $nodeName as xs:string, $path, $group, $type, $context) {

if ($group = 'true')
then (
  let $values :=
  for $i in $path return
    if (contains($i, ' ')) then tokenize($i, ' ')
    else if ($i=' ' or $i='' ) then ()
    else apprest:trim(normalize-space($i))
                    let $nodes := config:distinct-values($values)

                    return <div class="w3-container">
                    <label for="{$nodeName}">{$label}s
                    <span class="badge">{count($nodes[. != ''][. != ' '])}</span>
                    </label>
                    {apprest:newselectors($nodeName, $path, $nodes, $type, $context)}
     </div>
     )
                else (
       apprest:newselectors($nodeName, $path, $path, $type, $context)
        )
};


(:~determins what the selectors for various form controls will look like, is called by app:formcontrol() :)
declare function apprest:newselectors($nodeName, $path, $nodes, $type, $context){
             <select multiple="multiple" name="{$nodeName}" id="{$nodeName}" class="w3-select w3-border">
            {

            if ($type = 'keywords') then (
                    for $group in $nodes/t:category[t:desc]
                    let $label := $group/t:desc/text()
                     let $rangeindexname := switch($label)
                    case 'Occupation' return 'occtype'
                    case 'Art Themes' return 'refcorresp'
                    case 'Additiones' return 'desctype'
                    case 'Place types' return 'placetype'
                    default return 'termkey'
                    return
                    for $n in $group//t:catDesc
                    let $id := $n/text()
                    let $title :=exptit:printTitleID($id)

                    let $facet := try{
                        $path/$app:range-lookup($rangeindexname, $id, function($key, $count){$count[2]}, 100)} catch*{($err:code || $err:description)}
                    let $fac := if($facet[1] ge 1) then $facet[1] else '0'
                    return
                       <option value="{$id}">{($title[1] ||' (' || $fac  ||')')}</option>
                                )

            else if ($type = 'name')
                            then (for $n in $nodes[. != ''][. != ' ']
                            let $id := string($n/@xml:id)
                            let $title := exptit:printTitleID($id)
                                               order by $id
                                               return

                                                <option value="{$id}" >{$title}</option>
                                          )
            else if ($type = 'rels')
                     then (

                 for $n in $nodes[. != ''][. != ' ']
                          let $title :=  exptit:printTitleID($n)
                            order by $title[1]
                             return

                             <option value="{$n}">{normalize-space(string-join($title))}</option>
                        )
             else if ($type = 'hierels')
             then (
             for $n in $nodes[. != ''][. != ' '][not(starts-with(.,'#'))]
             group by $work := if (contains($n, '#')) then (substring-before($n, '#')) else $n
                            order by $work
                                return
                                let $label :=
                                    try{
                                        if ($exptit:col/id($work))
                                        then exptit:printTitle($exptit:col/id($work))
                                        else $work}
(:                                        this has to stay because optgroup requires label and this cannot be computed from the javascript as in other places:)
                                    catch* {
                                        ('while trying to create a list for the filter ' ||$nodeName || ' I got '|| $err:code ||': '||$err:description || ' about ' || $work),
                                         $work}
                                return
                                if (count($n) = 1)
                                then <option value="{$work}">{exptit:printTitle($work)}</option>
                                else(
                                      <optgroup label="{$label}">

                    { for $subid in $n
                    return
                                        <option value="{$subid}">{
                                          if (contains($subid, '#')) then substring-after($subid, '#') else 'all'
                                         }</option>
                                         }


                                    </optgroup>)

                                    )
            else if ($type = 'institutions')
                      then (
                             let $institutions := collection($config:data-rootIn)//t:TEI/@xml:id
                                 for $institutionId in $nodes[. eq $institutions]
                            return

                            <option value="{$institutionId}" >{exptit:printTitle($institutionId)}</option>
                        )

            else if ($type = 'sex')
                     then (for $n in $nodes[. != ''][. != ' ']
                        let $key := replace(apprest:trim($n), '_', ' ')
                         order by $n
                         return
                             <option value="{string($key)}">{switch($key) case '1' return 'Male' default return 'Female'}</option>
                        )
            else(
            (: type is values :)
            for $n in $nodes[. != ''][. != ' ']
                let $thiskey := replace(apprest:trim($n), '_', ' ')
                let $title := if($nodeName = 'keyword' or $nodeName = "placetype"or $nodeName = "country"or $nodeName = "settlement") then exptit:printTitleID($thiskey)
                                        else if ($nodeName = 'language') then $app:languages//t:item[@xml:id eq $thiskey]/text()
                                        else $thiskey
                let $rangeindexname :=
                                        switch($nodeName)
                                        case 'relType' return 'relname'
                                        case 'language' return 'TEIlanguageIdent'
                                        case 'material' return 'materialkey'
                                        case 'bmaterial' return 'materialkey'
                                        case 'bindingtype' return 'bindingtype'
                                         case 'placetype' return 'placetype'
                                         case 'country' return 'countryref'
                                         case 'settlement' return 'settlref'
                                         case 'occupation' return 'occtype'
                                         case 'faith' return 'faithtype'
                                         case 'objectType' return 'form'
                                         default return 'termkey'
                 let $ctx := util:eval($context)
                 let $facet := if($nodeName = 'script')
                                          then ($app:util-index-lookup($ctx//@script, lower-case($thiskey), function($key, $count) {$count[2]}, 100, 'lucene-index' ))
                                          else ( $ctx/$app:range-lookup($rangeindexname, $thiskey, function($key, $count) {$count[2]}, 100))
                order by $n
                return

            <option value="{$thiskey}">{if($thiskey = 'Printedbook') then 'Printed Book'
             else $title} {(' ('||$facet[1]||')')}</option>
            )
            }
        </select>
};

(:~  given an id looks for all manuscripts containing it and returns a div with cards use by Slick for the Carousel view:)
 declare function apprest:compareMssFromForm($target-work as xs:string?) {

 let $MAINtit := exptit:printTitleID($target-work)
     return
 if($target-work = '') then ()
 else(
<h2>Compare manuscripts which contain <span>{$MAINtit}</span></h2>,

let $items := $apprest:collection-rootMS//t:msItem
let $Additems := $apprest:collection-rootMS//t:additions//t:item[descendant::t:title[@ref]]
let $matchingAddmss := $Additems//t:title[contains(@ref , $target-work)]
let $matchingConmss := $items/t:title[matches(@ref , $target-work)]
let $matchingmss := ($matchingConmss, $matchingAddmss)
let $ids := for $manuscript in $matchingmss return string(root($manuscript)/t:TEI/@xml:id)
return
if(count($matchingmss) = 0) then (<p class="lead">Oh no! Currently, none of the catalogued manuscripts contains a link to this work. You can still see the record in case you find there useful information.</p>,<a class="w3-button w3-red" href="{$target-work}"> Go to {$MAINtit}</a>) else
(
<p class="w3-panel w3-card-2">There are currently <span class="w3-tag w3-gray">{count($matchingmss)}</span> pointers to this work in <span class="w3-tag w3-gray">{count(distinct-values($ids))}</span> mss.</p>,
<div class="w3-bar">
  <button class="w3-bar-item w3-button" onclick="document.getElementById('mscomps').scrollBy(-200,0)">
<i class="fa fa-arrow-left"></i>
  </button>
  <button class="w3-bar-item w3-button w3-right" onclick="document.getElementById('mscomps').scrollBy(200,0)">
  <i class="fa fa-arrow-right"></i>
  </button>
</div>,
<div id="mscomps" class=" w3-container" style="overflow: auto; scroll-behavior: smooth;">
{
for $manuscript in $matchingmss
let $msid := string(root($manuscript)/t:TEI/@xml:id)
let $notbefores := for $nbef in root($manuscript)/t:TEI//@notBefore return number(substring($nbef, 1,4))
let $notafters := for $naft in root($manuscript)/t:TEI//@notBefore return number(substring($naft, 1,4))
let $minnotBefore := min($notbefores)
let $maxnotAfter := min($notafters)
order by $minnotBefore
return
let $all := distinct-values($msid)
for $one in $all return
<div class="w3-cell">
<div class="w3-card-2 w3-margin w3-padding" style="width:250px;word-wrap: break-word;" >

<header class="w3-red w3-padding">
<a href="{('/'||$msid)}">{$msid}</a>
({string($minnotBefore)}-{string($maxnotAfter)})</header>
<div class="w3-container" style="max-height:60vh; overflow-y:auto">
<ul class="nodot">
{for $msitem at $p in root($manuscript)/t:TEI//t:msItem
(:  store in a variable the ref in the title or nothing:)
let $title := if ($msitem/t:title[@ref]) then $msitem/t:title[1]/@ref else ''
let $placement := locus:placement($msitem)
order by $p
return
<li style="{if(matches($msitem/@xml:id, '\d+\.\d+\.\d+'))
then 'text-indent: 4%;'
else if(matches($msitem/@xml:id, '\d+\.\d+'))
then 'text-indent: 2%;' else ()}">
{string($msitem/@xml:id )}
{if($msitem/t:title/@type)
     then ( ' (' || string($msitem/t:title[1]/@type) || ')')
     else ()},
{if($title = $target-work) (:highlight the position of the currently selected work:)
    then <mark>
        <a  class="itemtitle" data-value="{$title}" href="{$title}">{$MAINtit}</a> {$placement}
        </mark>
        (:if there is no ref, take the text of the element title content:)
        else if ($msitem/t:title[not(@ref)]/text())
   then (normalize-space(string-join(string:tei2string($msitem/t:title/node()))), $placement)
    (:normally print the title of the referred item:)
else (
<span>
<a class="itemtitle" data-value="{$title}" href="{$title}">{
if($title = '') then <span class="w3-tag w3-red">{'no ref in title'}</span>
else try{exptit:printTitle($title)} catch * {$title}}</a>
{$placement}</span>
)
 }
 </li>
 }
</ul>
<ul class="nodot">
{for $additem at $p in root($manuscript)/t:TEI//t:additions//t:item[descendant::t:title[matches(@ref , $target-work)]]
(:  store in a variable the ref in the title or nothing:)
let $title := if ($additem//t:title[@ref]) then for $t in $additem//t:title/@ref return $t else ''
let $placement := locus:placement($additem)
order by $p
return
<li>
{string($additem/@xml:id )}
{if($additem/t:desc/@type)
     then ( ' (' || string($additem/t:desc/@type) || ')')
     else ()},
{for $t in $title
return if($t = $target-work) (:highlight the position of the currently selected work:)
    then <mark>
        <a  class="itemtitle" data-value="{$t}" href="{$t}">{$MAINtit}</a> {$placement}
        </mark>
        (:if there is no ref, take the text of the element title content:)
        else if ($additem/t:title[not(@ref)]/text())
   then (normalize-space(string-join(string:tei2string($additem/t:title/node()))), $placement)
    (:normally print the title of the referred item:)
else (   <span><a class="itemtitle" data-value="{$t}" href="{$t}">{if($t = '') then <span class="w3-tag w3-red">{'no ref in title'}</span> else try{exptit:printTitle($t)} catch * {$t}}</a> {$placement}</span>)
 }
 </li>
 }
</ul>
</div>

</div>
</div>}
</div>(:,
<div class="w3-container">{
let $hits := for $match in $matchingmss return root($match)/t:TEI
return
charts:chart($hits)
}</div>:)
))
};

(:~  given an id looks for all manuscripts containing it and returns a div with cards use by Slick for the Carousel view:)
 declare function apprest:compareMssFromlist($mss) {
if($mss = '') then ()  else(
    let $matchingmss := for $ms in tokenize($mss, ',')
                                    return
                                          if(starts-with($ms, 'LIT'))
                                          then (
                                         let $titselectMss:= $apprest:collection-rootMS//t:title[contains(@ref, $ms)]
                                         let $selectMss := $titselectMss[parent::t:msItem or ancestor::t:additions]
                                         for $sm in $selectMss
                                         let $ms := root($sm)
                                         group by $MS := $ms
                                         return $MS
                                          )
                                          else $apprest:collection-rootMS//id($ms)[self::t:TEI]
    return
    (<div class="msscomparison w3-container">
    {
        for $manuscript in $matchingmss
        let $msid := string($manuscript/@xml:id)
        let $minnotBefore := min($manuscript//@notBefore)
        let $maxnotAfter := min($manuscript//@notAfter)
        order by $minnotBefore
        return

                <div  class="w3-card-2 w3-margin">
                                    <header class="w3-red w3-padding">
<a href="{('/'||$msid)}">{exptit:printTitleID($msid)}</a>
                                        ({string($minnotBefore)}-{string($maxnotAfter)})
                                     </header>
                                    <div class="w3-container" style="max-height:60vh; overflow-y:auto">
                                        <ul class="nodot">
                                            {for $msitem at $p in $manuscript//t:msItem
                                            (:  store in a variable the ref in the title or nothing:)
                                            let $title := if ($msitem/t:title[@ref]) then $msitem/t:title[1]/@ref else ''
                                            let $placement :=  locus:placement($msitem)
                                            order by $p
                                            return
                                                    <li style="{if(matches($msitem/@xml:id, '\d+\.\d+\.\d+'))
                                                                            then 'text-indent: 4%;'
                                                                            else if(matches($msitem/@xml:id, '\d+\.\d+'))
                                                                            then 'text-indent: 2%;'
                                                                            else ()}">
                                                        {string($msitem/@xml:id )}
                                                        {if($msitem/t:title/@type)
                                                          then ( ' (' || string($msitem/t:title[1]/@type) || ')')
                                                            else ()}
                                                        {if ($msitem/t:title[not(@ref)]/text())
                                                          then (normalize-space(string-join(string:tei2string($msitem/t:title/node()))), $placement)
                                                          else ( <a class="itemtitle" data-value="{$title}" href="{$title}">
                                                                        {
                                                                                if($title = '')
                                                                                then <span class="w3-tag w3-red">{'no ref in title'}</span>
                                                                                 else (try{exptit:printTitle($title)} catch * {$title})
                                                                        }
                                                                     </a>,
                                                                     $placement
                                                                   )
                                                                   }
                                                      </li>
                                              }
                                         </ul>
                                         <ul class="nodot">
{for $additem at $p in root($manuscript)/t:TEI//t:additions//t:item
(:  store in a variable the ref in the title or nothing:)
let $title := if ($additem//t:title[@ref]) then for $t in $additem//t:title/@ref return $t else ''
let $placement := locus:placement($additem)
order by $p
return
<li>
{string($additem/@xml:id )}
{if($additem/t:desc/@type)
     then ( ' (' || string($additem/t:desc/@type) || ')')
     else ()},
{for $t in $title
return
if ($additem/t:title[not(@ref)]/text())
   then (normalize-space(string-join(string:tei2string($additem/t:title/node()))), $placement)
    (:normally print the title of the referred item:)
else (   <a class="itemtitle" data-value="{$t}" href="{$t}">{if($t = '') then <span class="w3-tag w3-red">{'no ref in title'}</span> else try{exptit:printTitle($t)} catch * {$t}}</a>, $placement)
 }
 </li>
 }
</ul>
                                     </div>

              </div>
              }

              </div>

)
)
};
