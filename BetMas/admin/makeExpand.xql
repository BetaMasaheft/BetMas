xquery version "3.1";
declare namespace t = "http://www.tei-c.org/ns/1.0";
declare namespace xi = "http://www.w3.org/2001/XInclude";

import module namespace  expand="https://www.betamasaheft.uni-hamburg.de/BetMas/expand" at "xmldb:exist:///db/apps/BetMas/modules/expand.xqm";
import module namespace console = "http://exist-db.org/xquery/console";


for $file in collection('/db/apps/BetMasData')//t:TEI
let $start-time := util:system-time()
let $filepath := base-uri($file)
let $file := expand:file($filepath)
let $file-name := tokenize($filepath, '/')[last()]
let $collection := replace(substring($filepath, 1, (string-length($filepath) - string-length($file-name))), '/BetMasData/', '/expanded/')
let $collection-uri := if (xmldb:collection-available($collection)) then $collection
                                 else
                                  let $makeCollection := expand:create-collections($collection)
                              return  $collection
let $store := xmldb:store($collection-uri, xmldb:encode-uri($file-name), $file)
let $runtime-ms := ((util:system-time() - $start-time)
div xs:dayTimeDuration('PT1S')) * 1000
return
    'stored ' || $file-name || ' into ' || $collection-uri || ' in ' || $runtime-ms || ' milliseconds'
