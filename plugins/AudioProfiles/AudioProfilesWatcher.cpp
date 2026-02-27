// AudioProfilesWatcher.cpp
//
// PipeWire runs on its own thread via pw_thread_loop.  Qt properties live on
// the main thread.  The QTimer::poll() slot locks the PW loop, copies whatever
// changed, then updates properties — all without extra queued connections.
//
// The PipeWire C logic is ported directly from audioProfiles.go (the CGo block).

#include "AudioProfilesWatcher.h"

#include <QQmlEngine>
#include <QStringList>
#include <QDebug>

// ─── PipeWire / SPA headers ──────────────────────────────────────────────────
extern "C" {
#include <pipewire/pipewire.h>
#include <spa/pod/iter.h>
#include <spa/pod/parser.h>
#include <spa/utils/result.h>
#include <spa/param/profile.h>
#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#include <stdint.h>
}

// ─── C structs & callbacks ───────────────────────────────────────────────────

#define AP_MAX_PROFILES  64
#define AP_MAX_STR       256

typedef struct {
    int32_t index;
    char    name[AP_MAX_STR];
    char    description[AP_MAX_STR];
    char    available[32];
} ap_profile_entry_t;

typedef struct ap_device_node {
    struct pw_proxy         *proxy;
    struct spa_hook          device_listener;
    struct spa_hook          proxy_listener;

    uint32_t                 pw_id;
    char                     name[AP_MAX_STR];

    ap_profile_entry_t       profiles[AP_MAX_PROFILES];
    int                      profile_count;

    ap_profile_entry_t       staging[AP_MAX_PROFILES];
    int                      staging_count;
    int                      enum_seq;

    int32_t                  active_index;
    char                     active_name[AP_MAX_STR];
    char                     active_description[AP_MAX_STR];
    char                     active_available[32];

    int                      dirty;
    struct ap_device_node   *next;
} ap_device_node_t;

typedef struct {
    struct pw_thread_loop   *loop;
    struct pw_context       *context;
    struct pw_core          *core;
    struct pw_registry      *registry;
    struct spa_hook          registry_listener;
    ap_device_node_t        *devices;
} ap_app_t;

// ── Forward declarations (tables are defined after the callbacks) ─────────────
static void ap_registry_event_global(void *data, uint32_t id,
    uint32_t permissions, const char *type, uint32_t version,
    const struct spa_dict *props);
static void ap_registry_event_global_remove(void *data, uint32_t id);
static void ap_device_event_info(void *data, const struct pw_device_info *info);
static void ap_device_event_param(void *data, int seq, uint32_t id,
    uint32_t index, uint32_t next, const struct spa_pod *param);
static void ap_on_proxy_destroy(void *data);

// ── Helpers ───────────────────────────────────────────────────────────────────

static const char *ap_safe_lookup(const struct spa_dict *dict, const char *key)
{
    if (!dict) return "";
    const char *v = spa_dict_lookup(dict, key);
    return v ? v : "";
}

static void ap_safe_copy(char *dst, size_t dst_size, const char *src)
{
    if (!src || dst_size == 0) { if (dst_size > 0) dst[0] = '\0'; return; }
    size_t i;
    for (i = 0; i < dst_size - 1 && src[i]; i++) dst[i] = src[i];
    dst[i] = '\0';
}

static const char *ap_parse_availability(const struct spa_pod *val)
{
    uint32_t av = 0;
    if (spa_pod_get_id(val, &av) != 0) return "unknown";
    switch (av) {
    case SPA_PARAM_AVAILABILITY_yes: return "yes";
    case SPA_PARAM_AVAILABILITY_no:  return "no";
    default:                         return "unknown";
    }
}

// ── Device callbacks ──────────────────────────────────────────────────────────

static void ap_device_event_info(void *data, const struct pw_device_info *info)
{
    ap_device_node_t *d = static_cast<ap_device_node_t *>(data);

    if (info->props) {
        const char *n = ap_safe_lookup(info->props, PW_KEY_DEVICE_NAME);
        if (*n) ap_safe_copy(d->name, sizeof(d->name), n);
    }

    if (info->change_mask & PW_DEVICE_CHANGE_MASK_PARAMS) {
        d->enum_seq = pw_device_enum_params(
            reinterpret_cast<struct pw_device *>(d->proxy),
            0, SPA_PARAM_EnumProfile, 0, UINT32_MAX, nullptr);
        d->staging_count = 0;

        pw_device_enum_params(
            reinterpret_cast<struct pw_device *>(d->proxy),
            0, SPA_PARAM_Profile, 0, UINT32_MAX, nullptr);
    }
}

static void ap_device_event_param(void *data, int seq, uint32_t id,
    uint32_t /*index*/, uint32_t /*next*/, const struct spa_pod *param)
{
    ap_device_node_t *d = static_cast<ap_device_node_t *>(data);

    if (id == SPA_PARAM_EnumProfile) {
        // Discard stale sequences
        if (seq != d->enum_seq) return;

        // Null/non-object param = end of sequence — commit staging
        if (!param || !spa_pod_is_object(param)) {
            if (d->staging_count > 0) {
                memcpy(d->profiles, d->staging,
                       sizeof(ap_profile_entry_t) * static_cast<size_t>(d->staging_count));
                d->profile_count = d->staging_count;
                d->dirty         = 1;
            }
            return;
        }

        if (d->staging_count >= AP_MAX_PROFILES) return;

        int32_t     pidx  = -1;
        const char *name  = nullptr;
        const char *desc  = nullptr;
        const char *avail = "unknown";

        struct spa_pod_prop *prop;
        SPA_POD_OBJECT_FOREACH(reinterpret_cast<const struct spa_pod_object *>(param), prop) {
            switch (prop->key) {
            case SPA_PARAM_PROFILE_index:
                spa_pod_get_int(&prop->value, &pidx);       break;
            case SPA_PARAM_PROFILE_name:
                spa_pod_get_string(&prop->value, &name);    break;
            case SPA_PARAM_PROFILE_description:
                spa_pod_get_string(&prop->value, &desc);    break;
            case SPA_PARAM_PROFILE_available:
                avail = ap_parse_availability(&prop->value); break;
            }
        }

        ap_profile_entry_t *e = &d->staging[d->staging_count++];
        e->index = pidx;
        ap_safe_copy(e->name,        sizeof(e->name),        name  ? name  : "");
        ap_safe_copy(e->description, sizeof(e->description), desc  ? desc  : "");
        ap_safe_copy(e->available,   sizeof(e->available),   avail);

    } else if (id == SPA_PARAM_Profile) {
        if (!param || !spa_pod_is_object(param)) return;

        // SPA_PARAM_Profile arrives after EnumProfile sequence — commit staging
        if (d->staging_count > 0) {
            memcpy(d->profiles, d->staging,
                   sizeof(ap_profile_entry_t) * static_cast<size_t>(d->staging_count));
            d->profile_count = d->staging_count;
            d->staging_count = 0;
        }

        int32_t     pidx  = -1;
        const char *name  = nullptr;
        const char *desc  = nullptr;
        const char *avail = "unknown";

        struct spa_pod_prop *prop;
        SPA_POD_OBJECT_FOREACH(reinterpret_cast<const struct spa_pod_object *>(param), prop) {
            switch (prop->key) {
            case SPA_PARAM_PROFILE_index:
                spa_pod_get_int(&prop->value, &pidx);       break;
            case SPA_PARAM_PROFILE_name:
                spa_pod_get_string(&prop->value, &name);    break;
            case SPA_PARAM_PROFILE_description:
                spa_pod_get_string(&prop->value, &desc);    break;
            case SPA_PARAM_PROFILE_available:
                avail = ap_parse_availability(&prop->value); break;
            }
        }

        d->active_index = pidx;
        ap_safe_copy(d->active_name,        sizeof(d->active_name),        name  ? name  : "");
        ap_safe_copy(d->active_description, sizeof(d->active_description), desc  ? desc  : "");
        ap_safe_copy(d->active_available,   sizeof(d->active_available),   avail);
        d->dirty = 1;
    }
}

static void ap_on_proxy_destroy(void *data)
{
    ap_device_node_t *d = static_cast<ap_device_node_t *>(data);
    spa_hook_remove(&d->device_listener);
    spa_hook_remove(&d->proxy_listener);
}

// ── Event tables (defined here so all callback symbols are already visible) ───

static const struct pw_registry_events ap_registry_events = {
    .version       = PW_VERSION_REGISTRY_EVENTS,
    .global        = ap_registry_event_global,
    .global_remove = ap_registry_event_global_remove,
};
static const struct pw_device_events ap_device_events = {
    .version = PW_VERSION_DEVICE_EVENTS,
    .info    = ap_device_event_info,
    .param   = ap_device_event_param,
};
static const struct pw_proxy_events ap_proxy_events = {
    .version = PW_VERSION_PROXY_EVENTS,
    .destroy = ap_on_proxy_destroy,
};

// ── Registry callbacks ────────────────────────────────────────────────────────

static void ap_registry_event_global(void *data, uint32_t id,
    uint32_t /*permissions*/, const char *type, uint32_t /*version*/,
    const struct spa_dict *props)
{
    ap_app_t *app = static_cast<ap_app_t *>(data);
    if (strcmp(type, PW_TYPE_INTERFACE_Device) != 0) return;

    const char *media_class = ap_safe_lookup(props, PW_KEY_MEDIA_CLASS);
    if (!strstr(media_class, "Audio")) return;

    ap_device_node_t *d =
        static_cast<ap_device_node_t *>(calloc(1, sizeof(ap_device_node_t)));
    if (!d) return;

    d->pw_id        = id;
    d->active_index = -1;
    ap_safe_copy(d->name, sizeof(d->name), ap_safe_lookup(props, PW_KEY_DEVICE_NAME));

    d->proxy = static_cast<struct pw_proxy *>(pw_registry_bind(app->registry, id,
        PW_TYPE_INTERFACE_Device, PW_VERSION_DEVICE, 0));
    if (!d->proxy) { free(d); return; }

    pw_proxy_add_object_listener(d->proxy, &d->device_listener, &ap_device_events, d);
    pw_proxy_add_listener(d->proxy, &d->proxy_listener, &ap_proxy_events, d);

    d->next      = app->devices;
    app->devices = d;
}

static void ap_registry_event_global_remove(void *data, uint32_t id)
{
    ap_app_t         *app  = static_cast<ap_app_t *>(data);
    ap_device_node_t *prev = nullptr;
    ap_device_node_t *d    = app->devices;

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

// ── App lifecycle ─────────────────────────────────────────────────────────────

static ap_app_t *ap_app_create()
{
    static bool pw_initialized = false;
    if (!pw_initialized) {
        int argc = 0; char **argv = nullptr;
        pw_init(&argc, &argv);
        pw_initialized = true;
    }

    ap_app_t *app = static_cast<ap_app_t *>(calloc(1, sizeof(ap_app_t)));
    if (!app) return nullptr;

    app->loop = pw_thread_loop_new("pw-profiles", nullptr);
    if (!app->loop) goto err;

    app->context = pw_context_new(pw_thread_loop_get_loop(app->loop), nullptr, 0);
    if (!app->context) goto err;

    // Connect before starting the thread so no locking is needed here
    app->core = pw_context_connect(app->context, nullptr, 0);
    if (!app->core) goto err;

    app->registry = pw_core_get_registry(app->core, PW_VERSION_REGISTRY, 0);
    pw_registry_add_listener(app->registry, &app->registry_listener,
        &ap_registry_events, app);

    if (pw_thread_loop_start(app->loop) < 0) goto err;
    return app;

err:
    if (app->core)    pw_core_disconnect(app->core);
    if (app->context) pw_context_destroy(app->context);
    if (app->loop)    pw_thread_loop_destroy(app->loop);
    free(app);
    return nullptr;
}

static void ap_app_destroy(ap_app_t *app)
{
    if (!app) return;
    pw_thread_loop_stop(app->loop);
    for (ap_device_node_t *d = app->devices, *n; d; d = n) {
        n = d->next;
        pw_proxy_destroy(d->proxy);
        free(d);
    }
    pw_proxy_destroy(reinterpret_cast<struct pw_proxy *>(app->registry));
    pw_core_disconnect(app->core);
    pw_context_destroy(app->context);
    pw_thread_loop_destroy(app->loop);
    free(app);
}

// Returns the first dirty device node that has profiles, clears its dirty flag.
// MUST be called with pw_thread_loop_lock held.
static ap_device_node_t *ap_drain_dirty(ap_app_t *app)
{
    for (ap_device_node_t *d = app->devices; d; d = d->next) {
        if (d->dirty && d->profile_count > 0) {
            d->dirty = 0;
            return d;
        }
    }
    return nullptr;
}

// ─── PwState (opaque impl) ────────────────────────────────────────────────────

struct AudioProfilesWatcher::PwState {
    ap_app_t *app = nullptr;
};

// ─── Qt implementation ────────────────────────────────────────────────────────

/*static*/
AudioProfilesWatcher *AudioProfilesWatcher::create(QQmlEngine *, QJSEngine *)
{
    static AudioProfilesWatcher s_instance;
    return &s_instance;
}

/*static*/
QString AudioProfilesWatcher::formatProfileName(const QString &name)
{
    if (name == QLatin1String("off"))       return QStringLiteral("Off");
    if (name == QLatin1String("pro-audio")) return QStringLiteral("Pro Audio");

    const QStringList parts = name.split(QLatin1Char('+'));
    QStringList out;
    out.reserve(parts.size());

    for (QString part : parts) {
        part = part.trimmed();
        if (part.startsWith(QLatin1String("output:"))) part.remove(0, 7);
        else if (part.startsWith(QLatin1String("input:")))  part.remove(0, 6);

        QStringList words = part.split(QLatin1Char('-'));
        for (QString &w : words)
            if (!w.isEmpty())
                w[0] = w[0].toUpper();

        out << words.join(QLatin1Char(' '));
    }
    return out.join(QStringLiteral(" + "));
}

AudioProfilesWatcher::AudioProfilesWatcher(QObject *parent)
    : QObject(parent)
    , m_model(new AudioProfilesModel(this))
    , m_timer(new QTimer(this))
    , m_pw(new PwState)
{
    m_pw->app = ap_app_create();

    if (!m_pw->app) {
        qWarning("AudioProfilesWatcher: failed to connect to PipeWire");
    } else {
        m_connected = true;
        emit connectedChanged();
    }

    m_timer->setInterval(200);
    connect(m_timer, &QTimer::timeout, this, &AudioProfilesWatcher::poll);
    m_timer->start();
}

AudioProfilesWatcher::~AudioProfilesWatcher()
{
    m_timer->stop();
    if (m_pw->app) {
        ap_app_destroy(m_pw->app);
        m_pw->app = nullptr;
    }
    delete m_pw;
}

void AudioProfilesWatcher::poll()
{
    if (!m_pw->app) return;

    ap_app_t *app = m_pw->app;

    // Lock the PW thread loop so we can safely read device state
    pw_thread_loop_lock(app->loop);
    ap_device_node_t *d = ap_drain_dirty(app);
    if (!d) {
        pw_thread_loop_unlock(app->loop);
        return;
    }

    // Copy all needed data while the lock is held
    const quint32  newDeviceId   = d->pw_id;
    const QString  newDeviceName = QString::fromUtf8(d->name);
    const int      newActIdx     = d->active_index;

    const QVariantMap newActProfile {
        { QStringLiteral("index"),       d->active_index                              },
        { QStringLiteral("name"),        QString::fromUtf8(d->active_name)        },
        { QStringLiteral("description"), QString::fromUtf8(d->active_description) },
        { QStringLiteral("available"),   QString::fromUtf8(d->active_available)   },
    };

    QList<ProfileEntry> newProfiles;
    newProfiles.reserve(d->profile_count);
    for (int i = 0; i < d->profile_count; ++i) {
        const ap_profile_entry_t &e = d->profiles[i];
        const QString nm = QString::fromUtf8(e.name);
        newProfiles.append(ProfileEntry{
            e.index,
            nm,
            QString::fromUtf8(e.description),
            QString::fromUtf8(e.available),
            formatProfileName(nm),
        });
    }

    pw_thread_loop_unlock(app->loop);

    // ── Update Qt properties (already on the main thread via QTimer) ─────────
    const bool deviceChanged  = (m_deviceId != newDeviceId || m_deviceName != newDeviceName);
    const bool profileChanged = (m_activeIndex != newActIdx || m_activeProfile != newActProfile);

    m_deviceId      = newDeviceId;
    m_deviceName    = newDeviceName;
    m_activeIndex   = newActIdx;
    m_activeProfile = newActProfile;

    m_model->setProfiles(newProfiles);  // resets the list model

    if (deviceChanged)  emit deviceInfoChanged();
    if (profileChanged) emit activeProfileChanged();
}
