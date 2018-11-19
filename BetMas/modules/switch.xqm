
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