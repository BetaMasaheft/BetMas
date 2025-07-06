module namespace tuttle-expand = "https://www.betamasaheft.uni-hamburg.de/BetMas/do-tuttle-expand";

import module namespace expand = "https://www.betamasaheft.uni-hamburg.de/BetMas/expand" at "xmldb:exist:///db/apps/BetMas/modules/expand.xqm";

declare %private function local:split-path($path) {
  let $filename := tokenize($path, '/')[last()]

  return map{
    "basename": $filename,
    "directory": substring-before($path, '/' || $filename)
  }
};

declare function local:mkcol-recursive($collection, $components) {
    if (exists($components)) then
        let $newColl := concat($collection, "/", $components[1])
        return (
            if (not(xmldb:collection-available($collection || "/" || $components[1]))) then
                xmldb:create-collection($collection, $components[1])
            else
                (),
            local:mkcol-recursive($newColl, subsequence($components, 2))
        )
    else
        ()
};

(: Helper function to recursively create a collection hierarchy. :)
declare function local:mkcol($collection, $path) {
    local:mkcol-recursive($collection, tokenize($path, "/"))
};

(:~
 : Expand new files and remove deleted ones
 :
 : It will just return the arguments the function is called with
 : for documentation and testing purposes
 :
 : the first argument is the collection configuration as a map
 : the second argument is a report of the changes that were applied
 : example changes

map {
    "del": [
        map { "path": "fileD", "success": true() }
    ],
    "new": [
        map { "path": "fileN1", "success": true() }
        map { "path": "fileN2", "success": true() }
        map { "path": "fileN3", "success": false(), "error": map{ "code": "err:XPTY0004", "description": "AAAAAAH!", "value": () } }
    ],
    "ignored": [
        map { "path": "fileD" }
    ]
}

: each array member in del, new and ignored is a

record action-result(
 "path": xs:string,
 "success": xs:boolean,
 "error"?: xs:error()
)
:)
declare function tuttle-expand:expand-data (
  $collection-config as map(*),
  $changes as map(*)
) {
  let $_ := util:log('info', $collection-config)
  let $_ := util:log('info', $changes)
  let $expanded-root := "/db/apps/expanded/" || $collection-config?collection => substring-after('BetMasData/')
  let $unexpanded-root :=
    "/db/apps/" || $collection-config?collection
  return ( (: Remove old stuff :)
    for $removed-file in $changes?del?*
    where $removed-file?success
    let $path-in-expanded := $expanded-root || "/" || $removed-file?path
    let $descriptor-in-expanded := local:split-path($path-in-expanded)
    let $_ :=
      util:log("info", "Removing removed file " || $path-in-expanded)
    return if (not(doc-available($path-in-expanded))) then
        util:log(
          "warning",
          "File " || $removed-file?path || " does not exist in expanded data"
        )
      else
        xmldb:remove($descriptor-in-expanded?directory, $descriptor-in-expanded?basename),
    (: Add new expanded files :)
    for $inserted-file in $changes?new?*
    where $inserted-file?success
    let $filepath := $unexpanded-root || "/" || $inserted-file?path
    let $filepath-in-expanded := $expanded-root || "/" || $inserted-file?path
    let $descriptor-in-expanded := local:split-path($filepath-in-expanded)
    let $expanded := expand:file($filepath)
    let $_ := local:mkcol($expanded-root, local:split-path($inserted-file?path)?directory)
    return if ($expanded) then (
        util:log(
            "info",
            "Expanding " || $filepath || " into " || $filepath-in-expanded
        ),
        xmldb:store($descriptor-in-expanded?directory, $descriptor-in-expanded?basename, $expanded)
    ) else (
				(: This happens every so often. Be resilient to it. :)
        util:log(
            "warn",
            "Expanding " || $filepath || " into " || $filepath-in-expanded || "failed. Skipping."
        )
    )
  )
};
