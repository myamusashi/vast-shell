package main

/*
#cgo pkg-config: libpipewire-0.3

#include <pipewire/pipewire.h>
#include <spa/pod/iter.h>
#include <spa/pod/parser.h>
#include <spa/utils/result.h>
#include <spa/param/profile.h>
#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#include <stdint.h>
#include <errno.h>

static void registry_event_global(void *data, uint32_t id,
    uint32_t permissions, const char *type, uint32_t version,
    const struct spa_dict *props);
static void registry_event_global_remove(void *data, uint32_t id);
static void device_event_info(void *data, const struct pw_device_info *info);
static void device_event_param(void *data, int seq, uint32_t id,
    uint32_t index, uint32_t next, const struct spa_pod *param);

#define MAX_PROFILES  64
#define MAX_STR       256

// Worst-case JSON expansion of a single MAX_STR field:
// Every byte becomes \uXXXX (6 chars), plus 2 quotes = MAX_STR*6 + 2.
#define MAX_STR_JSON  (MAX_STR * 6 + 2)

// Error codes returned via the err out-param of device_to_json.
#define DJ_OK        0
#define DJ_ENOMEM   -1   // malloc failed
#define DJ_EOVERFLOW -2  // buffer arithmetic overflowed (shouldn't happen with
                         // the new cap formula, but kept as a safety net)

typedef struct {
    int32_t index;
    char    name[MAX_STR];
    char    description[MAX_STR];
    char    available[32];
} profile_entry_t;

typedef struct device_node {
    struct pw_proxy           *proxy;
    struct spa_hook           device_listener;
    struct spa_hook           proxy_listener;

    uint32_t                  pw_id;
    char                      name[MAX_STR];

    profile_entry_t           profiles[MAX_PROFILES];
    int                       profile_count;

    profile_entry_t           staging[MAX_PROFILES];
    int                       staging_count;
    int                       enum_seq;

    int32_t                   active_index;
    char                      active_name[MAX_STR];
    char                      active_description[MAX_STR];
    char                      active_available[32];

    int                       dirty;
    struct device_node        *next;
} device_node_t;

typedef struct {
    struct pw_main_loop      *loop;
    struct pw_context        *context;
    struct pw_core           *core;
    struct pw_registry       *registry;
    struct spa_hook           registry_listener;
    device_node_t            *devices;
} app_t;

// tables
static const struct pw_registry_events registry_events = {
    PW_VERSION_REGISTRY_EVENTS,
    .global        = registry_event_global,
    .global_remove = registry_event_global_remove,
};

static const struct pw_device_events device_events = {
    PW_VERSION_DEVICE_EVENTS,
    .info  = device_event_info,
    .param = device_event_param,
};

// helpers
static const char *safe_lookup(const struct spa_dict *dict, const char *key) {
    if (!dict) return "";
    const char *v = spa_dict_lookup(dict, key);
    return v ? v : "";
}

static void safe_copy(char *dst, size_t dst_size, const char *src) {
    if (!src || dst_size == 0) {
        if (dst_size > 0) dst[0] = '\0';
        return;
    }
    size_t i;
    for (i = 0; i < dst_size - 1 && src[i]; i++)
        dst[i] = src[i];
    dst[i] = '\0';
}

// Write a JSON-escaped string into buf[pos..cap).
// Returns new pos. On overflow returns cap (caller checks).
static size_t json_write_str(char *buf, size_t cap, size_t pos, const char *s) {
    if (pos >= cap) return cap;
    buf[pos++] = '"';
    for (; *s; s++) {
        unsigned char c = (unsigned char)*s;
        if (c == '"' || c == '\\') {
            if (pos + 2 > cap) return cap;
            buf[pos++] = '\\';
            buf[pos++] = (char)c;
        } else if (c < 0x20) {
            // "pos + 7 >= cap" (over-guarded by 1 and didn't account for the snprintf result).
			// Now we reserve 6 chars explicitly and validate the snprintf return.
            if (pos + 6 > cap) return cap;
            int written = snprintf(buf + pos, cap - pos, "\\u%04x", c);
            if (written < 0 || (size_t)written > cap - pos) return cap;
            pos += (size_t)written;
        } else {
            if (pos + 1 > cap) return cap;
            buf[pos++] = (char)c;
        }
    }
    // closing '"'
    if (pos + 1 > cap) return cap;
    buf[pos++] = '"';
    return pos;
}

static size_t json_write_lit(char *buf, size_t cap, size_t pos, const char *lit) {
    for (; *lit && pos < cap; lit++)
        buf[pos++] = *lit;
    return pos;
}

static size_t json_write_int(char *buf, size_t cap, size_t pos, int32_t v) {
    if (pos >= cap) return cap;
    int written = snprintf(buf + pos, cap - pos, "%d", v);
    if (written < 0 || (size_t)written >= cap - pos) return cap;
    return pos + (size_t)written;
}

static size_t json_write_uint(char *buf, size_t cap, size_t pos, uint32_t v) {
    if (pos >= cap) return cap;
    int written = snprintf(buf + pos, cap - pos, "%u", v);
    if (written < 0 || (size_t)written >= cap - pos) return cap;
    return pos + (size_t)written;
}

// Returns heap-allocated JSON string; caller must free().
// On failure returns NULL and sets *err to DJ_ENOMEM or DJ_EOVERFLOW.
// On success *err is DJ_OK.
static char *device_to_json(device_node_t *d, int *err) {
    if (err) *err = DJ_OK;

    // each MAX_STR field can expand to MAX_STR_JSON bytes in the worst case.
	// Per profile there are 2 such fields (name + description);
	// the device itself has 1 name + 3 active profile string fields.
	// Add generous fixed overhead for keys/punctuation.
    //
    //   Per profile:  2 * MAX_STR_JSON + 64  (keys + index + available + braces)
    //   Header/footer: 4 * MAX_STR_JSON + 256
    //
    size_t per_profile = 2 * MAX_STR_JSON + 64;
    size_t header      = 4 * MAX_STR_JSON + 256;
    size_t cap         = header + (size_t)d->profile_count * per_profile;

    char *buf = (char *)malloc(cap);
    if (!buf) {
        if (err) *err = DJ_ENOMEM;
        return NULL;
    }

    size_t p = 0;

// Helper macros, OVERFLOW_CHECK sets DJ_EOVERFLOW
#define W_LIT(s)  p = json_write_lit (buf, cap, p, (s))
#define W_STR(s)  p = json_write_str (buf, cap, p, (s))
#define W_INT(v)  p = json_write_int (buf, cap, p, (v))
#define W_UINT(v) p = json_write_uint(buf, cap, p, (v))
#define OVERFLOW_CHECK \
    do { if (p >= cap) { free(buf); if (err) *err = DJ_EOVERFLOW; return NULL; } } while(0)

    W_LIT("{\"deviceId\":"); W_UINT(d->pw_id);
    W_LIT(",\"deviceName\":"); W_STR(d->name);
    W_LIT(",\"activeIndex\":"); W_INT(d->active_index);
    W_LIT(",\"activeProfile\":{");
        W_LIT("\"index\":"); W_INT(d->active_index);
        W_LIT(",\"name\":"); W_STR(d->active_name);
        W_LIT(",\"description\":"); W_STR(d->active_description);
        W_LIT(",\"available\":"); W_STR(d->active_available);
    W_LIT("},\"profiles\":[");
    OVERFLOW_CHECK;

    for (int i = 0; i < d->profile_count; i++) {
        profile_entry_t *e = &d->profiles[i];
        if (i) W_LIT(",");
        W_LIT("{\"index\":"); W_INT(e->index);
        W_LIT(",\"name\":"); W_STR(e->name);
        W_LIT(",\"description\":"); W_STR(e->description);
        W_LIT(",\"available\":"); W_STR(e->available);
        W_LIT("}");
        OVERFLOW_CHECK;
    }

    W_LIT("]}");
    OVERFLOW_CHECK;

    buf[p] = '\0';

#undef W_LIT
#undef W_STR
#undef W_INT
#undef W_UINT
#undef OVERFLOW_CHECK

    return buf;
}

static const char *parse_availability(const struct spa_pod *val) {
    uint32_t av = 0;
    if (spa_pod_get_id(val, &av) != 0)
        return "unknown";
    switch (av) {
    case SPA_PARAM_AVAILABILITY_yes: return "yes";
    case SPA_PARAM_AVAILABILITY_no:  return "no";
    default:                         return "unknown";
    }
}

// device callbacks
static void device_event_info(void *data, const struct pw_device_info *info) {
    device_node_t *d = (device_node_t *)data;
    if (info->props) {
        const char *n = safe_lookup(info->props, PW_KEY_DEVICE_NAME);
        if (*n) safe_copy(d->name, sizeof(d->name), n);
    }
    if (info->change_mask & PW_DEVICE_CHANGE_MASK_PARAMS) {
        // pw_device_enum_params returns the seq number for this round.
        // Store it so device_event_param can discard stale callbacks
        // from previous rounds.
        d->enum_seq      = pw_device_enum_params((struct pw_device *)d->proxy,
                               0, SPA_PARAM_EnumProfile, 0, UINT32_MAX, NULL);
        d->staging_count = 0;   // reset staging for this fresh round

        pw_device_enum_params((struct pw_device *)d->proxy,
            0, SPA_PARAM_Profile, 0, UINT32_MAX, NULL);
    }
}

static void device_event_param(void *data, int seq, uint32_t id,
    uint32_t index, uint32_t next, const struct spa_pod *param) {

    device_node_t *d = (device_node_t *)data;

    if (id == SPA_PARAM_EnumProfile) {
        // Discard callbacks from stale rounds (old device_event_info calls)
        if (seq != d->enum_seq) {
			return;
		};

        // param == NULL or non-object signals end of this sequence —
        // commit whatever we've accumulated in staging.
        if (!param || !spa_pod_is_object(param)) {
            if (d->staging_count > 0) {
                memcpy(d->profiles, d->staging,
                       sizeof(profile_entry_t) * (size_t)d->staging_count);
                d->profile_count = d->staging_count;
                d->dirty         = 1;
            }
            return;
        }

        if (d->staging_count >= MAX_PROFILES) return;

        int32_t     pidx  = -1;
        const char *name  = NULL, *desc = NULL;
        const char *avail = "unknown";

        struct spa_pod_prop *prop;
        SPA_POD_OBJECT_FOREACH((const struct spa_pod_object *)param, prop) {
            switch (prop->key) {
            case SPA_PARAM_PROFILE_index:
                spa_pod_get_int(&prop->value, &pidx);    break;
            case SPA_PARAM_PROFILE_name:
                spa_pod_get_string(&prop->value, &name); break;
            case SPA_PARAM_PROFILE_description:
                spa_pod_get_string(&prop->value, &desc); break;
            case SPA_PARAM_PROFILE_available:
                avail = parse_availability(&prop->value); break;
            }
        }

        profile_entry_t *e = &d->staging[d->staging_count++];
        e->index = pidx;
        safe_copy(e->name,        sizeof(e->name),        name  ? name  : "");
        safe_copy(e->description, sizeof(e->description), desc  ? desc  : "");
        safe_copy(e->available,   sizeof(e->available),   avail);
    } else if (id == SPA_PARAM_Profile) {
    	if (!param || !spa_pod_is_object(param)) return;

    	// SPA_PARAM_Profile selalu datang setelah EnumProfile sequence selesai.
    	// Gunakan ini sebagai trigger commit staging -> profiles[].
    	if (d->staging_count > 0) {
        	memcpy(d->profiles, d->staging,
               sizeof(profile_entry_t) * (size_t)d->staging_count);
        	d->profile_count = d->staging_count;
        	d->staging_count = 0;  // reset agar tidak double-commit
    	}

    	int32_t     pidx  = -1;
    	const char *name  = NULL, *desc = NULL;
    	const char *avail = "unknown";

    	struct spa_pod_prop *prop;
    	SPA_POD_OBJECT_FOREACH((const struct spa_pod_object *)param, prop) {
        	switch (prop->key) {
        	case SPA_PARAM_PROFILE_index:
            	spa_pod_get_int(&prop->value, &pidx);    break;
        	case SPA_PARAM_PROFILE_name:
            	spa_pod_get_string(&prop->value, &name); break;
        	case SPA_PARAM_PROFILE_description:
            	spa_pod_get_string(&prop->value, &desc); break;
        	case SPA_PARAM_PROFILE_available:
            	avail = parse_availability(&prop->value); break;
        	}
    	}

    	d->active_index = pidx;
    	safe_copy(d->active_name,        sizeof(d->active_name),        name  ? name  : "");
    	safe_copy(d->active_description, sizeof(d->active_description), desc  ? desc  : "");
    	safe_copy(d->active_available,   sizeof(d->active_available),   avail);
    	d->dirty = 1;
	}
}

static void on_proxy_destroy(void *data) {
    device_node_t *d = (device_node_t *)data;
    spa_hook_remove(&d->device_listener);
    spa_hook_remove(&d->proxy_listener);
}

static const struct pw_proxy_events proxy_events = {
    PW_VERSION_PROXY_EVENTS,
    .destroy = on_proxy_destroy,
};

static void registry_event_global(void *data, uint32_t id,
    uint32_t permissions, const char *type, uint32_t version,
    const struct spa_dict *props) {

    app_t *app = (app_t *)data;
    if (strcmp(type, PW_TYPE_INTERFACE_Device) != 0) return;

    const char *media_class = safe_lookup(props, PW_KEY_MEDIA_CLASS);
    if (strstr(media_class, "Audio") == NULL) return;

    device_node_t *d = (device_node_t *)calloc(1, sizeof(device_node_t));
    if (!d) return;

    d->pw_id        = id;
    d->active_index = -1;
    safe_copy(d->name, sizeof(d->name), safe_lookup(props, PW_KEY_DEVICE_NAME));

    d->proxy = pw_registry_bind(app->registry, id,
        PW_TYPE_INTERFACE_Device, PW_VERSION_DEVICE, 0);
    if (!d->proxy) { free(d); return; }

    pw_proxy_add_object_listener(d->proxy, &d->device_listener,
        &device_events, d);
    pw_proxy_add_listener(d->proxy, &d->proxy_listener,
        &proxy_events, d);

    d->next      = app->devices;
    app->devices = d;
}

static void registry_event_global_remove(void *data, uint32_t id) {
    app_t          *app  = (app_t *)data;
    device_node_t  *prev = NULL, *d = app->devices;

    while (d) {
        if (d->pw_id == id) {
            if (prev) prev->next = d->next;
            else      app->devices = d->next;
            pw_proxy_destroy(d->proxy);
            free(d);
            return;
        }
        prev = d;
        d    = d->next;
    }
}

// public C API
static app_t *app_create(void) {
    int    argc = 0;
    char **argv = NULL;
    pw_init(&argc, &argv);

    app_t *app = (app_t *)calloc(1, sizeof(app_t));
    if (!app) return NULL;

    app->loop = pw_main_loop_new(NULL);
    if (!app->loop) goto err;

    app->context = pw_context_new(pw_main_loop_get_loop(app->loop), NULL, 0);
    if (!app->context) goto err;

    app->core = pw_context_connect(app->context, NULL, 0);
    if (!app->core) {
        goto err;
    }

    app->registry = pw_core_get_registry(app->core, PW_VERSION_REGISTRY, 0);
    pw_registry_add_listener(app->registry, &app->registry_listener,
        &registry_events, app);

    return app;

err:
    if (app->core)    pw_core_disconnect(app->core);
    if (app->context) pw_context_destroy(app->context);
    if (app->loop)    pw_main_loop_destroy(app->loop);
    free(app);
    return NULL;
}

static void app_destroy(app_t *app) {
    if (!app) return;
    for (device_node_t *d = app->devices, *n; d; d = n) {
        n = d->next;
        pw_proxy_destroy(d->proxy);
        free(d);
    }
    pw_proxy_destroy((struct pw_proxy *)app->registry);
    pw_core_disconnect(app->core);
    pw_context_destroy(app->context);
    pw_main_loop_destroy(app->loop);
    free(app);
    pw_deinit();
}

// the old code ignored the return value
// entirely.  pw_loop_iterate returns the number of dispatched events on
// success, or a negative errno-style value on error.
// We now:
//   - Return 0 on success (any non-negative result).
//   - Return the negative error code on failure so callers can act on it
//     (e.g. reconnect, log, or exit).
//
// The timeout of 500 ms is intentional it makes the call non-blocking for
// the common case while still allowing the kernel to batch short-lived events.
static int app_iterate(app_t *app) {
    struct pw_loop *loop = pw_main_loop_get_loop(app->loop);
    int ret = pw_loop_iterate(loop, 500);
    if (ret < 0) {
        return ret;   // negative errno-style code
    }
    return 0;
}

// *err is set to DJ_OK, DJ_ENOMEM, or DJ_EOVERFLOW
// so the caller can distinguish "nothing dirty" (returns NULL, *err==DJ_OK)
// from a serialisation failure.
static char *drain_dirty(app_t *app, int *err) {
    if (err) *err = DJ_OK;
    for (device_node_t *d = app->devices; d; d = d->next) {
        if (d->dirty && d->profile_count > 0) {
            d->dirty = 0;
            return device_to_json(d, err);
        }
    }
    return NULL;
}

static void app_quit(app_t *app) {
    pw_main_loop_quit(app->loop);
}
*/
import "C"

import (
	"encoding/json"
	"fmt"
	"log"
	"os"
	"os/signal"
	"path/filepath"
	"runtime"
	"strings"
	"syscall"
	"time"
	"unsafe"
)

func stateDir() string {
	if xdg := os.Getenv("XDG_RUNTIME_DIR"); xdg != "" {
		return filepath.Join(xdg, "pw-profiles")
	}
	return filepath.Join("/tmp", "pw-profiles")
}

// atomicWrite writes data to path via a temp file + rename so FileView never reads a partial file mid-write
func atomicWrite(path string, data []byte) error {
	dir := filepath.Dir(path)
	if err := os.MkdirAll(dir, 0o700); err != nil {
		return err
	}
	tmp := path + ".tmp"
	if err := os.WriteFile(tmp, data, 0o600); err != nil {
		return err
	}
	return os.Rename(tmp, path)
}

type Profile struct {
	Index       int    `json:"index"`
	Name        string `json:"name"`
	Description string `json:"description"`
	Available   string `json:"available"`
	Readable    string `json:"readable"`
}

type ActiveProfile struct {
	Index       int    `json:"index"`
	Name        string `json:"name"`
	Description string `json:"description"`
	Available   string `json:"available"`
}

// profiles.json
type ProfilesFile struct {
	DeviceID   uint32    `json:"deviceId"`
	DeviceName string    `json:"deviceName"`
	Profiles   []Profile `json:"profiles"`
}

// active.json
type ActiveFile struct {
	DeviceID      uint32        `json:"deviceId"`
	ActiveIndex   int           `json:"activeIndex"`
	ActiveProfile ActiveProfile `json:"activeProfile"`
}

type rawDevice struct {
	DeviceID      uint32 `json:"deviceId"`
	DeviceName    string `json:"deviceName"`
	ActiveIndex   int    `json:"activeIndex"`
	ActiveProfile struct {
		Index       int    `json:"index"`
		Name        string `json:"name"`
		Description string `json:"description"`
		Available   string `json:"available"`
	} `json:"activeProfile"`
	Profiles []struct {
		Index       int    `json:"index"`
		Name        string `json:"name"`
		Description string `json:"description"`
		Available   string `json:"available"`
	} `json:"profiles"`
}

func formatProfileName(name string) string {
	switch name {
	case "off":
		return "Off"
	case "pro-audio":
		return "Pro Audio"
	}
	parts := strings.Split(name, "+")
	out := make([]string, 0, len(parts))
	for _, part := range parts {
		part = strings.TrimSpace(part)
		part = strings.TrimPrefix(part, "output:")
		part = strings.TrimPrefix(part, "input:")
		words := strings.Split(part, "-")
		for i, w := range words {
			if len(w) > 0 {
				words[i] = strings.ToUpper(w[:1]) + w[1:]
			}
		}
		out = append(out, strings.Join(words, " "))
	}
	return strings.Join(out, " + ")
}

// helpers
func writeProfiles(dir string, rd rawDevice) error {
	profiles := make([]Profile, len(rd.Profiles))
	for i, p := range rd.Profiles {
		profiles[i] = Profile{
			Index:       p.Index,
			Name:        p.Name,
			Description: p.Description,
			Available:   p.Available,
			Readable:    formatProfileName(p.Name),
		}
	}
	f := ProfilesFile{
		DeviceID:   rd.DeviceID,
		DeviceName: rd.DeviceName,
		Profiles:   profiles,
	}
	data, err := json.MarshalIndent(f, "", "  ")
	if err != nil {
		return err
	}
	return atomicWrite(filepath.Join(dir, "profiles.json"), data)
}

func writeActive(dir string, rd rawDevice) error {
	f := ActiveFile{
		DeviceID:    rd.DeviceID,
		ActiveIndex: rd.ActiveIndex,
		ActiveProfile: ActiveProfile{
			Index:       rd.ActiveProfile.Index,
			Name:        rd.ActiveProfile.Name,
			Description: rd.ActiveProfile.Description,
			Available:   rd.ActiveProfile.Available,
		},
	}
	data, err := json.MarshalIndent(f, "", "  ")
	if err != nil {
		return err
	}
	return atomicWrite(filepath.Join(dir, "active.json"), data)
}

func main() {
	dir := stateDir()

	runtime.LockOSThread()

	app := C.app_create()
	if app == nil {
		fmt.Fprintln(os.Stderr, "pw-profiles: failed to connect to PipeWire")
		os.Exit(1)
	}

	sigs := make(chan os.Signal, 1)
	signal.Notify(sigs, syscall.SIGINT, syscall.SIGTERM)
	go func() {
		<-sigs
		C.app_quit(app)
	}()

	for {
		ret := C.app_iterate(app)
		if ret < 0 {
			break
		}

		for {
			var cerr C.int
			cjson := C.drain_dirty(app, &cerr)

			if cjson == nil {
				if cerr == C.DJ_ENOMEM {
					log.Printf("drain_dirty: out of memory")
					break
				}
				if cerr == C.DJ_EOVERFLOW {
					log.Printf("drain_dirty: json buffer overflow (bug)")
					break
				}
				break
			}

			raw := C.GoString(cjson)
			C.free(unsafe.Pointer(cjson))

			var rd rawDevice
			if err := json.Unmarshal([]byte(raw), &rd); err != nil {
				fmt.Fprintln(os.Stderr, "pw-profiles: parse error:", err)
				continue
			}

			if err := writeProfiles(dir, rd); err != nil {
				fmt.Fprintln(os.Stderr, "pw-profiles: write profiles.json:", err)
			}
			if err := writeActive(dir, rd); err != nil {
				fmt.Fprintln(os.Stderr, "pw-profiles: write active.json:", err)
			}

			log.Printf("writeProfiles: deviceId=%d count=%d", rd.DeviceID, len(rd.Profiles))
		}

		time.Sleep(500 * time.Millisecond)
	}

	C.app_destroy(app)
}
