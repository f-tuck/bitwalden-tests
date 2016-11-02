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
      [message (bencode {(str "random-number") (str (random))})]
      [dht-params {"seq" 1 "salt" "sw.profile" "v" message}]
      [dht-sig (dht-compute-sig signing-key dht-params)]
      [params {"c" "dht-put" "k" verify-key "u" client-id}]
      [response (post-to-api signing-key (-> {"s.dht" dht-sig} (merge dht-params) (merge params)))]]
  ;(print response)
  (print "Put request sent.")
  (test-case (assert (= response True)))
  (let [[results (wait-for-result signing-key client-id verify-key)] 
        [result-payloads (list-comp (get r "payload") [r results])]
        [last-timestamp (max (list-comp (get r "timestamp") [r results]))]
        [address (dht-address verify-key (get dht-params "salt"))]]
    (let [[[error dht-response-buffer count] (get result-payloads 0)]
          [hash-stored (hexlify (bytearray (get dht-response-buffer "data")))]]
      (print count "nodes stored our put.")
      (test-case (assert (= error nil)))
      (test-case (assert (> count 0)))
      (test-case (assert (= address hash-stored))))
    (print "Truncating messages.")
    (let [[response (post-to-api signing-key {"c" "get-queue" "k" verify-key "u" client-id "after" last-timestamp} :timeout 3)]]
      (test-case (assert (= response nil))))))

