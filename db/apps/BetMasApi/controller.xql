xquery version "3.1";

declare variable $exist:path external;

declare variable $exist:resource external;

declare variable $exist:controller external;

declare variable $exist:prefix external;

declare variable $exist:root external;

declare variable $local:isget := request:get-method() = ("GET", "get");

if ($local:isget and $exist:path eq "") then
	<dispatch xmlns="http://exist.sourceforge.net/NS/exist"><redirect url="{ request:get-uri() }/" /></dispatch>

(: serve api.json (and any other top-level *.json) directly, e.g. for API docs tooling :)
else if ($local:isget and matches($exist:path, "^/[^/]+\.json$", "s")) then
	<dispatch xmlns="http://exist.sourceforge.net/NS/exist" />

(: everything else goes through the roaster router :)
else
	<dispatch xmlns="http://exist.sourceforge.net/NS/exist">
		<forward url="{ $exist:controller }/modules/api.xql">
			<set-header name="Access-Control-Allow-Origin" value="*" />
			<set-header name="Access-Control-Allow-Credentials" value="true" />
			<set-header name="Access-Control-Allow-Methods" value="GET, POST, DELETE, PUT, PATCH, OPTIONS" />
			<set-header name="Access-Control-Allow-Headers" value="Accept, Content-Type, Authorization, X-Start" />
			<set-header name="Cache-Control" value="no-cache" />
		</forward>
	</dispatch>
