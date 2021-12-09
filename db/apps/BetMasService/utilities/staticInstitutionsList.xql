 xquery version "3.1";
 
(: Utility file used for the static institutions list :)
 declare namespace t="http://www.tei-c.org/ns/1.0";
 
import module namespace titles="https://www.betamasaheft.uni-hamburg.de/BetMas/titles" at "xmldb:exist:///db/apps/BetMas/modules/titles.xqm";
import module namespace config = "https://www.betamasaheft.uni-hamburg.de/BetMas/config" at "xmldb:exist:///db/apps/BetMas/modules/config.xqm";

<list>{
    for $repoi in collection($config:data-rootIn)//t:TEI/@xml:id
    let $i := string($repoi)
    let $tit := normalize-space(titles:printTitleMainID($i))
    let $normTit := lower-case(replace(normalize-unicode(replace($tit, 'Ǝ', 'E'), 'NFKD'), '\P{IsBasicLatin}', '' ))
   order by $normTit
    return
    <item>
    {$repoi}
    {$tit}
    </item>
    }
</list>

(:replace(normalize-unicode(replace('Ǝndā Māryām', 'Ǝ', 'e'), 'NFKD'), '\P{IsBasicLatin}', '' ):)