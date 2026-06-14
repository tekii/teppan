.SECONDEXPANSION:
.PRECIOUS: $(__SRC__)/%/
$(__SRC__)/%/:
	mkdir -p $@

.PHONY: cp-deferred-asset gzip-asset clean-asset
cp-deferred-asset :
gzip-asset :
clean-asset ::