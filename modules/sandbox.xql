xquery version "3.0";

declare namespace t = "http://www.tei-c.org/ns/1.0";
import module namespace config = "https://www.betamasaheft.uni-hamburg.de/BetMas/config" at "config.xqm";
import module namespace app = "https://www.betamasaheft.uni-hamburg.de/BetMas/app" at "app.xqm";
import module namespace titles = "https://www.betamasaheft.uni-hamburg.de/BetMas/titles" at "titles.xqm";
import module namespace apprest = "https://www.betamasaheft.uni-hamburg.de/BetMas/apprest" at "apprest.xqm";
import module namespace xqjson="http://xqilla.sourceforge.net/lib/xqjson";
import module namespace http="http://expath.org/ns/http-client";


    titles:printTitleID('PRS9162TaklaHa')