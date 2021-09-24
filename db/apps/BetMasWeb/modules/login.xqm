xquery version "3.1" encoding "UTF-8";
(:~
 : module used by the app for login and logout
 : 
 : @author Pietro Liuzzo 
 :)
module namespace locallogin="https://www.betamasaheft.eu/login";
import module namespace config = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/config" at "xmldb:exist:///db/apps/BetMasWeb/modules/config.xqm";
import module namespace request = "http://exist-db.org/xquery/request";

declare variable $locallogin:login :=
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
            locallogin:fallback-login#3
;



(:~
    Fallback login function used when the persistent login module is not available.
    Stores user/password in the HTTP session.
 :)
declare function locallogin:fallback-login($domain as xs:string, $maxAge as xs:dayTimeDuration?, $asDba as xs:boolean) {
    let $user := request:get-parameter("user", ())
    let $password := request:get-parameter("password", ())
    let $logout := request:get-parameter("logout", ())
    return
        if ($logout) then
            session:invalidate()
       else
            if ($user) then
                let $isLoggedIn := xmldb:login("/db", $user, $password, true())
                return (
                        session:set-attribute("BetMas.user", $user),
                        session:set-attribute("BetMas.password", $password),
                        request:set-attribute($domain || ".user", $user),
                        request:set-attribute("xquery.user", $user),
                        request:set-attribute("xquery.password", $password)
                        )
                   
            else
                let $user := session:get-attribute("BetMas.user")
                let $password := session:get-attribute("BetMas.password")
                return (
                    request:set-attribute($domain || ".user", $user),
                    request:set-attribute("xquery.user", $user),
                    request:set-attribute("xquery.password", $password)
                    )
};

declare function locallogin:user-allowed() {
    (
        request:get-attribute("org.exist.login.user") and
        request:get-attribute("org.exist.login.user") != "guest"
    ) or config:get-configuration()/restrictions/@guest = "yes"
};


(:declare function locallogin:logout(){
$locallogin:login("org.exist.login", (), false())
};

declare function locallogin:loginhere(){
$locallogin:login("org.exist.login", (), false())
};
:)

(:~ login function to be called from navigation template. if the user is guest, then show login, if not it is a logged user, then show logout:)

declare function locallogin:loginNew(){  
 if(sm:id()//sm:username/text() = 'guest') then
 
 <div class="w3-dropdown-hover w3-hide-small" id="logging">
      <button class="w3-button " title="resources">Login <i class="fa fa-caret-down"></i></button>     
      <div class="w3-dropdown-content w3-bar-block w3-card-4">
      
	<form method="post" class="w3-container" role="form" 
	accept-charset="UTF-8" id="login-nav">
                    <label for="user">User:</label>
                            <input type="text" name="user" required="required" class="w3-input"/>
                        
                        <label for="password">Password:</label>
                            <input type="password" name="password" class="w3-input"/>
                        
                            <button class="w3-button w3-small w3-red" type="submit">Login</button>
                          		
                </form>
                </div>
                </div>
                else
              <form method="post" action="" class="w3-bar-item w3-hide-smal" style="margin:0;padding:0" role="form" accept-charset="UTF-8" id="logout-nav">
                
              <button  class=" w3-button w3-red" type="submit">Logout</button>
              
              <input value="true" name="logout"  type="hidden"/>
                        
              </form>
}; 