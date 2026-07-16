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

(: Capture external-service endpoint overrides while running as DBA:
   fn:environment-variable is a DBA-only read in eXist, so request-time
   code cannot see these. config:service-url() in BetMasWeb reads the
   stored document instead and falls back to its default (the production
   wiring) when a variable was not set. This must run here (stage-2
   autodeploy, first container start) and not in BetMasWeb's own
   post-install, which runs during the image build where the runtime
   environment is not yet set. :)
let $services :=
    <services>{
        for $env in ('COLLATEX_URL', 'FUSEKI_URL')
        let $value := fn:environment-variable($env)
        where normalize-space($value) != ''
        return <service env="{$env}">{normalize-space($value)}</service>
    }</services>

let $_ := util:log('info', 'Storing ' || $app_url || ' as the root of the application.	')

return xmldb:store('/db/apps/BetMasWeb/modules', 'loc.xqm', $loc_module),

(: guest must be able to read but never write this document: it holds
   URLs the server itself will POST to :)
(xmldb:store('/db/apps/BetMasWeb', 'services.xml', $services),
 sm:chmod(xs:anyURI('/db/apps/BetMasWeb/services.xml'), 'rw-r--r--')),

(: Store tuttle configuration :)
xmldb:store('/db/apps/tuttle/data', 'tuttle.xml', doc('./tuttle.xml')),

util:eval(xs:anyURI('/db/apps/BetMasService/modules/registerRESTXQ.xql'))