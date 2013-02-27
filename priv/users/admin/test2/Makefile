#

all: 
	@./rebar compile
	
build: install
	
install: get-deps all

get-deps:
	@./rebar get-deps

clean:
	@./rebar clean
	rm -f erl_crash.dump

dist-clean: clean
