(import
  [base58]
  [nacl.public [PrivateKey PublicKey Box]])

(require utils)

(def seed "H33xgBQj5jTU6bKC5iw6B9docquvNpDeKoSSWkCpcU58")
(def newkey (PrivateKey.generate))
(def secret_key (PrivateKey (base58.b58decode seed)))

(print "old seed & key:")
(print seed)
(test-case (assert (= (base58.b58encode (secret_key.public_key.__bytes__)) "J7XiSVRjegseCQpJyhHDjKkkRDbCNu3WCywJj6kYvVzX")))

(print "freshly generated keys:")
(print (base58.b58encode (newkey.__bytes__)))
(print (base58.b58encode (newkey.public_key.__bytes__)))

