#include "FileChooser.hpp"

#include <qdbusmetatype.h>
#include <qdbuspendingcall.h>
#include <qdbuspendingreply.h>
#include <qdebug.h>
#include <qlogging.h>
#include <qrandom.h>
#include <qurl.h>

#include <utility>

namespace vast {

    namespace {
        constexpr auto SERVICE            = "org.freedesktop.portal.Desktop";
        constexpr auto OBJECT_PATH        = "/org/freedesktop/portal/desktop";
        constexpr auto CHOOSER_IFACE      = "org.freedesktop.portal.FileChooser";
        constexpr auto OPEN_METHOD        = "OpenFile";
        constexpr auto REQUEST_IFACE      = "org.freedesktop.portal.Request";
        constexpr auto RESPONSE_MEMBER    = "Response";
        constexpr auto RESPONSE_SIGNATURE = "ua{sv}";
        constexpr int  CALL_TIMEOUT_MS    = 15000;
    } // namespace

    QDBusArgument& operator<<(QDBusArgument& argument, const SPortalFilterRule& rule) {
        argument.beginStructure();
        argument << rule.type << rule.pattern;
        argument.endStructure();
        return argument;
    }

    const QDBusArgument& operator>>(const QDBusArgument& argument, SPortalFilterRule& rule) {
        argument.beginStructure();
        argument >> rule.type >> rule.pattern;
        argument.endStructure();
        return argument;
    }

    QDBusArgument& operator<<(QDBusArgument& argument, const SPortalFilter& filter) {
        argument.beginStructure();
        argument << filter.label << filter.rules;
        argument.endStructure();
        return argument;
    }

    const QDBusArgument& operator>>(const QDBusArgument& argument, SPortalFilter& filter) {
        argument.beginStructure();
        argument >> filter.label >> filter.rules;
        argument.endStructure();
        return argument;
    }

    void FileChooser::registerMetaTypes() {
        static const bool registered = []() {
            qDBusRegisterMetaType<SPortalFilterRule>();
            qDBusRegisterMetaType<SPortalFilter>();
            qDBusRegisterMetaType<PortalFilterList>();
            return true;
        }();
        Q_UNUSED(registered);
    }

    FileChooser::FileChooser(QObject* parent, QDBusConnection bus) : QObject(parent), mBus(std::move(bus)) {
        registerMetaTypes();
    }

    FileChooser::~FileChooser() {
        if (mBus.isConnected()) {
            for (auto it = mPendingRequests.cbegin(); it != mPendingRequests.cend(); ++it) {
                if (!it.value().isEmpty() && it.value() != QLatin1String("/"))
                    mBus.asyncCall(QDBusMessage::createMethodCall(QLatin1String(SERVICE), it.value(), QLatin1String(REQUEST_IFACE), QStringLiteral("Close")));
            }
        }
        mPendingRequests.clear();
        disconnectSignalIfIdle();
    }

    QString FileChooser::title() const {
        return mTitle;
    }

    void FileChooser::setTitle(const QString& title) {
        if (mTitle == title)
            return;
        mTitle = title;
        Q_EMIT titleChanged();
    }

    bool FileChooser::selectFolder() const noexcept {
        return mSelectFolder;
    }

    void FileChooser::setSelectFolder(bool selectFolder) {
        if (mSelectFolder == selectFolder)
            return;
        mSelectFolder = selectFolder;
        Q_EMIT selectFolderChanged();
    }

    QStringList FileChooser::nameFilters() const {
        return mNameFilters;
    }

    void FileChooser::setNameFilters(const QStringList& nameFilters) {
        if (mNameFilters == nameFilters)
            return;
        mNameFilters = nameFilters;
        Q_EMIT nameFiltersChanged();
    }

    bool FileChooser::busy() const noexcept {
        return !mPendingRequests.isEmpty();
    }

    bool FileChooser::ensureSignalConnected() {
        if (mSignalConnected)
            return true;

        if (!mBus.isConnected()) {
            qWarning() << "[Vast.Utils] Cannot connect portal signal: bus is not connected";
            return false;
        }

        const auto* const slot = SLOT(onPortalResponse(quint32, QVariantMap));
        const bool connected   = mBus.connect(QString(), QString(), QLatin1String(REQUEST_IFACE), QLatin1String(RESPONSE_MEMBER), QLatin1String(RESPONSE_SIGNATURE), this, slot);
        if (!connected) {
            qWarning() << "[Vast.Utils] Failed to subscribe to org.freedesktop.portal.Request.Response signal";
            return false;
        }

        mSignalConnected = true;
        return true;
    }
    void FileChooser::disconnectSignalIfIdle() {
        if (!mSignalConnected || !mPendingRequests.isEmpty())
            return;

        if (mBus.isConnected()) {
            const auto* const slot = SLOT(onPortalResponse(quint32, QVariantMap));
            mBus.disconnect(QString(), QString(), QLatin1String(REQUEST_IFACE), QLatin1String(RESPONSE_MEMBER), QLatin1String(RESPONSE_SIGNATURE), this, slot);
        }
        mSignalConnected = false;
    }

    QString FileChooser::nextToken() {
        return QStringLiteral("picker_%1_%2").arg(++mTokenCounter).arg(QRandomGenerator::global()->generate(), 8, 16, QLatin1Char('0'));
    }

    PortalFilterList FileChooser::buildFilters(const QStringList& nameFilters) {
        QStringList specificPatterns;
        for (const QString& filter : nameFilters) {
            const QString trimmed = filter.trimmed();
            if (trimmed.isEmpty() || trimmed == QLatin1String("*") || trimmed == QLatin1String("*.*"))
                continue;
            specificPatterns.append(trimmed);
        }

        if (specificPatterns.isEmpty())
            return {};

        SPortalFilter supportedFilter;
        supportedFilter.label = QStringLiteral("Supported Files (%1)").arg(specificPatterns.join(QLatin1Char(' ')));
        for (const QString& pattern : specificPatterns)
            supportedFilter.rules.append(SPortalFilterRule{.type = 0U, .pattern = pattern});

        SPortalFilter allFilter;
        allFilter.label = QStringLiteral("All Files");
        allFilter.rules.append(SPortalFilterRule{.type = 0U, .pattern = QStringLiteral("*")});

        return {supportedFilter, allFilter};
    }

    QDBusMessage FileChooser::buildOpenFileMessage(const QString& title, const QString& handleToken, bool selectFolder, const QStringList& nameFilters) {
        registerMetaTypes();

        if (handleToken.trimmed().isEmpty())
            return {};

        const QString effectiveTitle = title.trimmed().isEmpty() ? (selectFolder ? QStringLiteral("Select Folder") : QStringLiteral("Select File")) : title;

        QVariantMap   options;
        options.insert(QStringLiteral("handle_token"), handleToken);
        options.insert(QStringLiteral("modal"), true);

        if (selectFolder) {
            options.insert(QStringLiteral("directory"), true);
        } else {
            const PortalFilterList filters = buildFilters(nameFilters);
            if (!filters.isEmpty())
                options.insert(QStringLiteral("filters"), QVariant::fromValue(filters));
        }

        QDBusMessage message = QDBusMessage::createMethodCall(QLatin1String(SERVICE), QLatin1String(OBJECT_PATH), QLatin1String(CHOOSER_IFACE), QLatin1String(OPEN_METHOD));
        message.setArguments({QString(), effectiveTitle, options});
        return message;
    }

    QString FileChooser::expectedRequestPath(const QString& baseService, const QString& handleToken) {
        if (handleToken.trimmed().isEmpty())
            return {};

        QString sanitized = baseService;
        if (sanitized.startsWith(QLatin1Char(':')))
            sanitized.remove(0, 1);
        sanitized.replace(QLatin1Char('.'), QLatin1Char('_'));

        if (sanitized.isEmpty())
            return {};

        return QStringLiteral("/org/freedesktop/portal/desktop/request/%1/%2").arg(sanitized, handleToken);
    }

    QStringList FileChooser::urisToLocalPaths(const QStringList& uris) {
        QStringList paths;
        paths.reserve(uris.size());
        for (const QString& rawUri : uris) {
            if (rawUri.trimmed().isEmpty())
                continue;

            const QUrl url(rawUri);
            if (url.isLocalFile())
                paths.append(url.toLocalFile());
            else if (rawUri.startsWith(QLatin1String("file://")))
                paths.append(QUrl::fromPercentEncoding(rawUri.mid(7).toUtf8()));
            else
                paths.append(rawUri);
        }
        return paths;
    }

    void FileChooser::open() {
        if (!mPendingRequests.isEmpty())
            return;
        if (!mBus.isConnected()) {
            qWarning() << "[Vast.Utils] Portal FileChooser open rejected: session bus is not connected";
            Q_EMIT failed(QStringLiteral("Session bus is not connected"));
            return;
        }

        if (!ensureSignalConnected()) {
            Q_EMIT failed(QStringLiteral("Could not subscribe to portal Response signal"));
            return;
        }

        const QString token   = nextToken();
        const auto    message = buildOpenFileMessage(mTitle, token, mSelectFolder, mNameFilters);
        if (message.type() == QDBusMessage::InvalidMessage) {
            Q_EMIT failed(QStringLiteral("Invalid portal OpenFile request parameters"));
            return;
        }

        const bool wasEmpty = mPendingRequests.isEmpty();
        mPendingRequests.insert(token, expectedRequestPath(mBus.baseService(), token));
        if (wasEmpty)
            Q_EMIT busyChanged();

        auto* watcher = new QDBusPendingCallWatcher(mBus.asyncCall(message, CALL_TIMEOUT_MS), this);
        connect(watcher, &QDBusPendingCallWatcher::finished, this, [this, watcher, token](const QDBusPendingCall* call) {
            watcher->deleteLater();
            const QDBusPendingReply<QDBusObjectPath> reply(*call);

            if (reply.isError()) {
                const bool wasBusy = !mPendingRequests.isEmpty();
                mPendingRequests.remove(token);
                disconnectSignalIfIdle();
                if (wasBusy && mPendingRequests.isEmpty())
                    Q_EMIT busyChanged();

                qWarning() << "[Vast.Utils] Portal FileChooser OpenFile failed:" << reply.error().message();
                Q_EMIT failed(reply.error().message());
                return;
            }

            const QString replyPath = reply.value().path();
            if (replyPath.isEmpty() || replyPath == QLatin1String("/")) {
                const bool wasBusy = !mPendingRequests.isEmpty();
                mPendingRequests.remove(token);
                disconnectSignalIfIdle();
                if (wasBusy && mPendingRequests.isEmpty())
                    Q_EMIT busyChanged();

                qWarning() << "[Vast.Utils] Portal FileChooser returned invalid request path:" << replyPath;
                Q_EMIT failed(QStringLiteral("Portal returned an invalid request path"));
                return;
            }

            if (mPendingRequests.contains(token))
                mPendingRequests[token] = replyPath;
        });
    }
    void FileChooser::onPortalResponse(quint32 responseCode, const QVariantMap& results) {
        const QString signalPath = calledFromDBus() ? message().path() : QString();

        QString       matchedToken;
        for (auto it = mPendingRequests.cbegin(); it != mPendingRequests.cend(); ++it) {
            if (!signalPath.isEmpty() && (signalPath == it.value() || signalPath.endsWith(QLatin1Char('/') + it.key()))) {
                matchedToken = it.key();
                break;
            }
        }

        if (matchedToken.isEmpty() && signalPath.isEmpty() && mPendingRequests.size() == 1)
            matchedToken = mPendingRequests.cbegin().key();

        if (matchedToken.isEmpty())
            return;

        const bool wasBusy = !mPendingRequests.isEmpty();
        mPendingRequests.remove(matchedToken);
        disconnectSignalIfIdle();
        if (wasBusy && mPendingRequests.isEmpty())
            Q_EMIT busyChanged();

        if (responseCode != 0) {
            Q_EMIT cancelled();
            return;
        }

        const QStringList paths = urisToLocalPaths(results.value(QStringLiteral("uris")).toStringList());
        if (paths.isEmpty()) {
            Q_EMIT cancelled();
            return;
        }

        Q_EMIT filesSelected(paths);
        Q_EMIT fileSelected(paths.constFirst());
    }

} // namespace vast
