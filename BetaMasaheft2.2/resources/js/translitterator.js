//transcriptional vowels
var vowels =[ "a", "u", "i", "ā", "e", "ǝ", "o", ""]
//fidel letters ordered according to official translitteration
var fidel =[ {
    letter: "h", realization:[ "ሀ", "ሁ", "ሂ", "ሃ", "ሄ", "ህ", "ሆ"]
}, {
    letter: "l", realization:[ "ለ", "ሉ", "ሊ", "ላ", "ሌ", "ል", "ሎ"]
}, {
    letter: "ḥ", realization:[ "ሐ", "ሑ", "ሒ", "ሓ", "ሔ", "ሕ", "ሖ"]
}, {
    letter: "m", realization:[ "መ", "ሙ", "ሚ", "ማ", "ሜ", "ም", "ሞ"]
}, {
    letter: "ś", realization:[ "ሠ", "ሡ", "ሢ", "ሣ", "ሤ", "ሥ", "ሦ"]
}, {
    letter: "r", realization:[ "ረ", "ሩ", "ሪ", "ራ", "ሬ", "ር", "ሮ"]
}, {
    letter: "s", realization:[ "ሰ", "ሱ", "ሲ", "ሳ", "ሴ", "ስ", "ሶ"]
}, {
    letter: "q", realization:[ "ቀ", "ቁ", "ቂ", "ቃ", "ቄ", "ቅ", "ቆ"]
}, {
    letter: "b", realization:[ "በ", "ቡ", "ቢ", "ባ", "ቤ", "ብ", "ቦ"]
}, {
    letter: "t", realization:[ "ተ", "ቱ", "ቲ", "ታ", "ቴ", "ት", "ቶ"]
}, {
    letter: "ḫ", realization:[ "ኀ", "ኁ", "ኂ", "ኃ", "ኄ", "ኅ", "ኆ"]
}, {
    letter: "n", realization:[ "ነ", "ኑ", "ኒ", "ና", "ኔ", "ን", "ኖ"]
}, {
    letter: "ʾ", realization:[ "አ", "ኡ", "ኢ", "ኣ", "ኤ", "እ", "ኦ"]
}, {
    letter: "k", realization:[ "ከ", "ኩ", "ኪ", "ካ", "ኬ", "ክ", "ኮ"]
}, {
    letter: "w", realization:[ "ወ", "ዉ", "ዊ", "ዋ", "ዌ", "ው", "ዎ"]
}, {
    letter: "ʿ", realization:[ "ዐ", "ዑ", "ዒ", "ዓ", "ዔ", "ዕ", "ዖ"]
}, {
    letter: "z", realization:[ "ዘ", "ዙ", "ዚ", "ዛ", "ዜ", "ዝ", "ዞ"]
}, {
    letter: "y", realization:[ "የ", "ዩ", "ዪ", "ያ", "ዬ", "ይ", "ዮ"]
}, {
    letter: "d", realization:[ "ደ", "ዱ", "ዲ", "ዳ", "ዴ", "ድ", "ዶ"]
}, {
    letter: "g", realization:[ "ገ", "ጉ", "ጊ", "ጋ", "ጌ", "ግ", "ጎ"]
}, {
    letter: "ṭ", realization:[ "ጠ", "ጡ", "ጢ", "ጣ", "ጤ", "ጥ", "ጦ"]
}, {
    letter: "ṗ", realization:[ "ጰ", "ጱ", "ጲ", "ጳ", "ጴ", "ጵ", "ጶ"]
}, {
    letter: "ṣ", realization:[ "ጸ", "ጹ", "ጺ", "ጻ", "ጼ", "ጽ", "ጾ"]
}, {
    letter: "ḍ", realization:[ "ፀ", "ፁ", "ፂ", "ፃ", "ፄ", "ፅ", "ፆ"]
}, {
    letter: "f", realization:[ "ፈ", "ፉ", "ፊ", "ፋ", "ፌ", "ፍ", "ፎ"]
}, {
    letter: "p", realization:[ "ፐ", "ፑ", "ፒ", "ፓ", "ፔ", "ፕ", "ፖ"]
}, {
    letter: "qʷ", realization:[ "ቈ", "", "ቊ", "ቋ", "ቌ", "ቍ", ""]
}, {
    letter: "ḫʷ", realization:[ "ኈ", "", "ኊ", "ኋ", "ኌ", "ኍ", ""]
}, {
    letter: "kʷ", realization:[ "ኰ", "", "ኲ", "ኳ", "ኴ", "ኵ", ""]
}, {
    letter: "gʷ", realization:[ "ጐ", "", "ጒ", "ጓ", "ጔ", "ጕ", ""]
}, {
    letter: "č", realization:[ "ቸ", "ቹ", "ቺ", "ቻ", "ቼ", "ች", "ቾ"]
},
{
    letter: "ŋ", realization:[ "ጘ", "ጙ", "ጚ", "ጛ", "ጜ", "ጝ", "ጞ"]
},
{
    letter: "ŋʷa", realization:[ "ⶓ", "", "ⶔ", "", "ⶕ", "ⶖ", ""]
}, {
    letter: "ǧ", realization:[ "ጀ", "ጁ", "ጂ", "ጃ", "ጄ", "ጅ", "ጆ"]
},
{
    letter: "č̣", realization:[ "ጨ", "ጩ", "ጪ", "ጫ", "ጬ", "ጭ", "ጮ"]
},
{
    letter: "q̲", realization:[ "ቐ", "ቑ", "ቒ", "ቓ", "ቔ", "ቕ", "ቖ"]
},
{
    letter: "ḵ", realization:[ "ኸ", "ኹ", "ኺ", "ኻ", "ኼ", "ኽ", "ኾ"]
},
{
    letter: "š", realization:[ "ሸ", "ሹ", "ሺ", "ሻ", "ሼ", "ሽ", "ሾ"]
},
{
    letter: "ñ", realization:[ "ኘ", "ኙ", "ኚ", "ኛ", "ኜ", "ኝ", "ኞ"]
},
{
    letter: "ž", realization:[ "ዠ", "ዡ", "ዢ", "ዣ", "ዤ", "ዥ", "ዦ"]
}]



$(document).on('ready', function () {
    
    // this functions take input in translitteration or fidel and return the other of the two.
    
    // input in fidel
    $("#inputfidel").on('change paste', function () {
        var translitt = ""
        var translitt1 = ""
        var input = $(this).val()
        var l = input.length
        var match = ""
        var match1 = ""
        // consider letter by letter
        for (var t = 0; t < l; t++) {
            var thelet = input[t]
            // check if it is a space and leave a space
            if (/\s/g.test(thelet)) {
                match += ' '
                match1 += ' '
            } else if (thelet != '፡' && thelet != '። ') {
                $.each(fidel, function (i, val) {
                    // check in each object in fidel
                    var position = $.inArray(thelet, val.realization);
                    if (position > -1) {
                        // if it is the first letter of a word (absolute first or preceded by space) then vocalize.
                        if ((position == 5) && ((t == 0) || (/\s/g.test(input[t -1])))) {
                            match1 += val.letter + vowels[position]
                            match += val.letter + vowels[position]
                        }
                        // if it is in the sixth order, provide two different imputs for match1 without shwa and match with it
                        else if (position == 5) {
                            match1 += val.letter
                            match += val.letter + vowels[position]
                        } else {
                            // if it is not the sixth order, always print also the corresponding vowel
                            match += val.letter + vowels[position]
                            match1 += val.letter + vowels[position]
                        }
                    }
                    //assumes there will be one match
                });
            }
        }
        //add all matches to the transliteration
        translitt += match
        var removeFinalShwas = " "
        // tokenize if there are more then one word the translitteration output and look into each of the words to remove the shwa at the end
        if (/\s/g.test(translitt)) {
            var toks = translitt.split(" ")
            var tokL
            for (var t = 0; t < tokL; t++) {
                var curTok = toks[t]
                console.log(curTok)
                // if the token ends in shwa, then slice it away, otherwise keep it. add back a space after the word
                if (curTok.endsWith("ǝ")) {
                    var curTokNSh = curTok.slice(0, -1)
                    removeFinalShwas += curTokNSh + ' '
                } else {
                    removeFinalShwas += curTok + ' '
                }
            }
        } else {
            // same as above, in case there is no tokenization taking place
            if (translitt.endsWith("ǝ")) {
                var curTokNSh = translitt.slice(0, -1)
                removeFinalShwas += curTokNSh + ' '
            } else {
                removeFinalShwas += translitt + ' '; 
            }
        }
        translitt1 += match1
        $("#resultTr").text(removeFinalShwas)
        $("#resultNoShwa").text(translitt1)
    });
    
    
    // input in translitteration
    $("#inputtranslitteration").on('change paste', function () {
        var translitt = ""
        var input = $(this).val()
        var l = input.length
        var units =[]
        // consider letter by letter
        // split to units consontants+vowel or space.
        var split = input.match(/(([ṭṗṣḍḫčḥśʿʾbcdfghlmnpqrstvzwyxk])\2?ʷ?\u0323?[aeiouāēǝ]?|\s+)/ig);
        var splitLen = split.length;
        //console.log(split)
        // the array should contain each unit
        console.log(split)
        // loops through the units
        
        for (var t = 0; t < splitLen; t++) {
            var let = split[t]
            var letL = let.length
            console.log(letL)
            var match = ""
            
            if (letL === 1) {
                if (/\s/g.test(let)) {
                    // if it is a space, leave a space
                    match = '፡ '
                    translitt += match
                } else {
                    // if the unit has one character, use the sixth order
                    $.each(fidel, function (i, val) {
                        var rels = val.realization
                        if (val.letter === let) {
                            match = rels[5]
                            translitt += match
                        }
                    });
                }
                
                // if the unit has two character
            } else if (letL === 2) {
                //isolate the consonant
                var cons = let.charAt(0)
                //isolate the vowel
                var vow = let.charAt(1)
                // get the position of the vowel
                var pos = $.inArray(vow, vowels);
                $.each(fidel, function (i, val) {
                    var rels = val.realization
                    // return the realization with that vowel by looking in the array the same position of the vowel (and hope the array is correct)
                    if (val.letter === cons) {
                        match = rels[pos]
                        translitt += match
                    }
                });
            } else {
                
                // if the unit has more than two character it is rather  something with an underdot or a high w... or a geminated
                if (let.charAt(0) == let.charAt(1)) {
                    // check for geminated and consider only first for match
                    var cons = let.charAt(0)
                    var vow = let.charAt(2)
                    var pos = $.inArray(vow, vowels);
                    $.each(fidel, function (i, val) {
                        var rels = val.realization
                        if (val.letter === cons) {
                            match = rels[pos]
                            translitt += match
                        }
                    });
                } else {
                    // otherways is a letter with small w or with underdot
                    var cons = let.substring(0, 2)
                    var vow = let.charAt(2)
                    var pos = $.inArray(vow, vowels);
                    $.each(fidel, function (i, val) {
                        var rels = val.realization
                        if (val.letter === cons) {
                            match = rels[pos]
                            translitt += match
                        }
                    });
                }
            }
            if (t == splitLen -1) {
                // add word separator
                match = '፡'
                translitt += match
            }
        }
        
        $("#resultTr").text(translitt)
    });
});