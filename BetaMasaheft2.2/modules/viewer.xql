xquery version "3.1" encoding "UTF-8";


module namespace viewer = "https://www.betamasaheft.uni-hamburg.de/BetMas/iiif";
import module namespace rest = "http://exquery.org/ns/restxq";
import module namespace xdb="http://exist-db.org/xquery/xmldb";
import module namespace config = "https://www.betamasaheft.uni-hamburg.de/BetMas/config" at "config.xqm";
import module namespace console = "http://exist-db.org/xquery/console";
import module namespace nav = "https://www.betamasaheft.uni-hamburg.de/BetMas/nav" at "nav.xqm";
import module namespace item = "https://www.betamasaheft.uni-hamburg.de/BetMas/item" at "item.xqm";
import module namespace error = "https://www.betamasaheft.uni-hamburg.de/BetMas/error" at "error.xqm";
import module namespace apprest = "https://www.betamasaheft.uni-hamburg.de/BetMas/apprest" at "apprest.xqm";
declare namespace t = "http://www.tei-c.org/ns/1.0";

(: For REST annotations :)
declare namespace http = "http://expath.org/ns/http-client";
declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";



declare 
%rest:GET
%rest:path("/BetMas/manuscripts/viewer")
%output:method("html5")
function viewer:allmirador(){
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
        <link rel="shortcut icon" href="resources/images/favicon.ico"/>
<title xmlns="http://www.w3.org/1999/xhtml" property="dcterms:title og:title schema:name" >Mirador Manuscript viewer</title>
        <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
    <link rel="stylesheet" type="text/css" href="resources/mirador/css/mirador-combined.css"/>
    <script src="resources/mirador/mirador.min.js"></script>
    
     
    </head>
    <body id="body">
       <div id="content" class="container-fluid col-md-12">
 
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
%rest:path("/BetMas/manuscripts/{$repoid}/list/viewer")
%output:method("html5")
function viewer:allinRepo($repoid as xs:string){
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
        <link rel="shortcut icon" href="resources/images/favicon.ico"/>
<title xmlns="http://www.w3.org/1999/xhtml" property="dcterms:title og:title schema:name" >Mirador Manuscript viewer</title>
        <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
    <link rel="stylesheet" type="text/css" href="resources/mirador/css/mirador-combined.css"/>
    <script src="resources/mirador/mirador.min.js"></script>
    
     
    </head>
    <body id="body">
       <div id="content" class="container-fluid col-md-12">
 
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
%rest:path("/BetMas/{$collection}/{$id}/viewer")
%output:method("html5")
function viewer:mirador($collection as xs:string, $id as xs:string){

let $c := '/db/apps/BetMas/data/' || $collection
let $this := collection($c)//id($id)
let $biblio :=
<bibl>
{let $time := max($this//t:revisionDesc/t:change/xs:date(@when))
return
<date type="lastModified">{format-date($time, '[D].[M].[Y]')}</date>
}
<idno type="url">
{($config:appUrl ||'/'|| $collection||'/' ||$id)}
</idno>
<coll>{$collection}</coll>
</bibl>
let $manifest := 
(:ES:)
            if($this//t:collection = 'Ethio-SPaRe') 
            then $config:appUrl|| '/api/iiif/' || $id || '/manifest' 
            (:BNF:)
            else if ($this//t:repository/@ref = 'INS0303BNF') 
            then replace($this//t:msIdentifier/t:idno/@facs, 'ark:', 'iiif/ark:') || '/manifest.json'
(:           vatican :)
            else string($this//t:msIdentifier/t:idno/@facs)

let $location := 
(:ES:)
            if($this//t:collection = 'Ethio-SPaRe') 
            then $this//t:collection  
            (:BNF:)
            else if ($this//t:repository/@ref = 'INS0303BNF') 
            then 'BnF'
(:           vatican :)
            else  'Biblioteca Apostolica Vaticana'

let $firstcanvas := 
(:es:)
                if($this//t:collection = 'Ethio-SPaRe') 
               then $config:appUrl|| '/api/iiif/' || $id || '/canvas/p1' 
               (:BNF:)
            else if ($this//t:repository/@ref = 'INS0303BNF') 
            then replace($this//t:msIdentifier/t:idno/@facs, 'ark:', 'iiif/ark:') || '/canvas/f1'
(:           vatican :)
                else substring-before($this//t:msIdentifier/t:idno/@facs, '/manifest.json') || '/canvas/p0001'
                
                
let $Cmap := map {'type':= 'collection', 'name' := $collection, 'path' := $c}
let $Imap := map {'type':= 'item', 'name' := $id, 'path' := $collection}
return 


if(xdb:collection-available($c)) then (
(:check that it is one of our collections:)
 if ($collection='institutions') then (
 (:controller should handle this by redirecting /institutions/ID/main to /manuscripts/ID/list which is then taken care of by list.xql:)
 )
        else
(:        check that the item exists:)
       if(collection($config:data-root)//id($id)[name() = 'TEI']) then (
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
    {apprest:app-title($id)}
        <link rel="shortcut icon" href="resources/images/favicon.ico"/>
    <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
  {apprest:app-meta($biblio)}
     {apprest:scriptStyle()}
    <link rel="stylesheet" type="text/css" href="resources/mirador/css/mirador-combined.css"/>
    <script src="resources/mirador/mirador.min.js"></script>
    </head>
    <body id="body">
      {nav:bar()}
        {nav:modals()}
        {nav:searchhelp()}
       {item:RestViewOptions($this, $collection)}
  { item:RestItemHeader($this, $collection)}
       <div class="col-md-12">
 
    <div id="viewer"  allowfullscreen="allowfullscreen"></div>
    
<script type="text/javascript" >{'var data = [{manifestUri: "' || $manifest || '", location: "' || $location || '"}]
var loadedM =  "' || $manifest || '"
var canvasid = "' || $firstcanvas || '"
'}</script>
   <script type="text/javascript" src="resources/js/mirador.js"></script>
   
 </div>
        
    
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
};
