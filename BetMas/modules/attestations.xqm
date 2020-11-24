xquery version "3.1" encoding "UTF-8";
(:~
 : module retrieving a list of attestation of an entity in others.
 : 
 : @author Pietro Liuzzo 
 :)
module namespace att = "https://www.betamasaheft.uni-hamburg.de/BetMas/att";
import module namespace rest = "http://exquery.org/ns/restxq";
import module namespace api = "https://www.betamasaheft.uni-hamburg.de/BetMas/api" at "xmldb:exist:///db/apps/BetMas/modules/rest.xqm";
import module namespace titles="https://www.betamasaheft.uni-hamburg.de/BetMas/titles" at "xmldb:exist:///db/apps/BetMas/modules/titles.xqm";
import module namespace config = "https://www.betamasaheft.uni-hamburg.de/BetMas/config" at "xmldb:exist:///db/apps/BetMas/modules/config.xqm";
import module namespace string = "https://www.betamasaheft.uni-hamburg.de/BetMas/string" at "xmldb:exist:///db/apps/BetMas/modules/tei2string.xqm";

declare namespace t = "http://www.tei-c.org/ns/1.0";

(: For REST annotations :)
declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace json = "http://www.json.org";
declare namespace test="http://exist-db.org/xquery/xqsuite";


 declare function att:stringDates($nodes){
            let $strings := for $d in $nodes return string:tei2string($d) 
            return string-join($strings, ', ')
            };


    

(:given a  id returns the attestations and cooccurring entities:)
declare

%rest:GET
%rest:path("/BetMas/api/attestations/{$type}/{$id}")
%output:method("json")
%test:args("PRS8249Ruppell","person") %test:assertExists
function att:attestations($id as xs:string*, $type as xs:string*)
{
let $ty := switch($type)
case 'person' return 't:persName[@ref'
case 'place' return 't:placeName[@ref'
case 'work' return 't:title[@ref'
case 'mss' return 't:ref[@type eq "mss"][@corresp'
case 'term' return 't:term[@key'
default return 't:persName'

let $attestations:= api:restWhatPointsHere($id, $titles:collection-root)
let $hits :=
for $att in $attestations
let $rootID := string(root($att)/t:TEI/@xml:id) 
group by $MAINID := $rootID
return
if($MAINID = $id) then () else 
let $titleRoot := titles:printTitleMainID($MAINID)
let $atts := 
   for $a at $p in $att 
   let $element := $a/name()
   let $text := if($a/text()) 
                 then $a/text() 
                 else if ($a/t:label)
                 then string:tei2string($a/t:label)
                 else 'pointer only'
    let $cooccurringPers := ($a/preceding-sibling::t:persName,$a/following-sibling::t:persName)
    let $cooccurringPlace := ($a/preceding-sibling::t:placeName,$a/following-sibling::t:placeName)
    let $cooccurringworks := ($a/preceding-sibling::t:title,$a/following-sibling::t:title)
    let $cooccurringterm := ($a/preceding-sibling::t:term,$a/following-sibling::t:term)
    let $date := if($a/ancestor::t:item[1]//t:date) 
                  then att:stringDates($a/ancestor::t:item[1]//t:date)
                  else if($a/ancestor::t:msItem//t:date) 
                  then att:stringDates($a/ancestor::t:msItem[1]//t:date) 
                  else if($a/ancestor::t:handNote//t:date) 
                  then att:stringDates($a/ancestor::t:handNote[1]//t:date) 
                  else if($a/ancestor::t:decoNote//t:date) 
                  then att:stringDates($a/ancestor::t:decoNote[1]//t:date) 
                  else 'no date'
    let $MainRole := switch($element) 
    case 'persName' return string($a/@role)
    case 'div' return string($a/@type) || ' - ' || string($a/@subtype)
    case 'relation' return string($a/@name)
    case 'ref' return string($a/@type)
    default return ()
let $titles := ($a/t:roleName, $a/t:addName)
let $alltitles := for $t in $titles return $t/name() || ': ' || $t/text()
let $jointitles := string-join($alltitles, ', ')
let $occpers := if(count($cooccurringPers) gt 0) then 
(let $persons := for $pers in $cooccurringPers 
let $id := if($pers/@ref) then string($pers/@ref) else 'no-id'
         let $name := 
              if($pers/text())
              then $pers/text() 
              else titles:printTitleMainID($pers/@ref)
        let $thisrole := 
              if($pers/@role) 
              then string($pers/@role) 
              else () 
       return map {'id' : $id ,'name' : $name, 'type' : $thisrole}
return 
map {'type' : 'persons', 'persons' : $persons}
)
else ()
let $occplace := if(count($cooccurringPlace) gt 0) then 
(let $places := for $place in $cooccurringPlace
let $id := if($place/@ref) then string($place/@ref) else 'no-id'
         let $name := 
              if($place/text())
              then $place/text() 
              else titles:printTitleMainID($place/@ref)
        let $thistype := 
              if($place/@type) 
              then string($place/@type)
              else () 
       return map {'id' : $id ,'name' : $name, 'type' : $thistype}
return 
map {'type' : 'places', 'places' : $places}
)
else ()
let $occwork := if(count($cooccurringworks) gt 0) then 
(let $works := for $work in $cooccurringworks 
let $id := if($work/@ref) then string($work/@ref) else 'no-id'
         let $name := 
              if($work/text())
              then $work/text() 
              else titles:printTitleMainID($work/@ref)
        
       return map {'id' : $id , 'name' : $name}
return 
map {'type' : 'works', 'works' : $works}
)
else ()
let $occterm := if(count($cooccurringterm) gt 0) then 
(let $terms := for $term in $cooccurringterm 
let $id := if($term/@key) then string($term/@key) else 'no-id'
          let $name := 
              if($term/text() and $term/@key)
              then $term/text()
              else if (not($term/@key)) then $term/text()
              else titles:printTitleMainID($term/@key)
       
       return map {'id' : $id ,'name' : $name}
return 
map {'type' : 'terms', 'terms' : $terms}
)
else ()
let $occurrences := ($occpers, $occplace, $occwork, $occterm)



return 
map {'position' : $p, 
'role' : $MainRole,
'text' : $text,
'element' : $element,
'date' : $date,
'jointitles' : $jointitles,
'occurrences' : $occurrences
}


return 
map {'result' : $atts, 'title' : $titleRoot, 'id' : $MAINID }

return


($api:response200Json,
map {'query' : $id, 'results' : $hits }

)
};
