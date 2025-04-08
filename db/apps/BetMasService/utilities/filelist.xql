xquery version "3.1";

(: list files :)
declare namespace t="http://www.tei-c.org/ns/1.0";


let $input := collection("/db/apps/expanded/works/new") 
return
    <list>
        {
for $doc in collection("/db/apps/expanded/works/new") where contains(document-uri($doc), '.xml')
order by replace(fn:base-uri($doc),'^(.*/)(.*?\.\w+$)','$2')
return <item xml:id="{replace(fn:base-uri($doc),'^(.*/)(.*?\.\w+$)','$2')}"></item>
} </list>