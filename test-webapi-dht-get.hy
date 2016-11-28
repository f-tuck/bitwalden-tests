(import
  [requests]
  [base58 [b58encode b58decode]]
  [bencode [bencode bdecode]]
  [nacl.signing [SigningKey]]
  [utils [api post-to-api wait-for-result make-client-id with-timestamp with-signature extract-keys dht-compute-sig merge dht-address]]
  [random [random]]
  [binascii [hexlify]]
  [time [sleep]])
(require utils)

(def seed "H33xgBQj5jTU6bKC5iw6B9docquvNpDeKoSSWkCpcU58")

(let [[[signing-key verify-key] (extract-keys seed)]
      [client-id (make-client-id)]
      [params {"c" "dht-get" "k" verify-key "u" client-id}]
      [salt "sw.profile"]
      [address (dht-address verify-key salt)]
      [response (post-to-api signing-key (-> {"infohash" address} (merge params)))]]
  (print "Get request sent.")
  (test-case (assert (= response True)))
  (let [[results (wait-for-result signing-key client-id verify-key)] 
        [result-payloads (list-comp (get r "payload") [r results])]
        [last-timestamp (max (list-comp (get r "timestamp") [r results]))]]
    (let [[[error dht-response-object] (get result-payloads 0)]
          [seq (get dht-response-object "seq")]
          [k (-> dht-response-object (get "k") (get "data") (bytearray) (str) (b58encode))]
          [salt (-> dht-response-object (get "salt") (get "data") (bytearray))]]
      (test-case (assert (= error nil)))
      (test-case (assert (= k verify-key)))
      (test-case (assert (> seq 0))))
    (print "Truncating messages.")
    (let [[response (post-to-api signing-key {"c" "get-queue" "k" verify-key "u" client-id "after" last-timestamp} :timeout 3)]]
      (test-case (assert (= response nil))))))

