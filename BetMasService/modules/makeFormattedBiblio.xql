xquery version "3.1";

import module namespace gfb = "https://www.betamasaheft.uni-hamburg.de/BetMas/gfb" at "xmldb:exist:///db/apps/BetMas/modules/generateFormattedBibliography.xqm";

let $collection := collection('/db/apps/BetMasData')
return gfb:makeBib($collection)

(:after generting with this script the bibliography needs to be edited:

- format, indent and save
- replace escaped elements in the html fragments
- check wrong pointers and notify in issue using fix.xql
:)