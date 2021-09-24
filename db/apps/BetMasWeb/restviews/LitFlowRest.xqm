xquery version "3.1" encoding "UTF-8";
(:~
 : template like RESTXQ module to generate the comparison page
 : 
 : @author Pietro Liuzzo 
 :)

module namespace LitFlowRest = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/LitFlowRest";
import module namespace config = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/config" at "xmldb:exist:///db/apps/BetMasWeb/modules/config.xqm";
import module namespace rest = "http://exquery.org/ns/restxq";
import module namespace log="http://www.betamasaheft.eu/log" at "xmldb:exist:///db/apps/BetMasWeb/modules/log.xqm";
import module namespace scriptlinks = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/scriptlinks" at "xmldb:exist:///db/apps/BetMasWeb/modules/scriptlinks.xqm";
import module namespace nav = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/nav" at "xmldb:exist:///db/apps/BetMasWeb/modules/nav.xqm";
import module namespace LitFlow = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/LitFlow" at "xmldb:exist:///db/apps/BetMasWeb/modules/LitFlow.xqm";


(: For REST annotations :)
declare namespace http = "http://expath.org/ns/http-client";
declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace json = "http://www.json.org";
declare namespace t = "http://www.tei-c.org/ns/1.0";


declare 
%rest:GET
%rest:POST
%rest:path("/BetMasWeb/LitFlow")
%rest:query-param("subj", "{$subj}", "")
%output:method("html5")
function LitFlowRest:compareSelected(
$subj as xs:string*) {
let $list := for $s in $subj return $s
let $fullurl := '?' || (let $ss := for $s in $subj return ('subj=' || $s) return string-join($ss, '&amp;'))
let $Cmap := map {'type': 'item', 'name' : $list, 'path' : $fullurl}

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
    <script async="async" src="https://www.googletagmanager.com/gtag/js?id=UA-106148968-1"></script>
        <script type="text/javascript" src="resources/js/analytics.js"></script>
        <title property="dcterms:title og:title schema:name">Beta maṣāḥǝft: Manuscripts of Ethiopia and Eritrea</title>
        <link rel="shortcut icon" href="resources/images/favicon.ico"/>
        <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
         
        <meta  xmlns="http://www.w3.org/1999/xhtml" property="dcterms:type schema:genre" content="Comparison of Manuscripts {$list}"></meta>
            <meta  xmlns="http://www.w3.org/1999/xhtml" property="og:site_name" content="Beta maṣāḥǝft: Manuscripts of Ethiopia and Eritrea"></meta>
    <meta  xmlns="http://www.w3.org/1999/xhtml" property="dcterms:language schema:inLanguage" content="en"></meta>
    <meta  xmlns="http://www.w3.org/1999/xhtml" property="dcterms:rights" content="Copyright &#169; Akademie der Wissenschaften in Hamburg, Hiob-Ludolf-Zentrum für Äthiopistik.  Sharing and remixing permitted under terms of the Creative Commons Attribution Share alike Non Commercial 4.0 License (cc-by-nc-sa)."></meta>
    <meta   xmlns="http://www.w3.org/1999/xhtml" property="dcterms:publisher schema:publisher" content="Akademie der Wissenschaften in Hamburg, Hiob-Ludolf-Zentrum für Äthiopistik"></meta>

<link rel="stylesheet" type="text/css" href="https://cdn.jsdelivr.net/jquery.slick/1.6.0/slick.css"  />
        <link rel="stylesheet" type="text/css" href="https://cdn.jsdelivr.net/jquery.slick/1.6.0/slick-theme.css"  />
{scriptlinks:scriptStyle()}
<script type="text/javascript" src="https://www.gstatic.com/charts/loader.js"/>
    </head>
    <body id="body">
       {nav:barNew()}
        {nav:modalsNew()}
        <div id="content" class="w3-container w3-padding-64 w3-margin">
        <div class="w3-container">
        <div class="w3-col" style="width:15%">
            <form action="" class="w3-container" 
            data-hint="Select the subject keywords to see the Flow Chart break down by period.">
        
    <label>Subject Keywords</label>
  
  <select class="w3-select w3-border" id="inputGroupSelect01" multiple="multiple" name="subj">
    <option selected='Selected'>Choose...</option>
    {for $subject in doc(concat($config:data-rootA, '/taxonomy.xml'))//t:category[t:desc eq 'Subjects']//t:category/t:catDesc
    return 
    <option value="{$subject/text()}" class="MainTitle" data-value="{$subject/text()}">{$subject/text()}</option>}
  </select>
                    <div class="w3-bar">
                    <button type="submit" class="w3-bar-item w3-button w3-red">
                    Load literature flow
                </button>
                <a class="w3-button w3-bar-item w3-gray" href="javascript:void(0);" onclick="javascript:introJs().addHints();">hints</a>
    </div>
    </form>
        </div>
        <div class="w3-rest">
       {if($subj='') then <p class="lead">Please select values from the list.</p> 
       else (try{LitFlow:Sankey($list, 'works')} catch * {$err:description}, 
       try{LitFlow:Sankey($list, 'mss')} catch * {$err:description})
       }
        </div>
        </div>
        </div>
         {nav:footerNew()}

<script type="text/javascript" src="https://cdn.jsdelivr.net/jquery.slick/1.6.0/slick.min.js"  />
        <script type="text/javascript" src="https://cdnjs.cloudflare.com/ajax/libs/intro.js/2.9.3/intro.js"  ></script>
        <script type="text/javascript" src="resources/js/titles.js"/>
        <script type="text/javascript" src="resources/js/slickoptions.js"/>
    <script type="application/javascript" src="resources/js/coloronhover.js"/>
        <script type="text/javascript" src="resources/js/lookup.js"/>
       
    </body>
</html>
        )
};
