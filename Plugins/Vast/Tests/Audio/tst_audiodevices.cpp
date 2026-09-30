#include <qabstractitemmodel.h>
#include <qhash.h>
#include <qlist.h>
#include <qsignalspy.h>
#include <qstring.h>
#include <qtest.h>
#include <qvariant.h>

#include "../../Audio/AudioDevicesModel.hpp"

namespace {

    DeviceEntry device(quint32 id, const char* name, const char* desc, const char* mediaClass, const char* state, bool isMonitor, const char* monitorOf) {
        DeviceEntry e;
        e.id          = id;
        e.name        = QString::fromLatin1(name);
        e.description = QString::fromLatin1(desc);
        e.mediaClass  = QString::fromLatin1(mediaClass);
        e.state       = QString::fromLatin1(state);
        e.isMonitor   = isMonitor;
        e.monitorOf   = QString::fromLatin1(monitorOf);
        return e;
    }

    QList<DeviceEntry> sinkAndMonitor() {
        return {
            device(10, "alsa_output.pci-0000_00_1f.3.analog-stereo", "Built-in Audio Analog Stereo", "sink", "running", false, ""),
            device(10, "alsa_output.pci-0000_00_1f.3.analog-stereo.monitor", "Monitor of Built-in Audio Analog Stereo", "source", "running", true,
                   "alsa_output.pci-0000_00_1f.3.analog-stereo"),
        };
    }

} // namespace

class TestAudioDevices : public QObject {
    Q_OBJECT

  private Q_SLOTS:
    void roleNamesMatchQmlContract();
    void rowCountRejectsValidParent();
    void dataRejectsOutOfRangeIndex();
    void dataReturnsInvalidForUnknownRole();
    void dataExposesEveryDeviceField();
    void getReturnsAllSevenFields();
    void getRejectsOutOfRangeRow();
    void countMatchesRowCount();
    void setDevicesReplacesPreviousList();
    void setDevicesWithEmptySpanClearsModel();
    void setDevicesAlwaysResetsEvenWhenIdentical();
    void duplicateIdsAreNotDeduped();
    void monitorEntryCarriesMonitorOfLink();
    void countIsANotifyPropertySoQmlBindingsTrackIt();
    void setDevicesNotifiesCountOnlyWhenTheCountMoves();
};

void TestAudioDevices::roleNamesMatchQmlContract() {
    AudioDevicesModel            model;
    const QHash<int, QByteArray> names = model.roleNames();

    QCOMPARE(names.size(), 7);
    QCOMPARE(names.value(static_cast<int>(AudioDevicesModel::IdRole)), QByteArrayLiteral("id"));
    QCOMPARE(names.value(static_cast<int>(AudioDevicesModel::NameRole)), QByteArrayLiteral("name"));
    QCOMPARE(names.value(static_cast<int>(AudioDevicesModel::DescriptionRole)), QByteArrayLiteral("description"));
    QCOMPARE(names.value(static_cast<int>(AudioDevicesModel::MediaClassRole)), QByteArrayLiteral("mediaClass"));
    QCOMPARE(names.value(static_cast<int>(AudioDevicesModel::StateRole)), QByteArrayLiteral("state"));
    QCOMPARE(names.value(static_cast<int>(AudioDevicesModel::IsMonitorRole)), QByteArrayLiteral("isMonitor"));
    QCOMPARE(names.value(static_cast<int>(AudioDevicesModel::MonitorOfRole)), QByteArrayLiteral("monitorOf"));
}

void TestAudioDevices::rowCountRejectsValidParent() {
    AudioDevicesModel model;
    const auto        entries = sinkAndMonitor();
    model.setDevices(entries);

    QCOMPARE(model.rowCount({}), 2);
    QCOMPARE(model.rowCount(model.index(0, 0)), 0);
}

void TestAudioDevices::dataRejectsOutOfRangeIndex() {
    AudioDevicesModel model;
    const auto        entries = sinkAndMonitor();
    model.setDevices(entries);

    QVERIFY(!model.data(QModelIndex()).isValid());
    QVERIFY(!model.data(model.index(-1, 0)).isValid());
    QVERIFY(!model.data(model.index(2, 0)).isValid());
}

void TestAudioDevices::dataReturnsInvalidForUnknownRole() {
    AudioDevicesModel model;
    const auto        entries = sinkAndMonitor();
    model.setDevices(entries);

    QVERIFY(!model.data(model.index(0, 0), 9999).isValid());
}

void TestAudioDevices::dataExposesEveryDeviceField() {
    AudioDevicesModel model;
    const auto        entries = sinkAndMonitor();
    model.setDevices(entries);

    using enum AudioDevicesModel::Roles;

    const QModelIndex idx = model.index(0, 0);
    QCOMPARE(model.data(idx, IdRole).toUInt(), 10u);
    QCOMPARE(model.data(idx, NameRole).toString(), QStringLiteral("alsa_output.pci-0000_00_1f.3.analog-stereo"));
    QCOMPARE(model.data(idx, DescriptionRole).toString(), QStringLiteral("Built-in Audio Analog Stereo"));
    QCOMPARE(model.data(idx, MediaClassRole).toString(), QStringLiteral("sink"));
    QCOMPARE(model.data(idx, StateRole).toString(), QStringLiteral("running"));
    QCOMPARE(model.data(idx, IsMonitorRole).toBool(), false);
    QVERIFY(model.data(idx, MonitorOfRole).toString().isEmpty());

    QCOMPARE(model.data(idx, IdRole).metaType().id(), QMetaType::UInt);
    QCOMPARE(model.data(idx, IsMonitorRole).metaType().id(), QMetaType::Bool);
}

void TestAudioDevices::getReturnsAllSevenFields() {
    AudioDevicesModel model;
    const auto        entries = sinkAndMonitor();
    model.setDevices(entries);

    // Qml/Services/Audio.qml:81-87 indexes every one of these keys by string.
    const QVariantMap map = model.get(0);
    QCOMPARE(map.size(), 7);
    QCOMPARE(map.value(QStringLiteral("id")).toUInt(), 10u);
    QCOMPARE(map.value(QStringLiteral("name")).toString(), QStringLiteral("alsa_output.pci-0000_00_1f.3.analog-stereo"));
    QCOMPARE(map.value(QStringLiteral("description")).toString(), QStringLiteral("Built-in Audio Analog Stereo"));
    QCOMPARE(map.value(QStringLiteral("mediaClass")).toString(), QStringLiteral("sink"));
    QCOMPARE(map.value(QStringLiteral("state")).toString(), QStringLiteral("running"));
    QCOMPARE(map.value(QStringLiteral("isMonitor")).toBool(), false);
    QVERIFY(map.value(QStringLiteral("monitorOf")).toString().isEmpty());
}

void TestAudioDevices::getRejectsOutOfRangeRow() {
    AudioDevicesModel model;
    const auto        entries = sinkAndMonitor();
    model.setDevices(entries);

    QVERIFY(model.get(-1).isEmpty());
    QVERIFY(model.get(2).isEmpty());
}

void TestAudioDevices::countMatchesRowCount() {
    AudioDevicesModel model;
    const auto        entries = sinkAndMonitor();
    model.setDevices(entries);

    QCOMPARE(model.count(), model.rowCount({}));
    QCOMPARE(model.count(), 2);
}

void TestAudioDevices::setDevicesReplacesPreviousList() {
    AudioDevicesModel model;
    const auto        entries = sinkAndMonitor();
    model.setDevices(entries);

    const QList<DeviceEntry> single = {device(20, "bluez_output.HEADSET", "Headset", "source", "idle", false, "")};
    model.setDevices(single);

    QCOMPARE(model.rowCount({}), 1);
    QCOMPARE(model.get(0).value(QStringLiteral("id")).toUInt(), 20u);
}

void TestAudioDevices::setDevicesWithEmptySpanClearsModel() {
    AudioDevicesModel model;
    const auto        entries = sinkAndMonitor();
    model.setDevices(entries);

    const QList<DeviceEntry> empty;
    model.setDevices(empty);

    QCOMPARE(model.rowCount({}), 0);
}

void TestAudioDevices::setDevicesAlwaysResetsEvenWhenIdentical() {
    AudioDevicesModel model;
    QSignalSpy        resetSpy(&model, &QAbstractItemModel::modelReset);

    const auto        entries = sinkAndMonitor();
    model.setDevices(entries);
    QCOMPARE(resetSpy.count(), 1);

    // Unlike AudioProfilesModel::setProfiles there is no std::ranges::equal
    // fast path, so an identical span still resets. That is only safe because
    // AudioDevicesWatcher::poll guards the call with `if (changed)`. This test
    // exists so adding a dedup path later is a deliberate, visible change.
    model.setDevices(entries);
    QCOMPARE(resetSpy.count(), 2);
}

void TestAudioDevices::duplicateIdsAreNotDeduped() {
    AudioDevicesModel model;

    // The watcher synthesises a "<name>.monitor" row per sink carrying the
    // same id, so id is not a key.
    const QList<DeviceEntry> entries = {device(10, "sink_a", "A", "sink", "running", false, ""), device(10, "sink_a.monitor", "Monitor of A", "source", "running", true, "sink_a")};
    model.setDevices(entries);

    QCOMPARE(model.rowCount({}), 2);
    QCOMPARE(model.get(0).value(QStringLiteral("id")).toUInt(), 10u);
    QCOMPARE(model.get(1).value(QStringLiteral("id")).toUInt(), 10u);
}

void TestAudioDevices::monitorEntryCarriesMonitorOfLink() {
    AudioDevicesModel model;
    const auto        entries = sinkAndMonitor();
    model.setDevices(entries);

    using enum AudioDevicesModel::Roles;

    const QModelIndex monitor = model.index(1, 0);
    QCOMPARE(model.data(monitor, IsMonitorRole).toBool(), true);
    QCOMPARE(model.data(monitor, MonitorOfRole).toString(), QStringLiteral("alsa_output.pci-0000_00_1f.3.analog-stereo"));

    // Qml/Modules/Drawers/CaptureScreenVideo/PageAudio.qml splits sources and
    // monitors off these two fields, so both paths must agree.
    const QVariantMap map = model.get(1);
    QCOMPARE(map.value(QStringLiteral("isMonitor")).toBool(), true);
    QCOMPARE(map.value(QStringLiteral("monitorOf")).toString(), QStringLiteral("alsa_output.pci-0000_00_1f.3.analog-stereo"));
}

void TestAudioDevices::countIsANotifyPropertySoQmlBindingsTrackIt() {
    AudioDevicesModel        model;
    const QMetaObject* const meta = model.metaObject();

    const int                index = meta->indexOfProperty("count");
    QVERIFY2(index >= 0,
             "count must be a Q_PROPERTY; a Q_INVOKABLE records no QML binding dependency, "
             "so a binding that reads it never re-evaluates when the model fills asynchronously");
    const int notifyIndex = meta->indexOfSignal("countChanged()");
    QVERIFY(notifyIndex >= 0);
    QVERIFY(meta->property(index).hasNotifySignal());
    QCOMPARE(meta->property(index).notifySignal(), meta->method(notifyIndex));
}

void TestAudioDevices::setDevicesNotifiesCountOnlyWhenTheCountMoves() {
    AudioDevicesModel model;
    model.setDevices(sinkAndMonitor());

    QSignalSpy countSpy(&model, &AudioDevicesModel::countChanged);

    model.setDevices(sinkAndMonitor());
    QCOMPARE(countSpy.count(), 0);

    const QList<DeviceEntry> single{sinkAndMonitor().first()};
    model.setDevices(single);
    QCOMPARE(countSpy.count(), 1);

    const QList<DeviceEntry> empty;
    model.setDevices(empty);
    QCOMPARE(countSpy.count(), 2);
}

QTEST_GUILESS_MAIN(TestAudioDevices)
#include "tst_audiodevices.moc"
