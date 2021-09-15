import http from "../http-common";

class UploadFilesService {
  upload(file, onUploadProgress) {
    let formData = new FormData();

    formData.append("file", file);


/********************************************************/
  //changed to sandbox, becuase we cannot have nice things
  var chunkCounter =0;
  //break into 1 MB chunks for demo purposes
  const chunkSize = 1000000;  
  var videoId = "";
  var playerUrl = "";
  var numberofChunks = Math.ceil(file.size/chunkSize);

  var blob = new Blob(["\x01\x02\x03\x04"]),

  fileReader = new FileReader(),
  array;

  fileReader.onload = function() 
  {
      console.log("Calling.....");
      array = this.result;
      console.log("Big File contains", array.byteLength, "bytes.");
      const videoBuffer = Array.from(new Uint8Array(array));
      console.log(videoBuffer.length);
      const MAX_CHUNK_SIZE = 1024 * 500; // 500kb

      var start =0; 
      chunkCounter=0;
      videoId="";

      var chunkEnd = start + chunkSize;
      for (let byteStart = 0;	byteStart < file.size;	byteStart += MAX_CHUNK_SIZE,chunkCounter++) {
        const videoSlice = videoBuffer.slice(byteStart,Math.min(file.size, byteStart + MAX_CHUNK_SIZE));
        console.log(videoSlice.length);
        console.log(chunkCounter);
      }				
  };

  fileReader.readAsArrayBuffer(file);

  var message = "There will be " + numberofChunks + " chunks uploaded."
  var start =0; 
  chunkCounter=0;
  videoId="";
  var chunkEnd = start + chunkSize;
/****************************************************** */


	  const url = "https://ws.api.video/upload?token=to5PoOjCz98FdLGnsrFflnYo";

    return http.post(url, formData, {
      headers: {
        "Content-Type": "multipart/form-data",
      },
      onUploadProgress,
    });
  }

  getFiles() {
    return http.get("/files");
  }
}

export default new UploadFilesService();
