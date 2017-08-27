(import
  [requests]
  [base58]
  [utils [rpc]])

(require utils)

(print "Pinging server")
(let [[result (rpc.ping :hello 42)]]
  (test-case (assert (= (get result "hello") 42)))
  (test-case (assert (= (get result "pong") true))))
