xquery version "3.1" encoding "UTF-8";
(:~
 : module with all the main functions which can be called by the API.
 : 
 : @author Pietro Liuzzo 
 :)
module namespace what = "https://www.betamasaheft.uni-hamburg.de/BetMasApi/what";

declare namespace t = "http://www.tei-c.org/ns/1.0";

(:~gets the a list elements with a reference to the given id in the specified collection (c) :)
declare function what:PointsHere($id as xs:string, $c){
let $id := if(starts-with($id, 'https://betamasaheft.eu/')) then string($id) else 'https://betamasaheft.eu/' || string($id)
           let $witnesses := $c//t:witness[starts-with(@corresp, $id)]
            let $div := $c//t:div[starts-with(@corresp, $id)]
let $placeNames := $c//t:placeName[starts-with(@ref, $id)]
let $persNames := $c//t:persName[starts-with(@ref, $id)]
let $ref := $c//t:ref[starts-with(@corresp, $id)]
let $titles := $c//t:title[starts-with(@ref, $id)]
let $settlement := $c//t:settlement[starts-with(@ref, $id)]
let $region := $c//t:region[starts-with(@ref, $id)]
let $country := $c//t:country[starts-with(@ref, $id)]
let $active := $c//t:relation[starts-with(@active, $id)]
let $passive := $c//t:relation[starts-with(@passive, $id)]
let $allrefs := ($witnesses, 
$div,
        $placeNames,  
        $persNames, 
        $ref,
        $titles,
        $settlement,
        $region,
        $country,
        $active, 
        $passive)
return
for $corr in $allrefs
        return 
            $corr
            
            };

