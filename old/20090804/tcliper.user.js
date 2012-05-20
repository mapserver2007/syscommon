// ==UserScript==
// @author           summer-lights
// @name             tcliper api
// @namespace        http://summer-lights.dyndns.ws/tcliper_api/
// @include          *
// @description      tcliper api
// @version          1.0.1
// ==/UserScript==
(function(w){
var KEYCODE = 113;
var SEND_TO = "http://summer-lights.dyndns.ws/tcliper_api/pl/tcliper.pl";
var API_KEY = "34a044d78e02208c57841ecf3516464f85d5543baa697e087c13c20887bd015c";

w.document.onkeypress = setKeyEvent;

function execExtract(){
	//Rangeを取得(Only Firefox)
	var range = {}, extract_text = "";
	try{
		range.obj = w.getSelection().getRangeAt(0);
		range.fragment = document.createDocumentFragment();
		range.html = document.createElement("span");
		range.html.appendChild(range.obj.cloneContents());
		extract_text = range.html.textContent;
	}
	catch(err){
		//alert(err);
	}

	return extract_text;
}

function sendClipData(title, url, comment){
	GM_xmlhttpRequest({
		method: "post",
		url: SEND_TO,
		headers: {
			"Content-Type": "application/x-www-form-urlencoded"
		},
		data: "title=" + title + "&url=" + url + "&comment=" + comment + "&apikey=" + API_KEY,
		onload: function(res){
			alert(res.responseText);
		},
		onerror: function(res){
			alert(res.status);
		}
	});
}

function setKeyEvent(e){
	var code = e.keyCode != 0 ? e.keyCode : e.charCode;
	if(code == KEYCODE){
		var title   = encodeURIComponent(document.getElementsByTagName("title")[0].innerHTML);
		var url     = encodeURIComponent(location.href);
		var comment = encodeURIComponent(execExtract()) || title;
		sendClipData(title, url, comment);
	}
	else{
		//return false;
	}
}

})(this.unsafeWindow || window);
