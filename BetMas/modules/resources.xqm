xquery version "3.1" encoding "UTF-8";

(:~
 : This module contains functions printing indexes and lists extracted from the data which are not list of resources
 : @author Pietro Liuzzo 
 :)

module namespace lists="https://www.betamasaheft.uni-hamburg.de/BetMas/lists";
import module namespace config="https://www.betamasaheft.uni-hamburg.de/BetMas/config" at "xmldb:exist:///db/apps/BetMas/modules/config.xqm";
import module namespace titles="https://www.betamasaheft.uni-hamburg.de/BetMas/titles" at "xmldb:exist:///db/apps/BetMas/modules/titles.xqm";
import module namespace string = "https://www.betamasaheft.uni-hamburg.de/BetMas/string" at "xmldb:exist:///db/apps/BetMas/modules/tei2string.xqm";
import module namespace console="http://exist-db.org/xquery/console";

declare namespace t="http://www.tei-c.org/ns/1.0";
declare namespace templates="http://exist-db.org/xquery/templates" ;



(:~prints a responsive table with the first 100 ptr targets fount in
 : all the bibliography entries in the  entities in the app taken once, requesting the data from Zotero:)
declare

    %templates:default("collection", "")
    %templates:default("pointer", "")
    %templates:default("type", "all")
function lists:bibl ($node as node(), $model as map(*),
    $type as xs:string+, $collection as xs:string, $pointer as xs:string*) {
   let $coll := switch($collection)
   case'all' return '$config:collection-root'
   case 'mss' return '$config:collection-rootMS'
   case 'work' return '$config:collection-rootW'
   case 'auth' return '$config:collection-rootA'
   case 'pers' return '$config:collection-rootPr'
   case 'place' return '$config:collection-rootPl'
   case 'ins' return '$config:collection-rootIn'
   default return '$config:collection-root'
   let $Pointer := if($pointer = '') then "[starts-with(@target,'bm:')]" else "[@target='"||$pointer||"']"
    let $Type := if($type = 'all') then () else let $pars := for $ty in $type return "@type = '" || $ty || "'" return '//t:listBibl[' || string-join($pars, ' or ') || ']'
   let $path := $coll||$Type||'//t:ptr'||$Pointer 
   let $query := util:eval($path)//@target
let $bms :=
for $bibl in distinct-values($query)
order by $bibl
return
$bibl
    return
   map {
                    "hits" := $bms,
                    "type" := 'bibliography',
                    "coll" := $coll

                }

     };


declare
    %templates:default("scope", "narrow")
    %templates:default("type", "all")
    %templates:default("target-pers", "all")
    %templates:default("target-place", "all")
    %templates:default("target-work", "all")
    %templates:default("target-keyword", "all")
    %templates:default("target-language", "all")
    %templates:default("interpret", "all")
    function lists:additions( $node as node()*, $model as map(*),  $query as xs:string*,
    $type as xs:string+,
    $target-keyword as xs:string+,
    $target-language as xs:string+,
    $target-pers as xs:string+,
    $target-place as xs:string+,
    $target-work as xs:string+,
    $termText as xs:string*,
    $otherText as xs:string*,
    $interpret as xs:string*) {
   let $type := if($type = 'all') then '' else let $pars := for $ty in $type return "descendant::t:desc[@type = '" || $ty || "']" return '[' || string-join($pars, ' or ') || ']'
   let $target-work := if($target-work = 'all') then () else let $pars := for $ty in $target-work return "@ref = '" || $ty || "'" return '[descendant::t:title[' || string-join($pars, ' or ') || ']]'
   let $target-pers := if($target-pers = 'all') then () else let $pars := for $ty in $target-pers return "@ref = '" || $ty || "'" return '[descendant::t:persName[' || string-join($pars, ' or ') || ']]'
   let $target-place := if($target-place = 'all') then () else let $pars := for $ty in $target-place return "@ref = '" || $ty || "'" return '[descendant::t:placeName[' || string-join($pars, ' or ') || ']]'
   let $target-keyword := if($target-keyword = 'all') then () else let $pars := for $ty in $target-keyword return "@key = '" || $ty || "'" return '[descendant::t:term[' || string-join($pars, ' or ') || ']]'
   let $target-language := if($target-language = 'all') then () else let $pars := for $ty in $target-language return "@xml:lang = '" || $ty || "'" return '[descendant::t:q[' || string-join($pars, ' or ') || ']]'
   let $termText :=  if($termText) then ("[descendant::t:term[contains(.,'" || $termText || "')]]") else ()
   let $otherText :=if($otherText) then ("[descendant::t:q[ft:query(.,'" || $otherText || "')]]") else ()
   let $interpret :=if($interpret = 'all') then () else let $pars := for $ty in $interpret return "@ana = '" || $ty || "'" return '[descendant::t:seg[' || string-join($pars, ' or ') || ']]'
   let $path := '$config:collection-rootMS//t:item[starts-with(@xml:id, "a")]' || $type || $target-work || $target-pers || $target-place || $target-keyword|| $target-language || $termText ||$otherText || $interpret
 let $additions := for $add in util:eval($path) return $add
   return
   map {
                    "hits" := $additions

                }
   };


declare
    %templates:default("scope", "narrow")
    %templates:default("type", "all")
    %templates:default("target-keyword", "all")
    %templates:default("SewingStationsN", "all")
    %templates:default("BindingMaterial", "all")
    %templates:default("color", "all")
    %templates:default("pastedown", "all")
    %templates:default("fastening", "all")
function lists:SearchBinding(
$node as node()*,
$model as map(*),
$query as xs:string*,
    $type as xs:string+,
    $target-keyword as xs:string+,
    $SewingStationsN as xs:string+,
    $BindingMaterial as xs:string+,
    $color as xs:string+,
    $pastedown as xs:string+,
    $fastening as xs:string+
   ) {
   let $type := if($type = 'all') then () else let $pars := for $ty in $type return "@type = '" || $ty || "'" return '[' || string-join($pars, ' or ') || ']'
   let $target-keyword := if($target-keyword = 'all') then () else let $pars := for $ty in $target-keyword return "@key = '" || $ty || "'" return '[descendant::t:term[' || string-join($pars, ' or ') || ']]'
   let $SewingStationsN := if($SewingStationsN = 'all' or $SewingStationsN = '' ) then () else ("[@type='SewingStations'][.="||$SewingStationsN||"]")
   let $fastening := if($fastening = 'all') then () else ("[@type='Fastening'][.='"||$fastening||"']")
   let $BindingMaterial := if($BindingMaterial='all') then () else ("[descendant::t:material[@key='"||$BindingMaterial||"']]")
   let $color := if($color='all') then () else ("[@color='"||$color||"']")
   let $pastedown := if($pastedown='all') then () else ("[matches(@pastedown, '"||$pastedown||"')]")
   let $path := '$config:collection-rootMS//t:decoNote[starts-with(@xml:id, "b")]' || $type || $target-keyword || $SewingStationsN || $BindingMaterial || $color || $pastedown || $fastening
  let $decos := for $dec in util:eval($path) return $dec
   return
   map {
                    "hits" := $decos

                }
   };


declare
    %templates:default("scope", "narrow")
    %templates:default("type", "all")
    %templates:default("target-pers", "all")
    %templates:default("target-place", "all")
    %templates:default("target-work", "all")
    %templates:default("target-artTheme", "all")
    %templates:default("target-keyword", "all")
function lists:SearchDeco(
$node as node()*,
$model as map(*),
$query as xs:string*,
    $type as xs:string+,
    $target-keyword as xs:string+,
    $target-pers as xs:string+,
    $target-place as xs:string+,
    $target-work as xs:string+,
    $target-artTheme as xs:string+,
    $legendText as xs:string*,
    $otherText as xs:string*
   ) {
   let $type := if($type = 'all') then '[@type]' else let $pars := for $ty in $type return "@type = '" || $ty || "'" return '[' || string-join($pars, ' or ') || ']'
   let $target-work := if($target-work = 'all') then () else let $pars := for $ty in $target-work return "@ref = '" || $ty || "'" return '[descendant::t:title[' || string-join($pars, ' or ') || ']]'
   let $target-artTheme := if($target-artTheme= 'all') then () else let $pars := for $ty in $target-artTheme return "@corresp = '" || $ty || "'" return '[descendant::t:ref[@type="authFile"][' || string-join($pars, ' or ') || ']]'
   let $target-pers := if($target-pers = 'all') then () else let $pars := for $ty in $target-pers return "@ref = '" || $ty || "'" return '[descendant::t:persName[' || string-join($pars, ' or ') || ']]'
   let $target-place := if($target-place = 'all') then () else let $pars := for $ty in $target-place return "@ref = '" || $ty || "'" return '[descendant::t:placeName[' || string-join($pars, ' or ') || ']]'
   let $target-keyword := if($target-keyword = 'all') then () else let $pars := for $ty in $target-keyword return "@key = '" || $ty || "'" return '[descendant::t:term[' || string-join($pars, ' or ') || ']]'
   let $legendText :=  if($legendText) then ("[descendant::t:q[@xml:lang][ft:query(.,'" || $legendText || "')]]") else ()
   let $otherText :=if($otherText) then ("[descendant::t:foreign[@xml:lang='gez'][ft:query(.,'" || $otherText || "')]]") else ()
   let $path := "$config:collection-rootMS//t:decoNote[starts-with(@xml:id, 'd')]" || $type || $target-work || $target-artTheme || $target-pers || $target-place || $target-keyword || $legendText ||$otherText
  let $decos := for $dec in util:eval($path) return $dec
   return
   map {
                    "hits" := $decos

                }
   };
   
   
declare
    %templates:default("scope", "narrow")
    %templates:default("target-pers", "all")
    %templates:default("day", "all")
    %templates:default("month", "all")
    %templates:default("target-place", "all")
    %templates:default("target-work", "all")
    %templates:default("target-artTheme", "all")
    %templates:default("target-keyword", "all")
function lists:SearchCalendar(
$node as node()*,
$model as map(*),
    $target-keyword as xs:string+,
    $day as xs:string+,
    $month as xs:string+,
    $target-pers as xs:string+,
    $target-place as xs:string+,
    $target-work as xs:string+,
    $target-artTheme as xs:string+
   ) {
   let $day := if($day='all') then "[starts-with(@ref, 'ethiocal:')]" else if($day='all' and $month !='all') then "[starts-with(@ref, 'ethiocal:"||$month||"')]" else "[@ref = 'ethiocal:"||$day||"']"
   let $target-work := if($target-work = 'all') then () else let $pars := for $ty in $target-work return "@ref = '" || $ty || "'" return '[descendant::t:title[' || string-join($pars, ' or ') || ']]'
   let $target-artTheme := if($target-artTheme= 'all') then () else let $pars := for $ty in $target-artTheme return "@corresp = '" || $ty || "'" return '[descendant::t:ref[@type="authFile"][' || string-join($pars, ' or ') || ']]'
   let $target-pers := if($target-pers = 'all') then () else let $pars := for $ty in $target-pers return "@ref = '" || $ty || "'" return '[descendant::t:persName[' || string-join($pars, ' or ') || ']]'
   let $target-place := if($target-place = 'all') then () else let $pars := for $ty in $target-place return "@ref = '" || $ty || "'" return '[descendant::t:placeName[' || string-join($pars, ' or ') || ']]'
   let $target-keyword := if($target-keyword = 'all') then () else let $pars := for $ty in $target-keyword return "@key = '" || $ty || "'" return '[descendant::t:term[' || string-join($pars, ' or ') || ']]'
    let $path := "$config:collection-root//t:date"||$day||(if($target-work!='all' or $target-artTheme !='all' or $target-pers !='all' or $target-place !='all' or $target-keyword !='all') then
    "[ancestor::t:*[@xml:id][1]" || $target-work || $target-artTheme || $target-pers || $target-place || $target-keyword || ']' else ())
  let $dates := for $dec in util:eval($path) return $dec
   return
   map {
                    "hits" := $dates

                }
   };
   
   declare
    %templates:default("scope", "narrow")
    %templates:default("typeval", "marked")
    %templates:default("target-pers", "all")
    %templates:default("target-place", "all")
    %templates:default("target-work", "all")
    %templates:default("target-mss", "all")
    %templates:default("limit-mss", "")
    %templates:default("limit-work", "")
    %templates:default("target-artTheme", "all")
    %templates:default("target-keyword", "all")
    %templates:default("elements", "all")
function lists:SearchTitles(
$node as node()*,
$model as map(*),
$query as xs:string*,
    $typeval as xs:string+,
    $target-keyword as xs:string+,
    $target-pers as xs:string+,
    $target-place as xs:string+,
    $target-work as xs:string+,
    $limit-mss as xs:string+,
    $limit-work as xs:string+,
    $target-artTheme as xs:string+,
    $elements as xs:string+
   ) {
   let $values := ('subscriptio', 'supplication', 'embedded', 'inscriptio', 'translation', 'expanded', 'title', 'desinit')
   let $type := if($typeval = 'all') then '' 
                        else if($typeval = 'marked') then '[contains(@type, $values)]'  else let $pars := for $ty in $typeval return "contains(@type, '" || $ty || "')" return '[' || string-join($pars, ' or ') || ']'
   let $subtype := if($typeval = 'all') then ''  else if($typeval = 'marked') then '[contains(@subtype, $values)]' else let $pars := for $ty in $typeval return "contains(@subtype, '" || $ty || "')" return '[' || string-join($pars, ' or ') || ']'
   
   let $textquery:=if($query) then ("[ft:query(.,'" || $query || "')]") else ()
   let $works := if($limit-work = '') then () else $config:collection-rootW//id($limit-work)
   let $mss :=  if($limit-mss = '') then () else $config:collection-rootMS//id($limit-mss)
   let $mssWork := $config:collection-rootMS//t:msItem[t:title[@ref=$limit-work]]
   let $msitems := $mss//t:msItem[t:title[@ref=$limit-work]]
   let $msitemsIDS :=  $msitems/@xml:id
   let $msSitemsIDS :=  $mssWork/@xml:id
   let $divs := $mss//t:div[@corresp =$msitemsIDS]
   let $mssdivs := $mssWork/following::t:div[@corresp =$msSitemsIDS]
   let $additions := $mss//t:item[@corresp =$msitemsIDS]
   let $mssadditions := $mssWork/following::t:item[@corresp =$msSitemsIDS]
   let $workdivs := $works//t:div[@type='edition']

   let $context := 
(:   if the search is limited to a set of manuscripts or a set of works, the context changes.
first if the no limit is set, we will search all the collection :)
                                 if($limit-work = '' and $limit-mss = '') then '$config:collection-root' 
(:                                 if the search is limited by work, then we want to search
                                    - the file of that work, 
                                    - the relevant parts of manuscripts which contain that work 
                                    this assumes that if also parts or related works are wanted, the parameter should list those already:)
                                 else if($limit-work !='' and $limit-mss = '') then
                                         '('||'$workdivs' ||','||'$mssWork' || ','||'$mssadditions' ||','||'$mssdivs'||")"
(:                                 if the search is limited by manuscript, then we want to search
                                    - the files of those manuscripts :)
                                else if($limit-work = '' and $limit-mss !='') then
                                          '$mss'
(:                                 if the search is limited by manuscript and work
                                    - the relevant parts of those manuscripts which contain that work 
                                    this assumes that if also parts or related works are wanted, the parameter should list those already:)
                                 else 
                                           '('||'$msitems' ||','||'$additions' ||','||'$divs'||")"
                                           
  let $target-work := if($target-work = 'all') then () else let $pars := for $ty in $target-work return "@ref = '" || $ty || "'" return '[descendant::t:title[' || string-join($pars, ' or ') || ']]'
    let $target-artTheme := if($target-artTheme= 'all') then () else let $pars := for $ty in $target-artTheme return "@corresp = '" || $ty || "'" return '[descendant::t:ref[@type="authFile"][' || string-join($pars, ' or ') || ']]'
   let $target-pers := if($target-pers = 'all') then () else let $pars := for $ty in $target-pers return "@ref = '" || $ty || "'" return '[descendant::t:persName[' || string-join($pars, ' or ') || ']]'
   let $target-place := if($target-place = 'all') then () else let $pars := for $ty in $target-place return "@ref = '" || $ty || "'" return '[descendant::t:placeName[' || string-join($pars, ' or ') || ']]'
   let $target-keyword := if($target-keyword = 'all') then () else let $pars := for $ty in $target-keyword return "@key = '" || $ty || "'" return '[descendant::t:term[' || string-join($pars, ' or ') || ']]'
  let $filters := $target-work|| $target-artTheme || $target-pers || $target-place || $target-keyword || $textquery
  let $titles :=
   if($elements = 'all' or $elements = 'title') then
let $query := $context || '//t:title'||'[not(parent::t:titleStmt)]' || $subtype ||  $filters
return util:eval($query) else ()
  let $divs := 
  if($elements = 'all' or $elements = 'div') then 
let $query := $context || "//t:div"|| $subtype ||  $filters
return util:eval($query) else ()
  let $segs := 
   if($elements = 'all' or $elements = 'seg') then
let $query := $context || "//t:seg"|| '[not(ancestor::t:handDesc)]'|| $type ||  $filters
return util:eval($query) else ()
  let $colincex := for $cie in ('colophon', 'incipit', 'explicit') return 
  if($elements = 'all' or $elements = $cie) then 
let $query := $context || "//t:"||$cie|| $type ||  $filters
return util:eval($query) else ()
  let $allTitles := ($titles | $divs | $segs | $colincex)
   return
   map {
                    "hits" := $allTitles

                }
   };





   declare function lists:biblform($node as node(), $model as map(*)){
   <form xmlns="http://www.w3.org/1999/xhtml"  action="" class="w3-container">
   <div class="w3-container w3-margin-bottom">
   <small class="form-text text-muted">Select one
   or more type of bibliography</small><br/>
   <label class="checkbox">
   <input type="checkbox" class="w3-check" value="secondary" name="type"/>secondary</label><br/>
   <label class="checkbox"><input type="checkbox" class="w3-check" value="editions" name="type"/>editions</label><br/>
   <label class="checkbox"><input type="checkbox" class="w3-check" value="translation" name="type"/>translation</label><br/>
   <label class="checkbox"><input type="checkbox" class="w3-check" value="text" name="type"/>text</label><br/>
   <label class="checkbox"><input type="checkbox" class="w3-check" value="clavis" name="type"/>clavis</label><br/>
   <label class="checkbox"><input type="checkbox" class="w3-check" value="catalogue" name="type"/>catalogue</label><br/>
   <label class="checkbox"><input type="checkbox" class="w3-check" value="otherLanguages" name="type"/>otherLanguages</label><br/>
   </div>
      <div  class="w3-container w3-margin-bottom">
                               <small class="form-text text-muted">enter a Zotero bm:id</small>
                                <input class="w3-input w3-border" name="pointer" placeholder="bm:"></input>
                                </div>
                                <div class="w3-container w3-margin-bottom">
                                 <small class="form-text text-muted">Select a collection</small>
                                    <select name="collection" class="w3-select w3-border">
            <option value="all">all</option>
            <option value="mss">Manuscripts</option>
            <option value="work">Works</option>
            <option value="pers">Persons</option>
            <option value="place">Places</option>
            <option value="ins">Repositories</option>
            <option value="auth">Authority Files</option>
            </select>
                                 </div>
                                 <div class="w3-container w3-margin-top">
                                <div class="w3-bar">
                                 <button type="submit" class="w3-bar-item w3-button w3-red">
                                 <i class="fa fa-search" aria-hidden="true"></i></button>
                                 <a href="/bibliography" role="button" class="w3-bar-item w3-button w3-gray"><i class="fa fa-th-list" aria-hidden="true"></i></a></div>
                                 </div>
   </form>
   };

     declare function lists:additionsform($node as node(), $model as map(*)){
   let $auth := $config:collection-rootA
   return
   <form action="" class="w3-container">

                                <div  class="w3-container w3-margin">
                               <small class="form-text text-muted">Search in the text of marked terms</small><br/>
                                <input class="w3-input w3-border" name="termText"></input>
                                </div>
                                <div  class="w3-container w3-margin">
                               <small class="form-text text-muted">Search in the text of the documents or additions</small><br/>
                                <input class="w3-input w3-border" name="otherText"></input>
                                </div>
                               {if($model('hits')//t:q) then  <div class="w3-container w3-margin">
                                 <small class="form-text text-muted">Select the language of the additions you want to see</small><br/>

                                    <select xmlns="http://www.w3.org/1999/xhtml" multiple="multiple" id="target-language" name="target-language" class="w3-select w3-border">
            {for $d in distinct-values($model('hits')//t:q/@xml:lang)
            return
            <option value="{$d}">{$d}</option>}
            </select>
                                 </div> else () }
                               {if($model('hits')//t:title) then  <div class="w3-container w3-margin">
                                 <small class="form-text text-muted">Select one or more works referred to in the document or addition</small><br/>

                                    <select xmlns="http://www.w3.org/1999/xhtml" multiple="multiple" id="target-work" name="target-work" class="w3-select w3-border">
            {for $d in distinct-values($model('hits')//t:title/@ref)
            return
            <option value="{$d}" class="MainTitle" data-value="{$d}">{$d}</option>}
            </select>
                                 </div> else () }
                                 {if($model('hits')//t:seg) then  <div class="w3-container w3-margin">
                                 <small class="form-text text-muted">Select one or more interpretation segments</small><br/>

                                    <select xmlns="http://www.w3.org/1999/xhtml" multiple="multiple" id="target-int" name="interpret" class="w3-select w3-border">
            {for $d in distinct-values($model('hits')//t:seg/@ana)
            return
            <option value="{$d}">{substring-after($d, '#')}</option>}
            </select>
                                 </div> else () }
                                 {if($model('hits')//t:persName) then <div class="w3-container w3-margin">
                                 <small class="form-text text-muted">Select one or more persons referred to in the document or addition</small><br/>
                                    <select xmlns="http://www.w3.org/1999/xhtml" multiple="multiple" id="target-pers" name="target-pers" class="w3-select w3-border">
            {for $d in distinct-values($model('hits')//t:persName/@ref[not(contains(., '.xml'))])
            return
            <option value="{$d}" class="MainTitle" data-value="{$d}">{$d}</option>}
            </select>
                                 </div> else ()}
                                 {if($model('hits')//t:placeName) then <div class="w3-container w3-margin">
                                 <small class="form-text text-muted">Select one or more places referred to in the document or addition</small><br/>
                                    <select xmlns="http://www.w3.org/1999/xhtml" multiple="multiple" id="target-place" name="target-place" class="w3-select w3-border">
            {for $d in distinct-values($model('hits')//t:placeName/@ref[not(contains(., '.xml'))])
            return
            <option value="{$d}" class="MainTitle" data-value="{$d}">{$d}</option>}
            </select>
                                 </div> else () }
                                 {if($model('hits')//t:term) then
                                 <div class="w3-container w3-margin">
                                 <small class="form-text text-muted">Select one or more keywords referred to in the document or addition</small><br/>
                                    <select xmlns="http://www.w3.org/1999/xhtml" multiple="multiple" id="target-keyword" name="target-keyword" class="w3-select w3-border">
            {for $d in distinct-values($model('hits')//t:term/@key)
            return
            <option value="{$d}" class="MainTitle" data-value="{$d}">{$d}</option>}
            </select>
                                 </div> else() }
                                 <div id="additiontypes"></div>
                                 <div class="w3-container w3-margin-top">
                                 <div class="w3-bar">
                                 <button type="submit" class="w3-bar-item w3-button w3-red">
                                 <i class="fa fa-search" aria-hidden="true"></i></button>
                                 <a href="/additions" role="button" class="w3-bar-item w3-button w3-gray"><i class="fa fa-th-list" aria-hidden="true"></i></a></div>
                                 </div>
                        </form>
   };

   declare function lists:titlesform($node as node(), $model as map(*)){
   let $auth := $config:collection-rootA
   return
   <form action="" class="w3-container">
                               <div  class="w3-container  w3-margin">
                               <small class="form-text text-muted">Search Text</small><br/>
                               <input  class="w3-input w3-border" name="query"></input>
                                </div>
                                <div  class="w3-container  w3-margin">
                               <small class="form-text text-muted">Limit to Textual Units, adding a list of space separated identifiers</small><br/>
                               <input  class="w3-input w3-border" name="limit-work"></input>
                                </div>
                                <div  class="w3-container  w3-margin">
                               <small class="form-text text-muted">Limit to Manuscripts, adding a list of space separated identifiers</small><br/>
                               <input  class="w3-input w3-border" name="limit-mss"></input>
                               
                                </div>
                                <div  class="w3-container  w3-margin">
                               <small class="form-text text-muted">Limit by type</small><br/>
                                <select class="w3-select w3-border" name="typeval" multiple="multiple">
                                <option selected="selected" val="marked">marked</option>
                                {let $types := ($model('hits')[name() = 'title' or name()='div']//@subtype, 
                                                   $model('hits')[name() = 'incipit' or name()='explicit'or name()='colophon' or name()='seg']//@type)
                                         for $d in distinct-values($types)
            return
            <option value="{$d}">{$d} ({count($model('hits')[@* = $d])})</option>}
            <option value="all">all</option>
                                </select>
                                </div>
                                
                                
                                <div  class="w3-container  w3-margin">
                               <small class="form-text text-muted">Limit to a specific context element</small><br/>
                                <select class="w3-select w3-border" name="elements" multiple="multiple">
                               { for $d in distinct-values($model('hits')/name())
            return
            <option value="{$d}">{$d} ({count($model('hits')[name() = $d])})</option>}
                                </select>
                                </div>
                               {if($model('hits')//t:ref[@type='authFile']) then  
                               <div class="w3-container w3-margin">
                                 <small class="form-text text-muted">Select one or more Art Themes associated with the title/colophon/supplication</small><br/>

                                    <select xmlns="http://www.w3.org/1999/xhtml" multiple="multiple" id="target-artTheme" name="target-artTheme" class="w3-select w3-border">
            {for $d in distinct-values($model('hits')//t:ref[@type='authFile']/@corresp)
            return
            <option value="{$d}" class="MainTitle" data-value="{$d}">{$d}</option>}
            </select>
                                 </div> else () }
                               {if($model('hits')//t:title) then  <div class="w3-container w3-margin">
                                 <small class="form-text text-muted">Select one or more works referred to in the title/colophon/supplication</small><br/>

                                    <select xmlns="http://www.w3.org/1999/xhtml" multiple="multiple" id="target-work" name="target-work"  class="w3-select w3-border">
            {for $d in distinct-values($model('hits')//t:title/@ref)
            return
            <option value="{$d}" class="MainTitle" data-value="{$d}">{$d}</option>}
            </select>
                                 </div> else () }
                                 {if($model('hits')//t:persName) then <div class="w3-container w3-margin">
                                 <small class="form-text text-muted">Select one or more persons referred to in the title/colophon/supplication</small><br/>
                                    <select xmlns="http://www.w3.org/1999/xhtml" multiple="multiple" id="target-pers" name="target-pers"  class="w3-select w3-border">
            {for $d in distinct-values($model('hits')//t:persName/@ref)
            return
            <option value="{$d}" class="MainTitle" data-value="{$d}">{$d}</option>}
            </select>
                                 </div> else ()}
                                 {if($model('hits')//t:placeName) then <div class="w3-container w3-margin">
                                 <small class="form-text text-muted">Select one or more places referred to in the title/colophon/supplication</small><br/>
                                    <select xmlns="http://www.w3.org/1999/xhtml" multiple="multiple" id="target-place" name="target-place"  class="w3-select w3-border">
            {for $d in distinct-values($model('hits')//t:placeName/@ref)
            return
            <option value="{$d}" class="MainTitle" data-value="{$d}">{$d}</option>}
            </select>
                                 </div> else () }
                                 {if($model('hits')//t:term) then
                                 <div class="w3-container w3-margin">
                                 <small class="form-text text-muted">Select one or more keywords referred to in the title/colophon/supplication</small><br/>
                                    <select xmlns="http://www.w3.org/1999/xhtml" multiple="multiple" id="target-keyword" name="target-keyword"  class="w3-select w3-border">
            {for $d in distinct-values($model('hits')//t:term/@key)
            return
            <option value="{$d}" class="MainTitle" data-value="{$d}">{$d}</option>}
            </select>
                                 </div> else() }
                                 <div class="w3-container w3-margin">
                                 <div class="w3-bar">
                                 <button type="submit" class="w3-bar-item w3-button w3-red">
                                 <i class="fa fa-search" aria-hidden="true"></i></button>
                                 <a href="/titles" role="button" class="w3-bar-item w3-button w3-gray"><i class="fa fa-th-list" aria-hidden="true"></i></a></div>
                        </div></form>
   };
   
   declare function lists:decorationsform($node as node(), $model as map(*)){
   let $auth := $config:collection-rootA
   return
   <form action="" class="w3-container">
                               <div  class="w3-container  w3-margin">
                               <small class="form-text text-muted">Select one or more type of decoration</small><br/>

                               {for $d in distinct-values($model('hits')/@type)
                                 return  (<label class="checkbox"><input type="checkbox" class="w3-check" value="{$d}" name="type"/>{$d}</label>,<br/>)}

                                </div>
                                <div  class="w3-container  w3-margin">
                               <small class="form-text text-muted">Search in the text of the legends</small><br/>
                                <input class="w3-input w3-border" name="legendText"></input>
                                </div>
                                <div  class="w3-container  w3-margin">
                               <small class="form-text text-muted">Select in text on the decorations which is not the legend</small><br/>
                                <input  class="w3-input w3-border" name="otherText"></input>
                                </div>
                               {if($model('hits')//t:ref[@type='authFile']) then  
                               <div class="w3-container w3-margin">
                                 <small class="form-text text-muted">Select one or more Art Themes associated with the decoration description</small><br/>

                                    <select xmlns="http://www.w3.org/1999/xhtml" multiple="multiple" id="target-artTheme" name="target-artTheme" class="w3-select w3-border">
            {for $d in distinct-values($model('hits')//t:ref[@type='authFile']/@corresp)
            return
            <option value="{$d}" class="MainTitle" data-value="{$d}">{$d}</option>}
            </select>
                                 </div> else () }
                               {if($model('hits')//t:title) then  <div class="w3-container w3-margin">
                                 <small class="form-text text-muted">Select one or more works referred to in the decoration description</small><br/>

                                    <select xmlns="http://www.w3.org/1999/xhtml" multiple="multiple" id="target-work" name="target-work"  class="w3-select w3-border">
            {for $d in distinct-values($model('hits')//t:title/@ref)
            return
            <option value="{$d}" class="MainTitle" data-value="{$d}">{$d}</option>}
            </select>
                                 </div> else () }
                                 {if($model('hits')//t:persName) then <div class="w3-container w3-margin">
                                 <small class="form-text text-muted">Select one or more persons referred to in the decoration description</small><br/>
                                    <select xmlns="http://www.w3.org/1999/xhtml" multiple="multiple" id="target-pers" name="target-pers"  class="w3-select w3-border">
            {for $d in distinct-values($model('hits')//t:persName/@ref)
            return
            <option value="{$d}" class="MainTitle" data-value="{$d}">{$d}</option>}
            </select>
                                 </div> else ()}
                                 {if($model('hits')//t:placeName) then <div class="w3-container w3-margin">
                                 <small class="form-text text-muted">Select one or more places referred to in the decoration description</small><br/>
                                    <select xmlns="http://www.w3.org/1999/xhtml" multiple="multiple" id="target-place" name="target-place"  class="w3-select w3-border">
            {for $d in distinct-values($model('hits')//t:placeName/@ref)
            return
            <option value="{$d}" class="MainTitle" data-value="{$d}">{$d}</option>}
            </select>
                                 </div> else () }
                                 {if($model('hits')//t:term) then
                                 <div class="w3-container w3-margin">
                                 <small class="form-text text-muted">Select one or more artistic elements referred to in the decoration description</small><br/>
                                    <select xmlns="http://www.w3.org/1999/xhtml" multiple="multiple" id="target-keyword" name="target-keyword"  class="w3-select w3-border">
            {for $d in distinct-values($model('hits')//t:term/@key)
            return
            <option value="{$d}" class="MainTitle" data-value="{$d}">{$d}</option>}
            </select>
                                 </div> else() }
                                 <div class="w3-container w3-margin">
                                 <div class="w3-bar">
                                 <button type="submit" class="w3-bar-item w3-button w3-red">
                                 <i class="fa fa-search" aria-hidden="true"></i></button>
                                 <a href="/decorations" role="button" class="w3-bar-item w3-button w3-gray"><i class="fa fa-th-list" aria-hidden="true"></i></a></div>
                        </div></form>
   };


declare function lists:calendarform($node as node(), $model as map(*)){
   let $auth := $config:collection-rootA
   return
   <form action="" class="w3-container">
                               
                               <div class="w3-container w3-margin">
                                 <small class="form-text text-muted">Select a month</small><br/>

                                    <select xmlns="http://www.w3.org/1999/xhtml" multiple="multiple" id="month" name="month" class="w3-select w3-border">
            {for $d  at $p in doc('/db/apps/BetMas/calendars/ethiopian.xml')//t:body/t:list/t:item/@xml:id
            order by $p
            return
            <option value="{string($d)}" >{string($d)}</option>}
            </select>
                                 </div>
                                 
                                   <div class="w3-container w3-margin">
                                 <small class="form-text text-muted">Select a day</small><br/>

                                    <select xmlns="http://www.w3.org/1999/xhtml" multiple="multiple" id="day" name="day" class="w3-select w3-border">
            {for $d  at $p in doc('/db/apps/BetMas/calendars/ethiopian.xml')//t:body/t:list/t:item/t:list/t:item
            order by $p
            return
            <option value="{string($d/@xml:id)}">{$d/text()}</option>}
            </select>
                                 </div>
                                 
                               {if($model('hits')//t:ref[@type='authFile']) then  
                               <div class="w3-container w3-margin">
                                 <small class="form-text text-muted">Select one or more Art Themes associated with the date</small><br/>

                                    <select xmlns="http://www.w3.org/1999/xhtml" multiple="multiple" id="target-artTheme" name="target-artTheme" class="w3-select w3-border">
            {for $d in distinct-values($model('hits')//t:ref[@type='authFile']/@corresp)
            return
            <option value="{$d}" class="MainTitle" data-value="{$d}">{$d}</option>}
            </select>
                                 </div> else () }
                               {if($model('hits')/parent::t:*[@xml:id][1]//t:title) then  <div class="w3-container w3-margin">
                                 <small class="form-text text-muted">Select one or more works referred to in the decoration description</small><br/>

                                    <select xmlns="http://www.w3.org/1999/xhtml" multiple="multiple" id="target-work" name="target-work"  class="w3-select w3-border">
            {for $d in distinct-values($model('hits')/parent::t:*[@xml:id][1]//t:title/@ref)
            return
            <option value="{$d}" class="MainTitle" data-value="{$d}">{$d}</option>}
            </select>
                                 </div> else () }
                                 {if($model('hits')/parent::t:*[@xml:id][1]//t:persName) then <div class="w3-container w3-margin">
                                 <small class="form-text text-muted">Select one or more persons referred to in the decoration description</small><br/>
                                    <select xmlns="http://www.w3.org/1999/xhtml" multiple="multiple" id="target-pers" name="target-pers"  class="w3-select w3-border">
            {for $d in distinct-values($model('hits')/parent::t:*[@xml:id][1]//t:persName/@ref)
            return
            <option value="{$d}" class="MainTitle" data-value="{$d}">{$d}</option>}
            </select>
                                 </div> else ()}
                                 {if($model('hits')/parent::t:*[@xml:id][1]//t:placeName) then <div class="w3-container w3-margin">
                                 <small class="form-text text-muted">Select one or more places referred to in the decoration description</small><br/>
                                    <select xmlns="http://www.w3.org/1999/xhtml" multiple="multiple" id="target-place" name="target-place"  class="w3-select w3-border">
            {for $d in distinct-values($model('hits')/parent::t:*[@xml:id][1]//t:placeName/@ref)
            return
            <option value="{$d}" class="MainTitle" data-value="{$d}">{$d}</option>}
            </select>
                                 </div> else () }
                                 {if($model('hits')/parent::t:*[@xml:id][1]//t:term) then
                                 <div class="w3-container w3-margin">
                                 <small class="form-text text-muted">Select one or more artistic elements referred to in the decoration description</small><br/>
                                    <select xmlns="http://www.w3.org/1999/xhtml" multiple="multiple" id="target-keyword" name="target-keyword"  class="w3-select w3-border">
            {for $d in distinct-values($model('hits')/parent::t:*[@xml:id][1]//t:term/@key)
            return
            <option value="{$d}" class="MainTitle" data-value="{$d}">{$d}</option>}
            </select>
                                 </div> else() }
                                 <div class="w3-container w3-margin">
                                 <div class="w3-bar">
                                 <button type="submit" class="w3-bar-item w3-button w3-red">
                                 <i class="fa fa-search" aria-hidden="true"></i></button>
                                 <a href="/decorations" role="button" class="w3-bar-item w3-button w3-gray"><i class="fa fa-th-list" aria-hidden="true"></i></a></div>
                        </div></form>
   };


   declare function lists:bindingsform($node as node(), $model as map(*)){
   let $auth := $config:collection-rootA
   return
   <form action="" class="w3-container">
                               <div  class="w3-container w3-margin">
                               <small class="form-text text-muted">Select one or more type of decoration</small><br/>

                               {for $d in distinct-values($model('hits')/@type)
                                 return  (<label class="checkbox"><input type="checkbox" class="w3-check" value="{$d}" name="type"/>{$d}</label>,<br/>)}

                                </div>

                                 {if($model('hits')//t:term) then
                                 <div class="w3-container w3-margin">
                                 <small class="form-text text-muted">Select one or more features of the binding description</small><br/>
                                    <select xmlns="http://www.w3.org/1999/xhtml" multiple="multiple" id="target-keyword" name="target-keyword" class="w3-select w3-border">
            {for $d in distinct-values($model('hits')//t:term/@key)
            return
            <option value="{$d}" class="MainTitle" data-value="{$d}">{$d}</option>}
            </select>
                                 </div> else() }
                                 {if($model('hits')//@color) then
                                 <div class="w3-container w3-margin">
                                 <small class="form-text text-muted">Select a color</small><br/>
                                    <select xmlns="http://www.w3.org/1999/xhtml" id="color" name="color" class="w3-select w3-border">
            <option value="all">all</option>
            {for $d in distinct-values($model('hits')//@color)
            return
            <option value="{$d}">{$d}</option>}
            </select>
                                 </div> else() }
                                 {if($model('hits')//@pastedown) then
                                 <div class="w3-container w3-margin">
                                 <small class="form-text text-muted">Select a pastedown type (will search only manuscripts where this is present)</small><br/>
                                    <select xmlns="http://www.w3.org/1999/xhtml" id="pastedown" name="pastedown" class="w3-select w3-border">
            <option value="all">all</option>
            {for $d in distinct-values($model('hits')//@pastedown)
            return
            <option value="{$d}">{$d}</option>}
            </select>
                                 </div> else() }
                                 {if($model('hits')//t:material) then
                                 <div class="w3-container w3-margin">
                                 <small class="form-text text-muted">Select a binding material</small><br/>
                                    <select xmlns="http://www.w3.org/1999/xhtml" id="BindingMaterial" name="BindingMaterial" class="w3-select w3-border">
            <option value="all">all</option>
            {for $d in distinct-values($model('hits')//t:material/@key)
            return
            <option value="{$d}">{$d}</option>}
            </select>
                                 </div> else() }
                                 {if($model('hits')//t:decoNote[@type='Fastening']) then
                                 <div class="w3-container w3-margin">
                                 <small class="form-text text-muted">Select a fastening feature</small><br/>
                                    <select xmlns="http://www.w3.org/1999/xhtml" id="Fastening" name="fastening" class="w3-select w3-border">
            <option value="all">all</option>
            {for $d in $model('hits')//t:decoNote[@type='Fastening']
            return
            <option value="{$d/text()}">{$d/text()}</option>}
            </select>
                                 </div> else() }
                                 <div  class="w3-container w3-margin">
                                 <small  class="form-text text-muted">number of Sewing stations</small><br/>
                                 <input type="number" class="w3-input w3-border" id="SewingStationsN" name="SewingStationsN"></input>
                                 </div>
                                 <div class="w3-container w3-margin">
                                 <div class="w3-bar">
                                 <button type="submit" class="w3-bar-item w3-button w3-red">
                                 <i class="fa fa-search" aria-hidden="true"></i></button>
                                 <a href="/bindings" role="button" class="w3-bar-item w3-button w3-gray"><i class="fa fa-th-list" aria-hidden="true"></i></a></div>
                        </div></form>
   };



declare
%templates:wrap
    %templates:default('start', 1)
    %templates:default("per-page", 10)
    function lists:biblRes($node as node(), $model as map(*), $start as xs:integer, $per-page as xs:integer){

for $target at $p in subsequence($model("hits"), $start, $per-page)
let $ptrs := util:eval($model("coll"))//t:ptr[@target = $target]
let $count := count($ptrs)
return
<div class="w3-container w3-padding w3-border-bottom">
<div class="w3-half w3-padding">
    <div id="{$target}" class="biblioentry w3-col" style="width:90%"/>
    <div class="w3-col w3-center" style="width:10%">
    <a href="https://www.zotero.org/groups/358366/ethiostudies/items/tag/{$target}" target="_blank"><img src="/resources/images/zotero_16x16x32.png" style="display:inline;"/></a>
    <br/>
    <span class="w3-small w3-tag w3-gray w3-margin-top w3-hide-small" style="word-break: break-all;">{$target}</span>
    </div>
</div>
<div class="w3-half w3-padding">
<div class="w3-threequarter">
<ul class="w3-ul w3-hoverable">
    {    
   for $citingentity in $ptrs/@target
   let $stringR := string(root($citingentity)/t:TEI/@xml:id)
  let $cr := $citingentity/parent::t:ptr/following-sibling::t:citedRange/text()
   let $n := number($cr[1] => replace('-', '') => replace('[a-zA-Z]', ''))group by $root :=    $stringR 
    order by $n[1] ascending
   return
     <li class="w3-padding"><a href="/{$root}" class="MainTitle" data-value="{$root}">{$root}</a>
     {let $ranges := for $c in $citingentity
     let $cr := $c/parent::t:ptr/following-sibling::t:citedRange
     order by $cr[1]
     return 
     if($cr) then (string($cr[1]/@unit) || ', ' || $cr[1]/text()) else ()
     return if(count($ranges) ge 1) then (' ('||string-join($ranges, '; ')||')') else ()
     }
     </li>
    }
    </ul>
    </div>
    <div class="w3-quarter w3-center w3-hide-small"><span class="w3-tag w3-gray">{$count}</span></div>
    </div>
    </div>
};



declare
%templates:wrap
function lists:addRes($node as node(), $model as map(*)){
   let $data := $model("hits")
   return
for $addition at $p in $data
    let $t := if($addition//t:desc/@type) then string($addition//t:desc/@type) else 'undefined'
    group by $type := $t
    order by $type
    let $tit := titles:printTitleMainID($type, $config:data-rootA)
    return
        
        (<button onclick="openAccordion('{data($type)}')" class="w3-button w3-block w3-gray w3-margin-bottom">
<span class="w3-badge w3-right">{if ($type = 'undefined') then count($data[not(descendant::t:desc/@type)]) else count($data/t:desc[@type = $type])}</span>
<span class="w3-left additionType" data-value="{$type}">{
       if ($type = 'undefined') then $type else $tit
    }</span></button>,
    
    <div class="w3-container w3-hide" id="{data($type)}">
    <h2>{if ($type = 'undefined') then $type else <a href="/authority-files/list?keyword={string($type)}">{$tit}</a> }</h2>
        
    <ul class="w3-ul w3-padding w3-hoverable">
    {
                for $a in $addition
                let $fileID := data($a/ancestor::t:TEI/@xml:id)
                let $additionID := data($a/@xml:id)
                order by $fileID
                return
            <li><a href="{$fileID}#{$additionID}">{$fileID},{$additionID}</a> |
            <div class="additionTextContent w3-container">

               <div
               id="{$fileID}_{$additionID}">
               {if ($a//t:relation[@name='saws:formsPartOf'][contains(@passive, 'corpus')]) then (<p>Document in Corpus <a href="/{$a//t:relation/@passive}/corpus">{string($a//t:relation/@passive)}</a> </p>) else ()}
               {for $q in $a//t:q return <p>{if($q[@xml:lang = 'gez']) then attribute class {'gez'} else()}{$q}</p>}
               </div>


            </div>

            </li>

            }
    </ul>
    </div>
    )

};


declare
%templates:wrap
    function lists:bindingRes($node as node(), $model as map(*)){

for $binding at $p in $model("hits")
    let $t := $binding/@type
   (: group by type :)
    group by $type := $t
    order by $type
    return
        (<button onclick="openAccordion('{data($type)}')" 
        class="w3-button w3-block w3-gray w3-padding w3-margin-bottom">
<span class="w3-badge w3-right">{count($binding)}</span>
<span class="w3-left " data-value="{$type}">{string($type)}</span>
</button>,

        <div  class="w3-container w3-hide" id="{data($type)}">
            {
                for $b in $binding
                let $msid := $b/ancestor::t:TEI/@xml:id

                (:group by containing ms:)
                group by $ms := $msid
                order by $ms
                return

(<button onclick="openAccordion('{data($ms)}')" 
        class="w3-button w3-block w3-red w3-padding w3-margin-bottom">
<span class="w3-badge w3-right">{count($b)}</span>
<span class="w3-left " data-value="{$type}">{$config:collection-rootMS//id($ms)//t:msIdentifier/t:idno}</span>
</button>,
<div class="w3-container w3-hide" id="{data($ms)}">
<ul class="w3-ul w3-hoverable" >
                 {
                     for $sb in $b
                     let $images := root($sb)//t:msIdentifier/t:idno
                     let $locus := string($sb/t:locus/@facs)
                     order by $sb/@xml:id
                     return
            <li>

            <a href="{data($ms)}#{data($sb/@xml:id)}">{data($sb/@xml:id)}</a>: {try{string:tei2string($sb/node())} catch * {(($err:code || ": "|| $err:description), string-join($sb//text(), ' '))}}
            </li>
                 }
            </ul>
            </div>)
            }

        </div>)
};


declare
%templates:wrap
    function lists:calendarRes($node as node(), $model as map(*)){

for $date at $p in $model("hits")
    let $t := substring-after($date/@ref, 'ethiocal:')
   (: group by type :)
    group by $type := $t
    order by $type
    return
        (<button onclick="openAccordion('{data($type)}')" 
        class="w3-button w3-block w3-gray w3-padding w3-margin-bottom">
<span class="w3-badge w3-right">{count($date)}</span>
<span class="w3-left " data-value="{$type}">{string($type)}</span>
</button>,

        <div  class="w3-container w3-hide" id="{data($type)}">
            {
                for $d in $date
                let $msid := $d/ancestor::t:TEI/@xml:id

                (:group by containing ms:)
                group by $ms := $msid
                order by $ms
                return

(<button onclick="openAccordion('{data($ms)}')" 
        class="w3-button w3-block w3-red w3-padding w3-margin-bottom">
<span class="w3-badge w3-right">{count($d)}</span>
<span class="w3-left " data-value="{$type}">{titles:printTitleMainID($ms)}</span>
</button>,
<div class="w3-container w3-hide" id="{data($ms)}">
<ul class="w3-ul w3-hoverable" >
                 {
                     for $sd in $d
                     let $parentID := $sd/ancestor::t:*[@xml:id][1]/@xml:id
                     let $parentName := $sd/ancestor::t:*[@xml:id][1]/name()
                     order by $parentID
                     return
            <li>

            <a href="{data($ms)}{if($parentID != $ms) then '#'|| data($parentID) else ()}">
            {if($parentID != $ms) then 'In a ' ||$parentName || ' element with xml:id ' ||data($parentID) else ( 'within the file: ')}
            </a>: 
            {try{string:tei2string($sd/node())} catch * {(($err:code || ": "|| $err:description), string-join($sd//text(), ' '))}}
            
            </li>
                 }
            </ul>
            </div>)
            }

        </div>)
};



declare
%templates:wrap
    function lists:decoRes($node as node(), $model as map(*)){
   
for $decoration at $p in $model("hits")
    let $t := $decoration/@type
   (: group by type :)
    group by $type := $t
    order by $type
    return
    
    (<button onclick="openAccordion('{data($type)}')" class="w3-button w3-block w3-gray w3-padding w3-margin-bottom">
<span class="w3-badge w3-right">{count($decoration)}</span>
<span class="w3-left additionType" data-value="{$type}">{string($type)}</span>
</button>,
    
    <div class="w3-container w3-hide" id="{data($type)}">
    
<div  class="w3-container" id="{data($type)}">
            {
                for $d in $decoration
                let $msid := $d/ancestor::t:TEI/@xml:id

                (:group by containing ms:)
                group by $ms := $msid
                order by $ms
                return

(<button onclick="openAccordion('{data($ms)}{data($type)}')" class="w3-button w3-block w3-red  w3-margin-bottom">
<span class="w3-left">{$config:collection-rootMS//id($ms)//t:msIdentifier/t:idno}</span>
<span class="w3-badge w3-right">{count($d)}</span>
</button>,
             <div  class="w3-container w3-hide" id="{data($ms)}{data($type)}">

                 <ul class="w3-ul w3-hoverable" >
                 {
                     for $sd in $d
                     let $images := root($sd)//t:msIdentifier/t:idno
                     let $locus := string($sd/t:locus/@facs)
                     order by $sd/@xml:id
                     return
            <li class="w3-container">

            {if($images/@facs and $locus) then (<a target="_blank"  href="/manuscripts/{$ms}/viewer"><img class="thumb" src="{
           if(starts-with($ms, 'BML'))
           then $config:appUrl ||'/iiif/' || string($images/@facs)||$locus||'.tif/full/150,/0/default.jpg'
          else if(starts-with($ms, 'ES'))
           then $config:appUrl ||'/iiif/' || string($images/@facs) || '_'||$locus||'.tif/full/150,/0/default.jpg'
          else if(starts-with($ms, 'BNF'))
           then replace($images/@facs, 'ark:', 'iiif/ark:') || '/'||$locus||'/full/150,/0/native.jpg'
          else if(starts-with($ms, 'BAV'))
           then replace(substring-before($images/@facs, '/manifest.json'), 'iiif', 'pub/digit') || '/thumb/'
                    ||
                    substring-before(substring-after($images/@facs, 'MSS_'), '/manifest.json') ||
                    '_'||$locus||'.tif.jpg'
           else ()}" style="width:10%"/></a>

           )
            else ()}
            <p class="w3-rest">
            <a href="{data($ms)}#{data($sd/@xml:id)}">{data($sd/@xml:id)}</a><br/>
            {if(count($sd//t:ref[@type='authFile']) ge 1) then 'Art Themes: ' || string-join(string:tei2string($sd//t:ref[@type='authFile']), ', ') else ()}
            </p>

            </li>
                 }
            </ul>
            </div>
            
            )}

        </div>
        
    </div>
    )
    
};


declare
%templates:wrap
    function lists:titlesRes($node as node(), $model as map(*)){
   
for $title at $p in $model("hits")
    let $t := if($title/@subtype) then $title/@subtype else $title/@type
   (: group by type :)
    group by $type := $t
    order by $type
    return
    
    (<button onclick="openAccordion('{data($type)}')" class="w3-button w3-block w3-gray w3-padding w3-margin-bottom">
<span class="w3-badge w3-right">{count($title)}</span>
<span class="w3-left additionType" data-value="{$type}">{string($type)}</span>
</button>,
    
    <div class="w3-container w3-hide" id="{data($type)}">
    
<div  class="w3-container" id="{data($type)}">
            {
                for $d in $title
                let $tei := $d/ancestor::t:TEI
                let $msid := $tei/@xml:id

                (:group by containing ms:)
                group by $ms := $msid
                order by $ms
                return

(<button onclick="openAccordion('{data($ms)}')" class="w3-button w3-block w3-red  w3-margin-bottom">
<span class="w3-left">{if($type/@type= 'mss') then $config:collection-rootMS//id($ms)//t:msIdentifier/t:idno else titles:printTitleMainID($ms)}</span>
<span class="w3-badge w3-right">{count($d)}</span>
</button>,
             <div  class="w3-container w3-hide" id="{data($ms)}">

                 <ul class="w3-ul w3-hoverable" >
                 {if($type/@type= 'mss') then 
                     for $sd in $d
                     let $images := root($sd)//t:msIdentifier/t:idno
                     let $locus := string($sd/t:locus/@facs)
                     order by $sd/@xml:id
                     return
            <li class="w3-container">

            {if($images/@facs and $locus) then (<a target="_blank"  href="/manuscripts/{$ms}/viewer"><img class="thumb" src="{
           if(starts-with($ms, 'BML'))
           then $config:appUrl ||'/iiif/' || string($images/@facs)||$locus||'.tif/full/150,/0/default.jpg'
          else if(starts-with($ms, 'ES'))
           then $config:appUrl ||'/iiif/' || string($images/@facs) || '_'||$locus||'.tif/full/150,/0/default.jpg'
          else if(starts-with($ms, 'BNF'))
           then replace($images/@facs, 'ark:', 'iiif/ark:') || '/'||$locus||'/full/150,/0/native.jpg'
          else if(starts-with($ms, 'BAV'))
           then replace(substring-before($images/@facs, '/manifest.json'), 'iiif', 'pub/digit') || '/thumb/'
                    ||
                    substring-before(substring-after($images/@facs, 'MSS_'), '/manifest.json') ||
                    '_'||$locus||'.tif.jpg'
           else ()}" style="width:10%"/></a>

           )
            else<div class="w3-third">No image found</div>}
            <div class="w3-third" >{string:tei2string($sd/node())}</div>
                 <div class="w3-third">
                 <div class="w3-third"><a href="/{$ms}"><b>{$sd/name()}</b>{" | "}{if($sd/@subtype) then string($sd/@subtype) else string($sd/@type)}</a></div>
                 <div class="w3-third">Refers to {if($sd/name() = 'div' and $type/@type= 'work') 
                                                   then <span class="MainTitle" data-value="{$ms}">{$ms}</span> 
                                                 else if($sd/name() = 'div' and $type/@type= 'mss') then 
                                                                    (let $corr := $sd/@corresp 
                                                                    let $msitem := $sd/ancestor::t:TEI//t:msItem[@xml:id=$corr]
                                                                    let $work := $msitem/t:title/@ref
                                                                    return <span class="MainTitle" data-value="{string($work[1])}">{string($work[1])}</span> )
                                                  else if($sd/name() = 'colophon' or $sd/name() = 'incipit' or $d/name() = 'explicit' or $sd/name() = 'title') 
                                                                   then (  let $msitem := $sd/ancestor::t:msItem 
                                                                   let $work := $msitem/t:title/@ref
                                                                   return <span class="MainTitle" data-value="{string($work[1])}">{string($work[1])}</span> )
                                                  else 'unable to retrive reference'}</div>
                 <div class="w3-third">
            <a href="{data($ms)}#{data($sd/@xml:id)}">{data($sd/@xml:id)}</a><br/>
            {if(count($sd//t:ref[@type='authFile']) ge 1) then 'Art Themes: ' || string-join(string:tei2string($sd//t:ref[@type='authFile']), ', ') else ()}
            </div>
            </div>

            </li>
                 else 
                  for $sd in $d
                  return
                 <li class="w3-container">
                 <div class="w3-half" >{string:tei2string($sd/node())}</div>
                 <div class="w3-half">
                 <div class="w3-third"><a href="/{$ms}"><b>{$sd/name()}</b>{" | "}{if($sd/@subtype) then string($sd/@subtype) else string($sd/@type)}</a></div>
                 <div class="w3-third">Refers to {if($sd/name() = 'div' and $type/@type= 'work') 
                                                   then (<a href="/{$ms}"><span class="MainTitle" data-value="{$ms}">{$ms}</span></a>, <br/>,
                                                                    <div class="w3-bar w3-gray w3-small"><a class="w3-bar-item w3-button" href="/titles?limit-work={$ms}">limit results to this work</a>
                                                                    <a  class="w3-bar-item w3-button" href="/compare?workid={$ms}">compare mss</a>
                                                                    <a  class="w3-bar-item w3-button" href="/workmap?worksid={$ms}">map mss</a>
                                                                    <a  class="w3-bar-item w3-button" href="/litcomp?worksid={$ms}">literature view</a></div>) 
                                                 else if($sd/name() = 'div' and $type/@type= 'mss') then 
                                                                    (let $corr := $sd/@corresp 
                                                                    let $msitem := $sd/ancestor::t:TEI//t:msItem[@xml:id=$corr]
                                                                    let $work := $msitem/t:title/@ref
                                                                    return (<a href="/{string($work[1])}"><span class="MainTitle" data-value="{string($work[1])}">{string($work[1])}</span></a>, <br/>,
                                                                    <div class="w3-bar w3-gray w3-small"><a class="w3-bar-item w3-button" href="/titles?limit-work={string($work[1])}">limit results to this work</a>
                                                                    <a  class="w3-bar-item w3-button" href="/compare?workid={string($work[1])}">compare mss</a>
                                                                    <a  class="w3-bar-item w3-button" href="/workmap?worksid={string($work[1])}">map mss</a>
                                                                    <a  class="w3-bar-item w3-button" href="/litcomp?worksid={string($work[1])}">literature view</a></div>) )
                                                  else if($sd/name() = 'colophon' or $sd/name() = 'incipit' or $d/name() = 'explicit' or $sd/name() = 'title') 
                                                                   then (  let $msitem := $sd/ancestor::t:msItem 
                                                                   let $work := $msitem/t:title/@ref
                                                                   return (<a href="/{string($work[1])}"><span class="MainTitle" data-value="{string($work[1])}">{string($work[1])}</span></a>, <br/>,
                                                                    <div class="w3-bar w3-gray w3-small"><a class="w3-bar-item w3-button" href="/titles?limit-work={string($work[1])}">limit results to this work</a>
                                                                    <a  class="w3-bar-item w3-button" href="/compare?workid={string($work[1])}">compare mss</a>
                                                                    <a  class="w3-bar-item w3-button" href="/workmap?worksid={string($work[1])}">map mss</a>
                                                                    <a  class="w3-bar-item w3-button" href="/litcomp?worksid={string($work[1])}">literature view</a></div>) )
                                                  else 'unable to retrive reference'}</div>
                 <div class="w3-third">
            <a href="{data($ms)}#{data($sd/@xml:id)}">{data($sd/@xml:id)}</a><br/>
            {if(count($sd//t:ref[@type='authFile']) ge 1) then 'Art Themes: ' || string-join(string:tei2string($sd//t:ref[@type='authFile']), ', ') else ()}
            </div>
            </div>

            </li>
                 }
            </ul>
            </div>
            
            )}

        </div>
        
    </div>
    )
    
};



declare function lists:corporaeditors ($editor as node()*){
 for $node in $editor
    return
        typeswitch ($node)
        case element(t:forename)
                return
                $node/text() || ' '
        case element(t:surname)
                return
                $node/text()

        case element(t:resp)
                return
                <i>{$node/text()}</i>
case element()
                return
                    lists:corporaeditors($node/node())
            default
                return
                    $node

};

declare function lists:corpora ($node as node(), $model as map(*)){
<div class="w3-responsive">
<table class="w3-table w3-hoverable">
<thead>
<tr>
<th>Title</th>
<th>Primary editor</th>
<th>Description</th>
<th>Contents</th>
<th>Statement of responsabilty</th>
</tr>
</thead>
<tbody>{
for $corpus in collection($config:data-root || '/corpora')//*:teiCorpus
let $id := string($corpus//t:TEI/@xml:id)
let $title := $corpus//t:titleStmt/t:title[@type='corpus']/text()
order by $title
return <tr>
<td><a href="/{$id}/corpus"><h4>{$title}</h4></a></td>
<td>{lists:corporaeditors($corpus//t:principal)}</td>
<td>{$corpus//t:projectDesc}</td>
<td><ul class="nodot">{for $document in $config:collection-rootMS//t:relation[contains(@passive, $id)]
let $rootid := string($document/@active)
let $mainid := substring-before($rootid, '#')
group by $ID := $mainid
return <li class="nodot"><a href="/{$ID}">{titles:printTitleID($ID)}</a></li>}</ul></td>
<td><ul class="nodot">{for $r in $corpus//t:respStmt return <li class="nodot">{lists:corporaeditors($r/node())}</li>}</ul></td>
</tr>

}</tbody></table></div>
};
