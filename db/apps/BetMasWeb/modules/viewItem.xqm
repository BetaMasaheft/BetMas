xquery version "3.1";
(:refactoring of the former XSLT library into an Xquery module with typeswitch:)
module namespace viewItem = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/viewItem";
import module namespace config = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/config" at "xmldb:exist:///db/apps/BetMasWeb/modules/config.xqm";
import module namespace exptit = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/exptit" at "xmldb:exist:///db/apps/BetMasWeb/modules/exptit.xqm";
import module namespace switch2 = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/switch2" at "xmldb:exist:///db/apps/BetMasWeb/modules/switch2.xqm";
import module namespace item2 = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/item2" at "xmldb:exist:///db/apps/BetMasWeb/modules/item.xqm";
import module namespace http = "http://expath.org/ns/http-client";
import module namespace functx = 'http://www.functx.com';
declare namespace t = "http://www.tei-c.org/ns/1.0";
declare namespace s = "http://www.w3.org/2005/xpath-functions";
declare namespace b = "betmas.biblio";
declare namespace d = "betmas.domlib";
declare namespace dts = "https://w3id.org/dts/api#";
declare namespace number = "roman.numerals.funct";
declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";
declare option output:method "html5";
declare option output:indent "yes";

(:to preserve white spaces in mixed content the option in conf.xml preserve-white-space needs to be set to yes! :)

declare variable $viewItem:coll := collection('/db/apps/expanded');
declare variable $viewItem:bibliography := doc('/db/apps/lists/bibliography.xml');
declare variable $viewItem:prefixDef := doc('/db/apps/lists/listPrefixDef.xml');
declare variable $viewItem:domlib := doc('/db/apps/lists/domlib.xml');
declare variable $viewItem:editors := doc('/db/apps/lists/editors.xml')//t:list;
declare variable $viewItem:lang := doc('/db/apps/lists/languages.xml')//t:list;

declare %private function viewItem:imagesID($locus, $callorid, $att, $ancID) {
    let $id := concat('images', replace(normalize-space(string-join($att)), ' ', '_'), $ancID)
    return
        if ($callorid = 'call') then
            concat('document.getElementById(&#34;', $id, '&#34;).style.display=&#34;block&#34;')
        else
            $id
};

declare %private function viewItem:parseRef($FromToTarget) {
    let $regex := '(\d+)([r|v])?([A-Za-z]+)?(\d+)?'
    let $analyse := analyze-string($FromToTarget, $regex)
    return
        (for $s in $analyse//s:non-match
        return
            $s,
        for $s in $analyse//s:match
        return
            ($s/s:group[@nr = "1"]/text(), $s/s:group[@nr = "2"]/text(), $s/s:group[@nr = "3"]/text(),
            if ($s/s:group[@nr = "4"]) then
                concat(' l.', $s/s:group[@nr = "4"]/text())
            else
                ())
        )
};

declare %private function viewItem:breakdownRef($FromToTarget) {
    let $regex := '(\d+)([r|v])?([A-Za-z]+)?(\d+)?'
    let $analyse := analyze-string($FromToTarget, $regex)
    return
        (for $s in $analyse//s:non-match
        return
            $s,
        for $s in $analyse//s:match
        return
            <ref>
                <folio>
                    {$s/s:group[@nr = "1"]/text()}
                </folio>
                {
                    if ($s/s:group[@nr = "2"]) then
                        <side>
                            {$s/s:group[@nr = "2"]/text()}
                        </side>
                    else
                        ()
                }
                {
                    if ($s/s:group[@nr = "3"]) then
                        <col>
                            {$s/s:group[@nr = "3"]/text()}
                        </col>
                    else
                        ()
                }

                {
                    if ($s/s:group[@nr = "4"]) then
                        <line>
                            {$s/s:group[@nr = "4"]/text()}
                        </line>
                    else
                        ()
                }
            </ref>
        )
};

declare %private function viewItem:mainID($node) {
    string($node/ancestor::t:TEI/@xml:id)
};

declare %private function viewItem:locus($this) {
    let $parent := $this/parent::t:*
    let $mainID := viewItem:mainID($this)
    let $anc := ($this/ancestor::t:*[@xml:id])[1]
    let $ancID := replace($anc/@xml:id, '\.', '_')
    let $prevTextNode := $this/preceding-sibling::text()
    let $clean := replace(string-join($prevTextNode), '\s', '')
    return
  (::  if((count($this/ancestor::t:msItem) gt 2) or (count($this/ancestor::t:TEI//t:msItem) gt 100)) then
    $this/text()
    else ::)
        (
        if ($this/parent::t:ab[not(@type = 'CruxAnsata' or @type = 'ChiRho' or @type = 'coronis' or @type = 'ruling'  or @type = 'pricking' )]) then
            '(Excerpt from '
        else
            (),
        if ($this[not(text())]) then
            if (contains($this/@target, ' ')) then
                let $prefix := if ($this/ancestor::t:TEI//t:extent/t:measure[@type != "blank"][@unit = 'page']) then
                    'pp. '
                else
                     if (matches($clean, '[^\.]$') or matches($clean, ' ca.') or matches($clean, ' e.g.'))
                                    then
                                        'ff. '
                                    else
                                        'Ff. '
                let $targets := for $t at $p in viewItem:makeSequence($this/@target)
                return
                    (<a
                        href="{$t}">
                        {viewItem:choosefacsorlb($this, $ancID)}
                        {viewItem:parseRef(concat(substring-after($t, '#'), ' '))}
                    </a>,  if ($p = count(viewItem:makeSequence($this/@target))) then  ()  else  ', ')
                return
                    ($prefix,
                    $targets)
            else
                if ($this/@target) then
                    let $prefix := if ($this/ancestor::t:TEI//t:extent/t:measure[@type != "blank"][@unit = 'page']) then
                        'p. '
                    else
                       if (matches($clean, '[^\.]$') or matches($clean, ' ca.') or matches($clean, ' e.g.') or matches($clean, ' cp.')  or matches($clean, ' esp.'))
                                    then
                                        'f. '
                                    else
                                        'F. '
                    return
                        ($prefix,
                        <a
                            href="{$this/@target}">
                            {viewItem:choosefacsorlb($this, $ancID)}
                            {viewItem:parseRef(concat(substring-after($this/@target, '#'), ' '))}
                        </a>)
                else
                    let $prefix := if ($this/ancestor::t:TEI//t:extent/t:measure[@type != "blank"][@unit = 'page']) then
                        'pp. '
                    else
                         if (matches($clean, '[^\.]$') or matches($clean, ' ca.') or matches($clean, ' e.g.') or matches($clean, ' cp.')  or matches($clean, '  esp.'))
                                    then
                                        'ff. '
                                    else
                                        'Ff. '
                    return
                        ($prefix, <a
                            href="#{$this/@from}">
                            {viewItem:choosefacsorlb($this, $ancID)}
                            {viewItem:parseRef($this/@from)}
                        </a>,
                        '–',
                        <a
                            href="#{$this/@to}">
                            {viewItem:choosefacsorlb($this, $ancID)}
                            {viewItem:parseRef($this/@to)}
                        </a>
                        )
        else
            (
            if ($this/@target) then
                <a
                    href="{$this/@target}">
                    {viewItem:choosefacsorlb($this, $ancID)}
                    {$this/text()}
                </a>
            else

                <a
                    href="#{$this/@from}">
                    {viewItem:choosefacsorlb($this, $ancID)}
                    {$this/text()}
                </a>
            ),
        if ($this/@cert = 'low') then
            ' (?)'
        else
            (),
        (:             and not($text = 'only')"  ?????:)
        if ($this/@facs) then
            try {
                viewItem:matchingFacs($this)
            } catch * {
                util:log('info', $err:description)
            }
        else
            if ($this/ancestor::t:TEI//t:div[@xml:id = 'Transkribus']) then
                (:      'matches lb':)
                viewItem:matchinglb($this)
            else
                (),
        if ($this/ancestor::t:TEI//t:div[@type = 'edition'][descendant::t:ab[descendant::text()]]) then
            let $to := if ($this/@to) then
                ('-' ||
                string($this/@to))
            else
                ()
            let $refs :=
            (concat(string($this/@from), $to),
            for $t in viewItem:makeSequence($this/@target)
            return
                substring-after($t, '#')
            )
            for $r in $refs[not(. = '')]
            return
                <a
                    class="locusReference"
                    target="_blank"
                    href="{$config:appUrl}/{$mainID}.{$r}">
                    <i
                        class="fa fa-file-text-o"
                        aria-hidden="true"/>
                </a>
        else
            (),

        if ($this/parent::t:ab[not(@type = 'CruxAnsata' or @type = 'ChiRho' or @type = 'coronis' or @type = 'ruling'  or @type = 'pricking' )]) then
            (')', <br></br>)
        else
            (),

            ' '
        )
};

declare %private function viewItem:matchingFacs($locus) {
    let $anc := ($locus/ancestor::t:*[@xml:id][1])
    let $ancID := replace($anc/@xml:id, '\.', '_')
    let $modalid := viewItem:imagesID($locus, 'id', $locus/@facs, $ancID)
    let $mainID := viewItem:mainID($locus)
    let $idandanchor := $mainID || '#' || $ancID
    return
        <div
            class="w3-modal"
            id="{$modalid}">


            <!-- Modal content-->
            <div
                class="w3-modal-content">
                <header
                    class="w3-container">
                    <h4>Images relevant for {exptit:printTitle($idandanchor)}, from {string($locus/ancestor::t:TEI//t:msIdentifier/t:idno/@facs)}</h4>
                    <div>{
                            if ($locus/@target) then
                                ('You are viewing a sequence of images including ', $locus/text())
                            else
                                ('You are viewing a sequence of images from f.', string($locus/@from), 'to f. ', string($locus/@to))
                        }</div>
                    <button
                        class="w3-button w3-gray w3-display-topright"
                        onclick="document.getElementById('{$modalid}').style.display='none'">Close</button>
                </header>
                <div
                    class="w3-container">
                    {
                        let $MainFacs := $locus/ancestor::t:TEI//t:msIdentifier/t:idno/@facs
                        let $mid := if ($locus/parent::t:witness) then
                            string($locus/parent::t:witness/@corresp)
                        else
                            $mainID
                        let $manifest := if (starts-with($MainFacs, 'http')) then
                            $MainFacs
                        else
                            concat('https://betamasaheft.eu/api/iiif/', $mid, '/manifest')
                        let $firstCanv :=
                        let $fc := if (contains($locus/@facs, ' ')) then
                            substring-before($locus/@facs, ' ')
                        else
                            $locus/@facs
                        let $fcc := replace($fc, '[a-z\s]', '')
                        return
                            if (not(starts-with($MainFacs, 'http'))) then
                                concat('?FirstCanv=', 'https://betamasaheft.eu/api/iiif/', $mid, '/canvas/p', format-number(xs:integer($fcc), '###'))
                            else
                                ()
                        let $mirador := concat('https://betamasaheft.eu/manuscripts/', $mid, '/viewer', $firstCanv)
                        let $f := $locus/@facs
                        let $idnoFacs := $locus/ancestor::t:TEI//t:msIdentifier/t:idno/@facs
                        let $tilesources :=
                        (:                        gallica :)
                        if (contains($idnoFacs, 'gallica')) then
                            let $iiif := replace($idnoFacs, '/ark:', '/iiif/ark:')
                            return
                                if ($locus/@from and $locus/@to) then
                                    let $from := viewItem:locusrv($locus/@from)
                                    let $to := viewItem:locusrv($locus/@to)
                                    let $count := (number($to) - number($from)) * 2
                                    let $tiles := for $tile in 0 to (xs:integer($count) + 1)
                                    return
                                        '"' || concat($iiif, '/f', (xs:integer(substring-after($f, 'f')) + $tile), '/info.json') || '"'
                                    return
                                        string-join($tiles, ', ')
                                else
                                    if ($locus/@from and not($locus/@to))
                                    then
                                        concat('"', $iiif, '/', $locus/@facs, '/info.json', '"')
                                    else
                                        if ($locus/@target) then
                                            let $targets := viewItem:makeSequence($locus/@target)
                                            let $tiles := for $t in $targets
                                            return
                                                '"' || concat($iiif, '/', $t, '/info.json') || '"'
                                            return
                                                string-join($tiles, ', ')
                                        else
                                            ()

                                            (:                         bm server , EthioSpare          :)
                        else
                            if (matches($idnoFacs, '\w{3}/\d{3}/\w{3,4}-\d{3}')) then
                                let $iiif := $idnoFacs
                                let $fullIIIF := concat('/iiif/', $idnoFacs)
                                (:                        expected format: of //t:TEI//t:msIdentifier/t:idno/@facs is : BMQ/003/BMQM-003 where the
                                    first folder is the institution folder, then there is the number of the manuscript and the prefix of the photos which must have been converted to .tif
                                    :)
                                return
                                    if ($locus/@from and $locus/@to) then
                                        let $from := viewItem:locusrv($locus/@from)
                                        let $to := viewItem:locusrv($locus/@to)
                                        let $count := (number($to) - number($from)) * 2
                                        let $tiles := for $tile in 0 to (xs:integer($count) + 1)
                                        return
                                            '"' || concat($fullIIIF, '_', format-number((xs:integer($f) + $tile), '000'), '.tif/info.json') || '"'
                                        return
                                            string-join($tiles, ', ')
                                    else
                                        if ($locus/@from and not($locus/@to))
                                        then
                                            '"' || concat($fullIIIF, '_', $locus/@facs, '.tif/info.json') || '"'
                                        else
                                            if ($locus/@target)
                                            then
                                                let $targets := for $t in viewItem:makeSequence($locus/@facs)
                                                return
                                                    '"' || concat($fullIIIF, '_', $t, '.tif/info.json') || '"'
                                                return
                                                    string-join($targets, ', ')
                                            else
                                                ()

                                                (:                         bm server EMIP     and Laurenziana                 :)
                            else
                                if (matches($idnoFacs, 'EMIP/Codices/\d+/') or matches($idnoFacs, 'Laurenziana')) then
                                    let $iiif := $idnoFacs
                                    let $fullIIIF := concat('/iiif/', $idnoFacs)
                                    return
                                        if ($locus/@from and $locus/@to) then
                                            let $from := viewItem:locusrv($locus/@from)
                                            let $to := viewItem:locusrv($locus/@to)
                                            let $count := (number($to) - number($from)) * 2
                                            let $tiles := for $tile in 0 to (xs:integer($count) + 1)
                                            return
                                                '"' || concat($fullIIIF, format-number((xs:integer($f) + $tile), '000'), '.tif/info.json') || '"'
                                            return
                                                string-join($tiles, ', ')
                                        else
                                            if ($locus/@from and not($locus/@to))
                                            then
                                                '"' || concat($fullIIIF, string($locus/@facs), '.tif/info.json') || '"'
                                            else
                                                if ($locus/@target)
                                                then
                                                    let $targets := for $t in viewItem:makeSequence($locus/@facs)
                                                    return
                                                        '"' || concat($fullIIIF, ., '.tif/info.json') || '"'
                                                    return
                                                        string-join($targets, ', ')
                                                else
                                                    ()

                                                    (:                         images infos are at
                                            http://digi.vatlib.it/iiifimage/MSS_Vat.et.1/Vat.et.1_0003.jp2/info.json

                                        http://digi.vatlib.it/iiif/MSS_Vat.et.1/manifest.json
                                        http://digi.vatlib.it/mss/detail/Vat.et.1
                                        as for gallica many assumptions are made, which could be avoided using jquery to build the viewer instead of this xslt script.
                                                       :)
                                else
                                    if (contains($idnoFacs, 'vatlib')) then
                                        let $msname := substring-after(substring-before($idnoFacs, 'manifest.json'), 'MSS_')
                                        let $iiif := concat('https://digi.vatlib.it/iiifimage/MSS_', $msname, substring-before($msname, '/'), '_')
                                        return
                                            if (($locus/@from and $locus/@to) and (matches($locus/@from, '\d') and matches($locus/@to, '\d'))) then
                                                let $from := viewItem:locusrv($locus/@from)
                                                let $to := viewItem:locusrv($locus/@to)
                                                let $count := (number($to) - number($from)) * 2
                                                let $tiles := for $x in 0 to (xs:integer($count))
                                                return
                                                    concat('&#34;', $iiif, format-number((xs:integer($f) + $x), '0000'), '.jp2/info.json', '&#34;')
                                                return
                                                    string-join($tiles, ', ')
                                            else
                                                if ($locus/@from and not($locus/@to) and matches($locus/@from, '\d'))
                                                then
                                                    '"' || concat($iiif, $locus/@facs, '.jp2/info.json') || '"'
                                                else
                                                    if ($locus/@target and matches($locus/@target, '\d'))
                                                    then
                                                        let $targets := for $t in viewItem:makeSequence($locus/@target)
                                                        return
                                                            '"' || concat($iiif, ., '.jp2/info.json') || '"'
                                                        return
                                                            string-join($targets, ', ')
                                                    else
                                                        ()

                                    else
                                        ('I do not know where these images come from')
                        let $openseadragonjsid := 'openseadragon' || replace($locus/@facs, ' ', '_') || $locus/ancestor::t:*[@xml:id][1]/@xml:id
                        let $openseadragonjs := 'OpenSeadragon({
                           id: "openseadragon' || $openseadragonjsid || '",
                           prefixUrl: "../resources/openseadragon/images/",
                           preserveViewport: true,
                           visibilityRatio:    1,
                           minZoomLevel:       1,
                           defaultZoomLevel:   1,"' || (if (($locus/@from and $locus/@to) or $locus/@target[contains(., ' ')]) then
                            '    sequenceMode:      true, '
                        else
                            ()) || 'tileSources:   [' ||
                        $tilesources
                        ||
                        ' ]
                           });'
                        return
                            (<p
                                class="w3-panel w3-red">
                                <a
                                    href="{$manifest}"
                                    target="_blank">
                                    <img
                                        src="/resources/images/iiif.png"
                                        width="20px"/>
                                </a>
                                <a
                                    href="{$mirador}"
                                    target="_blank">Open with Mirador Viewer</a>
                            </p>,
                            <div
                                id="{$openseadragonjsid}"/>,
                            <script
                                type="text/javascript">
                                {$openseadragonjs}
                            </script>
                            )
                    }
                </div>
            </div>
        </div>

};

declare %private function viewItem:matchinglb($locus) {
    let $mainID := viewItem:mainID($locus)
    let $modalid := viewItem:imagesID($locus, 'id', $locus/@*, '')
    let $iiifbase := $config:appUrl || 'iiif/'
    let $values := ($locus/string(@from), $locus/string(@to), tokenize($locus/@target, '#'))
    let $ranges := for $v in $values[string-length() ge 1]
    let $FromToTarget := replace($v, '\s', '')
    return
        <val>
            <pos>{$locus/position()}</pos>
            {viewItem:breakdownRef($FromToTarget)}
        </val>
    return
        <div
            class="w3-modal"
            id="{$modalid}">
            <!-- Modal content-->
            <div
                class="w3-modal-content">
                <header
                    class="w3-container">
                    <h4>Images relevant for {string-join($values[string-length() ge 1], ', ')}</h4>
                    <button
                        class="w3-button w3-gray w3-display-topright"
                        onclick="document.getElementById('{$modalid}').style.display='none'">Close</button>
                    <p>Click on the image to see the relevant page in Mirador viewer.</p>
                </header>
                <div
                    class="w3-container">{
                        let $file := $locus/ancestor::t:TEI
                        let $location := tokenize($file//t:msIdentifier/t:idno/@facs/string(), '/')
                        for $range in $ranges/*:val
                        let $nextpos := (xs:integer($range/*:pos) + 1)
                        let $prevpos := (xs:integer($range/*:pos) - 1)
                        let $next := $ranges//*:val[*:pos = $nextpos]
                        let $prev := $ranges//*:val[*:pos = $prevpos]
                        let $f := $ranges//*:folio
                        let $s := $ranges//*:side
                        let $c := $ranges//*:col
                        let $l := $ranges//*:line
                        let $fs := ($f || $s)
                        let $nf := $next//*:folio
                        let $ns := $next//*:side
                        let $nc := $next//*:col
                        let $nl := $next//*:line
                        let $nfs := ($nf || $ns)
                        let $pf := $prev//*:folio
                        let $ps := $prev//*:side
                        let $pc := $prev//*:col
                        let $pl := $prev//*:line
                        let $pfs := ($pf || $ps)
                        return
                            if (($f = $pf) and ($s = $ps)) then
                                ()
                            else
                                let $url := if ($l and $file//t:lb[@n = $l/text()][starts-with(@facs, '#facs_')][preceding-sibling::t:cb[1][@n = $c]][preceding-sibling::t:pb[1][@n = $fs]]) then
                                    let $matchingPageBreak := $file//t:lb[@n = $l/text()][starts-with(@facs, '#facs_')][preceding-sibling::t:cb[1][@n = $c]][preceding-sibling::t:pb[1][@n = $fs]]
                                    let $nextMatchingPageBreak := $file//t:lb[@n = $nl/text()][starts-with(@facs, '#facs_')][preceding-sibling::t:cb[1][@n = $nc]][preceding-sibling::t:pb[1][@n = $nfs]]
                                    let $matchingLine := $file//t:zone[@rendition = 'Line'][@xml:id = substring-after($matchingPageBreak/@facs, '#')]
                                    let $m := substring-after($nextMatchingPageBreak/@facs, '#')
                                    let $nextMatchingLine := if ($f = $nf and ($c = $nc or $s = $ns)) then
                                        $file//t:zone[@rendition = 'Line'][@xml:id = $m]
                                    else
                                        ()
                                    let $locationclean := string-join($location[position() lt last()], '/')
                                    let $filename := string($matchingLine/ancestor-or-self::t:surface[1]/t:graphic/@url)
                                    let $regionX := string($matchingLine/@ulx)
                                    let $regionY := string($matchingLine/@uly)
                                    let $regionW := (if ($nextMatchingLine) then
                                        $nextMatchingLine/@lrx
                                    else
                                        $matchingLine/@lrx) - $matchingLine/@ulx
                                    let $regionZ := (if ($nextMatchingLine) then
                                        $nextMatchingLine/@lry
                                    else
                                        $matchingLine/@lry) - $matchingLine/@uly
                                    let $region := string-join(($regionX, $regionY, $regionW, $regionZ), ',')
                                    return
                                        concat($iiifbase, $locationclean, '/', $filename, '/', $region, '/full/0/default.jpg')

                                else
                                    if ($c and $file//t:cb[@n = $c][starts-with(@facs, '#facs_')][preceding-sibling::t:pb[1][@n = $fs]]) then
                                        let $matchingColumnBreak := $file//t:cb[@n = $c][starts-with(@facs, '#facs_')][preceding-sibling::t:pb[1][@n = $fs]]
                                        let $nextMatchingColBreak := ($file//t:cb[@n = $nc][preceding-sibling::t:pb[1][@n = $nfs]])[1]
                                        let $m := substring-after($matchingColumnBreak[1]/@facs, '#')
                                        let $n := substring-after($nextMatchingColBreak[1]/@facs, '#')
                                        let $matchingCol := $file//t:zone[@rendition = 'TextRegion'][@xml:id = $m]
                                        let $nextMatchingCol := if ($f = $nf and ($c = $nc or $s = $ns)) then
                                            $file//t:zone[@rendition = 'TextRegion'][@xml:id = $n]
                                        else
                                            ()
                                        let $locationclean := string-join($location[position() lt last()], '/')
                                        let $filename := string($matchingCol/ancestor-or-self::t:surface[1]/t:graphic/@url)
                                        let $regionX := string($matchingCol/@ulx)
                                        let $regionY := string($matchingCol/@uly)
                                        let $regionW := (if ($nextMatchingCol) then
                                            $nextMatchingCol/@lrx
                                        else
                                            $matchingCol/@lrx) - $matchingCol/@ulx
                                        let $regionZ := (if ($nextMatchingCol) then
                                            $nextMatchingCol/@lry
                                        else
                                            $matchingCol/@lry) - $matchingCol/@uly
                                        let $region := string-join(($regionX, $regionY, $regionW, $regionZ), ',')
                                        return
                                            concat($iiifbase, $locationclean, '/', $filename, '/', $region, '/full/0/default.jpg')
                                    else
                                        if ($s and $file//t:pb[@n = $fs][starts-with(@facs, '#facs_')]) then
                                            let $matchingPageBreak := $file//t:pb[@n = $fs][starts-with(@facs, '#facs_')]
                                            let $m := substring-after($matchingPageBreak/@facs, '#')
                                            let $matchingImage := ($file//t:facsimile[@xml:id = $m] | $file//t:surface[@xml:id = $m])
                                            let $locationclean := string-join($location[position() lt last()], '/')
                                            let $filename := string($matchingImage/(self::t:surface | child::t:surface)/t:graphic/@url)
                                            return
                                                concat($iiifbase, $locationclean, '/', $filename, '/full/full/0/default.jpg')
                                        else
                                            ()

                                let $FromToTarget := string-join($range//text()[not(parent::*:pos)])
                                let $firstcanvas := concat('https://betamasaheft.eu/manuscripts/', $mainID, '/viewer?FirstCanv=https://betamasaheft.eu/api/iiif/', $mainID, '/canvas/p', $f)
                                return
                                    (<p>{viewItem:parseRef($FromToTarget)}</p>,
                                    <a
                                        href="{$firstcanvas}"
                                        target="_blank">
                                        <img
                                            src="{$url}"
                                            alt="Extract from {$location} for {$FromToTarget}"
                                            style="max-width:100%"/>
                                    </a>
                                    )
                    }</div>
            </div>
        </div>
};


declare %private function viewItem:locusrv($att) {
    if (contains($att, 'r')) then
        substring-before($att, 'r')
    else
        if (contains($att, 'v')) then
            (substring-before($att, 'v'))
        else
            string($att)
};

declare %private function viewItem:choosefacsorlb($locus, $ancID) {
    if ($locus/@facs) then
        attribute onclick {viewItem:imagesID($locus, 'call', $locus/@facs, $ancID)}
    else
        if ($locus/ancestor::t:TEI//t:div[@xml:id = 'Transkribus']) then
            attribute onclick {viewItem:imagesID($locus, 'call', $locus/@*, '')}
        else
            (attribute class {'w3-tooltip'},
            <span style="position:absolute;left:0;bottom:16px"
                class="w3-text w3-tag w3-dark-grey w3-tiny">check the viewer</span>)
};


declare %private function viewItem:VisColl($collation) {
    let $xslt := 'xmldb:exist:///db/apps/BetMasWeb/xslt/collationAlone.xsl'
    let $parameters := <parameters>
        <param
            name="mainID"
            value="{string($collation/ancestor::t:TEI/@xml:id)}"></param>
        <param
            name="porterified"
            value="."/>
        <param
            name="folio"
            value="1"/>
        <param
            name="currentpos"
            value="1"/>
        <param
            name="rend"
            value="."/>
        <param
            name="from"
            value="."/>
        <param
            name="to"
            value="."/>
        <param
            name="prec"
            value="."/>
        <param
            name="count"
            value="."/>
        <param
            name="singletons"
            value="."/>
        <param
            name="step1ed"
            value="."/>
        <param
            name="step2ed"
            value="."/>
        <param
            name="step3ed"
            value="."/>
        <param
            name="Finalvisualization"
            value="."/>
    </parameters>
    let $transformation := try {
        transform:transform($collation, $xslt, $parameters)
    } catch * {
        <error>{$err:description}</error>
    }
    return
        if ($transformation/error) then
            <p>Sorry, an error happened and we could not transform the file you want to look at at the moment.</p>
        else
            $transformation
};

declare %private function viewItem:date($date) {
    if (matches($date, '\d{4}-\d{2}-\d{2}')) then
        format-date(xs:date($date), '[D]-[M]-[Y0001]', 'en', 'AD', ())
    else
        if (matches($date, '\d{4}-\d{2}')) then
            let $monthnumber := substring-after($date, '-')
            let $monthname := switch ($monthnumber)
                case '01'
                    return
                        'January'
                case '02'
                    return
                        'February'
                case '03'
                    return
                        'March'
                case '04'
                    return
                        'April'
                case '05'
                    return
                        'May'
                case '06'
                    return
                        'June'
                case '07'
                    return
                        'July'
                case '08'
                    return
                        'August'
                case '09'
                    return
                        'September'
                case '10'
                    return
                        'October'
                case '11'
                    return
                        'November'
                case '12'
                    return
                        'December'
                default return
                    ()
        return
            concat(replace(substring-after($date, '-'), $monthnumber, $monthname), ' ', substring-before($date, '-'))
    else
        format-number($date, '####')
};

declare %private function viewItem:notBnotA($element) {
    let $prefix := if (not($element/@notBefore)) then
        'Before '
    else
        if (not($element/@notAfter)) then
            'After'
        else
            ()
    let $nB := if ($element/@notBefore) then
        viewItem:date($element/@notBefore)
    else
        ()
    let $minus := if ($element/@notBefore and $element/@notAfter) then
        '–'
    else
        ()
    let $nA := if ($element/@notAfter) then
        viewItem:date($element/@notAfter)
    else
        ()
    return
        $prefix || $nB || $minus || $nA
};

declare %private function viewItem:datepicker($element) {
    (if ($element/@notBefore or $element/@notAfter) then
        viewItem:notBnotA($element)
    else
        viewItem:date($element/@when)
    ,
    if ($element/@cert) then
        concat(' (certainty: ', $element/@cert, ')')
    else
        ()
    )
};
declare %private function viewItem:sup($t) {
    if ($t/@xml:lang) then
        <sup>{string($t/@xml:lang)}</sup>
    else
        ()
};

declare %private function viewItem:correspTit($t, $id) {
    let $cors := $t/parent::t:titleStmt/t:title[substring-after(@corresp, '#') = $id]
    let $count := count($cors)
    for $corresp at $p in $cors
    return
        (viewItem:TEI2HTML($corresp), viewItem:sup($corresp),
        if ($p = $count) then
            ()
        else
            ', ')
};

declare %private function viewItem:worktitle($t) {
    let $id := string($t/@xml:id)

    return
        <li
            property="http://purl.org/dc/elements/1.1/title">
            {
                attribute {'xml:id'} {$id},
                if ($t/@type) then
                    concat(string($t/@type), ': ')
                else
                    (),
                if ($t/@ref) then
                    <a
                        href="{$config:appUrl}/{viewItem:URI2ID($t/@ref)}"
                        target="_blank">{$t/text()}</a>
                else
                    viewItem:TEI2HTML($t/node()),
                viewItem:sup($t),
                if ($t/parent::t:titleStmt/t:title[substring-after(@corresp, '#') = $id]) then
                    (' (', viewItem:correspTit($t, $id), ')')
                else
                    ()
            }
        </li>
};
declare %private function viewItem:placename($name) {
 let $id := string($name/@xml:id)
 let $cors := $name/parent::t:place/t:placeName[substring-after(@corresp, '#') = $id]
 let $count := count($cors)
    return
        <li>
            {
                attribute {'xml:id'} {$id},
                if ($name/@type) then
                    concat(string($name/@type), ': ')
                else
                    (),
                if ($name/@ref) then
                    <a
                        href="{$config:appUrl}/{viewItem:URI2ID($t/@ref)}"
                        target="_blank">{$name/text()}</a>
                else
                    viewItem:TEI2HTML($name/node()),
                viewItem:sup($name),
                if ($name/parent::t:place/t:placeName[@corresp]) then
                    (' (',
    for $corresp at $p in $cors
    return
        (viewItem:TEI2HTML($corresp), viewItem:sup($corresp),
        if ($p = $count) then
            ()
        else
            ', ')
, ')')
                else
                    ()
            }
        </li>
};

declare %private function viewItem:persname($name) {
    let $id := string($name/@xml:id)
    return
        <li>
            {
                attribute {'xml:id'} {$id},
                if ($name/@type) then
                    concat(string($name/@type), ': ')
                else
                    (),
                if ($name/@ref) then
                    <a
                        href="{$config:appUrl}/{viewItem:URI2ID($name/@ref)}"
                        target="_blank">{$name/text()}</a>
                else
                    viewItem:TEI2HTML($name/node()),
                viewItem:sup($name),
                 if ($name/parent::t:person/t:persName[@corresp]) then
                    (' (', viewItem:correspN($name, $id), ')')
                else
                    if ($name/parent::t:persGroup/t:persName[@corresp]) then
                    (' (', viewItem:correspN($name, $id), ')')
                else
                    ()
            }
        </li>
};
declare %private function viewItem:correspN($name, $id) {
    let $cors := $name/parent::t:listPerson//t:persName[substring-after(@corresp, '#') = $id]
    let $count := count($cors)
    for $corresp at $p in $cors
    return
        (viewItem:TEI2HTML($corresp), viewItem:sup($corresp),
        if ($p = $count) then
            ()
        else
            ', ')
};
declare %private function viewItem:makeSequence($attribute) {
let $string := normalize-space($attribute) return
    if (contains($string, ' ')) then
        tokenize($string, ' ')
    else
        string($attribute)
};

declare %private function viewItem:workAuthorList($parentname, $p, $a) {
    let $filename := viewItem:URI2ID($p)
    return
    ($parentname,
    <a
        href="{$config:appUrl}/{$filename}"
        class="persName">
        {exptit:printTitle($p)}
    </a>,
    if ($a/@name = 'saws:isAttributedToAuthor') then
        (' ',
        <span
            class="w3-tag w3-round-large w3-red">attributed</span>)
    else
        (),
        <a
            id="{generate-id($a)}Ent{$filename}relations">

            <span
                class="glyphicon glyphicon-hand-left"/>
        </a>,
    '.',
    if ($a/t:desc) then
        viewItem:TEI2HTML($a/t:desc)
    else
        ()
    )
};

declare %private function viewItem:URI2ID($string) {
    let $string := normalize-space(string-join($string)) => replace('\s', '')
    return
        if (starts-with($string, $config:appUrl)) then
            substring-after($string, ($config:appUrl || '/'))
        else
            $string
};

declare %private function viewItem:ID2URI($string) {
    if (starts-with($string, $config:appUrl)) then
        $string
    else
        $config:appUrl || '/' || $string
};

declare %private function viewItem:workAuthLi($a, $aorp) {
    let $parentname := viewItem:parentLink($a)
    let $att := if ($aorp = 'a') then
        $a/@active
    else
        $a/@passive
    let $ps := viewItem:makeSequence($att)
    return
        for $p in $ps
        return
            <li>{viewItem:workAuthorList($parentname, $p, $a)}</li>
};


declare %private function viewItem:personAuthLi($a, $aorp) {
    let $parentname := viewItem:parentLink($a)
    let $att := if ($aorp = 'a') then
        $a/@active
    else
        $a/@passive
    let $ps := viewItem:makeSequence($att)
    return
        for $p in $ps
        return
            <li>{viewItem:persRelList($parentname, $p, $a)}</li>
};

declare %private function viewItem:persRelList($parentname, $p, $a) {
    let $filename := viewItem:URI2ID($p)
    return
     ($parentname,
    <a
        href="{viewItem:TEI2HTML($p)}">
        {exptit:printTitle($p)}
     </a>,
  <a
            id="{generate-id($a)}Ent{$filename}relations">

            <span
                class="glyphicon glyphicon-hand-left"/>
        </a>,
    '.',
    if ($a/t:desc) then
        viewItem:TEI2HTML($a/t:desc)
    else
        ()
    )
};

declare %private function viewItem:parentLink($node) {
    if ($node/ancestor::t:div[@xml:id]) then
        let $href := '/text/' || string($node/ancestor::t:TEI/@xml:id) || '#' || string($node/ancestor::t:div[@xml:id][1]/@xml:id)
        return
            (<a
                class="page-scroll"
                target="_blank"
                href="{$href}">
                {exptit:printTitle($node/ancestor::t:div[@xml:id][1]/@xml:id)}
            </a>, ': ')
    else
        ()
};

declare %private function viewItem:headercontext($node) {
    if ($node/ancestor::t:msPart[1]) then
        (' of codicological unit ',
        <a
            href="#{$node/ancestor::t:msPart[1]/@xml:id}">
            {substring-after($node/ancestor::t:msPart[1]/@xml:id, 'p')}</a>)
    else
        (), ' ',
    if ($node/ancestor::t:msItem[1]) then
        (', item ',
        <a
            href="#{$node/ancestor::t:msItem[1]/@xml:id}">
            {substring-after($node/ancestor::t:msItem[1]/@xml:id, 'i')}</a>)
    else
        (), ' ',
    if ($node/@corresp) then
        let $cors := viewItem:makeSequence($node/@corresp)
        let $file := $node/ancestor::t:TEI
        let $items := for $c in $cors
        let $id := if (contains($c, '#')) then
            substring-after($c, '#')
        else
            viewItem:URI2ID($c)
        let $item := $file/t:*[@xml:id = $c]
        let $text := if ($item/text()) then
            $item/text()
        else
            if ($item/name() = 'listWit') then
                viewItem:TEI2HTML($item)
            else
                exptit:printTitle($c)
        let $lang := if ($item/@xml:lang) then
            concat(' [', $file//t:language[@ident = $item/@xml:lang], ']')
        else
            ()
        return
            <a
                href="{$config:appUrl}/{viewItem:URI2ID($c)}">{$text}
                {$lang}</a>
        return
            ('(about:', $items, ')')
    else
        ()
};

declare %private function viewItem:biblioHeader($listBibl) {
    for $t in $listBibl/@type
    return
        concat(concat(upper-case(substring(string($t), 1, 1)), substring($t, 2), ' '[not(last())]), ' Bibliography'),
    viewItem:headercontext($listBibl)
};

declare %private function viewItem:bibliographyHeader($listBibl) {
    if ($listBibl/ancestor::t:note) then
        viewItem:TEI2HTML($listBibl)
    else
        if ($listBibl[not(parent::t:item) and not(ancestor::t:physDesc)]) then
            <p class="w3-text-white">{
                    if ($listBibl/@type = 'catalogue') then
                        attribute id {string($listBibl/@type)}
                    else
                        ()
                }
                {viewItem:biblioHeader($listBibl)}
                </p>
                else ()
};

declare %private function viewItem:zot($c) {
    let $xml-url-formattedBiblio := concat('https://api.zotero.org/groups/358366/items?tag=', $c, '&amp;format=bib&amp;locale=en-GB&amp;style=hiob-ludolf-centre-for-ethiopian-studies-with-url-doi&amp;linkwrap=1')
   let $data := try{let $request := <http:request href="{xs:anyURI($xml-url-formattedBiblio)}" method="GET"/>
                               return http:send-request($request)[2]} catch *{$err:description}
    let $datawithlink := $data//*:div[@class = 'csl-entry']
    return
        $datawithlink
};

declare %private function viewItem:bibl($node, $t) {
    <div
        class="w3-row">
        <div
            class="w3-col"
            style="width:85%">
            <span
                class="Zotero Zotero-full"
                data-value="{$t}"
                data-type="{$node/t:seg/@type}">
                {let $bib := $viewItem:bibliography//b:entry[@id = $t]/b:reference/*:div/node()
                return if(count($bib) ge 1 ) then $bib else viewItem:zot($t)
                }
                {
                    let $crs := for $cr in $node/t:citedRange
                    return
                        (string($cr/@unit) || ' ' || $cr/text())
                    return
                        ' ' || string-join($crs, ', ')
                }
                {viewItem:TEI2HTML($node/t:note[@type = 'about'])}
                {viewItem:TEI2HTML($node/t:ref[@target])}
                {viewItem:TEI2HTML($node/t:note[not(@type)])}
            </span>

        </div>
        <div
            class="w3-rest">
            <span
                class="w3-bar-block w3-hide-small w3-hide-medium">
                <a
                    class="w3-bar-item w3-button w3-tiny"
                    target="_blank"
                    href="{$node/@corresp}">Zotero</a>
                <a
                    class="w3-bar-item w3-button w3-tiny"
                    href="{$config:appUrl}/bibliography?pointer={$t}">Other citations</a>

            </span>
        </div>
    </div>
};

declare %private function viewItem:bibliographyitem($node) {
    if ($node[not(@corresp) and not(t:ptr[@target])]) then
        <b
            style="color:red;">THIS BIBLIOGRAPHIC RECORD ({$node}) has no @corresp or t:ptr/@target. Please check the
            schema error report to fix it.</b>
    else
        if ($node[@corresp and not(t:ptr[@target])]) then
            (
            let $cors := viewItem:makeSequence($node/@corresp)
            for $c in $cors
            return
                <a
                    href="{$c}">{exptit:printTitle($c)}</a>,
            $node/text(),
            viewItem:TEI2HTML($node/t:date),
            viewItem:TEI2HTML($node/t:note)
            )
        else
            if ($node/t:ptr/@target = 'bm:EthioSpare' and $node/parent::t:listBibl[@type = 'catalogue'])
            then
                viewItem:EthioSpareFormatter($node)
            else
                let $t := $node/t:ptr/@target
                return
                    if ($node/parent::t:surrogates)
                    then
                        <p>{viewItem:bibl($node, $t)}</p>
                        else
                        if ($node/parent::t:witness) then
                            <span>
                                {$viewItem:bibliography//b:entry[@id = $t]/b:citation/node()}
                            </span>
                    else
                        if ($node/parent::t:listBibl[not(ancestor::t:note)]) then
                            <li
                                class="bibliographyItem">
                                {viewItem:bibl($node, $t)}
                                <hr/>
                            </li>
                        else
                            $viewItem:bibliography//b:entry[@id = $t]/b:citation/node()

};

declare %private function viewItem:EthioSpareFormatter($node) {
    let $t := $node/t:ptr/@target
    let $TEI := $node/ancestor::t:TEI
    let $BMsignature := $TEI//t:idno[preceding-sibling::t:collection[. = 'Ethio-SPaRe']]
    let $domliblist := $viewItem:domlib//item[signature = $BMsignature]/domlib
    let $cataloguer := if ($TEI//t:editor[@role = 'cataloguer'])
    then
        $TEI//t:editor[@role = 'cataloguer']/text()
    else
        if ($TEI//t:editor[not(@role = 'generalEditor')])
        then
            $TEI//t:editor[not(@role = 'generalEditor')]/text()
        else
            let $resp := substring-after(($TEI//t:change[contains(., 'created')]/@who)[1], '#')
            return
                string-join(distinct-values(($TEI//t:editor[@key = $resp]/text() | $TEI//t:respStmt[@xml:id = $resp]/t:name/text())), ', ')
    let $repository := $TEI//t:repository/text()
    let $date := for $d in $TEI//t:origDate return viewItem:dates($d)
    let $title := $TEI//t:titleStmt/t:title[1]/text()
    return
        (<a
            href="https://mycms-vs03.rrz.uni-hamburg.de/domlib/receive/{$domliblist}">MS {$repository}, Ethio-SPaRe {$BMsignature}
            , catalogued by {$cataloguer}</a>, ' in ',
        $viewItem:bibliography//b:entry[@id = $t]/b:reference/node())
};

declare %private function viewItem:relation($node) {
    (<a
        href="{viewItem:reflink($node/@active)}">{exptit:printTitle($node/@active)}</a>, ' ',
    <a
        href="{viewItem:reflink($node/@ref)}">
        <code>{string($node/@name)}</code>
    </a>, ' ',
    <a
        href="{viewItem:reflink($node/@passive)}">{exptit:printTitle($node/@passive)}</a>, ' ',
    viewItem:TEI2HTML($node/t:desc)
    )
};

declare %private function viewItem:publicationStmt($node) {
    <div
        class="w3-container w3-small w3-responsive" style="overflow-x:auto;"
        id="publicationStmt">
        <h3>Publication Statement</h3>
        {
            for $n in $node/node()
            return
                <div
                    class="w3-row">
                    <div
                        class="w3-col"
                        style="width:80px;">{$n/name()}</div>
                    <div
                        class="w3-col"
                        style="width:110px;">{
                            for $att in $n/@* return $att/name() || '=' || $att/data()
                        }</div>
                    <div
                        class="w3-rest" style="overflow-x:auto; vertical-align: text-top; text-align: left;">{viewItem:TEI2HTML($n)}</div>
                </div>
        }
    </div>
};

declare %private function viewItem:ref($ref) {
    if ($ref/text()) then
        (
        if ($ref/@cRef) then
            if (starts-with($ref/@cRef, 'urn:cts')) then
                <a
                    href="http://data.perseus.org/citations/{$ref/@cRef}">
                    <i
                        class="fa fa-angle-double-right"/>{$ref/text()}<i
                        class="fa fa-angle-double-right"/>
                </a>
            else
                <a
                    class="reference"
                    href="{$config:appUrl}/{substring-after($ref/@cRef, 'betmas:')}"
                    target="_blank">
                    {$ref/text()}
                    <i
                        class="fa fa-file-text-o"
                        aria-hidden="true"/>
                </a>
        else
            if ($ref/@corresp) then
                for $c in viewItem:makeSequence($ref/@corresp)
                return
                    (<a
                        href="{$config:appUrl}/{viewItem:URI2ID($c)}">{$ref/text()}</a>,
                    let $relsid := generate-id($ref)
                    return
                        <a
                            id="{$relsid}Ent{viewItem:URI2ID($c)}relations">
                            <span
                                class="glyphicon glyphicon-hand-left"/>
                        </a>
                    )
            else
                if ($ref/@target) then
                    for $t in viewItem:makeSequence($ref/@target)
                    return
                        if (starts-with($t, '#')) then
                            let $id := $ref/ancestor::t:TEI/@xml:id
                            let $anchor := substring-after($t, '#')
                            let $node := $ref/ancestor::t:TEI/id($anchor)
                            return
                                <a
                                    href="{$config:appUrl}/{$id}#{$anchor}">
                                    {$ref/text()}</a>
                        else
                            if (starts-with($t, 'http')) then
                                <a
                                    href="{$t}">
                                    {$ref/text()}</a>
                            else
                                <a
                                    href="{$config:appUrl}/{$t}">{$ref/text()}</a>
                else
                    ()
        )
    else
        if ($ref/@cRef) then
            if (starts-with($ref/@cRef, 'urn:cts')) then
                <a
                    href="http://data.perseus.org/citations/{$ref/@cRef}">
                    <i
                        class="fa fa-angle-double-right"/>ref<i
                        class="fa fa-angle-double-right"/>
                </a>
            else
                <a
                    class="reference"
                    href="{substring-after($ref/@cRef, 'betmas:')}"
                    target="_blank">
                    <i
                        class="fa fa-file-text-o"
                        aria-hidden="true"/>
                </a>
        else
            if ($ref/@corresp) then
                for $c in viewItem:makeSequence($ref/@corresp)
                return
                    (<a
                        href="{$config:appUrl}/{viewItem:URI2ID($c)}">{exptit:printTitle($c)}</a>,
                    let $relsid := generate-id($ref)
                    return
                        <a
                            id="{$relsid}Ent{viewItem:URI2ID($c)}relations">
                            <span
                                class="glyphicon glyphicon-hand-left"/>
                        </a>
                    )
            else
                if ($ref/@target) then
                    for $t in viewItem:makeSequence($ref/@target)
                    return
                        if (starts-with($t, '#')) then
                            let $anchor := substring-after($t, '#')
                            let $node := $ref/ancestor::t:TEI/id($anchor)
                            return
                            if(count($node) = 1) then    <a
                                    href="{$t}">
                                    {viewItem:switchsubids($anchor, $node)}</a> else $anchor || ' not found in this file'
                        else
                            if (starts-with($t, 'http')) then
                                <a
                                    href="{$t}">
                                    {$t}</a>
                            else
                                <a
                                    href="{$t}"> [link]</a>
                else
                    ()
};

declare %private function viewItem:certainty($certainty) {
    let $match := util:eval(concat('$certainty/', $certainty/@match))/name()
    let $resp := viewItem:editorName($certainty/@resp)
    let $statement := if ($certainty[@cert and not(@resp) and not(@assertedValue)])
    then
        concat(' is ', $certainty/@cert, '.')
    else
        if ($certainty[@resp and @assertedValue])
        then
            concat(' is ', $certainty/@assertedValue, ' according to ', $resp)
        else
            if ($certainty[not(@resp) and @assertedValue])
            then
                concat(' is low. It might alternatively be ', $certainty/@assertedValue, '.')
            else
                if ($certainty[@resp and not(@assertedValue)])
                then
                    concat(' is low according to ', $resp)
                else
                    ' is not set.'
    let $desc := if ($certainty/t:desc) then
        (': ', viewItem:TEI2HTML($certainty/t:desc))
    else
        ()
    return
        <span
            class="w3-tooltip">
            <sup>[!]</sup>
            <span
                class="w3-text">The certainty about the {string($certainty/@locus)} of {$match}
                {$statement}{$desc}</span>
        </span>
};

declare %private function viewItem:footnoteptr($node) {
    let $target := $node/@target
    let $t := substring-after($node/@target, '#')
    let $note := $node/ancestor::t:TEI//t:note[@xml:id = $t]
    return
        <sup>
            <a
                href="{$node/@target}"
                id="pointer{$t}">
                {string($note/@n)}
            </a>
        </sup>
};

declare %private function viewItem:footnote($node) {
    <dl
        style="font-size:smaller;">
        {
            let $t := substring-after($node/@xml:id, '#')
            return
                (<dt>
                    <i>
                        <a
                            href="#pointer{$t}"
                            id="{$node/@xml:id}">
                            {string($node/@n)})
                        </a>
                    </i>
                </dt>,
                <dd>
                    {viewItem:TEI2HTML($node/node())}
                </dd>)
        }
    </dl>
};

declare %private function viewItem:date-like($date) {
    if ($date/@calendar) then
        let $id := generate-id($date)
        return
            (
            viewItem:dates($date),
            viewItem:time($date),
            <a
                id="date{$id}calendar"
                class="popup"
                onclick="popup('dateInfo{$id}')">
                <i
                    class="fa fa-calendar-plus-o"
                    aria-hidden="true"/>
            </a>
            )
    else
        (
        viewItem:dates($date),
        viewItem:time($date)
        )
};


declare %private function viewItem:time($date) {
    let $cal := $date/@calendar
    return
        <sup
            class="w3-tooltip">
            <i
                class="fa fa-exchange"></i>
            <span
                class="w3-text">
                {
                    for $att in ($date/@notBefore | $date/@notAfter | $date/@when | $date/@notBefore-custom | $date/@notAfter-custom | $date/@when-custom)
                    return
                        <time
                            data-calendar="{
                                    if ($cal) then
                                        $cal
                                    else
                                        'western'
                                }">
                            {
                                if (string-length($att) = 4) then
                                    attribute data-year {number($att)}
                                else
                                    if (string-length($att) = 7) then
                                        (attribute data-year {number(substring($att, 1, 4))}, attribute data-month {number(substring($att, 6, 2))})
                                    else
                                        if (starts-with($att, '--')) then
                                            (attribute data-month {number(substring($att, 3, 2))}, attribute data-day {number(substring($att, 6, 2))})
                                        else
                                            (attribute data-year {number(substring($att, 1, 4))},
                                            attribute data-month {number(substring($att, 6, 2))},
                                            attribute data-day {number(substring($att, 9, 2))})
                            }
                            {$att/name()}: {$att/string()}
                        </time>
                }</span>
        </sup>
};

declare %private function viewItem:witness($witness) {
    <li><a
            href="{
                    if ($witness/@type = 'external' and $witness/@facs) then
                        $witness/@facs
                    else
                        $witness/@corresp
                }"
            property="http://purl.org/dc/elements/1.1/source"
            resource="{$witness/@corresp}">
            {
                if ($witness/@xml:id) then
                    attribute id {$witness/@xml:id}
                else
                    ()
            }
            {
                if ($witness/@facs) then
                    attribute data-location {$witness/@facs}
                else
                    ()
            }
            {
                if ($witness/t:ptr/@target) then
                    attribute data-manifest {$witness/t:ptr/@target}
                else
                    ()
            }
            {
                if ($witness/@corresp) then
                    let $witid := viewItem:URI2ID($witness/@corresp)
                    return
                        $witness//text()
                else
                    ()
            }</a>
        {
            if (contains($witness/@corresp, '#')) then
                substring-after($witness/@corresp, '#')
            else
                ()
        }
        {
            if ($witness/@type) then
                ' (' || string($witness/@type) || ')'
            else
                ()
        }
        {
            if ($witness/@cert = 'low') then
                '?'
            else
                ()
        }
        {
            if ($witness/@facs and not($witness/@type = 'external')) then
                <a
                    href="{$witness/@facs}"> [link]</a>
            else
                ()
        }
    </li>
};

declare %private function viewItem:summary($node) {
    if ($node/parent::t:decoDesc) then
        ()
    else
        let $id := string(($node/ancestor::t:*[@xml:id])[1]/@xml:id)
        return
            (<h3>Summary {viewItem:headercontext($node)}</h3>,
            <div
                class="w3-bar w3-gray">
                <button
                    class="w3-bar-item w3-button w3-half"
                    onclick="openSummary('extracted{$id}')">
                    Extracted
                </button>
                <button
                    class="w3-bar-item w3-button w3-half"
                    onclick="openSummary('given{$id}')">
                    Given
                </button>
            </div>,
            <div
                class="summaryText"
                id="given{$id}">
                {
                    if ($node/ancestor::t:TEI//@form = 'Inscription') then
                        attribute style {'display:none;'}
                    else
                        ()
                }
                {viewItem:TEI2HTML($node/node())}
            </div>,
            <div
                class="summaryText"
                id="extracted{$id}">
                {
                    if ($node/ancestor::t:TEI//@form = 'Inscription') then
                        attribute style {'display:none;'}
                    else
                        ()
                }
                <ol
                    class="summary">
                    {
                        if ($node/ancestor::t:msPart or $node/ancestor::t:msFrag)
                        then
                            for $item in $node/ancestor::t:msPart//t:msItem[not(parent::t:msItem)]
                                order by $item/position()
                            return
                                viewItem:summaryitems($item)
                        else
                            for $item in $node/ancestor::t:msDesc//t:msItem[not(parent::t:msItem)]
                                order by $item/position()
                            return
                                viewItem:summaryitems($item)
                    }
                </ol>
            </div>
            )
};

declare %private function viewItem:summaryitems($item) {
    <li>
        <a
            class="page-scroll"
            href="#{$item/@xml:id}">
            {string($item/@xml:id)}
        </a>
        ({viewItem:TEI2HTML($item/t:locus)}),
        {$item/t:title/text()}
        {if ((count($item/ancestor::t:TEI//t:msItem) gt 100) and (count($item/ancestor::t:msItem) gt 1))
                    then <p>There are {count($item/ancestor::t:TEI//t:msItem)} items in this description, to show this page we have to stop here.</p>
                    else
            if ($item/t:msItem) then
                <ol
                    class="summary">
                    {
                        for $subitem in $item/t:msItem
                            order by $subitem/position()
                        return
                            viewItem:summaryitems($subitem)
                    }
                </ol>
            else
                ()
        }
    </li>
};

declare %private function viewItem:namedEntity($entity) {
    (switch ($entity/name())
        case 'title'
            return
                viewItem:namedEntityTitle($entity)
        case 'persName'
            return
                viewItem:namedEntityPerson($entity)
        default return
            viewItem:namedEntityPlace($entity), ' ',
viewItem:lefthand($entity), ' ',
if ($entity/@evidence) then
    concat(' (', $entity/@evidence, ')')
else
    (), ' ',
if ($entity/@cert = 'low') then
    '?'
else
    ()
)
};

declare %private function viewItem:cae($entity) {
 if (contains($entity/@ref, 'NAR')) then
        ()
    else
     if (contains($entity/@ref, 'STU')) then
        ()
     else
     if (contains($entity/@ref, 'IHA')) then
        ()
    else
    let $id := viewItem:URI2ID($entity/@ref)
    return
        'CAe ' || substring($id, 4, 4) || (if (contains($id, '#')) then
            (' ' || substring-after($id, '#'))
        else
            ())
};

declare %private function viewItem:lefthand($entity) {
    let $id := viewItem:URI2ID($entity/@ref)
    return
        <span
            xmlns="http://www.w3.org/1999/xhtml"
            id="{generate-id($entity)}Ent{$id}relations"
            class="popup">
            <span
                class="fa fa-hand-o-left"/>
        </span>
};

declare %private function viewItem:namedEntityTitle($entity) {
  (:if(count($entity/ancestor::t:msItem) gt 2) then

   (string-join($entity//text()),
    if (matches($entity/@ref, 'LIT')) then
        (' (' || viewItem:cae($entity) || ')')
    else
        ()
    )
    else:)
    (
    <a target="_blank"
        xmlns="http://www.w3.org/1999/xhtml"
        href="{$config:appUrl}/{viewItem:URI2ID($entity/@ref)}">{viewItem:TEI2HTML($entity/node())}</a>,
    if (matches($entity/@ref, 'LIT')) then
        (' (' || viewItem:cae($entity) || ')')
    else
        ()
    )
};

declare %private function viewItem:namedEntityTitleNoLink($entity) {
 (concat(substring(string-join($entity//text()), 1, 30), '...'),
    (' (' || viewItem:cae($entity) || ')'), ' ',
    if ($entity/@evidence) then
        concat(' (', $entity/@evidence, ')')
    else
        (), ' ',
    if ($entity/@cert = 'low') then
        '?'
    else
        (),
    ' / '
    )
};

declare %private function viewItem:namedEntityPerson($entity) {
    (if ($entity/@ref) then
        <a
            xmlns="http://www.w3.org/1999/xhtml"
            href="{viewItem:reflink($entity/@ref)}">{viewItem:TEI2HTML($entity/node())}</a>
    else
        viewItem:TEI2HTML($entity/node()), ' ',
    if ($entity/@role) then
        string($entity/@role)
    else
        () (:,
viewItem:TEI2HTML($entity/t:note):))
};

declare %private function viewItem:namedEntityPersonNoLink($entity) {
    (<span
        xmlns="http://www.w3.org/1999/xhtml"
        class="persName"
        property="http://purl.org/dc/elements/1.1/relation"
        resource="{viewItem:reflink($entity/@ref)}">{viewItem:TEI2HTML($entity/node()[not(self::t:note)])}
    </span>,
    if ($entity/@role) then
        <sup>{concat('(', $entity/@role, ')')}</sup>
    else
        ()), ' ',
    viewItem:TEI2HTML($entity/t:note), ' ',
    if ($entity/@evidence) then
        concat(' (', $entity/@evidence, ')')
    else
        (), ' ',
    if ($entity/@cert = 'low') then
        '?'
    else
        ()
};

declare %private function viewItem:namedEntityPlace($entity) {
    (if ($entity/@type and not($entity/ancestor::t:div[@type = 'edition'])) then
        concat($entity/@type, ': ')
    else
        (),
    <a
        xmlns="http://www.w3.org/1999/xhtml"
        href="{viewItem:reflink($entity/@ref)}">{if(count($entity/node()) ge 1) then viewItem:TEI2HTML($entity/node()[not(self::t:note)][not(self::t:certainty)]) else ()}</a>,
    let $idref := viewItem:URI2ID($entity/@ref)
    return
        if (contains($idref, 'pleiades')) then
            let $pleiadesid := substring-after($idref, 'pleiades:')
            return
                <span
                    xmlns="http://www.w3.org/1999/xhtml"
                    class="pelagios popup"
                    data-pelagiosID="{encode-for-uri(concat('http://pleiades.stoa.org/places/', $pleiadesid))}"
                    data-href="https://pleiades.stoa.org/places/{$pleiadesid}"
                    data-value="{$pleiadesid}">↗</span>
        else
            if (contains($idref, 'wd')) then
                <span
                    xmlns="http://www.w3.org/1999/xhtml"
                    class="pelagios popup"
                    data-pelagiosID="{encode-for-uri(replace($idref, 'wd:', 'http://www.wikidata.org/entity/'))}"
                    data-href="https://www.wikidata.org/wiki/{replace($idref, 'wd:', '')}"
                    data-value="{$entity/@ref}">↗</span>
            else
                <span
                    xmlns="http://www.w3.org/1999/xhtml"
                    class="pelagios popup"
                    data-pelagiosID="{encode-for-uri(concat('http://betamasaheft.eu/places/', $idref))}"
                    data-href="https://betamasaheft.eu/{$idref}"
                    data-value="{$idref}">↗</span>, ' ',
    viewItem:TEI2HTML($entity/t:note), ' ',
    viewItem:TEI2HTML($entity/t:certainty), ' ',
    if (not($entity/ancestor::t:div[@type = 'edition']) and $entity[@when | @notBefore | @notAfter | @when-custom | @notBefore-custom | @notAfter-custom]) then
        if ($entity/@when) then
            (' (information recorded on: ' || viewItem:date($entity/@when) || ')')
        else
            if ($entity/@notBefore) then
                (' After: ' || viewItem:date($entity/@notBefore))
            else
                if ($entity/@notAfter) then
                    (' Before: ' || viewItem:date($entity/@notAfter))
                else
                    ()
    else
        (), ' ',
    if ($entity/@type = 'qušat') then
        ' qušat '
    else
        if ($entity/@type = 'waradā') then
            ' waradā '
        else
            ()
    )
};


declare %private function viewItem:reflink($ref) {
    let $ref := viewItem:URI2ID($ref)
    return
        if (contains($ref, ':')) then
            let $prefix := substring-before($ref, ':')
            let $suffix := substring-after($ref, ':')
            let $prefixDef := $viewItem:prefixDef//t:prefixDef[@ident = $prefix]
            return
                if (count($prefixDef) = 1)
                then
                    replace($suffix, $prefixDef/@matchPattern, $prefixDef/@replacementPattern)
                else
                    string($ref)
        else
            string($ref)
};

declare %private function viewItem:msItem($msItem) {
    let $mainID := viewItem:mainID($msItem)
    let $id := string($msItem/@xml:id)
    let $msItemsCount := count($msItem/ancestor::t:TEI//t:msItem)
    let $trimid := if ($msItem/parent::t:msContents) then
        concat(replace($id, '\.', '-'), 'N', $msItem/position())
    else
        replace($id, '\.', '-')
    return
        <div
            class="w3-container msItem"
            resource="https://betamasaheft.eu/{$mainID}/msitem/{$id}"
            typeof="https://betamasaheft.eu/msitem https://w3id.org/sdc/ontology#UniCont"
            id="{$id}">
            <button
                style="max-width:100%"
                onclick="openAccordion('item{$trimid}')"
                class="w3-button w3-gray contentItem "
                resource="https://betamasaheft.eu/{$mainID}/msitem/{$id}">
                {viewItem:namedEntityTitleNoLink($msItem/t:title)} Item {$id}
                {
                    if ($msItem/t:msItem) then
                        <span
                            class="w3-badge w3-margin-left"
                            property="http://www.cidoc-crm.org/cidoc-crm/P57_has_number_of_parts"
                            about="https://betamasaheft.eu/{$mainID}/msitem/{$id}">
                            {count($msItem/t:msItem)}
                        </span>
                    else
                        ()
                }
            </button>
            <div
                id="item{$trimid}"
                class="w3-hide msItemContent">
                <div
                    class="w3-container">
                    <hr
                        class="msItems"
                        align="left"/>
                    {
                        let $anchor := concat('#', $id)
                        return
                            if ($msItem//ancestor::t:TEI//t:div[@corresp = $anchor])
                            then
                                let $number := if ($msItem/ancestor::t:TEI//t:div[@corresp = $anchor]/@n) then
                                    $msItem/ancestor::t:TEI//t:div[@corresp = $anchor]/@n
                                else
                                    1
                                return
                                    <a
                                        role="button"
                                        class="w3-button w3-gray w3-small"
                                        href="{$config:appUrl}/manuscripts/{$mainID}/text?per-page=1&amp;start={$number}">Transcription</a>
                            else
                                ()
                    }
                    {
         (::           if ((count($msItem/ancestor::t:msItem) gt 1) and ($msItemsCount gt 100))
                    then <div><a
                    class="w3-button msitemloader"
                    data-mainID="{$mainID}"
                    data-msItem="{replace($msItem/@xml:id, '\.', '-')}">Click here to load the {count($msItem/t:msItem)} items contained in the current one.</a><div id="msitemloadcontainer{replace($msItem/@xml:id, '\.', '-')}"/></div>
                    else  ::) if ($msItem/t:msItem) then
                        (
                        viewItem:TEI2HTML($msItem/node()[not(name()='msItem')])
                        ,
                        for $m in $msItem/t:msItem
                        let $innerMsItem :=  viewItem:msItem($m)
                         return
                            <div
                                class="w3-container"
                                id="contentItem{$trimid}"
                                rel="http://purl.org/dc/terms/hasPart">{
                               $innerMsItem
                                }</div>
                                )
                        else
                            viewItem:TEI2HTML($msItem/node())
                    }
                </div>
            </div>
        </div>
};

declare %private function viewItem:figure($figure as element(t:figure)) {
    let $link := $figure/t:graphic/@url
    let $height := $figure/t:graphic/@height
    let $url := concat('https://betamasaheft.eu/iiif/', $link, '/info.json')
    let $uri := concat('https://betamasaheft.eu/iiif/', $link)
    let $mainID := $figure/ancestor::t:TEI/@xml:id
    let $id := concat($mainID, 'graphic')
    return

     (:  if the link ends with .svg :)
 if (matches($link, "\.svg$")) then
 <div id="{$id}" style="height:{if ($height) then $height else '100%'}">
            {doc($link) }
            <div class="caption w3-margin-left w3-tiny">
              {viewItem:TEI2HTML($figure/t:graphic/t:desc)}
            </div>
          </div>

  else if (contains($link, 'http')) then
                <div
                    id="{$id}">
                    <span><a href="{$link}"><img src="{$link}" style="height:{$height}"/></a></span>
                <div
                    class="caption w3-margin-left w3-tiny">
                    {viewItem:TEI2HTML($figure/t:graphic/t:desc)}
                </div>
                </div>
        else
        if ($figure/t:graphic/@n) then
            let $n := $figure/t:graphic/@n
            let $urls := for $f in 1 to $n
            return
                '"' || replace($url, '/info.json', concat(format-number(., '000'), '.tif/info.json')) || '"'
            return
                <div
                    id="{$id}">
                    <div
                        id="openseadragon{$id}"
                        style="height:300px"/>
                    <div
                        class="caption w3-margin-left w3-tiny">
                        {viewItem:TEI2HTML($figure/t:graphic/t:desc)}
                    </div>
                    <script
                        type="text/javascript">
                        {
                            'OpenSeadragon({
                           id: "openseadragon' || $id || '",
                           prefixUrl: "resources/openseadragon/images/",
                           preserveViewport: true,
                           visibilityRatio:    1,
                           minZoomLevel:       1,
                           defaultZoomLevel:   1,
                        sequenceMode :true,
                        tileSources:   ['
                            || string-join($urls, ', ') ||
                            ']
                           });'
                        }
                    </script>
                </div>
        else
            <div
                id="{$id}">
                <div
                    id="{$id}"
                    style="height:300px"><a href="{$uri || '/full/1424,/0/default.jpg'}"><img src="{$uri || '/full/356,/0/default.jpg'}" style="height:300px"/></a></div>
                <div
                    class="caption w3-margin-left w3-tiny">
                    {viewItem:TEI2HTML($figure/t:graphic/t:desc)}
                </div>
         <!--       <script
                    type="text/javascript">
                    {
                        'OpenSeadragon({
                           id: "openseadragon' || $id || '",
                           prefixUrl: "resources/openseadragon/images/",
                           preserveViewport: true,
                           visibilityRatio:    1,
                           minZoomLevel:       1,
                           defaultZoomLevel:   1,
                        sequenceMode :true,
                        tileSources:   ['
                        || $url ||
                        ']
                           });'
                    }
                </script>-->
            </div>
};

declare %private function viewItem:supportDesc($node) {
    (<h2>Physical Description {viewItem:headercontext($node)}</h2>,
    if ($node/parent::t:objectDesc/@form) then
        (<h3>Form of support {viewItem:headercontext($node)}</h3>,
        <p>{
                if ($node//t:material/@key) then
                    for $m in $node//t:material
                    let $mk := string($m/@key)
                    return
                        <span
                            class="w3-tag w3-gray"
                            property="http://www.cidoc-crm.org/cidoc-crm/P46_is_composed_of"
                            resource="https://betamasaheft.eu/material/{$mk}">
                            {concat(upper-case(substring($mk, 1, 1)), substring($mk, 2), ' ')}
                        </span>
                else
                    ()
            }<span
                class="w3-tag w3-red"
                typeof="https://betamasaheft.eu/{$node/parent::t:objectDesc/@form}">
                {string($node/parent::t:objectDesc/@form)}
            </span></p>)
    else
        (),
    viewItem:TEI2HTML($node/node())
    )
};

declare %private function viewItem:layoutDesc($node) {
    <div
        rel="http://purl.org/dc/terms/hasPart">
        <h3>Layout {viewItem:headercontext($node)}</h3>
        {viewItem:TEI2HTML($node/t:summary)}
        {
            for $l in $node/t:layout
                order by $l/position()
            return
                viewItem:layout($l)
        }
    </div>
};

declare %private function viewItem:palaeography($node) {
    <div
        rel="http://purl.org/dc/terms/hasPart">
        <h3>Palaeography {viewItem:headercontext($node)}</h3>
        {      for $h in $node/t:handNote
                return
                    <li class="nodot"
                        id="{$h/@xml:id}">
                    {    <h4>Hand {substring-after($h/@xml:id, 'h')}</h4>}
                    {viewItem:headercontext($node)}
                    {if ($h/t:persName[@role = 'scribe']) then
                        <p>Scribe: {viewItem:TEI2HTML($h/t:persName[@role = 'scribe'])}</p>
                    else
                       ()}
                    { <p>Script: {string($h/@script)}</p>}
                    { <p>{viewItem:TEI2HTML($h/t:seg[@type = 'script'])}</p>}
                    {if ($h/t:seg[@type = 'ink']) then
                        <p>Ink: {viewItem:TEI2HTML($h/t:seg[@type = 'ink'])}</p>
                    else
                        ()}
                    {if ($h/t:seg[@type = 'rubrication']) then
                        <p>Rubrication: {viewItem:TEI2HTML($h/t:seg[@type = 'rubrication'])}</p>
                    else
                        ()}
                    {if ($h/t:date) then
                        <p>Date: {viewItem:TEI2HTML($h/t:date)}</p>
                    else
                        ()}
                    {viewItem:TEI2HTML($h/node()[empty(self::t:seg)][empty(self::t:list)])}
                    {if ($h/t:list[@type = 'abbreviations']) then
                        (<h4>Abbreviations</h4>,
                        <ul>{viewItem:TEI2HTML($h/t:list[@type = 'abbreviations']/node())}</ul>)
                    else
                        ()}
                    </li>
               }
        </div>
};

declare %private function viewItem:layoutdimensionunit($dim) {
    (<span
        class="lead">
        {$dim/text()}
    </span>,
    string($dim/parent::t:*/@unit))
};
declare %private function viewItem:layout($node) {
let $pos := index-of($node/parent::*/t:layout, $node)[1] return
    <div
        id="layout{$pos}"
        resource="http://betamasaheft.eu/{$node/ancestor::t:TEI/@xml:id}#layout{$pos}">
        <h4>Layout note {$pos}
            {
                if ($node/t:locus) then
                    (  '(' , viewItem:TEI2HTML($node/t:locus), ')' )
                else
                    ()
            }</h4>
        {
            if ($node/@columns) then
                <p>Number of columns: {string($node/@columns)}</p>
            else
                ()
        }
        {
            if ($node/@writtenLines) then
                <p>Number of lines: {
                        if (contains($node/@writtenLines, ' ')) then
                            replace($node/@writtenLines, ' ', '-')
                        else
                            string($node/@writtenLines)
                    }</p>
            else
                ()
        }
        {
            if ($node//t:dimensions[not(@xml:lang)]) then
                <div
                    class="w3-responsive">
                    <table
                        class="w3-table w3-hoverable">
                        <tr>
                            <td>H</td>
                            <td>{viewItem:layoutdimensionunit($node/t:dimensions[not(@xml:lang)]/t:height)}</td>
                        </tr>
                        <tr>
                            <td>W</td>
                            <td>{viewItem:layoutdimensionunit($node/t:dimensions[not(@xml:lang)]/t:width)}</td>
                        </tr>
                        {
                            if ($node/t:dimensions[not(@xml:lang)][not(@type = 'margin')]/t:dim[@type = 'intercolumn']) then
                                <tr>
                                    <td>Intercolumn</td>
                                    <td>{viewItem:layoutdimensionunit($node/t:dimensions[not(@xml:lang)][not(@type = 'margin')]/t:dim[@type = 'intercolumn'])}</td>
                                </tr>
                            else
                                ()
                        }
                        {
                            if ($node/t:dimensions[not(@xml:lang)][@type = 'margin']/t:dim[@type]) then
                                (<tr>
                                    <td><b>Margins</b></td>
                                    <td/>
                                </tr>,
                                for $margin in $node/t:dimensions[not(@xml:lang)][@type = 'margin']/t:dim[@type]
                                return
                                    <tr>
                                        <td>{string($margin/@type)}</td>
                                        <td>{viewItem:layoutdimensionunit($margin)}</td>
                                    </tr>
                                )
                            else
                                ()
                        }
                    </table>
                </div>
            else
                ()
        }
        {
            if ($node/t:note) then
                viewItem:TEI2HTML($node/t:note)
            else
                ()(:,
            let $topmargin := if ($node/t:dimensions[not(@xml:lang)][@type = 'margin'][1]/t:dim[@type = 'top'][1]/text()) then
                ($node/t:dimensions[not(@xml:lang)][@type = 'margin'][1]/t:dim[@type = 'top'][1])
            else
                ('0')
            let $bottomargin := if ($node/t:dimensions[not(@xml:lang)][@type = 'margin'][1]/t:dim[@type = 'bottom'][1]/text()) then
                ($node/t:dimensions[not(@xml:lang)][@type = 'margin'][1]/t:dim[@type = 'bottom'][1])
            else
                ('0')
            let $rightmargin := if ($node/t:dimensions[not(@xml:lang)][@type = 'margin'][1]/t:dim[@type = 'right'][1]/text()) then
                ($node/t:dimensions[not(@xml:lang)][@type = 'margin'][1]/t:dim[@type = 'right'][1])
            else
                ('0')
            let $leftmargin := if ($node/t:dimensions[not(@xml:lang)][@type = 'margin'][1]/t:dim[@type = 'left'][1]/text()) then
                ($node/t:dimensions[not(@xml:lang)][@type = 'margin'][1]/t:dim[@type = 'left'][1])
            else
                ('0')
            let $textwidth := $node/t:dimensions[not(@xml:lang)][not(@type)][1]/t:width[1]
            let $heighText := $node/t:dimensions[not(@xml:lang)][not(@type)][1]/t:height[1]
            let $totalHeight := if ($node/ancestor::t:TEI//t:dimensions[not(@xml:lang)][@type = 'outer' and @unit = 'mm']/t:height/text() or
            $node/ancestor::t:TEI//t:dimensions[not(@xml:lang)][@type = 'outer']/t:height[@unit = 'mm']/text()) then
                (max($node/ancestor::t:TEI//t:dimensions[not(@xml:lang)][@type = 'outer']/t:height))
            else
                0
            let $totalwidth := if ($node/ancestor::t:TEI//t:dimensions[not(@xml:lang)][@type = 'outer' and @unit = 'mm']/t:width/text() or
            $node/ancestor::t:TEI//t:dimensions[not(@xml:lang)][@type = 'outer']/t:width[@unit = 'mm']/text()) then
                (max($node/ancestor::t:TEI//t:dimensions[not(@xml:lang)][@type = 'outer']/t:width))
            else
                0
            let $computedheight := number($heighText) + number($bottomargin) + number($topmargin)
            let $computedwidth := number($textwidth) + number($rightmargin) + number($leftmargin)
            let $currentMsPart := if ($node/ancestor::t:msPart[1]) then
                substring-after($node/ancestor::t:msPart[1]/@xml:id, 'p')
            else
                ' main part'
            return
            if ($node/t:dimensions)
            then
                (<button
                    type="button"
                    class="w3-button w3-gray"
                    onclick="openAccordion('layoutreport{$currentMsPart}')">Layout
                    report</button>,
                <div
                    class="report w3-container w3-hide"
                    id="layoutreport{$currentMsPart}">
                    <p>Ms {concat(exptit:printTitle($node/ancestor::t:TEI/@xml:id), $currentMsPart)}</p>
                    {
                        if (number($computedheight) gt number($totalHeight))
                        then
                            <span>has a sum of layout height of {$computedheight}mm which is greater than the
                                object height of {$totalHeight}mm </span>

                        else
                            ()
                    }
                    {
                        if (number($computedwidth) gt number($totalwidth))
                        then
                            <span>has a sum of layout width of {$computedwidth}mm which is greater than the
                                object height of {$totalwidth}mm </span>

                        else
                            ()
                    }
                    {
                        if (not((number($computedheight) gt number($totalHeight)) or (number($computedwidth) gt number($totalwidth)))) then
                            <span> looks ok for measures computed width is:
                                {$computedwidth}mm, object width
                                is: {$totalwidth}mm, computed height
                                is: {$computedheight}mm and object
                                height is: {$totalHeight}mm.
                                {
                                    if (number($topmargin) = 0 or number($bottomargin) = 0 or
                                    number($rightmargin) = 0 or number($leftmargin) = 0 or
                                    number($totalHeight) = 0 or number($totalwidth) = 0)
                                    then
                                        <span>but the following values are recognized as empty:
                                            {
                                                if (number($topmargin) = 0) then
                                                    'top margin'
                                                else
                                                    ()
                                            }
                                            {
                                                if (number($bottomargin) = 0) then
                                                    'bottom margin'
                                                else
                                                    ()
                                            }
                                            {
                                                if (number($rightmargin) = 0) then
                                                    'right margin'
                                                else
                                                    ()
                                            }
                                            {
                                                if (number($leftmargin) = 0) then
                                                    'left margin'
                                                else
                                                    ()
                                            }
                                            {
                                                if (number($totalHeight) = 0) then
                                                    'object height'
                                                else
                                                    ()
                                            }
                                            {
                                                if (number($totalwidth) = 0) then
                                                    'object width'
                                                else
                                                    ()
                                            }</span>
                                    else
                                        ()
                                }</span>
                        else
                            ()
                    }
                </div>
                )
                else
                ()
        }
        {
            if ($node//t:ab[@type = 'ruling']) then
                (<h5>Ruling {viewItem:headercontext($node)}</h5>,
                <ul>
                    {
                        for $ruling in $node//t:ab[@type = 'ruling']
                        return
                            <li>
                                {
                                    if ($ruling/@subtype) then
                                        '(Subtype: ' || string($ruling/@subtype) || ')'
                                    else
                                        ()
                                }
                                {
                                    if ($ruling/@subtype = 'pattern') then

                                        let $regex := '(([A-Z\d\-]+)/([A-Z\d\-]+)/([A-Z\d\-]+)/([A-Z\d\-]+))'
                                        let $analyze := analyze-string($ruling, $regex)
                                        for $m in $analyze/node()
                                        return
                                            if ($m/name() = 'match') then
                                                let $muzerelle := 'http://palaeographia.org/muzerelle/regGraph2.php?F='
                                                let $formula := $m/s:group[@nr = '1']//text()
                                                return
                                                    <a
                                                        href="{concat($muzerelle, string-join($formula))}"
                                                        target="_blank">{$formula}
                                                    </a>
                                            else
                                                $m/text()
                                    else
                                        viewItem:TEI2HTML($ruling/node())
                                }
                            </li>
                    }
                </ul>
                )
            else
                ()
        }
        {
            if ($node//t:ab[@type = 'pricking']) then
                (<h5>Pricking {viewItem:headercontext($node)}</h5>,
                <ul>
                    {
                        for $ruling in $node//t:ab[@type = 'pricking']
                        return
                            <li>
                                {
                                    if ($ruling/@subtype) then
                                        '(Subtype: ' || string($ruling/@subtype) || ')'
                                    else
                                        ()
                                }
                                {viewItem:TEI2HTML($ruling/node())}
                            </li>
                    }
                </ul>
                )
            else
                ()
        }
        {
            if ($node//t:ab[@type != 'pricking'][@type != 'ruling'][@type != 'punctuation'][@type != 'CruxAnsata'][@type != 'ChiRho'][@type != 'coronis']) then
                (<h5>Other {viewItem:headercontext($node)}</h5>,
                <ul>
                    {
                        for $ruling in $node//t:ab[@type != 'pricking'][@type != 'ruling'][@type != 'punctuation'][@type != 'CruxAnsata'][@type != 'ChiRho'][@type != 'coronis']
                        return
                            <li>
                                {
                                    if ($ruling/@subtype) then
                                        '(Subtype: ' || string($ruling/@subtype) || ')'
                                    else
                                        ()
                                }
                                {viewItem:TEI2HTML($ruling/node())}
                            </li>
                    }
                </ul>
                )
            else
                ()
        }
        {
            if ($node//t:ab[not(@type)]) then
                (<h5
                    style="color:red;"><code>ab</code> element without <code>@type</code> in layout {viewItem:headercontext($node)}</h5>,
                <ul>
                    {
                        for $ruling in $node//t:ab[not(@type)]
                        return
                            <li>
                                <b
                                    style="color:red;">This ab element does not have a required type.</b>
                                {
                                    if ($ruling/@subtype) then
                                        '(Subtype: ' || string($ruling/@subtype) || ')'
                                    else
                                        ()
                                }
                                {viewItem:TEI2HTML($ruling/node())}
                            </li>
                    }
                </ul>
                )
            else
                ()
        }
        {
            if ($node//t:ab[@subtype = 'Executed'] or $node//t:ab[@subtype = 'Usage'] or $node//t:ab[@subtype = 'Dividers']) then
                (<h4>Punctuation {viewItem:headercontext($node)}</h4>,

                for $punctuation in ($node//t:ab[@subtype = 'Executed'] | $node//t:ab[@subtype = 'Usage'] | $node//t:ab[@subtype = 'Dividers'])
                return
                    <p>
                        {string($punctuation/@subtype) || ': '}
                        {viewItem:TEI2HTML($punctuation/node())}
                    </p>

                )
            else
                ()
        }
        {
            if ($node//t:ab[@type = 'punctuation'][not(@subtype)]) then
                for $n in $node//t:ab[@type = 'punctuation'][not(@subtype)]
                return
                    viewItem:TEI2HTML($n)
            else
                ()
        }
        {
            for $ab in ('CruxAnsata', 'coronis', 'ChiRho')
            return
                if ($node//t:ab[@type = $ab][not(@subtype)]) then
                    (<h4>{$ab}</h4>,
                    <p>Yes {viewItem:TEI2HTML($node//t:ab[@type = $ab][not(@subtype)])}
                    </p>)
                else
                    ():)
        }
    </div>
};

declare %private function viewItem:ab($node as element(t:ab)) {
    if ($node/ancestor::t:div[@type = 'edition']) then
        <div
            class="w3-container">
            { if ($node/t:title/t:ref[1][@target]) then <h3><a
                        target="_blank"
                        href="{string($node/t:title[1]/@target)}">{string($node/t:title)}</a></h3> else ()}
            {if ($node/t:title/t:ref[1][@target]) then  viewItem:TEI2HTML($node/node()[not(self::t:title)])
            else viewItem:TEI2HTML($node/node())}</div>
    else
        if ($node/ancestor::t:div[@subtype = 'Psalmus']) then
            <div
                class="w3-container">
                <h3>
                    <a
                        href="{$node/t:title/t:ref/@target}">
                        {viewItem:TEI2HTML($node/t:title)}
                    </a>
                </h3>
                {viewItem:TEI2HTML($node/t:l)}
            </div>
        else
            <p>{
                    if ($node/@type) then
                        (<b>{
                                if ($node/@type = 'script') then
                                    string($node/parent::t:handNote/@script)
                                else
                                    string($node/@type)
                            }</b>, ': ')
                    else
                        ()
                }
                {viewItem:TEI2HTML($node/node())}</p>
};

declare %private function viewItem:abbr($node as element(t:abbr)) {
    (viewItem:TEI2HTML($node/node()),
    if (not($node/ancestor::t:expand)) then
        '(- - -)'
    else
        ())
};

declare %private function viewItem:acquisition($node as element(t:acquisition)) {
    (<h3>Acquisition</h3>,
    <p>{viewItem:TEI2HTML($node/node())}
    </p>)
};

declare %private function viewItem:adminInfo($node as element(t:adminInfo)) {
    (if ($node/t:note) then
        <h2>Administrative Information</h2>
    else
        (),
    viewItem:TEI2HTML($node/node())
    )
};

declare %private function viewItem:altIdentifier($node as element(t:altIdentifier)) {
    (<p>Also identified as</p>,
    for $idno in $node/t:idno
    return
        <span
            property="http://www.cidoc-crm.org/cidoc-crm/P1_is_identified_by"
            content="{$idno/text()}">{$idno/text()}</span>,
    viewItem:TEI2HTML($node/node()[not(self::t:idno)])
    )
};

declare %private function viewItem:cit($node as element(t:cit)) {
    ('“', viewItem:TEI2HTML($node/node()), '”')
};

declare %private function viewItem:custEvent($node) {
    if ($node/@type = 'restorations') then
        <p
            class="w3-large">
            This manuscript has {
                if ($node/@subtype = 'none') then
                    'no'
                else
                    string($node/@subtype)
            } restorations.</p>
    else
        ()
};

declare %private function viewItem:collectionelement($node) {
    <p>Collection: {$node/text()}</p>
};

declare %private function viewItem:handDesc($node) {
    <div
        resource="https://betamasaheft.eu/{$node/ancestor::t:TEI/@xml:id}/hand/{$node/@xml:id}">
        {
            attribute typeof {
                if ($node/@script) then
                    ('https://betamasaheft.eu/scripts/' || string($node/@script))
                else
                    (), 'https://betamasaheft.eu/hand', 'https://w3id.org/sdc/ontology#UniMain'
            }
        }
        <h6 style="scroll-margin-top: 64px;"
            id="{$node/@xml:id}">Hand {viewItem:headercontext($node)}
            {
                if ($node/@corresp) then
                    ('(',
                    for $c in viewItem:makeSequence($node/@corresp)
                    let $type := switch ($c)
                        case starts-with(., '#q')
                            return
                                'quire'
                        case starts-with(., '#a')
                            return
                                'addition'
                        case starts-with(., '#i')
                            return
                                'content item'
                        case starts-with(., '#b')
                            return
                                'binding'
                        case starts-with(., '#d')
                            return
                                'decoration'
                        default return
                            $c
                return
                    (<a
                        href="{$c}">{$type}
                        {substring-after($c, '#')}</a>,
                    <span
                        property="http://purl.org/dc/terms/relation"
                        resource="https://betamasaheft/{$node/ancestor::t:TEI/@xml:id}/{$type}/{substring-after($c, '#')}"/>),

                ')')
            else
                ()
        }</h6>
</div>

};
(:taken out what repeated the palaeography section above:)

declare %private function viewItem:foliation($node as element(t:foliation)) {
    (<h3>Foliation {viewItem:headercontext($node)}</h3>,
    <p>{viewItem:TEI2HTML($node/node())}</p>
    )
};

declare %private function viewItem:condition($node as element(t:condition)) {
    (<h3>State of preservation {viewItem:headercontext($node)}</h3>,
    <p>{string($node/@key)}</p>,
    <h4>Condition</h4>,
    <p>
        {viewItem:TEI2HTML($node/node())}
    </p>
    )
};

declare %private function viewItem:dimensions($node as element(t:dimensions)) {

<h5>Dimensions {if ($node/@type) then '(' || string($node/@type) || ')' else ()} {viewItem:headercontext($node)}</h5>,
 <div
                    class="w3-responsive">
                    <table
                        class="w3-table w3-hoverable">
                        {
                         if ($node[@type = 'margin']/t:dim[@type]) then
                                (<tr>
                                    <td><b>Margins</b></td>
                                    <td/>
                                </tr>,
                                for $margin in $node[@type = 'margin']/t:dim[@type]
                                return
                                    <tr>
                                        <td>{string($margin/@type)}</td>
                                        <td>{viewItem:layoutdimensionunit($margin)}</td>
                                    </tr>
                                )
                                else ()
                        }
                        {(:for EMML with dim:)
                            if ($node[not(contains(@type, 'margin'))]/t:dim) then for $dim in $node/t:dim return
                                <tr>
                                    {string($dim)}
                                </tr>
                            else
                                ()
                        }
                         {
                            if ($node/t:height) then
                                <tr>
                                    <td>Height</td>
                            		<td>{viewItem:layoutdimensionunit($node/t:height)}</td>
                                </tr>
                            else
                                ()
                        }
                        {
                            if ($node/t:width) then
                                <tr>
                                    <td>Width</td>
                            		<td>{viewItem:layoutdimensionunit($node/t:width)}</td>
                                </tr>
                            else
                                ()
                        }
                        {
                            if ($node/t:depth) then
                                <tr>
                                    <td>Depth</td>
                            		<td>{viewItem:layoutdimensionunit($node/t:depth)}</td>
                                </tr>
                            else
                                ()
                        }
                         {
                            if ($node[not(@type = 'margin')]/t:dim[@type = 'intercolumn']) then
                                <tr>
                                    <td>Intercolumn</td>
                                    <td>{viewItem:layoutdimensionunit($node/t:dimensions[not(@xml:lang)][not(@type = 'margin')]/t:dim[@type = 'intercolumn'])}</td>
                                </tr>
                            else
                                ()
                        }
                    </table>
                </div>
};

declare %private function viewItem:extent($node as element(t:extent)) {
    <h4>Extent {viewItem:headercontext($node)}</h4>,
     <div
        rel="http://purl.org/dc/terms/hasPart">
        <span
            property="http://betamasaheft.eu/hasTotalLeaves"
            content="{$node/t:measure[1][@unit = 'leaf'][not(@type)]}"/>
        {viewItem:TEI2HTML($node/node())}
        </div>
};


declare %private function viewItem:decoDesc($node) {
    <div
        id="deco"
        rel="http://purl.org/dc/terms/hasPart">
        <h2><span
                class="w3-tooltip">Decoration {viewItem:headercontext($node)}
                <span
                    class="w3-text">
                    In this unit there are in total {
                        let $types := for $type in distinct-values($node/t:decoNote/@type)
                        let $count := count($node/t:decoNote[@type = $type])
                        return
                            ($count || ' ' || viewItem:categoryname($node/ancestor::t:TEI, $type) || (if ($count gt 2) then
                                's'
                            else
                                ''))
                        return
                            string-join($types, ', ')
                    }.
                </span>
            </span>
        </h2>
        <p>{viewItem:TEI2HTML($node/t:summary)}</p>
        {
            if ($node/t:decoNote[@type = 'rubrication']) then
                (<h3>Rubrication</h3>,
                <ol>{
                        for $r in $node/t:decoNote[@type = 'rubrication']
                        return
                            viewItem:decoNoteItem($node, $r)
                    }
                </ol>
                )
            else
                ()
        }
        {
            if ($node/t:decoNote[@type = 'frame']) then
                (<h3>Frame notes</h3>,
                <ol>{
                        for $r in $node/t:decoNote[@type = 'frame']
                        return
                            viewItem:decoNoteItem($node, $r)
                    }
                </ol>
                )
            else
                ()
        }
        {
            if ($node/t:decoNote[@type = 'miniature']) then
                (<h3>Miniatures notes</h3>,
                <ol>{
                        for $r in $node/t:decoNote[@type = 'miniature']
                        return
                            viewItem:decoNoteItem($node, $r)
                    }
                </ol>
                )
            else
                ()
        }
        {
            if ($node/t:decoNote[not(ancestor::t:binding)][@type != 'rubrication'][@type != 'miniature'][@type != 'frame']) then
                (<h3>Other Decorations</h3>,
                <ol>{
                        for $r in $node/t:decoNote[not(ancestor::t:binding)][@type != 'rubrication'][@type != 'miniature'][@type != 'frame']
                        return
                            viewItem:decoNoteItem($node, $r)
                    }
                </ol>
                )
            else
                ()
        }
    </div>
};

declare %private function viewItem:decoNoteItem($node, $r) {
    <li style="scroll-margin-top: 64px;"
        id="{$r/@xml:id}"
        resource="http://betamasaheft.eu/{$node/ancestor::t:TEI/@xml:id}/decoration/{$node/@xml:id}">
        {
            attribute typeof {
                for $type in $r//t:term/@key
                return
                    ('http://betamasaheft.eu/ontology/' || $type),
                for $type in $r/@type
                return
                    ('http://betamasaheft.eu/ontology/' || $type)
            }
        }
        {string($r/@type)}:
        {viewItem:TEI2HTML($r/node())}
    </li>
};


declare %private function viewItem:colophon($node as element(t:colophon)) {
    (
    <hr
        class="colophon"/>,
    <h3
        id="{$node/@xml:id}">{
            if ($node/@type) then
                string($node/@type)
            else
                'Colophon'
        }</h3>,
    <p>{viewItem:TEI2HTML($node/t:locus)}</p>,
    <p>{viewItem:TEI2HTML($node/node()[not(self::t:note)][not(self::t:foreign)][not(self::t:listBibl)][not(self::t:locus)])}</p>,
    if ($node/t:foreign) then
        for $t in $node/t:foreign
        return
            <p
                lang="{$t/@xml:lang}">
                <b>Translation {viewItem:fulllang($t/@xml:lang)}: </b>
                {viewItem:TEI2HTML($t/node())}
            </p>
    else
        (),
    if ($node/t:note) then
        <p>
            {viewItem:TEI2HTML($node/t:note)}
        </p>
    else
        (),
    if ($node/t:listBibl) then
        <p>
            {viewItem:TEI2HTML($node/t:listBibl)}
        </p>
    else
        ()
    )
};


declare %private function viewItem:bindingDesc($node) {
    (<h3>Binding {viewItem:headercontext($node)}</h3>,
            if ($node/t:binding/@contemporary) then
            (<h4>  {
                    if ($node/t:binding/@contemporary = 'true') then
                        'Original: yes'
                    else if ($node/t:binding/@contemporary = 'false') then
                        'Original: no'
                        else
                        concat('Origin: ', string($node/t:binding/@contemporary))
                }</h4>)
        else
            (),
    <p
        id='b1'>{viewItem:TEI2HTML($node/t:binding/t:decoNote[@xml:id = 'b1'])}</p>,
     if ($node//t:decoNote[@type = 'bindingMaterial']) then
            (for $bo in $node/t:binding/t:decoNote[@type = 'bindingMaterial']
            return
                (<h4
                    id="{$bo/@xml:id}">Binding material</h4>,
                for $m in $bo/t:material/@key
                return
                    <p>{string($m)}</p>,
                <p>
                    {viewItem:TEI2HTML($bo/node())}
                </p>))
        else
            (),
    for $b in $node/t:binding/t:decoNote[not(@type = 'Other')][not(@type = 'bindingMaterial')][not(@xml:id = 'b1')]
    return
        (<h4
            id="{$b/@xml:id}">{
                if ($b/@type = 'SewingStations') then
                    'Sewing stations'
                else
                  if  ($b/@type) then functx:capitalize-first(string($b/@type)) else ()
            }</h4>,
        viewItem:TEI2HTML($b/node())),
    if ($node/t:binding/t:decoNote[@type = 'Other']) then
               (<h4>More details</h4>,
            for $bo in $node/t:binding/t:decoNote[@type = 'Other']
            return
                <p>
                    {viewItem:TEI2HTML($bo/node())}
                </p>)
        else
            ()
        )
};

declare %private function viewItem:accMat($node as element(t:accMat)) {
    (<h3>Accompanying Material</h3>,
    <p>{viewItem:TEI2HTML($node/node())}
    </p>)
};

declare %private function viewItem:revisionDesc($node) {
    <ul>
        {
            for $change in $node/t:change
            return
                <li>{$change/text()}</li>
        }
    </ul>
};


declare %private function viewItem:additions($node) {
    <div
        id="additiones"
        rel="http://purl.org/dc/terms/hasPart">
        <h2><span
                class="w3-tooltip">Additions {viewItem:headercontext($node)}
                <span
                    class="w3-text">
                    In this unit there are in total {
                        let $types := for $type in distinct-values($node//t:item/t:desc/@type)
                        let $count := count($node//t:item/t:desc[@type = $type])
                        return
                            ($count || ' ' || viewItem:categoryname($node/ancestor::t:TEI, $type) || (if ($count gt 2) then
                                's'
                            else
                                ''))
                        return
                            string-join($types, ', ')
                    }.
                </span>
            </span>
        </h2>
        {
            if ($node/t:note) then
                viewItem:TEI2HTML($node/t:note)
            else
                ()
        }
        <ol>{
                for $a in $node//t:item[starts-with(@xml:id, 'a')]
                return
                    viewItem:additionItem($a)
            }</ol>
        {
            if ($node//t:item[starts-with(@xml:id, 'e')])
            then
                (<h3>Extras {viewItem:headercontext($node)}</h3>,
                <ol>{
                        for $a in $node//t:item[starts-with(@xml:id, 'e')]
                        return
                            viewItem:additionItem($a)
                    }</ol>
                )
            else
                ()
        }
    </div>
};

declare %private function viewItem:additionItem($a) {
    <li style="scroll-margin-top: 64px;"
        id="{$a/@xml:id}"
        resource="https://betamasaheft.eu/{$a/ancestor::t:TEI/@xml:id}/addition/{$a/@xml:id}">
        {
            if ($a/t:desc/@type) then
                attribute typeof {'https://betamasaheft.eu/ontology/' || string($a/t:desc/@type)}
            else
                ()
        }
        <p>{viewItem:TEI2HTML($a/t:locus)}
            {
                if ($a/t:desc/@type) then
                    (' (Type: ',
                    <a
                        target="_blank" href="{$config:appUrl}/authority-files/list?keyword={$a/t:desc/@type}">{string($a/t:desc/@type)}</a>,
                    <a target="_blank"
                        href="{$config:appUrl}/additions?type={$a/t:desc/@type}">
                        <i
                            class="fa fa-hand-o-left"/>
                    </a>, ') ')
                else
                    ()
            }
        </p>
        {
            if ($a/@rend) then
                <p>{string($a/@rend)}</p>
            else
                ()
        }
        {
            if ($a/t:desc) then
                <p>{viewItem:TEI2HTML($a/t:desc)}</p>
            else
                ()
        }
        {
            if ($a/t:q) then
                viewItem:TEI2HTML($a/t:q)
            else
                ()
        }
         {
            if ($a/t:quote) then
                viewItem:TEI2HTML($a/t:quote)
            else
                ()
        }
        {
            if ($a/text()) then
                viewItem:TEI2HTML($a/text())
            else
                ()
        }
        {
            if ($a/t:note) then
                viewItem:TEI2HTML($a/t:note)
            else
                ()
        }
        {
            if ($a/t:listBibl) then
                viewItem:TEI2HTML($a/t:listBibl)
            else
                ()
        }
    </li>
};


declare %private function viewItem:desc($node as element(t:desc)) {
    if ($node[not(parent::t:relation)][not(parent::t:handNote)])
    then
        <p>{viewItem:TEI2HTML($node/node())}</p>
    else
        viewItem:TEI2HTML($node/node())
};


declare %private function viewItem:ex($node as element(t:ex)) {
    '(' || $node/text() || ')'
};

declare %private function viewItem:explicit($node as element(t:explicit)) {
    <p
        lang="{$node/@xml:lang}">
        <b>{
                if ($node/@type = 'supplication') then
                    'Supplication'
                else
                    if ($node/@type = 'subscriptio') then
                        'Subscription'
                    else
                        'Explicit'
            } ({viewItem:fulllang($node/@xml:lang)}
            ):</b>
        {viewItem:TEI2HTML($node/node())}</p>
};

declare %private function viewItem:faith($node as element(t:faith)) {
    if ($node/text()) then
        $node/text()
    else
        if (count($node/ancestor::t:TEI//t:catDesc[. = string($node/@type)]) ge 1)
        then
            $node/ancestor::t:TEI//t:catDesc[. = string($node/@type)]/text()
        else
            if ($node/@type) then
                string($node/@type)
            else
                'Unknown'
};

declare %private function viewItem:filiation($node as element(t:filiation)) {
    <p>
        <b>Filiation: </b>
        {viewItem:TEI2HTML($node/node())}
    </p>
};


declare %private function viewItem:forename($node as element(t:forename)) {
    $node/text() || ' '
};

declare %private function viewItem:hi($node as element(t:hi)) {
    if ($node/@rend = 'ligature') then
        <span
            style="border-top:1px solid">{viewItem:TEI2HTML($node/node())}</span>
    else
        if ($node/@rend = 'apices') then
            <sup>{viewItem:TEI2HTML($node/node())}</sup>
        else
            if ($node/@rend = 'underline') then
                <u>{viewItem:TEI2HTML($node/node())}</u>
            else
                if ($node/@rend = 'rubric') then
                    <span
                        class="rubric">{viewItem:TEI2HTML($node/node())}</span>
                else
                    if ($node/@rend = 'encircled') then
                        <span
                            class="encircled">{viewItem:TEI2HTML($node/node())}</span>
                    else
                        viewItem:TEI2HTML($node/node())
};

declare %private function viewItem:history($node as element(t:history)) {
    (<h2>Origin {viewItem:headercontext($node)}</h2>,
    <p>{viewItem:TEI2HTML($node/node())}</p>
    )
};

declare %private function viewItem:idno($node as element(t:idno)) {
    <span>{$node/text()}</span>
};

declare %private function viewItem:incipit($node as element(t:incipit)) {
    <p
        lang="{$node/@xml:lang}">
        <b>{
                if ($node/@type = 'supplication') then
                    'Supplication'
                else
                 if ($node/@type = 'inscriptio') then
                    'Inscriptio'
                    else
                    'Incipit'
            } ({viewItem:fulllang($node/@xml:lang)}
            ):</b>
        {viewItem:TEI2HTML($node/node())}</p>
};

declare %private function viewItem:item($node as element(t:item)) {
    <li>{viewItem:TEI2HTML($node/node())}</li>
};

declare %private function viewItem:list($node as element(t:list)) {
    if ($node[ancestor::t:abstract or ancestor::t:desc]) then
        <ol>
            {viewItem:TEI2HTML($node/node())}</ol>
    else
        <ul>
            {viewItem:TEI2HTML($node/node())}
        </ul>
};

declare %private function viewItem:listBibl($node as element(t:listBibl)) {
    (
    <h4>{viewItem:biblioHeader($node)}</h4>,
    <ul
        class="bibliographyList">
        {viewItem:TEI2HTML($node/node())}
    </ul>
    )
};

declare %private function viewItem:measureelement($node as element(t:measure)) {
    <span
        class="w3-tooltip">
        {
            if ($node/@xml:lang) then
                (attribute lang {$node/@xml:lang}, <span>{$node/text()}</span>)
            else
    (:            if (contains($node, '+')) then
                    viewItem:measure($node/text())
                else :)
              if (($node/@quantity)) then
                    string($node/@quantity)
             else
                    $node/text()
        }
        ({string($node/@unit)}{
            if ($node/@type) then
                (', ' || string($node/@type))
            else
                ()
        })
        {
            if ($node/following-sibling::t:*[1][self::t:locus]) then
                ': '
            else
                if ($node/following-sibling::t:measure[not(@xml:lang)][@unit = 'leaf'][@type = 'blank']) then
                    ', '
                else
                    '.'
        }
        <span
            class="w3-text w3-tag">Entered as {$node/text()}
        </span>
    </span>
};




declare %private function viewItem:msContents($node as element(t:msContents)) {
    (
    <h3>Contents</h3>,
    <div
        id="contents"
        class="accordion">
        {viewItem:TEI2HTML($node/node()[not(name() = 'summary')])}
    </div>
    )
};

declare %private function viewItem:note($node as element(t:note)) {
    if ($node/parent::t:placeName) then
        <div
            class="w3-panel w3-gray">
            {
                if ($node/t:p or $node/ancestor::t:app)
                then
                    viewItem:TEI2HTML($node/node())
                else
                    if (not($node/parent::*:fragment))
                    then
                        <p>{viewItem:TEI2HTML($node/node())}</p>
                    else
                        <p>{viewItem:TEI2HTML($node/node())}</p>
            }
            {
                if ($node/@source) then
                    <a
                        href="{$node/@source}">Source <i
                            class="fa fa-link"
                            aria-hidden="true"/>
                    </a>
                else
                    ()
            }
        </div>
    else
        if ($node/parent::t:rdg) then
            (' ', <i>{viewItem:TEI2HTML($node/node())}</i>, ' ')
        else
            if ($node[@xml:id][@n]) then
                viewItem:footnote($node)
            else
              <span> ({viewItem:TEI2HTML($node/node()) }) </span>
};

declare %private function viewItem:nationality($node as element(t:nationality)) {
    if ($node/node()) then
        viewItem:TEI2HTML($node/node())
    else
        string($node/@type)
};

declare %private function viewItem:origplace($node as element(t:origPlace)) {
    (<p>
        <b>Original Location: </b>
        {viewItem:TEI2HTML($node/node())}
    </p>,
    <p>
        {viewItem:TEI2HTML($node/parent::t:origin/t:provenance)}
    </p>)
};

declare %private function viewItem:provenance($node as element(t:provenance)) {
    (<h3>Provenance</h3>,
    <p>{viewItem:TEI2HTML($node/node())}
    </p>)
};

declare %private function viewItem:ptr($node as element(t:ptr)) {
    if ($node[starts-with(@target, '#')]) then
        viewItem:footnoteptr($node)
    else
        viewItem:TEI2HTML($node/node())
};

declare %private function viewItem:qelement($node as element(t:q)) {
    if ($node/parent::t:desc) then
        <span
            lang="{$node/@xml:lang}">
            {
                if ($node/ancestor::t:decoNote) then
                    'Legend: '
                else
                    ()
            }
            {
                if ($node/text()) then
                    ('(', string($node/@xml:lang), ') ')
                else
                    ('Text in ', viewItem:fulllang($node/@xml:lang))
            }
            {viewItem:TEI2HTML($node/node())}
        </span>
    else
        <p
            lang="{$node/@xml:lang}">
            {
                if ($node/ancestor::t:decoNote) then
                    'Legend: '
                else
                    ()
            }
            {
                if ($node/text()) then
                    ('(', string($node/@xml:lang), ') ')
                else
                    ('Text in ', viewItem:fulllang($node/@xml:lang))
            }
            {viewItem:TEI2HTML($node/node())}
        </p>

};


declare %private function viewItem:repository($node as element(t:repository)) {
    <a
        target="_blank"
        href="{$node/@ref}"
        role="button"
        class="w3-tag w3-gray w3-margin-top"
        property="http://www.cidoc-crm.org/cidoc-crm/P55_has_current_location"
        resource="{$node/@ref}">
        {$node/text()}
    </a>
};

declare %private function viewItem:roleName($node as element(t:roleName)) {
    if ($node[not(parent::t:persName)]) then
        <a
            xmlns="http://www.w3.org/1999/xhtml"
            href="/xpath.html?xpath=%24config%3Acollection-root%2F%2Ft%3AroleName%5Bcontains%28.%2C%27{$node/text()}%27%29%5D"
            class="AttestationsWithSameRole"
            data-value="{$node/text()}">
             {concat($node/text(), ' ')}<sup>{string($node/@type)}</sup>
        </a>
    else
        <span
            xmlns="http://www.w3.org/1999/xhtml"
            class="w3-tooltip">
            {concat($node/text(), ' ')}
            <span
                class="w3-text"><sup>role: {string($node/@type)}</sup></span>
        </span>

};

declare %private function viewItem:rs($node as element(t:rs)) {
    if ($node/@type = 'inline') then
        <img
            src="{$node/t:graphic/@url}"
            alt="Region of image from {$node/t:graphic/@url}"/>
    else
        viewItem:TEI2HTML($node/node())
};

declare %private function viewItem:rubric($node as element(t:rubric)) {
    <p
        lang="{$node/@xml:lang}">
        <b>Rubric {string($node/@xml:lang)}: </b>
        {viewItem:TEI2HTML($node/node())}</p>

};

declare %private function viewItem:sealDesc($node as element(t:sealDesc)) {
    (
    <h3>Seals {viewItem:headercontext($node)}</h3>,
    viewItem:TEI2HTML($node/node())
    )
};

declare %private function viewItem:seg($node as element(t:seg)) {
    if ($node/@ana) then
        <span
            class="{substring-after($node/@ana, '#')}">
            {viewItem:TEI2HTML($node/node())}
        </span>
    else
        viewItem:TEI2HTML($node/node())
};

declare %private function viewItem:surname($node as element(t:surname)) {
    $node/text() || ' '
};

declare %private function viewItem:signatures($node as element(t:signatures)) {
    ($node/text(),
    if ($node/t:note) then
        ('-', viewItem:TEI2HTML($node/t:note))
    else
        ())
};

declare %private function viewItem:surrogates($node as element(t:surrogates)) {
    (<h2>Surrogates</h2>,
    viewItem:TEI2HTML($node/node())
    )
};

declare %private function viewItem:textLang($node as element(t:textLang)) {
    <p>
        <b>Language of the text: </b>
         <span
            property="http://purl.org/dc/elements/1.1/language">{if ($node/@xml:lang) then viewItem:fulllang($node/@xml:lang) else viewItem:fulllang($node/@mainLang)}</span>
        {
            if ($node/@otherLangs) then
                (' and ', viewItem:fulllang($node/@otherLangs))
            else
                ()
        }
    </p>
};

declare %private function viewItem:term($node as element(t:term)) {
    if ($node[parent::t:desc | parent::t:summary]) then
        <a
            target="_blank">
            {attribute href {concat('/newSearch.html?searchType=text&amp;mode=any&amp;termkey=', string($node/@key))}}
            {$node/text()||' '}
        </a>
    else
        if ($node/text()) then
            <b>{viewItem:TEI2HTML($node/node())}</b>
        else
            viewItem:TEI2HTML($node/node())
};

declare %private function viewItem:watermark($node as element(t:watermark)) {
    if ($node/parent::t:support[t:material[@key = 'parchment']]) then
        ()
    else
        (<h3>Watermark</h3>,
        <p>{
                if ($node != '') then
                    viewItem:TEI2HTML($node/node())
                else
                    'No'
            }</p>)
};

declare %private function viewItem:label($node as element(t:label)) {
    if ($node/parent::t:div[@subtype = 'Psalmus']) then
        ()
    else
        viewItem:TEI2HTML($node/node())
};


declare %private function viewItem:lb($node as element(t:lb)) {
    if ($node/parent::t:ab)
    then
        (if ($node/@break) then
            '|'
        else
            (' |',
            <sup
                id="{viewItem:DTSpartID($node)}">{$node/@n}</sup>, ' '))
    else
        if ($node[ancestor::t:ab][parent::t:placeName or parent::t:persName or parent::t:w])
        then
            (if ($node/@break) then
                '|'
            else
                (' |',
                <sup
                    id="{viewItem:DTSpartID($node)}">{$node/@n}</sup>, ' '))
        else
            if ($node[parent::t:l][not(parent::t:ab)] and $node/preceding-sibling::text())
            then
                (<br/>)
            else
                if ($node[not(parent::t:ab)][not(parent::t:l)][not(parent::t:w)][not(parent::t:persName)][not(parent::t:placeName)])
                then
                    (let $line := $node/@n
                    return
                        (<br/>,
                        if (number($node/@n) and $node/@n mod number(5) = 0 and not($node/@n = 0)) then
                            (
                            string($node/@n),
                            <span
                                style="padding-left: 5em;"/>)
                        else
                            <span
                                style="padding-left: 5em;"/>
                        ))
                else
                    ()
};


declare %private function viewItem:cb($node as element(t:cb)) {
    ('|',
    <sup
        id="{viewItem:DTSpartID($node)}">{$node/@n}</sup>)
};

declare %private function viewItem:handShift($node as element(t:handShift)) {
    <sub>
        <a
            href="{$node/@new}">
            {substring-after($node/@new, '#')}
        </a>
    </sub>
};

declare %private function viewItem:surplus($node as element(t:surplus)) {
<span
        class="w3-tooltip">
   { ('{', viewItem:TEI2HTML($node/node()), '}')}
    <span
            class="w3-text w3-tag w3-small">{
            if ($node/@resp) then
            (
            if (starts-with($node/@resp, 'PRS') or starts-with($node/@resp, 'ETH')) then
                                                concat('resp: ', exptit:printTitle($node/@resp))
   else if (starts-with($node/@resp, 'bm:')) then
                                                concat('resp: ', string($node/@resp))
   else
                                                 concat('resp: ', viewItem:editorName($node/@resp)))
          else
                                                 ()}</span>
    </span>
};

declare %private function viewItem:space($node as element(t:space)) {
    <span
        class="w3-tooltip">

           {
               if ($node/@reason = 'rubrication') then
                concat('(', $node/@quantity, ' ', $node/@unit, ' left for rubrication and never filled)')
            else
                concat('(', $node/@quantity, ' ', $node/@unit, ' unfilled space)')
            }

<span
            class="w3-text w3-tag w3-small">{
            if ($node/@resp) then
            (
            if (starts-with($node/@resp, 'PRS') or starts-with($node/@resp, 'ETH')) then
                                                concat('resp: ', exptit:printTitle($node/@resp))
   else if (starts-with($node/@resp, 'bm:')) then
                                                concat('resp: ',  string($node/@resp))
   else
                                                 concat('resp: ', viewItem:editorName($node/@resp)))
          else
                                                 ()}</span>
    </span>
};

declare %private function viewItem:choice($node as element(t:choice)) {
    let $id := generate-id($node)
    return
        <span
        class="w3-tooltip">{
        if ($node[t:sic and t:corr]) then
            (<b>
                    {$node/t:corr}
            </b>
            ,
            <script
                type="text/javascript">
                {
                    "$('#" || $id || "').bind('click', function() {
            $(this).html($(this).html() == '" || $node/t:corr || "' ? '" || concat(viewItem:TEI2HTML($node/t:sic), '(!)') || "' : '" || $node/t:corr || "');
            });"
                }
            </script>
            )
        else
            if ($node[t:sic and t:orig]) then
                concat('{', $node/t:orig, '}')
            else
                (viewItem:TEI2HTML($node/node()))
                }

                <span
            class="w3-text w3-tag w3-small">{
            if ($node/@resp) then
                  (      if (starts-with($node/@resp, 'PRS') or starts-with($node/@resp, 'ETH')) then
                        concat(viewItem:TEI2HTML($node/t:sic), '(!)', 'corrected by ', exptit:printTitle($node/@resp))
   else  if (starts-with($node/@resp, 'bm:')) then
                        concat(viewItem:TEI2HTML($node/t:sic), '(!)', 'corrected by ',  string($node/@resp))
   else
                       concat(viewItem:TEI2HTML($node/t:sic), '(!)', 'corrected by ', viewItem:editorName($node/@resp))
                                                 )
                                                 else
                                                 if ($node/t:corr/@resp) then
                  (      if (starts-with($node/t:corr/@resp, 'PRS') or starts-with($node/t:corr/@resp, 'ETH')) then
                        concat(viewItem:TEI2HTML($node/t:sic), '(!)', 'corrected by ', exptit:printTitle($node/t:corr/@resp))
   else if (starts-with($node/t:corr/@resp, 'bm:')) then
                        concat(viewItem:TEI2HTML($node/t:sic), '(!)', 'corrected by ', string($node/t:corr/@resp))
   else
                       concat(viewItem:TEI2HTML($node/t:sic), '(!)', 'corrected by ', viewItem:editorName($node/t:corr/@resp))
                                                 )
                                                 else

                      concat(viewItem:TEI2HTML($node/t:sic), '(!)')}
                </span>
                </span>
};

declare %private function viewItem:unclear($node as element(t:unclear)) {
     <span
                        style="background-color:hsla(50, 20%, 50%, 0.2); opacity: 0.6; text-decoration-line: underline; text-decoration-style: wavy; text-decoration-color: gray;">[{viewItem:TEI2HTML($node/node())}?]</span>
};

declare %private function viewItem:sic($node as element(t:sic)) {
     <span
        class="w3-tooltip">
            {$node/text()}(!)<span
            class="w3-text w3-tag w3-small CorrResp">{
            if ($node/@resp) then
            (
            if (starts-with($node/@resp, 'PRS') or starts-with($node/@resp, 'ETH')) then
                                                concat('sic by ', exptit:printTitle($node/@resp))
   else  if (starts-with($node/t:corr/@resp, 'bm:')) then
                        concat('sic by ', string($node/@resp))
   else
                                                 concat('sic by ', viewItem:editorName($node/@resp)))
          else
                                                 ()}</span>
    </span>
};

declare %private function viewItem:del($node as element(t:del)) {
    <span
        class="w3-tooltip">
           {
                if ($node[contains(@rend , 'erasure')]) then
                    ('〚',
                    (if (empty($node)) then
                        (concat($node/@extent, ' ', $node/@unit))
                    else
                        viewItem:TEI2HTML($node/node())), '〛')
                else
                    if ($node[contains(@rend , 'strikethrough')]) then
                        <strike>{
                                if (empty($node)) then
                                    (concat($node/@extent, ' ', $node/@unit))
                                else
                                    viewItem:TEI2HTML($node/node())
                            }</strike>
                          else
                    if ($node[contains(@rend , 'expunctuated')]) then
                        <span style="border-bottom: 1px dotted #000; padding: 1px;">{
                                if (empty($node)) then
                                    (concat($node/@extent, ' ', $node/@unit))
                                else
                                    viewItem:TEI2HTML($node/node())
                            }</span>
                             else
                    if ($node[contains(@rend , 'encircled')]) then
                        <span class="w3-border w3-round-xxlarge">{
                                if (empty($node)) then
                                    (concat($node/@extent, ' ', $node/@unit))
                                else
                                    viewItem:TEI2HTML($node/node())
                            }</span>
                            else
                    if ($node[contains(@rend , 'overUnderlined')]) then
                        <span style="border-bottom: 1px dotted #000; border-top: 1px dotted #000; padding: 1px;">{
                                if (empty($node)) then
                                    (concat($node/@extent, ' ', $node/@unit))
                                else
                                    viewItem:TEI2HTML($node/node())
                            }</span>
                            else
                    if ($node[contains(@rend , 'effaced')]) then
                        <span class="w3-gray">{
                                if (empty($node)) then
                                    (concat($node/@extent, ' ', $node/@unit))
                                else
                                    viewItem:TEI2HTML($node/node())
                            }</span>
                    else
                        viewItem:TEI2HTML($node/node())
            }
        <span
            class="w3-text w3-tag w3-small CorrResp">{
            if ($node/@resp) then
            (
            if (starts-with($node/@resp, 'PRS') or starts-with($node/@resp, 'ETH')) then
                                                concat('corrected by ', exptit:printTitle($node/@resp))
     else if (starts-with($node/@resp, 'bm:')) then
                                                concat('resp: ', string($node/@resp))
             else
                                                 concat('corrected by ', viewItem:editorName($node/@resp)))
          else
                                                 ()}</span>
    </span>
};

declare %private function viewItem:supplied($node as element(t:supplied)) {
    <span
        class="w3-tooltip">

            {
 if ($node/@reason = 'undefined') then
    concat('[', viewItem:TEI2HTML($node/node()), '(?)]')
    else
        if ($node/@reason = 'lost') then
            concat('[', viewItem:TEI2HTML($node/node()), ']')
        else
            if ($node/@reason = 'omitted') then
                concat('&lt;', viewItem:TEI2HTML($node/node()), '&gt;')
                else
                    if ($node/@reason = 'explanation') then
                concat('&#34;', viewItem:TEI2HTML($node/node()), '&#34;')

                     else
                        (string-join($node/@*, ' '))
            }

        <span
            class="w3-text w3-tag w3-small SupResp">{
            if ($node/@resp) then
            (
            if (starts-with($node/@resp, 'PRS') or starts-with($node/@resp, 'ETH')) then
                                                concat('supplied by ', exptit:printTitle($node/@resp))
  else if (starts-with($node/@resp, 'bm:')) then
                                                concat('supplied by ',   string($node/@resp))
   else
                                                 concat('supplied by ', viewItem:editorName($node/@resp)))
          else
                                                 ()}</span>
    </span>
};

declare %private function viewItem:orig($node as element(t:orig)) {
    <span
        class="undeciphrable">{viewItem:TEI2HTML($node/node())}</span>
};

declare %private function viewItem:add($node as element(t:add)) {
    let $id := generate-id($node)
    return
        if ($node/@hand and $node/@place) then
            (
            <span
                class="w3-tooltip">
                {viewItem:TEI2HTML($node/node())}
                <span
                    class="w3-text">Note added {
                        if ($node/@hand)
                        then
                            concat('by ', substring-after($node/@hand, '#'))
                        else
                            ''
                    }
                    at {upper-case(string($node/@place))} according to TEI definitions.</span>
            </span>
            )
        else
            if ($node/@place = 'overstrike' and $node/preceding-sibling::t:del) then
                (
                '{', viewItem:TEI2HTML($node/node()), '}'
                )
            else
                if ($node/@hand and not($node/@place)) then
                    (
                    '/',
                    <span
                        class="w3-tooltip">
                        {viewItem:TEI2HTML($node/node())}
                        <span
                            class="w3-text">Note added {
                                if ($node/@hand)
                                then
                                    concat('by ', substring-after($node/@hand, '#'))
                                else
                                    ''
                            }</span>
                    </span>,
                    '/')
                else
                    if ($node/@place = 'margin' and $node/ancestor::t:TEI[@type = 'work']) then
                        (
                        <span
                            class="w3-tooltip">
                            {viewItem:TEI2HTML($node/node())}
                            <span
                                class="w3-text">Note added {
                                    if ($node/@hand)
                                    then
                                        concat('by ', substring-after($node/@hand, '#'))
                                    else
                                        ''
                                }
                                at {upper-case(string($node/@place))} according to TEI definitions.</span>
                        </span>)
                    else
                        ()
};

declare %private function viewItem:gap($node as element(t:gap)) {
    let $quantity := $node/@quantity
    let $extent := $node/@extent
    return
<span
        class="w3-tooltip">
             {
                if ($node/@reason = 'illegible') then
                    (
                    if ($node/@quantity) then
                        (for $q in 1 to $quantity
                        return
                            '+')
                   else
                        if ($node/@extent) then
                        (
                        if ($node/@extent="unknown") then ('[...]')
                        else
                            for $q in 1 to $extent
                            return
                                '▧')
                        else
                            ('[...]')
                    )
                else
                    if ($node/@reason = 'omitted') then
                        (
                    if ($node/@quantity) then
                        (for $q in 1 to $quantity
                        return
                            '.')
                    else
                        ('. . . . .')
                        )
                    else
                        if ($node/@reason = 'lost') then
                        (
                          if ($node/@quantity) then
                            concat('[c. ', $node/@quantity, ' ', $node/@unit, ' lost]')
                            else
                            ('[…]')
                            )
                        else
                            if ($node/@reason = 'ellipsis') then
                                ('(…)')
                            else
                                ()
            }

       <span
            class="w3-text w3-tag w3-small OmissionResp">{if (starts-with($node/@resp, 'PRS') or starts-with($node/@resp, 'ETH')) then
                                                concat('ommission by ', string-join(exptit:printTitle($node/@resp), ', '))
    else if (starts-with($node/@resp, 'bm:')) then
                                                concat('ommission by ',  string($node/@resp))
   else
                                                 concat('ommission by ', viewItem:editorName($node/@resp))}</span>
    </span>
};

declare %private function viewItem:pb($node as element(t:pb)) {
    if ($node/ancestor::t:div[@type = 'edition'] or $node/ancestor::dts:fragment)
    then
        (' |',
        <sup
            id="{viewItem:DTSpartID($node)}">{$node/@n}</sup>, ' ',
        viewItem:imagelink($node))
    else
        (<hr
            id="part{$node/@n}"/>,
        <p>{viewItem:imagelink($node)}</p>
        )
};

declare %private function viewItem:imagelink($node) {

    if (starts-with($node/@facs, 'http') and $node/ancestor::t:TEI[@type = 'work']) then
        (
        (:        in this case the edition of a work points to a witness which is external and whose coordinates are explicitly provided

e.g. LIT2170Peripl :)
        let $corresp := substring-after($node/@corresp, '#')
        let $manifest := $node/ancestor::t:TEI//t:witness[@xml:id = $corresp]/t:ptr/@target
        let $location := $node/ancestor::t:TEI//t:witness[@xml:id = $corresp]/@facs
        return
            <span
                class="imageLink"
                data-manifest="{$manifest}"
                data-location="{$location}"
                data-canvas="{$node/@facs}"/>
        )
    else
        (
        (: in this case there is a pb in the transcription, so it should be a manuscript.
        The manifest should be the one available for the manuscript
        Here there are several cases
        - the manifest is external
        - the @facs points at a facsimile/zone element from transkribus
        - there is no facs in the pb, but there is a manifest, so the page may be guessed.

        THIS IS NOT DONE YET!
        :)
        <span
            class="imageLink"/>
        )
};

declare %private function viewItem:lg($node as element(t:lg)) {
    <div
        class="w3-container"> {
                  if ($node/@type) then
                   string($node/@type) || (if ($node/@n) then
                                            '  ' || string($node/@n)
                                        else
                                            ()) else ()
            } <br/>{viewItem:TEI2HTML($node/node())}</div>
};

declare %private function viewItem:l($node as element(t:l)) {
    if ($node/ancestor::t:div[@subtype = 'Psalmus']) then
        <div
            class="w3-container">
            <p>
                <sup>{$node/@n}</sup>
                {viewItem:TEI2HTML($node)}
            </p>
        </div>
    else
        (<sup>
            {
                if ($node/t:ref[1][@target]) then
                    <a
                        target="_blank"
                        href="{string($node/t:ref[1]/@target)}">{string($node/@n)}</a>
                else if ($node/@n) then
                    string($node/@n)
                  else ' '
            }
        </sup>,
        viewItem:TEI2HTML($node/node()[not(self::t:ref)]),
        <br/>
        )
};



declare %private function viewItem:app($node as element(t:app)) {
    if ($node/parent::t:lem) then
        ()
    else
        (
        viewItem:TEI2HTML($node/t:lem/node()),
        <sup
            id="{$node/ancestor::t:div[@type = 'textpart'][1]/@n}appNote{generate-id($node)}">
            <a
                href="#{$node/ancestor::t:div[@type = 'textpart'][1]/@n}appPointer{generate-id($node)}">
                {count($node/parent::t:*/t:app[. << $node]) + 1}
            </a>
        </sup>,
        ' ')
};

declare %private function viewItem:wit($node) {
    let $listWit := $node/ancestor::t:TEI//t:listWit
    for $w in viewItem:makeSequence($node/@wit)
    let $trimmedid := substring-after($w, '#')
    let $witness := $listWit//t:witness[@xml:id = $trimmedid]
    return
        <span>
            {
                if ($node/@resp) then
                    (attribute data-resp {string($node/@resp)},
                    attribute class {'w3-tooltip RdgRespMs'})
                else
                    (attribute class {'w3-tooltip'})
            }
            {$trimmedid}
            <span
                class="w3-text">{
                    <a
                        href="{string($witness/@corresp)}"> {$witness/t:idno/text()} </a>
                }</span>
        </span>
};

declare %private function viewItem:lem($node as element(t:lem)) {
    let $resp := $node/@resp
    let $listWit := $node/ancestor::t:TEI//t:listWit
    return
        (
        viewItem:TEI2HTML($node/node()),
        ' ',
        viewItem:wit($node),
        ' '
        )

};


declare %private function viewItem:rdg($node as element(t:rdg)) {
    let $resp := $node/@resp
    return
        (<b>
            {
                if ($node/@xml:lang) then
                    attribute lang {$node/@xml:lang}
                else
                    ()
            }
            {viewItem:wit($node)}
        </b>,
        ' ',
        if ($node/@xml:lang) then
            (
            ' Cfr. ' || string($node/@xml:lang))
        else
            ()
        , viewItem:TEI2HTML($node/node())
        )
};

(:refactoring structures found in divEdition.xsl:)
declare function viewItem:div($node as element(t:div)) {
    if ($node[@type = 'apparatus'])
    then
        <div
            class="row-fluid"
            id="apparatus">
            <hr/>
            {
                for $app at $p in $node/t:app
                return
                    (<a
                        href="{$app/@from}">{concat(substring-after($app/@from, '#'), ', ', $app/@loc, ' ')}</a>,
                    viewItem:TEI2HTML($app),
                    if ($p != count($node/t:app)) then
                        ' | '
                    else
                        ()
                    )
            }

        </div>
    else
        if ($node[parent::t:body][not(@type = 'apparatus')])
        then
            (<div
                class="w3-row"
                id="{$node/@type}">
                {
                    if ($node/@xml:id = 'Transkribus') then
                        attribute style {'color:gray;'}
                    else
                        ()
                }
                <head>
                    {
                        if ($node/@corresp) then
                            <a
                                href="{$node/@corresp}">
                                {replace(substring-after($node/@corresp, '#'), '_', ' ')}
                                {
                                    if ($node/@subtype)
                                    then
                                        ', ' || string($node/@subtype) || (if ($node/@n) then
                                            ': ' || string($node/@n)
                                        else
                                            ())
                                    else
                                        ()
                                }
                            </a>
                        else
                            ()
                    }
                </head>
                <br/>
                {viewItem:TEI2HTML($node/node())}
            </div>,
            <br/>)
        else
            if ($node[@type = 'textpart'] | $node[@type = 'edition'][not(child::t:div)])
            then
                <div
                    id="{viewItem:DTSpartID($node)}">
                    {
                        if (not($node/descendant::t:pb) and not($node/parent::t:div[@type = 'textpart'])) then
                            viewItem:TEI2HTML($node/preceding::t:pb[1])
                        else
                            ()
                    }
                    {
                        let $text := string($node/ancestor::t:TEI/@xml:id)
                        return
                            if ($node/child::t:div[@type = 'textpart']) then
                                 (viewItem:titletemplate($node, $text),
(:                                if the div has its own contant, print that, not that of nested divs:)
                                if($node/child::t:ab) then viewItem:TEI2HTML($node/node()[not(self::t:div)])
(:                                otherways look at first order of nested divs which do not have further nested divs to came back here :)
                                else viewItem:TEI2HTML($node/node()[not(self::t:div[t:div])])
                             )
                            else
                                (<div
                                    class="{
                                            if ($node/parent::t:div[@type = 'textpart']) then
                                                'subtextpart'
                                            else
                                                ()
                                        } w3-row"
                                    id="{viewItem:DTSpartID($node)}"
                                >
                                    {
                                        if ($node/ancestor-or-self::t:div[@xml:lang][1]) then
                                            attribute lang {string($node/ancestor-or-self::t:div[@xml:lang][1]/@xml:lang)}
                                        else
                                            ()
                                    }
                                    {
                                        viewItem:titletemplate($node, $text)
                                    }</div>,
                                <div
                                    id="{$node/@xml:id}">
                                    {
                                        if ($node/t:ab//t:app) then
                                            attribute class {'w3-twothird w3-padding chapterText'}
                                        else
                                            attribute class {'w3-container w3-padding chapterText'}
                                    }
                                    {(:if($node/t:ab) then viewItem:TEI2HTML($node/node()[not(self::t:label)]) else :) viewItem:TEI2HTML($node/node())}
                                </div>,
                                if ($node/t:ab//t:app) then
                                    <div
                                        class="w3-third row apparata ">
                                        {
                                            let $tot := count($node/t:ab//t:app[not(@type)])
                                            for $app at $p in $node/t:ab//t:app[not(@type)]
                                                order by $p
                                            return
                                                viewItem:applisting($app, $p)
                                        }
                                        <hr/>
                                        {
                                            for $app in $node/t:ab//t:app[@type]
                                                group by $type := $app/@type
                                            return
                                                (<span
                                                    class="badge">{$type}</span>,
                                                for $a at $p in $app
                                                return
                                                    viewItem:applisting($a, $p)
                                                )
                                        }
                                    </div>
                                else
                                    (),
                                <div
                                    id="AllQuotations{$node/@n}"/>
                                )
                    }
                </div>
            else
                <div
                    class="w3-container">{$node}</div>
};

declare %private function viewItem:titletemplate($div, $text) {
    <div
        class="w3-bar">
        <div
            class="w3-bar-item">
            <i>
                {viewItem:TEI2HTML($div/t:label)}
                {
                    if ($div/parent::t:div[@type = 'edition']/@resp)
                    then
                        let $r := $div/parent::t:div[@type = 'edition']/@resp
                        return
                            ('Edition by ',
                            if (starts-with($r, '#'))
                            then
                                (
                                let $bmbiblid := substring-after($r, '#')
                                let $bibl := $div/ancestor::t:TEI//t:bibl[@xml:id = $bmbiblid]
                                let $t := string($bibl/t:ptr/@target)
                                return
                                    $viewItem:bibliography//b:entry[@id = $t]/b:reference/node())
                            else
                                ()
                            )
                    else
                        (
                        viewItem:editorName($div/parent::t:div[@type = 'edition']/@resp)
                        )
                }
                {
                    if ($div/@subtype) then
                        (
                        string($div/@subtype),
                        if ($div/@n) then
                            (': ',
                            string($div/@n)
                            )
                        else
                            (),
                        ' '
                        )
                    else
                        ()
                }
                {
                    if ($div/@corresp) then
                        (' (',
                        (if (starts-with($div/@subtype, '#')) then
                            (let $id := substring-after($div/@subtype, '#')
                            let $match := $div/ancestor::t:TEI//t:*[@xml:id = $id]
                            return
                                (viewItem:TEI2HTML($match/t:title),
                                <a
                                    href="{$div/@corresp}">{$id}</a>
                                )
                            )
                        else
                            (
                            <a
                                href="{$div/@corresp}">
                               {exptit:printTitle(string($div/@corresp))}
                                <span
                                    class="glyphicon glyphicon-share"/>
                            </a>

                            )
                        )
                        ,
                        ')')
                    else
                        ()
                }
                {
                    if ($div/@corresp and $div/ancestor::t:TEI/@type = 'work')

                    then
                        <span
                            class="parallelversions  w3-tooltip">
                            <a
                                class="parallelversion w3-red"
                                data-textid="{$text}"
                                data-unit="{$div/@corresp}">
                                Versions
                            </a>
                            <span
                                class="w3-tag w3-text">See parallel versions if any is available</span>
                        </span>

                    else
                        ()
                }
            </i>
        </div>
        {
            if ($div/t:ab[descendant::text()]) then
                (<div
                    class="ugaritcontrols w3-tooltip w3-bar-item w3-button w3-padding-small w3-gray w3-right">
                    <a
                        class="ugarit  w3-small"
                        href="https://alignment.alpheios.net/">
                        Alignment
                    </a>
                    <span
                        class="w3-text w3-tag">Start a translation alignment with Alpheios Alignment. You can also add morphological annotations there. See <a
                            href="https://github.com/BetaMasaheft/alpheiosannotations">instructions in GitHub</a>. </span>
                </div>
                ,
                if ($div/@corresp) then
                    <div
                        class="parallelversions w3-tooltip w3-bar-item w3-button w3-padding-small w3-gray w3-right">
                        <a
                            class="parallelversion  w3-small"
                            data-textid="{$text}"
                            data-unit="{$div/@corresp}">
                            Versions
                        </a>
                        <span
                            class="w3-text w3-tag">See parallel versions if any is available</span>
                    </div>
                else
                    (),
                <div
                    class="quotations w3-tooltip w3-bar-item w3-button w3-padding-small w3-gray w3-right">
                    <a
                        id="quotations{$div/@n}"
                        class="quotations  w3-small"
                        data-textid="{$text}"
                        data-unit="{$div/@n}">
                        Quotations
                    </a>
                    <span
                        class="w3-text w3-tag">Check for marked up quotations of a passage in this section</span>
                </div>
                ,

                <a
                    href="#"
                    class="w3-button w3-padding-small w3-gray w3-right w3-bar-item"
                    onclick="document.getElementById('textHelp').style.display='block'">
                    <i
                        class="fa fa-info-circle"
                        aria-hidden="true"/>
                </a>
                )
            else
                ()
        }
        <a
            href="#transcription"
            class="page-scroll w3-button w3-padding-small w3-right w3-bar-item w3-gray">back to top</a>
    </div>
};


declare %private function viewItem:applisting($app, $p) {
    <span
        id="{string($app/ancestor::t:div[@type = 'textpart'][1]/@n)}appPointer{$p}">
        <a
            href="#{string($app/ancestor::t:div[@type = 'textpart'][1]/@n)}appnote{$p}">
            {count($app/preceding-sibling::t:app) + 1}
        </a>{')'}
        {viewItem:TEI2HTML($app/t:lem)}:
        {
            for $r in $app/*:rdg
            return
                try {
                    viewItem:rdg($r)
                } catch * {
                    $err:description
                }
        }
        {viewItem:TEI2HTML($app/t:note)}
        {
            if ($p = (count($app/preceding-sibling::t:app) + 1)) then
                ()
            else
                ' | '
        }
    </span>
};

declare %private function viewItem:DTSpartID($node) {
    if (count($node/t:ab/t:cb) ge 1)
    then
        string($node/preceding::t:pb[@n][1]/@n) || string($node/@n)
    else
        if ($node/@corresp)
        then
            string($node/@corresp)
        else
            if ($node/@n)
            then
                string($node/@n)
            else
                if ($node/@xml:id)
                then
                    string($node/@xml:id)
                else
                    if ($node/@subtype)
                    then
                        string($node/@subtype)
                    else
                        concat('tei:', $node/name(), '[', $node/position(), ']')
};

(:  as element(t:handDesc):)

declare function viewItem:TEI2HTML($nodes) {
    for $node in $nodes
(:        let $test := util:log('info',$node/name()):)
    return
        typeswitch ($node)
            (:        clears all comments:)
            case comment()
                return
                    ()
                    (:                    decides what to do for each named element, ordered alphabetically:)
            case element(t:ab)
                return
                    viewItem:ab($node)
            case element(t:abbr)
                return
                    viewItem:abbr($node)
             case element(t:accMat)
                return
                    viewItem:accMat($node)
            case element(t:acquisition)
                return
                    viewItem:acquisition($node)
            case element(t:add)
                return
                    viewItem:add($node)
            case element(t:additions)
                return
                    viewItem:additions($node)
            case element(t:adminInfo)
                return
                    viewItem:adminInfo($node)
            case element(t:altIdentifier)
                return
                    viewItem:altIdentifier($node)
            case element(t:app)
                return
                    viewItem:app($node)
            case element(t:bibl)
                return
                    viewItem:bibliographyitem($node)
            case element(t:bindingDesc)
                return
                    viewItem:bindingDesc($node)
            case element(t:birth)
                return
                    viewItem:date-like($node)
            case element(t:cb)
                return
                    viewItem:cb($node)
            case element(t:certainty)
                return
                    viewItem:certainty($node)
            case element(t:choice)
                return
                    viewItem:choice($node)
            case element(t:cit)
                return
                    viewItem:cit($node)
             case element(t:citeStructure)
                return
                    ()
            case element(t:classDecl)
                return
                    ()
            case element(t:collation)
                return
                    viewItem:VisColl($node)
            case element(t:collection)
                return
                    viewItem:collectionelement($node)
            case element(t:colophon)
                return
                    viewItem:colophon($node)
            case element(t:condition)
                return
                    viewItem:condition($node)
            case element(t:country)
                return
                    viewItem:namedEntity($node)
            case element(t:custEvent)
                return
                    viewItem:custEvent($node)
            case element(t:date)
                return
                    viewItem:date-like($node)
            case element(t:death)
                return
                    viewItem:date-like($node)
            case element(t:decoDesc)
                return
                    viewItem:decoDesc($node)
            case element(t:del)
                return
                    viewItem:del($node)
            case element(t:desc)
                return
                    viewItem:desc($node)
             case element(t:dimensions)
                return
                    viewItem:dimensions($node)
            case element(t:div)
                return
                    viewItem:div($node)
            case element(t:ex)
                return
                    viewItem:ex($node)
            case element(t:explicit)
                return
                    viewItem:explicit($node)
            case element(t:extent)
                return
                    viewItem:extent($node)
            case element(t:facsimile)
                return
                    ()
            case element(t:faith)
                return
                    viewItem:faith($node)
            case element(t:figure)
                return
                    viewItem:figure($node)
            case element(t:filiation)
                return
                    viewItem:filiation($node)
            case element(t:foliation)
                return
                    viewItem:foliation($node)
            case element(t:floruit)
                return
                    viewItem:date-like($node)
            case element(t:forename)
                return
                    viewItem:forename($node)
            case element(t:gap)
                return
                    viewItem:gap($node)
            case element(t:handDesc)
                return
                    viewItem:palaeography($node)
            case element(t:handShift)
                return
                    viewItem:handShift($node)
            case element(t:hi)
                return
                    viewItem:hi($node)
            case element(t:history)
                return
                    viewItem:history($node)
            case element(t:idno)
                return
                    viewItem:idno($node)
            case element(t:incipit)
                return
                    viewItem:incipit($node)
            case element(t:item)
                return
                    viewItem:item($node)
            case element(t:layoutDesc)
                return
                    viewItem:layoutDesc($node)
                    case element(t:lem)
                return
                    viewItem:lem($node)
            case element(t:list)
                return
                    viewItem:list($node)
            case element(t:listBibl)
                return
                    viewItem:listBibl($node)
            case element(t:label)
                return
                    viewItem:label($node)
            case element(t:lb)
                return
                    viewItem:lb($node)
            case element(t:lg)
                return
                    viewItem:lg($node)
            case element(t:l)
                return
                    viewItem:l($node)
            case element(t:locus)
                return
                    viewItem:locus($node)
            case element(t:measure)
                return
                    viewItem:measureelement($node)
            case element(t:metamark)
                return
                    ()
            case element(t:msContents)
                return
                    viewItem:msContents($node)
            case element(t:msDesc)
                return
                    viewItem:manuscriptStructure($node)

            case element(t:msFrag)
                return
                    viewItem:codicologicalUnit($node)
            case element(t:msItem)
                return
                    viewItem:msItem($node)
            case element(t:msPart)
                return
                    viewItem:codicologicalUnit($node)
            case element(t:nationality)
                return
                    viewItem:nationality($node)
            case element(t:note)
                return
                    viewItem:note($node)
            case element(t:orig)
                return
                    viewItem:orig($node)
            case element(t:origDate)
                return
                    viewItem:date-like($node)
            case element(t:origin)
                return
                    viewItem:TEI2HTML($node/node()[not(self::t:provenance)])
            case element(t:origPlace)
                return
                    viewItem:origplace($node)
            case element(t:p)
                return
                    <p>{viewItem:TEI2HTML($node/node())}</p>
            case element(t:pb)
                return
                    viewItem:pb($node)
            case element(t:persName)
                return
                    viewItem:namedEntity($node)
            case element(t:placeName)
                return
                    viewItem:namedEntity($node)
            case element(t:provenance)
                return
                    viewItem:provenance($node)
            case element(t:ptr)
                return
                    viewItem:ptr($node)
            case element(t:q)
                return
                    viewItem:qelement($node)
            case element(t:rdg)
                return
                    viewItem:rdg($node)
            case element(t:region)
                return
                    viewItem:namedEntity($node)
            case element(t:relation)
                return
                    viewItem:relation($node)
            case element(t:ref)
                return
                    viewItem:ref($node)

            case element(t:repository)
                return
                    viewItem:repository($node)
            case element(t:revisionDesc)
                return
                    viewItem:revisionDesc($node)
            case element(t:roleName)
                return
                    viewItem:roleName($node)
            case element(t:rs)
                return
                    viewItem:rs($node)
            case element(t:rubric)
                return
                    viewItem:rubric($node)
            case element(t:sealDesc)
                return
                    viewItem:sealDesc($node)
            case element(t:seg)
                return
                    viewItem:seg($node)
            case element(t:settlement)
                return
                    viewItem:namedEntity($node)
            case element(t:sic)
                return
                    viewItem:sic($node)
            case element(t:signatures)
                return
                    viewItem:signatures($node)
            case element(t:space)
                return
                    viewItem:space($node)
            case element(t:summary)
                return
                    viewItem:summary($node)
             case element(t:supplied)
                return
                    viewItem:supplied($node)
            case element(t:supportDesc)
                return
                    viewItem:supportDesc($node)
            case element(t:surname)
                return
                    viewItem:surname($node)
            case element(t:surrogates)
                return
                    viewItem:surrogates($node)
            case element(t:surplus)
                return
                    viewItem:surplus($node)
            case element(t:textLang)
                return
                    viewItem:textLang($node)
            case element(t:term)
                return
                    viewItem:term($node)
            case element(t:title)
                return
                    viewItem:namedEntity($node)
            case element(t:unclear)
                return
                    viewItem:unclear($node)
            case element(t:witness)
                return
                    viewItem:witness($node)
            case element(t:watermark)
                return
                    viewItem:watermark($node)


                    (:                        default passthrough for elments not specified:)
            case text()
                return
                    viewItem:tokenize-text($node)
            case element()
                return
                    viewItem:TEI2HTML($node/node())
            default
                return
                    $node
};

declare %private function viewItem:tokenize-text($node) {
    if ($node[
    (ancestor::t:*[@xml:lang])[1][@xml:lang = 'gez']][
    parent::t:*[name() != 'label'][name() != 'note'][name() != 'persName'][name() != 'placeName']]) then

        for $w in tokenize(normalize-space($node), '\s')
        return
            (<span class="word">{$w}</span>, ' ')
            else
            $node
};

declare %private function viewItem:standards($item) {
  (::  viewItem:zotero($item),::)
    viewItem:keywords($item, switch2:col($item/@type)),
    (::if ($item//t:editionStmt) then
        <div
            class="w3-container w3-small"
            id="editionStmt">
            <h3>Edition Statement</h3>
            {viewItem:TEI2HTML($item//t:editionStmt)}
        </div>
    else
        (),::)
     <button
        class="w3-button w3-gray w3-bar-item"
        onclick="openAccordion('pub')">Publication Statement</button>,
    <ul
        class="w3-bar-item w3-hide"
        id="pub">{viewItem:publicationStmt($item//t:publicationStmt)}
        </ul>,
        <button
        class="w3-button w3-gray w3-bar-item"
        onclick="openAccordion('enc')">Encoding Description</button>,
    <ul
        class="w3-bar-item w3-hide"
        id="enc">{viewItem:TEI2HTML($item//t:encodingDesc/node())}
        </ul>
};

declare %private function viewItem:work($item) {
    let $id := string($item/@xml:id)
    let $uri := viewItem:ID2URI($id)
    let $relsP := $viewItem:coll//t:relation[contains(@passive, $uri)]
    let $relsA := $viewItem:coll//t:relation[contains(@active, $uri)]
    let $rels := ($relsA | $relsP)
    return
        <div
            id="MainData"
            class="w3-twothird">
            <div
                id="description">
                {
                    if (count($item//t:titleStmt/t:title) ge 1)
                    then
                        (<h2>Titles</h2>,
                        <ul>
                            {
                                for $t in $item//t:titleStmt/t:title[not(@type = 'full')][@xml:id]
                                    order by $t/@xml:id,
                                        string-join($t/text())
                                return
                                    viewItem:worktitle($t)
                            }
                            {
                                for $t in $item//t:titleStmt/t:title[not(@type = 'full')][not(@xml:id or @corresp)]
                                    order by string-join($t/text())
                                return
                                    viewItem:worktitle($t)
                            }
                        </ul>
                        )
                    else
                        ()
                }
                {
                    let $attributed := $relsA[@name = 'saws:isAttributedToAuthor']
                    let $attributedp := $relsP[@name = 'saws:isAttributedAuthorOf']
                    let $creator := $relsA[@name = 'dcterms:creator']
                    return
                        if (count($item//t:author[not(parent::t:bibl)] | $attributed | $attributedp | $creator) ge 1)
                        then
                            (<h2>Authorship</h2>,
                            <ul>
                                {
                                    for $aut in ($attributed | $creator)
                                    return
                                        viewItem:workAuthLi($aut, 'p')
                                }
                                {
                                    for $aut in ($attributedp)
                                    return
                                        viewItem:workAuthLi($aut, 'a')
                                }
                                {
                                    for $aut in $item//t:author[not(parent::t:bibl)]
                                    return
                                        <li>{$aut}</li>
                                }

                            </ul>
                            )
                        else
                            ()
                }
                {
                    let $translator := $relsP[@name = 'betmas:isAuthorOfEthiopicTranslation']
                    let $translatora := $relsA[@name = 'betmas:isAuthorOfEthiopicTranslation']

                    return
                        if (count($translator | $translatora) ge 1)
                        then
                            (<h2>Translator</h2>,
                            <ul>
                                {
                                    for $a in ($translator)
                                    return
                                        viewItem:workAuthLi($a, 'a')
                                }
                                {
                                    for $a in ($translatora)
                                    return
                                        viewItem:workAuthLi($a, 'p')
                                }
                                {
                                    for $a in $item//t:author[not(parent::t:bibl)]
                                    return
                                        <li>{$a}</li>
                                }
                            </ul>
                            )
                        else
                            ()
                }
                {
                    if ((count($rels) ge 1) or $item//t:abstract) then
                        (<h2>General description</h2>,
                        viewItem:TEI2HTML($item//t:abstract),
                        viewItem:relsinfoblock($rels, $id))
                    else
                        ()
                }
                {
                    if ($item//t:extent) then
                        <p>
                            {viewItem:TEI2HTML($item//t:extent)}
                        </p>
                    else
                        ()
                }
                 {
                    if ($item//t:div[contains(@subtype, 'incipit')]) then
                        <p class="w3-small">
                          Incipit:
                            {viewItem:TEI2HTML($item//t:div[contains(@subtype, 'incipit')][1])}
                        </p>
                    else
                        ()
                }
                {
                    if ($item//t:creation) then
                        (
                        for $b in $item//t:creation[@when or @notBefore or @notAfter]
                        return
                            <p>Creation date: {viewItem:datepicker($b)}</p>,
                        <p>
                            {viewItem:TEI2HTML($item//t:creation)}
                            {
                                if ($item//t:creation/@evidence) then
                                    '(' || string($item//t:creation/@evidence) || ')'
                                else
                                    ()
                            }
                        </p>)
                    else
                        ()
                }
                {
                    if ($item//t:listWit) then
                        (<h2>Witnesses</h2>,
                        <p
                            class="alert alert-info">The following manuscripts are reported in this record as witnesses of the source of the information or the edition here encoded.
                            Please check the <a
                                href="#computedWitnesses">box on the right</a> for a live updated list of manuscripts pointing to this record.</p>,
                        if ($item//t:listWit/@rend = 'edition') then
                            <b>Manuscripts used in the edition</b>
                        else
                        if ($item//t:listWit) then
                            ()
                        else
                            (),
                        <ul>
                            {viewItem:TEI2HTML($item//t:listWit[not(parent::t:listWit)])}
                        </ul>
                        )
                    else
                        ()
                }
                {
                    if ($item//t:sourceDesc/t:p) then
                        viewItem:TEI2HTML($item//t:sourceDesc/t:p)
                    else
                        ()
                }
                {
                    for $b in $item//t:listBibl[@type = 'clavis']
                    return
                        <div
                            id="clavisbibliography">
                            {viewItem:bibliographyHeader($b)}
                            <ul
                                class="bibliographyList">
                                {viewItem:TEI2HTML($b)}
                            </ul>
                        </div>
                }
                {
                    for $b in $item//t:listBibl[not(@type = 'clavis')]
                    return
                        <div
                            id="bibliography">
                            {viewItem:bibliographyHeader($b)}
                            <ul
                                class="bibliographyList">
                                {viewItem:TEI2HTML($b)}
                            </ul>
                        </div>
                }
                {viewItem:standards($item)}
                {
                    if ($item//t:div[@type = 'edition']//t:ab//text()) then
                        <a
                            class="w3-button w3-gray"
                            target="_blank"
                            href="http://voyant-tools.org/?input=https://betamasaheft.eu/works/{$id}.xml">Voyant</a>
                    else
                        ()
                }
                <button
                    class="w3-button w3-red"
                    id="showattestations"
                    data-value="work"
                    data-id="{$id}">Show attestations</button>
                <div
                    id="allattestations"
                    class="w3-container"/>
            </div>
            {viewItem:resp($item)}
        </div>
};

declare %private function viewItem:resp($item) {
    <div
        class="w3-hide">
        {
            for $r in distinct-values($item//@resp)
            return
                <span
                    id="{$r}Name">
                    {$viewItem:editors//t:item[@xml:id = $r]/text()}
                </span>
        }
    </div>
};

declare %private function viewItem:relsinfoblock($rels, $id) {
    <p>
        {
            let $notFormrly := $rels[not(@name = 'betmas:formerlyAlsoListedAs')][not(@name = 'betmas:isAuthorOfEthiopicTranslation')][@name = 'saws:isAttributedToAuthor'][@name = 'dc:creator']
            return
                if (count($notFormrly) ge 1) then
                    ('See ',
                    for $r in $notFormrly
                    return
                        viewItem:TEI2HTML($r)
                    )
                else
                    ()
        }
    </p>,
    <p
        class="w3-tiny">For a table of all relations from and to this record,
        please go to the <a
            class="w3-tag w3-gray"
            href="{$config:appUrl}/{switch2:col(switch2:switchPrefix($id))}/{$id}/analytic">Relations</a> view.
        In the Relations boxes on the right of this page, you can also find all available relations grouped by name.
    </p>
};


declare %private function viewItem:narrative($item) {
    (:replaces nar.xsl :)
    let $id := string($item/@xml:id)
    let $uri := viewItem:ID2URI($id)
    let $relsP := $viewItem:coll//t:relation[contains(@passive, $uri)]
    let $relsA := $viewItem:coll//t:relation[contains(@active, $uri)]
    let $rels := ($relsA | $relsP)
    let $mainidno := $item//t:msIdentifier/t:idno
    return
        <div
            id="MainData"
            class="w3-twothird">
            <div
                id="description">
                <h2>General description</h2>
                <p>{viewItem:TEI2HTML($item//t:body)}</p>
                {
                    if ($item//t:witness) then
                        (<h2>Witnesses</h2>,
                        <p>(check also the dynamic list in the box)</p>,
                        <ul>
                            {viewItem:TEI2HTML($item//t:listWit)}</ul>)
                    else
                        ()
                }
                {
                    for $b in $item//t:listBibl
                    return
                        <div
                            id="bibliography">
                            <h3>{viewItem:bibliographyHeader($b)}</h3>
                            {viewItem:TEI2HTML($b)}

                        </div>
                }
                {viewItem:relsinfoblock($rels, $id)}
            </div>
            {viewItem:standards($item)}
        </div>

};
declare %private function viewItem:person($item) {
    (:replaces Person.xsl :)
    let $id := string($item/@xml:id)
    let $uri := viewItem:ID2URI($id)
    let $relsP := $viewItem:coll//t:relation[contains(@passive, $uri)]
    let $relsA := $viewItem:coll//t:relation[contains(@active, $uri)]
    let $rels := ($relsA | $relsP)
    let $mainidno := $item//t:msIdentifier/t:idno
    let $prs := $item//(personGrp | person)/persName
    return
        <div
            class="w3-twothird"
            id="MainData">
            <div
                class="w3-container">
                <div
                    class="w3-threequarter w3-padding"
                    id="history">
                    {viewItem:divofperson($item, 'persName')}
                    {viewItem:divofperson($item, 'birth')}
                    {viewItem:divofperson($item, 'education')}
                    {viewItem:divofperson($item, 'floruit')}
                    {viewItem:divofperson($item, 'death')}
                    {
                    let $membera := $relsA[@name = 'snap:Group']
                    return
                        if (count($membera) ge 1)
                        then
                            (<h4>Group of</h4>,
                            <ul class="w3-small">
                                {
                                    for $m in ($membera)
                                    return
                                        viewItem:workAuthLi($m, 'p')
                                }
                            </ul>
                            )
                        else
                            ()
                    }
                    {
                    let $memberp := $relsP[@name = 'snap:Group']
                    return
                        if (count($memberp) ge 1)
                        then
                            (<h4>Member of</h4>,
                            <ul class="w3-small">
                                {
                                    for $m in ($memberp)
                                    return
                                        viewItem:workAuthLi($m, 'a')
                                }
                            </ul>
                            )
                        else
                            ()
                    }
                    {
                    let $attributed := $relsP[@name = 'saws:isAttributedToAuthor']
                    let $attributedp := $relsA[@name = 'saws:isAttributedAuthorOf']
                    let $creator := $relsP[@name = 'dcterms:creator']
                    return
                        if (count($attributed | $attributedp | $creator) ge 1)
                        then
                            (<h4>Author of</h4>,
                            <ul class="w3-small">
                                {
                                    for $aut in ($attributed | $creator)
                                    return
                                        viewItem:workAuthLi($aut, 'a')
                                }
                                {
                                    for $aut in ($attributedp)
                                    return
                                        viewItem:workAuthLi($aut, 'p')
                                }


                            </ul>
                            )
                        else
                            ()
                }
                {
                    let $translator := $relsA[@name = 'betmas:isAuthorOfEthiopicTranslation']
                    let $translatora := $relsP[@name = 'betmas:isAuthorOfEthiopicTranslation']

                    return
                        if (count($translator | $translatora) ge 1)
                        then
                            (<h4>Translator of</h4>,
                            <ul class="w3-small">
                                {
                                    for $a in ($translator)
                                    return
                                        viewItem:workAuthLi($a, 'p')
                                }
                                {
                                    for $a in ($translatora)
                                    return
                                        viewItem:workAuthLi($a, 'a')
                                }
                            </ul>
                            )
                        else
                            ()
                }

                    {
                        if ($item//t:person/t:note) then
                            for $n in $item//t:person/t:note
                            return
                                <div
                                    class="w3-container">
                                    <h4>{
                                            if ($n/@type) then
                                                viewItem:capitalize-first($n/@type)
                                            else
                                                'Notes'
                                        }</h4>
                                    {viewItem:TEI2HTML($n)}
                                </div>
                        else
                            ()
                    }
                    {viewItem:relsinfoblock($rels, $id)}
                    <button
                        class="w3-button w3-red w3-large"
                        id="showattestations"
                        data-value="person"
                        data-id="{$id}">Show attestations</button>
                    <div
                        id="allattestations"
                        class="w3-container"/>
                </div>
                <div
                    class="w3-quarter w3-panel w3-red w3-card-4 w3-padding "
                    id="description"
                    rel="http://xmlns.com/foaf/0.1/name">
                    <h3>Names {
                            switch ($item//t:person/@sex)
                                case '1'
                                    return
                                        <i
                                            class="fa fa-mars"/>
                                case '2'
                                    return
                                        <i
                                            class="fa fa-venus"/>
                                default return
                                    ()
                    }
                    {
                        if ($item//t:person/@sameAs) then
                            <a
                                href="{viewItem:reflink($item//t:person/@sameAs)}">
                                <span
                                    class="icon-large icon-vcard"/>
                            </a>
                        else
                            ()
                    }
                </h3>
                <ul
                    class="nodot">
                    {
                        for $name in $item//(t:personGrp | t:person)/t:persName[not(@corresp)]
                        let $nameid := $name/@xml:id
                        return
                            <li>{
                                    if ($nameid) then
                                        attribute
                                        id {$nameid}
                                    else
                                        ()
                                }{
                                    if ($name/@type) then
                                        string($name/@type) || ': '
                                    else
                                        ()
                                }
                                {viewItem:TEI2HTML($name/t:roleName)}
                                {
                                    if ($name/@ref) then
                                        <a
                                            href="{@ref}"
                                            target="_blank">{viewItem:TEI2HTML($name/node()[not(self::t:roleName)])}</a>
                                    else
                                        (viewItem:TEI2HTML($name/node()[not(self::t:roleName)]), ' ')
                                }
                                {viewItem:sup($name)}
                                {
                                    if ((count($nameid) gt 1) and $item//t:persName[matches(@corresp, $nameid)]) then
                                        ('(',
                                        let $corrnames := for $corrname in $item//t:persName[matches(@corresp, $nameid)]
                                            order by string-join($corrname/text())
                                        return
                                            ($corrname/text(),
                                            viewItem:sup($corrname)
                                            )
                                        return
                                            viewItem:joinmixed($corrnames),
                                        ')')
                                    else
                                        ()
                                }
                            </li>
                    }
                </ul>
                {
                    if ($item//(t:floruit | t:birth | t:death)/@*) then
                        (<h3>Dates </h3>,
                        for $b in $item//t:birth[@when or @notBefore or @notAfter]
                        return
                            <p>Birth: {viewItem:datepicker($b)}</p>,
                        for $b in $item//t:floruit[@when or @notBefore or @notAfter]
                        return
                            <p>Period of activity: {viewItem:datepicker($b)}</p>,
                        for $b in $item//t:death[@when or @notBefore or @notAfter]
                        return
                            <p>Death: {viewItem:datepicker($b)}</p>
                        )
                    else
                        ()
                }

            {
                if ($item//t:occupation) then
                    (<h3>Occupation</h3>,
                    for $o in $item//t:occupation
                    return
                        <p
                            class="lead"
                            property="http://data.snapdrgn.net/ontology/snap#occupation">
                            {viewItem:date-like($o)}
                        </p>
                    )
                else
                    ()
            }
            {
                for $othernodes in ('residence', 'faith', 'nationality')
                return
                    viewItem:divofperson($item, $othernodes)
            }
             {
                    let $successor := $relsA[@name = 'betmas:isSuccessorOf']
                       return
                        if (count($successor) ge 1)
                        then
                            (<h6></h6>,
                            <ul class="w3-small nodot">
                                {
                                    for $aut in ($successor)
                                    return
                                        <li>Predecessor: {viewItem:personAuthLi($aut, 'p')}</li>
                                }
                            </ul>
                            )
                        else
                            ()
                }
                             {
                    let $predecessor := $relsA[@name = 'betmas:isPredecessorOf']
                       return
                        if (count($predecessor) ge 1)
                        then
                            (<h6></h6>,
                            <ul class="w3-small nodot">
                                {
                                    for $aut in ($predecessor)
                                    return
                                        <li>Successor: {viewItem:personAuthLi($aut, 'p')}</li>
                                }
                            </ul>
                            )
                        else
                            ()
                }
                                {
                    let $about := $relsP[@name = 'ecrm:P129_is_about']
                    let $subject := $relsA[@name = 'ecrm:P129i_is_subject_of']
                       return
                        if (count($about | $subject) ge 1)
                        then
                            (<h6>Subject of</h6>,
                            <ul class="w3-small">
                                {
                                    for $aut in ($about)
                                    return
                                        viewItem:workAuthLi($aut, 'a')
                                }
                                {
                                    for $aut in ($subject)
                                    return
                                        viewItem:workAuthLi($aut, 'p')
                                }


                            </ul>
                            )
                        else
                            ()
                }
                </div>
            <div
                id="bibliography" class="w3-container">
                <h3>{viewItem:bibliographyHeader($item//t:listBibl)}</h3>
                {viewItem:TEI2HTML($item//t:listBibl)}

            </div>
            {viewItem:standards($item)}
        </div>
        {viewItem:resp($item)}
    </div>
};
declare %private function viewItem:place($item) {
    (:replaces placesInstit.xsl :)
    let $id := string($item/@xml:id)
    let $uri := viewItem:ID2URI($id)
    let $relsP := $viewItem:coll//t:relation[contains(@passive, $uri)]
    let $relsA := $viewItem:coll//t:relation[contains(@active, $uri)]
    let $rels := ($relsA | $relsP)
    return
        (if ($item//t:figure) then
            <script
                type="text/javascript"
                src="resources/openseadragon/openseadragon.min.js"/>
        else
            (),
        <div
            id="MainData"
            class="w3-twothird">
            <div
                id="description">
                <h2>Names {
                        if ($item//t:place/@sameAs) then
                            for $sa in viewItem:makeSequence($item//t:place/@sameAs)
                            let $url := viewItem:reflink($sa)
                            return
                                <a
                                    href="{$url}">
                                    <span
                                        class="icon-large icon-globe"/>
                                </a>
                        else
                            ()
                    }{
                        if ($id = 'INS0880WHU') then
                            <a
                                href="https://betamasaheft.eu/tweed.html"><span
                                    class="w3-tag w3-red">Tweed Collection</span></a>
                        else
                            ()
                    }
                </h2>
                <div
                    class="placeNames w3-container">
                    {viewItem:divofplacepath($item, "//t:placeName", ' ', 2)}
                    {
                        for $name in $item//t:place/t:placeName[@xml:id]
                        return
                            <div
                                class="w3-container"
                                rel="http://lawd.info/ontology/hasName">
                                <p
                                    class="lead"
                                    id="{$name/@xml:id}">
                                    <i
                                        class="fa fa-chevron-right"
                                        aria-hidden="true"/>
                                    {
                                        if ($name/@type) then
                                            concat($name/@type, ': ')
                                        else
                                            ()
                                    }
                                    {
                                        if ($name/@ref) then
                                            <a
                                                href="{$name/@ref}"
                                                target="_blank"
                                                property="http://lawd.info/ontology/primaryForm">{$name/text()}</a>
                                        else
                                            $name/text()
                                    }
                                    {viewItem:sup($name)}
                                    {viewItem:TEI2HTML($name/t:note)}
                                    {
                                        let $nameid := $name/@xml:id
                                        let $corrs := $item//t:place/t:placeName[ends-with(@corresp, $id)]
                                        return
                                            if (count($corrs) ge 1) then
                                                (' (',
                                                let $corrnames := for $corrname in $item//t:place/t:placeName[ends-with(@corresp, $id)]
                                                return
                                                    ($corrname/text(), viewItem:sup($corrname))
                                                return
                                                    viewItem:joinmixed($corrnames)
                                                ,
                                                ')')
                                            else
                                                ()
                                    }
                                </p>
                                {
                                    if ($item//t:place/t:placeName[not(@xml:id) and not(@corresp)]) then
                                        for $name in $item//t:place/t:placeName[not(@xml:id) and not(@corresp)]
                                        return
                                            <div
                                                class="w3-container"
                                                rel="http://lawd.info/ontology/hasName">
                                                <p>{
                                                        if ($name/@type) then
                                                            concat($name/@type, ': ')
                                                        else
                                                            ()
                                                    }
                                                    {
                                                        if ($name/@ref) then
                                                            <a
                                                                href="{$name/@ref}"
                                                                target="_blank"
                                                                property="http://lawd.info/ontology/variantForm">{$name/text()}</a>
                                                        else
                                                            $name/text()
                                                    }
                                                    {viewItem:sup($name)}
                                                </p>
                                            </div>
                                    else
                                        ()
                                }
                            </div>
                    }
                </div>
                 {viewItem:osm($item)}

                {viewItem:divofplacepath($item, "//t:ab[@type = 'description']", 'General information', 3)}
                {viewItem:divofplacepath($item, "//t:location[@type='relative']", 'Location', 3)}
                {viewItem:divofplacepath($item, "//t:ab[@type = 'appellations'][child::*]", 'Appellations', 3)}
                {viewItem:divofplacepath($item, "//t:date[@type = 'foundation']", 'Foundation date', 3)}
                {viewItem:divofplacepath($item, "//t:desc[@type = 'foundation']", 'Foundation story', 3)}
                {viewItem:divofplacepath($item, "//t:ab[@type = 'history']", 'History', 3)}
                {viewItem:divofplacepath($item, "//t:ab[@type = 'tabot']", 'Tābots', 3)}
                {viewItem:TEI2HTML($item//t:listBibl)}
                {viewItem:divofplacepath($item, "//t:note[not(descendant::t:ab)][not(descendant::t:listBibl)][not(parent::t:placeName)][not(@source)][not(starts-with(@type,'tag'))][not(starts-with(@type,'url'))]", 'Other', 3)}
                <button
                    class="w3-button w3-red w3-large"
                    id="showattestations"
                    data-value="place"
                    data-id="{string($item/@xml:id)}">Show attestations</button>
                <div
                    id="allattestations"
                    class="w3-container"/>
            </div>
            {viewItem:relsinfoblock($rels, $item)}
            {viewItem:standards($item)}
        </div>,
        viewItem:resp($item)
        )

};


declare %private function viewItem:joinmixed($sequence) {
    for $c at $p in $sequence
    return
        ($c,
        if ($p = count($sequence)) then
            ''
        else
            ', ')
};

declare %private function viewItem:auth($item) {
    (:replaces auth.xsl :)
    let $id := string($item/@xml:id)
    let $uri := viewItem:ID2URI($id)
    let $relsP := $viewItem:coll//t:relation[contains(@passive, $uri)]
    let $relsA := $viewItem:coll//t:relation[contains(@active, $uri)]
    let $rels := ($relsA | $relsP)
    let $mainidno := $item//t:msIdentifier/t:idno
    return
        <div
            id="MainData"
            class="w3-twothird">
            <div
                id="description">
                <h2>General description</h2>
                <div>{viewItem:TEI2HTML($item//t:sourceDesc)}</div>
                <div>{viewItem:TEI2HTML($item//t:abstract)}</div>

                {viewItem:relsinfoblock($rels, $id)}
                <div
                    id="bibliography">
                    <h3>{viewItem:bibliographyHeader($item//t:listBibl)}</h3>
                    {viewItem:TEI2HTML($item//t:listBibl)}

                </div>
                 <button  class="w3-button w3-red"><a href="https://betamasaheft.eu/authority-files/list?keyword={$id}" target="_blank">List of entities using the keyword</a></button>
                <button
                    class="w3-button w3-red"
                    id="showattestations"
                    data-value="term"
                    data-id="{$id}">Show attestations</button>
                <div
                    id="allattestations"
                    class="w3-container"/>


            </div>
            {viewItem:standards($item)}
        </div>
};

declare %private function viewItem:corpus($item) {
    viewItem:documents($item)
};

declare %private function viewItem:manuscript($item) {
    (:replaces mss.xsl :)
    let $id := string($item/@xml:id)
    let $uri := viewItem:ID2URI($id)
    let $relsP := $viewItem:coll//t:relation[contains(@passive, $uri)]
    let $relsA := $viewItem:coll//t:relation[contains(@active, $uri)]
    let $rels := ($relsA | $relsP)
    let $mainidno := $item//t:msIdentifier/t:idno

    return
        <div

            id="MainData">
            <span
                property="http://www.cidoc-crm.org/cidoc-crm/P48_has_preferred_identifier"
                content="{$id}"/>
            <div
                class="w3-container"
                id="description"
                typeof="http://lawd.info/ontology/AssembledWork https://betamasaheft.eu/mss">
                {
                    if ($item//t:date[@evidence = 'internal-date'] or $item//t:origDate[@evidence = 'internal-date']) then
                        <h1>
                            <span
                                class="label label-primary">Dated</span>
                        </h1>
                    else
                        ()
                }
                <div
                    id="maintoogles"
                    class="btn-group">
                    <div
                        class="w3-bar">
                        {
                            if ($item//t:collection[. = 'Tweed Collection']) then
                                <a
                                    class="w3-bar-item  w3-hide-medium w3-hide-small w3-button w3-red"
                                    href="https://betamasaheft.eu/tweed.html">Tweed Collection</a>
                            else
                                ()
                        }
                        <button
                    class="w3-bar-item w3-button w3-red"
                            id="showattestations"
                            data-value="mss"
                            data-id="{$id}">Show attestations</button>
                        <a
                            class="w3-bar-item  w3-hide-medium w3-hide-small w3-button w3-gray"
                            id="togglecodicologicalInformation"><span
                                class="showHideText">Hide</span> codicological information</a>
                        <a
                            class="w3-bar-item w3-hide-medium w3-hide-small w3-button w3-gray"
                            id="toggletextualcontents"><span
                                class="showHideText">Hide</span> contents</a>
                    </div>
                </div>

                <div
                    class="w3-third">
                    <h2>General description</h2>
                </div>
                <div
                    class="w3-third"/>
                <!--       <div
                    class="w3-third">
                    {
                        if ($item//t:listPerson/t:person/t:persName[@ref]) then
                            (<h3>People</h3>,
                            for $person in $item//t:listPerson/t:person
                            return
                                <p>
                                    {viewItem:TEI2HTML($person/node())}
                                </p>
                            )
                        else
                            ()
                    }
                </div>-->

                <div
                    id="allattestations"
                    class="w3-container"/>
                <div
                    class="w3-third  w3-padding">
                    <h4
                        property="http://purl.org/dc/elements/1.1/title"
                        class="toptitle">
                        {$item//t:titleStmt/t:title[not(@type = 'full')]/text()}
                    </h4>
                </div>

                <span
                    property="http://www.cidoc-crm.org/cidoc-crm/P57_has_number_of_parts"
                    content="{count($item//t:msContents/t:msItem)}"/>
                <div
                    class="w3-third  w3-padding">
                    <h4>Number of Codicological units: <span
                            class="label label-default">
                            {
                                if (count($item//(t:msPart | t:msFrag)) ge 1) then
                                    count($item//(t:msPart | t:msFrag))
                                else
                                    1
                            }
                        </span>
                    </h4>
                </div>

                {viewItem:relsinfoblock($rels, $id)}
                <div
                    class="w3-container"
                    id="generalphysical">
                    {viewItem:TEI2HTML($item//t:msDesc)}
                </div>
                <img
                    id="loadingRole"
                    src="resources/Loading.gif"
                    style="display: none;"/>
                <div
                    id="roleAttestations"/>
            </div>
            {viewItem:standards($item)}
            {viewItem:calendartables($item)}
        </div>
};

declare %private function viewItem:divofperson($item, $element) {
let $path := '$item//(t:person | t:personGrp)/t:'||$element
    let $this := util:eval($path)
    return
        if (count($this) ge 1) then
            <div
                class="w3-container"
                id="{$element}">
                <h4>{
                        if ($element = "floruit") then
                            'Period of Activity'
                        else
                            if ($element = "persName") then
                            'Names'
                        else
                            viewItem:capitalize-first($element)
                    }</h4>
                <p>
                    {viewItem:TEI2HTML($this)}
                </p>
            </div>
        else
            ()
};

declare %private function viewItem:divofmanuscript($msDesc, $element, $label) {
    let $this := $msDesc/t:*[name() = $element]
    return
        if (count($this) ge 1) then
            <div
                id="{$this/@xml:id}{$label}"
                class="w3-container w3-margin-bottom">
                {viewItem:TEI2HTML($this)}
            </div>
        else
            ()
};

declare %private function viewItem:divofmanuscriptpath($msDesc, $path, $label) {
    let $this := util:eval(concat('$msDesc', $path))
    return
        if (count($this) ge 1) then
            <div
                id="{$this/@xml:id}{$label}"
                class="w3-container w3-margin-bottom">
                {if(ends-with($path, "msContents")) then viewItem:msContents($this) else viewItem:TEI2HTML($this)}
            </div>
        else
            ()
};

declare %private function viewItem:divofplacepath($place, $path, $label, $level) {
    let $this := util:eval(concat('$place', $path))
    return
        if (count($this) ge 1) then
            (if ($level = 2) then
                <h2>{$label}</h2>
            else
                <h3>{$label}</h3>,
            <p
                class="w3-container w3-margin-bottom">
                {viewItem:TEI2HTML($this)}
            </p>)
        else
            ()
};

declare %private function viewItem:partofmanuscript($item, $path) {
    let $this := util:eval(concat('$item', $path))
    return
        if (count($this) ge 1) then
            viewItem:TEI2HTML($this)
        else
            ()
};

declare %private function viewItem:manuscriptStructure($msDesc) {
    (:replaces msselements.xsl:)
    (<div
        class="w3-twothird well"
        id="textualcontents{$msDesc/@xml:id}">
        <div
            class="w3-half">
            {viewItem:divofmanuscript($msDesc, 'history', 'history')}
        </div>
        <div
            class="w3-half">
            {viewItem:partofmanuscript($msDesc, '/t:msContents/t:summary')}
        </div>
        {viewItem:divofmanuscriptpath($msDesc, '/t:msContents', 'content')}
        {viewItem:divofmanuscriptpath($msDesc, '/t:physDesc/t:additions', 'additiones')}
        {viewItem:divofmanuscriptpath($msDesc, '/t:physDesc/t:decoDesc', 'decorations')}
        {viewItem:divofmanuscriptpath($msDesc, '/t:additional', 'additionals')}
    </div>,
    <div
        class="w3-third w3-border-left"
        id="codicologicalInformation{$msDesc/@xml:id}">
        {viewItem:divofmanuscriptpath($msDesc, '/t:physDesc//t:objectDesc/t:supportDesc', 'dimensions')}
        {viewItem:divofmanuscriptpath($msDesc, '/t:physDesc//t:bindingDesc', 'binding')}
        {viewItem:divofmanuscriptpath($msDesc, '/t:physDesc//t:accMat', 'accompanying material')}
        {viewItem:divofmanuscriptpath($msDesc, '/t:physDesc//t:sealDesc', 'seals')}
        {viewItem:divofmanuscriptpath($msDesc, '/t:physDesc//t:objectDesc/t:layoutDesc', 'layout') (:dimensions again! :)}
        {viewItem:divofmanuscriptpath($msDesc, '/t:physDesc/t:handDesc', 'hands')}
        {
            if ($msDesc/ancestor::t:TEI//t:persName[@role])
            then
                <div
                    id="perswithrolemainview"
                    class="w3-panel w3-red w3-card-4 w3-margin-bottom">
                    {
                        for $person in $msDesc/ancestor::t:TEI//t:persName[@role]
                            group by $ref := $person/@ref
                        return
                            (<a
                                xmlns="http://www.w3.org/1999/xhtml"
                                href="{$ref}"
                                class="persName">
                                {
                                    for $r in $ref
                                    return
                                        (viewItem:TEI2HTML($r/t:choice), viewItem:TEI2HTML($r/t:roleName), viewItem:TEI2HTML($r/t:hi))
                                }{exptit:printTitle($ref)}
                            </a>,
                            let $roles := for $role in $ref/@role
                            return
                                $role
                            return
                                string-join($roles, ', '), <br/>)
                    }
                </div>
            else
                ()
        }

    </div>,
    viewItem:divofmanuscriptpath($msDesc, '/t:msPart', 'parts'),
    viewItem:divofmanuscriptpath($msDesc, '/t:msFrag', 'fragments')
    )
};


declare %private function viewItem:codicologicalUnit($mspart) {
    <div
        class="w3-container w3-margin-bottom"
        id="{$mspart/@xml:id}">
        <div
            class="w3-container w3-margin-bottom">
            <h2>Codicological Unit {substring($mspart/@xml:id, 1)}
            </h2>

        </div>
        <div
            class="w3-twothird"
            id="textualcontents{$mspart/@xml:id}">
            <div
                class="w3-panel w3-card-2 w3-margin-right">
                {viewItem:TEI2HTML($mspart/t:msIdentifier)}
            </div>
        </div>
        {viewItem:manuscriptStructure($mspart)}
    </div>

};

declare %private function viewItem:calendartables($item) {
    for $date in $item//t:date[@calendar] | $item//t:origDate[@calendar]
    let $id := generate-id($date)
    return
        <div
            class="w3-hide">
            <div
                class="w3-responsive w3-hide popuptext"
                id="dateInfo{$id}">

                <table
                    class="w3-table w3-hoverable">
                    <thead>
                        <tr>
                            <th>info</th>
                            <th>value</th>
                        </tr>
                    </thead>
                    <tbody>
                        <tr>
                            <td>Standard date</td>
                            <td>
                                {viewItem:dates($date)}
                            </td>
                        </tr>
                        <tr>
                            <td>Date in current calendar</td>
                            <td>
                                {viewItem:dates-custom($date)}
                            </td>
                        </tr>
                        <tr>
                            <td>Calendar</td>
                            <td>
                                {string($date/@calendar)}
                            </td>
                        </tr>
                        {
                            if ($date/@dur) then
                                <tr>
                                    <td>Duration</td>
                                    <td>
                                        {string($date/@dur)}
                                    </td>
                                </tr>
                            else
                                ()
                        }
                        {
                            if ($date/@type) then
                                <tr>
                                    <td>Date type</td>
                                    <td>
                                        {string($date/@type)}
                                    </td>
                                </tr>
                            else
                                ()
                        }
                        {
                            if ($date/@evidence) then
                                <tr>
                                    <td>Evidence</td>
                                    <td>
                                        {string($date/@evidence)}
                                    </td>
                                </tr>
                            else
                                ()
                        }
                        {
                            if ($date/@cert) then
                                <tr>
                                    <td>Certainty</td>
                                    <td>
                                        {string($date/@cert)}
                                    </td>
                                </tr>
                            else
                                ()
                        }
                        {
                            if ($date/@resp) then
                                <tr>
                                    <td>Attribution</td>
                                    <td>
                                        {
                                            if (starts-with($date/@resp, 'PRS') or starts-with($date/@resp, 'ETH')) then
                                                exptit:printTitle($date/@resp)
                                            else if (starts-with($date/@resp, 'bm:')) then string($date/@resp)
                                            else
                                                viewItem:editorName($date/@resp)
                                        }
                                    </td>
                                </tr>
                            else
                                ()
                        }

                    </tbody>
                </table>
            </div>
        </div>

};

declare function viewItem:main($item) {
    (:replaces the switch in items.xql, redirecting to distinct xslts :)
    let $type := $item/@type
    return
        switch ($type)
            case 'work'
                return
                    viewItem:work($item)
            case 'studies'
                return
                    viewItem:work($item)
            case 'nar'
                return
                    viewItem:narrative($item)
            case 'pers'
                return
                    viewItem:person($item)
            case 'place'
                return
                    viewItem:place($item)
            case 'ins'
                return
                    viewItem:place($item)
            case 'auth'
                return
                    viewItem:auth($item)
            case 'mss'
                return
                    viewItem:manuscript($item)
            default return
                viewItem:corpus($item)
};

declare function viewItem:relations($rels) {
    (:replaces relation.xsl:)
    viewItem:TEI2HTML($rels)
};

declare function viewItem:documents($doc) {
    (:replaces documents.xsl:)
    (<div
        class="w3-container">
        <div
            class="w3-twothird w3-padding w3-card-4">
            <div
                class="w3-row w3-padding w3-margin-bottom w3-red">
                {viewItem:TEI2HTML($doc//t:note[@type = 'résumé'])}
                <span
                    class="w3-tag w3-gray">
                    {viewItem:TEI2HTML($doc//t:date)}
                </span>
            </div>
            <div
                class="w3-row w3-margin-bottom">
                <div
                    class="w3-half w3-padding"
                    lang="gez">
                    {viewItem:TEI2HTML($doc//t:q[@xml:lang = 'gez'])}
                </div>
                <div
                    class="w3-half w3-padding">
                    {viewItem:TEI2HTML($doc//t:q[not(@xml:lang = 'gez')])}
                </div>
                <div
                    class="footnotes">
                    {viewItem:TEI2HTML($doc//t:note[@n][@xml:id])}
                </div>
            </div>
        </div>
        <div
            class="w3-third w3-padding w3-card-4 w3-gray">
            {viewItem:TEI2HTML($doc//t:note[not(@n)][not(@xml:id)][not(@type = 'résumé')])}
            {viewItem:TEI2HTML($doc//t:listBibl)}
        </div>

    </div>,
    <hr/>)
};

declare function viewItem:q($q) {
    (:replaces q.xsl:)
    <div
        class="w3-container w3-gray">
        {viewItem:TEI2HTML($q)}
    </div>
    ,
    for $n in $q//t:note
    return
        <div
            class="w3-container">
            {viewItem:TEI2HTML($n)}
        </div>

};

declare function viewItem:dates-custom($date) {
    if ($date/@notBefore-custom and $date/@notAfter-custom) then
        (viewItem:date($date/@notBefore-custom) || '-' || viewItem:date($date/@notAfter-custom))
    else
        if ($date/@notAfter-custom and not($date/@notBefore-custom)) then
            ('Before ' || viewItem:date($date/@notAfter-custom))
        else
            if (not($date/@notAfter-custom) and $date/@notBefore-custom) then
                ('After ' || viewItem:date($date/@notBefore-custom))
            else
                if ($date/@when-custom) then
                    string($date/@when-custom)
                else
                    ('no *-custom attributes')
};

declare function viewItem:dates($date) {
    (:replaces dates.xsl expects origDate, floruit, death or birth returns a string:)
    let $dates := if ($date/@when) then
        string($date/@when)
    else
        if ($date/(@from | @to)) then
            if ($date/@from and $date/@to) then
                (viewItem:date($date/@from) || '-' || viewItem:date($date/@to))
            else
                if ($date/@from and not($date/@to)) then
                    ('Before ' || viewItem:date($date/@to))
                else
                    if (not($date/@from) and $date/@to) then
                        ('After ' || viewItem:date($date/@from))
                    else
                        ()
        else
            if ($date/(@notBefore | @notAfter)) then
                if ($date/@notBefore and $date/@notAfter) then
                    (viewItem:date(string($date/@notBefore)) || '-' || viewItem:date(string($date/@notAfter)))
                else
                    if ($date/@notAfter and not($date/@notBefore)) then
                        ('Before ' || viewItem:date($date/@notAfter))
                    else
                        if (not($date/@notAfter) and $date/@notBefore) then
                            ('After ' || viewItem:date($date/@notBefore))
                        else
                            ()
            else
                ()
    let $evidence := if ($date/@evidence = 'lettering') then
        ' (dating on palaeographic grounds)'
    else
        if ($date/@evidence) then
            concat(' (', $date/@evidence, ')')
        else
            ()
    let $cert := if ($date/@cert = 'low') then
        '?'
    else
        ()
    let $resp := if ($date/@resp) then
        (' according to ',
        if (starts-with($date/@resp, 'PRS') or starts-with($date/@resp, 'ETH')) then
            exptit:printTitle($date/@resp)
           else if (starts-with($date/@resp, 'bm:')) then string($date/@resp)
        else
            viewItem:editorName($date/@resp))
    else
        ()
    let $formatortext := if (count($date/node()) gt 1) then
        viewItem:TEI2HTML($date/node())
    else if($date/text()) then $date/text()
        else
        $dates
    return
        ($formatortext, $evidence, $cert, $resp)
};


declare function viewItem:textfragment($frag) {
  (:  let $test := util:log('info', 'got to the textfragment' )
return:)
    <div>
        <div
            id="transcription" style="word-break: keep-all;">
            {
                if (count($frag/t:div) = 0) then
                    attribute class {'w3-container chapterText'}
                else
                    ()
            }
            {if($frag[@subtype="transkribus"] and (count($frag/t:div[@subtype='folio']) gt 20))
            then  <div>This manuscript transcription has {count($frag/t:div[@subtype='folio'])} folia, which is too much to show.
            Please, use the navigation bar on the left to narrow down.</div>
            else
                try {
                    viewItem:TEI2HTML($frag)
                } catch * {
                    util:log('info', $err:description)
                }
            }
            <div
                class="w3-modal"
                id="textHelp">
                <div
                    class="w3-modal-content">
                    <header
                        class="w3-container w3-red">
                        <h2>Text visualization help</h2>
                        <span
                            class="w3-button w3-display-topright"
                            onclick="document.getElementById('textHelp').style.display='none'">
                            <i
                                class="fa fa-times"/>
                        </span>
                    </header>
                    <div
                        class="w3-container w3-margin">
                        Page breaks are indicated with a line and the number of the page break.
                        Column breaks are indicated with a pipe (|) followed by the name of the column.
                        <p>In the text navigation bar:</p>
                        <ul
                            class="nodot">
                            <li>References are relative to the current level of the view. If you want to see further navigation levels, please click the arrow to open in another page.</li>
                            <li>Each reference available for the current view can be clicked to scroll to that point. alternatively you can view the section clicking on the arrow.</li>
                            <li>Using an hyphen between references, like LIT3122Galaw.1-2 you can get a view of these two sections only</li>
                            <li>Clicking on an index will call the list of relevant annotated entities and print a parallel navigation aid. This is not limited to the context but always refers to the entire text.
                                Also these references can either be clicked if the text is present in the context or can be opened clicking on the arrow, to see them in another page.</li>
                        </ul>

                        <p>In the text:</p>
                        <ul
                            class="nodot">
                            <li>Click on ↗ to see the related items in Pelagios.</li>
                            <li>Click on <i
                                    class="fa fa-hand-o-left"/>
                                to see the which entities within Beta maṣāḥǝft point to this identifier.</li>
                            <li>
                                <sup>[!]</sup> contains additional information related to uncertainties in the encoding.</li>
                            <li>Superscript digits refer to notes in the apparatus which are displayed on the right.</li>
                            <li>to return to the top of the page, please use the back to top button</li>
                        </ul>
                    </div>
                </div>
            </div>
        </div>
        <script
            type="text/javascript"
            src="resources/js/pelagios.js"/>
        <img
            id="loadingRole"
            src="resources/Loading.gif"
            style="display: none;"/>
        <div
            id="versions"
            class="w3-container"/>
        {
            if ($frag//t:pb[@facs]) then
                (<div
                    id="viewer"
                    class="w3-container"/>,
                <script
                    type="text/javascript">
                    {"var data = [{collectionUri: " || concat('/api/iiif/witnesses/', $frag//ancestor::t:TEI/@xml:id) || "}]"}
                </script>,
                <script
                    type="text/javascript"
                    src="resources/js/editionmirador.js"/>)
            else
                ()
        }
        <div
            id="roleAttestations"
            class="w3-container"/>
        <div
            class="w3-hide">
            {
                for $r in distinct-values($frag//@resp)
                return
                    <span
                        id="{$r}Name">
                        {viewItem:editorName($r)}
                    </span>
            }
        </div>
    </div>
};

declare %private function viewItem:editorName($ref) {
    if (string-length($ref) != 2) then
        ()
    else
        (
        try {
            if ($viewItem:editors//t:item[@xml:id = $ref]) then
                $viewItem:editors//t:item[@xml:id = $ref]/text()
            else
                string($ref)
        } catch * {
            util:log('info', concat('failed parsing with viewItem:editorName ', $ref))
        })
};

declare function viewItem:textfragmentbibl($this, $id) {
    (:replaces textfragmentbibl.xsl:)
    if ($this//t:listBibl)
    then
        <div
            class="w3-container"
            id="bibliographyText{$id}">
            {viewItem:TEI2HTML($this//t:listBibl)}
        </div>
    else
        ()
    ,
    for $r in distinct-values($this//@resp)
    return
        <span
            id="{$r}Name">
            {viewItem:editorName($r)}
        </span>
};

declare function viewItem:table($t as element(t:table)) {
  <table class="w3-table w3-bordered">
        <thead class="w3-light-gray">
          {
            for $header in $t/t:row[@role="label"]
            return
              <tr>
                {
                  for $cell in $header/t:cell
                  return
                    <th rowspan="{if ($cell/@rows) then string($cell/@rows) else '1'}">
                      {viewItem:TEI2HTML($cell)}
                    </th>
                }
              </tr>
          }
        </thead>
        <tbody>
          {
            for $row in $t/t:row[not(@role="label")]
            return
                let $cells:=$row/t:cell
                return
                  <tr>
                    {
                      for $cell in $cells
                      return
                          <td rowspan="{if ($cell/@rows) then string($cell/@rows) else '1'}">
                            {viewItem:TEI2HTML($cell)}
                          </td>
                    }
                  </tr>
          }
        </tbody>
      </table>
    };

declare function viewItem:worknav($item) {
    (
    <a
        class="w3-bar-item page-scroll"
        href="#description">Description</a>,
    if ($item//t:placeName) then
        <a
            class="w3-bar-item page-scroll"
            href="{$config:appUrl}/IndexPlaces?entity={string($item/@xml:id)}">Places Index</a>
    else
        (),
    if ($item//t:persName) then
        <a
            class="w3-bar-item page-scroll"
            href="{$config:appUrl}/IndexPersons?entity={string($item/@xml:id)}">Persons Index</a>
    else
        (),
    if ($item//t:body[t:div[@type = 'edition'][t:ab or t:div[@type = 'textpart']]]) then
        <a
            class="w3-bar-item page-scroll w3-red"
            href="{$config:appUrl}/works/{$item/@xml:id}/text">Text</a>
    else
        (),
    if ($item//t:body[t:div[@type = 'translation'][t:ab or t:div[@type = 'textpart']]]) then
        <a
            class="w3-bar-item page-scroll w3-red"
            href="{$config:appUrl}/works/{$item/@xml:id}/text">Translation</a>
    else
        (),
    <a
        class="w3-bar-item page-scroll"
        href="#bibliography">Bibliography</a>
    )
};


declare function viewItem:personnav($item) {
    (<a
        class="w3-bar-item page-scroll"
        href="{$config:appUrl}/IndexPersons?pointer={string($item/@xml:id)}">Persons Index</a>,
    <a
        class="w3-bar-item page-scroll"
        href="#general">General</a>,
    if ($item//t:birth) then
        <a
            class="w3-bar-item page-scroll"
            href="#birth">Birth</a>
    else
        (),
    if ($item//t:floruit) then
        <a
            class="w3-bar-item page-scroll"
            href="#floruit">Floruit</a>
    else
        (),
    if ($item//t:death) then
        <a
            class="w3-bar-item page-scroll"
            href="#death">Death</a>
    else
        ()
    )
};

declare function viewItem:placenav($item) {
    (
    <a
        class="w3-bar-item page-scroll"
        href="{$config:appUrl}/IndexPlaces?pointer={string($item/@xml:id)}">Places Index</a>,
    <a
        class="w3-bar-item page-scroll"
        href="#general">General</a>,
    <a
        class="w3-bar-item page-scroll"
        href="#description">Description</a>,
    <a
        class="w3-bar-item page-scroll"
        href="#map">Map</a>
    )
};

declare function viewItem:authnav($item) {
    (
    <a
        class="w3-bar-item page-scroll"
        href="#general">General</a>,
    <a
        class="w3-bar-item page-scroll"
        href="#description">Description</a>,
    <a
        class="w3-bar-item page-scroll"
        href="#authors">Authors</a>)
};

declare function viewItem:manuscriptnav($item) {
    (
    if ($item//t:placeName) then
        <a
            class="w3-bar-item page-scroll"
            href="{$config:appUrl}/IndexPlaces?entity={string($item/@xml:id)}">Places Index</a>
    else
        (),
    if ($item//t:persName) then
        <a
            class="w3-bar-item page-scroll"
            href="{$config:appUrl}/IndexPersons?entity={string($item/@xml:id)}">Persons Index</a>
    else
        (),
    <a
        class="w3-bar-item page-scroll"
        href="#general">General</a>,
    <a
        class="w3-bar-item page-scroll"
        href="#description">Description</a>,
    <a
        class="w3-bar-item page-scroll"
        href="#generalphysical">Physical Description</a>,
    if ($item//t:msPart or $item//t:msFrag) then
        <div
            class="w3-bar-item">
            Main parts
            <ul>
                {
                    for $part in ($item//t:msPart, $item//t:msFrag)
                    return
                        <li>
                            <a
                                class="page-scroll"
                                href="#{$part/@xml:id}">Codicological unit {substring($part/@xml:id, 1)}</a>
                        </li>
                }</ul>
        </div>
    else
        (),
    if ($item//t:additional//t:listBibl) then
        <a
            class="w3-bar-item page-scroll"
            href="#catalogue">Catalogue</a>
    else
        (),
    if ($item//t:body[t:div]) then
        <a
            class=" w3-bar-item page-scroll"
            href="#transcription">Transcription </a>
    else
        (),
    <a
        class="w3-bar-item page-scroll"
        href="#footer">Authors</a>,
    <button
        class="w3-button w3-red w3-bar-item"
        onclick="openAccordion('NavByIds')">Show more links</button>,
    <ul
        class="w3-bar-item w3-hide"
        id="NavByIds">
        {
            for $node at $p in $item//t:*[not(self::t:TEI)][not(self::t:category)][not(self::t:editor)][not(self::t:calendar)][@xml:id]
            let $anchor := string($node/@xml:id)
                order by $p
            return
                <li>
                    <a
                        class="page-scroll"
                        href="#{$anchor}">
                        {
                            if ($anchor = 'ms') then
                                'General manuscript description'
                            else
	                              if (starts-with($anchor, 'coloph') and matches($anchor, 'coloph')) then
                                   'Colophon ' || substring-after($anchor, 'coloph') || string-join(viewItem:headercontext($node))
														else
																if (not(matches($anchor, '^\w\d+$'))) then $node/name()
														else
																switch(substring($anchor, 1))
		                                case 'p' return
																		    'Codicological Unit ' || substring($anchor, 1) || string-join(viewItem:headercontext($node))
                                    case 'f' return
                                        'Fragment ' || substring($anchor, 1) || string-join(viewItem:headercontext($node))
                                    case 't' return
																			 'Title ' || substring($anchor, 1) || string-join(viewItem:headercontext($node))
																		case 'b' return
																	     'Binding ' || substring($anchor, 1) || string-join(viewItem:headercontext($node))
																    case 'a' return
															         viewItem:categoryname($node, $node/t:desc/@type) || ' (' || substring($anchor, 1) || ') ' || string-join(viewItem:headercontext($node))
																		case 'e' return
                                       viewItem:categoryname($node, $node/t:desc/@type) || ' (' || substring($anchor, 1) || ') ' || string-join(viewItem:headercontext($node))
																		case 'd' return
                                      'Decoration ' || substring($anchor, 1) || string-join(viewItem:headercontext($node))
																		default return
                                      if (contains($anchor, '_i') and matches($anchor, '\w\d+')) then
																					'Content Item ' || substring-after($anchor, '_i') || string-join(viewItem:headercontext($node)) || string-join($node/t:title//text())
                                      else if (starts-with($anchor, 'q') and matches($anchor, '\w\d+')) then
                                          'Quire ' || substring($anchor, 1) || string-join(viewItem:headercontext($node))
																			else if (starts-with($anchor, 'h') and matches($anchor, '\w\d+')) then
                                          'Hand ' || substring($anchor, 1) || string-join(viewItem:headercontext($node))
                                      else $node/name()
                        }
                    </a>
                </li>
        }
    </ul>
    )
};

declare function viewItem:switchsubids($anchor, $node) {
    if ($anchor = 'ms') then
        ' General manuscript description'
    else
        if (starts-with($anchor, 'p') and matches($anchor, '^\w\d+$')) then
            ' Codicological Unit ' || substring($anchor, 1) || string-join(viewItem:headercontext($node))
        else
            if (starts-with($anchor, 'f') and matches($anchor, '^\w\d+$')) then
                ' Fragment ' || substring($anchor, 1) || string-join(viewItem:headercontext($node))
            else
                if (starts-with($anchor, 't') and matches($anchor, '\w\d+')) then
                    ' Title ' || substring($anchor, 1) || string-join(viewItem:headercontext($node))
                else
                    if (starts-with($anchor, 'b') and matches($anchor, '\w\d+')) then
                        ' Binding ' || substring($anchor, 1) || string-join(viewItem:headercontext($node))
                    else
                        if (starts-with($anchor, 'a') and matches($anchor, '\w\d+')) then
                            viewItem:categoryname($node, $node/t:desc/@type) || ' (' || substring($anchor, 1) || ') ' || string-join(viewItem:headercontext($node))
                        else
                            if (starts-with($anchor, 'e') and matches($anchor, '\w\d+')) then
                                viewItem:categoryname($node, $node/t:desc/@type) || ' (' || substring($anchor, 1) || ') ' || string-join(viewItem:headercontext($node))
                            else
                                if (starts-with($anchor, 'd') and matches($anchor, '\w\d+')) then
                                    ' Decoration ' || substring($anchor, 1) || string-join(viewItem:headercontext($node))
                                else
                                    if (starts-with($anchor, 'coloph') and matches($anchor, 'coloph')) then
                                        ' Colophon ' || substring-after($anchor, 'coloph') || string-join(viewItem:headercontext($node))
                                    else
                                        if (contains($anchor, '_i') and matches($anchor, '\w\d+')) then
                                           ( ' Content Item ' || substring-after($anchor, '_i') || string-join(viewItem:headercontext($node)) ,
                                            if(count($node/t:title) ge 1) then viewItem:TEI2HTML($node/t:title[1]) else ())
                                        else
                                            if (starts-with($anchor, 'q') and matches($anchor, '\w\d+')) then
                                                ' Quire ' || substring($anchor, 1) || string-join(viewItem:headercontext($node))
                                            else
                                                if (starts-with($anchor, 'h') and matches($anchor, '\w\d+')) then
                                                    ' Hand ' || substring($anchor, 1) || string-join(viewItem:headercontext($node))
                                                else
                                                    $node/name()
};

declare function viewItem:categoryname($item, $type) {
    ' ' || $item//t:category[@xml:id = $type]/t:catDesc/text()
};


declare function viewItem:nav($item) {
    let $type := $item/@type
    return
        switch ($type)
            case 'work'
                return
                    viewItem:worknav($item)
            case 'studies'
                return
                    viewItem:worknav($item)
            case 'nar'
                return
                    viewItem:authnav($item)
            case 'pers'
                return
                    viewItem:personnav($item)
            case 'place'
                return
                    viewItem:placenav($item)
            case 'ins'
                return
                    viewItem:placenav($item)
            case 'auth'
                return
                    viewItem:authnav($item)
            case 'mss'
                return
                    viewItem:manuscriptnav($item)
            default return
                ()
};


declare function viewItem:capitalize-first($arg as xs:string?) as xs:string? {
    concat(upper-case(substring(string($arg), 1, 1)),
    substring($arg, 2))
};

declare %private function number:RomanToInteger($romannumber, $followingvalue) {
    if (ends-with($romannumber, 'CM')) then
        900 + number:RomanToInteger(substring($romannumber, 1, string-length($romannumber) - 2), 900)
    else
        if (ends-with($romannumber, 'M')) then
            1000 + number:RomanToInteger(substring($romannumber, 1, string-length($romannumber) - 1), 1000)
        else
            if (ends-with($romannumber, 'CD')) then
                400 + number:RomanToInteger(substring($romannumber, 1, string-length($romannumber) - 2), 400)
            else
                if (ends-with($romannumber, 'D')) then
                    500 + number:RomanToInteger(substring($romannumber, 1, string-length($romannumber) - 1), 500)
                else
                    if (ends-with($romannumber, 'XC')) then
                        90 + number:RomanToInteger(substring($romannumber, 1, string-length($romannumber) - 2), 90)
                    else
                        if (ends-with($romannumber, 'C')) then
                            (if (100 ge number($followingvalue)) then
                                100
                            else
                                -100) + number:RomanToInteger(substring($romannumber, 1, string-length($romannumber) - 1), 100)
                        else
                            if (ends-with($romannumber, 'XL')) then
                                40 + number:RomanToInteger(substring($romannumber, 1, string-length($romannumber) - 2), 40)
                            else
                                if (ends-with($romannumber, 'L')) then
                                    50 + number:RomanToInteger(substring($romannumber, 1, string-length($romannumber) - 1), 50)
                                else
                                    if (ends-with($romannumber, 'IX')) then
                                        9 + number:RomanToInteger(substring($romannumber, 1, string-length($romannumber) - 2), 9)
                                    else
                                        if (ends-with($romannumber, 'X')) then
                                            (if (10 ge number($followingvalue)) then
                                                10
                                            else
                                                -10) + number:RomanToInteger(substring($romannumber, 1, string-length($romannumber) - 1), 10)
                                        else
                                            if (ends-with($romannumber, 'IV')) then
                                                4 + number:RomanToInteger(substring($romannumber, 1, string-length($romannumber) - 2), 4)
                                            else
                                                if (ends-with($romannumber, 'V')) then
                                                    5 + number:RomanToInteger(substring($romannumber, 1, string-length($romannumber) - 1), 5)
                                                else
                                                    if (ends-with($romannumber, 'I')) then
                                                        (if (1 ge number($followingvalue)) then
                                                            1
                                                        else
                                                            -1) + number:RomanToInteger(substring($romannumber, 1, string-length($romannumber) - 1), 1)
                                                    else
                                                        0
};


declare %private function viewItem:analyseMeasure($measure) {
    let $regex1 := '\s*(\d+)\s*\+\s*(\d+)\s*\+\s*(\d+)\s*'
    let $regex2 := '\s*(\d+)\s*\+\s*(\d+)\s*'
    let $regex3 := '\s*([ivx|IVX]+)\s*\+\s*(\d{1,3})\s*\+\s*([ivx|IVX]+)\s*'
    let $regex4 := '\s*([ivx|IVX]+)\s*\+\s*(\d{1,3})\s*'
    let $regex5 := '\s*(\d{1,3})\s*\+\s*([ivx|IVX]+)\s*'
    let $regex6 := '.*\((.*)\)'

    return

        if (matches($measure, $regex1)) then
            let $analyse := analyze-string($measure, $regex1)
            return
                (for $m in $analyse/s:match
                return
                    (<beginning>
                        {$m/s:group[@nr = '1']}
                    </beginning>,
                    <text>
                        {$m/s:group[@nr = '2']}
                    </text>,
                    <end>
                        {$m/s:group[@nr = '3']}
                    </end>),
                for $n in $analyse/s:not-match
                return
                    $n)
        else
            if (matches($measure, $regex2)) then
                let $analyse := analyze-string($measure, $regex2)
                return
                    (for $m in $analyse/s:match
                    return
                        let $values := <vals>
                            <val>
                                {$m/s:group[@nr = '1']/text()}
                            </val>
                            <val>
                                {$m/s:group[@nr = '2']/text()}
                            </val>
                        </vals>
                        let $max := max($values//*:val)
                        let $min := min($values//*:val)
                        return
                            (if ($min = xs:integer($m/s:group[@nr = '1']/text())) then
                                <beginning>
                                    {$min}
                                </beginning>
                            else
                                (),
                            <text>{$max}</text>,
                            if ($min = xs:integer($m/s:group[@nr = '2']/text())) then
                                <end>
                                    {$min}
                                </end>
                            else
                                ()
                            ),
                    for $n in $analyse/s:not-match
                    return
                        $n)
            else
                if (matches($measure, $regex3)) then
                    let $analyse := analyze-string($measure, $regex3)
                    return
                        (for $m in $analyse/s:match
                        return
                            (
                            <beginning>{format-number(number:RomanToInteger($m/s:group[@nr = '1']/text(), 0), '####')}</beginning>,
                            <text>
                                {$m/s:group[@nr = '2']/text()}
                            </text>,
                            <end>{format-number(number:RomanToInteger($m/s:group[@nr = '3']/text(), 0), '####')}</end>
                            ),
                        for $n in $analyse/s:not-match
                        return
                            $n)
                else
                    if (matches($measure, $regex4)) then
                        let $analyse := analyze-string($measure, $regex4)
                        return
                            (for $m in $analyse/s:match
                            return
                                (<beginning>{format-number(number:RomanToInteger($m/s:group[@nr = '1']/text(), 0), '####')}</beginning>,
                                <text>
                                    {$m/s:group[@nr = '2']/text()}
                                </text>
                                ),
                            for $n in $analyse/s:not-match
                            return
                                $n)
                    else
                        if (matches($measure, $regex5)) then
                            let $analyse := analyze-string($measure, $regex5)
                            return
                                (for $m in $analyse/s:match
                                return
                                    (
                                    <text>
                                        {$m/s:group[@nr = '1']/text()}
                                    </text>,
                                    <end>{format-number(number:RomanToInteger($m/s:group[@nr = '2']/text(), 0), '####')}</end>
                                    ),
                                for $n in $analyse/s:not-match
                                return
                                    $n)
                        else
                            if (matches($measure, $regex6)) then
                                let $analyse := analyze-string($measure, $regex6)
                                return
                                    (for $m in $analyse/s:match
                                    return
                                        viewItem:analyseMeasure($m/s:group[@nr = '1']/text())
                                    )
                            else
                                $measure
};

declare %private function viewItem:measure($measure) {
    let $parsedMeasure := viewItem:analyseMeasure($measure)
    let $totalprotectives :=
    if ($parsedMeasure//*:beginning and $parsedMeasure//*:end) then
        xs:integer($parsedMeasure//*:beginning/data()) + xs:integer($parsedMeasure//*:end/data())
    else
        if ($parsedMeasure//*:beginning and not($parsedMeasure//*:end)) then
            xs:integer($parsedMeasure//*:beginning/data())
        else
            if ($parsedMeasure//*:end and not($parsedMeasure//*:beginning)) then
                xs:integer($parsedMeasure//*:end/data())
            else
                ()
    let $seq := (if ($parsedMeasure//*:beginning) then
        if (xs:integer($parsedMeasure//*:beginning/data()) gt 1) then
            ' i-' || lower-case(viewItem:n2roman($parsedMeasure//*:beginning/data()))
        else
            'i'
    else
        (), '+',
    format-number($parsedMeasure//*:text/data(), '####'),
    if ($parsedMeasure//*:end) then
        ('+',
        if ((xs:integer($parsedMeasure//*:end/data()) gt 1) and $parsedMeasure//*:beginning)
        then
            viewItem:smallroman(($parsedMeasure//*:beginning/data() + 1)) || '-' || viewItem:smallroman($totalprotectives)
        else
            viewItem:smallroman($totalprotectives))
    else
        ()
    )
    return
        string-join($seq)
};

declare %private function viewItem:smallroman($val) {
    lower-case(viewItem:n2roman($val))
};

(:return the concatenation of strings by continuous reduction:)
declare function viewItem:n2roman($num as xs:integer) as xs:string
{
    (:the basis of transformation is a series of strings for components:)
    let $values := (
    <value
        num="1"
        char="I"/>,
    <value
        num="4"
        char="IV"/>,
    <value
        num="5"
        char="V"/>,
    <value
        num="9"
        char="IX"/>,
    <value
        num="10"
        char="X"/>,
    <value
        num="40"
        char="XL"/>,
    <value
        num="50"
        char="L"/>,
    <value
        num="90"
        char="XC"/>,
    <value
        num="100"
        char="C"/>,
    <value
        num="400"
        char="CD"/>,
    <value
        num="500"
        char="D"/>,
    <value
        num="900"
        char="CM"/>,
    <value
        num="1000"
        char="M"/>)
    return
        (:as long as we have a number, keep going:)
        if ($num) then
            (:reduce by the largest number that has a string value:)

            for $val in $values[@num <= $num][fn:last()]
            return
                (:using the highest value:)
                fn:concat($val/@char, viewItem:n2roman($num - xs:integer($val/@num
                )))
                (:nothing left:)
        else
            ""
};




declare %private function viewItem:fulllang($lang) {
    try {
        $viewItem:lang//t:item[@xml:id = $lang]/text()
    } catch * {
        util:log('INFO', $lang)
    }
};


declare %private function viewItem:keywordtag($x){<span class="w3-tag w3-gray"><a
                                        target="_blank" href="{$config:appUrl}/newSearch.html?searchType=text&amp;mode=any&amp;termkey={$x}">{exptit:printTitleID($x)}</a></span>};

  declare %private function viewItem:keywordgroup($keys){
                                        if ($keys) then
                    <div
                        class="w3-row">{
                            for $x in distinct-values($keys)
                            return
                                viewItem:keywordtag($x)
                        }</div>
                else
                    ()
                                        };

  declare %private function viewItem:keywordgroupauth($keys){
                                        if ($keys) then
                    <div
                        class="w3-row">{
                            for $x in $keys
                             let $auth := string($x/@passive)
                            return
                                viewItem:keywordtag($x)
                        }</div>
                else
                    ()
                                        };

  declare %private function viewItem:keywordgroupmulti($keys){
                                        if ($keys) then
                    <div
                        class="w3-row">{
                             if (contains($keys, ' '))
                            then
                                for $x in tokenize($keys, ' ')
                                return

                                viewItem:keywordtag($x)
                            else
                                let $type := $keys
                                return
                                viewItem:keywordtag($type)
                        }</div>
                else
                    ()
                                        };
(:~ returns a selector with values which can be searched. a javascript will pick the selected one and send it to the restxq to get related items :)
declare function viewItem:keywords($file, $collection) {
    let $id := string($file/@xml:id)
    let $classes := for $class in $file//t:term/@key
    return
        'http://betamasaheft.eu/' || $class
    let $options := switch ($collection)
        (:                   decides on the basis of the collection what is relevant to match related records :)
        case 'manuscripts'
            return
              (  viewItem:keywordgroup($file//t:term/@key),
                viewItem:keywordgroup($file//t:supportDesc/t:material/@key),
                viewItem:keywordgroup($file//t:handNote[@script]/@script),
                viewItem:keywordgroup($file//t:objectDesc/@form)
               )
        case 'works'
            return
                (viewItem:keywordgroup($file//t:term/@key)
                )
        case 'studies'
            return
               (viewItem:keywordgroup($file//t:term/@key))
        case 'narratives'
            return
                 (viewItem:keywordgroup($file//t:term/@key) )
        case 'places'
            return
                (viewItem:keywordgroup($file//t:term/@key),
                viewItem:keywordgroup($file//t:settlement/@ref),
                viewItem:keywordgroup($file//t:region/@ref),
                viewItem:keywordgroup($file//t:country/@ref),
                viewItem:keywordgroupmulti($file//t:place/@type)
                )
        case 'institutions'
            return
             (viewItem:keywordgroup($file//t:term/@key),
                viewItem:keywordgroup($file//t:settlement/@ref),
                viewItem:keywordgroup($file//t:region/@ref),
                viewItem:keywordgroup($file//t:country/@ref),
                viewItem:keywordgroupmulti($file//t:place/@type)
                )
        case 'persons'
            return
            (viewItem:keywordgroup($file//t:term/@key),
            viewItem:keywordgroup($file//t:roleName/@type),
            viewItem:keywordgroup($file//t:faith/@type),
            viewItem:keywordgroup($file//t:occupation/@type)
                )
        default return
            viewItem:keywordgroup($file//t:term/@key)
return
    if(count($options) gt 1) then <div
        class="w3-container"
        id="keywordslist">
        <h3>Keywords</h3>
        {$options}
    </div> else ()
};

declare function viewItem:zotero($file) {
    let $id := string($file/@xml:id)
    return
   <div
        class="w3-container"
        id="zoterolink">
        <h3>Check for additional bibliography</h3>
        <div><a href="{concat('https://api.zotero.org/groups/358366/items?tag=',$id,'&amp;format=bib&amp;style=hiob-ludolf-centre-for-ethiopian-studies-with-url-doi&amp;linkwrap=1')}  target='_blank'">Click on this link to view bibliography mentioning this record</a></div>
    </div>
};

declare function viewItem:osm($item) {
let $coor := string($item//t:location/t:geo)
let $geo := tokenize($coor, ',')
let $geo1 := substring-before($coor, ' ')
let $geo2 := substring-after($coor, ' ')
let $marker := concat('=',$geo1,'%2C',$geo2)
return
if  ($item//t:location/t:geo) then
<div
    class="w3-container w3-padding float" >
<iframe width="425" height="350" src="https://www.openstreetmap.org/export/embed.html?bbox=33.68408203125001%2C11.646856393732364%2C42.857666015625%2C16.883403464236842&amp;layer=mapnik&amp;marker={$geo1}%2C{$geo2}" style="border: 1px solid black"></iframe><br/><small><a href="https://www.openstreetmap.org/?mlat={$geo1}&amp;mlon={$geo2}#map=8/{$geo1}/{$geo2}">Show a larger map</a></small>
</div>
else ()
};