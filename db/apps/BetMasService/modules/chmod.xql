xquery version "3.1";
for $collection in ('/db/rdf/manuscripts')
let $tmp :=
 for $file in collection($collection)
 let $uri := document-uri($file)
let $a := sm:chown($uri, 'BetaMasaheftAdmin')
let $b := sm:chmod($uri, 'rwxrwxr--')
   return ()
return     'job done'