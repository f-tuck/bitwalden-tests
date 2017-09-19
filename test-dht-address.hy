(import
  [utils [extract-keys dht-address]]
  [binascii [hexlify]])
(require utils)

(def seed "H33xgBQj5jTU6bKC5iw6B9docquvNpDeKoSSWkCpcU58")

(let [[[signing-key verify-key] (extract-keys seed)]
      [known-good-hash "614ca87810ab7b11502a913c81c944d0ecf02dd5"]
      [address (dht-address verify-key "bw.profile")]]
  (test-case (assert (= address known-good-hash))))

