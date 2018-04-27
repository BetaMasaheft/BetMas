xquery version "3.0" encoding "UTF-8";


module namespace rels="https://www.betamasaheft.uni-hamburg.de/BetMas/rels";
import module namespace config="https://www.betamasaheft.uni-hamburg.de/BetMas/config" at "config.xqm";

import module namespace titles="https://www.betamasaheft.uni-hamburg.de/BetMas/titles" at "titles.xqm";
import module namespace app="https://www.betamasaheft.uni-hamburg.de/BetMas/app" at "app.xqm";
import module namespace apprest = "https://www.betamasaheft.uni-hamburg.de/BetMas/apprest" at "apprest.xqm";

import module namespace templates="http://exist-db.org/xquery/templates" ;


declare namespace t="http://www.tei-c.org/ns/1.0";

declare option exist:serialize "method=text mediatype=text/javascript";

declare function rels:getZoteroTextData ($string as xs:string){
let $xml-url := concat('https://api.zotero.org/groups/358366/items?tag=',$string,'&amp;format=bib&amp;style=hiob-ludolf-centre-for-ethiopian-studies&amp;linkwrap=1')
let $data := httpclient:get(xs:anyURI($xml-url), true(), <Headers/>)
return
$data//text()
};

(:VIS.JS GRAPHS:)
(:graph of relations stated in one entity:)
declare function rels:EntityRels($node as node(), $model as map(*)){

let $entity := $model('entity')

let $localId := $entity/@xml:id
(:all these need to be here because they are used first to build nodes, then to build the edges:)
let $all := 
(:looks for corresps, refs and relations which have the id of this item in them it performs the same function on the secondary relations root element, see below:)
let $whatpointshere := apprest:WhatPointsHereQuery($localId)
          
(:looks for what point to corresps, refs and relations within the current item and returns all items pointing there:)
let $secondaryrelations := for $ref in ($entity//@ref[. != $localId][not(parent::t:repository)] , $entity//@active[. != $localId], $entity//@passive[. != $localId])
          return apprest:WhatPointsHereQuery($ref)

(:looks for any person with a role and a ref, excluding the ES placeholders:)
let $persWithRole := $entity//t:persName[@role and @ref[. != 'PRS00000']]

(:looks for titles in msItems:)
let $msItems := $entity//t:msItem/t:title

(:takes divs in the transcription or edition:)
let $divs := $entity//t:div[@type='edition']//t:div

(:looks for relations with @mutual or the couple @active @passive:)
let $relations := $entity//t:relation[@name][(@active and @passive) or @mutual]


let $data :=
(:collects all available ids:)
(:the first entry makes sure there is the id of the current item:)
<allIDS>
<id type="entry">{string($localId)}</id>

{
(:returns the title and id of the entities referring to this entity or entity referring to those pointing to the entity:)
for $pointerRoot in ($whatpointshere, $secondaryrelations)
let $refid := if($pointerRoot/@ref) then $pointerRoot/@ref else if($pointerRoot/@corresp) then $pointerRoot/@corresp else if($pointerRoot/@passive) then $pointerRoot/@passive else if($pointerRoot/@mutual) then $pointerRoot/@mutual else $pointerRoot/@active

return 
(:first return the root of the referring entity and the id in the corresp, active, passive, mutual, etc. there.:)
<data>
<ids type="wph">
<id >{string(root($pointerRoot)/t:TEI/@xml:id)}</id>
<id>{string($refid)}</id>
{if (contains($refid, '#')) then 
<id>{substring-before($refid, '#')}</id>
else ()}
</ids>
<relations>
 { let $ref := string(root($pointerRoot)/t:TEI/@xml:id)
    let $name := name($pointerRoot)
return 
<edge>
{
                        ('{from:"' || $ref|| '", to:"' || $refid || '", label:"' ||$name || '", value:' || count($name)  ||
                        ', font: {align: ''top''}},')
                    }</edge>
                    }
</relations>
</data>
}


{ 

(:takes ids of any relevant subparts in a item:)
(:titles :)
for $msItem in $msItems
(:a title is always in a msItem with a xml:id. we point to that id returns the id of the subpart and the id of the title referred to:)
let $parent := $msItem//parent::t:msItem
let $container := if ($msItem//ancestor::t:msPart[1]) then $msItem//ancestor::t:msPart[1]  else $msItem//ancestor::t:TEI
let $titleId := if (contains($msItem/@ref, '#')) then substring-before($msItem/@ref, '#') else $msItem/@ref
return 
<data>
<ids  type="title"><id>{string($localId)}{if ($container/name() = 'msPart') then ('#'  || string($container/@xml:id)) else ()}</id>
<id>{string($msItem/@ref)}</id></ids>
<relations>
<edge>{
                        ('{from:"' || ($localId || (if ($container/name() = 'msPart') then ('#'  || string($container/@xml:id)) else ())) || '", to:"' || string($msItem/@ref) || '", label:"' || 'saws:contains'||
                        '", font: {align: ''top''}},')
                    }</edge>
                    {
                    if (contains($msItem/@ref, '#'))
                    then(<edge>{
                        ('{from:"' || string($msItem/@ref) || '", to:"' || $titleId || '", label:"' || 'saws:formsPartOf'||
                        '", font: {align: ''top''}},')
                    }</edge>)
                    else()
                    }
</relations>
</data>
}



{ 
(:divs, this will always have their own xml:id the parent will always be a div, worst case scenario, the edition div. :)
for $div in $divs
let $parent := $div/parent::t:div[1][not(@type='edition')]

return 
<data>
<ids  type="div">
<id type="current">{string($localId)}#{string($div/@xml:id)}</id>
{if ($parent) then <id  type="parent">{string($localId)}#{string($parent/@xml:id)}</id> else ()}
</ids>
<relations>
<edge>{
                        ('{from:"' || $localId || '", to:"' || $localId||'#'||string($div/@xml:id) || '", label:"' || 'saws:contains'||
                        '", font: {align: ''top''}},')
                    }</edge>
                    {
                    if ($parent)
                    then(<edge>{
                        ('{from:"' || string($parent/@xml:id) || '", to:"' ||  string($div/@xml:id) || '", label:"' || 'saws:formsPartOf'||
                        '", font: {align: ''top''}},')
                    }</edge>)
                    else()
                    }
</relations>
</data>


}



{ for $singlePersWithRole in $persWithRole
let $persID := string($singlePersWithRole/@ref)
return 
<data>
<id type="person">{$persID}</id>
<relations>
<edge>{
                        ('{from:"' || $persID || '", to:"' || (if($singlePersWithRole/@corresp) then(string($singlePersWithRole/@corresp)) else $localId)|| '", label:"' || ('bm:'||string($singlePersWithRole/@role)) ||
                        '", font: {align: ''top''}},')
                    }</edge>
</relations>
</data>
}
    
    
    {<data>
    <ids>
    {
        for $active in data($relations/@active) 
        let $list :=
              if (contains($active, ' ')) 
             then
                 for $eachID in tokenize(normalize-space($active), ' ')
                     return 
              <id  type="rel">{
                    
                        $eachID
                }</id>
        else
        (
            <id type="rel">{
                   
                        $active
                }</id>)
                return
                $list
                
                
    }
    
    {
        for $passive in data($relations/@passive)
        let $list :=
              if (contains($passive, ' ')) 
             then
                 for $eachID in tokenize(normalize-space($passive), ' ')
                     return 
              <id type="rel">{
                   
                        $eachID
                }</id>
        else
        (
            <id type="rel">{
                   
                        $passive
                }</id>)
                return
                $list
    }
    
    
    {
        for $mutual in data($relations/@mutual)
        let $list :=
              if (contains($mutual, ' ')) 
             then
                 for $eachID in tokenize(normalize-space($mutual), ' ')
                     return 
              <id type="rel">{
                  
                        $eachID
                }</id>
        else
        (
            <id type="rel">{
                   
                        $mutual
                }</id>)
                return
                $list
    }
    </ids>
    <relations>
    {
            for $relation in $relations
            let $active := data($relation/@active)
            let $passive := data($relation/@passive)
            let $mutual := data($relation/@mutual)
            let $edges :=
            if (contains(normalize-space($mutual), ' '))
            
            then
            let $eachID := tokenize(normalize-space($mutual), ' ')
            return
            <edge>{
                        ('{from:"' || (
                            $eachID[1]) || '", to:"' || (
                            $eachID[2]) || '", label:"' || substring-after(string($relation/@name), ':') ||
                        '", font: {align: ''top''}},')
                    }
                </edge>
            else  if (contains(normalize-space($active), ' '))
           
            then (
            for $eachID in tokenize(normalize-space($active), ' ')
            return
            <edge>{
                        ('{from:"' || (
                            $eachID) || '", to:"' || (
                            $passive) || '", label:"' || substring-after(string($relation/@name), ':') ||
                        '", font: {align: ''top''}},')
                    }
                </edge>
                )
                 else    if (contains(normalize-space($passive), ' '))
            
            then(
            for $eachID in tokenize(normalize-space($passive), ' ')
            return
            <edge>{
                        ('{from:"' || (
                            $active) || '", to:"' || (
                            $eachID) || '", label:"' || substring-after(string($relation/@name), ':') ||
                        '", font: {align: ''top''}},')
                    }
                </edge>
                )
            else (
                <edge>{
                        ('{from:"' || (
                            $active) || '", to:"' || (
                            $passive) || '", label:"' || substring-after(string($relation/@name), ':') ||
                        '", font: {align: ''top''}},')
                    }
                </edge>
                )
               return
               $edges
        }
        </relations>
        </data>
    }
</allIDS>

let $nodes :=
<ids>
            {
                for $distinctId in distinct-values($data//id)
                 let $collection :=
                switch (substring($distinctId, 0, 4))
                    case 'LOC'
                        return
                            'places'
                    case 'LIT'
                        return
                            'works'
                    case 'PRS'
                        return
                            'persons'
                            case 'ETH'
                        return
                            'persons'
                    case 'NAR'
                        return
                            'narratives'
                    case 'INS'
                        return
                            'institutions'
                            case 'gn:'
                         return
                            'http://www.geonames.org/'
                    default return
                        'manuscripts'
               
            let $filetitle :=
            try {
            
            
            
             let $title :=  
                                            if (contains($distinctId, 'bm')) then (
                                            rels:getZoteroTextData($distinctId)
(:                                            could be made to look at the title in zotero:)
                                            )
                                            
                                            else if (starts-with($distinctId, 'gn:'))
                                               then (titles:getGeoNames($distinctId))
             
                                      (:   else if (contains($distinctId, '#'))  then (
                          
(\:                          consider if there is an id, and if this has a title which can be used as label :\)
                                              let $id := substring-after($distinctId, '#')
                                                  let $element := doc(concat($config:data-root, '/', $collection, '/', 
                                                             (if (contains($distinctId, '#')) 
                                                             then substring-before($distinctId, '#') 
                                                             else $distinctId ), '.xml'))//t:*[@xml:id= $id]
                          
                                                      return
                        
                                              try{  if ($element//t:label/text()) then $element//t:label/text()
                                               else $element/text()}
                                               catch * { $id}
                                            ):)

                                       else (
(:                          use the main name of the file:)
                          
                                    normalize-space(titles:printTitle(collection($config:data-root)//id(if (contains($distinctId, '#')) 
                                                    then substring-before($distinctId, '#') 
                                                   else $distinctId ))) ||
(                                                   if (contains($distinctId, '#')) 
                                                    then substring-after($distinctId, '#') 
                                                   else ()
                                                   )
                                )
             
             
                                             
              let $substring := if (string-length(replace($title, '"', '')) gt 20) then concat(substring(replace($title, '"', ''), 0, 20), '...') else replace($title, '"', '')
              return $substring
            }
            catch * {
                $distinctId
            }
            
            
            return
                
                <node>
                    {
                        ('{id:"' || $distinctId || '", label:"' || $filetitle ||  '", group:"' || $collection ||
                        '"},')
                    }
                </node>
        
        }
    
    </ids>

return
<all>
<nodes>{$nodes//node/text()}</nodes>
<edges>{$data//edge/text()}</edges>
</all>

return

('var nodes = new vis.DataSet([' || $all//nodes||']);'||
'var edges = new vis.DataSet([' || $all//edges||']);' ||
'var options = {layout:{randomSeed:'||string($localId)|| '}};')
               
          
};

declare function rels:EntityRelsTable($node as node(), $model as map(*)){

                        <table class="table table-hover" width="100%"  xmlns="http://www.w3.org/1999/xhtml">
                            <thead>
                                <tr>
                                    <th>Subject</th>
                                    <th>Relation</th>
                                    <th>Object</th>
                                    <th>Description</th>
                                </tr>
                            </thead>
                            <tbody>

{for $relation in $model('entity')//t:relation[@name][(@active and @passive) or @mutual]
return
                                    <tr>
                                        <th>
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
                
                for $id in $list//id
                return
                <a href="{concat('http://betamasaheft.aai.uni-hamburg.de/',$id)}" class="MainTitle" data-value="{$id}">{$id}</a>
                
                
    }
                                            
                                        </th>
                                        <th>
                                            {data($relation/@name)}
                                        </th>
                                        <th>
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
                for $id in $list/id
                return
                <a href="{concat('http://betamasaheft.aai.uni-hamburg.de/',$id)}" class="MainTitle" data-value="{$id}">{$id}</a>
                
                
    }
                                           
                                        </th>
                                        <th>
{                                            transform:transform($relation/t:desc, 'xmldb:exist:///db/apps/BetMas/xslt/relation.xsl',())

}
                                        </th>
                                    </tr>
                                    }
                            </tbody>
                        </table>
                        

};

