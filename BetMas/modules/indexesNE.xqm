xquery version "3.0" encoding "UTF-8";

(:~
 : This module contains functions printing indexes and lists extracted from the data which are not list of resources
 : @author Pietro Liuzzo <pietro.liuzzo@uni-hamburg.de'>
 :)

module namespace indexesNE="https://www.betamasaheft.uni-hamburg.de/BetMas/indexesNE";
import module namespace config="https://www.betamasaheft.uni-hamburg.de/BetMas/config" at "xmldb:exist:///db/apps/BetMas/modules/config.xqm";
import module namespace titles="https://www.betamasaheft.uni-hamburg.de/BetMas/titles" at "xmldb:exist:///db/apps/BetMas/modules/titles.xqm";
import module namespace string = "https://www.betamasaheft.uni-hamburg.de/BetMas/string" at "xmldb:exist:///db/apps/BetMas/modules/tei2string.xqm";
import module namespace charts = "https://www.betamasaheft.uni-hamburg.de/BetMas/charts" at "xmldb:exist:///db/apps/BetMas/modules/charts.xqm";

declare namespace t="http://www.tei-c.org/ns/1.0";
declare namespace templates="http://exist-db.org/xquery/templates" ;


declare
    %templates:default("collection", "")
    %templates:default("entity", "")
    %templates:default("pointer", "")
function indexesNE:placeNames ($node as node(), $model as map(*),  $collection as xs:string,$entity as xs:string, $pointer as xs:string*) {
   let $coll := switch($collection)
   case'all' return '$config:collection-root'
   case 'mss' return '$config:collection-rootMS'
   case 'work' return '$config:collection-rootW'
   case 'auth' return '$config:collection-rootA'
   case 'pers' return '$config:collection-rootPr'
   case 'place' return '$config:collection-rootPl'
   case 'ins' return '$config:collection-rootIn'
   default return '$config:collection-root'
   let $Pointer := if($pointer = '') then "[@ref]" else "[@ref='"||$pointer||"']"
   let $entityRef := if($entity='') then '' else '/id($entity)'
   let $path := $coll||$entityRef||'//t:placeName'||$Pointer 
   let $places := util:eval($path)
let $placeIDS := distinct-values($places/@ref)
    return
   map {
                    "hits" := $placeIDS,
                    "type" := 'indexes'

                }

     };
     
     
declare
    %templates:default("collection", "")
    %templates:default("entity", "")
    %templates:default("pointer", "")
function indexesNE:persNames ($node as node(), $model as map(*),  $collection as xs:string,$entity as xs:string, $pointer as xs:string*) {
   let $coll := switch($collection)
   case'all' return '$config:collection-root'
   case 'mss' return '$config:collection-rootMS'
   case 'work' return '$config:collection-rootW'
   case 'auth' return '$config:collection-rootA'
   case 'pers' return '$config:collection-rootPr'
   case 'place' return '$config:collection-rootPl'
   case 'ins' return '$config:collection-rootIn'
   default return '$config:collection-root'
   let $Pointer := if($pointer = '') then "[@ref]" else "[@ref='"||$pointer||"']"
   let $entityRef := if($entity='') then '' else '/id($entity)'
   let $path := $coll||$entityRef||'//t:persName'||$Pointer 
   let $persons := util:eval($path)
let $persIDS := distinct-values($persons/@ref)
    return
   map {
                    "hits" := $persIDS[.!='PRS00000'][.!='PRS0000'],
                    "type" := 'indexes'

                }

     };
     
     declare function indexesNE:placeNameForm($node as node(), $model as map(*)){
   <form xmlns="http://www.w3.org/1999/xhtml"  action="" class="form form-horizontal">
   
      <div  class="form-group">
                               <small class="form-text text-muted">enter a Beta maṣāḥǝft, Pleiades or Wikidata identifier</small>
                                <input class="form-control" name="pointer" placeholder="LOC / INS / pleiades: / Q"></input>
                                </div><div class="form-group">
                                 <small class="form-text text-muted">Select one collections</small>
                                    <select name="collection" class="form-control">
            <option value="all">all</option>
            <option value="mss">Manuscripts</option>
            <option value="work">Works</option>
            <option value="pers">Persons</option>
            <option value="place">Places</option>
            <option value="ins">Repositories</option>
            <option value="auth">Authority Files</option>
            </select>
                                 </div>
                                <div class="btn-group">
                                 <button type="submit" class="btn btn-primary">
                                 <i class="fa fa-filter" aria-hidden="true"></i></button>
                                 <a href="/bibliography" role="button" class="btn btn-info"><i class="fa fa-th-list" aria-hidden="true"></i></a></div>
   </form>
   };
   
   
     declare function indexesNE:persNameForm($node as node(), $model as map(*)){
   <form xmlns="http://www.w3.org/1999/xhtml"  action="" class="form form-horizontal">
   
      <div  class="form-group">
                               <small class="form-text text-muted">enter a Beta maṣāḥǝft or Wikidata identifier</small>
                                <input class="form-control" name="pointer" placeholder="PRS / Q"></input>
                                </div><div class="form-group">
                                 <small class="form-text text-muted">Select one collections</small>
                                    <select name="collection" class="form-control">
            <option value="all">all</option>
            <option value="mss">Manuscripts</option>
            <option value="work">Works</option>
            <option value="pers">Persons</option>
            <option value="place">Places</option>
            <option value="ins">Repositories</option>
            <option value="auth">Authority Files</option>
            </select>
                                 </div>
                                <div class="btn-group">
                                 <button type="submit" class="btn btn-primary">
                                 <i class="fa fa-filter" aria-hidden="true"></i></button>
                                 <a href="/bibliography" role="button" class="btn btn-info"><i class="fa fa-th-list" aria-hidden="true"></i></a></div>
   </form>
   };
     
declare
%templates:wrap
    %templates:default('start', 1)
    %templates:default("per-page", 10)
    function indexesNE:placeNamesRes($node as node(), $model as map(*), $start as xs:integer, $per-page as xs:integer){

for $target at $p in subsequence($model("hits"), $start, $per-page)
let $ptrs := $config:collection-root//t:placeName[@ref = $target]
let $count := count($ptrs)
return
<div class="col-md-12">
<script type="text/javascript" src="https://www.gstatic.com/charts/loader.js"  ></script>
    <div id="{$target}" class="col-md-2">
    <a href="/{$target}" class="MainTitle" data-value="{$target}">{$target}</a> 
    has been marked up <span class="badge">{$count}</span> times in the selected collections.
    </div>
<div class="col-md-10">
<div class="col-md-12">
<div class="col-md-6">
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
    <div class="col-md-6">
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
let $ptrs := $config:collection-root//t:persName[@ref = $target]
let $count := count($ptrs)
return
<div class="col-md-12">
<script type="text/javascript" src="https://www.gstatic.com/charts/loader.js"  ></script>
    <div id="{$target}" class="col-md-2">
    <a href="/{$target}" class="MainTitle" data-value="{$target}">{$target}</a> 
    has been marked up <span class="badge">{$count}</span> times in the selected collections.
    </div>
<div class="col-md-10">
<div class="col-md-12">
<div class="col-md-6">
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
    <div class="col-md-6">
    {charts:pieAttestations($target, 'persName')}
    </div>
    </div>
    </div>
    </div>
};