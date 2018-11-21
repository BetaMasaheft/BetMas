 xquery version "3.1";
 
(: Utility file used for the static institutions list :)
 declare namespace t="http://www.tei-c.org/ns/1.0";
 
import module namespace titles="https://www.betamasaheft.uni-hamburg.de/BetMas/titles" at "xmldb:exist:///db/apps/BetMas/modules/titles.xqm";
import module namespace config = "https://www.betamasaheft.uni-hamburg.de/BetMas/config" at "xmldb:exist:///db/apps/BetMas/modules/config.xqm";

<list>{
    for $repoi in collection($config:data-rootIn)//t:TEI/@xml:id
    let $i := string($repoi)
    let $tit := titles:printTitleMainID($i)
    let $title := if (starts-with($tit, 'ʾ') or starts-with($tit, 'ʿ')) then substring($tit, 2) else $tit
   order by $title
    return
    <item>
    {$repoi}
    {$tit}
    </item>
    }
</list>