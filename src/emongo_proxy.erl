-module(emongo_proxy).
-behaviour(gen_server).
-define(SERVER, ?MODULE).
-compile(export_all).
%% ------------------------------------------------------------------
%% API Function Exports
%% ------------------------------------------------------------------

-export([start_link/0]).

%% ------------------------------------------------------------------
%% gen_server Function Exports
%% ------------------------------------------------------------------

-export([init/1, handle_call/3, handle_cast/2, handle_info/2,
         terminate/2, code_change/3]).

-define(TIMEOUT, 500000).
%% ------------------------------------------------------------------
%% API Function Definitions
%% ------------------------------------------------------------------

start_link() ->
    gen_server:start_link(?MODULE, [], []).

%% ------------------------------------------------------------------
%% gen_server Function Definitions
%% ------------------------------------------------------------------

init(_Args) ->
	{ok, [], ?TIMEOUT}.

handle_call(_Msg, _From, State) ->
	{reply, ok, State}.

handle_cast(_Msg, State) ->
    {noreply, State}.

handle_info({process_async, From, Json}, State) ->
	L = jsx:decode(Json),
	Action = proplists:get_value(<<"action">>, L),
	DB = emongo:tolist(proplists:get_value(<<"db">>, L)),
	Table = emongo:tolist(proplists:get_value(<<"table">>, L)),
	PoolId = emongo:poolid(),
	{Pid2, Pool} = gen_server:call(emongo, {pid, PoolId}, infinity),
	R = gen_server:call(emongo, {process, Action, L, Pid2, Pool, DB, Table}, ?TIMEOUT),
	%%io:format("response is:~p~n", [R]),
	RetID = proplists:get_value(<<"retID">>, L),
	OtherArg = proplists:get_value(<<"othArg">>, L),
	From ! {db_result, emongo:encode(R, RetID, OtherArg)},
    {noreply, State};

handle_info(timeout, State) ->
	{stop, normal, State}.

terminate(_Reason, _State) ->
	ok.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

