xquery version "3.1";
declare namespace t = "http://www.tei-c.org/ns/1.0";
declare namespace xi = "http://www.w3.org/2001/XInclude";

import module namespace expand = "https://www.betamasaheft.uni-hamburg.de/BetMas/expand" at "xmldb:exist:///db/apps/BetMas/modules/expand.xqm";

let $context :=

(collection('/db/apps/BetMasData/works/1-1000')//t:TEI
)
let $t := util:system-time()
let $files :=
for $file in $context
let $xmlid := $file/@xml:id
let $start-time := util:system-time()
let $filepath := base-uri($file)
let $file := expand:file($filepath)
let $file-name := tokenize($filepath, '/')[last()]
let $collection := replace(substring($filepath, 1, (string-length($filepath) - string-length($file-name))), '/BetMasData/', '/expanded/')
let $collection-uri := if (xmldb:collection-available($collection)) then
    $collection
else
    let $makeCollection := expand:create-collections($collection)
    return
        $collection
        (:
 : expanded iteration on collection, as well as that in git are faulty, the iteration assumes that there are no parts of the path which are the same to one another
 : 
 : Check if file already exist 
 : and has same last change so that if already done it will not do anything 
 : if (xmldb:last-modified($collection-uri as item(), $resource as xs:string) le xmldb:last-modified($collection-uri as item(), $resource as xs:string)) then....
 :)
        (: if it already existing in a different location, delete the old version:)
let $removeExisting :=
let $existings := collection($collection)//t:TEI//id($xmlid)
return
    if (count($existings) = 0) then
        util:log('info', (' no other file with id ' || $xmlid))
    else
(:    let $t := util:log('info', (count($existings) || ' other files with id ' || $xmlid)):)
        for $existing in $existings
        let $filebase := base-uri($existing)
(:         let $te := util:log('info', $filebase):)
        let $filecoll := substring-before($filebase, $xmlid)
        let $filecollclean := replace($filecoll, '/$', '')
(:         let $tec := util:log('info', $filecollclean):)
        let $filename := substring-after($filebase, $filecoll)
(:         let $tef := util:log('info', $filename):)
       let $remove := try{xmldb:remove($filecollclean, $filename)} catch * {$err:description}
       return   util:log('info', ('removed ' || $filebase))
let $store := if (doc-available(concat($collection-uri, $file-name)))
(:log and overwrite:)
then
    (util:log('info', ($file-name || ' is already available in ' || $collection-uri)),
    try {
        xmldb:store($collection-uri, $file-name, $file)
    } catch * {
        util:log('info', $err:description)
    })
    (:                write doc:)
else
    try {
        xmldb:store($collection-uri, $file-name, $file)
    } catch * {
        util:log('info', $err:description)
    }
let $permissions := let $stored := concat($collection-uri, '/', $file-name)
return
    try {
        (sm:chgrp($stored, 'Cataloguers'), sm:chmod($stored, 'rwxrwxrwx'))
    } catch * {
        util:log('info', $err:description)
    }
let $runtime-ms := ((util:system-time() - $start-time)
div xs:dayTimeDuration('PT1S')) * 1000
let $message := 'stored ' || $file-name || ' into ' || $collection-uri || ' in ' || $runtime-ms || ' milliseconds'
return
    util:log('INFO', $message)

let $totrun := ((util:system-time() - $t)
div xs:dayTimeDuration('PT1S'))
return
    'expanded ' || count($context) || ' file(s) in ' || $totrun || ' seconds'