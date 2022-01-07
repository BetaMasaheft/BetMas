
xquery version "3.1" encoding "UTF-8";
(:~
 : implementation of the http://iiif.io/api/presentation/2.1/ 
 : for images of manuscripts stored in betamasaheft server. extracts manifest, sequence, canvas from the tei data
 : 
 : @author Pietro Liuzzo 
 :)
 module namespace persiiif = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/persiiif";
import module namespace iiif = "https://www.betamasaheft.uni-hamburg.de/BetMas/iiif"at "xmldb:exist:///db/apps/BetMasApi/specifications/iiif.xqm";
import module namespace rest = "http://exquery.org/ns/restxq";
import module namespace log="http://www.betamasaheft.eu/log" at "xmldb:exist:///db/apps/BetMasWeb/modules/log.xqm";
import module namespace all="https://www.betamasaheft.uni-hamburg.de/BetMasWeb/all" at "xmldb:exist:///db/apps/BetMasWeb/modules/all.xqm";
import module namespace exptit="https://www.betamasaheft.uni-hamburg.de/BetMasWeb/exptit" at "xmldb:exist:///db/apps/BetMasWeb/modules/exptit.xqm";
import module namespace api="https://www.betamasaheft.uni-hamburg.de/BetMasApi/api" at "xmldb:exist:///db/apps/BetMasApi/local/rest.xqm";
import module namespace config = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/config" at "xmldb:exist:///db/apps/BetMasWeb/modules/config.xqm";
import module namespace kwic = "http://exist-db.org/xquery/kwic"
    at "resource:org/exist/xquery/lib/kwic.xql";
import module namespace string = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/string" at "xmldb:exist:///db/apps/BetMasWeb/modules/tei2string.xqm";
import module namespace console = "http://exist-db.org/xquery/console";
(: namespaces of data used :)
declare namespace t = "http://www.tei-c.org/ns/1.0";
(: For REST annotations :)
declare namespace http = "http://expath.org/ns/http-client";
declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace json = "http://www.json.org";


  declare function persiiif:capitalize-first
  ( $arg as xs:string? )  as xs:string? {

   concat(upper-case(substring($arg,1,1)),
             substring($arg,2))
 } ;

declare function persiiif:fileingit($bmID, $sha){

let $permapath := replace(persiiif:capitalize-first(substring-after(base-uri($exptit:col/id($bmID)[name() eq 'TEI']), '/db/apps/BetMasData/')), 'Manuscripts', '')
return 
doc('https://raw.githubusercontent.com/BetaMasaheft/Manuscripts/'||$sha||'/'|| $permapath)//t:TEI
};


(:manifest for one manuscript, including all ranges and canvases:)
(:IIIF: The manifest response contains sufficient information for the client to initialize itself and begin to display something quickly to the user. The manifest resource represents a single object and any intellectual work or works embodied within that object. In particular it includes the descriptive, rights and linking information for the object. It then embeds the sequence(s) of canvases that should be rendered to the user.:)
declare 
%rest:GET
%rest:path("/permanent/{$sha}/api/iiif/{$id}/manifest")
%output:method("json") 
function persiiif:manifest($id as xs:string*,$sha as xs:string*) {
let $item := persiiif:fileingit($id, $sha)
       return
       if($item//t:msIdentifier/t:idno/@facs) then
($iiif:response200,

log:add-log-message('/api/iiif/'||$id||'/manifest', sm:id()//sm:real/sm:username/string() , 'iiif'),

       let $institutionID := string($item//t:repository/@ref)

       let $institution := exptit:printTitleID($institutionID)
let $imagesbaseurl := $config:appUrl ||'/iiif/' || string($item//t:msIdentifier/t:idno/@facs)
       let $tot := $item//t:msIdentifier/t:idno/@n
       let $url :=  $config:appUrl ||"/manuscripts/" || $id
      (:       this is where the images actually are, in the images server:)
       let $thumbid := $imagesbaseurl ||(if($item//t:collection='EMIP') then () else if($item//t:repository/@ref eq 'INS0339BML') then () else '_') || '001.tif/full/80,100/0/default.jpg'
       let $objectType := string($item//@form[1])
       let $iiifroot := $config:appUrl ||"/api/iiif/" || $id
       let $image := $config:appUrl ||'/iiif/'||$id||'/'
       let $canvas := iiif:Canvases($item, $id, $iiifroot, $tot)
       let $structures := iiif:Structures($item, $iiifroot, $tot)
(:       this is where the manifest is:)
       let $request := $iiifroot || "/manifest"
       (:       this is where the sequence is:)
       let $attribution := if($item//t:repository/@ref  eq 'INS0339BML') then ('The images of the manuscript taken by Antonella Brita, Karsten Helmholz and Susanne Hummel during a mission funded by the Sonderforschungsbereich 950 Manuskriptkulturen in Asien, Afrika und Europa, the ERC Advanced Grant TraCES, From Translation to Creation: Changes in Ethiopic Style and Lexicon from Late Antiquity to the Middle Ages (Grant Agreement no. 338756) and Beta maṣāḥǝft. The images are published in conjunction with this descriptive data about the manuscript with the permission of the https://www.bmlonline.it/la-biblioteca/cataloghi/, prot. 190/28.13.10.01/2.23 of the 24 January 2019 and are available for research purposes.') else "Provided by "||$item//t:collection/text()||" project."
       let $logo := if($item//t:repository/@ref eq 'INS0339BML') then ('/rest/BetMasWeb/resources/images/logobml.png') else "/rest/BetMasWeb/resources/images/logo"||$item//t:collection/text()||".png"
       let $sequence := $iiifroot || "/sequence/normal"
     
     
(:    $mainstructure:)
return 
map {"@context": "http://iiif.io/api/presentation/2/context.json",
  "@id": $request,
  "@type": "sc:Manifest",
  "label": exptit:printTitleID($id),
  "metadata": [
    map {"label": "Repository", 
                "value": [
                  map   {"@value": '<a href="'||$config:appUrl||'/manuscripts/'||$institutionID||'/list">'||$institution ||'</a>' , "@language": "en"}
                            ]
      }, 
      map {"label": "object type", 
                "value": [
                  map   {"@value": $objectType, "@language": "en"}
                            ]
      }, 
      map {"label": "main view", 
                "value": $config:appUrl ||'/'|| $id
      }
      ],
      "description" : "An Ethiopian Manuscript.",
     
      
    "viewingDirection": "right-to-left",
  "viewingHint": "paged",
  "license": "http://creativecommons.org/licenses/by-nc-nd/4.0/",
  "attribution": $attribution,
  "logo": map {
    "@id": $config:appUrl || $logo
    },
"rendering": map {
    "@id": $url,
    "label": "web presentation",
    "format": "text/html"
  },
  "within": $config:appUrl ||"/manuscripts/list",

  "sequences": [ 
   map   {"@context": "http://iiif.io/api/presentation/2/context.json",
        "@id": $sequence,
        "@type": "sc:Sequence",
        "label": "Current Page Order",
  "viewingDirection": "left-to-right",
  "viewingHint": "paged",
  "canvases": $canvas
       }
      ],
  "structures": $structures
    }
    )
    else 
      ($iiif:response400,
       
       map{'info': ('no manifest available for ' || $id )}
   )
};



(:dereferencable sequence The sequence conveys the ordering of the views of the object.:)
declare 
%rest:GET
%rest:path("/permanent/{$sha}/api/iiif/{$id}/sequence/normal")
%output:method("json")
function persiiif:sequence($id as xs:string*,$sha as xs:string*) {
($iiif:response200,

log:add-log-message('/api/iiif/'||$id||'/sequence/normal', sm:id()//sm:real/sm:username/string() , 'iiif'),
        let $item := persiiif:fileingit($id, $sha)

let $iiifroot := $config:appUrl ||"/api/iiif/" || $id
let $sequence := $iiifroot || "/sequence/normal"
let $startCanvas := $iiifroot || '/canvas/p1'

let $canvas := iiif:Canvases($item, $id, $iiifroot, $item//t:msIdentifier/t:idno[@facs])

       return
       
       map{"@context": "http://iiif.io/api/presentation/2/context.json",
  "@id": $sequence,
  "@type": "sc:Sequence",
  "label": "Current Page Order",
  "viewingDirection": "left-to-right",
  "viewingHint": "paged",
  "startCanvas": $startCanvas,
  "canvases": $canvas}
       )};
       
       
(:   dereference    canvas:)

(:IIIF: The canvas represents an individual page or view and acts as a central point for laying out the different content resources that make up the display. :)
       declare 
%rest:GET
%rest:path("/permanent/{$sha}/api/iiif/{$id}/canvas/p{$n}")
%output:method("json")
function persiiif:canvas($id as xs:string*, $n as xs:string*,$sha as xs:string*) {
($iiif:response200,

log:add-log-message('/api/iiif/'||$id||'/canvas/p' || $n, sm:id()//sm:real/sm:username/string() , 'iiif'),
let $item := persiiif:fileingit($id, $sha)
let $iiifroot := $config:appUrl ||"/api/iiif/" || $id 
let $imagesbaseurl := $config:appUrl ||'/iiif/' || string($item//t:msIdentifier/t:idno/@facs)
 let $imagefile := format-number($n, '000') || '.tif'
let $resid := ($imagesbaseurl || (if($item//t:collection='EMIP') then () else if($item//t:repository[@ref eq 'INS0339BML']) then () else '_') || $imagefile )
 let $image := ($imagesbaseurl || (if($item//t:collection='EMIP') then () else if($item//t:repository[@ref eq 'INS0339BML']) then () else '_') || $imagefile || '/full/full/0/default.jpg' )
let $name := string($n)
let $id := $iiifroot || '/canvas/p'  || $n
       return
       iiif:oneCanvas($id, $name, $image, $resid)
      ) };
       
       
      