$(function () {
    
    var lang = "en";
    $.keyboard.language[lang].comboRegex = /([`\'~\^\"a-z0-9\{\}\[\]\|<>])([a-z0-9_\-\.\|`\'~\^\"!,=])/mig;
    $.keyboard.altKeys = {
        'a': '\u02be \u1ea1 \u00e0 \u00e1 \u00e3 \u00e2 \u00e4 \u0101 \u1360',
        'A': '\u02bf \u0100 \u00c0 \u00c1 \u00c3 \u00c4 \u00c2',
        'e': '\u01dd \u0113 \u1367 \u00e8 \u00e9 \u1ebd \u00eb \u00ea',
        'E': '\u018e \u0112 \u00c8 \u00c9 \u1ebc \u00cb \u00ca',
        'i': '\u00ec \u00ed \u0129 \u00ef \u00f6 \u00ee',
        'I': '\u00cc \u00cd \u0128 \u00cf \u00ce',
        'o': '\u00f2 \u00f3 \u00f5 \u00f4',
        'O': '\u00d2 \u00d3 \u00d5 \u00d6 \u00d4',
        'u': '\u00f9 \u00fa \u0169 \u00fc \u00fb',
        'U': '\u00d9 \u00da \u0168 \u00dc \u00db',
        '\u1200': '\u1201 \u1202 \u1203 \u1204 \u1205 \u1206 \u1207 \u1e2b \u1e25',
        "\u1208": '\u1209 \u120a \u120b \u120c \u120d \u120e \u120F',
        "\u1210": '\u1211 \u1212 \u1213 \u1214 \u1215 \u1216 \u1217 \u1e2a',
        "\u1218": '\u1219 \u121a \u121b \u121c \u121d \u121e \u121F',
        "\u1220": '\u1221 \u1222 \u1223 \u1224 \u1225 \u1226 \u1227 \u1e62 \u0160 \u015A',
        "\u1228": '\u1229 \u122a \u122b \u122c \u122d \u122e \u122F',
        "\u1230": '\u1231 \u1232 \u1233 \u1234 \u1235 \u1236 \u1237 \u1e63 \u0161 \u015b',
        "\u1238": '\u1239 \u123a \u123b \u123c \u123d \u123e \u123F',
        "\u1240": '\u1241 \u1242 \u1243 \u1244 \u1245 \u1246 \u1247',
        "\u1260": '\u1261 \u1262 \u1263 \u1264 \u1265 \u1266 \u1267 \u1363',
        "\u1268": '\u1269 \u126A \u126B \u126C \u126D \u126E \u126F',
        "\u1270": '\u1271 \u1272 \u1273 \u1274 \u1275 \u1276 \u1277 \u1e6d',
        "\u1278": '\u1279 \u127a \u127b \u127c \u127d \u127e \u127F \u010d\u0323 \u010d \u1364',
        "\u1280": '\u1281 \u1282 \u1283 \u1284 \u1285 \u1286 \u1287',
        "\u1290": '\u1291 \u1292 \u1293 \u1294 \u1295 \u1296 \u1297 \u00f1',
        "\u1298": '\u1299 \u129a \u129b \u129c \u129d \u129e \u129F \u00d1',
        "\u12a0": '\u12a1 \u12a2 \u12a3 \u12a4 \u12a5 \u12a6 \u12A7',
        "\u12a8": '\u12a9 \u12aa \u12ab \u12ac \u12ad \u12ae \u12AF',
        "\u12b8": '\u12b9 \u12ba \u12bb \u12bc \u12bd \u12be',
        "\u12c8": '\u12c9 \u12ca \u12cb \u12cc \u12cd \u12ce \u12CF \u02b7',
        "\u12d0": '\u12d1 \u12d2 \u12d3 \u12d4 \u12d5 \u12d6',
        "\u12d8": '\u12d9 \u12da \u12db \u12dc \u12dd \u12de \u12DF \u017e',
        "\u12e0": '\u12e1 \u12e2 \u12e3 \u12e4 \u12e5 \u12e6 \u12E7 \u017d',
        "\u12e8": '\u12e9 \u12ea \u12eb \u12ec \u12ed \u12ee \u12EF \u1ef3 \u00fd \u1ef9 \u00ff \u0177',
        "\u12f0": '\u12f1 \u12f2 \u12f3 \u12f4 \u12f5 \u12f6 \u12F7 \u1e0d \u1366',
        "\u12F8": '\u12F9 \u12FA \u12FB \u12FC \u12FD \u12FE \u12FF',
        "\u1300": '\u1301 \u1302 \u1303 \u1304 \u1305 \u1306 \u1307 \u1e0c',
        "\u1308": '\u1309 \u130a \u130b \u130c \u130d \u130e \u130F \u01e7',
        "\u1318": '\u1319 \u131a \u131b \u131c \u131d \u131e \u131F \u01e6',
        "\u1320": '\u1321 \u1322 \u1323 \u1324 \u1325 \u1326 \u1327 \u1e6c',
        "\u1328": '\u1329 \u132a \u132b \u132c \u132d \u132e \u132F',
        "\u1330": '\u1331 \u1332 \u1333 \u1334 \u1335 \u1336 \u1337 \u1e57',
        "\u1338": '\u1339 \u133a \u133b \u133c \u133d \u133e \u133F',
        "\u1340": '\u1341 \u1342 \u1343 \u1344 \u1345 \u1346 \u1347',
        "\u1348": '\u1349 \u134a \u134b \u134c \u134d \u134e \u134F \u1368',
        "\u1350": '\u1351 \u1352 \u1353 \u1354 \u1355 \u1356 \u1357 \u1E56',
        "\u1250": '\u1251 \u1252 \u1253 \u1254 \u1255 \u1256',
        "\u1248": '\u124a \u124b \u124c \u124d',
        "\u1288": '\u128a \u128b \u128c \u128d',
        "\u12b0": '\u12b2 \u12b3 \u12b4 \u12b5',
        "\u1310": '\u1312 \u1313 \u1314 \u1315',
        "\u1380": '\u1381 \u1382 \u1383',
        "\u1384": '\u1385 \u1386 \u1387',
        "\u1388": '\u1389 \u138A \u138B',
        "\u138C": '\u138D \u138E \u138F',
        'Y': '\u1ef2 \u00dd \u1ef8 \u0178 \u0176',
        // action keys the "!!" makes the button get the "ui-state-active"
        // (set by the css.buttonActive option)
        'enter': '{!!clear} {!!a} {!!c}'
    };
    
    $('.diacritics').keyboard({
        openOn: '',
        position: {
            // null (attach to input/textarea) or a jQuery object (attach elsewhere)
            of: null,
            my: 'center top',
            at: 'center top',
            // at2 is used when "usePreview" is false (centers keyboard at the bottom
            // of the input/textarea)
            at2: 'center bottom',
            collision: 'flipfit flipfit'
        },
        layout: 'custom',
        customLayout: {
            'normal':[
            '\u1369 \u136A \u136B \u136C \u136D \u136E \u136F \u1370 \u1371 \u1365',
            '\u1240 \u12c8 \u1228 \u1270 \u12e8 \u1330 \u1248 \u1288',
            '\u1230 \u12f0 \u1348 \u1308 \u1200 \u1338 \u12a8 \u1208 \u12a0',
            '{shift} \u12d8 \u1280 \u1278 \u1238 \u1260 \u1290 \u1218 \u1361 \u1362 {shift}',
            '{accept} {alt} {space} {alt} {cancel}'],
            'shift':[
            '\u1372 \u1373 \u1374 \u1375 \u1376 \u1377 \u1378 \u1379 \u137A \u137B \u137C',
            '\u1250 \u12d0 \u018e \u122f \u1320 Y \u1350 \u1310 \u12b0 \u1384',
            '\u0101 \u1220 \u1300 \u1358 \u1318 \u1210 \u1340 \u12b8 \u12f8 \u12A5\u130D\u12DA\u12A0\u1265\u1214\u122D\u1361 ',
            '{shift} \u12e0 \u1359 \u1328 \u135A \u1268 \u1298 \u1380 \u1388 \u138C  {shift}',
            '{accept} {alt} {space} {alt} {cancel}'],
            'alt':[
            '` 1 2 3 4 5 6 7 8 9 0 - = {bksp}',
            '{tab} q \u02b7 e r t y u i o \u1e57 [ ] \\',
            'a \u0161 d f \u01e7 \u1e2b j k l ; \u02be {enter}',
            '{shift} \u017e x \u010d\u0323 \u010d b \u00f1 m , . / {shift}',
            '{accept} {alt} {space} {alt} {cancel}'],
            'alt-shift':[
            '~ ! @ # $ % ^ & * ( ) _ + {bksp}',
            '{tab} Q W E R T Y U I O \u1E56 { } |',
            'A \u0160 D F \u01e6 \u1e2a J K L : \u02bf {enter}',
            '{shift} \u017d X \u010c\u0323 \u010c B \u00d1 M < > ? {shift}',
            '{accept} {alt} {space} {alt} {cancel}']
        },
        language: lang,
        // Added here as an example on how to add combos
        combos: {
            // a first order
            // u second order
            // i third order
            // A fourth order
            // E fifth order
            // e sixth order
            // o seventh order
            // 1 grave
            // 2 acute  cedilla
            // 3 tilde
            // 4 breve
            // 5 circle above
            // 6 dot above
            // 7 pipetta
            // 8 circle below
            // 9 umlaut/trema
            // . dot below
            // - long
            // = circumflex
            // , punctuation signs
            
            a: {
                a: '\u02be', '.': '\u1ea1', 1: "\u00e0", 2: "\u00e1", 3: "\u00e3", '=': "\u00e2", 9: "\u00e4", '-': "\u0101", ',': '\u1360'
            },
            A: {
                A: '\u02bf', '-': "\u0100", 1: "\u00c0", 2: "\u00c1", 3: "\u00c3", 9: "\u00c4", '=': "\u00c2"
            },
            e: {
                e: '\u01dd', '-': "\u0113", ',': '\u1367', 1: "\u00e8", 2: "\u00e9", 3: "\u1ebd", 9: "\u00eb", '=': "\u00ea"
            },
            E: {
                E: '\u018e', '-': "\u0112", 1: "\u00c8", 2: "\u00c9", 3: "\u1ebc", 9: "\u00cb", '=': "\u00ca"
            },
            i: {
                1: "\u00ec", 2: "\u00ed", 3: "\u0129", 9: "\u00ef", 9: "\u00f6", '=': "\u00ee"
            },
            I: {
                1: "\u00cc", 2: "\u00cd", 3: "\u0128", 9: "\u00cf", '=': "\u00ce"
            },
            o: {
                1: "\u00f2", 2: "\u00f3", 3: "\u00f5", '=': "\u00f4"
            },
            O: {
                1: "\u00d2", 2: "\u00d3", 3: "\u00d5", 9: "\u00d6", '=': "\u00d4"
            },
            u: {
                1: "\u00f9", 2: "\u00fa", 3: "\u0169", 9: "\u00fc", '=': "\u00fb"
            },
            U: {
                1: "\u00d9", 2: "\u00da", 3: "\u0168", 9: "\u00dc", '=': "\u00db"
            },
            'h': {
                a: "\u1200", u: "\u1201", i: "\u1202", A: "\u1203", E: "\u1204", e: "\u1205", o: "\u1206", '!': '\u1207', '_': '\u1e2b', '.': '\u1e25'
            },
            "l": {
                a: "\u1208", u: "\u1209", i: "\u120a", A: "\u120b", E: "\u120c", e: "\u120d", o: "\u120e", '!': '\u120F'
            },
            "H": {
                a: "\u1210", u: "\u1211", i: "\u1212", A: "\u1213", E: "\u1214", e: "\u1215", o: "\u1216", '!': '\u1217', '_': '\u1e2a'
            },
            "m": {
                a: "\u1218", u: "\u1219", i: "\u121a", A: "\u121b", E: "\u121c", e: "\u121d", o: "\u121e", '!': '\u121F'
            },
            "S": {
                a: "\u1220", u: "\u1221", i: "\u1222", A: "\u1223", E: "\u1224", e: "\u1225", o: "\u1226", '!': '\u1227', '.': '\u1e62', '|': '\u0160', 6: "\u015A"
            },
            "r": {
                a: "\u1228", u: "\u1229", i: "\u122a", A: "\u122b", E: "\u122c", e: "\u122d", o: "\u122e", '!': '\u122F'
            },
            "s": {
                a: "\u1230", u: "\u1231", i: "\u1232", A: "\u1233", E: "\u1234", e: "\u1235", o: "\u1236", '!': '\u1237', '.': '\u1e63', '|': '\u0161', 6: "\u015b"
            },
            "v": {
                a: "\u1238", u: "\u1239", i: "\u123a", A: "\u123b", E: "\u123c", e: "\u123d", o: "\u123e", '!': '\u123F'
            },
            "q": {
                a: "\u1240", u: "\u1241", i: "\u1242", A: "\u1243", E: "\u1244", e: "\u1245", o: "\u1246", '!': '\u1247'
            },
            "b": {
                a: "\u1260", u: "\u1261", i: "\u1262", A: "\u1263", E: "\u1264", e: "\u1265", o: "\u1266", '!': '\u1267', ',': '\u1363'
            },
            "B": {
                a: "\u1268", u: "\u1269", i: "\u126A", A: "\u126B", E: "\u126C", e: "\u126D", o: "\u126E", '!': '\u126F'
            },
            "t": {
                a: "\u1270", u: "\u1271", i: "\u1272", A: "\u1273", E: "\u1274", e: "\u1275", o: "\u1276", '!': '\u1277', '.': '\u1e6d'
            },
            "c": {
                a: "\u1278", u: "\u1279", i: "\u127a", A: "\u127b", E: "\u127c", e: "\u127d", o: "\u127e", '!': '\u127F', '_': '\u010d\u0323', '|': '\u010d', ',': '\u1364'
            },
            "x": {
                a: "\u1280", u: "\u1281", i: "\u1282", A: "\u1283", E: "\u1284", e: "\u1285", o: "\u1286", '!': '\u1287'
            },
            "n": {
                a: "\u1290", u: "\u1291", i: "\u1292", A: "\u1293", E: "\u1294", e: "\u1295", o: "\u1296", '!': '\u1297', 3: "\u00f1"
            },
            "N": {
                a: "\u1298", u: "\u1299", i: "\u129a", A: "\u129b", E: "\u129c", e: "\u129d", o: "\u129e", '!': '\u129F', 3: "\u00d1"
            },
            "'": {
                a: "\u12a0", u: "\u12a1", i: "\u12a2", A: "\u12a3", E: "\u12a4", e: "\u12a5", o: "\u12a6", '!': '\u12A7'
            },
            "k": {
                a: "\u12a8", u: "\u12a9", i: "\u12aa", A: "\u12ab", E: "\u12ac", e: "\u12ad", o: "\u12ae", '!': '\u12AF'
            },
            "K": {
                a: "\u12b8", u: "\u12b9", i: "\u12ba", A: "\u12bb", E: "\u12bc", e: "\u12bd", o: "\u12be"
            },
            "w": {
                a: "\u12c8", u: "\u12c9", i: "\u12ca", A: "\u12cb", E: "\u12cc", e: "\u12cd", o: "\u12ce", '!': '\u12CF', '=': "\u02b7"
            },
            "W": {
                a: "\u12d0", u: "\u12d1", i: "\u12d2", A: "\u12d3", E: "\u12d4", e: "\u12d5", o: "\u12d6"
            },
            "z": {
                a: "\u12d8", u: "\u12d9", i: "\u12da", A: "\u12db", E: "\u12dc", e: "\u12dd", o: "\u12de", '!': '\u12DF', '|': '\u017e'
            },
            "Z": {
                a: "\u12e0", u: "\u12e1", i: "\u12e2", A: "\u12e3", E: "\u12e4", e: "\u12e5", o: "\u12e6", '!': '\u12E7', '|': '\u017d'
            },
            "y": {
                a: "\u12e8", u: "\u12e9", i: "\u12ea", A: "\u12eb", E: "\u12ec", e: "\u12ed", o: "\u12ee", '!': '\u12EF', 1: "\u1ef3", 2: "\u00fd", 3: "\u1ef9", 9: "\u00ff", '=': "\u0177"
            },
            "d": {
                a: "\u12f0", u: "\u12f1", i: "\u12f2", A: "\u12f3", E: "\u12f4", e: "\u12f5", o: "\u12f6", '!': '\u12F7', '.': '\u1e0d', ',': '\u1366'
            },
            "L": {
                a: "\u12F8", u: "\u12F9", i: "\u12FA", A: "\u12FB", E: "\u12FC", e: "\u12FD", o: "\u12FE", '!': '\u12FF'
            },
            "D": {
                a: "\u1300", u: "\u1301", i: "\u1302", A: "\u1303", E: "\u1304", e: "\u1305", o: "\u1306", '!': '\u1307', '.': '\u1e0c'
            },
            "g": {
                a: "\u1308", u: "\u1309", i: "\u130a", A: "\u130b", E: "\u130c", e: "\u130d", o: "\u130e", '!': '\u130F', '|': '\u01e7'
            },
            "G": {
                a: "\u1318", u: "\u1319", i: "\u131a", A: "\u131b", E: "\u131c", e: "\u131d", o: "\u131e", '!': '\u131F', '|': '\u01e6'
            },
            "T": {
                a: "\u1320", u: "\u1321", i: "\u1322", A: "\u1323", E: "\u1324", e: "\u1325", o: "\u1326", '!': '\u1327', '.': '\u1e6c'
            },
            "C": {
                a: "\u1328", u: "\u1329", i: "\u132a", A: "\u132b", E: "\u132c", e: "\u132d", o: "\u132e", '!': '\u132F'
            },
            "p": {
                a: "\u1330", u: "\u1331", i: "\u1332", A: "\u1333", E: "\u1334", e: "\u1335", o: "\u1336", '!': '\u1337', 6: "\u1e57"
            },
            "j": {
                a: "\u1338", u: "\u1339", i: "\u133a", A: "\u133b", E: "\u133c", e: "\u133d", o: "\u133e", '!': '\u133F'
            },
            "J": {
                a: "\u1340", u: "\u1341", i: "\u1342", A: "\u1343", E: "\u1344", e: "\u1345", o: "\u1346", '!': '\u1347'
            },
            "f": {
                a: "\u1348", u: "\u1349", i: "\u134a", A: "\u134b", E: "\u134c", e: "\u134d", o: "\u134e", '!': '\u134F', ',': '\u1368'
            },
            "P": {
                a: "\u1350", u: "\u1351", i: "\u1352", A: "\u1353", E: "\u1354", e: "\u1355", o: "\u1356", '!': '\u1357', 6: "\u1E56"
            },
            "Q": {
                a: "\u1250", u: "\u1251", i: "\u1252", A: "\u1253", E: "\u1254", e: "\u1255", o: "\u1256"
            },
            "[": {
                a: "\u1248", i: "\u124a", A: "\u124b", E: "\u124c", e: "\u124d"
            },
            "]": {
                a: "\u1288", i: "\u128a", A: "\u128b", E: "\u128c", e: "\u128d"
            },
            "}": {
                a: "\u12b0", i: "\u12b2", A: "\u12b3", E: "\u12b4", e: "\u12b5"
            },
            "{": {
                a: "\u1310", i: "\u1312", A: "\u1313", E: "\u1314", e: "\u1315"
            },
            "M": {
                a: "\u1380", i: "\u1381", E: "\u1382", e: "\u1383"
            },
            "|": {
                a: "\u1384", i: "\u1385", E: "\u1386", e: "\u1387"
            },
            "<": {
                a: "\u1388", i: "\u1389", E: "\u138A", e: "\u138B"
            },
            ">": {
                a: "\u138C", i: "\u138D", E: "\u138E", e: "\u138F"
            },
            'Y': {
                1: "\u1ef2", 2: "\u00dd", 3: "\u1ef8", 9: "\u0178", '=': "\u0176"
            }
        }
        // example callback function
        // accepted : function(e, keyboard, el){ alert('The content "' + el.value + '" was accepted!'); }
    }).addAltKeyPopup({
        // time to hold down a button in milliseconds to trigger a popup
        holdTime: 750,
        // events triggered when popup is visible & hidden
        popupVisible: 'popup-visible',
        popupHidden: 'popup-hidden',
        // optional reposition popup callback function
        popupPosition: function (keyboard, data) {
            console.log(data);
            /*
            {
            $kb         : Keyboard element (jQuery object),
            $key        : Clicked key element (jQuery object),
            $popup      : Popup container (jQuery object),
            kbHeight    : Keyboard element outer height,
            kbWidth     : Keyboard element outer width,
            popupHeight : Popup container height,
            popupWidth  : Popup container width,
            popupLeft   : Popup container left position,
            popupTop    : Popup container top position
            }
            example (shift popup left 100px):
            data.$popup.css('left', data.popupLeft - 100);
             */
        }
    })
    // optional: use popup visible event to do something to the overlay,
    // popup container or buttons
    .on('popup-visible', function (keyboard) {
        // access the overlay from keyboard.altKeyPopup_$overlay
        // or keys container from keyboard.altKeyPopup_$overlay.find('.ui-keyboard-popup')
        // or keys from keyboard.altKeyPopup_$overlay.find('.ui-keyboard-button')
        var keyboard = $(this).data('keyboard');
        // reposition the popup - setting top to zero & left to zero will
        // overlap the preview input, if usePreview is true
        keyboard.altKeyPopup_$overlay.find('.ui-keyboard-popup').css({
            top: 0,
            left: 0
        });
    })
    // popup close
    .on('popup-hidden', function (keyboard) {
        // event fired when altkeypopup closes - added in v1.25.11
    }).addTyping({
        // if true, typing on real keyboard will not highlight keys on the keyboard
        showTyping: true,
        // prevent user typing WHILE using the typing simulator `.typeIn('foobar')`
        lockTypeIn: false,
        // change default simulated typing delay
        delay: 250
    });
    $('.kb').click(function () {
        var kb = $('.diacritics').getkeyboard().reveal();
    });
});