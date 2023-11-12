#!/usr/bin/osascript

function run(cmd_args) {
  var args = JSON.parse(cmd_args);
  let windowId = args["windowId"];
  let tabTitle = args["tabTitle"];
  let operation = args["operation"];

  if (operation == ":getTabs") {
    return getWindows();
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
          win.activeTabIndex = j + 1;
          chrome.activate();
        }
        return;
      }
    }
  }
}

class Window {
  constructor(windowId, tabs) {
    this.windowId = windowId;
    this.tabs = tabs;
  }
}

class Tab {
  constructor(title, url) {
    this.title = title;
    this.url = url;
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
function getWindows() {
  var chrome = Application('Google Chrome');
  var wins = chrome.windows;

  let chrome_tabs = [];
  for (var i = 0; i < wins.length; i++) {
    var win = wins.at(i);
    var tabs = [];
    for (var j = 0; j < win.tabs.length; j++) {
      var tab = win.tabs.at(j);
      tabs.push(new Tab(tab.title(), tab.url()))
    }
    chrome_tabs.push(new Window(win.id(), tabs))
  }
  return JSON.stringify(chrome_tabs);
}
