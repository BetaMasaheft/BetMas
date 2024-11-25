xquery version "3.1";
declare namespace t = "http://www.tei-c.org/ns/1.0"; declare namespace xmldb="http://exist-db.org/xquery/xmldb";

declare variable $ThisFileContent:=
let $col := '/db/apps/BetMasData/works/1-1000'
let $col1 := '/db/apps/BetMasData/works/1001-2000'
let $col2 := '/db/apps/BetMasData/works/2001-3000'
let $col3 := '/db/apps/BetMasData/works/3001-4000'
let $col4 := '/db/apps/BetMasData/works/4001-5000'
let $col5 := '/db/apps/BetMasData/works/5001-6000'
let $col6 := '/db/apps/BetMasData/works/6001-7000'
let $col7 := '/db/apps/BetMasData/works/7001-8000'
let $colnew := '/db/apps/BetMasData/works/new'
return
<div xmlns="http://www.w3.org/1999/xhtml" xmlns:fn="http://www.w3.org/2005/xpath-functions" data-template="templates:surround" data-template-with="templates/newpage.html" data-template-at="content">
    <div class="w3-container w3-margin w3-padding-64">
        <h1> Clavis Aethiopica listing </h1>
        <h2>Visit the <a href="https://betamasaheft.eu/works/list">dynamic filtrable listing</a> for
            fuller results</h2>
        <h3>The list below was generated on {format-date(current-date(), "[Y0001]-[M01]-[D01]")}
</h3>
        <table class="w3-table w3-hoverable">
<tr><th width="100">CAe</th><th>Main title</th></tr>
{
for $book in (collection($col)//t:TEI, collection($col1)//t:TEI, collection($col2)//t:TEI, collection($col3)//t:TEI, collection($col4)//t:TEI, collection($col5)//t:TEI, collection($col6)//t:TEI, collection($colnew)//t:TEI)
let $id := concat('LIT', substring-before(substring-after(base-uri($book), 'LIT'), '.xml'))
let $cae := substring($id, 4, 4)
order by $cae
return


<tr>
<td>
{$cae}
</td>

<td><a href="https://www.betamasaheft.eu/{$id}">
{
let $W := $book//t:titleStmt
let $Maintitle := $W/t:title[@type eq  'main'][@corresp eq  '#t1'][text()]
let $amarictitle := $W/t:title[@corresp eq  '#t1'][@xml:lang = 'am' or @xml:lang = 'ar']
let $geztitle := $W/t:title[@corresp eq  '#t1'][@xml:lang = 'gez']
let $entitle := $W/t:title[@corresp eq  '#t1'][@xml:lang = 'en']
return
if ($Maintitle)
then
normalize-space(string-join(($Maintitle[1])))
else
if ($amarictitle)
then
normalize-space(string-join(($amarictitle[1])))
else
if ($geztitle)
then
normalize-space(string-join(($geztitle[1])))
else
if ($entitle)
then
normalize-space(string-join(($entitle[1])))
else
if ($W/t:title[@xml:id])
then
let $tit := $W/t:title[@xml:id = 't1']
return normalize-space(string-join(($tit)))
else
normalize-space(string-join(($W/t:title[1])))}
</a>
</td>
</tr>


} </table>
    </div>
</div>;
let $filename := "clavis-list.html"
let $doc-db-uri := xmldb:store("/db/apps/BetMasWeb", $filename, $ThisFileContent, "html")
return $doc-db-uri