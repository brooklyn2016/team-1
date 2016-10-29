
// Initialize Firebase
var config = {
    apiKey: "AIzaSyD5CKyFLfaFZfo2g8Tak8-IuIeTrZTVD0Y",
    authDomain: "bric-live.firebaseapp.com",
    databaseURL: "https://bric-live.firebaseio.com",
    storageBucket: "bric-live.appspot.com",
    messagingSenderId: "144009791835"
};
firebase.initializeApp(config);

var ref = firebase.database().ref().child("Events");

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


//            var uploader = document.getElementById("uploader");
//            var fileButton = document.getElementById("fileButton")
//
//            fileButton.addEventListener('change', function(e) {
//
//                var file = e.target.files[0];
//
//                var storageref = firebase.storage().ref('fathers_day/' + file.name);
//
//                var databaseref = firebase.database().ref('fathers_day');
//
//                var task = storageref.put(file);
//
//                task.on('state_changed',
//
//                        function progress(snapshot) {
//                    var percentage = (snapshot.bytesTransferred / snapshot.totalBytes) * 100;
//                    uploader.value = percentage;
//                },
//                        function error(err) {
//
//                },
//                        function complete() {
//                    console.log("COMPLETED");
//
//
//                    var newFileName = file.name.slice(0, -4);
//                    //console.log(newFileName);
//                    storageref.getDownloadURL().then(function(url) {
//                        console.log(url);
//                        databaseref.child(newFileName).set(url);
//                    }).catch(function(error) {
//                        console.log(error);
//                    });
//                    //databaseref.child(newFileName).set(storageref.getDownloadURL())
//                }
//
//                       );
//
//            });
