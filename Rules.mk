.SECONDEXPANSION:
.PRECIOUS: $(__SRC__)/%/
$(__SRC__)/%/:
	mkdir -p $@

deferred-asset :
clean-asset ::