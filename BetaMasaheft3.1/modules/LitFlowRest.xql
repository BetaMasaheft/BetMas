xquery version "3.1" encoding "UTF-8";
(:~
 : template like RESTXQ module to generate the comparison page
 : 
 : @author Pietro Liuzzo <pietro.liuzzo@uni-hamburg.de'>
 :)

module namespace LitFlowRest = "https://www.betamasaheft.uni-hamburg.de/BetMas/LitFlowRest";
import module namespace config = "https://www.betamasaheft.uni-hamburg.de/BetMas/config" at "config.xqm";
import module namespace rest = "http://exquery.org/ns/restxq";
import module namespace log="http://www.betamasaheft.eu/log" at "log.xqm";
import module namespace apprest = "https://www.betamasaheft.uni-hamburg.de/BetMas/apprest" at "apprest.xqm";
import module namespace nav = "https://www.betamasaheft.uni-hamburg.de/BetMas/nav" at "nav.xqm";
import module namespace LitFlow = "https://www.betamasaheft.uni-hamburg.de/BetMas/LitFlow" at "LitFlow.xqm";


(: For REST annotations :)
declare namespace http = "http://expath.org/ns/http-client";
declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace json = "http://www.json.org";
declare namespace t = "http://www.tei-c.org/ns/1.0";



declare 
%rest:GET
%rest:POST
%rest:path("/BetMas/LitFlow")
%rest:query-param("subj", "{$subj}", "")
%output:method("html5")
function LitFlowRest:compareSelected(
$subj as xs:string*) {
let $list := for $s in $subj return $s
let $fullurl := '?' || (let $ss := for $s in $subj return ('subj=' || $s) return string-join($ss, '&amp;'))
let $Cmap := map {'type':= 'item', 'name' := $list, 'path' := $fullurl}

return
(
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
        <title property="dcterms:title og:title schema:name">Beta maṣāḥǝft: Manuscripts of Ethiopia and Eritrea</title>
        <link rel="shortcut icon" href="resources/images/favicon.ico"/>
        <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
         
        <meta  xmlns="http://www.w3.org/1999/xhtml" property="dcterms:type schema:genre" content="Comparison of Manuscripts {$list}"></meta>
            <meta  xmlns="http://www.w3.org/1999/xhtml" property="og:site_name" content="Beta maṣāḥǝft: Manuscripts of Ethiopia and Eritrea"></meta>
    <meta  xmlns="http://www.w3.org/1999/xhtml" property="dcterms:language schema:inLanguage" content="en"></meta>
    <meta  xmlns="http://www.w3.org/1999/xhtml" property="dcterms:rights" content="Copyright &#169; Akademie der Wissenschaften in Hamburg, Hiob-Ludolf-Zentrum für Äthiopistik.  Sharing and remixing permitted under terms of the Creative Commons Attribution Share alike Non Commercial 4.0 License (cc-by-nc-sa)."></meta>
    <meta   xmlns="http://www.w3.org/1999/xhtml" property="dcterms:publisher schema:publisher" content="Akademie der Wissenschaften in Hamburg, Hiob-Ludolf-Zentrum für Äthiopistik"></meta>

{apprest:scriptStyle()}
    </head>
    <body id="body">
       {nav:bar()}
        {nav:modals()}
        <div id="content">
        <div class="col-md-12">
        <div class="col-md-2">
            <form action="" class="form form-horizontal" 
            data-hint="Select the subject keywords to see the Flow Chart break down by period.">
        <div class="form-group">
            <div class="input-group">
  <div class="input-group-prepend">
    <label class="input-group-text" for="inputGroupSelect01">Subject Keywords</label>
  </div>
  <select class="form-control" id="inputGroupSelect01" multiple="multiple" name="subj">
    <option selected='Selected'>Choose...</option>
    {for $subject in doc(concat($config:data-rootA, '/taxonomy.xml'))//t:category[t:desc='Subjects']//t:category/t:catDesc
    return 
    <option value="{$subject/text()}" class="MainTitle" data-value="{$subject/text()}">{$subject/text()}</option>}
  </select>
</div>
                <div class="input-group-btn">
                    <button type="submit" class="btn btn-primary">
                    Load literature flow
                </button>
                </div>
            </div>
    </form>
        </div>
        <div class="col-md-10">
       {if($subj='') then <p class="lead">Please select values from the list.</p> 
       else (try{LitFlow:Sankey($list, 'works')} catch * {$err:description}, 
       try{LitFlow:Sankey($list, 'mss')} catch * {$err:description})
       }
        </div>
        </div>
        </div>
         {nav:footer()}

        <script type="text/javascript" src="resources/js/titles.js"/>
        <script type="text/javascript" src="resources/js/slickoptions.js"/>
    <script type="application/javascript" src="resources/js/coloronhover.js"/>
        <script type="text/javascript" src="resources/js/lookup.js"/>
       
    </body>
</html>
        )
};
