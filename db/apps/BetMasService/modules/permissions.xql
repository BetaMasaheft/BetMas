xquery version "3.1" encoding "UTF-8";

import module namespace xdb = "http://exist-db.org/xquery/xmldb";

(:declare variable $local:ADMIN := environment-variable('ExistAdmin');
declare variable $local:ppw := environment-variable('ExistAdminPw');

let $login := xmldb:login('/db/', $local:ADMIN, $local:ppw):)
let $start := '/db/apps/expanded'
return
(for $resource in xmldb:get-child-collections($start) 
let $b := xs:anyURI(concat($start,'/',$resource))
for $subfolder in xmldb:get-child-collections($b)
let $s := xs:anyURI(concat($b,'/',$subfolder))
let $group := sm:chgrp($s, 'Cataloguers') 
let $mod := sm:chmod($s, 'rwxrwxr-x')
return
    'updated group and mode for ' || $s
,
for $resource in (collection($start), collection('/db/apps/EthioStudies/'), collection('/db/apps/lists/') )
return try{(sm:chgrp(xs:anyURI(base-uri($resource)), 'Cataloguers'), sm:chmod(xs:anyURI(base-uri($resource)), 'rwxrwxr-x'), util:log('info',('updated ' || base-uri($resource))))} catch*{util:log('info', $err:description)}
)
