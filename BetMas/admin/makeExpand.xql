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
(:
 : expanded iteration on collection, as well as that in git are faulty, the iteration assumes that there are no parts of the path which are the same to one another
 : 
 : Check if file already exist 
 : and has same last change so that if already done it will not do anything 
 : if (xmldb:last-modified($collection-uri as item(), $resource as xs:string) le xmldb:last-modified($collection-uri as item(), $resource as xs:string)) then....
 :)                              
let $store :=   if(doc-available(concat($collection-uri,$file-name))) 
                then console:log( $file-name || ' is already available in ' || $collection-uri )
                else try{xmldb:store($collection-uri, xmldb:encode-uri($file-name), $file)} catch * {console:log($err:description)}
let $permissions := let $stored := concat($collection-uri, '/', $file-name) return (sm:chgrp($stored, 'Cataloguers'), sm:chmod($stored, 'rwxrwxrwx'))                
let $runtime-ms := ((util:system-time() - $start-time)
div xs:dayTimeDuration('PT1S')) * 1000
let $message := 'stored ' || $file-name || ' into ' || $collection-uri || ' in ' || $runtime-ms || ' milliseconds'
return
   util:log('INFO', $message)
