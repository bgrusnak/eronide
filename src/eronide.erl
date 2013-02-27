%% Feel free to use, reuse and abuse the code in this file.

-module(eronide).
-behaviour(application).
-export([start/0, start/2, stop/1]).

start() ->
	application:start(sync),
	application:start(lager),
	application:start(mimetypes),
%	,
%	gettext_server:start(),
%	LoadPo = 
%            fun(Lang)->
%                {_, Bin} = file:read_file("./lang/default/"++ Lang ++"/gettext.po"),
%                gettext:store_pofile(Lang, Bin)
%            end,
%        lists:map(LoadPo, ["es","en"]),
	application:start(crypto),
	application:start(public_key),
	application:start(ssl),
	application:start(cowboy),
	application:start(eronide).

start(_Type, _Args) ->
	lager:start(),
%	mimetypes:load(default, [{"erl", "text/x-erlang"}, {"hrl", "text/x-erlang"}]),
%	mimetypes:load(default, [{ <<"erl">> ,  <<"text/x-erlang">> }, { <<"hrl">> ,  <<"text/x-erlang">> }]),
	process_conf:start_link(),
	Dispatch = [
	 {'_', [
		{[<<"websocket">>], websocket_handler, []}
		,{[<<"static">>, '...'], cowboy_http_static,
		[{directory, {priv_dir, eronide, "static"}},
%			{mimetypes, {fun mimetypes:path_to_mimes/2, default}}]}
		  {mimetypes,  [
			  {<<".css">>, [<<"text/css">>]}
			  , {<<".js">>, [<<"application/javascript">>]}
			  , {<<".eot">>, [<<"application/vnd.ms-fontobject">>]}
			  , {<<".svg">>, [<<"image/svg+xml">>]}
			  , {<<".ttf">>, [<<"application/x-font-ttf">>]}
			  , {<<".woff">>, [<<"application/x-font-woff">>]}
			  , {<<".png">>, [<<"image/png">>]}
			  , {<<".jpg">>, [<<"image/jpeg">>]}
			  , {<<".jpeg">>, [<<"image/jpeg">>]}
			  , {<<".gif">>, [<<"image/gif">>]}
			  , {<<".ico">>, [<<"image/x-icon">>]}
			  , {<<".html">>, [<<"text/html">>]}
			  , {<<".htm">>, [<<"text/html">>]}
		  ]}]}			
		, {'_', default_handler, []}
		]}	
	],
  {ok, _} = cowboy:start_listener(my_http_listener, 100,
		cowboy_tcp_transport, [{port, list_to_integer(process_conf:lookup(port))}],
		cowboy_http_protocol, [{dispatch, Dispatch}]
	),
	eronide_sup:start_link().

stop(_State) ->
	ok.
