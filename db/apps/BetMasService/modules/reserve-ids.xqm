xquery version "3.1";

import module namespace idmanager = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/idmanager" at "xmldb:exist:///db/apps/BetMasWeb/modules/idmanager.xqm";

declare function local:reserve-ids ($type as xs:string, $amount as xs:integer) {
	let $typesResponse := idmanager:list-types()

	return if ($typesResponse?status != 200) then (
		error(
			xs:QName("local:ERR"),
			'"Requesting current types failed' || serialize($typesResponse, map {"method": "json"})
		)
	) else if (not($type = $typesResponse?body?*?type)) then (
		error(
			xs:QName("local:ERR"),
			'"Type ' ||
				$type ||
				" is not a known type. Valid types are " ||
				$typesResponse?body?*?type => array:flatten() => string-join(", ")
		)
	) else if (not($typesResponse?body?*[?type = $type]?mode = "auto")) then (
		error(xs:QName("local:ERR"), '"Type ' || $type || " is not an auto-incrementing type.")
	) else (
		let $next := idmanager:reserve-auto($type, ())
		return if ($next?status != 201) then (
			error(xs:QName("local:ERR"), "Reserving ID failed " || serialize($next, map {"method": "json"}))
		) else (
			let $sequence := $next?body?sequence

			(: We already reserved one. Pick up from here :)
			let $last := $sequence + $amount - 1
			let $seedResult := idmanager:reset-counter($type, $last)

			return if ($seedResult?status != 200) then (
				error(xs:QName("local:ERR"), "Seeding IDs failed " || serialize($seedResult, map {"method": "json"}))
			) else (
				let $newLastId := $next?body?prefix || xs:integer($last)
				return "Reserved ID " || $next?body?id || " until " || $newLastId
			)
		)
	)
};

(:~
 : The type to reserve for. One of:
 : * "dillmann-entries"
 : * "institutions"
 : * "narratives"
 : * "persons"
 : * "places"
 : * "studies"
 : * "works"
 :)
let $typeToReserve := "works"
(:~
 : How many to reserve
 :)
let $amountToReserve := 100

let $result := local:reserve-ids($typeToReserve, $amountToReserve)

return $result
