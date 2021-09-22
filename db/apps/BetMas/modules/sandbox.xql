xquery version "3.1";
declare namespace t="http://www.tei-c.org/ns/1.0";
import module namespace config="https://www.betamasaheft.uni-hamburg.de/BetMas/config" at "xmldb:exist:///db/apps/BetMas/modules/config.xqm";
let $dates := $config:collection-rootMS//t:date
let $origDates := $config:collection-rootMS//t:origDate
let $alldates := ($dates, $origDates)
return (
count($alldates), 
count($alldates[@calendar]), 
count($alldates[@when-custom]), 
count($alldates[@notBefore-custom]), 
count($alldates[@notAfter-custom])
)