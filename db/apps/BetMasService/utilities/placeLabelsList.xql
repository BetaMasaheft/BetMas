xquery version "3.1";
 
(: Utility file used for the static places list :)
 declare namespace t="http://www.tei-c.org/ns/1.0";
 
import module namespace titles="https://www.betamasaheft.uni-hamburg.de/BetMas/titles" at "xmldb:exist:///db/apps/BetMas/modules/titles.xqm";
import module namespace config = "https://www.betamasaheft.uni-hamburg.de/BetMas/config" at "xmldb:exist:///db/apps/BetMas/modules/config.xqm";


let $pl1 := collection('/db/apps/BetMasData/')//t:relation/@passive[contains(.,'LOC')]
let $pl2 := collection('/db/apps/BetMasData/')//t:placeName/@ref[not(matches(., 'INS'))]
return
    <list>{
    for $i in distinct-values(($pl1, $pl2)) 
    let $tit := try{titles:printTitleMainID($i)} catch *{$err:description}
    let $title := if (starts-with($tit, 'ʾ') or starts-with($tit, 'ʿ')) then substring($tit, 2) else $tit
   order by $title
    return
    <item corresp="{$i}">
    {normalize-space($tit)}
    </item>}</list>
   
   