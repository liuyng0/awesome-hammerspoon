#!/usr/bin/osascript

const TABS_FILE = "~/vif/chrome_incognito.gpg";
const GPG_PUB_IDENTITY = "24AEDD124AC59CF2F2EFF136B6AE2801ADC719BA";

function run(cmd_args) {
    var args = JSON.parse(cmd_args);
    let operation = args["operation"];

    return operate(operation, cmd_args);
}

function operate(operation, args) {
    if (operation == "save") {
        return saveIncognitoWindowTabs();
    } else if (operation == "reload") {
        return reloadIncognitoWindowTabs();
    } else {
        throw "unsupported operation";
    }
}

function saveIncognitoWindowTabs() {
	  var chrome = Application('Google Chrome');
	  var wins = chrome.windows;

	  let chrome_tabs = [];
    for (var i = 0; i < wins.length; i++) {
        var win = wins.at(i);
        if (win.mode() != 'incognito') {
            continue;
        }
        var tabs = [];
        for (var j = 0; j < win.tabs.length; j++) {
            var tab = win.tabs.at(j);
            tabs.push({"title": tab.title(), "url": tab.url()});
        }
		    chrome_tabs.push({"windowId": win.id(), "windowName": win.name(), "mode": win.mode(), "tabs": tabs});
    }
	  var json_stringified = JSON.stringify(chrome_tabs);
    encrypt(json_stringified, TABS_FILE, GPG_PUB_IDENTITY);
}

function runAndGetOutput(args) {
    var app = Application.currentApplication();
    app.includeStandardAdditions = true;
    console.log(`run commands: ${args}`);
    return app.doShellScript(args);
}

function encrypt(str, file, gpg_identity) {
    var base64_str = Base64.encode(str);
    runAndGetOutput(`echo ${base64_str} | gpg --encrypt -r ${gpg_identity} --armor > ${file}`);
}

function decryptAsString(file) {
    var result = runAndGetOutput(`gpg --decrypt ${file}`);
    return Base64.decode(result);
}

function openTabs(tabs) {
    var tabs_as_string = tabs.join(',');
    // console.log("tabs_as_string: " + tabs_as_string);
    runAndGetOutput(`./OpenIncognitoTab.applescript "${tabs_as_string}"`);
}

function reloadIncognitoWindowTabs() {
    var raw_str = decryptAsString(TABS_FILE);
    // console.log("raw_str is:" + raw_str);
    var window_tabs = JSON.parse(raw_str);
    for (index in window_tabs) {
        // console.log(window_tabs[index]);
        var wtab = window_tabs[index];
        tabs = [];
        for (index2 in wtab.tabs) {
           tabs.push(wtab.tabs[index2].url);
        }
        openTabs(tabs);
        // console.log(`window: ${wtab.windowName}, tabs: ${wtab.tabs}`);
    }
}


/**
 *
 *  Base64 encode / decode
 *  http://www.webtoolkit.info/
 *
 **/
var Base64 = {

    // private property
    _keyStr : "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/=",

    // public method for encoding
    encode : function (input) {
        var output = "";
        var chr1, chr2, chr3, enc1, enc2, enc3, enc4;
        var i = 0;

        input = Base64._utf8_encode(input);

        while (i < input.length) {

            chr1 = input.charCodeAt(i++);
            chr2 = input.charCodeAt(i++);
            chr3 = input.charCodeAt(i++);

            enc1 = chr1 >> 2;
            enc2 = ((chr1 & 3) << 4) | (chr2 >> 4);
            enc3 = ((chr2 & 15) << 2) | (chr3 >> 6);
            enc4 = chr3 & 63;

            if (isNaN(chr2)) {
                enc3 = enc4 = 64;
            } else if (isNaN(chr3)) {
                enc4 = 64;
            }

            output = output +
                this._keyStr.charAt(enc1) + this._keyStr.charAt(enc2) +
                this._keyStr.charAt(enc3) + this._keyStr.charAt(enc4);

        }

        return output;
    },

    // public method for decoding
    decode : function (input) {
        var output = "";
        var chr1, chr2, chr3;
        var enc1, enc2, enc3, enc4;
        var i = 0;

        input = input.replace(/[^A-Za-z0-9\+\/\=]/g, "");

        while (i < input.length) {

            enc1 = this._keyStr.indexOf(input.charAt(i++));
            enc2 = this._keyStr.indexOf(input.charAt(i++));
            enc3 = this._keyStr.indexOf(input.charAt(i++));
            enc4 = this._keyStr.indexOf(input.charAt(i++));

            chr1 = (enc1 << 2) | (enc2 >> 4);
            chr2 = ((enc2 & 15) << 4) | (enc3 >> 2);
            chr3 = ((enc3 & 3) << 6) | enc4;

            output = output + String.fromCharCode(chr1);

            if (enc3 != 64) {
                output = output + String.fromCharCode(chr2);
            }
            if (enc4 != 64) {
                output = output + String.fromCharCode(chr3);
            }

        }

        output = Base64._utf8_decode(output);

        return output;

    },

    // private method for UTF-8 encoding
    _utf8_encode : function (string) {
        string = string.replace(/\r\n/g,"\n");
        var utftext = "";

        for (var n = 0; n < string.length; n++) {

            var c = string.charCodeAt(n);

            if (c < 128) {
                utftext += String.fromCharCode(c);
            }
            else if((c > 127) && (c < 2048)) {
                utftext += String.fromCharCode((c >> 6) | 192);
                utftext += String.fromCharCode((c & 63) | 128);
            }
            else {
                utftext += String.fromCharCode((c >> 12) | 224);
                utftext += String.fromCharCode(((c >> 6) & 63) | 128);
                utftext += String.fromCharCode((c & 63) | 128);
            }

        }

        return utftext;
    },

    // private method for UTF-8 decoding
    _utf8_decode : function (utftext) {
        var string = "";
        var i = 0;
        var c = c1 = c2 = 0;

        while ( i < utftext.length ) {

            c = utftext.charCodeAt(i);

            if (c < 128) {
                string += String.fromCharCode(c);
                i++;
            }
            else if((c > 191) && (c < 224)) {
                c2 = utftext.charCodeAt(i+1);
                string += String.fromCharCode(((c & 31) << 6) | (c2 & 63));
                i += 2;
            }
            else {
                c2 = utftext.charCodeAt(i+1);
                c3 = utftext.charCodeAt(i+2);
                string += String.fromCharCode(((c & 15) << 12) | ((c2 & 63) << 6) | (c3 & 63));
                i += 3;
            }

        }

        return string;
    }
}
