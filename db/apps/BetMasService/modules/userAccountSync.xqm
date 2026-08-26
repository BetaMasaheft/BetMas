
(:~
 : Keeps eXist-db user accounts durable across a container redeploy.
 :
 : The actual XQueryTrigger entry points live in userAccountTrigger.xqm,
 : which delegates to sync-account()/remove-account() below - a trigger's
 : callback functions MUST be declared in the fixed namespace
 : http://exist-db.org/xquery/trigger (confirmed empirically: the "local:"
 : binding-prefix convention some docs mention does not apply here), so
 : that module is kept separate and minimal, while this one stays under
 : its own descriptive namespace so it can be imported normally elsewhere
 : (e.g. BetMasInitInstance's restore loop).
 :
 : post-install.xq installs the collection.xconf that registers
 : userAccountTrigger.xqm on /db/system/security/exist/accounts. eXist
 : funnels every sm:create-account / sm:passwd / sm:add-group-member /
 : sm:remove-account call through the exact same document-store path
 : xmldb:store uses for that collection, so this fires for every account
 : mutation regardless of which code triggered it - not just the endpoints
 : in restviews/userAdmin.xqm.
 :
 : Each account's own stored document already contains its password hash
 : (in whatever format eXist itself produced - never computed here) and
 : every group it belongs to (first <group/> = primary), so the mirrored
 : copy in the volume is that document, verbatim, and BetMasInitInstance's
 : restore loop only ever transplants that copy back in via sm:passwd-hash
 : / sm:add-group-member / sm:set-account-metadata - it never re-derives a
 : hash from a plaintext password.
 :
 : A trigger that throws breaks every account create/update/delete until
 : fixed, so every filesystem operation here is defensive: a missing or
 : unmounted volume (e.g. local dev without the compose volume) must never
 : block an account mutation, it just means that mutation isn't durable
 : yet.
 :)
module namespace userAccountSync = "https://www.betamasaheft.uni-hamburg.de/BetMasService/userAccountSync";

import module namespace file = "http://exist-db.org/xquery/file";

(:~
 : Where to synchronize users to, a local directory somewhere that can be mounted as a volume
 :)
declare variable $userAccountSync:volume-path := doc("/db/apps/BetMasWeb/services.xml")//service[@env eq
	"USERS_VOLUME_DIRECTORY"][normalize-space(.) ne ""]/string();

declare function userAccountSync:user-file-path($username as xs:string) as xs:string {
	$userAccountSync:volume-path || "/" || encode-for-uri($username) || ".xml"
};

declare function userAccountSync:list-user-files() as xs:string* {
	if (file:exists($userAccountSync:volume-path) and file:is-directory($userAccountSync:volume-path)) then
		(: file:list() returns <list><file:file name="..." .../>...</list>, not a
		   sequence of plain filename strings - confirmed empirically. :)
		for $f in file:list($userAccountSync:volume-path)/*:file[ends-with(@name, ".xml")]
		return $userAccountSync:volume-path || "/" || $f/@name
	else (
	)
};

declare function userAccountSync:read-user-file($path as xs:string) as element()? {
	if (file:exists($path)) then
		parse-xml(file:read($path))/*
	else (
	)
};

declare function userAccountSync:sync-account($uri as xs:anyURI) {
	if (not(starts-with($uri, "/db/system/security/exist/accounts"))) then (
		(: Ignore this change: it is not regarding users. :)
	) else (
		try {
			let $_ := util:log("info", "Syncing account " || $uri || " to disk")
			let $account := doc($uri)/*:account
			let $username := $account/*:name/string()
			return if (exists($account) and $username ne "" and file:exists($userAccountSync:volume-path)) then
				file:serialize($account, userAccountSync:user-file-path($username), "indent=yes")
			else (
			)
		} catch * {
			util:log(
				"error",
				"userAccountSync:sync-account failed for " || $uri || " - " || $err:code || ": " || $err:description
			)
		}
	)
};

declare function userAccountSync:remove-account($uri as xs:anyURI) {
	try {
		let $username := replace(tokenize(string($uri), "/")[last()], "\.xml$", "")
		let $path := userAccountSync:user-file-path($username)
		return if ($username ne "" and file:exists($path)) then
			file:delete($path)
		else (
		)
	} catch * {
		util:log(
			"error",
			"userAccountSync:remove-account failed for " || $uri || " - " || $err:code || ": " || $err:description
		)
	}
};
