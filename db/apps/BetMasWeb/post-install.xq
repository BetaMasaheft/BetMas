xquery version "3.1";

declare namespace sm="http://exist-db.org/xquery/securitymanager";

declare variable $target external;

util:eval(xs:anyURI('/db/apps/BetMasService/modules/registerRESTXQ.xql')),

(: Create the groups needed in this app :)
for $group in ('Editors', 'Cataloguers')
	where not(sm:group-exists($group))
	return sm:create-group($group),

(: Create logging collection. TODO: remove the use of it :)
if (not(xmldb:collection-available('/db/apps/log')) then
	xmldb:create-collection('/db/apps', 'log')
else
	()

(: Create placeholders  :)
for $col in ('authority-files','manuscripts', 'institutions', 'narratives', 'persons', 'places', 'studies', 'works')
let $col := '/db/apps/expanded/' || $col
where not(xmldb:collection-available($col || '/new'))
return xmldb:create-collection($col, 'new')