xquery version "3.0" encoding "UTF-8";

import module namespace config = "https://www.betamasaheft.uni-hamburg.de/BetMas/config" at "modules/config.xqm";
import module namespace request = "http://exist-db.org/xquery/request";
import module namespace console = "http://exist-db.org/xquery/console";
import module namespace error = "https://www.betamasaheft.uni-hamburg.de/BetMas/error" at "modules/error.xqm";


declare namespace t = "http://www.tei-c.org/ns/1.0";

declare variable $exist:path external;
declare variable $exist:resource external;
declare variable $exist:controller external;
declare variable $exist:prefix external;
declare variable $exist:root external;
declare variable $taxonomy := doc(concat($config:data-rootA, '/taxonomy.xml'))//t:catDesc;
(:  get what Nginx sends:)
declare function local:get-uri() {
    (request:get-header("nginx-request-uri"), request:get-uri())[1]
};


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
;



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
            (
            session:invalidate(),
             console:log('logout'),
             console:log('I have just logged out. This list of SESSION attributes should be empty ' ||string-join(session:get-attribute-names(), ' '))
                        
             )
       else
            if ($user) then
                let $isLoggedIn := xmldb:login("/db", $user, $password, true())
                return (
                        session:set-attribute("BetMas.user", $user),
                        session:set-attribute("BetMas.password", $password),
                        request:set-attribute($domain || ".user", $user),
                        request:set-attribute("xquery.user", $user),
                        request:set-attribute("xquery.password", $password),
                        console:log(if(session:exists()) then 'yes' else 'no'),
                        console:log('I have just set user param. These are the REQUEST attributes ' ||string-join(request:attribute-names(), ' ')),
                        console:log('I have just set user param. These are the SESSION attributes ' ||string-join(session:get-attribute-names(), ' '))
                        
                        )
                   
            else
             let $test := console:log('isNotLogged')
                let $user := session:get-attribute("BetMas.user")
                let $password := session:get-attribute("BetMas.password")
                return (
                    request:set-attribute($domain || ".user", $user),
                    request:set-attribute("xquery.user", $user),
                    request:set-attribute("xquery.password", $password),
                        console:log('No user param. These are the REQUEST attributes ' || string-join(request:attribute-names(), ' ')),
                        console:log('No user param. These are the SESSION attributes' || string-join(session:get-attribute-names(), ' '))
                )
};

declare function local:user-allowed() {
    (
        request:get-attribute("org.exist.login.user") and
        request:get-attribute("org.exist.login.user") != "guest"
    ) or config:get-configuration()/restrictions/@guest = "yes"
};

declare function local:switchCol($type){
    
    switch($type)
        case 'work' return 'works'
        case 'narr' return 'narratives'
        case 'pers' return 'persons'
        case 'place' return 'places'
        case 'ins' return 'institutions'
        case 'auth' return 'authority-files'
        default return 'manuscripts'
    
};

declare function local:switchPrefix( $prefix){
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
                                                    default return
                                                        'manuscripts'
                                                        };

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
                url="/shared-resources/{substring-after($exist:path, '/$shared/')}"/>
        </dispatch>
        
        (: Requests for javascript libraries are resolved to the file system :)
    else
        if (contains($exist:path, "resources/")) then
            <dispatch
                xmlns="http://exist.sourceforge.net/NS/exist">
                <forward
                    url="{$exist:controller}/resources/{substring-after($exist:path, 'resources/')}"/>
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
           
             else if (ends-with($exist:resource, ".pdf")) then
    let $id := substring-before($exist:resource, '.pdf')
    return
            <dispatch xmlns="http://exist.sourceforge.net/NS/exist">
                <forward url="{$exist:controller}/modules/tei2fo.xql">
            <set-header name="Cache-Control" value="no-cache"/>
                    <add-parameter name="id" value="{$id}"/>
                </forward>
                <error-handler>
                    <forward url="{$exist:controller}/error.html" method="get"/>
                    <forward url="{$exist:controller}/modules/view.xql"/>
                </error-handler>
            </dispatch>
            
           else
                    if (contains($exist:path, 'institutions') and ends-with($exist:path, '/main')) then
                        let $url := replace(replace($exist:path, 'institutions', 'manuscripts'), 'main', 'list')
                        return
                        <dispatch
                            xmlns="http://exist.sourceforge.net/NS/exist">
                            <redirect
                                url="{$url}"
                                absolute="yes"/>
                        </dispatch>
                         
                (:            redirect to api all calls starting with /api/ ending with one of the specific rest modules:)
           
            else
                if (contains($exist:path, '/api/') or
                ends-with($exist:path, '/list') or
                ends-with($exist:path, '/analytic') or
                ends-with($exist:path, '/main') or
                ends-with($exist:path, '/compare') or
                ends-with($exist:path, '/text') or
                ends-with($exist:path, '/viewer') or
                ends-with($exist:path, '/time') or
                starts-with($exist:path, '/user') or
                starts-with($exist:path, '/listIds')) then
                   
                    if (ends-with($exist:path, "/")) then
                        <dispatch
                            xmlns="http://exist.sourceforge.net/NS/exist">
                            <redirect
                                url="/apidoc.html"/>
                        </dispatch>
                    else
                        <dispatch
                            xmlns="http://exist.sourceforge.net/NS/exist">
                            <forward
                                url="{concat('/restxq/BetMas', $exist:path)}"
                                absolute="yes"> 
                                {$login("org.exist.login", (), false())}
                                {console:log(xmldb:get-current-user())}
                                 <set-header name="Cache-Control" value="no-cache"/>
                                </forward>
                        </dispatch>
                        
               
                                
                                (:    redirects to api for geoJson:)
                    else
                        if (ends-with($exist:path, ".json")) then
                            <dispatch
                                xmlns="http://exist.sourceforge.net/NS/exist">
                                <forward
                                    url="/restxq/BetMas/api/geoJson/places/{substring-before($exist:resource, '.json')}"
                                    absolute="yes"
                                >
                                
                                </forward>
                            
                            </dispatch>
                            
                            (:                :)
                        else
                            if (starts-with($exist:path, '/tei/') and ends-with($exist:path, ".xml")) then
                                 let $coll := collection($config:data-root)
                            let $id := substring-before($exist:resource, '.xml')
                            let $item := $coll//id($id)[name()='TEI']
                            let $collection := local:switchCol($item/@type)
                            let $uri := base-uri($item)
                               
                            return
                            if ($item) then
                                <dispatch
                                    xmlns="http://exist.sourceforge.net/NS/exist">
                                    <forward
                                        url="/{substring-after($uri, 'db/apps/')}"/>
                                    <view>
                                        <forward
                                            servlet="XSLTServlet">
                                            <set-attribute
                                                name="xslt.stylesheet"
                                                value="{concat($exist:root, $exist:controller, "/xslt/post.xsl")}"/>
                                                
            <set-header name="Cache-Control" value="no-cache"/>
                                        </forward>
                                    </view>
                                </dispatch>
                                 else 
                                
                              let $Imap := map {'type':= 'xmlitem', 'name' := $id, 'path' := $collection}
                                 return
                                 error:error($Imap)
                        
                        
                        else
                            if (ends-with($exist:path, ".xml")) then
                            let $coll := collection($config:data-root)
                            let $id := substring-before($exist:resource, '.xml')
                            let $item := $coll//id($id)[name()='TEI']
                            let $collection := local:switchCol($item/@type)
                            let $uri := base-uri($item)
                            return
                            if ($item) then
                                <dispatch
                                    xmlns="http://exist.sourceforge.net/NS/exist">
                                    <forward
                                        url="/{substring-after($uri, 'db/apps/')}"/>
                                        <error-handler>
                                                <forward
                                                    url="{$exist:controller}/error/error-page.html"
                                                    method="get"/>
                                                <forward
                                                    url="{$exist:controller}/modules/view.xql"/>
                                            
                                            </error-handler>
                                </dispatch>
                                
                                
                                else 
                                
let $Imap := map {'type':= 'xmlitem', 'name' := $id, 'path' := $collection}
return
                                 error:error($Imap)
                                 
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
                                        url="/rdf/{$exist:resource}"/>
                                        <error-handler>
                                                <forward
                                                    url="{$exist:controller}/error/error-page.html"
                                                    method="get"/>
                                                <forward
                                                    url="{$exist:controller}/modules/view.xql"/>
                                            
                                            </error-handler>
                                </dispatch>
                                
                                
                                else 
                                
let $Imap := map {'type':= 'xmlitem', 'name' := $id, 'path' := $coll}
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
                                                     {$login("org.exist.login", (), false())}
             {console:log(xmldb:get-current-user())}
                                                     <set-header name="Cache-Control" value="no-cache"/>
                                            </forward>
                                            <view>
                                                <forward
                                                    url="{$exist:controller}/modules/view.xql">
                                                    <add-parameter
                                                        name="uri"
                                                        value="{('/db/apps/BetMas/index.html')}"/>
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
                             
                                        
(:                                        if the resource does match the id, then redirect to main view of that item:)
                                        
                                        else
                                            if (matches($exist:resource, "\w+\d+(\w+)?")) then
                                                let $prefix := substring($exist:resource, 1, 2)
                                                let $switchCollection := local:switchPrefix($prefix)
                                            return
                                                if (not(contains($exist:path, $switchCollection))) then
                                                    <dispatch
                                                        xmlns="http://exist.sourceforge.net/NS/exist">
                                                        <redirect
                                                            url="/{$switchCollection}/{$exist:resource}/main"/>
                                                    </dispatch>
                                                else
                                                    
                                                    <dispatch
                                                        xmlns="http://exist.sourceforge.net/NS/exist">
                                                        <redirect
                                                            url="/{$switchCollection}/{$exist:resource}/main"/>
                                                    
                                                    </dispatch>
                                        
                                        
                                                            
                                                            else
                                                                if (ends-with($exist:resource, ".html")) then
                                                                    
                                                                    <dispatch
                                                                        xmlns="http://exist.sourceforge.net/NS/exist">
                                                                        <forward
                                                                            url="{$exist:controller}/{$exist:resource}"/>
                                                                        <view>
                                                                            <forward
                                                                                url="{$exist:controller}/modules/view.xql"/>
             {$login("org.exist.login", (), false())}
             {console:log(xmldb:get-current-user())}
            <set-header name="Cache-Control" value="no-cache"/>
                                                                        
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
                                    else
                                        if (matches($exist:resource, "^[^.\d]+$")) then
                                            
(:                                            if it actually points to authority files, go there:)
                                            if (contains($exist:path, "/authority-files/")) then
                                                <dispatch
                                                    xmlns="http://exist.sourceforge.net/NS/exist">
                                                    <redirect
                                                        url="/authority-files/{$exist:resource}/main"/>
                                                </dispatch>
                                            
                                            else
                                            
(:                                            if it is a special page then go there :)
                                                    if (starts-with($exist:path, "/timeline")) then
                                                        <dispatch
                                                            xmlns="http://exist.sourceforge.net/NS/exist">
                                                            <forward
                                                                url="{$exist:controller}/timeline.html"
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
                                                        if (starts-with($exist:path, "/images/")) then
                                                            <dispatch
                                                                xmlns="http://exist.sourceforge.net/NS/exist">
                                                                <forward
                                                                    url="{$exist:controller}/data/{$exist:path}"
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
                                                            if (starts-with($exist:path, "/decorations")) then
                                                                <dispatch
                                                                    xmlns="http://exist.sourceforge.net/NS/exist">
                                                                    <forward
                                                                        url="{$exist:controller}/decorations.html"
                                                                        method="get">
                                                                        <add-parameter
                                                                            name="uri"
                                                                            value="{('/db/apps/BetMas/decorations.html')}"/>
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
                                                                                    value="{('/db/apps/BetMas/xpath.html')}"/>
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
                                                                                    value="{('/db/apps/BetMas/sparql.html')}"/>
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
                                                        
                                                        else if ($exist:path eq '/manuscripts/' or
                                                        $exist:path eq '/works/' or
                                                        $exist:path eq '/narratives/' or
                                                        $exist:path eq '/places/' or
                                                        $exist:path eq '/persons/' or
                                                        $exist:path eq '/institutions/'
                                                        ) then
                                                        
                                                        <dispatch
                                                                            xmlns="http://exist.sourceforge.net/NS/exist">
                                                                            <redirect
                                                                                url="{$exist:path}list"/>
                                                                           
                                                                        </dispatch>
                                                                         
                                                        else if (
                                                        $exist:path eq '/manuscripts' or
                                                       
                                                        $exist:path eq '/works' or
                                                     
                                                        $exist:path eq '/narratives' or
                                                     
                                                        $exist:path eq '/places' or
                                               
                                                        $exist:path eq '/persons' or
                                                        $exist:path eq '/institutions'
                                                      
                                                        ) then
                                                        
                                                        <dispatch
                                                                            xmlns="http://exist.sourceforge.net/NS/exist">
                                                                            <redirect
                                                                                url="{$exist:path}/list"/>
                                                                           
                                                                        </dispatch>
                                                                    
                                                          else if ($taxonomy = $exist:resource) then
                                                          <dispatch
                                                    xmlns="http://exist.sourceforge.net/NS/exist">
                                                    <redirect
                                                        url="/authority-files/{$exist:resource}/main"/>
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
