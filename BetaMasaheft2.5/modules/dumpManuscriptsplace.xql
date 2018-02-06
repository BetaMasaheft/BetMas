xquery version "3.1";

declare namespace t="http://www.tei-c.org/ns/1.0";
import module namespace http = "http://expath.org/ns/http-client";
import module namespace app="https://www.betamasaheft.uni-hamburg.de/BetMas/app" at "app.xqm";
import module namespace places = "https://www.betamasaheft.uni-hamburg.de/BetMas/places" at "places.xql";
import module namespace titles="https://www.betamasaheft.uni-hamburg.de/BetMas/titles" at "titles.xqm";
import module namespace config = "https://www.betamasaheft.uni-hamburg.de/BetMas/config" at "config.xqm";
import module namespace all = "https://www.betamasaheft.uni-hamburg.de/BetMas/all" at "all.xqm";
import module namespace console = "http://exist-db.org/xquery/console";


let $c := collection($config:data-rootMS)
let $placeNames := $c//t:placeName[starts-with(@ref, 'LOC') or starts-with(@ref, 'Q') or starts-with(@ref, 'pleiades')]
let $repositories:= $c//t:repository[starts-with(@ref, 'INS')]
let $data := ($placeNames, $repositories)
 let $annotations :=
 for $d in $data 
 group by $r := root($d)//t:TEI/@xml:id
let $tit := titles:printTitleID(string($r))
 order by $r
 return
 
 <annotatedThing id="{$r}">
 
            
             {places:ThisAnnotatedThing($r, $tit, 'manuscripts')}
   
   <annotations>
 {for $thisd at $x in $d
 return
 places:annotation($thisd, $r, $x, 'manuscripts')
 }
 </annotations>
 </annotatedThing>

let $file :=
( $places:prefixes
        || string-join($annotations//text())
)
let $filename := 'allmanuscripts.ttl'
return
    xmldb:store('/db/apps/BetMas/ttl', $filename, $file )
        

