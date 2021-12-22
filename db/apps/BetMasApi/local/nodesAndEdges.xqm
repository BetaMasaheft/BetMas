xquery version "3.1" encoding "UTF-8";
(:~
 : returns maps of nodes and edges for a given entity
 : 
 : @author Pietro Liuzzo 
 :)
module namespace NE = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/NE";
import module namespace rest = "http://exquery.org/ns/restxq";
import module namespace switch2 = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/switch2" at "xmldb:exist:///db/apps/BetMasWeb/modules/switch2.xqm";
import module namespace exptit = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/exptit" at "xmldb:exist:///db/apps/BetMasWeb/modules/exptit.xqm";
import module namespace config = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/config" at "xmldb:exist:///db/apps/BetMasWeb/modules/config.xqm";
import module namespace string = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/string" at "xmldb:exist:///db/apps/BetMasWeb/modules/tei2string.xqm";
import module namespace what = "https://www.betamasaheft.uni-hamburg.de/BetMasApi/what" at "xmldb:exist:///db/apps/BetMasApi/local/whatpointshere.xqm";

(: namespaces of data used :)

declare namespace t = "http://www.tei-c.org/ns/1.0";
import module namespace http = "http://expath.org/ns/http-client";
(: For REST annotations :)
declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace json = "http://www.json.org";

declare option output:method "json";
declare option output:indent "yes";

(:~gets the a json object containing an array of objects related to the given id. the array will contain the requested entity as a node and any one retrived using the function api:restWhatPointsHere() with the properties id label and group properties. it is thought to be used in combination with the edges for graph visualization :)
declare
%rest:GET
%rest:path("/api/relations/{$localId}")
%output:method("json")
function NE:relNodes($localId as xs:string*) {
    let $uri := $config:baseURI || $localId
    let $entity := $exptit:col/id($localId)[self::t:TEI]
    let $type := $entity/@type
    let $collection := switch2:col($type)
    
    let $thisMap := map {
        "id": $uri,
        "label": exptit:printTitleID($localId),
        "group": string($type)
    }
    
    let $whatpointshere := what:PointsHere($localId, $exptit:col)
    
    
    let $refs := ($entity//@ref[not(./ancestor::t:respStmt)], $entity//@active, $entity//@passive)
(:    let $log := util:log('info', $refs):)
    
    
    let $secondaryrelations := 
    for $id in config:distinct-values($refs[. != $uri])
(:    let $logid := util:log('info', $id):)
    let $ins := $config:baseURI || 'INS'
    return
    try {
        (:exclude empty values :)
        if ($id = '') then
            ()
        else
            if (starts-with($id, $ins)) then
                ()
            else
                if (contains($id, ' ')) then
                    ()
                else
                    let $whatppointstothat := what:PointsHere($id, $exptit:col)
(:                       let $log0 := util:log('info',  $whatppointstothat):)
                    return
                        (:if more than 10 items are related then it is unlikely to be relevant:)
                        if (count($whatppointstothat) gt 10) then
                            ()
                        else
                            $whatppointstothat } catch * {util:log('info', $err:description)}
        
        
    let $wph :=
    let $ids := for $pointerRoot in ($whatpointshere, $secondaryrelations)
                       let $refid := string(root($pointerRoot)/t:TEI/@xml:id)
                        return
                               'https://betamasaheft.eu/' || $refid
    let $allids := ($ids, $refs)
(:    let $log2 := util:log('info', $allids):)
    let $distincts := distinct-values($allids)
    for $I in $distincts
    let $cleanId := if (contains($I, '#')) then
        substring-before($I, '#')
    else
        string($I)
(:         let $log3 := util:log('info', $cleanId):)
    let $rootype := switch2:switchPrefix($cleanId)
    let $title :=  exptit:printTitle($I)
    let $titleN := if (count($title) gt 1) then
        normalize-space(string-join($title, ' '))
    else
        normalize-space($title)
    return
        (:first return the root of the referring entity and the id in the corresp, active, passive, mutual, etc. there.:)
        map {
            "id": $I,
            "label": $titleN,
            "group": $rootype
        }
       
(:    let $log4 := util:log('info', $wph):)


    let $here :=
    (: from the current item to the entities it points to :)
    for $id in $refs
    let $elem := $id/parent::t:*
    let $pN := name($elem)
    let $name := if ($pN = 'relation') then
        string($elem/@name)
    else
        $pN
    return
        map {
            'from': $uri,
            'to': $id/string(),
            'label': $name,
            'value': 1,
            'font': map {'align': 'top'}
        }
(:            let $log4 := util:log('info', $here):)


    let $there :=
    (:from what points here to the current item:)
    for $id in $secondaryrelations
    let $r := string(root($id)/t:TEI/@xml:id)
    let $refname := name($id)
    let $name := if ($refname = 'relation') then
        string($id/@name)
    else
        $refname
    let $R := if ($refname = 'witness') then
        string($id/@corresp)
    else
        if ($refname = 'relation') then
            if ($refs = $id/@active) then
                string($id/@active)
            else
                string($id/@passive)
        else
            string($id/@ref)
    return
        map {
            'from': ($config:baseURI || string($r)),
            'to': $R,
            'label': $name,
            'value': 1,
            'font': map {'align': 'top'}
        }
        
(:            let $log5 := util:log('info', $there):)


    let $tohere :=
    (:from what points here to the current item:)
    for $id in $whatpointshere
    let $r := string(root($id)/t:TEI/@xml:id)
    let $refname := name($id)
    let $name := if ($refname = 'relation') then
        string($id/@name)
    else
        $refname
    
    return
        map {
            'from': ($config:baseURI || string($r)),
            'to': $uri,
            'label': $name,
            'value': 1,
            'font': map {'align': 'top'}
        }
    
(:            let $log4 := util:log('info', $tohere):)
    let $edges := ($here, $there, $tohere)
    let $idswph := for $x in $wph
    return
        $x('id')
    let $nodes := if ($idswph = $localId) then
        $wph
    else
        ($thisMap, $wph)
    return
        (:returns the title and id of the entities referring to this entity or entity referring to those pointing to the entity:)
        ($config:response200Json,
        map {
            'nodes': $nodes,
            'edges': $edges,
            'cN': count($nodes),
            'cE': count($edges)
        })
};
