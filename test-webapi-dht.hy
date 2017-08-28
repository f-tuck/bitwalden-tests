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

(defn parse-get-response [results]
  (let [[result-payloads (list-comp (get r "payload") [r results])]
        [last-timestamp (max (list-comp (get r "timestamp") [r results]))]
        [[error dht-response-object-get] (get result-payloads 0)]]
    [last-timestamp error
     (if dht-response-object-get
       [(get dht-response-object-get "seq")
        (-> dht-response-object-get (get "k") (get "data") (bytearray) (str) (b58encode))
        (-> dht-response-object-get (get "salt") (get "data") (bytearray))
        (-> dht-response-object-get (get "v") (get "data") (bytearray) (str) (bdecode))]
       [-1 nil nil nil])]))

(let [[[signing-key verify-key] (extract-keys seed)]
      [client-id (make-client-id)]
      [salt "sw.profile"]
      [address (dht-address verify-key salt)]
      [params-get {"c" "dht-get" "k" verify-key "u" client-id}]
      [response-get (post-to-api signing-key (-> {"infohash" address} (merge params-get)))]]
  (print "Get request sent to:" address)
  (test-case (assert (= response-get True)))
  (let [[[last-timestamp error response-vals] (parse-get-response (wait-for-result signing-key client-id verify-key))]
        [[seq-get k salt-get value-get] response-vals]]
    ; check GET request value
    (if (>= seq-get 0)
      (do
        (test-case (assert (= error nil)))
        (test-case (assert (= k verify-key)))
        (test-case (assert (>= seq-get 0))))
      (print "No initial DHT value, skipping get tests."))

    (print "DHT initial seq:" seq-get)
    (print "DHT initial salt:" salt-get)
    (print "DHT initial contents:" value-get)

    ; issue a post to update the DHT

    (let [[value {"random-number" (str (random))}]
          [client-id (make-client-id)]
          [message-put (bencode value)]
          [seq-put (+ seq-get 1)]
          [dht-params {"seq" seq-put "salt" salt "v" message-put}]
          [dht-sig (dht-compute-sig signing-key dht-params)]
          [params-put {"c" "dht-put" "k" verify-key "u" client-id}]
          [response-put (post-to-api signing-key (-> {"s.dht" dht-sig "after" last-timestamp} (merge dht-params) (merge params-put)))]]
      (print "Put request sent:" dht-params)
      (test-case (assert (= response-put True)))
      (let [[results (wait-for-result signing-key client-id verify-key)]
            [result-payloads (list-comp (get r "payload") [r results])]
            [last-timestamp (max (list-comp (get r "timestamp") [r results]))]
            [address (dht-address verify-key (get dht-params "salt"))]]
        (print "result:" (get result-payloads 0))
        (let [[[error dht-response-buffer-put count] (get result-payloads 0)]
              [hash-stored (hexlify (bytearray (get dht-response-buffer-put "data")))]]
          (print count "nodes stored our put.")
          (test-case (assert (= error nil)))
          (test-case (assert (> count 0)))
          (test-case (assert (= address hash-stored)))
          (print "DHT put node count:" count)
          (print "DHT put address:" address))

        ; finally check the DHT to see that our PUT worked

        (let [[client-id (make-client-id)]
              [response-get (post-to-api signing-key (-> {"infohash" address "after" last-timestamp} (merge params-get) (merge {"u" client-id})))]]
          (print "Get request sent.")
          (test-case (assert (= response-get True)))
          (let [[[last-timestamp error response-vals] (parse-get-response (wait-for-result signing-key client-id verify-key))]
                [[seq k salt-put value-put] response-vals]]

            (print "DHT new seq:" seq)
            (print "DHT new salt:" salt-put)
            (print "DHT new contents:" value-put)

            ; check GET request value
            (test-case (assert (= error nil)))
            (test-case (assert (= k verify-key)))
            (test-case (assert (= seq seq-put)))
            (test-case (assert (= value value-put)))
            
            (print "Truncating messages.")
            (let [[response (post-to-api signing-key {"c" "get-queue" "k" verify-key "u" client-id "after" last-timestamp} :timeout 3)]]
              (test-case (assert (= response nil))))))))))

