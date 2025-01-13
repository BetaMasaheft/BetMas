xquery version "3.1";
declare namespace t = "http://www.tei-c.org/ns/1.0";

let $col := '/db/apps/BetMasData/works/new'

return
    <list>
        {
            for $book in (collection($col)//t:TEI)
            let $id := concat('LIT', substring-before(substring-after(base-uri($book), 'LIT'), '.xml'))
            let $cae := substring($id, 4, 4)
                order by $cae
            return
                
                
                
                
                <item
                    corresp="{$id}">
                    {
                        let $W := $book//t:titleStmt
                        let $Maintitle := $W/t:title[@type eq 'main'][@corresp eq '#t1'][text()]
                        let $amarictitle := $W/t:title[@corresp eq '#t1'][@xml:lang = 'am' or @xml:lang = 'ar']
                        let $geztitle := $W/t:title[@corresp eq '#t1'][@xml:lang = 'gez']
                        let $entitle := $W/t:title[@corresp eq '#t1'][@xml:lang = 'en']
                        return
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
                    }
                
                </item>
        
        
        
        }</list>