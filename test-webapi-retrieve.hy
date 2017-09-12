(import
  [requests]
  [base58 [b58encode b58decode]]
  [bencode [bencode bdecode]]
  [nacl.signing [SigningKey]]
  [utils [rpc-signed api make-client-id with-timestamp with-signature extract-keys dht-compute-sig merge dht-address compute-infohash]]
  [random [random]]
  [binascii [hexlify]]
  [time [sleep]])
(require hy.contrib.loop)
(require utils)

(def seed "H33xgBQj5jTU6bKC5iw6B9docquvNpDeKoSSWkCpcU58")

(let [[[signing-key verify-key] (extract-keys seed)]
      [content-name "unenumerated.rss"]
      [content (.read (file "unenumerated.rss"))]
      [seed-params {"name" content-name "content" content}]
      [expected-infohash (compute-infohash content-name content)]]
  (print "Expecting infohash:" expected-infohash)
  (let [[[error infohash] (rpc-signed "torrent-seed" signing-key seed-params)]]
    (print "Got:" infohash)
    (test-case (assert (= error nil)))
    (test-case (assert (= infohash expected-infohash)))
    (print "Stored at:" (% "magnet:?xt=urn:btih:%s" infohash))
    
    ; now that we have seeded the file, attempt to download it
    (let [[client-id (make-client-id)]
          [params {"u" client-id "infohash" expected-infohash}]
          [fetch-client-id (rpc-signed "torrent-fetch" signing-key params)]]
      (test-case (assert (= client-id fetch-client-id)))

      (loop [[last-timestamp 0]]
        (let [[results (rpc-signed "get-queue" signing-key {"u" client-id "after" last-timestamp})]
              [result-payloads (list-comp (get r "payload") [r results])]
              [timestamps (list-comp (get r "timestamp") [r results])]
              [last-timestamp-new (if timestamps (max timestamps) nil)]
              [done (list-comp f [f result-payloads] (= (get f "download") "done"))]]
          (print "Payloads:" result-payloads)
          (print "Timestamps:" timestamps)
          (test-case (assert (!= last-timestamp-new nil)))
          (if done
            (do
              (let [[url (+ api "content/" infohash "/" (-> done (get 0) (get "files") (get 0) (get "path")))]]
                (print "Downloading:" url)
                (let [[response-text (. (requests.get url) text)]]
                  (test-case (assert (= response-text (.decode content "utf8"))))))
              (print "Truncating messages after" last-timestamp-new)
              (let [[response (rpc-signed "get-queue" signing-key {"u" client-id "after" last-timestamp-new "timeout" 1000})]]
                (test-case (assert (= response [])))))
            (recur last-timestamp-new)))))))

