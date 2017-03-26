(import
  [requests]
  [base58 [b58encode b58decode]]
  [bencode [bencode bdecode]]
  [nacl.signing [SigningKey]]
  [utils [api post-to-api wait-for-result make-client-id with-timestamp with-signature extract-keys dht-compute-sig merge dht-address compute-infohash]]
  [random [random]]
  [binascii [hexlify]]
  [time [sleep]])
(require hy.contrib.loop)
(require utils)

(def seed "H33xgBQj5jTU6bKC5iw6B9docquvNpDeKoSSWkCpcU58")

(let [[[signing-key verify-key] (extract-keys seed)]
      [client-id-seed (make-client-id)]
      [content-name "The Crypto Anarchist Manifesto.htm"]
      [content (-> (file content-name) (.read))]
      [params {"c" "seed" "k" verify-key "u" client-id-seed}]
      [seed-params {"name" content-name "content" content}]
      [expected-infohash (compute-infohash content-name content)]]
  (print "Seeding" content-name)
  (print "Expecting infohash:" expected-infohash)
  (let [[response (post-to-api signing-key (merge seed-params params))]]
    (print "Seed request sent.")
    (print response)
    (test-case (assert (= response True)))
    (let [[results (wait-for-result signing-key client-id-seed verify-key)]
          [result-payloads (list-comp (get r "payload") [r results])]
          [last-timestamp-seed (max (list-comp (get r "timestamp") [r results]))]
          [infohash (get result-payloads 0)]]
      (print "Stored at:" (% "magnet:?xt=urn:btih:%s" infohash))
      (test-case (assert (= infohash expected-infohash)))
      (print "Truncating messages.")
      (let [[response (post-to-api signing-key {"c" "get-queue" "k" verify-key "u" client-id-seed "after" last-timestamp-seed} :timeout 3)]]
        (test-case (assert (= response nil))))

      ; now that we have seed the file, attempt to download it
      (let [[client-id (make-client-id)]
            [params {"c" "retrieve" "k" verify-key "u" client-id "infohash" expected-infohash}]]
        (print "Retrieving:" infohash)
        (let [[response (post-to-api signing-key params)]]
          (print "Seed request sent.")
          (print response)
          (test-case (assert (= response True)))

          (loop [[last-timestamp 0]]
            (print "last-timestamp" last-timestamp)
            (let [[results (wait-for-result signing-key client-id verify-key :after last-timestamp)]
                  [result-payloads (list-comp (get r "payload") [r results])]
                  [last-timestamp-new (max (list-comp (get r "timestamp") [r results]))]
                  [done (list-comp f [f result-payloads] (= (get f "download") "done"))]]
              (print "Result payload:" result-payloads)
              (if done
                (let [[url (+ api "content/" infohash "/" (-> done (get 0) (get "files") (get 0) (get "path")))]]
                  (print "Downloading:" url)
                  (let [[response-text (. (requests.get url) text)]]
                    (test-case (assert (= response-text content))))
                  (print "Truncating messages.")
                  (let [[response (post-to-api signing-key {"c" "get-queue" "k" verify-key "u" client-id "after" last-timestamp-new} :timeout 3)]]
                    (test-case (assert (= response nil)))))
                (recur last-timestamp-new)))))))))

