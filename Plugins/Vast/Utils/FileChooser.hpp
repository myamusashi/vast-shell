#pragma once

#include <qdbusargument.h>
#include <qdbusconnection.h>
#include <qdbuscontext.h>
#include <qdbusmessage.h>
#include <qhash.h>
#include <qlist.h>
#include <qobject.h>
#include <qqmlintegration.h>
#include <qstring.h>
#include <qstringlist.h>
#include <qvariant.h>

class QDBusPendingCallWatcher;

namespace vast {

    struct SPortalFilterRule {
        quint32 type{0};
        QString pattern;

        bool    operator==(const SPortalFilterRule& other) const = default;
    };

    struct SPortalFilter {
        QString                  label;
        QList<SPortalFilterRule> rules;

        bool                     operator==(const SPortalFilter& other) const = default;
    };

    using PortalFilterList = QList<SPortalFilter>;

    QDBusArgument&       operator<<(QDBusArgument& argument, const SPortalFilterRule& rule);
    const QDBusArgument& operator>>(const QDBusArgument& argument, SPortalFilterRule& rule);
    QDBusArgument&       operator<<(QDBusArgument& argument, const SPortalFilter& filter);
    const QDBusArgument& operator>>(const QDBusArgument& argument, SPortalFilter& filter);

    /// Declarative QML element (`Vast.Utils.FileChooser`) for XDG Desktop Portal file/folder selection.
    /// Ownership: instantiated and owned by the QML engine (or caller-supplied parent `QObject*`);
    /// internal `QDBusPendingCallWatcher` instances are parented to `this` and freed via `deleteLater()`.
    class FileChooser : public QObject, protected QDBusContext {
        Q_OBJECT
        QML_ELEMENT

        Q_PROPERTY(QString title READ title WRITE setTitle NOTIFY titleChanged)
        Q_PROPERTY(bool selectFolder READ selectFolder WRITE setSelectFolder NOTIFY selectFolderChanged)
        Q_PROPERTY(QStringList nameFilters READ nameFilters WRITE setNameFilters NOTIFY nameFiltersChanged)
        Q_PROPERTY(bool busy READ busy NOTIFY busyChanged)

      public:
        explicit FileChooser(QObject* parent = nullptr, QDBusConnection bus = QDBusConnection::sessionBus());
        ~FileChooser() override;

        FileChooser(const FileChooser&)                                = delete;
        FileChooser& operator=(const FileChooser&)                     = delete;
        FileChooser(FileChooser&&)                                     = delete;
        FileChooser&                          operator=(FileChooser&&) = delete;

        [[nodiscard]] QString                 title() const;
        void                                  setTitle(const QString& title);

        [[nodiscard]] bool                    selectFolder() const noexcept;
        void                                  setSelectFolder(bool selectFolder);

        [[nodiscard]] QStringList             nameFilters() const;
        void                                  setNameFilters(const QStringList& nameFilters);

        [[nodiscard]] bool                    busy() const noexcept;

        Q_INVOKABLE void                      open();

        static void                           registerMetaTypes();
        [[nodiscard]] static PortalFilterList buildFilters(const QStringList& nameFilters);
        [[nodiscard]] static QDBusMessage     buildOpenFileMessage(const QString& title, const QString& handleToken, bool selectFolder, const QStringList& nameFilters = {});
        [[nodiscard]] static QString          expectedRequestPath(const QString& baseService, const QString& handleToken);
        [[nodiscard]] static QStringList      urisToLocalPaths(const QStringList& uris);

      public Q_SLOTS:
        void onPortalResponse(quint32 responseCode, const QVariantMap& results);

      Q_SIGNALS:
        void titleChanged();
        void selectFolderChanged();
        void nameFiltersChanged();
        void busyChanged();
        void fileSelected(const QString& path);
        void filesSelected(const QStringList& paths);
        void cancelled();
        void failed(const QString& reason);

      private:
        [[nodiscard]] bool      ensureSignalConnected();
        [[nodiscard]] QString   nextToken();
        void                    disconnectSignalIfIdle();

        QDBusConnection         mBus;
        QString                 mTitle;
        QStringList             mNameFilters{QStringLiteral("*")};
        QHash<QString, QString> mPendingRequests;
        quint32                 mTokenCounter{0};
        bool                    mSelectFolder{false};
        bool                    mSignalConnected{false};
    };

} // namespace vast

Q_DECLARE_METATYPE(vast::SPortalFilterRule)
Q_DECLARE_METATYPE(vast::SPortalFilter)
Q_DECLARE_METATYPE(vast::PortalFilterList)
