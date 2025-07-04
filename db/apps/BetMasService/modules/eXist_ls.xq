xquery version "3.0";
import module namespace xmldb = "http://exist-db.org/xquery/xmldb";
import module namespace request = "http://exist-db.org/xquery/request";

declare namespace ls="ls";
declare function ls:ls($collection as xs:string) as element()* {
if (xmldb:collection-available($collection)) then
(         
for $child in xmldb:get-child-collections($collection)
let $path := concat($collection, '/', $child)
order by $child 
return
<collection name="{$child}" path="{$path}">
{
if (xmldb:collection-available($path)) then (  
attribute {'files'} {count(xmldb:get-child-resources($path))},
attribute {'cols'} {count(xmldb:get-child-collections($path))},
sm:get-permissions(xs:anyURI($path))/*/@*
)
else 'no permissions'
}
{ls:ls($path)}
</collection>,

for $child in xmldb:get-child-resources($collection)
let $path := concat($collection, '/', $child)
order by $child 
return
<resource name="{$child}" path="{$path}" mime="{xmldb:get-mime-type(xs:anyURI($path))}" size="{fn:ceiling(xmldb:size($collection, $child) div 1024)}">
{sm:get-permissions(xs:anyURI($path))/*/@*}
</resource>
)
else ()    
};

let $collection := request:get-parameter('/db/apps/EthioStudies/', '/db')
return
<ls path="{$collection}">{ls:ls($collection)}</ls> 