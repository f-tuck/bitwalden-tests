(import
  [utils [extract-keys dht-address]]
  [binascii [hexlify]])
(require utils)

(def seed "H33xgBQj5jTU6bKC5iw6B9docquvNpDeKoSSWkCpcU58")

(let [[[signing-key verify-key] (extract-keys seed)]
      [known-good-hash "37a55b66bf8215adfda872659839811fcb6ae298"]
      [address (dht-address verify-key "sw.profile")]]
  (test-case (assert (= address known-good-hash))))

