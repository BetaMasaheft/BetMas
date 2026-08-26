let $app_url := fn:environment-variable("APP_URL")
let $loc_module :=
``[xquery version "3.1";

module namespace loc="https://www.betamasaheft.uni-hamburg.de/BetMasWeb/loc";

(:~
 : This variable is set with the app url, usually:
 :  * http://localhost:8080/exist/betmasweb for local development or
 :  * https://betamasaheft.eu for production
 :
 : It is automatically generated
 :)
declare variable $loc:appUrl := "`{$app_url}`";
]``

(: Capture external-service endpoint overrides while running as DBA:
   fn:environment-variable is a DBA-only read in eXist, so request-time
   code cannot see these. config:service-url() in BetMasWeb reads the
   stored document instead and falls back to its default (the production
   wiring) when a variable was not set. This must run here (stage-2
   autodeploy, first container start) and not in BetMasWeb's own
   post-install, which runs during the image build where the runtime
   environment is not yet set. :)
let $services := <services>
	{
		for $env in ("COLLATEX_URL", "FUSEKI_URL", "ID_MANAGER_URL", "USERS_VOLUME_DIRECTORY")
		let $value := fn:environment-variable($env)
		where normalize-space($value) != ""
		return <service env="{ $env }">{ normalize-space($value) }</service>
	}
</services>

let $_ := util:log("info", "Storing " || $app_url || " as the root of the application.	")

return (
	xmldb:store("/db/apps/BetMasWeb/modules", "loc.xqm", $loc_module),
	(: guest must be able to read but never write this document: it holds
       URLs the server itself will POST to :)
	(
		xmldb:store("/db/apps/BetMasWeb", "services.xml", $services),
		sm:chmod(xs:anyURI("/db/apps/BetMasWeb/services.xml"), "rw-r--r--")
	),
	(: Store tuttle configuration :)
	xmldb:store("/db/apps/tuttle/data", "tuttle.xml", doc("./tuttle.xml")),
	(: Add the scratchpad for any new files. They are created here so they can be downloaded right away. :)

	for $col in xmldb:get-child-collections("/db/apps/expanded")
	let $newCollection := xmldb:create-collection("/db/apps/expanded/" || $col, "new")
	(: And allow editors to write to it :)
	return (sm:chgrp($newCollection, "Cataloguers"), sm:chmod($newCollection, "rwxrwxr-x"))
),
(:~
 : Restore accounts from the users volume (see BetMasWeb's
 : modules/userAccountSync.xqm, which mirrors each account's own stored
 : document - <account><password>...</password><group name=".."/>*
 : <metadata key="..">..</metadata>* <name>..</name></account> - into this
 : volume via a trigger on /db/system/security/exist/accounts every time an
 : account is created/changed/deleted, from any code path). A freshly
 : recreated container has no accounts beyond whatever's baked into the
 : image, so this only ever needs to add/update, never delete.
 :)
let $usersVolumeDirectory := fn:environment-variable("USERS_VOLUME_DIRECTORY")
return if (empty($usersVolumeDirectory) or not(file:is-directory($usersVolumeDirectory))) then (
	(: Nothing to do: no users to import :)
) else (
	for $file in file:list($usersVolumeDirectory)/*:file[ends-with(@name, ".xml")]
	let $account := parse-xml(file:read($usersVolumeDirectory || "/" || $file/@name))/*
	let $username := $account/*:name/string()
	let $groups := $account/*:group/@name/string()
	let $primaryGroup := $groups[1]
	let $rawPasswordHash := replace($account/*:password/string(), "^\{[^}]*\}", "")
	where $username ne "" and exists($primaryGroup)
	let $_ := util:log("info", "Creating user from volume with name " || $username)
	return (
		if (sm:user-exists($username)) then (
			(: User is already there. Do not create, but overwrite password anyway :)
		) else (
			sm:create-account($username, "unused-overwritten-below", $primaryGroup, $primaryGroup, "")
		),
		sm:passwd-hash($username, $rawPasswordHash),
		for $g in $groups[position() > 1]
		where not($username = sm:get-group-members($g))
		return sm:add-group-member($g, $username),
		for $m in $account/*:metadata
		return sm:set-account-metadata($username, xs:anyURI($m/@key/string()), $m/string())
	)
),
(:~
 : Register the account-persistence trigger (BetMasService/modules/userAccountTrigger.xqm,
 : which delegates to userAccountSync.xqm) on eXist's own accounts
 : collection, so every account create/update/delete - from these
 : endpoints, the self-service scripts, or anywhere else - gets mirrored
 : into the users volume and survives a container redeploy.
 : Per https://exist-db.org/exist/apps/doc/triggers , a collection's config
 : must live at exactly /db/system/config + its own path, so this collection's
 : config is /db/system/config/db/system/security/exist/accounts/collection.xconf.
 : xmldb:create-collection needs each parent to exist first, so walk it down
 : the same way as the /db/apps/expanded/* placeholders above.
 :)
let $configAccountsCollection := "/db/system/config/db/system/security/exist/accounts"
return (
	if (xmldb:collection-available($configAccountsCollection)) then (
	) else (
		if (xmldb:collection-available("/db/system/config/db")) then (
		) else
			xmldb:create-collection("/db/system/config", "db"),
		if (xmldb:collection-available("/db/system/config/db/system")) then (
		) else
			xmldb:create-collection("/db/system/config/db", "system"),
		if (xmldb:collection-available("/db/system/config/db/system/security")) then (
		) else
			xmldb:create-collection("/db/system/config/db/system", "security"),
		if (xmldb:collection-available("/db/system/config/db/system/security/exist")) then (
		) else
			xmldb:create-collection("/db/system/config/db/system/security", "exist"),
		xmldb:create-collection("/db/system/config/db/system/security/exist", "accounts")
	),
	xmldb:store(
		$configAccountsCollection,
		"collection.xconf",
		<collection xmlns="http://exist-db.org/collection-config/1.0">
			<triggers>
				<trigger class="org.exist.collections.triggers.XQueryTrigger" event="create,update,delete">
					<parameter name="url" value="xmldb:exist:///db/apps/BetMasService/modules/userAccountTrigger.xqm" />
				</trigger>
			</triggers>
		</collection>
	)
)
