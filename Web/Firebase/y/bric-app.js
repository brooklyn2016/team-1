
// Initialize Firebase
var config = {
    apiKey: "AIzaSyDa9whWIEBgb7csrFTkcbPBL8useGgUIz8",
    authDomain: "bric-live-ii.firebaseapp.com",
    databaseURL: "https://bric-live-ii.firebaseio.com",
    storageBucket: "bric-live-ii.appspot.com",
    messagingSenderId: "1047090944642"
};
firebase.initializeApp(config);

var ref = firebase.database().ref().child("Events");

//
//function facebookAuth() {
//
//
//
//    // Initialize the FirebaseUI Widget using Firebase.
//    var ui = new firebaseui.auth.AuthUI(firebase.auth());
//    // The start method will wait until the DOM is loaded.
//
//
//    ui.start('#firebaseui-auth-container', {
//        'signInOptions': [
//            {
//                provider: firebase.auth.FacebookAuthProvider.PROVIDER_ID,
//                scopes: [
//                    'public_profile',
//                    'email'
//                ]
//            },
//        ]
//    });
//    
//    //document.location.href = "bric.html"
//
//}
function getDropdown() {
    ref.on('value', snap => {
        var someJSON = JSON.stringify(snap.val());
        var parse = JSON.parse(someJSON);
        var dropdown = document.getElementById("dropdown");
        for (var k in parse) {
            var someList = document.createElement("option");
            someList.text = k;
            dropdown.appendChild(someList);
            console.log(k);
        }
        $(function() {

            $('#dropdown').material_select();

        });
    })
}


function upload() {
    var uploader = document.getElementById("uploader");
    var fileButton = document.getElementById("file_input_file")

    var theCat = sessionStorage.getItem("category");
    fileButton.addEventListener('change', function(e) {
        var file = e.target.files[0];
        var storageref = firebase.storage().ref(theCat + "/" + file.name);
        var databaseref = firebase.database().ref("Events/" + theCat);
        var task = storageref.put(file);

        task.on('state_changed',

                function progress(snapshot) {
            var percentage = (snapshot.bytesTransferred / snapshot.totalBytes) * 100;
            uploader.value = percentage;
        },
                function error(err) {

        },
                function complete() {
            console.log("COMPLETED");


            var newFileName = file.name.slice(0, -4);
            //console.log(newFileName);
            storageref.getDownloadURL().then(function(url) {
                console.log(url);
                databaseref.child(newFileName).set(url);
            }).catch(function(error) {
                console.log(error);
            });
            //databaseref.child(newFileName).set(storageref.getDownloadURL())
        }

               );

    });
}

function loadPlayback() {
    var category = sessionStorage.getItem("category");
    var title = document.getElementById("title");
    title.innerHTML = category;
    //category = "fathers_day";
    var newRef = ref.child(category);
    var numVideosCount = 0;
    var videos = new Array();
    newRef.once('value').then(function(snapshot) {
        var hello = JSON.stringify(snapshot.val());
        var helloObj = JSON.parse(hello);

        for (var key in helloObj) {
            if (helloObj.hasOwnProperty(key)) {
                numVideosCount++;
                var currURL = helloObj[key];
                videos.push(currURL);
                console.log(currURL);
            }
        }
        run(numVideosCount, videos);
    });
};

var videoCount = 0;
var currVideo = 0;
var videoplayer = document.getElementById("playback");
var allVideos = null;
function run(count, vidArray) {
    videoCount = count;
    allVideos = vidArray;
    var nextVideo = vidArray[currVideo];
    videoplayer.src = nextVideo;
    videoplayer.play();  
    currVideo++;
}

function next() {
    if(currVideo == videoCount) {
        currVideo = 0;
    }
    var nextVideo = allVideos[currVideo];
    videoplayer.src = nextVideo;
    videoplayer.load(nextVideo);
    videoplayer.play();  
    currVideo++;  
}
function change() {
    console.log(document.getElementById("dropdown").value)
}

function uploadButton() {
    var selectedValue = document.getElementById("dropdown").value;
    sessionStorage.setItem("category", selectedValue);
    document.location.href = "bric-upload.html"
}

function viewButton() {
    var selectedValue = document.getElementById("dropdown").value;
    sessionStorage.setItem("category", selectedValue);
    document.location.href = "bric-playback.html"

} 

var fileInputTextDiv = document.getElementById('file_input_text_div');
var fileInput = document.getElementById('file_input_file');
var fileInputText = document.getElementById('file_input_text');
fileInput.addEventListener('change', changeInputText);
fileInput.addEventListener('change', changeState);

function changeInputText() {
    var str = fileInput.value;
    var i;
    if (str.lastIndexOf('\\')) {
        i = str.lastIndexOf('\\') + 1;
    } else if (str.lastIndexOf('/')) {
        i = str.lastIndexOf('/') + 1;
    }
    fileInputText.value = str.slice(i, str.length);
}

function changeState() {
    if (fileInputText.value.length != 0) {
        if (!fileInputTextDiv.classList.contains("is-focused")) {
            fileInputTextDiv.classList.add('is-focused');
        }
    } else {
        if (fileInputTextDiv.classList.contains("is-focused")) {
            fileInputTextDiv.classList.remove('is-focused');
        }
    }
}


//            
