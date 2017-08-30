(import
  [os [environ]]
  [random [random]]
  [time [time]]
  [hashlib [sha256 sha1]]
  [requests]
  [jsonrpclib]
  [hy.models.expression [HyExpression]]
  [hy.models.string [HyString]]
  [nacl.signing [SigningKey]]
  [bencode [bencode]]
  [base58 [b58encode b58decode]]
  [base64 [b64encode b64decode]])

(require hy.contrib.loop)

; *** Net

(def api (.get environ "BWSERVER" "http://localhost:8923/sw/"))

(def rpc (let [[s (jsonrpclib.Server (+ api "rpc"))]]
           (fn [method params]
             (cond
               [(= (type params) dict) (apply (getattr s method) [] params)]
               [(= (type params) list) (apply (getattr s method) params)]))))

(defn rpc-signed [method signing-key params]
  (let [[verify-key (b58encode (signing-key.verify_key.__bytes__))]]
    (rpc method (merge (with-signature signing-key (with-timestamp params)) {"k" verify-key}))))

(defn wait-for-result [signing-key id k &optional [after 0]]
  (loop []
    (import [time [sleep]])
    ;(print "wait-for-result polling")
    (let [[result (try
                    (post-to-api signing-key {"c" "get-queue" "u" id "k" k "after" after})
                    (catch [e Exception]))]]
      ;(print "wait-for-result from server:" result)
      (if (not result)
        (do (sleep 0.5)
          (recur))
        result))))

(defn post-to-api [signing-key packet &optional [timeout 30]]
  (let [[verify-key (b58encode (signing-key.verify_key.__bytes__))]]
    (try
      (.json (requests.post api :json (with-signature signing-key (with-timestamp packet)) :timeout timeout))
      (catch [e Exception]))))

; *** Utils

(defn assoc! [d k v]
  (assoc d k v)
  d)

(defn merge [d1 d2] (apply dict [d1] (or d2 {})))

(defn make-client-id []
  (.hexdigest (sha256 (str (random)))))

(defn with-timestamp [params]
  (merge params {"t" (int (* (time) 1000))}))

; *** Crypto

(defn extract-keys [seed]
  (let [[signing-key (SigningKey (b58decode seed))]
        [verify-key (b58encode (signing-key.verify_key.__bytes__))]]
    [signing-key verify-key]))

(defn dht-compute-sig [k params]
  (b64encode (bytes (. (k.sign (bytes (slice (bencode params) 1 -1))) signature))))

(defn with-signature [k params]
  (merge params {"s" (b64encode (bytes (. (k.sign (bytes (bencode params))) signature)))}))

(defn verify-signature [k params]
  (let [[signature (b64decode (.pop params "s"))]]
    (k.verify (bytes (bencode params)) signature)))

(defn dht-address [k salt]
  (.hexdigest (sha1 (+ (b58decode k) (bytes salt)))))

(defn compute-infohash [content-name content]
  (let [[length 16384] ; webtorrent default piece length
        [pieces (.join (bytes "") (list-comp (.digest (sha1 (slice (bytes content) (+ 0 i) (+ length i)))) [i (range 0 (len (bytes content)) length)]))]
        [info {"length" (len (bytes content))
               "piece length" length
               "pieces" pieces
               "name" (bytes content-name)}]]
    (.hexdigest (sha1 (bencode info)))))

; *** Test harness

(defn print-expression [expr]
  (+ "(" (.join " " (list-comp (cond [(= (type x) HyExpression) (print-expression x)]
                                 [(= (type x) HyString) (+ "\"" x "\"")]
                                 [True (str x)]) [x expr])) ")"))

(defmacro test-case [expr]
  (quasiquote (do
                (print (+ "Test: \t" (unquote (print-expression expr))))
                (unquote expr)
                (print "Pass:\t✔"))))

