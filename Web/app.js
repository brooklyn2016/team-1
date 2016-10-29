(function localFileVideoPlayer() {
	'use strict'
  var videoSources = new Array();
  videoSources[0] = 'videos/1.mp4';
  videoSources[1] = 'videos/2.mp4';
    
    document.getElementById("myVideo").setAttribute("src", videoSources[0])

function videoPlay() {
    document.getElementById("myVideo").load();
    document.getElementById("myVideo").play();
    document.getElementById("myVideo").setAttribute("src", videoSources[1]);
    document.getElementById("myVideo").load();
    document.getElementById("myVideo").play(); 
}
}
 
)()