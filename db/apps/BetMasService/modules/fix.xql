xquery version "3.1";
declare namespace t = "http://www.tei-c.org/ns/1.0";
declare namespace b = "betmas.biblio";
let $bibl := doc('/db/apps/lists/bibliography.xml')

for $wrong in $bibl//b:citation[. = 'EMPTY! WRONG POINTER!']
let $id := string($wrong/parent::b:entry/@id)
let $tei := for $wrongpointer in collection('/db/apps/BetMasData/')//t:bibl/t:ptr[@target = $id] return string($wrongpointer/ancestor::t:TEI/@xml:id)
return
    replace($id, ',', ' ') || ", " || string-join(distinct-values($tei), ' ')