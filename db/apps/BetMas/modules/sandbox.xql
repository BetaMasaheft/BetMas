xquery version "3.1";
declare namespace t = "http://www.tei-c.org/ns/1.0";
let $file := collection('/db/apps/expanded')/id('LIT2384Taamme')
return
distinct-values(($file//t:revisionDesc/t:change/@who| $file//t:editor/@key| $file//t:respStmt/@xml:id))