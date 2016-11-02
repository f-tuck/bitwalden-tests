(import
  [utils [extract-keys dht-address]]
  [binascii [hexlify]])
(require utils)

(def seed "H33xgBQj5jTU6bKC5iw6B9docquvNpDeKoSSWkCpcU58")

(let [[[signing-key verify-key] (extract-keys seed)]
      [hash (hexlify (bytearray [30 39 14 220 17 32 250 230 216 37 147 2 170 244 163 210 14 255 33 78]))]
      [address (dht-address verify-key "sw.profile")]]
  (test-case (assert (= address hash))))

