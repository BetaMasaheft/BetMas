xquery version "3.0" encoding "UTF-8";
(:~
 : module used by items.xql for several parts of the view produced
 :
 : @author Pietro Liuzzo
 :)
module namespace item2="https://www.betamasaheft.uni-hamburg.de/BetMas/item2";
import module namespace config="https://www.betamasaheft.uni-hamburg.de/BetMas/config" at "xmldb:exist:///db/apps/BetMas/modules/config.xqm";
import module namespace string = "https://www.betamasaheft.uni-hamburg.de/BetMas/string" at "xmldb:exist:///db/apps/BetMas/modules/tei2string.xqm";
import module namespace apprest = "https://www.betamasaheft.uni-hamburg.de/BetMas/apprest" at "xmldb:exist:///db/apps/BetMas/modules/apprest.xqm";
import module namespace editors="https://www.betamasaheft.uni-hamburg.de/BetMas/editors" at "xmldb:exist:///db/apps/BetMas/modules/editors.xqm";
import module namespace wiki="https://www.betamasaheft.uni-hamburg.de/BetMas/wiki" at "xmldb:exist:///db/apps/BetMas/modules/wikitable.xqm";
import module namespace titles="https://www.betamasaheft.uni-hamburg.de/BetMas/titles" at "xmldb:exist:///db/apps/BetMas/modules/titles.xqm";
import module namespace app="https://www.betamasaheft.uni-hamburg.de/BetMas/app" at "xmldb:exist:///db/apps/BetMas/modules/app.xqm";
import module namespace xdb="http://exist-db.org/xquery/xmldb";
declare namespace test="http://exist-db.org/xquery/xqsuite";
declare namespace s = "http://www.w3.org/2005/xpath-functions";
declare namespace t="http://www.tei-c.org/ns/1.0";

(:~ used by item2:restNav:)
declare function item2:witnesses($id){
let $item := ($config:collection-rootMS, $config:collection-rootW)//t:TEI/id($id)
return
if($item/@type='mss') then 
<div class="w3-bar-item" id="textWitnesses">
<h5>Transcription of the manuscript</h5>
</div>
else
(<div class="w3-bar-item" id="textWitnesses">
<h5>Witnesses of the edition</h5>
</div>,
<ul class=" w3-bar-item nodot">
{
for $wit in $item//t:witness[not(@type)] return
<li class="nodot" id="{string($wit/@xml:id)}">
<a href="/manuscripts/{string($wit/@corresp)}/main" target="_blank"><b class="lead">{string($wit/@xml:id)}</b>: {titles:printTitleID(string($wit/@corresp))}</a></li>}
{
for $wit in $item//t:witness[@type = 'external'] return
<li class="nodot" id="{string($wit/@xml:id)}">
<a href="{$wit/@facs}" target="_blank"><b class="lead">{string($wit/@xml:id)}</b>: {if($wit/text()) then $wit/text() else string($wit/@corresp)}</a></li>}

</ul>
       ,
       let $versions := $config:collection-root//t:relation[@name='saws:isVersionOf'][contains(@passive, $id)]
       return
       if($versions) then (<h5 class="w3-bar-item">Other versions</h5>,
         <ul  class="w3-bar-item nodot">
                {
                    for $parallel in $versions
                    let $p := $parallel/@active
                    return
                        <li><a
                                href="{$p}" class="MainTitle"  data-value="{$p}" >{$p}</a></li>
                }
            </ul>)
            else()
            ,
            
            let $versionsO := $config:collection-root//t:relation[@name='isVersionInAnotherLanguageOf'][contains(@passive, $id)]
       return
       if($versionsO) then (
            <h5 class="w3-bar-item">Versions in another language</h5>,
            <ul  class=" w3-bar-item nodot">
                {
                    for $parallel in $versionsO
                     let $p := $parallel/@active
                    return
                        <li><a
                                href="{$p}" class="MainTitle"  data-value="{$p}" >{$p}</a></li>
                }
            </ul>)
            else(),

            <a class="w3-bar-item w3-button w3-red" href="/compare?workid={$id}" target="_blank">Compare</a>
)
};

(:~ under the main navigation bar there are the view options, this function returns the available values deciding on the type of input:)
declare function item2:RestViewOptions($this, $collection) {
let $document := $this
let $id := string($this/@xml:id)
return
<div xmlns="http://www.w3.org/1999/xhtml" class="w3-bar w3-small" id="options">

 <div class="w3-bar-item" >
 <a class="w3-button w3-padding-small w3-gray" href="javascript:void(0);" onclick="startIntroItem();">Explore this page</a>
 </div>
 <div class="w3-bar-item w3-tooltip" >
 <a class="w3-button w3-padding-small w3-gray" target="_blank" href="https://github.com/BetaMasaheft/Documentation/issues/new/choose">
                                <i class="fa fa-envelope"/>
                            </a>
                            <span class="w3-text w3-tag itemoptiontooltip">Do you want to notify us of an error, please do so by writing an issue in our GitHub repository (click the envelope for a precomiled one).</span>

     </div>                       
            
 <div class="w3-bar-item  
 w3-hide-large w3-tooltip" >
 <span class="w3-text w3-tag itemoptiontooltip">On small screens, will show a navigation bar on the left</span>
 <a class="w3-button w3-padding-small w3-gray" onclick="w3_openItemSB()">Open 
 Item Navigation</a>
 </div>
<div class="w3-bar-item  w3-tooltip">

<a target="_blank" class="w3-button w3-padding-small w3-gray" 
    href="https://github.com/BetaMasaheft/{replace(replace(base-uri($this), '/db/apps/BetMasData/', ''), 
    $collection, concat($collection, '/blob/master'))}">Edit</a>
    <span class="w3-text w3-tag itemoptiontooltip">
Not sure how to do this? Have a look at the <a href="/Guidelines">Beta maṣāḥǝft Guidelines</a>!
</span>
    </div>
<div class="w3-bar-item w3-tooltip" >
<a class="w3-button w3-padding-small w3-gray" id="toggleHands">Hide/show pointers</a>
<span class="w3-text w3-tag itemoptiontooltip">Click here to hide or show again the little arrows and small left pointing hands in this page.</span>
</div>
<div class="w3-bar-item w3-tooltip" >
<a class="w3-button w3-padding-small w3-gray" id="toogleSeeAlso">Hide/show related</a>
<span class="w3-text w3-tag itemoptiontooltip">Click here to hide or show again the right side of the content area, where related items and keywords are shown.</span>
</div>
            
<div class="w3-bar-item w3-tooltip">
{app:pdf-link($id)}
<span class="w3-text w3-tag itemoptiontooltip">Produces a PDF on the fly from the source TEI-XML using XSL-FO and Apache FOP</span>
</div>

<div class="w3-bar-item w3-tooltip" >
           <a class="w3-button w3-padding-small w3-gray"  id="mainEntryLink" href="/{$collection}/{$id}/main" 
           target="_blank" >Entry</a>
<span class="w3-text w3-tag itemoptiontooltip">Main Entry</span>
 </div>
<div class="w3-bar-item w3-tooltip">
<a class="w3-button w3-padding-small w3-gray"  id="TEILink" href="{( '/tei/' || $id ||  '.xml')}" target="_blank">TEI/XML</a>
<span class="w3-text w3-tag itemoptiontooltip">Download an enriched TEI file with explicit URIs bibliography from Zotero API. </span>
</div>
<div class="w3-bar-item w3-tooltip">
<a class="w3-button w3-padding-small w3-gray"  id="GraphViewLink"  href="/{$collection}/{$id}/graph" target="_blank">{if($collection = 'manuscripts') then <i>Syntaxe</i> else 'Graph'}</a>
<span class="w3-text w3-tag itemoptiontooltip">See graphs of the information available. If the manuscript contains relevant information, 
then you will see visualizations based on La Syntaxe du Codex, by Andrist, Canart and Maniaci.</span>
</div>
    {if(($collection = 'institutions' or $collection = 'places') and ($document//t:geo/text() or $document//t:place[@sameAs] )) then
    <div class="w3-bar-item"><a class="w3-button w3-padding-small w3-gray"  href="/{( $id ||
    '.json')}" target="_blank">geoJson</a></div> else ()}
<div class="w3-bar-item w3-tooltip"  
><a class="w3-button w3-padding-small w3-gray"  href="/{$collection}/{$id}/analytic" target="_blank">Relations</a>
<span class="w3-text w3-tag itemoptiontooltip">Further visualization of relational information</span></div>
    {if ($collection = 'works' or $collection = 'narratives') then
    (<div class="w3-bar-item w3-tooltip" 
  >
    <a class="w3-button w3-padding-small w3-red"  href="{('/'||$collection|| '/' || $id || '/text' )}" 
    target="_blank">Text</a>
    <span class="w3-text w3-tag itemoptiontooltip">Text (as available). Do you have a text you want to contribute? 
    Contact us or click on EDIT and submit your contribution.</span>
    </div>,
    <div class="w3-bar-item w3-tooltip" >
    <a class="w3-button w3-padding-small w3-gray"  href="{('/'||$collection|| '/' || $id || '/geoBrowser' )}" 
    target="_blank">Places</a>
    <span class="w3-text w3-tag itemoptiontooltip">See places marked up in the text using the Dariah-DE Geo-Browser</span>
    </div>) else ()}
    {if ($collection = 'manuscripts') then
    <div class="w3-bar-item w3-tooltip"  >
    <a class="w3-button w3-padding-small w3-red"  href="{('/'||$collection|| '/' || $id || '/text' )}" 
    target="_blank">Transcription</a>
    <span class="w3-text w3-tag itemoptiontooltip">Transcription (as available). Do you have a transcription you want to contribute? 
    Contact us or click on EDIT and submit your contribution.</span>
    </div> else ()}
    {if ($collection = 'manuscripts' and ($this//t:msIdentifier/t:idno[@facs][@n] or $this//t:msIdentifier/t:idno[starts-with(@facs, 'http')])) then
    <div class="w3-bar-item w3-tooltip" >
    <a class="w3-button w3-padding-small w3-gray"  href="{('/manuscripts/' || $id || '/viewer' )}" 
    target="_blank">Images</a>
    <span class="w3-text w3-tag itemoptiontooltip">Manuscript images in the Mirador viewer via IIIF</span>
    </div> else ()}
    {if ($collection = 'manuscripts' and $this//t:facsimile/t:graphic) then
    <div class="w3-bar-item w3-tooltip" >
    <a class="w3-button w3-padding-small w3-gray"  href="{$this//t:facsimile/t:graphic/@url}" 
    target="_blank">Link to images</a>
    <span class="w3-text w3-tag itemoptiontooltip">Link to images available not on this site</span>
    </div> else ()}
    {if ($collection = 'works' or $collection = 'narratives') then
    (<div class="w3-bar-item w3-tooltip" >
    <a class="w3-button w3-padding-small w3-gray"  href="{('/compare?workid=' || $id  )}" target="_blank">Compare</a>
    <span class="w3-text w3-tag itemoptiontooltip">Compare manuscripts with this content</span>
    </div>,
    <div class="w3-bar-item w3-tooltip" >
    <a class="w3-button w3-padding-small w3-gray"  href="{('/workmap?worksid=' || $id  )}" target="_blank">Manuscripts Map</a>
    <span class="w3-text w3-tag itemoptiontooltip">Map of manuscripts with this content</span>
    </div>)
    else ()}
    
    </div>
};

(:~ produces each item header with contents:)

declare function item2:RestItemHeader($this, $collection) {
let $document := $this
let $id := string($this/@xml:id)
let $repoids := if ($document//t:repository/text() = 'Lost' or $document//t:repository/text() = 'In situ' ) 
                               then ($document//t:repository/text()) 
                             else if ($document//t:repository/@ref) 
                                then distinct-values($document//t:repository/@ref) 
                             else 'No Repository Specified'
let $key := for $ed in $document//t:titleStmt/t:editor[not(@role = 'generalEditor')]  
                                  return 
                                  editors:editorKey(string($ed/@key)) || (if($ed/@role) then ' (' ||string($ed/@role)|| ')' else ())

return

    <div xmlns="http://www.w3.org/1999/xhtml" class="ItemHeader w3-container">

    <div xmlns="http://www.w3.org/1999/xhtml" class="w3-twothird">
            <h1 id="headtitle">
                {titles:printTitleID($id)}
            </h1>
          <p id="mainEditor"><i>{string-join($key, ', ')}</i></p>
          {if($collection = 'manuscripts') then <p>{if($this//t:additional//t:source/t:listBibl[@type='catalogue']) then ('This manuscript description is based on ' , <a href="#catalogue">the catalogues listed in the catalogue bibliography</a> )
          else if($this//t:collection = 'EMIP') then string-join($this//t:collection//text(), ', ')
          else if(contains($this//t:funder, 'IslHornAfr')) then ('Newly catalogued in IslHornAfr, see also ', <a href="http://islhornafr.tors.sc.ku.dk/backend/manuscripts/{format-number(number(replace($id, 'IHA', '')), '####')}">IslHornAfr manuscript {format-number(number(replace($id, 'IHA', '')), '####')}</a>)
          else if(contains($this//t:idno, 'EMML')) then string:tei2string($this//t:editionStmt)
          else 'Newly catalogued in Beta maṣāḥǝft'}</p> else ()}
          </div>


    <div xmlns="http://www.w3.org/1999/xhtml" class="w3-third">


    <div  id="general" class="w3-container">
    <div class="w3-row">
   
   {if (count($document//t:change[not(@who='PL')]) eq 1) then
   <span class="w3-tag w3-red">Stub</span>
   else if ($document//t:change[contains(.,'completed')]) then
   <span class="w3-tag w3-gray" >Under Review</span>
     else if ($document//t:change[contains(.,'reviewed')]) then
   <span class="w3-tag w3-white" >Version of {max($document//t:change/xs:date(@when))}</span>
   else
<span class="w3-tag w3-red" >{"Work in progress, please don't use as reference"}</span>
    }
    </div>
    <div class="w3-row w3-hide-small"><span class="w3-tag w3-gray w3-small" style="word-break:break-all;">{$config:appUrl || '/' || $id}</span></div>
 {switch ($collection)
case 'manuscripts' return

    if($document//t:repository/text() = 'Lost' or $document//t:repository/text() = 'In situ')
    then <div class="w3-row"><span class="w3-tag w3-gray w3-large w3-margin-top">{$document//t:repository/text()}</span>
    <p class="w3-large">Collection:  {string-join($document//t:msIdentifier/t:collection, ', ')}</p>

            {if($document//t:altIdentifier) then
            <p>Other identifiers: {
                   for $altId at $p in $document//t:msIdentifier/t:altIdentifier/t:idno
                   return
                   if ( $altId/@type='TM') 
                   then 
                   <a href="https://www.trismegistos.org/text/{$altId/text()}" property="http://www.cidoc-crm.org/cidoc-crm/P1_is_identified_by" 
                    content="{$altId}">TM{$altId/text()}{if($altId[$p = count($document//t:msIdentifier/t:altIdentifier/t:idno/text())]) then ' ' else ', '}</a>
                   else 
                     <span property="http://www.cidoc-crm.org/cidoc-crm/P1_is_identified_by" 
                    content="{$altId/text()}">{$altId/text()}{if($altId[$p = count($document//t:msIdentifier/t:altIdentifier/t:idno/text())]) then ' ' else ', '}</span>
            }
            </p>
            else
            ()
            }</div>
    else
<div>
            { for $repo in $repoids
            let $repodoc := $config:collection-rootIn/id($repo)
             let $repoplace := if ($repodoc//t:settlement[1]/@ref) then titles:printTitleID($repodoc//t:settlement[1]/@ref) else if ($repodoc//t:settlement[1]/text()) then $repodoc//t:settlement[1]/text() else if ($repodoc//t:country[1]/@ref) then titles:printTitleID($repodoc//t:country[1]/@ref) else ()
return
            <a target="_blank" 
            href="/manuscripts/{$repo}/list" 
            role="button"
            class="w3-tag w3-gray w3-large w3-margin-top" 
            property="http://www.cidoc-crm.org/cidoc-crm/P55_has_current_location" 
            resource="http://betamasaheft.eu/{$repo}">{if($repoplace) then ($repoplace, ', ') else ()}
                   {titles:printTitleID($repo) }</a>
                  }


 <p class="w3-large">Collection:  {string-join($document//t:msIdentifier/t:collection, ', ')}</p>

           { if($document//t:altIdentifier) then
            <p>Other identifiers: {
                   for $altId at $p in $document//t:msIdentifier/t:altIdentifier/t:idno
                   return
                   if ( $altId/@type='TM') 
                   then 
                   <a href="https://www.trismegistos.org/text/{$altId/text()}" property="http://www.cidoc-crm.org/cidoc-crm/P1_is_identified_by" 
                    content="{$altId}">TM{$altId/text()}{if($altId[$p = count($document//t:msIdentifier/t:altIdentifier/t:idno/text())]) then ' ' else ', '}</a>
                   else 
                     <span property="http://www.cidoc-crm.org/cidoc-crm/P1_is_identified_by" 
                    content="{$altId/text()}">{$altId/text()}{if($altId[$p = count($document//t:msIdentifier/t:altIdentifier/t:idno/text())]) then ' ' else ', '}</span>
            }
            </p>
            else
            ()
            }
            </div>
            case 'persons' return if(starts-with($document//t:person/@sameAs, 'wd:')) then wiki:wikitable(substring-after($document//t:person/@sameAs, 'wd:')) else (string($document//t:person/@sameAs))

            case 'works' return
            app:clavisIds(root($document))
            
 case 'institutions' return

                            <div class="w3-row">
                            <a href="/institutions/" role="label" class="w3-tag w3-red">Institution</a>

{                            if($document//t:place/@type)
   then

    let $type := data($document//t:place/@type)
    let $list := if(contains($type, ' ')) then tokenize(normalize-space($type), ' ') else string($type)
    return
     <div>{for $t in $list return <a class="w3-tag w3-red" href="/places/list?placetype={$t}" target="_blank">{$t}</a>}</div>
   else ()}</div>


 case 'places' return

   (if($document//t:place/@type)
   then

    let $type := data($document//t:place/@type)
    let $list := if(contains($type, ' ')) then tokenize(normalize-space($type), ' ') else string($type)
    return
     <div  class="w3-row">{for $t in $list return <a class="w3-tag w3-red" href="/places/list?placetype={$t}" target="_blank">{$t}</a>}</div>
   else (),
    <a target="_blank" 
            href="/manuscripts/place/list?place={$id}" 
            role="button"
            class="w3-tag w3-gray w3-large 
            w3-margin-top">
                  Manuscripts in {titles:printTitleID($id) }</a>
)
 case 'persons' return
 if($document//t:personGrp) then
                         <div  class="w3-row">   <span class="w3-tag w3-red">
                            {if ($document//t:personGrp[@role = 'ethnic']) then 'Ethnic/Linguistic' else ()}
                            Group</span></div> else ()
 case 'work' return
  if ($document//t:titleStmt/t:author) then <div  class="w3-row"><p class="w3-large"><a href="{$document//t:titleStmt/t:author[1]/@ref}">{$document//t:titleStmt/t:author[1]}</a></p></div> else ()
   default return ()
   }


    </div>

</div>


</div>

};

(:~for place like items returns a row for a table with the values of the element :)
declare function item2:AdminLocTable($adminLoc as element()*){
                                           for $s in $adminLoc
                                           return
                                           <tr>
                                           <td>{if($s/@type) then titles:printTitleMainID($s/@type/data()) else $s/name()}</td>
                                           <td>{
                                           if($s/@ref) then
                                           (<a target="_blank" href="/{$s/@ref}">{titles:printTitleMainID($s/@ref)}</a>,
                                           <a xmlns="http://www.w3.org/1999/xhtml"
                                           id="{generate-id($s)}Ent{$s/@ref}relations"> <i class="fa fa-hand-o-left"/>
                                           </a>)
                                           else  $s/text()
                                           }</td>
                                           </tr>

                                           };
                                           
                                           
(:~called by item2:restNav, makes the boxes where the main relations are dispalied:)
declare function item2:mainRels($this,$collection){
      let $document := $this
      let $id := string($this/@xml:id)
      let $w := $config:collection-rootW
      let $n := $config:collection-rootN
      let $ms := $config:collection-rootMS
      let $plin := $config:collection-rootPlIn
      return
          <div class="allMainRel">{
     switch($collection)
     case 'persons' return (
     let $isSubjectof :=
            for $corr in $w//t:relation[@passive = $id][@name = 'ecrm:P129_is_about']

            return
                $corr
      let $isAuthorof :=
            for $corr in ($w//t:relation[@passive = $id][@name = 'saws:isAttributedToAuthor'],
            $w//t:relation[@passive = $id][@name = 'dcterms:creator'])

            return
                $corr
                  let $predecessorSuccessor :=
            for $corr in ($this//t:relation[@active = $id][@name = 'betmas:isSuccessorOf'], $this//t:relation[@active = $id][@name = 'betmas:isPredecessorOf'])

            return
                $corr
return
<div class="mainrelations w3-container">


                                            {

                   if ($isSubjectof) then  <div  class="relBox  w3-panel w3-card-4 w3-gray"><b class="openInDialog">This person is subject of the following <span class="w3-tag">{count($isSubjectof)}</span> textual units</b>
                        <ul  class="w3-ul w3-hoverable">{
                        for $p in $isSubjectof
                    return
                        if (contains($p/@active, ' ')) then for $value in tokenize ($p/@active, ' ') return
                        <li class="nodot"><a href="{$value}">{titles:printTitleID(string($value))}</a></li>
                        else
                        <li  class="nodot"><a href="{$p/@active}">{titles:printTitleID(string($p/@active))}</a></li>
                        }</ul></div> else ()

                }
                {

                   if ($isAuthorof) then  <div  class="relBox  w3-panel w3-card-4 w3-gray"><b  class="openInDialog">This person is author or attributed author of the following <span class="w3-tag">{count($isAuthorof)}</span> textual units</b>
                        <ul  class="w3-ul w3-hoverable">{
                        for $p in $isAuthorof
                    return
                        if (contains($p/@active, ' ')) then for $value in tokenize ($p/@active, ' ') return
                        <li  class="nodot"><a href="{$value}">{titles:printTitleID(string($value))}</a></li>
                        else
                        <li  class="nodot"><a href="{$p/@active}">{titles:printTitleID(string($p/@active))}</a></li>
                        }</ul></div> else ()

                }
{

                   if ($predecessorSuccessor) then  <div  class="relBox  w3-panel w3-card-4 w3-gray">
                   <b class="openInDialog">Successors and predecessors</b>
                        <ul  class="w3-ul w3-hoverable">{
                        for $p in $predecessorSuccessor
                        let $rel := if($p/@name = 'bm:isSuccessorOf') then 'Predecessor: ' else 'Successor: '
                    return
                        if (contains($p/@passive, ' ')) then for $value in tokenize ($p/@passive, ' ') return
                        <li  class="nodot">{$rel}<a href="{$value}">{titles:printTitleID(string($value))}</a></li>
                        else
                        <li  class="nodot">{$rel}<a href="{$p/@passive}">{titles:printTitleID(string($p/@passive))}</a></li>
                        }</ul></div> else ()

                }
             </div>
      )
       case 'places' return (
     let $isSubjectof :=  for $corr in $w//t:relation[@passive = $id][@name = 'ecrm:P129_is_about'] return $corr
     let $churchesAndMonasteries :=  for $corr in $plin//t:place[contains(@type, 'church') or contains(@type, 'monastery')][t:*[@ref = $id]] return $corr
return
<div  class="mainrelations w3-container">

                                          { if ($this//t:settlement or $this//t:region or $this//t:country) then  
                                          <div  class="relBox  w3-panel w3-card-4 w3-gray">
                                           {
                                           <b  class="openInDialog">Administrative position</b>,
                                           <table class="w3-table w3-hoverable adminpos">
                                           <tbody>
                                           {
                                          item2:AdminLocTable($this//t:country), 
                                          item2:AdminLocTable($this//t:region),
                                          item2:AdminLocTable($this//t:settlement),
                                          if($this//t:location/t:geo) then <tr><td>Coordinates</td><td>{$this//t:location/t:geo/text()}</td></tr> else (),
                                          if($this//t:location/t:height) then <tr><td>Altitude</td><td>{concat($this//t:location/t:height/text(), $this//t:location/t:height/@unit)}</td></tr>  else (),
                                         
                                          if($this//t:location[@typ='relative']) then
                                          <tr><td>Relative location</td><td>{$this//t:location[@typ='relative']/text()}</td></tr> else ()

                                           }
                                           </tbody>
                                           </table>
                                           }
                                           </div>
                                           else()
                                            }
                                            { if ($this//t:state) then  <div  class="relBox  w3-panel w3-card-4 w3-gray">
                                           {
                                           <b  class="openInDialog">Place attested in the following periods</b>,
                                          <ul  class="w3-ul w3-hoverable">{for $s in $this//t:state[@type='existence']/@ref
                                          let $file := $config:collection-rootA/id($s)
                                          let $name := $file//t:title[1]/text()
                                          let $link := $file//t:sourceDesc//t:ref/@target
                                          return
                                          <li  class="nodot"><a href="{$link}">
                                          {$name}
                                          </a> (<a href='/authority-files/list?keyword={$s}'>See all items for this period</a>)</li>
                                          }</ul>
                                           }
                                           </div>
                                           else()
                                            }
                                            {
                     if ($isSubjectof) then
                     <div  class="relBox  w3-panel w3-card-4 w3-gray"><b  class="openInDialog">This place is subject of the following <span class="w3-tag">{count($isSubjectof)}</span> textual units</b>
                        <ul  class="w3-ul w3-hoverable">{
                        for $p in $isSubjectof
                    return
                        if (contains($p/@active, ' ')) then for $value in tokenize ($p/@active, ' ') return
                        <li  class="nodot"><a href="{$value}" >{titles:printTitleID(string($value))}</a></li>
                        else
                        <li  class="nodot"><a href="{$p/@active}">{titles:printTitleID(string($p/@active))}</a></li>
                        }</ul></div> else ()

                }
                {if($churchesAndMonasteries) then (
                <div  class="relBox  w3-panel w3-card-4 w3-gray"><b  class="openInDialog">{count($churchesAndMonasteries)} churches and monasteries can be found in this place</b>
                        <ul  class="w3-ul w3-hoverable">{
                        for $p in $churchesAndMonasteries
                        let $root := string(root($p)/t:TEI/@xml:id)
                    return
                        <li  class="nodot"><a href="{$root}">{titles:printTitleID($root)}</a></li>
                        }</ul></div>
                ) else ()
                }


             </div>
      )
     case 'works' return (
     let $relations := ($w//t:relation[@active = $id],
     $w//t:relation[@passive = $id])
     let $relatedWorks :=
            for $corr in $relations[@name  != 'saws:isAttributedToAuthor'][@name != 'dcterms:creator']

            return
                if ($corr[ancestor::t:TEI[@xml:id [. = $id]]]) then () else $corr
let $relations := $document//t:relation[@name [. != 'saws:isAttributedToAuthor'][. != 'dcterms:creator']]
return
if(empty($relatedWorks) and not($document//t:relation)) then ()
else
<div  class="mainrelations w3-container">


                                            {
                    for $par in $relations
                    let $relname := string(($par/@name)[1])
                    group by $rn := $relname
                    return
                      <div  class="relBox  w3-panel w3-card-4 w3-gray"> {(

                       switch($rn)
                        case 'saws:contains' return <b  class="openInDialog">The following <span class="w3-tag">{count($par)}</span> parts of this textual unit are also independent textual units ({$rn})</b>
                        case 'ecrm:P129_is_about' return <b  class="openInDialog">The following <span class="w3-tag">{count($par)}</span> subjects are treated in this textual unit  ({$rn})</b>
                       case 'saws:isVersionInAnotherLanguageOf' return <b  class="openInDialog">The following <span class="w3-tag">{count($par)}</span> textual units are versions in other languages of this ({$rn})</b>
                         case 'saws:formsPartOf' return <b  class="openInDialog">This textual unit is included in the following <span class="w3-tag">{count($par)}</span> textual units ({$rn})</b>
                        case 'saws:isDifferentTo' return <b  class="openInDialog">This textual unit is marked as different from the following <span class="w3-tag">{count($par)}</span> ({$rn})</b>
                       default return <b  class="openInDialog">The following <span class="w3-tag">{count($par)}</span> textual units have a relation {$rn} with this textual unit</b>,

                      <ul  class="w3-ul w3-hoverable">{for $p in $par/@passive
                        let $normp := normalize-space($p)
                        return
                        if (contains($normp, ' ')) then
                        for $value in tokenize ($normp, ' ') return
                        if(starts-with($value,'http')) then 
                        <li class="nodot"><a href="{$value}">{$value}</a></li>
                        else <li class="nodot"><a href="{$value}" class="MainTitle" data-value="{$value}">{$value}</a></li>
                        else
                         if(starts-with($p,'http')) then 
                        <li class="nodot"><a href="{$p}">{$p}</a></li>
                        else
                        <li class="nodot"><a href="{$p}"  class="MainTitle" data-value="{$p}">{$p}</a></li>
                        }</ul>)

                }</div>}

                {
                    for $par in $relatedWorks
                    let $relname := string(($par/@name)[1])
                    group by $rn := $relname
                    return
                     <div  class="relBox  w3-panel w3-card-4 w3-gray">
                     {( switch($rn)
                        case 'saws:isVersionOf' return <b  class="openInDialog">The following <span class="w3-tag">{count($par)}</span> textual units are versions of this ({$rn})</b>
                        case 'saws:isVersionInAnotherLanguageOf' return <b  class="openInDialog">The following <span class="w3-tag">{count($par)}</span> textual units are versions in other languages of this ({$rn})</b>
                        case 'saws:isDifferentTo' return <b  class="openInDialog">This textual unit is marked as different from the following <span class="w3-tag">{count($par)}</span> ({$rn})</b>
                       default return <b  class="openInDialog">The following <span class="w3-tag">{count($par)}</span> textual units have a relation {$rn} with this work</b>,
                        <ul  class="w3-ul w3-hoverable">{for $p in $par
                        return
                        <li  class="nodot"><a href="{$p/@active}" class="MainTitle" data-value="{string($p/@active)}">{string($p/@active)}</a></li>
                        }</ul>)
                } </div>}



             </div>
      )
      
      case 'narratives' return (
   
let $relations := $document//t:relation[@name = 'skos:broadMatch']
return
if(not($document//t:relation)) then ()
else
<div  class="mainrelations w3-container">


                                            {
                    for $par in $relations
                    let $relname := string(($par/@name)[1])
                    group by $rn := $relname
                    return
                      <div  class="relBox  w3-panel w3-card-4 w3-gray"> {(

                       switch($rn)
                        case 'skos:broadMatch' return <b  class="openInDialog">Broadly matching entities</b>
                       default return <b  class="openInDialog">The following <span class="w3-tag">{count($par)}</span> textual units have a relation {$rn} with this textual unit</b>,

                      <ul  class="w3-ul w3-hoverable">{for $p in $par/@passive
                        let $normp := normalize-space($p)
                        return
                        if (contains($normp, ' ')) then
                        for $value in tokenize ($normp, ' ') return
                        if(starts-with($value,'http')) then 
                        <li class="nodot"><a href="{$value}">{$value}</a></li>
                        else <li class="nodot"><a href="{$value}" class="MainTitle" data-value="{$value}">{$value}</a></li>
                        else
                         if(starts-with($p,'http')) then 
                        <li class="nodot"><a href="{$p}">{$p}</a></li>
                        else
                        <li class="nodot"><a href="/{substring-after($p, 'betmas:')}"  class="MainTitle" data-value="{substring-after($p, 'betmas:')}">{substring-after($p, 'betmas:')}</a></li>
                        }</ul>)

                }</div>}


             </div>
      )
      
       case 'authority-files' return (
   let $pass := concat('betmas:', $id)
let $relations := $config:collection-rootN//t:relation[@name = 'skos:broadMatch'][@passive=$pass]
return
if(count($relations) eq 0) then ()
else
<div  class="mainrelations w3-container">


                                            {
                    for $par in $relations
                    let $relname := string(($par/@name)[1])
                    group by $rn := $relname
                    return
                      <div  class="relBox  w3-panel w3-card-4 w3-gray"> {(

                       switch($rn)
                        case 'skos:broadMatch' return <b  class="openInDialog">Broadly matching entities</b>
                       default return <b  class="openInDialog">The following <span class="w3-tag">{count($par)}</span> textual units have a relation {$rn} with this textual unit</b>,

                      <ul  class="w3-ul w3-hoverable">{for $p in $par/@active
                        let $normp := normalize-space($p)
                        return
                        if (contains($normp, ' ')) then
                        for $value in tokenize ($normp, ' ') return
                        if(starts-with($value,'http')) then 
                        <li class="nodot"><a href="{$value}">{$value}</a></li>
                        else <li class="nodot"><a href="{$value}" class="MainTitle" data-value="{$value}">{$value}</a></li>
                        else
                         if(starts-with($p,'http')) then 
                        <li class="nodot"><a href="{$p}">{$p}</a></li>
                        else
                        <li class="nodot"><a href="/{$p}"  class="MainTitle" data-value="{$p}">{$p}</a></li>
                        }</ul>)

                }</div>}


             </div>
      )

 case 'institutions' return (
 let $mssSameRepo :=
            for $corr in $ms//t:repository[ft:query(@ref, $id)]
             order by ft:score($corr) descending
            return
               $corr
return

<div class="mainrelations w3-container">
<div  class="relBox  w3-panel w3-card-4 w3-gray">
                                           {
                                           <b>Administrative position</b>,
                                           <table class="w3-table w3-hoverable adminpos">
                                           <tbody>
                                           {
                                          item2:AdminLocTable($this//t:country),
                                          item2:AdminLocTable($this//t:region),
                                          item2:AdminLocTable($this//t:settlement),
                                           if($this//t:location/t:geo) then <tr><td>Coordinates</td><td>{$this//t:location/t:geo/text()}</td></tr> else (),
                                          if($this//t:location/t:height) then <tr><td>Altitude</td><td>{concat($this//t:location/t:height/text(), $this//t:location/t:height/@unit)}</td></tr>  else (),
                                          if($this//t:location[@typ='relative']) then
                                          <tr><td>Relative location</td><td>{$this//t:location[@typ='relative']/text()}</td></tr> else ()

                                           }
                                           </tbody>
                                           </table>
                                           }
                                           </div>
             </div>
             )

 default return ()
     }</div>
      };


(:~returns the navigation bar with links to items and is called by the RESTXQ module items.xql :)
declare function item2:RestNav ($this, $collection, $type) {
let $document := $this
let $id := string($this/@xml:id)
return
<div class="w3-sidebar w3-bar-block w3-card w3-animate-left " id="sidebar" style="max-height:50vh;width:10%">
       <button type="button" class="w3-bar-item w3-button w3-hide-large" onclick="w3_closeItemSB()">
                    Close Item Navigation
                </button>
                {
            if($type = 'text') then  item2:witnesses($id) 
            else <div class="w3-container w3-col">
            <img id="loading" src="resources/Loading.gif" style="display: none; align: centre;" width="100%"></img>
            {transform:transform($document, 'xmldb:exist:///db/apps/BetMas/xslt/nav.xsl', ())}</div>
           }
</div>
};


(:~called by he RESTXQ module items.xql :)
declare function item2:RestPersRole($file, $collection){
   
    let $id := string($file/@xml:id)
    return
if ($collection = 'persons') then(
<div  class="w3-panel w3-margin  w3-gray w3-card-4">{
let $persrol := $config:collection-root//t:persName[@ref = $id]
let $persrole := $persrol[@role]
return
if($persrole) then
for $role in $persrole
             group by $r := $role/@role
            return
             <div>{<span class="MainTitle" data-value="{$id}"></span>} is <span class="w3-button w3-gray role" 
             onclick="document.getElementById('{$r}list').style.display='block'">{string($r)}</span><div>
                    <div id="{$r}list"  class="w3-modal fade">
                    
  <div class="w3-modal-content">
                        <button type="button" class="w3-button w3-red" onclick="document.getElementById('{$r}list').style.display='none'">Close</button>
                                    <header class="w3-container">
                                            <h4 class="w3-margin" id="{$r}listcount">There are other</h4>
                                    </header>
                                    <div class="w3-container">
                                            <ul id="{$r}listitems" class="w3-ul w3-hoverable"></ul>
                                    </div>
                                    </div>
             </div>
             </div>  of
             <ul class="w3-ul w3-hoverable">
            {for $root in $role/ancestor::t:TEI[@xml:id !=$id]
            let $thisid := string($root/@xml:id)
                   return
                   <li><a href="{$thisid}">{titles:printTitleID($thisid)}</a></li>}
                   </ul>
                   </div>
          else ('This person is mentioned nowhere with a specific role.')  }

</div>
           )

else if ($collection = 'manuscripts' or $collection = 'works' or $collection = 'narratives') then(
    let $notnull := $file//t:persName[@ref != 'PRS00000']
    let $pers := $notnull[@role]
    return
        for $p in $pers

        group by $ID := $p/@ref

 return
<div  class="w3-panel w3-margin w3-gray w3-card-4">
    <a href="{$ID}">{titles:printTitleID($ID)}</a>
    is <span class="w3-tag w3-red">{for $role in distinct-values($p/@role) return string($role) || ' '}</span>{' of this manuscript'}.

    {
    let $tei := $config:collection-root//t:TEI[@xml:id !=$id]
    let $persons := $tei//t:persName[@ref = string($ID)]
    for $role in $persons[@role]

    group by $r := $role/@role

            return

        <ul>and is also <span class="w3-red w3-tag role" onclick="document.getElementById('{$r}list').style.display='block'">{string($r)}</span><div>
                    <div id="{$r}list"  class="w3-modal " >
                    
  <div class="w3-modal-content">
                        <button type="button" class="w3-button w3-red" onclick="document.getElementById('{$r}list').style.display='none'">Close</button>
                     
                        <header>
                                            <h4 class="w3-margin" id="{$r}listcount">There are other</h4>
                                            </header>
                                            
                                    <div class="w3-container">
                                            <ul id="{$r}listitems" class="w3-ul w3-hoverable"></ul>
                                    </div>
                                    </div>
             </div>
             </div> of :

                {
                for $root in $role/ancestor::t:TEI[@xml:id !=$id]
                   return
                   <li><a href="{string($root/@xml:id)}">{titles:printTitleID(string($root/@xml:id))}</a></li>

                }

        </ul>
    }

</div>

)

else ()
           };


(:~ returns a div with a list of additions containing the given id :)
declare function item2:RestAdditions($id){
       let $adds := $config:collection-rootMS//t:additions
       let $sameKey :=
            for $corr in $adds//t:persName[@ref= $id]
            return $corr
return
if ($sameKey) then
<div class="w3-panel w3-card-4 w3-margin w3-gray" id="InAdditions">
   <h4 class="modal-title">{count($sameKey)} Addition{if(count($sameKey) gt 1) then 's' else ()} name{if(count($sameKey) gt 1) then () else 's'} person <span class="MainTitle" data-value="{$id}">{$id}</span> </h4>
                       <div id="InAdditions{$id}">
                                           <ul>{
                                                apprest:referencesList($id, $sameKey, 'name')
                                             }
                                             </ul>
                                    </div>

                                </div>
                                else ()
       };

      (:~ returns a div with a list of additions containing the given id :)
declare function item2:RestMiniatures($id){
       let $adds := $config:collection-root//t:decoNote[@type='miniature']
       let $sameKey :=
            for $corr in $adds//t:persName[@ref= $id]
            return $corr
return
if ($sameKey) then
<div class="w3-panel w3-card-4 w3-margin w3-gray" id="InMiniatures">
   <h4 class="modal-title">{count($sameKey)} Miniature{if(count($sameKey) gt 1) then 's' else ()} name{if(count($sameKey) gt 1) then () else 's'} person <span class="MainTitle" data-value="{$id}">{$id}</span> </h4>
                       <div id="InMiniatures{$id}">
                                           <ul class="w3-ul w3-hoverable">{
                                                apprest:referencesList($id, $sameKey, 'name')
                                             }
                                             </ul>
                                    </div>

                                </div>
                                else ()
       };

      (:~ returns a div with a list of the keywords used in the description of a miniture with the given art theme :)
declare function item2:RestMiniaturesKeys($id){
       let $adds := $config:collection-rootMS//t:decoNote[@type='miniature'][descendant::t:ref[@type='authFile'][@corresp=$id]]
       let $themes := $adds//t:term
     return
                                           <ul  class="w3-ul w3-hoverable">{
                                           for $t in $themes
                                           let $key := string($t/@key)
                                           group by $K := $key
                                           return

                                           <li class="nodot"><a target="_blank" role="button" class="btn btn-success btn-sm" href="/authority-files/list?keyword={$K}">{titles:printTitleMainID($K)}</a>
                                               in
                                               <ul>
                                               {for $th in $t
                                               let $container := root($th)/t:TEI
                                               let $containerID := string($container/@xml:id)
                                               return
                                               <li><a target="_blank" href="/{$containerID}">{titles:printTitleMainID($containerID)}</a></li>
                                               }</ul>

                                               </li>
                                             }
                                             </ul>
       };
      (:~ returns a div with a list of place like records containing the given id as tabot :)
declare function item2:RestTabot($id){
       let $tabot := $config:collection-rootPlIn//t:place//t:ab[@type='tabot']
       let $sameKey :=
            for $corr in $tabot//t:persName[@ref = $id]
            return $corr

return
if ($sameKey) then
<div class="w3-panel w3-card-4 w3-margin w3-gray" id="tabots">
   <h4 class="modal-title">{count($sameKey)} place record{if(count($sameKey) gt 1) then 's' else ()} name{if(count($sameKey) gt 1) then () else 's'} person <span class="MainTitle" data-value="{$id}">{$id}</span> as a tabot</h4>

                       <div id="Tabot{$id}">
                                           <ul  class="w3-ul w3-hoverable">{
                                                apprest:referencesList($id, $sameKey, 'name')
                                             }
                                             </ul>
                                    </div>

                                </div>
else ()
       };



       (:~ returns a div with a list of manuscripts containing the work with the given id :)
declare function item2:RestMss($id){
       let $string := $id
let $sameKey :=
            for $corr in $config:collection-rootMS//t:title[starts-with(@ref , $id)][parent::t:msItem]
            return
                $corr
  let $sameKeyAdd :=
            for $corr in               $config:collection-rootMS//t:additions//t:item//t:title[starts-with(@ref , $id)]
            return
                $corr
   let $count := count($sameKey) + count($sameKeyAdd)      
   let $distinctMssIds := for $s in ($sameKey, $sameKeyAdd) return string($s/ancestor::t:TEI/@xml:id)
   let $countDistMss := count(distinct-values($distinctMssIds))
return

   <div class="w3-panel w3-margin w3-red w3-card-4" id="computedWitnesses">
   <h4  class="openInDialog">This unit, or parts of it, is contained in {$countDistMss} manuscript records {$count} time{if($count gt 1) then 's' else ()}</h4>
<p><a target="_blank" href="/manuscripts/list?contents={$id}">See these {$countDistMss} manuscripts in the list view.</a> Scrolling in this box will also show you a summary of all the occurences.</p>
    <div id="Samekeyword{$string}"  >
    {if(count($sameKey) gt 0) then
(<p>As main content</p>,

                                            <ul class="nodot w3-padding">{
                                                for $hit in  $sameKey
                                                let $item := root($hit)
                                              let $root := $item/t:TEI/@xml:id
                                              let $itemid := string($root)
                                                group by $groupkey := $root
                                                 let $tit := titles:printTitleID($groupkey)
                                                 order by $tit[1]

                                               (: inside the list then :)
(:                                                         order by root($hit)/t:TEI/@xml:id:)
                                                    return

                                                          <li class="w3-bar w3-card-2 list-group">
                                                        {  if ($item//t:facsimile/t:graphic/@url) then 
                                                        <a class="w3-bar-item" target="_blank" href="{$item//t:facsimile/t:graphic/@url}">Link to images</a> 
                                                        else if($item//t:msIdentifier/t:idno/@facs) then 
                 <a class="w3-bar-item w3-circle" target="_blank" href="/manuscripts/{$itemid}/viewer">{
                if($item//t:collection = 'Ethio-SPaRe') 
               then <img src="{$config:appUrl ||'/iiif/' || string($item//t:msIdentifier/t:idno/@facs) || '_001.tif/full/140,/0/default.jpg'}" class="thumb w3-image"/>
(:laurenziana:)
else  if($item//t:repository/@ref[.='INS0339BML']) 
               then <img src="{$config:appUrl ||'/iiif/' || string($item//t:msIdentifier/t:idno/@facs) || '005.tif/full/140,/0/default.jpg'}" class="thumb w3-image"/>
          
(:          
EMIP:)
              else if($item//t:collection = 'EMIP' and $item//t:msIdentifier/t:idno/@n) 
               then <img src="{$config:appUrl ||'/iiif/' || string($item//t:msIdentifier/t:idno/@facs) || '001.tif/full/140,/0/default.jpg'}" class="thumb w3-image"/>
              
             (:BNF:)
            else if ($item//t:repository/@ref = 'INS0303BNF') 
            then <img src="{replace($item//t:msIdentifier/t:idno/@facs, 'ark:', 'iiif/ark:') || '/f1/full/140,/0/native.jpg'}" class="thumb w3-image"/>
(:           vatican :)
                else <img src="{replace(substring-before($item//t:msIdentifier/t:idno/@facs, '/manifest.json'), 'iiif', 'pub/digit') || '/thumb/'
                    ||
                    substring-before(substring-after($item//t:msIdentifier/t:idno/@facs, 'MSS_'), '/manifest.json') || 
                    '_0001.tif.jpg'
                }" class="thumb w3-image"/>
                 }</a>
                
                else ()}
                                                          <a class="w3-bar-item"
                                               href="/manuscripts/{$groupkey}/main">{$tit} ({string($groupkey)}) </a>
                                               
                                                      <div class="w3-bar-item">  <span class="WordCount w3-tag" data-msID="{$groupkey}" data-wID="{$string}"/>
                                                         
                                                         <ul class="w3-padding">{
                                                         for $h in $hit
                                                         let $msitem := $h/parent::t:msItem
                                                         let $placement := if ($h/preceding-sibling::t:locus) then ( ' ('|| (let $locs :=for $loc in $h/preceding-sibling::t:locus return string:tei2string($loc) return string-join($locs, ' ')) || ')') else ''
                                                         let $position := ' [' || count($msitem/preceding-sibling::t:msItem) +1 || '/' || count($msitem/parent::t:*/child::t:msItem) || ']'
                                                         return

<li>content item with id <b>{string($msitem/@xml:id)}</b> {if($h/text()) then (', ', <i>{$h/text()}</i> ) else () } {$placement} {$position}</li>
                                                         }
                                                         </ul>
</div> 
                                                            </li>
                                             }
                                             </ul>) else ()}
                                             {if(count($sameKeyAdd) gt 0) then
(<p>As additional content</p>,

                                            <ul class="nodot  w3-padding ">{
                                                for $hit in  $sameKeyAdd
                                              let $root := root($hit)/t:TEI/@xml:id
                                                group by $groupkey := $root
                                                 let $tit := titles:printTitleID($groupkey)
                                                 order by $tit[1]

                                               (: inside the list then :)
(:                                                         order by root($hit)/t:TEI/@xml:id:)
                                                    return

                                                          <li class="list-group">
                                                          <a
                                               href="/manuscripts/{$groupkey}/main">{$tit} ({string($groupkey)}) </a> <br/>
                                                         <span class="WordCount" data-msID="{$groupkey}" data-wID="{$string}"/>
                                                         <br/>
                                                         <ul class="w3-padding">{
                                                         for $h in $hit
                                                         let $item := $h/ancestor::t:item[1]
                                                         let $placement := if ($item/t:locus) then ( ' ('|| (let $locs :=for $loc in $item/t:locus return string:tei2string($loc) return string-join($locs, ' ')) || ')') else ''
                                                         let $position := ' [' || count($item/preceding-sibling::t:item) +1 || '/' || count($item/parent::t:*/child::t:item) || ']'
                                                         return

<li>addition with id <b>{string($item/@xml:id)}</b> {if($h/text()) then (', ', <i>{$h/text()}</i> ) else () } {$placement} {$position}</li>
                                                         }
                                                         </ul>

                                                            </li>
                                             }
                                             </ul>
                                           
                                             
                                             ) else ()}
                                             {  if(starts-with($id, 'NAR')) then (
                                             let $file := $config:collection-rootN//id($id)
                                             let $broadMatch := $file//t:relation[@name="skos:broadMatch"]/@passive
                                             for $b in $broadMatch
                                             let $broad := substring-after($b, 'betmas:')
                                             let $usedasType :=  $config:collection-rootMS//t:additions//t:item/t:desc[@type = $broad]
                                             return
  (<p>As additional content associated with the keyword <b><a href="/authority-files/list?keyword={string($broad)}">{titles:printTitleMainID($broad)}</a></b> this unit 
  is present an additional {count($usedasType)} time{if(count($usedasType) gt 1) then 's' else ()}</p>,       
                                             <ul class="nodot w3-padding ">{
                                                for $hit in  $usedasType
                                              let $root := root($hit)/t:TEI/@xml:id
                                                group by $groupkey := $root
                                                 let $tit := titles:printTitleID($groupkey)
                                                 order by $tit[1]

                                               (: inside the list then :)
(:                                                         order by root($hit)/t:TEI/@xml:id:)
                                                    return

                                                          <li class="list-group">
                                                          <a
                                               href="/manuscripts/{$groupkey}/main">{$tit} ({string($groupkey)}) </a> <br/>
                                                         <span class="WordCount" data-msID="{$groupkey}" data-wID="{$string}"/>
                                                         <br/>
                                                         <ul class="w3-padding ">{
                                                         for $h in $hit
                                                         let $item := $h/ancestor::t:item[1]
                                                         let $placement := if ($item/t:locus) then ( ' ('|| (let $locs :=for $loc in $item/t:locus return string:tei2string($loc) return string-join($locs, ' ')) || ')') else ''
                                                         let $position := ' [' || count($item/preceding-sibling::t:item) +1 || '/' || count($item/parent::t:*/child::t:item) || ']'
                                                         return

<li>addition with id <b>{string($item/@xml:id)}</b> {if($h/text()) then (', ', <i>{$h/text()}</i> ) else () } {$placement} {$position}</li>
                                                         }
                                                         </ul>

                                                            </li>
                                             }
                                             </ul>)
                                             )
                                             else ()}
                                    </div>


             {
let $corresps := $config:collection-rootW//t:div[@type ='textpart'][@corresp = $id]
return
if (count($corresps) ge 1) then
 (
for $c in $corresps
let $workid := string(root($c)/t:TEI/@xml:id )
let $witnesses := $config:collection-rootMS//t:title[contains(@ref, $workid)]
let $tit := titles:printTitleMainID($workid)
return
(
<p>This work is also part of <a target="_blank" href="/{$workid}">{$tit}</a>, which is contained in the following manuscripts:</p>,
<div><ul class=" w3-padding">{
for $wit in $witnesses
 let $wid :=  string(root($wit)/t:TEI/@xml:id )
 group by $id := $wid
 let $wtit :=  titles:printTitleMainID($id)
return
<li><a target="_blank" href="/{$id}">{$wtit}</a></li>
}</ul></div>
)
) else ()
}
     </div>
       };


(:~ returns a selector with values which can be searched. a javascript will pick the selected one and send it to the restxq to get related items :)
 declare function item2:RestSeeAlso ($this, $collection)  {
 let $file := $this
 let $id := string($this/@xml:id)
 let $classes := for $class in $this//t:term/@key return 'http://betamasaheft.eu/'||$class
 let $options := switch($collection)
(:                   decides on the basis of the collection what is relevant to match related records :)
                   case 'manuscripts' return
                   (if ($file//t:term/@key) then <optgroup label="keywords">{for $x in distinct-values($file//t:term/@key) return <option value="{$x}">{titles:printTitleID($x)}</option>}</optgroup> else (),
                   if ($file//t:supportDesc/t:material/@key) then <optgroup label="material">{for $x in ($file//t:supportDesc/t:material/@key) return <option value="{$x}">{$x}</option>}</optgroup> else (),
                   if ($file//t:handNote[@script]/@script) then <optgroup label="script">{for $x in distinct-values($file//t:handNote[@script]/@script) return <option value="{$x}">{string($x)}</option>}</optgroup> else (),
                   if ($file//t:objectDesc/@form) then <optgroup label="form">{for $x in distinct-values($file//t:objectDesc/@form) return <option value="{$x}">{string($x)}</option>}</optgroup> else ())
                   case 'works' return
                   (if ($file//t:term/@key) then <optgroup label="keywords">{for $x in distinct-values($file//t:term/@key) return <option value="{$x}">{titles:printTitleID($x)}</option>}</optgroup> else (),
                   if ($file//t:relation[@name='dcterms:creator']) then <optgroup label="author">{for $x in ($file//t:relation[@name='dcterms:creator']) let $auth := string($x/@passive) return <option value="{$auth}">{titles:printTitleID($auth)}</option>}</optgroup> else (),
                   if ($file//t:relation[@name='saws:isAttributedToAuthor']) then <optgroup label="relation">{for $x in ($file//t:relation[@name='saws:isAttributedToAuthor']) let $auth := string($x/@passive) return <option value="{$auth}">{titles:printTitleID($auth)}</option>}</optgroup> else ()
                   )
                    case 'narratives' return
                   (if ($file//t:term/@key) then <optgroup label="keywords">{for $x in distinct-values($file//t:term/@key) return <option value="{$x}">{titles:printTitleID($x)}</option>}</optgroup> else (),
                   if ($file//t:relation[@name='dcterms:creator']) then <optgroup label="author">{for $x in ($file//t:relation[@name='dcterms:creator']) let $auth := string($x/@passive) return <option value="{$auth}">{titles:printTitleID($auth)}</option>}</optgroup> else (),
                   if ($file//t:relation[@name='saws:isAttributedToAuthor']) then <optgroup label="attributed author">{for $x in ($file//t:relation[@name='saws:isAttributedToAuthor']) let $auth := string($x/@active) return <option value="{$auth}">{titles:printTitleID($auth)}</option>}</optgroup> else ()
                   )
                   case 'places' return
                   (if ($file//t:term/@key) then <optgroup label="keywords">{for $x in distinct-values($file//t:term/@key) return <option value="{$x}">{titles:printTitleID($x)}</option>}</optgroup> else (),
                    if ($file//t:settlement) then <optgroup label="settlement">{for $x in $file//t:settlement/@ref return <option value="{$x}">{titles:printTitleID($x)}</option>}</optgroup> else (),
                   if ($file//t:region) then <optgroup label="region">{for $x in $file//t:region/@ref return <option value="{$x}">{titles:printTitleID($x)}</option>}</optgroup> else (),
                   if ($file//t:country) then <optgroup label="country">{for $x in $file//t:country/@ref return <option value="{$x}">{titles:printTitleID($x)}</option>}</optgroup> else (),
                   if ($file//t:place[@type]) then <optgroup label="type">{if(contains($file//t:place/@type, ' ')) then for $x in tokenize($file//t:place/@type, ' ')  return <option value="{$x}">{titles:printTitleID($x)}</option> else let $type := $file//t:place/@type return <option value="{$type}">{titles:printTitleID($type)}</option>}</optgroup> else ()
                   )
                   case 'institutions' return
                   (if ($file//t:term/@key) then <optgroup label="keywords">{for $x in distinct-values($file//t:term/@key) return <option value="{$x}">{titles:printTitleID($x)}</option>}</optgroup> else (),
                    if ($file//t:settlement) then <optgroup label="settlement">{for $x in $file//t:settlement/@ref return <option value="{$x}">{titles:printTitleID($x)}</option>}</optgroup> else (),
                   if ($file//t:region) then <optgroup label="region">{for $x in $file//t:region/@ref return <option value="{$x}">{titles:printTitleID($x)}</option>}</optgroup> else (),
                   if ($file//t:country) then <optgroup label="country">{for $x in $file//t:country/@ref return <option value="{$x}">{titles:printTitleID($x)}</option>}</optgroup> else (),
                   if ($file//t:place[@type]) then <optgroup label="type">{if(contains($file//t:place/@type, ' ')) then for $x in ($file//t:place/@type)  return <option value="{$x}">{titles:printTitleID($x)}</option> else let $type := $file//t:place/@type return <option value="{$type}">{titles:printTitleID($type)}</option>}</optgroup> else ()
                   )
                   case 'persons' return
                   (if ($file//t:term/@key) then <optgroup label="keywords">{for $x in distinct-values($file//t:term/@key) return <option value="{$x}">{titles:printTitleID($x)}</option>}</optgroup> else (),
                  if ($file//t:roleName) then <optgroup label="role">{for $x in ($file//t:roleName/@type) return <option value="{$x}">{titles:printTitleID($x)}</option>}</optgroup> else (),
                   if ($file//t:faith) then <optgroup label="faith">{for $x in ($file//t:faith/@type) return <option value="{$x}">{titles:printTitleID($x)}</option>}</optgroup> else (),
                   if ($file//t:occupation) then <optgroup label="occupation">{for $x in ($file//t:occupation/@type) return <option value="{$x}">{titles:printTitleID($x)}</option>}</optgroup> else ()
                   )
                  default return (if ($file//t:term/@key) then <optgroup label="keywords">{for $x in distinct-values($file//t:term/@key) return <option value="{$x}">{titles:printTitleID($x)}</option>}</optgroup> else ()
                   )
 return
       <div class="{if(starts-with($id, 'INS')) then 'w3-container w3-padding' else 'w3-third w3-padding'}" id="seeAlsoForm" >

{if(count($options) ge 1) then(
       <p class="w3-large">Select one of the keywords listed from the record to see related data</p>,
       <span typeof="{string-join($classes, ' ')}"/>,
        <form action="" class="w3-container">
                <div class="w3-container w3-margin-bottom">
                    <select class="w3-select w3-border" name="seealso" id="seealsoSelector">
                    <option>select...</option>
                   {$options}
                   </select>
                    </div>
            
        </form>,
     <img id="loading" src="resources/Loading.gif" style="display: none;"></img>,
     <div id="SeeAlsoResults" class="w3-panel w3-margin w3-card-4 w3-gray">No keyword selected.</div>) else
     <div class="w3-panel w3-margin w3-card-4 w3-gray">No keywords associated with this item yet.</div>}
     {if($collection='works' or $collection='narratives') then item2:RestMss($id) else ()}
     {item2:mainRels($this, $collection)}
     <div class="w3-panel w3-margin w3-gray w3-card-4"><b>Hypothes.is public annotations pointing here</b>
     <div id="hypothesisFeedResults" data-value="{$id}"></div>
     <p>Use the tag <span class="w3-tag w3-red">BetMas:{$id}</span> in your public <a href="https://web.hypothes.is/">hypothes.is</a> annotations which refer to this entity.</p>
     </div>
     {if($collection = 'places' or $collection='institutions') then <div>
     <div class="w3-panel w3-margin w3-gray w3-card-4" id="pelagiosrelateditems" data-id="{$id}">
     {if($file//t:place/@sameAs) then attribute data-sameAs {string($file//t:place/@sameAs)} else ()}
     </div>
     <div class="w3-panel w3-margin w3-gray w3-card-4" id="Chojnacki" data-id="{$id}"/>
     <script type="text/javascript" src="resources/js/gnisci.js"/>
     <script type="text/javascript" src="resources/js/pelagios.js"/></div> else ()}
     {if($collection='authority-files' and $file//t:relation[starts-with(@passive,'ic')]) 
     then <div class="w3-panel w3-margin w3-gray w3-card-4" id="EuropeanaMatches">
     {for $iconclass in $file//t:relation[starts-with(@passive,'ic')] 
     let $icID := substring-after($iconclass/@passive, 'ic:')
     let $europeanalink := ('http://sparql.europeana.eu/?default-graph-uri=http%3A%2F%2Fdata.europeana.eu%2F&amp;query=SELECT+%3FProvidedCHO%0D%0AWHERE+%7B%0D%0A++%3FProxy+%3Fproperty+%3Chttp%3A%2F%2Ficonclass.org%2F'|| 
                                           $icID   ||'%3E+%3B%0D%0A+++++++++ore%3AproxyIn+%3FAggregation+.+%0D%0A++%3FAggregation+edm%3AaggregatedCHO+%3FProvidedCHO%0D%0A%7D&amp;format=text%2Fhtml&amp;timeout=0&amp;debug=on')
     return
     <div data-value="{string($iconclass/@passive)}">
   Items  linked to <a href="http://iconclass.org/{$icID}">Iconclass concept {$icID}</a>:
   <ul><li><a href="{$europeanalink}">Click to see items in Europeana</a></li>
   <li><a href="https://corpusvitrearum.de/id/{$icID}/about.html">Click to see items in Corpus Vitrearum Medii Aevi </a></li>
   </ul>
     
     <script type="application/javascript" src="resources/js/europeanaSparql.js"/>
     </div>
     }
     
     </div> else ()}
   </div>

      };

(:~ depending on the type of item sends to the correct XSLT producing the main content of the page :)
declare function item2:RestItem($this, $collection) {
let $document := $this
let $id := string($document/t:TEI/@xml:id)
return
let $xslt :=  switch($collection)
        case "manuscripts"  return       'xmldb:exist:///db/apps/BetMas/xslt/mss.xsl'
        case "places"  return       'xmldb:exist:///db/apps/BetMas/xslt/placeInstit.xsl'
        case "institutions"  return       'xmldb:exist:///db/apps/BetMas/xslt/placeInstit.xsl'
        case "persons"  return       'xmldb:exist:///db/apps/BetMas/xslt/Person.xsl'
        case "works"  return       'xmldb:exist:///db/apps/BetMas/xslt/Work.xsl'
        case "narratives"  return       'xmldb:exist:///db/apps/BetMas/xslt/Work.xsl'
        (:THE FOLLOWING TWO ARE TEMPORARY PLACEHOLDERS:)
        case "authority-files"  return       'xmldb:exist:///db/apps/BetMas/xslt/auth.xsl'
        default return 'xmldb:exist:///db/apps/BetMas/xslt/Work.xsl'

let $parameters : = if ($collection = 'manuscripts') then <parameters>
    <param name="porterified" value="."/>
    <param name="folio" value="1"/>
    <param name="currentpos" value="1"/>
    <param name="rend" value="."/>
    <param name="from" value="."/>
    <param name="to" value="."/>
    <param name="prec" value="."/>
    <param name="count" value="."/>
    <param name="singletons" value="."/>
    <param name="step1ed" value="."/>
    <param name="step2ed" value="."/>
    <param name="step3ed" value="."/>
    <param name="Finalvisualization" value="."/>
</parameters> else ()

return
(:because nav takes 2 colums:)

    <div class="w3-container " resource="http://betamasaheft.eu/{$id}" >
{transform:transform($document,$xslt,$parameters)}
    {item2:RestSeeAlso($this, $collection)}
    </div>



};


(:~ sends to the correct XSLT producing the main content of the page for text view:)
declare  function item2:RestText($this,
$start as xs:integer*,
$per-page as xs:integer*) {
let $document := $this
let $parameters := map{}
let $xslt :=   'xmldb:exist:///db/apps/BetMas/xslt/text.xsl'
        let $xslpars := <parameters>
    <param name="startsection" value="{$start}"/>
    <param name="perpage" value="{$per-page}"/>
</parameters>

return
if(count($document//t:div[@type='edition']) gt 1) then
let $matches := for $hit in $document//t:div[@type='edition'][1]/t:div[@type='textpart']
                            return $hit
let $hits :=        map { 'hits' := $matches, 'type' := 'text'}
return
   <div class="w3-container">
     {if(count($hits) gt 1) then <div class="w3-left w3-row" >
    {apprest:paginate-rest($hits, $parameters, $start, $per-page, 1, 21)}
    </div> else ()}
    <div class="w3-row w3-margin-top" >
                   {
    transform:transform(
        $document,
       $xslt,
$xslpars)}
</div>
    </div>
    else
if($document//t:div[@type='textpart']) then
let $matches := for $hit in $document//t:div[@type='textpart']
                            return $hit
let $hits :=        map { 'hits' := $matches, 'type' := 'text'}
let $count := count($matches)
return
   <div class="w3-container">
   
{if($per-page = $count) then () else
<div class="w3-container w3-twothird">
   <div class="w3-left">
    {apprest:paginate-rest($hits, $parameters, $start, $per-page, 1, 10)}
    </div>
    </div>
    }
                   {
    transform:transform(
        $document,
       $xslt,
$xslpars)}
    </div>
    else if($document//t:div[@type='edition'][t:ab]) then
   
   <div class="w3-container">{ transform:transform(
        $document,
       $xslt,
$xslpars)}
</div>
    else if($document//t:relation[@name="saws:contains"])
    then
    let $ids := for $contains in $document//t:relation[@name="saws:contains"]/@passive 
                         return 
                       if(contains($contains, ' ')) then for $x in tokenize($contains, ' ') return $x else string($contains)
return
    <div class="w3-container">

    { for $contained in $ids

    let $file := $config:collection-rootW//id($contained)[name()='TEI']
     let $matches := for $hit in $file//t:div[@type='textpart'] return $hit
    let $hits :=        map { 'hits' := $matches, 'type' := 'text'}

let $xsltlocalparameters  :=  <parameters>
    <param name="startsection" value="{$start}"/>
    <param name="perpage" value="{$per-page}"/>
</parameters>
    return
     <div class="w3-container">
     <h1><a target="_blank" href="/works/{$contained}/text">{titles:printTitleID($contained)}</a></h1>
     <div class="w3-left">
    {apprest:paginate-rest($hits, $parameters, $start, $per-page, 1, 21)}
    </div>
    {transform:transform(
        $file,
       $xslt,
$xslpars)}

     </div>
    }


    <div>

    </div>

    </div>
    else ()



};
