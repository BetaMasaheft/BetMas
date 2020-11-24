xquery version "3.0" encoding "UTF-8";

(:~
 : This module contains functions printing indexes and lists extracted from the data which are not list of resources
 : @author Pietro Liuzzo 
 :)

module namespace indexesNE="https://www.betamasaheft.uni-hamburg.de/BetMas/indexesNE";
import module namespace config="https://www.betamasaheft.uni-hamburg.de/BetMas/config" at "xmldb:exist:///db/apps/BetMas/modules/config.xqm";
import module namespace titles="https://www.betamasaheft.uni-hamburg.de/BetMas/titles" at "xmldb:exist:///db/apps/BetMas/modules/titles.xqm";
import module namespace string = "https://www.betamasaheft.uni-hamburg.de/BetMas/string" at "xmldb:exist:///db/apps/BetMas/modules/tei2string.xqm";
import module namespace charts = "https://www.betamasaheft.uni-hamburg.de/BetMas/charts" at "xmldb:exist:///db/apps/BetMas/modules/charts.xqm";
import module namespace switch ="https://www.betamasaheft.uni-hamburg.de/BetMas/switch2" at "xmldb:exist:///db/apps/BetMas/modules/switch2.xqm";

declare namespace t="http://www.tei-c.org/ns/1.0";
declare namespace templates="http://exist-db.org/xquery/templates" ;


declare
    %templates:default("collection", "")
    %templates:default("entity", "")
    %templates:default("pointer", "")
function indexesNE:placeNames ($node as node(), $model as map(*),  $collection as xs:string,$entity as xs:string, $pointer as xs:string*) {
   let $coll := switch2:collectionVarValTit($collection)
   let $Pointer := if($pointer = '') then "[@ref]" else "[@ref eq '"||$pointer||"']"
   let $entityRef := if($entity='') then '' else '/id($entity)'
   let $path := $coll||$entityRef||'//t:placeName'||$Pointer 
   let $places := util:eval($path)
let $placeIDS := config:distinct-values($places/@ref)
    return
   map {
                    "hits" : $placeIDS,
                    "type" : 'indexes'

                }

     };
     
     
declare
    %templates:default("collection", "")
    %templates:default("entity", "")
    %templates:default("pointer", "")
function indexesNE:persNames ($node as node(), $model as map(*),  $collection as xs:string,$entity as xs:string, $pointer as xs:string*) {
   let $coll := switch2:collectionVarValTit($collection)
   let $Pointer := if($pointer = '') then "[@ref]" else "[@ref eq '"||$pointer||"']"
   let $entityRef := if($entity='') then '' else '/id($entity)'
   let $path := $coll||$entityRef||'//t:persName'||$Pointer 
   let $persons := util:eval($path)
let $persIDS := config:distinct-values($persons/@ref)
    return
   map {
                    "hits" : $persIDS[.!='PRS00000'][.!='PRS0000'],
                    "type" : 'indexes'

                }

     };
     
     declare function indexesNE:placeNameForm($node as node(), $model as map(*)){
   <form xmlns="http://www.w3.org/1999/xhtml"  action="" class="w3-container">
   
      <div  class="w3-container w3-margin-bottom">
                               <small class="form-text text-muted">enter a Beta maṣāḥǝft, Pleiades or Wikidata identifier</small><br/>
                                <input class="w3-input w3-border" name="pointer" placeholder="LOC / INS / pleiades: / wd:"></input>
                                </div>
                                <div  class="w3-container w3-margin-bottom">
                                 <small class="form-text text-muted">Select one collections</small><br/>
                                    <select name="collection" class="w3-select w3-border">
            <option value="all">all</option>
            <option value="mss">Manuscripts</option>
            <option value="work">Works</option>
            <option value="pers">Persons</option>
            <option value="place">Places</option>
            <option value="ins">Repositories</option>
            <option value="auth">Authority Files</option>
            </select>
                                 </div>
                                 <div class="w3-container w3-margin-bottom">
                                <div class="w3-bar">
                                 <button type="submit" class="w3-bar-item w3-button w3-red">
                                 <i class="fa fa-filter" aria-hidden="true"></i></button>
    
    <a href="/IndexPlaces" role="button" class="w3-bar-item w3-button w3-gray"><i class="fa fa-th-list" aria-hidden="true"></i></a></div>
   </div>
   </form>
   };
   
   
     declare function indexesNE:persNameForm($node as node(), $model as map(*)){
   <form xmlns="http://www.w3.org/1999/xhtml"  action="" class="w3-container">
   
      <div  class="w3-container  w3-margin-bottom">
                               <small >enter a Beta maṣāḥǝft or Wikidata identifier</small><br/>
                                <input class="w3-input w3-border" name="pointer" placeholder="PRS / wd:"></input>
                                </div><div class="w3-container w3-margin-bottom">
                                 <small>Select one collections</small><br/>
                                    <select name="collection" class="w3-select w3-border" >
            <option value="all">all</option>
            <option value="mss">Manuscripts</option>
            <option value="work">Works</option>
            <option value="pers">Persons</option>
            <option value="place">Places</option>
            <option value="ins">Repositories</option>
            <option value="auth">Authority Files</option>
            </select>
                                 </div>
                                <div class="w3-container w3-margin-bottom">
                                <div class="w3-bar">
                                 <button type="submit" class="w3-bar-item w3-button w3-red">
                                 <i class="fa fa-filter" aria-hidden="true"></i></button>
    
    <a href="/IndexPersons" role="button" class="w3-bar-item w3-button w3-gray"><i class="fa fa-th-list" aria-hidden="true"></i></a></div>
   </div></form>
   };
     
declare
%templates:wrap
    %templates:default('start', 1)
    %templates:default("per-page", 10)
    function indexesNE:placeNamesRes($node as node(), $model as map(*), $start as xs:integer, $per-page as xs:integer){

for $target at $p in subsequence($model("hits"), $start, $per-page)
let $ptrs := $titles:collection-root//t:placeName[@ref eq $target]
let $count := count($ptrs)
return
<div class="w3-container w3-margin">
<div id="{$target}" class="w3-col" style="width:15%">
    <a href="/{$target}" class="MainTitle" data-value="{$target}">{$target}</a> 
    has been marked up <span class="badge">{$count}</span> times in the selected collections.
    </div>
<div class="w3-rest">
<div class="w3-container">
<div class="w3-half w3-padding">
<ul class="nodot">
    {    
   for $citingentity in $ptrs
   let $stringR := string(root($citingentity)/t:TEI/@xml:id)

   group by $root :=    $stringR 
    return
     <li style="margin-bottom:20pt">in <a href="/{$root}" class="MainTitle" data-value="{$root}">{$root}</a> as
     <ol>
     {for $ptr in $citingentity
     return
     <li>{if($ptr/text()) then $ptr/text() else 'pointer only'}</li>
     }</ol>
     </li>
    }
    </ul>
    </div>
    <div class="w3-half w3-padding">
    {charts:pieAttestations($target, 'placeName')}
    </div>
    </div>
    </div>
    </div>
};

declare
%templates:wrap
    %templates:default('start', 1)
    %templates:default("per-page", 10)
    function indexesNE:persNamesRes($node as node(), $model as map(*), $start as xs:integer, $per-page as xs:integer){

for $target at $p in subsequence($model("hits"), $start, $per-page)
let $ptrs := $titles:collection-root//t:persName[@ref eq $target]
let $count := count($ptrs)
return
<div class="w3-margin">
    <div id="{$target}" class="w3-col" style="width:15%">
    <a href="/{$target}" class="MainTitle" data-value="{$target}">{$target}</a> 
    has been marked up <span class="badge">{$count}</span> times in the selected collections.
    </div>
<div class="w3-rest">
<div class="w3-container">
<div class="w3-half w3-padding">
<ul class="nodot">
    {    
   for $citingentity in $ptrs
   let $stringR := string(root($citingentity)/t:TEI/@xml:id)

   group by $root :=    $stringR 
    return
     <li style="margin-bottom:20pt">in <a href="/{$root}" class="MainTitle" data-value="{$root}">{$root}</a> as
     <ol>
     {for $ptr in $citingentity
     return
     <li>{if($ptr/text()) then $ptr/text() else 'pointer only'}</li>
     }</ol>
     </li>
    }
    </ul>
    </div>
    <div class="w3-half w3-padding">
    {charts:pieAttestations($target, 'persName')}
    </div>
    </div>
    </div>
    </div>
};