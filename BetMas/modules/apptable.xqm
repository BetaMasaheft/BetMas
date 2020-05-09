xquery version "3.1" encoding "UTF-8";
(:~
 : module used by the app for tables of results
 : 
 : @author Pietro Liuzzo 
 :)
module namespace apptable="https://www.betamasaheft.uni-hamburg.de/BetMas/apptable";
import module namespace titles="https://www.betamasaheft.uni-hamburg.de/BetMas/titles" at "xmldb:exist:///db/apps/BetMas/modules/titles.xqm";
import module namespace config="https://www.betamasaheft.uni-hamburg.de/BetMas/config" at "xmldb:exist:///db/apps/BetMas/modules/config.xqm";

declare namespace t="http://www.tei-c.org/ns/1.0";

(:~ button only visible to editors for creating a new entry  :)
declare function apptable:nextID($collection as xs:string) {
if(contains(sm:get-user-groups(sm:id()//sm:real/sm:username/string() ), 'Editors')) then (
<a role="button" class="w3-button w3-red w3-bar-item" target="_blank" href="/newentry.html?collection={$collection}">create new entry</a>) else ()
};

(: ~
 : the PDF link html snippet, called by other function based on if statements :)
declare function apptable:pdf-link($id) {
    
        <a  xmlns="http://www.w3.org/1999/xhtml" id="mainPDF" href="/{$id}.pdf" class="w3-button w3-padding-small w3-gray"><i class="fa fa-file-pdf-o" aria-hidden="true"></i></a>
};

(:~  returns a responsive table with a list of the collection selected by parameter. 
 : The parameter is decided by the url call, which is handled by the controller. 
 : might be better as a proper view. :)
declare function apptable:table($model as map(*), $start as xs:integer, $per-page as xs:integer) {
     let $items-info := $model('hits')
     let $collection := $model('collection')
return

<table class="w3-table w3-hoverable">
                    <thead data-hint="The color of each row tells you about the status of the entry. red is a stub, yellow is in progress, green/blue is completed.">
                        <tr class="w3-small">{
            if ($collection = 'works') then
                (<th>n°</th>,
                            <th>Titles</th>,
                            <th>Authors</th>,
                            <th>Witnesses</th>,
                            <th data-hint="select the works whose manuscripts you want to map and click the button above to go to the map view.">Map<input type="checkbox" class="w3-check" id="select_all_map"/></th>,
                            <th>Text</th>
                            )
            else
                if ($collection = 'places') then
                    (<th>Name</th>,
                                <th>Wikidata</th>,
                                <th>geoJson</th>)
                else
                    if ($collection = 'institutions') then
                        (<th>Name</th>,
                                    <th>Mss</th>,
                                <th>Wikidata</th>,
                                    <th>geoJson</th>)
                    else
                        if ($collection = 'persons') then
                            (<th>Name</th>,
                                        <th>Wikidata</th>,
                                        <th>Gender</th>,
                                        <th>Occupation</th>)
                        else
                            if ($collection = 'narratives') then
                                (<th>Name</th>,
                                            <th>Text</th>)
 else
                            if ($collection = 'authority-files') then
                                (<th>Name</th>)
else
                                (<th>Name</th>,
                                            <th>Shelfmarks</th>,
                                            <th>Images</th>,
                                            <th>Units</th>,
                                            <th>Parts</th>,
                                            <th>Hands</th>,
                                            <th>Script</th>,
                                      <th data-hint="select the manuscripts you want to compare and click the button above to go to the comparison view.">Compare<input type="checkbox" class="w3-check" id="select_all_compare"/></th>,
                                            <th>Text</th>)
        }
                            <th>Dated</th>
                            <th>TEI</th>
                            <th>Print <input type="checkbox" class="w3-check" id="select_all_print"/></th>
    </tr>
                    </thead>
                   <tbody  class="ListItems">
                                        {
                                    for $hit at $p in subsequence($items-info, $start, $per-page)
                                   let $doc := doc(base-uri($hit))
            return
                                                   apptable:tr($doc, $collection)
                               
                             
                                    }
                                    </tbody>
                </table>

};


(:~table rows and color code for change records:)
declare function apptable:tr($doc as node(), $list as xs:string) {

    <tr class="ListItems"
        style="{
                if (count($doc//t:change[@who != 'PL']) eq 1) then
                    'background-color:rgb(213, 75, 10, 0.4)'
                else
                    if ($doc//t:change[contains(., 'completed')]) then
                        'background-color:rgb(172, 169, 166, 0.4)'
                    else
                        if ($doc//t:change[contains(., 'reviewed')]) then
                            'background-color:white'
                        else
                            'background-color:rgb(213, 75, 10, 0.4)'
            }">
            
            {
            
            
           apptable:tds($doc, $list)
            
            }
       
    </tr>
    
};

(:~function to print the values of parallel clavis ids:)
declare function apptable:clavisIds($doc as node()){
    <span class="w3-tooltip"><span class="w3-tag">CAe {substring(string($doc/t:TEI/@xml:id), 4, 4)}</span>
    <span class="w3-text"><a href="https://www.traces.uni-hamburg.de/en/texts/clavis.html"><em>Clavis Aethiopica</em></a>, an ongoing repertory of all known Ethiopic <a href="https://betamasaheft.eu/Guidelines/?id=definitionWorks">Textual Units</a>. Use this to refer univocally to a specific text in your publications. Please note that this shares only the 
    numeric part with the <a href="https://betamasaheft.eu/Guidelines/?id=entities-id-structure">Textual Unit Record Identifier</a>.</span>
    </span> ,
if($doc//t:listBibl[@type='clavis']) 
            then (
            <div class="w3-responsive"><table class="w3-table w3-hoverable">
            <thead>
            <tr>
            <th><span class="w3-tooltip">Clavis
<span class="w3-text">(list of identifiable texts)</span></span></th><th>ID</th></tr>
            </thead>
            <tbody>
            {for $bibl in $doc//t:listBibl[@type='clavis']/t:bibl 
             let $st := string($bibl/@type)
            return 
            <tr>
            <td>
            <span class="w3-tooltip">{$st}<span class="w3-text">{
            switch($st) 
            case "CC" return (<a href="http://www.cmcl.it/">Clavis Coptica</a>, <a href="http://paths.uniroma1.it/">PAThs</a>)
              case "BHO" return <a href="https://en.wikipedia.org/wiki/Bibliotheca_Hagiographica_Orientalis">Bibliotheca Hagiographica Orientalis</a> 
              case "BHG" return <a href="https://en.wikipedia.org/wiki/Bibliotheca_Hagiographica_Graeca">Bibliotheca Hagiographica Graeca</a>
                case "CANT" return <a href="http://www.brepols.net/pages/ShowProduct.aspx?prod_id=IS-9782503502519-1">Clavis Apocryphorum Novi Testamenti</a>
                  case "CAVT" return <a href="http://www.brepols.net/pages/ShowProduct.aspx?prod_id=IS-9782503507033-1">Clavis Apocryphorum Veteris Testamenti</a>
                    case "BHL" return <a href="https://it.wikipedia.org/wiki/Bibliotheca_hagiographica_latina">Bibliotheca Hagiographica Latina</a>
                    case "syriaca" return <a href="http://syriaca.org">Syriaca.org</a>
                      case "KRZ" return 'Kinefe-Rigb Zelleke 1975. ‘Bibliography of the Ethiopic Hagiographical Traditions’, Journal of Ethiopian Studies, 13/2 (1975), 57–102.' 
                      case "H" return 'Hammerschmidt, E. 1987. Studies in the Ethiopic Anaphoras, Äthiopistische Forschungen, 25 (Stuttgart: Franz Steiner Verlag Wiesbaden GmbH,1987)'
            default return <a href="https://en.wikipedia.org/wiki/Clavis_Patrum_Graecorum">Clavis Patrum Graecorum</a>}</span></span>
          </td>
            <td>
            <a href='{$bibl/@corresp}'>{$bibl/t:citedRange/text()}{if($bibl/ancestor::t:div[@type='textpart' or @type='edition']) then (' (' || string($bibl/ancestor::t:div[@type][1]/@xml:id) || ')') else ()}</a>
            </td>
            </tr>
            }
            </tbody>
            </table></div>
            ) else ()
};


(:~table cells:)
declare function apptable:tds($item as node(), $list as xs:string) {

let $itemid := string($item/t:TEI/@xml:id)
let $itemtitle := titles:printTitleID($itemid)
   
return

(
if ($list = 'works') then (
(: id only works :)
<td><a href="/{$list}/{$itemid}/main"><i class="fa fa-arrow-circle-right"></i></a>
{if(ends-with($itemid, 'IHA'))  then ('IslHornAfr ' || substring($itemid, 4, 4)) else apptable:clavisIds($item)}
            </td>)
            else if ( matches($list, '\w+\d+\w+'))then (
(: link to main view from catalogues :)
<td><a
            href="/manuscripts/{$itemid}/main">{$itemtitle}</a>
            </td>) 
            else if ( starts-with($list, 'INS'))then (
(: link to list view for institutions :)
<td><a
            href="/manuscripts/{$itemid}/main">{$itemtitle}</a>
            </td>) 
            else if ($list = 'institutions') then (
(: link to list view for institutions :)
<td><a
            href="/manuscripts/{$itemid}/list">{$itemtitle}</a>
            </td>) 
    else
    (:  name ALL:)
        (<td><a
            href="/{$itemid}" >{$itemtitle}</a></td>),
            
            
    if ($list = 'works') then
        (
   (:work titles:)
        <td><ul class="nodot">
                {
                    for $title in $item//t:titleStmt/t:title
                    return
                        <li><a href="/{$list}/{$itemid}/main">{$title/text()} {if ($title/@xml:lang) then (' (' || string($title/@xml:lang) || ')') else ()}</a></li>
                }
            </ul>
        </td>,
(:        work authors:)
        <td><ul class="nodot">
                {
                    for $author in $item//t:titleStmt/t:author
                    return
                        <li>{$author}</li>
                }
                {
                let $attributions := for $r in $item//t:relation[@name="saws:isAttributedToAuthor"]
                let $rpass := $r/@passive
                return 
                if (contains($rpass, ' ')) then tokenize($rpass, ' ') else $rpass
                    for $author in distinct-values($attributions)
                    return
                        <li><a href="{$author}"><mark>{try{titles:printTitleID($author)} catch*{$author//t:titleStmt/t:title[1]/text()}}</mark></a></li>
                }
            </ul>
        </td>,
(:        work witnesses:)
        <td>
            <ul  class="nodot">
                {
                    for $witness in $item//t:listWit/t:witness
                    let $corr := $witness/@corresp
                    return
                        <li><a
                                href="{$witness/@corresp}" class="MainTitle"  data-value="{$corr}" >{string($corr)}</a></li>
                }
            </ul>
            <ul  class="nodot">
                {
                    for $parallel in $config:collection-root//t:relation[@name='saws:isVersionOf'][contains(@passive, $itemid)]
                    let $p := $parallel/@active
                    return
                        <li><a
                                href="{$p}" class="MainTitle"  data-value="{$p}" >{$p}</a></li>
                }
            </ul>
            <ul  class="nodot">
                {
                    for $parallel in $config:collection-root//t:relation[@name='isVersionInAnotherLanguageOf'][contains(@passive, $itemid)]
                     let $p := $parallel/@active
                    return
                        <li><a
                                href="{$p}" class="MainTitle"  data-value="{$p}" >{$p}</a></li>
                }
            </ul>
            <a role="button" class="w3-button w3-small w3-gray" href="/compare?workid={$itemid}">compare</a>
            <a role="button" class="w3-button w3-small w3-gray" href="/workmap?worksid={$itemid}">map of mss</a>
        </td>,
(:        work parts:)
        
<td><input type="checkbox" class="w3-check mapSelected" data-value="{$itemid}"/></td>
)
    else
        if ($list = 'manuscripts' or starts-with($list, 'INS')  or matches($list, '\w+\d+\w+')) then
        
(:      images  msitemsm msparts, hands, script:)
            (<td>{let $idnos := for $shelfmark in $item//t:msIdentifier//t:idno return $shelfmark/text() return string-join($idnos, ', ')}
            </td>,
            <td>{if ($item//t:facsimile/t:graphic/@url) then <a target="_blank" href="{$item//t:facsimile/t:graphic/@url}">Link to images</a> else if($item//t:msIdentifier/t:idno/@facs) then 
                 <a target="_blank" href="/manuscripts/{$itemid}/viewer">{
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
                else if (contains($item//t:msIdentifier/t:idno/@facs, 'digi.vat')) then <img src="{replace(substring-before($item//t:msIdentifier/t:idno/@facs, '/manifest.json'), 'iiif', 'pub/digit') || '/thumb/'
                    ||
                    substring-before(substring-after($item//t:msIdentifier/t:idno/@facs, 'MSS_'), '/manifest.json') || 
                    '_0001.tif.jpg'
                }" class="thumb w3-image"/>
(:                bodleian:)
else if (contains($item//t:msIdentifier/t:idno/@facs, 'bodleian')) then ('images')
                else (<img src="{$config:appUrl ||'/iiif/' || string($item//t:msIdentifier/t:idno/@facs) || '_001.tif/full/140,/0/default.jpg'}" class="thumb w3-image"/>)
                 }</a>
                
                else ()}</td>,
            <td>{count($item//t:msItem[not(t:msItem)])}</td>,
            <td>{
                    if (count($item//t:msPart) = 0) then
                        1
                    else
                        count($item//t:msPart)
                }{
                    if ($item//t:collation[descendant::t:item]) then
                        ' with collation'
                    else
                        ()
                }</td>,
            <td>{count($item//t:handNote)}</td>,
            <td>{distinct-values(data($item//@script))}</td>,
<td><input type="checkbox" class="w3-check compareSelected" data-value="{$itemid}"/></td>
            )
        else
            if ($list = 'persons') then
(:            gender:)
                (
                <td>{let $wd :=string($item//t:person/@sameAs)
                return
                <a
                    href="{('https://www.wikidata.org/wiki/'||$wd)}"
                    target="_blank">{$wd}</a>}</td>,
                <td>{
                    switch (data($item//t:person/@sex))
                            case "1"
                                return
                                    <i class="fa fa-male" aria-hidden="true"></i>
                            case "2"
                                return
                                   <i class="fa fa-female" aria-hidden="true"></i>
                            default return
                                ()
                }</td>,
                <td>{
                   let $occupation := $item//t:person/t:occupation
                           return 
                           $occupation/text()
                }</td>
            )
        else
            if ($list = 'institutions') then
(:            mss from same repo:)
                (
                <td>{
                        let $id := string($itemid)
                        let $mss := $config:collection-rootMS//t:repository[@ref = $id]
                        return
                            count($mss)
                    }</td>
                )
            else
                (),  
if ($list = 'places' or $list = 'institutions') then
(:geojson:)
    (<td>{
    let $wd := substring-after($item//t:place/@sameAs, 'wd:')
    return
            if ($wd) then
                <a
                    href="{('https://www.wikidata.org/wiki/'||$wd)}"
                    target="_blank">{$wd}</a>
            else
                ()
        }</td>,
    <td>{
            if ($item//t:geo) then
                <a
                    href="{($itemid)}.json"
                    target="_blank"><span
                        class="glyphicon glyphicon-map-marker"></span></a>
            else
                ()
        }</td>)
else
    if ($list = 'works' or $list = 'manuscripts' or starts-with($list, 'INS') or matches($list, '\w+\d+\w+') or $list = 'narratives') then
  
(:    text:)
        <td>
      {
  if ($item//t:div/t:ab) 
  then
         <a href="{('/' || $itemid || '/text')}"
                        target="_blank">text</a>
            else
                ()
        }
        </td>
else
    (),
    
(:    date, xml, analytics, seeAlso:)
<td>{
        if ($list = 'works' or $list = 'manuscripts' or $list = 'narratives' or $list = 'places' or $list = 'institutions') 
        
        then (
      let $dates :=
           for $date in ($item//t:date[@evidence = 'internal-date'],
        $item//t:origDate, 
        $item//t:date[@type = 'foundation'], 
        $item//t:creation)
             
           return
          ('['||data($date/ancestor::t:*[@xml:id][1]/@xml:id)|| '] '||
                (if ($date/@when) then
                    data($date/@when)
                     else
                    if ($date/@notBefore or $date/@notAfter) then
                        ('between ' || (if ($date/@notBefore) then data($date/@notBefore) else ('?')) || ' and ' || (if ($date/@notAfter) then data($date/@notAfter) else ('?')))
                else
                    if ($date/@from or $date/@to) then
                        (data($date/@from) || '-' || data($date/@to))
                    else
                        $date))
                        
        return
        string-join($dates, ', ')
            ) 
         else if ($list = 'persons') then (
         if ($item//t:birth[@when or @notBefore or @notAfter or text()[. !='']] or 
        $item//t:death[@when or @notBefore or @notAfter  or text()[. !='']] or 
       $item//t:floruit[@when or @notBefore or @notAfter  or text()[. !='']])
        then(
         for $date in ($item//t:birth[@when or @notBefore or @notAfter or text()], 
         $item//t:death[@when or @notBefore or @notAfter or text()], 
         $item//t:floruit[@when or @notBefore or @notAfter or text()])
        return
        <p>{switch ($date/name())
        case 'birth' return 'b. '
        case 'death' return 'd. '
        default return 'f. ',
            if($date[@when]) 
            then string($date/@when)
            else if($date[@notBefore and @notAfter]) 
            then string($date/@notBefore) || '-'|| string($date/@notAfter)
            else if($date[@notBefore and not(@notAfter)]) 
            then 'after ' || string($date/@notBefore)
            else if($date[@notAfter and not(@notbefore)]) 
            then 'before ' || string($date/@notAfter) 
            else transform:transform($date, 'xmldb:exist:///db/apps/BetMas/xslt/dates.xsl',())  }</p>
           
         )
           else
            'N/A'
        )
        
       
         
            
            else 'N/A'
    }</td>,
<td><a
        href="{('/tei/' || $itemid || '.xml')}"
        target="_blank">XML</a></td>,
<td><input type="checkbox" class="form-control pdf" data-value="{$itemid}"/></td>
)
};
