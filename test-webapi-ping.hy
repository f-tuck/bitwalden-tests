(import
  [requests]
  [base58]
  [utils [api]])
(require utils)

(print "Pinging server")
(let [[result (.json (requests.post api :params {"c" "ping"} :timeout 3))]]
  (test-case (assert (= result "pong"))))

