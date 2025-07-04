xquery version "3.1";

declare namespace api="https://www.betamasaheft.uni-hamburg.de/BetMas/counter-app/api";

import module namespace config="https://www.betamasaheft.uni-hamburg.de/BetMas/counter-app/config" at "./config.xql";
import module namespace roaster="http://e-editiones.org/roaster";
declare namespace output="http://www.w3.org/2010/xslt-xquery-serialization";

(:~
 : list of definition files to use
 :)
declare variable $api:definitions := ("api.json");

declare variable $current-counter := fn:doc('../data/counter.xml')/counter;

declare function api:reserve-counter($request as map(*)) {
		let $current := number($current-counter)
		let $new := $current + 1
		let $_ := update value $current-counter with $new
		return map{
			  "success": true(),
	   		"value": $new
		}
};

declare function api:reset-counter($request as map(*)) {
		let $new := $request?parameters?value
		let $_ := update value $current-counter with $new
		return map{
			   "success": true()
		}
};

declare function api:lookup ($name as xs:string) {
    function-lookup(xs:QName($name), 1)
};

roaster:route($api:definitions, api:lookup#1)
