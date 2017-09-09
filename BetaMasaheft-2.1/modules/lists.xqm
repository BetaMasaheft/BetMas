xquery version "3.0" encoding "UTF-8";

module namespace lists="https://www.betamasaheft.uni-hamburg.de/BetMas/lists";
import module namespace config="https://www.betamasaheft.uni-hamburg.de/BetMas/config" at "config.xqm";
import module namespace templates="http://exist-db.org/xquery/templates" ;
import module namespace app="https://www.betamasaheft.uni-hamburg.de/BetMas/app" at "app.xqm";
import module namespace titles="https://www.betamasaheft.uni-hamburg.de/BetMas/titles" at "titles.xqm";
import module namespace console="http://exist-db.org/xquery/console";
declare namespace t="http://www.tei-c.org/ns/1.0";


declare variable  $lists:collection := request:get-parameter('collection',());

(:  returns a responsive table with a list of the collection selected by parameter. 
The parameter is decided by the url call, which is handled by the controller. 
might be better as a proper view. :)
declare function lists:list($node as node(), $model as map(*)) {
     let $items-info := lists:items($lists:collection)

return
    <div
        class="table-responsive"><table
                    class="table table-hover"
                    id="completeList">
                    <thead>
                        <tr>
        {
            if ($lists:collection = 'works') then
                (
                
                            <th>ID</th>,
                            <th>Name</th>,
                            <th>Titles</th>,
                            <th>Authors</th>,
                            <th>Witnesses</th>,
                            <th>Text</th>
                        
                )
            else
                if ($lists:collection = 'places') then
                    (
                    
                                <th>Name</th>,
                                <th>geoJson</th>
                           
                    )
                else
                    if ($lists:collection = 'institutions') then
                        (
                        
                                    <th>Name</th>,
                                    <th>Mss</th>,
                                    <th>geoJson</th>
                                
                        )
                    else
                        if ($lists:collection = 'persons') then
                            (
                            
                                        <th>Name</th>,
                                        <th>Gender</th>
                                    
                            )
                        else
                            if ($lists:collection = 'narratives') then
                                (
                                
                                            <th>Name</th>,
                                            <th>Text</th>
                                        
                                )
 else
                            if ($lists:collection = 'authority-files') then
                                (
                                
                                            <th>Name</th>
                                        
                                )
else
                                (
                                
                                            <th>Name</th>,
                                            <th>Textual Units</th>,
                                            <th>Manuscript Parts</th>,
                                            <th>Hands</th>,
                                            <th>Script</th>,
                                            <th>Text</th>
                                        
                                )
        }
                            <th>Dated</th>
                            <th>TEI-XML</th>
                            <th>Analytics</th>
                            <th>See also...</th>
    </tr>
                    </thead>
                   
                                    {lists:body($items-info)}
                </table>
    
    </div>
};


declare function lists:items($collection as xs:string) {

    let $type := switch ($collection)
     case 'manuscripts' return 'mss'
         case 'works' return 'work'
         case 'narratives' return 'nar'
         case 'places' return 'place'
         case 'institutions' return 'ins'
         case 'persons' return 'pers'
         default return 'auth'
         let $path := concat("collection('", $config:data-root, "')//t:TEI[ft:query(@type, '",$type,"')]")
         let $eval := util:eval($path)
         
         return
    <items>
        {
            for $resource in 
            $eval
(:            collection($config:data-root)//t:TEI[ft:query(@type, $type)]:)
            return
                <item
                    uri="{base-uri($resource)}"
                    name="{util:unescape-uri(replace(base-uri($resource), ".+/(.+)$", "$1"), "UTF-8")}"
                    title="{titles:printTitle($resource)}"
                    id="{string($resource/@xml:id)}"
                    doc="{document-uri($resource)}"
                    type="{string($resource/@type)}">
                    {
                        titles:printTitle($resource)
                    }
                </item>
        }
    </items>
};

declare function lists:body($items-info as node()){
<tbody>
                                        {
                                            
                                            for $item in $items-info/item
                                            order by $item/@name
                                            return
                                               lists:tr($item)
                                        }
                                    
                                    </tbody>
};

declare function lists:tr($item as node()) {
    
    <tr
        style="{
                if (count(doc($item/@uri)//t:change[not(@who = 'PL')]) eq 1) then
                    'background-color:#ffefcc;'
                else
                    if (doc($item/@uri)//t:change[contains(., 'completed')]) then
                        'background-color:#e6ffff;'
                    else
                        if (doc($item/@uri)//t:change[contains(., 'reviewed')]) then
                            'background-color:#e6ffe6;'
                        else
                            'background-color:#ffe6e6;'
            }">
        
        {lists:tds($item)}
    </tr>
};


declare function lists:tds($item as node()) {

    if ($lists:collection = 'works') then
(: id only works :)
        <td>{substring(doc($item/@uri)/t:TEI/@xml:id, 4, 4)}</td>
    else
        (),
(:  name ALL:)
    <td><a
            href="{$item/@id}">{$item/text()}</a></td>,
    if ($lists:collection = 'works') then
        (
   (:work titles:)
        <td><ul>
                {
                    for $title in doc($item/@uri)//t:titleStmt/t:title
                    return
                        <li>{$title/text()}</li>
                }
            </ul>
        </td>,
(:        work authors:)
        <td><ul>
                {
                    for $author in doc($item/@uri)//t:titleStmt/t:author
                    return
                        <li>{$author}</li>
                }
            </ul>
        </td>,
(:        work witnesses:)
        <td>
            <ul>
                {
                    for $witness in doc($item/@uri)//t:listWit/t:witness
                    return
                        <li><a
                                href="{$witness/@corresp}">{string($witness/@corresp)}</a></li>
                }
            </ul>
        </td>)
    else
        if ($lists:collection = 'manuscripts') then
        
(:        msitemsm msparts, hands, script:)
            (
            <td>{count(doc($item/@uri)//t:msItem[not(t:msItem)])}</td>,
            <td>{
                    if (count(doc($item/@uri)//t:msPart) = 0) then
                        1
                    else
                        count(doc($item/@uri)//t:msPart)
                }</td>,
            <td>{count(doc($item/@uri)//t:handNote)}</td>,
            <td>{distinct-values(data(doc($item/@uri)//@script))}</td>
            )
        else
            if ($lists:collection = 'persons') then
(:            gender:)
                (
                <td>{
                    switch (data(doc($item/@uri)//t:person/@sex))
                            case "1"
                                return
                                    <i
                                        class="icon-large icon-male"/>
                            case "2"
                                return
                                    <i
                                        class="icon-large icon-female"/>
                            default return
                                ()
                }</td>
            )
        else
            if ($lists:collection = 'institutions') then
(:            mss from same repo:)
                (
                <td>{
                        let $id := string($item/@id)
                        let $mss := collection($config:data-rootMS)//t:repository[ft:query(@ref, $id)]
                        return
                            count($mss)
                    }</td>
                )
            else
                (),
if ($lists:collection = 'places' or $lists:collection = 'institutions') then
(:geojson:)
    <td>{
            if (doc($item/@uri)//t:geo) then
                <a
                    href="{($item/@id)}.json"
                    target="_blank"><span
                        class="glyphicon glyphicon-map-marker"></span></a>
            else
                ()
        }</td>
else
    if ($lists:collection = 'works' or $lists:collection = 'manuscripts' or $lists:collection = 'narratives') then
    
(:    text:)
        <td>{
            if (doc($item/@uri)//t:div[@type = 'edition']) then
                    <a
                        href="{('/text/' || $item/@id)}"
                        target="_blank">{
                        switch ($lists:collection)
                                case 'manuscripts'
                                    return
                                        'transcription'
                                case 'works'
                                    return
                                        'edition'
                                default return
                                    'text'
                    }</a>
            else
                ()
        }</td>
else
    (),
    
(:    date, xml, analytics, seeAlso:)
<td>{
        if (doc($item/@uri)//t:date[@evidence = 'internal-date'] or doc($item/@uri)//t:origDate[@evidence = 'internal-date'] or doc($item/@uri)//t:date[@type = 'foundation'])
        then
            let $date := doc($item/@uri)//t:*[@evidence = 'internal-date' or @type = 'foundation'][1]
            return
                if ($date/@when) then
                    data($date/@when)
                else
                    if ($date/@from or $date/@to) then
                        (data($date/@from) || '-' || data($date/@to))
                    else
                        $date
        
        else
            'N/A'
    }</td>,
<td><a
        href="{('/tei/' || $item/@id)}"
        target="_blank">XML</a></td>,
<td><a
        href="{('/analytic/' || $item/@id)}"
        target="_blank"><span
            class="glyphicon glyphicon-list-alt"></span></a></td>,
<td><a
        href="{('/seealso/' || $item/@id)}"
        target="_blank"><span
            class="glyphicon glyphicon-hand-left"></span></a></td>

};



(:prints a responsive table with the first 100 ptr targets fount in 
all the bibliography entries in the  entities in the app taken once, requesting the data from Zotero:)
declare function lists:bibl ($node as node(), $model as map(*)) {
for $bibl in collection($config:data-root)//t:ptr[contains(@target, 'bm:')]
let $bm := $bibl/@target
group by  $bm
order by $bm
return
<tr>
    <td id="{$bm}" class="biblioentry"/>
<td><ul>
    {    
   for $citingentity in $bibl/@target
   group by $root :=    root($citingentity)/t:TEI/@xml:id
    return
    <li><a href="{$root}">{titles:printTitle(root($root)/t:TEI)}</a></li>
    }
    </ul>
    </td>
    <td>{count($bibl/@target)}</td>
    </tr>
    
   

     };


(: indexes and lists :)

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



declare function lists:keywords($node as node(), $model as map(*)){ 
    let $data as element()* := collection($config:data-rootMS)//t:term[@key]
return
    <div class="list-group list-group-root col-md-12">
        {
for $keyword in $data
    let $t := $keyword/@key
    let $authfile := collection($config:data-rootA)/t:TEI[@xml:id = $t]
    let $typeName := $authfile//t:titleStmt/t:title/text()
    group by $type := $t
    order by $type
    return
        <ul class="list-group" id="{data($type)}list">
        
        <a href="#{data($type)}" class="list-group-item" data-toggle="collapse"><i class="glyphicon glyphicon-chevron-right"></i><span class="badge">{count($data[@key = $type])}</span>{
        let $authfile := collection($config:data-rootA)/t:TEI[@xml:id = $type]
    let $typeName := $authfile//t:titleStmt/t:title/text()
    return $typeName}</a>
        <ul class="list-group collapse" id="{data($type)}">
        <h2 class="list-group-item-heading"><a href="{data($authfile/@xml:id)}">{$typeName}</a></h2>
            {
                for $k in $keyword
                order by $k/ancestor::t:TEI/@xml:id
                return
            <li class="list-group-item"><a href="{data($k/ancestor::t:TEI/@xml:id)}">{data($k/ancestor::t:TEI/@xml:id)}: {data($k/ancestor::t:TEI//t:titleStmt/t:title[1])}</a></li>
                
            }
            </ul>
            
            
        </ul>
}
</div>
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



(:print out of the values and definitions in the schema:)
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

