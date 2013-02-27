%% Feel free to use, reuse and abuse the code in this file.

-module(websocket_handler).
-behaviour(cowboy_http_handler).
-behaviour(cowboy_http_websocket_handler).
-include("eronide.hrl").
-export([init/3, handle/2, terminate/2]).
-export([websocket_init/3, websocket_handle/3,
	websocket_info/3, websocket_terminate/3]).

init({_Any, http}, Req, []) ->
	
	case cowboy_http_req:header('Upgrade', Req) of
		{undefined, Req2} -> {ok, Req2, undefined};
		{<<"websocket">>, _Req2} -> {upgrade, protocol, cowboy_http_websocket};
		{<<"WebSocket">>, _Req2} -> {upgrade, protocol, cowboy_http_websocket}
	end.

handle(Req, State) ->
	{ok, Req2} = cowboy_http_req:reply(200, [{'Content-Type', <<"text/html">>}], <<"">>, Req),
	{ok, Req2, State}.

terminate(_Req, _State) ->
	ok.

websocket_init(_Any, Req, []) ->
%	timer:send_interval(1000, tick),
%mimetypes:load(default, [{ <<"erl">> ,  <<"text/x-erlang">> }, { <<"hrl">> ,  <<"text/x-erlang">> }]),
%mimetypes:load(default, [{"erl", "text/x-erlang"}, {"hrl", "text/x-erlang"}]),
	Req2 = cowboy_http_req:compact(Req),
	{ok, Req2, #rs_state{}, hibernate}.

rendertempfile(Filename, Data) ->
	erlydtl:compile(binary:bin_to_list(Filename), temp_module), 
	{ok, Body}=temp_module:render(Data),
	file:write_file(Filename, Body, [binary])
.


websocket_processor(<<"register">>, Data, State) ->
%	process_conf:refresh(),
	{_, ULogin}=lists:keyfind(<<"login">>, 1, Data),
	Login=filename:basename(ULogin),
	{_, Password}=lists:keyfind(<<"password">>, 1, Data),
	Users=process_conf:lookup(users),
	User=lists:keyfind(Login, 2, Users),
	Ufind=if
		User == false ->
			process_conf:update(users, lists:append(process_conf:lookup(users), [#user{email =Login, password =Password}])),
			file:make_dir(filename:join(process_conf:lookup(usersfolder), Login)),
			{[{<<"state">>, <<"ok">>}, {<<"action">>, <<"register">>}, {<<"data">>, << Login/binary >>}], State}
		;
		true ->
			{[{<<"state">>, <<"error">>}, {<<"action">>, <<"register">>}, {<<"data">>, <<"User already exists">>}], State}
	end,
	Ufind
	;
	
websocket_processor(<<"projects">>, Data, State) ->	
	{_, Do}=lists:keyfind(<<"do">>, 1, Data),
	{_, Pdata}=lists:keyfind(<<"data">>, 1, Data),
	Login=State#rs_state.user,	
	if
		Login==undefined ->
			{[{<<"state">>, <<"error">>}, {<<"action">>, <<"projects">>}, {<<"data">>, <<"User not authorized">>}], State}
		;
		true ->
			Dir =filename:join(process_conf:lookup(usersfolder), Login),
			Config= filename:join(Dir , <<"projects.config" >>),
			if
				Do == <<"list">> ->
					Exists=filelib:is_file(Config),
					{_, Plist}=if 
						Exists ->				
							{ok, Projects}=file:consult(Config),
							lists:keyfind(projects, 1, Projects)
						;
						true ->
							{projects, []}
					end,
					{[{<<"state">>, <<"ok">>}, {<<"action">>, <<"projects">>}, {<<"do">>, Do}, {<<"data">>, Plist}], State}
				;
				Do == <<"load">> ->
					{[{<<"state">>, <<"ok">>}, {<<"action">>, <<"projects">>}, 
					{<<"do">>, Do}, {<<"data">>, [{<<"project">>, Pdata}, 
					{<<"tree">>, jstree:parsefiles(filetree:show(filename:join(Dir, 
					Pdata)), Dir)}]}], State}
				;
				Do == <<"loaddirs">> ->
					{[{<<"state">>, <<"ok">>}, {<<"action">>, <<"projects">>}, {<<"do">>, Do}, {<<"data">>, [{<<"project">>, Pdata}, {<<"tree">>, jstree:parsefiles(filetree:showdirs(filename:join(Dir, Pdata)), Dir)}]}], State}
				;
				Do == <<"ls">> ->
					Fret=filetree:showfiles(filename:join(Dir, Pdata)),
					{[{<<"state">>, <<"ok">>}, {<<"action">>, <<"projects">>}, {<<"do">>, Do}, {<<"data">>, Fret}], State}
				;
				Do == <<"loadfile">> ->
					Filename = filename:join(Dir , Pdata),
					{ok, File }  = file:read_file(binary:bin_to_list(Filename)),		
					{[{<<"state">>, <<"ok">>}, {<<"action">>, <<"projects">>}, {<<"do">>, Do}, {<<"data">>, [ {<<"filename">>, Pdata}, {<<"mimetype">>, mimetypes:filename(Filename)}, {<<"content">>, <<File/binary>>}] }], State}
				;
				Do == <<"reloadfile">> ->
					Filename = filename:join(Dir , Pdata),
					{ok, File }  = file:read_file(binary:bin_to_list(Filename)),		
					{[{<<"state">>, <<"ok">>}, {<<"action">>, <<"projects">>}, {<<"do">>, Do}, {<<"data">>, [ {<<"filename">>, Pdata}, {<<"mimetype">>, mimetypes:filename(Filename)}, {<<"content">>, <<File/binary>>}] }], State}
				;
				Do == <<"movefile">> ->
					{_, Oldname}=lists:keyfind(<<"oldname">>, 1, Pdata),
					{_, Newname}=lists:keyfind(<<"newname">>, 1, Pdata),
					Filestate= file:rename(binary:bin_to_list(filename:join(Dir , Oldname)), binary:bin_to_list(filename:join(Dir , Newname))),
					case Filestate of
						{error, Reason}  ->
							Rl=atom_to_list(Reason),
							{[{<<"state">>, <<"error">>}, {<<"action">>, <<"unknown">>}, {<<"data">>, << "Error: ", Rl >>}], State};
						_Else ->
							{[{<<"state">>, <<"ok">>}, {<<"action">>, <<"projects">>}, {<<"do">>, Do}], State}
						end	
				;
				Do == <<"deletefile">> ->
					Filename = filename:join(Dir , Pdata),
					Filestate= file:delete(binary:bin_to_list(filename:join(Dir , Filename))),
					case Filestate of
						{error, Reason}  ->
							Rl=atom_to_list(Reason),
							{[{<<"state">>, <<"error">>}, {<<"action">>, <<"unknown">>}, {<<"data">>, << "Error: ", Rl >>}], State};
						_Else ->
							{[{<<"state">>, <<"ok">>}, {<<"action">>, <<"projects">>}, {<<"do">>, Do}], State}
						end	
				;
				Do == <<"copyfile">> ->
					{_, Oldname}=lists:keyfind(<<"oldname">>, 1, Pdata),
					{_, Newname}=lists:keyfind(<<"newname">>, 1, Pdata),
					Filestate= file:copy(binary:bin_to_list(filename:join(Dir , Oldname)), binary:bin_to_list(filename:join(Dir , Newname))),
					case Filestate of
						{error, Reason}  ->
							Rl=atom_to_list(Reason),
							{[{<<"state">>, <<"error">>}, {<<"action">>, <<"unknown">>}, {<<"data">>, << "Error: ", Rl >>}], State};
						_Else ->
							{[{<<"state">>, <<"ok">>}, {<<"action">>, <<"projects">>}, {<<"do">>, Do}], State}
						end	
				;
				Do == <<"savefile">> ->
					{_, Fname}=lists:keyfind(<<"filename">>, 1, Pdata),
					{_, Bytes}=lists:keyfind(<<"content">>, 1, Pdata),
					Filename = filename:join(Dir , Fname),
					Filestate=file:write_file(binary:bin_to_list(Filename), << 
					Bytes/binary >>,[ binary]),
					case Filestate of
						{error, Reason}  ->
							Rl=atom_to_list(Reason),
							{[{<<"state">>, <<"error">>}, {<<"action">>, <<"unknown">>}, {<<"data">>, << "Error: ", Rl  >>}], State};
						_Else ->
							{[{<<"state">>, <<"ok">>}, {<<"action">>, <<"projects">>}, {<<"do">>, Do}, {<<"data">>,  Fname}], State}
						end					
				;
				Do == <<"create">> ->
					{_, Projectname}=lists:keyfind(<<"name">>, 1, Pdata),
					{_, Templatename}=lists:keyfind(<<"template">>, 1, Pdata),
					Templates=process_conf:lookup(ptemplates),
					[Template]=lists:filter(fun(X) -> 
						{_, N}=lists:keyfind(name, 1, X), 
						N == binary:bin_to_list(Templatename)
					end, Templates),
					Newdir=filename:join(Dir , Projectname),
					file:make_dir(Newdir),
					Src=lists:keyfind(source, 1, Template),
					if 
						Src == false ->
							Src
						;
% if exists source template for the project
						true ->
							{_, Source} = Src,
							Ptemplatesfolder =  process_conf:lookup(ptemplatesfolder),
							erl_tar:extract(filename:join(Ptemplatesfolder , Source), [compressed, {cwd,Newdir}]),
% if exists files for processing
							Psource=lists:keyfind(processfiles, 1, Template),
							if 
								Psource == false ->
									Psource;
								true ->
									{_, Pfiles} = Psource, 
									Atomized=lists:map(fun(X) -> {A, V} = X, {list_to_atom(binary:bin_to_list(A)), V} end, Pdata),
									lists:foreach(fun(X) -> rendertempfile(filename:join(Newdir, X), Atomized) end, Pfiles)
							end,
% if exists nameholder, search all files and replace nameholder to the name of project		
							Nsource=lists:keyfind(nameholder, 1, Template),
							if 
								Nsource == false ->
									Nsource;
								true ->
									{_, Nameholder} = Nsource, 
									filetree:renamefiles(Newdir, Nameholder, Projectname)
							end
					end,
					Config=filename:join(Dir , <<"projects.config" >>),
					Pfound=file:consult(Config),
					Newproject={project, [{name, Projectname}, {icon, <<"Blank_template.png">>}, {description, <<"">>}]},
					NewConf= case Pfound of
						{error, _} ->
							{projects, [{project, [Newproject]}]}
						;
						{ok,[{_, Projlist}]} ->
							{projects, lists:append(Projlist, [Newproject])}
					end,
					file:write_file(Config, io_lib:fwrite("~p.\n",[NewConf]), [write]),
					{[{<<"state">>, <<"ok">>}, {<<"action">>, <<"projects">>},  {<<"do">>, <<"list">>}, {<<"data">>, [{<<"project">>, Projectname}, {<<"tree">>, jstree:parsefiles(filetree:show(Newdir), Dir)}]}], State}
				;
				true ->
					{[{<<"state">>, <<"error">>}, {<<"action">>, <<"projects">>}, {<<"data">>, <<"Wrong projects command">>}], State}
			end
		end
;
	
websocket_processor(<<"login">>, Data, State) ->
%	process_conf:refresh(),
	{_, ULogin}=lists:keyfind(<<"login">>, 1, Data),
	Login=filename:basename(ULogin),
	{_, Password}=lists:keyfind(<<"password">>, 1, Data),
	Ls=process_conf:lookup(adminlogin)==Login,
	Ps=process_conf:lookup(adminpass)==Password,
	Afind=Ls and Ps,
	Users=process_conf:lookup(users),
	User=lists:keyfind(Login, 2, Users),
	Ufind=if
		User /= false ->
			User#user.password==Password
		;
		true ->
			false
	end,
	if
        Afind or Ufind ->     
            {[{<<"state">>, <<"ok">>}, {<<"action">>, <<"login">>}, {<<"data">>, << Login/binary >> }], State#rs_state{user=Login}}
        ;
        true -> 
			{[{<<"state">>, <<"error">>}, {<<"action">>, <<"login">>}, {<<"data">>, <<"Non-existent user or wrong password">>}], State}
    end
;
websocket_processor(_, _Data, State) ->
	{[{<<"state">>, <<"error">>}, {<<"action">>, <<"unknown">>}, {<<"data">>, _Data}], State}
.

websocket_handle({text, Msg}, Req, State) ->
%lager:debug(binary:bin_to_list(Msg)),
%lager:info(binary:bin_to_list(Msg)),
	[{Command, Data}]=jsx:decode(Msg),
	{Reply, Newstate}=websocket_processor(Command, Data, State),	
	{reply, {text, jsx:encode(Reply)}, Req, Newstate, hibernate};
	
websocket_handle(_Any, Req, State) ->
%lager:info(_Any),
	{ok, Req, State}.

websocket_info(tick, Req, State) ->
	{reply, {text, <<"Tick">>}, Req, State, hibernate};
websocket_info(_Info, Req, State) ->
	{ok, Req, State, hibernate}.

websocket_terminate(_Reason, _Req, _State) ->
	ok.
