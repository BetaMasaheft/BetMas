xquery version "3.1" encoding "UTF-8";
(:~
 : module used by the restXQ modules functions
 : used by the main views for items
 :
 : @author Pietro Liuzzo 
 :)
 
module namespace scriptlinks="https://www.betamasaheft.uni-hamburg.de/BetMas/scriptlinks";

import module namespace config="https://www.betamasaheft.uni-hamburg.de/BetMas/config" at "xmldb:exist:///db/apps/BetMas/modules/config.xqm";

declare namespace t="http://www.tei-c.org/ns/1.0";

(:~embedded metadata for Zotero mapping (schema.org and dcterms properties as RDFa) :)
declare function scriptlinks:app-meta($biblio as node()){

let $col :=$biblio//t:idno[@type='collection']/text()
let $LM :=$biblio//t:date[@type eq 'lastModified']/text()
let $url := $biblio//t:idno[@type eq 'url']
let $DOI := $biblio//t:idno[@type eq 'DOI']
return
        (
     <meta  xmlns="http://www.w3.org/1999/xhtml" name="description" content="{$config:repo-descriptor/repo:description/text()}"/>,
    for $author in config:distinct-values(($biblio//t:respStmt/t:name/text()| $biblio//t:editor/text()))
         return  <meta  xmlns="http://www.w3.org/1999/xhtml" property="dcterms:creator schema:creator" content="{$author}"></meta>,
     <meta  xmlns="http://www.w3.org/1999/xhtml" property="dcterms:type schema:genre" content="{switch($col)
         case 'manuscripts' return 'Catalogue of Ethiopian Manuscripts'
         case 'works' return 'Clavis of Ethiopian Literature'
         case 'narratives' return 'Clavis of Ethiopian Literature'
         case 'places' return 'Gazetteer of Places'
         case 'institutions' return 'Gazetteer of Places'
         case 'persons' return 'A Prosopography of Ethiopia'
         default return 'catalogue'}"></meta>,
    <meta xmlns="http://www.w3.org/1999/xhtml" property="schema:isPartOf" content="{$config:appUrl}/{$col}"></meta>,
    <meta  xmlns="http://www.w3.org/1999/xhtml" property="og:site_name" content="Beta maṣāḥǝft: Manuscripts of Ethiopia and Eritrea"></meta>,
    <meta  xmlns="http://www.w3.org/1999/xhtml" property="dcterms:language schema:inLanguage" content="en"></meta>,
    <meta  xmlns="http://www.w3.org/1999/xhtml" property="dcterms:rights" content="Copyright &#169; Akademie der Wissenschaften in Hamburg, Hiob-Ludolf-Zentrum für Äthiopistik.  Sharing and remixing permitted under terms of the Creative Commons Attribution Share alike Non Commercial 4.0 License (cc-by-nc-sa)."></meta>,
    <meta   xmlns="http://www.w3.org/1999/xhtml" property="dcterms:publisher schema:publisher" content="Akademie der Wissenschaften in Hamburg, Hiob-Ludolf-Zentrum für Äthiopistik"></meta>,
    <meta  xmlns="http://www.w3.org/1999/xhtml" property="dcterms:date schema:dateModified" content="{$LM}"></meta>,
    <meta  xmlns="http://www.w3.org/1999/xhtml" property="dcterms:identifier schema:url" content="{$url}"></meta>,
    <meta  xmlns="http://www.w3.org/1999/xhtml" property="dcterms:identifier dcterms:URI" content="{$DOI}"></meta>
    )
};

(:~html page title:)
declare function scriptlinks:app-title($title) as element()* {
<title xmlns="http://www.w3.org/1999/xhtml" property="dcterms:title og:title schema:name" >{$title}</title>
};

(:~html page js calls:)
declare function scriptlinks:footerjsSelector() as element()* {
        if (contains(request:get-uri(), 'analytic'))
        then (<script xmlns="http://www.w3.org/1999/xhtml" type="text/javascript" src="resources/js/datatable.js"/>,
        <script xmlns="http://www.w3.org/1999/xhtml" type="text/javascript" src="resources/js/visgraphspec.js"/>)
        else ()
        };

(:~html page script and styles to be included :)
declare function scriptlinks:scriptStyle(){
(
        <link rel="shortcut icon" href="resources/images/minilogo.ico"/>,
        <link rel="stylesheet" type="text/css" href="resources/font-awesome-4.7.0/css/font-awesome.min.css"  />   ,
<link rel="stylesheet" type="text/css" href="https://cdnjs.cloudflare.com/ajax/libs/virtual-keyboard/1.26.22/css/keyboard-basic.min.css"  />,

(:        introjs:)
        <link rel="stylesheet" type="text/css" href="https://cdnjs.cloudflare.com/ajax/libs/intro.js/2.9.3/introjs.css"  />,
        <link rel="stylesheet" type="text/css" href="resources/css/style.css"  />,
(:        Alpheios :)
        <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/alpheios-components@latest/dist/style/style-components.min.css"/>,
      
(:      d3 :)
      <link rel="stylesheet" type="text/css" href="resources/css/d3.css"  />,
        <link rel="stylesheet" href="$shared/resources/css/w3.css"/>,
(:      w3 :)
        <link rel="stylesheet" href="resources/css/w3local.css"/>,
        <script type="text/javascript" src="https://code.jquery.com/jquery-1.11.1.min.js"/>
        )};
        
        declare function scriptlinks:listScriptStyle(){
        (
        <link rel="stylesheet" type="text/css" href="resources/font-awesome-4.7.0/css/font-awesome.min.css"  /> ,  
        <link rel="stylesheet" type="text/css" href="https://cdnjs.cloudflare.com/ajax/libs/virtual-keyboard/1.26.22/css/keyboard-basic.min.css"  />,
        <link rel="stylesheet" type="text/css" href="https://cdnjs.cloudflare.com/ajax/libs/intro.js/2.9.3/introjs.css"  />,
          <link rel="stylesheet" type="text/css" href="$shared/resources/css/bootstrap-3.0.3.min.css"  />,
        <link rel="stylesheet" href="https://code.jquery.com/ui/1.12.1/themes/base/jquery-ui.css"/>,
        <link rel="stylesheet" type="text/css" href="https://cdnjs.cloudflare.com/ajax/libs/bootstrap-slider/9.5.1/css/bootstrap-slider.min.css"  />,
        <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/alpheios-components@rc/dist/style/style-components.min.css"  />,
        <link rel="stylesheet" href="$shared/resources/css/w3.css"/>,
        <link rel="stylesheet" href="resources/css/w3local.css"/>,
        <script type="text/javascript" src="https://code.jquery.com/jquery-1.11.1.min.js"/>,
        <script type="text/javascript" src="$shared/resources/scripts/bootstrap-3.0.3.min.js"  />,
        <script type="text/javascript" src="https://code.jquery.com/ui/1.12.1/jquery-ui.min.js"/>,
        <script type="text/javascript" src="https://cdnjs.cloudflare.com/ajax/libs/bootstrap-slider/9.5.1/bootstrap-slider.min.js"/>
        
        
       )
        };

(:~html page script and styles to be included specific for item :)
declare function scriptlinks:ItemScriptStyle(){
<link xmlns="http://www.w3.org/1999/xhtml" rel="stylesheet" type="text/css" href="resources/css/mapbox.css"  />,
        <link xmlns="http://www.w3.org/1999/xhtml" rel="stylesheet" type="text/css" href="resources/css/leaflet.css"  />,
        <link xmlns="http://www.w3.org/1999/xhtml" rel="stylesheet" type="text/css" href="resources/css/leaflet.fullscreen.css"  />,
        <link xmlns="http://www.w3.org/1999/xhtml" rel="stylesheet" type="text/css" href="resources/css/leaflet-search.css"  />,
       <link xmlns="http://www.w3.org/1999/xhtml" href="https://unpkg.com/vis-timeline/styles/vis-timeline-graph2d.min.css" rel="stylesheet" type="text/css" />,
       <script xmlns="http://www.w3.org/1999/xhtml" type="text/javascript" src="https://cdnjs.cloudflare.com/ajax/libs/leaflet/0.7.7/leaflet.js"  />,
        <script xmlns="http://www.w3.org/1999/xhtml" type="text/javascript" src="resources/js/mapbox.js"  />,
        <script  xmlns="http://www.w3.org/1999/xhtml" type="text/javascript" src="resources/js/Leaflet.fullscreen.min.js"  />,
       <script xmlns="http://www.w3.org/1999/xhtml" type="text/javascript" src="resources/js/leaflet-ajax-gh-pages/dist/leaflet.ajax.min.js"  ></script>,
        <script xmlns="http://www.w3.org/1999/xhtml"  type="text/javascript" src="https://www.gstatic.com/charts/loader.js"  ></script>,
        <script xmlns="http://www.w3.org/1999/xhtml" type="text/javascript" src="resources/openseadragon/openseadragon.min.js"  />,
        <script  xmlns="http://www.w3.org/1999/xhtml" type="text/javascript" src="https://unpkg.com/vis-timeline/standalone/umd/vis-timeline-graph2d.min.js"></script>,
        <script xmlns="http://www.w3.org/1999/xhtml" type="text/javascript" src="https://unpkg.com/vis-network@7.10.2/peer/umd/vis-network.min.js"></script>
};

(:~html page script and styles to be included specific for item :)
declare function scriptlinks:ItemFooterScript(){

    <script type="text/javascript" src="resources/js/explain.js"/>,
        <script type="application/javascript" src="resources/js/w3.js"/>,
        <script type="text/javascript" src="https://code.jquery.com/ui/1.12.1/jquery-ui.min.js" ></script>,
        <script type="text/javascript" src="https://cdnjs.cloudflare.com/ajax/libs/virtual-keyboard/1.26.22/js/jquery.keyboard.js"  />,
        <script type="text/javascript" src="https://cdnjs.cloudflare.com/ajax/libs/virtual-keyboard/1.26.22/js/jquery.mousewheel.min.js"  />,
        <script type="text/javascript" src="https://cdnjs.cloudflare.com/ajax/libs/virtual-keyboard/1.26.22/js/jquery.keyboard.extension-typing.min.js"  />,
        <script type="text/javascript" src="https://cdnjs.cloudflare.com/ajax/libs/virtual-keyboard/1.26.22/js/jquery.keyboard.extension-altkeyspopup.min.js"  ></script>,
        <script type="text/javascript" src="$shared/resources/scripts/loadsource.js"  />,
        <script type="text/javascript" src="https://cdnjs.cloudflare.com/ajax/libs/bootstrap-slider/9.5.1/bootstrap-slider.min.js"  />,
        <script type="text/javascript" src="resources/js/diacriticskeyboard.js"  />,
        <script type="text/javascript" src="resources/js/analytics.js"  ></script>,
        <script type="text/javascript" src="https://cdnjs.cloudflare.com/ajax/libs/intro.js/2.9.3/intro.js"  ></script>,
        <script type="text/javascript" src="resources/alpheios/alpheiosStart.js" />,
        <script type="application/javascript" src="resources/js/introText.js"/>,
<script type="text/javascript" src="resources/js/versions.js"/>,
<script type="text/javascript" src="resources/js/quotations.js"/>,
<script type="text/javascript" src="resources/js/samerole.js"/>,
<script type="text/javascript" src="resources/js/allattestations.js"/>,
<script type="text/javascript" src="resources/js/ugarit.js"/>,
<script type="text/javascript" src="resources/js/highlight.js"/>,
        <script type="text/javascript" src="resources/js/titles.js"/>,
        <script type="text/javascript" src="resources/js/PointsHere.js"/>,
        <script type="text/javascript" src="resources/js/resp.js"/>,
        <script type="text/javascript" src="resources/js/relatedItems.js"/>,
        <script type="text/javascript" src="resources/js/citations.js"/>,
        <script type="text/javascript" src="resources/js/hypothesis.js"/>
};

(:~ be kind to the logged user :)
declare function scriptlinks:greetings-rest(){
<a href="">Hi {sm:id()//sm:real/sm:username/string() }!</a>
    };
