
-module(default_handler).
-behaviour(cowboy_http_handler).
-export([init/3, handle/2, terminate/2]).
-include("eronide.hrl").

init({_Any, http}, Req, []) ->
	process_conf:start_link(),
	{ok, Req, undefined}.

	
handle(Req, State) ->
	erlydtl_compiler:compile("./templates/layout.dtl", layout_dtl),
	{_,[{_, Host}]}= inet:ifget("eth0", [addr]),
	{ok, Body} = layout_dtl:render([
		{is_logged, false},
		{title, "ErOnIDE"},
		{description, "Online IDE for Erlang - host once, develop everywhere"},
		{keywords, ["Erlang", "IDE"]},
		{author, "Ilya A. Shlyakhovoy, info@cmsaas.info"},
		{google_analytics, ""},
		{robots, "Viva la Robots!"},
		{host, inet_parse:ntoa(Host)},
		{port, process_conf:lookup(port)},
		{ptemplates, process_conf:lookup(ptemplates)},
		{filetypes, process_conf:lookup(filetypes)},
		{ptemplatesfolder, process_conf:lookup(ptemplatesfolder)},
		{template, process_conf:lookup(template)}
	]),
	{ok, Req2} = cowboy_http_req:reply(200, [{<<"content-type">>, <<"text/html">>}, 
		{<<"content-encoding">>, <<"utf-8">>}], Body, Req),
	{ok, Req2, State}.	

terminate(_Req, _State) ->
	ok.
