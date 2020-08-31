xquery version "3.1" encoding "UTF-8";
(:~
 : template like RESTXQ module to generate the comparison page
 : 
 : @author Pietro Liuzzo 
 :)

module namespace litcomp = "https://www.betamasaheft.uni-hamburg.de/BetMas/litcomp";
import module namespace rest = "http://exquery.org/ns/restxq";
import module namespace log="http://www.betamasaheft.eu/log" at "xmldb:exist:///db/apps/BetMas/modules/log.xqm";
import module namespace nav = "https://www.betamasaheft.uni-hamburg.de/BetMas/nav" at "xmldb:exist:///db/apps/BetMas/modules/nav.xqm";
import module namespace apprest = "https://www.betamasaheft.uni-hamburg.de/BetMas/apprest" at "xmldb:exist:///db/apps/BetMas/modules/apprest.xqm";
import module namespace error = "https://www.betamasaheft.uni-hamburg.de/BetMas/error" at "xmldb:exist:///db/apps/BetMas/modules/error.xqm";
import module namespace config = "https://www.betamasaheft.uni-hamburg.de/BetMas/config" at "xmldb:exist:///db/apps/BetMas/modules/config.xqm";
import module namespace titles="https://www.betamasaheft.uni-hamburg.de/BetMas/titles" at "xmldb:exist:///db/apps/BetMas/modules/titles.xqm";
import module namespace string = "https://www.betamasaheft.uni-hamburg.de/BetMas/string" at "xmldb:exist:///db/apps/BetMas/modules/tei2string.xqm";
import module namespace locus = "https://www.betamasaheft.uni-hamburg.de/BetMas/locus" at "xmldb:exist:///db/apps/BetMas/modules/locus.xqm";

declare namespace t = "http://www.tei-c.org/ns/1.0";
declare namespace dcterms = "http://purl.org/dc/terms";
declare namespace saws = "http://purl.org/saws/ontology";
declare namespace cmd = "http://www.clarin.eu/cmd/";
declare namespace test="http://exist-db.org/xquery/xqsuite";

(: For REST annotations :)
declare namespace http = "http://expath.org/ns/http-client";
declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace json = "http://www.json.org";

declare variable $litcomp:meta := <meta  xmlns="http://www.w3.org/1999/xhtml" name="description" content="{$config:repo-descriptor/repo:description/text()}"/>,
    for $genauthor in $config:repo-descriptor/repo:author
    return
        <meta xmlns="http://www.w3.org/1999/xhtml" name="creator" content="{$genauthor/text()}"></meta>
        ;



declare 
%rest:GET
%rest:POST
%rest:path("/BetMas/litcomp")
%rest:query-param("worksid", "{$worksid}", "")
%rest:query-param("type", "{$type}", "formsPart")
%output:method("html5")
function litcomp:litcomp(
$worksid as xs:string*, $type as xs:string*) {
let $fullurl := ('?worksid=' || $worksid)
let $log := log:add-log-message($fullurl, sm:id()//sm:real/sm:username/string() , 'litcomp')
let $w :=  if(contains($worksid, ',')) then for $work in tokenize($worksid, ',') return $config:collection-rootW/id($work) else $config:collection-rootW/id($worksid)  
let $baseuris := for $bu in $w return base-uri($bu)
let $Cmap := map {'type': 'item', 'name' : $worksid, 'path' : string-join($baseuris)}
let $worktitles := for $work in $w/@xml:id return titles:printTitleID($work)
let $query := switch($type) 
case 'mightFormPart' return $config:collection-rootW//t:relation[@name eq 'ecrm:CLP46i_may_form_part_of'][@passive eq $worksid]
case 'contains' return $config:collection-rootW//t:relation[@name eq 'saws:contains'][@active eq $worksid]
default return  $config:collection-rootW//t:relation[@name eq 'saws:formsPartOf'][@passive eq $worksid]
return
if(exists($w) or $worksid ='') then (
<rest:response>
            <http:response
                status="200">
                <http:header
                    name="Content-Type"
                    value="text/html; charset=utf-8"/>
            </http:response>
        </rest:response>,
        <html xmlns="http://www.w3.org/1999/xhtml">
    <head>
    <script async="async" src="https://www.googletagmanager.com/gtag/js?id=UA-106148968-1"></script>
        <script type="text/javascript" src="resources/js/analytics.js"></script>
        <title property="dcterms:title og:title schema:name">Beta maṣāḥǝft: Manuscripts of Ethiopia and Eritrea</title>
        <link rel="shortcut icon" href="resources/images/favicon.ico"/>
        <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
         {$litcomp:meta}
         
        <meta  xmlns="http://www.w3.org/1999/xhtml" property="dcterms:type schema:genre" content="GeoBrowser view of Manuscripts of {$worksid}"></meta>
            <meta  xmlns="http://www.w3.org/1999/xhtml" property="og:site_name" content="Beta maṣāḥǝft: Manuscripts of Ethiopia and Eritrea"></meta>
    <meta  xmlns="http://www.w3.org/1999/xhtml" property="dcterms:language schema:inLanguage" content="en"></meta>
    <meta  xmlns="http://www.w3.org/1999/xhtml" property="dcterms:rights" content="Copyright &#169; Akademie der Wissenschaften in Hamburg, Hiob-Ludolf-Zentrum für Äthiopistik.  Sharing and remixing permitted under terms of the Creative Commons Attribution Share alike Non Commercial 4.0 License (cc-by-nc-sa)."></meta>
    <meta   xmlns="http://www.w3.org/1999/xhtml" property="dcterms:publisher schema:publisher" content="Akademie der Wissenschaften in Hamburg, Hiob-Ludolf-Zentrum für Äthiopistik"></meta>
<link rel="stylesheet" type="text/css" href="https://cdnjs.cloudflare.com/ajax/libs/intro.js/2.9.3/introjs.css"  />
<link rel="stylesheet" type="text/css" href="https://cdn.jsdelivr.net/jquery.slick/1.6.0/slick.css"  />
        <link rel="stylesheet" type="text/css" href="https://cdn.jsdelivr.net/jquery.slick/1.6.0/slick-theme.css"  />
        
{apprest:scriptStyle()}

<script type="text/javascript" src="https://www.gstatic.com/charts/loader.js"/>
    </head>
    <body id="body">
       {nav:barNew()}
        {nav:modalsNew()}
        <div id="content" class="w3-container w3-padding-64 w3-margin">
        <div class="w3-container">
        
    
        <form action="" class="w3-container" 
        data-hint="enter here the id of the work you would like to analyze.">
        <select class="w3-select w3-border" name="type">
        <option value="formsPart" selected="selected">Textual Units which form part of the selected one(s)</option>
        <option value="mightFormPart">Textual Units which might form part of the selected one(s)</option>
        <option value="contains">Textual Units contained by the selected one(s)</option>
        </select>
        <input 
        class="w3-input w3-border" list="gotohits" id="GoTo" 
        name="worksid" data-value="works">{if(count($worksid) gt 0) then attribute value {$worksid} else attribute placeholder {"choose work to produce map of manuscripts"} }</input>
               <datalist id="gotohits">
                    
                </datalist>
          <div class="w3-bar"><button type="submit" class="w3-bar-item w3-button w3-red"> Show table
                </button><a class="w3-bar-item w3-button w3-gray" href="javascript:void(0);" 
        onclick="javascript:introJs().addHints();">show hints</a></div>
    </form>
            <div class="w3-container" style="overflow-y:auto;">
            {if($worksid = '') then <div class="w3-panel w3-red">enter the Identifier of a Textual Unit and select the type of relation</div> else 
   <table class="w3-table w3-striped">
   <thead>
   <tr>
   <th>ID</th>
   <th>english titles</th>
   <th>bibliography</th>
   <th>incipit</th>
   <th>manuscripts</th>
   <th>total manuscripts</th>
   <th>compare</th>
   <th>maps</th>
   </tr>
   </thead>
   <tbody>
   {
   for $miracle in $query
let $bmid := if($type='contains') then string($miracle/@passive) else string($miracle/@active)
let $link := 'https://betamasaheft.eu/'||$bmid
let $textlink := 'https://betamasaheft.eu/works/'||$bmid||'/text'
let $miraclefile := $config:collection-rootW/id($bmid)
let $entitles := replace(string-join($miraclefile//t:title[@xml:lang='en'], ' | '), ',', '')
let $bibl := for $bib in $miraclefile//t:bibl return
(<a href="https://betamasaheft.eu/bibliography?pointer={$bib/t:ptr/@target}"
           >{string($bib/t:ptr/@target)}</a>, 
           for $c in $bib/t:citedRange return $c/@unit || $c/text(),
           <br/>
           )
let $incipit := replace(string-join($miraclefile//t:div[@subtype eq 'incipit']/t:ab/text(), ' '), ',', '')
let $incipitnote := replace(string-join(string:tei2string($miraclefile//t:div[@subtype eq 'incipit']/t:note), ' '), ',', '')
let $mss := $config:collection-rootMS//t:title[@ref eq  $bmid]

return
<tr>
<td><a href="{$link}">{$bmid}</a></td>
<td>{normalize-space($entitles)}</td>
<td>{$bibl}</td>
<td>{normalize-space($incipit)} <a href="{$textlink}">available text</a></td>
<td>{$incipitnote}</td>
<td>{if(count($mss) gt 0) then <table>
<thead><tr>
<th>manuscript</th>
<th>placement</th>
<th>position</th>
<th>word count</th>
<th>total miracles in this MS</th>
<th>1/4</th>
<th>2/4</th>
<th>3/4</th>
<th>4/4</th>
</tr></thead><tbody>{
for $m in $mss
                        let $root :=string(root($m)/t:TEI/@xml:id)
                        
                        let $msitem := $m/parent::t:msItem
                        let $placement := if ($m/preceding-sibling::t:locus) then ( locus:stringloc($m/preceding-sibling::t:locus)) else ''
                        let $number := count($msitem/preceding-sibling::t:msItem) +1
                        let $totalparts := count($msitem/parent::t:*/child::t:msItem)
                        let $position :=$number || '/' || $totalparts
                         let $works := for $w in $msitem/ancestor::t:TEI//t:msItem/t:title/@ref 
                                              return $config:collection-rootW/id($w)//t:keywords
                         let $totalmiracles := count($works//t:term[@key eq  'Miracle'])                         
                        return 
                        <tr>
                        <td><a href="https://betamasaheft.eu/{$root}">{titles:printTitleMainID($root)}</a></td>
                        <td>{$placement}</td>
                        <td>{$position}</td>
                        <td><span class="WordCount" data-msID="{$root}" data-wID="{$bmid}"/></td>
                        <td>{$totalmiracles} </td>
                        <td class="{$bmid}firstquarter">{if($number le ($totalparts div 4)) then 'x' else ''}</td>
                        <td class="{$bmid}secondquarter">{if(($number le ($totalparts div 2)) and ($number gt ($totalparts div 4))) then 'x' else ''}</td>
                        <td class="{$bmid}thirdquarter">{if(($number gt ($totalparts div 2)) and ($number le (($totalparts div 4) + ($totalparts div 2)))) then 'x' else ''}</td>
                        <td class="{$bmid}fourthquarter">{if($number gt (($totalparts div 4) + ($totalparts div 2))) then 'x' else ''}</td>
                        </tr>
                        
}
<tr><td></td>
<td></td>
<td></td>
<td></td>
<td></td>
<td class="{$bmid}percentfirstquarter"> </td>
<td class="{$bmid}percentsecondquarter"> </td>
<td class="{$bmid}percentthirdquarter"> </td>
<td class="{$bmid}percentfourthquarter"> </td>
</tr>
</tbody></table> else ()}</td>
<td class="{$bmid}totalMss">{count($mss)}</td>
<td><a href="https://betamasaheft.eu/compare?workid={$bmid}">Compare manuscript structure</a></td>
<td><a href="https://betamasaheft.eu/workmap?worksid={$bmid}">Map of Mss current location</a>
<a href="https://betamasaheft.eu/workmap?worksid={$bmid}">Map of Mss place of origin </a></td>
</tr>}
   </tbody>
   </table>
            
      }  </div>
        </div>
        </div>
         {nav:footerNew()}
<script type="text/javascript" src="https://cdn.jsdelivr.net/jquery.slick/1.6.0/slick.min.js"  />

        <script type="text/javascript" src="https://cdnjs.cloudflare.com/ajax/libs/intro.js/2.9.3/intro.js"  ></script>
        <script type="application/javascript" src="resources/js/introText.js"/>
        
        <script type="text/javascript" src="resources/js/NewBiblio.js"/>
        <script type="text/javascript" src="resources/js/titles.js"/>
        <script type="text/javascript" src="resources/js/slickoptions.js"/>
    <script type="application/javascript" src="resources/js/coloronhover.js"/>
        <script type="text/javascript" src="resources/js/lookup.js"/>
        <script type="text/javascript" src="resources/js/percent.js"/>
       
    </body>
</html>
        )
        else (
        <rest:response>
            <http:response
                status="400">
                <http:header
                    name="Content-Type"
                    value="text/html; charset=utf-8"/>
            </http:response>
        </rest:response>,
        error:error($Cmap)
        )
};



