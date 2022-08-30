xquery version "3.1";
declare namespace t = "http://www.tei-c.org/ns/1.0";
declare namespace xi = "http://www.w3.org/2001/XInclude";

declare namespace rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#";
(:imports the transformation to RDF and module to take that and push it to the Fuseki Triplestore - version of makeRDF for subcollections:)
import module namespace updatefuseki = 'https://www.betamasaheft.uni-hamburg.de/BetMas/updatefuseki' at "xmldb:exist:///db/apps/BetMas/fuseki/updateFuseki.xqm";
declare variable $local:data2rdf := 'xmldb:exist:///db/apps/BetMas/rdfxslt/data2rdf.xsl';

let $collection-uri := '/db/apps/expanded/persons/PRS1001-2000'
let $context := collection($collection-uri)//t:TEI
let $t := util:system-time()
let $files :=

for $file in $context
let $start-time := util:system-time()
let $rdf := try{transform:transform($file, $local:data2rdf, ())} catch * {util:log('info', $file),util:log('info', $err:description)}
return
if($rdf[not(node())]) then (util:log('info', 'issue transforming')) else 
let $filepath := base-uri($file)
let $file-name := tokenize($filepath, '/')[last()]
let $rdffilename := replace($file-name, '.xml', '.rdf')

let $storecoll := '/db/rdf/persons/'
let $storeRDFXML := try{xmldb:store($storecoll, $rdffilename, $rdf)} catch * {util:log('info', $rdffilename),util:log('info', $err:description)}
(:retrieve the RDF/XML as stored, and send it to update Apache Jena Fuseki and the triplestore:)
let $rdfxml := doc($storecoll || '/' || $rdffilename)
let $updateFuseki := try{updatefuseki:update($rdfxml, 'INSERT')} catch * {util:log('info', $err:description)}
let $runtime-ms := ((util:system-time() - $start-time))
return
    'stored RDF/XML and updated fuseki in ' || $runtime-ms

let $totrun := ((util:system-time() - $t)
div xs:dayTimeDuration('PT1S'))
return
    'transformed to RDF and stored in Fuseki ' || count($context) || ' file(s) in ' || $totrun || ' seconds.'