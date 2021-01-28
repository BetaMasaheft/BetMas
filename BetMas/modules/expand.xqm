xquery version "3.1";

module namespace expand = "https://www.betamasaheft.uni-hamburg.de/BetMas/expand";
import module namespace titles = "https://www.betamasaheft.uni-hamburg.de/BetMas/titles" at "xmldb:exist:///db/apps/BetMas/modules/titles.xqm";
import module namespace console = "http://exist-db.org/xquery/console";
declare namespace t = "http://www.tei-c.org/ns/1.0";
declare namespace xi = "http://www.w3.org/2001/XInclude";

declare variable $expand:listPrefixDef :=
<listPrefixDef
    xmlns="http://www.tei-c.org/ns/1.0">
    <prefixDef
        ident="bm"
        matchPattern="([a-zA-Z0-9]+)"
        replacementPattern="https://www.zotero.org/groups/358366/ethiostudies/items/tag/bm:$1">
    </prefixDef>
    <prefixDef
        ident="betmas"
        matchPattern="([a-zA-Z0-9]+)"
        replacementPattern="https://betamasaheft.eu/$1">
    </prefixDef>
    <prefixDef
        ident="ethiocal"
        matchPattern="([a-zA-Z0-9]+)"
        replacementPattern="https://raw.githubusercontent.com/BetaMasaheft/BetMas/master/BetMas/calendars/ethiopian.xml#$1">
    </prefixDef>
    <prefixDef
        ident="pleiades"
        matchPattern="(\d{5 - 8})"
        replacementPattern="https://pleiades.stoa.org/places/$1">
    </prefixDef>
    <prefixDef
        ident="sdc"
        matchPattern="([a-zA-Z0-9]+)"
        replacementPattern="https://w3id.org/sdc/ontology#$1">
    </prefixDef>
    <prefixDef
        ident="wd"
        matchPattern="([a-zA-Z0-9]+)"
        replacementPattern="https://www.wikidata.org/entity/$1">
    </prefixDef>
    <prefixDef
        ident="snap"
        matchPattern="([a-zA-Z]+)"
        replacementPattern="http://data.snapdrgn.net/ontology/snap#$1">
    </prefixDef>
    <prefixDef
        ident="saws"
        matchPattern="([a-zA-Z]+)"
        replacementPattern="http://purl.org/saws/ontology#$1">
    </prefixDef>
    <prefixDef
        ident="skos"
        matchPattern="([a-za-zA-Z]+)"
        replacementPattern="http://www.w3.org/2004/02/skos/core#$1">
    </prefixDef>
    <prefixDef
        ident="gn"
        matchPattern="([a-zA-Z0-9]+)"
        replacementPattern="http://www.geonames.org/ontology#$1">
    </prefixDef>
    <prefixDef
        ident="dcterms"
        matchPattern="([a-zA-Z]+)"
        replacementPattern="http://purl.org/dc/terms/$1">
    </prefixDef>
    <prefixDef
        ident="dc"
        matchPattern="([a-zA-Z]+)"
        replacementPattern="http://purl.org/dc/terms/$1">
    </prefixDef>
    <prefixDef
        ident="lawd"
        matchPattern="([a-zA-Z]+)"
        replacementPattern="http://lawd.info/ontology/$1">
    </prefixDef>
    <prefixDef
        ident="syriaca"
        matchPattern="([a-zA-Z\-]+)"
        replacementPattern="http://syriaca.org/documentation/relations.html#$1">
    </prefixDef>
    
    <prefixDef
        ident="agrelon"
        matchPattern="([a-zA-Z]+)"
        replacementPattern="http://d-nb.info/standards/elementset/agrelon.owl#$1">
    </prefixDef>
    <prefixDef
        ident="rel"
        matchPattern="([a-zA-Z]+)"
        replacementPattern="http://purl.org/vocab/relationship/$1">
    </prefixDef>
    <prefixDef
        ident="em"
        matchPattern="(\d+)"
        replacementPattern="https://www.eagle-network.eu/voc/material/lod/$1">
    </prefixDef>
    
    <prefixDef
        ident="eo"
        matchPattern="(\d+)"
        replacementPattern="https://www.eagle-network.eu/voc/objtyp/lod/$1">
    </prefixDef>
    
    <prefixDef
        ident="ew"
        matchPattern="(\d+)"
        replacementPattern="https://www.eagle-network.eu/voc/writing/lod/$1">
    </prefixDef>
    <prefixDef
        ident="ic"
        matchPattern="([a-zA-Z0-9]+)"
        replacementPattern="http://iconclass.org/$1">
    </prefixDef>
    <prefixDef
        ident="ecrm"
        matchPattern="([a-zA-Z0-9]+)"
        replacementPattern="http://erlangen-crm.org/current/$1">
    </prefixDef>
    <prefixDef
        ident="foaf"
        matchPattern="([a-zA-Z0-9]+)"
        replacementPattern="http://xmlns.com/foaf/0.1/$1">
    </prefixDef>
</listPrefixDef>;

declare variable $expand:BMurl := 'https://betamasaheft.eu/';
declare variable $expand:editorslist := doc('/db/apps/BetMas/lists/editors.xml')//t:list;
declare variable $expand:canontax := doc('/db/apps/BetMas/lists/canonicaltaxonomy.xml');

declare variable $expand:fullTEIcol-path := '/db/apps/expanded';

declare function expand:create-collections($uri as xs:string) {
    let $collection-uri := substring($uri, 1)
    for $collections in tokenize($collection-uri, '/')
    let $current-path := concat('/', substring-before($collection-uri, $collections), $collections)
    let $parent-collection := substring($current-path, 1, string-length($current-path) - string-length(tokenize($current-path, '/')[last()]))
    return
        if (xmldb:collection-available($current-path)) then
            ()
        else
            (xmldb:create-collection($parent-collection, $collections),
            let $createdcol := xs:anyURI($parent-collection||'/'||$collections)
            return(
            sm:chgrp($createdcol, 'Cataloguers'),
            sm:chmod($createdcol, 'rwxrwxr-x'))
            )
};

declare function expand:id($id) {
    (:   refactoring from post.xslt post:id :)
    if (starts-with($id, 'http')) then
        $id
    else
        if (contains($id, ':')) then
            let $prefix := substring-before($id, ':')
            let $pdef := $expand:listPrefixDef//t:prefixDef[@ident = $prefix]
            return
                if ($pdef) then
                    replace(substring-after($id, ':'), $pdef/@matchPattern, $pdef/@replacementPattern)
                else
                    concat('no matching prefix ', $prefix, ' found for ', $id)
        else
            'https://betamasaheft.eu/' || $id
};

declare function expand:token($val) {
    (:   refactoring from post.xslt post:token :)
    if (contains($val, ' '))
    then
        let $links := for $l in tokenize($val, ' ')
        return
            expand:id($l)
        return
            string-join($links, ' ')
    else
        expand:id($val)
};

declare function expand:tei2fulltei($nodes as node()*, $bibliography) {
    (:   refactoring of post.xslt:)
    for $node in $nodes
    return
        typeswitch ($node)
            (:        clears all comments:)
            case comment()
                return
                    ()
            case element(t:TEI)
                return
                    <TEI
                        xmlns="http://www.tei-c.org/ns/1.0">{
                            $node/@type, $node/@xml:lang, $node/@xml:id,
                            expand:tei2fulltei($node/t:teiHeader, $bibliography),
                            <standOff
                                xmlns="http://www.tei-c.org/ns/1.0">
                                <listRelation>
                                    {
                                        for $relations in $node//t:listRelation
                                        return
                                            expand:tei2fulltei($relations/node(), $bibliography)
                                    }
                                </listRelation>
                            </standOff>,
                            expand:tei2fulltei($node/t:facsimile, $bibliography),
                            expand:tei2fulltei($node/t:text, $bibliography)
                        }</TEI>
            case element(t:listRelation)
                return
                    ()
            case element(t:listPrefixDef)
                return
                    ()
            case element(t:publicationStmt)
                return
                    element {fn:QName("http://www.tei-c.org/ns/1.0", name($node))} {
                        ($node/@*,
                        expand:tei2fulltei($node/node(), $bibliography)),
                        <date>{current-dateTime()}</date>
                    }
            case element(t:encodingDesc)
                return
                    element {fn:QName("http://www.tei-c.org/ns/1.0", name($node))} {
                        ($node/@*,
                        expand:tei2fulltei($node/node(), $bibliography)),
                        $expand:canontax
                    }
            case element(t:relation)
                return
                    <relation
                        xmlns="http://www.tei-c.org/ns/1.0"
                        name="{$node/@name}"
                        ref="{expand:id($node/@name)}"
                    >{
                            for $attribute in ($node/@active | $node/@passive | $node/@mutual)
                            return
                                attribute {$attribute/name()} {expand:token(normalize-space($attribute))}
                            ,
                            expand:tei2fulltei($node/node(), $bibliography)
                        }</relation>
            case element(t:titleStmt)
                return
                    <titleStmt
                        xmlns="http://www.tei-c.org/ns/1.0">
                        {expand:tei2fulltei($node/node(), $bibliography)}
                        {
                            let $ekeys := $node//t:editor/@key
                            let $cwhos := $node/ancestor::t:TEI//t:change/@who
                            for $resp in distinct-values($cwhos[not(. = $ekeys)])
                            return
                                <respStmt
                                    xml:id="{$resp}"
                                    corresp="https://betamasaheft.eu/team.html#{$resp}">
                                    <resp>contributor</resp>
                                    <name>{$expand:editorslist//t:item[@xml:id = $resp]/text()}</name>
                                </respStmt>
                        }
                    </titleStmt>
            case element(t:profileDesc)
                return
                    <profileDesc
                        xmlns="http://www.tei-c.org/ns/1.0">
                        {expand:tei2fulltei($node/node(), $bibliography)}
                        <calendarDesc>
                            <calendar
                                xml:id="world">
                                <p>ʿĀmata ʿālam/ʿĀmata ʾəm-fəṭrat (Era of the World)</p>
                            </calendar>
                            <calendar
                                xml:id="ethiopian">
                                <p> ʿĀmata śəggāwe (Era of the Incarnation –
                                    Ethiopian)</p>
                            </calendar>
                            <calendar
                                xml:id="grace">
                                <p>ʿĀmata məḥrat (Era of Grace)</p>
                            </calendar>
                            <calendar
                                xml:id="diocletian">
                                <p>ʿĀmata samāʿtāt (Era of Martyrs (Diocletian))</p>
                            </calendar>
                            <calendar
                                xml:id="alexander">
                                <p> Era of Alexander</p>
                            </calendar>
                            <calendar
                                xml:id="evangelists">
                                <p>Evangelists' years</p>
                            </calendar>
                            <calendar
                                xml:id="islamic">
                                <p>Hiǧrī (Islamic)</p>
                            </calendar>
                            <calendar
                                xml:id="hijri">
                                <p>Hiǧrī (Islamic) in IslHornAfr</p>
                            </calendar>
                            <calendar
                                xml:id="julian">
                                <p>Julian</p>
                            </calendar>
                        </calendarDesc>
                    </profileDesc>
            case element(t:title)
                return
                   expand:refel($node, $bibliography)
            case element(t:persName)
                return
                  expand:refel($node, $bibliography)
            case element(t:placeName)
                return
                   expand:refel($node, $bibliography)
                     case element(t:origPlace)
                return
                   expand:refel($node, $bibliography)
            case element(t:repository)
                return
                   expand:refel($node, $bibliography)
                     case element(t:settlement)
                return
                   expand:refel($node, $bibliography)
                    case element(t:region)
                return
                    expand:refel($node, $bibliography)
                    case element(t:country)
                return
                    expand:refel($node, $bibliography)
            case element(t:ref)
                return
                    element {fn:QName("http://www.tei-c.org/ns/1.0", name($node))} {
                        ($node/@*[not(name() = 'ref')][not(name() = 'corresp')],
                        if ($node/@ref) then
                            expand:reflike($node/@ref)
                        else
                            (),
                        if ($node/@ref and not($node/text())) then
                            titles:printTitleMainID($node/@ref)
                        else
                            (),
                        if ($node/@type = 'authFile' and not($node/text())) then
                            titles:printTitleMainID($node/@corresp)
                        else
                            (),
                        if ( $node[not(text())] and $node/@corresp and $node/@type) then
                        let $corrnode := $node/ancestor::t:TEI/id($node/@corresp) 
                        return
                            if ($corrnode) then
                                let $buildID := titles:printTitleMainID($node/ancestor::t:TEI/@xml:id) || ' element '|| $corrnode/name()|| ' with id ' || string($node/@corresp)
                                return
                                    $buildID
                           else if (starts-with($node/@corresp, '#')) then
                                let $buildID := titles:printTitleMainID($node/ancestor::t:TEI/@xml:id) || ' id ' || string($node/@corresp)
                                return
                                    $buildID
                            else
                                titles:printTitleMainID($node/@corresp)
                        else
                            (),
                        expand:tei2fulltei($node/node(), $bibliography))
                    }
            
            case element(t:editor)
                return
                    let $k := $node/@key
                    return
                        element {fn:QName("http://www.tei-c.org/ns/1.0", name($node))} {
                            ($node/@*,
                            attribute corresp {concat('https://betamasaheft.eu/team.html#', $k)},
                            attribute {'xml:id'} {$k},
                            $expand:editorslist//t:item[@xml:id = $k]/text(),
                            expand:tei2fulltei($node/node(), $bibliography))
                        }
            case element(t:bibl)
                return
                    let $target := $node/t:ptr/@target
                    let $matchingbibl := $bibliography[t:ptr/@target = $target]
                    return
                        element {fn:QName("http://www.tei-c.org/ns/1.0", name($node))} {
                            ($node/@*[not(name()='corresp')],
                            $matchingbibl/@*[not(name()='type')],
                            if($node/@corresp or $matchingbibl/@type) then <seg xmlns="http://www.tei-c.org/ns/1.0" > 
                            {if($node/@corresp) then attribute corresp {$node/@corresp} else (), 
                            if($matchingbibl/@type) then attribute type {$matchingbibl/@type} else ()}
                            <!-- attributes from original bibl-->
                            </seg> else (),
                            $matchingbibl/element(),
                            expand:tei2fulltei($node/t:citedRange, $bibliography))
                        }
            case element(t:handNote)
                return
                    expand:attributes($node, $bibliography)
            case element(t:div)
                return
                    expand:attributes($node, $bibliography)
            case element(t:witness)
                return
                    expand:attributes($node, $bibliography)
            case element(t:term)
                return
                    let $k := $node/@key
                    return
                        element {fn:QName("http://www.tei-c.org/ns/1.0", name($node))} {
                            ($node/@*,
                            attribute ana {concat('#', $k)},
                            if (empty($node)) then
                                $expand:canontax//t:category[@xml:id = $k]/t:catDesc/text()
                            else
                                (),
                            expand:tei2fulltei($node/node(), $bibliography))
                        }
            case element(t:locus)
                return
                    element {fn:QName("http://www.tei-c.org/ns/1.0", name($node))} {
                        ($node/@*,
                        if ($node[not(text())]) then
                            (
                            let $valandcomma := (
                            let $fF := if ($node/preceding-sibling::text())
                            then
                                let $prevTextNode := $node/preceding-sibling::text()
                                let $clean := replace(string-join($prevTextNode), '\s', '')
                                return
                                    if (matches($clean, '[^\.]$'))
                                    then
                                        'f'
                                    else
                                        'F'
                            else
                                'F'
                            let $fFornot := if (($node/preceding-sibling::element())[1]/name() = 'locus') then
                                'x'
                                else if ($node/ancestor::t:TEI//t:extent/t:measure[@unit = 'page']) then 'pp'
                            else
                                if (($node/following-sibling::element())[1]/name() = 'locus') then
                                    ($fF || 'ols')
                                else
                                    ($fF || 'ol')
                            
                            let $value :=
                            (if ($node/@from and $node/@to)
                            then
                                
                                (
                                if ($fFornot = 'x') then
                                    ()
                                else
                                    ($fFornot ||
                                    (if (ends-with($fFornot, 's')) then
                                        ' '
                                    else
                                        's ')
                                    ))
                                || string($node/@from) || '–' || string($node/@to)
                            else
                                if ($node/@from) then
                                    ((if ($fFornot = 'x') then
                                        ()
                                    else
                                        ($fFornot || (if (ends-with($fFornot, 's')) then
                                            ' '
                                        else
                                            's ')))
                                    || string($node/@from || ' and following'))
                                else
                                    if ($node/@target)
                                    then
                                        let $targets :=
                                        if (contains($node/@target, ' '))
                                        then
                                            let $ts := for $t in tokenize($node/@target, ' ')
                                            return
                                                substring-after($t, '#')
                                            return
                                                (if ($fFornot = 'x') then
                                                    ()
                                                else
                                                    ($fFornot || 's. '))
                                                || string-join($ts, ', ')
                                        else
                                            ((if ($fFornot = 'x') then
                                                ()
                                            else
                                                ($fFornot || '. '))
                                            || substring-after(string($node/@target), '#'))
                                        let $cutlistoftargets := if (count($targets) ge 3) then
                                            (subsequence($targets, 1, 3), 'etc.')
                                        else
                                            $targets
                                        return
                                            string-join($cutlistoftargets, ', ')
                                    else
                                        $node/node()
                            )
                            return
                                $value
                            ,
                            if (($node/following-sibling::element())[1]/name() = 'locus') then
                                ', '
                            else
                                ()
                            )
                            
                            return
                                replace(string-join($valandcomma), ' , ', ', ')
                            )
                        else
                            (),
                        expand:tei2fulltei($node/node(), $bibliography))
                    }
            case element(t:idno)
                return
                    element {fn:QName("http://www.tei-c.org/ns/1.0", name($node))} {
                        ($node/@*[not(name() = 'facs')],
                        if ($node/@facs) then
                            let $mainFacs := $node/@facs
                            return
                                attribute facs {
                                    if (contains($mainFacs, 'vatlib') or contains($mainFacs, 'gallica')) then
                                        $mainFacs
                                    else
                                        concat($expand:BMurl, 'api/iiif/', $node/ancestor::t:TEI/@xml:id/data(), '/manifest')
                                }
                        else
                            (),
                        expand:tei2fulltei($node/node(), $bibliography))
                    }
            case element(t:material)
                return
                    element {fn:QName("http://www.tei-c.org/ns/1.0", name($node))} {
                        ($node/@*,
                        if (empty($node)) then
                            string($node/@key)
                        else
                            (),
                        expand:tei2fulltei($node/node(), $bibliography))
                    }
            case element(t:condition)
                return
                    element {fn:QName("http://www.tei-c.org/ns/1.0", name($node))} {
                        ($node/@*,
                        if (empty($node)) then
                            string($node/@key)
                        else
                            (),
                        expand:tei2fulltei($node/node(), $bibliography))
                    }
            case element(t:custEvent)
                return
                    element {fn:QName("http://www.tei-c.org/ns/1.0", name($node))} {
                        ($node/@*,
                        if (empty($node)) then
                            string($node/@type)
                        else
                            (),
                        expand:tei2fulltei($node/node(), $bibliography))
                    }
                    (:                    any other not named element goes through:)
            case element()
                return
                    try{element {fn:QName("http://www.tei-c.org/ns/1.0", name($node))} {
                        ($node/@*,
                        expand:tei2fulltei($node/node(), $bibliography))
                    }} catch * {console:log($err:description), console:log($node)}
                    (:                    anything which is not a node of those named above, including text() and attributes:)
            default
                return
                    $node
};


declare function expand:refel($node, $bibliography){
element {fn:QName("http://www.tei-c.org/ns/1.0", name($node))} {
                        ($node/@*[not(name() = 'ref')],
                        if ($node/@ref) then
                            expand:reflike($node/@ref)
                        else
                            (),
                        if ($node/@ref and not($node/text())) then
                            titles:printTitleMainID($node/@ref)
                        else
                            (),
                        expand:tei2fulltei($node/node(), $bibliography))
                    }};
declare function expand:attributes($node, $bibliography) {
    element {fn:QName("http://www.tei-c.org/ns/1.0", name($node))} {
        ($node/@*[not(name() = 'corresp')][not(name() = 'resp')][not(name() = 'who')][not(name() = 'ref')][not(name() = 'sameAs')][not(name() = 'calendar')],
        if ($node/@corresp) then
            attribute corresp {$expand:BMurl || string($node/@corresp)}
        else
            (),
        if ($node/@calendar) then
            attribute calendar {'#' || $node/@calendar/data()}
        else
            (),
        if ($node/@who) then
            expand:wholike($node/@who)
        else
            (),
        if ($node/@resp) then
            expand:wholike($node/@resp)
        else
            (),
        if ($node/@ref) then
            expand:reflike($node/@ref)
        else
            (),
        if ($node/@sameAs) then
            expand:reflike($node/@sameAs)
        else
            (),
        expand:tei2fulltei($node/node(), $bibliography)),
        if ($node/name() = 'witness' and $node[not(@type = 'external')])
        then
            (
            let $filename := if (contains($node/@corresp, '#')) then
                substring-before($node/@corresp, '#')
            else
                $node/@corresp
            let $file := collection('/db/apps/BetMasData/')/id($filename)
            return
                ($file//t:msIdentifier/t:idno,
                $file//t:titleStmt/t:title)
            )
        else
            ()
    }
};

declare function expand:reflike($attribute) {
    attribute {name($attribute)} {
        if (string-length($attribute/data()) le 3)
        then
            concat('#', $attribute/data())
        else
            expand:id($attribute)
    }
};
declare function expand:wholike($attribute) {
    attribute {name($attribute)} {expand:id($attribute/data())}
};

declare function expand:file($filepath) {
    let $doc := doc($filepath)
    (:util:expand needs to go to a node, therefore the processing instructions need to be added back:)
    let $expanded := util:expand($doc/t:TEI)
    let $zotero :=
      for $ptr in distinct-values($expanded//t:ptr/@target[starts-with(., 'bm:')]) 
                        let $z := try{doc(concat('https://api.zotero.org/groups/358366/items?tag=',$ptr, '&amp;format=tei'))//t:biblStruct} catch * {console:log($err:description)}
                            return 
                            <bibl xmlns="http://www.tei-c.org/ns/1.0"
                                     corresp="{$z/@corresp}" 
                                     type="{$z/@type}">
                            <ptr target="{$ptr}"/>
                            {$z//t:title}
                            {$z//t:author}
                            {$z//t:editor}
                            {$z//t:pubPlace}
                            {$z//t:publisher}
                            {$z//t:date}
                            {$z//t:series}
                            {$z//t:biblScope}
                            {$z//t:note}
                            </bibl>
    (:                            let $test := console:log($zotero):)
    return
        document {
            expand:tei2fulltei($expanded, $zotero)
        }
};
