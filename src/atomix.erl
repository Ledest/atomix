-module(atomix).

-export([new/1, new/2,
         put/3,
         get/2,
         add/3,
         add_get/3,
         sub/3,
         sub_get/3,
         exchange/3,
         compare_exchange/4,
         info/1]).

-export_type([atomics_ref/0]).

-opaque atomics_ref() :: binary().
-ifdef(no_strict_map_type).
-type info() :: #{size => non_neg_integer(), max => integer(), min => integer(), memory => non_neg_integer()}.
-else.
-type info() :: #{size := non_neg_integer(), max := integer(), min := integer(), memory := non_neg_integer()}.
-endif.

-compile(no_inline).

-on_load(load_nif/0).
-define(ATOMICS_NIF_VSN, 1).

-define(OPT_SIGNED, 2#00000001).
-define(OPT_DEFAULT, ?OPT_SIGNED).

load_nif() ->
    P = case code:priv_dir(rar) of
            {error, bad_name} ->
                D1 = filename:join([".", "priv", "lib"]),
                case filelib:is_dir(D1) of
                    true -> D1;
                    _ ->
                        D2 = [$.|D1],
                        case filelib:is_dir(D2) of
                            true -> D2;
                            _ -> "."
                        end
                end;
            D -> D
        end,
    E = file:native_name_encoding(),
    L = filename:join(P, "atomix"),
    erlang:load_nif(L, {?ATOMICS_NIF_VSN, unicode:characters_to_binary(L, E, E)}).

-spec new(Arity::pos_integer()) -> atomics_ref().
new(Arity) -> atomics_new(Arity, ?OPT_DEFAULT band (bnot ?OPT_SIGNED)).

-spec new(Arity::pos_integer(), Opts::[{signed, boolean()}]) -> atomics_ref().
new(Arity, Opts) -> atomics_new(Arity, encode_opts(Opts, ?OPT_DEFAULT)).

-spec atomics_new(Arity::pos_integer(), Opts::non_neg_integer()) -> atomics_ref().
atomics_new(_Arity, _Opts) -> erlang:nif_error(undef).

encode_opts([{signed, true}|T], Acc) -> encode_opts(T, Acc bor ?OPT_SIGNED);
encode_opts([{signed, false}|T], Acc) -> encode_opts(T, Acc band (bnot ?OPT_SIGNED));
encode_opts([], Acc) -> Acc;
encode_opts(_, _) -> error(badarg).

-spec put(Ref::atomics_ref(), Ix::integer(), Value::integer()) -> ok.
put(_Ref, _Ix, _Value) -> erlang:nif_error(undef).

-spec get(Ref::atomics_ref(), Ix::integer()) -> integer().
get(_Ref, _Ix) -> erlang:nif_error(undef).

-spec add(Ref::atomics_ref(), Ix::integer(), Incr::integer()) -> ok.
add(_Ref, _Ix, _Incr) -> erlang:nif_error(undef).

-spec add_get(Ref::atomics_ref(), Ix::integer(), Incr::integer()) -> integer().
add_get(_Ref, _Ix, _Incr) -> erlang:nif_error(undef).

-spec sub(Ref::atomics_ref(), Ix::integer(), Decr::integer()) -> ok.
sub(_Ref, _Ix, _Decr) -> erlang:nif_error(undef).

-spec sub_get(Ref::atomics_ref(), Ix::integer(), Decr::integer()) -> integer().
sub_get(_Ref, _Ix, _Decr) -> erlang:nif_error(undef).

-spec exchange(Ref::atomics_ref(), Ix::integer(), Desired::integer()) -> integer().
exchange(_Ref, _Ix, _Desired) -> erlang:nif_error(undef).

-spec compare_exchange(Ref::atomics_ref(), Ix::integer(), Expected::integer(), Desired::integer()) -> ok | integer().
compare_exchange(_Ref, _Ix, _Expected, _Desired) -> erlang:nif_error(undef).

-spec info(Ref::atomics_ref()) -> info().
info(_Ref) -> erlang:nif_error(undef).
