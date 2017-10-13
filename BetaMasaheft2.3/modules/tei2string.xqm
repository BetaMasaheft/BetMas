xquery version "3.1" encoding "UTF-8";
(:~
 : module producing string from nodes with mixed content
 : @author Pietro Liuzzo <pietro.liuzzo@uni-hamburg.de'>
 :)

module namespace string = "https://www.betamasaheft.uni-hamburg.de/BetMas/string";
import module namespace titles = "https://www.betamasaheft.uni-hamburg.de/BetMas/titles" at "titles.xqm";
import module namespace console = "http://exist-db.org/xquery/console";
declare namespace t = "http://www.tei-c.org/ns/1.0";


(:takes a node as argument and loops through each element it contains. if it matches one of the definitions it does that, otherways checkes inside it. This actually reproduces the logic of the apply-templates function in  xslt:)
declare function string:tei2string($nodes as node()*) {
    
    for $node in $nodes
    return
        typeswitch ($node)
            case element(t:persName)
                return
                    titles:printTitleMainID($node/@ref)
            case element(t:placeName)
                return
                    
                    titles:printTitleMainID($node/@ref)
            case element(t:title)
                return
                    titles:printTitleMainID($node/@ref)
            case element(t:ref)
                return
                    if ($node/@corresp) then
                        titles:printTitleID($node/@corresp)
                    else
                        if ($node/@target) then
                            if (starts-with($node/@target, '#')) then
                            let $anchor := substring-after($node/@target, '#')
                            return
                                (root($node)//t:*[@xml:id = $anchor]/name(), $anchor) 
                            else
                                (string($node/@target))
                        else
                            string:tei2string($node/node())
            case element()
                return
                    string:tei2string($node/node())
            default
                return
                    $node
};
