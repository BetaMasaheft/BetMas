xquery version "3.1" encoding "UTF-8";
(:~
 : module used by the restXQ modules functions
 : used by the main views for items
 : 
 : @author Pietro Liuzzo <pietro.liuzzo@uni-hamburg.de'>
 :)
module namespace apprest="https://www.betamasaheft.uni-hamburg.de/BetMas/apprest";

declare namespace t="http://www.tei-c.org/ns/1.0";
declare namespace functx = "http://www.functx.com";
declare namespace exist = "http://exist.sourceforge.net/NS/exist";
declare namespace s = "http://www.w3.org/2005/xpath-functions";

import module namespace string = "https://www.betamasaheft.uni-hamburg.de/BetMas/string" at "tei2string.xqm";
import module namespace kwic = "http://exist-db.org/xquery/kwic"   at "resource:org/exist/xquery/lib/kwic.xql";
import module namespace app="https://www.betamasaheft.uni-hamburg.de/BetMas/app" at "app.xqm";
import module namespace titles="https://www.betamasaheft.uni-hamburg.de/BetMas/titles" at "titles.xqm";
import module namespace templates="http://exist-db.org/xquery/templates" ;
import module namespace config="https://www.betamasaheft.uni-hamburg.de/BetMas/config" at "config.xqm";
import module namespace console="http://exist-db.org/xquery/console";

(:test function returns the formatted zotero entry given the unique tag :)
declare function apprest:getZoteroTextData ($ZoteroUniqueBMtag as xs:string){
let $xml-url := concat('https://api.zotero.org/groups/358366/items?tag=',$string,'&amp;format=bib&amp;style=hiob-ludolf-centre-for-ethiopian-studies&amp;linkwrap=1')
let $data := httpclient:get(xs:anyURI($xml-url), true(), <Headers/>)
return
$data//text()
};

(:~used by items.xql to print the relations as a table in the relations view:)
declare function apprest:EntityRelsTable($this, $collection){

let $entity := $this
let $id := string($this/@xml:id)
let $rels := $entity//t:relation[@name][(@active and @passive) or @mutual]
let $otherrelsp := collection($config:data-root)//t:relation[ancestor::t:TEI[not(@xml:id = $id)]][@name][@passive = $id]
let $otherrelsa := collection($config:data-root)//t:relation[ancestor::t:TEI[not(@xml:id = $id)]][@name][@active = $id]
(:the three variables here assume that there will be relations in the requested file, and that if a relation somewhere else has this id in active it will not have it in passive:)
let $allrels := ($rels, $otherrelsp, $otherrelsa)
return
                        <table class="table table-hover" width="100%"  xmlns="http://www.w3.org/1999/xhtml">
                            <thead>
                                <tr>
                                    <th>Subject</th>
                                    <th>Relation</th>
                                    <th>Object</th>
                                    <th>Description</th>
                                </tr>
                            </thead>
                            <tbody>

{for $relation in $allrels
return
                                    <tr>
                                        <th>
                                        {
        for $active in data($relation/@active) 
          let $list :=<list>{
              if (contains($active, ' ')) 
             then
                 for $eachID in tokenize(normalize-space($active), ' ')
                     return 
              <id>{
                    
                        $eachID
                }</id>
               else
        (
            <id>{
                    
                        $active
                }</id>)}
              </list>  
                
                for $id in $list//id
                return
                <a href="{concat($config:appUrl,'/',$id)}" class="MainTitle" data-value="{$id}">{$id}</a>
                
                
    }
                                            
                                        </th>
                                        <th>
                                            {data($relation/@name)}
                                        </th>
                                        <th>
                                         { for $passive in data($relation/@passive) 
          let $list := <list>{
              if (contains($passive, ' ')) 
             then
                 for $eachID in tokenize(normalize-space($passive), ' ')
                     return 
              <id>{
                    
                        $eachID
                }</id>
               else
        (
            <id>{
                   
                        $passive
                }</id>)}
              </list>  
                for $id in $list/id
                return
                <a href="{concat($config:appUrl,'/',$id)}" class="MainTitle" data-value="{$id}">{$id}</a>
                
                
    }
                                           
                                        </th>
                                        <th>
{                                            transform:transform($relation/t:desc, 'xmldb:exist:///db/apps/BetMas/xslt/relation.xsl',())

}
                                        </th>
                                    </tr>
                                    }
                            </tbody>
                        </table>
                        

};



(:~The SEE ALSO section has ready made queries providing related contents,these are all dispalyed in divs with lists of which this is the template:)
declare function apprest:ModalRefsList($id, $string as xs:string, $sameKey){
let $value := if (doc($config:data-rootA || '/taxonomy.xml')//t:catDesc[text() = $string] )
                           then collection($config:data-root)//id($string)//t:titleStmt/t:title/text()
                           else if (matches($string, 'gn:'))  then titles:getGeoNames($string)
                           else if (matches($string, '(LOC|INS)(\d+)(\w+)')) 
                           then try {titles:printTitle(collection($config:data-rootPl, $config:data-rootIn)/id($string)//t:place)}
                           catch * {'no record'}
                           else $string
return   
    <div class="row-fluid">
     <h4>The following {count($sameKey)} entities also share the <a href="{if (matches($string, 'gn:'))  then ('http://www.geonames.org/'||substring-after($string, 'gn:')) else concat($config:appUrl,'/',$string)}">{$value}</a> tag </h4>
                                      <div id="Samekeyword{$string}">      
                                      <ul>{if (matches($string, '(\w{3})(\d+)(\w+)')) 
                                            then apprest:referencesList($id, $sameKey, 'link')
                                               else  apprest:referencesList($id, $sameKey, 'name')
                                             }
                                             </ul>
                                             </div>
                                    
                        </div>
};

(:~returns items in a  list of results from a references lookup:)
declare function apprest:referencesList($id, $list, $mode as xs:string){
      
          for $hit in  $list
          
          let $strid := $hit/ancestor::t:TEI/@xml:id
          group by $stringid := string($strid)
          order by $stringid
      return 
         <li class="nodot" xmlns="http://www.w3.org/1999/xhtml" >
         {if ($strid = $id) then ('here') else <a 
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



declare function apprest:institutions(){
<form action="" class="form form-horizontal">
<div class="form-group">
<label for="GoToRepo">filter by repository</label>
<div class="input-group">
<select id="GoToRepo" class="form-control">{
for $i in collection($config:data-rootIn)//t:TEI/@xml:id
let $id := string($i)
let $name := base-uri($i)
let $tit := titles:printTitleID($id)
order by $tit
return
<option value="{$id}">{$tit}</option>
}
</select>
<div class="input-group-btn"><button id="clickandgotoRepoID" class="btn btn-primary">Go</button></div>
</div></div>
</form>
};

declare function apprest:catalogues(){
<form action="" class="form form-horizontal">
<div class="form-group">
<label for="GoToRepo">filter by catalogue</label>
<div class="input-group">
<select id="GoToCatalogue" class="form-control">{
for $catalogue in distinct-values(collection($config:data-rootMS)//t:listBibl[@type='catalogue']//t:ptr/@target)
let $xml-url := concat('https://api.zotero.org/groups/358366/items?&amp;tag=', $catalogue, '&amp;format=bib&amp;style=hiob-ludolf-centre-for-ethiopian-studies')
let $data := httpclient:get(xs:anyURI($xml-url), true(), <Headers/>)
    order by $data
return
<option value="{$catalogue}">{$data//httpclient:body}</option>
}
</select>
<div class="input-group-btn"><button id="clickandgotoCatalogueID" class="btn btn-primary">Go</button></div>
</div></div>
</form>
};

declare function apprest:namedentitiescorresps($this, $collection){
let $document := $this
let $id := string($this/@xml:id)
return

let $refs := 

for $r in (
$document//t:persName[not(ancestor::t:listPerson)][@ref], 
$document//t:title[@ref], 
$document//t:placeName[@ref], 
$document//t:region[@ref], 
$document//t:country[@ref], 
$document//t:settlement[@ref], 
$document//t:relation[@name ='saws:isAttributedToAuthor'])
return 
if($r/@ref = ' ' or $r/@ref = '') then (<ref>no valid id</ref>)
else if($r[name() = 'relation']) then <ref ref="{$r/@passive}"></ref>
else
                       <ref ref="{if (contains($r/@ref, '#')) then substring-before($r/@ref, '#') else string($r/@ref)}"></ref>
 let $corresps := 

for $r in $document//t:ref[@corresp]

                       return <ref ref="{if (contains($r/@corresp, '#')) then substring-before($r/@corresp, '#') else string($r/@corresp)}"></ref>
let $all := ($refs/@ref, $corresps/@ref)
for $namedEntity in distinct-values($all)
return
<div id="{$namedEntity}relations-all" class="hidden">
<div id="{$namedEntity}relations-content">
{apprest:AnyReferences($id, $namedEntity)}
</div>
</div>
};


(:~a list of items pointing to something:)
declare function apprest:AnyReferences($sourceid, $id as xs:string){
let $file := collection($config:data-root)
let $ref := apprest:WhatPointsHere($id, $file)
  return
<ul xmlns="http://www.w3.org/1999/xhtml" class="nodot"><head xmlns="http://www.w3.org/1999/xhtml" >This record, with ID: {string($id)} is mentioned by </head>
    {apprest:referencesList($sourceid, $ref, 'name')}

      </ul>
};



(:~searches an ID in a @corresp, @ref, <relation> and makes a list :)
declare function apprest:WhatPointsHereQuery($id as xs:string){
for $corr in (collection($config:data-root)//t:*[ft:query(@corresp, $id)], 
        collection($config:data-root)//t:*[ft:query(@ref, $id)], 
        collection($config:data-root)//t:relation[ft:query(., $id)])
        order by ft:score($corr) descending
        return 
            $corr
            
            };
       
(: ~          used by apprest.xqm and timeline.xqm :)
declare function apprest:WhatPointsHere($id as xs:string, $c){
            let $witnesses := $c//t:witness[@corresp = $id]
let $placeNames := $c//t:placeName[@ref = $id]
let $persNames := $c//t:persName[@ref = $id]
let $ref := $c//t:ref[@corresp = $id]
let $titles := $c//t:title[@ref = $id]
let $settlement := $c//t:settlement[@ref = $id]
let $region := $c//t:region[@ref = $id]
let $country := $c//t:country[@ref = $id]
let $active := $c//t:relation[@active = $id]
let $passive := $c//t:relation[@passive = $id]
let $allrefs := ($witnesses, 
        $placeNames,  
        $persNames, 
        $ref,
        $titles,
        $settlement,
        $region,
        $country,
        $active, 
        $passive)
return
for $corr in $allrefs
        return 
            $corr
            
            };



(:~collects bibliographical information for zotero metadata:)
declare function apprest:bibdata ($id, $collection)  as node()*{
let $file := collection($config:data-root)//t:TEI/id($id)
return

(:here I cannot use for the title the javascript titles.js because the content is not exposed:)
<bibl>
{
for $author in distinct-values($file//t:revisionDesc/t:change/@who)
                return
<author>{app:editorKey(string($author))}</author>
}
<title level="a">{titles:printTitle($file)}</title>
<title level="j">{collection($config:data-root)//t:TEI/id($id)//t:publisher/text()}</title>
<date type="accessed"> [Accessed: {current-date()}] </date>
{let $time := max($file//t:revisionDesc/t:change/xs:date(@when))
return
<date type="lastModified">(Last Modified: {format-date($time, '[D].[M].[Y]')}) </date>
}
<idno type="url">
{($config:appUrl||'/' || $collection||'/' ||$id)}
</idno>
</bibl>
};


(:~prints the revision informations:)
declare function apprest:authors($this, $collection) {
let $document := $this
let $id := string($this/@xml:id)
let $app:bibdata := apprest:bibdata($id, $collection)
return

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
                {for $change in $document//t:revisionDesc/t:change
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
                {for $respStmt in $document//t:titleStmt/t:respStmt
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
     <div>{string:tei2string($document//t:editionStmt/node())}</div>
    </div>
    </div>
    
};



(:~embedded metadata for Zotero mapping:)

declare function apprest:app-meta($biblio as node()){

let $col :=$biblio//coll/text()
let $LM :=$biblio//date[@type='lastModified']/text()
let $url := $biblio//idno[@type='url']
return
        (
     <meta  xmlns="http://www.w3.org/1999/xhtml" name="description" content="{$config:repo-descriptor/repo:description/text()}"/>,
    for $genauthor in $config:repo-descriptor/repo:author
    return <meta xmlns="http://www.w3.org/1999/xhtml" name="creator" content="{$genauthor/text()}"></meta>,
    for $author in $biblio//author
         return  <meta  xmlns="http://www.w3.org/1999/xhtml" property="dcterms:creator schema:creator" content="{$author}"></meta>,
     <meta  xmlns="http://www.w3.org/1999/xhtml" property="dcterms:type schema:genre" content="{switch($col)
         case 'manuscripts' return 'Catalogue of ethiopian manuscripts'
         case 'works' return 'Clavis of Ethiopian Literature'
         case 'narratives' return 'Clavis of Ethiopian Literature'
         case 'places' return 'Gazetteer of Places'
         case 'institutions' return 'Gazetteer of Places'
         case 'persons' return 'A prosopography of Ethiopia'
         default return 'catalogue'}"></meta>,
    <meta xmlns="http://www.w3.org/1999/xhtml" property="schema:isPartOf" content="{$config:appUrl}/{$col}"></meta>,
    <meta  xmlns="http://www.w3.org/1999/xhtml" property="og:site_name" content="Beta maṣāḥǝft: Manuscripts of Ethiopia and Eritrea"></meta>,
    <meta  xmlns="http://www.w3.org/1999/xhtml" property="dcterms:language schema:inLanguage" content="en"></meta>,
    <meta  xmlns="http://www.w3.org/1999/xhtml" property="dcterms:rights" content="Copyright &#169; Akademie der Wissenschaften in Hamburg, Hiob Ludolf Zentrum für Äthiopistik.  Sharing and remixing permitted under terms of the Creative Commons Attribution Share alike Non Commercial 4.0 License (cc-by-nc-sa)."></meta>,
    <meta   xmlns="http://www.w3.org/1999/xhtml" property="dcterms:publisher schema:publisher" content="Akademie der Wissenschaften in Hamburg, Hiob Ludolf Zentrum für Äthiopistik"></meta>,
    <meta  xmlns="http://www.w3.org/1999/xhtml" property="dcterms:date schema:dateModified" content="{$LM}"></meta>,
    <meta  xmlns="http://www.w3.org/1999/xhtml" property="dcterms:identifier schema:url" content="{$url}"></meta>
    )
};



(:~html page title:)
declare function apprest:app-title($id) as element()* {  
<title xmlns="http://www.w3.org/1999/xhtml" property="dcterms:title og:title schema:name" >{titles:printTitleID($id)}</title>
};

(:~html page js calls:)
declare function apprest:footerjsSelector() as element()* {
        if (contains(request:get-uri(), 'analytic')) 
        then (<script xmlns="http://www.w3.org/1999/xhtml" type="text/javascript" src="resources/js/datatable.js"/>,
        <script xmlns="http://www.w3.org/1999/xhtml" type="text/javascript" src="resources/js/visgraphspec.js"/>) 
        else ()
        };

(:~html page script and styles to be included :)
declare function apprest:scriptStyle(){
(
        <link rel="shortcut icon" href="resources/images/minilogo.ico"/>,
        <link rel="stylesheet" type="text/css" href="$shared/resources/css/bootstrap-3.0.3.min.css"/>,
        <link rel="stylesheet" type="text/css" href="resources/css/bootstrap.icon-large.min.css" />,
        <link rel="stylesheet" type="text/css" href="https://cdnjs.cloudflare.com/ajax/libs/bootstrap-slider/9.5.1/css/bootstrap-slider.min.css"/>,
        <link rel="stylesheet" type="text/css" href="resources/font-awesome-4.7.0/css/font-awesome.min.css"/>   ,
        <link rel="stylesheet" type="text/css" href="https://code.jquery.com/ui/1.12.1/themes/base/jquery-ui.css"/>,
        <link rel="stylesheet" type="text/css" href="https://cdnjs.cloudflare.com/ajax/libs/virtual-keyboard/1.26.22/css/keyboard-basic.min.css"/>,
        <link rel="stylesheet" type="text/css" href="http://cdn.jsdelivr.net/jquery.slick/1.6.0/slick.css"/>,
        <link rel="stylesheet" type="text/css" href="http://cdn.jsdelivr.net/jquery.slick/1.6.0/slick-theme.css"/>,
        <link href="https://maxcdn.bootstrapcdn.com/bootswatch/3.3.7/flatly/bootstrap.min.css" rel="stylesheet" integrity="sha384-+ENW/yibaokMnme+vBLnHMphUYxHs34h9lpdbSLuAwGkOKFRl4C34WkjazBtb7eT" crossorigin="anonymous"></link>,
        <link rel="stylesheet" type="text/css" href="resources/css/style.css"/>,
        <script type="text/javascript" src="http://code.jquery.com/jquery-1.11.1.min.js"/>,
        <script type="text/javascript" src="https://code.jquery.com/ui/1.12.1/jquery-ui.min.js"></script>,
        <script type="text/javascript" src="https://cdnjs.cloudflare.com/ajax/libs/virtual-keyboard/1.26.22/js/jquery.keyboard.js"/>,
        <script type="text/javascript" src="https://cdnjs.cloudflare.com/ajax/libs/virtual-keyboard/1.26.22/js/jquery.mousewheel.min.js"/>,
        <script type="text/javascript" src="https://cdnjs.cloudflare.com/ajax/libs/virtual-keyboard/1.26.22/js/jquery.keyboard.extension-typing.min.js"/>,
        <script type="text/javascript" src="https://cdnjs.cloudflare.com/ajax/libs/virtual-keyboard/1.26.22/js/jquery.keyboard.extension-altkeyspopup.min.js"></script>,
        <script type="text/javascript" src="http://cdn.jsdelivr.net/jquery.slick/1.6.0/slick.min.js"/>,
        <script type="text/javascript" src="$shared/resources/scripts/loadsource.js"/>,
        <script type="text/javascript" src="$shared/resources/scripts/bootstrap-3.0.3.min.js"/>,
        <script  type="text/javascript" src="resources/js/jquery.dataTables.min.js"/>,
        <script type="text/javascript" src="resources/js/dataTables.bootstrap.min.js"/>,
        <script type="text/javascript" src="https://cdnjs.cloudflare.com/ajax/libs/bootstrap-slider/9.5.1/bootstrap-slider.min.js"/>,
        <script type="text/javascript" src="resources/js/diacriticskeyboard.js"/>,
        <script type="text/javascript" src="resources/openseadragon/openseadragon.min.js"/>,
        <script type="text/javascript" src="resources/js/analytics.js"></script>
        )};


(:~html page script and styles to be included specific for item :)
declare function apprest:ItemScriptStyle(){
<link xmlns="http://www.w3.org/1999/xhtml" rel="stylesheet" type="text/css" href="resources/css/mapbox.css"/>,
        <link xmlns="http://www.w3.org/1999/xhtml" rel="stylesheet" type="text/css" href="resources/css/leaflet.css"/>,
        <link xmlns="http://www.w3.org/1999/xhtml" rel="stylesheet" type="text/css" href="resources/css/leaflet.fullscreen.css"/>,
        <link xmlns="http://www.w3.org/1999/xhtml" rel="stylesheet" type="text/css" href="resources/css/leaflet-search.css"/>,
        <link rel="stylesheet" type="text/css" href="https://cdnjs.cloudflare.com/ajax/libs/vis/4.12.0/vis.min.css"/>,
       <script xmlns="http://www.w3.org/1999/xhtml" type="text/javascript" src="http://cdn.leafletjs.com/leaflet/v0.7.7/leaflet.js"/>,
        <script xmlns="http://www.w3.org/1999/xhtml" type="text/javascript" src="resources/js/mapbox.js"/>,
        <script  xmlns="http://www.w3.org/1999/xhtml" type="text/javascript" src="resources/js/Leaflet.fullscreen.min.js"/>,
        <script  xmlns="http://www.w3.org/1999/xhtml" type="text/javascript" src="resources/js/leaflet-search.js"/>,
         <script xmlns="http://www.w3.org/1999/xhtml" type="text/javascript" src="resources/js/leaflet-ajax-gh-pages/dist/leaflet.ajax.min.js"></script>,
                         <script xmlns="http://www.w3.org/1999/xhtml" type="text/javascript" src="https://cdnjs.cloudflare.com/ajax/libs/vis/4.12.0/vis.min.js"/>,
        <script src="resources/awdl/lib/requirejs/require.min.js" type="text/javascript"/>,
         <script src="resources/awdl/awld.js" type="text/javascript"/>,
        <script type="text/javascript">
                           awld.init();
                        </script>
};

(:~html page script and styles to be included specific for item :)
declare function apprest:ItemFooterScript(){
<script type="text/javascript" src="resources/js/ugarit.js"/>,
        <script type="text/javascript" src="resources/js/highlight.js"/>,
        <script type="text/javascript" src="resources/js/toogle.js"/>,
        <script type="text/javascript" src="resources/js/titles.js"/>,
        <script type="text/javascript" src="resources/js/NewBiblio.js"/>,
        <script type="text/javascript" src="resources/js/PointsHere.js"/>,
        <script type="text/javascript" src="resources/js/resp.js"/>,
        <script type="text/javascript" src="resources/js/slickoptions.js"/>,
        <script type="text/javascript" src="resources/js/relatedItems.js"/>,
        <script type="text/javascript" src="resources/js/citations.js"/>
};

(:~ be kind to the logged user :)
declare function apprest:greetings-rest(){
<a href="">Hi {xmldb:get-current-user()}!</a>
    };

(:~ produces the lists and updates the filters :)

declare 
%templates:default('start', 1) 
%templates:default("per-page", 20) 
function apprest:listrest($type, 
$collection, $parameters as map(*), $params) {
let $keywords := $parameters('key')
let $languages := $parameters('lang')
let $dateRange := $parameters('date')
let $clavisType := $parameters('clavistype')
let $clavisID := $parameters('clavisID')
let $numberOfP := $parameters('numberOfParts')
let $key := if($keywords = '') then () else 
switch($collection)
case 'narratives' return ()
case 'institutions' return apprest:ListQueryParam-rest($keywords, 't:ab[@type="tabot"]/t:persName/@ref', 'any', 'list')
case 'places' return apprest:ListQueryParam-rest($keywords, 't:place/@type', 'any', 'list')
case 'persons' return apprest:ListQueryParam-rest($keywords, 't:occupation/@type', 'any', 'list')
default return apprest:ListQueryParam-rest($keywords, 't:term/@key', 'any', 'list')
let $ClavisIDs := 
if(($clavisID = '') and ($clavisType = '')) then () 
else if(($clavisID = '') and (matches($clavisType, '\w+'))) then "[descendant::t:bibl[@type='"||$clavisType||"']]" 
else  "[descendant::t:bibl[@type='"||$clavisType||"'][t:citedRange[@unit='item'] ='"||$clavisID||"']]"
let $languages := if($languages = '') then () else  apprest:ListQueryParam-rest($languages, 't:language/@ident', 'any', 'list')
let $dR :=  if ($dateRange) 
                then (
                let $range := $dateRange
                let $from := substring-before($dateRange, ',') 
                let $to := substring-after($dateRange, ',') 
                return
                if ($dateRange = '0,2000')
                then ()
                else
                "[descendant::t:*
                [xs:integer((if (contains(@notBefore, '-')) then (substring-before(@notBefore, '-')) else @notBefore)[. !='']) >= " || $from || " or 
                xs:integer((if (contains(@notAfter, '-')) then    (substring-before(@notAfter, '-')) else    @notAfter)[. != '']) >= " ||$from||"]
                [xs:integer((if (contains(@notBefore, '-')) then (substring-before(@notBefore, '-')) else @notBefore)[. !='']) <= " || $to || " or 
                xs:integer((if (contains(@notAfter, '-')) then (substring-before(@notAfter, '-')) else @notAfter)[. != '']) <= " ||$to ||"]]" ) else ()
let $nOfP := if(empty($numberOfP) or $numberOfP = '') then (console:log('empty')) else '[count(descendant::t:msPart) ge ' || $numberOfP || ']'
let $path := switch($type)
case 'catalogue' return "collection('"||$config:data-rootMS || "')//t:TEI[descendant::t:listBibl[@type='catalogue']//t:ptr[@target='"||$collection||"']]"  || $key || $languages || $dR
case 'repo' return "collection('"||$config:data-rootMS || "')//t:TEI[descendant::t:repository[@ref='"||$collection||"']]"  || $key || $languages || $dR
default return 
if ($collection = 'places') 
then ("(collection('/db/apps/BetMas/data/"||$collection || "')//t:TEI"   || $key || $languages|| $dR || ", collection('/db/apps/BetMas/data/institutions')//t:TEI" || $key || $languages  || $dR || ')') 
else "collection('/db/apps/BetMas/data/"||$collection || "/')//t:TEI"   || $key || $languages|| $dR || $ClavisIDs || $nOfP
let $hits := for $resource in util:eval($path)
let $recordid := string($resource/@xml:id)
let $recordtype := string($resource/@type)

let $sorting := if(matches($recordid, '\w{3}\d+')) then substring($recordid, 4, 4) else substring($recordid, 0, 3)
            order by $sorting
                      return $resource
                      return 
                      map { 
                      'hits' := $hits,
                      'collection' := $collection
                      }
};



declare function apprest:ListQueryParam-rest($parameter, $context, $mode, $function){
let $keys := 
        if ($parameter = 'keyword')
        then (
        for $k in $parameter 
      
        let $ks := doc($config:data-rootA || '/taxonomy.xml')//t:catDesc[text() = $k]/following-sibling::t:*/t:catDesc/text() 
        let $nestedCats := for $n in $ks return $n 
            return 
            if ($nestedCats >= 2) then (replace($k, '#', ' ') || ' OR ' || string-join($nestedCats, ' OR ')) else (replace($k, '#', ' '))
        )
        else(
            for $k in $parameter 
            return 
            replace($k, '#', ' ') 
            )
            
       return 
       if ($function = 'list')
       then
     let $all :=  for $k in $keys
       return
       "descendant::" || $context || "='" || $k ||"'"
       return
      "[" || string-join($all, ' or ') || "]"
       else 
       (:search:)
       let $limit := for $k in $parameter 
            return 
       "ancestor::t:TEI/" || $context || "='" || $k ||"' "
       return
       "[" || string-join($limit, ' or ') || "]"
       
       
};


(:~ the form in the list view which provides also the filters :)

declare function apprest:searchFilter-rest($collection, $model as map(*)) {
let $items-info := $model('hits')

let $onchange := 'if (this.value) window.location.href=this.value'
return

<form action="" class="form form-horizontal">

<div class="form-group">{app:nextID($collection)}</div>
<div class="form-group">
<div class="alert alert-info">Here you can go directly to an item, searching the content of ist title or part of its id.</div>
<label class="form-check-label">
                            <input type="radio" class="form-check-input" name="AttestedInType" id="AttestedInTypeID" value="1" checked="checked"/>
                            ID
                        </label>
                            <label class="form-check-label">
                                <input type="radio" class="form-check-input" name="AttestedInType" id="AttestedInTypeTITLE" value="2"/>
                                Title
                            </label>
                            <div class="input-group">

<input placeholder="Type a title or an id here..." class="form-control" id="GoTo" list="gotohits" autocomplete="on" data-value="{$collection}"/>
<select class="form-control" xmlns="http://www.w3.org/1999/xhtml"  id="gotohits">
        
            </select>
            <div class="input-group-btn">
<button id="clickandgoto" class="btn btn-primary"> Go
                    </button>
                    </div>
                    
                    </div>
                    <small>Selecting or typing an item id here and clicking on go will take you to that item directly.</small>
            
                    
                    </div>
<div class="alert alert-info">The following filters can be applied by clicking on the filter icon below, to return to the full list, click the list, to go to advanced search the cog</div>

<div class="form-group">
                <label for="dates">date range</label>
                <div class="input-group">
                <input id="dates" type="text" class="span2" 
                name="date-range" 
                data-slider-min="0" 
                data-slider-max="2000" 
                data-slider-step="10" 
                data-slider-value="[0,2000]"/>
                <script type="text/javascript">
                {"$('#dates').bootstrapSlider({});"}
                </script>
            </div>
            </div>
                {app:formcontrol('language', $items-info//@xml:lang, 'true', 'values'),
 switch($collection) 
case 'narratives' return ()
case 'works' return (
                <div class="form-group">
    <div class="col">
    <label>Other Clavis ID</label>
                <select name="clavistype" class="form-control">
<option value="BHG">BHG</option>
<option value="BHO">BHO</option>
<option value="CAVT">CAVT</option>
<option value="CANT">CANT</option>
<option value="CC">CC</option>
<option value="CPG">CPG</option>
<option value="KRZ">KRZ</option>
<option value="H">H</option>
</select>
</div>
    <div class="col">
<input class="form-control" type="number" name="clavisID"/></div></div>, apprest:formcontrol('keyword','keyword', $items-info//t:term/@key, 'true', 'titles'))
(:                case 'institutions' return apprest:formcontrol('tabot','keyword', $items-info//t:ab[@type='tabot']/t:persName/@ref, 'true', 'rels'):)
case 'places' return apprest:formcontrol('place type','keyword', $items-info//t:place/@type, 'true', 'values')
case 'persons' return apprest:formcontrol('occupation','keyword', $items-info//t:occupation/@type, 'true', 'titles')
default return apprest:formcontrol('keyword','keyword', $items-info//t:term/@key, 'true', 'titles')
            }
            <div class="form-group">
            <label for="numberOfP">Limit by minimum number of codicological units</label>
            <input id="numberOfP" class="form-control" type="number" name="numberOfParts"></input>
            </div>
            <div class="form-group">
            <div class="btn-group">
                <button type="submit" class="btn btn-primary"><i class="fa fa-filter" aria-hidden="true"></i>
</button>
                    <a href="/{$collection}/list" role="button" class="btn btn-info"><i class="fa fa-th-list" aria-hidden="true"></i></a>
                <a href="/as.html" role="button" class="btn btn-primary"><i class="fa fa-cog" aria-hidden="true"/></a>
                </div>
                </div>
</form>
};

(:~ pagination element for search results :)

declare function apprest:paginate-rest($model as map(*), $parameters as map(*), $start as xs:int, $per-page as xs:int, $min-hits as xs:int, $max-pages as xs:int) {
       <div class="col-md-12"><ul class="pagination">{
     
    if ($min-hits < 0 or count($model("hits")) >= $min-hits) then
        let $count := xs:integer(ceiling(count($model("hits"))) div $per-page) + 1
        let $middle := ($max-pages + 1) idiv 2
        
        return (
            if ($start = 1) then (
                <li class="disabled">
                    <a><i class="fa fa-fast-backward" aria-hidden="true"></i></a>
                </li>,
                <li class="disabled">
                    <a><i class="fa fa-backward" aria-hidden="true"></i></a>
                </li>
            ) else (
                <li>
                    <a href="?per-page={$per-page}&amp;start=1&amp;keyword={$parameters('key')}&amp;date-range={$parameters('date')}&amp;language={$parameters('lang')}"><i class="glyphicon glyphicon-fast-backward"/></a>
                </li>,
                <li>
                    <a href="?per-page={$per-page}&amp;start={max( ($start - $per-page, 1 ) ) }&amp;keyword={$parameters('key')}&amp;date-range={$parameters('date')}&amp;language={$parameters('lang')}"><i class="glyphicon glyphicon-backward"/></a>
                </li>
            ),
            let $startPage := xs:integer(ceiling($start div $per-page))
            let $lowerBound := max(($startPage - ($max-pages idiv 2), 1))
            let $upperBound := min(($lowerBound + $max-pages - 1, $count))
            let $lowerBound := max(($upperBound - $max-pages + 1, 1))
            for $i in $lowerBound to $upperBound
            return
                if ($i = ceiling($start div $per-page)) then
                    <li class="active"><a href="?per-page={$per-page}&amp;start={max( (($i - 1) * $per-page + 1, 1) )}&amp;keyword={$parameters('key')}&amp;date-range={$parameters('date')}&amp;language={$parameters('lang')}">{$i}</a></li>
                else
                    <li><a href="?per-page={$per-page}&amp;start={max( (($i - 1) * $per-page + 1, 1)) }&amp;keyword={$parameters('key')}&amp;date-range={$parameters('date')}&amp;language={$parameters('lang')}">{$i}</a></li>,
            if ($start + $per-page < count($model("hits"))) then (
                <li>
                    <a href="?per-page={$per-page}&amp;start={$start + $per-page}&amp;keyword={$parameters('key')}&amp;date-range={$parameters('date')}&amp;language={$parameters('lang')}"><i class="glyphicon glyphicon-forward"/></a>
                </li>,
                <li>
                    <a href="?per-page={$per-page}&amp;start={max( (($count - 1) * $per-page + 1, 1))}&amp;keyword={$parameters('key')}&amp;date-range={$parameters('date')}&amp;language={$parameters('lang')}"><i class="glyphicon glyphicon-fast-forward"/></a>
                </li>
            ) else (
                <li class="disabled">
                    <a><i class="fa fa-step-forward" aria-hidden="true"></i></a>
                </li>,
                <li>
                    <a><i class="fa fa-fast-forward" aria-hidden="true"></i></a>
                </li>
            )
        ) else
            ()
            }
             <li><form action="" class="form-inline"><div class="input-group">
            <input type="hidden" name="start" value="{$start}"/>
            <input type="hidden" name="keyword" value="{$parameters('key')}"/>
            <input type="hidden" name="language" value="{$parameters('lang')}"/>
            <input type="hidden" name="date-range" value="{$parameters('date')}"/>
   <input type="number" class="form-control" name="per-page" placeholder="how many per page?"></input>
   <span class="input-group-btn">
   <button type="submit" class="btn btn-primary">
   <i class="fa fa-check" aria-hidden="true"></i>
   </button>
   </span>
   </div></form></li>
   <li><button class="btn btn-default printgroup">Print PDF with all selected items</button>
       </li>
            </ul></div>
};

(:~ 
 builds the form control according to the data specification:)
declare function apprest:formcontrol($label as xs:string*, $nodeName as xs:string, $path, $group, $type) {

        

if ($group = 'true') then ( 

let $values := for $i in $path return  if (contains($i, ' ')) then tokenize($i, ' ') else if ($i=' ' or $i='' ) then () else functx:trim(normalize-space($i))
                    let $nodes := distinct-values($values)
                    
                    return <div class="form-group">
                    <label for="{$nodeName}">{$label}s <span class="badge">{count($nodes[. != ''][. != ' '])}</span></label>
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

declare function functx:trim( $arg as xs:string? )  as xs:string {

   replace(replace($arg,'\s+$',''),'^\s+','')
 } ;
 
 
(:~ 
 given an id looks for all manuscripts containing it and returns a div with cards use by Slick for the Carousel view:)
 declare function apprest:compareMssFromForm($target-work as xs:string?) {
     
 let $MAINtit := titles:printTitleID($target-work)
     return
 if($target-work = '') then ()
 else(
<h2>Compare manuscripts which contain <span>{$MAINtit}</span></h2>,
let $c := collection($config:data-rootMS)
let $items := $c//t:msItem
let $matchingmss := $items/t:title[@ref = $target-work]
return
if(count($matchingmss) = 0) then (<p class="lead">Oh no! Currently, none of the catalogued manuscripts contains a link to this work. You can still see the record in case you find there useful information.</p>,<a class="btn btn-primary" href="{$target-work}"> Go to {$MAINtit}</a>) else 
(
<p class="lead">They are currently {count($matchingmss)}.</p>,
<div class="msscomparison col-md-12">
{
for $manuscript in $matchingmss
let $msid := string(root($manuscript)/t:TEI/@xml:id)
let $minnotBefore := min(root($manuscript)/t:TEI//@notBefore)
let $maxnotAfter := min(root($manuscript)/t:TEI//@notAfter)
order by $minnotBefore
return
<div class="card">
<div class="card-block">
<h3 class="card-title"><a href="{('/'||$msid)}">{titles:printTitleID($msid)}</a> ({string($minnotBefore)}-{string($maxnotAfter)})</h3>
<p class="card-text">
<ul class="nodot">
{for $msitem at $p in root($manuscript)/t:TEI//t:msItem
(:  store in a variable the ref in the title or nothing:)
let $title := if ($msitem/t:title[@ref]) then $msitem/t:title[1]/@ref else ''
order by $p
return
<li style="{if(matches($msitem/@xml:id, '\d+\.\d+\.\d+')) 
then 'text-indent: 4%;' 
else if(matches($msitem/@xml:id, '\d+\.\d+')) 
then 'text-indent: 2%;' else ()}">
{string($msitem/@xml:id )} 
{if($msitem/t:title/@type) 
     then ( ' (' || string($msitem/t:title[1]/@type) || ')') 
     else ()}, 
{if($title = $target-work) (:highlight the position of the currently selected work:)
    then <mark>
        <a  class="itemtitle" data-value="{$title}" href="{$title}">{$MAINtit}</a>
        </mark> 
        (:if there is no ref, take the text of the element title content:)
        else if ($msitem/t:title[not(@ref)]/text()) 
   then normalize-space(string-join(string:tei2string($msitem/t:title/node())))
    (:normally print the title of the referred item:)
else <a class="itemtitle" data-value="{$title}" href="{$title}">{if($title = '') then <span class="label label-warning">{'no ref in title'}</span> else try{titles:printTitleID($title)} catch * {$title}}</a>}</li>}
</ul>
</p>
</div>
</div>
}
</div>
))
};
