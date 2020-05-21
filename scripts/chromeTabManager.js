#!/usr/bin/osascript

function run(cmd_args) {
    var args = JSON.parse(cmd_args);
    let windowId = args["windowId"];
    let tabTitle = args["tabTitle"];
    let operation = args["operation"];

    if (operation == ":getTabs") {
        return getTabs();
    }
    tabOperationOn(operation, tabTitle, windowId);
}

function tabOperationOn(operation, tabTitle, windowId) {
    var chrome = Application('Google Chrome');
	  var wins = chrome.windows;

    for (var i = 0; i < wins.length; i++) {
        var win = wins.at(i);
        if (wins.at(i).id() != windowId) {
            continue;
        }

        var tabs = win.tabs;
        for (var j = 0; j < tabs.length; j++) {
            var tab = tabs.at(j);
            if (tab.title() == tabTitle) {
                if (operation == ":delete") {
                    tab.close();
                } else if (operation == ":switchTo") {
                    win.activeTabIndex = j+1;
                    chrome.activate();
                }
                return;
            }
        }
    }
}

// Return with
// {
//    "windowId": windowId
//    "tabs": [
//     {"title": title}
//     {"url": url}
//     ]
// }
function getTabs() {
	  var chrome = Application('Google Chrome');
	  var wins = chrome.windows;

	  let chrome_tabs = [];
    for (var i = 0; i < wins.length; i++) {
        var win = wins.at(i);
        var tabs = [];
        for (var j = 0; j < win.tabs.length; j++) {
            var tab = win.tabs.at(j);
            tabs.push({"title": tab.title(), "url": tab.url()});
        }
		    chrome_tabs.push({"windowId": win.id(), "tabs": tabs});
    }
	  return JSON.stringify(chrome_tabs);
}
