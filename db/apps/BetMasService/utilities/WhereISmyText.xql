xquery version "3.1";
declare namespace t = "http://www.tei-c.org/ns/1.0";
import module namespace config = "https://www.betamasaheft.uni-hamburg.de/BetMas/config" at "../modules/config.xqm";
import module namespace coord = "https://www.betamasaheft.uni-hamburg.de/BetMas/coord" at "../modules/coordinates.xqm";
import module namespace titles="https://www.betamasaheft.uni-hamburg.de/BetMas/titles" at "../modules/titles.xqm";
declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";
declare option output:method "json";
(: store in a variable the ID of the work:)
 let $work := 'LIT3178Deggwa'
(: select from manuscript files those which contain a t:title with @ref='LIT1146Argano'
could have been limited to t:title inside t:msItem with //t:msItem/t:title instead of //t:title 
:)
let $mss := $config:collection-rootMS//t:title[contains(@ref , $work)]
for $ms in $mss 
let $repo := root($ms)//t:repository
let $id := string(root($ms)/t:TEI/@xml:id)
let $date := root($ms)//t:origDate
let $stringDate := for $d in $date 
let $atts := for $att in ($d/@notBefore, $d/@notAfter, $d/@when) return string($att)
                        return min($atts)
let $getcoor := coord:getCoords($repo/@ref)
let $reponame := titles:printTitleMainID($repo/@ref)
return
             $reponame || ';' || $getcoor || ';' || $id || ';' || min($stringDate)