#!/bin/sh
erl -sname test2 -pa ebin -pa deps/*/ebin -s test2 \
	-eval "io:format(\"* Point your browser into: http://localhost:22~n\")." 

xx
