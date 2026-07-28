xquery version "3.0";

module namespace r = "http://joewiz.org/ns/xquery/roman-numerals";
(: code by Joe Wicentowski 
  from https://gist.github.com/joewiz/228e9cc174694e146cc8
 :)
(:  Converts standard Roman numerals to integers. 
    Handles additive and subtractive but not double subtractive. 
    Case insensitive.
    Doesn't attempt to validate a numeral other than a naïve character check. 
    See discussion of standard modern Roman numerals at http://en.wikipedia.org/wiki/Roman_numerals.
    Adapted from an XQuery 1.0 module at 
    https://github.com/subugoe/ropen-backend/blob/master/src/main/xquery/queries/modules/roman-numerals.xqm
:)

declare function r:roman-numeral-to-integer($input as xs:string) as xs:integer {
    let $characters := string-to-codepoints(upper-case($input)) ! codepoints-to-string(.)
    let $character-to-integer := 
        function($character as xs:string) { 
            switch ($character)
                case "I" return 1
                case "V" return 5
                case "X" return 10
                case "L" return 50
                case "C" return 100
                case "D" return 500
                case "M" return 1000
                default return error(xs:QName('roman-numeral-error'), concat('Invalid input: ', $input, '. Valid Roman numeral characters are I, V, X, L, C, D, and M. This function is case insensitive.'))
            }
    let $numbers := $characters ! $character-to-integer(.)
    let $values := 
        for $number at $n in $numbers
        return 
            if ($number < $numbers[position() = $n + 1]) then 
                (0 - $number) (: Handles subtractive principle of Roman numerals. :)
            else 
                $number
    return 
        sum($values)
};