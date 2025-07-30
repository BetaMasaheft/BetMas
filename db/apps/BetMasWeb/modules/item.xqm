xquery version "3.0" encoding "UTF-8"; 
(:~
 : module used by items.xql for several parts of the view produced
 :
 : @author Pietro Liuzzo
 :)
module namespace item2="https://www.betamasaheft.uni-hamburg.de/BetMasWeb/item2";
import module namespace config="https://www.betamasaheft.uni-hamburg.de/BetMasWeb/config" at "xmldb:exist:///db/apps/BetMasWeb/modules/config.xqm";
import module namespace string = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/string" at "xmldb:exist:///db/apps/BetMasWeb/modules/tei2string.xqm";
import module namespace apprest = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/apprest" at "xmldb:exist:///db/apps/BetMasWeb/modules/apprest.xqm";
import module namespace editors="https://www.betamasaheft.uni-hamburg.de/BetMasWeb/editors" at "xmldb:exist:///db/apps/BetMasWeb/modules/editors.xqm";
import module namespace wiki="https://www.betamasaheft.uni-hamburg.de/BetMasWeb/wiki" at "xmldb:exist:///db/apps/BetMasWeb/modules/wikitable.xqm";
import module namespace exptit="https://www.betamasaheft.uni-hamburg.de/BetMasWeb/exptit" at "xmldb:exist:///db/apps/BetMasWeb/modules/exptit.xqm";
import module namespace apptable="https://www.betamasaheft.uni-hamburg.de/BetMasWeb/apptable" at "xmldb:exist:///db/apps/BetMasWeb/modules/apptable.xqm";
import module namespace viewItem = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/viewItem" at "xmldb:exist:///db/apps/BetMasWeb/modules/viewItem.xqm";
import module namespace tl="https://www.betamasaheft.uni-hamburg.de/BetMasWeb/timeline"at "xmldb:exist:///db/apps/BetMasWeb/modules/timeline.xqm";
import module namespace xdb="http://exist-db.org/xquery/xmldb";
import module namespace locus = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/locus" at "xmldb:exist:///db/apps/BetMasWeb/modules/locus.xqm";
declare namespace test="http://exist-db.org/xquery/xqsuite";
declare namespace s = "http://www.w3.org/2005/xpath-functions";
declare namespace t="http://www.tei-c.org/ns/1.0";

declare function item2:authorsSHA($id, $this, $collection, $sha){
apprest:authorsSHA($id, $this, $collection, $sha)
};

declare function item2:printTitle($id){exptit:printTitle($id)};

declare function item2:getTEIbyID($id){
$apprest:collection-root/id($id)[self::t:TEI]
};

declare function item2:formerly($id){
$apprest:collection-root//t:relation[@name eq 'betmas:formerlyAlsoListedAs'][@passive eq $id]
};
declare function item2:rels($id){
$apprest:collection-rootMS//t:relation[contains(@passive, $id)]
};

declare function item2:namedentitiescorresps($this, $collection){
apprest:namedentitiescorresps($this, $collection)
};
declare function item2:EntityRelsTable($this, $collection) {
apprest:EntityRelsTable($this, $collection)
};
declare function item2:authors($this, $collection){
apprest:authors($this, $collection)
};
declare function item2:bottom($this, $collection){
apprest:bottom($this, $collection)
};
declare function item2:persList($item){
(:expects a manuscript item:)
let $id := $item/@xml:id
let $persons := $item//t:persName[@role]
return
if (count($persons) le 0) then <p>No persons related to this manuscripts are known.</p> else

<ul class=" w3-ul w3-hoverable">
{
for $pers in $item//t:persName[@role] return
<li class="nodot">
<a href="{$pers/@ref}" target="_blank">{string($pers/@role)}: {$pers/text()}</a>
</li>}
</ul>
};

declare function item2:witList($item){
(:expects a work item:)
<ul class=" w3-ul w3-hoverable">
{
for $wit in $item//t:witness[not(@type)] return
<li class="nodot" id="{string($wit/@xml:id)}">
<a href="{$wit/@corresp}" target="_blank">{if($wit/@xml:id) then (<b class="lead">{string($wit/@xml:id)}</b>,':') else ()} {$wit/t:idno/text(), ', ' ,$wit/t:title/text()}</a></li>}
{
for $wit in $item//t:witness[@type eq 'external'] return
<li class="nodot" id="{string($wit/@xml:id)}">
<a href="{$wit/@facs}" target="_blank">{if($wit/@xml:id) then (<b class="lead">{string($wit/@xml:id)}</b>,':') else ()}  {if($wit/text()) then $wit/text() else string($wit/@corresp)}</a></li>}

</ul>
};
(:~ used by item2:restNav:)
declare function item2:witnesses($id){
let $item := ($apprest:collection-rootMS, $apprest:collection-rootW)//t:TEI/id($id)
return
if($item/@type eq 'mss') then
<div class="w3-bar-item" id="textWitnesses">
<h5>Transcription of the manuscript</h5>
</div>
else
(<div class="w3-bar-item" id="textWitnesses">
<h5>Witnesses of the edition</h5>
</div>,
item2:witList($item)
       ,
       let $versions := $exptit:col//t:relation[@name eq 'saws:isVersionOf'][contains(@passive, $id)]
       return
       if($versions) then (<h5 class="w3-bar-item">Other versions</h5>,
         <ul  class="w3-bar-item nodot">
                {
                    for $parallel in $versions
                    let $p := $parallel/@active
                    return
                        <li><a
                                href="{$p}" >{exptit:printTitle($p)}</a></li>
                }
            </ul>)
            else()
            ,

            let $versionsO := $exptit:col//t:relation[@name eq 'isVersionInAnotherLanguageOf'][contains(@passive, $id)]
       return
       if($versionsO) then (
            <h5 class="w3-bar-item">Versions in another language</h5>,
            <ul  class=" w3-bar-item nodot">
                {
                    for $parallel in $versionsO
                     let $p := $parallel/@active
                    return
                        <li><a
                                href="{$p}" >{exptit:printTitle($p)}</a></li>
                }
            </ul>)
            else(),

            <a class="w3-bar-item w3-button w3-red" href="{$config:appUrl}/compare?workid={$id}" target="_blank">Compare</a>
)
};

(:~ under the main navigation bar there are the view options, this function returns the available values deciding on the type of input:)
declare function item2:RestViewOptions($this, $collection) {
let $document := $this
let $id := string($this/@xml:id)
return
<div xmlns="http://www.w3.org/1999/xhtml" class="w3-bar w3-small w3-padding w3-margin-top" id="options">

<!--
 <div class="w3-bar-item" >
 <a class="w3-button w3-padding-small w3-gray" href="javascript:void(0);" onclick="startIntroItem();">Explore this page</a>
 </div>-->
 <!--
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
 </div> -->
 <div class="w3-bar-item w3-tooltip" >
           <a class="w3-button w3-padding-small w3-gray"  id="mainEntryLink" href="{$config:appUrl}/{$collection}/{$id}/main">Main view</a>
<span class="w3-text w3-tag itemoptiontooltip">Main view</span>
 </div>
<div class="w3-bar-item  w3-tooltip">

<a target="_blank" class="w3-button w3-padding-small w3-gray" 
    href="https://github.com/BetaMasaheft/{replace(replace(base-uri($this), '/db/apps/expanded/', ''), 
    $collection, concat($collection, '/blob/master'))}"><i class="fa fa-pencil-square-o"></i></a>
    <span class="w3-text w3-tag itemoptiontooltip">
 Edit on GitHub
</span>
    </div>
<div class="w3-bar-item w3-tooltip" >
<a class="w3-button w3-padding-small w3-gray" id="toggleHands"><span class="showHideText">Hide</span> pointers</a>
<span class="w3-text w3-tag itemoptiontooltip">Click here to hide or show again the little arrows and small left pointing hands in this page.</span>
</div>
<!--
<div class="w3-bar-item w3-tooltip" >
<a class="w3-button w3-padding-small w3-gray" id="toogleSeeAlso"><span class="showHideText">Hide</span> related</a>
<span class="w3-text w3-tag itemoptiontooltip">Click here to hide or show again the right side of the content area, where related items and keywords are shown.</span>
</div>-->
            
<!--<div class="w3-bar-item w3-tooltip">
{apptable:pdf-link($id)}
<span class="w3-text w3-tag itemoptiontooltip">Produces a PDF on the fly from the source TEI-XML using XSL-FO and Apache FOP</span>
</div>-->

<!--
<div class="w3-bar-item w3-tooltip">
<a class="w3-button w3-padding-small w3-gray"  id="TEILink" href="{( '' || $id ||  '.xml')}" target="_blank">TEI/XML</a>
<span class="w3-text w3-tag itemoptiontooltip">Download an enriched TEI file with explicit URIs bibliography from Zotero API. </span>
</div>-->
{if(($collection = 'manuscripts') and ($document//t:relation[contains(@name, 'sdc')])) then
<div class="w3-bar-item w3-tooltip">
<a class="w3-button w3-padding-small w3-gray"  id="GraphViewLink"  href="{$config:appUrl}/{$collection}/{$id}/graph" target="_blank"><i>Syntaxe</i></a>
<span class="w3-text w3-tag itemoptiontooltip">See graphs of the information available. If the manuscript contains relevant information,
then you will see visualizations based on La Syntaxe du Codex, by Andrist, Canart and Maniaci.</span>
</div>
else ()}
{if(($document//t:placeName )) then
    <div class="w3-bar-item"><a class="w3-button w3-padding-small w3-gray"  href="{$config:appUrl}/IndexPlaces?entity={string($document/@xml:id)}">Places Index</a></div> else ()}
{if(($document//t:persName )) then
    <div class="w3-bar-item"><a class="w3-button w3-padding-small w3-gray"  href="{$config:appUrl}/IndexPersons?entity={string($document/@xml:id)}">Persons Index</a></div> else ()}

 {if($collection = 'institutions' and ($document//t:geo/text() or $document//t:place[@sameAs] )) then
    <div class="w3-bar-item"><a class="w3-button w3-padding-small w3-gray"  href="{$config:appUrl}/{( $id ||
    '.json')}" target="_blank">geoJson</a></div> else ()}
  <!--
<div class="w3-bar-item w3-tooltip"
><a class="w3-button w3-padding-small w3-gray"  href="VROTTERDEVROT{$config:appUrl}/{$collection}/{$id}/analytic" target="_blank">Relations</a>
<span class="w3-text w3-tag itemoptiontooltip">Further visualization of relational information</span></div>
  -->
<div class="w3-bar-item w3-container">
  <a
  onclick="document.getElementById('relations').style.display='block'"
  class="w3-button w3-padding-small w3-gray"
  >Relations</a>
 <div id="relations" class="w3-modal w3-card w3-display-container w3-margin-top" style="vertical-align: top;max-height:600px;width:80%;">
  <div class="w3-modal-content w3-white">
    <header>
      <span
        onclick="document.getElementById('relations').style.display='none'"
        class="w3-button w3-display-topright"
      >
       <i class="fa fa-times"/>
      </span>
      <span class="w3-button w3-padding-small">Relations</span>
    </header>

    <div class="w3-container">
     {item2:EntityRelsTable($document, $collection)} 
    </div>

  
    <div class="w3-container w3-hide-small">
     {if (item2:RestPersRole($document, $collection)) then item2:RestPersRole($document, $collection) else ()}
    </div>
    <div id="timeLine" class="w3-container w3-hide-small" />
    <script type="text/javascript">
      {if (item2:timeline($document, $collection)) then item2:timeline($document, $collection) else ()}
    </script>
  </div>
 </div>
</div>
<!--show attestations new button
<div class="w3-bar-item w3-container">
  <a
  onclick="document.getElementById('attest').style.display='block'"
  class="w3-button w3-padding-small w3-red"   id="showattestations" data-value="{if ($collection = 'works' or $collection = 'narratives' or $collection = 'studies') then 'work' else if ($collection = 'persons') then 'person' else if ($collection = 'places' or $collection = 'institutions' ) then 'place' else if ($collection = 'authority-files') then 'term' else if ($collection = 'manuscripts') then 'mss' else ()}"
                        data-id="{$id}"
  >Attestations</a>
 <div id="attest" class="w3-modal w3-card w3-display-container w3-margin-top" style="vertical-align: top;max-height:600px;width:80%;">
  <div class="w3-modal-content w3-white">
    <header class="w3-container w3-red">
      <span
        onclick="document.getElementById('attest').style.display='none'"
        class="w3-button w3-display-topright"
      >
       <i class="fa fa-times"/>
      </span>
      <h4>Attestations</h4>
    </header>
                    <div
                        id="allattestations"
                        class="w3-container"/>
                </div>   

</div>
</div>-->

{if (($collection = 'works' or $collection = 'narratives' or $collection = 'studies' or $collection = 'manuscripts') and ($document//t:body[t:div[@type = 'edition'][t:ab or t:div[@type = 'textpart']]]) ) then
    (<div class="w3-bar-item w3-tooltip" 
  >
    <a class="w3-button w3-padding-small w3-red"  href="{$config:appUrl}{('/'||$collection|| '/' || $id || '/text' )}"
    target="_blank">Text</a>
    <span class="w3-text w3-tag itemoptiontooltip">Text</span>
    </div>,
    <div class="w3-bar-item w3-tooltip" >
    <a class="w3-button w3-padding-small w3-gray"  href="{$config:appUrl}{('/'||$collection|| '/' || $id || '/geoBrowser' )}"
    target="_blank">Map of places</a>
    <span class="w3-text w3-tag itemoptiontooltip">See places marked up in the text using the Dariah-DE Geo-Browser</span>
    </div>) else ()}
    
    {if (($collection = 'works' or $collection = 'narratives' or $collection = 'studies') and ($document//t:body[t:div[@type = 'translation'][t:ab or t:div[@type = 'textpart']]]) ) then
    (<div class="w3-bar-item w3-tooltip" 
  >
    <a class="w3-button w3-padding-small w3-red"  href="{$config:appUrl}{('/'||$collection|| '/' || $id || '/text' )}"
    target="_blank">Translation</a>
    <span class="w3-text w3-tag itemoptiontooltip">Translation</span>
    </div>) else ()}
    
        {if ($collection = 'manuscripts' and ($this//t:msIdentifier//t:idno[@facs][@n] or $this//t:msIdentifier//t:idno[starts-with(@facs, 'http')])) then
    <div class="w3-bar-item w3-tooltip" >
    <a class="w3-button w3-padding-small w3-gray"  href="{$config:appUrl}{('/manuscripts/' || $id || '/viewer' )}"
    target="_blank">Images</a>
    <span class="w3-text w3-tag itemoptiontooltip">Mirador viewer via IIIF</span>
    </div> else ()}
    {if ($collection = 'manuscripts' and ($this//t:msIdentifier/t:idno[not(@facs)] ) and $this//t:collection[. eq 'Ethio-SPaRe']) then
    <div class="w3-bar-item w3-tooltip" >
    <a class="w3-button w3-padding-small w3-gray"  href="{('mailto:denis.nosnitsin@uni-hamburg.de?Subject=Request%20for%20images%20of%20Ethio-SPaRe%20Manuscript%20' || $id )}" 
    target="_blank">Request Images from Ethio-SPaRe</a>
    <span class="w3-text w3-tag itemoptiontooltip">Send an email to Ethio-SPaRe Project leader to request to make the images of this manuscript available here.</span>
    </div> else ()}
    {if ($collection = 'manuscripts' and $this//t:facsimile/t:graphic) then
    <div class="w3-bar-item w3-tooltip" >
    <a class="w3-button w3-padding-small w3-gray"  href="{$this//t:facsimile/t:graphic/@url}" 
    target="_blank">Link to images</a>
    <span class="w3-text w3-tag itemoptiontooltip">Link to images available not on this site</span>
    </div> else ()}
    {if ($collection = 'works' or $collection = 'narratives' or $collection = 'studies') then
    (<div class="w3-bar-item w3-tooltip" >
    <a class="w3-button w3-padding-small w3-gray"  href="{$config:appUrl}{('/compare?workid=' || $id  )}" target="_blank">Compare</a>
    <span class="w3-text w3-tag itemoptiontooltip">Compare manuscripts with this content</span>
    </div>,
    <div class="w3-bar-item w3-tooltip" >
    <a class="w3-button w3-padding-small w3-gray"  href="{$config:appUrl}{('/workmap?worksid=' || $id  )}" target="_blank">Map of witnesses</a>
    <span class="w3-text w3-tag itemoptiontooltip">Map of manuscripts with this content</span>
    </div>)
    else ()}
    
    </div>
};

(:~ produces each item header with contents:)

declare function item2:RestItemHeader($this, $collection) {
let $document := $this
let $id := string($this/@xml:id)
let $repoids := if ($document//t:msIdentifier/t:repository/text() = 'Lost' or $document//t:msIdentifier/t:repository/text() = 'In situ' ) 
                               then ($document//t:msIdentifier/t:repository/text()) 
                             else if ($document//t:msIdentifier/t:repository/@ref) 
                                then config:distinct-values($document//t:msIdentifier/t:repository/@ref) 
                             else 'No Repository Specified'
let $key := for $ed in $document//t:titleStmt/t:editor[not(@role eq  'generalEditor')]  
                                  return 
                                  editors:editorKey(string($ed/@key)) || (if($ed/@role) then ' (' ||string($ed/@role)|| ')' else ())
let $altID := config:distinct-values($document//t:msIdentifier/t:altIdentifier/t:idno/text())
return

    <div xmlns="http://www.w3.org/1999/xhtml" class="ItemHeader w3-container">

    <div xmlns="http://www.w3.org/1999/xhtml" class="w3-twothird">
            <h3 id="headtitle">
                {exptit:printTitleID($id)}
            </h3>
            {let $formerly := $document//t:relation[@name eq 'betmas:formerlyAlsoListedAs'][@active eq $id]
             let $same := $document//t:relation[@name eq 'skos:exactMatch'][@active eq $id]
            return
            (if($formerly) then <p>This record was formerly also listed as {string-join($formerly/@passive, ', ')}.</p> 
            else(),
            if($same) then 
                    for $s in $same return <p>This record is the same as <a href="{string($s/@passive)}" target="_blank">{exptit:printTitleID($s/@passive)}</a>.</p> 
            else ())}
          <p id="mainEditor"><i>{string-join($key, ', ')}</i></p>
          {if($collection = 'manuscripts') then <p>{if($this//t:additional//t:source/t:listBibl[@type eq 'catalogue']) then 
          ('This manuscript description is based on ' , <a href="#additionals">the catalogues listed in the Catalogue Bibliography</a>, if($this//t:additional//t:source/t:listBibl[@type eq 'catalogue']/t:bibl/t:ptr[@target eq 'bm:BmWebsite']) then 
          (' and has been corrected or enriched by the Bm project team; please check our ', <a href="#footer">Revision history for more information</a> )
          else () )
          else if($this//t:collection = 'EMIP') then string-join($this//t:collection//text(), ', ')
          else if(contains($this//t:funder, 'IslHornAfr')) then ('Newly catalogued in IslHornAfr, see also ', <a href="http://islhornafr.tors.sc.ku.dk/backend/manuscripts/{format-number(number(replace($id, 'IHA', '')), '####')}">IslHornAfr manuscript {format-number(number(replace($id, 'IHA', '')), '####')}</a>)
          else if(contains($this//t:idno, 'EMML')) then string:tei2string($this//t:editionStmt)
          else 'Newly catalogued in Beta maṣāḥǝft'}</p> else ()}
          </div>


    <div xmlns="http://www.w3.org/1999/xhtml" class="w3-third">


    <div  id="general" class="w3-container">
    <div class="w3-row">
   
   {if  ($document//t:change[not(@who eq 'PL')]) then
   if (count($document//t:change[not(@who eq 'PL')]) eq 1) then
   <span class="w3-tag w3-red">Draft</span>
   else if ($document//t:change[contains(.,'stub')]) then
   <span class="w3-tag w3-red">Stub</span>
   else 
   <span class="w3-tag w3-gray w3-small">Last edit: {let $last :=max(for $date in $document//t:change/@when  return xs:date($date)) return format-date($last , "[MNn] [D], [Y]", "en", (), ())
   }</span>
else <span class="w3-tag w3-red">Stub</span>
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
                   for $altId at $p in $document//t:msIdentifier/t:altIdentifier/t:idno[text()]
                   return
                   if ( $altId/@type eq 'TM') 
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
            let $repodoc := $apprest:collection-rootIn/id($repo)
             let $repoplace := if ($repodoc//t:settlement[1]/@ref) then exptit:printTitleID($repodoc//t:settlement[1]/@ref) else if ($repodoc//t:settlement[1]/text()) then $repodoc//t:settlement[1]/text() else if ($repodoc//t:country[1]/@ref) then exptit:printTitleID($repodoc//t:country[1]/@ref) else ()
return
            (<a target="_blank"
            href="{$config:appUrl}/newSearch.html?searchType=text&amp;mode=any&amp;reporef={replace($repo, concat($config:appUrl, '/'), '')}"
            role="button"
            class="w3-tag w3-gray w3-large w3-margin-top"
            property="http://www.cidoc-crm.org/cidoc-crm/P55_has_current_location"
            resource="{$repo}">{if($repoplace) then ($repoplace, ', ') else ()}
                   {string($this//t:msIdentifier/t:repository/text())}</a>,
                  <a target="_blank"
            href="{replace($repo, $config:appUrl, '')}">
                   <sup>[view repository]</sup></a>)
                  }


 <p class="w3-large">Collection:  {string-join($document//t:msIdentifier/t:collection, ', ')}</p>

           { if($document//t:altIdentifier) then
            <p>Other identifiers: {
                   for $altId at $p in $document//t:msIdentifier/t:altIdentifier/t:idno
                   return
                   if ( $altId/@type eq 'TM') 
                   then 
                   <a href="https://www.trismegistos.org/text/{$altId/text()}" property="http://www.cidoc-crm.org/cidoc-crm/P1_is_identified_by" 
                    content="{$altId}">TM{$altId/text()}{if($altId[$p = count($document//t:msIdentifier/t:altIdentifier/t:idno/text())]) then ' ' else ', '}</a>
                   else 
                     <span property="http://www.cidoc-crm.org/cidoc-crm/P1_is_identified_by" 
                    content="{$altId/text()}">{concat(string($altId/ancestor::t:altIdentifier[1]/t:repository), ' ', $altId/text())}{if($altId[$p = count($document//t:msIdentifier/t:altIdentifier/t:idno/text())]) then ' ' else ', '}</span>
            }
            </p>
            else
            ()
            }
            </div>
            case 'persons' return if(starts-with($document//t:person/@sameAs, 'wd:')) then wiki:wikitable(substring-after($document//t:person/@sameAs, 'wd:')) else (string($document//t:person/@sameAs))

            case 'works' return
            apptable:clavisIds(root($document))
            
 case 'institutions' return

                            <div class="w3-row">
                            <a href="{$config:appUrl}/institutions/" role="label" class="w3-tag w3-red">Institution</a>

{                            if($document//t:place/@type)
   then

    let $type := data($document//t:place/@type)
    let $list := if(contains($type, ' ')) then tokenize(normalize-space($type), ' ') else string($type)
    return
     (<div>{for $t in $list return <a class="w3-tag w3-red" href="{$config:appUrl}/places/list?placetype={$t}" target="_blank">{$t}</a>}</div>,
  if(starts-with($document//t:place/@sameAs, 'wd:')) then wiki:wikitable(substring-after($document//t:place/@sameAs, 'wd:')) else (string($document//t:place/@sameAs)))
   else ()}</div>


 case 'places' return

   (if($document//t:place/@type)
   then

    let $type := data($document//t:place/@type)
    let $list := if(contains($type, ' ')) then tokenize(normalize-space($type), ' ') else string($type)
    return
(     <div  class="w3-row">{for $t in $list return <a class="w3-tag w3-red" href="{$config:appUrl}/places/list?placetype={$t}" target="_blank">{$t}</a>}</div>,
  if(starts-with($document//t:place/@sameAs, 'wd:')) then wiki:wikitable(substring-after($document//t:place/@sameAs, 'wd:')) else (string($document//t:place/@sameAs)))
   else (),
    <a target="_blank"
            href="{$config:appUrl}/manuscripts/place/list?place={$id}"
            role="button"
            class="w3-tag w3-gray w3-large 
            w3-margin-top">
                  Manuscripts in {exptit:printTitleID($id) }</a>
)
 case 'persons' return
 if($document//t:personGrp) then
                         <div  class="w3-row">   <span class="w3-tag w3-red">
                            {if ($document//t:personGrp[@role eq  'ethnic']) then 'Ethnic/Linguistic' else ()}
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
                                           <td>{if($s/@type) then exptit:printTitleID($s/@type/data()) else $s/name()}</td>
                                           <td>{
                                           if($s/@ref) then
                                           (<a target="_blank" href="{$config:appUrl}/{if(starts-with($s/@ref, $config:appUrl)) then substring-after($s/@ref, concat($config:appUrl, '/')) else $s/@ref}">{exptit:printTitle($s/@ref)}</a>,
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
      let $w := $apprest:collection-rootW
      let $n := collection($config:data-rootN)
      let $ms := $apprest:collection-rootMS
      let $plin := $apprest:collection-rootPlIn
      return
          <div class="allMainRel">{
     switch($collection)
     case 'persons' return (
     let $isSubjectof :=
            for $corr in $w//t:relation[contains(@passive,  $id)][@name eq  'ecrm:P129_is_about']

            return
                $corr
      let $isAuthorof :=
            for $corr in ($w//t:relation[contains(@passive,  $id)][@name eq  'saws:isAttributedToAuthor'],
            $w//t:relation[contains(@passive,  $id)][@name eq  'dcterms:creator'])

            return
                $corr
                  let $predecessorSuccessor :=
            for $corr in ($this//t:relation[contains(@active,  $id)][@name eq  'betmas:isSuccessorOf'], $this//t:relation[contains(@active,  $id)][@name eq  'betmas:isPredecessorOf'])

            return
                $corr
return
<div class="mainrelations w3-container">


                                            {

                   if ($isSubjectof) then  
                   <div  class="relBox  w3-panel w3-card-4 w3-gray">
                   
                   <b class="openInDialog">This person is subject of the following <span class="w3-tag">{count($isSubjectof)}</span> textual units</b>
                        <ul  class="w3-ul w3-hoverable">{
                        for $p in $isSubjectof
                    return
                        if (contains($p/@active, ' ')) then for $value in tokenize ($p/@active, ' ') return
                        <li class="nodot"><a href="{$value}">{exptit:printTitleID(string($value))}</a></li>
                        else
                        <li  class="nodot"><a href="{$p/@active}">{exptit:printTitleID(string($p/@active))}</a></li>
                        }</ul></div> else ()

                }
                {

                   if ($isAuthorof) then  <div  class="relBox  w3-panel w3-card-4 w3-gray"><b  class="openInDialog">This person is author or attributed author of the following <span class="w3-tag">{count($isAuthorof)}</span> textual units</b>
                        <ul  class="w3-ul w3-hoverable ">{
                        for $p in $isAuthorof
                    return
                        if (contains($p/@active, ' ')) then for $value in tokenize ($p/@active, ' ') return
                        <li  class="nodot"><a href="{$value}">{exptit:printTitleID(string($value))}</a></li>
                        else
                        <li  class="nodot"><a href="{$p/@active}">{exptit:printTitleID(string($p/@active))}</a></li>
                        }</ul></div> else ()

                }
{

                   if ($predecessorSuccessor) then  <div  class="relBox  w3-panel w3-card-4 w3-gray">
                   <b class="openInDialog">Successors and predecessors</b>
                        <ul  class="w3-ul w3-hoverable">{
                        for $p in $predecessorSuccessor
                        let $rel := if($p/@name eq  'bm:isSuccessorOf') then 'Predecessor: ' else 'Successor: '
                    return
                        if (contains($p/@passive, ' ')) then for $value in tokenize ($p/@passive, ' ') return
                        <li  class="nodot">{$rel}<a href="{$value}">{exptit:printTitleID(string($value))}</a></li>
                        else
                        <li  class="nodot">{$rel}<a href="{$p/@passive}">{exptit:printTitleID(string($p/@passive))}</a></li>
                        }</ul></div> else ()

                }
             </div>
      )
       case 'places' return (
     let $isSubjectof :=  for $corr in $w//t:relation[contains(@passive,  $id)][@name eq  'ecrm:P129_is_about'] return $corr
     let $churchesAndMonasteries :=  for $corr in $plin//t:place[contains(@type, 'church') or contains(@type, 'monastery')][t:*[contains(@ref ,  $id)]] return $corr
    let $formerly := for $corr in $this//t:relation[@name eq 'betmas:formerlyAlsoListedAs'][contains(@active,  $id)] return $corr
let $same := for $corr in collection($config:data-root)//t:relation[@name eq 'skos:exactMatch'][contains(@active,  $id)] return $corr 
let $samep := for $corr in collection($config:data-root)//t:relation[@name eq 'skos:exactMatch'][contains(@passive,  $id)] return $corr 
return
<div  class="mainrelations w3-display-container">

                                          { if ($this//t:settlement or $this//t:region or $this//t:country) then  
                                          <div  class="relBox w3-panel w3-card-4 w3-gray">
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
                                         
                                          if($this//t:location[@type eq 'relative']) then
                                          <tr><td>Relative location</td><td>{$this//t:location[@type eq 'relative']/text()}</td></tr> else ()

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
                                          <ul  class="w3-ul w3-hoverable">{for $s in $this//t:state[@type eq 'existence']/@ref
                                          let $file := collection($config:data-rootA)/id($s)
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
                                            {if($formerly) then (
                <div  class="relBox  w3-panel w3-card-4 w3-gray"><b  class="openInDialog">Formerly listed as:</b>
                        <ul  class="w3-ul w3-hoverable">{
                        string-join($formerly/@passive, ', ')}</ul></div>
                ) else ()
                }
                {if($same or $samep) then (
                <div  class="relBox  w3-panel w3-card-4 w3-gray"><b  class="openInDialog">Same as:</b>
                        <ul  class="w3-ul w3-hoverable">{
                        for $p in $same return <li  class="nodot"><a href="{$p/@passive}">{string($p/@passive)}</a></li>} {
                        for $p in $samep return <li  class="nodot"><a href="{$p/@passive}">{string($p/@active)}</a></li>}</ul></div>
                ) else ()
                }
                                            {
                     if ($isSubjectof) then
                     <div  class="relBox  w3-panel w3-card-4 w3-gray"><b  class="openInDialog">This place is subject of the following <span class="w3-tag">{count($isSubjectof)}</span> textual units</b>
                        <ul  class="w3-ul w3-hoverable">{
                        for $p in $isSubjectof
                    return
                        if (contains($p/@active, ' ')) then for $value in tokenize ($p/@active, ' ') return
                        <li  class="nodot"><a href="{$value}" >{exptit:printTitleID(string($value))}</a></li>
                        else
                        <li  class="nodot"><a href="{$p/@active}">{exptit:printTitleID(string($p/@active))}</a></li>
                        }</ul></div> else ()

                }
                {if($churchesAndMonasteries) then (
                <div  class="relBox  w3-panel w3-card-4 w3-gray"><b  class="openInDialog">{count($churchesAndMonasteries)} churches and monasteries can be found in this place</b>
                        <ul  class="w3-ul w3-hoverable">{
                        for $p in $churchesAndMonasteries
                        let $root := string(root($p)/t:TEI/@xml:id)
                    return
                        <li  class="nodot"><a href="{$root}">{exptit:printTitleID($root)}</a></li>
                        }</ul></div>
                ) else ()
                }


             </div>
      )
     case 'works' return (
     let $relations := ($w//t:relation[contains(@active,  $id)],
     $w//t:relation[contains(@passive,  $id)])
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
                       <li class="nodot"><a href="{$value}">{if (contains($p, 'betamasaheft')) then exptit:printTitle($p) else string($p)}</a></li>
                        else
                        <li class="nodot">{if(contains($p, 'betmas:'))
                        then <a href="{$config:appUrl}/{substring-after($p, 'betmas:')}" >{exptit:printTitle(substring-before(substring-after($p, 'betmas:'), '.'))}{()}</a> else <a href="{$p}" >{if (contains($p, 'betamasaheft')) then exptit:printTitle($p) else string($p)}</a>}</li>
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
                        <li  class="nodot"><a href="{$p/@active}" >{exptit:printTitle($p/@active)}</a></li>
                        }</ul>)
                } </div>}



             </div>
      )
      
      case 'studies' return (
     let $relations := ($w//t:relation[contains(@active,  $id)],
     $w//t:relation[contains(@passive,  $id)])
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
                       <li class="nodot"><a href="{$value}">{exptit:printTitle($value)}</a></li>
                        else
                        <li class="nodot">{if(contains($p, 'betmas:'))
                        then <a href="{$config:appUrl}/{substring-after($p, 'betmas:')}" >{exptit:printTitle(substring-before(substring-after($p, 'betmas:'), '.'))}{()}</a> else <a href="{$p}" >{if (contains($p, 'betamasaheft')) then exptit:printTitle($p) else string($p)}</a>}</li>
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
                        <li  class="nodot"><a href="{$p/@active}" >{exptit:printTitle($p/@active)}</a></li>
                        }</ul>)
                } </div>}



             </div>
      )
      
      
      case 'narratives' return (
   
let $relations := $document//t:relation[@name eq  'skos:broadMatch']
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
                        <li class="nodot"><a href="{$value}">{exptit:printTitle($value)}</a></li>
                        else
                         if(starts-with($p,'http')) then 
                        <li class="nodot"><a href="{$p}">{if (contains($p, 'betamasaheft')) then exptit:printTitle($p) else string($p)}</a></li>
                        else
                        <li class="nodot"><a href="{$config:appUrl}/{substring-after($p, 'betmas:')}">{exptit:printTitle(substring-after($p, 'betmas:'))} ({substring-after($p, 'betmas:')})</a></li>
                        }</ul>)

                }</div>}


             </div>
      )
      
       case 'authority-files' return (
   let $pass := concat('betmas:', $id)
let $relations := collection($config:data-rootN)//t:relation[@name eq  'skos:broadMatch'][contains(@passive, $pass)]
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
                        <li class="nodot">{if(starts-with($value, 'betmas:'))
                        then <a href="{$config:appUrl}/{substring-after($value, 'betmas:')}"  class="MainTitle" data-value="{substring-after($value, 'betmas:')}">{exptit:printTitle(substring-after($value, 'betmas:'))}</a> else <a href="{$value}" >{exptit:printTitle($value)}</a>}</li>
                        else

                        <li class="nodot">{if(contains($p, 'betmas:'))
                        then <a href="{$config:appUrl}/{substring-after($p, 'betmas:')}" >{exptit:printTitle(substring-before(substring-after($p, 'betmas:'), '.'))}{()}</a> else <a href="{$p}" >{if (contains($p, 'betamasaheft')) then exptit:printTitle($p) else string($p)}</a>}</li>
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
let $formerly := for $corr in $this//t:relation[@name eq 'betmas:formerlyAlsoListedAs'][contains(@active,  $id)] return $corr
let $same := for $corr in collection($config:data-root)//t:relation[@name eq 'skos:exactMatch'][contains(@active,  $id)] return $corr 
let $samep := for $corr in collection($config:data-root)//t:relation[@name eq 'skos:exactMatch'][contains(@passive,  $id)] return $corr  
return

<div class="mainrelations w3-container">
<div  class="relBox w3-panel w3-card-4 w3-gray">
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
                                          if($this//t:location[@type eq 'relative']) then
                                          <tr><td>Relative location</td><td>{$this//t:location[@type eq 'relative']/text()}</td></tr> else ()

                                           }
                                           </tbody>
                                           </table>
                                           }
                                           </div>
                                           {if($formerly) then (
                <div  class="relBox  w3-panel w3-card-4 w3-gray"><b  class="openInDialog">Formerly listed as:</b>
                        <ul  class="w3-ul w3-hoverable">{
                        string-join($formerly/@passive, ', ')}</ul></div>
                ) else ()
                }
                {if($same or $samep) then (
                <div  class="relBox  w3-panel w3-card-4 w3-gray"><b  class="openInDialog">Same as:</b>
                        <ul  class="w3-ul w3-hoverable">{
                        for $p in $same return <li  class="nodot"><a href="{$p/@passive}">{string($p/@passive)}</a></li>} {
                        for $p in $samep return <li  class="nodot"><a href="{$p/@passive}">{string($p/@active)}</a></li>}</ul></div>
                ) else ()
                }
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
 if($type = 'work') then
<div class="w3-sidebar w3-bar-block w3-card " id="sidebar" style="max-height:50vh;width:auto;z-index:auto;">
       <button type="button" class="w3-bar-item w3-button w3-hide-large" onclick="w3_closeItemSB()">
                    Close Item Navigation
                </button>
                {item2:witnesses($id)}
</div>
else ()
};


(:~called by he RESTXQ module items.xql :)
declare function item2:RestPersRole($file, $collection){
    let $id := string($file/@xml:id)
    return
if ($collection = 'persons') then(
<div  class="w3-panel w3-margin w3-card-4">{
let $persrol := $exptit:col//t:persName[ends-with(@ref,  $id)]
let $persrole := $persrol[@role]
return
if($persrole) then
for $role in $persrole
             group by $r := $role/@role
            return
             <div>{exptit:printTitle($id)} is  {string($r)}  of the following items
             <ul class="w3-ul w3-hoverable">
            {for $root in $role/ancestor::t:TEI[@xml:id !=$id]
            let $thisid := string($root/@xml:id)
                   return
                   <li>
                   <a href="{$thisid}">{exptit:printTitle($thisid)}</a>
                   {if((count($root//t:origDate[@evidence="internal-date"]) ge 1)) then 
                       let $dates:=  for $date in $root//t:origDate[@evidence="internal-date"]
                         return string:tei2string($date) 
                         return
                         ' which contains the following internal dates: ' || string-join($dates, ', ') || '.'
                         else () 
                         
                   }
                   {if((count($root//t:msDesc//t:date) ge 1)) then 
                       let $dates:=  for $date in $root//t:msDesc//t:date
                         return (string:tei2string($date) || ' in a ' || $date/parent::t:*/name() || " element")
                         return
                         ' The description of the manuscript also contains the following dates ' || string-join($dates, ', ') || '.'
                         else () 
                         
                   }
                   </li>}
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
    <a href="{$ID}">{exptit:printTitle($ID)}</a>
    is <span class="w3-tag w3-red">{for $role in config:distinct-values($p/@role) return string($role) || ' '}</span>{' of this manuscript'}.

    {
    let $tei := $exptit:col//t:TEI[@xml:id !=$id]
    let $persons := $tei//t:persName[@ref eq  string($ID)]
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
                   <li><a href="{string($root/@xml:id)}">{exptit:printTitle(string($root/@xml:id))}</a></li>

                }

        </ul>
    }

</div>

)

else ()
           };


(:~ returns a div with a list of additions containing the given id :)
declare function item2:RestAdditions($id){
       let $adds := $apprest:collection-rootMS//t:additions
       let $sameKey :=
            for $corr in $adds//t:persName[@ref eq  $id]
            return $corr
return
if ($sameKey) then
<div class="w3-panel w3-card-4 w3-margin w3-gray" id="InAdditions">
   <h4 class="modal-title">{count($sameKey)} Addition{if(count($sameKey) gt 1) then 's' else ()} name{if(count($sameKey) gt 1) then () else 's'} person <span>{exptit:printTitle($id)}</span> </h4>
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
       let $adds := $exptit:col//t:decoNote[@type eq 'miniature']
       let $sameKey :=
            for $corr in $adds//t:persName[@ref eq  $id]
            return $corr
return
if ($sameKey) then
<div class="w3-panel w3-card-4 w3-margin w3-gray" id="InMiniatures">
   <h4 class="modal-title">{count($sameKey)} Miniature{if(count($sameKey) gt 1) then 's' else ()} name{if(count($sameKey) gt 1) then () else 's'} person <span >{exptit:printTitle($id)}</span> </h4>
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
       let $adds := $apprest:collection-rootMS//t:decoNote[@type eq 'miniature'][descendant::t:ref[@type eq 'authFile'][@corresp eq $id]]
       let $themes := $adds//t:term
     return
                                           <ul  class="w3-ul w3-hoverable">{
                                           for $t in $themes
                                           let $key := string($t/@key)
                                           group by $K := $key
                                           return

                                           <li class="nodot"><a target="_blank" role="button" class="btn btn-success btn-sm" href="{$config:appUrl}/authority-files/list?keyword={$K}">{exptit:printTitleID($K)}</a>
                                               in
                                               <ul>
                                               {for $th in $t
                                               let $container := root($th)/t:TEI
                                               let $containerID := string($container/@xml:id)
                                               return
                                               <li><a target="_blank" href="{$config:appUrl}/{$containerID}">{exptit:printTitleID($containerID)}</a></li>
                                               }</ul>

                                               </li>
                                             }
                                             </ul>
       };
      (:~ returns a div with a list of place like records containing the given id as tabot :)
declare function item2:RestTabot($id){
       let $tabot := $apprest:collection-rootPlIn//t:place//t:ab[@type eq 'tabot']
       let $sameKey :=
            for $corr in $tabot//t:persName[@ref eq  $id]
            return $corr

return
if ($sameKey) then
<div class="w3-panel w3-card-4 w3-margin w3-gray" id="tabots">
   <h4 class="modal-title">{count($sameKey)} place record{if(count($sameKey) gt 1) then 's' else ()} name{if(count($sameKey) gt 1) then () else 's'} person <span >{exptit:printTitle($id)}</span> as a tabot</h4>

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
(:           let $test := util:log("info",$id):)
let $sameKey :=
            for $corr in $apprest:collection-rootMS//t:title[contains(@ref , $id)][parent::t:msItem]
            return
                $corr
  let $sameKeyAdd :=
            for $corr in               $apprest:collection-rootMS//t:additions//t:item//t:title[contains(@ref , $id)]
            return
                $corr
   let $count := count($sameKey) + count($sameKeyAdd)      
   let $distinctMssIds := for $s in ($sameKey, $sameKeyAdd) return string($s/ancestor::t:TEI/@xml:id)
   let $countDistMss := count(config:distinct-values($distinctMssIds))
return

   <div class="w3-panel w3-margin w3-red w3-card-4" style="word-break:break-all;"
   id="computedWitnesses"><span class="scrollwrap nodot w3-small">
   <h5  class="openInDialog">This unit, or parts of it, is contained in {$countDistMss} manuscript records {$count} time{if($count gt 1) then 's' else ()}</h5>
<p><a target="_blank" href="{$config:appUrl}/newSearch.html?searchType=text&amp;mode=any&amp;work-types=mss&amp;titletext=https://betamasaheft.eu/{$id}">See these {$countDistMss} manuscripts in the list view.</a>
Scrolling in this box will also show you a summary of all the occurences.  <a target="_blank" href="{$config:appUrl}/compare?workid={$id}">See also compare view.</a> </p>
    <div id="Samekeyword{$string}" class="w3-small">
    {if(count($sameKey) gt 0) then
(<p>As main content</p>,

                <ul class="nodot w3-padding">{
                                                for $hit in  $sameKey
                                                let $item := root($hit)
                                              let $root := $item/t:TEI/@xml:id
                                              let $itemid := string($root)
                                                group by $groupkey := $itemid
                                                 let $tit := exptit:printTitleID($groupkey)
                                                 order by $tit[1]

                                               (: inside the list then :)
(:                                                         order by root($hit)/t:TEI/@xml:id:)
                                                    return

                                                          <li class="w3-bar w3-card-2 list-group">
                                                        { if($item//t:msIdentifier/t:idno/@facs) then
                                                     <a class="w3-bar-item w3-circle" target="_blank" href="{$config:appUrl}/manuscripts/{$groupkey}/viewer"><i class="fa fa-picture-o" /></a> else if ($item//t:facsimile/t:graphic/@url) then
                                                        <a class="w3-bar-item" target="_blank" href="{$item//t:facsimile/t:graphic[1]/@url}"><i class="fa fa-picture-o" /></a>  else ()}
                                                          <a class="w3-bar-item"
                                               href="{$config:appUrl}/manuscripts/{$groupkey}/main">{$tit} ({string($groupkey)}) </a>

                                                      <div class="w3-bar-item"><!--  <span class="WordCount w3-tag" data-msID="{$groupkey}" data-wID="{$string}"/> -->

                                                         
                                                         <ul class="w3-padding">{
                                                         for $h in $hit
                                                         let $msitem := $h/parent::t:msItem
                                                         return

<li>content item with id <b>{string($msitem/@xml:id)}</b> {if($h/text()) then (', ', <i>{$h/text()}</i> ) else () } 
</li>
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
                                                 let $tit := exptit:printTitleID($groupkey)
                                                 order by $tit[1]

                                               (: inside the list then :)
(:                                                         order by root($hit)/t:TEI/@xml:id:)
                                                    return

                                                          <li class="w3-bar w3-card-2 list-group">
                                                          <a
                                               href="{$config:appUrl}/manuscripts/{$groupkey}/main">{$tit} ({string($groupkey)}) </a> <br/>
                                                   <!--       <span class="WordCount" data-msID="{$groupkey}" data-wID="{$string}"/>
                                                         <br/>-->
                                                         <ul class="w3-padding">{
                                                         for $h in $hit
                                                         let $item := $h/ancestor::t:item[1]
                                                         let $placement := locus:placement($item)
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
                                             let $file := collection($config:data-rootN)//id($id)
                                             let $broadMatch := $file//t:relation[@name eq "skos:broadMatch"]/@passive
                                             for $b in $broadMatch
                                             let $broad := substring-after($b, 'betmas:')
                                             let $usedasType :=  $apprest:collection-rootMS//t:additions//t:item/t:desc[@type eq  $broad]
                                             return
  (<p>As additional content associated with the keyword <b><a href="{$config:appUrl}/authority-files/list?keyword={string($broad)}">{exptit:printTitleID($broad)}</a></b> this unit
  is present an additional {count($usedasType)} time{if(count($usedasType) gt 1) then 's' else ()}</p>,
                                             <ul class="nodot w3-padding ">{
                                                for $hit in  $usedasType
                                              let $root := root($hit)/t:TEI/@xml:id
                                                group by $groupkey := $root
                                                 let $tit := exptit:printTitleID($groupkey)
                                                 order by $tit[1]

                                               (: inside the list then :)
(:                                                         order by root($hit)/t:TEI/@xml:id:)
                                                    return

                                                          <li class="w3-bar w3-card-2 list-group">
                                                          <a
                                               href="{$config:appUrl}/manuscripts/{$groupkey}/main">{$tit} ({string($groupkey)}) </a> <br/>
                                                <!--          <span class="WordCount" data-msID="{$groupkey}" data-wID="{$string}"/>
                                                         <br/>-->
                                                         <ul class="w3-padding nodot">{
                                                         for $h in $hit
                                                         let $item := $h/ancestor::t:item[1]
                                                         let $placement := locus:placement($item)
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
let $corresps := $apprest:collection-rootW//t:div[@type eq 'textpart'][@corresp eq  $id]
return
if (count($corresps) ge 1) then
 (
for $c in $corresps
let $workid := string(root($c)/t:TEI/@xml:id )
let $witnesses := $apprest:collection-rootMS//t:title[contains(@ref, $workid)][parent::t:msItem or ancestor::t:additions]
let $countwitnesses := for $wit in $witnesses
 let $wid :=  string(root($wit)/t:TEI/@xml:id )
 group by $id := $wid return $id
let $tit := exptit:printTitleID($workid)
return
(
<div id="Samepart{$string}"  class="w3-small scrollwrap">
<p>This textual unit is also part of <a target="_blank" href="{$config:appUrl}/{$workid}">{$tit}</a>, which is contained in the following {count($countwitnesses)} manuscripts {count($witnesses)} times:</p>,
<ul class=" w3-padding nodot">{
for $wit in $witnesses
 let $wid :=  string(root($wit)/t:TEI/@xml:id )
 group by $id := $wid
 let $wtit :=  exptit:printTitleID($id)
return
<li><a target="_blank" href="{$config:appUrl}/{$id}">{$wtit}</a></li>
}</ul></div>
)
) else ()
}

 {
(: subparts :)
let $work := $apprest:collection-rootW/id($id)
let $parts := $work//t:div[@type eq 'textpart'][@corresp]/@corresp
let $rels := $exptit:col//t:relation[@name eq 'saws:contains'][starts-with(@active,$id)]/@passive  
let $relformspart := $exptit:col//t:relation[(@name eq 'saws:formsPartOf') or (@name eq 'ecrm:CLP46i_may_form_part_of')][starts-with(@passive,$id)]/@active
let $all := ($parts,$rels,$relformspart)
let $ids := distinct-values($all)
return
if (count($ids) ge 1) then
 (
 
 <p>This textual unit has also {count($ids)} parts which are also independent Textual Units. 
 Below is a list of witnesses for each of them.</p>, 
for $c in $ids
let $witnesses := $apprest:collection-rootMS//t:title[contains(@ref, $c)][parent::t:msItem or ancestor::t:additions]
let $countwitnesses := for $wit in $witnesses
 let $wid :=  string(root($wit)/t:TEI/@xml:id )
 group by $id := $wid return $id
let $tit := exptit:printTitleID($c)
let $subids := for $subid in $work//t:div[@type eq 'textpart'][@corresp eq $c]/@xml:id return $id || '#' || string($subid)
let $stringsubids:=string-join($subids, ',')

return
if(count($witnesses) ge 1) then (
<div id="Samepart2{$string}"  class="w3-small scrollwrap"><p>
{$stringsubids} is listed as <a target="_blank" href="{$c}">{$c}</a> in <a target="_blank" href="{$config:appUrl}/newSearch.html?searchType=text&amp;mode=any&amp;work-types=mss&amp;{$c}">{count($countwitnesses)} manuscripts {count($witnesses)} times</a>:</p>
<ul class="nodot w3-padding">{
for $wit in $witnesses
 let $wid :=  string(root($wit)/t:TEI/@xml:id )
 group by $id := $wid
 let $wtit :=  exptit:printTitleID($id)
return
<li class="w3-bar w3-card-2 list-group"><a target="_blank" href="{$config:appUrl}/{$id}">{$wtit}</a></li>
}</ul>
{if($work//t:div[@type eq 'textpart'][@corresp=$c])
then
    let $subids := for $subid in $work//t:div[@type eq 'textpart'][@corresp eq $c]/@xml:id return $id || '#' || string($subid)
let $stringsubids:=string-join($subids, ',')
return <p><a target="_blank" href="{$config:appUrl}/compare?workid={$stringsubids},{$c}">Click to compare manuscripts of both {$stringsubids} and {$c}.</a></p> else ()}
</div>
) else <p>
<a target="_blank" href="{$config:appUrl}/{$c}">{$tit}</a> is listed also as {$c}, but not recorded with this reference in any manuscript at the moment.</p>
) else ()
}
    </span> </div>
       };


(:~ returns a selector with values which can be searched. a javascript will pick the selected one and send it to the restxq to get related items :)
 declare function item2:RestSeeAlso ($this, $collection)  {
 let $file := $this
 let $id := string($this/@xml:id)
 let $classes := for $class in $this//t:term/@key return 'http://betamasaheft.eu/'||$class
 let $options := switch($collection)
(:                   decides on the basis of the collection what is relevant to match related records :)
                   case 'manuscripts' return
                   (if ($file//t:term/@key) then <optgroup label="keywords">{for $x in config:distinct-values($file//t:term/@key) return <option value="{$x}">{exptit:printTitleID($x)}</option>}</optgroup> else (),
                   if ($file//t:supportDesc/t:material/@key) then <optgroup label="material">{for $x in ($file//t:supportDesc/t:material/@key) return <option value="{$x}">{$x}</option>}</optgroup> else (),
                   if ($file//t:handNote[@script]/@script) then <optgroup label="script">{for $x in config:distinct-values($file//t:handNote[@script]/@script) return <option value="{$x}">{string($x)}</option>}</optgroup> else (),
                   if ($file//t:objectDesc/@form) then <optgroup label="form">{for $x in config:distinct-values($file//t:objectDesc/@form) return <option value="{$x}">{string($x)}</option>}</optgroup> else ())
                   case 'works' return
                   (if ($file//t:term/@key) then <optgroup label="keywords">{for $x in config:distinct-values($file//t:term/@key) return <option value="{$x}">{exptit:printTitleID($x)}</option>}</optgroup> else (),
                   if ($file//t:relation[@name eq 'dcterms:creator']) then <optgroup label="author">{for $x in ($file//t:relation[@name eq 'dcterms:creator']) let $auth := string($x/@passive) return <option value="{$auth}">{exptit:printTitleID($auth)}</option>}</optgroup> else (),
                   if ($file//t:relation[@name eq 'saws:isAttributedToAuthor']) then <optgroup label="relation">{for $x in ($file//t:relation[@name eq 'saws:isAttributedToAuthor']) let $auth := string($x/@passive) return <option value="{$auth}">{exptit:printTitleID($auth)}</option>}</optgroup> else ()
                   )                   
                   case 'studies' return
                   (if ($file//t:term/@key) then <optgroup label="keywords">{for $x in config:distinct-values($file//t:term/@key) return <option value="{$x}">{exptit:printTitleID($x)}</option>}</optgroup> else (),
                   if ($file//t:relation[@name eq 'dcterms:creator']) then <optgroup label="author">{for $x in ($file//t:relation[@name eq 'dcterms:creator']) let $auth := string($x/@passive) return <option value="{$auth}">{exptit:printTitleID($auth)}</option>}</optgroup> else (),
                   if ($file//t:relation[@name eq 'saws:isAttributedToAuthor']) then <optgroup label="relation">{for $x in ($file//t:relation[@name eq 'saws:isAttributedToAuthor']) let $auth := string($x/@passive) return <option value="{$auth}">{exptit:printTitleID($auth)}</option>}</optgroup> else ()
                   )
                    case 'narratives' return
                   (if ($file//t:term/@key) then <optgroup label="keywords">{for $x in config:distinct-values($file//t:term/@key) return <option value="{$x}">{exptit:printTitleID($x)}</option>}</optgroup> else (),
                   if ($file//t:relation[@name eq 'dcterms:creator']) then <optgroup label="author">{for $x in ($file//t:relation[@name eq 'dcterms:creator']) let $auth := string($x/@passive) return <option value="{$auth}">{exptit:printTitleID($auth)}</option>}</optgroup> else (),
                   if ($file//t:relation[@name eq 'saws:isAttributedToAuthor']) then <optgroup label="attributed author">{for $x in ($file//t:relation[@name eq 'saws:isAttributedToAuthor']) let $auth := string($x/@active) return <option value="{$auth}">{exptit:printTitleID($auth)}</option>}</optgroup> else ()
                   )
                   case 'places' return
                   (if ($file//t:term/@key) then <optgroup label="keywords">{for $x in config:distinct-values($file//t:term/@key) return <option value="{$x}">{exptit:printTitleID($x)}</option>}</optgroup> else (),
                    if ($file//t:settlement) then <optgroup label="settlement">{for $x in $file//t:settlement/@ref return <option value="{$x}">{exptit:printTitleID($x)}</option>}</optgroup> else (),
                   if ($file//t:region) then <optgroup label="region">{for $x in $file//t:region/@ref return <option value="{$x}">{exptit:printTitleID($x)}</option>}</optgroup> else (),
                   if ($file//t:country) then <optgroup label="country">{for $x in $file//t:country/@ref return <option value="{$x}">{exptit:printTitleID($x)}</option>}</optgroup> else (),
                   if ($file//t:place[@type]) then <optgroup label="type">{if(contains($file//t:place/@type, ' ')) then for $x in tokenize($file//t:place/@type, ' ')  return <option value="{$x}">{exptit:printTitleID($x)}</option> else let $type := $file//t:place/@type return <option value="{$type}">{exptit:printTitleID($type)}</option>}</optgroup> else ()
                   )
                   case 'institutions' return
                   (if ($file//t:term/@key) then <optgroup label="keywords">{for $x in config:distinct-values($file//t:term/@key) return <option value="{$x}">{exptit:printTitleID($x)}</option>}</optgroup> else (),
                    if ($file//t:settlement) then <optgroup label="settlement">{for $x in $file//t:settlement/@ref return <option value="{$x}">{exptit:printTitleID($x)}</option>}</optgroup> else (),
                   if ($file//t:region) then <optgroup label="region">{for $x in $file//t:region/@ref return <option value="{$x}">{exptit:printTitleID($x)}</option>}</optgroup> else (),
                   if ($file//t:country) then <optgroup label="country">{for $x in $file//t:country/@ref return <option value="{$x}">{exptit:printTitleID($x)}</option>}</optgroup> else (),
                   if ($file//t:place[@type]) then <optgroup label="type">{if(contains($file//t:place/@type, ' ')) then for $x in ($file//t:place/@type)  return <option value="{$x}">{exptit:printTitleID($x)}</option> else let $type := $file//t:place/@type return <option value="{$type}">{exptit:printTitleID($type)}</option>}</optgroup> else ()
                   )
                   case 'persons' return
                   (if ($file//t:term/@key) then <optgroup label="keywords">{for $x in config:distinct-values($file//t:term/@key) return <option value="{$x}">{exptit:printTitleID($x)}</option>}</optgroup> else (),
                  if ($file//t:roleName) then <optgroup label="role">{for $x in ($file//t:roleName/@type) return <option value="{$x}">{exptit:printTitleID($x)}</option>}</optgroup> else (),
                   if ($file//t:faith) then <optgroup label="faith">{for $x in ($file//t:faith/@type) return <option value="{$x}">{exptit:printTitleID($x)}</option>}</optgroup> else (),
                   if ($file//t:occupation) then <optgroup label="occupation">{for $x in ($file//t:occupation/@type) return <option value="{$x}">{exptit:printTitleID($x)}</option>}</optgroup> else ()
                   )
                  default return (if ($file//t:term/@key) then <optgroup label="keywords">{for $x in config:distinct-values($file//t:term/@key) return <option value="{$x}">{exptit:printTitleID($x)}</option>}</optgroup> else ()
                   )
 return
       <div class="w3-third w3-padding" id="seeAlsoForm" >

{if(count($options) ge 1) then(
       <p>Select one of the keywords listed from the record to see related data</p>,
       <span typeof="{string-join($classes, ' ')}"/>,
        <form action="" class="w3-container">
                <div class="w3-container">
                    <select class="w3-select w3-border" name="seealso" id="seealsoSelector">
                    <option>select...</option>
                   {$options}
                   </select>
                    </div>
            
        </form>,
       <div id="SeeAlsoResults" class="w3-container w3-margin w3-gray">No keyword selected.</div>) else
     <div class="w3-container w3-margin w3-gray">No keywords associated with this item yet.</div>}
     {item2:mainRels($this, $collection)}
     {if($collection='works' or $collection='narratives' or $collection='studies') then item2:RestMss($id) else ()}
   {if($collection="institutions") then 
    let $t := util:log('info', concat('item see also for ', $id, ' in ', $collection))
    let $fullid := ('https://betamasaheft.eu/' || $id)
    let $mss := $exptit:col//t:repository[@ref = $fullid]
    return
        if (count($mss) ge 1) then
            <div
                class="w3-panel w3-card w3-red" style="word-break:break-all;max-height:  350px;overflow-y: scroll;">
                The dataset contains {count($mss)}
                <a
                    href="{$config:appUrl}/newSearch.html?searchType=text&amp;mode=any&amp;reporef={$id}"> records for manuscripts at this repository</a>.
                 {if (count($mss) lt 50) then
                <ul class="w3-ul">
                    {
                        for $m in $mss
                        return
                            <li><a
                                    target="blank"
                                    href="{$config:appUrl}/{string($m/ancestor::t:TEI/@xml:id)}">{if (exptit:printTitle($m)) then exptit:printTitle($m) else string($m/ancestor::t:TEI/@xml:id)}</a></li>
                    }</ul> else <span>These are too many to be shown here, please follow the <a
                    href="/newSearch.html?searchType=text&amp;mode=any&amp;reporef={$id}"> link</a> to see the full list.</span>}
            </div>
   else()
   else ()}
     {if($collection = 'places' or $collection='institutions') then <div>
     <div class="w3-container" id="pelagiosrelateditems" data-id="{$id}">
     {if($file//t:place/@sameAs) then attribute data-sameAs {string($file//t:place/@sameAs)} else ()}
     <script type="text/javascript" src="resources/js/pelagios.js"/></div>
     <div class="w3-container" id="Chojnacki" data-id="{$id}"/>
     <script type="text/javascript" src="resources/js/gnisci.js"/>
     </div> else ()}
     {if($collection='authority-files' and $file//t:relation[starts-with(@passive,'ic')]) 
     then <div class="w3-container" id="EuropeanaMatches">
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
(:because nav takes 2 colums:)
  return
       <div class="w3-container " resource="http://betamasaheft.eu/{$id}" >
       {viewItem:main($document)}
    {item2:RestSeeAlso($this, $collection)}
    </div>
};

declare function item2:documents($doc){
viewItem:documents($doc)
};

declare function item2:timeline($this, $collection){
tl:RestEntityTimeLine($this, $collection)
};

(:~ sends to the correct XSLT producing the main content of 
the page for text view
REPLACED BY dtsc:client() in dtsclient.xqm item2:RestText() 
:)

declare function item2:title($id){
exptit:printTitle($id)
};

declare function item2:textBibl($this, $id){
viewItem:textfragmentbibl($this, $id)
};