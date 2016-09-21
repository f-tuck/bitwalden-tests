(import
  [bencode [bencode]])

(require utils)

(test-case (assert (= (bencode 42) "i42e")))
(test-case (assert (= (bencode "yes") "3:yes")))
(test-case (assert (= (bencode {"hello" 12 "adoob" "ble" "chucho" "Hello! 中英字典"}) (.encode "d5:adoob3:ble6:chucho19:Hello! 中英字典5:helloi12ee" "utf8"))))

