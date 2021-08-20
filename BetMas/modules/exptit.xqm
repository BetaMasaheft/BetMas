xquery version "3.1" encoding "UTF-8";

(:titles.xqm uses existing lists maintained on upload of the source data. it will update the lists when needed.
only the gitsync.xqm and the expanded.xqm modules, which deal with the data as entered in the db, should use titles.xqm
the expanded TEI will include those titles and names.
The views do not need to use this, and should instead get the information straight from the context of the expanded file, without checking lists or other files again :)

module namespace exptit = "https://www.betamasaheft.uni-hamburg.de/BetMas/exptit";
import module namespace config = "https://www.betamasaheft.uni-hamburg.de/BetMas/config" at "xmldb:exist:///db/apps/BetMas/modules/config.xqm";

declare namespace t = "http://www.tei-c.org/ns/1.0";

declare variable $exptit:col := collection($config:data-root);
(: The entry point function of the module. Establishes the different rules and priority to print a title referring to a record. can start from any node in the document. :)
declare function exptit:printTitle($titleMe) {
    (:titleable could a node or a string, and the string could be anything...:)
    typeswitch ($titleMe)
        case element()
        (:        could be TEI or any other node, just go back to the top:)
            return
                let $resource := root($titleMe)
                return
                    (:                this is added by expanded.xql exptit relies on that :)
                    $resource//t:title[@type = 'full']/text()
        default
            return
                (:            the string could be really just anything, but in the expanded data, it will often be a URI.:)
                if (starts-with($titleMe, $config:appUrl)) then
                    (:                check if it is a local URI :)
                    let $id := substring-after($titleMe, concat($config:appUrl, '/'))
                    let $log := util:log('INFO', $id)
                    return
                        $exptit:col/id($id)//t:title[@type = 'full']/text()
                else
                    if (starts-with($titleMe, 'http')) then
                        (:                it is a URI, but not ours   :)
                        $titleMe
                        (:                perhaps it is just an identifier.... try to get the full title and if you do not find it, return what was submitted:)
                    else
                        let $title := $exptit:col/id($titleMe)//t:title[@type = 'full']/text()
                        return
                            if (string-length($title) ge 1) then
                                $title
                            else
                                $titleMe
};
