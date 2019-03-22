xquery version "3.1";
declare namespace t="http://www.tei-c.org/ns/1.0";
import module namespace config="https://www.betamasaheft.uni-hamburg.de/BetMas/config" at "xmldb:exist:///db/apps/BetMas/modules/config.xqm";
inspect:inspect-module(xs:anyURI("xmldb:exist:///db/apps/BetMas/modules/places.xqm"))