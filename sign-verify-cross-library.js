var bs58 = require('bs58')
var ed = require('ed25519-supercop')
var nacl = require('tweetnacl')

var seed = new Buffer(bs58.decode("H33xgBQj5jTU6bKC5iw6B9docquvNpDeKoSSWkCpcU58"));
var keypair = nacl.sign.keyPair.fromSeed(seed);
var message = "hello!";
var sig = nacl.sign.detached(new Buffer(message), keypair.secretKey);
console.log("Message:", message);
console.log("Signature (tweetnacl):", bs58.encode(sig));
console.log("Sig = 52Y6M45n2TGuPixQ1AnqpQ1PdoJb3dgCP6bHp4TM3w1xfTkZHw864eo7nhhTBBRDRi6kLQLbndVk9vtkkfuqz97i?", bs58.encode(sig) == "52Y6M45n2TGuPixQ1AnqpQ1PdoJb3dgCP6bHp4TM3w1xfTkZHw864eo7nhhTBBRDRi6kLQLbndVk9vtkkfuqz97i");
console.log("ed25519-supercop verify:", ed.verify(new Buffer(sig), new Buffer(message), new Buffer(keypair.publicKey)));
