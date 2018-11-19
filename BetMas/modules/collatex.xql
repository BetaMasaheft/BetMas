xquery version "3.1" encoding "UTF-8";
(:~
 : template like RESTXQ module to generate the comparison page
 : 
 : @author Pietro Liuzzo <pietro.liuzzo@uni-hamburg.de'>
 :)

module namespace collatex = "https://www.betamasaheft.uni-hamburg.de/BetMas/collatex";
import module namespace rest = "http://exquery.org/ns/restxq";
import module namespace log="http://www.betamasaheft.eu/log" at "xmldb:exist:///db/apps/BetMas/modules/log.xqm";
import module namespace item = "https://www.betamasaheft.uni-hamburg.de/BetMas/item" at "xmldb:exist:///db/apps/BetMas/modules/item.xqm";
import module namespace nav = "https://www.betamasaheft.uni-hamburg.de/BetMas/nav" at "xmldb:exist:///db/apps/BetMas/modules/nav.xqm";
import module namespace apprest = "https://www.betamasaheft.uni-hamburg.de/BetMas/apprest" at "xmldb:exist:///db/apps/BetMas/modules/apprest.xqm";
import module namespace error = "https://www.betamasaheft.uni-hamburg.de/BetMas/error" at "xmldb:exist:///db/apps/BetMas/modules/error.xqm";
declare namespace t = "http://www.tei-c.org/ns/1.0";

(: For REST annotations :)
declare namespace http = "http://expath.org/ns/http-client";
declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace json = "http://www.json.org";

declare variable $collatex:meta := <meta  xmlns="http://www.w3.org/1999/xhtml" name="description" content="Collation Interface using Collatex https://collatex.net/"/>;


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
         {$collatex:meta}
         
        <meta  xmlns="http://www.w3.org/1999/xhtml" property="dcterms:type schema:genre" content="Collation of {replace($list, ',',', ')}"></meta>
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
        <div class="col-md-3">
        <p>Here you can collate transcriptions of manuscripts using Collatex <a href="https://collatex.net/">https://collatex.net/</a>) from our server installation.</p>
        <p>You cannot enter your own text, but you can collate any text which is in the database. To add your transcription, see the guidelines <a href="/Guidelines/?id=howto">here</a>.</p>
            <p>In the form below you have to provide the two DTS URNs of the passages you want to compare, then hit the collate button and you will get a visualization of the TEI apparatus output from Collatex.</p>
            <p>The format of your URNs has to be the following</p>
            <ul>
            <li><pre>urn:dts:betmasMS:BLorient718:1</pre> will point to all the folio 1 of BL Orient 718 (recto and verso) and take all what is in there</li>
            <li><pre>urn:dts:betmasMS:BLorient718:1r</pre> will point to all the folio 1 recto of BL Orient 718 and take all what is on that page</li>
            <li><pre>urn:dts:betmasMS:BLorient718:1ra</pre> will point to  the folio 1 recto, column a  of BL Orient 718 and take all what is in that column</li>
            <li><pre>urn:dts:betmasMS:BLorient718:1ra@ወወልድ</pre>  will point to  the folio 1 recto, column a  of BL Orient 718 and take all what is in that column starting from the first occurrence of the word ወወልድ</li>
            <li><pre>urn:dts:betmasMS:BLorient718:1ra@ወወልድ[1]</pre> will point to  the folio 1 recto, column a  of BL Orient 718 and take all what is in that column starting from the first occurrence of the word ወወልድ, but note the specification of the occurrence, it could also be [2]</li>
            <li><pre>urn:dts:betmasMS:BLorient718:1ra@ወወልድ[1]-1ra@ቅዱስ[1]</pre> will point to the folio 1 recto, column a  of BL Orient 718 and take all what is in that column starting from the first occurrence of the word ወወልድ, and ending at the first occurrence of the word ቅዱስ</li>
            <li><pre>urn:dts:betmasMS:BLorient718:1ra@ወወልድ[1]-3va</pre> will point to the folio 1 recto, column a  of BL Orient 718 and take all what is in that column starting from the first occurrence of the word ወወልድ, and everything including in the transcription up to the end of folio 3va</li>
            </ul>
            <p>Of course, if there is no transcription, there will be no text to collate and the quality of the transcription depends on external factors.</p>
            <p>The level of precision possible, depends from the encoding. If you have encoded page and column breaks you can use them, otherways hopefully there are at least folia divisions.</p>
            <p>The collated text is cleaned from all markup and all punctuation and uses the default collation algorithm of Collatex.</p>
        </div>
        <div class="col-md-9">
        <div id="dtsURNs">
        <input type="text" class="dts form-control col-md-6" placeholder="urn:dts:betmasMS:{{manuscriptid}}:{{passage}}-{{passage}}"></input>
        <input type="text" class="dts form-control col-md-6" placeholder="urn:dts:betmasMS:{{manuscriptid}}:{{passage}}-{{passage}}"></input>
        
        </div>
        
        <button  class="btn btn-info" id="addDTS">Add another witness</button><button  class="btn btn-info" id="collate">Collate</button>
        <img id="loading" src="resources/Loading.gif" style="display: none;"></img>
        <div id="collationResult" class="col-md-12"/>
        <script type="application/javascript" src="resources/js/collatex.js"></script>
        </div>
        </div>
        <div>
        </div>
        </div>
         {nav:footer()}
       </body>
</html>
        )
};
