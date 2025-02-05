xquery version "3.1";
declare namespace t = "http://www.tei-c.org/ns/1.0";

let $col := '/db/apps/BetMasData/institutions/'

return
    <TEI
        xmlns="http://www.tei-c.org/ns/1.0">
        <teiHeader>
            <fileDesc>
                <titleStmt>
                    <title>List of institutions</title>
                </titleStmt>
                <publicationStmt>
                    <p/>
                </publicationStmt>
                <sourceDesc>
                    <p>Generated from data</p>
                </sourceDesc>
            </fileDesc>
        </teiHeader>
        <text>
            <body>
                <list>
                    {
                        for $book in (collection($col)//t:TEI)
                        let $id := string($book/@xml:id)
                        let $cae := substring($id, 4, 4)
                            order by $cae
                        return
                            
                            
                            
                            
                            <item
                                xml:id="{$id}">
                                {
                                    let $W := $book//t:place
                                    let $Maintitle := $W/t:placeName[@type eq 'main'][@corresp eq '#t1'][text()]
                                    let $amarictitle := $W/t:placeName[@corresp eq '#n1'][@xml:lang = 'am' or @xml:lang = 'ar']
                                    let $geztitle := $W/t:placeName[@corresp eq '#n1'][@xml:lang = 'gez']
                                    let $entitle := $W/t:placeName[@corresp eq '#n1'][@xml:lang = 'en']
                                    let $placename := $W/t:placeName[@xml:id eq 'n1'][text()]
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
                                                        if ($W/t:placeName[@xml:id])
                                                        then
                                                            let $tit := $W/t:placeName[@xml:id = 'n1']
                                                            return
                                                                normalize-space(string-join(($tit)))
                                                        else
                                                            normalize-space(string-join(($W/t:placeName[1])))
                                }
                            
                            </item>
                    
                    
                    
                    }</list>
            </body>
        </text>
    </TEI>