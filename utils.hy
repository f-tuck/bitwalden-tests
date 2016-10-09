(import
  [random [random]]
  [time [time]]
  [hashlib [sha256]]
  [requests]
  [hy.models.expression [HyExpression]]
  [hy.models.string [HyString]]
  [bencode [bencode]]
  [base64 [b64encode b64decode]])

(require hy.contrib.loop)

(def api "http://localhost:8923/sw/")

(defn assoc! [d k v]
  (assoc d k v)
  d)

(defn merge [d1 d2] (apply dict [d1] (or d2 {})))

(defn wait-for-result [k &optional [after 0]]
  (loop []
    (import [time [sleep]])
    ;(print "polling")
    (let [[result (try (.json (requests.get api :params {"c" "get-queue" "k" k "after" after} :timeout 30)) (catch [e Exception]))]]
      ;(print "From server:" result)
      (if (not result)
        (do (sleep 0.5)
          (recur))
        result))))

(defn make-client-id []
  (.hexdigest (sha256 (str (random)))))

(defn with-timestamp [params]
  (merge params {"t" (int (* (time) 1000))}))

(defn with-signature [k params]
  (merge params {"s" (b64encode (bytes (. (k.sign (bytes (bencode params))) signature)))}))

(defn verify-signature [k params]
  (let [[signature (b64decode (.pop params "s"))]]
    (k.verify (bytes (bencode params)) signature)))

(defn print-expression [expr]
  (+ "(" (.join " " (list-comp (cond [(= (type x) HyExpression) (print-expression x)]
                                 [(= (type x) HyString) (+ "\"" x "\"")]
                                 [True (str x)]) [x expr])) ")"))

(defmacro test-case [expr]
  (quasiquote (do
                (print (+ "Test: \t" (unquote (print-expression expr))))
                (unquote expr)
                (print "Pass:\t✔"))))

