(import
  [requests]
  [base58 [b58encode b58decode]]
  [bencode [bencode bdecode]]
  [nacl.signing [SigningKey]]
  [utils [rpc-signed make-client-id with-timestamp with-signature extract-keys dht-compute-sig merge dht-address]]
  [random [random]]
  [binascii [hexlify]]
  [time [sleep]])
(require utils)

(def seed "H33xgBQj5jTU6bKC5iw6B9docquvNpDeKoSSWkCpcU58")

(let [[[signing-key verify-key] (extract-keys seed)]
      [salt "bw.profile"]
      [address (dht-address verify-key salt)]
      [response-get (or (rpc-signed "dht-get" signing-key {"addresshash" address "salt" salt}) {})]
      [error-get (.get response-get "error" nil)]]
  (print "Get request sent")
  (print "Address:" address)
  (print "Salt:" salt)
  (test-case (assert (= error-get nil)))

  (let [[seq-get (.get response-get "seq" 0)]
        [k-get (.get response-get "k" None)]
        [value-get (.get response-get "v" nil)]]
    (print "DHT initial seq:" seq-get)
    (print "DHT initial contents:" value-get) 

    ; check GET request value
    (if (not response-get)
      (print "No initial DHT value, skipping get tests.") 
      (do
        (test-case (assert (= k-get verify-key)))
        (test-case (assert (>= seq-get 0)))))

    ; issue a post to update the DHT
    (let [[value {"random-number" (str (random))}]
          [value-put (bencode value)]
          [seq-put (+ seq-get 1)]
          [dht-params {"seq" seq-put "salt" salt "v" value-put}]
          [dht-sig (dht-compute-sig signing-key dht-params)]
          [put-params (merge dht-params {"s.dht" dht-sig})]
          [address (dht-address verify-key salt)]
          [put-response (rpc-signed "dht-put" signing-key put-params)]
          [put-addresshash (.get put-response "addresshash" nil)]
          [put-nodes-count (.get put-response "nodecount" nil)]
          [put-error (.get put-response "error" nil)]]
      (print "Put request sent:")
      (print "DHT sig:" dht-sig)
      (print "DHT message:" (slice (bencode dht-params) 1 -1))
      (print "DHT pk:" (hexlify (bytes (signing-key.verify_key.__bytes__))))
      (print put-params)
      (print "DHT put node count:" put-nodes-count)
      (print "DHT put address:" put-addresshash)
      (if put-error (print put-error put-response))
      (test-case (assert (= put-error nil)))
      (test-case (assert (= address put-addresshash)))
      (test-case (assert (> put-nodes-count 0)))

      (let [[response-get (or (rpc-signed "dht-get" signing-key {"addresshash" address "salt" salt}) {})]
            [error-get (.get response-get "error" nil)]
            [seq-get (.get response-get "seq" 0)]
            [k-get (.get response-get "k" None)]
            [value-get (.get response-get "v" nil)]]

        (print "DHT new seq:" seq-get)
        (print "DHT new contents:" value-get)

        ; check GET request value
        (test-case (assert (= error-get nil)))
        (test-case (assert (= k-get verify-key)))
        (test-case (assert (= seq-get seq-put)))
        (test-case (assert (= value-get value-put)))))

    ; there is a bug in webtorrent 0.81.0 which causes this test to fail
    ; because older DHT put values with lower seq can be returned
    ;(print "Attempting bad put.")
    ;(let [[value {"random-number" (str (random))}]
          ;[value-put (bencode value)]
          ;[seq-put seq-get]
          ;[dht-params {"seq" seq-put "salt" salt "v" value-put}]
          ;[dht-sig (dht-compute-sig signing-key dht-params)]
          ;[put-params (merge dht-params {"s.dht" dht-sig})]
          ;[address (dht-address verify-key (get dht-params "salt"))] 
          ;[[error put-addresshash put-nodes-count] (rpc-signed "dht-put" signing-key put-params)]]
      ;(print "Put request sent:")
      ;(print put-params)
      ;(print "DHT put node count:" put-nodes-count)
      ;(print "DHT put address:" put-addresshash)
      ;(print "DHT error:" error)
      ;(test-case (assert (!= get-error nil)))
      ;(test-case (assert (= address put-addresshash)))
      ;(test-case (assert (= put-nodes-count 0)))

      ;(let [[[get-error response-get] (rpc-signed "dht-get" signing-key {"addresshash" address})]
            ;[response-get (or response-get {})]
            ;[seq-get (.get response-get "seq" 0)]
            ;[k-get (.get response-get "k" None)]
            ;[salt-get (.get response-get "salt" nil)]
            ;[value-get (.get response-get "v" nil)]]

        ;(print "DHT new seq:" seq-get)
        ;(print "DHT new salt:" salt-get)
        ;(print "DHT new contents:" value-get)

         ;check GET request value
        ;(test-case (assert (= error nil)))
        ;(test-case (assert (= k-get verify-key)))
        ;(test-case (assert (= seq-get seq-put)))
        ;(test-case (assert (= value-get value-put)))))
    ))

