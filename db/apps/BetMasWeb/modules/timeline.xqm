xquery version "3.0" encoding "UTF-8";

module namespace tl="https://www.betamasaheft.uni-hamburg.de/BetMasWeb/timeline";
import module namespace config="https://www.betamasaheft.uni-hamburg.de/BetMasWeb/config" at "xmldb:exist:///db/apps/BetMasWeb/modules/config.xqm";
import module namespace exptit="https://www.betamasaheft.uni-hamburg.de/BetMasWeb/exptit" at "xmldb:exist:///db/apps/BetMasWeb/modules/exptit.xqm";
import module namespace apprest = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/apprest" at "xmldb:exist:///db/apps/BetMasWeb/modules/apprest.xqm";
import module namespace console="http://exist-db.org/xquery/console";

declare namespace t="http://www.tei-c.org/ns/1.0";
declare option exist:serialize "method=text mediatype=text/javascript";


(:Item timeline extracted  from all stated dates in item and related entities. first ids are listed with data in a temporary tree and then functions are used to output the javascript as text:)
declare function tl:RestEntityTimeLine($this, $collection) {

let $itemid := $this/@xml:id
let $whatpointshere := apprest:WhatPointsHere($itemid, $exptit:col)
let $data :=
let $dateManuscripts :=
let $dateofThisManuscript := $this//t:origDate[@when or (@notBefore or @notAfter)]
let $datesofRelatedManuscripts := for $ref in config:distinct-values($this//@ref[not(matches(., '\w{3}\d+\w+'))][not(starts-with(., 'wd:'))][not(starts-with(., 'pleiades:'))])
return doc(($config:data-rootMS || '/' ||string($ref)|| '.xml'))//t:origDate[@when or (@notBefore or @notAfter)]
let $datesofcitingMss := for $citingms in config:distinct-values($whatpointshere[ancestor::t:TEI[@type eq 'mss']]/ancestor::t:TEI/@xml:id) return doc(($config:data-rootMS || '/' ||string($citingms)|| '.xml'))//t:origDate[@when or (@notBefore or @notAfter)]
for $date in ($dateofThisManuscript, $datesofRelatedManuscripts, $datesofcitingMss)
return
tl:date($date, 'obj')

let $dateInManuscripts :=
let $dateinthisms := $this//t:date[@when or @notBefore or @notAfter]
let $datesinRelatedManuscripts := for $ref in config:distinct-values($this//@ref[not(matches(., '\w{3}\d+\w+'))][not(starts-with(., 'wd:'))][not(starts-with(., 'pleiades:'))])
return doc(($config:data-rootMS || '/' ||string($ref)|| '.xml'))//t:date[@when or @notBefore or @notAfter]
let $datesIncitingMss := for $Incitingms in config:distinct-values($whatpointshere[ancestor::t:TEI[@type eq 'mss']]/ancestor::t:TEI/@xml:id) return doc(($config:data-rootMS || '/' ||string($Incitingms)|| '.xml'))//t:date[@when or @notBefore or @notAfter]

for $date in ($dateinthisms, $datesinRelatedManuscripts, $datesIncitingMss)
return
tl:date($date, 'obj')


let $datePersons :=
let $datesOfThisPerson := $this//t:person[t:birth[@evidence eq  "internal"][@when or @notBefore or @notAfter] or t:death[@evidence eq  "internal"][@when or @notBefore or @notAfter] or t:floruit[@evidence eq  "internal"][@when or @notBefore or @notAfter]]
let $datesofRelatedPersons := for $ref in config:distinct-values($this//@ref[starts-with(.,'PRS')])
return doc(($config:data-rootPr || '/' ||string($ref)|| '.xml'))//t:person[t:birth[@evidence eq  "internal"][@when or @notBefore or @notAfter] or t:death[@evidence eq  "internal"][@when or @notBefore or @notAfter] or t:floruit[@evidence eq  "internal"][@when or @notBefore or @notAfter]]
let $datesIncitingPrs := for $citingpr in config:distinct-values($whatpointshere[ancestor::t:TEI[@type eq 'pers']]/ancestor::t:TEI/@xml:id) return doc(($config:data-rootPr || '/' ||string($citingpr)|| '.xml'))//t:person[t:birth[@evidence eq  "internal"][@when or @notBefore or @notAfter] or t:death[@evidence eq  "internal"][@when or @notBefore or @notAfter] or t:floruit[@evidence eq  "internal"][@when or @notBefore or @notAfter]]

for $datep in ($datesOfThisPerson, $datesofRelatedPersons)
let $root := $datep/ancestor::t:TEI
(:collect all ids:)
return
tl:date($datep, 'prs')
    
    (:  
        :)
return
    <all>
        <links>
            {
                for $dateManuscript in ($dateManuscripts, $dateInManuscripts)
                return
                   
                    tl:link($dateManuscript, 'obj', 'e') 
                    }
            
            {
                for $datePerson in $datePersons
                return
                    tl:link($datePerson, 'prs', 'e') 
            }
        </links>
        <dates>
            {
                for $dateManuscript in ($dateManuscripts, $dateInManuscripts)
               return
                    tl:dateObj($dateManuscript, 'obj')
                    }
            {
                for $datePerson in $datePersons
                return
                   tl:dateObj($datePerson, 'prs')
            }
        </dates>
    </all>

return
    tl:js($data, 'entity')
    
    };


(:builds objects with the id, content, start and end. end can be empty, but tl:js will replace those with a type point option instead:)
declare function tl:dateObj($date as node(), $mode as xs:string) {
    switch ($mode)
 case 'prs' return  ('{id:"' || $date/item || '", group: "persons", content: ' || $date/item || ', start: "' || $date//from || '", end: "' || $date//to || '"},')
 case 'work' return ('{id:"' || $date/item || '#' || $date/location || '",  group: "works", content: ' || $date/item || '_' || $date/location || ', start: "' || $date//from || '", end: "' || $date//to || '"},')
    default return                ('{id:"' || 'date'   || $date/evidence ||$date/item || '#' || $date/location || '_' ||substring(replace(tl:resp($date/resp), ' ', ''), 1, 5)|| '",  group: "manuscripts", content: ' || $date/item || '_' || $date/location || '_' ||  substring(replace(tl:resp($date/resp), ' ', ''), 1, 5) || ', start: "' || $date//from || '", end: "' || $date//to || '"},')
           
    };
    
(:builds varibles containing the links and labels of such links:)
declare function tl:link($date as node(), $mode as xs:string, $context as xs:string){
        let $label := switch ($context)
            case 'g' return ('<a href="'|| $date/item || '#' || $date/location || '">' ||  $date/name || "</a>" )
            default return ('<a href="'|| $date/item || '#' || $date/location || '">' || 'Date of '|| $date/name ||( if ($date/location) then ', ' || $date/location else ()) || (if ($date/resp/text()) then ' according to '|| tl:resp($date/resp) else ()) ||  (if ($date/evidence/text()) then' based on ' || $date/evidence else ()) || "</a>" )
            return
       switch ($mode)
       case 'prs' return  ('var ' || $date/item ||  "= '" || '<a href="'|| $date/item || '">' || $date/name || "</a>'; ")
      case 'work' return ('var ' || $date/item || '_' || $date/location || "= '" || '<a href="'|| $date/item || '#' || $date/location || '">' || $date/name || "</a>'; ")
      default return             ('var ' || $date/item || '_' || $date/location|| '_' || substring(replace(tl:resp($date/resp), ' ', ''), 1, 5) ||  "= '" || normalize-space($label)|| "'; ")
           
        };
    
(:    checks the name of resps and return a string join of them if more then one:)
    declare function tl:resp($node){
     let $resps :=if(starts-with($node, 'bm_')) then (<span class="Zotero Zotero-citation">{$node}</span>) else if ($node) then (for $r in $node  return <r>{normalize-space(exptit:printTitle(collection($config:data-rootPr)/id($r)))}</r>) else ()
     return
     <resps>{if(starts-with($node, 'bm_')) then $resps else string-join($resps, ' and ')}</resps>
    };

(:constructs the main variables needed by timeline:)
declare function tl:js($data as node(), $mode as xs:string){
let $options := "end: 2016,
    // groupOrder: 'content',
      autoResize: true,
      //configure: true,
      "
    
let $periods := "
    {id: 'preAks', content: 'Pre Aksumite phase', start: '-0800', end: '0100', type: 'background', className:'Fattovich preAks'},    
    {id: 'preAks1', content: 'Pre Aksumite phase', start: '-0800', end: '0100', type: 'background', className:'Phillipson preAks'},
        {id: 'pPreAks', content: 'proper Pre-Aksumite Phase South Arabian Phase', start: '-0700', end: '-0300', type: 'background', className: 'Finneran pPreAks'},
    {id: 'ProtoAks', content: 'Proto Aksumite Phase', start: '-0300', end: '0200', type: 'background', className: 'Finneran ProtoAks' },
    {id: 'Aks', content: 'Aksumite Phase', start: '0100', end: '0700', type: 'background', className: 'Finneran Aks'},
    {id: 'postAks', content: 'Post Aksumite Phase', start: '0700', end: '1137', type: 'background', className: 'Finneran postAks'},
    {id: 'Zagwe', content: 'Zagwe Dynasty', start: '1137', end: '1225', type: 'background', className: 'Finneran Zagwe'},
    {id: 'Solomonic', content: 'Solomonic Period', start: '1270', end: '1769', type: 'background', className: 'Finneran Solomonic'},
    {id: 'earlySolomonic', content: 'Early Solomonic Period', start: '1270', end: '1500', type: 'background', className: 'Bausi portuguese'},
    {id: 'invasions', content: 'The period of the Islamic and Oromo invasions<br> and of early contacts with Europe ', start: '1501', end: '1600', type: 'background', className: 'Bausi invasions'},
    {id: 'portoguese', content: 'Period of Portuguese Jesuite Missionaries', start: '1501', end: '1700', type: 'background', className: 'Bausi portuguese'},
    {id: 'gondarine', content: 'Gondarine Period', start: '1632', end: '1769', type: 'background', className: 'Bausi Gondarine'},
    {id: 'Zemana', content: 'Zamana Masāfǝnt, Era of the Judges (Princes)', start: '1769', end: '1855', type: 'background', className: 'Finneran Zemana'},
    {id: 'Imperial', content: 'Later Imperial Period', start: '1855', end: '1974', type: 'background', className: 'Finneran Imperial'},
    {id: 'Dergue', content: 'Dergue', start: '1974', end: '1991', type: 'background', className: 'Finneran Dergue'},
    {id: 'Democratic', content: 'Democratic Government', start: '1991', end: '', type: 'background', className: 'Finneran Democratic'},"
    
let $buttonFunctions := "
document.getElementById('aksumite').onclick = function() {
    timeline.setWindow('0100', '0700');
  };
  document.getElementById('zagwe').onclick = function() {
    timeline.setWindow('1137', '1225');
  };
document.getElementById('solomonic').onclick = function() {
    timeline.setWindow('1270', '1500');
  };
document.getElementById('invasions').onclick = function() {
    timeline.setWindow('1501', '1600');
  };
  document.getElementById('earlysolomonic').onclick = function() {
    timeline.setWindow('1270', '1769');
  };
document.getElementById('gondarine').onclick = function() {
    timeline.setWindow('1632', '1769');
  };
document.getElementById('judges').onclick = function() {
    timeline.setWindow('1769', '1855');
  };  
document.getElementById('imperial').onclick = function() {
    timeline.setWindow('1855', '1974');
  };
  
  "
    
    return
(
    "var container = document.getElementById('timeLine'); " ||
    
    $data//links ||
    " 
    var groups = new vis.DataSet([
    {id: 'persons', content: 'Persons'},
    {id: 'works', content: 'Works'},
    {id: 'manuscripts', content: 'Manuscripts'}
  ]);
  
    var items = new vis.DataSet(["
    
    || 
     (if ($mode = 'general') then $periods else ())
    ||
    
    replace($data//dates, ', end: ""', ', type: "box"') ||
    "]); " ||
    "var options = {
    " || 
    (if ($mode = 'general') then $options else ())
    ||"

      clickToUse: true,
    orientation: 'top'    }; " ||
    "var timeline = new vis.Timeline(container); 
timeline.setOptions(options);
  // timeline.setGroups(groups);
  timeline.setItems(items);
  
    "|| 
    (if ($mode = 'general') then $buttonFunctions else ())
    )
};



(:builds a temporary date object ready for use in js serialization:)
declare function tl:date($date as node(), $mode as xs:string) {
let $root := $date/ancestor::t:TEI
let $rid:=string($root/@xml:id)
(:collect all ids:)
let $tree := 
<date>
        <item>
            {$rid}
        </item>
        <name>
             {exptit:printTitleID($rid)}
        </name>
        <location>
            {string($date/ancestor::t:*[@xml:id][1]/@xml:id)}
        </location>
        <evidence>{string($date/@evidence)}</evidence>
        {if($date/@resp) then for $d in tokenize($date/@resp, ' ') return <resp>{string($d)}</resp> else for $d in $date//t:bibl/t:ptr return <resp>{replace(string($d/@target), ':', '_')}</resp> }
        {switch($mode)
case 'prs' return

if ($date[t:birth[@when or @notBefore or @notAfter] and t:death[@when or @notBefore or @notAfter]]) then
        
<range><from>
            {
                if ($date/t:birth/@notBefore)
                then
                    string($date/t:birth/@notBefore)
                else
                    if ($date/t:birth/@when)
                    then
                        string($date/t:birth/@when)
                    else
                        $date/t:birth/text()
            }
        </from><to>{
                if ($date/t:death/@notAfter)
                then
                    string($date/t:death/@notAfter)
                else
                    if ($date/t:death/@when)
                    then
                        string($date/t:death/@when)
                    else
                        $date/t:death/text()
            }
        </to>
        </range>
        
        
        else if ($date[t:birth[@when or @notBefore or @notAfter] and not(t:death)]) then
        <range><from>
            {
                if ($date/t:birth/@notBefore)
                then
                    string($date/t:birth/@notBefore)
                else
                    if ($date/t:birth/@when)
                    then
                        string($date/t:birth/@when)
                    else
                        ()
            }
        </from><to>{
                if ($date/t:birth/@notAfter)
                then
                    string($date/t:birth/@notAfter)
                else
                    if ($date/t:birth/@when)
                    then
                        string($date/t:birth/@when)
                    else
                        ()
            }
        </to></range>
        
        else if ($date[not(t:birth) and t:death[@when or @notBefore or @notAfter]]) then
        <range><from>
            {
                if ($date/t:death/@notBefore)
                then
                    string($date/t:death/@notBefore)
                else
                    if ($date/t:death/@when)
                    then
                        string($date/t:death/@when)
                    else
                       ()
            }
        </from><to>{
                if ($date/t:death/@notAfter)
                then
                    string($date/t:death/@notAfter)
                else
                    if ($date/t:death/@when)
                    then
                        string($date/t:death/@when)
                    else
                        ()
            }
        </to></range>
        
        else if ($date[t:floruit[@notBefore or @notAfter]]) then
        <range><from>
            {
                if ($date/t:floruit/@notBefore)
                then
                    string($date/t:floruit/@notBefore)
                else
                    
                        ()
            }
        </from>
        <to>
            {
                if ($date/t:floruit/@notAfter)
                then
                    string($date/t:floruit/@notAfter)
                else
                   
                        ()
            }
        </to></range>
        
        else if ($date[t:floruit[@when]]) then
        <range><from>
            {
                        string($date/t:floruit/@when)
                 }
        </from>
      </range>
        
        else ()
    

default return
            
        
            if ($date[@notBefore and @notAfter]) then
                <range><from>
                        {string($date/@notBefore)}
                    </from>
                    <to>
                        {string($date/@notAfter)}
                    </to>
                </range>
            else
                if ($date[@notBefore and not(@notAfter)]) then
                    <from>
                        {string($date/@notBefore)}
                    </from>
                else
                    if ($date[@notAfter and not(@notBefore)]) then
                        <from>
                            {string($date/@notAfter)}
                        </from>
                    else
                        if ($date[@when]) then
                            <from>
                                {string($date/@when)}
                            </from>
                            
                        else
                            ()
        
        }
    </date>

return $tree

};

