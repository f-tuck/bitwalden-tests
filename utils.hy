(import
  [random [random]]
  [time [time]]
  [hashlib [sha256]]
  [requests]
  [hy.models.expression [HyExpression]]
  [hy.models.string [HyString]]
  [bencode [bencode]]
  [base58 [b58encode b58decode]]
  [base64 [b64encode b64decode]])

(require hy.contrib.loop)

; *** Net

(def api "http://localhost:8923/sw/")

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

(defn with-signature [k params]
  (merge params {"s" (b64encode (bytes (. (k.sign (bytes (bencode params))) signature)))}))

(defn verify-signature [k params]
  (let [[signature (b64decode (.pop params "s"))]]
    (k.verify (bytes (bencode params)) signature)))

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

