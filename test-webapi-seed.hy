(import
  [requests]
  [base58 [b58encode b58decode]]
  [bencode [bencode bdecode]]
  [nacl.signing [SigningKey]]
  [utils [api post-to-api wait-for-result make-client-id with-timestamp with-signature extract-keys dht-compute-sig merge dht-address compute-infohash]]
  [random [random]]
  [binascii [hexlify]]
  [time [sleep]])
(require utils)

(def seed "H33xgBQj5jTU6bKC5iw6B9docquvNpDeKoSSWkCpcU58")

(let [[[signing-key verify-key] (extract-keys seed)]
      [client-id (make-client-id)]
      [content-name "test-post.txt"]
      [content (bencode {(str "random-number") (str (random))})]
      [params {"c" "seed" "k" verify-key "u" client-id}]
      [seed-params {"name" content-name "content" content}]
      [expected-infohash (compute-infohash content-name content)]]
  (print "Seeding:" content)
  (print "Expecting infohash:" expected-infohash)
  (let [[response (post-to-api signing-key (merge seed-params params))]]
    (print "Seed request sent.")
    (print response)
    (test-case (assert (= response True)))
    (let [[results (wait-for-result signing-key client-id verify-key)]
          [result-payloads (list-comp (get r "payload") [r results])]
          [last-timestamp (max (list-comp (get r "timestamp") [r results]))]
          [infohash (get result-payloads 0)]]
      (print "Stored at:" (% "magnet:?xt=urn:btih:%s" infohash))
      (test-case (assert (= infohash expected-infohash)))
      (print "Truncating messages.")
      (let [[response (post-to-api signing-key {"c" "get-queue" "k" verify-key "u" client-id "after" last-timestamp} :timeout 3)]]
        (test-case (assert (= response nil)))))))
