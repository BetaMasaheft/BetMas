xquery version "3.1";

module namespace q = "https://www.betamasaheft.uni-hamburg.de/BetMas/queries";
import module namespace all = "https://www.betamasaheft.uni-hamburg.de/BetMas/all" at "xmldb:exist:///db/apps/BetMas/modules/all.xqm";
import module namespace templates = "http://exist-db.org/xquery/templates";
import module namespace editors = "https://www.betamasaheft.uni-hamburg.de/BetMas/editors" at "xmldb:exist:///db/apps/BetMas/modules/editors.xqm";
import module namespace titles = "https://www.betamasaheft.uni-hamburg.de/BetMas/titles" at "xmldb:exist:///db/apps/BetMas/modules/titles.xqm";
import module namespace exptit="https://www.betamasaheft.uni-hamburg.de/BetMas/exptit" at "xmldb:exist:///db/apps/BetMas/modules/exptit.xqm";
import module namespace item2 = "https://www.betamasaheft.uni-hamburg.de/BetMas/item2" at "xmldb:exist:///db/apps/BetMas/modules/item.xqm";
import module namespace console = "http://exist-db.org/xquery/console";
import module namespace functx = "http://www.functx.com";
import module namespace kwic = "http://exist-db.org/xquery/kwic" at "resource:org/exist/xquery/lib/kwic.xql";
import module namespace viewItem = "https://www.betamasaheft.uni-hamburg.de/BetMas/viewItem" at "xmldb:exist:///db/apps/BetMas/modules/viewItem.xqm";
import module namespace fusekisparql = 'https://www.betamasaheft.uni-hamburg.de/BetMas/sparqlfuseki' at "xmldb:exist:///db/apps/BetMas/fuseki/fuseki.xqm";
import module namespace switch2 = "https://www.betamasaheft.uni-hamburg.de/BetMas/switch2" at "xmldb:exist:///db/apps/BetMas/modules/switch2.xqm";
import module namespace config = "https://www.betamasaheft.uni-hamburg.de/BetMas/config" at "xmldb:exist:///db/apps/BetMas/modules/config.xqm";
import module namespace apptable = "https://www.betamasaheft.uni-hamburg.de/BetMas/apptable" at "xmldb:exist:///db/apps/BetMas/modules/apptable.xqm";
import module namespace string = "https://www.betamasaheft.uni-hamburg.de/BetMas/string" at "xmldb:exist:///db/apps/BetMas/modules/tei2string.xqm";
import module namespace morpho="http://betamasaheft.eu/parser/morpho" at "xmldb:exist:///db/apps/parser/modules/morphoparser.xqm";
declare namespace t = "http://www.tei-c.org/ns/1.0";
declare namespace xconf = "http://exist-db.org/collection-config/1.0";
declare namespace sr = "http://www.w3.org/2005/sparql-results#";

declare variable $q:deleted := doc('/db/apps/lists/deleted.xml');
declare variable $q:collection as xs:string := request:get-parameter('collection', ());
declare variable $q:name as xs:string := request:get-parameter('name', ());
declare variable $q:searchType as xs:string := request:get-parameter('searchType', ());
declare variable $q:mode as xs:string := request:get-parameter('mode', ());
declare variable $q:defop := request:get-parameter('defaultoperator', ());
declare variable $q:sort as xs:string := if (request:get-parameter('sort', ())) then
    request:get-parameter('sort', ())
else
    '';
declare variable $q:params := request:get-parameter-names();
declare variable $q:facets := doc("/db/system/config/db/apps/expanded/collection.xconf")//xconf:facet/@dimension;
declare variable $q:TEIrangeFields := doc("/db/system/config/db/apps/expanded/collection.xconf")//xconf:range/xconf:create/xconf:field/@name;
declare variable $q:col := collection("/db/apps/expanded/");
declare variable $q:populatefacets := for $parm in $q:params[ends-with(., '-facet')]
let $key := substring-before($parm, '-facet')
let $values := request:get-parameter($parm, ())
return
    map {$key: ($values)};
declare variable $q:populatefields := for $parm in $q:params[ends-with(., '-field')][not(contains(., '-operator-'))]
let $key := substring-before($parm, '-field')
let $values := request:get-parameter($parm, ())
return
    map {$key: ($values)};
declare variable $q:optionsFacet := map:merge($q:populatefacets);
declare variable $q:optionsFields := map:merge($q:populatefields);
declare variable $q:allopts := map {
    'default-operator': $q:defop,
    'phrase-slop': '0',
    'leading-wildcard': 'no',
    'filter-rewrite': 'yes',
    'facets': $q:optionsFacet,
    "fields": $q:optionsFields
};


declare variable $q:lists := collection('/db/apps/lists/');
declare variable $q:languages := doc('/db/apps/lists/languages.xml');
declare variable $q:tax := doc('/db/apps/lists/canonicaltaxonomy.xml');
declare variable $q:range-lookup3 :=function-lookup(xs:QName("range:index-keys-for-field"), 3);
declare variable $q:range-lookup :=
(
function-lookup(xs:QName("range:index-keys-for-field"), 4),
function-lookup(xs:QName("range:index-keys-for-field"), 3)
)[1];

declare variable $q:util-index-lookup :=
(
function-lookup(xs:QName("util:index-keys"), 5),
function-lookup(xs:QName("util:index-keys"), 4)
)[1];


(:~ 
 : Functions with values which depend on the request parameters (to keep values as selected when the user runs a query.
 : called by newSearch.html
 :)

declare function q:querytype($node as node(), $model as map(*)) {
let $querytypeparam:= request:get-parameter('searchType', ())
return
    <select id="SType" name="searchType" class="w3-select">
        <option value="text">{if($querytypeparam='' or $querytypeparam='text') then attribute selected {'selected'} else ()}Simple Text search (select here another type of search)</option>
        <option value="bmid">{if($querytypeparam='bmid') then attribute selected {'selected'} else ()}Lookup Beta maṣāḥǝft ID</option>
        <option value="clavis">{if($querytypeparam='clavis') then attribute selected {'selected'} else ()}Lookup Clavis Aethiopica Number</option>
        <option  value="otherclavis">{if($querytypeparam='otherclavis') then attribute selected {'selected'} else ()}Lookup other Clavis ID</option>
        <option value="fields">{if($querytypeparam='fields') then attribute selected {'selected'} else ()}Additional Fields</option>
        <option  value="xpath">{if($querytypeparam='xpath') then attribute selected {'selected'} else ()}Xpath</option>
        <option   value="list">{if($querytypeparam='list') then attribute selected {'selected'} else ()}list</option>
        <!--
split for each list or resource specific, it will show  a search box and a series of filters specific to the list type, 
these will be the parameters and will be mixable with the facets. search without query will search all. each list as a specific context and specific filters

keywords list
decorations, additions, titles, binding lists
clavis/mss/institutions/places/persons lists
catalogues list
shelf marks list
advanced search
-->
        <option
            value="sparql">{if($querytypeparam='sparql') then attribute selected {'selected'} else ()}SPARQL</option>
    </select>
};

declare function q:textquerymode($node as node(), $model as map(*)) {
let $textquerymodeparam:= request:get-parameter('mode', ())
return
    <select
        name="mode"
        class="w3-select"
        style="padding:0px 0px;">
        <option
            value="none">{if($textquerymodeparam='' or $textquerymodeparam='none') then attribute selected {'selected'} else ()}default (no mode)</option>
        <option
            value="any">{if($textquerymodeparam='any') then attribute selected {'selected'} else ()}any</option>
        <option
            value="all">{if($textquerymodeparam='all') then attribute selected {'selected'} else ()}all</option>
        <option
            value="phrase">{if($textquerymodeparam='phrase') then attribute selected {'selected'} else ()}phrase</option>
        <option
            value="regex">{if($textquerymodeparam='regex') then attribute selected {'selected'} else ()}regex</option>
        <option
            value="wildcard">{if($textquerymodeparam='wildcard') then attribute selected {'selected'} else ()}wildcard</option>
        <option
            value="fuzzy">{if($textquerymodeparam='fuzzy') then attribute selected {'selected'} else ()}fuzzy</option>
        <option
            value="near-ordered">{if($textquerymodeparam='near-ordered') then attribute selected {'selected'} else ()}near-ordered</option>
        <option
            value="near-unordered">{if($textquerymodeparam='near-unordered') then attribute selected {'selected'} else ()}near-unordered</option>
    </select>
};

declare function q:textquerydefaultoperator($node as node(), $model as map(*)) {
let $defopparam:= $q:defop
return
    <select
        name="defaultoperator"
        class="w3-select"
        style="padding:0px 0px;">
        <option
            value="OR">{if($defopparam='' or $defopparam='OR') then attribute selected {'selected'} else ()}default (OR)</option>
        <option
            value="AND">{if($defopparam='AND') then attribute selected {'selected'} else ()}AND</option>
         </select>
};

declare function q:homophonecheckbox($node as node()*, $model as map(*)){
let $h:= request:get-parameter('homophones', ())
return
<input type="checkbox" name="homophones">{if(not($q:params = $h) or $h='on') then attribute checked{"checked"} else ()}</input>
};

declare function q:ranking($node as node()*, $model as map(*)){
let $h:= request:get-parameter('sort', ())
return
<input type="checkbox" name="sort" >{if($h='on') then attribute checked{"checked"} else ()}</input>
};

declare function q:translitcheckbox($node as node()*, $model as map(*)){
let $h:= request:get-parameter('translit', ())
return
<input type="checkbox" name="translit">{if($h='on') then attribute checked{"checked"} else ()}</input>
};




(:~ 
 : the most generic ft:query call returning a map with the  query, the results, the timing and the type of query
 :)
declare function q:query($node as node()*, $model as map(*), $query as xs:string*) {
    let $start-time := util:system-time()
    let $t := if (request:get-parameter('searchType', ())) then
        $q:searchType
    else
        'undefined'
    return
        if ((string-length($query) lt 1) and ($t != 'fields')) then
            ()
        else
            let $hits := q:switchSearchType($t, $query, $q:params)
            let $runtime-ms := ((util:system-time() - $start-time) div xs:dayTimeDuration('PT1S')) * 1000
            return
                map {
                    'runtime': $runtime-ms,
                    'type': $t,
                    'query': $query,
                    'hits': $hits
                }
};


(:~
: This function takes the query string and the parameters and redirects to the correct query type and result format passing on filtering parameters
:)
declare function q:switchSearchType($t, $q, $params) {
    switch ($t)
        (:a query based on ft:query() and lucene indexes will always have facets and fields activated and search the two parallel indexes on the full TEI 
like the facet, simple and advanced searches :)
        case 'text'
            return
                q:text($q, $params)
                (:   a generic xpath returning elements of any kind according to the specified path :)
        case 'fields'
            return
                q:text($q, $params)
                (:   a generic xpath returning elements of any kind according to the specified path :)
        case 'xpath'
            return
                q:xpath($q, $params)
                (:a query based on xpath selectors returning TEI records homogeneous for their type, e.g. manuscripts/list, catalogue list, institution list, etc persons, clavis :)
        case 'list'
            return
                'list'
                (:a query to the sparql endpoint to the RDF, returning a sparql response :)
        case 'sparql'
            return
                q:sparql($q)
                (:a query to a specific element returning options to filter it in more detail e.g. decorations, bibliography, additions :)
        case 'clavis'
            return
                q:clavis($q)
       case 'otherclavis'
            return
                q:otherclavis($q)
       case 'bmid'
            return
                q:bmid($q)
        case 'resources'
            return
                'resources'
                (:                default is a search for the empty string, returning all data...:)
        default return
           for $r in $q:col//t:TEI[ft:query(., (), $q:allopts)] group by $TEI := $r return $TEI
};


(:~
: from the results of a q:query displays in the header of the search result the time of the query (not of loading the HTML... or response from the server...) 
:)
declare function q:displayQtime($node as node()*, $model as map(*)) {
    
    <div
        class="w3-panel w3-card-4">{
            if ($model('type') = 'bibliography') then
                <h3>There are <span
                        xmlns="http://www.w3.org/1999/xhtml"
                        class="w3-tag w3-gray"
                        id="hit-count">{count($model("hits"))}</span>
                    distinct bibliographical references</h3>
            else
                if ($model('type') = 'matches') then
                    <h3>You found <span
                            class="w3-tag w3-gray">{q:create-field-query($model('query'), $q:mode)}</span> in
                        <span
                            xmlns="http://www.w3.org/1999/xhtml"
                            id="hit-count"
                            class="w3-tag w3-gray">{count($model("hits"))}</span> results</h3>
                else
                    (<h3> There are <span
                            xmlns="http://www.w3.org/1999/xhtml"
                            id="hit-count"
                            class="w3-tag w3-gray">{count($model("hits"))}</span>
                        entities matching your
                        <span
                            class="w3-label w3-margin">{$q:searchType}
                        </span>
                        <span
                            class="w3-tooltip">query
                            <span
                                class="w3-text">(<em>{$model('query')}</em>)</span></span></h3>),
            <span
                class="w3-right">{'Search time: '}
                <span
                    class="w3-badge">{$model('runtime')}</span>
                {' milliseconds.'}</span>
        }
    </div>

};

declare function q:bmid($q){
for $m in  $q:col//t:TEI[contains(@xml:id,$q)] 
group by $TEI := $m
    return $TEI
};

declare function q:otherclavis($q){
let $clavisType := request:get-parameter('clavistype', ())
let $selector :=  if(($q = '') and (matches($clavisType, '\w+'))) 
                           then "[descendant::t:bibl[@type eq '"||$clavisType||"']]"
                           else  "[descendant::t:bibl[@type eq '"||$clavisType||"'][t:citedRange eq '"||$q||"']]"
 let $path := '$q:col//t:TEI[@type="work"]' || $selector
for $m in util:eval($path)
        group by $TEI := $m
    return $TEI
};


declare function q:clavis($q) {
    let $q := format-number($q, '0000')
    let $clavisNsearch := if ($q = '') then
        ()
    else
        "[contains(@xml:id, '" || string(format-number($q, '0000')) || "') and not(ends-with(@xml:id, 'IHA'))]"
    let $deletedClavis := for $d in doc('/db/apps/lists/deleted.xml')//t:item[contains(., $q)]
    return
        map {
            'hit': $d,
            'type': 'deleted'
        }
    let $path := '$q:col//t:TEI[@type="work"]' || $clavisNsearch
    (:the following needs to group due to the two indexes:)
    let $matches := for $m in util:eval($path)
        group by $TEI := $m
    return
        map {
            'hit': $TEI,
            'type': 'match'
        }
    return
        ($deletedClavis, $matches)
};

declare function q:xpath($q, $params) {
    let $q := for $query in normalize-space($q)
    return
        if ($q = '') then
            ()
        else
            $q
    let $xpath := replace($q, '\$config:collection-(\w+)(//.+)', 'collection(\$config:data-$1)$2')
    return  util:eval($xpath)
};

declare function q:sparql($q) {
    let $prefixes := "PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#>
         PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
         PREFIX lawd: <http://lawd.info/ontology/>
         PREFIX oa: <http://www.w3.org/ns/oa#>
         PREFIX ecrm: <http://erlangen-crm.org/current/>
         PREFIX crm: <http://www.cidoc-crm.org/cidoc-crm/>
         PREFIX gn: <http://www.geonames.org/ontology#>
         PREFIX agrelon: <http://d-nb.info/standards/elementset/agrelon.owl#>
         PREFIX rel: <http://purl.org/vocab/relationship/>
         PREFIX dcterms: <http://purl.org/dc/terms/>
         PREFIX bm: <https://betamasaheft.eu/>
         PREFIX bmont: <https://betamasaheft.eu/ontology/>
         PREFIX pelagios: <http://pelagios.github.io/vocab/terms#>
         PREFIX syriaca: <http://syriaca.org/documentation/relations.html#>
         PREFIX saws: <http://purl.org/saws/ontology#>
         PREFIX snap: <http://data.snapdrgn.net/ontology/snap#>
         PREFIX pleiades: <https://pleiades.stoa.org/>
         PREFIX wd: <https://www.wikidata.org/>
         PREFIX dc: <http://purl.org/dc/elements/1.1/>
         PREFIX skos: <http://www.w3.org/2004/02/skos/core#>
         PREFIX xsd: <http://www.w3.org/2001/XMLSchema#>
         PREFIX t: <http://www.tei-c.org/ns/1.0>
         PREFIX geo: <http://www.w3.org/2003/01/geo/wgs84_pos#>
         PREFIX foaf: <http://xmlns.com/foaf/0.1/>
         PREFIX sdc: <https://w3id.org/sdc/ontology#>"
    let $allquery := ($prefixes || normalize-space($q))
    return
        fusekisparql:query('betamasaheft', $allquery)
};

declare function q:text($q, $params) {
    let $qs := q:querystring($q, $q:mode)
    let $query :=  $q:col//t:TEI[ft:query(., $qs, $q:allopts)]
    return
        if ($q:sort = '')
        then
            for $r in $query
            group by $TEI := $r
            let $matchcount := q:matchescount($TEI)
            order by $matchcount descending
            return
                $TEI
        else
            for $r in $query
            group by $TEI := $r
             let $matchcount := q:matchescount($TEI)
            let $title := q:sortingkey($TEI//t:titleStmt/t:title[1]/text())
            let $sort := q:enrichScore($TEI)
                order by $sort descending
            return
                $TEI
};

declare function q:indexquery($element, $q) {
    let $path := '$q:col//t:' || $element || '[ft:query(., $q, $q:allopts)]'
    for $q in util:eval($path)
    return
        $q/ancestor::t:TEI
};

declare function q:tracesquery($q){
let $sparql := 
"PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
SELECT DISTINCT ?translit
WHERE {
{  ?subject rdfs:label '" || $q || "'@gez ;
                 rdfs:label ?translit .
  FILTER (lang(?translit) = 'gez-trsl') }
  UNION
  {  ?subject rdfs:label '" || $q || "'@gez-trsl ;
                 rdfs:label ?translit .
  FILTER (lang(?translit) = 'gez') }
}" 
                let $query := fusekisparql:query('traces', $sparql)
               return $query//sr:binding/sr:literal/text()
               };

declare function q:gettranslit($sequenceoftokens){
 for $q in $sequenceoftokens 
                let $traces := q:tracesquery($q)
                
 (:if nothing has been found in traces then the morphoparser can provide a tempative transliteration, 
   which will be in none of the official formats, because this is made meaningless by the homophons substitutions:)
            return
            if(count($traces) ge 1) 
                then $traces 
                else q:prepareformorphoparser($q)
};

declare function q:translitquery($query-string){
let $tokenizedquery := if(contains($query-string, ' ')) then tokenize($query-string, ' ') else $query-string

(:this variable will return at least one transliteration option for each token:)

               let $trytraces :=  q:gettranslit($tokenizedquery)
(: traces contains only singe token annotations so the query must be repeated for each word. It may return for one part only of the query:)

 (:how to join this, which will then be passed to the substitutions and then to the query builder, depends on the mode and the operator
each transliteration is alternative to the term, so it should be (source OR translit) if the query is for any term 
:)
(:but if this is a phrase search, 
<query><phrase>(wä-kāʿǝbä OR ወካዕበ፡) (äʿräfä OR አዕረፈ፡)</phrase></query> 
will not work
we need alternate phrases, so the results of the query for each term need to be joined among them before being grouped
:)
              let $modejoin := if(request:get-parameter('mode', ()) = 'phrase') 
                            then 
                            (:                                      'source1 source2' OR 'translit1 translit2' :)
                            <query><phrase>{string-join($trytraces, ' ')}</phrase><phrase>{string-join($tokenizedquery, ' ')}</phrase></query>

                           else if($q:defop = 'AND') 
                            then 
                            (:    (source1 AND source2) OR (translit1 AND translit2) :)
                            <query>
                            <bool>
                                 <bool occur="should">
                                     {for $t in $trytraces return <term occur="must">{$t}</term>}
                                 </bool>
                                 <bool occur="should">
                                     {for $t in $tokenizedquery return <term occur="must">{$t}</term>}
                                 </bool>
                            </bool>
                            </query> 
                            else 
                            (:   (source1 OR translit1) AND/OR (source2 OR translit2)
here AND / OR should be the default operator chosen, so leaving it blank actually defaults to the configuration
(source1 OR translit1) (source2 OR translit2)    :)
                               let $toks := for $tok at $p in $tokenizedquery 
                                                return 
                                                <bool>
                                                {attribute occur {if($q:defop = 'AND') then 'must' else 'should'}}
                                                <term occur="should">{$trytraces[$p]}</term>
                                                <term occur="should">{$tok}</term>
                                 </bool> 
                               
                               return <query><bool>{$toks}</bool></query>
                          
                          return $modejoin
   

 
};

declare function q:prepareformorphoparser($q){
let $cleanup := morpho:cleanQ($q, 'true', 'BM')
return
(:if the string was in transliteration, I already have what I want:)
if(not(matches($q, '\p{IsEthiopic}'))) 
    then $cleanup 
    else 
            let $chars := functx:chars($q)
            let $parsed := morpho:formulas($chars,$q,'BM','fuzzy')
            return morpho:genericTranscription($parsed)
};

(:before anything is done, get rid of punctuation... :)
declare function q:cleanquery($query-string){
replace($query-string, '፡', '')
};


declare function q:querystring($query-string, $mode as xs:string*) {
let $query-string := q:cleanquery($query-string)
return
    if ($q:searchType = 'fields') 
    then
        q:create-field-query($query-string, $mode)
    else
        let $homophonesparam := request:get-parameter('homophones', ())
        let $translitparam := request:get-parameter('translit', ())
        let $homophones :=  if ($homophonesparam='on' and (string-length($query-string) le 10)) then  'true'  else   'false'
        let $translit-query-string := if($translitparam='on') then q:translitquery($query-string) else $query-string
   (:        translit will return a query already. but if that did not go through the input may be a string :)
(:    here a temporary query is stored, which is either a parsing of a string or an improvement of the existing one it calls the creat-query function :)
       let $modequery := 
           <querytemp>{if ($mode = 'none') then
                                                  (  if (functx:contains-any-of($translit-query-string, ('AND', 'OR', 'NOT', '+', '-', '!', '~', '^', '.', '?', '*', '|', '{', '[', '(', '<', '@', '#', '&amp;'))) 
                                                        then
                                             q:create-query($translit-query-string, $mode)
                                                         else
                                                        $translit-query-string)
                  else if ($mode = 'regex' or $mode='wildcard' or $mode = 'fuzzy') then q:create-query($query-string, $mode)
(:                  for these three modes ignore any homophones or transliteration:)
                else if ($mode = 'phrase'  or starts-with($mode, 'near')) then
               typeswitch($translit-query-string )
               case element(query) return $translit-query-string
               default return 
                                            let $createq := q:create-query($translit-query-string, $mode)
                                            return $createq
                else
                q:create-query($translit-query-string, $mode)
                }</querytemp> 
                
  let $subs-query-string := if ($mode = 'regex' or $mode='wildcard' or $mode = 'fuzzy') then $modequery else <querytemp>{q:loopqueryxml($modequery, $homophones)}</querytemp>
  
  let $query-clean-up := if ($mode = 'regex' or $mode='wildcard' or $mode = 'fuzzy') then $modequery/querytemp else q:querycleanup($subs-query-string)
    
         return
         $query-clean-up
};


(:the query coming out of the substitutions pass contains extra terms and query elements 
a descandant query element should be removed, only one is allowed at the top.
a term with children bool shuold also be removed
consecutive bool[@occur] with only one child element term[@occur] can be removed:)
declare function q:querycleanup($xmlquery){for $node in $xmlquery/node()
return typeswitch($node)
   case element(query) return  if($node/ancestor::query) then q:querycleanup($node) else <query>{q:querycleanup($node)}</query>
   case element(term) return  if((count($node/descendant::bool) ge 1) or ($node/ancestor::fuzzy)or ($node/ancestor::wildcard)or ($node/ancestor::regex)) then q:querycleanup($node) else element {$node/name()} {($node/@*, q:querycleanup($node))}
    case element(bool) return 
    if ($node/@occur = 'must') then element {$node/name()} {($node/@*, q:querycleanup($node))} 
    else
                   if($node/bool[@occur][count(term[@occur]) eq 1]) then 
                   for $term in $node/bool[@occur][count(term[@occur]) eq 1] 
                   group by $occur := $term/@occur
                   return
                   <bool>
                   {$occur}
                   {q:querycleanup($term)}
                   </bool>
                   else if ($node/ancestor::near or $node/ancestor::fuzzy) then q:querycleanup($node)
                    else element {$node/name()} {($node/@*, q:querycleanup($node))}
   case element() return element {$node/name()} {($node/@*, q:querycleanup($node))}
   default return $node};

(:the query may be text or already a moded xml query. This loops through whatever comes in and adds options from the substitutions 
it should always get an xml node which should contain a query element and children

text children are those which should be passed to substitute and add options from homophones.  
it goes in anyway, and the q:subst checks for the homophones parameter
if the query is a phrase query, nothing should be done. otherways options should be added within the query structure
:)
declare function q:loopqueryxml($xmlquery, $homophones){
for $node in $xmlquery/node() 
   return 
    typeswitch ($node)
            case text() return 
(:                  this should return a list of options for a term. these need to be formatted into a part of query:)
              let $andchecksubs := if(not(functx:contains-any-of($node, ('AND', 'OR', 'NOT', '+', '-', '!', '~', '^', '.', '?', '*', '|', '{', '[', '(', '<', '@', '#', '&amp;'))) and contains($node, ' ') and $q:defop = 'AND') then replace($node, ' ', ' AND ') else $node    
              let $subs :=     q:subst($andchecksubs, $homophones)
             return typeswitch($subs)
(:             if the result of substitutions is a query, go with that:)
                       case element()  
                       return $subs/query
(:                       if the result is a string, then pass it on to the query parser to make it into a series of element, but do not take the query element, which should already be there :)
                       default return   
                                let $andchecksubs := if(not(functx:contains-any-of($subs, ('AND', 'OR', 'NOT', '+', '-', '!', '~', '^', '.', '?', '*', '|', '{', '[', '(', '<', '@', '#', '&amp;'))) and contains($subs, ' ') and $q:defop = 'AND') then replace($subs, ' ', ' AND ') else $subs
                                let $luceneParse := q:parse-lucene($andchecksubs)
                                let $luceneXML := parse-xml($luceneParse)
                                let $mode := if($q:defop = 'AND') then 'all' else 'any'
                                let $lucene2xml := q:lucene2xml($luceneXML/node(), $mode)
                                return $lucene2xml
            case element(phrase) return  
                   element {$node/name()} {$node/text()}
           default 
                  return element {$node/name()} {($node/@*, q:loopqueryxml($node, $homophones))}
};


(:all:substinsInQuery will return (term OR term1) strings. This reasons in terms of receiving a string. 
The string can actually be also an already composed thing. 
If that is the case, then the query will be built and the q:loopqueryxml called within, so xml will be returned. 
in most cases a string query will be returned:)
declare function q:groupsubst($query, $homophones){
(:query with AND:)
   if (contains($query, 'AND')) then
                (let $parts := for $qpart in tokenize($query, 'AND')
                return
                    all:substitutionsInQuery($qpart)
                return
                    '(' || string-join($parts, ') AND (')) || ')'
(:                    query with OR :)
            else  if (contains($query, 'OR') and (not(matches($query, '[\(\)]')))) then
                    (let $parts := for $qpart in tokenize($query, 'OR')
                    return
                        all:substitutionsInQuery($qpart)
                    return
                        '(' || string-join($parts, ') OR (')) || ')'
(:                        complex query :)
                else  if (contains($query, 'OR') and (matches($query, '[\(\)]'))) then
                  
                                let $luceneParse := q:parse-lucene($query)
                                let $luceneXML := parse-xml($luceneParse)
                                let $lucene2xml := <querytemp>{q:lucene2xml($luceneXML/node(), 'any')}</querytemp>
                                
                                return
                            q:loopqueryxml($lucene2xml/query, $homophones)
                else
(:                only text :)
                    all:substitutionsInQuery($query)
                    };
                    
                    
                    
declare function q:subst($query, $homophones) {
       if ($query != '')
    then
        (if ($homophones = 'true')
        then
            q:groupsubst($query, $homophones)
        else
            $query)
    else
        ()
};



declare function q:create-field-query($query-string, $mode) {
    let $fields := for $field in $q:params[ends-with(., '-field')][not(contains(., '-operator'))]
    let $fieldpar := request:get-parameter($field, ())
    return
        if ($fieldpar = '') then
            ()
        else
            let $operator := replace($field, '-field', '-operator-field')
            return
                request:get-parameter($operator, ()) || ' ' || substring-before($field, '-field') || ':(' || $fieldpar || ')'
    let $joinfields := string-join($fields, ' ')
    let $query := $query-string || ' ' || (if ($query-string = '') then
        (if (starts-with($joinfields, 'AND')) then
            substring-after($joinfields, 'AND ')
        else
            substring-after($joinfields, 'OR '))
    else
        $joinfields)
    return
        $query
};


declare function q:showFacets($node as node()*, $model as map(*)) {
    if ($q:searchType = 'clavis' or $q:searchType = 'otherclavis' or $q:searchType = 'xpath' or $q:searchType = 'sparql' ) then
        <div><p>No facets available for this type of search.</p></div>
    else
        let $subsequence := $model('hits')
        let $itemtype := $q:facets[. eq 'type']
        let $general := $q:facets[parent::xconf:facet[not(@if)][not(@dimension eq 'type')]]
        let $mss := $q:facets[parent::xconf:facet[contains(@if, 'mss')]]
        let $works := $q:facets[parent::xconf:facet[contains(@if, 'work')]]
        let $places := $q:facets[parent::xconf:facet[contains(@if, 'place')]]
        let $persons := $q:facets[parent::xconf:facet[contains(@if, 'pers')]]
        return
            <form
                id="facetsSearch"
                action=""
                class="w3-container w3-center">
                <div
                    class="w3-row w3-left-align">
                    <button
                        type="submit"
                        class="w3-button w3-block w3-left-align w3-red">refine search results <i
                            class="fa fa-search"></i></button>
                   { for $param in request:get-parameter-names()
                   for $notfacet in $param[not(ends-with(.,'-facet'))]
                   let $p := request:get-parameter($notfacet, ())
                   return if(count($p)) then
                    <input
                        name="{$notfacet}"
                        value="{$p}"
                        hidden="hidden"/> else () }
                </div>
                {q:facetGroup($itemtype, 'Resource type', $subsequence)}
                {q:facetGroup($general, 'General', $subsequence)}
                {q:facetGroup($mss, 'Manuscripts', $subsequence)}
                {q:facetGroup($works, 'Textual and Narrative Units', $subsequence)}
                {q:facetGroup($places, 'Places and Repositories', $subsequence)}
                {q:facetGroup($persons, 'Persons and Groups', $subsequence)}
                <div
                    class="w3-row w3-left-align">
                    <button
                        type="submit"
                        class="w3-button w3-block w3-left-align w3-red">refine search results <i
                            class="fa fa-search"></i></button>
                </div>
            </form>
};

declare function q:facetGroup($group, $groupname, $subsequence) {
    <div>
        <div
            class="w3-row w3-left-align w3-margin-top"><b>{$groupname}</b></div>
        {
            for $f in $group
            let $facetTitle := q:facetName($f)
            let $facets := ft:facets($subsequence, string($f), ())
                order by $facetTitle
                group by $ft := $facetTitle
            return
                q:facetDiv($f[1], $facets, $ft)
        }</div>
};

declare function q:facetDiv($f, $facets, $facetTitle) {
    let $facets := map:merge($facets)
    return
        if (map:size($facets) = 0) then
            ()
        else
            <div
                class="w3-row w3-left-align">
                <button
                    type="button"
                    onclick="openAccordion('{string($f)}-facet-list')"
                    class="w3-button w3-block w3-left-align w3-gray">{
                        $facetTitle
                    }</button>
                <div
                    class="w3-padding w3-hide"
                    id="{string($f)}-facet-list">
                    {
                        let $inputs := map:for-each($facets, function ($label, $count) {
                            <span><input
                                    class="w3-check w3-margin-right"
                                    type="checkbox"
                                    name="{string($f)}-facet"
                                    value="{$label}"/>
                                {
                                    if ($f = 'witness')
                                    then
                                        titles:printTitleID($label)
                                    else
                                        if ($f = 'changeWho') then
                                            editors:editorKey($label)
                                        else
                                            if ($f = 'languages') then
                                                $q:languages//t:item[@xml:id eq $label]/text()
                                            else
                                                $label
                                }
                                <span
                                    class="w3-badge w3-margin-left">{$count div 2}</span><br/></span>
                        })
                        return
                            if ($f = 'keywords') then
                                (for $input in $inputs
                                let $val := $input/*:input/@value
                                let $taxonomy := $q:tax//t:catDesc[. eq $val]/ancestor::t:category[t:desc][1]/t:desc/text()
                                    group by $taxonomy
                                    order by $taxonomy
                                return
                                    <div
                                        class="w3-row w3-left-align">
                                        <button
                                            type="button"
                                            onclick="openAccordion('{string($f)}-{replace($taxonomy, ' ', '')}-facet-sublist')"
                                            class="w3-button w3-block w3-left-align w3-gray">
                                            {$taxonomy}
                                        </button>
                                        <div
                                            class="w3-padding w3-hide"
                                            id="{string($f)}-{replace($taxonomy, ' ', '')}-facet-sublist">{
                                                for $i in $input
                                                let $sortkey := q:sortingkey($i)
                                                    order by $sortkey
                                                return
                                                    $i/node()
                                            }</div></div>)
                            else
                                if ($f = 'changeWhen') then
                                    (for $input in $inputs
                                    let $val := $input/*:input/@value
                                    let $taxonomy := substring-before($val, '-')
                                        group by $taxonomy
                                        order by xs:gYear($taxonomy) descending
                                    return
                                        <div
                                            class="w3-row w3-left-align">
                                            <button
                                                type="button"
                                                onclick="openAccordion('{string($f)}-{replace($taxonomy, ' ', '')}-facet-sublist')"
                                                class="w3-button w3-block w3-left-align w3-gray">
                                                {$taxonomy}
                                            </button>
                                            <div
                                                class="w3-padding w3-hide"
                                                id="{string($f)}-{replace($taxonomy, ' ', '')}-facet-sublist">{
                                                    for $i in $input
                                                    let $sortkey := q:sortingkey($i)
                                                        order by $sortkey
                                                    return
                                                        $i/node()
                                                }</div></div>)
                                else
                                    if ($f = 'titleRef') then
                                        (for $input in $inputs
                                        let $sortkey := q:sortingkey($input)
                                        let $first := substring($sortkey, 1, 1)
                                            group by $first
                                            order by $first
                                        return
                                            <div
                                                class="w3-row w3-left-align">
                                                <button
                                                    type="button"
                                                    onclick="openAccordion('{string($f)}-{$first}-facet-sublist')"
                                                    class="w3-button w3-block w3-left-align w3-gray">
                                                    {upper-case($first)}
                                                </button>
                                                <div
                                                    class="w3-padding w3-hide"
                                                    id="{string($f)}-{$first}-facet-sublist">{
                                                        for $i in $input
                                                        let $sortkey := q:sortingkey($i)
                                                            order by $sortkey
                                                        return
                                                            $i/node()
                                                    }</div></div>)
                                    else
                                        (for $input in $inputs
                                        let $sortkey := q:sortingkey($input)
                                            order by $sortkey
                                        return
                                            $input/node()
                                        )
                    }
                </div>
            </div>
};

declare function q:sortingkey($input) {
    string-join($input//text())
    => replace('ʾ', '')
    => replace('ʿ', '')
    => replace('\s', '')
    => translate('ƎḤḪŚṢṣḫḥǝʷāṖ', 'EHHSSshhewaP')
    => lower-case()
};

declare function q:facetName($f) {
    switch ($f)
        case 'keywords'
            return
                'Keywords'
        case 'languages'
            return
                'Languages'
        case 'changeWho'
            return
                'Author of changes'
        case 'changeWhen'
            return
                'Date of changes'
        case 'script'
            return
                'Script'
        case 'condition'
            return
                'Condition'
        case 'form'
            return
                'Form'
        case 'material'
            return
                'Material'
        case 'height'
            return
                'Height'
        case 'width'
            return
                'Width'
        case 'depth'
            return
                'Depth'
        case 'scribe'
            return
                'Scribe'
        case 'donor'
            return
                'Donor'
        case 'msItemsCount'
            return
                'N. of content units'
        case 'msPartsCount'
            return
                'N. of Codicological Units'
        case 'handsCount'
            return
                'N. of Hands'
        case 'sealCount'
            return
                'N. of Seals'
        case 'QuireCount'
            return
                'N. of Quires'
        case 'AdditionsCount'
            return
                'N. of Additions'
        case 'AdditionsType'
            return
                'Types of Addition'
        case 'titleRef'
            return
                'Contents'
        case 'titleType'
            return
                'Complete/Incomplete contents'
        case 'ExtraCount'
            return
                'N. of Extras'
        case 'ExtraType'
            return
                'Types of Extra'
        case 'leafs'
            return
                'N. of leaves'
        case 'origDateNotBefore'
            return
                'Date of production (not before)'
        case 'origDateNotAfter'
            return
                'Date of production (not after)'
        case 'origplace'
            return
                'Place of origin'
        case 'repository'
            return
                'Repository'
        case 'collection'
            return
                'Collection'
        case 'rulingpattern'
            return
                'Ruling Pattern'
        case 'artThemes'
            return
                'Art Themes (in decorations)'
        case 'artkeywords'
            return
                'Art Keywords (in decorations)'
        case 'bindingkeywords'
            return
                'Keywords (in binding)'
        case 'rubricationkeywords'
            return
                'Keywords (in rubrication)'
        case 'decoType'
            return
                'Type of Decoration'
        case 'calendarType'
            return
                'Type of calendar used'
        case 'images'
            return
                'Images Availability'
        case 'writtenLines'
            return
                'Written Lines'
        case 'columns'
            return
                'Columns'
        case 'authors'
            return
                'Authors'
        case 'textDivs'
            return
                'Text parts'
        case 'sawsVersionOf'
            return
                'Versions'
        case 'sex'
            return
                'Gender'
        case 'name'
            return
                'Personal Name in language'
        case 'group'
            return
                'Group'
        case 'faith'
            return
                'Faith'
        case 'sameAs'
            return
                'Alignment'
        case 'personSameAs'
            return
                'Alignment'
        case 'placetype'
            return
                'Type of place'
        case 'settlement'
            return
                'Settlement'
        case 'region'
            return
                'Region'
        case 'country'
            return
                'Country'
        case 'witness'
            return
                'Witnesses'
        case 'thereistext'
            return
                'Text'
        case 'thereistranscription'
            return
                'Transcription'
        case 'reltype'
            return
                'Relation Names'
        case 'bindingMaterial'
            return
                'Binding Material'
        case 'tabot'
            return
                'Tābots'
        case 'occupation'
            return
                'Occupation Type'
       case 'persDateNotBefore'
            return
                'Date Not Before'
                case 'persDateNotAfter'
            return
                'Date Not After'
                case 'persDateWhen'
            return
                'Date point'
                     case 'eth'
            return
                'Ethnic group'
        default return
            'Item type'
};

(:~
    Helper function: create a lucene query from the user input
:)

declare function q:create-query($query-string as xs:string?, $mode as xs:string) {
let $query-string := if ($query-string)   then q:sanitize-lucene-query($query-string)   else  ''
        (:        strip out full stop if in the query :)
let $query-string := replace(normalize-space($query-string), '\.', '')
let $query :=    
    (:    this filters queries to fields so that they are not passed as xml fragment:)
               if ($mode = 'none' or contains($query-string, ':')) 
               then $query-string
        (:If the query contains any operator used in standard lucene searches or regex searches, pass it on to the query parser;:)
                else
                    if (functx:contains-any-of($query-string, ('AND', 'OR', 'NOT', '+', '-', '!', '~', '^', '.', '?', '*', '|', '{', '[', '(', '<', '@', '#', '&amp;')) and ($mode eq 'any'))
                    then 
                                let $luceneParse := q:parse-lucene($query-string)
                                let $luceneXML := parse-xml($luceneParse)
                                let $lucene2xml := q:lucene2xml($luceneXML/node(), $mode)
                                return
                            $lucene2xml
                (:otherwise the query is performed by selecting one of the special options (any, all, phrase, near, fuzzy, wildcard or regex):)
                     else
                                let $query-string := tokenize($query-string, '\s')
                                let $last-item := $query-string[last()]
                                let $query-string :=
                                        if ($last-item castable as xs:integer)
                                        then
                                            string-join(subsequence($query-string, 1, count($query-string) - 1), ' ')
                                        else
                                                string-join($query-string, ' ')           
                                let $query :=
                                                 <query>
                            {
                    if ($mode eq 'any')
                    then
                        <bool>
                            {
                                for $term in tokenize($query-string, '\s')
                                return
                                    <term
                                        occur="should">{$term}</term>
                            }
                        </bool>
                    else
                        if ($mode eq 'all')
                        then
                            <bool>
                                {
                                    for $term in tokenize($query-string, '\s')
                                    return
                                        <term
                                            occur="must">{$term}</term>
                                }
                            </bool>
                        else
                            if ($mode eq 'phrase')
                            then
                                <phrase>{$query-string}</phrase>
                            else
                                if ($mode eq 'near-unordered')
                                then
                                    <near
                                        slop="{
                                                if ($last-item castable as xs:integer) then
                                                    $last-item
                                                else
                                                    5
                                            }"
                                        ordered="no">{$query-string}</near>
                                else
                                    if ($mode eq 'near-ordered')
                                    then
                                        <near
                                            slop="{
                                                    if ($last-item castable as xs:integer) then
                                                        $last-item
                                                    else
                                                        5
                                                }"
                                            ordered="yes">{$query-string}</near>
                                    else
                                        if ($mode eq 'fuzzy')
                                        then
                                            <fuzzy
                                                max-edits="{
                                                        if ($last-item castable as xs:integer and number($last-item) < 3) then
                                                            $last-item
                                                        else
                                                            2
                                                    }">{$query-string}</fuzzy>
                                        else
                                            if ($mode eq 'wildcard')
                                            then
                                                <wildcard>{$query-string}</wildcard>
                                            else
                                                if ($mode eq 'regex')
                                                then
                                                    <regex>{$query-string}</regex>
                                                else
                                                    ()
                }</query>
            return
                $query
    return
        $query

};



(: This functions provides crude way to avoid the most common errors with paired expressions and apostrophes. :)
(: TODO: check order of pairs:)
declare %private function q:sanitize-lucene-query($query-string as xs:string) as xs:string {
    let $query-string := replace($query-string, "'", "''") (:escape apostrophes:)
    (:Remove colons – Lucene fields are not supported.:)
    let $query-string := translate($query-string, ":", " ")
    let $query-string :=
    if (functx:number-of-matches($query-string, '"') mod 2)
    then
        $query-string
    else
        replace($query-string, '"', ' ') (:if there is an uneven number of quotation marks, delete all quotation marks.:)
    let $query-string :=
    if ((functx:number-of-matches($query-string, '\(') + functx:number-of-matches($query-string, '\)')) mod 2 eq 0)
    then
        $query-string
    else
        translate($query-string, '()', ' ') (:if there is an uneven number of parentheses, delete all parentheses.:)
    let $query-string :=
    if ((functx:number-of-matches($query-string, '\[') + functx:number-of-matches($query-string, '\]')) mod 2 eq 0)
    then
        $query-string
    else
        translate($query-string, '[]', ' ') (:if there is an uneven number of brackets, delete all brackets.:)
    let $query-string :=
    if ((functx:number-of-matches($query-string, '\{') + functx:number-of-matches($query-string, '\}')) mod 2 eq 0)
    then
        $query-string
    else
        translate($query-string, '{}', ' ') (:if there is an uneven number of braces, delete all braces.:)
    let $query-string :=
    if ((functx:number-of-matches($query-string, '<') + functx:number-of-matches($query-string, '>')) mod 2 eq 0)
    then
        $query-string
    else
        translate($query-string, '<>', ' ') (:if there is an uneven number of angle brackets, delete all angle brackets.:)
    return
        $query-string
};

(: Function to translate a Lucene search string to an intermediate string mimicking the XML syntax, 
with some additions for later parsing of boolean operators. The resulting intermediary XML search string will be parsed as XML with parse-xml(). 
Based on Ron Van den Branden, https://rvdb.wordpress.com/2010/08/04/exist-lucene-to-xml-syntax/:)
(:TODO:
The following cases are not covered:
1)
<query><near slop="10"><first end="4">snake</first><term>fillet</term></near></query>
as opposed to
<query><near slop="10"><first end="4">fillet</first><term>snake</term></near></query>

w(..)+d, w[uiaeo]+d is not treated correctly as regex.
:)
declare %private function q:parse-lucene($string as xs:string) {
    (: replace all symbolic booleans with lexical counterparts :)
    if (matches($string, '[^\\](\|{2}|&amp;{2}|!) '))
    then
        let $rep :=
        replace(
        replace(
        replace(
        $string,
        '&amp;{2} ', 'AND '),
        '\|{2} ', 'OR '),
        '! ', 'NOT ')
        return
            q:parse-lucene($rep)
    else
        (: replace all booleans with '<AND/>|<OR/>|<NOT/>' :)
        if (matches($string, '[^<](AND|OR|NOT) '))
        then
            let $rep := replace($string, '(AND|OR|NOT) ', '<$1/>')
            return
                q:parse-lucene($rep)
        else
            (: replace all '+' modifiers in token-initial position with '<AND/>' :)
            if (matches($string, '(^|[^\w&quot;])\+[\w&quot;(]'))
            then
                let $rep := replace($string, '(^|[^\w&quot;])\+([\w&quot;(])', '$1<AND type=_+_/>$2')
                return
                    q:parse-lucene($rep)
            else
                (: replace all '-' modifiers in token-initial position with '<NOT/>' :)
                if (matches($string, '(^|[^\w&quot;])-[\w&quot;(]'))
                then
                    let $rep := replace($string, '(^|[^\w&quot;])-([\w&quot;(])', '$1<NOT type=_-_/>$2')
                    return
                        q:parse-lucene($rep)
                else
                    (: replace parentheses with '<bool></bool>' :)
                    (:NB: regex also uses parentheses!:)
                    if (matches($string, '(^|[\W-[\\]]|>)\(.*?[^\\]\)(\^(\d+))?(<|\W|$)'))
                    then
                        let $rep :=
                        (: add @boost attribute when string ends in ^\d :)
                        (:if (matches($string, '(^|\W|>)\(.*?\)(\^(\d+))(<|\W|$)')) 
                            then replace($string, '(^|\W|>)\((.*?)\)(\^(\d+))(<|\W|$)', '$1<bool boost=_$4_>$2</bool>$5')
                            else:) replace($string, '(^|\W|>)\((.*?)\)(<|\W|$)', '$1<bool>$2</bool>$3')
                        return
                            q:parse-lucene($rep)
                    else
                        (: replace quoted phrases with '<near slop="0"></bool>' :)
                        if (matches($string, '(^|\W|>)(&quot;).*?\2([~^]\d+)?(<|\W|$)'))
                        then
                            let $rep :=
                            (: add @boost attribute when phrase ends in ^\d :)
                            (:if (matches($string, '(^|\W|>)(&quot;).*?\2([\^]\d+)?(<|\W|$)')) 
                                then replace($string, '(^|\W|>)(&quot;)(.*?)\2([~^](\d+))?(<|\W|$)', '$1<near boost=_$5_>$3</near>$6')
                                (\: add @slop attribute in other cases :\)
                                else:) replace($string, '(^|\W|>)(&quot;)(.*?)\2([~^](\d+))?(<|\W|$)', '$1<near slop=_$5_>$3</near>$6')
                            return
                                q:parse-lucene($rep)
                        else (: wrap fuzzy search strings in '<fuzzy max-edits=""></fuzzy>' :)
                            if (matches($string, '[\w-[<>]]+?~[\d.]*'))
                            then
                                let $rep := replace($string, '([\w-[<>]]+?)~([\d.]*)', '<fuzzy max-edits=_$2_>$1</fuzzy>')
                                return
                                    q:parse-lucene($rep)
                            else (: wrap resulting string in '<query></query>' :)
                                concat('<query>', replace(normalize-space($string), '_', '"'), '</query>')
};

(: Function to transform the intermediary structures in the search query generated through q:parse-lucene() and parse-xml() 
to full-fledged boolean expressions employing XML query syntax. 
Based on Ron Van den Branden, https://rvdb.wordpress.com/2010/08/04/exist-lucene-to-xml-syntax/:)
declare %private function q:lucene2xml($node as item(), $mode as xs:string) {
    typeswitch ($node)
        case element(query)
            return
                element {node-name($node)} {
                    element bool {
                        $node/node()/q:lucene2xml(., $mode)
                    }
                }
        case element(AND)
            return
                ()
        case element(OR)
            return
                ()
        case element(NOT)
            return
                ()
        case element()
            return
                let $name :=
                if (($node/self::phrase | $node/self::near)[not(@slop > 0)])
                then
                    'phrase'
                else
                    node-name($node)
                return
                    element {$name} {
                        $node/@*,
                        if (($node/following-sibling::*[1] | $node/preceding-sibling::*[1])[self::AND or self::OR or self::NOT or self::bool])
                        then
                            attribute occur {
                                if ($node/preceding-sibling::*[1][self::AND])
                                then
                                    'must'
                                else
                                    if ($node/preceding-sibling::*[1][self::NOT])
                                    then
                                        'not'
                                    else
                                        if ($node[self::bool] and $node/following-sibling::*[1][self::AND])
                                        then
                                            'must'
                                        else
                                            if ($node/following-sibling::*[1][self::AND or self::OR or self::NOT][not(@type)])
                                            then
                                                'should' (:must?:)
                                            else
                                                'should'
                            }
                        else
                            ()
                        ,
                        $node/node()/q:lucene2xml(., $mode)
                    }
        case text()
            return
                if ($node/parent::*[self::query or self::bool])
                then
                    for $tok at $p in tokenize($node, '\s+')[normalize-space()]
                    (:Here the query switches into regex mode based on whether or not characters used in regex expressions are present in $tok.:)
                    (:It is not possible reliably to distinguish reliably between a wildcard search and a regex search, so switching into wildcard searches is ruled out here.:)
                    (:One could also simply dispense with 'term' and use 'regex' instead - is there a speed penalty?:)
                    let $el-name :=
                    if (matches($tok, '((^|[^\\])[.?*+()\[\]\\^|{}#@&amp;<>~]|\$$)') or $mode eq 'regex')
                    then
                        'regex'
                    else
                        'term'
                    return
                        element {$el-name} {
                            attribute occur {
                                (:if the term follows AND:)
                                if ($p = 1 and $node/preceding-sibling::*[1][self::AND])
                                then
                                    'must'
                                else
                                    (:if the term follows NOT:)
                                    if ($p = 1 and $node/preceding-sibling::*[1][self::NOT])
                                    then
                                        'not'
                                    else (:if the term is preceded by AND:)
                                        if ($p = 1 and $node/following-sibling::*[1][self::AND][not(@type)])
                                        then
                                            'must'
                                            (:if the term follows OR and is preceded by OR or NOT, or if it is standing on its own:)
                                        else
                                            'should'
                            }
                            ,
                            if (matches($tok, '((^|[^\\])[.?*+()\[\]\\^|{}#@&amp;<>~]|\$$)'))
                            then
                                (:regex searches have to be lower-cased:)
                                attribute boost {
                                    lower-case(replace($tok, '(.*?)(\^(\d+))(\W|$)', '$3'))
                                }
                            else
                                ()
                            ,
                            (:regex searches have to be lower-cased:)
                            lower-case(normalize-space(replace($tok, '(.*?)(\^(\d+))(\W|$)', '$1')))
                        }
                else
                    normalize-space($node)
        default
            return
                $node
};

(:functions generating serch fields for the for form with an associated operator:)
declare function q:fieldinputTemplate($name, $parm) {
    <div
        class="w3-row"><label
            class="w3-col"
            style="width:10%">{$name}</label><br/>
        <select
            class="w3-select w3-col"
            style="width:10%"
            name="{$parm}-operator-field">
            <option
                selected="selected"
                value="AND">AND</option>
            <option
                value="OR">OR</option>
        </select>
        <input
            class="w3-input w3-col "
            style="width:80%"
            name="{$parm}-field"
            placeholder="type here the text you want to search into tei:{$parm}"/>
    
    </div>
};
declare function q:fieldInputDecoDesc($node as node(), $model as map(*), $decoDesc-field as xs:string*) {
    q:fieldinputTemplate('Decorations', 'decoDesc')
};

declare function q:fieldInputHandDesc($node as node(), $model as map(*), $handDesc-field as xs:string*) {
    q:fieldinputTemplate('Palaeography', 'handDesc')
};

declare function q:fieldInputBinding($node as node(), $model as map(*), $binding-field as xs:string*) {
    q:fieldinputTemplate('Binding', 'binding')
};

declare function q:fieldInputSupportDesc($node as node(), $model as map(*), $supportDesc-field as xs:string*) {
    q:fieldinputTemplate('Support', 'supportDesc')
};

declare function q:fieldInputMsContent($node as node(), $model as map(*), $msContent-field as xs:string*) {
    q:fieldinputTemplate('Contents', 'msContent')
};

declare function q:fieldInputText($node as node(), $model as map(*), $text-field as xs:string*) {
    q:fieldinputTemplate('Text / Transcription', 'text')
};

declare function q:fieldInputColophon($node as node(), $model as map(*), $colophon-field as xs:string*) {
    q:fieldinputTemplate('Colophon (as recorded in the catalogue record)', 'colophon')
};

declare function q:fieldInputIncipit($node as node(), $model as map(*), $incipit-field as xs:string*) {
    q:fieldinputTemplate('Incipit (as recorded in the catalogue record)', 'incipit')
};

declare function q:fieldInputExplicit($node as node(), $model as map(*), $explicit-field as xs:string*) {
    q:fieldinputTemplate('Explicit (as recorded in the catalogue record)', 'explicit')
};

declare function q:fieldInputAdditions($node as node(), $model as map(*), $additions-field as xs:string*) {
    q:fieldinputTemplate('Additions', 'additions')
};

declare function q:fieldInputTitle($node as node(), $model as map(*), $titleStmt-field as xs:string*) {
    q:fieldinputTemplate('Titles', 'titleStmt')
};

declare function q:fieldInputPlace($node as node(), $model as map(*), $place-field as xs:string*) {
    q:fieldinputTemplate('Place', 'place')
};

declare function q:fieldInputPerson($node as node(), $model as map(*), $person-field as xs:string*) {
    q:fieldinputTemplate('Person / Group', 'person')
};



declare
%templates:wrap
%templates:default('start', 1)
%templates:default("per-page", 40)
function q:results($node as node()*, $model as map(*), $start as xs:integer, $per-page as xs:integer) {
    (:   produces a table of results. the header of the table is a row as the results. 
first here is the header of the results table:)
    q:resultsTableHeader($model),
    (:    here are the rows of the table:)
    for $hit at $p in subsequence($model('hits'), $start, $per-page)
    return
        if ($model('type') = 'text' 
        or $model('type') = 'fields') then
            (
            q:resultswithmatch($hit, $p)
            )
        else
            if ($model('type') = 'sparql') then
                q:sparqlRes($hit, $p)
            else
                if ($model('type') = 'xpath' 
                or $model('type') = 'clavis' 
                or $model('type') = 'otherclavis') then
                    q:resultswithoutmatch($hit, $p)
                else
                    ()
};

declare function q:resultsTableHeader($model) {
    if ($model('type') = 'sparql') then
        () (:the sparql results are passed to an XSLT which produces the header as well:)
    else
        if ($model('type') = 'clavis' 
        or $model('type') = 'xpath'
        or $model('type') = 'otherclavis') 
        then
            (:    only return the status title and no KWIC sections  :)
            <div
                class="w3-row w3-border-bottom w3-margin-bottom w3-gray">
                <div
                    class="w3-third">
                    <div
                        class="w3-col"
                        style="width:10%">
                        <span
                            class="number">status</span>
                    </div>
                    <div
                        class="w3-col"
                        style="width:85%">
                        title
                    </div>
                </div>
                <div
                    class="w3-twothird">item-type specific options
                </div>
            </div>
        
        else
            (:     results table header for results with KWIC matches:)
            <div
                class="w3-row w3-border-bottom w3-margin-bottom w3-gray">
                <div
                    class="w3-third">
                    <div
                        class="w3-col"
                        style="width:10%">
                        <span
                            class="number">status</span>
                    </div>
                    <div
                        class="w3-col"
                        style="width:70%">
                        title
                    </div>
                    <div
                        class="w3-col"
                        style="width:20%">
                        hits count
                    </div>
                </div>
                <div
                    class="w3-twothird">
                    <div
                        class="w3-twothird">first three keywords in context</div>
                    <div
                        class="w3-third">item-type specific options</div>
                </div>
            </div>
};

declare
%templates:wrap
function q:sparqlRes($hit, $p) {
    transform:transform($hit, 'xmldb:exist:///db/apps/BetMas/rdfxslt/sparqltable.xsl', ())

};

declare function q:matchescount($text){
let $expanded := kwic:expand($text) return count($expanded//exist:match)
};
(:~
: if the smart sort function is selected then an enriched score will be used to 
: sort the results which multiplies the values or adds to them according to set rules
:)
declare function q:enrichScore($text) {
    let $queryText := request:get-parameter('query', ())
    let $expanded := kwic:expand($text)
    let $score as xs:float := ft:score($text)
    let $tokvalues := for $tokenInQuery in tokenize($queryText, '\s')
    return
        if ($text[contains(., $tokenInQuery)]) then
            5
        else
            0
    let $values := sum($tokvalues)
    let $matches := for $m in $expanded//exist:match
    return
        $m
    let $countelnames := count($matches/parent::t:persName)
    let $countelplace := count($matches/parent::t:placeName)
    let $counttext := count($matches/ancestor::t:div)
    let $countelmsItem := count($matches/(ancestor::t:msItem|ancestor::t:msPart|ancestor::t:msDesc))
(:    doubles the full bill it the item type matches the most commonly used element for references to that entity. persName in person, placeName in place, etc.:)
    let $elementtypematch := 
                        if (((($countelnames gt $countelplace) 
                            and ($countelnames gt $counttext) 
                            and ($countelnames gt $countelmsItem)) 
                            and string($text/ancestor-or-self::t:TEI/@type) ='pers')
                            or
                            ((($countelmsItem gt $countelplace) 
                            and ($countelmsItem gt $counttext) 
                            and ($countelmsItem gt $countelnames)) 
                            and string($text/ancestor-or-self::t:TEI/@type) ='mss')
                            ) then 2 else 1
    let $scores := for $match in $matches
    return
        if ($match/parent::t:idno)
        then
            $score * 5
        else
            if ($match/parent::t:title[parent::t:titleStmt])
            then
                $score * 5
                else if ($match/parent::t:*[self::t:persName or self::t:placeName])
            then
                $score * 4
            else
                $score
(:                the following two depend on the previous, so that they are incentives, and do not risk to overtake the previous measure:)
   let $relations := if($elementtypematch=2) then count($text//t:relation) else 0
   let $numberofnodes := if($relations gt 0) then (count($text//node()) div 100) else 0
   let $occupationChange := 
    
    if ($text//t:ab[node()]) then
        4
    else
        if ($text//t:occupation) then
            2
        else
            if ($text/ancestor::t:TEI//t:change[contains(., 'complete')]) then
                1
            else
                0
    let $enrichedScore :=
    $score +
    $values +
    $numberofnodes +
    $occupationChange + $relations +
    (sum($scores) * $elementtypematch)
    return
        format-number($enrichedScore, '0000')
        
};


(:outputs for a subsequence of results the rows of a table of results including KWIC for text and field searches:)
declare function q:resultswithmatch($text, $p) {
    
    let $queryText := request:get-parameter('query', ())
    
    let $expanded := kwic:expand($text)
    let $firstancestorwithID := ($expanded//exist:match/(ancestor::t:*[(@xml:id | @n)] | ancestor::t:text))[last()]
    let $firstancestorwithIDid := $firstancestorwithID/string(@xml:id)
    let $view := if ($firstancestorwithID[ancestor-or-self::t:text]) then
        'text'
    else
        'main'
    let $firstancestorwithIDanchor := if ($view = 'main') then
        '#' || $firstancestorwithIDid
    else
        ()
    
    let $count := count($expanded//exist:match)
    let $root := root($text)
    let $item := $root/ancestor-or-self::t:TEI
    let $t := string($text/@type)
    let $id := data($root/t:TEI/@xml:id)
    let $collection := switch2:col($t)
    return
        <div
            class="w3-row w3-border-bottom w3-margin-bottom">
            <div
                class="w3-third">
                <div
                    class="w3-row">
                    <div
                        class="w3-col"
                        style="width:10%">
                        {q:statusBadge($item)}
                    </div>
                    <div
                        class="w3-col"
                        style="width:70%">
                        {q:resultitemlinks($collection, $item, $id, $root, $text)}
                    </div>
                    
                    <div
                        class="w3-col"
                        style="width:20%">
                        <span
                            class="w3-badge">{$count}</span>
                        in {
                            for $match in config:distinct-values($expanded//exist:match/parent::t:*/name())
                            return
                                (<code>{string($match)}</code>, <br/>)
                        }
                    </div>
                </div>
                <div
                    class="w3-row">{q:summary($text)}</div>
            </div>
            <div
                class="w3-twothird">
                <div
                class="w3-twothird">
                {
                    for $match in subsequence($expanded//exist:match, 1, 3)
                    let $matchancestorwithID := ($match/(ancestor::t:*[(@xml:id | @n)] | ancestor::t:text))[last()]
                    let $matchancestorwithIDid := $matchancestorwithID/string(@xml:id)
                    let $view := if ($matchancestorwithID[ancestor-or-self::t:text]) then
                        'text'
                    else
                        'main'
                    let $matchancestorwithIDanchor := if ($view = 'main') then
                        '#' || $matchancestorwithIDid
                    else
                        ()
                    
                    return
                        let $matchref := replace(q:refname($match), '.$', '')
                        let $ref := if ($view = 'text' and $matchref != '') then
                            '&amp;ref=' || $matchref
                        else
                            ()
                        return
                            <div
                                class="w3-row w3-padding"><div
                                    class="w3-twothird w3-padding match">
                                    {
                                        kwic:get-summary($match/parent::node(), $match, <config
                                            width="40"/>)
                                    }
                                </div>
                                <div
                                    class="w3-third w3-padding">
                                    <a
                                        href="/{$collection}/{$id}/{$view}{$matchancestorwithIDanchor}?hi={$queryText}{$ref}">
                                        {
                                            ' in element ' || $match/parent::t:*/name() || ' within a ' ||
                                            $matchancestorwithID/name()
                                            ||
                                            (if ($view = 'text' and $matchref != '')
                                            then
                                                ', at ' || $matchref
                                            else
                                                if ($view = 'main')
                                                then
                                                    ', with id ' || $matchancestorwithIDid
                                                else
                                                    ())
                                        }</a>
                                </div>
                            </div>
                }</div>
                {q:resultslinkstoviews($t, $id, $collection)}
        </div>
            
        </div>
};

(:outputs for a subsequence of results the rows of a table of results without KWIC for clavis and xpath searches:)
declare function q:resultswithoutmatch($text, $p) {
    let $queryText := request:get-parameter('query', ())
    let $root := if ($q:searchType = 'clavis') then    $text('hit')     else   $text
    let $item := if ($q:searchType = 'clavis') then  $text('hit')  else  $root/ancestor-or-self::t:TEI
    let $t := if ($q:searchType = 'clavis' and $text('type') = 'deleted') then   'deleted'  else     $item/@type
    let $id := if ($q:searchType = 'clavis' and $text('type') = 'deleted') then   'deleted'  else    data($item/@xml:id)
    let $collection := if ($q:searchType = 'clavis' and $text('type') = 'deleted') then   'deleted'   else   switch2:col($t)
    return
        <div
            class="w3-row w3-border-bottom w3-margin-bottom">
            <div
                class="w3-row"><
                div
                    class="w3-third">
                    <div
                        class="w3-col"
                        style="width:10%">
                        {
                            if ($q:searchType = 'clavis' and $text('type') = 'deleted') then
                                <span
                                    class="w3-tag w3-black">DELETED</span>
                            else
                                q:statusBadge($item)
                        }
                    </div>
                    <div
                        class="w3-col"
                        style="width:85%">
                        {
                            if ($q:searchType = 'clavis' and $text('type') = 'deleted') then
                                ()
                            else
                                q:resultitemlinks($collection, $item, $id, $root, $text)
                        }
                    </div>
               <div
                    class="w3-row">{q:summary($item)}</div>
          
               </div>
            <div
                class="w3-twothird">
                <div
                    class="w3-container">
                    {
                        if ($q:searchType = 'clavis' and $text('type') = 'deleted') then
                            <a
                                href="/deleted.html">to see when {$text('hit')/text()} was deleted and why, click here for the list of deleted files</a>
                        else
                            q:resultslinkstoviews($t, $id, $collection)
                    }</div>
            </div>
        </div>
                  </div>
};

(: adds a summary to the result of the search
https://github.com/BetaMasaheft/Documentation/issues/1595 

for persons

dates, description, names, occupation
for works

abstract, author, dates
for manuscripts

date, general title, number of leaves, number of quires

but there is already the format of the information given in the current list views to be merged with this to be generic enough.

:)
declare function q:summary($item) {
    let $id := $item/@xml:id
    let $dates := ($item//t:date[not(parent::t:publicationStmt)][not(parent::t:bibl)], $item//t:origDate, $item//t:birth, $item//t:floruit, $item//t:death)
    return
        <div
            class="w3-card-4 w3-margin w3-padding"
            style="height:200px;resize: both;overflow:auto">
            
            {
                switch ($item/@type)
                    case 'work'
                        return
                            q:summaryWork($item, $id)
                   case 'mss'
                        return
                            q:summaryMss($item, $id)
                         case 'nar'
                        return
                            q:summaryWork($item, $id)
                     case 'auth'
                        return
                            q:summaryWork($item, $id)
                     case 'pers'
                        return
                            q:summaryPers($item, $id)
                    case 'place'
                        return
                            q:summaryPlace($item, $id)
                   case 'ins'
                        return
                            (q:summaryIns($item, $id), q:summaryPlace($item, $id))
                    default return
                        ()
        }</div>
};


declare function q:summaryPers($item, $id) {
<div class="w3-container">
        {if(starts-with($item/@xml:id, 'E')) then 'Ethnic ' else ()} {if($item//t:personGrp) then 'Group' else ()}
        {if(//t:person/@sex = 1) then <i class="fa fa-mars"/> else  <i class="fa fa-venus"/>}
        {if($item//t:person/@sameAs) then <a href="{$item//t:person/@sameAs}">
                           <span class="icon-large icon-vcard"/>
                       </a> else ()}
        </div>,
        <div  class="w3-container">
         <h5>Names</h5>
         <ul class="nodot">
         {
         for $n in $item//t:persName[@xml:id]
         let $Nid := $n/@xml:id
         return
         <li>{$n//text()}<sup>{$n/@xml:lang}</sup> 
         {if($item//t:persName[@corresp]) 
         then (let $corrsNs := for $corrN in $item//t:persName[@corresp]
                                                let $corrNcorr := substring-after($corrN/@corresp, '#')
                                                return
                                                 if($corrNcorr = $Nid) then ($corrN//text(),<sup>{$corrN/@xml:lang}</sup>) else ()
                   return ('(', $corrsNs,')') )
         else ()}</li>
         }
         </ul>
         </div>,
         if($item//t:floruit/@* or $item//t:birth/@* or $item//t:death/@*) 
            then <div class="w3-container">
            <h5>Dates</h5>
            <ul class="nodot">
            {for $d in ($item//t:floruit | $item//t:birth |$item//t:death | $item//t:date[ancestor::t:person])
            return <li>{$d/name()}: {try{viewItem:dates($d)} catch * {util:log('info', $err:description)}}</li>}
            </ul>
         </div> else (),
         if($item//t:occupation) 
            then <div class="w3-container">
            <h5>Occupation</h5>
            <ul class="nodot">
            {for $o in ($item//t:occupation)
            return <li>{$o/text()} ({string($o/@type)})</li>}
            </ul>
         </div> else ()
};

declare function q:summaryPlace($item, $id) {
<div
        class="w3-container">
        {if($item//t:place/@sameAs) then let $wd := substring-after($item//t:place/@sameAs, 'wd:')
            return
                    <a
                        href="{('https://www.wikidata.org/wiki/' || $wd)}"
                        target="_blank">{$wd}</a>
           else ()}
                    {
            if ($item//t:geo) then
                <a
                    href="{($id)}.json"
                    target="_blank"><span
                        class="glyphicon glyphicon-map-marker"></span></a>
            else
                ()
        }
        </div>
};

declare function q:summaryIns($item, $id) {
let $fullid :=  ('https://betamasaheft.eu/'||$id)
return
<div class="w3-container">
        There are {count($q:col//t:repository[@ref =$fullid])} items at this repository.
        </div>
};

declare function q:summaryWork($item, $id) {

                let $isVersion := $q:col//t:relation[@name = 'saws:isVersionOf'][contains(@passive, $id)]
                let $anotherlang := $q:col//t:relation[@name = 'saws:isVersionInAnotherLanguageOf'][contains(@passive, $id)]
                  let $creator := $item//t:relation[@name = "dcterms:creator"]
                let $attributed := $item//t:relation[@name = "saws:isAttributedToAuthor"]
             
                return
                (
   if($item//t:titleStmt/t:author or $creator or $attributed) then  <div
        class="w3-container">
        <h5>Author attributions</h5>
        <ul
            class="nodot">
            {
                for $author in $item//t:titleStmt/t:author
                return
                    <li>{$author}</li>
            }
            {
                 let $attributions := for $r in ($creator, $attributed)
                let $rpass := $r/@passive
                return
                    if (contains($rpass, ' ')) then
                        tokenize($rpass, ' ')
                    else
                        $rpass
                for $author in config:distinct-values($attributions)
                let $id := replace($author, 'https://betamasaheft.eu/', '')
                return
                    <li><a
                            href="{$author}">{
                                try {
                                    titles:printTitleID($id)
                                } catch * {
                                    $author//t:titleStmt/t:title[1]/text()
                                }
                            }</a></li>
            }
        
        </ul>
    </div> else (),
    if($item//t:listWit/t:witness or $isVersion or $anotherlang) then
    <div
        class="w3-container">
        <h5>Witnesses</h5>
        <ul
            class="nodot">
            {
                for $witness in $item//t:listWit/t:witness
                let $corr := $witness/@corresp
                let $id := replace($corr, 'https://betamasaheft.eu/', '')
                return
                    <li><a
                            href="{$corr}">{titles:printTitleID($id)}</a></li>
            }
        </ul>
        <ul
            class="nodot">
            {
                for $parallel in ($isVersion, $anotherlang)
                let $p := $parallel/@active
                let $id := replace($parallel, 'https://betamasaheft.eu/', '')
                return
                    <li><a
                            href="{$p}">{titles:printTitleID($id)}</a></li>
            }
        </ul>
    </div> else (),
    if($item//t:abstract) then <div
        class="w3-container">
        <h5>Abstract</h5>
        {string-join($item//t:abstract//text()[not(ancestor::t:bibl)], ' ')}
    </div> else ()
    )
};

declare function q:summaryMss($item, $id) {
    <div
        class="w3-container">
        <h5>Signatures</h5>
        {
            let $idnos := for $shelfmark in $item//t:msIdentifier//t:idno
            return
                $shelfmark/text()
            return
                string-join($idnos, ', ')
        }
    </div>,
    <div
        class="w3-container">
        <h5>Short Description</h5>
        This {lower-case(($item//t:material/@key)[1])}
        {lower-case(($item//t:objectDesc/@form)[1])}
        is composed of {$item//t:extent/t:measure[@unit = 'leaf'][not(@type = 'blank')]} leaves.
        It has {count($item//t:msItem[not(t:msItem)])
        } main content units in {
            if (count($item//t:msPart) = 0) then
                1
            else
                count($item//t:msPart)
        } codicological unit{
            if (count($item//t:msPart) gt 1) then
                's'
            else
                ''
        }.
        {
            if ($item//t:origDate or $item//t:date[@evidence eq 'internal-date'])
            then
                'Available dates of origin in the description: '
                || (
                let $orig := $item//t:origDate
                let $internal := $item//t:date[@evidence eq 'internal-date']
                let $alldates := ($orig, $internal)
               let $formatdates := for $d in $alldates
                 return
                    try{viewItem:dates($d)} catch * {util:log('info', $err:description)}
                    return string-join($formatdates, ' '))
                            || '. '
            else
                ()
        }
       {if($item//t:handNote) then 'There are ' || count($item//t:handNote) ||
        ' described hands using ' || string-join(config:distinct-values(data($item//@script)), ', ') || ' script. ' else () }
        The description {
            if ($item//t:collation[descendant::t:item]) then
                ' includes a collation of the quires.'
            else
                ' does not include a collation of the quires.'
        }</div>
};

declare function q:dates($d){
if ($d/text())
                    then
                        string-join($d//text(), ' ')
                    else
                        let $atts := for $att in $d/@* return  ($att/name() || ' ' || $att/data())
                        return
                            string-join($atts, ' ')};


(:the following three functions are shared by results with and without matches:)
declare function q:statusBadge($item) {
    <span
        class="w3-tag w3-red">{
            if ($item//t:change[contains(., 'complete')]) then
                (attribute style {'background-color:rgb(172, 169, 166, 0.4)'},
                'complete')
            else
                if ($item//t:change[contains(., 'review')]) then
                    (attribute style {'background-color:white'},
                    'reviewed')
                else
                    (attribute style {'background-color:rgb(213, 75, 10, 0.4)'},
                    'stub')
        }
    </span>
};

declare function q:resultitemlinks($collection, $item, $id, $root, $text) {
    <span
        class="w3-tag w3-gray">{$collection}</span>,
    <span
        class="w3-tag w3-gray"
        style="word-break: break-all; text-align: left;">{$id}</span>,
    <span
        class="w3-tag w3-red"><a
            href="{('/tei/' || $id || '.xml')}"
            target="_blank">TEI</a></span>,
    <span
        class="w3-tag w3-red"><a
            href="/{$id}.pdf"
            target="_blank">PDF</a></span>,
    <br/>,
    <a
        target="_blank"
        href="/{$collection}/{$id}/main"><b>{
                if (starts-with($id, 'corpus')) then
                    $root//t:titleStmt/t:title[1]/text()
                else
                    try {
                        titles:printTitleID($id)
                    } catch * {
                        console:log(($text, $id, $err:description))
                    }
            }</b></a>,
    <br/>
    ,
    if ($item//t:facsimile/t:graphic/@url)
    then
        <a
            target="_blank"
            href="{$item//t:facsimile/t:graphic/@url}">Link to images</a>
    else
        if ($item//t:msIdentifier/t:idno[@facs][@n]) then
            <a
                target="_blank"
                href="/manuscripts/{$id}/viewer">{
                    if ($item//t:collection = 'Ethio-SPaRe')
                    then
                        <img
                            src="{$config:appUrl || '/iiif/' || string(($item//t:msIdentifier)[1]/t:idno/@facs) || '_001.tif/full/140,/0/default.jpg'}"
                            class="thumb w3-image"/>
                        (:laurenziana:)
                    else
                        if ($item//t:repository[@ref eq 'INS0339BML'])
                        then
                            <img
                                src="{$config:appUrl || '/iiif/' || string($item//t:msIdentifier/t:idno/@facs) || '005.tif/full/140,/0/default.jpg'}"
                                class="thumb w3-image"/>
                            
                            (:          
EMIP:)
                        else
                            if (($item//t:collection = 'EMIP') and $item//t:msIdentifier/t:idno/@n)
                            then
                                <img
                                    src="{$config:appUrl || '/iiif/' || string(($item//t:msIdentifier)[1]/t:idno/@facs) || '001.tif/full/140,/0/default.jpg'}"
                                    class="thumb w3-image"/>
                                
                                (:BNF:)
                            else
                                if ($item//t:repository/@ref eq 'INS0303BNF')
                                then
                                    <img
                                        src="{replace($item//t:msIdentifier/t:idno/@facs, 'ark:', 'iiif/ark:') || '/f1/full/140,/0/native.jpg'}"
                                        class="thumb w3-image"/>
                                    (:           vatican :)
                                else
                                    if (contains($item//t:msIdentifier/t:idno/@facs, 'digi.vat')) then
                                        <img
                                            src="{
                                                    replace(substring-before($item//t:msIdentifier/t:idno/@facs, '/manifest.json'), 'iiif', 'pub/digit') || '/thumb/'
                                                    ||
                                                    substring-before(substring-after($item//t:msIdentifier/t:idno/@facs, 'MSS_'), '/manifest.json') ||
                                                    '_0001.tif.jpg'
                                                }"
                                            class="thumb w3-image"/>
                                        (:                bodleian:)
                                    else
                                        if (contains($item//t:msIdentifier/t:idno/@facs, 'bodleian')) then
                                            ('images')
                                        else
                                            (<img
                                                src="{$config:appUrl || '/iiif/' || string(($item//t:msIdentifier/t:idno)[1]/@facs) || '_001.tif/full/140,/0/default.jpg'}"
                                                class="thumb w3-image"/>)
                }</a>
        
        else
            ()
    
    ,
    if ($collection = 'works' and (contains($q:searchType, 'clavis'))) then
    
        apptable:clavisIds($item)
    else     if ($collection = 'works' and (not(contains($q:searchType, 'clavis')))) then
        apptable:clavisIds($text)
    else
        ()
    
    
};

declare function q:resultslinkstoviews($t, $id, $collection) {
    <div
        class="w3-third">
        {
            switch ($t)
                case 'mss'
                    return
                        (
                        <a
                            role="button"
                            class="w3-button w3-small w3-gray"
                            href="/IndexPlaces?entity={$id}">places</a>,
                        <a
                            role="button"
                            class="w3-button w3-small w3-gray"
                            href="/IndexPersons?entity={$id}">persons</a>)
                case 'pers'
                    return
                        ()
                case 'ins'
                    return
                        (<a
                            role="button"
                            class="w3-button w3-small w3-gray"
                            href="/manuscripts/{$id}/list">manuscripts</a>)
                case 'place'
                    return
                        (<a
                            role="button"
                            class="w3-button w3-small w3-gray"
                            href="/manuscripts/place/list?place={$id}">manuscripts</a>)
                case 'nar'
                    return
                        (<a
                            role="button"
                            class="w3-button w3-small w3-gray"
                            href="/collate">collate</a>)
                case 'work'
                    return
                        (<a
                            role="button"
                            class="w3-button w3-small w3-gray"
                            href="/compare?workid={$id}">compare</a>,
                        <a
                            role="button"
                            class="w3-button w3-small w3-gray"
                            href="/workmap?worksid={$id}">map of mss</a>,
                        <a
                            role="button"
                            class="w3-button w3-small w3-gray"
                            href="/collate">collate</a>,
                        <a
                            role="button"
                            class="w3-button w3-small w3-gray"
                            href="/IndexPlaces?entity={$id}">places</a>,
                        <a
                            role="button"
                            class="w3-button w3-small w3-gray"
                            href="/IndexPersons?entity={$id}">persons</a>)
                default return
                    <a
                        role="button"
                        class="w3-button w3-small w3-gray"
                        href="/authority-files/list?keyword={$id}">with this keyword</a>
    }
    <a
        role="button"
        class="w3-button w3-small w3-gray"
        href="/{$collection}/{$id}/analytic">relations</a>
        <div class="w3-card w3-margin w3-padding" style="height:200px;resize: both;overflow:auto">
        
         {
         let $item := $q:col/id($id)[name() = 'TEI']
         let $log := if(count($item) gt 1) then for $i in $item return util:log('INFO', base-uri($i)) else ()
         return
         switch ($t)
                case 'pers'
                    return item2:RestPersRole($item, $collection)
                    case 'work'
                    return (<h4>List of computed witnesses</h4>,item2:witList($item))
                    case 'mss'
                    return (<h4>List of related persons</h4>, item2:persList($item))
                default return ()    
                    }
        </div>
</div>
};

(:~  copied from  dts: to format and select the references :)
declare function q:refname($n) {
    (:has to recurs each level of ancestor of the node which 
   has a valid position in the text structure:)
    let $refname := if ($n[name() = 'ab'] or $n[name() = 'match']) then
        ()
    else
        q:rn($n)
    let $this := normalize-space($refname)
    let $ancestors := for $a in $n/ancestor::t:div[@xml:id or @n or @corresp][ancestor::t:div[@type]]
    return
        q:rn($a)
    let $all := ($ancestors, $this)
    return
        string-join($all, '.')
};

(:~  copied and adapted from dts and called by q:refname to format 
a single reference starting from a match :)
declare function q:rn($n) {
    if ($n[name() = 'exist:match']) then
        ()
    else
        if ($n/preceding-sibling::t:cb) then
            (string($n/preceding-sibling::t:pb[@n][1]/@n) || string($n/preceding-sibling::t:cb[@n][1]/@n))
        else
            if ($n/name() = 'pb' and $n/@corresp) then
                (string($n/@n) || '[' || substring-after($n/@corresp, '#') || ']')
            else
                if ($n/@n) then
                    string($n/@n)
                else
                    if ($n/@xml:id) then
                        string($n/@xml:id)
                    else
                        if ($n/@subtype) then
                            string($n/@subtype)
                        else
                            'tei:' || $n/name() || '[' || $n/position() || ']'
};

declare function q:queryinput($node as node(), $model as map(*), $query as xs:string*) {
    <textarea
        id="sparql"
        style="height:200px"
        name="query"
        type="search"
        class="w3-input diacritics">
        {$query}
    
    </textarea>
};

declare function q:elements($node as node(), $model as map(*)) {
    let $control :=
        <select xmlns="http://www.w3.org/1999/xhtml" multiple="multiple" id="element" name="element" class="w3-select">
            
            <option value="title">Titles</option>
            <option value="persName">Person names</option>
            <option value="placeName">Place names</option>
            <option value="ref">References</option>
            <option value="ab">Texts</option>
            <option value="l">Lines</option>
            <option value="p">Paragraphs</option>
            <option value="note">Notes</option>
            <option value="incipit">Incipits</option>
            <option value="explicit">Explicits</option>
            <option value="colophon">Colophons</option>
            <option value="q">Quotes</option>
            <option value="occupation">Occupation</option>
            <option value="roleName">Role</option>
            <option value="summary">Summaries</option>
            <option value="abstract">Abstracts</option>
            <option value="desc">Descriptions</option>
            <option value="relation">Relations</option>
            <option value="foliation">Foliation</option>
            <option value="origDate">Origin Dates</option>
            <option value="measure">Measures</option>
            <option value="floruit">Floruit</option>
        </select>
    return
        templates:form-control($control, $model)
};

(:switch mapping the name of a filter to the correct range index name:)
declare function q:rangeindexname($nodeName){
                                        switch($nodeName) 
                                        case 'relType' return 'relname' 
                                        case 'language' return 'TEIlanguageIdent' 
                                        case 'material' return 'materialkey' 
                                        case 'bmaterial' return 'materialkey'
                                         case 'placetype' return 'placetype' 
                                         case 'country' return 'countryref' 
                                         case 'settlement' return 'settlref' 
                                         case 'occupation' return 'occtype' 
                                         case 'faith' return 'faithtype' 
                                         case 'objectType' return 'form' 
                                         default return 'termkey'
};

declare function q:rangeindexlabel($nodeName){
                                        switch($nodeName) 
                                        case 'TEItermKey' return 'keyword' 
                                        case 'TEIlanguageIdent' return 'language' 
                                        case 'TEIrepo' return 'repository' 
                                        case 'TEIclavistype' return 'clavis type'
                                         case 'TEIclavisID' return 'clavis id' 
                                         case 'TEIorigDateW' return 'origin date (when)' 
                                         case 'TEIorigDateNB' return 'origin date (notBefore)' 
                                         case 'TEIorigDateNA' return 'origin date (notAfter)' 
                                         case 'TEIDateW' return 'date (when)' 
                                         case 'TEIDateNB' return 'date (notBefore)' 
                                         case 'TEIDateNA' return 'date (notAfter)' 
                                         case 'TEIplNametx' return 'place reference' 
                                         case 'TEIprNametx' return 'person reference' 
                                         case 'TEIscript' return 'script' 
                                         case 'TEIsupport' return 'form' 
                                         case 'TEIdecoMat' return 'binding material'
                                         case 'TEIpersOcc' return 'occupation type' 
                                         case 'TEIreltx' return 'relation name' 
                                         case 'TEIreltxA' return 'relation target (active)'
                                         case 'TEIreltxP' return 'relation target (passive)' 
                                         case 'TEItitle' return 'title reference' 
                                         case 'TEIwitt' return 'witness'
                                         case 'TEIsex' return 'gender'
                                         case 'TEImeasure' return 'measure'
                                         case 'TEIwrittenLines' return 'written lines'
                                         case 'TEIquireDim' return 'quire dimension'
                                         case 'materialkey' return 'material'
                                         case 'itemtype' return 'addition'
                                         case 'persrole' return 'person role'
                                         case 'custEventsubtype' return 'restoration'
                                         case 'repositorytext' return 'repository'
                                         case 'titletext' return 'title'
                                         case 'witnesstext' return 'witness'
                                         default return 'unknown'
};

declare function q:rangeindexlookup ($rangeindexname){
$q:col/$q:range-lookup3($rangeindexname, function($key, $count) 
                {q:sortedoptions($rangeindexname, $key, $count)}, 
                1000)
(:                this tries to take all, keeping the total number of keys high:)
};

declare function q:sortedoptions($rangeindexname, $key, $count){
let $options := for $option in q:formatOption($rangeindexname, $key, $count) 
                           return
                              if(starts-with($key,'https://betamasaheft.eu/') and contains($key, '#')) 
                              then
                                       try{ let $id := replace($key,'https://betamasaheft.eu/', '') 
                                        let $subid := substring-after($key, '#')
                                          let $mainid := substring-before($key, '#')
                                          group by $MAIN := $mainid
                                         return   
                                         <optgroup label="{$MAIN/text()}">{for $o in $option return $o}</optgroup>} catch * {$err:description}
                  else 
                  let $sorting := q:sortingkey($option)
                                            order by $sorting
                                            return $option 
return $options};

declare function q:formatOption($rangeindexname,$key, $count){
if($rangeindexname='TEIlanguageIdent')
then <option value="{$key}">{$q:languages//id($key)/text()} ({$count[2]})</option>

else if(starts-with($key,'https://betamasaheft.eu/'))
         then 
                  let $id := replace($key,'https://betamasaheft.eu/', '') 
                  let $title := ($q:lists//t:item[@xml:id=$id] | $q:lists//t:item[@corresp=$id])/text() 
                  let $titlesel := if ($title) then $title else try{titles:printTitleID($id)} catch * {util:log('INFO',$err:description)}
                  return <option value="{$key}">{$titlesel} ({$count[2]})</option>
else if(starts-with($key,'#'))
         then 
                  let $id := replace($key,'#', '') 
                  let $title := $q:lists//t:item[@xml:id=$id]/text() 
                  return <option value="{$key}">{$title} ({$count[2]})</option>
else  if ($rangeindexname = 'TEItermKey') then 
            let $cat := $q:tax//t:category[@xml:id=$key] 
            return
                     <option value="{$key}">{$cat/t:catDesc/text()}</option>
else if ($rangeindexname ='TEIsex') then <option value="{$key}">{switch($key) case '1' return 'Male' default return 'Female'} ({$count[2]})</option>
else 
<option value="{$key}">{$key} ({$count[2]})</option>
};


declare function q:generalRangeIndexesFilters($node as node(), $model as map(*)) {
let $indexnames:=('TEIlanguageIdent', 'TEItermKey')
return q:datalist($indexnames)
};

declare function q:MssRangeIndexesFilters($node as node(), $model as map(*)) {
let $indexnames:=('TEIscript', 'TEIsupport', 'materialkey', 'TEIdecoMat', 'custEventsubtype')
return q:datalist($indexnames)
};

declare function q:target-ins($node as node(), $model as map(*)){
q:datalist('repositorytext')
};


declare function q:roles($node as node(), $model as map(*)){
q:datalist('persrole')
};

declare function q:contents($node as node(), $model as map(*)){
let $indexes := ('titletext', 'itemtype') return
q:datalist($indexes)
};

declare function q:datalist ($indexnames){
let $indexesSelection := $q:TEIrangeFields[.=$indexnames]
for $rangeindexname in $indexesSelection
let $nodeName := q:rangeindexlabel($rangeindexname)
let $lookup :=  q:rangeindexlookup($rangeindexname)
   return 
   <div class="w3-container">
                    <label for="{$nodeName}">{$nodeName}s <span class="w3-badge">{count($lookup)}</span></label>
                 <input
                    list="{$nodeName}-list"
                    class="w3-input"
                    name="{$nodeName}" id="{$nodeName}" ></input>
                <datalist style="width:100%"
                    id="{$nodeName}-list">
                    {for $option in $lookup return $option}
                </datalist>
      </div>};


(:~determins what the selectors for various form controls will look like, is called by app:formcontrol() :)
declare function q:selectors($nodeName, $nodes, $type){
             <select multiple="multiple" name="{$nodeName}" id="{$nodeName}" class="w3-select">
            {
            
            if ($type = 'keywords') then (
                    for $group in $nodes/t:category[t:desc]
                    let $label := $group/t:desc/text()
                    
                    return
                    for $n in $group//t:catDesc
                    let $id := $n/text()
                    let $title :=titles:printTitleMainID($id)
                    return
                       <option value="{$id}">{$title[1]}</option>
                                )
                                              
            else if ($type = 'name')
                            then (for $n in $nodes[. != ''][. != ' ']
                            let $id := string($n/@xml:id)
                            let $title := titles:printTitleMainID($id)
                            let $sortkey := q:sortingkey($title)
                                               order by $sortkey
                                               return
            
                                                <option value="{$id}" >{$title}</option>
                                          )
            else if ($type = 'rels')
                     then (
                    
                 for $n in $nodes[. != ''][. != ' ']
                          let $title :=  titles:printTitleID($n)  
                          let $sortkey := q:sortingkey($title[1])
                            order by $sortkey
                             return
            
                             <option value="{$n}">{normalize-space(string-join($title))}</option>
                        )
             else if ($type = 'hierels')
             then (
             for $n in $nodes[. != ''][. != ' '][not(starts-with(.,'#'))]
             let $cleanid := if (contains($n, '#')) then (substring-before($n, '#')) else $n
             group by $work := $cleanid
             let $record := $q:col/id($work)
             let $titlework := titles:printTitle($record)
               let $sortkey := q:sortingkey($titlework)
               order by $sortkey
                                  (:  try{
                                        if ($titles:collection-root/id($work)) 
                                        then titles:printTitle($titles:collection-root/id($work)) 
                                        else $work} 
(\:                                        this has to stay because optgroup requires label and this cannot be computed from the javascript as in other places:\)
                                    catch* {
                                        ('while trying to create a list for the filter ' ||$nodeName || ' I got '|| $err:code ||': '||$err:description || ' about ' || $work), 
                                         $work}:)
                                return
                                if (count($n) = 1)
                                then <option value="{$work}">{$titlework}</option>
                                else(
                                      <optgroup label="{$titlework}">
                  
                    { for $subid in $n
                    return
                                        <option value="{$subid}">{
                                          if (contains($subid, '#')) then substring-after($subid, '#') else 'all'
                                         }</option>
                                         }
                             
                             
                                    </optgroup>)
                                    
                                    )
            else if ($type = 'institutions')
                      then (
                             let $institutions := collection($config:data-rootIn)//t:TEI/@xml:id
                                 for $institutionId in $nodes[. eq $institutions]
                            return
            
                            <option value="{$institutionId}">{titles:printTitleMainID($institutionId)}</option>
                        )
            
            else if ($type = 'sex')
                     then (for $n in $nodes[. != ''][. != ' ']
                        let $key := replace(functx:trim($n), '_', ' ')
                         order by $n
                         return
                             <option value="{string($key)}">{switch($key) case '1' return 'Male' default return 'Female'}</option>
                        )
            else(
            (: type is values :)
            for $n in $nodes[. != ''][. != ' ']
                let $thiskey := replace(functx:trim($n), '_', ' ')
                let $title := if($nodeName = 'keyword' or $nodeName = "placetype"or $nodeName = "country"or $nodeName = "settlement") then titles:printTitleID($thiskey) 
                                        else if ($nodeName = 'language') then $q:languages//t:item[@xml:id eq $thiskey]/text()
                                        else $thiskey
               order by $n
               return
            <option value="{$thiskey}">{if($thiskey = 'Printedbook') then 'Printed Book' 
             else $title}</option>
            )
            }
        </select>
};