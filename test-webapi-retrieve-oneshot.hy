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

; TODO: test timeout with nonexistent infohash [ 678dbdacfa5f94ed5d38bb4f534866792a2400e8 ]

(let [[[signing-key verify-key] (extract-keys seed)]
      [content-name "unenumerated.rss"]
      [content (.read (file "unenumerated.rss"))]
      [seed-params {"name" content-name "content" content}]
      [expected-infohash (compute-infohash content-name content)]]
  (print "Expecting infohash:" expected-infohash)
  (let [[result (rpc-signed "torrent-seed" signing-key seed-params)]
        [error (.get result "error" nil)]
        [infohash (.get result "infohash" nil)]]
    (print "Got:" infohash)
    (test-case (assert (= error nil)))
    (test-case (assert (= infohash expected-infohash)))

    (print "Stored at:" (% "magnet:?xt=urn:btih:%s" infohash))
    
    ; now that we have seeded the file, attempt to download it
    (let [[client-id (make-client-id)]
          [params {"u" client-id "infohash" expected-infohash}]
          [fetch-result (rpc-signed "torrent-fetch" signing-key params)]]
      
      (test-case (assert (= (get fetch-result "download") "done")))
      (test-case (assert (> (len (get fetch-result "files")) 0)))
      
      (print "fetch-result" fetch-result)

      (let [[file (-> fetch-result (get "files") (get 0) (get "path"))]
             [path (get fetch-result "path")]
             [url (+ api path file)]]
                (print "Downloading:" url)
                (let [[response-text (. (requests.get url) text)]]
                  (test-case (assert (= response-text (.decode content "utf8")))))))))

