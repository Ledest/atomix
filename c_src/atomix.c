#include <stdint.h>
#include <stdbool.h>
#include <string.h>
#include "erl_nif.h"

#define OPT_SIGNED 0b00000001

static ERL_NIF_TERM ATOM_OK;

typedef struct {
	uint32_t opts;
	uint32_t arity;
	uint64_t array[0];
} atomics_handle_t;

static ErlNifResourceType *atomics_handle_resource = NULL;

ERL_NIF_TERM new(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[])
{
	unsigned int arity;
	unsigned int opts;

	if (enif_get_uint(env, argv[0], &arity) && arity && enif_get_uint(env, argv[1], &opts)) {
		ERL_NIF_TERM r;
		size_t size = arity * sizeof(uint64_t);
		atomics_handle_t* h = enif_alloc_resource(atomics_handle_resource, sizeof(atomics_handle_t) + size);

		h->opts = opts;
		h->arity = arity;
		memset(h->array, 0, size);
		r = enif_make_resource(env, h);
		enif_release_resource(h);
		return r;
	}
	return enif_make_badarg(env);
}

ERL_NIF_TERM get(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[])
{
	atomics_handle_t* h;
	unsigned int i;

	return enif_get_resource(env, argv[0], atomics_handle_resource, (void*)&h) &&
	       enif_get_uint(env, argv[1], &i) && i && i <= h->arity
	       ? enif_make_uint64(env, __atomic_load_n(h->array + i - 1, __ATOMIC_RELAXED))
	       : enif_make_badarg(env);
}

ERL_NIF_TERM put(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[])
{
	atomics_handle_t* h;
	unsigned int i;
	uint64_t v;

	if (enif_get_resource(env, argv[0], atomics_handle_resource, (void*)&h) &&
	    enif_get_uint(env, argv[1], &i) && i && i <= h->arity && enif_get_uint64(env, argv[2], &v)) {
		__atomic_store_n(h->array + i - 1, v, __ATOMIC_RELAXED);
		return ATOM_OK;
	}
	return enif_make_badarg(env);
}

ERL_NIF_TERM add(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[])
{
	atomics_handle_t* h;
	unsigned int i;
	uint64_t v;

	if (enif_get_resource(env, argv[0], atomics_handle_resource, (void*)&h) &&
	    enif_get_uint(env, argv[1], &i) && i && i <= h->arity && enif_get_uint64(env, argv[2], &v)) {
		__atomic_add_fetch(h->array + i - 1, v, __ATOMIC_RELAXED);
		return ATOM_OK;
	}
	return enif_make_badarg(env);
}

ERL_NIF_TERM sub(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[])
{
	atomics_handle_t* h;
	unsigned int i;
	uint64_t v;

	if (enif_get_resource(env, argv[0], atomics_handle_resource, (void*)&h) &&
	    enif_get_uint(env, argv[1], &i) && i && i <= h->arity && enif_get_uint64(env, argv[2], &v)) {
		__atomic_sub_fetch(h->array + i - 1, v, __ATOMIC_RELAXED);
		return ATOM_OK;
	}
	return enif_make_badarg(env);
}

ERL_NIF_TERM add_get(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[])
{
	atomics_handle_t* h;
	unsigned int i;
	uint64_t v;

	return enif_get_resource(env, argv[0], atomics_handle_resource, (void*)&h) &&
	       enif_get_uint(env, argv[1], &i) && i && i <= h->arity && enif_get_uint64(env, argv[2], &v)
	       ? enif_make_uint64(env, __atomic_add_fetch(h->array + i - 1, v, __ATOMIC_RELAXED))
	       : enif_make_badarg(env);
}

ERL_NIF_TERM sub_get(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[])
{
	atomics_handle_t* h;
	unsigned int i;
	uint64_t v;

	return enif_get_resource(env, argv[0], atomics_handle_resource, (void*)&h) &&
	       enif_get_uint(env, argv[1], &i) && i && i <= h->arity && enif_get_uint64(env, argv[2], &v)
	       ? enif_make_uint64(env, __atomic_sub_fetch(h->array + i - 1, v, __ATOMIC_RELAXED))
	       : enif_make_badarg(env);
}

ERL_NIF_TERM exchange(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[])
{
	atomics_handle_t* h;
	unsigned int i;
	uint64_t v;

	return enif_get_resource(env, argv[0], atomics_handle_resource, (void*)&h) &&
	       enif_get_uint(env, argv[1], &i) && i && i <= h->arity && enif_get_uint64(env, argv[2], &v)
	       ? enif_make_uint64(env, __atomic_exchange_n(h->array + i - 1, v, __ATOMIC_RELAXED))
	       : enif_make_badarg(env);
}

ERL_NIF_TERM compare_exchange(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[])
{
	atomics_handle_t* h;
	unsigned int i;
	uint64_t e, d;

	if (enif_get_resource(env, argv[0], atomics_handle_resource, (void*)&h) &&
	    enif_get_uint(env, argv[1], &i) && i && i <= h->arity &&
	    enif_get_uint64(env, argv[2], &e) && enif_get_uint64(env, argv[3], &d))
		return __atomic_compare_exchange_n(h->array + i - 1, &e, d, true, __ATOMIC_RELAXED, __ATOMIC_RELAXED)
		       ? ATOM_OK
		       : enif_make_uint64(env, e);
	return enif_make_badarg(env);
}

ERL_NIF_TERM info(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[])
{
	atomics_handle_t* h;

	if (enif_get_resource(env, argv[0], atomics_handle_resource, (void*)&h)) {
		uint64_t max, min;

		if (h->opts & OPT_SIGNED) {
			max = INT64_MAX;
			min = INT64_MIN;
		} else {
			max = UINT64_MAX;
			min = 0;
		}
		return enif_make_list4(env,
				       enif_make_tuple2(env, enif_make_atom(env, "size"), enif_make_uint(env, h->arity)),
				       enif_make_tuple2(env, enif_make_atom(env, "max"), enif_make_uint64(env, max)),
				       enif_make_tuple2(env, enif_make_atom(env, "min"), enif_make_uint64(env, min)),
				       enif_make_tuple2(env, enif_make_atom(env, "memory"),
							enif_make_uint64(env, h->arity * sizeof(uint64_t) + 40)));
	}
	return enif_make_badarg(env);
}

static void atomics_handle_dtor(ErlNifEnv *env, void *r)
{
	enif_release_resource(r);
}

static int on_load(ErlNifEnv* env, void** priv, ERL_NIF_TERM info)
{
	ATOM_OK = enif_make_atom(env, "ok");
	atomics_handle_resource = enif_open_resource_type(env, NULL, "atomics_handle", &atomics_handle_dtor,
							  ERL_NIF_RT_CREATE | ERL_NIF_RT_TAKEOVER, NULL);
	return 0;
}

static int on_reload(ErlNifEnv* env, void**priv, ERL_NIF_TERM info)
{
	return 0;
}

static int on_upgrade(ErlNifEnv* env, void** priv, void** old_priv, ERL_NIF_TERM info)
{
	return 0;
}

static ErlNifFunc nif_functions[] = {
	{"atomics_new", 2, new},
	{"get", 2, get},
	{"put", 3, put},
	{"add", 3, add},
	{"sub", 3, sub},
	{"add_get", 3, add_get},
	{"sub_get", 3, sub_get},
	{"exchange", 3, exchange},
	{"compare_exchange", 4, compare_exchange},
	{"atomics_info", 1, info}
};

ERL_NIF_INIT(atomix, nif_functions, &on_load, &on_reload, &on_upgrade, NULL);
