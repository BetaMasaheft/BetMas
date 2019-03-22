xquery version "3.1" encoding "UTF-8";
(:~
 : switches 
 : @author Pietro Liuzzo
 :)
 
module namespace switch2 = "https://www.betamasaheft.uni-hamburg.de/BetMas/switch2";
import module namespace config = "https://www.betamasaheft.uni-hamburg.de/BetMas/config" at "xmldb:exist:///db/apps/BetMas/modules/config.xqm";

declare namespace test="http://exist-db.org/xquery/xqsuite";

(:~gets the collection name from one of the standard values of the attribute type in the TEI element :)
declare 
%test:arg("type", "work") %test:assertEquals("works")
    %test:arg("type", "corpus") %test:assertEquals("corpora")
function switch2:col($type){
    
    switch($type)
        case 'work' return 'works'
        case 'narr' return 'narratives'
        case 'pers' return 'persons'
        case 'place' return 'places'
        case 'ins' return 'institutions'
        case 'auth' return 'authority-files'
        case 'corpus' return 'corpora'
        default return 'manuscripts'
    
};


(:~gets the collection variable as string from one of the standard values of the attribute type in the TEI element :)
declare
%test:arg("type", "works") %test:assertEquals("$config:collection-rootW")
    %test:arg("type", "xxxx") %test:assertEquals("$config:collection-root")
    function switch2:collection($type){
    
    switch($type)
        case 'works' return '$config:collection-rootW'
        case 'narratives' return '$config:collection-rootN'
        case 'persons' return '$config:collection-rootPr'
        case 'places' return '$config:collection-rootPl'
        case 'institutions' return '$config:collection-rootIn'
        case 'authority-files' return '$config:collection-rootA'
        case 'manuscripts' return '$config:collection-rootMS'
        default return '$config:collection-root'
    
};

(:~gets the collection varibale from one of the standard values of the attribute type in the TEI element :)
declare function switch2:collectionVar($type){  
    switch($type)
        case 'works' return $config:collection-rootW
        case 'narratives' return $config:collection-rootN
        case 'persons' return $config:collection-rootPr
        case 'places' return $config:collection-rootPl
        case 'institutions' return $config:collection-rootIn
        case 'authority-files' return $config:collection-rootA
        case 'manuscripts' return $config:collection-rootMS
        default return $config:collection-root
};