#include "BrightnessManager.hpp"
#include "../Jobs/JobExecutor.hpp"

#include <cstdint>
#include <expected>
#include <ddcutil_types.h>
#include <ddcutil_c_api.h>
#include <filesystem>
#include <memory>
#include <qcontainerfwd.h>
#include <qdebug.h>

#include <algorithm>
#include <fstream>
#include <qlist.h>
#include <qobject.h>
#include <qlogging.h>
#include <qstring.h>
#include <qtmetamacros.h>
#include <qtypes.h>
#include <string>
#include <utility>
#include <string_view>
#include <vector>

namespace vast {

    namespace {
        constexpr uint8_t K_VCP_BRIGHTNESS = 0x10;

        class DdcHandle final {
          public:
            DdcHandle() noexcept = default;
            explicit DdcHandle(DDCA_Display_Handle handle) noexcept : mHandle(handle) {}
            ~DdcHandle() noexcept {
                reset();
            }

            DdcHandle(const DdcHandle&)            = delete;
            DdcHandle& operator=(const DdcHandle&) = delete;
            DdcHandle(DdcHandle&& o) noexcept : mHandle(std::exchange(o.mHandle, nullptr)) {}

            DdcHandle& operator=(DdcHandle&& o) noexcept {
                if (this != &o) {
                    reset();
                    mHandle = std::exchange(o.mHandle, nullptr);
                }
                return *this;
            }

            [[nodiscard]] DDCA_Display_Handle get() const noexcept {
                return mHandle;
            }

            void reset() noexcept {
                if (mHandle) {
                    ddca_close_display(mHandle);
                    mHandle = nullptr;
                }
            }

          private:
            DDCA_Display_Handle mHandle{nullptr};
        };

        // The display the target points at, in the list ddcutil knows about.
        [[nodiscard]] const DDCA_Display_Info* findDisplay(const DDCA_Display_Info_List& list, const DdcTarget& target) noexcept {
            for (int i = 0; i < list.ct; ++i) {
                const auto& info = list.info[i];
                if (info.path.io_mode != target.mode)
                    continue;
                if (target.mode == DDCA_IO_I2C) {
                    if (info.path.path.i2c_busno == target.bus)
                        return &info;
                } else if (info.usb_bus == target.bus && info.usb_device == target.device) {
                    return &info;
                }
            }
            return nullptr;
        }

        template <typename Action>
        [[nodiscard]] std::expected<void, BrightnessError> withDdcDisplay(const DdcTarget& target, Action action) noexcept {
            DDCA_Display_Info_List* list{};
            ddca_get_display_info_list2(/*include_invalid_displays=*/false, &list);
            if (!list)
                return std::unexpected(BrightnessError{.message = "ddcutil returned no display list", .unavailable = true});

            const DDCA_Display_Info* info = findDisplay(*list, target);
            if (!info) {
                ddca_free_display_info_list(list);
                return std::unexpected(BrightnessError{.message = "display is not connected any more", .unavailable = true});
            }

            DDCA_Display_Handle handle{};
            const DDCA_Status   rc = ddca_open_display2(info->dref, /*wait=*/false, &handle);
            ddca_free_display_info_list(list);
            if (rc != 0) {
                return std::unexpected(BrightnessError{
                    .message     = ddca_rc_desc(rc),
                    .code        = static_cast<int>(rc),
                    .unavailable = true,
                });
            }

            DdcHandle owned{handle};
            return action(owned.get());
        }
    } // namespace

    BrightnessManager::BrightnessManager(QObject* parent) : QObject(parent) {}

    /* NOTE: no explicit destructor body needed.
     * Write jobs capture shared_ptr<DisplayWorker>, so a write still queued or
     * running at shutdown keeps its state alive. Completion callbacks are
     * queued with `this` as context, so once the manager is gone they are
     * dropped, never dereferenced.
     * A queued write may still be dropped at exit.
     */

    std::expected<int, BrightnessError> BrightnessManager::readDdcBrightness(const DdcTarget& target) noexcept {
        int        value{0};
        const auto result = withDdcDisplay(target, [&value](DDCA_Display_Handle handle) -> std::expected<void, BrightnessError> {
            DDCA_Non_Table_Vcp_Value val{};
            const DDCA_Status        rc = ddca_get_non_table_vcp_value(handle, K_VCP_BRIGHTNESS, &val);
            if (rc != 0) {
                return std::unexpected(BrightnessError{
                    .message = ddca_rc_desc(rc),
                    .code    = static_cast<int>(rc),
                });
            }
            const int current = (val.sh << 8) | val.sl;
            const int max     = (val.mh << 8) | val.ml;
            if (max == 0) {
                return std::unexpected(BrightnessError{.message = "monitor reported max brightness of 0"});
            }
            value = (current * K_MAX_PERCENT) / max;
            return {};
        });

        if (!result)
            return std::unexpected(result.error());
        return value;
    }

    std::expected<void, BrightnessError> BrightnessManager::writeDdcBrightness(const DdcTarget& target, int percent) noexcept {
        return withDdcDisplay(target, [percent](DDCA_Display_Handle handle) -> std::expected<void, BrightnessError> {
            // most modern monitors use a 0–100 native range for VCP 0x10
            // hi_byte = 0, lo_byte = percent
            const DDCA_Status rc = ddca_set_non_table_vcp_value(handle, K_VCP_BRIGHTNESS,
                                                                /*hi_byte=*/static_cast<uint8_t>(percent >> 8),
                                                                /*lo_byte=*/static_cast<uint8_t>(percent & 0xFF));
            if (rc != 0) {
                return std::unexpected(BrightnessError{
                    .message = ddca_rc_desc(rc),
                    .code    = static_cast<int>(rc),
                });
            }
            return {};
        });
    }

    std::expected<int, BrightnessError> BrightnessManager::readBacklightBrightness(const std::filesystem::path& root) noexcept {
        std::ifstream bStream(root / "brightness");
        std::ifstream mStream(root / "max_brightness");

        if (!bStream || !mStream) {
            return std::unexpected(BrightnessError{
                .message = std::string("cannot read sysfs backlight at ") + root.string(),
            });
        }

        int current{0};
        int max{0};
        bStream >> current;
        mStream >> max;

        if (max == 0) {
            return std::unexpected(BrightnessError{.message = "max_brightness is 0"});
        }
        return (current * K_MAX_PERCENT) / max;
    }

    std::expected<void, BrightnessError> BrightnessManager::writeBacklightBrightness(const std::filesystem::path& root, int percent) noexcept {
        std::ifstream mStream(root / "max_brightness");
        if (!mStream) {
            return std::unexpected(BrightnessError{
                .message = std::string("cannot write ") + root.string() + "/brightness — add user to 'video' group or check udev rules",
            });
        }
        int max{0};
        mStream >> max;

        std::ofstream bStream(root / "brightness");
        if (!bStream) {
            return std::unexpected(BrightnessError{
                .message = "cannot write brightness — missing i2c group membership?",
            });
        }
        bStream << (percent * max / K_MAX_PERCENT);
        return {};
    }

    void BrightnessManager::initialize() {
        // The scan runs on the job thread: ddcutil refuses to open a display
        // that is already open, so every hardware access has to be serialised
        // with the writes, and the redetection must not block the UI thread.
        vast::JobExecutor::instance().post([this] {
            WorkerMap discovered = scanDisplays();

            QMetaObject::invokeMethod(
                this,
                [this, discovered = std::move(discovered)]() mutable {
                    if (discovered.empty()) {
                        Q_EMIT initializationFailed(QStringLiteral("no controllable displays found (no DDC/CI monitors and no sysfs backlight device)"));
                    }

                    publishDisplays(std::move(discovered));
                },
                Qt::QueuedConnection);
        });
    }

    BrightnessManager::WorkerMap BrightnessManager::scanDisplays() noexcept {
        // The snapshot is rebuilt from scratch on every scan: a rescan is the
        // only way a display that was unplugged can leave the list, and a
        // display that was plugged can enter it.
        WorkerMap discovered;

        // ddcutil detects the displays once, when its library is initialised.
        // A monitor that is plugged in later only shows up after a
        // redetection, and a redetection closes every open display handle -
        // which is why no handle is kept between two hardware accesses.
        const DDCA_Status redetect = ddca_redetect_displays();
        if (redetect != 0)
            qWarning() << "[BrightnessManager] display redetection failed:" << ddca_rc_desc(redetect);

        DDCA_Display_Info_List* infoList{};
        ddca_get_display_info_list2(/*include_invalid_displays=*/false, &infoList);

        if (infoList) {
            for (int i = 0; i < infoList->ct; ++i) {
                const auto&     info = infoList->info[i];

                const DdcTarget target{
                    .mode   = info.path.io_mode,
                    .bus    = info.path.io_mode == DDCA_IO_I2C ? info.path.path.i2c_busno : info.usb_bus,
                    .device = info.path.io_mode == DDCA_IO_I2C ? 0 : info.usb_device,
                };

                // The id is derived from the port the display is attached to,
                // not from ddcutil's display number: that number is reassigned
                // on every detection run, so it would let one monitor take
                // over the identity of another one when the topology changes.
                const QString id   = target.mode == DDCA_IO_I2C ? QStringLiteral("ddc-%1").arg(target.bus) : QStringLiteral("ddc-usb-%1-%2").arg(target.bus).arg(target.device);
                const QString name = QStringLiteral("%1 %2").arg(QString::fromUtf8(info.mfg_id), QString::fromUtf8(info.model_name));

                const auto    read = readDdcBrightness(target);
                if (!read && read.error().unavailable) {
                    // The display is gone or cannot be opened: it does not
                    // belong in the list.
                    qWarning() << "[BrightnessManager] dropping display" << id << "—" << read.error().message;
                    continue;
                }

                const int initial = read.value_or(50);

                // clang-format off
                auto          meta = DisplayMeta{
                                                 .id            = id,
                                                 .name          = name,
                                                 .type          = DisplayType::Ddc,
                                                 .backlightPath = {},
                                                 .ddc           = target,
                };
                // clang-format on

                discovered.emplace(id, std::make_shared<DisplayWorker>(std::move(meta), initial));
            }
            ddca_free_display_info_list(infoList);
        }

        constexpr std::string_view kBacklightRoot = "/sys/class/backlight";

        if (std::filesystem::exists(kBacklightRoot)) {
            // collect all backlight entries, sorted by max_brightness descending
            // prefer intel_backlight / amdgpu_bl* over acpi_video* which is a
            // virtual ACPI interface requiring root to write
            std::vector<std::filesystem::path> entries;
            for (const auto& e : std::filesystem::directory_iterator(kBacklightRoot)) {
                const auto name = e.path().filename().string();
                // acpi_video* requires root, skip entirely
                if (name.starts_with("acpi_video"))
                    continue;
                entries.push_back(e.path());
            }

            for (const auto& path : entries) {
                const int     initial = readBacklightBrightness(path).value_or(50);
                const QString id      = QString::fromStdString(path.filename().string());
                // clang-format off
                auto          meta    = DisplayMeta{
                                                   .id            = id,
                                                   .name          = QStringLiteral("Internal: %1").arg(id),
                                                   .type          = DisplayType::Backlight,
                                                   .backlightPath = path,
                                                   .ddc           = {},
                };
                // clang-format on
                discovered.emplace(id, std::make_shared<DisplayWorker>(std::move(meta), initial));
            }
        }

        return discovered;
    }

    void BrightnessManager::publishDisplays(WorkerMap workers) {
        // Replacing the map drops the workers of the displays that are gone.
        // A write that is still in flight keeps its worker alive through the
        // shared_ptr it captured, so its hardware access stays valid; the
        // completion handler checks that the id is still known before it
        // publishes anything.
        mWorkers = std::move(workers);

        Q_EMIT displayListChanged();
    }

    // Queues exactly one hardware write per display onto the shared worker.
    // Called from the UI thread and re-invoked from write completions when a
    // newer value arrived while the previous write was in flight.
    void BrightnessManager::dispatchWrite(const QString& id, const std::shared_ptr<DisplayWorker>& worker) {
        if (!worker->beginWrite())
            return;

        // The target is copied: a rescan can replace the worker while the
        // write is queued, and the write still has to reach the display the
        // request was made for.
        const DdcTarget             target = worker->meta().ddc;
        const DisplayType           type   = worker->meta().type;
        const std::filesystem::path path   = worker->meta().backlightPath;

        vast::JobExecutor::instance().post([this, id, worker, target, type, path]() {
            const int  percent = clampPercent(worker->takePending());
            const auto result  = [&]() -> std::expected<void, BrightnessError> {
                switch (type) {
                    case DisplayType::Ddc: return writeDdcBrightness(target, percent);
                    case DisplayType::Backlight: return writeBacklightBrightness(path, percent);
                }
                std::unreachable();
            }();

            QMetaObject::invokeMethod(
                this,
                [this, id, worker, percent, result] {
                    worker->endWrite();

                    // A rescan may have replaced or dropped this display while
                    // the write was in flight. The hardware write already
                    // happened, so the value is published for the display that
                    // carries this id now, if there is one.
                    const auto it = mWorkers.find(id);
                    if (it == mWorkers.end())
                        return;

                    if (result) {
                        worker->setCurrentBrightness(percent);
                        it->second->setCurrentBrightness(percent);
                        Q_EMIT brightnessChanged(id, percent);
                    } else {
                        qWarning() << "[BrightnessManager] set failed for" << id << "—" << result.error().message;
                    }

                    // A newer value may have arrived while the hardware write
                    // was in flight; drain it instead of leaving the display stale.
                    // A replaced worker is not drained: the display it belonged
                    // to is gone and its pending value is not the current one.
                    if (it->second == worker && worker->hasPending())
                        dispatchWrite(id, worker);
                },
                Qt::QueuedConnection);
        });
    }

    QVariantList BrightnessManager::displays() const {
        QList<QVariant> out;
        out.reserve(static_cast<qsizetype>(mWorkers.size()));

        for (const auto& [id, worker] : mWorkers) {
            const auto& meta = worker->meta();
            out.append(QVariantMap{
                {QStringLiteral("id"), id},
                {QStringLiteral("name"), meta.name},
                {QStringLiteral("brightness"), worker->currentBrightness()},
                {QStringLiteral("isInternal"), meta.type == DisplayType::Backlight},
            });
        }
        return out;
    }

    void BrightnessManager::setBrightness(const QString& displayId, int percent) {
        if (const auto it = mWorkers.find(displayId); it != mWorkers.end()) {
            it->second->storePending(clampPercent(percent));
            dispatchWrite(displayId, it->second);
        }
    }

    void BrightnessManager::setBrightnessGroup(const QVariantMap& targets) {
        // Store all pending values first, then dispatch, so every display's
        // queued write picks up its final value in one sweep.
        for (const auto& [id, value] : targets.asKeyValueRange())
            if (const auto it = mWorkers.find(id); it != mWorkers.end())
                it->second->storePending(clampPercent(value.toInt()));

        for (const auto& [id, value] : targets.asKeyValueRange())
            if (const auto it = mWorkers.find(id); it != mWorkers.end())
                dispatchWrite(id, it->second);
    }

    void BrightnessManager::setBrightnessAll(int percent) {
        const int v = clampPercent(percent);

        for (const auto& [id, worker] : mWorkers)
            worker->storePending(v);

        for (const auto& [id, worker] : mWorkers)
            dispatchWrite(id, worker);
    }

    void BrightnessManager::saveProfile(const QString& name, const QVariantMap& targets) {
        mProfileStore.save(name, targets);
    }

    void BrightnessManager::applyProfile(const QString& name) {
        if (const auto targets = mProfileStore.find(name))
            setBrightnessGroup(*targets);
    }

    void BrightnessManager::removeProfile(const QString& name) {
        mProfileStore.remove(name);
    }

    QStringList BrightnessManager::profileNames() const {
        return mProfileStore.names();
    }

} // namespace vast
