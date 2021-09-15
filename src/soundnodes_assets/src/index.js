import { Actor, HttpAgent } from '@dfinity/agent';
import { idlFactory as soundnodes_idl, canisterId as soundnodes_id } from 'dfx-generated/soundnodes';

const agent = new HttpAgent();
const soundnodes = Actor.createActor(soundnodes_idl, { agent, canisterId: soundnodes_id });


const input = document.querySelector('#video-file');
//changed to sandbox, becuase we cannot have nice things
const url = "https://ws.api.video/upload?token=to5PoOjCz98FdLGnsrFflnYo";
var chunkCounter =0;
//break into 1 MB chunks for demo purposes
const chunkSize = 1000000;  
const MAX_CHUNK = 20;
var isChunkTruncated = false;
var truncateMessage = "";
var downloadCompleted = true;
var videoId = "";
var playerUrl = "";
var song = "NFT";
var row  = 1;
var col  = 1;

var inputElement = document.getElementById("mp3songs");
inputElement.addEventListener("change", handleFiles, false);

//inputElement = document.getElementById("get-song");
//inputElement.addEventListener("click", getFiles, false);

inputElement = document.getElementById("get-mp3");
inputElement.addEventListener("click", getMP3File, false);


//var inputElement = document.getElementById("test");
//inputElement.addEventListener("click", handleTestFiles, false);

populateSongs();

function hideZeroSongs() {

  let songList = document.getElementById('songList');
  var length = songList.options.length;
  var x = document.getElementById("songDiv");

  if(length < 1)
  {
    x.style.display = "none";
  }
  else{
    x.style.display = "block";    
  }
}

function typedArrayToURL(typedArray, mimeType) 
{
    return URL.createObjectURL(new Blob([typedArray.buffer], {type: mimeType}))
}

async function handleTestFiles() {
  //console.log("TEST");

  const bytes = new Uint8Array(59);

  for(let i = 0; i < 59; i++) {
  bytes[i] = 32 + i;
  }

  const url = typedArrayToURL(bytes, 'text/plain');

  const link = document.createElement('a');
  link.href = url;
  link.innerText = 'Open the array URL';

  document.body.appendChild(link);

}

async function getFiles()
{
  const chunkBuffers  = [];
  const chunksAsPromises = [];
  populateSongs();


  var select = document.getElementById('songList');
  song = select.options[select.selectedIndex].value;
  //console.log(song); // en

  var chunkCountElement = document.getElementById(song);
  let chunkCount = chunkCountElement.value;
  //console.log(chunkCount);

  let nestedBytes = "";
  for (let i = 1; i <= Number(chunkCount.toString()); i++) {
    chunkBuffers[i] = await soundnodes.getSongChunk(song,i);
    if(i < Number(chunkCount.toString()))
    {
      nestedBytes = nestedBytes + chunkBuffers[i] + ",";
    }
  }

  //console.log(nestedBytes);
 
  let rawDataArray = JSON.parse( "[" + nestedBytes + "]");
  let arrayBuffer = new Uint8Array(rawDataArray);

  /*
 
  const bytesAsBuffer = Buffer.from(new Uint8Array(result));
  const videoBlob = new Blob([arrayBuffer], {
    type: "video/mp4",
  });
  var imageurl = URL.createObjectURL(videoBlob);


  const link = document.createElement('source');
  link.src = url;
  link.type = "video/mp4"
  
  var sound      = document.createElement('video');
  sound.id       = 'video-player';
  sound.controls = 'controls';
  sound.width    = '320';
  sound.height   = '240';
  sound.type     = 'video/mp4';
  document.getElementById('video').appendChild(sound);
  document.body.appendChild(link);  
  
  //console.log(vidURL);
  */

}

async function getMP3File() //Working Function getFiles()
{
    /*


    getFiles();
    const result1 = await soundnodes.getSongChunk(song,1);
    //const result = result1 + "," + result2 + "," + result3;
    const result = result1;

    let rawDataArray = JSON.parse( "[" + result + "]");
    let arrayBuffer = new Uint8Array(rawDataArray);
    */

    downloadCompleted = false;  // While downloading we should not allow upload
    const chunkBuffers  = [];
    const chunksAsPromises = [];
    //populateSongs();
  
  
    var select = document.getElementById('songList');
    song = select.options[select.selectedIndex].value;
    //console.log(song); // en

    var myElement = document.getElementById("player-"+song);
    if(myElement){
        console.log("Song already loaded !");
        //document.getElementById("error").innerHTML = song + " already loaded !";
        return 0;
    }    
  
    var chunkCountElement = document.getElementById(song);
    let chunkCount = chunkCountElement.value;
    //console.log("Number of Chunks" + chunkCount);

    document.getElementById("chunk-information").innerHTML = "0/" + chunkCount+" chunk(s) downloaded.";

  
    let nestedBytes = "";
    for (let i = 1; i <= Number(chunkCount.toString()); i++) {
      chunkBuffers[i] = await soundnodes.getSongChunk(song,i);
      //console.log("Chunk count = " + i);
      document.getElementById("chunk-information").innerHTML = i + "/" + chunkCount+" chunk(s) downloaded.";

      if(i < Number(chunkCount.toString()))
      {
        nestedBytes = nestedBytes + chunkBuffers[i] + ",";
      }
      else
      {
        nestedBytes = nestedBytes + chunkBuffers[i];
      }
    }

    if(nestedBytes.slice(-1) == ',')
    {
      console.log("There is a comma");
      nestedBytes = nestedBytes.substring(0, nestedBytes.length-2);
    }
    else{
      console.log("There is no comma");
    }

    downloadCompleted = true;
  
    //console.log(nestedBytes);
   
    let rawDataArray = JSON.parse( "[" + nestedBytes + "]");
    let arrayBuffer = new Uint8Array(rawDataArray);    

    /*
    const bytesAsBuffer = Buffer.from(new Uint8Array(result));
    const videoBlob = new Blob([arrayBuffer], {
      type: "image/png",
    });
    var imageurl = URL.createObjectURL(videoBlob);
    */

    document.getElementById("chunk-information").innerHTML = "Chunks are being assembled...";


    const url =   URL.createObjectURL(new Blob([arrayBuffer], {type: 'audio/wav'}));
    const link = document.createElement('source');
    link.src = url;
    link.type = "audio/wav"
    
    var sound      = document.createElement('audio');
    sound.id       = "player-"+song;
    sound.controls = 'controls';
    sound.src      = url;
    sound.type     = 'audio/wav';

    let row = getRow();
    let col = getCol();
    let divID = row + "-" + col;
    //console.log(divID);
    createColumn(row,col);
    document.getElementById(divID).appendChild(sound);
    createSection(divID);
    document.getElementById("sec-"+divID).innerHTML = "Song NFT ID:<br>" + song;
    document.getElementById("chunk-information").innerHTML = "Play control created !";

    document.body.appendChild(link);  

}

function getRow()
{
  return document.getElementById("row").value;
}
function getCol()
{
  return document.getElementById("col").value;
}

function setRow(row)
{
  let rowElement = document.getElementById("row");
  rowElement.value = row;
}
function setCol(col)
{
  let colElement = document.getElementById("col");
  colElement.value = col;
}

function createRow(row)
{
  var myElement = document.getElementById(row);
  if(myElement){
      //console.log("Row already exist" + row);
      return 0;
  }
  var rowDiv  = document.createElement('div');
  rowDiv.className = "row";
  rowDiv.id = row;
  document.getElementById('song').appendChild(rowDiv);

}

function createColumn(row,col)
{
  createRow(row);

  var myElement = document.getElementById(row + "-" + col);
  if(myElement){
      //console.log("Column already loaded !" + row + "-" + col);
      return 0;
  }
  let id = row + "-" + col;
  var colDiv  = document.createElement('div');
  colDiv.className = "col-sm-4";
  colDiv.id = id;
  document.getElementById(row).appendChild(colDiv);
  col++;
  if(col > 3)
  {
    col = 1;
    row++;
  }
  
  setRow(row);
  setCol(col);
  //console.log("From createColumn" + col);
  
}

function createSection(id)
{
  var sec = document.createElement('section');
  sec.id  = "sec-"+id;
  document.getElementById(id).appendChild(sec);

}
async function handleFiles() {
  const fileList = this.files; /* now you can work with the file list */
  const file     = fileList[0];
  const MAX_CHUNK_SIZE = 1024 * 500; // 500kb

  const filename = fileList[0].name;
  const fileSize = fileList[0].size;
  var numberofChunks = Math.ceil(fileSize/MAX_CHUNK_SIZE);


  
  //console.log("Filenane = " + filename + " Size "+ fileSize);

  //If download is in progress then do not upload anything
  if(!downloadCompleted)
  {
    document.getElementById("video-information").innerHTML = document.getElementById("video-information").innerHTML + "<br>Download is in progress, please wait...";
    return 0;
  }

  document.getElementById("get-mp3").disabled = true;


  let saveFileAs = filename.replace(".", "-");
  document.getElementById("chunk-information").innerHTML = "";

  var reader = new FileReader();
  reader.onload = function(event) {
    // The file's text will be printed here
    ////console.log(event.target.result)
  };

  reader.readAsText(fileList[0]); 

  var fileReader = new FileReader(),
  array;
  if (numberofChunks > MAX_CHUNK)
  {
    numberofChunks = MAX_CHUNK; // Set to maximum size of chunks as 25
    isChunkTruncated = true;
    truncateMessage = " Size limit exceeded. Truncating your song to 10 mb.<br>";
    
  }  
  fileReader.onload = async function() 
  {
      //console.log("Calling....."+this.result);
      array = this.result;
      //console.log("Big File contains", array.byteLength, "bytes.");
      const songDataArray = Array.from(new Uint8Array(array));
      //console.log(songDataArray.length);

      
      var start =0; 
      chunkCounter=1;
      var chunkEnd = start + chunkSize;
      videoId="";

      const songName = document.getElementById("name").value.toString();
      const songCaption = document.getElementById("caption").value.toString();
      const songTags = document.getElementById("songtags").value.toString();
      const createdTime = Math.floor(Date.now() / 1000);

      let saveSongAs = saveFileAs + "-" + songName + "-" + songCaption;

      if(saveSongAs.length > 50)
      {
        saveSongAs  = saveSongAs.substring(0, 50);
      }
      

      const songInit = ({ userId:"NFT",name:saveSongAs,createdAt:createdTime,caption:songCaption,tags: [songTags],chunkCount:numberofChunks});
      const songCreateResult = await soundnodes.createSong(songInit);
      //console.log(songCreateResult);


      //console.log("Song NFT ID " + song);

      song = songCreateResult[0];
      //console.log("Song NFT ID " + song);

      document.getElementById("song-information").innerHTML = "Song NFT ID: <br>" + song;
      
      
      for (let byteStart = 0;	byteStart < file.size;	byteStart += MAX_CHUNK_SIZE,chunkCounter++)
      {
        const songSlice = songDataArray.slice(byteStart,Math.min(file.size, byteStart + MAX_CHUNK_SIZE));
        //console.log(songSlice.length);
        //console.log(chunkCounter);


        var id = chunkCounter;
        var chunk = songSlice;

        if(chunkCounter <= numberofChunks)
        {
          const result1 = await soundnodes.putSongChunk(song,id,chunk);
          document.getElementById("chunk-information").innerHTML = chunkCounter + "/" + numberofChunks+" chunk(s) uploaded."
          //console.log("Result of Chunk upload = " + result1);        
        }

      }

      document.getElementById("get-mp3").disabled = false;

      const allSongs = await soundnodes.getSongs();
      //console.log(allSongs);

      let songList = document.getElementById('songList');
      let songDiv  = document.getElementById('song-container');

      var length = songList.options.length;
      for (let i = length-1; i >= 0; i--) {
        var element = document.getElementById("song-container");
        var child=document.getElementById(songList.options[i].value);
        //console.log("Song ID " + songList.options[i].value)
        if(child){
          child.remove();
          //console.log("Removing...." + songList.options[i].value);
        }        
        songList.options[i] = null;
      }
      
      for (let i = 0; i < allSongs.length; i++) {
        for (let j = 0; j < allSongs[i].length; j++) {
          let songid = allSongs[i][j].songId;
          let chunks = allSongs[i][j].chunkCount;
          song = songid;

          //console.log(songid);
          //console.log(chunks);
          //console.log("Songs = " + song);

          songList.options[songList.options.length] = new Option(songid, songid);
          const chunkField = document.createElement('input');
          chunkField.type = "hidden";
          chunkField.id = songid;
          chunkField.value = chunks;
          songDiv.appendChild(chunkField);
        }
      }
      populateSongs();      
  };
  
  fileReader.readAsArrayBuffer(fileList[0]); 



  document.getElementById("video-information").innerHTML = truncateMessage + "File size : " + fileSize + "<br> There will be " + numberofChunks + " chunks uploads."
  var start =0; 
  chunkCounter=0;
  videoId="";
  var chunkEnd = start + chunkSize;


}

async function populateSongs()
{
  const allSongs = await soundnodes.getSongs();
  //console.log(allSongs);

  let songList = document.getElementById('songList');
  let songDiv  = document.getElementById('song-container');

  var length = songList.options.length;
  for (let i = length-1; i >= 0; i--) {
    var element = document.getElementById("song-container");
    var child=document.getElementById(songList.options[i].value);
    //console.log("Song ID " + songList.options[i].value)
    if(child){
      child.remove();
      //console.log("Removing...." + songList.options[i].value);
    }        
    songList.options[i] = null;
  }
  
  for (let i = 0; i < allSongs.length; i++) {
    for (let j = 0; j < allSongs[i].length; j++) {
      let songid = allSongs[i][j].songId;
      let chunks = allSongs[i][j].chunkCount;
      song = songid;

      //console.log(songid);
      //console.log(chunks);
      //console.log("Songs = " + song);

      songList.options[songList.options.length] = new Option(songid, songid);
      const chunkField = document.createElement('input');
      chunkField.type = "hidden";
      chunkField.id = songid;
      chunkField.value = chunks;
      songDiv.appendChild(chunkField);
    }
  }
  hideZeroSongs();      
}




function reference()
{
  const bytes = new Uint8Array(59);
  
  for(let i = 0; i < 59; i++) {
    bytes[i] = 32 + i;
  }

  const url1 = typedArrayToURL(bytes, 'text/plain');
  
  const link1 = document.createElement('a');
  link1.href = url1;
  link1.innerText = 'Open the Test URL';
  
  const linebrk = document.createElement('hr');

  const img = document.createElement('img');
  img.src = imageurl;

  document.body.appendChild(img);
  document.body.appendChild(linebrk); 
  document.body.appendChild(link1);  

}

function imgref()
{
  const videoBlob = new Blob([array], {
    type: "image/png",
  });


  var imageurl = URL.createObjectURL(videoBlob);
  const img = document.createElement('img');
  img.src = imageurl;

  document.body.appendChild(img);


  let rawDataArray = JSON.parse( "[" + songDataArray + "]");

  let arrayBuffer = new Uint8Array(rawDataArray);
 

  //console.log(songDataArray.buffer);
  const bufferBlob = new Blob([arrayBuffer], {
    type: "image/png",
  });

  //console.log("Blob");
  //console.log(bufferBlob);
  //console.log(videoBlob);

  //console.log(songDataArray);
  //console.log(array);

  if(array.buffer == songDataArray.buffer)
  {
    //console.log("Data are equal");
  }
  else
  {
    //console.log("Not array are equal");
  }


  var bufferImage = URL.createObjectURL(bufferBlob);
  const bufferImg = document.createElement('img');
  bufferImg.src = bufferImage;

  document.body.appendChild(bufferImg);

}

/*
document.getElementById("clickMeBtn").addEventListener("click", async () => {
  const name = document.getElementById("name").value.toString();
  const greeting = await soundnodes.greet(name);

  const result = await soundnodes.createUserProfile(name);

  var song = "test";
  var id = 1;
  var chunk = new Uint8Array([1, 2, 3, 4]);

  const result1 = await soundnodes.putSongChunk(song,id,chunk);
  
  //console.log("Result of Chunk upload = " + result1);
  document.getElementById("greeting").innerText = greeting;

});
*/