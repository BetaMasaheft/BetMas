$(document).ready(function () {

$(".ugarit").on('click', function () {
var workid = $(this).data('textid');
var number = $(this).data('currentid');
var ugarit = 'http://ugarit.ialigner.com/api.php'
var password = '&u=BetaMasaheft&p=3et4M4s4heft'
var getText = "/api/dts/text/" + workid + '/' + number ; // this is the base for all calls here.

/*on click query the api and send to ugarit reference and text */
$.getJSON(getText, function (d) {
var ugaritplusparameters = ugarit + '?id='  + d["0"].id +  '&section='  + number + password
console.log(ugaritplusparameters)     
/*            window.location = ugaritplusparameters */
        });
        
/*        check ugarit for an alignment of this text 
if there is an alignment provide in .ugaritcontrols also an SEE and and EDIT 
button beside the one with create alignment


* */

});
});