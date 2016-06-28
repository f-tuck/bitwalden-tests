(import [base58 [b58encode b58decode]])
(import [requests])
(import [nacl.signing [SigningKey VerifyKey]])
(import [nacl.encoding [HexEncoder]])
(import [utils [api]])
(require utils)

(def seed "H33xgBQj5jTU6bKC5iw6B9docquvNpDeKoSSWkCpcU58")

; (def newkey (SigningKey.generate))
(def signing-key (SigningKey (b58decode seed)))

(print "signature seed:" seed)
(def verify-key-bytes (signing-key.verify_key.__bytes__))
(def verify-key (b58encode verify-key-bytes))
(print "verify key:" verify-key)
(test-case (assert (= "7Q9he6fH1m6xAk5buSSPwK4Jjmute9FjF5TgidTZqiHM" verify-key)))

(def message "hello!")
(print "Signing message:" message)
(def signed (b58encode (. (signing-key.sign (str message)) signature)))
(test-case (assert (= "52Y6M45n2TGuPixQ1AnqpQ1PdoJb3dgCP6bHp4TM3w1xfTkZHw864eo7nhhTBBRDRi6kLQLbndVk9vtkkfuqz97i" signed)))

(def verify-key-recipient (VerifyKey (b58decode verify-key)))
(def verified-message (verify-key-recipient.verify (str message) (b58decode signed)))
(print "Verified:" verified-message)
(test-case (assert (= verified-message message)))

(print "Checking signature length")
(test-case (assert (= (len (b58decode signed)) 64)))

(print "Remote signing test")
(let [[response (.json (requests.post api :params {"c" "authenticate" "k" verify-key-bytes "p" (str message) "s" (b58decode signed)}))]]
  (test-case (assert (= response True))))

(print "Mutated message signature failure test")
(let [[response (.json (requests.post api :params {"c" "authenticate" "k" verify-key-bytes "p" (str (+ message "!")) "s" (b58decode signed)}))]]
  (test-case (assert (= response False))))

