xquery version "3.1" encoding "UTF-8";

declare variable $exist:path external;
declare variable $exist:resource external;
declare variable $exist:controller external;
declare variable $exist:prefix external;
declare variable $exist:root external;

(: everything under /morpho is served by this app's own Roaster router
   (modules/api.xql + modules/routes.json) - replaces the classic RESTXQ
   (%rest:*) dispatch previously handled by eXist's built-in RestXqServlet. :)
if (starts-with($exist:path, "/morpho")) then
	<dispatch xmlns="http://exist.sourceforge.net/NS/exist">
		<forward url="{ $exist:controller }/modules/api.xql">
			<set-header name="Cache-Control" value="no-cache" />
		</forward>
	</dispatch>
else
	(: everything else is passed through :)
	<dispatch xmlns="http://exist.sourceforge.net/NS/exist"><cache-control cache="yes" /></dispatch>
