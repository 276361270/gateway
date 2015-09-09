all: rm tar console
clean:
	./rebar3 clean -a
tar:compile
	./rebar3 as prod release tar
compile:clean
	./rebar3 compile
debug:
	./rebar3 release	
console: debug
	_build/default/rel/gateway/bin/gateway console
java:
	./rebar3 compile
rm:
	rm -rf _build/default/rel && rm -rf _build/prod/rel
doc:
	./rebar3 edoc


