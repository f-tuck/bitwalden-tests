(import [requests])
(require hy.contrib.loop)

(def api "http://localhost:8923/sw/")

(defn raw [x]
  (bytes (.encode x "utf8")))

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
