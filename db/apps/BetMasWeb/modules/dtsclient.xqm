xquery version "3.1" encoding "UTF-8";
(:~
 : test implementation of the https://github.com/distributed-text-services
 : CLIENT
 : @author Pietro Liuzzo
 :
 : can take any number of specified DTS endpoints to parse and display them,
 : so, insted of just calling the functions in the DTS module or directly query the db, it sends
 : http requests and follows the structures of the DTS endpoint.
 :)

module namespace dtsc = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/dtsc";
declare namespace http = "http://expath.org/ns/http-client";
declare namespace test = "http://exist-db.org/xquery/xqsuite";
declare namespace dts = "https://w3id.org/dts/api#";
declare namespace t = "http://www.tei-c.org/ns/1.0";
import module namespace functx = "http://www.functx.com";
import module namespace localdts = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/localdts" at "xmldb:exist:///db/apps/BetMasWeb/modules/localdts.xqm";
import module namespace viewItem = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/viewItem" at "xmldb:exist:///db/apps/BetMasWeb/modules/viewItem.xqm";
import module namespace console = "http://exist-db.org/xquery/console";


declare function dtsc:text($id, $edition, $ref, $start, $end, $collection) {
(:    let $t := util:log('info', string-join(($edition, $ref, $start, $end), ' - ')):)
    let $approot :=
    'https://betamasaheft.eu'
    (:'http://localhost:8080/exist/apps/BetMas':)
    let $APIroot := '/api/dts/'
    let $NavAPI := 'navigation'
    let $ColAPI := 'collections'
    let $DocAPI := 'document'
    let $AnnoAPI := 'annotations'
    let $baseid := '?id=https://betamasaheft.eu/'
    let $ps := (if ($ref = '') then
        ()
    else
        'ref=' || $ref,
    if ($start = '') then
        ()
    else
        'start=' || $start,
    if ($end = '') then
        ()
    else
        'end=' || $end)
    let $parm := if (count($ps) ge 1) then
        '&amp;' || string-join($ps, '&amp;')
    else
        ()
    let $refstart := if ($ref != '') then
        ('.' || $ref)
    else
        if ($start != '') then
            ('.' || $start || '-' || $end)
        else
            ()
    let $citationuri := ($approot || '/' || $id || $edition || $refstart)
    let $fullid := $approot || '/' || $id || $edition
    let $fullidpar := $baseid || $id || $edition
    let $uricol := ($approot || $APIroot || $ColAPI || $fullidpar)
    let $urinav := ($approot || $APIroot || $NavAPI || $fullidpar || $parm)
    let $uridoc := ($approot || $APIroot || $DocAPI || $fullidpar || $parm)
    let $urianno := ($approot || $APIroot || $AnnoAPI || '/' || $collection || '/items/' || $id)
    let $fullxml := $approot || '/' || $id || '.xml'
    let $DTScol := if (starts-with($fullid, $approot)) then
        localdts:Collection($fullid, 1, 'children')
    else
        dtsc:request($uricol)
    let $DTSnav := if (starts-with($fullid, $approot)) then
        localdts:Navigation($fullid, $ref, '', $start, $end, '', '', '', 'no')
    else
        dtsc:request($urinav)
    let $DTSanno := if (starts-with($fullid, $approot)) then
        localdts:Annotations($collection, $id, '1', '1', 'no')
    else
        dtsc:request($urianno)
    let $DTSdoc := if (starts-with($fullid, $approot)) then
        localdts:Document($fullid, $ref, $start, $end)
    else
        dtsc:requestXML($uridoc)
(:    let $test := util:log('info', $DTSdoc)   :)
    let $links := for $link in tokenize($DTSdoc//http:header[@name = "link"]/string(@value), ',')
    return
        <link><val>{substring-after(substring-before($link, '&gt;'), 'ref=')}</val>
            <dir>{replace(substring-after($link, '&gt; ; rel='), "'", '')}</dir></link>
    let $selectedFrag := if ($DTSdoc//dts:fragment) then
        $DTSdoc//dts:fragment
    else
        $DTSdoc//t:div[@type = 'edition']

(:    let $test := util:log('info', $selectedFrag/name())     :)
        (:This checks for the presence of a corresp and print the edition of that if present:)
    let $docnode := if ($selectedFrag[self::dts:fragment][t:div/@corresp[starts-with(., 'LIT')] and not(t:div/t:ab | t:div/t:div[@type = 'textpart'])]) then
        let $corresp := string($selectedFrag/t:div/@corresp)
        return
            (:                                  construct a node to be transformed which has the corresp for linking and a label which says it is imported from the linked entity:)
            <div
                xmlns="http://www.tei-c.org/ns/1.0">{
                    $selectedFrag/t:div/@corresp,
                    $selectedFrag/t:div/@type,
                    <label
                        xmlns="http://www.tei-c.org/ns/1.0">Text imported from linked Textual Unit</label>,
                    collection('/db/apps/expanded')//id($corresp)//t:div[@type = 'edition']/node()
                }</div>
    else
        $selectedFrag
    let $docedition:=if($docnode/self::dts:fragment) then $docnode/*[self::t:div][1]
        else $docnode    
   let $children:= $docedition/*[self::t:div or self::t:ab or self::t:lg or self::t:p or self::t:l or self::t:note]   
    return
        <div
            class="w3-container">
            <div
                class="w3-row">
                <div
                    class="w3-bar">
                    { try{
                        for $d in $DTScol?('dts:dublincore')?('dc:title')?*?('@value')
                        return
                            <div
                                class="w3-bar-item w3-small">{$d}</div>} catch * {util:log('info', $err:description)}
                    }
                    <button
                        class="w3-bar-item w3-gray w3-small"
                        id="toogleTextBibl">Hide/Show Bibliography</button>
                    <button
                        class="w3-bar-item w3-gray w3-small"
                        id="toogleNavIndex">Hide/Show Text Navigation</button>
                    {
                        try {
                            for $index in $DTSanno?member
                            return
                                <button
                                    class="w3-bar-item w3-gray w3-small
DTSannoCollectionLink">{
                                        (attribute data-value {replace($index?('@id'), 'https://betamasaheft.eu', '')},
                                        substring-before($index?title, ' for'))
                                    }</button>
                        } catch * {
                            <button
                                class="w3-bar-item w3-gray w3-small">No available Indexes</button>
                        }
                    }
                    <!--<input type='text' placeholder="add the ID of another text (e.g. LIT1349EpistlEusebius)" id="addtextid"/><button id="addtext">Add</button>-->
                </div>

                {
                    if ($DTScol?('@type') = 'Collection') then
                        (<div
                            class="w3-bar w3-border">
                            <div
                                class="w3-bar-item">Editions and translations: </div>
                            {
                                for $ed in $DTScol?member
                                return
                                    <div
                                        class="w3-bar-item"><a
                                            href="{$ed?('@id')}"
                                            target="_blank">{$ed?title}</a></div>
                            }
                        </div>)
                    else
                        ()
                }
            </div>
            <div
                id="indexNav"
                class="w3-col w3-hide "
                style="width:15%">
                <div
                    class="w3-bar w3-gray"
                    id="indexnavigation"/>
                <div
                    class="w3-bar-block"
                    id="indexitems"/>
                <script
                    type="text/javascript"
                    src="resources/js/dtsAnno.js"/>
            </div>
            <div
                id="refslist"
                class="w3-col"
                style="width:10%">
                {
                    if ($ref != '' or $start != '') then
                        <div
                            class="w3-bar-item">
                            <div
                                class="w3-bar w3-gray"
                                id="textnavigation">
                                <div
                                    style="padding: 8px 8px;"
                                    class="w3-bar-item textNavigation">
                                    <a
                                        href="/{$collection}/{$id}/text?ref={$links[dir = 'prev']/val/text()}">
                                        <i
                                            class="fa fa-angle-left"></i></a>
                                </div>
                                <div
                                    style="padding: 8px 8px;"
                                    class="w3-bar-item textNavigation">
                                    <a
                                        href="/{$collection}/{$id}/text?level={$DTSnav?('dts:level')}">level</a>
                                </div>
                                <div
                                    style="padding: 8px 8px;"
                                    class="w3-bar-item  textNavigation">
                                    <a
                                        href="/{$collection}/{$id}/text?ref={$links[dir = 'next']/val/text()}">
                                        <i
                                            class="fa fa-angle-right"></i>
                                    </a>
                                </div>
                            </div>
                        </div>
                    else
                        ()
                }
                <div
                    class="w3-bar-block">
                    <div
                        class="w3-bar-item w3-black w3-small">
                        <a
                            target="_blank"
                            href="http://voyant-tools.org/?input=https://betamasaheft.eu/works/{$id}.xml">Voyant</a>
                    </div>
                    {
                        if ($ref != '' or $start != '') then
                            (
                            <div
                                class="w3-bar-item w3-red w3-small">
                                <a
                                    href="/{$collection}/{$id}/text">
                                    Full text view
                                </a>
                            </div>)
                        else
                            ()
                    }
                    {
                        for $member in $DTSnav?member?*
                        let $r := $member?('dts:ref')
                        return
                            <div
                                class="w3-bar-item w3-gray w3-small">
                                <span
                                    class="w3-tooltip">
                                    <a
                                        class="page-scroll"
                                        href="#{$r}">
                                        {$r}
                                    </a><a
                                        href="/{$id}{$edition}.{$r}"
                                        class="w3-right">↗</a>
                                    <span
                                        class="w3-text w3-tag"
                                        style="word-break:break-all;">{$approot}/{$id}{$edition}.{$r}</span>
                                </span>
                            </div>
                    }
                    <button
                        onclick="openAccordion('dtsuris')"
                        class="w3-bar-item w3-black w3-small w3-button">
                        DTS uris</button>
                </div>
                <ul
                    id="dtsuris"
                    class="w3-ul w3-border w3-hide"
                    style="word-break:break-word;">
                    <li><b>Citation URI</b>: {$citationuri}</li>
                    <li><b>Collection API</b>: {$uricol}</li>
                    <li><b>Navigation API</b>: {$urinav}</li>
                    <li><b>Document API</b>: {$uridoc}</li>
                </ul>
            </div>             
    <div class="w3-rest">
        {  let $textgez := normalize-space(string-join($children/*//text()))
            let $gezwords := if ($textgez) then count(tokenize($textgez, '፡')) else 0 return
          if (count($children) gt 50 and $gezwords gt 100) then
        <div class="w3-red">The text is too long to display. Only the first 50 sections of {count($children)} are displayed. Please use navigation (left navigation bar or references) to view other sections.</div>
    else ()}
        {for $child in subsequence($children, 1, 50)
          let $cid:=$child/ancestor-or-self::*[@xml:id][1]/@xml:id
          let $orig := if (exists($cid))
               then dtsc:requestXML($fullxml)//*[@xml:id = $cid][1]
               else dtsc:requestXML($fullxml)//*[name() = name($child)][1]
          let $origlang := $orig/ancestor-or-self::t:*[@xml:lang][1]
          let $lang := $origlang/@xml:lang
          let $childlang :=
           element { node-name($child) } {
           $child/@* except $child/@xml:lang,
           attribute xml:lang { $lang },
           $child/node()
    }
             return  if (name($child) = ('label', 'note', 'persName', 'placeName', 'ref'))
             then viewItem:textfragment($child) else viewItem:textfragment($childlang)
        }</div>)
        </div>
};


declare function dtsc:DTStext($base, $id) {
    (:support entering what as DTS url? only collection for a given text already?

if collection provided
e.g. 
https://dts.perseids.org/collection?id=urn:cts:greekLit:tlg0099.tlg001.perseus-grc2
follow dts:references for 
https://dts.perseids.org/navigation?id=urn:cts:greekLit:tlg0099.tlg001.perseus-grc2
https://dts.perseids.org/navigation?id=urn:cts:greekLit:tlg0099.tlg001.perseus-grc2&ref=12
https://dts.perseids.org/navigation?id=urn:cts:greekLit:tlg0099.tlg001.perseus-grc2&start=12&end=15
and follow dts:passage
https://dts.perseids.org/document?id=urn:cts:greekLit:tlg0099.tlg001.perseus-grc2&ref=12

if navigation provided 
https://dts.perseids.org/navigation?id=urn:cts:greekLit:tlg0099.tlg001.perseus-grc2&start=12&end=15
and follow dts:passage
https://dts.perseids.org/document?id=urn:cts:greekLit:tlg0099.tlg001.perseus-grc2&ref=12


if document, simply render the TEI returned

although this works in principle, it does not in practice, too many small divergencies in patterns
and encoded or non encoded parts in urns . also adding to a viewer would mean limiting space, i.e.
much better to just open another window...

tested with the following sandbox module 
xquery version "3.1";
declare namespace t="http://www.tei-c.org/ns/1.0";
import module namespace config="https://www.betamasaheft.uni-hamburg.de/BetMas/config" at "xmldb:exist:///db/apps/BetMas/modules/config.xqm";
import module namespace dtsc="https://www.betamasaheft.uni-hamburg.de/BetMas/dtsc" at "xmldb:exist:///db/apps/BetMas/modules/dtsclient.xqm";

let $DTSURL :=
<pairs>
<pair>
<base>http://localhost:8080/exist/apps/BetMas/api/dts</base>
<id>https://betamasaheft.eu/LIT1349EpistlEusebius</id>
</pair>
<!--<pair>
<base>https://dts.perseids.org</base>
<id>urn:cts:greekLit:tlg0099.tlg001.perseus-grc2</id>
</pair>-->
<!--<pair>
<base>https://texts.alpheios.net/api/dts</base>
<id>urn:cts:greekLit:tlg0085.tlg001.alpheios-text-grc1</id>
</pair>-->
<!--<pair>
<base>https://dev.chartes.psl.eu/api/nautilus/dts</base>
<id>urn:cts:froLit:geste.jns5911</id>
</pair>-->
</pairs>

for $d in $DTSURL//*:pair 
let $base := $d/*:base/text()
let $id := $d/*:id/text()
return 
dtsc:DTStext($base, $id)
:)
    let $cleanbase := (if ($base = '') then
        'https://betamasaheft.eu'
    else
        if (contains($base, '/api')) then
            substring-before($base, '/api')
        else
            $base)
    let $dtsCollection := $cleanbase || dtsc:request($base)?collections || '?id=' || $id
    let $t := console:log($dtsCollection)
    let $DTScol := dtsc:request($dtsCollection)
    let $context := $DTScol?('@context')
    let $vocab := $context?('@vocab')
    let $dtsprefix := if ($vocab = 'https://w3id.org/dts/api#') then
        ()
    else
        'dts:'
    let $dtsReferences := $cleanbase || $DTScol?($dtsprefix || 'references')
    (:let $t1 := console:log(normalize-unicode($dtsReferences)):)
    let $DTSnav := dtsc:request(normalize-unicode($dtsReferences))
    let $dtsPassage := $cleanbase || $DTSnav?($dtsprefix || 'passage')
    (:let $t2 := console:log($dtsPassage):)
    let $cleanDTSpass := replace($dtsPassage, '\{&amp;ref\}\{&amp;start\}\{&amp;end\}', '')
    (:let $t3 := console:log($cleanDTSpass):)
    let $DTSdoc := dtsc:requestXML($cleanDTSpass)
    let $voyantPassage := substring-after($dtsPassage, '?id=')
    return
        <div
            class="w3-container">
            <div
                class="w3-row">
                <div
                    class="w3-bar">
                    {
                        try {
                            for $d in $DTScol?($dtsprefix || 'dublincore')?('dc:title')?*?('@value')
                            return
                                <div
                                    class="w3-bar-item w3-small">{$d}</div>
                        }
                        catch * {
                            console:log($err:description)
                        }
                    }
                </div>
                {
                    if ($DTScol?('@type') = 'Collection') then
                        (<div
                            class="w3-bar w3-border">
                            {
                                for $ed in $DTScol?member?*
                                return
                                    <div
                                        class="w3-bar-item"><a
                                            href="{$ed?('@id')}"
                                            target="_blank">{$ed?title}</a></div>
                            }
                        </div>)
                    else
                        ()
                }
            </div>
            <div
                class="w3-col"
                style="width:10%">
                <div
                    class="w3-bar-block">
                    <div
                        class="w3-bar-item w3-black w3-small">
                        <a
                            target="_blank"
                            href="http://voyant-tools.org/?input={$voyantPassage}">Voyant</a>
                    </div>
                    {
                        for $member in $DTSnav?member?*
                        return
                            <div
                                class="w3-bar-item w3-gray w3-small">
                                <a
                                    href="{$dtsReferences}&amp;ref={$member?($dtsprefix || 'ref')}">
                                    {($member?($dtsprefix || 'citeType') || ' ' || $member?($dtsprefix || 'ref'))}
                                </a>
                            </div>
                    }
                    <button
                        onclick="openAccordion('dtsuris')"
                        class="w3-bar-item w3-black w3-small w3-button">
                        DTS uris</button>
                </div>
                <ul
                    id="dtsuris"
                    class="w3-ul w3-border w3-hide"
                    style="word-break:break-word;">
                    <li><b>Collection API</b>: {$dtsCollection}</li>
                    <li><b>Navigation API</b>: {$dtsReferences}</li>
                    <li><b>Document API</b>: {$dtsPassage}</li>
                </ul>
            </div>
            <div
                class="w3-rest">{
                    try {
                        viewItem:textfragment($DTSdoc/node()[name() != 'teiHeader'])
                    } catch * {
                        $err:description
                    }
                }</div>
        </div>
};

declare function dtsc:request($dtspaths) {
    for $dtspath in $dtspaths
    let $request := <http:request
        href="{xs:anyURI($dtspath)}"
        method="GET"/>
    let $file := http:send-request($request)[2]
    let $payload := util:base64-decode($file)
    let $parse-payload := parse-json($payload)
    return
        $parse-payload
};

declare function dtsc:requestXML($dtspaths) {
    for $dtspath in $dtspaths
    let $request := <http:request
        href="{xs:anyURI($dtspath)}"
        method="GET"/>
    return
        http:send-request($request)
};
