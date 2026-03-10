// PipeWire runs on its own thread via pw_thread_loop.
// Qt properties live on the main thread.
// The QTimer::poll() slot locks the PW loop,
// copies whatever changed, then updates properties

#include "AudioProfilesWatcher.hpp"

#include <QDebug>
#include <QQmlEngine>
#include <QStringList>

#include <memory>
#include <mutex>
#include <qtypes.h>
#include <stdexcept>
#include <vector>

extern "C" {
#include <pipewire/pipewire.h>
#include <spa/param/profile.h>
#include <spa/pod/iter.h>
#include <spa/pod/parser.h>
#include <spa/utils/result.h>
}

struct PwThreadLoopDeleter {
    void operator()(pw_thread_loop* p) const {
        pw_thread_loop_destroy(p);
    }
};
struct PwContextDeleter {
    void operator()(pw_context* p) const {
        pw_context_destroy(p);
    }
};
struct PwCoreDeleter {
    void operator()(pw_core* p) const {
        pw_core_disconnect(p);
    }
};
struct PwRegistryDeleter {
    void operator()(pw_registry* p) const {
        pw_proxy_destroy(reinterpret_cast<pw_proxy*>(p));
    }
};

using UniquePwThreadLoop = std::unique_ptr<pw_thread_loop, PwThreadLoopDeleter>;
using UniquePwContext    = std::unique_ptr<pw_context, PwContextDeleter>;
using UniquePwCore       = std::unique_ptr<pw_core, PwCoreDeleter>;
using UniquePwRegistry   = std::unique_ptr<pw_registry, PwRegistryDeleter>;

// SPA compat
#define AP_MAX_PROFILES 64
#define AP_MAX_STR      256

struct ap_profile_entry_t {
    int32_t index;
    char    name[AP_MAX_STR];
    char    description[AP_MAX_STR];
    char    available[32];
};

struct ap_device_node_t {
    pw_proxy*          proxy = nullptr;
    spa_hook           device_listener{};
    spa_hook           proxy_listener{};

    uint32_t           pw_id = 0;
    char               name[AP_MAX_STR]{};

    ap_profile_entry_t profiles[AP_MAX_PROFILES]{};
    int                profile_count = 0;

    ap_profile_entry_t staging[AP_MAX_PROFILES]{};
    int                staging_count = 0;
    int                enum_seq      = 0;

    int32_t            active_index = -1;
    char               active_name[AP_MAX_STR]{};
    char               active_description[AP_MAX_STR]{};
    char               active_available[32]{};

    int                dirty = 0;
};

// callbacks must be static free functions for pw C API
static void ap_registry_event_global(void* data, uint32_t id, uint32_t permissions, const char* type, uint32_t version, const spa_dict* props);
static void ap_registry_event_global_remove(void* data, uint32_t id);
static void ap_device_event_info(void* data, const pw_device_info* info);
static void ap_device_event_param(void* data, int seq, uint32_t id, uint32_t index, uint32_t next, const spa_pod* param);
static void ap_on_proxy_destroy(void* data);

// Helpers
static const char* ap_safe_lookup(const spa_dict* dict, const char* key) {
    if (!dict)
        return "";
    const char* v = spa_dict_lookup(dict, key);
    return v ? v : "";
}

static void ap_safe_copy(char* dst, size_t dst_size, const char* src) {
    if (!src || dst_size == 0) {
        if (dst_size > 0)
            dst[0] = '\0';
        return;
    }
    snprintf(dst, dst_size, "%s", src);
}

static const char* ap_parse_availability(const spa_pod* val) {
    uint32_t av = 0;
    if (spa_pod_get_id(val, &av) != 0)
        return "unknown";
    switch (av) {
        case SPA_PARAM_AVAILABILITY_yes: return "yes";
        case SPA_PARAM_AVAILABILITY_no: return "no";
        default: return "unknown";
    }
}

class PwApp {
  public:
    // we want spa_hook addresses must stay stable
    PwApp(const PwApp&)            = delete;
    PwApp& operator=(const PwApp&) = delete;

    PwApp() {
        static std::once_flag s_init;
        std::call_once(s_init, [] {
            int argc = 0;
            pw_init(&argc, nullptr);
        });

        m_loop.reset(pw_thread_loop_new("pw-profiles", nullptr));
        if (!m_loop)
            throw std::runtime_error("pw_thread_loop_new failed");

        m_context.reset(pw_context_new(pw_thread_loop_get_loop(m_loop.get()), nullptr, 0));
        if (!m_context)
            throw std::runtime_error("pw_context_new failed");

        m_core.reset(pw_context_connect(m_context.get(), nullptr, 0));
        if (!m_core)
            throw std::runtime_error("pw_context_connect failed");

        m_registry.reset(pw_core_get_registry(m_core.get(), PW_VERSION_REGISTRY, 0));
        if (!m_registry)
            throw std::runtime_error("pw_core_get_registry failed");

        pw_registry_add_listener(m_registry.get(), &m_registry_listener, &s_registry_events, this);

        if (pw_thread_loop_start(m_loop.get()) < 0)
            throw std::runtime_error("pw_thread_loop_start failed");
    }

    ~PwApp() {
        pw_thread_loop_stop(m_loop.get());
        for (ap_device_node_t* d : m_devices)
            pw_proxy_destroy(d->proxy);
        m_devices.clear();

        spa_hook_remove(&m_registry_listener);
    }

    pw_thread_loop* loop() const {
        return m_loop.get();
    }
    pw_registry* registry() const {
        return m_registry.get();
    }

    std::vector<ap_device_node_t*> m_devices;
    spa_hook                       m_registry_listener{};

    // defined after all callback symbols are visible
    static const pw_registry_events s_registry_events;
    static const pw_device_events   s_device_events;
    static const pw_proxy_events    s_proxy_events;

  private:
    // Destruction is reverse: registry → core → context → loop
    UniquePwThreadLoop m_loop;
    UniquePwContext    m_context;
    UniquePwCore       m_core;
    UniquePwRegistry   m_registry;
};

// device callbacks
static void ap_device_event_info(void* data, const pw_device_info* info) {
    auto* d = static_cast<ap_device_node_t*>(data);

    if (info->props) {
        const char* n = ap_safe_lookup(info->props, PW_KEY_DEVICE_NAME);
        if (*n)
            ap_safe_copy(d->name, sizeof(d->name), n);
    }

    if (info->change_mask & PW_DEVICE_CHANGE_MASK_PARAMS) {
        d->enum_seq      = pw_device_enum_params(reinterpret_cast<pw_device*>(d->proxy), 0, SPA_PARAM_EnumProfile, 0, UINT32_MAX, nullptr);
        d->staging_count = 0;
        pw_device_enum_params(reinterpret_cast<pw_device*>(d->proxy), 0, SPA_PARAM_Profile, 0, UINT32_MAX, nullptr);
    }
}

static void ap_device_event_param(void* data, int seq, uint32_t id, uint32_t /*index*/, uint32_t /*next*/, const spa_pod* param) {
    auto* d = static_cast<ap_device_node_t*>(data);

    if (id == SPA_PARAM_EnumProfile) {
        if (seq != d->enum_seq)
            return;

        if (!param || !spa_pod_is_object(param)) {
            if (d->staging_count > 0) {
                memcpy(d->profiles, d->staging, sizeof(ap_profile_entry_t) * static_cast<size_t>(d->staging_count));
                d->profile_count = d->staging_count;
                d->staging_count = 0; // clear so SPA_PARAM_Profile doesn't re-commit
                d->dirty         = 1;
            }
            return;
        }

        if (d->staging_count >= AP_MAX_PROFILES)
            return;

        int32_t       pidx  = -1;
        const char*   name  = nullptr;
        const char*   desc  = nullptr;
        const char*   avail = "unknown";

        spa_pod_prop* prop;
        SPA_POD_OBJECT_FOREACH(reinterpret_cast<const spa_pod_object*>(param), prop) {
            switch (prop->key) {
                case SPA_PARAM_PROFILE_index: spa_pod_get_int(&prop->value, &pidx); break;
                case SPA_PARAM_PROFILE_name: spa_pod_get_string(&prop->value, &name); break;
                case SPA_PARAM_PROFILE_description: spa_pod_get_string(&prop->value, &desc); break;
                case SPA_PARAM_PROFILE_available: avail = ap_parse_availability(&prop->value); break;
            }
        }

        ap_profile_entry_t* e = &d->staging[d->staging_count++];
        e->index              = pidx;
        ap_safe_copy(e->name, sizeof(e->name), name ? name : "");
        ap_safe_copy(e->description, sizeof(e->description), desc ? desc : "");
        ap_safe_copy(e->available, sizeof(e->available), avail);

    } else if (id == SPA_PARAM_Profile) {
        if (!param || !spa_pod_is_object(param))
            return;

        // Commit any staged profiles that arrived before this event
        if (d->staging_count > 0) {
            memcpy(d->profiles, d->staging, sizeof(ap_profile_entry_t) * static_cast<size_t>(d->staging_count));
            d->profile_count = d->staging_count;
            d->staging_count = 0;
        }

        int32_t       pidx  = -1;
        const char*   name  = nullptr;
        const char*   desc  = nullptr;
        const char*   avail = "unknown";

        spa_pod_prop* prop;
        SPA_POD_OBJECT_FOREACH(reinterpret_cast<const spa_pod_object*>(param), prop) {
            switch (prop->key) {
                case SPA_PARAM_PROFILE_index: spa_pod_get_int(&prop->value, &pidx); break;
                case SPA_PARAM_PROFILE_name: spa_pod_get_string(&prop->value, &name); break;
                case SPA_PARAM_PROFILE_description: spa_pod_get_string(&prop->value, &desc); break;
                case SPA_PARAM_PROFILE_available: avail = ap_parse_availability(&prop->value); break;
            }
        }

        d->active_index = pidx;
        ap_safe_copy(d->active_name, sizeof(d->active_name), name ? name : "");
        ap_safe_copy(d->active_description, sizeof(d->active_description), desc ? desc : "");
        ap_safe_copy(d->active_available, sizeof(d->active_available), avail);
        d->dirty = 1;
    }
}

static void ap_on_proxy_destroy(void* data) {
    auto* d = static_cast<ap_device_node_t*>(data);
    spa_hook_remove(&d->device_listener);
    spa_hook_remove(&d->proxy_listener);
    delete d;
}

// registry callbacks
static void ap_registry_event_global(void* data, uint32_t id, uint32_t /*permissions*/, const char* type, uint32_t /*version*/, const spa_dict* props) {
    auto* app = static_cast<PwApp*>(data);

    if (strcmp(type, PW_TYPE_INTERFACE_Device) != 0)
        return;

    const char* media_class = ap_safe_lookup(props, PW_KEY_MEDIA_CLASS);
    if (!strstr(media_class, "Audio"))
        return;

    auto* d  = new ap_device_node_t();
    d->pw_id = id;
    ap_safe_copy(d->name, sizeof(d->name), ap_safe_lookup(props, PW_KEY_DEVICE_NAME));

    d->proxy = static_cast<pw_proxy*>(pw_registry_bind(app->registry(), id, PW_TYPE_INTERFACE_Device, PW_VERSION_DEVICE, 0));
    if (!d->proxy) {
        delete d;
        return;
    }

    pw_proxy_add_object_listener(d->proxy, &d->device_listener, &PwApp::s_device_events, d);
    pw_proxy_add_listener(d->proxy, &d->proxy_listener, &PwApp::s_proxy_events, d);

    app->m_devices.push_back(d);
}

static void ap_registry_event_global_remove(void* data, uint32_t id) {
    auto* app = static_cast<PwApp*>(data);

    auto  it = std::find_if(app->m_devices.begin(), app->m_devices.end(), [id](const ap_device_node_t* d) { return d->pw_id == id; });

    if (it == app->m_devices.end())
        return;

    ap_device_node_t* d = *it;
    app->m_devices.erase(it);
    pw_proxy_destroy(d->proxy);
}

const pw_registry_events PwApp::s_registry_events = {
    .version       = PW_VERSION_REGISTRY_EVENTS,
    .global        = ap_registry_event_global,
    .global_remove = ap_registry_event_global_remove,
};
const pw_device_events PwApp::s_device_events = {
    .version = PW_VERSION_DEVICE_EVENTS,
    .info    = ap_device_event_info,
    .param   = ap_device_event_param,
};
const pw_proxy_events PwApp::s_proxy_events = {
    .version     = PW_VERSION_PROXY_EVENTS,
    .destroy     = ap_on_proxy_destroy,
    .bound       = nullptr,
    .removed     = nullptr,
    .done        = nullptr,
    .error       = nullptr,
    .bound_props = nullptr,
};

static ap_device_node_t* ap_drain_dirty(PwApp* app) {
    for (ap_device_node_t* d : app->m_devices) {
        if (d->dirty && d->profile_count > 0) {
            d->dirty = 0;
            return d;
        }
    }
    return nullptr;
}

struct AudioProfilesWatcher::PwState {
    std::unique_ptr<PwApp> app;
};

// qt impl
AudioProfilesWatcher* AudioProfilesWatcher::create(QQmlEngine*, QJSEngine*) {
    static AudioProfilesWatcher s_instance;
    return &s_instance;
}

QString AudioProfilesWatcher::formatProfileName(const QString& name) {
    if (name == QLatin1String("off"))
        return QStringLiteral("Off");
    if (name == QLatin1String("pro-audio"))
        return QStringLiteral("Pro Audio");

    const QStringList parts = name.split(QLatin1Char('+'));
    QStringList       out;
    out.reserve(parts.size());

    for (QString part : parts) {
        part = part.trimmed();
        if (part.startsWith(QLatin1String("output:")))
            part.remove(0, 7);
        else if (part.startsWith(QLatin1String("input:")))
            part.remove(0, 6);

        QStringList words = part.split(QLatin1Char('-'));
        for (QString& w : words)
            if (!w.isEmpty())
                w[0] = w[0].toUpper();

        out << words.join(QLatin1Char(' '));
    }
    return out.join(QStringLiteral(" + "));
}

AudioProfilesWatcher::AudioProfilesWatcher(QObject* parent) : QObject(parent), m_model(new AudioProfilesModel(this)), m_timer(new QTimer(this)), m_pw(new PwState) {
    try {
        m_pw->app   = std::make_unique<PwApp>();
        m_connected = true;
        emit connectedChanged();
    } catch (const std::exception& e) { qWarning("AudioProfilesWatcher: failed to connect to PipeWire: %s", e.what()); }

    m_timer->setInterval(100);
    connect(m_timer, &QTimer::timeout, this, &AudioProfilesWatcher::poll);
    m_timer->start();
}

AudioProfilesWatcher::~AudioProfilesWatcher() {
    m_timer->stop();
    delete m_pw;
}

void AudioProfilesWatcher::poll() {
    if (!m_pw->app)
        return;

    PwApp* app = m_pw->app.get();

    struct DeviceSnapshot {
        quint32             deviceId;
        QString             deviceName;
        qsizetype           activeIdx;
        QVariantMap         activeProfile;
        QList<ProfileEntry> profiles;
    };
    QList<DeviceSnapshot> snapshots;

    pw_thread_loop_lock(app->loop());
    while (ap_device_node_t* d = ap_drain_dirty(app)) {
        DeviceSnapshot snap;
        snap.deviceId   = d->pw_id;
        snap.deviceName = QString::fromUtf8(d->name);
        snap.activeIdx  = d->active_index;

        const QString actName = QString::fromUtf8(d->active_name);
        snap.activeProfile    = {
            {QStringLiteral("index"), d->active_index},
            {QStringLiteral("name"), actName},
            {QStringLiteral("description"), QString::fromUtf8(d->active_description)},
            {QStringLiteral("available"), QString::fromUtf8(d->active_available)},
            {QStringLiteral("readable"), formatProfileName(actName)},
        };

        snap.profiles.reserve(d->profile_count);
        for (int i = 0; i < d->profile_count; ++i) {
            const ap_profile_entry_t& e  = d->profiles[i];
            const QString             nm = QString::fromUtf8(e.name);
            snap.profiles.append(ProfileEntry{
                e.index,
                nm,
                QString::fromUtf8(e.description),
                QString::fromUtf8(e.available),
                formatProfileName(nm),
            });
        }
        snapshots.append(std::move(snap));
    }
    pw_thread_loop_unlock(app->loop());

    if (snapshots.isEmpty())
        return;

    for (const DeviceSnapshot& snap : snapshots) {
        const bool deviceChanged  = (m_deviceId != snap.deviceId || m_deviceName != snap.deviceName);
        const bool profileChanged = (m_activeIndex != snap.activeIdx || m_activeProfile != snap.activeProfile);

        m_deviceId      = snap.deviceId;
        m_deviceName    = snap.deviceName;
        m_activeIndex   = snap.activeIdx;
        m_activeProfile = snap.activeProfile;
        m_model->setProfiles(snap.profiles);

        if (deviceChanged)
            emit deviceInfoChanged();
        if (profileChanged)
            emit activeProfileChanged();
    }
}
