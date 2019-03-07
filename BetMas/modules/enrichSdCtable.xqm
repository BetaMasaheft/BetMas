xquery version "3.1" encoding "UTF-8";
(:~
 : gets information from single elements in a 
 : TEI file to enrich the table in the SdC views, called
 : by SdCtable.js 
 : 
 : @author Pietro Liuzzo <pietro.liuzzo@uni-hamburg.de'>
 :)
module namespace enrich = "https://www.betamasaheft.uni-hamburg.de/BetMas/enrich";
import module namespace rest = "http://exquery.org/ns/restxq";
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


(:~retrives a single part of a tei file, e.g. a single node:)
declare
%rest:GET
%rest:path("/BetMas/api/enrichMe/{$id}/{$anchor}")
%output:method("json")
function enrich:teipart($id as xs:string, $anchor as xs:string*){

    ($config:response200Json,
    let $file := api:get-tei-by-ID($id)
    let $node := $file//id($anchor)
    let $name :=  $node/name()
    let $NodeMap :=  map {}
    let $NodeMapwithxmllang := if($node/@xml:lang) then map:put($NodeMap, 'xml:lang', string($node/@xml:lang)) else $NodeMap
    let $NodeMapwithtitle := if($node/t:title) then 
                               let $titString := if ($node/t:title/@ref) then 
                                                                     let $titRef := string($node/t:title/@ref)
                                                                     return titles:printTitleMainID($titRef) 
                                                              else $node/t:title/text() 
                              return map:put($NodeMapwithxmllang, 'title', $titString[1]) 
                              else $NodeMapwithxmllang
  let $NodeMapwithdate := if($node/t:date) then 
                               let $dateString := string-join(string:tei2string($node/t:date), ', ')
                              return map:put($NodeMapwithtitle, 'date', $dateString) 
                              else $NodeMapwithtitle
  let $NodeMapwithbibl := if($node//t:bibl) then 
                              let $bibstrings := for $b in $node//t:bibl return string:tei2string($b)
                              let $biblString := string-join($bibstrings, '; ')
                              return map:put($NodeMapwithdate, 'bibliography', $biblString) 
                              else $NodeMapwithdate
 let $NodeMapwithnote := if($node/t:note) then 
                              let $noteString := string-join(string:tei2string($node/t:note), '; ')
                              return map:put($NodeMapwithbibl, 'note', $noteString) 
                              else $NodeMapwithbibl
 let $NodeMapwithdesc := if($node/t:desc/text()) then 
                              let $descString := string-join(string:tei2string($node/t:desc), '; ')
                              return map:put($NodeMapwithnote, 'desc', $descString) 
                              else $NodeMapwithnote
 let $NodeMapwithdesctype := if($node/t:desc/@type) then 
                              let $desctypeString := titles:printTitleMainID(string($node/t:desc/@type))
                              return map:put($NodeMapwithdesc, 'type', $desctypeString) 
                              else $NodeMapwithdesc
 let $NodeMapwithdecotype := if($node/name() = 'decoNote') then 
                              let $decotypeString := string($node/@type)
                              return map:put($NodeMapwithdesctype, 'deco type', $decotypeString) 
                              else $NodeMapwithdesctype
 let $NodeMapwithlinks := if($node//t:*[@ref ] or $node//t:term or $node//t:ref) then 
                              let $named := for $ne in $node//t:*[@ref] return titles:printTitleID($ne/@ref) || (if($ne/@role)then ' ('||string($ne/@role)||')' else ())
                              let $terms := for $t in $node//t:term/@key return titles:printTitleMainID($t)
                              let $refs :=for $r in $node//t:ref return string:tei2string($r)
                              let $all := ('Named Entities: ' ||string-join($named, ', ')||' | Terms: ' || string-join($terms, ', ')||' | References: ' || string-join($refs, ', '))
                              return map:put($NodeMapwithdecotype, 'links', $all) 
                              else $NodeMapwithdecotype
let $NodeMapwithscript := if($node/@script ) then 
                              let $scriptString := string($node/@script)
                              return map:put($NodeMapwithlinks, 'script', $scriptString) 
                              else $NodeMapwithlinks
                              
    return 
           $NodeMapwithlinks
    
    )
};
