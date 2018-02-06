xquery version "3.1" encoding "UTF-8";

declare namespace t="http://www.tei-c.org/ns/1.0";

import module namespace config = "https://www.betamasaheft.uni-hamburg.de/BetMas/config" at "config.xqm";
import module namespace all = "https://www.betamasaheft.uni-hamburg.de/BetMas/all" at "all.xqm";
import module namespace console = "http://exist-db.org/xquery/console";

let $c := collection($config:data-root)
let $dates := $c//t:date[not(parent::t:publicationStmt)]
let $origDate := $c//t:origDate
let $alldates := ($dates, $origDate)

let $rows :=    

for $d in $alldates
    return
        string(root($d)/t:TEI/@xml:id) || '&#9;' || $d/name() ||'&#9;'||normalize-space(string-join($d/text(), '')) || '&#9;' || string($d/@when) || '&#9;' || string($d/@notBefore) || '&#9;' || string($d/@notAfter)|| '&#9;' ||string( $d/@calendar)|| '&#9;' || string($d/@evidence)
        
let $content := 
    'resource ID&#9;element&#9;text&#9;when&#9;notbefore&#9;notafter&#9;calendar&#9;evidence
    ' ||
    string-join($rows, '
')
    
return
    xmldb:store('/db/apps/BetMas/ttl', 'dates.tsv', $content)