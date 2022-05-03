xquery version "3.1" encoding "UTF-8";
(:~
 : module used by the app for string query, templating pages and general behaviours
 : mostly inherited from exist-db examples app but all largely modified
 : 
 : @author Pietro Liuzzo 
 :)
module namespace app="https://www.betamasaheft.uni-hamburg.de/BetMasWeb/app";

declare namespace test="http://exist-db.org/xquery/xqsuite";
declare namespace t="http://www.tei-c.org/ns/1.0";
declare namespace functx = "http://www.functx.com";
declare namespace exist = "http://exist.sourceforge.net/NS/exist";
declare namespace skos = "http://www.w3.org/2004/02/skos/core#";
declare namespace rdf = "http://www.w3.org/1999/02/22-rdf-syntax-ns#";
declare namespace s = "http://www.w3.org/2005/xpath-functions";
declare namespace sr = "http://www.w3.org/2005/sparql-results#";
declare namespace xconf="http://exist-db.org/collection-config/1.0";

import module namespace switch2 = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/switch2"  at "xmldb:exist:///db/apps/BetMasWeb/modules/switch2.xqm";
import module namespace kwic = "http://exist-db.org/xquery/kwic" at "resource:org/exist/xquery/lib/kwic.xql";
import module namespace templates="http://exist-db.org/xquery/templates" ;
import module namespace log="http://www.betamasaheft.eu/log" at "xmldb:exist:///db/apps/BetMasWeb/modules/log.xqm";
import module namespace coord="https://www.betamasaheft.uni-hamburg.de/BetMasWeb/coord" at "xmldb:exist:///db/apps/BetMasWeb/modules/coordinates.xqm";
import module namespace nav="https://www.betamasaheft.uni-hamburg.de/BetMasWeb/nav" at "xmldb:exist:///db/apps/BetMasWeb/modules/nav.xqm";
import module namespace ann = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/ann" at "xmldb:exist:///db/apps/BetMasWeb/modules/annotations.xqm";
import module namespace all="https://www.betamasaheft.uni-hamburg.de/BetMasWeb/all" at "xmldb:exist:///db/apps/BetMasWeb/modules/all.xqm";
import module namespace editors="https://www.betamasaheft.uni-hamburg.de/BetMasWeb/editors" at "xmldb:exist:///db/apps/BetMasWeb/modules/editors.xqm";
import module namespace exptit="https://www.betamasaheft.uni-hamburg.de/BetMasWeb/exptit" at "xmldb:exist:///db/apps/BetMasWeb/modules/exptit.xqm";
import module namespace config="https://www.betamasaheft.uni-hamburg.de/BetMasWeb/config" at "xmldb:exist:///db/apps/BetMasWeb/modules/config.xqm";
import module namespace xdb = "http://exist-db.org/xquery/xmldb";
import module namespace validation = "http://exist-db.org/xquery/validation";
import module namespace fusekisparql = 'https://www.betamasaheft.uni-hamburg.de/BetMasWeb/sparqlfuseki' at "xmldb:exist:///db/apps/BetMasWeb/fuseki/fuseki.xqm";
import module namespace console="http://exist-db.org/xquery/console";
import module namespace apptable="https://www.betamasaheft.uni-hamburg.de/BetMasWeb/apptable" at "xmldb:exist:///db/apps/BetMasWeb/modules/apptable.xqm";

(:~declare variable $app:item-uri as xs:string := raequest:get-parameter('uri',());:)
declare variable $app:deleted := doc('/db/apps/lists/deleted.xml');
declare variable $app:collection as xs:string := request:get-parameter('collection',());
declare variable $app:name as xs:string := request:get-parameter('name',());
declare variable $app:params := request:get-parameter-names() ;
declare variable $app:facets := doc("/db/system/config/db/apps/BetMasData/collection.xconf")//xconf:facet/@dimension ;
declare variable $app:rest  as xs:string := '/rest/';
declare variable $app:languages := doc('/db/apps/lists/languages.xml');
declare variable $app:tax := doc('/db/apps/lists/canonicaltaxonomy.xml');
declare variable $app:range-lookup := 
    (
        function-lookup(xs:QName("range:index-keys-for-field"), 4),
        function-lookup(xs:QName("range:index-keys-for-field"), 3)
    )[1];
    
    declare variable $app:util-index-lookup := 
    (
        function-lookup(xs:QName("util:index-keys"), 5),
        function-lookup(xs:QName("util:index-keys"), 4)
    )[1];
    

(:~collects bibliographical information for zotero metadata:)
declare variable $app:bibdata := 
let $file := $exptit:col/id($app:name)
let $auths := $file//t:revisionDesc/t:change/@who[. != 'PL']
return

(:~here I cannot use for the title the javascript titles.js because the content is not exposed:)
<bibl>
{
for $author in config:distinct-values($auths)
let $count := count($file//t:revisionDesc/t:change[@who eq $author])
order by $count descending
                return
<author>{editors:editorKey(string($author))}</author>
}
<title level="a">{exptit:printTitle($file)}</title>
<title level="j">{$exptit:col/id($app:name)//t:publisher/text()}</title>
<date type="accessed"> [Accessed: {current-date()}] </date>
{let $time := max($file//t:revisionDesc/t:change/xs:date(@when))
return
<date type="lastModified">(Last Modified: {format-date($time, '[D].[M].[Y]')}) </date>
}
<idno type="url">
{($config:appUrl || $app:collection||'/' ||$app:name)}
</idno>
<idno type="DOI">
{($config:DOI || '.' ||$app:name)}
</idno>
</bibl>
;


declare variable $app:search-title as xs:string := "Search: ";
declare variable $app:searchphrase as xs:string := request:get-parameter('query',());
declare variable $app:APP_ROOT :=
    let $nginx-request-uri := request:get-header('nginx-request-uri')
    return
        (: if request received from nginx :)
        if ($nginx-request-uri) then
                ""
        (: otherwise we're in the eXist URL space :)
        else
            request:get-context-path() || "/apps/BetMas"
            ;

declare %private function functx:capitalize-first( $arg as xs:string? )  as xs:string? {
   concat(upper-case(substring($arg,1,1)),
             substring($arg,2))
 } ;
 
declare function app:interpretationSegments($node as node(), $model as map(*)){
 for $d in config:distinct-values(collection($config:data-rootMS)//t:seg/@ana)
                    return
                    <option value="{$d}">{substring-after($d, '#')}</option>
                    };


(:get parallel diplomatique forms:)
declare function app:diplomatiqueforms($node as node(), $model as map(*),$interpret as xs:string*)
{
let $path := '$exptit:col//t:seg[@ana eq "' || $interpret ||'"]'
let $hits := for $occurrence in util:eval($path)
                 return $occurrence
return
map {'hits' : $hits}
};

declare 
%templates:wrap
    %templates:default('start', 1)
    %templates:default("per-page", 10) 
function app:diplomatiqueResults($node as node(), 
    $model as map(*), $start as xs:integer, $per-page as xs:integer) {
        
    for $occurrence at $p in subsequence($model("hits"), $start, $per-page)
let $text := normalize-space($occurrence/text())
let $rootID := string(root($occurrence)/t:TEI/@xml:id)
let $itemid := string($occurrence/ancestor::t:item/@xml:id)
let $source := ($rootID || '#' || $itemid)
let $stitle := $source
return 
<div class="w3-row reference">
                <div class="w3-col"><span class="number">{$start + $p - 1}</span></div>
                        <div class="w3-quarter"><a href="/{$rootID}">{exptit:printTitleID($rootID)}</a> ({$rootID}#{$itemid})</div>
                        <div class="w3-rest">{$text}</div>
                        
                    </div>

};

(:~ logging function to be called from templating pages:)
declare function app:logging ($node as node(), $model as map(*)){
let $url := request:get-uri()

   let $paramstobelogged := for $p in $app:params for $value in request:get-parameter($p, ()) return ($p || '=' || $value)
   let $logparams := if(count($paramstobelogged) >= 1) then '?' || string-join($paramstobelogged, '&amp;') else ()
   let $url := $url || $logparams
   return 
   log:add-log-message($url, sm:id()//sm:real/sm:username/string() , 'page')
  
};


(:~storing separately this input in this 
 : function makes sure that when the page is 
 : reloaded with the results the value entered remains in the input element:)
declare function app:queryinput ($node as node(), $model as map(*), $query as xs:string*){<input name="query" type="search" class="w3-input  w3-border diacritics" placeholder="type here the text you want to search" value="{$query}"/>};


(: ~ calls the templates for static parts of the page so that different templates can use them. To make those usable also from restxq, they have to be called by templates like this, so nav.xql needs not the template module :)
declare function app:NbarNew($node as node()*, $model as map(*)){nav:barNew()};
declare function app:modalsNew($node as node()*, $model as map(*)){nav:modalsNew()};
declare function app:footerNew($node as node()*, $model as map(*)){nav:footerNew()};


(:~ the new issue button with a link to the github repo issues list :)
declare function app:newissue($node as node()*, $model as map(*)){
<a role="button" class="w3-button w3-small w3-gray" target="_blank" href="https://github.com/BetaMasaheft/Documentation/issues/new/choose">new issue</a>};



(:~determins what the selectors for various form controls will look like, is called by app:formcontrol() :)
declare function app:selectors($nodeName, $path, $nodes, $type, $context){
             <select multiple="multiple" name="{$nodeName}" id="{$nodeName}" class="w3-select w3-border">
            {
            
            if ($type = 'keywords') then (
                    for $group in $nodes/t:category[t:desc]
                    let $label := $group/t:desc/text()
                     let $rangeindexname := switch($label) 
                    case 'Occupation' return 'occtype'
                    case 'Art Themes' return 'refcorresp'
                    case 'Additiones' return 'desctype'
                    case 'Place types' return 'placetype'
                    default return 'termkey'
                    return
                    for $n in $group//t:catDesc
                    let $id := $n/text()
                    let $title :=exptit:printTitleID($id)
                   
                    let $facet := try{
                        $path/$app:range-lookup($rangeindexname, $id, function($key, $count){$count[2]}, 100)} catch*{($err:code || $err:description)}
                    let $fac := if($facet[1] ge 1) then $facet[1] else '0'
                    return
                       <option value="{$id}">{($title[1] ||' (' || $fac  ||')')}</option>
                                )
                                              
            else if ($type = 'name')
                            then (for $n in $nodes[. != ''][. != ' ']
                            let $id := string($n/@xml:id)
                            let $title := exptit:printTitleID($id)
                                               order by $id
                                               return
            
                                                <option value="{$id}" >{$title}</option>
                                          )
            else if ($type = 'rels')
                     then (
                    
                 for $n in $nodes[. != ''][. != ' ']
                          let $title :=  exptit:printTitleID($n)
                            order by $title[1] 
                             return
            
                             <option value="{$n}">{normalize-space(string-join($title))}</option>
                        )
             else if ($type = 'hierels')
             then (
             for $n in $nodes[. != ''][. != ' '][not(starts-with(.,'#'))]
             group by $work := if (contains($n, '#')) then (substring-before($n, '#')) else $n
                            order by $work
                                return 
                                let $label :=
                                    try{
                                        if ($exptit:col/id($work)) 
                                        then exptit:printTitle($exptit:col/id($work)) 
                                        else $work} 
(:                                        this has to stay because optgroup requires label and this cannot be computed from the javascript as in other places:)
                                    catch* {
                                        ('while trying to create a list for the filter ' ||$nodeName || ' I got '|| $err:code ||': '||$err:description || ' about ' || $work), 
                                         $work}
                                return
                                if (count($n) = 1)
                                then <option value="{$work}">{exptit:printTitleID($work)}</option>
                                else(
                                      <optgroup label="{$label}">
                  
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
            
                            <option value="{$institutionId}" >{exptit:printTitleID($institutionId)}</option>
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
                let $title := if($nodeName = 'keyword' or $nodeName = "placetype"or $nodeName = "country"or $nodeName = "settlement") then exptit:printTitleID($thiskey) 
                                        else if ($nodeName = 'language') then $app:languages//t:item[@xml:id eq $thiskey]/text()
                                        else $thiskey
                let $rangeindexname := 
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
                 let $ctx := util:eval($context)
                 let $facet := if($nodeName = 'script') 
                                          then ($app:util-index-lookup($ctx//@script, lower-case($thiskey), function($key, $count) {$count[2]}, 100, 'lucene-index' )) 
                                          else ( $ctx/$app:range-lookup($rangeindexname, $thiskey, function($key, $count) {$count[2]}, 100))
                order by $n
                return
                
            <option value="{$thiskey}">{if($thiskey = 'Printedbook') then 'Printed Book' 
             else $title} {(' ('||$facet[1]||')')}</option>
            )
            }
        </select>
};

(:~ builds the form control according to the data specification and is called by all 
 : the functions building the search form. these are in turn called by a html div called by a javascript function.
 : retold from user perspective the initial form in as.html uses the controller template model with the template search.html, which calls 
 : a javascirpt filters.js which on click loads with AJAX the selected form*.html file. 
 : Each of these contains a call to a function app:NAMEofTHEform which will call app:formcontrol which will call app:selectors:)
declare function app:formcontrol($nodeName as xs:string, $path, $group, $type, $context) {

        

if ($group = 'true') 
then ( 
      let $values := for $i in $path return  if (contains($i, ' ')) then tokenize($i, ' ') else if ($i=' ' or $i='' ) then () else functx:trim(normalize-space($i))
      let $nodes := config:distinct-values($values)
      return 
       <div class="w3-container">
                    <label for="{$nodeName}">{$nodeName}s <span class="w3-badge">{count($nodes[. != ''][. != ' '])}</span></label>
                    {app:selectors($nodeName, $path, $nodes, $type, $context) }
      </div>
      )
else (
         let $nodes := for $node in $path return $node
            return
       app:selectors($nodeName, $path, $nodes, $type, $context)   
       )
};



(:~the filters available in the search results view used by search.html:)
declare function app:searchFilter($node as node()*, $model as map(*)) {
let $items-info := $model('hits')
let $q := $model('q')
let $cont := $model('query')
return

<form action="" class="w3-container">
                {app:formcontrol('language', $items-info//@xml:lang, 'true', 'values', $cont),
                app:formcontrol('keyword', $items-info//t:term/@key, 'true', 'titles', $cont),
               
                <label for="dates">date range</label>,
                <input id="dates" type="text" class="span2" 
                name="dateRange" 
                data-slider-min="0" 
                data-slider-max="2000" 
                data-slider-step="10" 
                data-slider-value="[0,2000]"/>,
                <script type="text/javascript">
                {"$('#dates').bootstrapSlider({});"}
                </script>,
  <input type="hidden" name="query" value="{$q}"/>
            }
                <div class="w3-bar">
                <button type="submit" class="w3-button w3-red w3-bar-item"> Filter
                    </button>
                <a href="/as.html" role="button" class="w3-button w3-gray w3-bar-item">Advanced Search Form</a>
</div></form>
};


(:~query parameters and corresponding filtering of the xpath context for ft:query
 : returns xpath as string to be later evaluated:)
declare function app:ListQueryParam($parameter, $context, $mode, $function){
      if(exists($app:params)) 
      then( 
               let $allparamvalues := 
                                     if ($parameter = $app:params) 
                                     then (request:get-parameter($parameter, ())) 
                                     else 'all'
                return
                       if ($allparamvalues = 'all') then () 
                       else ( 
                                if($parameter='xmlid') then (
                                            if($allparamvalues = '') then () 
                                            else if($allparamvalues != 'all') then "[contains(@xml:id, '" ||$allparamvalues||"')]" 
                                            else ())
                                else
                                      let $keys :=  if ($parameter = 'keyword')  then (
                                                                        for $k in $allparamvalues 
                                                                        let $ks := doc($config:data-rootA || '/taxonomy.xml')//t:catDesc[text() eq $k]/following-sibling::t:*/t:catDesc/text() 
                                                                         let $nestedCats := for $n in $ks return $n 
                                                                           return 
                                                                            if ($nestedCats >= 2) then (replace($k, '#', ' ') || ' OR ' || string-join($nestedCats, ' OR ')) else (replace($k, '#', ' ')))
                                                             else(
                                                                         for $k in $allparamvalues 
                                                                          return 
                                                                          replace($k, '#', ' ') )
                                        return 
                                                if ($function = 'list')  then "[ft:query(" || $context || ", '" || string-join($keys, ' ') ||"')]"
                                                 else  
                                                         let $limit := for $k in $allparamvalues  
                                                                              return 
                                                                             if($parameter = 'author')
                                                                             then "descendant::" || $context || "='" || $k ||"' or  descendant::t:relation[@name eq 'dcterms:creator']/@passive eq '"|| $k ||"'"
                                                                           else if($parameter = 'tabot')
                                                                             then 
                                                                             "descendant::t:ab[@type eq 'tabot'][descendant::t:persName[contains(@ref, '"||$k||"')] or descendant::t:ref[contains(@corresp, '"||$k||"')]]"
                                                                            
                                                                            else 
                                                                                         let $c := if(starts-with($context, '@')) then () else "descendant::"
                                                                                         return $c || $context || "='" || replace($k, ' ', '_') ||"' "
      
                                                          return "[" || string-join($limit, ' or ') || "]")
       ) else ()
};

    


(:~on login, print the name of the logged user:)
declare function app:greetings-rest(){
<a href="">Hi {sm:id()//sm:username/text()}!</a>
    };
(:on login, print the name of the logged user:)
declare function app:greetings($node as element(), $model as map(*)) as xs:string{
<a href="">Hi {sm:id()//sm:username/text()}!</a>
    };
    
 declare function app:logout(){
    session:invalidate()
    };

                        
                

(:~general count of contributions to the data:)
declare function app:team ($node as node(), $model as map(*)) {
<ul class="w3-ul w3-hoverable w3-padding">{
    $exptit:col/$app:range-lookup('changewho', (),
        function($key, $count) {
             <li id="{$key}">{editors:editorKey(replace($key, '#', '')) || ' ('||$key||')' || ' made ' || $count[1] ||' changes in ' || $count[2]||' documents. '}<a href="/xpath?xpath=%24config%3Acollection-root%2F%2Ft%3Achange%5B%40who%3D%27{$key}%27%5D">See the changes.</a></li>
        }, 1000)
       }
       </ul>
};


(:~general count of contributions to the data:)
declare function app:deleted ($node as node(), $model as map(*)) {
<ul class="w3-ul w3-hoverable w3-padding">{
    for $deleted in $app:deleted//t:item
    order by $deleted/@change descending
    let $coll := switch2:col(switch2:switchPrefix( $deleted))
    return <li  class="w3-display-container" id="permanentIDs{$deleted}" 
    data-id="{$deleted}" 
    data-path="{functx:capitalize-first(string($deleted/@source))}/{$deleted}.xml"
    data-type="{functx:capitalize-first($coll)}" >{$deleted/text()}, deleted from {string($deleted/@source)} on {string($deleted/@change)}.
    {let $formerly := $exptit:col//t:relation[@name eq 'betmas:formerlyAlsoListedAs'][@passive eq $deleted]
             let $same := $exptit:col//t:relation[@name eq 'skos:exactMatch'][@passive eq $deleted]
            return
            (if($formerly) then <p>This record is now listed as {string-join($formerly/@active, ', ')}.</p> 
            else(),
            if($same) then 
                    for $s in $same return <p>This record is the same as <a href="{string($s/@active)}" target="_blank">{exptit:printTitleID($s/@active)}</a>.</p> 
            else ())}
    <a class="w3-btn w3-gray w3-display-right" id="LoadPermanentIDs{$deleted}">Permalinks</a>
    </li>}
       </ul>,
       <script type="text/javascript" src="resources/js/permanentID.js"></script>
};

declare function app:oldids ($node as node(), $model as map(*)) {
<ul class="w3-ul w3-hoverable w3-padding">{
let $formerly := $exptit:col//t:relation[@name eq 'betmas:formerlyAlsoListedAs']/@passive
    for $deleted in $formerly
    let $now := string-join($deleted/ancestor::t:relation[@passive eq $deleted]/@active, ', ')
    order by $deleted  
    return 
    <li  class="w3-display-container">{substring-after($deleted, 'eu/')} is now listed as <a href="{$now}">{substring-after($now, 'eu/')}</a>. 
    </li>}
       </ul>
};

declare function functx:value-intersect  ( $arg1 as xs:anyAtomicType* ,    $arg2 as xs:anyAtomicType* )  as xs:anyAtomicType* {

  config:distinct-values($arg1[. eq $arg2])
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


(:~ADVANCED SEARCH FUNCTIONS the list of searchable and indexed elements :)
declare function app:elements($node as node(), $model as map(*)) {
    let $control :=
        <select xmlns="http://www.w3.org/1999/xhtml" multiple="multiple" id="element" name="element" class="w3-select w3-border">
            
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

(:~ called by form*.html files used by advances search form as.html and filters.js :)
declare
%templates:default("context", "collection($config:data-rootMS)")
function app:target-mss($node as node(), $model as map(*), $context as xs:string*) {
  let $cont := util:eval($context)
      let $control :=
        app:formcontrol('target-ms', $cont//t:TEI, 'false', 'name', $context)
        
    return
        templates:form-control($control, $model)
};

(:~ called by form*.html files used by advances search form as.html and filters.js :)
declare
%templates:default("context", "collection($config:data-rootW, $config:data-rootN)")
function app:target-works($node as node(), $model as map(*), $context as xs:string*) {
   let $cont := util:eval($context)
     let $control :=
    app:formcontrol('target-work', $cont//t:TEI, 'false', 'name', $context)
        
    return
        templates:form-control($control, $model)
};

(:~ called by form*.html files used by advances search form as.html and filters.js :)
declare
%templates:default("context", "collection($config:data-rootIn)")
function app:target-ins($node as node(), $model as map(*), $context as xs:string*) {
   let $cont := util:eval($context)
    let $control :=
    app:formcontrol('target-ins', $cont//t:TEI, 'false', 'name', $context)
        
    return
        templates:form-control($control, $model)
};


(:~ called by form*.html files used by advances search form as.html and filters.js MANUSCRIPTS FILTERS for CONTEXT:)
declare 
%templates:default("context", "collection($config:data-rootMS)")
function app:scripts($node as node(), $model as map(*), $context as xs:string*) {
    let $cont := util:eval($context)
    let $scripts := $app:util-index-lookup($cont//@script, (), function($key, $count) {$key}, 100, 'lucene-index' )
    let $control := app:formcontrol('script', $scripts, 'false', 'values', $context)
    return
        templates:form-control($control, $model)
};

(:~ called by form*.html files used by advances search form as.html and filters.js :)
declare 
%templates:default("context", "collection($config:data-rootMS)")
function app:support($node as node(), $model as map(*), $context as xs:string*) {
     let $cont := util:eval($context)
     let $forms := config:distinct-values($cont//@form)
     let $control := app:formcontrol('support', $forms, 'false', 'values', $context)
     return
        templates:form-control($control, $model)
};

(:~ called by form*.html files used by advances search form as.html and filters.js :)
declare
%templates:default("context", "collection($config:data-rootMS)")
function app:material($node as node(), $model as map(*), $context as xs:string*) {
      let $cont := util:eval($context)
      let $materials := config:distinct-values($cont//t:support/t:material/@key)
      let $control := app:formcontrol('material', $materials, 'false', 'values', $context)
      return
        templates:form-control($control, $model)
};

(:~ called by form*.html files used by advances search form as.html and filters.js :)
declare
%templates:default("context", "collection($config:data-rootMS)") 
function app:bmaterial($node as node(), $model as map(*), $context as xs:string*) {
    let $cont := util:eval($context)
      let $bmaterials := config:distinct-values($cont//t:decoNote[@type eq 'bindingMaterial']/t:material/@key)
    
   let $control :=
        app:formcontrol('bmaterial', $bmaterials, 'false', 'values', $context)
    return
        templates:form-control($control, $model)
};


(:~ called by form*.html files used by advances search form as.html and filters.js PLACES FILTERS for CONTEXT:)
declare
%templates:default("context", "collection($config:data-rootPl,$config:data-rootIn)") 
function app:placeType($node as node(), $model as map(*), $context as xs:string*) {
      let $cont := util:eval($context)
     let $placeTypes := config:distinct-values($cont//t:place/@type/tokenize(., '\s+'))
    let $control := app:formcontrol('placeType', $placeTypes, 'false', 'values', $context)
    return
        templates:form-control($control, $model)
};

(:~ called by form*.html files used by advances search form as.html and filters.js :)
declare
%templates:default("context", "collection($config:data-rootPr)") 
function app:personType($node as node(), $model as map(*), $context as xs:string*) {
    let $cont := util:eval($context)
      let $persTypes := config:distinct-values($cont//t:person//t:occupation/@type/tokenize(., '\s+'))
    let $control := app:formcontrol('persType', $persTypes, 'false', 'values', $context)
    return
        templates:form-control($control, $model)
};

(:~ called by form*.html files used by advances search form as.html and filters.js :)
declare
%templates:default("context", "$exptit:col") 
function app:relationType($node as node(), $model as map(*), $context as xs:string*) {
    let $cont := util:eval($context)
    let $relTypes := config:distinct-values($cont//t:relation/@name/tokenize(., '\s+'))
    let $control :=app:formcontrol('relType', $relTypes, 'false', 'values', $context)
    return
        templates:form-control($control, $model)
};

(:~ called by form*.html files used by advances search form as.html and filters.js :)
declare function app:keywords($node as node(), $model as map(*), $context as xs:string*) {
    let $keywords := doc($config:data-rootA || '/taxonomy.xml')//t:taxonomy
   let $control := app:formcontrol('keyword', $keywords, 'false', 'keywords', $context)
    return
        templates:form-control($control, $model)
};

(:~ called by form*.html files used by advances search form as.html and filters.js :)
declare
%templates:default("context", "collection($config:data-rootMS)") 
function app:languages($node as node(), $model as map(*), $context as xs:string*) {
     let $cont := util:eval($context)
     let $keywords := config:distinct-values($cont//t:language/@ident)
     let $control := app:formcontrol('language', $keywords, 'false', 'values', $context)
      return
        templates:form-control($control, $model)
};

(:~ called by form*.html files used by advances search form as.html and filters.js :)
declare
%templates:default("context", "collection($config:data-rootMS)")  
function app:scribes($node as node(), $model as map(*), $context as xs:string*) {
     let $cont := util:eval($context)
      let $elements := $cont//t:persName[@role eq 'scribe'][not(@ref eq 'PRS00000')][ not(@ref eq 'PRS0000')]
    let $keywords := config:distinct-values($elements/@ref)
    let $control := app:formcontrol('scribe', $keywords, 'false', 'rels', $context)
    return
        templates:form-control($control, $model)
};

(:~ called by form*.html files used by advances search form as.html and filters.js :)
declare
%templates:default("context", "collection($config:data-rootMS)")   
function app:donors($node as node(), $model as map(*), $context as xs:string*) {
     let $cont := util:eval($context)
    let $elements := $cont//t:persName[@role eq 'donor'][not(@ref eq 'PRS00000')][ not(@ref eq 'PRS0000')]
    let $keywords := config:distinct-values($elements/@ref)
   let $control :=app:formcontrol('donor', $keywords, 'false', 'rels', $context)
    return
        templates:form-control($control, $model)
};

(:~ called by form*.html files used by advances search form as.html and filters.js :)
declare
%templates:default("context", "collection($config:data-rootMS)")   
function app:patrons($node as node(), $model as map(*), $context as xs:string*) {
     let $cont := util:eval($context)
      let $elements := $cont//t:persName[@role eq 'patron'][not(@ref eq 'PRS00000')][ not(@ref eq 'PRS0000')]
    let $keywords := config:distinct-values($elements/@ref)
  let $control :=app:formcontrol('patron', $keywords, 'false', 'rels', $context)
    return
        templates:form-control($control, $model)
};

(:~ called by form*.html files used by advances search form as.html and filters.js :)
declare
%templates:default("context", "collection($config:data-rootMS)")  
function app:owners($node as node(), $model as map(*), $context as xs:string*) {
      let $cont := util:eval($context)
      let $elements := $cont//t:persName[@role eq 'owner'][not(@ref eq 'PRS00000')][ not(@ref eq 'PRS0000')]
      let $keywords := config:distinct-values($elements/@ref)
      let $control := app:formcontrol('owner', $keywords, 'false', 'rels', $context)
      return
        templates:form-control($control, $model)
};

(:~ called by form*.html files used by advances search form as.html and filters.js :)
declare
%templates:default("context", "collection($config:data-rootMS)") 
function app:binders($node as node(), $model as map(*), $context as xs:string*) {
      let $cont := util:eval($context)
      let $elements := $cont//t:persName[@role eq 'binder'][not(@ref eq 'PRS00000')][ not(@ref eq 'PRS0000')]
    let $keywords := config:distinct-values($elements/@ref)
   let $control := app:formcontrol('binder', $keywords, 'false', 'rels', $context)
    return
        templates:form-control($control, $model)
};

(:~ called by form*.html files used by advances search form as.html and filters.js :)
declare
%templates:default("context", "collection($config:data-rootMS)")
function app:parmakers($node as node(), $model as map(*), $context as xs:string*) {
    let $cont := util:eval($context)
      let $elements := $cont//t:persName[@role eq 'parchmentMaker'][not(@ref eq 'PRS00000')][ not(@ref eq 'PRS0000')]
    let $keywords := config:distinct-values($elements/@ref)
    let $control := app:formcontrol('parchmentMaker', $keywords, 'false', 'rels', $context)
       return
        templates:form-control($control, $model)
};

(:~ called by form*.html files used by advances search form as.html and filters.js :)
declare
%templates:default("context", "collection($config:data-rootMS)")
function app:contents($node as node(), $model as map(*), $context as xs:string*) {
    let $cont := util:eval($context)
    let $elements :=$cont//t:msItem[not(contains(@xml:id, '.'))]
    let $titles := $elements/t:title/@ref
    let $keywords := config:distinct-values($titles)
  return
   app:formcontrol('content', $keywords, 'false', 'hierels', $context)
};

(:~ called by form*.html files used by advances search form as.html and filters.js :)
declare
%templates:default("context", "collection($config:data-rootMS)")
function app:mss($node as node(), $model as map(*), $context as xs:string*) {
    let $cont := util:eval($context)
    let $keywords := for $r in $cont//t:witness/@corresp return string($r)|| ' '
   return
   app:formcontrol('ms', $keywords, 'false', 'hierels', $context)
};

(:~ called by form*.html files used by advances search form as.html and filters.js :)
declare
%templates:default("context", "collection($config:data-rootMS)")
function app:WorkAuthors($node as node(), $model as map(*), $context as xs:string*) {
let $works := util:eval($context)
let $attributions := for $rel in ($works//t:relation[@name eq "saws:isAttributedToAuthor"], $works//t:relation[@name eq "dcterms:creator"])
let $r := $rel/@passive
                return 
                if (contains($r, ' ')) then tokenize($r, ' ') else $r  
let $keywords := config:distinct-values($attributions)
  return
   app:formcontrol('author', $keywords, 'false', 'rels', $context)
};

(:~ called by form*.html files used by advances search form as.html and filters.js :)
declare 
%templates:default("context", "collection($config:data-rootIn)") 
function app:tabots($node as node(), $model as map(*), $context as xs:string*) {
let $cont := util:eval($context)
let $tabots:= $cont//t:ab[@type eq 'tabot']
    let $personTabot := config:distinct-values($tabots//t:persName/@ref) 
    let $thingsTabot := config:distinct-values($tabots//t:ref/@corresp)
    let $alltabots := ($personTabot, $thingsTabot)
  return
   app:formcontrol('tabot', $alltabots, 'false', 'rels', $context)
};


(:~ called by form*.html files used by advances search form as.html and filters.js IDS, TITLES, PERSNAMES, PLACENAMES, provide lists with guessing based on typing. the list must suggest a name but search for an ID:)
declare function app:BuildSearchQuery($element as xs:string, $query as xs:string){
let $SearchOptions := "map {
  'default-operator': 'or',
  'phrase-slop' : '0',
  'leading-wildcard' :'yes',
  'filter-rewrite': 'yes'
}"
    return
    if ($element='TEI') then 
    
concat("ft:query(., '" , $query, "', ", $SearchOptions ,")")
    else 
concat("descendant::t:", $element, "[ft:query(., '" , $query, "', ", $SearchOptions ,")]")
};


(:~ a function simply evaluating an xpath entered as string:)
declare  function app:xpathQuery($node as node(), $model as map(*), $xpath as xs:string?) {
if(empty($xpath)) then () else 
let $logpath := log:add-log-message($xpath, sm:id()//sm:real/sm:username/string() , 'XPath query')  
let $xpath := replace($xpath, '\$config:collection-(\w+)(//.+)', 'collection(\$config:data-$1)$2') 
let $hits := for $hit in util:eval($xpath)
return $hit
 return            
map {"hits": $hits, "path": $xpath, "total": count($hits)}
         
    };
    
    (:~ a function evaluating a sparql query, using the https://github.com/ljo/exist-sparql package:)
declare  function app:sparqlQuery($node as node(), $model as map(*), $query as xs:string?) {

if(empty($query)) then 'Please enter a valid SPARQL query.' else 
let $prefixes := $config:sparqlPrefixes
let $allquery := ($prefixes || normalize-space($query))
let $logpath := log:add-log-message($query, sm:id()//sm:real/sm:username/string() , 'SPARQL query')  
let $results := fusekisparql:query('betamasaheft', $allquery)
 return            
map {"sparqlResult": $results, "q": $query}
         
    };
    
    declare    
%templates:wrap
    function app:sparqlRes (
    $node as node(), 
    $model as map(*)) {
    transform:transform($model("sparqlResult"), 'xmldb:exist:///db/apps/BetMasWeb/rdfxslt/sparqltable.xsl', ())

    };
    
(:~ produces a piece of xpath for the query if the input is a range    :)
declare function app:paramrange($par, $path as xs:string){
    let $rangeparam := request:get-parameter($par, ())
   
     let $from := substring-before($rangeparam, ',') 
                let $to := substring-after($rangeparam, ',') 
                return
                if ($rangeparam = '0,2000')
                then ()
                else if ($rangeparam = '')
                then ()
                else
    ("[descendant::t:"||$path||"[. ge " || $from ||' ][ .  le ' || $to || "]]")
    
    };


(:~
    Execute the query on TEI, so that facet indexes will be reacheable
:)
declare function app:facetquery($node as node()*, $model as map(*), $query as xs:string*){
 if(string-length($query) lt 1) then () else
  let $homophones:='true'
  let $query-string := 
     if ($query != '') 
        then (if($homophones='true') 
              then 
                if(contains($query, 'AND')) then 
                        (let $parts:= for $qpart in tokenize($query, 'AND') 
                         return all:substitutionsInQuery($qpart) return '(' || string-join($parts, ') AND (')) || ')'
                else if(contains($query, 'OR')) then 
                        (let $parts:= for $qpart in tokenize($query, 'OR') return all:substitutionsInQuery($qpart) 
                        return '(' || string-join($parts, ') OR (')) || ')'
                else all:substitutionsInQuery($query) 
        else $query)  
     else ()
  
  let $populatefacets := for $parm in $app:params[ends-with(.,'-facet')] 
                        let $key := substring-before($parm, '-facet')
                        let $values := request:get-parameter($parm, ())
                        return map {$key : ($values)}
  let $options := map:merge($populatefacets)
  let $allopts := map {
        'default-operator': 'or',
        'phrase-slop' : '0',
        'leading-wildcard' :'yes',
        'filter-rewrite': 'yes',
        'facets': $options}
  let $queryExpr := '//t:TEI[descendant::t:change[contains(., "complete")]][ft:query(., (), $allopts)]'
  let $hits := $exptit:col//t:TEI[ft:query(., $query-string, $allopts)]
  return
      map {
          "hits" : $hits,
          "q" : $query,
          "type" : 'matches',
          "query" : $queryExpr}  
};

declare function app:showFacets($node as node()*, $model as map(*)){
    
let $subsequence := $model('hits')
let $itemtype:=$app:facets[. eq 'type']
let $general:=$app:facets[parent::xconf:facet[not(@if)][not(@dimension eq 'type')]]
let $mss:=$app:facets[parent::xconf:facet[contains(@if, 'mss')]]
let $works:=$app:facets[parent::xconf:facet[contains(@if, 'work')]]
let $places:=$app:facets[parent::xconf:facet[contains(@if, 'place')]]
let $persons:=$app:facets[parent::xconf:facet[contains(@if, 'pers')]]
return
    <form id="facetsSearch" action="" class="w3-container w3-center">
    <div class="w3-row w3-left-align">
    <button type="submit" class="w3-button w3-block w3-left-align w3-red">refine search results <i class="fa fa-search"></i></button>
    <input name="query" value="{request:get-parameter('query', ())}" hidden="hidden"/>
    </div>
     {app:facetGroup($itemtype, 'Resource type', $subsequence)}
    {app:facetGroup($general, 'General', $subsequence)}
    {app:facetGroup($mss, 'Manuscripts', $subsequence)}
    {app:facetGroup($works, 'Textual and Narrative Units', $subsequence)}
    {app:facetGroup($places, 'Places and Repositories', $subsequence)}
    {app:facetGroup($persons, 'Persons and Groups', $subsequence)}
    <div class="w3-row w3-left-align">
    <button type="submit" class="w3-button w3-block w3-left-align w3-red">refine search results <i class="fa fa-search"></i></button>
    </div>
    </form>
};

declare function app:facetGroup($group, $groupname, $subsequence){
    <div>
    <div class="w3-row w3-left-align w3-margin-top"><b>{$groupname}</b></div>
        {
for $f in $group
let $facetTitle := app:facetName($f)
let $facets := ft:facets($subsequence, string($f), ())
order by $facetTitle
return
    app:facetDiv ($f, $facets, $facetTitle)
    }</div>
};

declare function app:facetDiv ($f, $facets, $facetTitle){
    if(map:size($facets) = 0) then () else 
    <div class="w3-row w3-left-align">
    <button type="button" 
            onclick="openAccordion('{string($f)}-facet-list')" 
            class="w3-button w3-block w3-left-align w3-gray">{
                $facetTitle
            }</button>
    <div
        class="w3-padding w3-hide" 
        id="{string($f)}-facet-list">
        {
(:        line0 on slack suggested 
map:keys($map) => sort() => for-each(function ($key) {
   let $value := $map($key)
   (: do something with $key and $value :)
   return $value
})
however this here cannot work, because the values are not the ones to be displayed directly.
if and when the import module function will work and enable 
to store in the index the titles, then this will be much better solution
:)
    let $inputs :=map:for-each($facets, function($label, $count) {
            <span><input 
            class="w3-check w3-margin-right" 
            type="checkbox" 
            name="{string($f)}-facet" 
            value="{$label}"/>
         {   if ($f = 'witness') 
                then exptit:printTitleID($label)
            else if($f= 'changeWho') then editors:editorKey($label)
            else if($f = 'languages') then $app:languages//t:item[@xml:id eq $label]/text()
            else $label}
            <span class="w3-badge w3-margin-left">{$count}</span><br/></span>        })
         return
         if($f='keywords') then
          (   for $input in $inputs
             let $val := $input/*:input/@value
             let $taxonomy := $app:tax//t:catDesc[. eq $val]/ancestor::t:category[t:desc][1]/t:desc/text()
             group by $taxonomy
             order by $taxonomy
             return 
            <div class="w3-row w3-left-align">
    <button type="button" 
            onclick="openAccordion('{string($f)}-{replace($taxonomy, ' ','')}-facet-sublist')" 
            class="w3-button w3-block w3-left-align w3-gray">
                {$taxonomy}
            </button>
    <div
        class="w3-padding w3-hide" 
        id="{string($f)}-{replace($taxonomy, ' ','')}-facet-sublist">{
             for $i in $input
        let $sortkey := app:sortingkey($i)
        order by $sortkey
        return
        $i/node()}</div></div>)
        else if($f='changeWhen') then
          (   for $input in $inputs
             let $val := $input/*:input/@value
             let $taxonomy := substring-before($val,'-')
             group by $taxonomy
             order by xs:gYear($taxonomy) descending
             return 
            <div class="w3-row w3-left-align">
    <button type="button" 
            onclick="openAccordion('{string($f)}-{replace($taxonomy, ' ','')}-facet-sublist')" 
            class="w3-button w3-block w3-left-align w3-gray">
                {$taxonomy}
            </button>
    <div
        class="w3-padding w3-hide" 
        id="{string($f)}-{replace($taxonomy, ' ','')}-facet-sublist">{
             for $i in $input
        let $sortkey := app:sortingkey($i)
        order by $sortkey
        return
        $i/node()}</div></div>)
        else if($f='titleRef') then
          (   for $input in $inputs
              let $sortkey := app:sortingkey($input)
              let $first := substring($sortkey, 1, 1)
             group by $first
             order by $first
             return 
            <div class="w3-row w3-left-align">
    <button type="button" 
            onclick="openAccordion('{string($f)}-{$first}-facet-sublist')" 
            class="w3-button w3-block w3-left-align w3-gray">
                {upper-case($first)}
            </button>
    <div
        class="w3-padding w3-hide" 
        id="{string($f)}-{$first}-facet-sublist">{
             for $i in $input
        let $sortkey := app:sortingkey($i)
        order by $sortkey
        return
        $i/node()}</div></div>)
            else 
       ( for $input in $inputs
        let $sortkey := app:sortingkey($input)
        order by $sortkey
        return
        $input/node()
        )
        }
    </div>
    </div>
};

declare function app:sortingkey($input){ string-join($input//text())
             => replace('ʾ', '')
             =>replace('ʿ','')
             =>replace('\s','')
             =>translate('ƎḤḪŚṢṣḫḥǝʷāṖ','EHHSSshhewaP') 
             => lower-case()};
declare function app:facetName($f){
    switch($f)
                case 'keywords' return 'Keywords'
                case 'languages' return 'Languages'
                case 'changeWho' return 'Author of changes'
                case 'changeWhen' return 'Date of changes'
                case 'script' return 'Script'
                case 'condition' return 'Condition'
                case 'form' return 'Form'
                case 'material' return 'Material'
                case 'height' return 'Height'
                case 'width' return 'Width'
                case 'depth' return 'Depth'
                case 'scribe' return 'Scribe'
                case 'donor' return 'Donor'
                case 'msItemsCount' return 'N. of content units'
                case 'msPartsCount' return 'N. of Codicological Units'
                case 'handsCount' return 'N. of Hands'
                case 'sealCount' return 'N. of Seals'
                case 'QuireCount' return 'N. of Quires'
                case 'AdditionsCount' return 'N. of Additions'
                case 'AdditionsType' return 'Types of Addition'
                case 'titleRef' return 'Contents'
                case 'titleType' return 'Complete/Incomplete contents'
                case 'ExtraCount' return 'N. of Extras'
                case 'ExtraType' return 'Types of Extra'
                case 'leafs' return 'N. of leaves'
                case 'origDateNotBefore' return 'Date of production (not before)'
                case 'origDateNotAfter' return 'Date of production (not after)'
                case 'origplace' return 'Place of origin'
                case 'repository' return 'Repository'
                case 'collection' return 'Collection'
                case 'rulingpattern' return 'Ruling Pattern'
                case 'artThemes' return 'Art Themes (in decorations)'
                case 'artkeywords' return 'Art Keywords (in decorations)'
                case 'bindingkeywords' return 'Keywords (in binding)'
                case 'rubricationkeywords' return 'Keywords (in rubrication)'
                case 'decoType' return 'Type of Decoration'
                case 'calendarType' return 'Type of calendar used'
                case 'images' return 'Images Availability'
                case 'writtenLines' return 'Written Lines'
                case 'columns' return 'Columns'
                case 'authors' return 'Authors'
                case 'textDivs' return 'Text parts'
                case 'sawsVersionOf' return 'Versions'
                case 'sex' return 'Gender'
                case 'name' return 'Personal Name in language'
                case 'group' return 'Group'
                case 'faith' return 'Faith'
                case 'sameAs' return 'Alignment'
                case 'personSameAs' return 'Alignment'
                case 'placetype' return 'Type of place'
                case 'settlement' return 'Settlement'
                case 'region' return 'Region'
                case 'country' return 'Country'
                case 'witness' return 'Witnesses'
                case 'thereistext' return 'Text'
                case 'thereistranscription' return 'Transcription'
                case 'reltype' return 'Relation Names'
                case 'bindingMaterial' return 'Binding Material'
                case 'tabot' return 'Tābots'
                case 'occupation' return 'Occupation Type'
                default return 'Item type'
};
(:~
    Execute the query. The search results are not output immediately. Instead they
    are passed to nested templates through the $model parameter.
:)
declare 
    %templates:default("scope", "narrow")
    %templates:default("work-types", "all")
    %templates:default("target-ms", "all")
    %templates:default("target-work", "all")
    %templates:default("homophones", "true")
%templates:default("numberOfParts", "")
    %templates:default("element",  "TEI")
function app:query(
$node as node()*, 
$model as map(*), 
$query as xs:string*, 
$numberOfParts as xs:string*, 
    $work-types as xs:string+,
    $element as xs:string+,
    $target-ms as xs:string+,
    $target-work as xs:string+,
    $homophones as xs:string+   ) {
    let $homophones :=request:get-parameter('homophones', ())
  
   let $paramstobelogged := for $p in $app:params for $value in request:get-parameter($p, ()) return ($p || '=' || $value)
   let $logparams := '?' || string-join($paramstobelogged, '&amp;')
   let $log := log:add-log-message($logparams, sm:id()//sm:real/sm:username/string() , 'query')
    let $IDpart := app:ListQueryParam('xmlid', '@xml:id', 'any', 'search')
    let $collection := app:ListQueryParam('work-types', '@type', 'any', 'search')
    let $script := app:ListQueryParam('script', 't:handNote/@script', 'any', 'search')
    let $mss := app:ListQueryParam('target-ms', '@xml:id', 'any', 'search')
    let $texts := app:ListQueryParam('target-work', '@xml:id', 'any', 'search')
    let $support := app:ListQueryParam('support', 't:objectDesc/@form', 'any', 'search')
    let $material := app:ListQueryParam('material', 't:support/t:material/@key', 'any', 'search')
    let $bmaterial := app:ListQueryParam('bmaterial', "t:decoNote[@type eq 'bindingMaterial']/t:material/@key", 'any', 'search')
    let $placeType := app:ListQueryParam('placeType', 't:place/@type', 'any', 'search') 
    let $personType := app:ListQueryParam('persType', 't:person//t:occupation/@type', 'any', 'search')
    let $relationType := app:ListQueryParam('relType', 't:relation/@name', 'any', 'search')
    let $repository := app:ListQueryParam('target-ins', 't:repository/@ref ', 'any', 'search')
    let $keyword := app:ListQueryParam('keyword', 't:term/@key ', 'any', 'search')
    let $languages := app:ListQueryParam('language', 't:language/@ident', 'any', 'search')
let $scribes := app:ListQueryParam('scribe', "t:persName[@role eq 'scribe']/@ref", 'any',  'search')
let $donors := app:ListQueryParam('donor', "t:persName[@role eq 'donor']/@ref", 'any',  'search')
let $patrons := app:ListQueryParam('patron', "t:persName[@role eq 'patron']/@ref", 'any', 'search')
let $owners := app:ListQueryParam('owner', "t:persName[@role eq 'owner']/@ref", 'any',  'search')
let $parchmentMakers := app:ListQueryParam('parchmentMaker', "t:persName[@role eq 'parchmentMaker']/@ref", 'any',  'search')
let $binders := app:ListQueryParam('binder', "t:persName[@role eq 'binder']/@ref", 'any',  'search')
let $contents := app:ListQueryParam('content', "t:title/@ref", 'any', 'search')
let $wits := app:ListQueryParam('ms', "t:witness/@corresp", 'any', 'search')
let $authors := app:ListQueryParam('author', "t:relation[@name eq 'saws:isAttributedToAuthor']/@passive", 'any', 'search')
(:let $authorsCertain := app:ListQueryParam('author', "t:relation[@name='dcterms:creator']/@passive", 'any', 'search'):)
let $tabots := app:ListQueryParam('tabot', "t:ab[@type eq 'tabot']/t:*/(@ref|@corresp)", 'any', 'search')
let $references := if (contains($app:params, 'references')) then let $refs := for $ref in tokenize(request:get-parameter('references', ()), ',') return "[descendant::t:*/@*[not(name() eq 'xml:id')] ='"  ||$ref || "' ]" return string-join($refs, '') else ()
let $genders := if (contains($app:params, 'gender')) then '[descendant::t:person/@sex  eq '  ||request:get-parameter('gender', ()) || ' ]' else ()
let $leaves :=  if (contains($app:params, 'folia')) 
                then (
                let $range := request:get-parameter('folia', ())
                let $min := substring-before($range, ',') 
                let $max := substring-after($range, ',') 
                return
                if ($range = '1,1000')
                then ()
                else if (empty($range))
                then ()
                else
                "[descendant::t:extent/t:measure[@unit eq 'leaf'][not(@type)][matches(.,'^\d+$')][xs:integer(.) ge "||$min|| ' ][ xs:integer(.)  le ' || $max ||"]]"
               ) else ()
let $wL :=  if (contains($app:params, 'wL')) 
                then (
                let $range := request:get-parameter('wL', ())
                let $min := substring-before($range, ',') 
                let $max := substring-after($range, ',') 
                return
                if ($range = '1,1000')
                then ()
                else if (empty($range))
                then ()
                else
                "[descendant::t:layout[@writtenLines ge "||$min|| '][@writtenLines  le ' || $max ||"]]"
               ) else ()
let $quires :=  if (contains($app:params, 'qn')) 
                then (
                let $range := request:get-parameter('qn', ())
                return
                 if ($range = '1,100')
                then ()
                else
                app:paramrange('qn', "extent/t:measure[@unit eq 'quire'][not(@type)][matches(.,'^\d+$')]")
               ) else ()
let $quiresComp :=  if (contains($app:params, 'qcn')) 
                then (
                let $range := request:get-parameter('qcn', ())
                return
                 if ($range = '1,40')
                then ()
                else
                app:paramrange('qcn', "collation//t:dim[@unit eq 'leaf']")
               ) else ()
let $dateRange := 
                if (contains($app:params, 'dataRange')) 
                then (
                let $range := request:get-parameter('dateRange', ())
                let $from := substring-before($range, ',') 
                let $to := substring-after($range, ',') 
                return
                if ($range = '0,2000')
                then ()
                else if ($range = '')
                then ()
                else
                "[descendant::t:*[(if 
(contains(@notBefore, '-')) 
then (substring-before(@notBefore, '-')) 
else @notBefore)[. !=''][. ge " || $from || '][.  le ' || $to || "] 

or 
(if (contains(@notAfter, '-')) 
then (substring-before(@notAfter, '-')) 
else @notAfter)[. !=''][. ge " || $from || '][.  le ' || $to || '] 

]
]' ) else ()
   let $height :=   if (contains($app:params, 'height')) then (app:paramrange('height', 'height')) else ()
   let $width :=  if (contains($app:params, 'width')) then (app:paramrange('width', 'width')) else ()
   let $depth :=  if (contains($app:params, 'depth')) then (app:paramrange('depth', 'depth')) else ()
   let $marginTop :=  if (contains($app:params, 'tmargin')) then (app:paramrange('tmargin', "dimension[@type eq 'margin']/t:dim[@type eq 'top']")) else ()
   let $marginBot :=  if (contains($app:params, 'bmargin')) then (app:paramrange('tmargin', "dimension[@type eq 'margin']/t:dim[@type eq 'bottom']")) else ()
   let $marginR :=  if (contains($app:params, 'rmargin')) then (app:paramrange('tmargin', "dimension[@type eq 'margin']/t:dim[@type eq 'right']")) else ()
   let $marginL :=  if (contains($app:params, 'lmargin')) then (app:paramrange('tmargin', "dimension[@type eq 'margin']/t:dim[@type eq 'left']")) else ()
   let $marginIntercolumn :=  if (contains($app:params, 'intercolumn')) then (app:paramrange('intercolumn', "dimension[@type eq 'margin']/t:dim[@type eq 'intercolumn']")) else ()
                            
let $query-string := if ($query != '') 
                                        then (
                                                                       if($homophones='true') 
                                                                       then 
                                                                                if(contains($query, 'AND')) then 
                                                                                (let $parts:= for $qpart in tokenize($query, 'AND') 
                                                                                return all:substitutionsInQuery($qpart) return 
                                                                                '(' || string-join($parts, ') AND (')) || ')'
                                                                                else if(contains($query, 'OR')) then 
                                                                                (let $parts:= for $qpart in tokenize($query, 'OR') 
                                                                                return all:substitutionsInQuery($qpart) return 
                                                                                '(' || string-join($parts, ') OR (')) || ')'
                                                                                else all:substitutionsInQuery($query) 
                                                                       else $query)  
                                        else ()

let $eachworktype := for $wtype in request:get-parameter('work-types', ()) 
                                   return  "@type='"|| $wtype || "'" || (
(:                                   in case there is only one collection parameter selected and this is equal to place, search also institutions :)
                                   if(count(request:get-parameter('work-types', ())) eq 1 and request:get-parameter('work-types', ()) = 'place' ) then ("or @type='ins'")   else '')
        
let $wt := if(contains($app:params, 'work-types')) then "[" || string-join($eachworktype, ' or ') || "]" else ()
let $nOfP := if(empty($numberOfParts) or $numberOfParts = '') then () else '[count(descendant::t:msPart) ge ' || $numberOfParts || ']'


let $allfilters := concat($IDpart, $wt, $repository, $mss, $texts, $script, $support, 
             $material, $bmaterial, $placeType, $personType, $relationType, 
             $keyword, $languages, $scribes, $donors, $patrons, $owners, $parchmentMakers, 
             $binders, $contents, $authors, $tabots, $genders, $dateRange, $leaves, $wL,  $quires, $quiresComp,
             $references, $height, $width, $depth, $marginTop, $marginBot, $marginL, $marginR, $marginIntercolumn)
         
(:         the evalutaion of the entire string for the query makes it impossible to use range indexes in a proper way,
the same for the elements evaluated with the OR operator in one argument for the path.
this should update the query results for each parameter, updating the variable step by step
for the elements to be searched it should search one by one AFTER applying the filters, so only in the items filter out and then 
union the sequences of results and remove the doubles from the union
:)
    
let $queryExpr := $query-string
    return
        if (empty($queryExpr) or $queryExpr = "") then
          (if(empty($app:params)) then () else ( let $hits := 
             let $path := 
             concat("$exptit:col","//t:TEI", 
             $allfilters, $nOfP)
                   for $hit in util:eval($path)
                   return $hit
                 
            
            return
                map {
                    "hits" : $hits,
                    "type" : 'records'
                    
                } ))
        else
          
          let $hits :=

                 let $elements : =
                   for $e in $element
                   return 
                   app:BuildSearchQuery($e, $query-string)
                   
                   let $allels := string-join($elements, ' or ')
                   let $path:=    concat("$exptit:col","//t:TEI[",$allels, "]", $allfilters)
                   let $log := util:log('info', $path)
                   let $logpath := log:add-log-message($path, sm:id()//sm:real/sm:username/string() , 'XPath')  
                   let $hits := util:eval($path)
                   for $hit in $hits
                    order by ft:score($hit) descending
                    return $hit
                    
              
            
        let $store := (
                session:set-attribute("apps.BetMas", $hits),
                session:set-attribute("apps.BetMas.query", $queryExpr)
            )
       
            return
                (: Process nested templates :)
              map {
                    "hits" : $hits,
                    "q" : $query,
                    "type" : 'matches',
                    "query" : $queryExpr
                }
};



(:~
    Helper function: create a lucene query from the user input
:)
declare function app:create-query($query-string as xs:string?, $mode as xs:string) {
    let $query-string := 
        if ($query-string) 
        then app:sanitize-lucene-query($query-string) 
        else ''
    let $query-string := normalize-space($query-string)
   let $query-string := if(contains($query-string, 's')) then let $options := replace($query-string, 's', 'ḍ')  return ($query-string || ' ' || $options)  else $query-string
    let $query-string := if(contains($query-string, 'e')) then let $options := (replace($query-string, 'e', 'ǝ'),replace($query-string, 'e', 'ē'))  return ($query-string || ' ' || string-join($options, ' '))  else $query-string
   
    (:Remove/ignore ayn and alef :)
    let $query-string := if(contains($query-string, 'ʾ')) then let $options := replace($query-string, "ʾ", "")  return ($query-string || ' ' || string-join($options, ' '))  else $query-string
   let $query-string := if(contains($query-string, 'ʿ')) then let $options := replace($query-string, "ʿ", "")  return ($query-string || ' ' || string-join($options, ' '))  else $query-string
    
   let $query:=
        (:If the query contains any operator used in sandard lucene searches or regex searches, pass it on to the query parser;:) 
        if (functx:contains-any-of($query-string, ('AND', 'OR', 'NOT', '+', '-', '!', '~', '^', '.', '?', '*', '|', '{','[', '(', '<', '@', '#', '&amp;')) and $mode eq 'any')
        then 
            let $luceneParse := app:parse-lucene($query-string)
            let $luceneXML := parse-xml($query-string)
            let $lucene2xml := app:lucene2xml($luceneXML/node(), $mode)
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
declare function app:hit-count($node as node()*, $model as map(*)) {
<div class="w3-panel w3-card-4">{
    if ($model('type') = 'bibliography') then <h3>There are <span xmlns="http://www.w3.org/1999/xhtml"  class="w3-tag w3-gray" id="hit-count">{ count($model("hits")) }</span> distinct bibliographical references</h3> else if ($model('type') = 'matches') then <h3>You found <span class="w3-tag w3-gray">{$app:searchphrase}</span> in <span xmlns="http://www.w3.org/1999/xhtml" id="hit-count" class="w3-tag w3-gray">{ count($model("hits")) }</span> results</h3> else (<h3> There are <span xmlns="http://www.w3.org/1999/xhtml" id="hit-count"  class="w3-tag w3-gray">{ count($model("hits")) }</span> entities matching your query. </h3>)
    }</div>
};

declare function app:hit-params($node as node()*, $model as map(*)) {
    <div>{
                    for $param in distinct-values($app:params)
                    let $values := request:get-parameter($param, ())
                   return if (count($values) = 2 and ( (string-join($values,',') != '0,2000') or (string-join($values) = '' ) )) 
                     then (<span class="w3-tag w3-gray w3-round ">{$param}{' between ', <span class="w3-badge">{$values[1]}</span>, ' and ', <span class="w3-badge">{$values[2]}</span>}</span>)
                    else for $value in $values
                    return
                    if ($value = '') then ()
                    else if ($param = 'start') then ()
                    else if ($param = 'query') then ()
                    else if (ends-with($param, '-operator-field')) then ()
                    else 
                        <span 
                        class="w3-tag w3-gray w3-round ">
                        {($param || ": ", 
                        <span class="w3-badge">{$value}</span>)}</span>
                }</div>
};

declare function app:gotoadvanced($node as node()*, $model as map(*)){
let $query := request:get-parameter('query', ())
return 
<div class="w3-bar">
<a href="/newSearch.html?query={$query}" class="w3-button w3-red w3-margin w3-bar-item">Repeat search in the New Search.</a>
</div>
};

declare function app:list-count($node as node()*, $model as map(*)) {
    <h3>{$app:collection || ' '}{string-join(
                    for $param in $app:params
                    for $value in request:get-parameter($param, ())
                    return
                    if ($param = 'start') then ()
                    else if ($param = 'collection') then ()
                    else if ($param = 'dateRange') then ('between ' || substring-before(request:get-parameter('dateRange', ()), ',') || ' and ' || substring-after(request:get-parameter('dateRange', ()), ','))
                    else
                        $param || ": " || $value, ", " 
                )}: <span xmlns="http://www.w3.org/1999/xhtml" id="hit-count">{ count($model("hits")) }</span></h3>
};


(:~
 : FROM SHAKESPEAR
 : Create a bootstrap pagination element to navigate through the hits.
 :)
 
 declare
    %templates:wrap
    %templates:default('start', 1)
    %templates:default("per-page", 20)
    %templates:default("min-hits", 0)
    %templates:default("max-pages", 20)
function app:paginate($node as node(), $model as map(*), $start as xs:int, $per-page as xs:int, $min-hits as xs:int,
    $max-pages as xs:int) {
        
    if ($min-hits < 0 or count($model("hits")) >= $min-hits) then
        let $types := if($model("type") = 'bibliography' or $model("type") = 'indexes')
        then(count($model("hits"))) 
        else
        for $x in $model("hits") 
                                  group by $t := root($x)/t:TEI/@type 
                                return 
                                count($x)
        let $count := xs:integer(ceiling(max($types)) div $per-page) + 1
        let $middle := ($max-pages + 1) idiv 2
        let $params :=
                string-join(
                    for $param in $app:params
                    for $value in request:get-parameter($param, ())
                    return
                    if ($param = 'start') then ()
                    else if ($param = 'collection') then ()
                    else
                        $param || "=" || $value,
                    "&amp;"
                )
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
                    <a href="?{$params}&amp;start=1"><i class="glyphicon glyphicon-fast-backward"/></a>
                </li>,
                <li>
                    <a href="?{$params}&amp;start={max( ($start - $per-page, 1 ) ) }"><i class="glyphicon glyphicon-backward"/></a>
                </li>
            ),
            let $startPage := xs:integer(ceiling($start div $per-page))
            let $lowerBound := max(($startPage - ($max-pages idiv 2), 1))
            let $upperBound := min(($lowerBound + $max-pages - 1, $count))
            let $lowerBound := max(($upperBound - $max-pages + 1, 1))
            for $i in $lowerBound to $upperBound
            return
                if ($i = ceiling($start div $per-page)) then
                    <li class="active"><a href="?{$params}&amp;start={max( (($i - 1) * $per-page + 1, 1) )}">{$i}</a></li>
                else
                    <li><a href="?{$params}&amp;start={max( (($i - 1) * $per-page + 1, 1)) }">{$i}</a></li>,
            if ($start + $per-page < count($model("hits"))) then (
                <li>
                    <a href="?{$params}&amp;start={$start + $per-page}"><i class="glyphicon glyphicon-forward"/></a>
                </li>,
                <li>
                    <a href="?{$params}&amp;start={max( (($count - 1) * $per-page + 1, 1))}"><i class="glyphicon glyphicon-fast-forward"/></a>
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



declare
    %templates:wrap
    %templates:default('start', 1)
    %templates:default("per-page", 20)
    %templates:default("min-hits", 0)
    %templates:default("max-pages", 20)
function app:paginateNew($node as node(), $model as map(*), $start as xs:int, $per-page as xs:int, $min-hits as xs:int,
    $max-pages as xs:int) {
        
    if ($min-hits < 0 or count($model("hits")) >= $min-hits) then
        let $types := if($model("type") = 'bibliography' or $model("type") = 'indexes')
        then(count($model("hits"))) 
        else
        for $x in $model("hits") 
                                  group by $t := root($x)/t:TEI/@type 
                                return 
                                count($x)
        let $count := xs:integer(ceiling(max($types)) div $per-page) + 1
        let $middle := ($max-pages + 1) idiv 2
        let $params :=
                string-join(
                    for $param in $app:params
                    for $value in request:get-parameter($param, ())
                    return
                    if ($param = 'start') then ()
                    else if ($param = 'collection') then ()
                    else
                        $param || "=" || $value,
                    "&amp;"
                )
        return (
        
        (:           backwarding arrows, disabled if not available:)
            if ($start = 1) then (
                    <a class="w3-button w3-disabled"><i class="fa fa-fast-backward"></i></a>,
               
                    <a class="w3-button w3-disabled"><i class="fa fa-backward"></i></a>
                
            ) else (
                    <a href="?{$params}&amp;start=1" class="w3-button "><i class="fa fa-fast-backward"></i></a>
                ,
                    <a href="?{$params}&amp;start={max( ($start - $per-page, 1 ) ) }" class="w3-button "><i class="fa fa-backward"></i></a>
                
            ),
            
(:            numbers:)
            let $startPage := xs:integer(ceiling($start div $per-page))
            let $lowerBound := max(($startPage - ($max-pages idiv 2), 1))
            let $upperBound := min(($lowerBound + $max-pages - 1, $count))
            let $lowerBound := max(($upperBound - $max-pages + 1, 1))
            for $i in $lowerBound to $upperBound
            return
                if ($i = ceiling($start div $per-page)) then
                    <a class="w3-button" href="?{$params}&amp;start={max( (($i - 1) * $per-page + 1, 1) )}">{$i}</a>
                else
                    <a class="w3-button" href="?{$params}&amp;start={max( (($i - 1) * $per-page + 1, 1)) }">{$i}</a>,
           
           
           
(:           forwarding arrows, disabled if not available:)
           if ($start + $per-page < count($model("hits"))) then (
                
                    <a  class="w3-button" href="?{$params}&amp;start={$start + $per-page}"><i class="fa fa-forward"></i></a>
                ,
                    <a  class="w3-button" href="?{$params}&amp;start={max( (($count - 1) * $per-page + 1, 1))}"><i class="fa fa-fast-forward"></i></a>
                
            ) else (
                <a class="w3-button w3-disabled"><i class="fa fa-forward"></i></a>,
                <a class="w3-button w3-disabled"><i class="fa fa-fast-forward"></i></a>
            )
        ) else
            ()
};


declare    
%templates:wrap
%templates:default('start', 1)
%templates:default("per-page", 40)
function app:facetSearchRes ( $node as node()*,  $model as map(*), $start as xs:integer,  $per-page as xs:integer) {
        <div class="w3-row w3-border-bottom w3-margin-bottom w3-gray">
              <div class="w3-third">
              <div class="w3-col" style="width:15%">
                <span class="number">score</span>
              </div>
              <div class="w3-col"  style="width:70%">
               title
              </div>
              <div class="w3-col"  style="width:15%">
                hits count
              </div>
            </div>
            <div class="w3-twothird">
                 <div class="w3-twothird">first three keywords in context</div>
                 <div class="w3-third">item-type specific options</div>
            </div>
            </div>,
        for $text at $p in subsequence($model('hits'), $start, $per-page)
        let $queryText := request:get-parameter('query', ())
        
            let $expanded := kwic:expand($text)
            let $firstancestorwithID:=($expanded//exist:match/(ancestor::t:*[(@xml:id|@n)] | ancestor::t:text))[last()]
      let $test := console:log($firstancestorwithID)
      let $firstancestorwithIDid := $firstancestorwithID/string(@xml:id)
        let $view := if($firstancestorwithID[ancestor-or-self::t:text]) then 'text' else 'main'
         let $firstancestorwithIDanchor := if($view = 'main') then '#' || $firstancestorwithIDid else ()
        
            let $count := count($expanded//exist:match)
            let $root := root($text)
            let $item := $root/t:TEI
            let $t := $root/t:TEI/@type
            let $id := data($root/t:TEI/@xml:id)
            let $collection := switch2:col($t)
        let $score as xs:float := ft:score($text)
        let $tokvalues := for $tokenInQuery in tokenize($queryText, '\s') 
                            return if ($text[contains(., $tokenInQuery)]) then 5 else 0
      let $values := sum($tokvalues)
        let $enrichedScore := 
                            $score + 
                            $values +
                            (count($text//node()) div 100) + 
                            ( if($text//t:ab[node()]) then 4 
                            else if($text//t:occupation) then 2 
                                else if ($text/ancestor::t:TEI//t:change[contains(.,'complete')]) then 1 else ())
        order by $enrichedScore descending
             return
            <div class="w3-row w3-border-bottom w3-margin-bottom">
              <div class="w3-third">
              <div class="w3-col" style="width:15%">
                <span class="w3-tag w3-red">{$enrichedScore}</span>
                <span class="w3-tag w3-red">{
                if ($item//t:change[contains(., 'complete')]) then
                        (attribute style {'background-color:rgb(172, 169, 166, 0.4)'},
                        'complete')
                    else
                        if ($item//t:change[contains(., 'review')]) then
                            (attribute style {'background-color:white'},
                            'reviewed')
                        else
                            (attribute style {'background-color:rgb(213, 75, 10, 0.4)'},
                            'stub')}
                 </span>
              </div>
              <div class="w3-col"  style="width:70%">
              <span class="w3-tag w3-gray">{$collection}</span>
              <span class="w3-tag w3-gray" style="word-break: break-all; text-align: left;">{$id}</span>
              <span class="w3-tag w3-red"><a href="{('/tei/' || $id || '.xml')}" target="_blank">TEI</a></span>
             <!-- <span class="w3-tag w3-red"><a href="/{$id}.pdf" target="_blank" >PDF</a></span><br/>-->
               <a target="_blank" href="/{$collection}/{$id}/main"><b>{if(starts-with($id, 'corpus')) then $root//t:titleStmt/t:title[1]/text() else try{exptit:printTitleID($id)} catch *{console:log(($text, $id, $err:description))}}</b></a><br/>
               {if ($item//t:facsimile/t:graphic/@url) 
               then <a target="_blank" href="{$item//t:facsimile/t:graphic/@url}">Link to images</a> 
               else if($item//t:msIdentifier/t:idno[@facs][@n]) then 
                 <a target="_blank" href="/manuscripts/{$id}/viewer">{
                if($item//t:collection = 'Ethio-SPaRe') 
               then <img src="{$config:appUrl ||'/iiif/' || string(($item//t:msIdentifier)[1]/t:idno/@facs) || '_001.tif/full/140,/0/default.jpg'}" class="thumb w3-image"/>
(:laurenziana:)
else  if($item//t:repository[@ref eq 'INS0339BML']) 
               then <img src="{$config:appUrl ||'/iiif/' || string($item//t:msIdentifier/t:idno/@facs) || '005.tif/full/140,/0/default.jpg'}" class="thumb w3-image"/>
          
(:          
EMIP:)
              else if(($item//t:collection = 'EMIP') and $item//t:msIdentifier/t:idno/@n) 
               then <img src="{$config:appUrl ||'/iiif/' || string(($item//t:msIdentifier)[1]/t:idno/@facs) || '001.tif/full/140,/0/default.jpg'}" class="thumb w3-image"/>
              
             (:BNF:)
            else if (($item//t:repository/@ref)[1]  eq 'INS0303BNF') 
            then <img src="{replace($item//t:msIdentifier/t:idno/@facs, 'ark:', 'iiif/ark:') || '/f1/full/140,/0/native.jpg'}" class="thumb w3-image"/>
(:           vatican :)
                else if (contains($item//t:msIdentifier/t:idno/@facs, 'digi.vat')) then <img src="{replace(substring-before($item//t:msIdentifier/t:idno/@facs, '/manifest.json'), 'iiif', 'pub/digit') || '/thumb/'
                    ||
                    substring-before(substring-after($item//t:msIdentifier/t:idno/@facs, 'MSS_'), '/manifest.json') || 
                    '_0001.tif.jpg'
                }" class="thumb w3-image"/>
(:                bodleian:)
else if (contains($item//t:msIdentifier/t:idno/@facs, 'bodleian')) then ('images')
          else (<img src="{$config:appUrl ||'/iiif/' || string($item//t:msIdentifier/t:idno[not(starts-with(@facs, 'https'))][1]/@facs) ||  (if(starts-with($item//t:collection, 'Ethio')) then '_' else())||'001.tif/full/140,/0/default.jpg'}" class="thumb w3-image"/>)
                       }</a>
                
                else ()}
                {if($collection = 'works') then apptable:clavisIds($root) else ()}
              </div>
              <div class="w3-col"  style="width:15%">
                <span class="w3-badge">{$count}</span>
                in {for $match in config:distinct-values($expanded//exist:match/parent::t:*/name()) return (<code>{string($match)}</code>,<br/>) }
              </div>
            </div>
            <div class="w3-twothird">
                 <div class="w3-twothird">{
                     for $match in subsequence($expanded//exist:match, 1, 3) 
                      let $matchancestorwithID:=($match/(ancestor::t:*[(@xml:id|@n)] | ancestor::t:text))[last()]
      let $matchancestorwithIDid := $matchancestorwithID/string(@xml:id)
        let $view := if($matchancestorwithID[ancestor-or-self::t:text]) then 'text' else 'main'
         let $matchancestorwithIDanchor := if($view = 'main') then '#' || $matchancestorwithIDid else ()
        
                     return  
                      let $matchref := replace(app:refname($match), '.$', '')
                let $ref := if($view = 'text' and $matchref !='') then '&amp;ref=' || $matchref else ()
                return 
               <div class="w3-row w3-padding"><div class="w3-twothird w3-padding match">
                   {  kwic:get-summary($match/parent::node(), $match,<config width="40"/>)}
                     </div>
                        <div class="w3-third w3-padding">
                        <a href="/{$collection}/{$id}/{$view}{$matchancestorwithIDanchor}?hi={$queryText}{$ref}">
                        {' in element ' ||$match/parent::t:*/name() || ' within a ' ||
                        $matchancestorwithID/name() 
                        || 
                       (if($view = 'text'  and $matchref !='') 
                                then ', at ' || $matchref 
                       else if($view = 'main') 
                                then ', with id ' || $matchancestorwithIDid 
                        else ())
                        }</a>
                        </div>
                        </div>
                 }</div>
                 <div class="w3-third">
                     {switch($t)
                        case 'mss' return (
                             <a role="button" class="w3-button w3-small w3-gray" href="/IndexPlaces?entity={$id}">places</a>,
                             <a role="button" class="w3-button w3-small w3-gray" href="/IndexPersons?entity={$id}">persons</a>)
                        case 'pers' return ()
                        case 'ins' return (<a role="button" class="w3-button w3-small w3-gray" href="/manuscripts/{$id}/list">manuscripts</a>)
                        case 'place' return (<a role="button" class="w3-button w3-small w3-gray" href="/manuscripts/place/list?place={$id}">manuscripts</a>)
                        case 'nar' return (<a role="button" class="w3-button w3-small w3-gray" href="/collate">collate</a>)
                        case 'work' return 
                            (<a role="button" class="w3-button w3-small w3-gray" href="/compare?workid={$id}">compare</a>,
                             <a role="button" class="w3-button w3-small w3-gray" href="/workmap?worksid={$id}">map of mss</a>,
                             <a role="button" class="w3-button w3-small w3-gray" href="/collate">collate</a>,
                             <a role="button" class="w3-button w3-small w3-gray" href="/IndexPlaces?entity={$id}">places</a>,
                             <a role="button" class="w3-button w3-small w3-gray" href="/IndexPersons?entity={$id}">persons</a>)
                        default return
                            <a role="button" class="w3-button w3-small w3-gray" href="/authority-files/list?keyword={$id}">with this keyword</a>
                     }
                     <a role="button" class="w3-button w3-small w3-gray" href="/{$collection}/{$id}/analytic">relations</a>
                 </div>
            </div>
            </div>
    };

(:~  copied from  dts: to format and select the references :)
declare function app:refname($n){
(:has to recurs each level of ancestor of the node which 
   has a valid position in the text structure:)
let $refname:=  if ($n[name()='ab'] or $n[name()='match']) then () else app:rn($n)
let $this := normalize-space($refname)
let $ancestors := for $a in $n/ancestor::t:div[@xml:id or @n or @corresp][ancestor::t:div[@type]]
return app:rn($a)
let $all := ($ancestors , $this)
return string-join($all,'.')
};

(:~  copied and adapted from dts and called by app:refname to format 
a single reference starting from a match :)
declare function app:rn($n){
  if ($n[name()='exist:match']) then ()
 else  if ($n/preceding-sibling::t:cb) then 
         (string($n/preceding-sibling::t:pb[@n][1]/@n)||string($n/preceding-sibling::t:cb[@n][1]/@n)) 
 else if ($n/name()='pb' and $n/@corresp) then 
         (string($n/@n) || '[' ||substring-after($n/@corresp, '#')||']') 
    else if($n/@n) then string($n/@n)
    else if($n/@xml:id) then string($n/@xml:id)
    else if($n/@subtype) then string($n/@subtype)
    else  'tei:' ||$n/name() ||'['|| $n/position() || ']'
    };

declare function app:searchResMatches($model, $start, $per-page){
for $text at $p in $model('hits')
        let $root := root($text)
        let $t := $root/t:TEI/@type
        group by $type := $t
        let $collection := switch2:col($type)
        
        return
        <div class="w3-container w3-panel w3-card-2 w3-padding results{$collection}">
        <div class="w3-padding">
        <h4>{count($text)} result{if(count($text) gt 1) then 's' else ''} in {if($collection='institutions') then 'repositories' else $collection}</h4>
        {
        for $tex at $p in subsequence($text, $start, $per-page)
        let $queryText := request:get-parameter('query', ())
         let $root := root($tex)
         let $id := $root/t:TEI/string(@xml:id)
         let $expanded := kwic:expand($tex)
        let $firstancestorwithID:=($expanded//exist:match/(ancestor::t:text|ancestor::t:*[(@xml:id|@n)][not(self::t:TEI)]))[1]
        let $firstancestorwithIDid := if($firstancestorwithID/@xml:id) then $firstancestorwithID/string(@xml:id) else ' without id '
        let $view := if($firstancestorwithID[ancestor-or-self::t:text]) then 'text' else 'main'
         let $firstancestorwithIDanchor := if($view = 'main') then '#' || $firstancestorwithIDid else ()
       let $count := count($expanded//exist:match)
        let $score as xs:float := ft:score($tex)
        return
        
            <div class="w3-row reference">
            <div class="w3-third">
            <div class="w3-col w3-padding" style="width:10%">
                <span class="number">{$start + $p - 1}</span>
                </div>
             <div class="w3-col w3-padding"  style="width:70%;word-break:break-all">
             {if(count($text) gt 50) then 
             <a target="_blank" href="/{$collection}/{$id}/main?hi={$queryText}" >{exptit:printTitleID($id)}</a> else
             <a target="_blank" href="/{$collection}/{$id}/main?hi={$queryText}" >{try{exptit:printTitleID($id)} catch * {console:log($err:description)}}</a>} ({$id})
             </div>
             <div class="w3-col w3-padding"  style="width:15%;overflow:auto;">
                <span class="w3-badge">{$count}</span>
                </div>
            </div>
            
            <div class="w3-twothird">
               { for $match in subsequence($expanded//exist:match, 1, 3) 
               let $matchref := replace(app:refname($match), '.$', '')
                let $ref := if($view = 'text' and $matchref !='') then '&amp;ref=' || $matchref else ()
                return 
               <div><div class="w3-twothird w3-padding match">
                   {  kwic:get-summary($match/parent::node(), $match,<config width="40"/>)}
                     </div>
                        <div class="w3-third w3-padding">
                        <a href="/{$collection}/{$id}/{$view}{$firstancestorwithIDanchor}?hi={$queryText}{$ref}">
                        {' in element ' ||
                        $firstancestorwithID/name() 
                        || 
                       (if($view = 'text'  and $matchref !='') 
                                then ', at ' || $matchref 
                       else if($view = 'main') 
                                then ', with id ' || $firstancestorwithIDid 
                        else ())
                        }</a>
                        </div>
                        </div>
                        }
                        </div>
                    </div>
       }</div></div>
       };


declare function app:searchResNotMatches($model, $start, $per-page){

                 for $text in $model('hits')
        let $root := root($text)
        let $t := $root/t:TEI/@type
        group by $type := $t
        let $collection := switch2:col($type)
        
        return
        <div class="w3-container w3-panel w3-card-2 w3-padding results{$collection}">
        <div class="w3-margin w3-padding">
        <h4>{count($text)} result{if(count($text) gt 1) then 's' else ''} in {if($collection='institutions') then 'repositories' else $collection}</h4>
        {
        for $tex at $p in subsequence($text, $start, $per-page)
        let $root := root($tex)
        let $id := data($root/t:TEI/@xml:id)
        let $collection := switch2:col($root/t:TEI/@type)
         return
            <div class="w3-row reference">
                <div class="w3-col" style="width:15%"><span class="number">{$start + $p - 1}</span></div>
                        <div class="w3-half"><a target="_blank" href="/{$collection}/{$id}/main">{exptit:printTitleID($id)}</a> ({$id})</div>
                        <div class="w3-rest">{data($root/t:TEI/@type)}</div>
                       
                    </div>
       }</div></div>
                
};

declare    
%templates:wrap
    %templates:default('start', 1)
    %templates:default("per-page", 10)
    function app:searchRes (
    $node as node()*, 
    $model as map(*), $start as xs:integer,  $per-page as xs:integer) {
        switch($model("type"))
(:        These will have exist:match and are results of a ft:query :)
        case 'matches' return app:searchResMatches($model,$start,$per-page)
(:        These are results of a query which does not include ft:query :)        
        default return  app:searchResNotMatches($model, $start, $per-page)
    };
    
    
    declare %templates:wrap function app:xpathresultstitle($node as node(), 
    $model as map(*)){
    <h2>{$model("total")} results for { $model("path")} </h2>
    };
    
  
    
    declare %templates:wrap function app:sparqlresultstitle($node as node(), 
    $model as map(*)){
    <div class="w3-panel w3-card-2 w3-white">Your query: <span class="w3-tag w3-gray">{$model("q")}</span> returned <span class="w3-tag w3-gray">{count($model("sparqlResult")//sr:result)}</span> results</div>
    };
    
    declare    
%templates:wrap
    %templates:default('start', 1)
    %templates:default("per-page", 10) 
    function app:XpathRes (
    $node as node(), 
    $model as map(*), $start as xs:integer, $per-page as xs:integer) {
        
       
    for $text at $p in subsequence($model("hits"), $start, $per-page)
        let $root := root($text)
        let $id := data($root/t:TEI/@xml:id)
         return
            <div class="w3-row  w3-margin-bottom">
                <div class="w3-col w3-container" style="width:10%"><span class="number">{$start + $p - 1}</span></div>
                <div  class="w3-col w3-container" style="width:50%"><a href="/{$id}">{exptit:printTitleID($id)}</a> ({$id})</div>
                <div  class="w3-col w3-container " style="width:20%">{data($text/ancestor::t:*[@xml:id][1]/@xml:id)}</div>
                <div  class="w3-col w3-container" style="width:20%"> <code>{$text/name()}</code></div>
           </div>
       
                
        

    };
    
    
(: copy all parameters, needed for search :)

declare function app:copy-params($node as node(), $model as map(*)) {
    element { node-name($node) } {
        $node/@* except $node/@href,
        attribute href {
            let $link := $node/@href
            let $params :=
                string-join(
                    for $param in $app:params
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
declare %private function app:sanitize-lucene-query($query-string as xs:string) as xs:string {
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
declare %private function app:parse-lucene($string as xs:string) {
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
        return app:parse-lucene($rep)                
    else 
        (: replace all booleans with '<AND/>|<OR/>|<NOT/>' :)
        if (matches($string, '[^<](AND|OR|NOT) ')) 
        then
            let $rep := replace($string, '(AND|OR|NOT) ', '<$1/>')
            return app:parse-lucene($rep)
        else 
            (: replace all '+' modifiers in token-initial position with '<AND/>' :)
            if (matches($string, '(^|[^\w&quot;])\+[\w&quot;(]'))
            then
                let $rep := replace($string, '(^|[^\w&quot;])\+([\w&quot;(])', '$1<AND type=_+_/>$2')
                return app:parse-lucene($rep)
            else 
                (: replace all '-' modifiers in token-initial position with '<NOT/>' :)
                if (matches($string, '(^|[^\w&quot;])-[\w&quot;(]'))
                then
                    let $rep := replace($string, '(^|[^\w&quot;])-([\w&quot;(])', '$1<NOT type=_-_/>$2')
                    return app:parse-lucene($rep)
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
                        return app:parse-lucene($rep)
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
                            return app:parse-lucene($rep)
                        else (: wrap fuzzy search strings in '<fuzzy max-edits=""></fuzzy>' :)
                            if (matches($string, '[\w-[<>]]+?~[\d.]*')) 
                            then
                                let $rep := replace($string, '([\w-[<>]]+?)~([\d.]*)', '<fuzzy max-edits=_$2_>$1</fuzzy>')
                                return app:parse-lucene($rep)
                            else (: wrap resulting string in '<query></query>' :)
                                concat('<query>', replace(normalize-space($string), '_', '"'), '</query>')
};

(: Function to transform the intermediary structures in the search query generated through app:parse-lucene() and parse-xml() 
to full-fledged boolean expressions employing XML query syntax. 
Based on Ron Van den Branden, https://rvdb.wordpress.com/2010/08/04/exist-lucene-to-xml-syntax/:)
declare %private function app:lucene2xml($node as item(), $mode as xs:string) {
    typeswitch ($node)
        case element(query) return 
            element { node-name($node)} {
            element bool {
            $node/node()/app:lucene2xml(., $mode)
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
                    $node/node()/app:lucene2xml(., $mode)
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


(:function defined by Wicentowski Joe joewiz@gmail.com on exist open mailing list for the Last created document in the collection:)
declare function app:get-latest-created-document($collection-uri as xs:string) as map(*) {
    if (xmldb:collection-available($collection-uri)) then
        let $documents := xmldb:xcollection($collection-uri) ! util:document-name(.)
        return
            if (exists($documents)) then
                let $latest-created :=
                    $documents
                    => sort((), xmldb:created($collection-uri, ?))
                    => subsequence(last())
                return
                    map {
                        "collection-uri": $collection-uri,
                        "document-name": $latest-created,
                        "created": xmldb:created($collection-uri, $latest-created)
                    }
            else
                map {
                    "warning": "No child documents in collection " || $collection-uri
                }
    else 
        map {
            "warning": "No such collection " || $collection-uri
        }
  };
  



declare  function app:worksforclavis($node as node(), $model as map(*), $xpath as xs:string?) {
  let $hits := for $hit in collection($config:data-rootW)//t:TEI[not(ends-with(@xml:id, 'IHA'))]
  order by $hit/@xml:id
                    return $hit
   return
  map {"hits": $hits, "path": $xpath}

      };


  declare
  %templates:wrap
  %templates:default('start', 1)
  %templates:default("per-page", 20)
  function app:worksclavis(
      $node as node()*,
      $model as map(*),
      $start as xs:integer,
      $per-page as xs:integer) {

  for $text at $p in subsequence($model("hits"), $start, $per-page)
          let $root := root($text)
          let $id := data($root/t:TEI/@xml:id)
          let $maintitle := exptit:printTitleID($id)
          let $clavis := apptable:clavisIds($root/t:TEI)
           return
              <div class="w3-row reference" style="margin-bottom:20px;border-bottom: double;">
                  <div class="w3-half w3-padding">
                  <div class="w3-half w3-padding">
                  <span class="w3-tag w3-gray work">{$id}</span><h3>{$maintitle}</h3>{$clavis}
                      
                  </div>
                  <div class="w3-half w3-padding">{
                  for $title at $t in $text//t:titleStmt/t:title
                  let $dv := $id||'TITLE'||$t
                  return
                  <div class="row">
                  <div class="w3-threequarter w3-padding"><p data-value="{$dv}">{$title/text()}</p></div>
                  <div class="w3-quarter w3-padding"><button data-value="{$dv}"
                  class="w3-button w3-red searchthis">search this</button></div>
                  </div>
                  }</div>
                  </div>
                  <div class="w3-half w3-padding"><label>Search PATHs/CMCL project data for matching clavis ids for {$id}</label><input id="{$id}" class="form-control querystring" type="text"/><div class="pathsResults"/></div>


              </div>
  };
