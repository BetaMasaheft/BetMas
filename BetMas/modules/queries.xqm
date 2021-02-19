xquery version "3.1";

module namespace q = "https://www.betamasaheft.uni-hamburg.de/BetMas/queries";
import module namespace all = "https://www.betamasaheft.uni-hamburg.de/BetMas/all" at "xmldb:exist:///db/apps/BetMas/modules/all.xqm";
import module namespace templates = "http://exist-db.org/xquery/templates";
import module namespace editors = "https://www.betamasaheft.uni-hamburg.de/BetMas/editors" at "xmldb:exist:///db/apps/BetMas/modules/editors.xqm";
import module namespace titles = "https://www.betamasaheft.uni-hamburg.de/BetMas/titles" at "xmldb:exist:///db/apps/BetMas/modules/titles.xqm";
import module namespace console = "http://exist-db.org/xquery/console";
import module namespace functx = "http://www.functx.com";
import module namespace kwic = "http://exist-db.org/xquery/kwic" at "resource:org/exist/xquery/lib/kwic.xql";
import module namespace fusekisparql = 'https://www.betamasaheft.uni-hamburg.de/BetMas/sparqlfuseki' at "xmldb:exist:///db/apps/BetMas/fuseki/fuseki.xqm";
import module namespace switch2 = "https://www.betamasaheft.uni-hamburg.de/BetMas/switch2" at "xmldb:exist:///db/apps/BetMas/modules/switch2.xqm";
import module namespace config = "https://www.betamasaheft.uni-hamburg.de/BetMas/config" at "xmldb:exist:///db/apps/BetMas/modules/config.xqm";
import module namespace apptable = "https://www.betamasaheft.uni-hamburg.de/BetMas/apptable" at "xmldb:exist:///db/apps/BetMas/modules/apptable.xqm";
import module namespace string = "https://www.betamasaheft.uni-hamburg.de/BetMas/string" at "xmldb:exist:///db/apps/BetMas/modules/tei2string.xqm";
declare namespace t = "http://www.tei-c.org/ns/1.0";
declare namespace xconf = "http://exist-db.org/collection-config/1.0";

declare variable $q:deleted := doc('/db/apps/BetMas/lists/deleted.xml');
declare variable $q:collection as xs:string := request:get-parameter('collection', ());
declare variable $q:name as xs:string := request:get-parameter('name', ());
declare variable $q:searchType as xs:string := request:get-parameter('searchType', ());
declare variable $q:mode as xs:string := request:get-parameter('mode', ());
declare variable $q:sort as xs:string := if (request:get-parameter('sort', ())) then
    request:get-parameter('sort', ())
else
    '';
declare variable $q:params := request:get-parameter-names();
declare variable $q:facets := doc("/db/system/config/db/apps/expanded/collection.xconf")//xconf:facet/@dimension;
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
    'default-operator': 'and',
    'phrase-slop': '0',
    'leading-wildcard': 'no',
    'filter-rewrite': 'yes',
    'facets': $q:optionsFacet,
    "fields": $q:optionsFields
};


declare variable $q:languages := doc('/db/apps/BetMas/lists/languages.xml');
declare variable $q:tax := doc('/db/apps/BetMas/lists/canonicaltaxonomy.xml');
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


declare function q:querytype($node as node(), $model as map(*)) {
    <select
        id="SType"
        name="searchType"
        class="w3-select w3-border">
        <option
            value="text"
            selected="selected">text search (select here another type of search)</option>
        <option
            value="clavis">Clavis Aethiopica Number</option>
            <option
            value="otherclavis">Other Clavis ID</option>
        <option
            value="fields">fields</option>
        <option
            value="xpath">xpath</option>
        <option
            value="list">list</option>
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
            value="sparql">sparql</option>
    </select>
};

declare function q:textquerymode($node as node(), $model as map(*)) {
    <select
        name="mode"
        class="w3-select"
        style="padding:0px 0px;">
        <option
            value="none"
            selected="selected">default</option>
        <option
            value="any">any</option>
        <option
            value="all">all</option>
        <option
            value="phrase">phrase</option>
        <option
            value="regex">regex</option>
        <option
            value="wildcard">wildcard</option>
        <option
            value="fuzzy">fuzzy</option>
        <option
            value="near-ordered">near-ordered</option>
        <option
            value="near-unordered">near-unordered</option>
    </select>
};



(:the most generic ft:query call returning a map with the  query, the results, the timing and the type of query:)
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


(:This function takes the query string and the parameters and redirects to the correct query type and result format passing on filtering parameters
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
        case 'resources'
            return
                'resources'
                (:                default is a search for the empty string, returning all data...:)
        default return
           for $r in $q:col//t:TEI[ft:query(., (), $q:allopts)] group by $TEI := $r return $TEI
};


(:from the results of a q:query displays in the header of the search result the time of the query (not of loading the HTML... or response from the server...) :)
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


declare function q:otherclavis($q){
let $clavisType := request:get-parameter('clavistype', ())
let $selector :=  if(($q = '') and (matches($clavisType, '\w+'))) 
                           then "[descendant::t:bibl[@type eq '"||$clavisType||"']]"
                           else  "[descendant::t:bibl[@type eq '"||$clavisType||"'][t:citedRange eq '"||$q||"']]"
 let $path := '$q:col//t:TEI[@type="work"]' || $selector
let $test := util:log('INFO', $path)
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
    let $deletedClavis := for $d in doc('/db/apps/BetMas/lists/deleted.xml')//t:item[contains(., $q)]
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
    let $m := if ($q:mode != '') then    $q:mode  else   'none'
    let $q := q:querystring($q, $q:mode)
    let $query :=  $q:col//t:TEI[ft:query(., $q, $q:allopts)]
    return
        if ($q:sort = '')
        then
            for $r in $query
            group by $TEI := $r
            return
                $TEI
        else
            for $r in $query
            group by $TEI := $r
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

declare function q:querystring($query-string, $mode as xs:string*) {
    if ($q:searchType = 'fields') then
        q:create-field-query($query-string, $mode)
    else
        let $homophones := if (string-length($query-string) le 10) then
            'true'
        else
            'false'
        let $subs := q:subst($query-string, $homophones)
        return
            if ($mode = 'none') then
                $subs
            else
                q:create-query($subs, $mode)

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
(:    let $log := util:log('INFO', $query):)
    return
        $query
};

declare function q:subst($query, $homophones) {
    
    if ($query != '')
    then
        (if ($homophones = 'true')
        then
            if (contains($query, 'AND')) then
                (let $parts := for $qpart in tokenize($query, 'AND')
                return
                    all:substitutionsInQuery($qpart)
                return
                    '(' || string-join($parts, ') AND (')) || ')'
            else
                if (contains($query, 'OR')) then
                    (let $parts := for $qpart in tokenize($query, 'OR')
                    return
                        all:substitutionsInQuery($qpart)
                    return
                        '(' || string-join($parts, ') OR (')) || ')'
                else
                    all:substitutionsInQuery($query)
        else
            $query)
    else
        ()
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
        default return
            'Item type'
};

(:~
    Helper function: create a lucene query from the user input
:)
declare function q:create-query($query-string as xs:string?, $mode as xs:string) {
    let $query-string :=
    if ($query-string)
    then
        q:sanitize-lucene-query($query-string)
    else
        ''
        (:        strip out full stop if in the query :)
    let $query-string := replace(normalize-space($query-string), '\.', '')
    
    let $query :=
    
    (:    this filters queries to fields so that they are not passed as xml fragment:)
    if ($mode = 'none' or contains($query-string, ':')) then
        $query-string
        (:If the query contains any operator used in standard lucene searches or regex searches, pass it on to the query parser;:)
    else
        if (functx:contains-any-of($query-string, ('AND', 'OR', 'NOT', '+', '-', '!', '~', '^', '.', '?', '*', '|', '{', '[', '(', '<', '@', '#', '&amp;')) and $mode eq 'any')
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
            class="w3-input w3-col w3-border"
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
(:util:log('INFO', $model),:)
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

(:if the smart sort function is selected then an enriched score will be used to sort the results which multiplies the values or adds to them according to set rules:)
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
    let $scores := for $match in $matches
    return
        if ($match/parent::t:idno)
        then
            $score * 5
        else
            if ($match/parent::t:*[self::t:persName or self::t:placeName])
            then
                $score * 4
            else
                $score
    let $occupationChange := if ($text//t:ab[node()]) then
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
    (count($text//node()) div 100) +
    $occupationChange +
    sum($scores)
    return
        format-number($enrichedScore, '#.00')
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
    let $test1 := util:log('INFO', $text)
    let $queryText := request:get-parameter('query', ())
    let $root := if ($q:searchType = 'clavis') then    $text('hit')     else   $text
    let $item := if ($q:searchType = 'clavis') then  $text('hit')  else  $root/ancestor-or-self::t:TEI
    let $t := if ($q:searchType = 'clavis' and $text('type') = 'deleted') then   'deleted'  else     $item/@type
    let $id := if ($q:searchType = 'clavis' and $text('type') = 'deleted') then   'deleted'  else    data($item/@xml:id)
    let $collection := if ($q:searchType = 'clavis' and $text('type') = 'deleted') then   'deleted'   else   switch2:col($t)
    let $test := util:log('INFO', $item)
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
            <div
                class="w3-container">
                <h5>Titles</h5>
                <ul
                    class="nodot">
                    {
                        for $title in $item//t:titleStmt/t:title
                        return
                            <li>{$title/text()}
                                {
                                    if ($title/@xml:lang) then
                                        (' (' || string($title/@xml:lang) || ')')
                                    else
                                        ()
                                }</li>
                    }
                </ul>
            </div>
            {
                if (count($dates) = 0) then
                    ()
                else
                    <div
                        class="w3-container">
                        <h5>Dates</h5>
                        <ul
                            class="nodot">
                            {
                                for $date in ()
                                return
                                    <li>{$date/parent::node()//text()}</li>
                            }
                        </ul>
                    </div>
            }
            {
                switch ($item/@type)
                    case 'work'
                        return
                            q:summaryWork($item, $id)
                   case 'mss'
                        return
                            q:summaryMss($item, $id)
                         case 'narr'
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
        {if($item//t:personGrp) then 'Group' else ()}
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
            {for $d in ($item//t:floruit/@* | $item//t:birth/@* |$item//t:death/@*)
            return <li>{q:dates($d)}</li>}
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
                    q:dates($d)
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
                case 'narr'
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
        class="w3-input  w3-border diacritics">
        {$query}
    
    </textarea>
};
