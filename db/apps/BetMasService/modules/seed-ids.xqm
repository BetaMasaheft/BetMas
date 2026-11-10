xquery version "3.1";
import module namespace seed = "https://www.betamasaheft.uni-hamburg.de/BetMasWeb/idmanager-seed" at "/db/apps/BetMasWeb/modules/idmanager-seed.xqm";

(: Run this file to seed the ID manager. It should only be used when the state of the id-manager gets lost, otherwise it will reserve many ids for a buffer :)

(: Seed with plenty of leeway. 1000 should be fine. If not, change this value :)
let $buffer := 1000
return seed:run($buffer)