xquery version "3.1";
(: If a modification is made to data2rdf.xsl, this would tipically involve retransforming all RDF. 
 : with this module, the modification in question can be reproduced in the triplestore so that the queries can be made on the 
 : updated data, without running the transformation on all entities :)
import module namespace updatefuseki = 'https://www.betamasaheft.uni-hamburg.de/BetMas/updatefuseki' at "xmldb:exist:///db/apps/BetMas/fuseki/updateFuseki.xqm";
import module namespace config="https://www.betamasaheft.uni-hamburg.de/BetMas/config" at "xmldb:exist:///db/apps/BetMas/modules/config.xqm";
declare namespace rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#";
declare namespace rdfs="http://www.w3.org/2000/01/rdf-schema#";
declare namespace t="http://www.tei-c.org/ns/1.0";
let $operation := 'INSERT'
return
for $title in collection($config:data-rootW)//t:titleStmt/t:title[@xml:id] 
   let $rootID := string($title/ancestor::t:TEI/@xml:id)
    let $rdfxml :=  
                <rdf:RDF>
                <rdf:Description rdf:about="https://betamasaheft.eu/{$rootID}/title/{$title/@xml:id}">
                    <rdf:type rdf:resource="http://www.cidoc-crm.org/cidoc-crm/E35_Title"/>
                    <rdfs:label>{normalize-space(string-join($title/text()))}</rdfs:label>
                </rdf:Description>
                </rdf:RDF>
   let $tryupdate :=  try{updatefuseki:update($rdfxml, $operation)} catch * {$err:description}
   return 'done ' || $rootID || ' title ' || string($title/@xml:id)