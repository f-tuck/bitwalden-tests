(import
  [requests]
  [hy.models.expression [HyExpression]]
  [hy.models.string [HyString]])

(require hy.contrib.loop)

(def api "http://localhost:8923/sw/")

(defn assoc! [d k v]
  (assoc d k v)
  d)

(defn wait-for-result [k]
  (loop []
    (import [time [sleep]])
    ;(print "polling")
    (let [[result (try (.json (requests.get api :params {"c" "get-queue" "k" k "after" 0} :timeout 3)) (catch [e Exception]))]]
      ;(print "From server:" result)
      (if (not result)
        (do (sleep 0.5)
          (recur))
        result))))

(defn longpoller-thread [messages]
  )

(defn pop-messages-for-id [messages id]
  
  )

(defn print-expression [expr]
  (+ "(" (.join " " (list-comp (cond [(= (type x) HyExpression) (print-expression x)]
                                 [(= (type x) HyString) (+ "\"" x "\"")]
                                 [True (str x)]) [x expr])) ")"))

(defmacro test-case [expr]
  (quasiquote (do
                (print (+ "Test: \t" (unquote (print-expression expr))))
                (unquote expr)
                (print "Pass:\t✔"))))
