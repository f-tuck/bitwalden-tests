TESTS=bad bencode keys dht-address raw-signing parameter-signing webapi-ping webapi-signed-authentication webapi-long-poll webapi-dht webapi-seed webapi-retrieve

all: $(TESTS:%=logs/test-%.log)

logs:
	mkdir logs

logs/%.log: %.hy logs virtualenv/bin/hy
	@echo
	@echo "***** $< > $@ *****"
	@./log-test $< $@

virtualenv/bin/hy: requirements.txt
	@virtualenv virtualenv
	. ./virtualenv/bin/activate && pip install -r requirements.txt

.PHONY: clean

clean:
	rm -rf logs virtualenv

