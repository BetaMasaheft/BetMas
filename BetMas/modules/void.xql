xquery version "3.1" encoding "UTF-8";
(:~
 : rest XQ module producing general VoID 
 : @author Pietro Liuzzo <pietro.liuzzo@uni-hamburg.de'>
 :)

module namespace void = "https://www.betamasaheft.uni-hamburg.de/BetMas/void";
import module namespace switch = "https://www.betamasaheft.uni-hamburg.de/BetMas/switch"  at "xmldb:exist:///db/apps/BetMas/modules/switch.xqm";
import module namespace config = "https://www.betamasaheft.uni-hamburg.de/BetMas/config" at "xmldb:exist:///db/apps/BetMas/modules/config.xqm";
import module namespace titles="https://www.betamasaheft.uni-hamburg.de/BetMas/titles" at "xmldb:exist:///db/apps/BetMas/modules/titles.xqm";
import module namespace api="https://www.betamasaheft.uni-hamburg.de/BetMas/api" at "xmldb:exist:///db/apps/BetMas/modules/rest.xql";

declare namespace t = "http://www.tei-c.org/ns/1.0";
declare namespace http = "http://expath.org/ns/http-client";
declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace json = "http://www.json.org";


declare variable $void:response200turtle := <rest:response>
            <http:response
                status="200">
                <http:header
                    name="Content-Type"
                    value="text/turtle; charset=utf-8"/>
                <http:header
                    name="Access-Control-Allow-Origin"
                    value="*"
                    />
            </http:response>
        </rest:response>;

declare 
%rest:GET
%rest:path("/BetMas/api/void")
%output:method("text")
function void:general() {
$void:response200turtle, 
        '
@prefix : <'||$config:appUrl||'> .
        @prefix void: <http://rdfs.org/ns/void#> .
        @prefix dcterms: <http://purl.org/dc/terms/> .
        @prefix foaf: <http://xmlns.com/foaf/0.1/> .
        
        : a void:Dataset;
        dcterms:title "Beta Maṣāḥǝft";
        dcterms:publisher "Akademie der Wissenschaften in Hamburg";
        dcterms:publisher "Hiob-Ludolf-Zentrum für Äthiopistik";
        foaf:homepage <'||$config:appUrl||'>;
        dcterms:description "The project Beta maṣāḥǝft: Manuscripts of Ethiopia and Eritrea (Schriftkultur des christlichen 
        Äthiopiens: eine multimediale Forschungsumgebung) is a long-term project funded 
        within the framework of the Academies Programme (coordinated by the Union of the German 
        Academies of Sciences and Humanities) under survey of the Akademie der Wissenschaften in Hamburg. 
        The funding will be provided for 25 years, from 2016–2040. The project is hosted by the Hiob Ludolf 
        Centre for Ethiopian Studies at the University of Hamburg. It aims at creating a virtual research 
        environment that shall manage complex data related to predominantly Christian manuscript 
        tradition of the Ethiopian and Eritrean Highlands.";
        dcterms:license <http://opendatacommons.org/licenses/odbl/1.0/>;
        void:sparqlEndpoint <'||$config:appUrl||'/api/SPARQL?query=> ;
        void:sparqlEndpoint <'||$config:appUrl||'/api/SPARQL/json?query=> ;
        void:uriLookupEndpoint <'||$config:appUrl||'/api/dts> ;
        void:uriLookupEndpoint <'||$config:appUrl||'/api/iiif/collections> ;
        void:exampleResource <'||$config:appUrl||'/rdf/manuscripts/BAVcerulli37.rdf> ;
        void:exampleResource <'||$config:appUrl||'/rdf/works/LIT4275ChronAmdS.rdf> ;
        void:exampleResource <'||$config:appUrl||'/rdf/places/LOC1261Adulis.rdf> ;
        .'};


declare 
%rest:GET
%rest:path("/BetMas/api/void/{$id}")
%output:method("text")
function void:entity($id as xs:string*) {

($void:response200turtle, 
let $item := $config:collection-root/id($id)
let $coll := switch:col($item/@type)
let $dctermsContributor := ''
let $dctermsCreated := ''
let $dctermsModified := ''
let $thisUrl := $config:appUrl||'/'||$coll||'/'||$id
return
        '
@prefix : <'||$config:appUrl||'> .
        @prefix void: <http://rdfs.org/ns/void#> .
        @prefix dcterms: <http://purl.org/dc/terms/> .
        @prefix foaf: <http://xmlns.com/foaf/0.1/> .
        
        :'||$id||'_RDF a void:Dataset;
        dcterms:title "'||titles:printTitleMainID($id)||'";
        dcterms:publisher "Akademie der Wissenschaften in Hamburg";
        dcterms:publisher "Hiob-Ludolf-Zentrum für Äthiopistik";
        dcterms:source <'||$config:appUrl||'/'||$id||'.xml>;
        foaf:homepage <'||$thisUrl||'/main>;
        '||(if($coll = 'manuscripts' or $coll='works') then 'foaf:page <'||$thisUrl||'/text>;' else ())||' 
        foaf:page <'||$thisUrl||'/analytic>;
        foaf:page <'||$thisUrl||'/graph>;
        dcterms:license <http://opendatacommons.org/licenses/odbl/1.0/>;
        void:feature <http://www.w3.org/ns/formats/RDF_XML>;
        void:dataDump <'||$config:appUrl||'/rdf/'||$coll||'/'||$id||'.rdf> ;
        .
        
         :'||$id||'_RDFa a void:Dataset;
        dcterms:title "'||titles:printTitleMainID($id)||'";
        dcterms:publisher "Akademie der Wissenschaften in Hamburg";
        dcterms:publisher "Hiob-Ludolf-Zentrum für Äthiopistik";
        dcterms:source <'||$config:appUrl||'/'||$id||'.xml>;
        foaf:homepage <'||$thisUrl||'/main>;
        '||(if($coll = 'manuscripts' or $coll='works') then 'foaf:page <'||$thisUrl||'/text>;' else ())||' 
        foaf:page <'||$thisUrl||'/analytic>;
        foaf:page <'||$thisUrl||'/graph>;
        dcterms:license <http://opendatacommons.org/licenses/odbl/1.0/>;
        void:feature <http://www.w3.org/ns/formats/RDFa>;
        void:dataDump <'||$config:appUrl||'/rdf/'||$coll||'/'||$id||'/main> ;
        .
        
        '
        ||
        (
        if($coll='works' or $coll='manuscripts')
        then 
        '
        
        :'||$id||'_JSONLD a void:Dataset;
        dcterms:title "'||titles:printTitleMainID($id)||'";
        dcterms:publisher "Akademie der Wissenschaften in Hamburg";
        dcterms:publisher "Hiob-Ludolf-Zentrum für Äthiopistik";
        dcterms:source <'||$config:appUrl||'/'||$id||'.xml>;
        foaf:homepage <'||$thisUrl||'/main>;
        foaf:page <'||$thisUrl||'/text>;
        foaf:page <'||$thisUrl||'/analytic>;
        foaf:page <'||$thisUrl||'/graph>;
        foaf:page <'||$thisUrl||'/viewer>;
        dcterms:license <http://opendatacommons.org/licenses/odbl/1.0/>;
        void:feature <http://www.w3.org/ns/formats/JSON-LD>;
        void:uriLookupEndpoint <'||$config:appUrl||'/api/dts/collections?id=urn:dts:betmas'||(switch($coll) case 'manuscripts' return 'MS' default return '')||':'||$id||'> ;
        '||(if($coll='manuscripts' and $item//t:idno[@facs]) then 'void:uriLookupEndpoint <'||$config:appUrl||'/api/iiif/'||$id||'/manifest> ; '  else ()) || '
        .
        
        '
        else ())
        ||
        (
        if($coll='works' or $coll='manuscripts' or $coll='places' or $coll='institutions')
        then 
        '
        :'||$id||'_TTL a void:Dataset;
        dcterms:title "'||titles:printTitleMainID($id)||'";
        dcterms:publisher "Akademie der Wissenschaften in Hamburg";
        dcterms:publisher "Hiob-Ludolf-Zentrum für Äthiopistik";
        dcterms:source <'||$config:appUrl||'/'||$id||'.xml>;
        foaf:homepage <'||$thisUrl||'/main>;
        foaf:page <'||$thisUrl||'/text>;
        foaf:page <'||$thisUrl||'/analytic>;
        foaf:page <'||$thisUrl||'/graph>;
        dcterms:license <http://opendatacommons.org/licenses/odbl/1.0/>;
        void:feature <http://www.w3.org/ns/formats/Turtle>;
        ' || 
        (if($coll='works' or $coll='manuscripts')
        then 'void:dataDump <'||$config:appUrl||'/api/placeNames/'||$coll||'/'||$id||'> ;'
        else
        'void:dataDump <'||$config:appUrl||'/api/gazetteer/place/' ||$id||'> ;')||'
        .
        
        ' else ()))};



declare 
%rest:GET
%rest:path("/BetMas/api/dcat")
%output:method("text")
function void:DCAT() {
$void:response200turtle, 
        '
@prefix : <'||$config:appUrl||'> .
        @prefix dcat: <http://www.w3.org/ns/dcat#> .
        @prefix dct: <http://purl.org/dc/terms/> .
        @prefix foaf: <http://xmlns.com/foaf/0.1/> .
        @prefix dctype: <http://purl.org/dc/dcmitype/> .
        @prefix rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#> .
        @prefix rdfs: <http://www.w3.org/2000/01/rdf-schema#> .
        @prefix skos: <http://www.w3.org/2004/02/skos/core#> .
        @prefix vacard: <http://www.w3.org/2006/vcard/ns#> .
        @prefix xsd: <http://www.w3.org/2001/XMLSchema#> .
        
         :catalog
       a dcat:Catalog ;
       dct:title "Beta Maṣāḥǝft" ;
       rdfs:label "Beta Maṣāḥǝft: Manuscripts of Ethiopia and Eritrea (Schriftkultur des christlichen Äthiopiens: eine multimediale Forschungsumgebung)" ;
       foaf:homepage <https://betamasaheft.eu> ;
       dct:publisher "Akademie der Wissenschaften in Hamburg", "Hiob-Ludolf-Zentrum für Äthiopistik" ;
       dct:language <http://id.loc.gov/vocabulary/iso639-1/en>  ;
       dcat:dataset :RDFendpoint ; 
       .
       
       :RDFendpoint
       a dcat:Dataset ;
       dct:title "Beta Maṣāḥǝft" ;
       dcat:keyword "ethiopia","manuscripts" ,"literature", "clavis","Gǝʿǝz","Amharic" ;
       dct:issued "2018-08-31"^^xsd:date ;
       dcat:contactPoint <https://betamasaheft.eu/contacts.html> ;
       dct:temporal <http://n2t.net/ark:/99152/p03tcss4qvv>, <http://n2t.net/ark:/99152/p03tcssdh3k>,
                <http://n2t.net/ark:/99152/p03tcssfc3r>, <http://n2t.net/ark:/99152/p03tcssrjvk>, 
                <http://n2t.net/ark:/99152/p03tcssvm7f>, <http://n2t.net/ark:/99152/p03tcssvtwm> ;
       dct:spatial <http://www.geonames.org/337996>, <https://www.geonames.org/338010>, <http://www.geonames.org/51537> ;
       dct:publisher "Akademie der Wissenschaften in Hamburg", "Hiob-Ludolf-Zentrum für Äthiopistik" ;
       dct:language <http://id.loc.gov/vocabulary/iso639-1/en>  ;
       dcat:distribution :endpoint ;
       .
       
       :endpoint
       a dcat:Distribution ;
       dcat:accessURL <https://betamasaheft.eu/api/SPARQL?query=>;
       dct:title "Beta maṣāḥǝft endpoint returning  SPARQL Query Results XML format." ;
       dcat:mediaType "application/xml" ;
       
       .'};

