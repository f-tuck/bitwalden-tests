(import
  [requests]
  [base58 [b58encode b58decode]]
  [bencode [bencode bdecode]]
  [nacl.signing [SigningKey]]
  [utils [rpc rpc-signed make-client-id with-timestamp with-signature]]
  [random [random]]
  [time [sleep]])
(require utils)

(def seed "H33xgBQj5jTU6bKC5iw6B9docquvNpDeKoSSWkCpcU58")
(def signing-key (SigningKey (b58decode seed)))
(def verify-key (b58encode (signing-key.verify_key.__bytes__)))

(defn perform-client-test [messages timeout]
  (let [[client-id (make-client-id)]]
    (print "Initiating: client-test messages =" messages "with timeout" timeout)
    (for [message messages]
      (print "Sending:" message)
      (let [[response (rpc-signed "client-test" signing-key {"u" client-id "p" (bencode message)})]]
        (test-case (assert (= response client-id)))))
    (print "Sleeping: for" timeout)
    (sleep timeout)
    (print "Waiting: for result")
    (let [[results (rpc-signed "get-queue" signing-key {"u" client-id})]
          [result-payloads (list-comp (get r "payload") [r results])]
          [timestamps (list-comp (get r "timestamp") [r results])]
          [last-timestamp (if timestamps (max timestamps) nil)]]
      (print "Payloads:" result-payloads)
      (print "Timestamps:" timestamps)
      (for [message messages]
        (test-case (assert (in (bencode message) result-payloads))))
      (test-case (assert (!= last-timestamp nil)))
      (print "Truncating messages after" last-timestamp)
      (let [[response (rpc-signed "get-queue" signing-key {"u" client-id "after" last-timestamp "timeout" 1000})]]
        (test-case (assert (= response []))))))
  (print))

(defn make-random-message []
  {(str "random-number") (str (random))})

(perform-client-test [(make-random-message)] 1)
(perform-client-test [(make-random-message)] 5)

(perform-client-test (list-comp (make-random-message) [r (range 3)]) 5)

; this test fails becuase as soon as the first one comes back after 3 seconds only one result is returned
;(perform-client-test (list-comp (make-random-message) [r (range 3)]) 1)

; TODO: somehow test sending ultra-long timeout value and making sure it maxes at 5 mins
