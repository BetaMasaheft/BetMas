xquery version "3.1" encoding "UTF-8";
(:~
 : module used by text search query functions to provide alternative 
 : strings to the search, based on known homophones.
 : 
 : @author Pietro Liuzzo 
 :)
module namespace editors = "https://www.betamasaheft.uni-hamburg.de/BetMas/editors";
declare namespace test="http://exist-db.org/xquery/xqsuite";
 declare namespace t="http://www.tei-c.org/ns/1.0";
 
 declare variable $editors:list :=doc('/db/apps/BetMas/lists/editors.xml')//t:list ;
 
(:~gets the name of the editor given the initials:)
declare
%test:arg("key", "PL") %test:assertEquals('Pietro Maria Liuzzo')
function editors:editorKey($key as xs:string){
$editors:list/t:item[@xml:id eq $key]/text()
};


        (:~ given the user name, returns the initials:)
declare 
%test:arg("key", "Pietro") %test:assertEquals('PL')
function editors:editorNames($key as xs:string){
string($editors:list/t:item[@n eq $key]/@xml:id)
};