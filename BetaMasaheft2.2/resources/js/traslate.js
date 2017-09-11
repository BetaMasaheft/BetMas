$(document).ready(function () {
    $('#textinput').on("change paste", function () {
        
        var transcriptions = {
            "ä": "a", "a": "ā", "ṣ́": "ḍ", "ˀ": "ʾ", "ˁ": "ʿ"
        };
        var vowels =[ "a", "e", "i", "o", "u", "ǝ", "Ǝ", "A", "E", "I", "O", "U"];
        
        
        var prepositions =[ "wa", "Wa", "ba", "Ba", "ya", "Ya", "za", "Za", "la", "La", "ka", "Ka", "ʾǝm"];
        
        var input = this.value;
        //console.log(this.value);
        
        
        
        // slice in single words variable transcribed and check each for prepositions
        
        var list = input.split(" ");
        var listlength = list.length
        //console.log(list)
        
        //console.log(listlength)
        
        var transcribedpreposition = "";
        
        // loop through list of transcrbed words
        for (var i = 0; i < listlength; i++) {
           // console.log(list[i]);
            var length = list[i].length
            //console.log(length)
            var word = list[i]
          //  console.log(word)
            var transcribed = "";
            
            //loop through letters of each word
            for (var l = 0; l < length; l++) {
                var letter = word[l];
             //   console.log(letter)
                // if the first letter is a vowel add ayn
                if ((l === 0) && (vowels.includes(letter))) {
                    transcribed += "ʾ";
                };
                if (letter in transcriptions) {
                 if ((l === 0) && (letter =='a')) {
                      transcribed += letter;
                 }
                 else{
                    transcribed += transcriptions[letter];}
                } else {
                    transcribed += letter;
                };
               // console.log(transcribed);
                };
                
                //word check if it begins with one of the values in a prepositions array
                
                //three letters prepositions
                if (prepositions.includes(transcribed.substring(0, 3))) {
                  //  console.log(transcribed.substring(0, 3));
                    
                    // substitute contents
                    
                    var preposplit = transcribed.substring(0, 3) + "-" + transcribed.substring(3);
                    
                    // ask confirmation
                    if (confirm("Is this " + preposplit + " ? click ok to confirm, cancel to print " + transcribed + " instead.") == true) {
                   // var capitalized = capitalizeFirstLetter(transcribed.substring(0, 2)) + "-" + capitalizeFirstLetter(transcribed.substring(2));
                        //if (confirm('should'+ preposplit +' have capital letters like ' + capitalized + '?') == true){
                        //ask if to capitalize first letters
                          //   transcribedpreposition += capitalized ;
                       // } else {
                        transcribedpreposition += preposplit + ' ';
                    //} 
                    }else {
                        // if no print value
                        transcribedpreposition += transcribed + ' ';
                    };
                    
                    //     if does not match print value
                }
                else {
                
                //two letters prepositions
                if (prepositions.includes(transcribed.substring(0, 2))) {
                  //  console.log(transcribed.substring(0, 2));
                    
                    // substitute contents
                    
                    // check if the third and fourth are consonants == they are not in the vowels array, in this case do not ask. 
                    if((vowels.includes(transcribed.charAt(2)) === false) && (vowels.includes(transcribed.charAt(3)) === false)){
                    
                    transcribedpreposition += transcribed + ' ';
                 
                 //     if does not match print value
                } else {
                     var preposplit = transcribed.substring(0, 2) + "-" + transcribed.substring(2);
                    
                    // ask confirmation
                    if (confirm("Is this " + preposplit + " ? click ok to confirm, cancel to print " + transcribed + " instead.") == true) {
                   // var capitalized = capitalizeFirstLetter(transcribed.substring(0, 2)) + "-" + capitalizeFirstLetter(transcribed.substring(2));
                        //if (confirm('should'+ preposplit +' have capital letters like ' + capitalized + '?') == true){
                        //ask if to capitalize first letters
                          //   transcribedpreposition += capitalized ;
                       // } else {
                        transcribedpreposition += preposplit + ' ';
                    //} 
                    }else {
                        // if no print value
                        transcribedpreposition += transcribed + ' ';
                    };
                    
                };
                } else {
                    transcribedpreposition += transcribed + ' '
                };
                
                };
            
        };
        //it with capitalized preposition, hyphen and capitalize following part.
        
      //  console.log(transcribedpreposition)
        var result = transcribedpreposition;
        $("#result").text(result);
    });
    
    new Clipboard('.btn');
});
function capitalizeFirstLetter(string) {
    return string.charAt(0).toUpperCase() + string.slice(1);
}