(require utils)

(try
  (test-case (assert (= (this-symbol-is-not-defined) true)))
  (catch [NameError] (print "NameError thrown correctly.")))
