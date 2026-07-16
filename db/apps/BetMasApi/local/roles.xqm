xquery version "3.1" encoding "UTF-8";

(:~
 : module with all the main functions which can be called by the API.
 :
 : @author Pietro Liuzzo
 :)
module namespace roles = "https://www.betamasaheft.uni-hamburg.de/BetMasApi/roles";

(: namespaces of data used :)
declare namespace t = "http://www.tei-c.org/ns/1.0";
declare namespace test = "http://exist-db.org/xquery/xqsuite";
(: For REST annotations :)
declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";

import module namespace log = "http://www.betamasaheft.eu/log" at "xmldb:exist:///db/apps/BetMasWeb/modules/log.xqm";
import module namespace exptit = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/exptit" at "xmldb:exist:///db/apps/BetMasWeb/modules/exptit.xqm";
import module namespace config = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/config" at "xmldb:exist:///db/apps/BetMasWeb/modules/config.xqm";
import module namespace kwic = "http://exist-db.org/xquery/kwic" at "resource:org/exist/xquery/lib/kwic.xql";

(:~
 : given a role, search other attestations of it and print the persName around them and related infos
 :)
declare function roles:RoleAttestations($request as map(*)) {
	let $role as xs:string* := $request?parameters?role
	return (
		let $r := $role
		let $q := <query><fuzzy min-similarity="0.8">{ $r }</fuzzy></query>
		let $roleAttestations :=
			for $att in (collection($config:data-rootMS), collection($config:data-rootW))//t:TEI[ft:query(., $q)]
			let $expanded := kwic:expand($att)
			return $expanded//exist:match[parent::t:roleName]/parent::t:*
		let $roleAttestationsIdentified := $roleAttestations[parent::t:persName]

		let $results :=
			for $atttestation in $roleAttestations/parent::t:persName
			let $id := $atttestation/@ref
			group by $ID := $id
			let $roles :=
				for $rol in $atttestation
				let $type := $rol/t:roleName/@type
				group by $RT := $type
				let $atts :=
					for $ratt in $rol
					let $text := string-join($ratt/t:roleName/text())
					group by $T := $text
					let $sources :=
						for $rat in $ratt
						let $root := string(root($rat)/t:TEI/@xml:id)
						group by $ROOT := $root
						let $occurrences :=
							for $occurr in $rat
							let $f := string($occurr/@notBefore)
							let $t := string($occurr/@notAfter)
							let $anchor := if ($occurr/ancestor::t:body) then
								let $parent := $occurr/ancestor::t:*[@n][1]
								return ($parent/name() || "_" || string($parent/@n))
							else
								string($occurr/ancestor::t:*[@xml:id][1]/@xml:id)
							return <div class="w3-threequarter w3-padding">
								<div class="w3-third">from: { $f }</div>
								<div class="w3-third">to: { $t }</div>
								<div class="w3-third">in: { $anchor }</div>
							</div>

						return <div class="w3-threequarter">
							<div class="w3-quarter">
								<a class="MainTitle" data-value="{ $ROOT }" href="/{ $ROOT }">
									{ $ROOT }
									<span class="w3-tag w3-gray">{ count($occurrences) }</span>
								</a>
							</div>
							{
								for $occ in $occurrences
								return $occ
							}
						</div>
					return <div class="w3-col" style="width:85%">
						<div class="w3-quarter">{ $T }<span class="w3-tag w3-gray">{ count($sources) }</span></div>
						{
							for $sour in $sources
							return $sour
						}
					</div>
				return <div class="w3-col" style="width:85%">
					<div class="w3-col" style="width:15%">
						{ string($RT) }
						<span class="w3-tag w3-gray">{ count($atts) }</span>
					</div>
					{
						for $att in $atts
						return $att
					}
				</div>
			return <div class="w3-row">
				<div class="w3-col" style="width:15%">
					<a class="MainTitle" data-value="{ string($ID) }" href="/{ string($ID) }">
						{ string($ID) }
						<span class="w3-tag w3-gray">{ count($roles) }</span>
					</a>
				</div>
				{
					for $role in $roles
					return $role
				}
			</div>

		return <div class="w3-container">
			<p>There are in total { count($roleAttestationsIdentified) } attestations of the role name <span
					class="w3-tag w3-gray"
				>{ $r }</span> related to {
					count(config:distinct-values($roleAttestations/parent::t:persName/@ref))
				} persons.</p>
			{
				for $result in $results
				return $result
			}
		</div>
	)
};

(:~
 : returns an object which includes an array of objects with data about persons to which in some resource a specific role has been assigned, for each id, canonical title and the list of resources for which he/she covers such role, are given.
 :)
declare
	%test:arg("role", "donor") %test:assertExists %test:arg("role", "scribe") %test:assertExists
function roles:role($request as map(*)) {
	let $role as xs:string* := $request?parameters?role
	return let $log := log:add-log-message("/api/hasrole/" || $role, sm:id()//sm:real/sm:username/string(), "REST")
		let $cp := collection($config:data-rootPr)
		let $path := $exptit:col//t:persName[@role eq $role][@ref[not(starts-with(., "PRS0000"))][. != "PRS0476IHA"][. !=
			"PRS0204IHA"]]
		let $total := count($path)
		let $hits :=
			for $pwl in $path
			let $id := string($pwl/@ref)

			group by $ID := $id

			return map {"pwl": $ID, "title": exptit:printTitleID($ID), "hits": count($pwl)}

		return (map {"role": $role, "hits": $hits, "total": count($hits), "referring": $total})
};

(:~
 : returns an object which includes an array of objects with data about persons to which in some resource a specific role has been assigned, for each id, canonical title and the list of resources for which he/she covers such role, are given.
 :)
declare
	%test:args("patron", "PRS2916Bruce") %test:assertExists %test:args("owner", "PRS2916Bruce") %test:assertExists
function roles:roleID($request as map(*)) {
	let $role as xs:string* := $request?parameters?role
	let $ID as xs:string* := $request?parameters?ID
	return let $ID := if (starts-with($ID, "https://betamasaheft.eu/")) then
			string($ID)
		else
			"https://betamasaheft.eu/" || string($ID)
		let $log := log:add-log-message("/api/hasrole/" || $role, sm:id()//sm:real/sm:username/string(), "REST")
		let $path := $exptit:col//t:persName[@role eq $role][@ref eq $ID]
		let $hits :=
			for $x in $path
			let $root := string(root($x)/t:TEI/@xml:id)
			group by $r := $root
			return map {"prov": $r, "sourceTitle": exptit:printTitleID($r), "count": count($x)}

		let $hs := if (count($hits) gt 1) then
			$hits
		else
			[$hits]
		return (map {"pwl": $ID, "title": exptit:printTitleID($ID), "hits": count($path), "hasthisrole": $hs})
};
