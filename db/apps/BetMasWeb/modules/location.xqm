module namespace loc="https://www.betamasaheft.uni-hamburg.de/BetMasWeb/loc";

(:~
 : This variable is set with the app url, usually:
 :  * http://localhost:8080/exist/betmasweb for local development or
 :  * https://betamasaheft.eu for production
 :
 : This needs admin user elevation, so this module has the setuid bit set.
 :
 : This module has to be world-readable but does not expose any secrets.
 :)
declare function loc:appUrl () {
    (fn:environment-variable('APP_URL'), 'https://betamasaheft.eu')[1]
};