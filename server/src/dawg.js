csssetup = function() {
	head = document.head || document.getElementsByTagName( 'head' )[ 0 ];
	style = document.createElement( 'style' );
	style.type = 'text/css';
	if ( style.styleSheet ) {
			style.styleSheet.cssText = css;
	} else {
			style.appendChild( document.createTextNode( css ) );
	}
	head.appendChild( style );
};

function ensureLoggedIn() {
    var timerId = setInterval(function() {
        var loginButton = document.querySelector('a[href^="https://accounts.google.com/ServiceLogin"]');
        if (loginButton) {
            loginButton.click();
            clearTimeout(timerId);
        }
    }, 200);
}

function ensureChatOpen() {
    var timerId = setInterval(function() {
        var chatRoster = document.querySelector('[id$="ChatRoster"]');
        var chatOpenButton = document.querySelector('[guidedhelpid="chat_mole_icon"]');
        if (chatOpenButton) {
            chatOpenButton.click();
        }
        if (chatRoster && chatRoster.clientHeight !== 0) {
            chatRoster.parentElement.style.top = 0;
            clearInterval(timerId);
            onChatOpen();
            window.addEventListener('scroll', function() {
                chatRoster.parentElement.style.top = 0;
            });
        }
    }, 200);
}

function onChatOpen() {
}

function init() {

    csssetup();
    ensureLoggedIn();
    ensureChatOpen();

}
