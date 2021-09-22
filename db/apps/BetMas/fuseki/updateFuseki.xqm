xquery version "3.1" encoding "UTF-8";
module namespace updatefuseki = 'https://www.betamasaheft.uni-hamburg.de/BetMas/updatefuseki' ;
import module namespace fusekisparql = 'https://www.betamasaheft.uni-hamburg.de/BetMas/sparqlfuseki' at "xmldb:exist:///db/apps/BetMas/fuseki/fuseki.xqm";
import module namespace config="https://www.betamasaheft.uni-hamburg.de/BetMas/config" at "xmldb:exist:///db/apps/BetMas/modules/config.xqm";

declare namespace rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#";
declare namespace t="http://www.tei-c.org/ns/1.0";

declare function updatefuseki:Class($node){if ($node/name() = 'rdf:Description') 
        then (
            '<' || string($node/@rdf:about) || '> '|| 
        string-join(updatefuseki:loop($node), '; 
        ') || ' .')
    else (('<' || string($node/@rdf:about) || '>' || ' a ' || $node/name() || '; ' ), 
         string-join(updatefuseki:loop($node), '; 
        ') || ' .')
};
            
declare function updatefuseki:property($node){
    ($node/name() || ' <' || string($node/@rdf:resource) || '> ' )
};

declare function updatefuseki:rdftype($node){
    ('a <' || string($node/@rdf:resource) || '> ' )
};

declare function updatefuseki:datatype($node){
    ($node/name() ||  " '" || string($node/text()) || "'^^"  || replace($node/@rdf:datatype, 'http://www.w3.org/2001/XMLSchema#', 'xsd:') )
};

declare function updatefuseki:textnode($node){
    ($node/name() ||  " '" || string($node/text()) || "'" )
};

declare function updatefuseki:rdfxml2turtle($node){
if($node/@rdf:about) then updatefuseki:Class($node) 
else if($node/name() = 'rdf:type') then updatefuseki:rdftype($node) 
else if($node/@rdf:resource) then updatefuseki:property($node)  
else if($node/@rdf:datatype) then updatefuseki:datatype($node) 
else if($node[not(@*)]/text()) then updatefuseki:textnode($node) 
else if ($node[not(@*)]/node()[not(@*)]) then
    $node/name() || ' [
    a ' ||  $node/node()/name() || '; ' || 
    string-join(updatefuseki:loop($node/node()), '; 
        ') || ' 
        ]'
  else 'I am stuk at ' || $node/name()
};

declare function updatefuseki:loop($node){for $n at $p in $node/node() return  updatefuseki:rdfxml2turtle($n)};

(: takes as input the RDF/XML stored by the data2rdf.xslt and transforms it into triples in the format required for SPARQL Update :)
declare function updatefuseki:update($rdfxml, $operation){
let $parse := updatefuseki:loop($rdfxml)
let $rdfturtle := string-join($parse, '
        ')
return
fusekisparql:update('betamasaheft', $operation, $rdfturtle)
};