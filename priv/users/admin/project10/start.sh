#!/bin/sh
erl -sname project10 -pa ebin -pa deps/*/ebin -s project10 \
	-eval "io:format(\"* Point your browser into: http://localhost:1010~n\")." 

xx
