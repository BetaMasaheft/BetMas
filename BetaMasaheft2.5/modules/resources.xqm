xquery version "3.0" encoding "UTF-8";

(:~
 : This module contains functions printing indexes and lists extracted from the data which are not list of resources
 : @author Pietro Liuzzo <pietro.liuzzo@uni-hamburg.de'>
 :)

module namespace lists="https://www.betamasaheft.uni-hamburg.de/BetMas/lists";
import module namespace config="https://www.betamasaheft.uni-hamburg.de/BetMas/config" at "config.xqm";
import module namespace templates="http://exist-db.org/xquery/templates" ;
import module namespace app="https://www.betamasaheft.uni-hamburg.de/BetMas/app" at "app.xqm";
import module namespace titles="https://www.betamasaheft.uni-hamburg.de/BetMas/titles" at "titles.xqm";
import module namespace console="http://exist-db.org/xquery/console";
import module namespace string = "https://www.betamasaheft.uni-hamburg.de/BetMas/string" at "tei2string.xqm";

declare namespace t="http://www.tei-c.org/ns/1.0";


(:~prints a responsive table with the first 100 ptr targets fount in 
 : all the bibliography entries in the  entities in the app taken once, requesting the data from Zotero:)
declare

    %templates:default("collection", "")
    %templates:default("pointer", "")
    %templates:default("type", "all")
function lists:bibl ($node as node(), $model as map(*),
    $type as xs:string+, $collection as xs:string, $pointer as xs:string*) {
   let $coll := switch($collection) 
   case'all' return 'collection($config:data-root)'  
   case 'mss' return 'collection($config:data-rootMS)' 
   case 'work' return 'collection($config:data-rootW)' 
   case 'auth' return 'collection($config:data-rootA)' 
   case 'pers' return 'collection($config:data-rootPr)'  
   case 'place' return 'collection($config:data-rootPl)' 
   case 'ins' return 'collection($config:data-rootIn)'   
   default return 'collection($config:data-root)'
   let $Pointer := if($pointer = '') then () else "[.='"||$pointer||"']"
    let $Type := if($type = 'all') then () else let $pars := for $ty in $type return "@type = '" || $ty || "'" return '//t:listBibl[' || string-join($pars, ' or ') || ']'
   let $path := $coll||$Type||'//t:ptr/@target'||$Pointer
   let $query := util:eval($path)
let $bms := 
for $bibl in distinct-values($query)
return
$bibl
    return
   map {
                    "hits" := $bms,
                    "type" := 'bibliography'
                    
                }

     };


declare
%templates:wrap
    %templates:default('start', 1)
    %templates:default("per-page", 10)  
    
    function lists:biblRes($node as node(), $model as map(*), $start as xs:integer, $per-page as xs:integer){

for $target at $p in subsequence($model("hits"), $start, $per-page)
let $ptrs := collection($config:data-root)//t:ptr[@target = $target]
let $count := count($ptrs)
return
<div class="col-md-12">
    <div id="{$target}" class="biblioentry col-md-6"/>
<div class="col-md-6">
<div class="col-md-9">
<ul>
    {    
   for $citingentity in $ptrs/@target
   group by $root :=    root($citingentity)/t:TEI/@xml:id
    return
    <li><a href="{$root}">{titles:printTitle(root($root)/t:TEI)}</a></li>
    }
    </ul>
    </div>
    <div class="col-md-3">{$count}</div>
    </div>
    </div>
};
(:~ indexes and lists :)

declare function lists:additions($node as node(), $model as map(*)){
    let $c := collection($config:data-rootMS)
    let $auth := collection($config:data-rootA)
    let $data as element()* := $c//t:additions//t:item[t:desc/@type]
return
    <div class="list-group list-group-root col-md-12">
        {
for $addition in $data
    let $t := $addition//t:desc/@type
    group by $type := $t
    order by $type
    let $authfile := $auth/t:TEI[@xml:id = $type]
    let $typeName := $authfile//t:titleStmt/t:title/text()
    
    return
        <ul class="list-group" id="{data($type)}list">
        
        <a href="#{data($type)}" class="list-group-item" data-toggle="collapse">
        <i class="glyphicon glyphicon-chevron-right"></i><span class="badge">{count($data[t:desc/@type = $type])}</span>{
          $typeName
    }</a>
        <ul class="list-group collapse" id="{data($type)}">
        <h2 class="list-group-item-heading"><a href="/authority-files/list?keyword={data($authfile/@xml:id)}">{$typeName}</a></h2>
            {
                for $a in $addition
                let $fileID := data($a/ancestor::t:TEI/@xml:id)
                let $additionID := data($a/@xml:id)
                order by $fileID
                return
            <li class="list-group-item"><a href="{$fileID}#{$additionID}">{$fileID},{$additionID}</a> |  
            <div class="additionTextContent">
            
               <div 
               id="{$fileID}_{$additionID}">
               {$a//t:q}
               </div>
            
                
            </div>
                
            </li>
                
            }
            </ul>
            
            
        </ul>
}
</div>
};


declare 
    %templates:default("scope", "narrow")
    %templates:default("type", "all")
    %templates:default("target-pers", "all")
    %templates:default("target-place", "all")
    %templates:default("target-work", "all")
    %templates:default("target-artTheme", "all")
    %templates:default("target-keyword", "all")
function lists:SearchDeco(
$node as node()*, 
$model as map(*), 
$query as xs:string*, 
    $type as xs:string+,
    $target-keyword as xs:string+,
    $target-pers as xs:string+,
    $target-place as xs:string+,
    $target-work as xs:string+,
    $target-artTheme as xs:string+,
    $legendText as xs:string*,
    $otherText as xs:string*
   ) {
   let $type := if($type = 'all') then '[@type]' else let $pars := for $ty in $type return "@type = '" || $ty || "'" return '[' || string-join($pars, ' or ') || ']'
   let $target-work := if($target-work = 'all') then () else let $pars := for $ty in $target-work return "@ref = '" || $ty || "'" return '[descendant::t:title[' || string-join($pars, ' or ') || ']]'
   let $target-artTheme := if($target-artTheme= 'all') then () else let $pars := for $ty in $target-artTheme return "@corresp = '" || $ty || "'" return '[descendant::t:ref[@type="authFile"][' || string-join($pars, ' or ') || ']]'
   let $target-pers := if($target-pers = 'all') then () else let $pars := for $ty in $target-pers return "@ref = '" || $ty || "'" return '[descendant::t:persName[' || string-join($pars, ' or ') || ']]'
   let $target-place := if($target-place = 'all') then () else let $pars := for $ty in $target-place return "@ref = '" || $ty || "'" return '[descendant::t:placeName[' || string-join($pars, ' or ') || ']]'
   let $target-keyword := if($target-keyword = 'all') then () else let $pars := for $ty in $target-keyword return "@key = '" || $ty || "'" return '[descendant::t:term[' || string-join($pars, ' or ') || ']]'
   let $legendText :=  if($legendText) then ("[descendant::t:q[@xml:lang][ft:query(.,'" || $legendText || "')]]") else ()
   let $otherText :=if($otherText) then ("[descendant::t:foreign[@xml:lang='gez'][ft:query(.,'" || $otherText || "')]]") else ()
   let $path := 'collection($config:data-rootMS)//t:decoDesc//t:decoNote' || $type || $target-work || $target-artTheme || $target-pers || $target-place || $target-keyword || $legendText ||$otherText
  let $decos := for $dec in util:eval($path) return $dec
   return
   map {
                    "hits" := $decos
                    
                }
   };
   
   declare function lists:biblform($node as node(), $model as map(*)){
   <form xmlns="http://www.w3.org/1999/xhtml"  action="" class="form form-horizontal">
   <div class="control-group">
   <small class="form-text text-muted">Select one 
   or more type of bibliography</small>
   <label class="checkbox"><input type="checkbox" value="secondary" name="type"/>secondary</label>
   <label class="checkbox"><input type="checkbox" value="editions" name="type"/>editions</label>
   <label class="checkbox"><input type="checkbox" value="translation" name="type"/>translation</label>
   <label class="checkbox"><input type="checkbox" value="text" name="type"/>text</label>
   <label class="checkbox"><input type="checkbox" value="clavis" name="type"/>clavis</label>
   <label class="checkbox"><input type="checkbox" value="catalogue" name="type"/>catalogue</label>
   <label class="checkbox"><input type="checkbox" value="otherLanguages" name="type"/>otherLanguages</label>
   </div>
      <div  class="form-group">
                               <small class="form-text text-muted">enter a Zotero bm:id</small>
                                <input class="form-control" name="pointer" placeholder="bm:"></input>
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
   
   declare function lists:decorationsform($node as node(), $model as map(*)){
   let $auth := collection($config:data-rootA)
   return
   <form action="" class="form form-horizontal">
                               <div  class="control-group">
                               <small class="form-text text-muted">Select one or more type of decoration</small>
 
                               {for $d in distinct-values($model('hits')/@type)
                                 return  (<label class="checkbox"><input type="checkbox" value="{$d}" name="type"/>{$d}</label>)}
                                
                                </div>
                                <div  class="form-group">
                               <small class="form-text text-muted">Search in the text of the legends</small>
                                <input class="form-control" name="legendText"></input>
                                </div>
                                <div  class="form-group">
                               <small class="form-text text-muted">Select in text on the decorations which is not the legend</small>
                                <input class="form-control" name="otherText"></input>
                                </div>
                               {if($model('hits')//t:ref[@type='authFile']) then  <div class="form-group">
                                 <small class="form-text text-muted">Select one or more Art Themes associated with the decoration description</small>
 
                                    <select xmlns="http://www.w3.org/1999/xhtml" multiple="multiple" id="target-artTheme" name="target-artTheme" class="form-control">
            {for $d in distinct-values($model('hits')//t:ref[@type='authFile']/@corresp)
            return
            <option value="{$d}">{titles:printTitleMainID($d)}</option>}
            </select>
                                 </div> else () }
                               {if($model('hits')//t:title) then  <div class="form-group">
                                 <small class="form-text text-muted">Select one or more works referred to in the decoration description</small>
 
                                    <select xmlns="http://www.w3.org/1999/xhtml" multiple="multiple" id="target-work" name="target-work" class="form-control">
            {for $d in distinct-values($model('hits')//t:title/@ref)
            return
            <option value="{$d}">{titles:printTitleMainID($d)}</option>}
            </select>
                                 </div> else () }
                                 {if($model('hits')//t:persName) then <div class="form-group">
                                 <small class="form-text text-muted">Select one or more persons referred to in the decoration description</small>
                                    <select xmlns="http://www.w3.org/1999/xhtml" multiple="multiple" id="target-pers" name="target-pers" class="form-control">
            {for $d in distinct-values($model('hits')//t:persName/@ref)
            return
            <option value="{$d}">{titles:printTitleMainID($d)}</option>}
            </select>
                                 </div> else ()}
                                 {if($model('hits')//t:placeName) then <div class="form-group">
                                 <small class="form-text text-muted">Select one or more places referred to in the decoration description</small>
                                    <select xmlns="http://www.w3.org/1999/xhtml" multiple="multiple" id="target-place" name="target-place" class="form-control">
            {for $d in distinct-values($model('hits')//t:placeName/@ref)
            return
            <option value="{$d}">{titles:printTitleMainID($d)}</option>}
            </select>
                                 </div> else () }
                                 {if($model('hits')//t:term) then 
                                 <div class="form-group">
                                 <small class="form-text text-muted">Select one or more artistic elements referred to in the decoration description</small>
                                    <select xmlns="http://www.w3.org/1999/xhtml" multiple="multiple" id="target-keyword" name="target-keyword" class="form-control">
            {for $d in distinct-values($model('hits')//t:term/@key)
            return
            <option value="{$d}">{titles:printTitleMainID($d)}</option>}
            </select>
                                 </div> else() }
                                 <div class="btn-group">
                                 <button type="submit" class="btn btn-primary">
                                 <i class="fa fa-filter" aria-hidden="true"></i></button>
                                 <a href="/decorations" role="button" class="btn btn-info"><i class="fa fa-th-list" aria-hidden="true"></i></a></div>
                        </form>
   };
declare function lists:decorations($node as node(), $model as map(*)){ 
    let $c := collection($config:data-rootMS)
    let $data as element()* := $c//t:decoDesc//t:decoNote[@type]
return
    <div class="list-group list-group-root col-md-12">
        {
for $decoration in $data
    let $t := $decoration/@type
   (: group by type :)
    group by $type := $t
    order by $type
    return
        <div class="list-group" id="{data($type)}list">
        
        <a href="#{data($type)}" class="list-group-item" data-toggle="collapse"><i class="glyphicon glyphicon-chevron-right"></i><span class="badge">{count($decoration)}</span>{string($type)} </a>
        
        <div  class="list-group collapse" id="{data($type)}">
            {
                for $d in $decoration
                let $msid := $d/ancestor::t:TEI/@xml:id
                (:group by containing ms:)
                group by $ms := $msid
                order by $ms
                return
                    
             <div  class="list-group">
             
             <a class="list-group-item" data-toggle="collapse" href="#{$ms}"><i class="glyphicon glyphicon-chevron-right"></i>{$c//id($ms)//t:msIdentifier/t:idno}</a>
                 <ul class="list-group collapse" id="{data($ms)}">
                 {
                     for $sd in $d
                     order by $sd/@xml:id
                     return
            <li class="list-group-item"><a href="{data($ms)}#{data($sd/@xml:id)}">{data($sd/@xml:id)}</a>: {if($sd/t:desc/t:ref or $sd/t:desc/t:persName or $sd/t:desc/t:placeName) then transform:transform($sd/t:desc,  'xmldb:exist:///db/apps/BetMas/xslt/decodesc.xsl', ()) else $sd/t:desc/text() }</li>
                 }
            </ul>
            </div>
            }
    
        </div>
        </div>
}
</div>
};



declare 
%templates:wrap
    function lists:decoRes($node as node(), $model as map(*)){ 
   let $c := collection($config:data-rootMS)
   return
    <div class="list-group list-group-root col-md-12">
        {
for $decoration at $p in $model("hits")
    let $t := $decoration/@type
   (: group by type :)
    group by $type := $t
    order by $type
    return
        <div class="list-group" id="{data($type)}list">
        
        <a href="#{data($type)}" class="list-group-item" data-toggle="collapse"><i class="glyphicon glyphicon-chevron-right"></i><span class="badge">{count($decoration)}</span>{string($type)} </a>
        
        <div  class="list-group collapse" id="{data($type)}">
            {
                for $d in $decoration
                let $msid := $d/ancestor::t:TEI/@xml:id
                
                (:group by containing ms:)
                group by $ms := $msid
                order by $ms
                return
                    
             <div  class="list-group">
             
             <a class="list-group-item" data-toggle="collapse" href="#{$ms}"><i class="glyphicon glyphicon-chevron-right"></i>{$c//id($ms)//t:msIdentifier/t:idno}</a>
                 <ul class="list-group collapse" id="{data($ms)}">
                 {
                     for $sd in $d
                     let $images := root($sd)//t:msIdentifier/t:idno
                     let $locus := string($sd/t:locus/@facs)
                     order by $sd/@xml:id
                     return
            <li class="list-group-item container">
            
            {if($images/@facs and $locus) then (<a target="_blank"  href="/manuscripts/{$ms}/viewer"><img class="thumb col-md-1" src="{
           if(starts-with($ms, 'ES')) 
           then $config:appUrl ||'/iiif/' || string($images/@facs) || '_'||$locus||'.tif/full/150,100/0/default.jpg'
          else if(starts-with($ms, 'BNF')) 
           then replace($images/@facs, 'ark:', 'iiif/ark:') || '/'||$locus||'/full/80,100/0/native.jpg'
          else if(starts-with($ms, 'BAV')) 
           then replace(substring-before($images/@facs, '/manifest.json'), 'iiif', 'pub/digit') || '/thumb/'
                    ||
                    substring-before(substring-after($images/@facs, 'MSS_'), '/manifest.json') || 
                    '_'||$locus||'.tif.jpg'
           else ()}"/></a>
 
           )           
            else ()}
            <p class="col-md-11"><a href="{data($ms)}#{data($sd/@xml:id)}">{data($sd/@xml:id)}</a>: {try{string:tei2string($sd/node())} catch * {(console:log($err:code || ": "|| $err:description), string-join($sd//text(), ' '))}}
            </p></li>
                 }
            </ul>
            </div>
            }
    
        </div>
        </div>
}
</div>
};


(:~print out of the values and definitions in the schema:)
declare function lists:docs($node as node(), $model as map(*)){
<div class="container">

{
let $values := doc(($config:schema-root || '/tei-betamesaheft.xml'))//t:valItem[not(data(ancestor::t:elementSpec[1]/@ident)= 'change' or data(ancestor::t:elementSpec[1]/@ident)=  'editor')] 
return
<div class="container">
  <div class="row-fluid">
<p>In the schema there are {count($values[t:desc])} defined values and {count($values[not(t:desc)])} without a definition.</p>
</div>
<div class="table-responsive">
<table class="table table-hover" id="completeList">
<thead>
<tr>
<th>Value</th>
<th>Definition</th>
<th>Element</th>
</tr>
</thead>
<tbody>
{for $value in $values
return
<tr id="{
(
(if ($value/ancestor::t:elementSpec[1]/@ident = 'relation') 
then () 
else (string($value/ancestor::t:elementSpec[1]/@ident || '_'))) 
|| string($value/@ident))}">
<td>{string($value/@ident)}</td>
<td>{$value/t:desc/text()}</td>
<td><code>{(string($value/ancestor::t:elementSpec[1]/@ident) || '/@'|| string($value/ancestor::t:attDef[1]/@ident))}</code></td>
</tr>
}
</tbody>
</table>
</div>
</div>
}</div>
};

