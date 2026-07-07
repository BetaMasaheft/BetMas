xquery version "3.1";

module namespace iiifut = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/iiif-util";
declare namespace t = "http://www.tei-c.org/ns/1.0";

(:~
 : Helper to resolve the @facs string via an internal facsimile link reference if needed
 :)
declare function iiifut:facs-switch($idnofacs as element()) as xs:string {
    if (starts-with($idnofacs/@facs, '#')) then
        let $facsimileID := substring-after($idnofacs/@facs, '#')
        return string($idnofacs/ancestor::t:TEI//t:facsimile[@xml:id=$facsimileID]/@facs)
    else
        string($idnofacs/@facs)
};

(:firstcanvas:)
declare function iiifut:get-first-canvas($manifestUrl as xs:string) as xs:string? {
    try {
        let $json := json-doc(normalize-space($manifestUrl))
        return
            (: Check for IIIF v3 structure ('items') :)
            if (map:contains($json, 'items')) then
                let $firstCanvas := $json?items(1)?items(1)?items(1)
                return
                    if (map:contains($firstCanvas, 'id')) then
                        $firstCanvas?id
                    else
                        $json?items(1)?id
            (: Fallback to IIIF v2 structure ('sequences/canvases') :)
            else if (map:contains($json, 'sequences')) then
                $json?sequences(1)?canvases(1)?("@id")
            else ()
    } catch * {
        () (: Return empty sequence if the remote server is down or returns a 404 :)
    }
};

(:~ Central Canvas Calculator :)
declare function iiifut:calculate-canvas(
    $idnoFacs as xs:string,
    $page as xs:string,
    $id as xs:string,
    $appUrl as xs:string
) as xs:string {

    if (contains($idnoFacs, 'bodleian') or contains($idnoFacs, 'princeton')) then
        ''
    else if (not(starts-with($idnoFacs, 'http'))) then
        $appUrl || '/api/iiif/' || $id || '/canvas/p' || $page

    (: UNIVERSAL LIVE LOOKUP FOR EXTERNAL MANIFESTS :)
    else if (starts-with($idnoFacs, 'http')) then
        let $cleanUrl := if (contains($idnoFacs, 'cudl')) then replace($idnoFacs, '//iiif', '/iiif') else $idnoFacs
        let $dynamicCanvas := iiifut:get-first-canvas($cleanUrl)
        let $safePage := if (empty($page) or normalize-space($page) eq '') then '1' else $page
        let $cleanPage := replace($safePage, '[a-z\s#]', '')
        return
            if (string-length($dynamicCanvas) gt 0 and ($cleanPage eq '1' or $cleanPage eq '')) then
                $dynamicCanvas
            else
                (: --- STATIC SAFETY NET FALLBACKS --- :)
                if (contains($idnoFacs, 'digi.vat') or contains($idnoFacs, 'vatlib')) then
                    replace(substring-before($idnoFacs, '/manifest.json') || '/canvas/p0001', 'http:', 'https:')
                else if (contains($idnoFacs, 'loc.gov')) then
                    'https://tile.loc.gov/image-services/iiif/service:amed:amedmonastery:' || substring-before(substring-after($idnoFacs, 'item/'), '/manifest.json') || ':0001'
                else if (contains($idnoFacs, 'https://rct.resourcespace.com/iiif/1005081')) then $idnoFacs || 'canvas/P000'
                else if (contains($idnoFacs, 'https://rct.resourcespace.com/iiif/1005079')) then $idnoFacs || 'canvas/ 003'
                else if (contains($idnoFacs, 'https://rct.resourcespace.com/iiif/1005084')) then $idnoFacs || 'canvas/ _P002-hpr.jpg'
                else if (contains($idnoFacs, 'https://rct.resourcespace.com/iiif/1005085')) then $idnoFacs || 'canvas/1005085.a (1)-hpr.jpg'
                else if (contains($idnoFacs, 'rct.')) then $idnoFacs || 'canvas/001'
                else if (contains($idnoFacs, 'eap.')) then
                    replace($idnoFacs, 'manifest', 'canvas') || '/' || $cleanPage
                else if (contains($idnoFacs, 'bl.digirati')) then
                    let $n1 := number(substring-before(substring-after($idnoFacs, 'vdc_'), '.0x'))
                    let $facs := replace($idnoFacs, string($n1), string($n1 + 2))
                    let $newfacs := substring-before($facs, '000001')
                    return replace($newfacs, 'iiif', 'images') || '000001/canvas/c/' || $cleanPage
                else if (contains($idnoFacs, 'staatsbib')) then substring-before($idnoFacs, '/manifest') || '-' || format-number(xs:integer($cleanPage), '0000') || '/canvas'
                else if (contains($idnoFacs, 'le.ac.uk')) then 'https://cdm16445.contentdm.oclc.org/iiif/' || substring-before(substring-after($idnoFacs, 'iiif/'), 'coll6') || 'coll6:19840/canvas/c0'
                else if (contains($idnoFacs, 'tuebingen')) then replace($idnoFacs, '/manifest', '/') || 'canvas/' || $cleanPage
                else if (contains($idnoFacs, 'cbl.ie')) then substring-before($idnoFacs, '/manifest') || '/pages/' || $cleanPage || '/canvas/'
                else if (contains($idnoFacs, 'uni-hamburg')) then substring-before($idnoFacs, '/manifest') || '/canvas/PHYS_' || format-number(xs:integer($cleanPage), '0000')
                else if (contains($idnoFacs, 'cudl')) then replace($idnoFacs, '//iiif', '/iiif') || '/canvas/' || $cleanPage
                else if (contains($idnoFacs, 'gallica')) then replace($idnoFacs, 'ark:', 'iiif/ark:') || '/canvas/f' || $cleanPage
                else if (contains($idnoFacs, 'manchester')) then $idnoFacs || '/canvas/' || $cleanPage

                else $appUrl || '/api/iiif/' || $id || '/canvas/p1'
    else
        $appUrl || '/api/iiif/' || $id || '/canvas/p1'
};

(: OpenSeadragon Tile Sources Generator :)
declare function iiifut:tile-sources($idnoFacs as xs:string, $locus as element(), $locusrvFunc as function(element()) as xs:string, $makeSequenceFunc as function(element()) as item()*) as xs:string {
    let $f := string($locus/@facs)
    return
        if (contains($idnoFacs, 'gallica')) then
            let $iiif := replace($idnoFacs, '/ark:', '/iiif/ark:')
            return
                if ($locus/@from and $locus/@to) then
                    let $from := $locusrvFunc($locus/@from)
                    let $to := $locusrvFunc($locus/@to)
                    let $count := (number($to) - number($from)) * 2
                    let $tiles := for $tile in 0 to (xs:integer($count) + 1)
                                  return '"' || $iiif || '/f' || (xs:integer(substring-after($f, 'f')) + $tile) || '/info.json"'
                    return string-join($tiles, ', ')
                else if ($locus/@from and not($locus/@to)) then
                    '"' || $iiif || '/' || $f || '/info.json"'
                else if ($locus/@target) then
                    let $tiles := for $t in $makeSequenceFunc($locus/@target) return '"' || $iiif || '/' || $t || '/info.json"'
                    return string-join($tiles, ', ')
                else ''
        else if (matches($idnoFacs, '\w{3}/\d{3}/\w{3,4}-\d{3}')) then
            let $fullIIIF := '/iiif/' || $idnoFacs
            return
                if ($locus/@from and $locus/@to) then
                    let $from := $locusrvFunc($locus/@from)
                    let $to := $locusrvFunc($locus/@to)
                    let $count := (number($to) - number($from)) * 2
                    let $tiles := for $tile in 0 to (xs:integer($count) + 1)
                                  return '"' || $fullIIIF || '_' || format-number((xs:integer($f) + $tile), '000') || '.tif/info.json"'
                    return string-join($tiles, ', ')
                else if ($locus/@from and not($locus/@to)) then
                    '"' || $fullIIIF || '_' || $f || '.tif/info.json"'
                else if ($locus/@target) then
                    let $tiles := for $t in $makeSequenceFunc($locus/@facs) return '"' || $fullIIIF || '_' || $t || '.tif/info.json"'
                    return string-join($tiles, ', ')
                else ''
        else if (matches($idnoFacs, 'EMIP/Codices/\d+/') or matches($idnoFacs, 'Laurenziana')) then
            let $fullIIIF := '/iiif/' || $idnoFacs
            return
                if ($locus/@from and $locus/@to) then
                    let $from := $locusrvFunc($locus/@from)
                    let $to := $locusrvFunc($locus/@to)
                    let $count := (number($to) - number($from)) * 2
                    let $tiles := for $tile in 0 to (xs:integer($count) + 1)
                                  return '"' || $fullIIIF || format-number((xs:integer($f) + $tile), '000') || '.tif/info.json"'
                    return string-join($tiles, ', ')
                else if ($locus/@from and not($locus/@to)) then
                    '"' || $fullIIIF || $f || '.tif/info.json"'
                else if ($locus/@target) then
                    let $tiles := for $t in $makeSequenceFunc($locus/@facs) return '"' || $fullIIIF || $t || '.tif/info.json"'
                    return string-join($tiles, ', ')
                else ''
        else if (contains($idnoFacs, 'vatlib')) then
            let $msname := substring-after(substring-before($idnoFacs, 'manifest.json'), 'MSS_')
            let $iiif := 'https://digi.vatlib.it/iiifimage/MSS_' || $msname || substring-before($msname, '/') || '_'
            return
                if (($locus/@from and $locus/@to) and (matches($locus/@from, '\d') and matches($locus/@to, '\d'))) then
                    let $from := $locusrvFunc($locus/@from)
                    let $to := $locusrvFunc($locus/@to)
                    let $count := (number($to) - number($from)) * 2
                    let $tiles := for $x in 0 to xs:integer($count)
                                  return '"' || $iiif || format-number((xs:integer($f) + $x), '0000') || '.jp2/info.json"'
                    return string-join($tiles, ', ')
                else if ($locus/@from and not($locus/@to) and matches($locus/@from, '\d')) then
                    '"' || $iiif || $f || '.jp2/info.json"'
                else if ($locus/@target and matches($locus/@target, '\d')) then
                    let $tiles := for $t in $makeSequenceFunc($locus/@target) return '"' || $iiif || $t || '.jp2/info.json"'
                    return string-join($tiles, ', ')
                else ''
        else
            '"I do not know where these images come from"'
};
