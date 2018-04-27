xquery version "3.1";
import module namespace console = "http://exist-db.org/xquery/console";
import module namespace sparql = "http://exist-db.org/xquery/sparql" at "java:org.exist.xquery.modules.rdf.SparqlModule";
import module namespace config = "https://www.betamasaheft.uni-hamburg.de/BetMas/config" at "config.xqm";
import module namespace titles = "https://www.betamasaheft.uni-hamburg.de/BetMas/titles" at "titles.xqm";
declare namespace t = "http://www.tei-c.org/ns/1.0";
declare namespace rdf = "http://www.w3.org/1999/02/22-rdf-syntax-ns#";
declare namespace sr = "http://www.w3.org/2005/sparql-results#";

(:TUTORIAL for SPARQL queries here https://jena.apache.org/tutorials/sparql_basic_patterns.html and following!:)
let $id := 'LIT1401Fisalg'
let $chapterID := 'pelican'
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
                SELECT ?id
                WHERE
                {
                ?version a 'work' .
                ?version saws:isVersionOf bm:" || $id || " .
                ?version crm:P48_has_preferred_identifier ?id
                }
                "
)

let $sparqlresults := sparql:query($query)
for $result in $sparqlresults//sr:literal/text()
let $version := collection($config:data-rootW)//id($result)
let $resTit := titles:printTitleMainID($result)
let $texts :=
if ($version//t:div[contains(@xml:id, $chapterID)])
then
    (for $edition in $version//t:div[contains(@xml:id, $chapterID)]
    return
        <version><source><title>{$resTit}</title><id>{$result}</id><ed>{$edition//ancestor::t:div[@type='edition']/@resp}</ed></source><text>{$edition}</text></version>)
else
    if (count($version//t:witness) eq 1) then
        let $wit := string($version//t:witness/@corresp)
        let $uniqueWitness := collection($config:data-rootMS)//id($wit)
        let $titWit := titles:printTitleMainID($wit)
        return
            if ($uniqueWitness//t:div[contains(@xml:id, $chapterID)]) then
                
                <version><source><title>{$resTit}</title><id>{$result}</id><uniqueWitness>{$titWit}</uniqueWitness></source><text>{$uniqueWitness//t:div[contains(@xml:id, $chapterID)]}</text></version>
            else
                <version><source><title>{$resTit}</title><id>{$result}</id><uniqueWitness>{$titWit}</uniqueWitness></source><text>no text available for {$resTit} ({$result} unique witness {$titWit} ({$wit}))</text></version>
    else
        (<version><source><title>{$resTit}</title><id>{$result}</id></source><text>no text available for {$resTit} ({$result})</text></version>)
return
    $texts