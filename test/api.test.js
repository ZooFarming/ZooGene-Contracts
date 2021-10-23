const pinataSDK = require('@pinata/sdk');
const pinata = pinataSDK('e586035530e1fddb691b', process.env.SK);

pinata.testAuthentication().then((result) => {
  //handle successful authentication here
  console.log(result);
}).catch((err) => {
  //handle error here
  console.log(err);
});

const fs = require('fs');
const readableStreamForFile = fs.createReadStream('/Users/molin/Pictures/只言片语/images/56.jpg');
const options = {
    pinataOptions: {
        cidVersion: 0
    }
};
pinata.pinFileToIPFS(readableStreamForFile).then((result) => {
    //handle results here
    console.log(result);
}).catch((err) => {
    //handle error here
    console.log(err);
});
