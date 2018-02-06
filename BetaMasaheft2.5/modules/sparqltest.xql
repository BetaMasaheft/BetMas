xquery version "3.0";
import module namespace sparql="http://exist-db.org/xquery/sparql" at
 "java:org.exist.xquery.modules.rdf.SparqlModule";

declare namespace rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#";
declare namespace sr = "http://www.w3.org/2005/sparql-results#";

let $query1 := ("PREFIX myhouse: <myhouse://>
                SELECT ?x
                WHERE { ?x a myhouse:furniture }
                ORDER BY ?x")

(: ("myhouse://chair", "myhouse://table") :)

let $query2 := ("PREFIX myhouse: <myhouse://>
                SELECT ?x ?c
                WHERE { ?x myhouse:count ?c ; a myhouse:furniture }
                ORDER BY ASC(?c)")
(: ("myhouse://table", "1", "myhouse://chair", "2") :)

let $query3 := ("PREFIX myhouse: <myhouse://>
                SELECT ?x ?r
                WHERE { ?x myhouse:room ?r }
                ORDER BY ASC(?c)")
(: ("myhouse://chair", "kitchen", "myhouse://table", "kitchen") :)

let $queries := ($query1, $query2, $query3)

return
  for $query in $queries
    (: return sparql:query($query)//text() :)
    return 
        sparql:query($query)//sr:uri