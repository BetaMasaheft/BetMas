xquery version "3.1" encoding "UTF-8";

(:~
 : roaster OpenAPI router entry point. Routes requests according to
 : routes.json, resolving each operationId to a function in morphoparser.xqm.
 : Replaces the classic RESTXQ (%rest:*) dispatch previously handled by
 : eXist's built-in RestXqServlet.
 :)

declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";

import module namespace roaster = "http://e-editiones.org/roaster";
import module namespace morpho = "http://betamasaheft.eu/parser/morpho" at "morphoparser.xqm";

declare function local:lookup($name as xs:string) {
	function-lookup(xs:QName($name), 1)
};

roaster:route(("modules/api.json"), local:lookup#1)
