
xquery version "3.1" encoding "UTF-8";
(:~
 : switches
 : 
 : @author Pietro Liuzzo <pietro.liuzzo@uni-hamburg.de'>
 :)
module namespace switch = "https://www.betamasaheft.uni-hamburg.de/BetMas/switch";



(:~gets the collection name from one of the standard values of the attribute type in the TEI element :)
declare function switch:col($type){
    
    switch($type)
        case 'work' return 'works'
        case 'narr' return 'narratives'
        case 'pers' return 'persons'
        case 'place' return 'places'
        case 'ins' return 'institutions'
        case 'auth' return 'authority-files'
        default return 'manuscripts'
    
};

declare function switch:collection($type){
    
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