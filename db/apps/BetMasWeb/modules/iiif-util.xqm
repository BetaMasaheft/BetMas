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

(:~
 : 1. Central Canvas Calculator
 : Perfectly maps both short page inputs ('14r') and default initialization paths ('1')
 :)
declare function iiifut:calculate-canvas($idnoFacs as xs:string, $page as xs:string, $id as xs:string, $appUrl as xs:string) as xs:string {
    let $pageClean := replace($page, '[a-z\s]', '')
    return
        if (contains($idnoFacs, 'bodleian') or contains($idnoFacs, 'princeton')) then 
            ''
        else if (not(starts-with($idnoFacs, 'http'))) then
            $appUrl || '/api/iiif/' || $id || '/canvas/p' || $pageClean
        else if (contains($idnoFacs, 'digi.vat') or contains($idnoFacs, 'vatlib')) then
            let $base := if (contains($idnoFacs, 'manifest.json')) 
                           then substring-after(substring-before($idnoFacs, '/manifest.json'), 'MSS_')
                           else substring-after($idnoFacs, 'MSS_')
            let $cleanMs := substring-before($base, '/')
            let $msname := if ($cleanMs ne '') then $cleanMs else $base
            return 'https://digi.vatlib.it/iiif/MSS_' || $msname || '/canvas/p' || format-number(xs:integer($pageClean), '0000')
        else if (contains($idnoFacs, 'loc.gov')) then
            let $itemId := substring-before(substring-after($idnoFacs, 'item/'), '/manifest.json')
            return 'https://tile.loc.gov/image-services/iiif/service:amed:amedmonastery:' || $itemId || ':' || format-number(xs:integer($pageClean), '0000')
        else if (contains($idnoFacs, 'rct.resourcespace.com')) then
            if (contains($idnoFacs, '1005081')) then $idnoFacs || 'canvas/P000'
            else if (contains($idnoFacs, '1005079')) then $idnoFacs || 'canvas/ 003'
            else if (contains($idnoFacs, '1005084')) then $idnoFacs || 'canvas/ _P002-hpr.jpg'
            else if (contains($idnoFacs, '1005085')) then $idnoFacs || 'canvas/1005085.a (1)-hpr.jpg'
            else $idnoFacs || 'canvas/' || format-number(xs:integer($pageClean), '000')
        else if (contains($idnoFacs, 'eap.')) then
            replace($idnoFacs, 'manifest', 'canvas') || '/' || $pageClean
        else if (contains($idnoFacs, 'bl.digirati')) then
            let $n1 := number(substring-before(substring-after($idnoFacs, 'vdc_'), '.0x'))
            let $facs := replace($idnoFacs, string($n1), string($n1 + 2))
            return replace(substring-before($facs, '000001'), 'iiif', 'images') || '000001/canvas/c/' || $pageClean
        else if (contains($idnoFacs, 'staatsbib')) then
            substring-before($idnoFacs, '/manifest') || '-' || format-number(xs:integer($pageClean), '0000') || '/canvas'
        else if (contains($idnoFacs, 'le.ac.uk')) then
            'https://cdm16445.contentdm.oclc.org/iiif/' || substring-before(substring-after($idnoFacs, 'iiif/'), 'coll6') || 'coll6:19840/canvas/c0'
        else if (contains($idnoFacs, 'tuebingen')) then
            replace($idnoFacs, '/manifest', '/') || 'canvas/' || $pageClean
        else if (contains($idnoFacs, 'cbl.ie')) then
            substring-before($idnoFacs, '/manifest') || '/pages/' || $pageClean || '/canvas/'
        else if (contains($idnoFacs, 'uni-hamburg')) then
            substring-before($idnoFacs, '/manifest') || '/canvas/PHYS_' || format-number(xs:integer($pageClean), '0000')
        else if (contains($idnoFacs, 'cudl')) then
            replace($idnoFacs, '//iiif', '/iiif') || '/canvas/' || $pageClean
        else if (contains($idnoFacs, 'gallica')) then
            replace($idnoFacs, 'ark:', 'iiif/ark:') || '/canvas/f' || $pageClean
        else if (contains($idnoFacs, 'manchester')) then
            $idnoFacs || '/canvas/' || $pageClean
        else 
            $idnoFacs
};

(:~
 : 2. OpenSeadragon Tile Sources Generator
 :)
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