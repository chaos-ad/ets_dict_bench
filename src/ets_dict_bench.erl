-module(ets_dict_bench).
-compile(export_all).

tc(_, _, 0) -> {0, []};
tc(F, A, N) ->
    Before = erlang:now(),
    Result = [ erlang:apply(F, A) || _ <- lists:seq(1, N) ],
    After = erlang:now(),
    {timer:now_diff(After, Before)/N, Result}.

measure(F, A, N) ->
    {Time, Result} = tc(F, A, N),
    {trunc(Time), Result}.


do_test(Size) ->
    EtsInsert = fun(E, I, J) -> lists:foldl( fun(X, true) -> ets:insert(E, {X,100+X}) end, true, lists:seq(I,J) ) end,
    EtsLookup = fun(E, I, J) -> [ ets:lookup(E, X) || X <- lists:seq(I, J) ] end,
    DictInsert = fun(D, I, J) -> lists:foldl(fun(X, Y) -> dict:store(X, X+100, Y) end, D, lists:seq(I,J)) end,
    DictLookup = fun(D, I, J) -> [ dict:find(X, D) || X <- lists:seq(I,J) ] end,

    EtsInsertOne = fun(E) -> X = random:uniform(Size), EtsInsert(E, X, X) end,
    EtsLookupOne = fun(E) -> X = random:uniform(Size), EtsLookup(E, X, X) end,
    DictInsertOne = fun(D) -> X = random:uniform(Size), DictInsert(D, X, X) end,
    DictLookupOne = fun(D) -> X = random:uniform(Size), DictLookup(D, X, X) end,

    E1 = ets:new(ets1, [set]),
    {EtsInsertTime, _} = measure(EtsInsert, [E1, 1, Size], 1),
    {EtsLookupTime, _} = measure(EtsLookup, [E1, 1, Size], 1),
    {AvgEtsInsertTime,  _} = measure(EtsInsertOne, [E1], 1000),
    {AvgEtsLookupTime,  _} = measure(EtsLookupOne, [E1], 1000),
    ets:delete(E1),

    D1 = dict:new(),
    {DictInsertTime, [D2]} = measure(DictInsert, [D1, 1, Size], 1),
    {DictLookupTime,    _} = measure(DictLookup, [D2, 1, Size], 1),
    {AvgDictInsertTime, _} = measure(DictInsertOne, [D1], 1000),
    {AvgDictLookupTime, _} = measure(DictLookupOne, [D2], 1000),

    { [
          "Size"
        , "EtsInsertTime"
        , "EtsLookupTime"
        , "AvgEtsInsertTime"
        , "AvgEtsLookupTime"
        , "DictInsertTime"
        , "DictLookupTime"
        , "AvgDictInsertTime"
        , "AvgDictLookupTime"
      ],
      [
          Size
        , EtsInsertTime
        , EtsLookupTime
        , AvgEtsInsertTime
        , AvgEtsLookupTime
        , DictInsertTime
        , DictLookupTime
        , AvgDictInsertTime
        , AvgDictLookupTime
      ] }.


start_test() ->
    start_test(long).

start_test(short) ->
    start_test(lists:seq(10000, 100000, 10000));

start_test(long) ->
    start_test(lists:seq(10000, 100000, 10000) ++ lists:seq(200000, 1000000, 100000));

start_test(List) when is_list(List) ->
    start_test(List, true).

start_test([], _) -> ok;
start_test([Size|Tail], false) ->
    print_body(do_test(Size)),
    start_test(Tail, false);

start_test([Size|Tail], true) ->
    Result = do_test(Size),
    print_head(Result),
    print_body(Result),
    start_test(Tail, false).

print_head({Head, _}) ->
    io:format("~n|"),
    lists:foreach( fun(L) -> io:format("~18.18s|", [L]) end, Head ),
    io:format("~n").

print_body({_, Body}) ->
    io:format("|"),
    lists:foreach( fun(L) -> io:format("~18.18s|", [integer_to_list(L)]) end, Body ),
    io:format("~n").
