(import
  [json]
  [base58 [b58encode b58decode]]
  [requests]
  [nacl.signing [SigningKey VerifyKey]]
  [nacl.encoding [HexEncoder]]
  [utils [rpc with-timestamp with-signature merge]]
  [bencode [bencode]])

(require utils)

(def seed "H33xgBQj5jTU6bKC5iw6B9docquvNpDeKoSSWkCpcU58")

; (def newkey (SigningKey.generate))
(def signing-key (SigningKey (b58decode seed)))

(print "signature seed:" seed)
(def verify-key-bytes (signing-key.verify_key.__bytes__))
(def verify-key (b58encode verify-key-bytes))
;(print "verify key:" verify-key)
(test-case (assert (= "7Q9he6fH1m6xAk5buSSPwK4Jjmute9FjF5TgidTZqiHM" verify-key)))

(def message (.encode "hello! 中英字典" "utf8"))
(print "Signing message:" message)
(def signed (b58encode (. (signing-key.sign message) signature)))
(test-case (assert (= "3WSyL71QMGpAh7zoUPyBjoRanTAf2GXdYKFSgWEKPUV39HdUj1RGk9CGG7o3aCW75ihyyhaLqNCSSN2SNG8VSeW1" signed)))

(def verify-key-recipient (VerifyKey (b58decode verify-key)))
(def verified-message (verify-key-recipient.verify (str message) (b58decode signed)))
(print "Verified:" verified-message)
(test-case (assert (= verified-message message)))

(print "Checking signature length")
(test-case (assert (= (len (b58decode signed)) 64)))

(def params (with-timestamp {"k" verify-key "p" message}))
(def signed-params (with-signature signing-key params))

; (print "signed-params" signed-params)
; (print (bencode signed-params))

(print "Remote signing test")
(let [[response (rpc "authenticate" signed-params)]]
  (test-case (assert (= response True))))

(print "Mutated message signature failure test")
(let [[response (rpc "authenticate" (merge signed-params {"p" "hellooo!"}))]]
  (test-case (assert (= response False))))


