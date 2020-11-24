xquery version "3.1" encoding "UTF-8";
(:~
 : returns maps of nodes and edges for a given entity
 : 
 : @author Pietro Liuzzo 
 :)
module namespace NE = "https://www.betamasaheft.uni-hamburg.de/BetMas/NE";
import module namespace rest = "http://exquery.org/ns/restxq";
import module namespace switch2 = "https://www.betamasaheft.uni-hamburg.de/BetMas/switch2"  at "xmldb:exist:///db/apps/BetMas/modules/switch2.xqm";
import module namespace api = "https://www.betamasaheft.uni-hamburg.de/BetMas/api"  at "xmldb:exist:///db/apps/BetMas/modules/rest.xqm";
import module namespace titles="https://www.betamasaheft.uni-hamburg.de/BetMas/titles" at "xmldb:exist:///db/apps/BetMas/modules/titles.xqm";
import module namespace config = "https://www.betamasaheft.uni-hamburg.de/BetMas/config" at "xmldb:exist:///db/apps/BetMas/modules/config.xqm";
import module namespace string = "https://www.betamasaheft.uni-hamburg.de/BetMas/string" at "xmldb:exist:///db/apps/BetMas/modules/tei2string.xqm";

(: namespaces of data used :)

declare namespace t = "http://www.tei-c.org/ns/1.0";

import module namespace http="http://expath.org/ns/http-client";

(: For REST annotations :)
declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace json = "http://www.json.org";

(:~gets the a json object containing an array of objects related to the given id. the array will contain the requested entity as a node and any one retrived using the function api:restWhatPointsHere() with the properties id label and group properties. it is thought to be used in combination with the edges for graph visualization :)
declare
%rest:GET
%rest:path("/BetMas/api/relations/{$id}")
%output:method("json")
function NE:relNodes($id as xs:string*){

let $entity := $titles:collection-root/id($id)
let $type := $entity/@type
let $collection := switch2:col($type)

let $localId := $id
let $thisMap := map {
        "id" :  $id, 
        "label" : titles:printTitleID($id), 
        "group" : string($type)
        }

let $whatpointshere := api:restWhatPointsHere($localId, $titles:collection-root)

let $refs := ($entity//@ref[not(./ancestor::t:respStmt)], $entity//@active, $entity//@passive)
let $secondaryrelations := 
for $id in config:distinct-values($refs[.!=$localId]) return 
(:exclude empty values :)
if($id ='') then () 
else if(starts-with($id,'INS')) then () 
else if(contains($id,' ')) then () 
else 
    let $whatppointstothat := api:restWhatPointsHere($id, $titles:collection-root) 
    return
        (:if more than 10 items are related then it is unlikely to be relevant:)
    if(count($whatppointstothat) gt 10) then () else $whatppointstothat

let $wph := 
    let $ids := for $pointerRoot in ($whatpointshere, $secondaryrelations)
                let $refid := root($pointerRoot)/t:TEI/@xml:id
                return $refid
    let $allids :=($ids, $refs)
    let $distincts :=  config:distinct-values($allids)
    for $I in $distincts
    let $cleanId := if(contains($I, '#')) then substring-before($I,  '#') else $I
(:    let $thisI := $c//id($cleanId)[name()='TEI']:)
    let $rootype := switch2:switchPrefix($cleanId)
    let $title := if(contains($I, '#')) then titles:printTitleID($I) else titles:printTitleMainID($I)
    let $titleN := if(count($title) gt 1) then normalize-space(string-join($title, ' ')) else normalize-space($title)
    return 
      (:first return the root of the referring entity and the id in the corresp, active, passive, mutual, etc. there.:)
     map {
        "id" : $I, 
        "label" :  $titleN,
        "group" : $rootype
        }

let $here := 
    (: from the current item to the entities it points to :)
    for $id in $refs 
    let $elem := $id/parent::t:*
    let $pN := name($elem)
        let $name := if($pN = 'relation') then string($elem/@name) else $pN
        return
    map {'from': $localId, 
      'to': $id/string(), 
      'label': $name, 
      'value': 1, 
      'font':  map {'align':  'top'}}
      let $there :=
 (:from what points here to the current item:)
      for $id in $secondaryrelations 
      let $r := root($id)/t:TEI/@xml:id
      let $refname := name($id)
      let $name := if($refname = 'relation') then string($id/@name) else $refname
      let $R := if($refname = 'witness') then string($id/@corresp) else if($refname = 'relation') then if($refs = $id/@active) then  string($id/@active) else string($id/@passive) else string($id/@ref)
        return
    map {'from': string($r), 
      'to': $R, 
      'label' :  $name,
      'value':  1, 
      'font':  map {'align':  'top'}}
  let $tohere :=
 (:from what points here to the current item:)
      for $id in $whatpointshere 
      let $r := root($id)/t:TEI/@xml:id
      let $refname := name($id)
      let $name := if($refname = 'relation') then string($id/@name) else $refname
     
        return
    map {'from':  string($r), 
      'to': $localId, 
      'label' :  $name,
      'value':  1, 
      'font':  map {'align':  'top'}}
      
      let $edges := ($here, $there, $tohere)
      let $idswph :=  for $x in $wph return $x('id')
      let $nodes := if($idswph = $id) then $wph else ($thisMap, $wph)
return
(:returns the title and id of the entities referring to this entity or entity referring to those pointing to the entity:)
  ($api:response200Json,
 map {'nodes' :   $nodes,
 'edges' :   $edges,
     'cN' :  count($nodes),
     'cE' :  count($edges)
 })
};