#!/bin/sh
erl -sname {{name}} -pa ebin -pa deps/*/ebin -s {{name}} \
	-eval "io:format(\"* Point your browser into: http://localhost:{{port}}~n\")." 

xx
