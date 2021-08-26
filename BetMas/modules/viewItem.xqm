xquery version "3.1";
(:refactoring of the former XSLT library into an Xquery module with typeswitch:)
module namespace viewItem = "https://www.betamasaheft.uni-hamburg.de/BetMas/viewItem";
import module namespace config = "https://www.betamasaheft.uni-hamburg.de/BetMas/config" at "xmldb:exist:///db/apps/BetMas/modules/config.xqm";
import module namespace exptit = "https://www.betamasaheft.uni-hamburg.de/BetMas/exptit" at "xmldb:exist:///db/apps/BetMas/modules/exptit.xqm";
declare namespace t = "http://www.tei-c.org/ns/1.0";
declare namespace b = "betmas.biblio";
declare variable $viewItem:coll := collection('/db/apps/expanded');

declare variable $viewItem:bibliography := doc('/db/apps/BetMas/lists/bibliography.xml');
declare variable $viewItem:domlib := doc('/db/apps/BetMas/lists/domlib.xml');


declare function viewItem:VisColl($collation) {
    let $xslt := 'xmldb:exist:///db/apps/BetMas/xslt/collationAlone.xsl'
    let $parameters := doc('/db/apps/BetMas/xslt/params.xml')
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

declare function viewItem:date($date) {
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

declare function viewItem:notBnotA($element) {
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

declare function viewItem:datepicker($element) {
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
declare function viewItem:sup($t) {
    if ($t/@xml:lang) then
        <sup>{string($t/@xml:lang)}</sup>
    else
        ()
};

declare function viewItem:correspTit($t, $id) {
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

declare function viewItem:worktitle($t) {
    let $log := util:log('INFO', $t)
    let $id := string($t/@xml:id)
    
    return
        <li
            property="http://purl.org/dc/elements/1.1/title">
            {
                attribute {'xml:id'} {$id},
                util:log('INFO', $t),
                if ($t/@type) then
                    concat(string($t/@type), ': ')
                else
                    (),
                if ($t/@ref) then
                    <a
                        href="{$t/@ref}"
                        target="_blank">{$t/text()}</a>
                else
                    viewItem:TEI2HTML($t),
                viewItem:sup($t),
                if ($t/parent::t:titleStmt/t:title[@corresp]) then
                    (' (', viewItem:correspTit($t, $id), ')')
                else
                    ()
            }
        </li>
};



declare function viewItem:makeSequence($attribute) {
    if (contains($attribute, ' ')) then
        tokenize($attribute, ' ')
    else
        string($attribute)
};

declare function viewItem:workAuthorList($parentname, $p, $a) {
    ($parentname,
    <a
        href="{$p}"
        class="persName">
        {exptit:printTitle($p)}
    </a>,
    if ($a/@name = 'saws:isAttributedToAuthor') then
        (' ',
        <span
            class="w3-tag w3-round-large w3-red">attributed</span>)
    else
        (),
    let $filename := viewItem:URI2ID($p)
    return
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

declare function viewItem:URI2ID($string) {
    if (starts-with($string, $config:appUrl)) then
        substring-after($string, ($config:appUrl || '/'))
    else
        $string
};

declare function viewItem:ID2URI($string) {
    if (starts-with($string, $config:appUrl)) then
        $string
    else
        $config:appUrl || '/' || $string
};

declare function viewItem:workAuthLi($a, $aorp) {
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

declare function viewItem:parentLink($node) {
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

declare function viewItem:headercontext($node) {
    if ($node/ancestor::t:msPart[1]) then
        (' of codicological unit ',
        <a
            href="#{$node/ancestor::t:msPart[1]/@xml:id}">
            {substring-after($node/ancestor::t:msPart[1]/@xml:id, 'p')}</a>)
    else
        (),
    if ($node/ancestor::t:msItem[1]) then
        (', item ',
        <a
            href="#{$node/ancestor::t:msItem[1]/@xml:id}">
            {substring-after($node/ancestor::t:msItem[1]/@xml:id, 'i')}</a>)
    else
        (),
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
                href="{$c}">{$text}
                {$lang}</a>
        return
            ('(about:', $items, ')')
    else
        ()
};

declare function viewItem:biblioHeader($listBibl) {
    concat(concat(upper-case(substring($listBibl/@type, 1, 1)), substring($listBibl/@type, 2), ' '[not(last())]), ' Bibliography'),
    viewItem:headercontext($listBibl)
};

declare function viewItem:bibliographyHeader($listBibl) {
    if ($listBibl/ancestor::t:note) then
        viewItem:TEI2HTML($listBibl)
    else
        if ($listBibl[not(parent::t:item) and not(ancestor::t:physDesc)]) then
            viewItem:biblioHeader($listBibl)
        else
            <h4>{
                    if ($listBibl/@type = 'catalogue') then
                        attribute id {string($listBibl/@type)}
                    else
                        ()
                }{viewItem:biblioHeader($listBibl)}</h4>
};

declare function viewItem:bibl($node, $t) {
    <div
        class="w3-row">
        <div
            class="w3-col"
            style="width:85%">
            <span
                class="Zotero Zotero-full"
                data-value="{$t}"
                data-type="{$node/t:seg/@type}">
                {$viewItem:bibliography//b:entry[@id = $t]/b:reference/node()}
                {
                    let $crs := for $cr in $node/t:citedRange
                    return
                        (string($cr/@unit) || ' ' || $cr/text())
                    return
                        string-join($crs, ', ')
                }
                {viewItem:TEI2HTML($node/t:note[@type = 'about'])}
                {viewItem:TEI2HTML($node/t:ref[@target])}
                {viewItem:TEI2HTML($node/t:note[not(@type)])}
            </span>
            <span
                class="w3-bar-block w3-hide-small w3-hide-medium">
                <a
                    class="w3-bar-item w3-button w3-tiny"
                    target="_blank"
                    href="{$node/@corresp}">Zotero</a>
                <a
                    class="w3-bar-item w3-button w3-tiny"
                    href="/bibliography?pointer={$t}">Other citations</a>
            
            </span>
        </div>
    </div>
};

declare function viewItem:bibliographyitem($node) {
    if ($node[not(@corresp) and not(t:ptr[@target])]) then
        <b
            style="color:red;">THIS BIBLIOGRAPHIC RECORD ({$node}) has no @corresp or t:ptr/@target. Please check the
            schema error report to fix it.</b>
    else
        if ($node[@corresp and not(t:ptr[@target])]) then
            (
            let $cors := viewItem:makeSequence($node/@corresp)
            for $c in $cors  return
            <a  href="{$c}">{exptit:printTitle($c)}</a> ,
            $node/text(),
            viewItem:TEI2HTML($node/t:date),
            viewItem:TEI2HTML($node/t:note)
            )
     else if ($node/t:ptr/@target='bm:EthioSpare' and $node/parent::t:listBibl[@type='catalogue'])      
     then 
       viewItem:EthioSpareFormatter($node)
        else
            let $t := $node/t:ptr/@target
            return
                if ($node/parent::t:surrogates)
                then
                    <p>{viewItem:bibl($node, $t)}</p>
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

declare function viewItem:EthioSpareFormatter($node){
 let $t := $node/t:ptr/@target
        let $TEI := $node/ancestor::t:TEI
        let $BMsignature := $TEI//t:idno[preceding-sibling::t:collection[.='Ethio-SPaRe']]
        let $domliblist := $viewItem:domlib//*:item[*:signature = $BMsignature]/*:domlib
        let $cataloguer := if($TEI//t:editor[@role='cataloguer']) 
                                   then $TEI//t:editor[@role='cataloguer']/text() 
                                   else if ($TEI//t:editor[not(@role='generalEditor')]) 
                                   then $TEI//t:editor[not(@role='generalEditor')]/text() 
                                   else let $resp := substring-after(($TEI//t:change[contains(., 'created')]/@who)[1], '#') 
                                   return string-join(distinct-values(($TEI//t:editor[@key=$resp]/text()|$TEI//t:respStmt[@xml:id=$resp]/t:name/text())), ', ')
        let $repository := $TEI//t:repository/text()
        let $date := viewItem:date($TEI//t:origDate)
        let $title := $TEI//t:titleStmt/t:title[1]/text()
        return
         <a href="https://mycms-vs03.rrz.uni-hamburg.de/domlib/receive/{$domliblist}">MS {$repository}, {$BMsignature}  
         (digitized by the Ethio-SPaRe project), {$title}, {$date}, catalogued by {$cataloguer} In {$viewItem:bibliography//b:entry[@id = $t]/b:reference/node()}</a>
};

declare function viewItem:relation($node) {
    (<a
        href="{$node/@active}">{exptit:printTitle($node/@active)}</a>,
    <a
        href="{$node//@ref}">
        <code>{string($node/@name)}</code>
    </a>,
    <a
        href="{$node/@passive}">{exptit:printTitle($node/@passive)}</a>,
    viewItem:TEI2HTML($node/t:desc)
    )
};

declare function viewItem:TEI2HTML($nodes) {
    for $node in $nodes
    return
        typeswitch ($node)
            (:        clears all comments:)
            case comment()
                return
                    ()
            case element(t:TEI)
                return
                    ()
            case element(t:titleStmt)
                return
                    ()
            case element(t:listbibl)
                return
                    (
                    (:                template to be completed :)
                    <h4>Bibliography</h4>,
                    <ul
                        class="bibliographyList">
                        {viewItem:TEI2HTML($node/node())}
                    </ul>
                    )
            case element(t:bibl)
                return
                    viewItem:bibliographyitem($node)
            case element(t:relation)
                return
                    viewItem:relation($node)
            case element(t:collation)
                return
                    viewItem:VisColl($node)
            case element()
                return
                    viewItem:TEI2HTML($node/node())
            default
                return
                    $node
};

declare function viewItem:work($item) {
    let $id := string($item/@xml:id)
    let $uri := viewItem:ID2URI($id)
    let $relsP := $viewItem:coll//t:relation[@passive = $uri]
    let $relsA := $viewItem:coll//t:relation[@active = $uri]
    let $rels := ($relsA | $relsP)
    return
        <div
            id="MainData"
            class="w3-twothird">
            <div
                id="description">
                {
                    if (count($item//t:titleStmt/t:title) gt 1)
                    then
                        (<h2>Titles</h2>,
                        <ul>
                            {
                                for $t in $item//t:titleStmt/t:title[not(@type = 'full')][@xml:id]
                                    order by $t/@xml:id,
                                        $t/text()
                                return
                                    viewItem:worktitle($t)
                            }
                            {
                                for $t in $item//t:titleStmt/t:title[not(@type = 'full')][not(@xml:id or @corresp)]
                                    order by $t/text()
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
                    let $creator := $relsA[@name = 'dcterms:creator']
                    return
                        if (count($item//t:author[not(parent::t:bibl)] | $attributed | $creator) ge 1)
                        then
                            (<h2>Authorship</h2>,
                            <ul>
                                {
                                    for $a in ($attributed | $creator)
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
                    let $translator := $relsP[@name = 'betmas:isAuthorOfEthiopicTranslation']
                    return
                        if (count($translator) ge 1)
                        then
                            (<h2>Translator</h2>,
                            <ul>
                                {
                                    for $a in ($translator)
                                    return
                                        viewItem:workAuthLi($a, 'a')
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
                                href="/works/{$id}/analytic">Relations</a> view.
                            In the Relations boxes on the right of this page, you can also find all available relations grouped by name.
                        </p>)
                    else
                        ()
                }
                {
                    <div
                        id="clavisbibliography">
                        {viewItem:bibliographyHeader($item//t:listBibl[@type = 'clavis'])}
                        <ul
                            class="bibliographyList">
                            {viewItem:TEI2HTML($item//t:listBibl[@type = 'clavis'])}
                        </ul>
                    </div>
                }
                {
                    <div
                        id="bibliography">
                        {viewItem:bibliographyHeader($item//t:listBibl[not(@type = 'clavis')])}
                        <ul
                            class="bibliographyList">
                            {viewItem:TEI2HTML($item//t:listBibl[not(@type = 'clavis')])}
                        </ul>
                    </div>
                }
            </div>
        </div>
};
declare function viewItem:narrative($item) {
    $item
};
declare function viewItem:person($item) {
    $item
};
declare function viewItem:place($item) {
    $item
};
declare function viewItem:repo($item) {
    $item
};
declare function viewItem:auth($item) {
    $item
};
declare function viewItem:corpus($item) {
    $item
};
declare function viewItem:manuscript($item) {
    $item
};

declare function viewItem:main($item) {
    let $type := $item/@type
    return
        switch ($type)
            case 'work'
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
                    viewItem:repo($item)
            case 'auth'
                return
                    viewItem:auth($item)
            case 'mss'
                return
                    viewItem:manuscript($item)
            default return
                viewItem:corpus($item)
};
