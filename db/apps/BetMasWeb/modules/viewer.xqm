xquery version "3.1" encoding "UTF-8";


module namespace viewer = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/iiifviewer";
import module namespace rest = "http://exquery.org/ns/restxq";
import module namespace log="http://www.betamasaheft.eu/log" at "xmldb:exist:///db/apps/BetMasWeb/modules/log.xqm";
import module namespace xdb="http://exist-db.org/xquery/xmldb";
import module namespace config = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/config" at "xmldb:exist:///db/apps/BetMasWeb/modules/config.xqm";
import module namespace nav = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/nav" at "xmldb:exist:///db/apps/BetMasWeb/modules/nav.xqm";
import module namespace item2 = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/item2" at "xmldb:exist:///db/apps/BetMasWeb/modules/item.xqm";
import module namespace error = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/error" at "xmldb:exist:///db/apps/BetMasWeb/modules/error.xqm";
import module namespace scriptlinks = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/scriptlinks" at "xmldb:exist:///db/apps/BetMasWeb/modules/scriptlinks.xqm";
import module namespace switch2 = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/switch2"  at "xmldb:exist:///db/apps/BetMasWeb/modules/switch2.xqm";
import module namespace console="http://exist-db.org/xquery/console";
declare namespace t = "http://www.tei-c.org/ns/1.0";
declare namespace marc = "http://www.loc.gov/MARC21/slim";
(: For REST annotations :)
declare namespace http = "http://expath.org/ns/http-client";
declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";



declare 
%rest:GET
%rest:path("/BetMasWeb/manuscripts/viewer")
%output:method("html5")
function viewer:allmirador(){
 (
log:add-log-message('/manuscripts/viewer', sm:id()//sm:real/sm:username/string() , 'viewer'),
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
        <link rel="shortcut icon" href="resources/images/minilogo.ico"/>
<title xmlns="http://www.w3.org/1999/xhtml" property="dcterms:title og:title schema:name" >Mirador Manuscript viewer</title>
        <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
    <link rel="stylesheet" type="text/css" href="resources/mirador/css/mirador-combined.css"/>
    <script src="resources/mirador/mirador.js"></script>
    
     
    </head>
    <body id="body">
       <div id="content" class="w3-container w3-padding-64 w3-margin">
 
    <div id="viewer"></div>
    
<script type="text/javascript" >{'var data = [{collectionUri: "' ||$config:appUrl|| '/api/iiif/collections"}]'}</script>
   <script type="text/javascript" src="resources/js/miradorcoll.js"></script>
 </div>
        
    
    </body>
</html>
        )
        
};



declare 
%rest:GET
%rest:path("/BetMasWeb/manuscripts/{$repoid}/list/viewer")
%output:method("html5")
function viewer:allinRepo($repoid as xs:string){
 (
log:add-log-message('/manuscripts/'||$repoid||'/viewer', sm:id()//sm:real/sm:username/string() , 'viewer'),
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
        <link rel="shortcut icon" href="resources/images/favicon.ico"/>
<title xmlns="http://www.w3.org/1999/xhtml" property="dcterms:title og:title schema:name" >Mirador Manuscript viewer</title>
        <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
    <link rel="stylesheet" type="text/css" href="resources/mirador/css/mirador-combined.css"/>
    <script src="resources/mirador/mirador.js"></script>
    
     
    </head>
    <body id="body">
       <div id="content" class="w3-margin w3-container w3-padding-64">
 
    <div id="viewer"></div>
    
<script type="text/javascript" >{'var data = [{collectionUri: "' ||$config:appUrl|| '/api/iiif/collection/'||$repoid||'"}]'}</script>
   <script type="text/javascript" src="resources/js/miradorcoll.js"></script>
 </div>
        
    
    </body>
</html>
        )
        
};





declare 
%rest:GET
%rest:path("/BetMasWeb/{$collection}/{$id}/viewer")
%rest:query-param("FirstCanv", "{$FirstCanv}", '')
%output:method("html5")
function viewer:mirador($collection as xs:string, $id as xs:string, $FirstCanv as xs:string*){

let $c := switch2:collectionVar($collection)
let $coll := $config:data-root || '/' || $collection
let $this := $c/id($id)
let $title := item2:printTitle($id)
let $countsets:= count($this//t:idno[@facs])
return
if($countsets=1) then (
let $manifest := viewer:manifest($this, $id, $this//t:msIdentifier/t:idno)

let $location := viewer:location($this)
let $m := $this//t:msIdentifier/t:idno

let $firstcanvas := 
            (:bodleian:)
                if(contains(viewer:facsSwitch($m), 'bodleian')) 
               then   '' 
           (:vatican:)
               else if(contains(viewer:facsSwitch($m), 'digi.vat')) 
               then replace(substring-before(viewer:facsSwitch($m), '/manifest.json') || '/canvas/p0001', 'http:', 'https:')
            (:sinai and other loc.gov:)
            (:https://www.loc.gov/item/00279385706-ms/manifest.json
            https://tile.loc.gov/image-services/iiif/service:amed:amedmonastery:00279385706-ms:0001 :)
               else if(contains(viewer:facsSwitch($m), 'loc.gov')) 
               then concat('https://tile.loc.gov/image-services/iiif/service:amed:amedmonastery:', substring-before(substring-after(viewer:facsSwitch($m), 'item/'), '/manifest.json'), ':0001')
             (:windsor
            https://rct.resourcespace.com/iiif/1005080/            
            https://rct.resourcespace.com/iiif/1005079/canvas/ 003
            https://rct.resourcespace.com/iiif/1005080/canvas/001
            https://rct.resourcespace.com/iiif/1005081/canvas/P000
            https://rct.resourcespace.com/iiif/1005082/canvas/001
            https://rct.resourcespace.com/iiif/1005083/canvas/000
            https://rct.resourcespace.com/iiif/1005084/canvas/ _P002-hpr.jpg
            https://rct.resourcespace.com/iiif/1005085/canvas/1005085.a (1)-hpr.jpg
            :)

               else if(contains(viewer:facsSwitch($m), 'https://rct.resourcespace.com/iiif/1005081')) 
               then viewer:facsSwitch($m) || 'canvas/P000'  
               else if(contains(viewer:facsSwitch($m), 'https://rct.resourcespace.com/iiif/1005079')) 
               then viewer:facsSwitch($m) || 'canvas/ 003'  
               else if(contains(viewer:facsSwitch($m), 'https://rct.resourcespace.com/iiif/1005084')) 
               then viewer:facsSwitch($m) || 'canvas/ _P002-hpr.jpg'  
               else if(contains(viewer:facsSwitch($m), 'https://rct.resourcespace.com/iiif/1005085')) 
               then viewer:facsSwitch($m) || 'canvas/1005085.a (1)-hpr.jpg' 
               else if(contains(viewer:facsSwitch($m), 'rct.')) 
               then viewer:facsSwitch($m) || 'canvas/001'  
               
                 (:EAP
            https://eap.bl.uk/archive-file/EAP432-1-1/manifest
            https:\/\/eap.bl.uk\/archive-file\/EAP432-1-1\/canvas\/1
            :)
               else if(contains(viewer:facsSwitch($m), 'eap.')) 
               then replace(viewer:facsSwitch($m), 'manifest', 'canvas') || '/1'
               
               (:BL
            https://bl.digirati.io/iiif/ark:/81055/vdc_100054837854.0x000001
            https://bl.digirati.io/images/ark:/81055/vdc_100054837856.0x000001/canvas/c/1
            :)
               else if(contains(viewer:facsSwitch($m), 'bl.digirati')) 
               then 
               let $n1 := number(substring-before(substring-after(viewer:facsSwitch($m), 'vdc_'), '.0x')) 
               let $facs : =  replace(viewer:facsSwitch($m), $n1, $n1 +2)
               let $newfacs := substring-before($facs, '000001')
               return
               replace($newfacs, 'iiif', 'images') || '000001' || '/canvas/c/1'
               
            (:berlin
            https://content.staatsbibliothek-berlin.de/dc/1751174670/manifest
            https:\/\/content.staatsbibliothek-berlin.de\/dc\/1751174670-0001\/canvas
            :)
               else if(contains(viewer:facsSwitch($m), 'staatsbib')) 
               then substring-before(viewer:facsSwitch($m), '/manifest') || '-0001/canvas'
                           (:leicester
            https://specialcollections.le.ac.uk/digital/collection/p15407coll6/id/19840
            https://specialcollections.le.ac.uk/digital/collection/p15407coll6/id/20000
            https://specialcollections.le.ac.uk/iiif/2/p15407coll6:20030/manifest.json
            
            https://cdm16445.contentdm.oclc.org/iiif/p15407coll6:19840/canvas/c0
            :)
               else if(contains(viewer:facsSwitch($m), 'le.ac.uk')) 
               then concat('https://cdm16445.contentdm.oclc.org/iiif/', substring-before(substring-after(viewer:facsSwitch($m), 'iiif/'), 'coll6'), 'coll6:19840', '/canvas/c0')
              (:tuebingen
            https://opendigi.ub.uni-tuebingen.de/opendigi/MaIX2/manifest
            https://opendigi.ub.uni-tuebingen.de/opendigi/MaIX2/canvas/1
            :)
               else if(contains(viewer:facsSwitch($m), 'tuebingen')) 
            then replace(viewer:facsSwitch($m), '/manifest', '/') || 'canvas/1'
            (:princeton:)
                else if(contains($this//t:msIdentifier/t:idno/@facs, 'princeton')) 
                then   '' 
            (:dublin
            https://viewer.cbl.ie/viewer/api/v1/records/W_916/manifest/
            https://viewer.cbl.ie/viewer/api/v1/records/W_916/pages/1/canvas/
            :)
                else if(contains($this//t:msIdentifier/t:idno/@facs, 'cbl.ie')) 
            then substring-before(viewer:facsSwitch($m), '/manifest') || '/pages/1/canvas/'
            
            (:hamburg
            https://iiif.sub.uni-hamburg.de/object/PPN1845525922/manifest
            https://iiif.sub.uni-hamburg.de/object/PPN1845525922/canvas/PHYS_0001
            :)
            else if(contains($this//t:msIdentifier/t:idno/@facs, 'uni-hamburg')) 
            then substring-before(viewer:facsSwitch($m), '/manifest') || '/canvas/PHYS_0001'
            
            (:cambridge
            https://cudl.lib.cam.ac.uk//iiif/MS-ADD-01569
            https://cudl.lib.cam.ac.uk/iiif/MS-ADD-01569/canvas/1
            :)
              else if(contains(viewer:facsSwitch($m), 'cudl')) 
              then replace(viewer:facsSwitch($m), '//iiif', '/iiif') || '/canvas/1'
           (:BNF:)
            else if (contains($this//t:repository/@ref, 'INS0303BNF')) 
            then replace(viewer:facsSwitch($m), 'ark:', 'iiif/ark:') || '/canvas/f1'
            
            (:manchester  :)
               else if(contains(viewer:facsSwitch($m), 'manchester')) 
               then viewer:facsSwitch($m) || '/canvas/1'
            
(:           ES, EMIP, Laurenziana, all the others :)
                else 
                $config:appUrl|| '/api/iiif/' || $id || '/canvas/p1' 
                
let $Cmap := map {'type': 'collection', 'name' : $collection, 'path' : $c}
let $Imap := map {'type': 'item', 'name' : $id, 'path' : $collection}
return 


if(xdb:collection-available($coll)) then (
(:check that it is one of our collections:)
 if ($collection='institutions') then (
 (:controller should handle this by redirecting /institutions/ID/main to /manuscripts/ID/list which is then taken care of by list.xql:)
 )
        else
(:        check that the item exists:)
       if(item2:getTEIbyID($id)) then (
       log:add-log-message('/'||$collection||'/'||$id||'/viewer', sm:id()//sm:real/sm:username/string() , 'viewer'),

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
    {scriptlinks:app-title($title)}
        <link rel="shortcut icon" href="resources/images/favicon.ico"/>
    <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
  {scriptlinks:app-meta($this)}
     {scriptlinks:scriptStyle()}
    <link rel="stylesheet" type="text/css" href="resources/mirador/css/mirador-combined.css"/>
    <script src="resources/mirador/mirador.js"></script>
    </head>
    <body id="body">
      {nav:barNew()}
        {nav:modalsNew()}
        <div id="content" class="w3-container w3-padding-48">
       {item2:RestViewOptions($this, $collection)}
  { item2:RestItemHeader($this, $collection)}
       <div class="w3-container">
 
    <div id="viewer" class="w3-margin-top" allowfullscreen="allowfullscreen"></div>
    
<script type="text/javascript" >{'var data = [{manifestUri: "' || $manifest || '", location: "' || $location[1] || '"}]
var loadedM =  "' || $manifest || '"
var canvasid = "' || (if($FirstCanv = '') then $firstcanvas else $FirstCanv) || '"
'}</script>
   <script type="text/javascript" src="resources/js/mirador.js"></script>
   
 </div>
 <div class="w3-panel w3-gray w3-card-2">
 <p><a href="{$manifest}" target="_blank"><img src="/resources/images/iiif.png" width="20px"/> {$manifest}</a></p>
 </div>
        { item2:authors($this, $collection)}
        </div>
     {nav:footerNew()}
    </body>
</html>
        )
        else
       (<rest:response>
            <http:response
                status="400">
                <http:header
                    name="Content-Type"
                    value="text/html; charset=utf-8"/>
            </http:response>
        </rest:response>,
        error:error($Imap)) 
       
        )
        else
        (
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
        )
        
        
(:        if there are more  facs, then print a multiple view mirador:)
        else (
        
let $locations := for $m in $this//t:idno[@facs][@n]
                            let $manifest := viewer:manifest($this, $id, $m)

                                  let $location := viewer:location($this)
                            return
                             '{manifestUri: "' || $manifest || '", location: "' || $location[1] || '"}'
let $manifests := for $m in $this//t:idno[@facs][@n]
                               let $manifest := viewer:manifest($this, $id, $m)
                               let $firstcanvas := 
            (:bodleian:)
                if(contains(viewer:facsSwitch($m), 'bodleian')) 
               then   '' 
           (:vatican:)
               else if(contains(viewer:facsSwitch($m), 'digi.vat')) 
               then replace(substring-before(viewer:facsSwitch($m), '/manifest.json') || '/canvas/p0001', 'http:', 'https:')
            (:sinai and other loc.gov:)
            (:https://www.loc.gov/item/00279385706-ms/manifest.json
            https://tile.loc.gov/image-services/iiif/service:amed:amedmonastery:00279385706-ms:0001 :)
               else if(contains(viewer:facsSwitch($m), 'loc.gov')) 
               then concat('https://tile.loc.gov/image-services/iiif/service:amed:amedmonastery:', substring-before(substring-after(viewer:facsSwitch($m), 'item/'), '/manifest.json'), ':0001')
             (:windsor
            https://rct.resourcespace.com/iiif/1005080/            
            https://rct.resourcespace.com/iiif/1005079/canvas/ 003
            https://rct.resourcespace.com/iiif/1005080/canvas/001
            https://rct.resourcespace.com/iiif/1005081/canvas/P000
            https://rct.resourcespace.com/iiif/1005082/canvas/001
            https://rct.resourcespace.com/iiif/1005083/canvas/000
            https://rct.resourcespace.com/iiif/1005084/canvas/ _P002-hpr.jpg
            https://rct.resourcespace.com/iiif/1005085/canvas/1005085.a (1)-hpr.jpg
            :)

               else if(contains(viewer:facsSwitch($m), 'https://rct.resourcespace.com/iiif/1005081')) 
               then viewer:facsSwitch($m) || 'canvas/P000'  
               else if(contains(viewer:facsSwitch($m), 'https://rct.resourcespace.com/iiif/1005079')) 
               then viewer:facsSwitch($m) || 'canvas/ 003'  
               else if(contains(viewer:facsSwitch($m), 'https://rct.resourcespace.com/iiif/1005084')) 
               then viewer:facsSwitch($m) || 'canvas/ _P002-hpr.jpg'  
               else if(contains(viewer:facsSwitch($m), 'https://rct.resourcespace.com/iiif/1005085')) 
               then viewer:facsSwitch($m) || 'canvas/1005085.a (1)-hpr.jpg' 
               else if(contains(viewer:facsSwitch($m), 'rct.')) 
               then viewer:facsSwitch($m) || 'canvas/001'  
               
                 (:EAP
            https://eap.bl.uk/archive-file/EAP432-1-1/manifest
            https:\/\/eap.bl.uk\/archive-file\/EAP432-1-1\/canvas\/1
            :)
               else if(contains(viewer:facsSwitch($m), 'eap.')) 
               then replace(viewer:facsSwitch($m), 'manifest', 'canvas') || '/1'
               
               (:BL
            https://bl.digirati.io/iiif/ark:/81055/vdc_100054837854.0x000001
            https://bl.digirati.io/images/ark:/81055/vdc_100054837856.0x000001/canvas/c/1
            :)
               else if(contains(viewer:facsSwitch($m), 'bl.digirati')) 
               then 
               let $n1 := number(substring-before(substring-after(viewer:facsSwitch($m), 'vdc_'), '.0x')) 
               let $facs : =  replace(viewer:facsSwitch($m), $n1, $n1 +2)
               let $newfacs := substring-before($facs, '000001')
               return
               replace($newfacs, 'iiif', 'images') || '000001' || '/canvas/c/1'
               
            (:berlin
            https://content.staatsbibliothek-berlin.de/dc/1751174670/manifest
            https:\/\/content.staatsbibliothek-berlin.de\/dc\/1751174670-0001\/canvas
            :)
               else if(contains(viewer:facsSwitch($m), 'staatsbib')) 
               then substring-before(viewer:facsSwitch($m), '/manifest') || '-0001/canvas'
                           (:leicester
            https://specialcollections.le.ac.uk/digital/collection/p15407coll6/id/19840
            https://specialcollections.le.ac.uk/digital/collection/p15407coll6/id/20000
            https://specialcollections.le.ac.uk/iiif/2/p15407coll6:20030/manifest.json
            
            https://cdm16445.contentdm.oclc.org/iiif/p15407coll6:19840/canvas/c0
            :)
               else if(contains(viewer:facsSwitch($m), 'le.ac.uk')) 
               then concat('https://cdm16445.contentdm.oclc.org/iiif/', substring-before(substring-after(viewer:facsSwitch($m), 'iiif/'), 'coll6'), 'coll6:19840', '/canvas/c0')
              (:tuebingen
            https://opendigi.ub.uni-tuebingen.de/opendigi/MaIX2/manifest
            https://opendigi.ub.uni-tuebingen.de/opendigi/MaIX2/canvas/1
            :)
               else if(contains(viewer:facsSwitch($m), 'tuebingen')) 
            then replace(viewer:facsSwitch($m), '/manifest', '/') || 'canvas/1'
            (:princeton:)
                else if(contains($this//t:msIdentifier/t:idno/@facs, 'princeton')) 
                then   '' 
            (:dublin
            https://viewer.cbl.ie/viewer/api/v1/records/W_916/manifest/
            https://viewer.cbl.ie/viewer/api/v1/records/W_916/pages/1/canvas/
            :)
                else if(contains($this//t:msIdentifier/t:idno/@facs, 'cbl.ie')) 
            then substring-before(viewer:facsSwitch($m), '/manifest') || '/pages/1/canvas/'
            
            (:hamburg
            https://iiif.sub.uni-hamburg.de/object/PPN1845525922/manifest
            https://iiif.sub.uni-hamburg.de/object/PPN1845525922/canvas/PHYS_0001
            :)
            else if(contains($this//t:msIdentifier/t:idno/@facs, 'uni-hamburg')) 
            then substring-before(viewer:facsSwitch($m), '/manifest') || '/canvas/PHYS_0001'
            
            (:cambridge
            https://cudl.lib.cam.ac.uk//iiif/MS-ADD-01569
            https://cudl.lib.cam.ac.uk/iiif/MS-ADD-01569/canvas/1
            :)
              else if(contains(viewer:facsSwitch($m), 'cudl')) 
              then replace(viewer:facsSwitch($m), '//iiif', '/iiif') || '/canvas/1'
           (:BNF:)
            else if (contains($this//t:repository/@ref, 'INS0303BNF')) 
            then replace(viewer:facsSwitch($m), 'ark:', 'iiif/ark:') || '/canvas/f1'
            
            (:manchester  :)
               else if(contains(viewer:facsSwitch($m), 'manchester')) 
               then viewer:facsSwitch($m) || '/canvas/1'
            
(:           ES, EMIP, Laurenziana, all the others :)
                else 
                                           $config:appUrl|| '/api/iiif/' || $id || '/canvas/p1' 
                                          return 
                                '{  loadedManifest: "' || $manifest || '",
                                    canvasID: "'||(if($FirstCanv = '') then $firstcanvas else $FirstCanv)||'",
                                    slotAddress: "row1.column'||string(count($m/preceding::t:idno) + 1)||'",
                                    viewType: "ImageView" }'
            
            
let $Cmap := map {'type': 'collection', 'name' : $collection, 'path' : $c}
let $Imap := map {'type': 'item', 'name' : $id, 'path' : $collection}
return 


if(xdb:collection-available($coll)) then (
(:check that it is one of our collections:)
 if ($collection='institutions') then (
 (:controller should handle this by redirecting /institutions/ID/main to /manuscripts/ID/list which is then taken care of by list.xql:)
 )
        else
(:        check that the item exists:)
       if(item2:getTEIbyID($id)) then (
       log:add-log-message('/'||$collection||'/'||$id||'/viewer', sm:id()//sm:real/sm:username/string() , 'viewer'),

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
    {scriptlinks:app-title($title)}
        <link rel="shortcut icon" href="resources/images/favicon.ico"/>
    <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
  {scriptlinks:app-meta($this)}
     {scriptlinks:scriptStyle()}
    <link rel="stylesheet" type="text/css" href="resources/mirador/css/mirador-combined.css"/>
    <script src="resources/mirador/mirador.js"></script>
    </head>
    <body id="body">
      {nav:barNew()}
        {nav:modalsNew()}
        <div id="content" class="w3-container w3-padding-48">
       {item2:RestViewOptions($this, $collection)}
  { item2:RestItemHeader($this, $collection)}
       <div class="w3-container">
 
    <div id="viewer" class="w3-margin-top" allowfullscreen="allowfullscreen"></div>
    
<script type="text/javascript" >{'
var countlayout = "1x'||$countsets||'"
var data = ['||string-join($locations, ', ')||']
var windowobjs =  [' || string-join($manifests, ', ') || ']
'}</script>
   <script type="text/javascript" src="resources/js/miradormultiple.js"></script>
   
 </div>
 <div class="w3-panel w3-gray w3-card-2">{
 for $m in $this/t:idno[@facs][@n]
 let $manifest :=  viewer:manifest($this, $id, $m)
               return
 <p><a href="{$manifest}" target="_blank"><img src="/resources/images/iiif.png" width="20px"/> {$manifest}</a></p>
 }</div>
        { item2:authors($this, $collection)}
        </div>
     {nav:footerNew()}
    </body>
</html>
        )
        else
       (<rest:response>
            <http:response
                status="400">
                <http:header
                    name="Content-Type"
                    value="text/html; charset=utf-8"/>
            </http:response>
        </rest:response>,
        error:error($Imap)) 
       
        )
        else
        (
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
        )
};

(:for cases in which there is a facsimile with a @facs linked from the idno/@facs:)
declare function viewer:facsSwitch($idnofacs){
if (starts-with($idnofacs/@facs, '#')) 
then (let $facsimileID := substring-after($idnofacs/@facs, '#') 
            return $idnofacs/ancestor::t:TEI//t:facsimile[@xml:id=$facsimileID]/@facs) 
else $idnofacs/@facs 
};

declare function viewer:manifest($this, $id, $m){
let $alt := if($m/parent::t:altIdentifier) then ('?alt='||string($m/parent::t:altIdentifier/@xml:id))  else ()
return(:BNF 
                                                https://gallica.bnf.fr/ark:/12148/btv1b10087587w
                                                https://gallica.bnf.fr/iiif/ark:/12148/btv1b10087587w/manifest.json
                                                :)
                                               if (contains($this//t:repository/@ref, 'INS0303BNF')) 
                                                  then (
                                                  replace(viewer:facsSwitch($m), 'ark:', 'iiif/ark:') || '/manifest.json'
                                                  ,
                                                  console:log((replace(viewer:facsSwitch($m), 'ark:', 'iiif/ark:') || '/manifest.json'))
                                                  )
   (:                                                tuebingen :)
                                                else if(contains(viewer:facsSwitch($m), 'http://idb'))
                                                  then  viewer:facsSwitch($m) 
                                                else
(:                                                vatican :)
                                                if(contains(viewer:facsSwitch($m), 'http://digi')) 
                                                  then  replace(viewer:facsSwitch($m), 'http:', 'https:')
                                                 else   if(contains(viewer:facsSwitch($m), 'https:')) 
                                                  then  viewer:facsSwitch($m)
                                             (:           Ethio-SPaRe, EMIP, Laurenziana, and all the others :)
                                               else  $config:appUrl|| '/api/iiif/' || $id || '/manifest' || $alt
};

declare function viewer:location($this){

            (:ES:)
            if($this//t:collection = 'Ethio-SPaRe' or $this//t:collection = 'EMIP') 
            then $this//t:collection[1]  
            (:BNF:)
            else if (contains($this//t:repository/@ref, 'INS0303BNF')) 
            then 'BnF'
(:            Laurenziana:)
            else if (contains($this//t:repository/@ref, 'INS0339BML'))
            then 'Biblioteca Medicea Laurenziana'
(:           vatican :)
 else if (contains($this//t:repository/@ref, 'INS0339BML'))
            then  'Biblioteca Apostolica Vaticana'
            else  string-join($this//t:idno, ', ')
};

declare 
%rest:GET
%rest:path("/BetMasWeb/chojnacki/viewer")
%output:method("html5")
function viewer:allchojnacki(){
 (
log:add-log-message('/chojnacki/viewer', sm:id()//sm:real/sm:username/string() , 'viewer'),
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
        <link rel="shortcut icon" href="resources/images/minilogo.ico"/>
<title xmlns="http://www.w3.org/1999/xhtml" property="dcterms:title og:title schema:name" >Mirador Chojnacki images viewer</title>
        <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
    <link rel="stylesheet" type="text/css" href="resources/mirador/css/mirador-combined.css"/>
    <script src="resources/mirador/mirador.js"></script>
    
     
    </head>
    <body id="body">
       <div id="content" class="w3-container w3-padding-64 w3-margin">
 
    <div id="viewer"></div>
    
<script type="text/javascript" >{
let $manifs := for $ch in collection($config:data-rootCh)//marc:record
let $segnatura := $ch//marc:datafield[@tag="852"]/marc:subfield[@code="h"]/text()
return
'{"manifestUri": "https://digi.vatlib.it/iiif/STP_'||string-join($segnatura)||'/manifest.json", "location" : "DigiVatLib"}'

let $chmanif:= string-join($manifs, ',')
return 'var data = [' ||$chmanif||']'}</script>
   <script type="text/javascript" src="resources/js/miradorcoll.js"></script>
 </div>
        
    
    </body>
</html>
        )
        
};

