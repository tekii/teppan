.SECONDEXPANSION:
.PRECIOUS: $(__SRC__)/%/
$(__SRC__)/%/:
	mkdir -p $@

cp-deferred-asset :
gzip-asset :
clean-asset ::