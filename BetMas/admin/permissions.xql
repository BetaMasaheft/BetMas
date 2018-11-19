xquery version "3.1" encoding "UTF-8";
import module namespace config = "https://www.betamasaheft.uni-hamburg.de/BetMas/config" at "../modules/config.xqm";

import module namespace xdb = "http://exist-db.org/xquery/xmldb";
(:http://exist-db.org:8098/exist/apps/fundocs/view.html?uri=http://exist-db.org/xquery/securitymanager&location=java:org.exist.xquery.functions.securitymanager.SecurityManagerModule:)

let $login := xmldb:login('/db/', $config:ADMIN, $config:ppw)
 
let $assigntogroup := 
(
(:make all resources in betmas of cataloguers group:)
for $resource in collection('/db/apps/BetMas/') return (sm:chgrp(xs:anyURI(base-uri($resource)), 'Cataloguers'), sm:chmod(xs:anyURI(base-uri($resource)), 'rwxrwxr-x')),

(:reset the permission for the users to the user personal group:)
for $resource in xmldb:get-child-resources('/db/system/security/exist/accounts') 
return 
if($resource = 'admin') 
then() 
else (
sm:chgrp(xs:anyURI('/db/system/security/exist/accounts/' || $resource), substring-before($resource, '.xml')), 
sm:chmod(xs:anyURI('/db/system/security/exist/accounts/' || $resource), 'rwxrwx---')
)
)

(:set permissions on specific resources:)

(: NEW collections need write permissions for cataloguers:)
let $setNEWpermissions := (
let $i := xs:anyURI('/db/apps/BetMas/data/institutions/new') return (sm:chmod($i, 'rwxrwxr--'), sm:chgrp($i, 'Cataloguers')), 
let $i := xs:anyURI('/db/apps/BetMas/data/manuscripts/new') return (sm:chmod($i, 'rwxrwxr--'), sm:chgrp($i, 'Cataloguers')),
let $i := xs:anyURI('/db/apps/BetMas/data/works/new') return (sm:chmod($i, 'rwxrwxr--'), sm:chgrp($i, 'Cataloguers')),
let $i := xs:anyURI('/db/apps/BetMas/data/places/new') return (sm:chmod($i, 'rwxrwxr--'), sm:chgrp($i, 'Cataloguers')),
let $i := xs:anyURI('/db/apps/BetMas/data/persons/new') return (sm:chmod($i, 'rwxrwxr--'), sm:chgrp($i, 'Cataloguers')),
let $i := xs:anyURI('/db/apps/BetMas/data/authority-files/new') return (sm:chmod($i, 'rwxrwxr--'), sm:chgrp($i, 'Cataloguers')),
(:make the securitymanager functions and information editable by users:)
let $i := xs:anyURI('/db/system/security/exist/accounts') return ((sm:chmod($i, 'rwxrwx---')), sm:chgrp($i, 'Cataloguers'))

)

let $apiList := ('dts', 'rest', 'academics', 'annotations', 'apilists', 'apiText', 'apiTitles', 'apiSearch', 'attestations',
'chojnacki', 'clavis', 'collatex', 'enrichSdCtable', 'idlookup','nodesAndEdges', 'quotations', 'sharedKeywords',
'wordCount', 'roles','LitFlowRest')
(:rest API should be available to all:)
let $setAPIpermissions := (
for $module in $apiList let $mUri := concat('/db/apps/BetMas/modules/',$module,'.xql')
return sm:chmod(xs:anyURI($mUri), 'rwxrwxr-x'),
sm:chmod(xs:anyURI('/db/apps/BetMas/modules/switch.xqm'), 'rwxrwxr-x'),
sm:chmod(xs:anyURI('/db/apps/BetMas/modules/LitFlow.xqm'), 'rwxrwxr-x'),
sm:chmod(xs:anyURI('/db/apps/BetMas/auth/logout.xql'), 'rwxrwxr-x'),
sm:chmod(xs:anyURI('/db/apps/BetMas/auth/login.xql'), 'rwxrwxr-x')
)

(:git sync needs to be accessible to the webhook!:)
let $setGITpermissions := (
sm:chmod(xs:anyURI('/db/apps/BetMas/modules/gitsyncauth.xql'), 'rwxr-xr-x'),
sm:chmod(xs:anyURI('/db/apps/BetMas/modules/gitsyncinstitutions.xql'), 'rwxr-xr-x'),
sm:chmod(xs:anyURI('/db/apps/BetMas/modules/gitsyncmss.xql'), 'rwxr-xr-x'),
sm:chmod(xs:anyURI('/db/apps/BetMas/modules/gitsyncnarratives.xql'), 'rwxr-xr-x'),
sm:chmod(xs:anyURI('/db/apps/BetMas/modules/gitsyncpersons.xql'), 'rwxr-xr-x'),
sm:chmod(xs:anyURI('/db/apps/BetMas/modules/gitsyncplaces.xql'), 'rwxr-xr-x'),
sm:chmod(xs:anyURI('/db/apps/BetMas/modules/gitsyncworks.xql'), 'rwxr-xr-x'),
sm:chmod(xs:anyURI('/db/apps/BetMas/modules/gitsyncschema.xql'), 'rwxr-xr-x'),
sm:chmod(xs:anyURI('/db/apps/BetMas/modules/places.xql'), 'rwxr-xr-x')
)
(:controller must be executable also from guest:)
let $setControllerpermissions := sm:chmod(xs:anyURI('/db/apps/BetMas/controller.xql'), 'rwxr-xr-x')

 
(:view and other modules directly called must be closed to guest:)
let $setVIEWpermissions := (
sm:chmod(xs:anyURI('/db/apps/BetMas/modules/newEntry.xqm'), 'rwxr-x---'),
sm:chgrp(xs:anyURI('/db/apps/BetMas/modules/newEntry.xqm'), 'Cataloguers'),
sm:chmod(xs:anyURI('/db/apps/BetMas/modules/compare.xql'), 'rwxr-x---'),
sm:chgrp(xs:anyURI('/db/apps/BetMas/modules/compare.xql'), 'Cataloguers'),
sm:chmod(xs:anyURI('/db/apps/BetMas/modules/viewer.xql'), 'rwxr-x---'),
sm:chgrp(xs:anyURI('/db/apps/BetMas/modules/viewer.xql'), 'Cataloguers'),
sm:chmod(xs:anyURI('/db/apps/BetMas/modules/items.xql'), 'rwxr-x---'),
sm:chgrp(xs:anyURI('/db/apps/BetMas/modules/items.xql'), 'Cataloguers'),
sm:chmod(xs:anyURI('/db/apps/BetMas/modules/user.xql'), 'rwxr-x---'),
sm:chgrp(xs:anyURI('/db/apps/BetMas/modules/user.xql'), 'Cataloguers'),
sm:chmod(xs:anyURI('/db/apps/BetMas/modules/list.xql'), 'rwxr-x---'),
sm:chgrp(xs:anyURI('/db/apps/BetMas/modules/list.xql'), 'Cataloguers'),
sm:chmod(xs:anyURI('/db/apps/BetMas/modules/view.xql'), 'rwxr-x---'),
sm:chgrp(xs:anyURI('/db/apps/BetMas/modules/view.xql'), 'Cataloguers'),
sm:chmod(xs:anyURI('/db/apps/BetMas/modules/tei2fo.xql'), 'rwxr-x---'),
sm:chgrp(xs:anyURI('/db/apps/BetMas/modules/tei2fo.xql'), 'Cataloguers'),
sm:chmod(xs:anyURI('/db/apps/BetMas/modules/printSelected.xql'), 'rwxr-x---'),
sm:chgrp(xs:anyURI('/db/apps/BetMas/modules/printSelected.xql'), 'Cataloguers'),
sm:chmod(xs:anyURI('/db/apps/BetMas/modules/sparqlRest.xql'), 'rwxr-x---'),
sm:chgrp(xs:anyURI('/db/apps/BetMas/modules/sparqlRest.xql'), 'Cataloguers')
)

return
    
    <html>
        <head>
            <title>Admin</title>
        </head>
        <body>
            <h1>permissions</h1>
           
            <p>permissions updated
            </p>
        </body>
    </html>