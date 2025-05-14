xquery version "3.1";

module namespace expand = "https://www.betamasaheft.uni-hamburg.de/BetMas/expand";
import module namespace titles = "https://www.betamasaheft.uni-hamburg.de/BetMas/titles" at "xmldb:exist:///db/apps/BetMas/modules/titles.xqm";
import module namespace switch2 = "https://www.betamasaheft.uni-hamburg.de/BetMas/switch2"  at "xmldb:exist:///db/apps/BetMas/modules/switch2.xqm";
import module namespace console = "http://exist-db.org/xquery/console";
declare namespace t = "http://www.tei-c.org/ns/1.0";
declare namespace xi = "http://www.w3.org/2001/XInclude";
declare variable $expand:zotero := collection('/db/apps/EthioStudies') ;
declare variable $expand:BMurl := 'https://betamasaheft.eu/';
declare variable $expand:editorslist := doc('/db/apps/lists/editors.xml') ;
declare variable $expand:canontax := doc('/db/apps/lists/canonicaltaxonomy.xml');
declare variable $expand:fullTEIcol-path := '/db/apps/expanded';

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


(:~
 : Recursively creates new collections if necessary. 
 : improved from former gitsync:create-collections 
 : to avoid issues with parts of a uri which are the same
 : and directly change ownership and access
 : @param $uri url to resource being added to db 
 :)
declare function expand:create-collections($uri as xs:string) {
    let $collection-uri := substring($uri, 1)
   let $parts := for $part at $p in tokenize($collection-uri, '/') return <part n="{$p}">{$part}</part>
    for $collection at $p in $parts
    let $index := $collection/@n
    let $parent-collection := concat('/', string-join($parts[@n lt $index]/text(), '/'), '/')
    let $current-path := concat($parent-collection ,$collection)
    return
        if (xmldb:collection-available($current-path) or $current-path= '//') then
            ()
        else
            (xmldb:create-collection($parent-collection, $collection),
            let $createdcol := xs:anyURI($parent-collection||$collection)
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
        if (matches($id, 'betmas:')) then $id
    else
        if (contains($id, ':') and not(contains($id, '.'))) then
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
                            if(count($node//t:listRelation) ge 1) then
                            <standOff
                                xmlns="http://www.tei-c.org/ns/1.0">
                                <listRelation>
                                    {
                                        for $relations in $node//t:listRelation
                                        return
                                            expand:tei2fulltei($relations/node(), $bibliography)
                                    }
                                </listRelation>
                            </standOff> else (),
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
                        expand:tei2fulltei($node/node(), $bibliography),
                        expand:dateidno($node)
                        )
                    }
            case element(t:encodingDesc)
                return
                    element {fn:QName("http://www.tei-c.org/ns/1.0", name($node))} {
                        ($node/@*,
                        expand:tei2fulltei($node/node(), $bibliography)),
                        <p xmlns="http://www.tei-c.org/ns/1.0">Encoded according 
                        to the <ref target="https://betamasaheft.eu/Guidelines/">Beta maṣāḥǝft Guidelines</ref>. 
                        These Guidelines detail the TEI format ruled by 
                        the <ref target="https://betamasaheft.eu/Guidelines/?id=schemaView">Beta maṣāḥǝft Schema</ref>. 
                        The present TEI file is enriched with an 
                        <ref target="https://github.com/BetaMasaheft/BetMas/blob/master/db/apps/BetMas/modules/expand.xqm">Xquery transformation</ref> 
                        taking advantage of the <ref target="https://betamasaheft.eu">exist-db database instance</ref> where 
                        the data is stored and of the many external resources to which this data points to.</p>,
                        $expand:listPrefixDef,
                        <xi:include xmlns:xi="http://www.w3.org/2001/XInclude" href="xmldb:exist:///db/apps/lists/canonicaltaxonomy.xml">
            <xi:fallback>
               <p>Definitions of prefixes used.</p>
            </xi:fallback>
         </xi:include>,
<refsDecl xmlns="http://www.tei-c.org/ns/1.0">
{
let $text :=  $node/ancestor::t:TEI//t:div[@type = 'edition']
let $cS :=
     expand:citeStructBypass($text/(t:div | t:lg | t:l))
  (: a further step to reduce the list to similar instances should be performed grouping the citeStructures obtained:)
  
   return
   <citeStructure
        unit="edition"
        match="//div[@type='edition']"
        use="@xml:id" delim=".">
        {
       expand:groupCS($cS)
   }
    </citeStructure>
}
</refsDecl>
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
                        <title type="full">{try{titles:printTitleMainID(string($node/ancestor-or-self::t:TEI/@xml:id))} catch * {util:log('INFO', concat('no full title added for ', string($node/ancestor-or-self::t:TEI/@xml:id)))}}</title>
                        {expand:tei2fulltei($node/node(), $bibliography)}
                         {
                            let $gened := $node//t:editor[@role = 'generalEditor']/@key
                            for $resp in distinct-values($gened)
                            return
                                <respStmt
                                    xml:id="ed-{$resp}"
                                    corresp="https://betamasaheft.eu/team.html#{$resp}">
                                    <resp>general editor</resp>
                                    <name>{$expand:editorslist//t:item[@xml:id = string($resp)]/text()}</name>
                                </respStmt>
                        }
                         {
                            let $ekeys := $node//t:editor[not(@role = 'generalEditor')]/@key
                            for $resp in distinct-values($ekeys)
                            return
                                <respStmt
                                    xml:id="ed-{$resp}"
                                    corresp="https://betamasaheft.eu/team.html#{$resp}">
                                    <resp>editor</resp>
                                    <name>{$expand:editorslist//t:item[@xml:id = string($resp)]/text()}</name>
                                </respStmt>
                        }
                        {
                            let $ekeys := $node//t:editor/@key
                            let $cwhos := $node/ancestor-or-self::t:TEI//t:change/@who
                            for $resp in distinct-values($cwhos[not(. = $ekeys)])
                            return
                                <respStmt
                                    xml:id="{$resp}"
                                    corresp="https://betamasaheft.eu/team.html#{$resp}">
                                    <resp>contributor</resp>
                                    <name>{$expand:editorslist//t:item[@xml:id = string($resp)]/text()}</name>
                                </respStmt>
                        }
                                              
                    </titleStmt>
            case element(t:revisionDesc)
            return 
            element {fn:QName("http://www.tei-c.org/ns/1.0", name($node))} {
                        expand:tei2fulltei($node/node(), $bibliography)
                    }
           case element(t:change)
            return
            <change xmlns="http://www.tei-c.org/ns/1.0" who="#{$node/@who}" when="{$node/@when}"><!--{let $resp := $node/@who return $expand:editorslist//t:item[@xml:id = string($resp)]/text()}: -->{$node/text()}</change>
            case element(t:profileDesc)
                return
                    element {fn:QName("http://www.tei-c.org/ns/1.0", name($node))} {
                        (expand:tei2fulltei($node/node(), $bibliography),
                            <calendarDesc xmlns="http://www.tei-c.org/ns/1.0">
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
                        </calendarDesc>)
                    }
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
                   case element(t:msIdentifier)
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
                        else if ($node/@corresp) then
                            expand:reflike($node/@corresp)
                        else
                            (),
                        if ($node/@ref and not($node/text())) then
                            titles:printTitleMainID($node/@ref)
                        else
                            (),
                        if ($node/@type = 'authFile' and (string-length($node/text()) = 0)) then
                            titles:printTitleMainID($node/@corresp)
                        else
                            (),
                        if ( $node[not(text())] and $node/@corresp and $node/@type[not(. ='authFile')]) then
                        let $corrnode := $node/ancestor-or-self::t:TEI/id($node/@corresp) 
                        return
                            if ($corrnode) then
                                let $buildID := titles:printTitleMainID($node/ancestor-or-self::t:TEI/@xml:id) || ' element '|| $corrnode/name()|| ' with id ' || string($node/@corresp)
                                return
                                    $buildID
                           else if (starts-with($node/@corresp, '#')) then
                                let $buildID := titles:printTitleMainID($node/ancestor-or-self::t:TEI/@xml:id) || ' id ' || string($node/@corresp)
                                return
                                    $buildID
                            else
                                titles:printTitleID($node/@corresp)
                        else
                            (),
                        expand:tei2fulltei($node/node(), $bibliography))
                    }
            
            case element(t:editor)
                return
                    let $k := $node/@key
                    
                    return
                        element {fn:QName("http://www.tei-c.org/ns/1.0", name($node))} {
                            (
                            $node/@*,
                            attribute corresp {concat('https://betamasaheft.eu/team.html#', $k)},
                            attribute {'xml:id'} {$k},
                            $expand:editorslist//t:item[@xml:id = string($k)]/text(),
                            expand:tei2fulltei($node/node(), $bibliography)
                            )
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
                            expand:tei2fulltei($node/t:citedRange, $bibliography),
                            if($node/@corresp) then expand:biblCorresp($node/@corresp, $node) else (),
                            expand:tei2fulltei($node/t:note, $bibliography),
                            expand:tei2fulltei($node/t:ref, $bibliography)
                            )
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
   (:         case element(t:locus)
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
                                else if ($node/ancestor-or-self::t:TEI//t:extent/t:measure[@unit = 'page']) then 'pp'
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
                    }:)
            case element(t:idno)
                return
                    element {fn:QName("http://www.tei-c.org/ns/1.0", name($node))} {
                        ($node/@*,
                        if ($node/@facs) then
                            let $mainFacs := $node/@facs
                            return
                                attribute corresp {
                                    if (starts-with($mainFacs, 'http') or contains($mainFacs, 'vatlib') or contains($mainFacs, 'gallica')) then
                                        $mainFacs
                                    else    if (starts-with($mainFacs, '#')) then
                                        $mainFacs
                                    else
                                        concat($expand:BMurl, 'api/iiif/', $node/ancestor-or-self::t:TEI/@xml:id/data(), '/manifest')
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
            case element(t:origDate)
                return
                   expand:datelike($node, $bibliography)    
                    case element(t:date)
                return
                    expand:datelike($node, $bibliography)     
                      case element(t:birth)
                return
                    expand:datelike($node, $bibliography)     
                        case element(t:death)
                return
                    expand:datelike($node, $bibliography)     
                       case element(t:floruit)
                return
                    expand:datelike($node, $bibliography)     
                    
                    (:                    any other not named element goes through:)
            case element()
                return
                    try{element {fn:QName("http://www.tei-c.org/ns/1.0", name($node))} {
                        ($node/@*,
                (:         if($node[t:subst|t:choice]) then expand:optionsexpand($node, $bibliography)
                                 else :) 
                                 expand:tei2fulltei($node/node(), $bibliography)
                        )
                    }} catch * {util:log('INFO', $err:description), util:log('INFO', $node)}
                    (:                    anything which is not a node of those named above, including text() and attributes:)
            default
                return
                    $node
};

declare function expand:rn($n) as xs:string {
    if ($n/name() = 'cb') then
        (string($n/preceding::t:pb[@n][1]/@n) || string($n/@n))
    else
        if ($n/name() = 'pb' and $n/@corresp) then
            (string($n/@n) || '[' || substring-after($n/@corresp, '#') || ']')
        else
            if ($n/@n) then
                string($n/@n)
            else
                if ($n/@xml:id) then
                    string($n/@xml:id)
                else
                    if ($n/@subtype) then
                        string($n/@subtype)
                    else
                        'tei:' || $n/name() || '[' || $n/position() || ']'
};

declare function expand:citeStructure($level) {
    <citeStructure>
        {
            attribute unit {
                if ($level/@subtype) then
                    string($level/@subtype)
                else
                    if ($level/t:label) then
                        string-join($level/t:label//text())
                    else
                        if ($level/name() = 'lb') then
                            'line break'
                        else
                            if ($level/name() = 'cb') then
                                'column break'
                            else
                                if ($level/name() = 'pb') then
                                    'page break'
                                else
                                    $level/name()
            }
        }
        {attribute match {$level/name()}}
        {
            attribute use {
                if ($level/@n) then
                    '@n'
                else
                    if ($level/@subtype) then
                        '@subtype'
                    else
                        '@xml:id'
            }
        }
        <desc>{expand:rn($level)}</desc>
        {
            expand:citeStructBypass($level/(t:div | t:lg | t:l | t:cb | t:pb | t:lb))
        }
        {
           expand:citeStructBypass($level/t:ab/(t:div | t:lg | t:l | t:cb | t:pb | t:lb))
        }
    </citeStructure>
};


declare function expand:citeStructBypass($nodes){
for $sublevel in $nodes
            return
                expand:citeStructure($sublevel)
};

declare function expand:groupCS($cS){
 for $c in $cS 
        group by $Unit := $c/@unit
        return
        <citeStructure
        unit="{$Unit}"
        match="{distinct-values($c/@match)}"
        use="{distinct-values($c/@match)}">
       <desc><list> {for $desc in distinct-values($c/desc)
        return <item>{$desc}</item>}</list></desc>
        {expand:groupCS($c/citeStructure)}
        </citeStructure>
};

declare function expand:dateidno($node){
let $id := string($node/ancestor-or-self::t:TEI/@xml:id)
(:let $log := util:log('INFO', $id):)
return 
(<date xmlns="http://www.tei-c.org/ns/1.0" type="expanded">{format-dateTime(current-dateTime(), "[D1].[M1].[Y1] at [H01]:[m01]:[s01]")}</date>,
let $time := max($node/ancestor-or-self::t:TEI//t:revisionDesc/t:change/xs:date(@when))
return
(<date xmlns="http://www.tei-c.org/ns/1.0" type="lastModified">{format-date($time, '[D].[M].[Y]')}</date>
,
let $col := switch2:col($node/ancestor-or-self::t:TEI/@type) return
(<idno xmlns="http://www.tei-c.org/ns/1.0" type="collection">{$col}</idno>,
<idno xmlns="http://www.tei-c.org/ns/1.0" type="url">https://betamasaheft.eu/{$col}/{$id}/main</idno>),
<idno xmlns="http://www.tei-c.org/ns/1.0" type="URI">https://betamasaheft.eu/{$id}</idno>, 
<idno xmlns="http://www.tei-c.org/ns/1.0" type="filename">{$id}.xml</idno>,
<idno xmlns="http://www.tei-c.org/ns/1.0" type="ID">{$id}</idno>))
};

declare function expand:datelike($node, $bibliography){
element {fn:QName("http://www.tei-c.org/ns/1.0", name($node))} {
                        ($node/@*,
                        if (empty($node)) then
                            let $atts := for $att in $node/@* return  (
                            (switch($att/name()) 
                            case 'notBefore' return 'not before'
                            case 'notAfter' return 'not after' 
                            case 'cert' return 'certainty:' 
                            case 'resp' return titles:printTitleMainID($att)
                            default return $att/name()) || ' ' || $att/data())
                        return
                            string-join($atts, ' ')
                        else
                            (),
                          (:         if($node[t:subst|t:choice]) then expand:optionsexpand($node, $bibliography)
                                 else :) 
                                 expand:tei2fulltei($node/node(), $bibliography)
                        )
                    }
};
declare function expand:refel($node, $bibliography){
element {fn:QName("http://www.tei-c.org/ns/1.0", name($node))} {
                        ($node/@*[not(name() = 'ref')],
                        if ($node/@ref) then
                            expand:reflike($node/@ref)
                        else
                            (),
                        if ($node/@ref and not($node/text())) then
                            titles:printTitleID($node/@ref)
                        else
                            (),
                          (:         if($node[t:subst|t:choice]) then expand:optionsexpand($node, $bibliography)
                                 else :)  expand:tei2fulltei($node/node(), $bibliography)
                                 )
                    }};
declare function expand:attributes($node, $bibliography) {
    element {fn:QName("http://www.tei-c.org/ns/1.0", name($node))} {
        ($node/@*[not(name() = 'corresp')][not(name() = 'resp')][not(name() = 'who')][not(name() = 'ref')][not(name() = 'sameAs')][not(name() = 'calendar')],
        if ($node/@corresp and $node[not(@type = 'external')] ) then
            attribute corresp {$expand:BMurl || (if(starts-with($node/@corresp, '#')) then string($node/ancestor-or-self::t:TEI/@xml:id) || string($node/@corresp) else string($node/@corresp))}
        else
          if ($node/@corresp and $node[@type = 'external'] ) then
            attribute corresp { (if(starts-with($node/@corresp, '#')) then string($node/ancestor-or-self::t:TEI/@xml:id) || string($node/@corresp) else string($node/@corresp))}
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
        if ($node/name() = 'witness' and $node[not(@type = 'external')] and not($node/text()))
        then
            (
            let $filename := if (contains($node/@corresp, '#')) then
                substring-before($node/@corresp, '#')
            else
                $node/@corresp
            let $file := collection('/db/apps/BetMasData/')/id($filename)
            return
                ($file//t:msIdentifier/t:idno)
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
                        let $z := if($expand:zotero//t:biblStruct[t:note[@type='tags']/t:note[@type='tag'] = $ptr])
                                    then $expand:zotero//t:biblStruct[t:note[@type='tags']/t:note[@type='tag'] = $ptr][1]
                                    else try{doc(concat('https://api.zotero.org/groups/358366/items?tag=',$ptr, '&amp;format=tei'))//t:biblStruct} catch * {console:log($err:description)}
                            return 
                            <bibl xmlns="http://www.tei-c.org/ns/1.0">
                                     {if($z/@corresp) then attribute corresp {$z/@corresp} else ()}
                                     {if($z/@type) then attribute type {$z/@type} else ()}
                            <ptr target="{$ptr}"/>
                            {for $t in $z//t:title return <title>{$t/@*}{$t/node()}</title>}
                            {for $a in $z//t:author return <author>{$a/@*}{$a/node()}</author>}
                            {for $a in $z//t:editor return <editor>{$a/@*}{$a/node()}</editor>}
                            {for $a in $z//t:pubPlace return <pubPlace>{$a/@*}{$a/node()}</pubPlace>}
                            {for $a in $z//t:publisher return <publisher>{$a/@*}{$a/node()}</publisher>}
                            {for $a in $z//t:date return <date>{$a/@*}{$a/node()}</date>}
                            {for $a in $z//t:series return <series>{$a/@*}{$a/node()}</series>}
                            {for $a in $z//t:biblScope return <biblScope>{$a/@*}{$a/node()}</biblScope>}
                            {for $a in $z//t:note return <note>{$a/@*}{$a/node()}</note>}
                            </bibl>
    (:                            let $test := console:log($zotero):)
    return
        document {
            expand:tei2fulltei($expanded, $zotero)
        }
};

(:
declare function expand:optionsexpand($model, $bibliography){
if($model/t:choice[t:corr][t:sic]) then
<choice xmlns="http://www.tei-c.org/ns/1.0"><corr>{$model//t:corr/@resp}{
for $n in $model/node() return if ($n/self::t:choice) then expand:tei2fulltei($n/t:corr/node(), $bibliography) else expand:tei2fulltei($n, $bibliography)}</corr>
<sic>{$model//t:sic/@resp}{for $n in $model/node() return if ($n/self::t:choice) then expand:tei2fulltei($n/t:sic/node(), $bibliography) else expand:tei2fulltei($n, $bibliography)}</sic></choice>
else if ($model/t:choice[t:reg][t:orig]) then
<choice xmlns="http://www.tei-c.org/ns/1.0"><reg>{$model//t:reg/@resp}{for $n in $model/node() return if ($n/self::t:choice) then expand:tei2fulltei($n/t:reg/node(), $bibliography) else expand:tei2fulltei($n, $bibliography)}</reg>
<orig>{$model//t:orig/@resp}{for $n in $model/node() return if ($n/self::t:choice) then expand:tei2fulltei($n/t:orig/node(), $bibliography) else expand:tei2fulltei($n, $bibliography)}</orig></choice>
else
<subst xmlns="http://www.tei-c.org/ns/1.0"><del>{$model//t:del/@*}{for $n in $model/node() return if ($n/self::t:subst) then expand:tei2fulltei($n/t:del/node(), $bibliography) else expand:tei2fulltei($n, $bibliography)}</del>
<add>{$model//t:add/@*}{for $n in $model/node() return if ($n/self::t:subst) then expand:tei2fulltei($n/t:add/node(), $bibliography) else expand:tei2fulltei($n, $bibliography)}</add></subst>
}; 
:)

declare function expand:biblCorrTok($corresp, $node){
let $c :=if(starts-with($corresp, '#')) then concat($node/ancestor-or-self::t:TEI/@xml:id, $corresp) else string($corresp) 
let $anchor := if(contains($corresp, '#')) then substring-after($corresp, '#') else string($corresp)
let $anchornode := $node/id($anchor)
let $listWit := if ($anchornode/name() = 'listWit') then for $witness in $anchornode return titles:printTitleID($witness/@corresp) else ()
let $prefix := if($listWit ge 1) then $listWit else if(string-length($anchornode/name()) ge 1) then (' ', $anchornode/name(), ' ') else ()
let $lang := if (string-length($anchornode/@xml:lang) ge 1) then concat(' [', $node//t:language[@ident = $anchornode/@xml:lang], ']') else ()
let $wit :=  if ($anchornode/name() = 'witness' and $anchornode[not(@type = 'external')] and not($anchornode/text()))
        then
            (
            let $filename := if (contains($anchornode/@corresp, '#')) then
                substring-before($anchornode/@corresp, '#')
            else
                $anchornode/@corresp
            let $file := collection('/db/apps/BetMasData/')/id($filename)
            return
                ($file//t:msIdentifier/t:idno)
            )
        else
            ()
let $text := if ($anchornode//text()) then $anchornode//text() else if ($wit) then string($wit) else substring-after($corresp, '#')
return 
($prefix,
<ref xmlns="http://www.tei-c.org/ns/1.0" target="https://betamasaheft.eu/{$node/ancestor-or-self::t:TEI/@xml:id}#{$anchor}">{$text}</ref>)
};
declare function expand:biblCorresp($corresp, $node){
let $string := normalize-space($corresp) return
<note xmlns="http://www.tei-c.org/ns/1.0" type='about'>about {
if(contains($string, ' ')) then for $corr at $p in tokenize($string, ' ') return  
(expand:biblCorrTok($corr, $node), if ($p = count(tokenize($string, ' '))) then
            ()
        else
            ', ')
else expand:biblCorrTok($corresp, $node)
}</note>
};