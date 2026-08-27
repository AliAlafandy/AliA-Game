/*

Copyright (c) 2017-2019, Feral Interactive
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

 * Redistributions of source code must retain the above copyright notice,
   this list of conditions and the following disclaimer.
 * Redistributions in binary form must reproduce the above copyright
   notice, this list of conditions and the following disclaimer in the
   documentation and/or other materials provided with the distribution.
 * Neither the name of Feral Interactive nor the names of its contributors
   may be used to endorse or promote products derived from this software
   without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
POSSIBILITY OF SUCH DAMAGE.

 */
#ifndef CLIENT_GAMEMODE_H
#define CLIENT_GAMEMODE_H

#include <stdbool.h>
#include <stdio.h>

#include <dlfcn.h>
#include <string.h>

#include <assert.h>
#include <errno.h>
#include <time.h>

#include <sys/types.h>
#include <unistd.h>

#ifdef __cplusplus
#include <atomic>
#include <mutex>
#endif

static char internal_gamemode_client_error_string[512] = { 0 };

static volatile int internal_libgamemode_loaded = 1;

#ifdef __cplusplus
static std::mutex internal_gamemode_load_mutex;
#else
#include <pthread.h>
static pthread_mutex_t internal_gamemode_load_mutex = PTHREAD_MUTEX_INITIALIZER;
#endif

typedef int (*api_call_return_int)(void);
typedef const char *(*api_call_return_cstring)(void);
typedef int (*api_call_pid_return_int)(pid_t);

static api_call_return_int REAL_internal_gamemode_request_start = NULL;
static api_call_return_int REAL_internal_gamemode_request_end = NULL;
static api_call_return_int REAL_internal_gamemode_query_status = NULL;
static api_call_return_cstring REAL_internal_gamemode_error_string = NULL;
static api_call_pid_return_int REAL_internal_gamemode_request_start_for = NULL;
static api_call_pid_return_int REAL_internal_gamemode_request_end_for = NULL;
static api_call_pid_return_int REAL_internal_gamemode_query_status_for = NULL;

__attribute__((always_inline)) static inline int internal_bind_libgamemode_symbol(
    void *handle, const char *name, void **out_func, size_t func_size, bool required)
{
	void *symbol_lookup = NULL;
	char *dl_error = NULL;

	symbol_lookup = dlsym(handle, name);
	dl_error = dlerror();
	if (required && (dl_error || !symbol_lookup)) {
		snprintf(internal_gamemode_client_error_string,
		         sizeof(internal_gamemode_client_error_string),
		         "dlsym failed - %s",
		         dl_error);
		return -1;
	}

	memcpy(out_func, &symbol_lookup, func_size);
	return 0;
}

__attribute__((always_inline)) static inline int internal_load_libgamemode_unlocked(void)
{
	if (internal_libgamemode_loaded != 1) {
		return internal_libgamemode_loaded;
	}

	struct binding {
		const char *name;
		void **functor;
		size_t func_size;
		bool required;
	} bindings[] = {
		{ "real_gamemode_request_start",
		  (void **)&REAL_internal_gamemode_request_start,
		  sizeof(REAL_internal_gamemode_request_start),
		  true },
		{ "real_gamemode_request_end",
		  (void **)&REAL_internal_gamemode_request_end,
		  sizeof(REAL_internal_gamemode_request_end),
		  true },
		{ "real_gamemode_query_status",
		  (void **)&REAL_internal_gamemode_query_status,
		  sizeof(REAL_internal_gamemode_query_status),
		  false },
		{ "real_gamemode_error_string",
		  (void **)&REAL_internal_gamemode_error_string,
		  sizeof(REAL_internal_gamemode_error_string),
		  true },
		{ "real_gamemode_request_start_for",
		  (void **)&REAL_internal_gamemode_request_start_for,
		  sizeof(REAL_internal_gamemode_request_start_for),
		  false },
		{ "real_gamemode_request_end_for",
		  (void **)&REAL_internal_gamemode_request_end_for,
		  sizeof(REAL_internal_gamemode_request_end_for),
		  false },
		{ "real_gamemode_query_status_for",
		  (void **)&REAL_internal_gamemode_query_status_for,
		  sizeof(REAL_internal_gamemode_query_status_for),
		  false },
	};

	void *libgamemode = NULL;

	libgamemode = dlopen("libgamemode.so.0", RTLD_NOW);
	if (!libgamemode) {
		libgamemode = dlopen("libgamemode.so", RTLD_NOW);
		if (!libgamemode) {
			snprintf(internal_gamemode_client_error_string,
			         sizeof(internal_gamemode_client_error_string),
			         "dlopen failed - %s",
			         dlerror());
			internal_libgamemode_loaded = -1;
			return -1;
		}
	}

	for (size_t i = 0; i < sizeof(bindings) / sizeof(bindings[0]); i++) {
		struct binding *binder = &bindings[i];

		if (internal_bind_libgamemode_symbol(libgamemode,
		                                     binder->name,
		                                     binder->functor,
		                                     binder->func_size,
		                                     binder->required)) {
			internal_libgamemode_loaded = -1;
			return -1;
		};
	}

	internal_libgamemode_loaded = 0;
	return 0;
}

__attribute__((always_inline)) static inline int internal_load_libgamemode(void)
{
	int result;

#ifdef __cplusplus
	std::lock_guard<std::mutex> lock(internal_gamemode_load_mutex);
	result = internal_load_libgamemode_unlocked();
#else
	pthread_mutex_lock(&internal_gamemode_load_mutex);
	result = internal_load_libgamemode_unlocked();
	pthread_mutex_unlock(&internal_gamemode_load_mutex);
#endif

	return result;
}

__attribute__((always_inline)) static inline const char *gamemode_error_string(void)
{
	if (internal_load_libgamemode() < 0 || internal_gamemode_client_error_string[0] != '\0') {
		return internal_gamemode_client_error_string;
	}

	assert(REAL_internal_gamemode_error_string != NULL);

	return REAL_internal_gamemode_error_string();
}

#ifdef GAMEMODE_AUTO
__attribute__((constructor))
#else
__attribute__((always_inline)) static inline
#endif
int gamemode_request_start(void)
{
	if (internal_load_libgamemode() < 0) {
#ifdef GAMEMODE_AUTO
		fprintf(stderr, "gamemodeauto: %s\n", gamemode_error_string());
#endif
		return -1;
	}

	assert(REAL_internal_gamemode_request_start != NULL);

	if (REAL_internal_gamemode_request_start() < 0) {
#ifdef GAMEMODE_AUTO
		fprintf(stderr, "gamemodeauto: %s\n", gamemode_error_string());
#endif
		return -1;
	}

	return 0;
}

#ifdef GAMEMODE_AUTO
__attribute__((destructor))
#else
__attribute__((always_inline)) static inline
#endif
int gamemode_request_end(void)
{
	if (internal_load_libgamemode() < 0) {
#ifdef GAMEMODE_AUTO
		fprintf(stderr, "gamemodeauto: %s\n", gamemode_error_string());
#endif
		return -1;
	}

	assert(REAL_internal_gamemode_request_end != NULL);

	if (REAL_internal_gamemode_request_end() < 0) {
#ifdef GAMEMODE_AUTO
		fprintf(stderr, "gamemodeauto: %s\n", gamemode_error_string());
#endif
		return -1;
	}

	return 0;
}

__attribute__((always_inline)) static inline int gamemode_query_status(void)
{
	if (internal_load_libgamemode() < 0) {
		return -1;
	}

	if (REAL_internal_gamemode_query_status == NULL) {
		snprintf(internal_gamemode_client_error_string,
		         sizeof(internal_gamemode_client_error_string),
		         "gamemode_query_status missing (older host?)");
		return -1;
	}

	return REAL_internal_gamemode_query_status();
}

__attribute__((always_inline)) static inline int gamemode_request_start_for(pid_t pid)
{
	if (internal_load_libgamemode() < 0) {
		return -1;
	}

	if (REAL_internal_gamemode_request_start_for == NULL) {
		snprintf(internal_gamemode_client_error_string,
		         sizeof(internal_gamemode_client_error_string),
		         "gamemode_request_start_for missing (older host?)");
		return -1;
	}

	return REAL_internal_gamemode_request_start_for(pid);
}

__attribute__((always_inline)) static inline int gamemode_request_end_for(pid_t pid)
{
	if (internal_load_libgamemode() < 0) {
		return -1;
	}

	if (REAL_internal_gamemode_request_end_for == NULL) {
		snprintf(internal_gamemode_client_error_string,
		         sizeof(internal_gamemode_client_error_string),
		         "gamemode_request_end_for missing (older host?)");
		return -1;
	}

	return REAL_internal_gamemode_request_end_for(pid);
}

__attribute__((always_inline)) static inline int gamemode_query_status_for(pid_t pid)
{
	if (internal_load_libgamemode() < 0) {
		return -1;
	}

	if (REAL_internal_gamemode_query_status_for == NULL) {
		snprintf(internal_gamemode_client_error_string,
		         sizeof(internal_gamemode_client_error_string),
		         "gamemode_query_status_for missing (older host?)");
		return -1;
	}

	return REAL_internal_gamemode_query_status_for(pid);
}

__attribute__((always_inline)) static inline bool gamemode_is_supported(void)
{
	return internal_load_libgamemode() == 0;
}

__attribute__((always_inline)) static inline int gamemode_request_start_retry(int attempts,
                                                                                int delay_ms)
{
	int result = -1;

	for (int i = 0; i < attempts; i++) {
		result = gamemode_request_start();
		if (result == 0) {
			return 0;
		}

		struct timespec ts;
		ts.tv_sec = delay_ms / 1000;
		ts.tv_nsec = (delay_ms % 1000) * 1000000L;
		nanosleep(&ts, NULL);
	}

	return result;
}

__attribute__((always_inline)) static inline bool gamemode_is_active_for_self(void)
{
	return gamemode_query_status() >= 1;
}

__attribute__((always_inline)) static inline bool gamemode_is_registered_for_self(void)
{
	return gamemode_query_status() == 2;
}

#ifdef __cplusplus

class GameModeScope
{
      public:
	explicit GameModeScope(bool autoStart = true) : m_active(false)
	{
		if (autoStart) {
			start();
		}
	}

	~GameModeScope()
	{
		end();
	}

	GameModeScope(const GameModeScope &) = delete;
	GameModeScope &operator=(const GameModeScope &) = delete;

	bool start()
	{
		if (m_active) {
			return true;
		}

		if (gamemode_request_start() == 0) {
			m_active = true;
		}

		return m_active;
	}

	void end()
	{
		if (m_active) {
			gamemode_request_end();
			m_active = false;
		}
	}

	bool isActive() const
	{
		return m_active;
	}

	static const char *lastError()
	{
		return gamemode_error_string();
	}

      private:
	bool m_active;
};

class GameModeScopeFor
{
      public:
	explicit GameModeScopeFor(pid_t pid, bool autoStart = true) : m_pid(pid), m_active(false)
	{
		if (autoStart) {
			start();
		}
	}

	~GameModeScopeFor()
	{
		end();
	}

	GameModeScopeFor(const GameModeScopeFor &) = delete;
	GameModeScopeFor &operator=(const GameModeScopeFor &) = delete;

	bool start()
	{
		if (m_active) {
			return true;
		}

		if (gamemode_request_start_for(m_pid) == 0) {
			m_active = true;
		}

		return m_active;
	}

	void end()
	{
		if (m_active) {
			gamemode_request_end_for(m_pid);
			m_active = false;
		}
	}

	bool isActive() const
	{
		return m_active;
	}

      private:
	pid_t m_pid;
	bool m_active;
};

#endif // __cplusplus

#endif // CLIENT_GAMEMODE_H
