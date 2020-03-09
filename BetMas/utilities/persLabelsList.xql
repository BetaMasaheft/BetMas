 xquery version "3.1";
 
(: Utility file used for the static institutions list :)
 declare namespace t="http://www.tei-c.org/ns/1.0";
 
import module namespace titles="https://www.betamasaheft.uni-hamburg.de/BetMas/titles" at "xmldb:exist:///db/apps/BetMas/modules/titles.xqm";
import module namespace config = "https://www.betamasaheft.uni-hamburg.de/BetMas/config" at "xmldb:exist:///db/apps/BetMas/modules/config.xqm";


    for $i in distinct-values($config:collection-root//t:persName/@ref)
    let $tit := try{titles:printTitleMainID($i)} catch *{$err:description}
    let $title := if (starts-with($tit, 'ʾ') or starts-with($tit, 'ʿ')) then substring($tit, 2) else $tit
   order by $title
    return
    <item corresp="{$i}">
    {normalize-space($tit)}
    </item>
   