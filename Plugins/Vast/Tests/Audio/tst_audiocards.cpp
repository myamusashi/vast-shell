#include <qabstractitemmodel.h>
#include <qcoreapplication.h>
#include <qcoreevent.h>
#include <qhash.h>
#include <qlist.h>
#include <qmetatype.h>
#include <qobject.h>
#include <qpointer.h>
#include <qsignalspy.h>
#include <qstring.h>
#include <qtest.h>
#include <qvariant.h>

#include "../../Audio/AudioCard.hpp"
#include "../../Audio/AudioCardsModel.hpp"
#include "../../Audio/AudioDevicesWatcher.hpp"
#include "../../Audio/AudioProfilesWatcher.hpp"

namespace {

    ProfileEntry profile(int index, const char* name, const char* readable) {
        ProfileEntry e;
        e.index       = index;
        e.name        = QString::fromLatin1(name);
        e.description = QStringLiteral("desc");
        e.available   = QStringLiteral("yes");
        e.readable    = QString::fromLatin1(readable);
        return e;
    }

    QVariantMap activeMap(int index, const char* name, const char* readable) {
        return {
            {QStringLiteral("index"), index},
            {QStringLiteral("name"), QString::fromLatin1(name)},
            {QStringLiteral("description"), QStringLiteral("desc")},
            {QStringLiteral("available"), QStringLiteral("yes")},
            {QStringLiteral("readable"), QString::fromLatin1(readable)},
        };
    }

    CardEntry cardEntry(quint32 deviceId, const char* name, const char* description, qsizetype activeIndex, QVariantMap activeProfile, QList<ProfileEntry> profiles) {
        CardEntry e;
        e.deviceId      = deviceId;
        e.name          = QString::fromLatin1(name);
        e.description   = QString::fromLatin1(description);
        e.activeIndex   = activeIndex;
        e.activeProfile = activeProfile;
        e.profiles      = std::move(profiles);
        return e;
    }

    CardEntry twoProfileCard(quint32 deviceId, const char* name) {
        return cardEntry(deviceId, name, "Built-in Audio", 0, activeMap(0, "output:stereo", "Stereo"),
                         {profile(0, "output:stereo", "Stereo"), profile(1, "output:surround-51", "Surround 51")});
    }

} // namespace

class TestAudioCards : public QObject {
    Q_OBJECT

  private Q_SLOTS:
    void cardPropertiesMatchQmlContract();
    void setDeviceInfoReturnsFalseWhenIdentical();
    void setDeviceInfoEmitsOnlyForChangedFields();
    void setActiveProfileIsNoOpAtInitialValues();
    void setActiveProfileEmitsActiveIndexChangedOnce();
    void profilesIsAStableOwnedChildModel();
    void activeProfileMapRoundTripsVerbatim();

    void roleNamesMatchQmlContract();
    void upsertInsertsNewCardAndEmitsRowsInserted();
    void upsertExistingCardEmitsDataChangedNotInsert();
    void upsertIdenticalEntryReturnsFalseAndEmitsNothing();
    void upsertKeepsRowOrderAcrossInserts();
    void removeCardEmitsRowsRemovedAndDropsRow();
    void removeUnknownDeviceIdReturnsFalse();
    void cardReturnsNullForOutOfRangeRow();
    void dataExposesCardRolesAndPointers();
    void dataRejectsOutOfRangeIndexAndUnknownRole();
    void rowCountRejectsValidParent();
    void removedCardIsDeferredNotFreedImmediately();

    void watchersConstructAndExposeNonNullModels();
};

void TestAudioCards::cardPropertiesMatchQmlContract() {
    AudioCard                card;
    const QMetaObject* const meta = card.metaObject();

    // QML binds these by name (Audio.qml:110 reads activeIndex).
    for (const char* name : {"deviceId", "name", "description", "activeIndex", "activeProfile", "profiles"}) {
        QVERIFY2(meta->indexOfProperty(name) >= 0, name);
    }
}

void TestAudioCards::setDeviceInfoReturnsFalseWhenIdentical() {
    AudioCard card;

    QVERIFY(card.setDeviceInfo(1, QStringLiteral("a"), QStringLiteral("b")));
    QVERIFY(!card.setDeviceInfo(1, QStringLiteral("a"), QStringLiteral("b")));

    QCOMPARE(card.deviceId(), 1u);
    QCOMPARE(card.name(), QStringLiteral("a"));
    QCOMPARE(card.description(), QStringLiteral("b"));
}

void TestAudioCards::setDeviceInfoEmitsOnlyForChangedFields() {
    AudioCard  card;
    QSignalSpy idSpy(&card, &AudioCard::deviceIdChanged);
    QSignalSpy nameSpy(&card, &AudioCard::nameChanged);
    QSignalSpy descSpy(&card, &AudioCard::descriptionChanged);

    QVERIFY(card.setDeviceInfo(1, QStringLiteral("a"), QStringLiteral("b")));
    QCOMPARE(idSpy.count(), 1);
    QCOMPARE(nameSpy.count(), 1);
    QCOMPARE(descSpy.count(), 1);

    // Only descriptionChanged fires; the other two stay silent.
    QVERIFY(card.setDeviceInfo(1, QStringLiteral("a"), QStringLiteral("c")));
    QCOMPARE(idSpy.count(), 1);
    QCOMPARE(nameSpy.count(), 1);
    QCOMPARE(descSpy.count(), 2);

    QVERIFY(card.setDeviceInfo(2, QStringLiteral("a"), QStringLiteral("c")));
    QCOMPARE(idSpy.count(), 2);
    QCOMPARE(nameSpy.count(), 1);
    QCOMPARE(descSpy.count(), 2);
}

void TestAudioCards::setActiveProfileIsNoOpAtInitialValues() {
    AudioCard card;

    // The defaults (-1, empty map) make this a no-op; upsertCard relies on it.
    QVERIFY(!card.setActiveProfile(-1, {}));
    QCOMPARE(card.activeIndex(), static_cast<qsizetype>(-1));
    QVERIFY(card.activeProfile().isEmpty());
}

void TestAudioCards::setActiveProfileEmitsActiveIndexChangedOnce() {
    AudioCard  card;
    QSignalSpy spy(&card, &AudioCard::activeIndexChanged);

    QVERIFY(card.setActiveProfile(1, activeMap(1, "output:stereo", "Stereo")));
    QCOMPARE(spy.count(), 1);

    // Both properties share one NOTIFY, so a combined change fires once.
    QVERIFY(card.setActiveProfile(2, activeMap(2, "output:mono", "Mono")));
    QCOMPARE(spy.count(), 2);
    QCOMPARE(card.activeIndex(), static_cast<qsizetype>(2));
}

void TestAudioCards::profilesIsAStableOwnedChildModel() {
    AudioCard           card;

    AudioProfilesModel* first  = card.profiles();
    AudioProfilesModel* second = card.profiles();

    QVERIFY(first != nullptr);
    QCOMPARE(first, second);
    // The card must own its profiles model, or QML holds a dangling pointer.
    QCOMPARE(first->parent(), &card);
    QCOMPARE(first->count(), static_cast<qsizetype>(0));
}

void TestAudioCards::activeProfileMapRoundTripsVerbatim() {
    AudioCard  card;
    const auto map = activeMap(3, "output:surround-51", "Surround 51");

    QVERIFY(card.setActiveProfile(3, map));
    QCOMPARE(card.activeProfile(), map);
    QCOMPARE(card.activeProfile().size(), 5);
}

void TestAudioCards::roleNamesMatchQmlContract() {
    AudioCardsModel              model;
    const QHash<int, QByteArray> names = model.roleNames();

    QCOMPARE(names.size(), 7);
    QCOMPARE(names.value(static_cast<int>(AudioCardsModel::DeviceIdRole)), QByteArrayLiteral("deviceId"));
    QCOMPARE(names.value(static_cast<int>(AudioCardsModel::NameRole)), QByteArrayLiteral("name"));
    QCOMPARE(names.value(static_cast<int>(AudioCardsModel::DescriptionRole)), QByteArrayLiteral("description"));
    QCOMPARE(names.value(static_cast<int>(AudioCardsModel::ActiveIndexRole)), QByteArrayLiteral("activeIndex"));
    QCOMPARE(names.value(static_cast<int>(AudioCardsModel::ActiveProfileRole)), QByteArrayLiteral("activeProfile"));
    QCOMPARE(names.value(static_cast<int>(AudioCardsModel::ProfilesRole)), QByteArrayLiteral("profiles"));
    QCOMPARE(names.value(static_cast<int>(AudioCardsModel::CardRole)), QByteArrayLiteral("card"));
}

void TestAudioCards::upsertInsertsNewCardAndEmitsRowsInserted() {
    AudioCardsModel model;
    QSignalSpy      insertSpy(&model, &QAbstractItemModel::rowsInserted);
    QSignalSpy      resetSpy(&model, &QAbstractItemModel::modelReset);
    QSignalSpy      dataSpy(&model, &QAbstractItemModel::dataChanged);

    QVERIFY(model.upsertCard(twoProfileCard(1, "card_one")));
    QCOMPARE(model.count(), static_cast<qsizetype>(1));
    QCOMPARE(insertSpy.count(), 1);
    QCOMPARE(resetSpy.count(), 0);
    QCOMPARE(dataSpy.count(), 0);

    const auto args = insertSpy.takeFirst();
    QCOMPARE(args.at(1).value<int>(), 0);
    QCOMPARE(args.at(2).value<int>(), 0);
}

void TestAudioCards::upsertExistingCardEmitsDataChangedNotInsert() {
    AudioCardsModel model;
    QVERIFY(model.upsertCard(twoProfileCard(1, "card_one")));

    QSignalSpy insertSpy(&model, &QAbstractItemModel::rowsInserted);
    QSignalSpy dataSpy(&model, &QAbstractItemModel::dataChanged);

    QVERIFY(model.upsertCard(twoProfileCard(1, "card_renamed")));
    QCOMPARE(model.count(), static_cast<qsizetype>(1));
    QCOMPARE(insertSpy.count(), 0);
    QCOMPARE(dataSpy.count(), 1);
    QCOMPARE(model.card(0)->name(), QStringLiteral("card_renamed"));
}

void TestAudioCards::upsertIdenticalEntryReturnsFalseAndEmitsNothing() {
    AudioCardsModel model;
    const auto      entry = twoProfileCard(1, "card_one");
    QVERIFY(model.upsertCard(entry));

    QSignalSpy insertSpy(&model, &QAbstractItemModel::rowsInserted);
    QSignalSpy dataSpy(&model, &QAbstractItemModel::dataChanged);
    QSignalSpy resetSpy(&model, &QAbstractItemModel::modelReset);

    QVERIFY(!model.upsertCard(entry));
    QCOMPARE(insertSpy.count(), 0);
    QCOMPARE(dataSpy.count(), 0);
    QCOMPARE(resetSpy.count(), 0);
}

void TestAudioCards::upsertKeepsRowOrderAcrossInserts() {
    AudioCardsModel model;
    QVERIFY(model.upsertCard(twoProfileCard(1, "one")));
    QVERIFY(model.upsertCard(twoProfileCard(2, "two")));
    QVERIFY(model.upsertCard(twoProfileCard(3, "three")));

    // Both QML views drive a Repeater off this model, so row order is insertion order.
    QCOMPARE(model.count(), static_cast<qsizetype>(3));
    QCOMPARE(model.card(0)->deviceId(), 1u);
    QCOMPARE(model.card(1)->deviceId(), 2u);
    QCOMPARE(model.card(2)->deviceId(), 3u);
}

void TestAudioCards::removeCardEmitsRowsRemovedAndDropsRow() {
    AudioCardsModel model;
    QVERIFY(model.upsertCard(twoProfileCard(1, "one")));
    QVERIFY(model.upsertCard(twoProfileCard(2, "two")));

    QSignalSpy removeSpy(&model, &QAbstractItemModel::rowsRemoved);
    QVERIFY(model.removeCard(1));
    QCOMPARE(model.count(), static_cast<qsizetype>(1));
    QCOMPARE(removeSpy.count(), 1);
    QCOMPARE(model.card(0)->deviceId(), 2u);

    // The id is gone now, so the same call must report no change.
    QVERIFY(!model.removeCard(1));
    QCOMPARE(removeSpy.count(), 1);
}

void TestAudioCards::removeUnknownDeviceIdReturnsFalse() {
    AudioCardsModel model;
    QVERIFY(model.upsertCard(twoProfileCard(1, "one")));

    QSignalSpy removeSpy(&model, &QAbstractItemModel::rowsRemoved);
    QVERIFY(!model.removeCard(999));
    QCOMPARE(model.count(), static_cast<qsizetype>(1));
    QCOMPARE(removeSpy.count(), 0);
}

void TestAudioCards::cardReturnsNullForOutOfRangeRow() {
    AudioCardsModel model;
    QVERIFY(model.upsertCard(twoProfileCard(1, "one")));

    QVERIFY(model.card(0) != nullptr);
    QVERIFY(model.card(-1) == nullptr);
    QVERIFY(model.card(1) == nullptr);
    QVERIFY(model.card(999) == nullptr);
}

void TestAudioCards::dataExposesCardRolesAndPointers() {
    AudioCardsModel model;
    QVERIFY(model.upsertCard(twoProfileCard(7, "card_seven")));

    using enum AudioCardsModel::Roles;

    const QModelIndex idx  = model.index(0, 0);
    AudioCard* const  card = model.card(0);

    QCOMPARE(model.data(idx, DeviceIdRole).toUInt(), 7u);
    QCOMPARE(model.data(idx, NameRole).toString(), QStringLiteral("card_seven"));
    QCOMPARE(model.data(idx, DescriptionRole).toString(), QStringLiteral("Built-in Audio"));
    QCOMPARE(model.data(idx, ActiveIndexRole).toInt(), 0);
    QCOMPARE(model.data(idx, ActiveProfileRole).toMap(), activeMap(0, "output:stereo", "Stereo"));

    // VolumeSettings.qml:36 and ConfigurationTab.qml:50 bind CardRole.
    QCOMPARE(model.data(idx, CardRole).value<AudioCard*>(), card);

    // ProfilesRole must be the card's own instance, not a copy.
    QCOMPARE(model.data(idx, ProfilesRole).value<AudioProfilesModel*>(), card->profiles());
    QCOMPARE(card->profiles()->count(), static_cast<qsizetype>(2));
}

void TestAudioCards::dataRejectsOutOfRangeIndexAndUnknownRole() {
    AudioCardsModel model;
    QVERIFY(model.upsertCard(twoProfileCard(1, "one")));

    QVERIFY(!model.data(QModelIndex()).isValid());
    QVERIFY(!model.data(model.index(-1, 0)).isValid());
    QVERIFY(!model.data(model.index(1, 0)).isValid());
    QVERIFY(!model.data(model.index(0, 0), 9999).isValid());
}

void TestAudioCards::rowCountRejectsValidParent() {
    AudioCardsModel model;
    QVERIFY(model.upsertCard(twoProfileCard(1, "one")));
    QVERIFY(model.upsertCard(twoProfileCard(2, "two")));

    QCOMPARE(model.rowCount({}), 2);
    QCOMPARE(model.rowCount(model.index(0, 0)), 0);
}

void TestAudioCards::removedCardIsDeferredNotFreedImmediately() {
    AudioCardsModel model;
    QVERIFY(model.upsertCard(twoProfileCard(1, "one")));

    QPointer<AudioCard> alive = model.card(0);
    QVERIFY(!alive.isNull());

    QVERIFY(model.removeCard(1));
    // Still alive: removeCard calls deleteLater() after endRemoveRows().
    QVERIFY(!alive.isNull());

    QCoreApplication::sendPostedEvents(nullptr, QEvent::DeferredDelete);
    QVERIFY(alive.isNull());
}

void TestAudioCards::watchersConstructAndExposeNonNullModels() {
    // connected() is not asserted: the result depends on whether a PipeWire daemon is running. The
    // models must exist and start empty.
    AudioProfilesWatcher profiles;
    AudioDevicesWatcher  devices;

    QVERIFY(profiles.cards() != nullptr);
    QCOMPARE(profiles.cards()->rowCount({}), 0);
    QCOMPARE(profiles.cards()->count(), static_cast<qsizetype>(0));

    QVERIFY(devices.devices() != nullptr);
    QCOMPARE(devices.devices()->rowCount({}), 0);
    QCOMPARE(devices.devices()->count(), static_cast<qsizetype>(0));
}

QTEST_GUILESS_MAIN(TestAudioCards)
#include "tst_audiocards.moc"
