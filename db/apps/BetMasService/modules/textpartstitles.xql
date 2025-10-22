xquery version "3.1";
declare namespace t = "http://www.tei-c.org/ns/1.0";
declare variable $ThisFileContent:=
let $col := '/db/apps/BetMasData/works/1-1000'
let $col1 := '/db/apps/BetMasData/works/1001-2000'
let $col2 := '/db/apps/BetMasData/works/2001-3000'
let $col3 := '/db/apps/BetMasData/works/3001-4000'
let $col4 := '/db/apps/BetMasData/works/4001-5000'
let $col5 := '/db/apps/BetMasData/works/5001-6000'
let $col6 := '/db/apps/BetMasData/works/6001-7000'
let $col7 := '/db/apps/BetMasData/works/7001-8000'
let $col8 := '/db/apps/BetMasData/works/new'


return
    <list>
        {
            for $book in  (collection($col)//t:TEI, collection($col1)//t:TEI, collection($col2)//t:TEI, collection($col3)//t:TEI, collection($col4)//t:TEI, collection($col5)//t:TEI, collection($col6)//t:TEI, collection($col7)//t:TEI, collection($col8)//t:TEI)
            let $mainID := $book/@xml:id
            let $id := concat('LIT', substring-before(substring-after(base-uri($book), 'LIT'), '.xml'))
            let $cae := substring($id, 4, 4)
            let $W := $book//t:titleStmt
            let $Maintitle := $W/t:title[@type eq 'main'][@corresp eq '#t1'][text()]
            let $amarictitle := $W/t:title[@corresp eq '#t1'][@xml:lang = 'am' or @xml:lang = 'ar']
            let $geztitle := $W/t:title[@corresp eq '#t1'][@xml:lang = 'gez']
            let $entitle := $W/t:title[@corresp eq '#t1'][@xml:lang = 'en']
            let $mainTitle :=
            if ($Maintitle)
            then
                normalize-space(string-join(($Maintitle[1])))
            else
                if ($amarictitle)
                then
                    normalize-space(string-join(($amarictitle[1])))
                else
                    if ($geztitle)
                    then
                        normalize-space(string-join(($geztitle[1])))
                    else
                        if ($entitle)
                        then
                            normalize-space(string-join(($entitle[1])))
                        else
                            if ($W/t:title[@xml:id])
                            then
                                let $tit := $W/t:title[@xml:id = 't1']
                                return
                                    normalize-space(string-join(($tit)))
                            else
                                normalize-space(string-join(($W/t:title[1])))
                order by $cae
            return
                (
                <item
                    corresp="{$id}">{string($mainTitle)}</item>,
                
                (
                for $div in $book//t:div[@type = 'edition']//t:div[@xml:id]
                let $subid := string($div/@xml:id)
                let $label := normalize-space(string-join($div/t:label/text()))
                let $subtitle := if ($label) then
                    $label
                else
                    $subid
                return
                    <item
                        corresp="{$id}#{$subid}">{string($mainTitle)}: {string($subtitle)}</item>
                )
                )
        }
    </list>;
let $filename := "textlist.xml"
let $doc-db-uri := xmldb:store("/db/apps/lists", $filename, $ThisFileContent, "xml")
return $doc-db-uri