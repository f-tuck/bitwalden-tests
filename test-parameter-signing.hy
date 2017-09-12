(import
  base58
  [nacl.signing [SigningKey VerifyKey]]
  [nacl.encoding [HexEncoder]]
  [utils [merge with-timestamp with-signature verify-signature]]
  [bencode [bencode]])

(require utils)

(def seed "H33xgBQj5jTU6bKC5iw6B9docquvNpDeKoSSWkCpcU58")

(def message "hello! 中英字典")

(def signing-key (SigningKey (base58.b58decode seed)))
(def verify-key (base58.b58encode (signing-key.verify_key.__bytes__)))
(def verify-key-recipient (VerifyKey (base58.b58decode verify-key)))

; set up some test parameters
(def params {"c" "signing-test" "k" verify-key "m" message})

(print "Test timestamping params.")
(def timestamped-params (with-timestamp params))
(test-case (assert (in "t" timestamped-params)))
(test-case (assert (= (type (get timestamped-params "t")) int)))
(test-case (assert (> (get timestamped-params "t") 1471830934715)))

(print "Test signing params.")
(def fixed-timestamped-params (merge params {"t" 1471830934715}))
(def signed-params (with-signature signing-key fixed-timestamped-params))
(print signed-params)
(test-case (assert (in "s" signed-params)))
(let [[sig (get signed-params "s")]]
  (test-case (assert (= (len (-> signed-params (get "s"))) 128)))
  (test-case (assert (= (get signed-params "s") "746cfdcf148ad049a3e5a4d701d4234a651724f006fddaffa622a86ac6bf8091aa176fadb6d8ed25437a7007d0d43d5bd9fb10b81b2e4b7c12889f3c313a7508"))))
(test-case (assert (= verify-key (get signed-params "k"))))

(print "Test verify signed params.")
(def verified-params (base58.b58encode (verify-signature verify-key-recipient signed-params)))
(def bencoded-params (base58.b58encode (bencode fixed-timestamped-params)))
(test-case (assert (= bencoded-params verified-params)))

