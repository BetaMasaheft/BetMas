let $app_url := fn:environment-variable('APP_URL')
let $loc_module :=
``[xquery version "3.1";

module namespace loc="https://www.betamasaheft.uni-hamburg.de/BetMasWeb/loc";

(:~
 : This variable is set with the app url, usually:
 :  * http://localhost:8080/exist/betmasweb for local development or
 :  * https://betamasaheft.eu for production
 :
 : It is automatically generated
 :)
declare variable $loc:appUrl := "`{$app_url}`";
]``

let $_ := util:log('info', 'Storing ' || $app_url || ' as the root of the application.	')

return xmldb:store('/db/apps/BetMasWeb/modules', 'loc.xqm', $loc_module)