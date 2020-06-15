xquery version "3.1" encoding "UTF-8";
(:~
 : template like RESTXQ module to generate the comparison page
 : 
 : @author Pietro Liuzzo 
 :)

module namespace collatex = "https://www.betamasaheft.uni-hamburg.de/BetMas/collatex";
import module namespace rest = "http://exquery.org/ns/restxq";
import module namespace log="http://www.betamasaheft.eu/log" at "xmldb:exist:///db/apps/BetMas/modules/log.xqm";
import module namespace nav = "https://www.betamasaheft.uni-hamburg.de/BetMas/nav" at "xmldb:exist:///db/apps/BetMas/modules/nav.xqm";
import module namespace apprest = "https://www.betamasaheft.uni-hamburg.de/BetMas/apprest" at "xmldb:exist:///db/apps/BetMas/modules/apprest.xqm";
import module namespace config = "https://www.betamasaheft.uni-hamburg.de/BetMas/config" at "xmldb:exist:///db/apps/BetMas/modules/config.xqm";
import module namespace dts="https://www.betamasaheft.uni-hamburg.de/BetMas/dts" at "xmldb:exist:///db/apps/BetMas/modules/dts.xqm";
import module namespace error = "https://www.betamasaheft.uni-hamburg.de/BetMas/error" at "xmldb:exist:///db/apps/BetMas/modules/error.xqm";
import module namespace console="http://exist-db.org/xquery/console";

declare namespace t = "http://www.tei-c.org/ns/1.0";

(: For REST annotations :)
declare namespace http = "http://expath.org/ns/http-client";
declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace json = "http://www.json.org";
declare namespace test="http://exist-db.org/xquery/xqsuite";

declare variable $collatex:meta := <meta  xmlns="http://www.w3.org/1999/xhtml" name="description" content="Collation Interface using Collatex https://collatex.net/"/>;


(:~ given a series of dts urn of witness passages, produces the json required for a request to collatex and posts it :) 
declare
%rest:POST
%rest:GET
%rest:path("/BetMas/api/collatex")
%rest:query-param("dts", "{$dts}", "")
%rest:query-param("nU", "{$nU}", "")
%rest:query-param("format", "{$format}", "tei+xml")
function collatex:collatex($nU  as xs:string*,$dts  as xs:string*,$format  as xs:string*){
$config:response200,
let $urns := for $u in tokenize($dts, ',') return $u
return

if(count($urns) le 1) 

then (<info>please provide at least 2 dts URIs separated with comma</info>)  else(
  
                                         
   let $body :=   if ($nU !='') then dts:getnarrUnitWittnesses($nU) else dts:getCollatexBody($urns)
(:   let $test0 := console:log($body):)
     let $req :=
        <http:request
        http-version="1.1"
            href="{xs:anyURI('http://localhost:8081/collatex-servlet-1.7.1/collate')}"
            method="POST">
            <http:header
                name="Content-Type"
                value="application/json"/>
                <http:header name="Access-Control-Allow-Origin" value="*"/>
            <http:header name="Accept" value="application/{$format}"/>
            
                <http:body media-type="text" method="text" indent="yes">{$body}</http:body>
        </http:request>
let $post:=          hc:send-request($req)[2]
let $test :=console:log($post)
let $decoded := if(contains($format, 'xml')) then $post else try{util:base64-decode($post)} catch * {console:log($err:description), $post}
return 
$decoded
    
    )
};


declare 
%rest:GET
%rest:POST
%rest:path("/BetMas/collate")
%rest:query-param("dtsURNs", "{$dtsURNs}", "")
%output:method("html5")
function collatex:collateSelected(
$dtsURNs as xs:string*) {
let $list := $dtsURNs
let $fullurl := ('?dtsURNs=' || $dtsURNs)
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
         {$collatex:meta}
         
        <meta  xmlns="http://www.w3.org/1999/xhtml" property="dcterms:type schema:genre" content="Collation of {replace($list, ',',', ')}"></meta>
            <meta  xmlns="http://www.w3.org/1999/xhtml" property="og:site_name" content="Beta maṣāḥǝft: Manuscripts of Ethiopia and Eritrea"></meta>
    <meta  xmlns="http://www.w3.org/1999/xhtml" property="dcterms:language schema:inLanguage" content="en"></meta>
    <meta  xmlns="http://www.w3.org/1999/xhtml" property="dcterms:rights" content="Copyright &#169; Akademie der Wissenschaften in Hamburg, Hiob-Ludolf-Zentrum für Äthiopistik.  Sharing and remixing permitted under terms of the Creative Commons Attribution Share alike Non Commercial 4.0 License (cc-by-nc-sa)."></meta>
    <meta   xmlns="http://www.w3.org/1999/xhtml" property="dcterms:publisher schema:publisher" content="Akademie der Wissenschaften in Hamburg, Hiob-Ludolf-Zentrum für Äthiopistik"></meta>

{apprest:scriptStyle()}
    </head>
    <body id="body">
       {nav:barNew()}
        {nav:modalsNew()}
        <div id="content" class="w3-container w3-margin w3-padding-64">
        <div class="w3-container">
        <div class="w3-quarter">
        <p>Here you can collate transcriptions of manuscripts using Collatex <a href="https://collatex.net/">https://collatex.net/</a>) from our server installation.</p>
        <p>You cannot enter your own text, but you can collate any text which is in the database. To add your transcription, see the guidelines <a href="/Guidelines/?id=howto">here</a>.</p>
            <p>In the form below you have to provide the two DTS URNs of the passages you want to compare, then hit the collate button and you will get a visualization of the TEI apparatus output from Collatex.</p>
            <p>The format of your URNs has to be the following</p>
            <ul>
            <li><pre>BLorient718.1</pre> will point to all the folio 1 of BL Orient 718 (recto and verso) and take all what is in there</li>
            <li><pre>BLorient718.1r</pre> will point to all the folio 1 recto of BL Orient 718 and take all what is on that page</li>
            <li><pre>BLorient718.1ra</pre> will point to  the folio 1 recto, column a  of BL Orient 718 and take all what is in that column</li>
            <li><pre>BLorient718.1ra1</pre> will point to  the folio 1 recto, column a  of BL Orient 718 and take all what is in that column, line 1</li>
            <li><pre>BLorient718.1ra1-1ra3</pre>will point to  the folio 1 recto, column a  of BL Orient 718 and take all what is in that column, line 1 to 3</li>
            <li><pre>BLorient718.1.1-1.3</pre> will point to  the folio 1 recto, column a  of BL Orient 718 and take all what is in that column, line 1 to 3</li>
            <li><pre>BLorient718.1ra@ወወልድ</pre>  will point to  the folio 1 recto, column a  of BL Orient 718 and take all what is in that column starting from the first occurrence of the word ወወልድ</li>
            <li><pre>BLorient718.1ra@ወወልድ[1]</pre> will point to  the folio 1 recto, column a  of BL Orient 718 and take all what is in that column starting from the first occurrence of the word ወወልድ, but note the specification of the occurrence, it could also be [2]</li>
            <li><pre>BLorient718.1ra@ወወልድ[1]-1ra@ቅዱስ[1]</pre> will point to the folio 1 recto, column a  of BL Orient 718 and take all what is in that column starting from the first occurrence of the word ወወልድ, and ending at the first occurrence of the word ቅዱስ</li>
            <li><pre>BLorient718.1ra@ወወልድ[1]-3va</pre> will point to the folio 1 recto, column a  of BL Orient 718 and take all what is in that column starting from the first occurrence of the word ወወልድ, and everything including in the transcription up to the end of folio 3va</li>
            <li><pre>EMIP01859.month1.day1</pre> is also a valid reference and will fetch the element in the manuscript transcription associated with the specified structure of type and names</li>
           <li><pre>EMIP01859.1.1.1</pre> is also a valid reference and will fetch the nested structured marked with n</li>
           <li><pre>EMIP01859.month1.day1.NAR0019SBarkisos</pre> is also a valid reference and will fetch the element in the manuscript transcription associated with the specified narrative unit. If you want to fetch passages connected to a narrative unit without specifiying the manuscript, add the narrative unit id instead</li>
           <li><pre>EMIP01859.NAR0019SBarkisos</pre> is also a valid reference and will fetch the element in the manuscript transcription associated with the specified narrative unit. If you want to fetch passages connected to a narrative unit without specifiying the manuscript, add the narrative unit id instead</li>
           
            </ul>
            <p>Of course, if there is no transcription, there will be no text to collate and the quality of the transcription depends on external factors.</p>
            <p>The level of precision possible, depends from the encoding. If you have encoded page and column breaks you can use them, otherways hopefully there are at least folia divisions.</p>
            <p>The collated text is cleaned from all markup and all punctuation and uses the default collation algorithm of Collatex.</p>
        </div>
        <div class="w3-threequarter">
        <div id="dtsURNs">
        <input type="text" class="dts w3-input w3-margin w3-border" placeholder="{{manuscriptid}}.{{passage}}-{{passage}}"></input>
        <input type="text" class="dts w3-input w3-margin w3-border" placeholder="{{manuscriptid}}.{{passage}}-{{passage}}"></input>
        
        </div>
        <p>Alternatively, you can specify a narrative unit and we will pick any manuscript transcription which contains a reference to that and collate it.</p>
        <div id="narrativeUnit">
        <input type="text" class="narrUnit w3-input w3-margin w3-border" placeholder="{{narrativeunitid}}"></input>
        
        </div>
        
        <div class="w3-bar w3-margin">
        <button  class="w3-bar-item w3-button w3-red" id="collate">Collate</button>
        <button  class="w3-bar-item w3-button w3-gray" id="addDTS">Add another witness</button>
        <a class="w3-button w3-bar-item w3-gray" href="javascript:void(0);" onclick="javascript:introJs().addHints();">hints</a>
        </div>
        <img id="loading" src="resources/Loading.gif" style="display: none;"></img>
        <div id="collationResult" class="w3-container"/>
        <script type="application/javascript" src="resources/js/collatex.js"></script>
        </div>
        </div>
        <div>
        </div>
        </div>
         {nav:footerNew()}
        <script type="text/javascript" src="https://cdnjs.cloudflare.com/ajax/libs/intro.js/2.9.3/intro.js"  ></script>
       </body>
</html>
        )
};
