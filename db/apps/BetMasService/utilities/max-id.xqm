xquery version "3.1";
declare namespace t = "http://www.tei-c.org/ns/1.0";
declare namespace xi = "http://www.w3.org/2001/XInclude";
declare namespace s = "http://www.w3.org/2005/xpath-functions";

let $context :=

(collection('/db/apps/expanded/works/new/')//t:TEI
)
let $ids := for $x in $context/@xml:id
return
analyze-string($x, '([A-Z]+)(\d+)(\w+)')
let $numericvalue := for $id in $ids//s:group[@nr = '2']
return
$id
let $maxid := max($numericvalue)
let $full := for $file in $context return if (contains($file/@xml:id, string($maxid))) then string($file/@xml:id) else ()

return
<p>{$maxid}, {$full}</p>