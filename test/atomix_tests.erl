-module(atomix_tests).

-include_lib("eunit/include/eunit.hrl").

%% Test based on erts/emulator/test/atomics_SUITE.erl

bad_test() ->
    ?assertMatch({'EXIT', {badarg, _}}, catch atomix:new(0, [])),
    ?assertMatch({'EXIT', {badarg, _}}, catch atomix:new(10, [bad])),
    ?assertMatch({'EXIT', {badarg, _}}, catch atomix:new(10, [{signed, bad}])),
    ?assertMatch({'EXIT', {badarg, _}}, catch atomix:new(10, [{signed, true}, bad])),
    ?assertMatch({'EXIT', {badarg, _}}, catch atomix:new(10, [{signed, false}|bad])),
    Ref = atomix:new(10, []),
    ?assertMatch({'EXIT', {badarg, _}}, catch atomix:get(1742, 7)),
    ?assertMatch({'EXIT', {badarg, _}}, catch atomix:get(<<>>, 7)),
    ?assertMatch({'EXIT', {badarg, _}}, catch atomix:get(Ref, -1)),
    ?assertMatch({'EXIT', {badarg, _}}, catch atomix:get(Ref, 0)),
    ?assertMatch({'EXIT', {badarg, _}}, catch atomix:get(Ref, 11)),
    ?assertMatch({'EXIT', {badarg, _}}, catch atomix:get(Ref, 7.0)).

-ifndef(MODULE).
signed_test() ->
    Size = 10,
    Ref = atomix:new(Size, []),
    Info = #{memory := Memory} = atomix:info(Ref),
    ?assertMatch(#{size := Size}, Info),
    ?assert(Memory > Size * 8),
    ?assert(Memory < Size * 8 + 100),
    [signed_do(Ref, Ix) || Ix <- lists:seq(1, Size)].

signed_do(Ref, Ix) ->
    ?assertEqual(0, atomix:get(Ref, Ix)),
    ?assertEqual(ok, atomix:put(Ref, Ix, 3)),
    ?assertEqual(ok, atomix:add(Ref, Ix, 14)),
    ?assertEqual(17, atomix:get(Ref, Ix)),
    ?assertEqual(20, atomix:add_get(Ref, Ix, 3)),
    ?assertEqual(-3, atomix:add_get(Ref, Ix, -23)),
    ?assertEqual(17, atomix:add_get(Ref, Ix, 20)),
    ?assertEqual(ok, atomix:sub(Ref, Ix, 4)),
    ?assertEqual(13, atomix:get(Ref, Ix)),
    ?assertEqual(-7, atomix:sub_get(Ref, Ix, 20)),
    ?assertEqual(3, atomix:sub_get(Ref, Ix, -10)),
    ?assertEqual(3, atomix:exchange(Ref, Ix, 666)),
    ?assertEqual(ok, atomix:compare_exchange(Ref, Ix, 666, 777)),
    ?assertEqual(777, atomix:compare_exchange(Ref, Ix, 666, -666)).

signed_limits_test() ->
    Bits = 64,
    Max = (1 bsl (Bits - 1)) - 1,
    Min = -(1 bsl (Bits - 1)),
    Ref = atomix:new(1, [{signed, true}]),
    ?assertMatch(#{max := Max, min := Min}, atomix:info(Ref)),
    ?assertEqual(0, atomix:get(Ref, 1)),
    ?assertEqual(ok, atomix:add(Ref, 1, Max)),
    ?assertEqual(Min, atomix:add_get(Ref, 1, 1)),
    ?assertEqual(Max, atomix:sub_get(Ref, 1, 1)),
    IncrMax = (Max bsl 1) bor 1,
    ?assertEqual(ok, atomix:put(Ref, 1, 0)),
    ?assertEqual(ok, atomix:add(Ref, 1, IncrMax)),
    ?assertEqual(-1, atomix:get(Ref, 1)),
    ?assertMatch({'EXIT', {badarg, _}}, catch atomix:add(Ref, 1, IncrMax + 1)),
    ?assertMatch({'EXIT', {badarg, _}}, catch atomix:add(Ref, 1, Min - 1)),
    ok.
-endif.

unsigned_test() ->
    Size = 10,
    Ref = atomix:new(Size, [{signed, false}]),
    Info = #{memory := Memory} = atomix:info(Ref),
    ?assertMatch(#{size := Size}, Info),
    ?assert(Memory > Size * 8),
    ?assert(Memory < Size * 8 + 100),
    [unsigned_do(Ref, Ix) || Ix <- lists:seq(1, Size)].

unsigned_do(Ref, Ix) ->
    ?assertEqual(0, atomix:get(Ref, Ix)),
    ?assertEqual(ok, atomix:put(Ref, Ix, 3)),
    ?assertEqual(ok, atomix:add(Ref, Ix, 14)),
    ?assertEqual(17, atomix:get(Ref, Ix)),
    ?assertEqual(20, atomix:add_get(Ref, Ix, 3)),
    ?assertEqual(ok, atomix:sub(Ref, Ix, 7)),
    ?assertEqual(13, atomix:get(Ref, Ix)),
    ?assertEqual(3, atomix:sub_get(Ref, Ix, 10)),
    ?assertEqual(3, atomix:exchange(Ref, Ix, 666)),
    ?assertEqual(ok, atomix:compare_exchange(Ref, Ix, 666, 777)),
    ?assertEqual(777, atomix:compare_exchange(Ref, Ix, 666, 888)).

unsigned_limits_test() ->
    Bits = 64,
    Max = (1 bsl Bits) - 1,
    Min = 0,
    Ref = atomix:new(1, [{signed, false}]),
    ?assertMatch(#{max := Max, min := Min}, atomix:info(Ref)),
    ?assertEqual(0, atomix:get(Ref, 1)),
    ?assertEqual(ok, atomix:add(Ref, 1, Max)),
    ?assertEqual(Min, atomix:add_get(Ref, 1, 1)),
    ?assertEqual(Max, atomix:sub_get(Ref, 1, 1)),
    atomix:put(Ref, 1, Max),
    ?assertMatch({'EXIT', {badarg, _}}, catch atomix:add(Ref, 1, Max + 1)),
    IncrMin = -(1 bsl (Bits-1)),
    ?assertEqual(ok, atomix:put(Ref, 1, -IncrMin)),
    %?assertEqual(ok, atomix:add(Ref, 1, IncrMin)),
    %?assertEqual(0, atomix:get(Ref, 1)),
    %?assertMatch({'EXIT', {badarg, _}}, catch atomix:add(Ref, 1, IncrMin - 1)),
    ok.
