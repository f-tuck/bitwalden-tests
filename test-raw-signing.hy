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

(def message (.encode "hello! 中英字典" "utf8"))
(print "Signing message:" message)
(def signed (base58.b58encode (. (signing-key.sign message) signature)))
(print "signature:" signed)
(test-case (assert (= "3WSyL71QMGpAh7zoUPyBjoRanTAf2GXdYKFSgWEKPUV39HdUj1RGk9CGG7o3aCW75ihyyhaLqNCSSN2SNG8VSeW1" signed)))

(def verify-key-recipient (VerifyKey (base58.b58decode verify-key)))
(def verified-message (verify-key-recipient.verify message (base58.b58decode signed)))
(print "Verified:" verified-message)
(test-case (assert (= verified-message message)))
