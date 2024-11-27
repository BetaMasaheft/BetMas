 xquery version "3.1";
 
(: Utility file used for the static institutions list :)
 declare namespace t="http://www.tei-c.org/ns/1.0";
 
import module namespace titles="https://www.betamasaheft.uni-hamburg.de/BetMas/titles" at "xmldb:exist:///db/apps/BetMas/modules/titles.xqm";
import module namespace config = "https://www.betamasaheft.uni-hamburg.de/BetMas/config" at "xmldb:exist:///db/apps/BetMas/modules/config.xqm";


    for $i in distinct-values(collection($config:data-rootMS)//t:msItem/t:title[@ref]/@ref)
    let $tit := try{titles:printTitleID($i)} catch *{$err:description}
    let $titjoin := normalize-space(string-join($tit))
    let $title := if (starts-with($titjoin, 'ʾ') or starts-with($titjoin, 'ʿ')) then substring($titjoin, 2) else $titjoin
   order by $title
    return
    <item corresp="{$i}">
    {$tit}
    </item>
   