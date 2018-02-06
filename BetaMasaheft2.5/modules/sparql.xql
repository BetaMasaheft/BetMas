xquery version "3.1";
import module namespace console="http://exist-db.org/xquery/console";
import module namespace sparql="http://exist-db.org/xquery/sparql" at "java:org.exist.xquery.modules.rdf.SparqlModule";
declare namespace t="http://www.tei-c.org/ns/1.0";
declare namespace rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#";
declare namespace sr="http://www.w3.org/2005/sparql-results#";

(:TUTORIAL for SPARQL queries here https://jena.apache.org/tutorials/sparql_basic_patterns.html and following!:)

let $prefixes := 
        "PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
         PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
         PREFIX lawd: <http://lawd.info/ontology/>
         PREFIX oa: <http://www.w3.org/ns/oa#>
         PREFIX ecrm: <http://erlangen-crm.org/current/>
         PREFIX crm: <http://www.cidoc-crm.org/cidoc-crm/>
         PREFIX gn: <http://www.geonames.org/ontology#>
         PREFIX agrelon: <http://d-nb.info/standards/elementset/agrelon.owl#>
         PREFIX rel: <http://purl.org/vocab/relationship/>
         PREFIX dcterms: <http://purl.org/dc/terms/>
         PREFIX bm: <http://betamasaheft.eu/>
         PREFIX pelagios: <http://pelagios.github.io/vocab/terms#>
         PREFIX syriaca: <http://syriaca.org/documentation/relations.html#>
         PREFIX saws: <http://purl.org/saws/ontology#>
         PREFIX snap: <http://data.snapdrgn.net/ontology/snap#>
         PREFIX pleiades: <https://pleiades.stoa.org/>
         PREFIX wd: <https://www.wikidata.org/>
         PREFIX dc: <http://purl.org/dc/elements/1.1/>
         PREFIX skos: <http://www.w3.org/2004/02/skos/core#>
         PREFIX xsd: <http://www.w3.org/2001/XMLSchema#>
         PREFIX t: <http://www.tei-c.org/ns/1.0>"
         
let $query := ($prefixes || "
                SELECT ?y
                WHERE
                { ?y a bm:Bible }
                "
                )
                
let $test := console:log($query)
return
  for $query in $query
    return sparql:query($query)