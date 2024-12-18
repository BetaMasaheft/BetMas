xquery version "3.1" encoding "UTF-8";

import module namespace config = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/config" at "modules/config.xqm";
import module namespace request = "http://exist-db.org/xquery/request";
import module namespace error = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/error" at "modules/error.xqm";
import module namespace console = "http://exist-db.org/xquery/console";
import module namespace login = "http://exist-db.org/xquery/login" at "resource:org/exist/xquery/modules/persistentlogin/login.xql";

import module namespace functx = "http://www.functx.com";

declare namespace t = "http://www.tei-c.org/ns/1.0";

declare variable $exist:path external;
declare variable $exist:resource external;
declare variable $exist:controller external;
declare variable $exist:prefix external;
declare variable $exist:root external;

declare variable $domain := "org.exist.login";
declare variable $taxonomy := doc('/db/apps/lists/canonicaltaxonomy.xml')//t:category/@xml:id;
(:  get what Nginx sends:)

declare function local:get-uri() {
    (request:get-header("nginx-request-uri"), request:get-uri())[1]
};

(:
declare variable $login :=
    let $tryImport :=
        try {
            util:import-module(xs:anyURI("http://exist-db.org/xquery/login"), 
            "login", xs:anyURI("resource:org/exist/xquery/modules/persistentlogin/login.xql")),
            true()
        } catch * {
            false()
        }
    return
        if ($tryImport) then
            function-lookup(xs:QName("login:set-user"), 3)
           
        else
            local:fallback-login#3
;:)



(:~
    Fallback login function used when the persistent login module is not available.
    Stores user/password in the HTTP session.
 :)
declare function local:fallback-login($domain as xs:string, $maxAge as xs:dayTimeDuration?, $asDba as xs:boolean) {
    let $user := request:get-parameter("user", ())
    let $password := request:get-parameter("password", ())
    let $logout := request:get-parameter("logout", ())
    return
        if ($logout) then
            session:invalidate()
        else
            if ($user) then
                let $isLoggedIn := xmldb:login("/db", $user, $password, true())
                return
                    (
                    session:set-attribute("BetMas.user", $user),
                    session:set-attribute("BetMas.password", $password),
                    request:set-attribute($domain || ".user", $user),
                    request:set-attribute("xquery.user", $user),
                    request:set-attribute("xquery.password", $password)
                    )
            else
                let $user := session:get-attribute("BetMas.user")
                let $password := session:get-attribute("BetMas.password")
                return
                    (
                    request:set-attribute($domain || ".user", $user),
                    request:set-attribute("xquery.user", $user),
                    request:set-attribute("xquery.password", $password))
};

declare function local:user-allowed() {
    (
    request:get-attribute("org.exist.login.user") and
    request:get-attribute("org.exist.login.user") != "guest"
    ) or config:get-configuration()/restrictions/@guest = "yes"
};

declare function local:switchCol($type) {
    
    switch ($type)
        case 'work'
            return
                'works'
        case 'narr'
            return
                'narratives'
        case 'pers'
            return
                'persons'
        case 'place'
            return
                'places'
        case 'ins'
            return
                'institutions'
        case 'studies'
            return
                'studies'
        case 'auth'
            return
                'authority-files'
        default return
            'manuscripts'

};

declare function local:switchPrefix($prefix) {
    switch ($prefix)
        case 'IN'
            return
                'institutions'
        case 'PR'
            return
                'persons'
        case 'ET'
            return
                'persons'
        case 'LO'
            return
                'places'
        case 'LI'
            return
                'works'
        case 'NA'
            return
                'narratives'
        case 'AT'
            return
                'authority-files'
        case 'ST'
            return
                'studies'
        default return
            'manuscripts'
};

(:let $test := console:log($exist:path) return:)
if ($exist:path eq '') then
    <dispatch
        xmlns="http://exist.sourceforge.net/NS/exist">
        <redirect
            url="{local:get-uri()}/"/>
    </dispatch>
    
    (:ALL REQUESTS CHECK THAT USER IS IN ADMIN GROUP:)
    
    (: Resource paths starting with $shared are loaded from the shared-resources app :)
else
    if (contains($exist:path, "/$shared/")) then
        <dispatch
            xmlns="http://exist.sourceforge.net/NS/exist">
            <forward
                url="{$config:appUrl}/shared-resources/{substring-after($exist:path, '/$shared/')}"/>
        </dispatch>
    
    else
        if (starts-with($exist:path, "/openapi/")) then
            <dispatch
                xmlns="http://exist.sourceforge.net/NS/exist">
                <forward
                    url="{$config:appUrl}/openapi/{$exist:path => substring-after("/openapi/") => replace("json", "xq")}"
                    method="get">
                    <add-parameter
                        name="target"
                        value="{substring-after($exist:root, "://") || $exist:controller}"/>
                    <add-parameter
                        name="register"
                        value="false"/>
                </forward>
            </dispatch>
            
            (: Requests for javascript libraries are resolved to the file system :)
        else
            if (contains($exist:path, "resources/") and not(contains($exist:path, "api/"))) then
                <dispatch
                    xmlns="http://exist.sourceforge.net/NS/exist">
                    <forward
                        url="{$exist:controller}/resources/{substring-after($exist:path, 'resources/')}"/>
                </dispatch>
                (: Requests for javascript libraries are resolved to the file system :)
            else
                if (contains($exist:path, "vocabularies/")) then
                    <dispatch
                        xmlns="http://exist.sourceforge.net/NS/exist">
                        <forward
                            url="{$exist:controller}/vocabularies/{substring-after($exist:path, 'vocabularies/')}"/>
                    </dispatch>
                    
                    (: Requests for javascript libraries are resolved to the file system :)
                else
                    if (contains($exist:path, "build/mirador")) then
                        <dispatch
                            xmlns="http://exist.sourceforge.net/NS/exist">
                            <forward
                                url="{$exist:controller}/resources/mirador/{substring-after($exist:path, 'mirador/')}"/>
                        </dispatch>
                        (:         the xql files                                                                           :)
                    else
                        if (ends-with($exist:resource, ".xql")) then
                            <dispatch
                                xmlns="http://exist.sourceforge.net/NS/exist">
                            
                            </dispatch>
                            
                            (:              special redirect for institutions to redirect to list and bypass standard main view:)
                        else
                            if (ends-with($exist:resource, ".pdf")) then
                                let $id := substring-before($exist:resource, '.pdf')
                                return
                                    <dispatch
                                        xmlns="http://exist.sourceforge.net/NS/exist">
                                        <forward
                                            url="{$exist:controller}/modules/tei2fo.xql">
                                            <set-header
                                                name="Cache-Control"
                                                value="no-cache"/>
                                            <add-parameter
                                                name="id"
                                                value="{$id}"/>
                                        </forward>
                                        <error-handler>
                                            <forward
                                                url="{$exist:controller}/error.html"
                                                method="get"/>
                                            <forward
                                                url="{$exist:controller}/modules/view.xql"/>
                                        </error-handler>
                                    </dispatch>
                            else
                                if ((::$exist:path = '/as.html' or ::)$exist:path = '/search.html' (::or $exist:path = '/facet.html'
                                or $exist:path = '/sparql.html' or $exist:path = '/xpath.html'::)) then
                                    <dispatch
                                        xmlns="http://exist.sourceforge.net/NS/exist">
                                        <redirect
                                            url="{$config:appUrl}/simpleSearch.html"
                                            absolute="yes"/>
                                    </dispatch>
                                    (:                                        another backward compatibility redirect:)
                                else
                                    if (matches($exist:path, '/manuscripts/INS\d+[\w_-]+/list'))
                                    then
                                        let $insid := replace($exist:path, '/manuscripts/', '') => replace('/list', '')
                                        return
                                            <dispatch
                                                xmlns="http://exist.sourceforge.net/NS/exist">
                                                <redirect
                                                    url="{$config:appUrl}/newSearch.html?searchType=text&amp;mode=any&amp;work-types=mss&amp;reporef={$insid}"
                                                    absolute="yes"/>
                                            </dispatch>
                                    
                                    else
                                        if ($exist:path = '/manuscripts/place/list') then
                                            <dispatch
                                                xmlns="http://exist.sourceforge.net/NS/exist">
                                                <redirect
                                                    url="{$config:appUrl}/newSearch.html?searchType=placeSearch&amp;mode=any&amp;query={request:get-parameter('place', ())}"
                                                    absolute="yes"/>
                                            </dispatch>
                                        else
                                            if ($exist:path = '/manuscripts/list') then
                                                <dispatch
                                                    xmlns="http://exist.sourceforge.net/NS/exist">
                                                    <redirect
                                                        url="{$config:appUrl}/newSearch.html?searchType=text&amp;mode=any&amp;work-types=mss"
                                                        absolute="yes"/>
                                                </dispatch>
                                            else
                                                if ($exist:path = '/persons/list') then
                                                    <dispatch
                                                        xmlns="http://exist.sourceforge.net/NS/exist">
                                                        <redirect
                                                            url="{$config:appUrl}/newSearch.html?searchType=text&amp;mode=any&amp;work-types=pers"
                                                            absolute="yes"/>
                                                    </dispatch>
                                                    else
                                                if ($exist:path = '/institutions/list') then
                                                    <dispatch
                                                        xmlns="http://exist.sourceforge.net/NS/exist">
                                                        <redirect
                                                            url="{$config:appUrl}/newSearch.html?searchType=text&amp;mode=any&amp;work-types=ins"
                                                            absolute="yes"/>
                                                    </dispatch>
                                                else
                                                    if ($exist:path = '/ethnic/list') then
                                                        <dispatch
                                                            xmlns="http://exist.sourceforge.net/NS/exist">
                                                            <redirect
                                                                url="{$config:appUrl}/newSearch.html?searchType=text&amp;mode=any&amp;work-types=eth"
                                                                absolute="yes"/>
                                                        </dispatch>
                                                    else
                                                        if ($exist:path = '/places/list') then
                                                            <dispatch
                                                                xmlns="http://exist.sourceforge.net/NS/exist">
                                                                <redirect
                                                                    url="{$config:appUrl}/newSearch.html?searchType=text&amp;mode=any&amp;work-types=place&amp;work-types=ins"
                                                                    absolute="yes"/>
                                                            </dispatch>
                                                        else
                                                            if ($exist:path = '/institutions/list') then
                                                                <dispatch
                                                                    xmlns="http://exist.sourceforge.net/NS/exist">
                                                                    <redirect
                                                                        url="{$config:appUrl}/newSearch.html?searchType=text&amp;mode=any&amp;work-types=ins"
                                                                        absolute="yes"/>
                                                                </dispatch>
                                                            else
                                                                if ($exist:path = '/narratives/list') then
                                                                    <dispatch
                                                                        xmlns="http://exist.sourceforge.net/NS/exist">
                                                                        <redirect
                                                                            url="{$config:appUrl}/newSearch.html?searchType=text&amp;mode=any&amp;work-types=nar"
                                                                            absolute="yes"/>
                                                                    </dispatch>
                                                                else
                                                                    if ($exist:path = '/works/list') then
                                                                        <dispatch
                                                                            xmlns="http://exist.sourceforge.net/NS/exist">
                                                                            <redirect
                                                                                url="{$config:appUrl}/newSearch.html?searchType=text&amp;mode=any&amp;work-types=work"
                                                                                absolute="yes"/>
                                                                        </dispatch>
                                                                    else
                                                                        if ($exist:path = '/studies/list') then
                                                                            <dispatch
                                                                                xmlns="http://exist.sourceforge.net/NS/exist">
                                                                                <redirect
                                                                                    url="{$config:appUrl}/newSearch.html?searchType=text&amp;mode=any&amp;work-types=studies"
                                                                                    absolute="yes"/>
                                                                            </dispatch>
                                                                            (:                            redirect /institutions/INSid/main to /newSearch?type=mss&amp;reporef=INSid ?? :)
                                                                            (:   else
                                if (contains($exist:path, 'institutions') and ends-with($exist:path, '/main')) then
                                    let $insid := substring-after(substring-before($exist:path, '/main'), '/institutions/')
                                    return
                                        <dispatch
                                            xmlns="http://exist.sourceforge.net/NS/exist">
                                            <redirect
                                                url="{$config:appUrl}/newSearch?type=mss&amp;reporef={$insid}"
                                                absolute="yes"/>
                                        </dispatch>:)
                                                                            
                                                                            (:            redirect to api all calls starting with /api/ ending with one of the specific rest modules:)
                                                                        else
                                                                            if (contains($exist:path, 'morpho')) then
                                                                                let $url := concat('/restxq', util:unescape-uri($exist:path, 'UTF-8'))
                                                                                return
                                                                                    <dispatch
                                                                                        xmlns="http://exist.sourceforge.net/NS/exist">
                                                                                        <forward
                                                                                            url="{$url}"
                                                                                            absolute="yes">
                                                                                            {login:set-user($domain, (), false())}
                                                                                            <set-header
                                                                                                name="Cache-Control"
                                                                                                value="no-cache"/>
                                                                                        </forward>
                                                                                    </dispatch>
                                                                            else
                                                                                if (contains($exist:path, '/permanent/')) then
                                                                                    
                                                                                    if (ends-with($exist:path, "/")) then
                                                                                        <dispatch
                                                                                            xmlns="http://exist.sourceforge.net/NS/exist">
                                                                                            <redirect
                                                                                                url="{$config:appUrl}/apidoc.html"/>
                                                                                        </dispatch>
                                                                                    else
                                                                                        <dispatch
                                                                                            xmlns="http://exist.sourceforge.net/NS/exist">
                                                                                            <forward
                                                                                                url="{concat('/restxq', $exist:path)}"
                                                                                                absolute="yes">
                                                                                                {login:set-user($domain, (), false())}
                                                                                                <set-header
                                                                                                    name="Cache-Control"
                                                                                                    value="no-cache"/>
                                                                                            </forward>
                                                                                        </dispatch>
                                                                                else
                                                                                    if (contains($exist:path, 'Dillmann') and not(contains($exist:path, 'PRS')))
                                                                                    then
                                                                                        <dispatch
                                                                                            xmlns="http://exist.sourceforge.net/NS/exist">
                                                                                            <forward
                                                                                                url="{concat('/restxq', $exist:path)}"
                                                                                                absolute="yes">
                                                                                                {login:set-user($domain, (), false())}
                                                                                                <set-header
                                                                                                    name="Cache-Control"
                                                                                                    value="no-cache"/>
                                                                                            </forward>
                                                                                        </dispatch>
                                                                                    else
                                                                                        if (
                                                                                        ends-with($exist:path, '/rdf') or
                                                                                        ends-with($exist:path, '/list') or
                                                                                        ends-with($exist:path, '/listChart') or
                                                                                        ends-with($exist:path, '/browse') or
                                                                                        ends-with($exist:path, '/analytic') or
                                                                                        ends-with($exist:path, '/main') or
                                                                                        ends-with($exist:path, '/compare') or
                                                                                        ends-with($exist:path, '/LitFlow') or
                                                                                        ends-with($exist:path, '/collate') or
                                                                                        ends-with($exist:path, '/compareSelected') or
                                                                                        ends-with($exist:path, '/text') or
                                                                                        ends-with($exist:path, '/geoBrowser') or
                                                                                        ends-with($exist:path, '/viewer') or
                                                                                        ends-with($exist:path, '/time') or
                                                                                        ends-with($exist:path, '/graph') or
                                                                                        starts-with($exist:path, '/user') or
                                                                                        starts-with($exist:path, '/corpus') or
                                                                                        starts-with($exist:path, '/listIds') or
                                                                                        starts-with($exist:path, '/workmap') or
                                                                                        starts-with($exist:path, '/litcomp') or
                                                                                        starts-with($exist:path, '/gender')) then
                                                                                            
                                                                                            if (ends-with($exist:path, "/")) then
                                                                                                <dispatch
                                                                                                    xmlns="http://exist.sourceforge.net/NS/exist">
                                                                                                    <redirect
                                                                                                        url="{$config:appUrl}/apidoc.html"/>
                                                                                                </dispatch>
                                                                                            else
                                                                                                <dispatch
                                                                                                    xmlns="http://exist.sourceforge.net/NS/exist">
                                                                                                    <forward
                                                                                                        url="{concat('/restxq/BetMasWeb/', $exist:path)}"
                                                                                                        absolute="yes">
                                                                                                        {login:set-user($domain, (), false())}
                                                                                                        <set-header
                                                                                                            name="Cache-Control"
                                                                                                            value="no-cache"/>
                                                                                                    </forward>
                                                                                                </dispatch>
                                                                                        else
                                                                                            if (contains($exist:path, '/api/')) then
                                                                                                
                                                                                                if (ends-with($exist:path, "/")) then
                                                                                                    <dispatch
                                                                                                        xmlns="http://exist.sourceforge.net/NS/exist">
                                                                                                        <redirect
                                                                                                            url="{$config:appUrl}/apidoc.html"/>
                                                                                                    </dispatch>
                                                                                                else
                                                                                                    <dispatch
                                                                                                        xmlns="http://exist.sourceforge.net/NS/exist">
                                                                                                        <forward
                                                                                                            url="{concat('/restxq', $exist:path)}"
                                                                                                            absolute="yes">
                                                                                                            {login:set-user($domain, (), false())}
                                                                                                            <set-header
                                                                                                                name="Cache-Control"
                                                                                                                value="no-cache"/>
                                                                                                        </forward>
                                                                                                    </dispatch>
                                                                                                    
                                                                                                    (:    redirects to api for geoJson:)
                                                                                            else
                                                                                                if (ends-with($exist:path, ".json")) then
                                                                                                    <dispatch
                                                                                                        xmlns="http://exist.sourceforge.net/NS/exist">
                                                                                                        <forward
                                                                                                            url="{$config:appUrl}/restxq/api/geoJson/places/{substring-before($exist:resource, '.json')}"
                                                                                                            absolute="yes"
                                                                                                        >
                                                                                                        
                                                                                                        </forward>
                                                                                                    
                                                                                                    </dispatch>
                                                                                                    
                                                                                                    (:        tei tranformed        :)
                                                                                                else
                                                                                                    if (starts-with($exist:path, '/tei/') and ends-with($exist:path, ".xml")) then
                                                                                                        
                                                                                                        let $id := substring-before($exist:resource, '.xml')
                                                                                                        let $item := collection($config:data-root)/id($id)[name() = 'TEI']
                                                                                                        let $collection := local:switchCol($item/@type)
                                                                                                        
                                                                                                        return
                                                                                                            if ($item) then
                                                                                                                <dispatch
                                                                                                                    xmlns="http://exist.sourceforge.net/NS/exist">
                                                                                                                    <forward
                                                                                                                        url="{$config:appUrl}/{$id}.xml"
                                                                                                                        absolute="yes"/>
                                                                                                                </dispatch>
                                                                                                            else
                                                                                                                
                                                                                                                let $Imap := map {
                                                                                                                    'type': 'xmlitem',
                                                                                                                    'name': $id,
                                                                                                                    'path': $collection
                                                                                                                }
                                                                                                                return
                                                                                                                    error:error($Imap)
                                                                                                                    
                                                                                                                    (:  the xml stored in the db   :)
                                                                                                    else
                                                                                                        if (ends-with($exist:path, ".xml")) then
                                                                                                            
                                                                                                            let $id := substring-before($exist:resource, '.xml')
                                                                                                            let $item := collection($config:data-root)/id($id)[name() = 'TEI']
                                                                                                            let $collection := local:switchCol($item/@type)
                                                                                                            let $uri := base-uri($item)
                                                                                                            return
                                                                                                                if ($item) then
                                                                                                                    <dispatch
                                                                                                                        xmlns="http://exist.sourceforge.net/NS/exist">
                                                                                                                        <forward
                                                                                                                            url="{$config:appUrl}/{substring-after($uri, 'db/apps/')}"/>
                                                                                                                        <error-handler>
                                                                                                                            <forward
                                                                                                                                url="{$exist:controller}/error/error-page.html"
                                                                                                                                method="get"/>
                                                                                                                            <forward
                                                                                                                                url="{$exist:controller}/modules/view.xql"/>
                                                                                                                        
                                                                                                                        </error-handler>
                                                                                                                    </dispatch>
                                                                                                                
                                                                                                                
                                                                                                                else
                                                                                                                    
                                                                                                                    let $Imap := map {
                                                                                                                        'type': 'xmlitem',
                                                                                                                        'name': $id,
                                                                                                                        'path': $collection
                                                                                                                    }
                                                                                                                    return
                                                                                                                        error:error($Imap)
                                                                                                                        
                                                                                                                        (:RDF data as transformed on upload:)
                                                                                                        else
                                                                                                            if (ends-with($exist:path, ".rdf")) then
                                                                                                                let $coll := '/db/rdf/'
                                                                                                                let $id := substring-before($exist:resource, '.xml')
                                                                                                                let $item := doc($coll || $exist:resource)
                                                                                                                let $uri := base-uri($item)
                                                                                                                return
                                                                                                                    if ($item) then
                                                                                                                        <dispatch
                                                                                                                            xmlns="http://exist.sourceforge.net/NS/exist">
                                                                                                                            <forward
                                                                                                                                url="{$config:appUrl}/rdf/{$exist:resource}"/>
                                                                                                                            <error-handler>
                                                                                                                                <forward
                                                                                                                                    url="{$exist:controller}/error/error-page.html"
                                                                                                                                    method="get"/>
                                                                                                                                <forward
                                                                                                                                    url="{$exist:controller}/modules/view.xql"/>
                                                                                                                            
                                                                                                                            </error-handler>
                                                                                                                        </dispatch>
                                                                                                                    
                                                                                                                    
                                                                                                                    else
                                                                                                                        
                                                                                                                        let $Imap := map {
                                                                                                                            'type': 'xmlitem',
                                                                                                                            'name': $id,
                                                                                                                            'path': $coll
                                                                                                                        }
                                                                                                                        return
                                                                                                                            error:error($Imap)
                                                                                                                            
                                                                                                                            
                                                                                                                            (:                    ALSO INTERNAL CALLS of XSLT ARE THUS PROCESSED!:)
                                                                                                            else
                                                                                                                if (starts-with($exist:path, "/")) then
                                                                                                                    
                                                                                                                    if ($exist:path eq "/") then
                                                                                                                        <dispatch
                                                                                                                            xmlns="http://exist.sourceforge.net/NS/exist">
                                                                                                                            <forward
                                                                                                                                url="{$exist:controller}/index.html">
                                                                                                                                {login:set-user($domain, (), false())}
                                                                                                                                <set-header
                                                                                                                                    name="Cache-Control"
                                                                                                                                    value="no-cache"/>
                                                                                                                            </forward>
                                                                                                                            <view>
                                                                                                                                <forward
                                                                                                                                    url="{$exist:controller}/modules/view.xql">
                                                                                                                                    <add-parameter
                                                                                                                                        name="uri"
                                                                                                                                        value="{('/db/apps/BetMasWeb/index.html')}"/>
                                                                                                                                </forward>
                                                                                                                            </view>
                                                                                                                            <error-handler>
                                                                                                                                <forward
                                                                                                                                    url="{$exist:controller}/error/error-page.html"
                                                                                                                                    method="get"/>
                                                                                                                                <forward
                                                                                                                                    url="{$exist:controller}/modules/view.xql"/>
                                                                                                                            
                                                                                                                            </error-handler>
                                                                                                                        </dispatch>
                                                                                                                        
                                                                                                                        (:                                        redirects uris of subpart URI like
https://betamasaheft.eu/BDLaethe8/addition/a1
to the actual homepage with a # to their id
https://betamasaheft.eu/manuscripts/BDLaethe8/main#a1
if application/rdf+xml is asked then the request is forwarded to the sparqlRest.xql module where
function apisparql:constructURIsubid() is called to construct a graph of that resource.
:)
                                                                                                                    else
                                                                                                                        if (matches($exist:path, "\w+\d+(\w+)?") and (
                                                                                                                        contains($exist:path, '/layout/') or
                                                                                                                        contains($exist:path, '/quire/') or
                                                                                                                        contains($exist:path, '/addition/') or
                                                                                                                        contains($exist:path, '/decoration/') or
                                                                                                                        contains($exist:path, '/binding/') or
                                                                                                                        contains($exist:path, '/msItem/') or
                                                                                                                        contains($exist:path, '/msitem/') or
                                                                                                                        contains($exist:path, '/mspart/') or
                                                                                                                        contains($exist:path, '/msPart/') or
                                                                                                                        contains($exist:path, '/title/') or
                                                                                                                        contains($exist:path, '/hand/') or
                                                                                                                        contains($exist:path, '/transformation/') or
                                                                                                                        contains($exist:path, '/UniProd/') or
                                                                                                                        contains($exist:path, '/UniCirc/') or
                                                                                                                        contains($exist:path, '/UniMain/') or
                                                                                                                        contains($exist:path, '/UniMat/') or
                                                                                                                        contains($exist:path, '/UniCah/')
                                                                                                                        )) then
                                                                                                                            let $prefix := substring($exist:path, 2, 2)
                                                                                                                            let $switchCollection := local:switchPrefix($prefix)
                                                                                                                            let $tokenizePath := tokenize($exist:path, '/')
                                                                                                                            (:let $test := console:log(request:get-header('Accept')):)
                                                                                                                            return
                                                                                                                                if (contains(request:get-header('Accept'), 'rdf'))
                                                                                                                                then
                                                                                                                                    <dispatch
                                                                                                                                        xmlns="http://exist.sourceforge.net/NS/exist">
                                                                                                                                        <forward
                                                                                                                                            url="{concat('/restxq/BetMasWeb', $exist:path, '/rdf')}"
                                                                                                                                            absolute="yes">
                                                                                                                                            {login:set-user($domain, (), false())}
                                                                                                                                            <set-header
                                                                                                                                                name="Cache-Control"
                                                                                                                                                value="no-cache"/>
                                                                                                                                        </forward>
                                                                                                                                    
                                                                                                                                    
                                                                                                                                    </dispatch>
                                                                                                                                else
                                                                                                                                    <dispatch
                                                                                                                                        xmlns="http://exist.sourceforge.net/NS/exist">
                                                                                                                                        
                                                                                                                                        <redirect
                                                                                                                                            url="{$config:appUrl}/{$switchCollection}/{$tokenizePath[2]}/main#{$tokenizePath[last()]}"/>
                                                                                                                                    
                                                                                                                                    </dispatch>
                                                                                                                                    
                                                                                                                                    (:                  annotations                                  :)
                                                                                                                                    (:https://betamasaheft.eu/BNFet32/person/annotation/95
https://betamasaheft.eu/BNFet32/place/annotation/1
points to main item HTML as a page
construct the annotation graph if application/rdf+xml is specified
:)
                                                                                                                        else
                                                                                                                            if (matches($exist:path, "/annotation/")) then
                                                                                                                                let $prefix := substring($exist:resource, 1, 2)
                                                                                                                                let $switchCollection := local:switchPrefix($prefix)
                                                                                                                                let $tokenizePath := tokenize($exist:path, '/')
                                                                                                                                return
                                                                                                                                    if (contains(request:get-header('Accept'), 'rdf'))
                                                                                                                                    then
                                                                                                                                        <dispatch
                                                                                                                                            xmlns="http://exist.sourceforge.net/NS/exist">
                                                                                                                                            <forward
                                                                                                                                                url="{concat('/restxq/BetMasWeb', $exist:path, '/rdf')}"
                                                                                                                                                absolute="yes">
                                                                                                                                                {login:set-user($domain, (), false())}
                                                                                                                                                <set-header
                                                                                                                                                    name="Cache-Control"
                                                                                                                                                    value="no-cache"/>
                                                                                                                                            </forward>
                                                                                                                                        
                                                                                                                                        
                                                                                                                                        </dispatch>
                                                                                                                                    else
                                                                                                                                        <dispatch
                                                                                                                                            xmlns="http://exist.sourceforge.net/NS/exist">
                                                                                                                                            
                                                                                                                                            <redirect
                                                                                                                                                url="{$config:appUrl}/{$tokenizePath[2]}"/>
                                                                                                                                        
                                                                                                                                        </dispatch>
                                                                                                                                        
                                                                                                                                        
                                                                                                                                        
                                                                                                                                        (:https://betamasaheft.eu/bond/snap:GrandfatherOf-PRS1854Amdase:)
                                                                                                                            
                                                                                                                            else
                                                                                                                                if (starts-with($exist:path, "/bond/")) then
                                                                                                                                    let $tokenizePath := tokenize($exist:path, '/')
                                                                                                                                    let $tokenizeBond := tokenize($tokenizePath[3], '-')
                                                                                                                                    return
                                                                                                                                        if (contains(request:get-header('Accept'), 'rdf'))
                                                                                                                                        then
                                                                                                                                            <dispatch
                                                                                                                                                xmlns="http://exist.sourceforge.net/NS/exist">
                                                                                                                                                <forward
                                                                                                                                                    url="{concat('/restxq/BetMasWeb/bond/', encode-for-uri($tokenizePath[3]), '/rdf')}"
                                                                                                                                                    absolute="yes">
                                                                                                                                                    {login:set-user($domain, (), false())}
                                                                                                                                                    <set-header
                                                                                                                                                        name="Cache-Control"
                                                                                                                                                        value="no-cache"/>
                                                                                                                                                </forward>
                                                                                                                                            
                                                                                                                                            
                                                                                                                                            </dispatch>
                                                                                                                                        else
                                                                                                                                            <dispatch
                                                                                                                                                xmlns="http://exist.sourceforge.net/NS/exist">
                                                                                                                                                
                                                                                                                                                <redirect
                                                                                                                                                    url="{$config:appUrl}/{$tokenizeBond[2]}"/>
                                                                                                                                            
                                                                                                                                            </dispatch>
                                                                                                                                            
                                                                                                                                            (: 
allow understandable simple syntax for resolving
LIT1234name#anchor => LIT1234name&ref=anchor
LIT1234name.n1.n2.n3 => LIT1234name&ref=n1.n2.n3
LIT1234name.n1-n4 =>LIT1234name&start=n1&end=n4

if the resource match an id of a work or a 
manuscript followed by a passage reference, then go to the text view of that
 : http://betamasaheft.eu/LIT1340EnochE.1.3
 : LIT1340EnochE.1.3-2.5
 : BAVet1.1ra-4vb
 : should redirect to
 : http://betamasaheft.eu/works/LIT1340EnochE/text?ref=1.3
 : http://betamasaheft.eu/manuscripts/BAVet1/text?start=1ra&amp;end=4vb
 : these will actually go to the api
  :)
                                                                                                                                else
                                                                                                                                    if (matches($exist:resource, "^(\w+\d+(\w+)?(((_(ED|TR)_([a-zA-Z0-9]+)?)(\.)?)|\.))((NAR[0-9A-Za-z]+|(\d+(r|v)?([a-z])?(\d+)?)|([A-Za-z]+)?([0-9]+))(\.)?)?(\-)?(((NAR[0-9A-Za-z]+|(\d+(r|v)[a-z])|([A-Za-z]+)?([0-9]+))(\.)?)+)?")) then
                                                                                                                                        let $prefix := substring($exist:resource, 1, 2)
                                                                                                                                        let $switchCollection := local:switchPrefix($prefix)
                                                                                                                                        (:                                                looks for the FIRST dot, which separates ref and identifier:)
                                                                                                                                        let $passage := if (contains($exist:resource, '.')) then
                                                                                                                                            substring-after($exist:resource, '.')
                                                                                                                                        else
                                                                                                                                            ()
                                                                                                                                        let $idarea := if (contains($exist:resource, '.')) then
                                                                                                                                            substring-before($exist:resource, '.')
                                                                                                                                        else
                                                                                                                                            $exist:resource
                                                                                                                                            (:                                                looks for the first underscore, which separates the main identifier from the edition/translation:)
                                                                                                                                        let $id := if (contains($idarea, '_ED_') or contains($idarea, '_TR_')) then
                                                                                                                                            substring-before($idarea, '_')
                                                                                                                                        else
                                                                                                                                            $idarea
                                                                                                                                        let $ed := if (contains($idarea, '_ED_') or contains($idarea, '_TR_')) then
                                                                                                                                            substring-after($idarea, substring-before($idarea, '_'))
                                                                                                                                        else
                                                                                                                                            ()
                                                                                                                                        let $reforrange := if (contains($passage, '-')) then
                                                                                                                                            '?start=' || substring-before($passage, '-') || '&amp;end=' || substring-after($passage, '-')
                                                                                                                                        else
                                                                                                                                            '?ref=' || $passage
                                                                                                                                        let $edition := '&amp;edition=' || $ed
                                                                                                                                        let $parms := ($reforrange || $edition)
                                                                                                                                        
                                                                                                                                        return
                                                                                                                                            <dispatch
                                                                                                                                                xmlns="http://exist.sourceforge.net/NS/exist">
                                                                                                                                                <redirect
                                                                                                                                                    url="{$config:appUrl}/{$switchCollection}/{$id}/text{$parms}"/>
                                                                                                                                            </dispatch>
                                                                                                                                            
                                                                                                                                            
                                                                                                                                            (: if the resource does match the id, then redirect to main view of that item:)
                                                                                                                                    
                                                                                                                                    else
                                                                                                                                        if (matches($exist:resource, "^\w+\d+(\w+)?$")) then
                                                                                                                                            let $prefix := substring($exist:resource, 1, 2)
                                                                                                                                            let $switchCollection := local:switchPrefix($prefix)
                                                                                                                                            return
                                                                                                                                                (:                                            content negotiation,
requiring the ID
https://betamasaheft.eu/BNFet32
if the client explicitly requests application/xml+rdf then the RDF is returned from
the sparqlRest.xql module where
function apisparql:constructURIid() is called to construct a graph of that resource.
otherwise the html page is returned
https://betamasaheft.eu/manuscript/BNFet32/main
:)
                                                                                                                                                if (contains(request:get-header('Accept'), 'rdf'))
                                                                                                                                                then
                                                                                                                                                    <dispatch
                                                                                                                                                        xmlns="http://exist.sourceforge.net/NS/exist">
                                                                                                                                                        <forward
                                                                                                                                                            url="{concat('/restxq/BetMasWeb/', $exist:resource, '/rdf')}"
                                                                                                                                                            absolute="yes">
                                                                                                                                                            {login:set-user($domain, (), false())}
                                                                                                                                                            <set-header
                                                                                                                                                                name="Cache-Control"
                                                                                                                                                                value="no-cache"/>
                                                                                                                                                        </forward>
                                                                                                                                                    </dispatch>
                                                                                                                                                else
                                                                                                                                                    if (contains(request:get-header('Accept'), 'tei+xml'))
                                                                                                                                                    then
                                                                                                                                                        <dispatch
                                                                                                                                                            xmlns="http://exist.sourceforge.net/NS/exist">
                                                                                                                                                            <redirect
                                                                                                                                                                url="{concat('/tei/', $exist:resource, '.xml')}"/>
                                                                                                                                                        </dispatch>
                                                                                                                                                    else
                                                                                                                                                        <dispatch
                                                                                                                                                            xmlns="http://exist.sourceforge.net/NS/exist">
                                                                                                                                                            <redirect
                                                                                                                                                                url="{$config:appUrl}/{$switchCollection}/{$exist:resource}/main"/>
                                                                                                                                                        </dispatch>
                                                                                                                                        
                                                                                                                                        else
                                                                                                                                            if (ends-with($exist:resource, ".html")) then
                                                                                                                                                
                                                                                                                                                <dispatch
                                                                                                                                                    xmlns="http://exist.sourceforge.net/NS/exist">
                                                                                                                                                    <forward
                                                                                                                                                        url="{$exist:controller}/{$exist:path}"/>
                                                                                                                                                    <view>
                                                                                                                                                        <forward
                                                                                                                                                            url="{$exist:controller}/modules/view.xql"/>
                                                                                                                                                        {login:set-user($domain, (), false())}
                                                                                                                                                        <set-header
                                                                                                                                                            name="Cache-Control"
                                                                                                                                                            value="no-cache"/>
                                                                                                                                                    
                                                                                                                                                    </view>
                                                                                                                                                    <error-handler>
                                                                                                                                                        <forward
                                                                                                                                                            url="{$exist:controller}/error/error-page.html"
                                                                                                                                                            method="get"/>
                                                                                                                                                        <forward
                                                                                                                                                            url="{$exist:controller}/modules/view.xql"/>
                                                                                                                                                    </error-handler>
                                                                                                                                                </dispatch>
                                                                                                                                                
                                                                                                                                                
                                                                                                                                                (:                             if the url resource does not contain numbers, and thus is not the id of any resource, beside authority files:)
                                                                                                                                                (:                                            content negotiation,
requiring the ID
https://betamasaheft.eu/angel
if the client explicitly requests application/xml+rdf then the RDF is returned from
the sparqlRest.xql module where
function apisparql:constructURIid() is called to construct a graph of that resource.
otherwise the html page is returned
https://betamasaheft.eu/authority-files/angel/main
:)
                                                                                                                                            else
                                                                                                                                                if (matches($exist:resource, "^[^.\d]+$")) then
                                                                                                                                                 (:   let $t := console:log($exist:resource)
                                                                                                                                                    return:)
                                                                                                                                                    (:                                            if it actually points to authority files, go there:)
                                                                                                                                                    if (contains($exist:path, "/authority-files/")) then
                                                                                                                                                        if (contains(request:get-header('Accept'), 'rdf'))
                                                                                                                                                        then
                                                                                                                                                            <dispatch
                                                                                                                                                                xmlns="http://exist.sourceforge.net/NS/exist">
                                                                                                                                                                
                                                                                                                                                                <forward
                                                                                                                                                                    url="{concat('/restxq/BetMasWeb/', $exist:resource, '/rdf')}"
                                                                                                                                                                    absolute="yes">
                                                                                                                                                                    {login:set-user($domain, (), false())}
                                                                                                                                                                    <set-header
                                                                                                                                                                        name="Cache-Control"
                                                                                                                                                                        value="no-cache"/>
                                                                                                                                                                </forward>
                                                                                                                                                            
                                                                                                                                                            
                                                                                                                                                            </dispatch>
                                                                                                                                                        else
                                                                                                                                                            <dispatch
                                                                                                                                                                xmlns="http://exist.sourceforge.net/NS/exist">
                                                                                                                                                                <redirect
                                                                                                                                                                    url="{$config:appUrl}/authority-files/{$exist:resource}/main"/>
                                                                                                                                                            </dispatch>
                                                                                                                                                    
                                                                                                                                                    else
                                                                                                                                                        
                                                                                                                                                        (:                                            if it is a special page then go there :)
                                                                                                                                                        
                                                                                                                                                        if (starts-with($exist:path, "/decorations")) then
                                                                                                                                                            <dispatch
                                                                                                                                                                xmlns="http://exist.sourceforge.net/NS/exist">
                                                                                                                                                                <forward
                                                                                                                                                                    url="{$exist:controller}/decorations.html"
                                                                                                                                                                    method="get">
                                                                                                                                                                    <add-parameter
                                                                                                                                                                        name="uri"
                                                                                                                                                                        value="{('/db/apps/BetMasWeb/decorations.html')}"/>
                                                                                                                                                                </forward>
                                                                                                                                                                <view>
                                                                                                                                                                    <forward
                                                                                                                                                                        url="{$exist:controller}/modules/view.xql">
                                                                                                                                                                    </forward>
                                                                                                                                                                
                                                                                                                                                                </view>
                                                                                                                                                                
                                                                                                                                                                <error-handler>
                                                                                                                                                                    <forward
                                                                                                                                                                        url="{$exist:controller}/error/error-page.html"
                                                                                                                                                                        method="get"/>
                                                                                                                                                                    <forward
                                                                                                                                                                        url="{$exist:controller}/modules/view.xql"/>
                                                                                                                                                                </error-handler>
                                                                                                                                                            </dispatch>
                                                                                                                                                        else
                                                                                                                                                            if (starts-with($exist:path, "/titles")) then
                                                                                                                                                                <dispatch
                                                                                                                                                                    xmlns="http://exist.sourceforge.net/NS/exist">
                                                                                                                                                                    <forward
                                                                                                                                                                        url="{$exist:controller}/titles.html"
                                                                                                                                                                        method="get">
                                                                                                                                                                        <add-parameter
                                                                                                                                                                            name="uri"
                                                                                                                                                                            value="{('/db/apps/BetMasWeb/titles.html')}"/>
                                                                                                                                                                    </forward>
                                                                                                                                                                    <view>
                                                                                                                                                                        <forward
                                                                                                                                                                            url="{$exist:controller}/modules/view.xql">
                                                                                                                                                                        </forward>
                                                                                                                                                                    
                                                                                                                                                                    </view>
                                                                                                                                                                    
                                                                                                                                                                    <error-handler>
                                                                                                                                                                        <forward
                                                                                                                                                                            url="{$exist:controller}/error/error-page.html"
                                                                                                                                                                            method="get"/>
                                                                                                                                                                        <forward
                                                                                                                                                                            url="{$exist:controller}/modules/view.xql"/>
                                                                                                                                                                    </error-handler>
                                                                                                                                                                </dispatch>
                                                                                                                                                                                                                                                                                                                    else
                                                                                                                                                            if (starts-with($exist:path, "/paratexts")) then
                                                                                                                                                                <dispatch
                                                                                                                                                                    xmlns="http://exist.sourceforge.net/NS/exist">
                                                                                                                                                                    <forward
                                                                                                                                                                        url="{$exist:controller}/paratexts.html"
                                                                                                                                                                        method="get">
                                                                                                                                                                        <add-parameter
                                                                                                                                                                            name="uri"
                                                                                                                                                                            value="{('/db/apps/BetMasWeb/paratexts.html')}"/>
                                                                                                                                                                    </forward>
                                                                                                                                                                    <view>
                                                                                                                                                                        <forward
                                                                                                                                                                            url="{$exist:controller}/modules/view.xql">
                                                                                                                                                                        </forward>
                                                                                                                                                                    
                                                                                                                                                                    </view>
                                                                                                                                                                    
                                                                                                                                                                    <error-handler>
                                                                                                                                                                        <forward
                                                                                                                                                                            url="{$exist:controller}/error/error-page.html"
                                                                                                                                                                            method="get"/>
                                                                                                                                                                        <forward
                                                                                                                                                                            url="{$exist:controller}/modules/view.xql"/>
                                                                                                                                                                    </error-handler>
                                                                                                                                                                </dispatch>
                                                                                                                                                            else
                                                                                                                                                                if (starts-with($exist:path, "/calendar")) then
                                                                                                                                                                    <dispatch
                                                                                                                                                                        xmlns="http://exist.sourceforge.net/NS/exist">
                                                                                                                                                                        <forward
                                                                                                                                                                            url="{$exist:controller}/calendar.html"
                                                                                                                                                                            method="get">
                                                                                                                                                                            <add-parameter
                                                                                                                                                                                name="uri"
                                                                                                                                                                                value="{('/db/apps/BetMasWeb/calendar.html')}"/>
                                                                                                                                                                        </forward>
                                                                                                                                                                        <view>
                                                                                                                                                                            <forward
                                                                                                                                                                                url="{$exist:controller}/modules/view.xql">
                                                                                                                                                                            </forward>
                                                                                                                                                                        
                                                                                                                                                                        </view>
                                                                                                                                                                        
                                                                                                                                                                        <error-handler>
                                                                                                                                                                            <forward
                                                                                                                                                                                url="{$exist:controller}/error/error-page.html"
                                                                                                                                                                                method="get"/>
                                                                                                                                                                            <forward
                                                                                                                                                                                url="{$exist:controller}/modules/view.xql"/>
                                                                                                                                                                        </error-handler>
                                                                                                                                                                    </dispatch>
                                                                                                                                                                
                                                                                                                                                                
                                                                                                                                                                else
                                                                                                                                                                    if (starts-with($exist:path, "/bindings")) then
                                                                                                                                                                        <dispatch
                                                                                                                                                                            xmlns="http://exist.sourceforge.net/NS/exist">
                                                                                                                                                                            <forward
                                                                                                                                                                                url="{$exist:controller}/bindings.html"
                                                                                                                                                                                method="get">
                                                                                                                                                                                <add-parameter
                                                                                                                                                                                    name="uri"
                                                                                                                                                                                    value="{('/db/apps/BetMasWeb/bindings.html')}"/>
                                                                                                                                                                            </forward>
                                                                                                                                                                            <view>
                                                                                                                                                                                <forward
                                                                                                                                                                                    url="{$exist:controller}/modules/view.xql">
                                                                                                                                                                                </forward>
                                                                                                                                                                            
                                                                                                                                                                            </view>
                                                                                                                                                                            
                                                                                                                                                                            <error-handler>
                                                                                                                                                                                <forward
                                                                                                                                                                                    url="{$exist:controller}/error/error-page.html"
                                                                                                                                                                                    method="get"/>
                                                                                                                                                                                <forward
                                                                                                                                                                                    url="{$exist:controller}/modules/view.xql"/>
                                                                                                                                                                            </error-handler>
                                                                                                                                                                        </dispatch>
                                                                                                                                                                    
                                                                                                                                                                    else
                                                                                                                                                                        if (starts-with($exist:path, "/xpath")) then
                                                                                                                                                                            <dispatch
                                                                                                                                                                                xmlns="http://exist.sourceforge.net/NS/exist">
                                                                                                                                                                                <forward
                                                                                                                                                                                    url="{$exist:controller}/xpath.html"
                                                                                                                                                                                    method="get">
                                                                                                                                                                                    <add-parameter
                                                                                                                                                                                        name="uri"
                                                                                                                                                                                        value="{('/db/apps/BetMasWeb/xpath.html')}"/>
                                                                                                                                                                                </forward>
                                                                                                                                                                                <view>
                                                                                                                                                                                    <forward
                                                                                                                                                                                        url="{$exist:controller}/modules/view.xql">
                                                                                                                                                                                    </forward>
                                                                                                                                                                                
                                                                                                                                                                                </view>
                                                                                                                                                                                
                                                                                                                                                                                <error-handler>
                                                                                                                                                                                    <forward
                                                                                                                                                                                        url="{$exist:controller}/error/error-page.html"
                                                                                                                                                                                        method="get"/>
                                                                                                                                                                                    <forward
                                                                                                                                                                                        url="{$exist:controller}/modules/view.xql"/>
                                                                                                                                                                                </error-handler>
                                                                                                                                                                            </dispatch>
                                                                                                                                                                        
                                                                                                                                                                        else
                                                                                                                                                                            if (starts-with($exist:path, "/sparql")) then
                                                                                                                                                                                <dispatch
                                                                                                                                                                                    xmlns="http://exist.sourceforge.net/NS/exist">
                                                                                                                                                                                    <forward
                                                                                                                                                                                        url="{$exist:controller}/sparql.html"
                                                                                                                                                                                        method="get">
                                                                                                                                                                                        <add-parameter
                                                                                                                                                                                            name="uri"
                                                                                                                                                                                            value="{('/db/apps/BetMasWeb/sparql.html')}"/>
                                                                                                                                                                                    </forward>
                                                                                                                                                                                    <view>
                                                                                                                                                                                        <forward
                                                                                                                                                                                            url="{$exist:controller}/modules/view.xql">
                                                                                                                                                                                        </forward>
                                                                                                                                                                                    
                                                                                                                                                                                    </view>
                                                                                                                                                                                    
                                                                                                                                                                                    <error-handler>
                                                                                                                                                                                        <forward
                                                                                                                                                                                            url="{$exist:controller}/error/error-page.html"
                                                                                                                                                                                            method="get"/>
                                                                                                                                                                                        <forward
                                                                                                                                                                                            url="{$exist:controller}/modules/view.xql"/>
                                                                                                                                                                                    </error-handler>
                                                                                                                                                                                </dispatch>
                                                                                                                                                                            
                                                                                                                                                                            else
                                                                                                                                                                                if (starts-with($exist:path, "/bibliography")) then
                                                                                                                                                                                    <dispatch
                                                                                                                                                                                        xmlns="http://exist.sourceforge.net/NS/exist">
                                                                                                                                                                                        <forward
                                                                                                                                                                                            url="{$exist:controller}/bibl.html"
                                                                                                                                                                                            method="get">
                                                                                                                                                                                        </forward>
                                                                                                                                                                                        <view>
                                                                                                                                                                                            <forward
                                                                                                                                                                                                url="{$exist:controller}/modules/view.xql">
                                                                                                                                                                                            </forward>
                                                                                                                                                                                        
                                                                                                                                                                                        </view>
                                                                                                                                                                                        
                                                                                                                                                                                        <error-handler>
                                                                                                                                                                                            <forward
                                                                                                                                                                                                url="{$exist:controller}/error/error-page.html"
                                                                                                                                                                                                method="get"/>
                                                                                                                                                                                            <forward
                                                                                                                                                                                                url="{$exist:controller}/modules/view.xql"/>
                                                                                                                                                                                        </error-handler>
                                                                                                                                                                                    </dispatch>
                                                                                                                                                                                
                                                                                                                                                                                
                                                                                                                                                                                else
                                                                                                                                                                                    if (starts-with($exist:path, "/additions")) then
                                                                                                                                                                                        <dispatch
                                                                                                                                                                                            xmlns="http://exist.sourceforge.net/NS/exist">
                                                                                                                                                                                            <forward
                                                                                                                                                                                                url="{$exist:controller}/additions.html"
                                                                                                                                                                                                method="get">
                                                                                                                                                                                            </forward>
                                                                                                                                                                                            <view>
                                                                                                                                                                                                <forward
                                                                                                                                                                                                    url="{$exist:controller}/modules/view.xql">
                                                                                                                                                                                                </forward>
                                                                                                                                                                                            
                                                                                                                                                                                            </view>
                                                                                                                                                                                            
                                                                                                                                                                                            <error-handler>
                                                                                                                                                                                                <forward
                                                                                                                                                                                                    url="{$exist:controller}/error/error-page.html"
                                                                                                                                                                                                    method="get"/>
                                                                                                                                                                                                <forward
                                                                                                                                                                                                    url="{$exist:controller}/modules/view.xql"/>
                                                                                                                                                                                            </error-handler>
                                                                                                                                                                                        </dispatch>
                                                                                                                                                                                    
                                                                                                                                                                                    else
                                                                                                                                                                                        if (starts-with($exist:path, "/IndexPlaces")) then
                                                                                                                                                                                            <dispatch
                                                                                                                                                                                                xmlns="http://exist.sourceforge.net/NS/exist">
                                                                                                                                                                                                <forward
                                                                                                                                                                                                    url="{$exist:controller}/places.html"
                                                                                                                                                                                                    method="get">
                                                                                                                                                                                                </forward>
                                                                                                                                                                                                <view>
                                                                                                                                                                                                    <forward
                                                                                                                                                                                                        url="{$exist:controller}/modules/view.xql">
                                                                                                                                                                                                    </forward>
                                                                                                                                                                                                
                                                                                                                                                                                                </view>
                                                                                                                                                                                                
                                                                                                                                                                                                <error-handler>
                                                                                                                                                                                                    <forward
                                                                                                                                                                                                        url="{$exist:controller}/error/error-page.html"
                                                                                                                                                                                                        method="get"/>
                                                                                                                                                                                                    <forward
                                                                                                                                                                                                        url="{$exist:controller}/modules/view.xql"/>
                                                                                                                                                                                                </error-handler>
                                                                                                                                                                                            </dispatch>
                                                                                                                                                                                        
                                                                                                                                                                                        else
                                                                                                                                                                                            if (starts-with($exist:path, "/IndexPersons")) then
                                                                                                                                                                                                <dispatch
                                                                                                                                                                                                    xmlns="http://exist.sourceforge.net/NS/exist">
                                                                                                                                                                                                    <forward
                                                                                                                                                                                                        url="{$exist:controller}/persons.html"
                                                                                                                                                                                                        method="get">
                                                                                                                                                                                                    </forward>
                                                                                                                                                                                                    <view>
                                                                                                                                                                                                        <forward
                                                                                                                                                                                                            url="{$exist:controller}/modules/view.xql">
                                                                                                                                                                                                        </forward>
                                                                                                                                                                                                    
                                                                                                                                                                                                    </view>
                                                                                                                                                                                                    
                                                                                                                                                                                                    <error-handler>
                                                                                                                                                                                                        <forward
                                                                                                                                                                                                            url="{$exist:controller}/error/error-page.html"
                                                                                                                                                                                                            method="get"/>
                                                                                                                                                                                                        <forward
                                                                                                                                                                                                            url="{$exist:controller}/modules/view.xql"/>
                                                                                                                                                                                                    </error-handler>
                                                                                                                                                                                                </dispatch>
                                                                                                                                                                                            
                                                                                                                                                                                            else
                                                                                                                                                                                                if ($exist:path eq '/manuscripts/' or
                                                                                                                                                                                                $exist:path eq '/works/' or
                                                                                                                                                                                                $exist:path eq '/narratives/' or
                                                                                                                                                                                                $exist:path eq '/places/' or
                                                                                                                                                                                                $exist:path eq '/studies/' or
                                                                                                                                                                                                $exist:path eq '/persons/' or
                                                                                                                                                                                                $exist:path eq '/institutions/'
                                                                                                                                                                                                ) then
                                                                                                                                                                                                    
                                                                                                                                                                                                    <dispatch
                                                                                                                                                                                                        xmlns="http://exist.sourceforge.net/NS/exist">
                                                                                                                                                                                                        <redirect
                                                                                                                                                                                                            url="{$exist:path}list"/>
                                                                                                                                                                                                    </dispatch>
                                                                                                                                                                                                else
                                                                                                                                                                                                    if (
                                                                                                                                                                                                    $exist:path eq '/manuscripts' or
                                                                                                                                                                                                    $exist:path eq '/works' or
                                                                                                                                                                                                    $exist:path eq '/narratives' or
                                                                                                                                                                                                    $exist:path eq '/places' or
                                                                                                                                                                                                    $exist:path eq '/studies' or
                                                                                                                                                                                                    $exist:path eq '/persons' or
                                                                                                                                                                                                    $exist:path eq '/institutions'
                                                                                                                                                                                                    ) then
                                                                                                                                                                                                        
                                                                                                                                                                                                        <dispatch
                                                                                                                                                                                                            xmlns="http://exist.sourceforge.net/NS/exist">
                                                                                                                                                                                                            <redirect
                                                                                                                                                                                                                url="{$exist:path}/list"/>
                                                                                                                                                                                                        
                                                                                                                                                                                                        </dispatch>
                                                                                                                                                                                                    
                                                                                                                                                                                                    else
                                                                                                                                                                                                  (:  let $c := console:log($exist:resource)
                                                                                                                                                                                                   let $c2 := console:log($taxonomy)
                                                                                                                                                                                                    return
                                        :)                                                                                                                                                                if ($taxonomy = $exist:resource) then
                                                                                                                                                                                                            <dispatch
                                                                                                                                                                                                                xmlns="http://exist.sourceforge.net/NS/exist">
                                                                                                                                                                                                                <redirect
                                                                                                                                                                                                                    url="{$config:appUrl}/authority-files/{$exist:resource}/main"/>
                                                                                                                                                                                                            </dispatch>
                                                                                                                                                                                                        
                                                                                                                                                                                                        else
                                                                                                                                                                                                            
                                                                                                                                                                                                            <dispatch
                                                                                                                                                                                                                xmlns="http://exist.sourceforge.net/NS/exist">
                                                                                                                                                                                                                <forward
                                                                                                                                                                                                                    url="{$exist:controller}/error/error-page.html"/>
                                                                                                                                                                                                                <view>
                                                                                                                                                                                                                    <forward
                                                                                                                                                                                                                        url="{$exist:controller}/modules/view.xql"/>
                                                                                                                                                                                                                </view>
                                                                                                                                                                                                            </dispatch>
                                                                                                                                                else
                                                                                                                                                    
                                                                                                                                                    <dispatch
                                                                                                                                                        xmlns="http://exist.sourceforge.net/NS/exist">
                                                                                                                                                        <error-handler>
                                                                                                                                                            <redirect
                                                                                                                                                                url="{$exist:controller}/error/error-page.html"
                                                                                                                                                                method="get"/>
                                                                                                                                                            <forward
                                                                                                                                                                url="{$exist:controller}/modules/view.xql"/>
                                                                                                                                                        </error-handler>
                                                                                                                                                    </dispatch>
                                                                                                                
                                                                                                                else
                                                                                                                    (: everything else is passed through :)
                                                                                                                    <dispatch
                                                                                                                        xmlns="http://exist.sourceforge.net/NS/exist">
                                                                                                                        
                                                                                                                        <cache-control
                                                                                                                            cache="yes"/>
                                                                                                                    </dispatch>

