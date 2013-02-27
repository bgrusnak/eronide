#!/bin/sh
erl -sname test9 -pa ebin -pa deps/*/ebin -s test9 \
	-eval "io:format(\"* Point your browser into: http://localhost:99~n\")." 

xx
