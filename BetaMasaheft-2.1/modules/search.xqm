xquery version "3.0" encoding "UTF-8";

module namespace search="https://www.betamasaheft.uni-hamburg.de/BetMas/search";

import module namespace config="https://www.betamasaheft.uni-hamburg.de/BetMas/config" at "config.xqm";

import module namespace app="https://www.betamasaheft.uni-hamburg.de/BetMas/app" at "app.xqm";

import module namespace templates="http://exist-db.org/xquery/templates" ;

import module namespace kwic = "http://exist-db.org/xquery/kwic"
    at "resource:org/exist/xquery/lib/kwic.xql";

declare namespace functx = "http://www.functx.com";

declare namespace t="http://www.tei-c.org/ns/1.0";
declare namespace request="http://exist-db.org/xquery/request";
declare namespace util="http://exist-db.org/xquery/util";

declare function functx:value-intersect  ( $arg1 as xs:anyAtomicType* ,    $arg2 as xs:anyAtomicType* )  as xs:anyAtomicType* {

  distinct-values($arg1[.=$arg2])
 } ;

declare function functx:trim( $arg as xs:string? )  as xs:string {

   replace(replace($arg,'\s+$',''),'^\s+','')
 } ;

declare function functx:contains-any-of( $arg as xs:string? ,$searchStrings as xs:string* )  as xs:boolean {

   some $searchString in $searchStrings
   satisfies contains($arg,$searchString)
 } ;

(:modified by applying functx:escape-for-regex() :)
declare function functx:number-of-matches ( $arg as xs:string? ,$pattern as xs:string )  as xs:integer {
       
   count(tokenize(functx:escape-for-regex(functx:escape-for-regex($arg)),functx:escape-for-regex($pattern))) - 1
 } ;

declare function functx:escape-for-regex( $arg as xs:string? )  as xs:string {

   replace($arg,
           '(\.|\[|\]|\\|\||\-|\^|\$|\?|\*|\+|\{|\}|\(|\))','\\$1')
 } ;




(:ADVANCED SEARCH FUNCTIONS:)

declare function search:work-types($node as node(), $model as map(*)) {
    let $control :=
        <select multiple="multiple" name="work-types" class="form-control">
            <option value="all">All Work Types (includes authority files and narrative units)</option>
            <option value="mss">Manuscripts</option>
            <option value="place">Places</option>
            <option value="ins">Institutions</option>
            <option value="nar">Narrative Units</option>
            <option value="work">Text Units (Works)</option>
            <option value="pers">Persons</option>
        </select>
    return
        templates:form-control($control, $model)
};


declare function search:target-mss($node as node(), $model as map(*)) {
    let $control :=
        <datalist xmlns="http://www.w3.org/1999/xhtml"  multiple="multiple" id="manuscripts" class="hidden">
            {for $MSid in collection($config:data-rootMS)//t:TEI
            return
            <option value="{$MSid/@xml:id}">{app:printTitle($MSid)}</option>
            }
        </datalist>
    return
        templates:form-control($control, $model)
};

declare function search:target-texts($node as node(), $model as map(*)) {
    let $control :=
        <datalist xmlns="http://www.w3.org/1999/xhtml"  multiple="multiple" id="works" class="hidden">
            {for $MSid in collection($config:data-rootW, $config:data-rootN)//t:TEI
            return
            <option value="{$MSid/@xml:id}">{app:printTitle($MSid)}</option>
            }
        </datalist> 
    return
        templates:form-control($control, $model)
};

declare function search:target-pers($node as node(), $model as map(*)) {
    let $control :=
        <datalist xmlns="http://www.w3.org/1999/xhtml"  multiple="multiple" id="persons" class="hidden">
        
            {for $MSid in collection($config:data-rootPr)//t:TEI
            return
            <option value="{$MSid/@xml:id}">{app:printTitle($MSid)}</option>
            }
        </datalist>
    return
        templates:form-control($control, $model)
};

declare function search:target-place($node as node(), $model as map(*)) {
    let $control :=
        <datalist xmlns="http://www.w3.org/1999/xhtml"  multiple="multiple" id="places" class="hidden">
            {for $MSid in collection($config:data-rootPl)//t:TEI
            return
            <option value="{$MSid/@xml:id}">{app:printTitle($MSid)}</option>
            }
        </datalist>
    return
        templates:form-control($control, $model)
};

declare function search:target-auth($node as node(), $model as map(*)) {
    let $control :=
        <datalist xmlns="http://www.w3.org/1999/xhtml"  multiple="multiple" id="authority-files" class="hidden">
            {for $MSid in collection($config:data-rootA)//t:TEI
            return
            <option value="{$MSid/@xml:id}">{app:printTitle($MSid)}</option>
            }
        </datalist>
    return
        templates:form-control($control, $model)
};


declare function search:target-ins($node as node(), $model as map(*)) {
    let $control :=
        <datalist xmlns="http://www.w3.org/1999/xhtml"  multiple="multiple" id="institutions" class="hidden">
            {for $MSid in collection($config:data-rootIn)//t:TEI
            return
            <option value="{$MSid/@xml:id}">{app:printTitle($MSid)}</option>
            }
        </datalist>
    return
        templates:form-control($control, $model)
};


(:MANUSCRIPTS FILTERS for CONTEXT:)
declare function search:scripts($node as node(), $model as map(*)) {
    let $scripts := distinct-values(collection($config:data-rootMS)//@script)
    
   let $control :=
        <select multiple="multiple" name="script" class="form-control">
            <option value="all">all</option>
            {
            for $script in $scripts
            return
            <option value="{$script}">{$script}</option>
            }
        </select>
    return
        templates:form-control($control, $model)
};

declare function search:support($node as node(), $model as map(*)) {
    let $forms := distinct-values(collection($config:data-rootMS)//@form)
    
   let $control :=
        <select multiple="multiple" name="support" class="form-control">
            {
            for $form in $forms
            return
            <option value="{$form}">{$form}</option>
            }
        </select>
    return
        templates:form-control($control, $model)
};

declare function search:material($node as node(), $model as map(*)) {
    let $materials := distinct-values(collection($config:data-rootMS)//t:support/t:material/@key)
    
   let $control :=
        <select multiple="multiple" name="material" class="form-control">
            {
            for $material in $materials
            return
            <option value="{$material}">{$material}</option>
            }
        </select>
    return
        templates:form-control($control, $model)
};

declare function search:bmaterial($node as node(), $model as map(*)) {
    let $materials := distinct-values(collection($config:data-rootMS)//t:decoNote[@type='bindingMaterial']/t:material/@key)
    
   let $control :=
        <select multiple="multiple" name="bmaterial" class="form-control">
            {
            for $material in $materials
            return
            <option value="{$material}">{$material}</option>
            }
        </select>
    return
        templates:form-control($control, $model)
};



(:PLACES FILTERS for CONTEXT:)
declare function search:placeType($node as node(), $model as map(*)) {
    let $placeTypes := distinct-values(collection($config:data-rootPl,$config:data-rootIn)//t:place/@type/tokenize(., '\s+'))
    
   let $control :=
        <select multiple="multiple" name="placeType" class="form-control">
            {
            for $placeType in $placeTypes
            return
            <option value="{$placeType}">{$placeType}</option>
            }
        </select>
    return
        templates:form-control($control, $model)
};

declare function search:personType($node as node(), $model as map(*)) {
    let $persTypes := distinct-values(collection($config:data-rootPr)//t:person//t:occupation/@type/tokenize(., '\s+'))
    
   let $control :=
        <select multiple="multiple" name="occupationType" class="form-control">
            {
            for $persType in $persTypes
            return
            <option value="{$persType}">{$persType}</option>
            }
        </select>
    return
        templates:form-control($control, $model)
};

declare function search:relationType($node as node(), $model as map(*)) {
    let $relTypes := distinct-values(collection($config:data-root)//t:relation/@name/tokenize(., '\s+'))
    
   let $control :=
        <select multiple="multiple" name="relationType" class="form-control">
            {
            for $relType in $relTypes
            return
            <option value="{$relType}">{$relType}</option>
            }
        </select>
    return
        templates:form-control($control, $model)
};


(:IDS, TITLES, PERSNAMES, PLACENAMES, provide lists with guessing based on typing. the list must suggest a name but search for an ID:)


(:~
    Execute the query. The search results are not output immediately. Instead they
    are passed to nested templates through the $model parameter.
:)
declare 
     %templates:default("mode", "any")
    %templates:default("scope", "narrow")
    %templates:default("work-types", "all")
function search:query($node as node()*, $model as map(*), $query as xs:string?, $mode as xs:string, $scope as xs:string, 
    $work-types as xs:string+) {
    let $scr := 'all'
    let $coll := 'all'
    let $element := 'title'
    let $collection := if ($work-types = 'all') then () else ("//t:TEI[@type = '" ||$work-types|| "']")
    let $script := if ($scr = 'all') then () else ("[@script ='" || $scr || "']")
    let $queryExpr := search:create-query($query, $mode)
    
        if (empty($queryExpr) or $queryExpr = "") then
            let $cached := session:get-attribute("apps.BetMas")
            return
                map {
                    "hits" := $cached,
                    "query" := session:get-attribute("apps.BetMas.query")
                }
        else
            (:Get the work ids of the work types selected.:)  
            let $target-text-ids := distinct-values(collection($config:data-root)/t:TEI[@type = $coll]/@xml:id)
(:            get the ids the mss with the selected script:)
            let $target-script := distinct-values(collection($config:data-root)/t:TEI[.//@script = $script]/@xml:id)
            (:If no individual works have been selected, search in the works with ids selected by type;
            if indiidual works have been selected, then neglect that no selection has been done in works according to type.:) 
        
        let $target-texts := 
                if ($target-texts = 'all' and $coll = 'all' and $script = 'all')
                then 'all' 
                else 
                    if ($target-texts = 'all')
                    then $target-text-ids
                    else 
                        if ($coll = "all") then $target-texts else ($target-texts[. = $target-text-ids])
        
        let $context := 
               if ($target-texts = 'all')
                then collection($config:data-root)/t:TEI
                else collection($config:data-root)/t:TEI[@xml:id = $target-texts]
                
         let $build-query := concat("collection('",$config:data-root,"')","//t:title", "[ft:query(., '" , $query, "*')]")
          

                
                
          let $hits :=
                if ($scope eq 'narrow')
                then
              
                    for $hit in util:eval($build-query)
                    order by ft:score($hit) descending
                    return $hit
                    
                   else if ($scope eq 'text')
                then ()
                    for $hit in ($context//t:incipit[ft:query(., $queryExpr)], $context//t:explicit[ft:query(., $queryExpr)], $context//t:colophon[ft:query(., $queryExpr)], $context//t:ab[ft:query(., $queryExpr)], $context//t:l[ft:query(., $queryExpr)])
                    order by ft:score($hit) descending
                    return $hit
                else ()
                    for $hit in ($context//t:title[ft:query(., $queryExpr)], 
                    $context//t:desc[ft:query(., $queryExpr)], 
                    $context//t:note[ft:query(., $queryExpr)],
                    $context//t:p[ft:query(., $queryExpr)], 
                    $context//t:ab[ft:query(., $queryExpr)], 
                    $context//t:seg[ft:query(., $queryExpr)], 
                    $context//t:summary[ft:query(., $queryExpr)],
                    $context//t:foliation[ft:query(., $queryExpr)], 
                    $context//t:relation[ft:query(., $queryExpr)], 
                    $context//t:q[ft:query(., $queryExpr)], 
                    $context//t:incipit[ft:query(., $queryExpr)], 
                    $context//t:explicit[ft:query(., $queryExpr)], 
                    $context//t:abstract[ft:query(., $queryExpr)], 
                    $context//t:colophon[ft:query(., $queryExpr)], 
                    $context//t:incipit[ft:query(., $queryExpr)], 
                    $context//t:explicit[ft:query(., $queryExpr)],
                    $context//t:ab[ft:query(., $queryExpr)], 
                    $context//t:l[ft:query(., $queryExpr)])
                    order by ft:score($hit) descending
                    return $hit
            let $store := (
                session:set-attribute("apps.BetMas", $hits),
                session:set-attribute("apps.BetMas.query", $queryExpr)
            )
            return
                (: Process nested templates :)
                map {
                    "hits" := $hits,
                    "query" := $queryExpr
                }
};

declare function search:test($node as node()*, $model as map(*)){
$model('hits')
};

(:~
    Helper function: create a lucene query from the user input
:)
declare function search:create-query($query-string as xs:string?, $mode as xs:string) {
    let $query-string := 
        if ($query-string) 
        then search:sanitize-lucene-query($query-string) 
        else ''
    let $query-string := normalize-space($query-string)
    let $query:=
        (:If the query contains any operator used in sandard lucene searches or regex searches, pass it on to the query parser;:) 
        if (functx:contains-any-of($query-string, ('AND', 'OR', 'NOT', '+', '-', '!', '~', '^', '.', '?', '*', '|', '{','[', '(', '<', '@', '#', '&amp;')) and $mode eq 'any')
        then 
            let $luceneParse := search:parse-lucene($query-string)
            let $luceneXML := util:parse($luceneParse)
            let $lucene2xml := search:lucene2xml($luceneXML/node(), $mode)
            return $lucene2xml
        (:otherwise the query is performed by selecting one of the special options (any, all, phrase, near, fuzzy, wildcard or regex):)
        else
            let $query-string := tokenize($query-string, '\s')
            let $last-item := $query-string[last()]
            let $query-string := 
                if ($last-item castable as xs:integer) 
                then string-join(subsequence($query-string, 1, count($query-string) - 1), ' ') 
                else string-join($query-string, ' ')
            let $query :=
                <query>
                    {
                        if ($mode eq 'any') 
                        then
                            for $term in tokenize($query-string, '\s')
                            return <term occur="should">{$term}</term>
                        else if ($mode eq 'all') 
                        then
                            <bool>
                            {
                                for $term in tokenize($query-string, '\s')
                                return <term occur="must">{$term}</term>
                            }
                            </bool>
                        else 
                            if ($mode eq 'phrase') 
                            then <phrase>{$query-string}</phrase>
                       else
                                if ($mode eq 'near-unordered')
                                then <near slop="{if ($last-item castable as xs:integer) then $last-item else 5}" ordered="no">{$query-string}</near>
                        else 
                                    if ($mode eq 'near-ordered')
                                    then <near slop="{if ($last-item castable as xs:integer) then $last-item else 5}" ordered="yes">{$query-string}</near>
                                    else 
                                        if ($mode eq 'fuzzy')
                                        then <fuzzy max-edits="{if ($last-item castable as xs:integer and number($last-item) < 3) then $last-item else 2}">{$query-string}</fuzzy>
                                        else 
                                            if ($mode eq 'wildcard')
                                            then <wildcard>{$query-string}</wildcard>
                                            else 
                                                if ($mode eq 'regex')
                                                then <regex>{$query-string}</regex>
                                                else ()
                    }</query>
            return $query
    return $query
    
};


(: SIMPLE search :)



(:~
 : FROM SHAKESPEAR
    Create a span with the number of items in the current search result.
:)
declare function search:hit-count($node as node()*, $model as map(*)) {
    <h1>{$app:search-title}"{$app:searchphrase}", total results: <span xmlns="http://www.w3.org/1999/xhtml" id="hit-count">{ count($model("hits")) }</span></h1>
};


(:~
 : FROM SHAKESPEAR
 : Create a bootstrap pagination element to navigate through the hits.
 :)
declare
    %templates:wrap
    %templates:default('start', 1)
    %templates:default("per-page", 10)
    %templates:default("min-hits", 0)
    %templates:default("max-pages", 10)
function search:paginate($node as node(), $model as map(*), $start as xs:int, $per-page as xs:int, $min-hits as xs:int,
    $max-pages as xs:int) {
        
    if ($min-hits < 0 or count($model("hits")) >= $min-hits) then
        let $count := xs:integer(ceiling(count($model("hits"))) div $per-page) + 1
        let $middle := ($max-pages + 1) idiv 2
        return (
            if ($start = 1) then (
                <li class="disabled">
                    <a><i class="glyphicon glyphicon-fast-backward"/></a>
                </li>,
                <li class="disabled">
                    <a><i class="glyphicon glyphicon-backward"/></a>
                </li>
            ) else (
                <li>
                    <a href="?query={$app:searchphrase}&amp;start=1"><i class="glyphicon glyphicon-fast-backward"/></a>
                </li>,
                <li>
                    <a href="?query={$app:searchphrase}&amp;start={max( ($start - $per-page, 1 ) ) }"><i class="glyphicon glyphicon-backward"/></a>
                </li>
            ),
            let $startPage := xs:integer(ceiling($start div $per-page))
            let $lowerBound := max(($startPage - ($max-pages idiv 2), 1))
            let $upperBound := min(($lowerBound + $max-pages - 1, $count))
            let $lowerBound := max(($upperBound - $max-pages + 1, 1))
            for $i in $lowerBound to $upperBound
            return
                if ($i = ceiling($start div $per-page)) then
                    <li class="active"><a href="?searchphrase={$app:searchphrase}&amp;start={max( (($i - 1) * $per-page + 1, 1) )}">{$i}</a></li>
                else
                    <li><a href="?query={$app:searchphrase}&amp;start={max( (($i - 1) * $per-page + 1, 1)) }">{$i}</a></li>,
            if ($start + $per-page < count($model("hits"))) then (
                <li>
                    <a href="?query={$app:searchphrase}&amp;start={$start + $per-page}"><i class="glyphicon glyphicon-forward"/></a>
                </li>,
                <li>
                    <a href="?query={$app:searchphrase}&amp;start={max( (($count - 1) * $per-page + 1, 1))}"><i class="glyphicon glyphicon-fast-forward"/></a>
                </li>
            ) else (
                <li class="disabled">
                    <a><i class="glyphicon glyphicon-forward"/></a>
                </li>,
                <li>
                    <a><i class="glyphicon glyphicon-fast-forward"/></a>
                </li>
            )
        ) else
            ()
};


(: FROM SHAKESPEAR :)

declare    
%templates:wrap
    %templates:default('start', 1)
    %templates:default("per-page", 10) 
    function search:searchRes (
    $node as node(), 
    $model as map(*), $start as xs:integer, $per-page as xs:integer) {
        
    for $text at $p in subsequence($model("hits"), $start, $per-page)
        let $root := root($text)
        let $id := data($root/t:TEI/@xml:id)
        let $coll := switch($root/t:TEI/@type)
                    case "auth"  return       'authority-files' 
                    case "place"  return       'places' 
                    case "ins"  return       'institutions'
                    case "pers"  return       'persons'
                    case "work"  return       'works'
                    case "narr"  return       'narratives' 
                    default return 'manuscripts'
        let $score as xs:float := ft:score($text)
         return
            <div class="row reference">
                <div class="col-md-1"><span class="number">{$start + $p - 1}</span></div>
                        <div class="col-md-3"><a href="{$id}">
                    {app:printTitle(root($text)/t:TEI)} ({$id}), 
                    in <code>{$text/name()}</code></a></div>
                        <div class="col-md-7">{kwic:summarize($text,<config width="40"
                        />)}</div>
                        <div class="col-md-1"><p>Score: {$score}</p></div>
                    </div>
       
                
        

    };
    
    
(: copy all parameters, needed for search :)

declare function search:copy-params($node as node(), $model as map(*)) {
    element { node-name($node) } {
        $node/@* except $node/@href,
        attribute href {
            let $link := $node/@href
            let $params :=
                string-join(
                    for $param in request:get-parameter-names()
                    for $value in request:get-parameter($param, ())
                    return
                        $param || "=" || $value,
                    "&amp;"
                )
            return
                $link || "?" || $params
        },
        $node/node()
    }
};



(: This functions provides crude way to avoid the most common errors with paired expressions and apostrophes. :)
(: TODO: check order of pairs:)
declare %private function search:sanitize-lucene-query($query-string as xs:string) as xs:string {
    let $query-string := replace($query-string, "'", "''") (:escape apostrophes:)
    (:TODO: notify user if query has been modified.:)
    (:Remove colons – Lucene fields are not supported.:)
    let $query-string := translate($query-string, ":", " ")
    let $query-string := 
	   if (functx:number-of-matches($query-string, '"') mod 2) 
	   then $query-string
	   else replace($query-string, '"', ' ') (:if there is an uneven number of quotation marks, delete all quotation marks.:)
    let $query-string := 
	   if ((functx:number-of-matches($query-string, '\(') + functx:number-of-matches($query-string, '\)')) mod 2 eq 0) 
	   then $query-string
	   else translate($query-string, '()', ' ') (:if there is an uneven number of parentheses, delete all parentheses.:)
    let $query-string := 
	   if ((functx:number-of-matches($query-string, '\[') + functx:number-of-matches($query-string, '\]')) mod 2 eq 0) 
	   then $query-string
	   else translate($query-string, '[]', ' ') (:if there is an uneven number of brackets, delete all brackets.:)
    let $query-string := 
	   if ((functx:number-of-matches($query-string, '{') + functx:number-of-matches($query-string, '}')) mod 2 eq 0) 
	   then $query-string
	   else translate($query-string, '{}', ' ') (:if there is an uneven number of braces, delete all braces.:)
    let $query-string := 
	   if ((functx:number-of-matches($query-string, '<') + functx:number-of-matches($query-string, '>')) mod 2 eq 0) 
	   then $query-string
	   else translate($query-string, '<>', ' ') (:if there is an uneven number of angle brackets, delete all angle brackets.:)
    return $query-string
};

(: Function to translate a Lucene search string to an intermediate string mimicking the XML syntax, 
with some additions for later parsing of boolean operators. The resulting intermediary XML search string will be parsed as XML with util:parse(). 
Based on Ron Van den Branden, https://rvdb.wordpress.com/2010/08/04/exist-lucene-to-xml-syntax/:)
(:TODO:
The following cases are not covered:
1)
<query><near slop="10"><first end="4">snake</first><term>fillet</term></near></query>
as opposed to
<query><near slop="10"><first end="4">fillet</first><term>snake</term></near></query>

w(..)+d, w[uiaeo]+d is not treated correctly as regex.
:)
declare %private function search:parse-lucene($string as xs:string) {
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
        return search:parse-lucene($rep)                
    else 
        (: replace all booleans with '<AND/>|<OR/>|<NOT/>' :)
        if (matches($string, '[^<](AND|OR|NOT) ')) 
        then
            let $rep := replace($string, '(AND|OR|NOT) ', '<$1/>')
            return search:parse-lucene($rep)
        else 
            (: replace all '+' modifiers in token-initial position with '<AND/>' :)
            if (matches($string, '(^|[^\w&quot;])\+[\w&quot;(]'))
            then
                let $rep := replace($string, '(^|[^\w&quot;])\+([\w&quot;(])', '$1<AND type=_+_/>$2')
                return search:parse-lucene($rep)
            else 
                (: replace all '-' modifiers in token-initial position with '<NOT/>' :)
                if (matches($string, '(^|[^\w&quot;])-[\w&quot;(]'))
                then
                    let $rep := replace($string, '(^|[^\w&quot;])-([\w&quot;(])', '$1<NOT type=_-_/>$2')
                    return search:parse-lucene($rep)
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
                        return search:parse-lucene($rep)
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
                            return search:parse-lucene($rep)
                        else (: wrap fuzzy search strings in '<fuzzy max-edits=""></fuzzy>' :)
                            if (matches($string, '[\w-[<>]]+?~[\d.]*')) 
                            then
                                let $rep := replace($string, '([\w-[<>]]+?)~([\d.]*)', '<fuzzy max-edits=_$2_>$1</fuzzy>')
                                return search:parse-lucene($rep)
                            else (: wrap resulting string in '<query></query>' :)
                                concat('<query>', replace(normalize-space($string), '_', '"'), '</query>')
};

(: Function to transform the intermediary structures in the search query generated through app:parse-lucene() and util:parse() 
to full-fledged boolean expressions employing XML query syntax. 
Based on Ron Van den Branden, https://rvdb.wordpress.com/2010/08/04/exist-lucene-to-xml-syntax/:)
declare %private function search:lucene2xml($node as item(), $mode as xs:string) {
    typeswitch ($node)
        case element(query) return 
            element { node-name($node)} {
            element bool {
            $node/node()/search:lucene2xml(., $mode)
        }
    }
    case element(AND) return ()
    case element(OR) return ()
    case element(NOT) return ()
    case element() return
        let $name := 
            if (($node/self::phrase | $node/self::near)[not(@slop > 0)]) 
            then 'phrase' 
            else node-name($node)
        return
            element { $name } {
                $node/@*,
                    if (($node/following-sibling::*[1] | $node/preceding-sibling::*[1])[self::AND or self::OR or self::NOT or self::bool])
                    then
                        attribute occur {
                            if ($node/preceding-sibling::*[1][self::AND]) 
                            then 'must'
                            else 
                                if ($node/preceding-sibling::*[1][self::NOT]) 
                                then 'not'
                                else 
                                    if ($node[self::bool]and $node/following-sibling::*[1][self::AND])
                                    then 'must'
                                    else
                                        if ($node/following-sibling::*[1][self::AND or self::OR or self::NOT][not(@type)]) 
                                        then 'should' (:must?:) 
                                        else 'should'
                        }
                    else ()
                    ,
                    $node/node()/search:lucene2xml(., $mode)
        }
    case text() return
        if ($node/parent::*[self::query or self::bool]) 
        then
            for $tok at $p in tokenize($node, '\s+')[normalize-space()]
            (:Here the query switches into regex mode based on whether or not characters used in regex expressions are present in $tok.:)
            (:It is not possible reliably to distinguish reliably between a wildcard search and a regex search, so switching into wildcard searches is ruled out here.:)
            (:One could also simply dispense with 'term' and use 'regex' instead - is there a speed penalty?:)
                let $el-name := 
                    if (matches($tok, '((^|[^\\])[.?*+()\[\]\\^|{}#@&amp;<>~]|\$$)') or $mode eq 'regex')
                    then 'regex'
                    else 'term'
                return 
                    element { $el-name } {
                        attribute occur {
                        (:if the term follows AND:)
                        if ($p = 1 and $node/preceding-sibling::*[1][self::AND]) 
                        then 'must'
                        else 
                            (:if the term follows NOT:)
                            if ($p = 1 and $node/preceding-sibling::*[1][self::NOT])
                            then 'not'
                            else (:if the term is preceded by AND:)
                                if ($p = 1 and $node/following-sibling::*[1][self::AND][not(@type)])
                                then 'must'
                                    (:if the term follows OR and is preceded by OR or NOT, or if it is standing on its own:)
                                else 'should'
                    }
                    (:,
                    if (matches($tok, '((^|[^\\])[.?*+()\[\]\\^|{}#@&amp;<>~]|\$$)')) 
                    then
                        (\:regex searches have to be lower-cased:\)
                        attribute boost {
                            lower-case(replace($tok, '(.*?)(\^(\d+))(\W|$)', '$3'))
                        }
                    else ():)
        ,
        (:regex searches have to be lower-cased:)
        lower-case(normalize-space(replace($tok, '(.*?)(\^(\d+))(\W|$)', '$1')))
        }
        else normalize-space($node)
    default return
        $node
};

