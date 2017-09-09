xquery version "3.0";

declare namespace t="http://www.tei-c.org/ns/1.0";

let $data-root := '/db/apps/BetMas/data'
let $doc := collection($data-root)//id('BNFet32')
let $id := string($doc/@xml:id)
return

  if ($doc//t:div[@type = 'edition']) then
                    <a
                        href="{('/text/' || $id)}"
                        target="_blank">text</a>
            else
                ()