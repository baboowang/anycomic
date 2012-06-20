var anycomic_server = 'http://127.0.0.1:3000';

function is_server_alive()
{
    var ping_url = anycomic_server + '/api/ping'; 
}

function setAnyComicIcon(tabId, url)
{
    var monitor_urls = {
        'bengou.com' : /\d+\/\w+\/index\.html/,
        'imanhua.com' : /comic\/\d+\/?$/,
        'u17.com' : /comic\/\d+\.html/ 
    };

    var domain = (url.match(/\w+\.com/i) || [''])[0].toLowerCase();
    
    if ( ! monitor_urls[domain] || ! monitor_urls[domain].test(url)) {
        chrome.pageAction.hide(tabId); 
        return;
    }
    chrome.pageAction.show(tabId);
}

chrome.pageAction.onClicked.addListener(function(tab) {
    var book_url = '/book?url=' + encodeURIComponent(tab.url); 
        add_url = anycomic_server + '/book/add?url='
                + encodeURIComponent(tab.url) + '&redirect_uri='
                + encodeURIComponent(book_url);

    chrome.tabs.update(tab.id, {url : add_url});
});

chrome.tabs.onSelectionChanged.addListener(function(tabId, selectInfo) {
    chrome.tabs.get(tabId, function(tab) {
        setAnyComicIcon(tabId, tab.url);
    });
});
chrome.tabs.onUpdated.addListener(function(tabId, changeInfo, tab) {
    if (changeInfo.status == "complete") {
        chrome.tabs.getSelected(null, function(selectedTab) {
            if (selectedTab.id == tab.id)
                setAnyComicIcon(tab.id, tab.url);
        });
    }
});
