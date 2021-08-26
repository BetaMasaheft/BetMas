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
declare variable $viewItem:editors := doc('/db/apps/BetMas/lists/editors.xml')//t:list;


declare %private function viewItem:VisColl($collation) {
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



declare %private function viewItem:makeSequence($attribute) {
    if (contains($attribute, ' ')) then
        tokenize($attribute, ' ')
    else
        string($attribute)
};

declare %private function viewItem:workAuthorList($parentname, $p, $a) {
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

declare %private function viewItem:URI2ID($string) {
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

declare %private function viewItem:biblioHeader($listBibl) {
    concat(concat(upper-case(substring($listBibl/@type, 1, 1)), substring($listBibl/@type, 2), ' '[not(last())]), ' Bibliography'),
    viewItem:headercontext($listBibl)
};

declare %private function viewItem:bibliographyHeader($listBibl) {
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
                {$viewItem:bibliography//b:entry[@id = $t]/b:reference/*:div/node()}
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
                    href="/bibliography?pointer={$t}">Other citations</a>
            
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
    let $domliblist := $viewItem:domlib//*:item[*:signature = $BMsignature]/*:domlib
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
    let $date := viewItem:date($TEI//t:origDate)
    let $title := $TEI//t:titleStmt/t:title[1]/text()
    return
        <a
            href="https://mycms-vs03.rrz.uni-hamburg.de/domlib/receive/{$domliblist}">MS {$repository}, {$BMsignature}
            (digitized by the Ethio-SPaRe project), {$title}, {$date}, catalogued by {$cataloguer} In {$viewItem:bibliography//b:entry[@id = $t]/b:reference/node()}</a>
};

declare %private function viewItem:relation($node) {
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

declare %private function viewItem:publicationStmt($node) {
    <div
        class="w3-container"
        id="publicationStmt">
        <h2>Publication Statement</h2>
        {
            for $n in $node/node()
            return
                <div
                    class="w3-row">
                    <div
                        class="w3-col"
                        style="width:20%;">{$n/name()}</div>
                    <div
                        class="w3-col"
                        style="width:20%;">{
                            for $att in $n/@*
                            return
                                $att/name() || '=' || $att/data()
                        }</div>
                    <div
                        class="w3-rest">{viewItem:TEI2HTML($n)}</div>
                </div>
        }
    </div>
};

declare %private function viewItem:ref($ref) {
    <a
        href="{$ref/@target}">{$ref/text()}</a>
};

declare %private function viewItem:certainty($certainty) {
    let $match := util:eval(concat('$certainty/', $certainty/@match))/name()
    let $resp := $viewItem:editors//t:item[@xml:id = $certainty/@resp]/text()
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

declare %private function viewItem:TEI2HTML($nodes) {
    for $node in $nodes
    return
        typeswitch ($node)
            (:        clears all comments:)
            case comment()
                return
                    ()
                    (:                    decides what to do for each named element, ordered alphabetically:)
            case element(t:bibl)
                return
                    viewItem:bibliographyitem($node)
            case element(t:certainty)
                return
                    viewItem:certainty($node)
            
            case element(t:classDecl)
                return
                    ()
            case element(t:collation)
                return
                    viewItem:VisColl($node)
            case element(t:listbibl)
                return
                    (
                    <h4>{viewItem:biblioHeader($node)}</h4>,
                    <ul
                        class="bibliographyList">
                        {viewItem:TEI2HTML($node/node())}
                    </ul>
                    )
            case element(t:note)
                return
                    if ($node[@xml:id][@n]) then
                        viewItem:footnote($node)
                    else
                        viewItem:TEI2HTML($node/node())
            case element(t:ptr)
                return
                    if ($node[starts-with(@target, '#')]) then
                        viewItem:footnoteptr($node)
                    else
                        viewItem:TEI2HTML($node/node())
            case element(t:relation)
                return
                    viewItem:relation($node)
            case element(t:ref)
                return
                    viewItem:ref($node)
            case element(t:seg)
                return
                    if ($node/@ana) then
                        <span
                            class="{substring-after($node/@ana, '#')}">
                            {viewItem:TEI2HTML($node/node())}
                        </span>
                    else
                        viewItem:TEI2HTML($node/node())
            case element(t:term)
                return
                    if ($node/text()) then
                        <b>{viewItem:TEI2HTML($node/node())}</b>
                    else
                        viewItem:TEI2HTML($node/node())
                        (:                        default passthrough for elments not specified:)
            case element()
                return
                    viewItem:TEI2HTML($node/node())
            default
                return
                    $node
};

declare %private function viewItem:work($item) {
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
                    if ($item//t:extent) then
                        <p>
                            <b>Extent: </b>
                            {viewItem:TEI2HTML($item//t:extent)}
                        </p>
                    else
                        ()
                }
                {
                    if ($item//t:creation) then
                        (<h2>Date</h2>,
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
                                href="#computedWitnesses">box below</a> for a live updated list of manuscripts pointing to this record.</p>,
                        if ($item//t:listWit/@rend = 'edition') then
                            <b>Manuscripts used in this edition</b>
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
                {viewItem:publicationStmt($item//t:publicationStmt)}
                {
                    if ($item//t:editionStmt) then
                        <div
                            class="w3-container"
                            id="editionStmt">
                            <h2>Edition Statement</h2>
                            {viewItem:TEI2HTML($item//t:editionStmt)}
                        </div>
                    else
                        ()
                }
                <div
                    class="w3-container"
                    id="encodingDesc">
                    <h2>Encoding Description</h2>
                    {viewItem:TEI2HTML($item//t:encodingDesc/node())}
                </div>
                {
                    if ($item//t:div[@type = 'edition']//t:ab//text()) then
                        <a
                            class="w3-button w3-gray w3-large"
                            target="_blank"
                            href="{concat('http://voyant-tools.org/?input=https://betamasaheft.eu/works/', $id, '.xml')}">Voyant</a>
                    else
                        ()
                }
                <button
                    class="w3-button w3-red w3-large"
                    id="showattestations"
                    data-value="work"
                    data-id="{$id}">Show attestations</button>
                <div
                    id="allattestations"
                    class="w3-container"/>
            </div>
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
        </div>
};
declare %private function viewItem:narrative($item) {
    (:replaces nar.xsl :)
    $item
};
declare %private function viewItem:person($item) {
    (:replaces Person.xsl :)
    $item
};
declare %private function viewItem:place($item) {
    (:replaces placesInstit.xsl :)
    $item
};
declare %private function viewItem:repo($item) {
    (:replaces placesInstit.xsl :)
    $item
};
declare %private function viewItem:auth($item) {
    (:replaces auth.xsl :)
    $item
};
declare %private function viewItem:corpus($item) {
    $item
};
declare %private function viewItem:manuscript($item) {
    (:replaces mss.xsl :)
    $item
};

declare function viewItem:main($item) {
    (:replaces the switch in items.xql, redirecting to distinct xslts :)
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
                    (viewItem:date($date/@notBefore) || '-' || viewItem:date($date/@notAfter))
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
    let $evidence := if ($date/@evidence) then
        concat(' (', $date/@evidence, ')')
    else
        ()
    let $cert := if ($date/@cert = 'low') then
        '?'
    else
        ()
    return
        ($dates, $evidence, $cert, viewItem:TEI2HTML($date/node()))
};


declare function viewItem:textfragment($frag) {
    <div>
        <div
            id="transcription">
            {
                if ($frag/[not(t:div)]) then
                    attribute class {'w3-container chapterText'}
                else
                    ()
            }
            {viewItem:TEI2HTML($frag)}
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
                        {$viewItem:editors//t:item[@xml:id = $r]/text()}
                    </span>
            }
        </div>
    </div>
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
            {$viewItem:editors//t:item[@xml:id = $r]/text()}
        </span>
};

declare function viewItem:worknav($item) {
    (
    <a
        class="w3-bar-item page-scroll"
        href="#description">Description</a>,
    if ($item//t:placeName) then
        <a
            class="w3-bar-item page-scroll"
            href="/IndexPlaces?entity={string($item/@xml:id)}">Places Index</a>
    else
        (),
    if ($item//t:persName) then
        <a
            class="w3-bar-item page-scroll"
            href="/IndexPersons?entity={string($item/@xml:id)}">Persons Index</a>
    else
        (),
    if ($item//t:body[t:div[@type = 'edition'][t:ab or t:div[@type = 'textpart']]]) then
        <a
            class="w3-bar-item page-scroll w3-red"
            href="/works/{$item/@xml:id}/text">Text</a>
    else
        (),
    if ($item//t:body[t:div[@type = 'translation'][t:ab or t:div[@type = 'textpart']]]) then
        <a
            class="w3-bar-item page-scroll w3-red"
            href="/works/{$item/@xml:id}/text">Translation</a>
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
        href="/IndexPersons?pointer={string($item/@xml:id)}">Persons Index</a>,
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
        href="/IndexPlaces?pointer={string($item/@xml:id)}">Places Index</a>,
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
            href="/IndexPlaces?entity={string($item/@xml:id)}">Places Index</a>
    else
        (),
    if ($item//t:persName) then
        <a
            class="w3-bar-item page-scroll"
            href="/IndexPersons?entity={string($item/@xml:id)}">Persons Index</a>
    else
        (),
        <a class="w3-bar-item page-scroll" href="#general">General</a>,
                            <a class="w3-bar-item page-scroll" href="#description">Description</a>,
                            <a class="w3-bar-item page-scroll" href="#generalphysical">Physical Description</a>,
                            if($item//t:msPart or $item//t:msFrag) then
                            <div class="w3-bar-item">
                                Main parts
                                <ul>
{                            for $part in ($item//t:msPart, $item//t:msFrag)
                            return 
                            <li>
                                        <a class="page-scroll" href="#{$part/@xml:id}">Codicological unit {substring(@xml:id, 1)}</a>
                                    </li>
                            }</ul>
                            </div>
                            else (),
                            if($item//t:additional//t:listBibl) then 
                            <a class="w3-bar-item page-scroll" href="#catalogue">Catalogue</a>
                            else (),
                            if($item//t:body[t:div]) then 
                            <a class=" w3-bar-item page-scroll" href="#transcription">Transcription </a>
                            else (),
                            <a class="w3-bar-item page-scroll" href="#footer">Authors</a>,
                              <button class="w3-button w3-red w3-bar-item" onclick="openAccordion('NavByIds')">Show more links</button>,
                <ul class="w3-bar-item w3-hide" id="NavByIds">
                {for $node at $p in $item//t:*[not(self::t:TEI)][@xml:id]
                let $anchor := string($node/@xml:id)
                order by $p
                return 
                <li>
                                    <a class="page-scroll" href="#{$anchor}">
                                    {if ($anchor ='ms') then 'General manuscript description'
                                    else if (starts-with($anchor, 'p') and matches($anchor, '^\w\d+$')) then 'Codicological Unit ' || substring($anchor, 1) || viewItem:headercontext($p)
                                    else if (starts-with($anchor, 'f') and matches($anchor, '^\w\d+$')) then 'Fragment ' || substring($anchor, 1) || viewItem:headercontext($p)
                                    else if (starts-with($anchor, 't') and matches($anchor, '\w\d+')) then 'Title ' || substring($anchor, 1) || viewItem:headercontext($p)
                                    else if (starts-with($anchor, 'b') and matches($anchor, '\w\d+')) then 'Binding ' || substring($anchor, 1) || viewItem:headercontext($p)
                                    else if (starts-with($anchor, 'a') and matches($anchor, '\w\d+')) then 'Addition ' || substring($anchor, 1) || viewItem:headercontext($p)
                                    else if (starts-with($anchor, 'e') and matches($anchor, '\w\d+')) then 'Extra ' || substring($anchor, 1) || viewItem:headercontext($p)
                                    else if (starts-with($anchor, 'd') and matches($anchor, '\w\d+')) then 'Decoration ' || substring($anchor, 1) || viewItem:headercontext($p)
                                    else if (starts-with($anchor, 'coloph') and matches($anchor, 'coloph')) then 'Colophon ' || substring($anchor, 1) || viewItem:headercontext($p)
                                    else if (starts-with($anchor, 'i') and matches($anchor, '\w\d+')) then 'Content Item ' || substring($anchor, 1) || viewItem:headercontext($p)
                                    else if (starts-with($anchor, 'q') and matches($anchor, '\w\d+')) then 'Quire ' || substring($anchor, 1) || viewItem:headercontext($p)
                                    else if (starts-with($anchor, 'h') and matches($anchor, '\w\d+')) then 'Hand ' || substring($anchor, 1) || viewItem:headercontext($p)
                                    else $p/name() }
                                    </a>
                                    </li>
                }
                            </ul>
                            
)
};

declare function viewItem:nav($item) {
    let $type := $item/@type
    return
        switch ($type)
            case 'work'
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
