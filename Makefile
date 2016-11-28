TESTS=bad bencode keys dht-address raw-signing parameter-signing

all: $(TESTS:%=logs/test-%.log)

logs:
	mkdir logs

logs/%.log: %.hy logs
	@echo
	@echo "***** $< > $@ *****"
	@./log-test $< $@

.PHONY: clean

clean:
	rm -rf logs

