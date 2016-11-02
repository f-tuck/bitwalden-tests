(import
  [requests]
  [base58 [b58encode b58decode]]
  [bencode [bencode bdecode]]
  [nacl.signing [SigningKey]]
  [utils [api post-to-api wait-for-result make-client-id with-timestamp with-signature]]
  [random [random]]
  [time [sleep]])
(require utils)

(def seed "H33xgBQj5jTU6bKC5iw6B9docquvNpDeKoSSWkCpcU58")
(def signing-key (SigningKey (b58decode seed)))
(def verify-key (b58encode (signing-key.verify_key.__bytes__)))

(let [[message (bencode {(str "random-number") (str (random))})]
      [client-id (make-client-id)]]
  (print "Sending initial message:" message)
  (let [[response (post-to-api signing-key {"c" "client-test" "k" verify-key "u" client-id "p" message})]]
    (test-case (assert (= response True))))
  (print "Sleeping for 3 seconds")
  (sleep 3)
  (print "Waiting for result")
  (let [[results (wait-for-result signing-key client-id verify-key)]
        [result-payloads (list-comp (get r "payload") [r results])]
        [last-timestamp (max (list-comp (get r "timestamp") [r results]))]]
    (test-case (assert (in message result-payloads)))
    (print "Truncating messages after" last-timestamp)
    (let [[response (post-to-api signing-key {"c" "get-queue" "k" verify-key "u" client-id "after" last-timestamp} :timeout 3)]]
      (test-case (assert (= response nil))))))

