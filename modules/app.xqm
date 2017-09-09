xquery version "3.1" encoding "UTF-8";

module namespace app="https://www.betamasaheft.uni-hamburg.de/BetMas/app";

declare namespace t="http://www.tei-c.org/ns/1.0";
declare namespace functx = "http://www.functx.com";
declare namespace exist = "http://exist.sourceforge.net/NS/exist";
declare namespace skos = "http://www.w3.org/2004/02/skos/core#";
declare namespace rdf = "http://www.w3.org/1999/02/22-rdf-syntax-ns#";
declare namespace s = "http://www.w3.org/2005/xpath-functions";
declare namespace sparql = "http://www.w3.org/2005/sparql-results#";
import module namespace kwic = "http://exist-db.org/xquery/kwic"
    at "resource:org/exist/xquery/lib/kwic.xql";
import module namespace coord="https://www.betamasaheft.uni-hamburg.de/BetMas/coord" at "coordinates.xql";

import module namespace nav="https://www.betamasaheft.uni-hamburg.de/BetMas/nav" at "nav.xqm";
import module namespace templates="http://exist-db.org/xquery/templates" ;
import module namespace all="https://www.betamasaheft.uni-hamburg.de/BetMas/all" at "all.xqm";
import module namespace titles="https://www.betamasaheft.uni-hamburg.de/BetMas/titles" at "titles.xqm";
import module namespace config="https://www.betamasaheft.uni-hamburg.de/BetMas/config" at "config.xqm";
import module namespace console="http://exist-db.org/xquery/console";
import module namespace xdb = "http://exist-db.org/xquery/xmldb";
import module namespace httpclient="http://exist-db.org/xquery/httpclient";
import module namespace validation = "http://exist-db.org/xquery/validation";


declare variable $app:placeprefixes as xs:string := '
@prefix cnt: &lt;http://www.w3.org/2011/content#&gt; . 
@prefix dcterms: &lt;http://purl.org/dc/terms/&gt; .
@prefix foaf: &lt;http://xmlns.com/foaf/0.1/&gt; .
@prefix geo: &lt;http://www.w3.org/2003/01/geo/wgs84_pos#&gt; .
@prefix geosparql: &lt;http://www.opengis.net/ont/geosparql#&gt; .
@prefix gn: &lt;http://www.geonames.org/&gt; .
@prefix pleiades: &lt;https://pleiades.stoa.org/&gt; .
@prefix oa: &lt;http://www.w3.org/ns/oa#&gt; .
@prefix lawd: <http://lawd.info/ontology/> .
@prefix pelagios: &lt;http://pelagios.github.io/vocab/terms#&gt; .
@prefix relations: &lt;http://pelagios.github.io/vocab/relations#&gt; .
@prefix rdfs: &lt;http://www.w3.org/2000/01/rdf-schema#&gt; .
@prefix lawd: &lt;http://lawd.info/ontology/&gt; .
@prefix skos: &lt;http://www.w3.org/2004/02/skos/core#&gt; .
@prefix xsd: &lt;http://www.w3.org/2001/XMLSchema&gt; .' ;

(:declare variable $app:item-uri as xs:string := raequest:get-parameter('uri',());:)
declare variable $app:collection as xs:string := request:get-parameter('collection',());
declare variable $app:name as xs:string := request:get-parameter('name',());
declare variable $app:rest  as xs:string := '/rest/';

(:collects bibliographical information for zotero metadata:)
declare variable $app:bibdata := 
let $file := collection($config:data-root)//id($app:name)
return

(:here I cannot use for the title the javascript titles.js because the content is not exposed:)
<bibl>
{
for $author in distinct-values($file//t:revisionDesc/t:change/@who)
                return
<author>{app:editorKey(string($author))}</author>
}
<title level="a">{titles:printTitle($file)}</title>
<title level="j">{collection($config:data-root)//id($app:name)//t:publisher/text()}</title>
<date type="accessed"> [Accessed: {current-date()}] </date>
{let $time := max($file//t:revisionDesc/t:change/xs:date(@when))
return
<date type="lastModified">(Last Modified: {format-date($time, '[D].[M].[Y]')}) </date>
}
<idno type="url">
{($config:appUrl || $app:collection||'/' ||$app:name)}
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

(:for the annotations in pelagios, decide based on id how to format the uri:)
declare function app:getannotationbody($placeid as xs:string){
if(starts-with($placeid, 'INS')) then $config:appUrl || '/institutions/' || $placeid
else if(starts-with($placeid, 'LOC')) then $config:appUrl || '/places/' || $placeid
else if(starts-with($placeid, 'pleaides:')) then 'https://pleiades.stoa.org/places/' || substring-after($placeid, 'pleiades:')
else if(starts-with($placeid, 'Q')) then 'https://www.wikidata.org/wiki/' || $placeid
else 'http://sws.geonames.org/' || substring-after($placeid, 'gn:')
};

declare function app:annotatedThing($node, $tit, $id) as xs:string{
let $d := $node
let $r := $id
let $sr := string($r)
let $lang := if($d/t:placeName[.= $tit[1]]/@xml:lang) then '@' || $d/t:placeName[.= $tit[1]]/@xml:lang else ()
let $temporal := if($d//t:state[@type='existence'][@from or @to]) then for $existence in $d//t:state[@type='existence'][@from or @to] return let $from := string($existence/@from) let $to := string($existence/@to) return ('dcterms:temporal "' ||$from||'/'||$to||'";
 ') else ()
let $PeriodO := if($d//t:state[@type='existence'][@ref]) then for $periodExistence in  $d//t:state[@type='existence'][@ref]  let $periodid := string($periodExistence/@ref) let $period := collection($config:data-root)//id($periodid)[1] return ('dcterms:temporal <' || string(($period//t:sourceDesc//t:ref/@target)[1])|| '>;
 ') else ()
let $sameAs := if($d//@sameAs) then
' skos:exactMatch <' || app:getannotationbody($d//@sameAs[1]) ||'> ;
'else ()
let $names := for $name in $d/t:placeName
let $l := if($name/@xml:lang) then '@' || string($name/@xml:lang) else ()
return 
if($name/@xml:id = 'n1') 
then '
lawd:hasName [ lawd:primaryForm "'||normalize-space($name)||'"' ||$l|| ' ];'
else '
lawd:hasName [ lawd:variantForm "'||normalize-space($name)||'"' ||$l|| ' ];'

let $partof := if($d/t:settlement[@ref]) then let $setts := for $s in $d/t:settlement/@ref return 'dcterms:isPartOf <' || app:getannotationbody($s) || '>; 
'  return string-join($setts, ' 
')
else if ($d/t:region[@ref]) then let $regs := for $s in $d/t:region/@ref return 'dcterms:isPartOf <' || app:getannotationbody($s ) || '>;
'  return string-join($regs, ' 
')
else if ($d/t:country[@ref]) then let $countries := for $s in $d/t:country/@ref return  'dcterms:isPartOf <' || app:getannotationbody($s) || '>;
'  return string-join($countries, ' 
')
else ()
let $geo := if($d//t:geo/text()) then '
geo:location [ geo:lat '||substring-before($d//t:geo/text(), ' ')|| ' ;  geo:long '||substring-after($d//t:geo/text(), ' ')|| ' ] ;' else if($d//@sameAs[1]) then let $geoid := string($d//@sameAs[1]) let $coordinates := coord:GNorWD($geoid)  return if(starts-with($coordinates, 'no')) then () else '
geo:location [ geo:lat '||substring-before($coordinates, ',')|| ' ;  geo:long '||substring-after($coordinates, ',')|| ' ] ;' else ()
        
 return
 
 <annotatedThing id="{$r}">
 
             {'
             
             &lt;'||$config:appUrl || '/places/'||
 $sr||'&gt; a lawd:Place ;
  rdfs:label "' || 
 $tit[1] || '"' ||$lang ||';
 dcterms:source &lt;'||$config:appUrl || '/'||
 $sr||'.xml&gt; ;
 dcterms:description "A place in Ethiopia"@en ;
 '||string-join($temporal, '
') ||string-join($PeriodO, '
') ||$sameAs ||string-join($names, ' 
 ')||
 $geo||
 ' 
 foaf:primaryTopicOf &lt;'||$config:appUrl || '/places/' || 
                $sr || '/main&gt; ;
                ' ||
                $partof
                ||'
                .
                
                '}
   
   
 </annotatedThing>
 
 (: this should go into the <annotatedThing/> but I am not sure how to do it... 

<annotations>
 {for $thisd at $x in collection($config:data-rootW, $config:data-rootMS)//t:placeName[@ref = $r]
 return
 <annotation>{
' <http://betamasaheft.aai.uni-hamburg.de/att/'||$x||'> a lawd:Attestation ;
  dcterms:publisher <http://betamasaheft.aai.uni-hamburg.de/places/list/> ;
  cito:citesAsEvidence
    <http://www.mygazetteer.org/documents/01234> ;
  cnt:chars "Αθήνα" 
  .
 '
 }
 </annotation>
 }
 </annotations>:)
};

declare function app:pelagiosDump(){
   let $pl := collection($config:data-rootPl)
   let $in := collection($config:data-rootIn)
   let $plp := $pl//t:place
   let $inp := $in//t:place
   let $data := ($plp, $inp)
   let $txtarchive := '/db/apps/BetMas/ttl/'
   (: store the filename :)
   let $filename := concat('allplaces', format-dateTime(current-dateTime(), "[Y,4][M,2][D,2][H01][m01][s01]"), '.ttl')
   
   let $filecontent := 
       let $annotations := for $d in $data 
              let $r := root($d)//t:TEI/@xml:id
              let $i := string($r)
              let $tit := titles:printTitleID($i)
              let $annotatedthing := if($tit) then app:annotatedThing($d, $tit[1], $r) else ()
                order by $tit[1]
                 return
               $annotatedthing 
     return  $app:placeprefixes || string-join($annotations, ' ')
    
    (: create the new file with a still-empty id element :)
    let $store := xmldb:store($txtarchive, $filename, $filecontent)
    return
      'stored ' || $txtarchive || $filename
};

declare function app:Nbar($node as node()*, $model as map(*)){nav:bar()};
 declare function app:searchhelp($node as node()*, $model as map(*)){nav:searchhelp()};
declare function app:modals($node as node()*, $model as map(*)){nav:modals()};
declare function app:footer($node as node()*, $model as map(*)){nav:footer()};

declare function app:academics($node as node()*, $model as map(*)){
<div id="academics">
<h4>Scholars in Ethiopian Studies</h4>
<div class="card-columns">{
for $academic in collection($config:data-rootPr)//t:occupation[@type='academic']
let $title := normalize-space(string(titles:printTitle($academic)))
let $zoterurl := 'https://www.zotero.org/groups/ethiostudies/items/q/'||xmldb:encode-uri($title)
let $root := root($academic)
let $id := $root//t:TEI/@xml:id
let $date := ($root//t:body//t:*[@notBefore or @notAfter or @when], $root//t:floruit)
let $dates := ($date/@notBefore, $date/@notAfter, $date/@when)
let $years := for $d in $dates return if (contains(string($d), '-')) then substring-before(string($d),'-') else string($d)
let $mindate := min($years)
order by $mindate
return
<div class="card">
    <div class="card-block">
      <h4 class="card-title"><a href="/{string($id)}" target="_blank">{$title}</a></h4>
      <p class="card-text">{$academic/text()}</p>
      <p class="card-text"><small class="text-muted">{$mindate || ' - '||max($years)}</small></p>
      <p class="card-text academicBio">{transform:transform($root, 'xmldb:exist:///db/apps/BetMas/xslt/bio.xsl',())}</p>
      <p class="card-text"><a  href="{$zoterurl}" target="_blank">Items in Zotero EthioStudies</a></p>
 <p class="card-text">{if(starts-with($root//t:person/@sameAs, 'Q')) then app:wikitable(string($root//t:person/@sameAs)) else ($root//t:person/@sameAs)}</p>

    </div>
  </div>}
  </div>
  </div>
};


     

(:this function makes a call to wikidata API :)
declare function app:wikitable($Qitem) {
let $sparql := 'SELECT ?viafid ?viafidLabel WHERE {
   wd:' || $Qitem || ' wdt:P214 ?viafid .
   SERVICE wikibase:label {
    bd:serviceParam wikibase:language "en" .
   }
 }'

let $query := 'https://query.wikidata.org/sparql?query='|| xmldb:encode-uri($sparql)

let $req := httpclient:get(xs:anyURI($query), false(), <headers/>)

let $viafId := $req//sparql:result/sparql:binding[@name="viafidLabel"]
let $WDurl := 'https://www.wikidata.org/wiki/'||$Qitem
let $VIAFurl := 'https://viaf.org/viaf/'||$Qitem
(:returns the result in another small table with links:)
return
<table class="table table-responsive">
<tbody>
<tr>
<td>WikiData Item</td>
<td><a target="_blank" href="{$WDurl}">{$Qitem}</a></td>
</tr>
<tr>
<td>VIAF ID</td>
<td><a target="_blank" href="{$VIAFurl}">{$viafId}</a></td>
</tr>
</tbody>
</table>
};


(:  returns a responsive table with a list of the collection selected by parameter. 
The parameter is decided by the url call, which is handled by the controller. 
might be better as a proper view. :)
declare 
%templates:wrap %templates:default('start', 1) %templates:default("per-page", 20) 
function app:table($model as map(*), $start as xs:integer, $per-page as xs:integer) {
     let $items-info := $model('hits')
     let $collection := $model('collection')
return
<table class="table table-hover table-responsive">
                    <thead>
                        <tr>{
            if ($collection = 'works') then
                (<th>n°</th>,
                            <th>Titles</th>,
                            <th>Authors</th>,
                            <th>Witnesses</th>,
                            <th>Main parts</th>,
                            <th>Text</th>
                            )
            else
                if ($collection = 'places') then
                    (<th>Name</th>,
                                <th>geonames</th>,
                                <th>geoJson</th>)
                else
                    if ($collection = 'institutions') then
                        (<th>Name</th>,
                                    <th>Mss</th>,
                                <th>geonames</th>,
                                    <th>geoJson</th>)
                    else
                        if ($collection = 'persons') then
                            (<th>Name</th>,
                                        <th>Gender</th>,
                                        <th>Occupation</th>)
                        else
                            if ($collection = 'narratives') then
                                (<th>Name</th>,
                                            <th>Text</th>)
 else
                            if ($collection = 'authority-files') then
                                (<th>Name</th>)
else
                                (<th>Name</th>,
                                            <th>Images</th>,
                                            <th>Textual Units</th>,
                                            <th>Manuscript Parts</th>,
                                            <th>Hands</th>,
                                            <th>Script</th>,
                                            <th>Text</th>)
        }
                            <th>Dated</th>
                            <th>TEI-XML</th>
                            <th>Analytics</th>
    </tr>
                    </thead>
                   <tbody  class="ListItems">
                                        {
                                    for $hit at $p in subsequence($items-info, $start, $per-page)
                                   let $doc := doc(base-uri($hit))
            return
                                                   app:tr($doc, $collection)
                               
                             
                                    }
                                    </tbody>
                </table>
    
};


(:table rows and color code for change records:)
declare function app:tr($doc as node(), $list as xs:string) {

    <tr class="ListItems"
        style="{
                if (count($doc//t:change[@who != 'PL']) eq 1) then
                    'background-color:#ffefcc;'
                else
                    if ($doc//t:change[contains(., 'completed')]) then
                        'background-color:#e6ffff;'
                    else
                        if ($doc//t:change[contains(., 'reviewed')]) then
                            'background-color:#e6ffe6;'
                        else
                            'background-color:#ffe6e6;'
            }">
            
            {
            
            
           app:tds($doc, $list)
            
            }
       
    </tr>
    
};

(:function to print the values of parallel clavis ids:)
declare function app:clavisIds($doc as node()){
    
if($doc//t:listBibl[@type='clavis']) 
            then (
            <table class="table table-hover table-responsive">
            <thead>
            <tr>
            <th>clavis</th><th>id</th></tr>
            </thead>
            <tbody>
            {for $bibl in $doc//t:listBibl[@type='clavis']/t:bibl 
            return 
            <tr>
            <td>
            {string($bibl/@type) }
            </td>
            <td>
            <a href='{$bibl/@corresp}'>{$bibl/t:citedRange/text() }</a>
            </td>
            </tr>
            }
            </tbody>
            </table>
            ) else ()
};





(:table cells:)
declare function app:tds($item as node(), $list as xs:string) {

let $itemid := string($item/t:TEI/@xml:id)
let $itemtitle := titles:printTitleID($itemid)
   
return

(
if ($list = 'works') then (
(: id only works :)
<td><a
            href="/{$list}/{$itemid}/main">{substring($itemid, 4, 4)}</a>
            {app:clavisIds($item)}
            </td>)
            else if ( starts-with($list, 'bm:'))then (
(: link to main view from catalogues :)
<td><a
            href="/manuscripts/{$itemid}/main">{$itemtitle}</a>
            </td>) 
            else if ( starts-with($list, 'INS'))then (
(: link to list view for institutions :)
<td><a
            href="/manuscripts/{$itemid}/main">{$itemtitle}</a>
            </td>) 
            else if ($list = 'institutions') then (
(: link to list view for institutions :)
<td><a
            href="/manuscripts/{$itemid}/list">{$itemtitle}</a>
            </td>) 
    else
    (:  name ALL:)
        (<td><a
            href="/{$list}/{$itemid}/main" >{$itemtitle}</a></td>),
            
            
    if ($list = 'works') then
        (
   (:work titles:)
        <td><ul class="nodot">
                {
                    for $title in $item//t:titleStmt/t:title
                    return
                        <li>{$title/text()} {if ($title/@xml:lang) then (' (' || string($title/@xml:lang) || ')') else ()}</li>
                }
            </ul>
        </td>,
(:        work authors:)
        <td><ul class="nodot">
                {
                    for $author in $item//t:titleStmt/t:author
                    return
                        <li>{$author}</li>
                }
                {
                let $attributions := for $r in $item//t:relation[@name="saws:isAttributedToAuthor"]
                let $rpass := $r/@passive
                return 
                if (contains($rpass, ' ')) then tokenize($rpass, ' ') else $rpass
                    for $author in distinct-values($attributions)
                    return
                        <li><a href="{$author}"><mark>{try{titles:printTitleID($author)} catch*{$author//t:titleStmt/t:title[1]/text()}}</mark></a></li>
                }
            </ul>
        </td>,
(:        work witnesses:)
        <td>
            <ul  class="nodot">
                {
                    for $witness in $item//t:listWit/t:witness
                    let $corr := $witness/@corresp
                    return
                        <li><a
                                href="{$witness/@corresp}" class="MainTitle"  data-value="{$corr}" >{string($corr)}</a></li>
                }
            </ul>
            <ul  class="nodot">
                {
                    for $parallel in collection($config:data-root)//t:relation[@name='saws:isVersionOf'][contains(@passive, $itemid)]
                    let $p := $parallel/@active
                    return
                        <li><a
                                href="{$p}" class="MainTitle"  data-value="{$p}" >{$p}</a></li>
                }
            </ul>
            <ul  class="nodot">
                {
                    for $parallel in collection($config:data-root)//t:relation[@name='isVersionInAnotherLanguageOf'][contains(@passive, $itemid)]
                     let $p := $parallel/@active
                    return
                        <li><a
                                href="{$p}" class="MainTitle"  data-value="{$p}" >{$p}</a></li>
                }
            </ul>
            <a role="button" class="btn btn-primary btn-xs" href="/compare?workid={$itemid}">compare</a>
        </td>,
(:        work parts:)
        <td class="textparts">
            <ul  class="nodot">
              
            </ul>
        </td>)
    else
        if ($list = 'manuscripts' or starts-with($list, 'INS')  or starts-with($list, 'bm:')) then
        
(:      images  msitemsm msparts, hands, script:)
            (<td>{if($item//t:msIdentifier/t:idno/@facs) then 
                 <a target="_blank" href="/manuscripts/{$itemid}/viewer">{
                if($item//t:collection = 'Ethio-SPaRe') 
               then <img src="{string($item//t:msIdentifier/t:idno/@facs) || '_001.tif/full/80,100/0/default.jpg'}" class="thumb"/>
               (:BNF:)
            else if ($item//t:repository/@ref = 'INS0303BNF') 
            then <img src="{replace($item//t:msIdentifier/t:idno/@facs, 'ark:', 'iiif/ark:') || '/f1/full/80,100/0/native.jpg'}" class="thumb"/>
(:           vatican :)
                else <img src="{replace(substring-before($item//t:msIdentifier/t:idno/@facs, '/manifest.json'), 'iiif', 'pub/digit') || '/thumb/'
                    ||
                    substring-before(substring-after($item//t:msIdentifier/t:idno/@facs, 'MSS_'), '/manifest.json') || 
                    '_0001.tif.jpg'
                }" class="thumb"/>
                 }</a>
                
                else ()}</td>,
            <td>{count($item//t:msItem[not(t:msItem)])}</td>,
            <td>{
                    if (count($item//t:msPart) = 0) then
                        1
                    else
                        count($item//t:msPart)
                }</td>,
            <td>{count($item//t:handNote)}</td>,
            <td>{distinct-values(data($item//@script))}</td>
            )
        else
            if ($list = 'persons') then
(:            gender:)
                (
                <td>{
                    switch (data($item//t:person/@sex))
                            case "1"
                                return
                                    <i class="fa fa-male" aria-hidden="true"></i>
                            case "2"
                                return
                                   <i class="fa fa-female" aria-hidden="true"></i>
                            default return
                                ()
                }</td>,
                <td>{
                   let $occupation := $item//t:person/t:occupation
                           return 
                           $occupation/text()
                }</td>
            )
        else
            if ($list = 'institutions') then
(:            mss from same repo:)
                (
                <td>{
                        let $id := string($itemid)
                        let $mss := collection($config:data-rootMS)//t:repository[@ref = $id]
                        return
                            count($mss)
                    }</td>
                )
            else
                (),  
if ($list = 'places' or $list = 'institutions') then
(:geojson:)
    (<td>{
    let $geonames := substring-after($item//t:place/@sameAs, 'gn:')
    return
            if ($geonames) then
                <a
                    href="{('http://www.geonames.org/'||$geonames)}"
                    target="_blank">{$geonames}</a>
            else
                ()
        }</td>,
    <td>{
            if ($item//t:geo) then
                <a
                    href="{($itemid)}.json"
                    target="_blank"><span
                        class="glyphicon glyphicon-map-marker"></span></a>
            else
                ()
        }</td>)
else
    if ($list = 'works' or $list = 'manuscripts' or starts-with($list, 'INS') or starts-with($list, 'bm:') or $list = 'narratives') then
  
(:    text:)
        <td>
      {
  if ($item//t:div/t:ab) 
  then
         <a  href="{($list || '/' || $itemid || '/text')}"
                        target="_blank">text</a>
            else
                ()
        }
        </td>
else
    (),
    
(:    date, xml, analytics, seeAlso:)
<td>{
        if ($list = 'works' or $list = 'manuscripts' or $list = 'narratives' or $list = 'places' or $list = 'institutions') 
        
        then (
      let $dates :=
           for $date in ($item//t:date[@evidence = 'internal-date'],
        $item//t:origDate[@evidence = 'internal-date'], 
        $item//t:date[@type = 'foundation'], 
        $item//t:creation)
             
           return
          ('['||data($date/ancestor::t:*[@xml:id][1]/@xml:id)|| '] '||
                (if ($date/@when) then
                    data($date/@when)
                     else
                    if ($date/@notBefore or $date/@notAfter) then
                        ('between ' || (if ($date/@notBefore) then data($date/@notBefore) else ('?')) || ' and ' || (if ($date/@notAfter) then data($date/@notAfter) else ('?')))
                else
                    if ($date/@from or $date/@to) then
                        (data($date/@from) || '-' || data($date/@to))
                    else
                        $date))
                        
        return
        string-join($dates, ', ')
            ) 
         else if ($list = 'persons') then (
         if ($item//t:birth[@when or @notBefore or @notAfter or text()[. !='']] or 
        $item//t:death[@when or @notBefore or @notAfter  or text()[. !='']] or 
       $item//t:floruit[@when or @notBefore or @notAfter  or text()[. !='']])
        then(
         for $date in ($item//t:birth[@when or @notBefore or @notAfter or text()], 
         $item//t:death[@when or @notBefore or @notAfter or text()], 
         $item//t:floruit[@when or @notBefore or @notAfter or text()])
        return
        <p>{switch ($date/name())
        case 'birth' return 'b. '
        case 'death' return 'd. '
        default return 'f. ',
            if($date[@when]) 
            then string($date/@when)
            else if($date[@notBefore and @notAfter]) 
            then string($date/@notBefore) || '-'|| string($date/@notAfter)
            else if($date[@notBefore and not(@notAfter)]) 
            then 'after ' || string($date/@notBefore)
            else if($date[@notAfter and not(@notbefore)]) 
            then 'before ' || string($date/@notAfter) 
            else transform:transform($date, 'xmldb:exist:///db/apps/BetMas/xslt/dates.xsl',())  }</p>
           
         )
           else
            'N/A'
        )
        
       
         
            
            else 'N/A'
    }</td>,
<td><a
        href="{('/tei/' || $itemid || '.xml')}"
        target="_blank">XML</a></td>,
<td><a
        href="{($list || '/' || $itemid || '/analytic/')}"
        target="_blank"><span
            class="glyphicon glyphicon-list-alt"></span></a></td>
)
};




declare function app:newissue($node as node()*, $model as map(*)){
<a role="button" class="btn btn-warning btn-xs" target="_blank" href="https://github.com/BetaMasaheft/Documentation/issues/new?title={$app:name}&amp;labels[]={$app:collection}&amp;labels[]=app&amp;assignee=PietroLiuzzo&amp;body=There%20is%20an%20issue%20with%20{$app:name}">new issue</a>};


declare function app:AddFilters($node as node()*, $model as map(*), $filters as xs:string*) {
for $f in $filters
return
<div>{switch($f)
case 'language' return (
<div class="form-group list mss" data-toggle="tooltip" data-placement="left" title="Select Manuscript language">
                    <div class="col-md-6 col-xs-6">
                        <label class="control-label col-sm-3" for="language">Languages</label>
                        <div class="col-sm-9">
                            <span class="app:languages"/>
                        </div>
                    </div>
                    <div class="col-md-6 col-xs-6">Here you can filter entities which contain at least one part in a specific language.</div>
                </div>)
default return $f
}</div>
};

declare function app:nextID($collection as xs:string) {
if(contains(sm:get-user-groups(xmldb:get-current-user()), 'Cataloguers')) then (

<a role="button" class="btn btn-primary" target="_blank" href="/newentry.html?collection={$collection}">create new entry</a>) else ()
};

(:determins what the selectors for various form controls will look like:)
declare function app:selectors($nodeName, $nodes, $type){
<select multiple="multiple" name="{$nodeName}" id="{$nodeName}" class="form-control">
            {
            
                        if ($type = 'titles')
                                then ( for $n in $nodes[. != ''][. != ' ']
                                let $authfile := collection($config:data-rootA)//id($n)
                                 let $title := if ($authfile) then titles:printTitle($authfile) else $n
                                 order by $n
                                      return
                                   <option value="{$n}">{$title}</option>
                                               )
                    else if ($type = 'name')
                            then (for $n in $nodes[. != ''][. != ' ']
                                               order by $n/@xml:id
                                               return
            
                                                <option value="{$n/@xml:id}" >{titles:printTitle($n)}</option>
                                          )
            else if ($type = 'rels')
                     then (
                    
                 for $n in $nodes[. != ''][. != ' ']
                        let $item := if (contains($n, '#')) then (substring-before($n, '#'))  else $n
                       let $title :=  collection($config:data-root)//id($item)//t:titleStmt/t:title[1]
                            order by $title 
                             return
            
                             <option value="{$n}">{titles:printTitleID($item)}</option>
                        )
             else if ($type = 'hierels')
             then (
             for $n in $nodes[. != ''][. != ' '][not(starts-with(.,'#'))]
             group by $work := if (contains($n, '#')) then (substring-before($n, '#')) else $n
                            order by $work
                                return 
                                let $label :=
                                    try{
                                        if (collection($config:data-root)//id($work)) 
                                        then titles:printTitle(collection($config:data-root)//id($work)) 
                                        else $work} 
(:                                        this has to stay because optgroup requires label and this cannot be computed from the javascript as in other places:)
                                    catch* {
                                        console:log('while trying to create a list for the filter ' ||$nodeName || ' I got '|| $err:code ||': '||$err:description || ' about ' || $work), 
                                         $work}
                                return
                                if (count($n) = 1)
                                then <option value="{$work}" class="MainTitle" data-value="{$work}">{$work}</option>
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
                                 for $institutionId in $nodes[.=$institutions]
                            return
            
                            <option value="{$institutionId}" class="MainTitle" data-value="{$institutionId}">{$institutionId}</option>
                        )
            
            else if ($type = 'sex')
                     then (for $n in $nodes[. != ''][. != ' ']
                        let $key := replace(functx:trim($n), '_', ' ')
                         order by $n
                         return
                             <option value="{string($key)}">{switch($key) case '1' return 'Male' default return 'Female'}</option>
                        )
            else(for $n in $nodes[. != ''][. != ' ']
                let $key := replace(functx:trim($n), '_', ' ')
                order by $n
                return
            <option value="{$key}">{$key}</option>
            )
            }
        </select>
};

(:builds the form control according to the data specification:)
declare function app:formcontrol($nodeName as xs:string, $path, $group, $type) {

        

if ($group = 'true') then ( 

let $values := for $i in $path return  if (contains($i, ' ')) then tokenize($i, ' ') else if ($i=' ' or $i='' ) then () else functx:trim(normalize-space($i))
                    let $nodes := distinct-values($values)
                    
                    return <div class="form-group">
                    <label for="{$nodeName}">{$nodeName}s <span class="badge">{count($nodes[. != ''][. != ' '])}</span></label>
                    {
                  
   app:selectors($nodeName, $nodes, $type)     
   
        }
     </div>)
                else (
                
                let $nodes := for $node in $path return $node
            return
       app:selectors($nodeName, $nodes, $type)   
       
                )
};

declare function app:DataListWorks($node as node()*, $model as map(*)) {
        
            for $hit in collection($config:data-rootW)/t:TEI
            return
            <option xmlns="http://www.w3.org/1999/xhtml"  value="{$hit/@xml:id}">{titles:printTitle($hit)}</option>
           
                    };

(:the filters available in the list view of each collection:)
declare function app:listFilter($node as node()*, $model as map(*)) {
let $items-info := $model('hits')
let $onchange := 'if (this.value) window.location.href=this.value'
return
<div class="form-group">
<div class="input-group">
<input placeholder="go to..." class="form-control" id="GoTo" list="hits" onchange="{$onchange}" autocomplete="on"/>
<datalist xmlns="http://www.w3.org/1999/xhtml"  id="hits" class="hidden">
        
            {for $hit in $items-info
            return
            <option value="{$hit/@id}">{$hit/text()}</option>
            }
            </datalist><div class="input-group-btn">
<button type="submit" class="btn btn-primary"> Go
                    </button>
                    </div>
                    </div>

<form action="" class="form form-horizontal">

{if ($app:collection = 'persons') then (
app:formcontrol('occupation', $items-info//@occupation, 'true', 'values'),
app:formcontrol('role', $items-info//@role, 'true', 'values'),
app:formcontrol('gender', $items-info//@gender, 'true', 'sex')
)

else if ($app:collection = 'works' or $app:collection = 'narratives') then (
app:formcontrol('keyword', $items-info//@keyword, 'true', 'titles'),
                app:formcontrol('language', $items-info//@language, 'true', 'values'),
                app:formcontrol('author', $items-info//@author, 'true', 'rels'),
                app:formcontrol('ms', $items-info//@witness, 'true', 'hierels')

)

else if ($app:collection = 'places' or $app:collection = 'institutions') then (
app:formcontrol('placeType', $items-info//@placeType, 'true', 'values'),
app:formcontrol('tabot', $items-info//@tabot, 'true', 'rels'),
<div class="form-group">
<div class="input-group">

<input type="checkbox" name="geonames" value="gn">with geonames id</input>
</div>
</div>
                
)

(:manuscripts:)
                else (
                app:formcontrol('institution', $items-info//@institution, 'true', 'institutions'),
                app:formcontrol('script', $items-info//@script, 'true', 'values'),
                app:formcontrol('language', $items-info//@language, 'true', 'values'),
                app:formcontrol('support', $items-info//@support, 'true', 'values'),
                app:formcontrol('material', $items-info//@material, 'true', 'values'), 
                app:formcontrol('keyword', $items-info//@keyword, 'true', 'titles'),   
                app:formcontrol('scribe', $items-info//@scribe, 'true', 'rels'),
                app:formcontrol('donor', $items-info//@donor, 'true', 'rels'),
                app:formcontrol('patron', $items-info//@patron, 'true', 'rels'),
                app:formcontrol('content', $items-info//@content, 'true', 'hierels'), <div class="form-group">
            <label for="folia">Number of leaves</label>
            <div class="input-group">
                
             <input id="folia"  type="text" class="span2" 
                                name="folia" 
                                data-slider-min="1.0" 
                                data-slider-max="1000.0" 
                                data-slider-step="1.0" 
                                data-slider-value="[1,1000]"/>
                            <script type="text/javascript">
                                {"$('#folia').bootstrapSlider({});"}
                            </script>
<!--                            at 6 February the maximum number of leaves is 604-->
                            </div>
                    </div>,
                    <div class="form-group">
            <label for="wL">Number of written lines</label>
            <div class="input-group">
                
                            <input id="writtenLines" type="text" class="span2" 
                                name="wL" 
                                data-slider-min="1" 
                                data-slider-max="100" 
                                data-slider-step="1" 
                                data-slider-value="[1,100]"/>
                            <script type="text/javascript">
                                {"$('#writtenLines').bootstrapSlider({});"}
                            </script>
                            </div>
                            </div>
                
              )  
                }
                <div class="form-group"><label for="dates">date range</label><div class="input-group">
                
                <input id="dates" type="text" class="span2" 
                name="dateRange" 
                data-slider-min="0" 
                data-slider-max="2000" 
                data-slider-step="10" 
                data-slider-value="[0,2000]"/>
                <script type="text/javascript">
                {"$('#dates').bootstrapSlider({});"}
                </script>
            </div>
            </div>
            
                <button type="submit" class="btn btn-primary"> Filter
                    </button>
                    <a href="/{$app:collection}" role="button" class="btn btn-info">Full list</a>
</form>
</div>
};

(:the filters available in the search results view:)
declare function app:searchFilter($node as node()*, $model as map(*)) {
let $items-info := $model('hits')
let $q := $model('q')
return

<form action="" class="form form-horizontal">
                {app:formcontrol('language', $items-info//@xml:lang, 'true', 'values'),
                app:formcontrol('keyword', $items-info//t:term/@key, 'true', 'titles'),
               
                <div class="form-group container">
                <label for="dates">date range</label>
                <div class="input-group">
                <input id="dates" type="text" class="span2" 
                name="dateRange" 
                data-slider-min="0" 
                data-slider-max="2000" 
                data-slider-step="10" 
                data-slider-value="[0,2000]"/>
                <script type="text/javascript">
                {"$('#dates').bootstrapSlider({});"}
                </script>
            </div>
            </div>,
            <div>
  <input type="hidden" name="query" value="{$q}"/></div>
            }
                <button type="submit" class="btn btn-primary"> Filter
                    </button>
                <a href="/as.html" role="button" class="btn btn-primary">Advanced Search Form</a>
</form>
};


(:query parameters and corresponding filtering of the xpath context for ft:query:)

(:returns xpath as string to be later evaluated:)
declare function app:ListQueryParam($parameter, $context, $mode, $function){
let $paralist := request:get-parameter-names()
return
if(exists($paralist)) then(
let $allparamvalues := 
if (contains($paralist, $parameter)) 
then (request:get-parameter($parameter, ())) else 'all'
return
    if ($allparamvalues = 'all') 
    then () 
    else (
        let $keys := 
        if ($parameter = 'keyword')
        then (
        for $k in $allparamvalues 
      
        let $ks := doc($config:data-rootA || '/taxonomy.xml')//t:catDesc[text() = $k]/following-sibling::t:*/t:catDesc/text() 
        let $nestedCats := for $n in $ks return $n 
            return 
            if ($nestedCats >= 2) then (replace($k, '#', ' ') || ' OR ' || string-join($nestedCats, ' OR ')) else (replace($k, '#', ' '))
        )
        else(
            for $k in $allparamvalues 
            return 
            replace($k, '#', ' ') 
            )
            
       return 
       if ($function = 'list')
       then
       "[ft:query(" || $context || ", '" || string-join($keys, ' ') ||"')]"
       else 
       (:search:)
       let $limit := for $k in $allparamvalues 
            return 
            if($parameter = 'author')
            then "descendant::" || $context || "='" || $k ||"' or  descendant::t:relation[@name='dcterms:creator']/@passive ='"|| $k ||"'"
            else
       "descendant::" || $context || "='" || replace($k, ' ', '_') ||"' "
       return
       "[" || string-join($limit, ' or ') || "]"
       
       )
       )
       
       else ()
};

(:calls app:listQueryParam on each parameter of the query to build a full xpath query to be evaluated:)
declare function app:items($collection as xs:string?) {    
let $script := app:ListQueryParam('script', './/@script', 'any', 'list')
let $supp := app:ListQueryParam('support', './/t:objectDesc/@form', 'any', 'list')
let $repos := app:ListQueryParam('institution', './/t:repository/@ref', 'any', 'list')
let $mat := app:ListQueryParam('material', './/t:support/t:material/@key', 'any', 'list')
let $occ := app:ListQueryParam('occupation', './/t:occupation', 'all', 'list')
let $roles := app:ListQueryParam('role', './/t:roleName', 'any', 'list')
let $placeTypes := app:ListQueryParam('placeType', './/t:place/@type', 'any', 'list')
let $key := app:ListQueryParam('keyword', './/t:term/@key', 'any', 'list')
let $languages := app:ListQueryParam('language', './/t:language', 'any', 'list')
let $scribes := app:ListQueryParam('scribe', ".//t:persName[@role='scribe']/@ref", 'any', 'list')
let $donors := app:ListQueryParam('donor', ".//t:persName[@role='donor']/@ref", 'any', 'list')
let $patrons := app:ListQueryParam('patron', ".//t:persName[@role='patron']/@ref", 'any', 'list')
let $contents := app:ListQueryParam('content', ".//t:title/@ref", 'any', 'list')
let $mss := app:ListQueryParam('ms', ".//t:witness/@corresp", 'any', 'list')
let $authors := app:ListQueryParam('author', ".//t:relation[@name='saws:isAttributedToAuthor']/@passive", 'any', 'list')
let $authorsCertain := app:ListQueryParam('author', ".//t:relation[@name='dcterms:creator']/@passive", 'any', 'list')
let $tabots := app:ListQueryParam('tabot', ".//t:ab[@type='tabot']/t:persName/@ref", 'any', 'list')
let $genders := if (contains(request:get-parameter-names(), 'gender')) then '[.//t:person/@sex ='  ||request:get-parameter('gender', ()) || ' ]' else ()
let $geoname := if (contains(request:get-parameter-names(), 'geonames')) then '[.//t:place/@sameAs]' else ()
let $leaves :=  if (contains(request:get-parameter-names(), 'folia')) 
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
                "[ancestor::t:TEI//t:extent/t:measure[@unit='leaf'][not(@type)][number(.) >="||$min|| ' and number(.)  <= ' || $max ||"]]"
               ) else ()
let $wL :=  if (contains(request:get-parameter-names(), 'wL')) 
                then (
                let $range := request:get-parameter('wL', ())
                let $min := substring-before($range, ',') 
                let $max := substring-after($range, ',') 
                return
                if ($range = '1,100')
                then ()
                else if (empty($range))
                then ()
                else
                "[ancestor::t:TEI//@writtenLines[number(.) >="||$min|| ' and number(.)  <= ' || $max ||"]]"
               ) else ()
let $dateRange := 
                if (contains(request:get-parameter-names(), 'dateRange')) 
                then (
                let $range := request:get-parameter('dateRange', ())
                let $from := substring-before($range, ',') 
                let $to := substring-after($range, ',') 
                return
                if ($range = '0,2000')
                then ()
                else
                "[.//t:*[(if 
(contains(@notBefore, '-')) 
then (substring-before(@notBefore, '-')) 
else @notBefore)[. !=''][. >= " || $from || ' and .  <= ' || $to || "] 

or 
(if (contains(@notAfter, '-')) 
then (substring-before(@notAfter, '-')) 
else @notAfter)[. !=''][. >= " || $from || ' and .  <= ' || $to || '] 

]
]' ) else ()
            
    let $itemType := switch ($collection)
     case 'manuscripts' return 'mss'
         case 'works' return 'work'
         case 'narratives' return 'nar'
         case 'places' return 'place'
         case 'institutions' return 'ins'
         case 'persons' return 'pers'
         case 'authority-files' return 'auth'
         default return 'all'
   let $path := concat("collection('", 
         (if($collection = 'works') then $config:data-rootW 
         else if($collection = 'persons') then $config:data-rootPr
         else if($collection = 'institutions') then $config:data-rootIn
         else if($collection = 'manuscripts') then $config:data-rootMS
         else if($collection = 'narratives') then $config:data-rootN 
         else if($collection = 'authority-files') then $config:data-rootA 
         else if($collection = 'places') then $config:data-rootPl
         else $config:data-root)
         , "')//t:TEI", $repos, $script, $supp, $mat, $key, $occ, $roles, $placeTypes, $languages, $scribes, $donors, $patrons, $contents, $authors, $authorsCertain, $mss, $tabots, $genders, $dateRange, $geoname, $leaves, $wL)
         
let $hits :=
            for $resource in util:eval($path)
            let $root := root($resource)
            let $numericid := if ($root[@type = 'mss']) then $resource else if ($root[@type = 'pers']) then $resource else substring($resource/@xml:id, 4, 4)
            order by $numericid
            return 
            $resource
                    

let $store := ((:
                session:set-attribute("apps.BetMas", $hits),
                session:set-attribute("apps.BetMas.query", $collection),:)
                console:log('appitems results returned by query on '|| $collection || ': ' || count($hits))
            )

return
               map {'hits' : = $hits,
               'collection' := $collection}
                
                

};




(:  functions called by the ITEM template to determin what css and script to import according to the type of item and view
:  this way leaflet and mapbox are called only when there are coordinates to display in a map,
:  dataTable and vis.js are called only on the Analytics view
:)

(:stores the selected entity in a map:)
declare    %templates:wrap function app:entity($node as node(), $model as map(*), $id as xs:string?) {
    let $entity := collection($config:data-root)//t:TEI/id(replace($app:name, "^(.*)\.\w+$", "$1"))
    return
        map { "entity" := $entity }
};

(:decides which css to call:)
declare function app:cssSelector($node as node(), $model as map(*)) as element()* {
        
        if (contains(request:get-uri(), 'analytic') or contains(request:get-uri(), 'map') or contains(request:get-uri(), 'time')) then 
        <link xmlns="http://www.w3.org/1999/xhtml" rel="stylesheet" type="text/css" href="resources/css/dataTables.bootstrap.css"/>
        else (),
        
        if ((($app:collection = 'institutions' or $app:collection = 'places') and collection($config:data-root)//id($app:name)//t:geo) or contains(request:get-uri(), 'analytic'))
        then
        (
        <link xmlns="http://www.w3.org/1999/xhtml" rel="stylesheet" type="text/css" href="resources/css/mapbox.css"/>,
        <link xmlns="http://www.w3.org/1999/xhtml" rel="stylesheet" type="text/css" href="resources/css/leaflet.css"/>,
        <link xmlns="http://www.w3.org/1999/xhtml" rel="stylesheet" type="text/css" href="resources/css/leaflet.fullscreen.css"/>,
        <link xmlns="http://www.w3.org/1999/xhtml" rel="stylesheet" type="text/css" href="resources/css/leaflet-search.css"/>
        )
        else ()
        ,
        if (contains(request:get-uri(), 'analytic') or contains(request:get-uri(), 'map') or contains(request:get-uri(), 'time')) then 
        <link xmlns="http://www.w3.org/1999/xhtml" rel="stylesheet" type="text/css" href="https://cdnjs.cloudflare.com/ajax/libs/vis/4.12.0/vis.min.css"/>
        else ()
};

(:decides which js to call:)
declare function app:jsSelector($node as node(), $model as map(*)) as element()* {
        
        if ((($app:collection = 'institutions' or $app:collection = 'places') and collection($config:data-root)//id($app:name)//t:geo) or contains(request:get-uri(), 'analytic'))
        then
        (<script xmlns="http://www.w3.org/1999/xhtml" type="text/javascript" src="http://cdn.leafletjs.com/leaflet/v0.7.7/leaflet.js"/>,
        <script xmlns="http://www.w3.org/1999/xhtml" type="text/javascript" src="resources/js/mapbox.js"/>,
        <script  xmlns="http://www.w3.org/1999/xhtml"type="text/javascript" src="resources/js/Leaflet.fullscreen.min.js"/>,
        <script  xmlns="http://www.w3.org/1999/xhtml"type="text/javascript" src="resources/js/leaflet-search.js"/>
         )
        else ()
        ,
        
        <script type="text/javascript" src="http://code.jquery.com/jquery-1.11.1.min.js"></script>,
        
        <script src="https://code.jquery.com/ui/1.12.1/jquery-ui.min.js"></script>,
        <script type="text/javascript" src="http://code.jquery.com/jquery-migrate-1.2.1.min.js"></script>,        
        <script type="text/javascript" src="http://cdn.jsdelivr.net/jquery.slick/1.6.0/slick.min.js"></script>,
        

        <script xmlns="http://www.w3.org/1999/xhtml" type="text/javascript" src="$shared/resources/scripts/loadsource.js"/>,
        <script xmlns="http://www.w3.org/1999/xhtml" type="text/javascript" src="$shared/resources/scripts/bootstrap-3.0.3.min.js"/>,
        
        if (contains(request:get-uri(), 'analytic') or contains(request:get-uri(), 'map') or contains(request:get-uri(), 'time')) then (
        <script xmlns="http://www.w3.org/1999/xhtml" type="text/javascript" src="https://cdnjs.cloudflare.com/ajax/libs/vis/4.12.0/vis.min.js"/>,
        <script xmlns="http://www.w3.org/1999/xhtml" type="text/javascript" src="resources/js/jquery.dataTables.min.js"/>)
        else ()
      
};

declare function app:footerjsSelector($node as node(), $model as map(*)) as element()* {
        if (contains(request:get-uri(), 'analytic')) 
        then (<script xmlns="http://www.w3.org/1999/xhtml" type="text/javascript" src="resources/js/datatable.js"/>,
        <script xmlns="http://www.w3.org/1999/xhtml" type="text/javascript" src="resources/js/visgraphspec.js"/>) 
        else ()
        };


(:metadata for Zotero mapping:)

declare function app:title($node as node(), $model as map(*)) as element()* {  
<title xmlns="http://www.w3.org/1999/xhtml" property="dcterms:title og:title schema:name" class="MainTitle" data-value="{$app:name}">{$app:name}</title>
};

declare function app:meta($node as node(), $model as map(*)) as element()* {
    <meta  xmlns="http://www.w3.org/1999/xhtml" name="description" content="{$config:repo-descriptor/repo:description/text()}"/>,
    for $genauthor in $config:repo-descriptor/repo:author
    return
        <meta xmlns="http://www.w3.org/1999/xhtml" name="creator" content="{$genauthor/text()}"></meta> ,
         if (ends-with($app:name, 'html')) then ()
         else
         (for $author in $app:bibdata//author
         return 
         <meta  xmlns="http://www.w3.org/1999/xhtml" property="dcterms:creator schema:creator" content="{$author}"></meta>,
        
         <meta  xmlns="http://www.w3.org/1999/xhtml" property="dcterms:type schema:genre" content="{switch($app:collection)
         case 'manuscripts' return 'Catalogue of ethiopian manuscripts'
         case 'works' return 'Clavis of Ethiopian Literature'
         case 'narratives' return 'Clavis of Ethiopian Literature'
         case 'places' return 'Gazetteer of Places'
         case 'institutions' return 'Gazetteer of Places'
         case 'persons' return 'A prosopography of Ethiopia'
         default return 'catalogue'}"></meta>,
         <meta xmlns="http://www.w3.org/1999/xhtml" property="schema:isPartOf" content="{$config:appUrl}/"></meta>,
         <meta  xmlns="http://www.w3.org/1999/xhtml" property="og:site_name" content="Beta maṣāḥǝft: Manuscripts of Ethiopia and Eritrea"></meta>,
         <meta  xmlns="http://www.w3.org/1999/xhtml" property="dcterms:language schema:inLanguage" content="en"></meta>,
         <meta  xmlns="http://www.w3.org/1999/xhtml" property="dcterms:rights" content="Copyright &#169; Akademie der Wissenschaften in Hamburg, Hiob Ludolf Zentrum für Äthiopistik.  Sharing and remixing permitted under terms of the Creative Commons Attribution Share alike Non Commercial 4.0 License (cc-by-sa)."></meta>,
         <meta   xmlns="http://www.w3.org/1999/xhtml" property="dcterms:publisher schema:publisher" content="Akademie der Wissenschaften in Hamburg, Hiob Ludolf Zentrum für Äthiopistik"></meta>,
<meta  xmlns="http://www.w3.org/1999/xhtml" property="dcterms:date schema:dateModified" content="{max(collection($config:data-root)//id($app:name)//t:revisionDesc/t:change/xs:date(@when))}"></meta>,

<meta  xmlns="http://www.w3.org/1999/xhtml" property="dcterms:identifier schema:url" content="{($config:appUrl ||'/' || $app:collection||'/' ||$app:name)}"></meta>)
};


(:searches an ID in a @corresp, @ref, <relation> and makes a list :)
declare function app:WhatPointsHere($id as xs:string){
for $corr in (collection($config:data-root)//t:*[ft:query(@corresp, $id)], 
        collection($config:data-root)//t:*[ft:query(@ref, $id)], 
        collection($config:data-root)//t:relation[ft:query(., $id)])
        order by ft:score($corr) descending
        return 
            $corr
            
            };
           
           
            declare function app:restWhatPointsHere($id as xs:string, $c){
            let $witnesses := $c//t:witness[@corresp = $id]
let $placeNames := $c//t:placeName[@ref = $id]
let $persNames := $c//t:persName[@ref = $id]
let $titles := $c//t:title[@ref = $id]
let $active := $c//t:relation[@active = $id]
let $passive := $c//t:relation[@passive = $id]
let $allrefs := ($witnesses, 
        $placeNames,  
        $persNames, 
        $titles, 
        $active, 
        $passive)
return
for $corr in $allrefs
        return 
            $corr
            
            };

(:a list of items pointing to something:)
declare function app:AnyReferences($id as xs:string){
if($id = ' ' or $id = '') then ('no valid id') else
let $ref := try{app:WhatPointsHere($id)} catch * {console:log('app:WhatPointsHere has a problem with ' || $id )}
  return
<ul xmlns="http://www.w3.org/1999/xhtml" class="nodot"><head xmlns="http://www.w3.org/1999/xhtml" >This record, with ID: {string($id)} is mentioned by </head>
    {app:referencesList($ref, 'name')}

      </ul>
};


(:returns items in a  list of results from a references lookup:)
declare function app:referencesList($list, $mode as xs:string){
      
          for $hit in  $list
          
          let $strid := $hit/ancestor::t:TEI/@xml:id
          group by $stringid := string($strid)
          order by $stringid
      return 
         <li class="nodot" xmlns="http://www.w3.org/1999/xhtml" >
         {if ($strid = $app:name) then ('here') else <a 
          href="{concat('/',$stringid)}"
   class="MainTitle" data-value="{$stringid}"
   >{$stringid}</a>} ({$stringid})
   <ul  class="nodot">
   {for $h in $hit
   let $n := $h/name()
   group by $name := $n
   order by $name
   return
   <li class="nodot">a <code xmlns="http://www.w3.org/1999/xhtml" >{$name}</code> element {count($h)} time{if(count($h) > 1) then 's' else ()}
   {let $ids := for $each in $h return 
                      if ($h/ancestor::t:item/@xml:id) 
                     then data($h/ancestor::t:item/@xml:id) 
                     else if ($h/ancestor::t:msPart/@xml:id) 
                      then data($h/ancestor::t:msPart/@xml:id) else ()
      return ' ' || string-join($ids, ', ')}
   </li>
   }
   </ul>
         </li>
          
};

(: anything linking to the ID of the current entity, called by view-item.html under related entities:)
declare function app:corresps($node as node(), $model as map(*)){
<div xmlns="http://www.w3.org/1999/xhtml" id="whatPointsHere">
        
{app:AnyReferences(string($app:name))}
                
    </div>


};

declare function app:namedentitiescorresps($node as node(), $model as map(*)){
let $refs := 

for $r in (
$model('entity')//t:persName[not(ancestor::t:listPerson)][@ref], 
$model('entity')//t:title[@ref], 
$model('entity')//t:placeName[@ref], 
$model('entity')//t:region[@ref], 
$model('entity')//t:country[@ref], 
$model('entity')//t:settlement[@ref])

                       return <ref ref="{if (contains($r/@ref, '#')) then substring-before($r/@ref, '#') else string($r/@ref)}"></ref>
 let $corresps := 

for $r in $model('entity')//t:ref[@corresp]

                       return <ref ref="{if (contains($r/@corresp, '#')) then substring-before($r/@corresp, '#') else string($r/@corresp)}"></ref>
let $all := ($refs/@ref, $corresps/@ref)
for $namedEntity in distinct-values($all)
return
<div id="{$namedEntity}relations-all" class="hidden">
<div id="{$namedEntity}relations-content">
{app:AnyReferences($namedEntity)}
</div>
</div>
};


declare function app:getGeoNames ($string as xs:string){
let $gnid:= substring-after($string, 'gn:')
let $xml-url := concat('http://api.geonames.org/get?geonameId=',$gnid,'&amp;username=betamasaheft')
let $data := httpclient:get(xs:anyURI($xml-url), true(), <Headers/>)
return
if ($data//toponymName) then
$data//toponymName/text()
else ('no data from geonames', console:log($data))
};


(:The SEE ALSO section has ready made queries providing related contents, 
these are all dispalyed in divs with lists of which this is the template:)
declare function app:ModalRefsList($string as xs:string, $sameKey){
let $value := if (doc($config:data-rootA || '/taxonomy.xml')//t:catDesc[text() = $string] )
                           then collection($config:data-root)//id($string)//t:titleStmt/t:title/text()
                           else if (matches($string, 'gn:'))  then app:getGeoNames($string)
                           else if (matches($string, '(LOC|INS)(\d+)(\w+)')) 
                           then try {titles:printTitle(collection($config:data-rootPl, $config:data-rootIn)/id($string)//t:place)}
                           catch * {'no record'}
                           else $string
return   
    <div class="row-fluid">
     <h4>The following {count($sameKey)} entities also share the <a href="{if (matches($string, 'gn:'))  then ('http://www.geonames.org/'||substring-after($string, 'gn:')) else concat($config:appUrl,'/',$string)}">{$value}</a> tag </h4>
                                      <div id="Samekeyword{$string}">      
                                      <ul>{if (matches($string, '(\w{3})(\d+)(\w+)')) 
                                            then app:referencesList($sameKey, 'link')
                                               else  app:referencesList($sameKey, 'name')
                                             }
                                             </ul>
                                             </div>
                                    
                        </div>
};

(:makes a log of any page accessed:)
(:declare function app:log ($node as element(), $model as map(*)){
   
    BetMasLog:add-log-message('Visited ' || request:get-uri() || ' ' ||  request:get-parameter(
        switch (request:get-parameter-names()[1])
        case "collection" return 'collection'
        case "query" return 'query'
            default return "uri",()))
    
};:)

(:on login, print the name of the logged user:)
declare function app:greetings-rest(){
<a href="">Hi {xmldb:get-current-user()}!</a>
    };
(:on login, print the name of the logged user:)
declare function app:greetings($node as element(), $model as map(*)) as xs:string{
<a href="">Hi {xmldb:get-current-user()}!</a>
    };
    
 declare function app:logout(){
    session:invalidate()
    };




(:collects all the latest changes made to the collections and prints a list of twenty items:)
declare function app:latest($node as element(), $model as map(*)){

let $twoweekago := current-date() - xs:dayTimeDuration('P15D')
let $changes := collection($config:data-root)//t:change[@when]
let $latests := 
    for $alllatest in $changes[xs:date(@when) > $twoweekago]
    order by xs:date($alllatest/@when) descending
    return $alllatest

for $latest at $count in subsequence($latests, 1, 20)
let $id := string(root($latest)/t:TEI/@xml:id)
return
<li><a href="{$id}">{titles:printTitle($latest)}</a>: on {string($latest/@when)}, {app:editorKey($latest/@who)} [{$latest/text()}]</li>

};


declare function app:editorKey($key as xs:string){
switch ($key)
                        case "ES" return 'Eugenia Sokolinski'
                        case "DN" return 'Denis Nosnitsin'
                        case "MV" return 'Massimo Villa'
                        case "DR" return 'Dorothea Reule'
                        case "SG" return 'Solomon Gebreyes'
                        case "PL" return 'Pietro Maria Liuzzo'
                        case "SA" return 'Stéphane Ancel'
                        case "SD" return 'Sophia Dege'
                        case "VP" return 'Vitagrazia Pisani'
                        case "IF" return 'Iosif Fridman'
                        case "SH" return 'Susanne Hummel'
                        case "FP" return 'Francesca Panini'
                        case "DE" return 'Daria Elagina'
                        case "MK" return 'Magdalena Krzyzanowska'
                        case "VR" return 'Veronika Roth'
                        case "AA" return 'Abreham Adugna'
                        case "EG" return 'Ekaterina Gusarova'
                        case "IR" return 'Irene Roticiani'
                        case "MB" return 'Maria Bulakh'
                        case "NV" return 'Nafisa Valieva'
                        case "RHC" return 'Ran HaCohen'
                        case "SS" return 'Sisay Sahile'
                        default return 'Alessandro Bausi'};



(:prints the revision informations:)
declare function app:authors($node as node(), $model as map(*)) {

<div class="col-md-12" id="citations">
<div class="container-fluid col-md-4 well" id="citation">

<h3>Suggested Citation of this record</h3>
<div class="col-md-12" id="citationString">
<p>{for $a in $app:bibdata//author/text()  return ($a|| ', ')} ʻ{$app:bibdata//title[@level='a']/text()}ʼ, in Alessandro Bausi, ed.,
<i>{($app:bibdata//title[@level='j']/text() || ' ')}</i> {$app:bibdata//date[@type='lastModified']/text()}
<a href="{$app:bibdata/idno/text()}">{$app:bibdata/idno/text()}</a> {$app:bibdata//date[@type='accessed']/text()}</p></div>



</div>
<div class="container-fluid col-md-4 well" id="revisions">
<h3>Revisions of the data</h3>
                <ul>
                {for $change in $model('entity')//t:revisionDesc/t:change
                let $time := $change/@when
                let $author := app:editorKey(string($change/@who))
                order by $time descending
                return
                <li>
                {($author || ' ' || $change/text() || ' on ' ||  format-date($time, '[D].[M].[Y]'))}
                </li>
                }

    </ul>
    </div>
    <div class="container-fluid col-md-4 well" id="revisions">
<h3>Attributions of the contents</h3>
                <div>
                {for $respStmt in $model('entity')//t:titleStmt/t:respStmt
                let $action := $respStmt/t:resp
                let $authors := 
                            for $p in $respStmt/t:persName 
                                return 
                                    (if($p/@ref) then app:editorKey(string($p/@ref)) else $p) || (if($p/@from or $p/@to) then (' ('||'from '||$p/@from || ' to ' ||$p/@to||')') else ())
                                    
                                    
                order by $action descending
                return
                <p>
                {($action || ' by ' || string-join($authors, ', '))}
                </p>
                }

    </div>
    </div>
    </div>
    
};


(:general count of contributions to the data:)
declare function app:team ($node as node(), $model as map(*)) {
for $changes in distinct-values(collection($config:data-root)//t:change/@who)
order by $changes

return
<ul>{
    for $change in $changes
    let $changesBy := collection($config:data-root)//t:change/@who[ft:query(., string($change))]
    let $fileschanged := for $changedfile in $changesBy
                                                return
                                                root($changedfile)//t:TEI/@xml:id
    let $singlefileschanged  := distinct-values($fileschanged)                                          
   
   return
   <li class="lead">{app:editorKey($change)}  has <code>change</code>d <span class="badge">{count($changesBy)}</span> times <span class="badge">{count($singlefileschanged)}</span> files.  </li>
    }
</ul>

};

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

declare function app:elements($node as node(), $model as map(*)) {
    let $control :=
        <select xmlns="http://www.w3.org/1999/xhtml" multiple="multiple" id="element" name="element" class="form-control">
            
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

declare function app:work-types($node as node(), $model as map(*)) {
    let $control :=
        <select xmlns="http://www.w3.org/1999/xhtml" multiple="multiple" name="work-types" class="form-control" id="wt">
            <option value="all">All Work Types (includes authority files and narrative units)</option>
            <option value="mss">Manuscripts</option>
            <option value="place">Places</option>
            <option value="ins">Repositories</option>
            <option value="nar">Narrative Units</option>
            <option value="work">Text Units (Works)</option>
            <option value="pers">Persons</option>
        </select>
    return
        templates:form-control($control, $model)
};


declare function app:target-mss($node as node(), $model as map(*)) {
    let $control :=
        app:formcontrol('target-ms', collection($config:data-rootMS)//t:TEI, 'false', 'name')
        
    return
        templates:form-control($control, $model)
};

declare function app:target-works($node as node(), $model as map(*)) {
    let $control :=
    app:formcontrol('target-work', collection($config:data-rootW, $config:data-rootN)//t:TEI, 'false', 'name')
        
    return
        templates:form-control($control, $model)
};

declare function app:target-ins($node as node(), $model as map(*)) {
    let $control :=
    app:formcontrol('target-ins', collection($config:data-rootIn)//t:TEI, 'false', 'name')
        
    return
        templates:form-control($control, $model)
};


(:MANUSCRIPTS FILTERS for CONTEXT:)
declare function app:scripts($node as node(), $model as map(*)) {
    let $scripts := distinct-values(collection($config:data-rootMS)//@script)
    
   let $control :=
   app:formcontrol('script', $scripts, 'false', 'values')
       
    return
        templates:form-control($control, $model)
};

declare function app:support($node as node(), $model as map(*)) {
    let $forms := distinct-values(collection($config:data-rootMS)//@form)
    
   let $control :=
        app:formcontrol('support', $forms, 'false', 'values')
    return
        templates:form-control($control, $model)
};

declare function app:material($node as node(), $model as map(*)) {
    let $materials := distinct-values(collection($config:data-rootMS)//t:support/t:material/@key)
    
   let $control :=
         app:formcontrol('material', $materials, 'false', 'values')
    return
        templates:form-control($control, $model)
};

declare function app:bmaterial($node as node(), $model as map(*)) {
    let $bmaterials := distinct-values(collection($config:data-rootMS)//t:decoNote[@type='bindingMaterial']/t:material/@key)
    
   let $control :=
        app:formcontrol('bmaterial', $bmaterials, 'false', 'values')
    return
        templates:form-control($control, $model)
};



(:PLACES FILTERS for CONTEXT:)
declare function app:placeType($node as node(), $model as map(*)) {
    let $placeTypes := distinct-values(collection($config:data-rootPl,$config:data-rootIn)//t:place/@type/tokenize(., '\s+'))
    
   let $control :=
        app:formcontrol('placeType', $placeTypes, 'false', 'values')
    return
        templates:form-control($control, $model)
};

declare function app:personType($node as node(), $model as map(*)) {
    let $persTypes := distinct-values(collection($config:data-rootPr)//t:person//t:occupation/@type/tokenize(., '\s+'))
    
   let $control :=
        app:formcontrol('persType', $persTypes, 'false', 'values')
    return
        templates:form-control($control, $model)
};

declare function app:relationType($node as node(), $model as map(*)) {
    let $relTypes := distinct-values(collection($config:data-root)//t:relation/@name/tokenize(., '\s+'))
    
   let $control :=
        app:formcontrol('relType', $relTypes, 'false', 'values')
    return
        templates:form-control($control, $model)
};

declare function app:keywords($node as node(), $model as map(*)) {
    let $keywords := collection($config:data-rootA)//t:TEI
    
   let $control :=
   app:formcontrol('keyword', $keywords, 'false', 'name')
       
    return
        templates:form-control($control, $model)
};

declare function app:languages($node as node(), $model as map(*)) {
    let $keywords := distinct-values(collection($config:data-rootMS)//t:language)
    
   let $control :=
   app:formcontrol('language', $keywords, 'false', 'values')
       
    return
        templates:form-control($control, $model)
};

declare function app:scribes($node as node(), $model as map(*)) {
      let $keywords := distinct-values(collection($config:data-rootMS)//t:persName[@role='scribe']/@ref [not(.= 'PRS00000') and not(.= 'PRS0000')])
    
   let $control :=
   app:formcontrol('scribe', $keywords, 'false', 'rels')
       
    return
        templates:form-control($control, $model)
};

declare function app:donors($node as node(), $model as map(*)) {
       let $keywords := distinct-values(collection($config:data-rootMS)//t:persName[@role='donor']/@ref [not(.= 'PRS00000') and not(.= 'PRS0000')])
    
   let $control :=
   app:formcontrol('donor', $keywords, 'false', 'rels')
       
    return
        templates:form-control($control, $model)
};

declare function app:patrons($node as node(), $model as map(*)) {
       let $keywords := distinct-values(collection($config:data-rootMS)//t:persName[@role='patron']/@ref [not(.= 'PRS00000') and not(.= 'PRS0000')])
    
   let $control :=
   app:formcontrol('patron', $keywords, 'false', 'rels')
       
    return
        templates:form-control($control, $model)
};

declare function app:owners($node as node(), $model as map(*)) {
    let $keywords := distinct-values(collection($config:data-rootMS)//t:persName[@role='owner']/@ref [not(.= 'PRS00000') and not(.= 'PRS0000')])
    
   let $control :=
   app:formcontrol('owner', $keywords, 'false', 'rels')
       
    return
        templates:form-control($control, $model)
};
declare function app:binders($node as node(), $model as map(*)) {
      let $keywords := distinct-values(collection($config:data-rootMS)//t:persName[@role='binder']/@ref [not(.= 'PRS00000') and not(.= 'PRS0000')])
    
   let $control :=
   app:formcontrol('binder', $keywords, 'false', 'rels')
       
    return
        templates:form-control($control, $model)
};

declare function app:parmakers($node as node(), $model as map(*)) {
    let $keywords := distinct-values(collection($config:data-rootMS)//t:persName[@role='parchmentMaker']/@ref [not(.= 'PRS00000') and not(.= 'PRS0000')])
    
   let $control :=
   app:formcontrol('parchmentMaker', $keywords, 'false', 'rels')
       
    return
        templates:form-control($control, $model)
};

declare function app:contents($node as node(), $model as map(*)) {
    let $keywords := distinct-values(collection($config:data-rootMS)//t:msItem[not(contains(@xml:id, '.'))]/t:title/@ref)
  return
   app:formcontrol('content', $keywords, 'false', 'hierels')
   
};

declare function app:mss($node as node(), $model as map(*)) {
    let $keywords := for $r in collection($config:data-rootW)//t:witness/@corresp return string($r)|| ' '
    
   return
   app:formcontrol('ms', $keywords, 'false', 'hierels')
       
};

declare function app:WorkAuthors($node as node(), $model as map(*)) {
let $works := collection($config:data-rootW)
let $attributions := for $rel in ($works//t:relation[@name="saws:isAttributedToAuthor"], $works//t:relation[@name="dcterms:creator"])
let $r := $rel/@passive
                return 
                if (contains($r, ' ')) then tokenize($r, ' ') else $r  

let $keywords := distinct-values($attributions)
  return
   app:formcontrol('author', $keywords, 'false', 'rels')
   
};

declare function app:tabots($node as node(), $model as map(*)) {
    let $keywords := distinct-values(collection($config:data-rootPl, $config:data-rootIn)//t:ab[@type='tabot']/t:persName/@ref)
  return
   app:formcontrol('tabot', $keywords, 'false', 'rels')
   
};


(:IDS, TITLES, PERSNAMES, PLACENAMES, provide lists with guessing based on typing. the list must suggest a name but search for an ID:)

declare function app:BuildSearchQuery($element as xs:string, $query as xs:string){
let $SearchOptions :=
    <options>
        <default-operator>or</default-operator>
        <phrase-slop>0</phrase-slop>
        <leading-wildcard>yes</leading-wildcard>
        <filter-rewrite>yes</filter-rewrite>
    </options>
    return
concat("descendant::t:", $element, "[ft:query(., '" , $query, "', ", serialize($SearchOptions) ,")]")
};

(:~
    Execute the query. The search results are not output immediately. Instead they
    are passed to nested templates through the $model parameter.
:)

declare  function app:xpathQuery($node as node(), $model as map(*), $xpath as xs:string?) {
if(empty($xpath)) then 'Please enter a well formed Xpath expression' else 
let $hits := for $hit in (util:eval($xpath), console:log('direct xpath requested: ' || $xpath))
return $hit
 return            
map {"hits": $hits, "path": $xpath}
         
    };
    
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
    ("[descendant::t:"||$path||"[. <=" || $from ||' ][ .  <= ' || $to || "]]")
    
    };


declare 
    %templates:default("scope", "narrow")
    %templates:default("work-types", "all")
    %templates:default("target-ms", "all")
    %templates:default("target-work", "all")
    %templates:default("element",  "placeName", "title", "persName", "ab", "floruit", "p", "note")
function app:query(
$node as node()*, 
$model as map(*), 
$query as xs:string*, 
    $work-types as xs:string+,
    $element as xs:string+,
    $target-ms as xs:string+,
    $target-work as xs:string+
   ) {
    let $parameterslist := request:get-parameter-names()
     let $collection := app:ListQueryParam('work-types', '@type', 'any', 'search')
    let $script := app:ListQueryParam('script', '@script', 'any', 'search')
    let $mss := app:ListQueryParam('target-ms', '@xml:id', 'any', 'search')
    let $texts := app:ListQueryParam('target-work', '@xml:id', 'any', 'search')
    let $support := app:ListQueryParam('support', 't:objectDesc/@form', 'any', 'search')
    let $material := app:ListQueryParam('material', 't:support/t:material/@key', 'any', 'search')
    let $bmaterial := app:ListQueryParam('bmaterial', "t:decoNote[@type='bindingMaterial']/t:material/@key", 'any', 'search')
    let $placeType := app:ListQueryParam('placeType', 't:place/@type', 'any', 'search') 
    let $personType := app:ListQueryParam('personType', 't:person//t:occupation/@type', 'any', 'search')
    let $relationType := app:ListQueryParam('relType', 't:relation/@name', 'any', 'search')
    let $repository := app:ListQueryParam('target-ins', 't:repository/@ref ', 'any', 'search')
    let $keyword := app:ListQueryParam('keyword', 't:term/@key ', 'any', 'search')
    let $languages := app:ListQueryParam('language', 't:language', 'any', 'search')
let $scribes := app:ListQueryParam('scribe', "t:persName[@role='scribe']/@ref", 'any',  'search')
let $donors := app:ListQueryParam('donor', "t:persName[@role='donor']/@ref", 'any',  'search')
let $patrons := app:ListQueryParam('patron', "t:persName[@role='patron']/@ref", 'any', 'search')
let $owners := app:ListQueryParam('owner', "t:persName[@role='owner']/@ref", 'any',  'search')
let $parchmentMakers := app:ListQueryParam('parchmentMaker', "t:persName[@role='parchmentMaker']/@ref", 'any',  'search')
let $binders := app:ListQueryParam('binder', "t:persName[@role='binder']/@ref", 'any',  'search')
let $contents := app:ListQueryParam('content', "t:title/@ref", 'any', 'search')
let $mss := app:ListQueryParam('ms', "t:witness/@corresp", 'any', 'search')
let $authors := app:ListQueryParam('author', "t:relation[@name='saws:isAttributedToAuthor']/@passive", 'any', 'search')
(:let $authorsCertain := app:ListQueryParam('author', "t:relation[@name='dcterms:creator']/@passive", 'any', 'search'):)
let $tabots := app:ListQueryParam('tabot', "t:ab[@type='tabot']/t:persName/@ref", 'any', 'search')
let $references := if (contains($parameterslist, 'references')) then let $refs := for $ref in tokenize(request:get-parameter('references', ()), ',') return "[descendant::t:*/@*[not(name()='xml:id')] ='"  ||$ref || "' ]" return string-join($refs, '') else ()
let $genders := if (contains($parameterslist, 'gender')) then '[descendant::t:person/@sex ='  ||request:get-parameter('gender', ()) || ' ]' else ()
let $leaves :=  if (contains($parameterslist, 'folia')) 
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
                "[descendant::t:extent/t:measure[@unit='leaf'][not(@type)][. >="||$min|| ' ][ .  <= ' || $max ||"]]"
               ) else ()
let $wL :=  if (contains($parameterslist, 'wL')) 
                then (
                let $range := request:get-parameter('wL', ())
                let $min := substring-before($range, ',') 
                let $max := substring-after($range, ',') 
                return
                if ($range = '1,100')
                then ()
                else if (empty($range))
                then ()
                else
                "[descendant::t:layout[@writtenLines >="||$min|| '][@writtenLines  <= ' || $max ||"]]"
               ) else ()
let $quires :=  if (contains(request:get-parameter-names(), 'qn')) 
                then (app:paramrange('qn', "extent/t:measure[@unit='quire'][not(@type)]")
               ) else ()
let $dateRange := 
                if (contains(request:get-parameter-names(), 'dateRange')) 
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
else @notBefore)[. !=''][. >= " || $from || '][.  <= ' || $to || "] 

or 
(if (contains(@notAfter, '-')) 
then (substring-before(@notAfter, '-')) 
else @notAfter)[. !=''][. >= " || $from || '][.  <= ' || $to || '] 

]
]' ) else ()
   let $height :=   if (contains($parameterslist, 'height')) then (app:paramrange('height', 'height')) else ()
   let $width :=  if (contains($parameterslist, 'width')) then (app:paramrange('width', 'width')) else ()
   let $depth :=  if (contains($parameterslist, 'depth')) then (app:paramrange('depth', 'depth')) else ()
   let $marginTop :=  if (contains($parameterslist, 'tmargin')) then (app:paramrange('tmargin', "dimension[@type='margin']/t:dim[@type='top']")) else ()
   let $marginBot :=  if (contains($parameterslist, 'bmargin')) then (app:paramrange('tmargin', "dimension[@type='margin']/t:dim[@type='bottom']")) else ()
   let $marginR :=  if (contains($parameterslist, 'rmargin')) then (app:paramrange('tmargin', "dimension[@type='margin']/t:dim[@type='right']")) else ()
   let $marginL :=  if (contains($parameterslist, 'lmargin')) then (app:paramrange('tmargin', "dimension[@type='margin']/t:dim[@type='left']")) else ()
   let $marginIntercolumn :=  if (contains($parameterslist, 'intercolumn')) then (app:paramrange('intercolumn', "dimension[@type='margin']/t:dim[@type='intercolumn']")) else ()
                
                
                
        let $query-string := if ($query) then all:substitutionsInQuery($query) else ()
   

let $eachworktype := for $wtype in request:get-parameter('work-types', ()) 
                                   return  "@type='"|| $wtype || "'"
        
         let $wt := if(contains($parameterslist, 'work-types')) then "[" || string-join($eachworktype, ' or ') || "]" else ()
         
let $queryExpr := $query-string
    return
        if (empty($queryExpr) or $queryExpr = "") then
          (if(empty($parameterslist)) then () else ( let $hits := 
             let $path := concat("collection('",$config:data-root,"')//t:TEI", $wt, $repository, $mss, $texts, $script, $support, $material, $bmaterial, $placeType, $personType, $relationType, $keyword, $languages, $scribes, $donors, $patrons, $owners, $parchmentMakers, $binders, $contents, $mss, $authors, $tabots, $genders, $dateRange, $leaves, $wL, $references, $height, $width, $depth, $marginTop, $marginBot, $marginL, $marginR, $marginIntercolumn)
             
             return
                   for $hit in util:eval($path)
                   return $hit
                 
            
            return
                map {
                    "hits" := $hits,
                    "type" := 'records'
                    
                } ))
        else
           
           (:let $items := 
            let $elements : =
              for $e in $element
              return 
                       (util:eval(concat(app:BuildSearchQuery($e, $query-string), $collection, $repository, $mss, $texts, $script, $support, $material, $bmaterial, $placeType, $personType, $relationType, $keyword, $languages, $scribes, $donors, $patrons, $owners, $parchmentMakers, $binders, $contents, $mss, $authors, $authorsCertain, $tabots, $genders, $dateRange, $leaves, $wL, $references, $height, $width, $depth ))
                       ,
                       console:log(concat(app:BuildSearchQuery($e, $query-string), $collection, $repository, $mss, $texts, $script, $support, $material, $bmaterial, $placeType, $personType, $relationType, $keyword, $languages, $scribes, $donors, $patrons, $owners, $parchmentMakers, $binders, $contents, $mss, $authors, $authorsCertain, $tabots, $genders, $dateRange, $leaves, $wL, $references, $height, $width, $depth)))
                       for $result in $elements
                       let $resource := root($result)//t:TEI
                    order by ft:score($result) descending
                    return
                    $resource:)
          
          let $hits :=

                 let $elements : =
                   for $e in $element
                   return 
                   app:BuildSearchQuery($e, $query-string)
                   
                   let $allels := string-join($elements, ' or ')
                   let $path:=    concat("collection('",$config:data-root,"')//t:TEI[",$allels, "]", $wt, $repository, $mss, $texts, $script, $support, $material, $bmaterial, $placeType, $personType, $relationType, $keyword, $languages, $scribes, $donors, $patrons, $owners, $parchmentMakers, $binders, $contents, $mss, $authors, $tabots, $genders, $dateRange, $leaves, $wL, $references, $height, $width, $depth, $marginTop, $marginBot, $marginL, $marginR, $marginIntercolumn)
                   
                   for $hit in util:eval($path)
                    order by ft:score($hit) descending
                    return $hit
                    
              
              
            let $store := (
                session:set-attribute("apps.BetMas", $hits),
                session:set-attribute("apps.BetMas.query", $queryExpr)
            )
            return
                (: Process nested templates :)
                (map {
                    "hits" := $hits,
                    "q" := $query,
                    "type" := 'matches',
                    "query" := $queryExpr
                }, console:log('Initial query: ' || $query ||'; Requested query passed to lucene: '|| $queryExpr))
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
            let $luceneXML := util:parse($query-string)
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
    if ($model('type') = 'matches') then <h3>You found "{$app:searchphrase}" in <span xmlns="http://www.w3.org/1999/xhtml" id="hit-count">{ count($model("hits")) }</span> results</h3> else (<h3> There are <span xmlns="http://www.w3.org/1999/xhtml" id="hit-count">{ count($model("hits")) }</span> entities matching your query. </h3>),
    <div>{
                    for $param in request:get-parameter-names()
                    for $value in request:get-parameter($param, ())
                    return
                    if ($param = 'start') then ()
                    else if ($param = 'query') then ()
                    else if ($param = 'dateRange') 
                     then (<button type="button" class="btn btn-sm btn-info">{'between ' || substring-before(request:get-parameter('dateRange', ()), ',') || ' and ' || substring-after(request:get-parameter('dateRange', ()), ',')}</button>)
                    else
                        <button type="button" class="btn btn-sm btn-info">{($param || ": ", <span class="badge">{$value}</span>)}</button>
                }</div>
};

declare function app:list-count($node as node()*, $model as map(*)) {
    <h3>{$app:collection || ' '}{string-join(
                    for $param in request:get-parameter-names()
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
        let $count := xs:integer(ceiling(count($model("hits"))) div $per-page) + 1
        let $middle := ($max-pages + 1) idiv 2
        let $params :=
                string-join(
                    for $param in request:get-parameter-names()
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


 
declare function app:minified($resource as node()){
let $typ := $resource/@type
return
 element item{
                    attribute uri {base-uri($resource)},
                    attribute name {util:unescape-uri(replace(base-uri($resource), ".+/(.+)$", "$1"), "UTF-8")},
                    attribute id {string($resource/@xml:id)},
                    attribute type {string($typ)},
                    switch ($typ)
                    case 'mss' return
                        (
                        attribute support {for $r in $resource//@form return string($r) || ' '},
                        attribute institution {for $r in $resource//t:repository/@ref return string($r)|| ' '},
                        attribute script {for $r in $resource//@script return string($r)|| ' '},
                        attribute material {for $r in $resource//t:support/t:material/@key return string($r)|| ' '},
                        attribute keyword {for $r in $resource//t:term/@key return string($r)|| ' '},
                        attribute language {for $r in $resource//t:language return string($r)|| ' '},
                        attribute content {for $r in $resource//t:msItem[not(contains(@xml:id, '.'))]/t:title/@ref return string($r)|| ' '},
                        attribute scribe {for $r in $resource//t:persName[@role='scribe'][not(@ref= 'PRS00000')][not(@ref= 'PRS0000')] return string($r)|| ' '},
                        attribute donor {for $r in $resource//t:persName[@role='donor'][not(@ref= 'PRS00000')][not(@ref= 'PRS0000')]  return string($r)|| ' '},
                        attribute patron {for $r in $resource//t:persName[@role='patron'][not(@ref= 'PRS00000')][not(@ref= 'PRS0000')]  return string($r)|| ' '})
                         case 'pers' return 
                       (attribute occupation {for $r in  $resource//t:occupation return replace(normalize-space($r), ' ','_')|| ' '},
                        attribute role {for $r in  $resource//t:person/t:persName/t:roleName return replace(normalize-space($r), ' ','_')|| ' '},
                        attribute gender {$resource//t:person/@sex })
                        case 'place' return 
                        (attribute placeType {for $r in  $resource//t:place/@type return string($r)|| ' '},
                        attribute geonames {substring-after($resource//t:place/@sameAs, 'gn:')},
                        attribute tabot {for $r in $resource//t:ab[@type='tabot']/t:persName/@ref return string($r)|| ' '})
                        case 'ins' return 
                        (attribute placeType {for $r in  $resource//t:place/@type return string($r)|| ' '},
                        attribute tabot {for $r in $resource//t:ab[@type='tabot']/t:persName/@ref return string($r)|| ' '})
                         case 'work' return 
                        (attribute keyword {for $r in  $resource//t:term/@key return string($r)|| ' '},
                        attribute language {for $r in $resource//t:language return string($r)|| ' '},
                        attribute author {for $r in ($resource//t:relation[@name="saws:isAttributedToAuthor"], $resource//t:relation[@name="dcterms:creator"]) return string($r/@passive)|| ' '},
                        attribute witness {for $r in $resource//t:witness/@corresp return string($r)|| ' '})
                         case 'narr' return 
                        (attribute keyword {for $r in $resource//t:term/@key return string($r)|| ' '},
                        attribute language {for $r in $resource//t:language return string($r)|| ' '},
                        attribute author {for $r in ($resource//t:relation[@name="saws:isAttributedToAuthor"], $resource//t:relation[@name="dcterms:creator"]) return string($r/@passive)|| ' '})
                    default return (),
                    titles:printTitle($resource)
                    }
                    };

(: FROM SHAKESPEAR :)

declare function app:switchcol($type){
    
    switch($type)
        case 'work' return 'works'
        case 'narr' return 'narratives'
        case 'pers' return 'persons'
        case 'place' return 'places'
        case 'ins' return 'institutions'
        case 'auth' return 'authority-files'
        default return 'manuscripts'
    
};

declare    
%templates:wrap
    %templates:default('start', 1)
    %templates:default("per-page", 10) 
    function app:searchRes (
    $node as node()*, 
    $model as map(*), $start as xs:integer, $per-page as xs:integer) {
        
        switch($model("type"))
        case 'matches' return
    for $text at $p in subsequence($model("hits"), $start, $per-page)
        let $expanded := kwic:expand($text)
         let $count := count($expanded//exist:match)
        let $root := root($text)
        let $id := data($root/t:TEI/@xml:id)
        let $collection := app:switchcol($root/t:TEI/@type)
        let $score as xs:float := ft:score($text)
         return
            <div class="row reference">
            <div class="col-md-4">
            <div class="col-md-2">
                <span class="number">{$start + $p - 1}</span>
                </div>
             <div class="col-md-8"><a href="/{$collection}/{$id}/main">{titles:printTitleID($id)}</a> ({$id})</div>
                       <div class="col-md-2">
                <span class="badge">{$count}</span>
                </div>
            </div>
            
            <div class="col-md-8">
                 <div class="col-md-8">{kwic:summarize($text,<config width="40"
                        />)}</div>
                        
                        <div class="col-md-4">{data($text/ancestor::t:*[@xml:id][1]/@xml:id)}</div>
                        </div>
                    </div>
       
                default return 
                
         for $text at $p in subsequence($model("hits"), $start, $per-page)
        let $root := root($text)
        let $id := data($root/t:TEI/@xml:id)
        let $collection := app:switchcol($root/t:TEI/@type)
         return
            <div class="row reference">
                <div class="col-md-2"><span class="number">{$start + $p - 1}</span></div>
                        <div class="col-md-5"><a href="/{$collection}/{$id}/main">{titles:printTitleID($id)}</a> ({$id})</div>
                        <div class="col-md-5">{data($root/t:TEI/@type)}</div>
                       
                    </div>
       
                

    };
    
    declare %templates:wrap function app:xpathresultstitle($node as node(), 
    $model as map(*)){
    <h2>{count($model("hits"))} results for { $model("path")} </h2>
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
            <div class="row reference">
                <div class="col-md-1"><span class="number">{$start + $p - 1}</span></div>
                        <div class="col-md-3"><a href="/{$id}">{titles:printTitleID($id)}</a> ({$id})</div>
                        <div class="col-md-5"></div>
                        
                        <div class="col-md-1">{data($text/ancestor::t:*[@xml:id][1]/@xml:id)}</div>
                        <div class="col-md-2"> <code>{$text/name()}</code></div>
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

(: Function to transform the intermediary structures in the search query generated through app:parse-lucene() and util:parse() 
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


(:displaies on the hompage the totals of the portal:)
declare function app:count($node as element(), $model as map(*)){

let $total := count(collection($config:data-root))
let $totalMS := count(collection($config:data-rootMS))
let $totalInstitutions := count(collection($config:data-rootIn))
let $totalWorks := (count(collection($config:data-rootW)) + count(collection($config:data-rootN)))
let $totalPersons := count(collection($config:data-rootPr))
return 

<div>
<p>There are <b class="lead">{$total}</b> searchable and browsable items in the app. </p>
<p><b  class="lead">{$totalMS}</b> are Manuscript's Catalogue Records. </p>
<p><b class="lead">{$totalInstitutions}</b> are Repositories holding Ethiopian Manuscripts. </p>
<p><b class="lead">{$totalWorks}</b> are Text units, Narrative units or literary works. </p>
<p><b class="lead">{$totalPersons}</b> are Records about people, groups, ethnic or linguistic groups. </p>
<p>The other records are Authority files and places which are not repositories. </p>
</div>
};

