xquery version "3.1" encoding "UTF-8";
(:~
 : module used by text search query functions to provide alternative 
 : strings to the search, based on known homophones.
 : 
 : @author Pietro Liuzzo <pietro.liuzzo@uni-hamburg.de'>
 :)
module namespace all = "https://www.betamasaheft.uni-hamburg.de/BetMas/all";
import module namespace console = "http://exist-db.org/xquery/console";
declare namespace test="http://exist-db.org/xquery/xqsuite";
(:~
 : provided a string substitutes characters matching one by one, returning all possible combinations (but multiple times).
 : :)
declare function all:repl($query, $match, $sub)
{
(: take the string and make into a sequence eg. abcabc   :)
    let $seq :=
        for $ch in string-to-codepoints($query)
        return codepoints-to-string($ch)
(:        loop the sequence (a,b,c,a,b,c):)
    for $x in $seq
(:    get the position of the character in the sequence, a = (0, 3):)
    return
        if ($x = $match) then
         let $index := index-of($seq, $x)
         return
(:    loop each occurrence of that character to do the substitutions one by one in case it matches, 0 and 3 for the example:)
    for $i in $index
    
    return
(:        substitute only that occurence by removing it and adding the substitute in its place, so in the first loop, remove a and then add d before position 0:)
            let $rem := remove($seq, $i)
            let $add := insert-before($rem, $i, $sub)
            let $newstring := string-join($add, '')
(:          returns the string dbcabc and sends the same over again to this template.  :)
            return
           ($newstring,
           all:repl($newstring, $match, $sub))
            
        else
(:          there character does not match and the string is returned  :)
            string-join($seq, '')
            
(:            this generates an exponential number of options which are the same, but can then be filtered with distinct-values() :)
};

(:~
 : provided a string and a list of homophones, returns a sequence with al possible variants, excluding doubles by checking at each loop if the value is already there.
 : :)
declare function all:subs($query, $homophones, $mode) {
    let $all :=
    for $b in $homophones
    return
    for $q in $query return
        if (contains($q, $b)) then
            let $options := 
                    for $s in $homophones[. != $b]
                            return
                                (
                                distinct-values(all:repl($q, $b, $s)),
                                if ($mode = 'ws') then
                                    (replace($q, $b, ''))
                                     else()
                                )
             let $checkedoptions := 
                      for $o in $options 
                           return
                          if ($o = $query) then () else $o
            return
                $checkedoptions
        else
            ()
   let $queryAndAll := ($query, $all)
   return distinct-values($queryAndAll)
};


(:~
 : provided a string this function contains all known homophonoes and alternative writing for each letter.
 : it will loop through each homophone sequence and send the query string to the all:subs() to get all alternatives.
 : the sequence thus generated is passed on to the next possible substitutions.
 : the order in the function is not irrelevant. it will look first for the less common substitutions
 : :)
declare

 %test:arg("query", "ሠለሠ") %test:assertEquals("ሠለሠ ሰለሠ ሰለሰ ሠለሰ")

function all:substitutionsInQuery($query as xs:string*) {
    let $query-string := normalize-space($query)
    let $emphaticS := ('s','s', 'ḍ')
    let $query-string := all:subs($query-string, $emphaticS, 'normal')
 let $a := ('a','ä')
    let $query-string := all:subs($query-string, $a, 'normal')
        
    let $e := ('e','ǝ','ə','ē')
    let $query-string := all:subs($query-string, $e, 'normal')
    
     let $Ww:= ('w','ʷ')
    let $query-string := all:subs($query-string, $Ww, 'normal')
     
    (:Remove/ignore ayn and alef:)
    let $alay := ('ʾ', 'ʿ')
    let $query-string := all:subs($query-string, $alay, 'ws')
    
    (:  substitutions of homophones:)
    let $laringals14 := ('ሀ', 'ሐ', 'ኀ', 'ሃ', 'ሓ', 'ኃ')
    let $query-string := all:subs($query-string, $laringals14, 'normal')
    
   
    let $laringals2 := ('ሀ', 'ሐ', 'ኀ')
    let $query-string := all:subs($query-string, $laringals2, 'normal')
    let $laringals3 := ('ሂ', 'ሒ', 'ኂ')
    let $query-string := all:subs($query-string, $laringals3, 'normal')
    let $laringals4 := ('ሁ', 'ሑ', 'ኁ')
    let $query-string := all:subs($query-string, $laringals4, 'normal')
    let $laringals5 := ('ሄ', 'ሔ', 'ኄ')
    let $query-string := all:subs($query-string, $laringals5, 'normal')
    let $laringals6 := ('ህ', 'ሕ', 'ኅ')
    let $query-string := all:subs($query-string, $laringals6, 'normal')
    let $laringals7 := ('ሆ', 'ሖ', 'ኆ')
    let $query-string := all:subs($query-string, $laringals7, 'normal') 
    
    
  let $ssound := ('ሠ','ሰ')
    let $query-string :=   all:subs($query-string, $ssound, 'normal')
  let $ssound2 := ('ሡ','ሱ')
    let $query-string :=   all:subs($query-string, $ssound2, 'normal')   
  let $ssound3 := ('ሢ','ሲ')
    let $query-string :=   all:subs($query-string, $ssound3, 'normal')   
  let $ssound4 := ('ሣ','ሳ')
    let $query-string :=   all:subs($query-string, $ssound4, 'normal')   
  let $ssound5 := ('ሥ','ስ')
    let $query-string :=   all:subs($query-string, $ssound5, 'normal')    
  let $ssound6 := ('ሦ','ሶ')
    let $query-string :=   all:subs($query-string, $ssound6, 'normal')   
  let $ssound7 := ('ሤ','ሴ')
    let $query-string :=   all:subs($query-string, $ssound7, 'normal')  
   
        let $emphaticT1 := ('ጸ', 'ፀ')
    let $query-string := all:subs($query-string, $emphaticT1, 'normal')
       let $emphaticT2 := ('ጹ', 'ፁ')
    let $query-string := all:subs($query-string, $emphaticT2, 'normal')
        let $emphaticT3 := ('ጺ', 'ፂ')
    let $query-string := all:subs($query-string, $emphaticT3, 'normal')
        let $emphaticT4 := ('ጻ', 'ፃ')
    let $query-string := all:subs($query-string, $emphaticT4, 'normal')
        let $emphaticT5 := ('ጼ', 'ፄ')
    let $query-string := all:subs($query-string, $emphaticT5, 'normal')
        let $emphaticT6 := ('ጽ', 'ፅ')
    let $query-string := all:subs($query-string, $emphaticT6, 'normal')
        let $emphaticT7 := ('ጾ', 'ፆ')
    let $query-string := all:subs($query-string, $emphaticT7, 'normal')
    
      let $asounds14 :=   ('አ', 'ዐ', 'ኣ', 'ዓ')
    let $query-string := all:subs($query-string, $asounds14, 'normal')
    
    let $asounds2 := ('ኡ', 'ዑ')
    let $query-string := all:subs($query-string, $asounds2, 'normal')
    let $asounds3 := ('ኢ', 'ዒ')
    let $query-string := all:subs($query-string, $asounds3, 'normal')
    let $asounds5 := ('ኤ', 'ዔ')
    let $query-string := all:subs($query-string, $asounds5, 'normal')
    let $asounds6 := ('እ', 'ዕ')
    let $query-string := all:subs($query-string, $asounds6, 'normal')
    let $asounds7 := ('ኦ', 'ዖ')
    let $query-string := all:subs($query-string, $asounds7, 'normal') 
  
  (:let $query-string := 
  let $QUERY := 
  for $word in $query-string return if(matches($word, '^[aeiouAEIOU]')) then $word|| ' ʾ' || $word || ' ʿ' || $word else $word return $QUERY
:)
    
    return
        string-join($query-string, ' ')

};
