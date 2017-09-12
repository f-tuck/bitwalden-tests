(import
  [os]
  [requests]
  [base58 [b58encode b58decode]]
  [bencode [bencode bdecode]]
  [nacl.signing [SigningKey]]
  [utils [rpc-signed extract-keys dht-compute-sig merge dht-address compute-infohash]]
  [random [random]]
  [binascii [hexlify]]
  [time [sleep]])
(require utils)

(def seed "H33xgBQj5jTU6bKC5iw6B9docquvNpDeKoSSWkCpcU58")

(let [[[signing-key verify-key] (extract-keys seed)]
      [content-name "test-post.txt"]
      [content (.read (file "unenumerated.rss"))]
      [seed-params {"name" content-name "content" content}]
      [expected-infohash (compute-infohash content-name content)]]
  (print "Expecting infohash:" expected-infohash)
  (let [[[error infohash] (rpc-signed "torrent-seed" signing-key seed-params)]]
    (print "Got:" infohash)
    
    (test-case (assert (= error nil)))
    (test-case (assert (= infohash expected-infohash)))
    (print "Stored at:" (% "magnet:?xt=urn:btih:%s" infohash))))

