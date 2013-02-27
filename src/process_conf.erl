-module(process_conf).

-behaviour(gen_server).

%% API
-export([start_link/0]).

%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/2,
         terminate/2, code_change/3]).

-export([lookup/1, update/2, refresh/0]).

-define(SERVER, ?MODULE).
-define(CONFIGFILE, "eronide.config").

-record(state, {conf}).

start_link() ->
    gen_server:start_link({local, ?SERVER}, ?MODULE, [], []).

init([]) ->
    {ok, Conf} = file:consult(?CONFIGFILE),
    {ok, #state{conf=Conf}}.

handle_call({lookup, Tag}, _From, State) ->
    Reply = case lists:keyfind(Tag, 1, State#state.conf) of
                {Tag, Value} ->
                    Value;
                false ->
                    {error, noinstance}
            end,
    {reply, Reply, State};
    
handle_call({refresh}, _From, _State) ->
    init([]);

handle_call({update, {Tag, Value}}, _From, State) ->
	{ _, IsNewConfItem} = lists:keyfind(Tag, 1, State#state.conf),

	NewConf = if IsNewConfItem  == false ->
			lists:keymerge(1, State#state.conf, [{Tag, Value}])
		;
		true ->
			lists:keyreplace(Tag, 1, State#state.conf, {Tag, Value})
	end,
	file:write_file(?CONFIGFILE, lists:foldl(fun(X, Sum) -> Sum ++ io_lib:print(X) ++ ".\n" end, "", NewConf)),
    
    Reply = ok,
    {reply, Reply, State#state{conf=NewConf}};

handle_call(_Request, _From, State) ->
    Reply = ok,
    {reply, Reply, State}.

handle_cast(_Msg, State) ->
    {noreply, State}.

handle_info(_Info, State) ->
    {noreply, State}.

terminate(_Reason, _State) ->
    ok.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

lookup(Tag) ->
    gen_server:call(?SERVER, {lookup, Tag}).
    
refresh() ->
    gen_server:call(?SERVER, {refresh}).

update(Tag, Value) ->
    gen_server:call(?SERVER, {update, {Tag, Value}}).
