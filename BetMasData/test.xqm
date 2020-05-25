xquery version "3.1";

module namespace ti="https://www.betamasaheft.uni-hamburg.de/testfacetindex";
declare namespace t="http://www.tei-c.org/ns/1.0";

declare function ti:test($key){
    ($key || ' got to the function')
};
declare function ti:test($key, $type){
    switch($type)
    case 'auth' return doc('/db/apps/BetMas/lists/canonicaltaxonomy.xml')//t:category[@xml:id = $key]/t:catDesc/text()
    case 'tex' return doc('/db/apps/BetMas/lists/textpartstitles.xml')//t:item[@corresp = $key]/text()
    case 'pl' return doc('/db/apps/BetMas/lists/placeNamesLabels.xml')//t:item[@corresp = $key]/text()
    case 'ins' return doc('/db/apps/BetMas/lists/institutions.xml')//t:item[@xml:id = $key]/text()
        default return 
    doc('/db/apps/BetMas/lists/persNamesLabels.xml')//t:item[@corresp = $key]/text()
};