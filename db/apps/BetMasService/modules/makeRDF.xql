xquery version "3.1";
declare namespace t = "http://www.tei-c.org/ns/1.0";
declare namespace xi = "http://www.w3.org/2001/XInclude";

(:imports the transformation to RDF and module to take that and push it to the Fuseki Triplestore:)
import module namespace updatefuseki = 'https://www.betamasaheft.uni-hamburg.de/BetMas/updatefuseki' at "xmldb:exist:///db/apps/BetMas/fuseki/updateFuseki.xqm";
declare variable $local:data2rdf := 'xmldb:exist:///db/apps/BetMas/rdfxslt/data2rdf.xsl';

let $collection-uri := '/db/apps/BetMasData/narratives'
let $context := collection($collection-uri)//t:TEI
let $t := util:system-time()
let $files :=

for $file in $context
let $start-time := util:system-time()
let $rdf := transform:transform($file, $local:data2rdf, ())
let $filepath := base-uri($file)
let $file-name := tokenize($filepath, '/')[last()]
let $rdffilename := replace($file-name, '.xml', '.rdf')
let $collectionName := substring-after($collection-uri, '/db/apps/BetMasData/')
let $shortCollName := if (matches($collectionName, 'manuscripts')) then
    'manuscripts'
else
    if (matches($collectionName, 'works')) then
        'works'
    else
        if (matches($collectionName, 'persons')) then
            'persons'
        else
            if (matches($collectionName, 'places')) then
                'places'
            else
                if (matches($collectionName, 'institutions')) then
                    'institutions'
                else
                    if (matches($collectionName, 'studies')) then
                        'studies'
                    else
                        if (matches($collectionName, 'persons')) then
                            'persons'
                        else
                            'authority-files'
let $storecoll := concat('/db/rdf/', $shortCollName)
let $storeRDFXML := xmldb:store($storecoll, $rdffilename, $rdf)
(:retrieve the RDF/XML as stored, and send it to update Apache Jena Fuseki and the triplestore:)
let $rdfxml := doc($storecoll || '/' || $rdffilename)
let $updateFuseki := try{updatefuseki:update($rdfxml, 'INSERT')} catch * {util:log('info', $err:description)}
let $runtime-ms := ((util:system-time() - $start-time))
return
    'stored RDF/XML and updated fuseki in ' || $runtime-ms

let $totrun := ((util:system-time() - $t)
div xs:dayTimeDuration('PT1S'))
return
    'tranformed to RDF and stored in Fuseki ' || count($context) || ' file(s) in ' || $totrun || ' seconds'