xquery version "3.1" encoding "UTF-8";
(:~
 : switches 
 : @author Pietro Liuzzo
 :)
 
module namespace switch2 = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/switch2";
import module namespace config = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/config" at "xmldb:exist:///db/apps/BetMasWeb/modules/config.xqm";

declare namespace test="http://exist-db.org/xquery/xqsuite";

(:~gets the collection name from one of the standard values of the attribute type in the TEI element :)
declare 
%test:arg("type", "work") %test:assertEquals("works")
    %test:arg("type", "corpus") %test:assertEquals("corpora")
function switch2:col($type){
    
    switch($type)
        case 'work' return 'works'
        case 'nar' return 'narratives'
        case 'pers' return 'persons'
        case 'place' return 'places'
        case 'ins' return 'institutions'
        case 'auth' return 'authority-files'
        case 'mss' return 'manuscripts'
        default return 'corpus'
    
};


(:~gets the collection variable as string from one of the standard values of the attribute type in the TEI element :)
declare
%test:arg("type", "works") %test:assertEquals("'collection($config:data-rootW)")
    %test:arg("type", "xxxx") %test:assertEquals("'collection($config:data-root)")
    function switch2:collection($type){
    
    
    switch($type)
    
    case 'works' return 'collection($config:data-rootW)'
        case 'narratives' return 'collection($config:data-rootN)'
        case 'persons' return 'collection($config:data-rootPr)'
        case 'places' return 'collection($config:data-rootPl)'
        case 'institutions' return 'collection($config:data-rootIn)'
        case 'authority-files' return 'collection($config:data-rootA)'
        case 'manuscripts' return 'collection($config:data-rootMS)'
        default return 'collection($config:data-root)'
    
};

(:~gets the collection varibale from one of the standard values of the attribute type in the TEI element :)
declare function switch2:collectionVar($type){  
    switch($type)
        case 'works' return collection($config:data-rootW)
        case 'narratives' return collection($config:data-rootN)
        case 'persons' return collection($config:data-rootPr)
        case 'places' return collection($config:data-rootPl)
        case 'institutions' return collection($config:data-rootIn)
        case 'authority-files' return collection($config:data-rootA)
        case 'manuscripts' return collection($config:data-rootMS)
        default return collection($config:data-root)
};

(:~gets the collection varibale from one of the standard values of the attribute type in the TEI element :)
declare function switch2:collectionVarValTit($type){  
    switch($type)
     case'all' return '$exptit:col'
   case 'mss' return '$exptit:col//t:TEI[@type="mss"]'
   case 'work' return '$exptit:col//t:TEI[@type="work"]'
   case 'nar' return '$exptit:col//t:TEI[@type="nar"]'
   case 'auth' return '$exptit:col//t:TEI[@type="auth"]'
   case 'pers' return '$exptit:col//t:TEI[@type="pers"]'
   case 'place' return '$exptit:col//t:TEI[@type="place"]'
   case 'ins' return '$exptit:col//t:TEI[@type="ins"]'
   default return '$exptit:col'
       
};

(:~Given an id tries to decide which type it is:)
declare function switch2:switchPrefix( $id){
if(matches($id, '\d')) then

let $prefix := substring($id, 1,2)
return switch ($prefix)
                                                    case 'IN'
                                                        return
                                                            'ins'
                                                    case 'PR'
                                                        return
                                                            'pers'
                                                    case 'ET'
                                                        return
                                                            'pers'
                                                    case 'LO'
                                                        return
                                                            'place'
                                                    case 'LI'
                                                        return
                                                            'work'
                                                    case 'NA'
                                                        return
                                                            'nar'
                                                    case 'AT'
                                                        return
                                                            'auth'
                                                    default return
                                                        'mss'
else 'auth'
                                                        };