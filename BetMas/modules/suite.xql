xquery version "3.0";
import module namespace test="http://exist-db.org/xquery/xqsuite" at "resource:org/exist/xquery/lib/xqsuite/xqsuite.xql";
import module namespace titles="https://www.betamasaheft.uni-hamburg.de/BetMas/titles" at "xmldb:exist:///db/apps/BetMas/modules/titles.xqm";
import module namespace string = "https://www.betamasaheft.uni-hamburg.de/BetMas/string" at "xmldb:exist:///db/apps/BetMas/modules/tei2string.xqm";

test:suite(
    (
    inspect:module-functions(xs:anyURI("all.xqm")),
    inspect:module-functions(xs:anyURI("annotations.xql")),
    inspect:module-functions(xs:anyURI("rest.xql")),
    inspect:module-functions(xs:anyURI("titles.xqm")),
    inspect:module-functions(xs:anyURI("places.xql")),
    inspect:module-functions(xs:anyURI("log.xqm")),
    inspect:module-functions(xs:anyURI("iiif.xql")),
    inspect:module-functions(xs:anyURI("coordinates.xql"))
    )
)
