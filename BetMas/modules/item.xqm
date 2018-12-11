xquery version "3.0" encoding "UTF-8";
(:~
 : module used by items.xql for several parts of the view produced
 :
 : @author Pietro Liuzzo <pietro.liuzzo@uni-hamburg.de'>
 :)
module namespace item="https://www.betamasaheft.uni-hamburg.de/BetMas/item";
import module namespace config="https://www.betamasaheft.uni-hamburg.de/BetMas/config" at "xmldb:exist:///db/apps/BetMas/modules/config.xqm";
import module namespace string = "https://www.betamasaheft.uni-hamburg.de/BetMas/string" at "xmldb:exist:///db/apps/BetMas/modules/tei2string.xqm";
import module namespace apprest = "https://www.betamasaheft.uni-hamburg.de/BetMas/apprest" at "xmldb:exist:///db/apps/BetMas/modules/apprest.xqm";
import module namespace editors="https://www.betamasaheft.uni-hamburg.de/BetMas/editors" at "xmldb:exist:///db/apps/BetMas/modules/editors.xqm";
import module namespace wiki="https://www.betamasaheft.uni-hamburg.de/BetMas/wiki" at "xmldb:exist:///db/apps/BetMas/modules/wikitable.xqm";
import module namespace titles="https://www.betamasaheft.uni-hamburg.de/BetMas/titles" at "xmldb:exist:///db/apps/BetMas/modules/titles.xqm";
import module namespace app="https://www.betamasaheft.uni-hamburg.de/BetMas/app" at "xmldb:exist:///db/apps/BetMas/modules/app.xqm";
import module namespace xdb="http://exist-db.org/xquery/xmldb";

declare namespace s = "http://www.w3.org/2005/xpath-functions";
declare namespace t="http://www.tei-c.org/ns/1.0";

(:~ used by item:restNav:)
declare function item:witnesses($id){
let $item := ($config:collection-rootMS, $config:collection-rootW)//t:TEI/id($id)
return
if($item/@type='mss') then <div class="col-md-2"><div class="container-fluid well" id="textWitnesses">
<h5>Transcription of the manuscript</h5></div></div>
else
<div class="col-md-2" id="textWitnesses">
<div class="container-fluid well">
<h5>Witnesses of the edition</h5>
<ul class="nodot">{
for $wit in $item//t:witness[not(@type)] return
<li class="nodot" id="{string($wit/@xml:id)}">
<a href="/manuscripts/{string($wit/@corresp)}/main" target="_blank"><b class="lead">{string($wit/@xml:id)}</b>: {titles:printTitleID(string($wit/@corresp))}</a></li>}
{
for $wit in $item//t:witness[@type = 'external'] return
<li class="nodot" id="{string($wit/@xml:id)}">
<a href="{$wit/@facs}" target="_blank"><b class="lead">{string($wit/@xml:id)}</b>: {if($wit/text()) then $wit/text() else string($wit/@corresp)}</a></li>}

</ul>
       {let $versions := $config:collection-root//t:relation[@name='saws:isVersionOf'][contains(@passive, $id)]
       return
       if($versions) then (<h5>Other versions</h5>,
         <ul  class="nodot">
                {
                    for $parallel in $versions
                    let $p := $parallel/@active
                    return
                        <li><a
                                href="{$p}" class="MainTitle"  data-value="{$p}" >{$p}</a></li>
                }
            </ul>)
            else()}
            {let $versionsO := $config:collection-root//t:relation[@name='isVersionInAnotherLanguageOf'][contains(@passive, $id)]
       return
       if($versionsO) then (
            <h5>Versions in another language</h5>,
            <ul  class="nodot">
                {
                    for $parallel in $versionsO
                     let $p := $parallel/@active
                    return
                        <li><a
                                href="{$p}" class="MainTitle"  data-value="{$p}" >{$p}</a></li>
                }
            </ul>)
            else()}

            <a role="button" class="btn btn-primary" href="/compare?workid={$id}" target="_blank">Compare</a>
</div>
</div>
};

(:~ under the main navigation bar there are the view options, this function returns the available values deciding on the type of input:)
declare function item:RestViewOptions($this, $collection) {
let $document := $this
let $id := string($this/@xml:id)
return
<div xmlns="http://www.w3.org/1999/xhtml" class="row-fluid full-width-tabs" id="options">
<ul  class="nav nav-tabs">
<li  class="span_full_width">{app:pdf-link($id)}</li>
<li class="span_full_width"><a id="mainEntryLink" href="/{$collection}/{$id}/main" target="_blank" >Entry</a></li>
<li class="span_full_width"><a id="TEILink" href="{( '/tei/' || $id ||  '.xml')}" target="_blank">TEI/XML</a></li>
<li class="span_full_width"><a id="GraphViewLink"  href="/{$collection}/{$id}/graph" target="_blank">{if($collection = 'manuscripts') then 'Syntaxe' else 'Graph'}</a></li>
    {if(($collection = 'institutions' or $collection = 'places') and ($document//t:geo/text() or $document//t:place[@sameAs] )) then
    <li class="span_full_width"><a href="/{( $id ||
    '.json')}" target="_blank">geoJson</a></li> else ()}
<li class="span_full_width"><a href="/{$collection}/{$id}/analytic" target="_blank">Relations</a></li>
    {if ($collection = 'works' or $collection = 'narratives') then
    (<li class="span_full_width"><a href="{('/'||$collection|| '/' || $id || '/text' )}" target="_blank">Text</a></li>,
    <li class="span_full_width"><a href="{('/'||$collection|| '/' || $id || '/geoBrowser' )}" target="_blank">Geo-Browser</a></li>) else ()}
    {if ($collection = 'manuscripts') then
    <li class="span_full_width"><a href="{('/'||$collection|| '/' || $id || '/text' )}" target="_blank">Transcription</a></li> else ()}
    {if ($collection = 'manuscripts' and $this//t:msIdentifier/t:idno/@facs) then
    <li class="span_full_width"><a href="{('/manuscripts/' || $id || '/viewer' )}" target="_blank">Images</a></li> else ()}
    {if ($collection = 'manuscripts' and $this//t:facsimile/t:graphic) then
    <li class="span_full_width"><a href="{$this//t:facsimile/t:graphic/@url}" target="_blank">Link to images</a></li> else ()}
    {if ($collection = 'works' or $collection = 'narratives') then
    <li class="span_full_width"><a href="{('/compare?workid=' || $id  )}" target="_blank">Compare</a></li> else ()}
    </ul>
    </div>
};

(:~ produces each item header with contents:)

declare function item:RestItemHeader($this, $collection) {
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

    <div xmlns="http://www.w3.org/1999/xhtml" class="ItemHeader col-md-12">

    <div xmlns="http://www.w3.org/1999/xhtml" class="col-md-8">
            <h1 id="headtitle">
                {titles:printTitleID($id)}
            </h1>
          <p id="mainEditor"><i>{string-join($key, ', ')}</i></p>
          </div>


    <div xmlns="http://www.w3.org/1999/xhtml" class="col-md-4">


    <div class="row-fluid" id="general">
   <div>
   {if (count($document//t:change[not(@who='PL')]) eq 1) then
   <span class="label label-warning" >Stub</span>
   else if ($document//t:change[contains(.,'completed')]) then
   <span class="label label-info" >Under Review</span>
     else if ($document//t:change[contains(.,'reviewed')]) then
   <span class="label label-success" >Version of {max($document//t:change/xs:date(@when))}</span>
   else
<span class="label label-danger" >{"Work in progress, please don't use as reference"}</span>
    }
    </div>
 {switch ($collection)
case 'manuscripts' return

    if($document//t:repository/text() = 'Lost' or $document//t:repository/text() = 'In situ')
    then <div><span class="label label-danger">{$document//t:repository/text()}</span>
    <p class="lead">Collection:  {$document//t:msIdentifier/t:collection}</p>

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
            class="btn btn-success btn-sm" 
            property="http://www.cidoc-crm.org/cidoc-crm/P55_has_current_location" 
            resource="http://betamasaheft.eu/{$repo}">{if($repoplace) then ($repoplace, ', ') else ()}
                   {titles:printTitleID($repo) }</a>
                  }


 <p class="lead">Collection:  {distinct-values($document//t:msIdentifier/t:collection)}</p>

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
            case 'persons' return if(starts-with($document//t:person/@sameAs, 'Q')) then wiki:wikitable(string($document//t:person/@sameAs)) else (string($document//t:person/@sameAs))

            case 'works' return
            app:clavisIds($document)
            
 case 'institutions' return

                            <div>
                            <a href="/institutions/" role="label" class="label label-success">Institution</a>

{                            if($document//t:place/@type)
   then

    let $type := data($document//t:place/@type)
    let $list := if(contains($type, ' ')) then tokenize(normalize-space($type), ' ') else string($type)
    return
     <div>{for $t in $list return <a class="label label-success" href="/places/list?keyword={$t}" target="_blank">{$t}</a>}</div>
   else ()}</div>


 case 'places' return

   if($document//t:place/@type)
   then

    let $type := data($document//t:place/@type)
    let $list := if(contains($type, ' ')) then tokenize(normalize-space($type), ' ') else string($type)
    return
     <div>{for $t in $list return <a class="label label-success" href="/places/list?keyword={$t}" target="_blank">{$t}</a>}</div>
   else ()

 case 'persons' return
 if($document//t:personGrp) then
                            <span class="label label-success">
                            {if ($document//t:personGrp[@role = 'ethnic']) then 'Ethnic/Linguistic' else ()}
                            Group</span> else ()
 case 'work' return
  if ($document//t:titleStmt/t:author) then <p class="lead"><a href="{$document//t:titleStmt/t:author[1]/@ref}">{$document//t:titleStmt/t:author[1]}</a></p> else ()
   default return ()
   }


</div>

</div>


</div>

};

(:~for place like items returns a row for a table with the values of the element :)
declare function item:AdminLocTable($adminLoc as element()*){
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
                                           
                                           
(:~called by item:restNav, makes the boxes where the main relations are dispalied:)
declare function item:mainRels($this,$collection){
      let $document := $this
      let $id := string($this/@xml:id)
      let $w := $config:collection-rootW
      let $ms := $config:collection-rootMS
      return
          <div class="allMainRel container-fluid">{
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
            for $corr in ($this//t:relation[@active = $id][@name = 'bm:isSuccessorOf'], $this//t:relation[@active = $id][@name = 'bm:isPredecessorOf'])

            return
                $corr
return
<div class="mainrelations">


                                            {

                   if ($isSubjectof) then  <div  class="relBox alert alert-info"><b>This person is subject of the following textual units</b>
                        <ul>{
                        for $p in $isSubjectof
                    return
                        if (contains($p/@active, ' ')) then for $value in tokenize ($p/@active, ' ') return
                        <li><a href="{$value}">{titles:printTitleID(string($value))}</a></li>
                        else
                        <li><a href="{$p/@active}">{titles:printTitleID(string($p/@active))}</a></li>
                        }</ul></div> else ()

                }
                {

                   if ($isAuthorof) then  <div  class="relBox alert alert-info"><b>This person is author or attributed author of the following textual units</b>
                        <ul>{
                        for $p in $isAuthorof
                    return
                        if (contains($p/@active, ' ')) then for $value in tokenize ($p/@active, ' ') return
                        <li><a href="{$value}">{titles:printTitleID(string($value))}</a></li>
                        else
                        <li><a href="{$p/@active}">{titles:printTitleID(string($p/@active))}</a></li>
                        }</ul></div> else ()

                }
{

                   if ($predecessorSuccessor) then  <div  class="relBox alert alert-info">
                        <ul>{
                        for $p in $predecessorSuccessor
                        let $rel := if($p/@name = 'bm:isSuccessorOf') then 'Predecessor: ' else 'Successor: '
                    return
                        if (contains($p/@passive, ' ')) then for $value in tokenize ($p/@passive, ' ') return
                        <li>{$rel}<a href="{$value}">{titles:printTitleID(string($value))}</a></li>
                        else
                        <li>{$rel}<a href="{$p/@passive}">{titles:printTitleID(string($p/@passive))}</a></li>
                        }</ul></div> else ()

                }
             </div>
      )
       case 'places' return (
     let $isSubjectof :=
            for $corr in $w//t:relation[@passive = $id][@name = 'ecrm:P129_is_about']

            return
                $corr
return
<div  class="mainrelations">

                                          { if ($this//t:settlement or $this//t:region or $this//t:country) then  <div  class="relBox alert alert-info">
                                           {
                                           <b>Administrative position</b>,
                                           <table class="table table-responsive adminpos">
                                           <tbody>
                                           {
                                          item:AdminLocTable($this//t:country), 
                                          item:AdminLocTable($this//t:region),
                                          item:AdminLocTable($this//t:settlement),
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
                                            { if ($this//t:state) then  <div  class="relBox alert alert-info">
                                           {
                                           <b>Place attested in the following periods</b>,
                                          <ul>{for $s in $this//t:state[@type='existence']/@ref
                                          let $file := $config:collection-rootA/id($s)
                                          let $name := $file//t:title[1]/text()
                                          let $link := $file//t:sourceDesc//t:ref/@target
                                          return
                                          <li><a href="{$link}">
                                          {$name}
                                          </a> (<a href='/authority-files/list?keyword={$s}'>See all items for this period</a>)</li>
                                          }</ul>
                                           }
                                           </div>
                                           else()
                                            }
                                            {

                     if ($isSubjectof) then
                     <div  class="relBox alert alert-info"><b>This place is subject of the following textual units</b>
                        <ul>{
                        for $p in $isSubjectof
                    return
                        if (contains($p/@active, ' ')) then for $value in tokenize ($p/@active, ' ') return
                        <li><a href="{$value}" >{titles:printTitleID(string($value))}</a></li>
                        else
                        <li><a href="{$p/@active}">{titles:printTitleID(string($p/@active))}</a></li>
                        }</ul></div> else ()

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
<div  class="mainrelations">


                                            {
                    for $par in $relations
                    let $relname := string(($par/@name)[1])
                    group by $rn := $relname
                    return
                      <div  class="relBox alert alert-info"> {(

                       switch($rn)
                        case 'saws:contains' return <b>The following parts of this textual unit are also independent textual units ({$rn})</b>
                        case 'ecrm:P129_is_about' return <b>The following subjects are treated in this textual unit  ({$rn})</b>
                       case 'saws:isVersionInAnotherLanguageOf' return <b>The following Textual Units are versions in other languages of this ({$rn})</b>
                         case 'saws:formsPartOf' return <b>This textual unit is included in the following textual units ({$rn})</b>
                        case 'saws:isDifferentTo' return <b>This textual unit is marked as different from the current ({$rn})</b>
                       default return <b>The following textual units have a relation {$rn} with this textual unit</b>,

                      <ul>{for $p in $par/@passive
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
                     <div  class="relBox alert alert-info">
                     {( switch($rn)
                        case 'saws:isVersionOf' return <b>The following Textual Units are versions of this ({$rn})</b>
                        case 'saws:isVersionInAnotherLanguageOf' return <b>The following Textual Units are versions in other languages of this ({$rn})</b>
                        case 'saws:isDifferentTo' return <b>This work is marked as different from the current ({$rn})</b>
                       default return <b>The following works have a relation {$rn} with this work</b>,
                        <ul>{for $p in $par
                        return
                        <li><a href="{$p/@active}" class="MainTitle" data-value="{string($p/@active)}">{string($p/@active)}</a></li>
                        }</ul>)
                } </div>}



             </div>
      )

 case 'institutions' return (
 let $mssSameRepo :=
            for $corr in $ms//t:repository[ft:query(@ref, $id)]
             order by ft:score($corr) descending
            return
               $corr
return

<div class="mainrelations col-md-12">
<div  class="relBox alert alert-info">
                                           {
                                           <b>Administrative position</b>,
                                           <table class="table table-responsive adminpos">
                                           <tbody>
                                           {
                                          item:AdminLocTable($this//t:country),
                                          item:AdminLocTable($this//t:region),
                                          item:AdminLocTable($this//t:settlement),
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
declare function item:RestNav ($this, $collection, $type) {
let $document := $this
let $id := string($this/@xml:id)
return


            if($type = 'text') then  item:witnesses($id) else
            <div class="col-md-2">
            
                <a class="btn btn-xs btn-info" href="javascript:void(0);" onclick="startIntroItem();">Take a tour of this page</a>
            <script type="application/javascript" src="resources/js/introText.js"/>
            <img id="loading" src="resources/Loading.gif" style="display: none; align: centre;" width="100%"></img>
            <nav class="navbar" id="ItemSideBar">
            <div class="navbar-header">
                <button type="button" class="navbar-toggle" data-toggle="collapse" data-target="#navbar-collapse-2">
                    <span class="sr-only">Toggle Item Navigation</span>
                    <span class="icon-large icon-plus-sign"/>
                </button>
                <a class="navbar-brand" href="/">Item Navigation</a><span/>
</div>
    <div class="navbar-collapse collapse" id="navbar-collapse-2">


    <ul class="nav nav-pills nav-stacked">
{
    transform:transform(
        $document,

        'xmldb:exist:///db/apps/BetMas/xslt/nav.xsl'
        ,
        ()
    )}
    </ul>


    </div>
    </nav>

   {item:mainRels($this, $collection)}
</div>

      };


(:~called by he RESTXQ module items.xql :)
declare function item:RestPersRole($file, $collection){
    let $c := $config:collection-root
    let $id := string($file/@xml:id)
    return
if ($collection = 'persons') then(
<div  class="well">{
let $persrol := $c//t:persName[@ref = $id]
let $persrole := $persrol[@role]
return
if($persrole) then
for $role in $persrole
             group by $r := $role/@role
            return
             <div>{<span class="MainTitle" data-value="{$id}"></span>} is <span class="label label-info role" role="btn btn-small" data-toggle="modal" data-target="#{$r}list">{string($r)}</span><div>
                    <div id="{$r}list"  class="modal fade" role="dialog">
                        <div class="modal-dialog">
                                <div class="modal-content">
                                    <div class="modal-header">
                                            <h4 class="modal-title" id="{$r}listcount">There are other</h4>
                                    </div>
                                    <div class="modal-body">
                                            <ul id="{$r}listitems"></ul>
                                    </div>
                                    <div class="modal-footer">
                        <button type="button" class="btn btn-default" data-dismiss="modal">Close</button>
                    </div>
                              </div>
                        </div>
             </div>
             </div>  of
             <ul class="lead">
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
<div  class="well">
    <a href="{$ID}">{titles:printTitleID($ID)}</a>
    is <span class="label label-success" role="btn btn-small">{for $role in distinct-values($p/@role) return string($role) || ' '}</span>{' of this manuscript'}.

    {
    let $tei := $c//t:TEI[@xml:id !=$id]
    let $persons := $tei//t:persName[@ref = string($ID)]
    for $role in $persons[@role]

    group by $r := $role/@role

            return

        <ul>and is also <span class="label label-info role" role="btn btn-small" data-toggle="modal" data-target="#{$r}list">{string($r)}</span><div>
                    <div id="{$r}list"  class="modal fade" role="dialog">
                        <div class="modal-dialog">
                                <div class="modal-content">
                                    <div class="modal-header">
                                            <h4 class="modal-title" id="{$r}listcount">There are other</h4>
                                    </div>
                                    <div class="modal-body">
                                            <ul id="{$r}listitems"></ul>
                                    </div>
                                    <div class="modal-footer">
                        <button type="button" class="btn btn-default" data-dismiss="modal">Close</button>
                    </div>
                              </div>
                        </div>
             </div>
             </div> of :

                {
                for $root in $role/ancestor::t:TEI[@xml:id !=$id]
                   return
                   <li class="lead"><a href="{string($root/@xml:id)}">{titles:printTitleID(string($root/@xml:id))}</a></li>

                }

        </ul>
    }

</div>

)

else ()
           };


(:~ returns a div with a list of additions containing the given id :)
declare function item:RestAdditions($id){
       let $adds := $config:collection-rootMS//t:additions
       let $sameKey :=
            for $corr in $adds//t:persName[@ref= $id]
            return $corr
return
if ($sameKey) then
<div class="container-fluid col-md-6" id="InAdditions">
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
declare function item:RestMiniatures($id){
       let $adds := $config:collection-root//t:decoNote[@type='miniature']
       let $sameKey :=
            for $corr in $adds//t:persName[@ref= $id]
            return $corr
return
if ($sameKey) then
<div class="container-fluid col-md-6" id="InMiniatures">
   <h4 class="modal-title">{count($sameKey)} Miniature{if(count($sameKey) gt 1) then 's' else ()} name{if(count($sameKey) gt 1) then () else 's'} person <span class="MainTitle" data-value="{$id}">{$id}</span> </h4>
                       <div id="InMiniatures{$id}">
                                           <ul>{
                                                apprest:referencesList($id, $sameKey, 'name')
                                             }
                                             </ul>
                                    </div>

                                </div>
                                else ()
       };

      (:~ returns a div with a list of the keywords used in the description of a miniture with the given art theme :)
declare function item:RestMiniaturesKeys($id){
       let $adds := $config:collection-rootMS//t:decoNote[@type='miniature'][descendant::t:ref[@type='authFile'][@corresp=$id]]
       let $themes := $adds//t:term
     return
                                           <ul class="nodot">{
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
declare function item:RestTabot($id){
       let $tabot := $config:collection-rootPlIn//t:place//t:ab[@type='tabot']
       let $sameKey :=
            for $corr in $tabot//t:persName[@ref = $id]
            return $corr

return
if ($sameKey) then
<div class="container-fluid col-md-6" id="tabots">
   <h4 class="modal-title">{count($sameKey)} place record{if(count($sameKey) gt 1) then 's' else ()} name{if(count($sameKey) gt 1) then () else 's'} person <span class="MainTitle" data-value="{$id}">{$id}</span> as a tabot</h4>

                       <div id="Tabot{$id}">
                                           <ul>{
                                                apprest:referencesList($id, $sameKey, 'name')
                                             }
                                             </ul>
                                    </div>

                                </div>
else ()
       };



       (:~ returns a div with a list of manuscripts containing the work with the given id :)
declare function item:RestMss($id){
       let $string := $id
let $sameKey :=
            for $corr in $config:collection-rootMS//t:title[@ref = $id]
            return
                $corr
return

   <div class="alert alert-success" id="computedWitnesses">
   <h4 >This Work is contained in Manuscript records {count($sameKey)} time{if(count($sameKey) gt 1) then 's' else ()}</h4>

    <div id="Samekeyword{$string}"  >


                                            <ul class="nodot">{
                                                for $hit in  $sameKey
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
                                                         <ul>{
                                                         for $h in $hit
                                                         let $msitem := $h/parent::t:msItem
                                                         let $placement := if ($h/preceding-sibling::t:locus) then ( ' ('|| (let $locs :=for $loc in $h/preceding-sibling::t:locus return string:tei2string($loc) return string-join($locs, ' ')) || ')') else ''
                                                         let $position := ' [' || count($msitem/preceding-sibling::t:msItem) +1 || '/' || count($msitem/parent::t:*/child::t:msItem) || ']'
                                                         return

<li>content item with id <b>{string($msitem/@xml:id)}</b> {if($h/text()) then (', ', <i>{$h/text()}</i> ) else () } {$placement} {$position}</li>
                                                         }
                                                         </ul>

                                                            </li>
                                             }
                                             </ul>
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
<div><ul>{
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
 declare function item:RestSeeAlso ($this, $collection)  {
 let $file := $this
 let $id := string($this/@xml:id)
 let $classes := for $class in $this//t:term/@key return 'http://betamasaheft.eu/'||$class
 return
       <div class="col-md-{if($collection = 'works' or $collection = 'places' or $collection = 'narratives') then '4' else '12'}" id="seeAlsoForm" >


       <p class="lead">Select one of the keywords listed from the record to see related data</p>
       <span typeof="{string-join($classes, ' ')}"/>
        <form action="" class="form">
            <div class="form-group">
                <div class="input-group">
                    <select class="form-control" name="seealso" id="seealsoSelector">
                    <option>select...</option>
                   {switch($collection)
(:                   decides on the basis of the collection what is relevant to match related records :)
                   case 'manuscripts' return
                   (if ($file//t:term/@key) then <optgroup label="keywords">{for $x in ($file//t:term/@key) return <option value="{$x}">{titles:printTitleID($x)}</option>}</optgroup> else (),
                   if ($file//t:supportDesc/t:material/@key) then <optgroup label="material">{for $x in ($file//t:supportDesc/t:material/@key) return <option value="{$x}">{$x}</option>}</optgroup> else (),
                   if ($file//t:handNote[@script]/@script) then <optgroup label="script">{for $x in distinct-values($file//t:handNote[@script]/@script) return <option value="{$x}">{string($x)}</option>}</optgroup> else (),
                   if ($file//t:objectDesc/@form) then <optgroup label="form">{for $x in distinct-values($file//t:objectDesc/@form) return <option value="{$x}">{string($x)}</option>}</optgroup> else ())
                   case 'works' return
                   (if ($file//t:term/@key) then <optgroup label="keywords">{for $x in ($file//t:term/@key) return <option value="{$x}">{titles:printTitleID($x)}</option>}</optgroup> else (),
                   if ($file//t:relation[@name='dcterms:creator']) then <optgroup label="author">{for $x in ($file//t:relation[@name='dcterms:creator']) let $auth := string($x/@passive) return <option value="{$auth}">{titles:printTitleID($auth)}</option>}</optgroup> else (),
                   if ($file//t:relation[@name='saws:isAttributedToAuthor']) then <optgroup label="relation">{for $x in ($file//t:relation[@name='saws:isAttributedToAuthor']) let $auth := string($x/@passive) return <option value="{$auth}">{titles:printTitleID($auth)}</option>}</optgroup> else ()
                   )
                    case 'narratives' return
                   (if ($file//t:term/@key) then <optgroup label="keywords">{for $x in ($file//t:term/@key) return <option value="{$x}">{titles:printTitleID($x)}</option>}</optgroup> else (),
                   if ($file//t:relation[@name='dcterms:creator']) then <optgroup label="author">{for $x in ($file//t:relation[@name='dcterms:creator']) let $auth := string($x/@passive) return <option value="{$auth}">{titles:printTitleID($auth)}</option>}</optgroup> else (),
                   if ($file//t:relation[@name='saws:isAttributedToAuthor']) then <optgroup label="attributed author">{for $x in ($file//t:relation[@name='saws:isAttributedToAuthor']) let $auth := string($x/@active) return <option value="{$auth}">{titles:printTitleID($auth)}</option>}</optgroup> else ()
                   )
                   case 'places' return
                   (if ($file//t:term/@key) then <optgroup label="keywords">{for $x in ($file//t:term/@key) return <option value="{$x}">{titles:printTitleID($x)}</option>}</optgroup> else (),
                    if ($file//t:settlement) then <optgroup label="settlement">{for $x in $file//t:settlement/@ref return <option value="{$x}">{titles:printTitleID($x)}</option>}</optgroup> else (),
                   if ($file//t:region) then <optgroup label="region">{for $x in $file//t:region/@ref return <option value="{$x}">{titles:printTitleID($x)}</option>}</optgroup> else (),
                   if ($file//t:country) then <optgroup label="country">{for $x in $file//t:country/@ref return <option value="{$x}">{titles:printTitleID($x)}</option>}</optgroup> else (),
                   if ($file//t:place[@type]) then <optgroup label="type">{if(contains($file//t:place/@type, ' ')) then for $x in tokenize($file//t:place/@type, ' ')  return <option value="{$x}">{titles:printTitleID($x)}</option> else let $type := $file//t:place/@type return <option value="{$type}">{titles:printTitleID($type)}</option>}</optgroup> else ()
                   )
                   case 'institutions' return
                   (if ($file//t:term/@key) then <optgroup label="keywords">{for $x in ($file//t:term/@key) return <option value="{$x}">{titles:printTitleID($x)}</option>}</optgroup> else (),
                    if ($file//t:settlement) then <optgroup label="settlement">{for $x in $file//t:settlement/@ref return <option value="{$x}">{titles:printTitleID($x)}</option>}</optgroup> else (),
                   if ($file//t:region) then <optgroup label="region">{for $x in $file//t:region/@ref return <option value="{$x}">{titles:printTitleID($x)}</option>}</optgroup> else (),
                   if ($file//t:country) then <optgroup label="country">{for $x in $file//t:country/@ref return <option value="{$x}">{titles:printTitleID($x)}</option>}</optgroup> else (),
                   if ($file//t:place[@type]) then <optgroup label="type">{if(contains($file//t:place/@type, ' ')) then for $x in ($file//t:place/@type)  return <option value="{$x}">{titles:printTitleID($x)}</option> else let $type := $file//t:place/@type return <option value="{$type}">{titles:printTitleID($type)}</option>}</optgroup> else ()
                   )
                   case 'persons' return
                   (if ($file//t:term/@key) then <optgroup label="keywords">{for $x in ($file//t:term/@key) return <option value="{$x}">{titles:printTitleID($x)}</option>}</optgroup> else (),
                  if ($file//t:roleName) then <optgroup label="role">{for $x in ($file//t:roleName/@type) return <option value="{$x}">{titles:printTitleID($x)}</option>}</optgroup> else (),
                   if ($file//t:faith) then <optgroup label="faith">{for $x in ($file//t:faith/@type) return <option value="{$x}">{titles:printTitleID($x)}</option>}</optgroup> else (),
                   if ($file//t:occupation) then <optgroup label="occupation">{for $x in ($file//t:occupation/@type) return <option value="{$x}">{titles:printTitleID($x)}</option>}</optgroup> else ()
                   )
                  default return (if ($file//t:term/@key) then <optgroup label="keywords">{for $x in ($file//t:term/@key) return <option value="{$x}">{titles:printTitleID($x)}</option>}</optgroup> else ()
                   )}
                   </select>
                    </div>
            </div>
        </form>
     <img id="loading" src="resources/Loading.gif" style="display: none;"></img>
     <div id="SeeAlsoResults" class="well">No keyword selected.</div>
     {if($collection='works') then item:RestMss($id) else ()}
     <div><button class="btn btn-primary" id="hypothesisFeed" data-value="{$id}">Load hypothes.is public annotations pointing here</button>
     <div id="hypothesisFeedResults"></div>
     <p>Use the tag <span class="label  label-info">BetMas:{$id}</span> in your public <a href="https://web.hypothes.is/">hypothes.is</a> annotations which refer to this entity.</p>
     </div>
     {if($collection = 'places' or $collection='institutions') then <div>
     <div id="pelagiosrelateditems" data-id="{$id}">
     {if($file//t:place/@sameAs) then attribute data-sameAs {string($file//t:place/@sameAs)} else ()}
     </div>
     <div id="Chojnacki" data-id="{$id}"/>
     <script type="text/javascript" src="resources/js/gnisci.js"/>
     <script type="text/javascript" src="resources/js/pelagios.js"/></div> else ()}
   </div>

      };

(:~ depending on the type of item sends to the correct XSLT producing the main content of the page :)
declare function item:RestItem($this, $collection) {
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

    <div class="container-fluid col-md-10" resource="http://betamasaheft.eu/{$id}" >
{transform:transform(
        $document,
       $xslt,
$parameters

    )}
    {item:RestSeeAlso($this, $collection)}
    </div>



};


(:~ sends to the correct XSLT producing the main content of the page for text view:)
declare  function item:RestText($this,
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
let $hits :=        map { 'hits' := $matches}
return
   <div class="col-md-10">
     <ul class="pagination" >
    {apprest:paginate-rest($hits, $parameters, $start, $per-page, 1, 21)}
    </ul>
                   {
    transform:transform(
        $document,
       $xslt,
$xslpars)}
    </div>
    else
if($document//t:div[@type='textpart']) then
let $matches := for $hit in $document//t:div[@type='textpart']
                            return $hit
let $hits :=        map { 'hits' := $matches}
let $count := count($matches)
return
   <div class="col-md-10">
   
{if($per-page = $count) then () else
(<a href="?per-page={$count}" class="btn btn-primary" id="fullText">See full text</a>,
     <ul class="pagination" >
    {apprest:paginate-rest($hits, $parameters, $start, $per-page, 1, 21)}
    </ul>)
    }
                   {
    transform:transform(
        $document,
       $xslt,
$xslpars)}
    </div>
    else if($document//t:div[@type='edition'][t:ab]) then
   
   <div class="col-md-10">{ transform:transform(
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
    <div class="col-md-10">

    { for $contained in $ids

    let $file := $config:collection-rootW//id($contained)[name()='TEI']
     let $matches := for $hit in $file//t:div[@type='textpart'] return $hit
    let $hits :=        map { 'hits' := $matches}

let $xsltlocalparameters  :=  <parameters>
    <param name="startsection" value="{$start}"/>
    <param name="perpage" value="{$per-page}"/>
</parameters>
    return
     <div class="col-md-12">
     <h1><a target="_blank" href="/works/{$contained}/text">{titles:printTitleID($contained)}</a></h1>
     <ul class="pagination" >
    {apprest:paginate-rest($hits, $parameters, $start, $per-page, 1, 21)}
    </ul>
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
