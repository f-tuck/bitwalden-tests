(import [requests])
(import base58)

(def api "http://localhost:8923/sw/")

(print (.json (requests.post api :params {"c" "ping"} :timeout 3)))
