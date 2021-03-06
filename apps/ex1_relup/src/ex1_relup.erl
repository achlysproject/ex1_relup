%%%-------------------------------------------------------------------
%%% @author Maxim Fedorov <maximfca@gmail.com>
%%% @copyright (C) 2019, Maxim Fedorov
%%% @doc
%%%     Prints a message to stdout every NNNN milliseconds.
%%% @end
%%%-------------------------------------------------------------------
-module(ex1_relup).
-author("maximfca@gmail.com").

-behaviour(gen_server).

%% Configuration change validation API
%% See LESSON1.md to find out why it is important.
-export([ticker/1]).

%% API
-export([start_link/0]).

%% gen_server callbacks
-export([init/1,
    handle_call/3,
    handle_cast/2,
    handle_info/2,
    terminate/2,
    code_change/3]).

-define(SERVER, ?MODULE).

-record(state, {}).

%%%===================================================================
%%% API

%% @doc Validates 'ticker' value change, and returns value ready for
%%  making it persistent.
%% Rejects timeouts less than 200 ms or longer than 60 seconds.
-spec ticker(NewValue :: string()) -> non_neg_integer().
ticker(NewValue) ->
    IntVal = list_to_integer(NewValue),
    true = (IntVal > 200) andalso (IntVal < 60000),
    IntVal.

%%--------------------------------------------------------------------
%% @doc
%% Starts print loop and links to calling process.
-spec(start_link() ->
    {ok, Pid :: pid()} | ignore | {error, Reason :: term()}).
start_link() ->
    gen_server:start_link({local, ?SERVER}, ?MODULE, [], []).

%%%===================================================================
%%% gen_server callbacks
%%%===================================================================

%%--------------------------------------------------------------------
%% @private
%% @doc
%% Initialises printer loop and subscribes to configuration changes.
%%--------------------------------------------------------------------
-spec(init(Args :: term()) ->
    {ok, State :: #state{}} | {ok, State :: #state{}, timeout() | hibernate} |
    {stop, Reason :: term()} | ignore).
init([]) ->
    % subscribe to configuration changes - we need a guarantee that
    %   it succeeds!
    ok = subscription_manager:subscribe(?MODULE),
    handle_info(timer, #state{}),
    {ok, #state{}}.

%%--------------------------------------------------------------------
%% @private
%% @doc
%% Ignores all calls
-spec(handle_call(Request :: term(), From :: {pid(), Tag :: term()},
    State :: #state{}) ->
    {reply, Reply :: term(), NewState :: #state{}} |
    {reply, Reply :: term(), NewState :: #state{}, timeout() | hibernate} |
    {noreply, NewState :: #state{}} |
    {noreply, NewState :: #state{}, timeout() | hibernate} |
    {stop, Reason :: term(), Reply :: term(), NewState :: #state{}} |
    {stop, Reason :: term(), NewState :: #state{}}).
handle_call(_Request, _From, State) ->
    {noreply, State}.

%%--------------------------------------------------------------------
%% @private
%% @doc
%% Ignores all casts
-spec(handle_cast(Request :: term(), State :: #state{}) ->
    {noreply, NewState :: #state{}} |
    {noreply, NewState :: #state{}, timeout() | hibernate} |
    {stop, Reason :: term(), NewState :: #state{}}).
handle_cast(_Request, State) ->
    {noreply, State}.

%%--------------------------------------------------------------------
%% @private
%% @doc
%% Handles timer, printing a message, and rearms the timer.
%% Ignores all other messages.
-spec(handle_info(Info :: timeout() | term(), State :: #state{}) ->
    {noreply, NewState :: #state{}} |
    {noreply, NewState :: #state{}, timeout() | hibernate} |
    {stop, Reason :: term(), NewState :: #state{}}).
handle_info(timer, State) ->
    Ticker = config:get(ticker),
    io:format("Next tick in ~b ms!~n", [Ticker]),
    erlang:send_after(Ticker, self(), timer),
    {noreply, State};
handle_info(_Info, State) ->
    {noreply, State}.

%%--------------------------------------------------------------------
%% @private
%% @doc
%% No cleanup is done (timer is expected to be dropped automatically)
-spec(terminate(Reason :: (normal | shutdown | {shutdown, term()} | term()),
    State :: #state{}) -> term()).
terminate(_Reason, _State) ->
    ok.

%%--------------------------------------------------------------------
%% @private
%% @doc
%% Convert process state when code is changed
-spec(code_change(OldVsn :: term() | {down, term()}, State :: #state{},
    Extra :: term()) ->
    {ok, NewState :: #state{}} | {error, Reason :: term()}).
code_change(_OldVsn, State, _Extra) ->
    {ok, State}.
