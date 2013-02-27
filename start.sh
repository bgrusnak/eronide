#!/bin/sh
erl -sname eronide -pa ebin -pa deps/*/ebin -s eronide \
	-eval "io:format(\"* Point your browser into: http://localhost:8080~n\")." 

xx
