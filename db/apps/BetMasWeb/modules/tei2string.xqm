xquery version "3.1" encoding "UTF-8";
(:~
 : module producing string from nodes with mixed content
 : @author Pietro Liuzzo 
 :)

module namespace string = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/string";
import module namespace exptit="https://www.betamasaheft.uni-hamburg.de/BetMasWeb/exptit" at "xmldb:exist:///db/apps/BetMasWeb/modules/exptit.xqm";
import module namespace editors = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/editors" at "editors.xqm";
declare namespace test="http://exist-db.org/xquery/xqsuite";
declare namespace t = "http://www.tei-c.org/ns/1.0";
declare namespace http = "http://expath.org/ns/http-client";

declare function string:date($node){
 let $cal := if($node/@calendar) then (' (' || $node/@calendar || ')') else ()
                   let $date :=
                    if ($node/@when) then
                        string:date($node/@when)
                        else
                        if ($node/@notBefore and $node/@notAfter) then
                        string:date($node/@notBefore) || ' - ' ||  string:date($node/@notAfter) 
                        else
                            string:tei2string($node/node())
                            return 
                            string-join($date, ' ') || $cal
                            };
declare function string:ref($node){
 if ($node/@corresp) then
                        exptit:printTitleID($node/@corresp)
                    else
                        if ($node/@target) then
                            if (starts-with($node/@target, '#')) 
                            then
                                  let $anchor := substring-after($node/@target, '#')
                                  let $r :=root($node)
                                  let $item :=$r//t:*[@xml:id eq $anchor]
                                  let $nodeName := $item/name()
                                  let $title := switch($nodeName) 
                                                case 'persName' return
                                                                                            if($r//t:persName[@type eq  'normalized'][contains(@corresp,$anchor)]) 
                                                                                            then string-join($r//t:persName[@type eq  'normalized'][contains(@corresp,$anchor)]//text(), '')
                                                                                            else normalize-space(string-join($item, '')) 
                                                case 'msItem' return 
                                                                         if ($item/t:title/@ref)
                                                                            then
                                                                         (exptit:printTitleID(string($item/t:title/@ref)) || ' (in ' || $nodeName || $anchor || ')')
                                                                         else
                                              normalize-space(string-join(string:tei2string($item/t:title), ''))
                     
                                                case 'div' return
                                                                if($item[@type eq  'edition']) then (
                                                                
                     
                                                                'edition ' || (if($item[@resp]) then (let $respsource := string($item/@resp)
                                                                                                                                    let $resp := if(starts-with($respsource, '#')) then ( $anchor) 
                                                                                                                                                            else 'by ' || editors:editorKey($respsource)
                                                                                                                                    return $resp)
                                                                                                                          else $anchor
                                                                )
                                                                )
                                                                else if ($item/t:label) then
                                                                                normalize-space(string-join(string:tei2string($item/t:label), ''))
                                                                else if ($item/t:desc) then
                                                                                 (exptit:printTitleID(string($item/t:desc/@type)) || ' ' || $anchor)
                                                                else if ($item/@subtype) then
                                                                                  (exptit:printTitleID(string($item/@subtype)) || ': ' || $anchor)
                                                                 else
                                                                     ($item/name() || ' ' || $anchor)
                                                case 'title' return 'title' || ($item/@xml:lang || $item)
                                                case 'handNote' return 'hand ' || $anchor
                                                case 'decoNote' return 'decoration ' || $anchor
                                                case 'layout' return 'layout note ' || $anchor
                                                default return $nodeName || ' ' || $anchor
                                  return
                                $title 
                            else
                                (string($node/@target))
                        else
                            string:tei2string($node/node())
                            };
declare function string:locus($node){
 if($node/@from and $node/@to) 
                    then ('ff. ' || $node/@from || '-' || $node/@to)
                    else if($node/@from) then ('ff. ' || $node/@from || '-')
                    else if($node/@target) then 
                          if (contains($node/@target, ' ')) 
                          then 
                                let $targets :=  for $t in tokenize($node/@target, ' ') 
                                                        return substring-after($t, '#') 
                                return 'ff.'|| string-join($targets, ', ') 
                          else('f. ' || substring-after($node/@target, '#'))
                    else ()};
                    
(:takes a node as argument and loops through each element it contains. if it matches one of the definitions it does that, otherways checkes inside it. This actually reproduces the logic of the apply-templates function in  xslt:)
declare function string:tei2string($nodes as node()*) {
    
    for $node in $nodes
    return
        typeswitch ($node)
        (:case text()
        return
        for $w in tokenize($node, '\s') return <span class="word">{$w}</span>
        :)case element(a)
                return
                    <a
                        href="{string($node/@href)}">{$node/text()}</a>
            case element(i)
                return
                    <i>{$node/text()}</i>
            
          case element(t:listBibl)
        return
            <div>
                <h4>Bibliography</h4>
                {string:tei2string($node/node())}
            </div>
    
        case element(t:bibl)
        return
            if ($node/node()) then
                string:Zotero($node/t:ptr/@target)
            else
                ()
         case element(t:locus)
                return
                   string:locus($node)
            case element(t:persName)
                return
                    if($node/text()) then $node/text() else exptit:printTitleID($node/@ref)
            case element(t:placeName)
                return
                    if($node/text()) then $node/text() else 
                    exptit:printTitleID($node/@ref)
            case element(t:title)
                return
                   if($node/@ref) then exptit:printTitleID($node/@ref) else string:tei2string($node/node())
                    case element(t:term)
                return
                   if($node/@key) then exptit:printTitleID($node/@key) else $node/text()
            case element(t:ref)
                return
                   string:ref($node)
            case element(t:date)
                return
               string:date($node)
           case element(t:origDate)
                return
              string:date($node)
            case element()
                return
                    string:tei2string($node/node())
            default
                return
                    $node
};

(:declare function string:date($date){

                        if(matches($date, '\d{4}')) then string($date) else
                        try {format-date(xs:date($date), '[Y0]-[M0]-[D0]')} catch * {($err:description)}
                        };:)

declare function string:additionstitles($nodes as node()*){
for $node in $nodes
    return
        typeswitch ($node)
            case element(t:term)
                return
                    <b>{$node/text()}</b>
                    case element(t:locus)
                return
                    string:locus($node)
            default
                return
                    $node
};

declare function string:Zotero($ZoteroUniqueBMtag as xs:string) {
    let $xml-url := concat('https://api.zotero.org/groups/358366/items?tag=', $ZoteroUniqueBMtag, '&amp;format=bib&amp;style=hiob-ludolf-centre-for-ethiopian-studies&amp;linkwrap=1')
   let $request := <http:request href="{xs:anyURI($xml-url)}" method="GET"/>
    let $data := http:send-request($request)[2]
    let $datawithlink := string:tei2string($data//div[@class eq  'csl-entry'])
    return
        $datawithlink
};
