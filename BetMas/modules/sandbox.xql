 xquery version "3.1";
 declare namespace t="http://www.tei-c.org/ns/1.0";
 
import module namespace config="https://www.betamasaheft.uni-hamburg.de/BetMas/config" at "xmldb:exist:///db/apps/BetMas/modules/config.xqm";
let $cats := collection($config:data-rootMS)//t:listBibl[@type='catalogue']
   for $catalogue in distinct-values($cats//t:ptr/@target)
   let $zoTag := substring-after($catalogue, 'bm:')
   let $count := count($cats[t:bibl/t:ptr[@target=$catalogue]])
   return 
   $zoTag || ': ' || $count
        
