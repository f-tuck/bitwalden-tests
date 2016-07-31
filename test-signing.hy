(import base58)
(import [nacl.signing [SigningKey VerifyKey]])
(import [nacl.encoding [HexEncoder]])

(require utils)

(def seed "H33xgBQj5jTU6bKC5iw6B9docquvNpDeKoSSWkCpcU58")

; (def newkey (SigningKey.generate))
(def signing-key (SigningKey (base58.b58decode seed)))

;(print "signature seed:" seed)
(def verify-key (base58.b58encode (signing-key.verify_key.__bytes__)))
(print "Checking verify key:" verify-key)
(test-case (assert (= "7Q9he6fH1m6xAk5buSSPwK4Jjmute9FjF5TgidTZqiHM" verify-key)))

(def message "hello!")
(print "Signing message:" message)
(def signed (base58.b58encode (. (signing-key.sign (str message)) signature)))
;(print "signature:" signed)
(test-case (assert (= "52Y6M45n2TGuPixQ1AnqpQ1PdoJb3dgCP6bHp4TM3w1xfTkZHw864eo7nhhTBBRDRi6kLQLbndVk9vtkkfuqz97i" signed)))

(def verify-key-recipient (VerifyKey (base58.b58decode verify-key)))
(def verified-message (verify-key-recipient.verify (str message) (base58.b58decode signed)))
;(print "Verified:" verified-message)
(test-case (assert (= verified-message message)))
