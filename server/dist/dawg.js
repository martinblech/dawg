var css="#gb,#gba,.GY,[guidedhelpid=talkwithfriends],[guidedhelpid=appindicator_content],[role=main],[role=region]{display:none!important}";function ensureLoggedIn(){var e=setInterval(function(){var t=document.querySelector('a[href^="https://accounts.google.com/ServiceLogin"]');t&&(t.click(),clearTimeout(e))},200)}function ensureChatOpen(){var e=setInterval(function(){var t=document.querySelector('[id$="ChatRoster"]'),n=document.querySelector('[guidedhelpid="chat_mole_icon"]');n&&n.click(),t&&0!==t.clientHeight&&(t.parentElement.style.top=0,clearInterval(e),onChatOpen(),window.addEventListener("scroll",function(){t.parentElement.style.top=0}))},200)}function onChatOpen(){}function init(){csssetup(),ensureLoggedIn(),ensureChatOpen()}csssetup=function(){head=document.head||document.getElementsByTagName("head")[0],style=document.createElement("style"),style.type="text/css",style.styleSheet?style.styleSheet.cssText=css:style.appendChild(document.createTextNode(css)),head.appendChild(style)};