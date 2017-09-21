(import
  [requests]
  [base58]
  [utils [bwserver get-json]])

(require utils)

(print "Testing basic endpoints.")
(test-case (assert (= (get-json "") true)))
(test-case (assert (in "bitwalden" (-> (get-json "bw/info") (.keys)))))
(test-case (assert (= (type (get-json "bw/peers")) dict)))
