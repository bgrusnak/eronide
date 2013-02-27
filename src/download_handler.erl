-module(download_handler).
-behaviour(cowboy_http_handler).
-export([init/3, handle/2, terminate/2]).
-include("eronide.hrl").


init({_Any, http}, Req, []) ->
	process_conf:start_link(),
	{ok, Req, undefined}.

handle(Req, State) ->
	{ok, Req2} = cowboy_http_req:reply(200, [{<<"content-type">>, <<"text/html">>}, 
		{<<"content-encoding">>, <<"utf-8">>}], Body, Req),
	{ok, Req2, State}.	

terminate(_Req, _State) ->
	ok.
