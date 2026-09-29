#include <qstring.h>
#include <qstringlist.h>
#include <qtest.h>
#include <qvariantmap.h>

#include <future>

#include "../../Brightness/BrightnessProfileStore.hpp"

class TestBrightnessStore : public QObject {
    Q_OBJECT

  private Q_SLOTS:
    void findOnEmptyStoreReturnsNullopt();
    void saveThenFindRoundTripsTheMap();
    void saveOverSameNameReplacesTargets();
    void removeDeletesTheProfile();
    void removeUnknownNameIsANoOp();
    void namesAreSortedBecauseBackedByStdMap();
    void namesExcludeRemovedProfiles();
    void findReturnsACopyMutatingItDoesNotAffectTheStore();
    void emptyTargetsRoundTripAsARealProfile();
    void concurrentFindDuringSaveIsSafe();
};

void TestBrightnessStore::findOnEmptyStoreReturnsNullopt() {
    vast::BrightnessProfileStore store;
    QVERIFY(!store.find(QStringLiteral("absent")).has_value());
}

void TestBrightnessStore::saveThenFindRoundTripsTheMap() {
    vast::BrightnessProfileStore store;
    // The shape Qml/Services/Brightness.qml:117-120 builds: display id -> percent.
    const QVariantMap targets{
        {QStringLiteral("ddc-1"), 80},
        {QStringLiteral("intel_backlight"), 40},
    };

    store.save(QStringLiteral("night"), targets);

    const auto found = store.find(QStringLiteral("night"));
    QVERIFY(found.has_value());
    QCOMPARE(*found, targets);
}

void TestBrightnessStore::saveOverSameNameReplacesTargets() {
    vast::BrightnessProfileStore store;

    store.save(QStringLiteral("p"), QVariantMap{{QStringLiteral("a"), 1}});
    store.save(QStringLiteral("p"), QVariantMap{{QStringLiteral("b"), 2}});

    const auto found = store.find(QStringLiteral("p"));
    QVERIFY(found.has_value());
    QCOMPARE(found->size(), 1);
    QCOMPARE(found->value(QStringLiteral("b")).toInt(), 2);
    QCOMPARE(store.names(), QStringList{QStringLiteral("p")});
}

void TestBrightnessStore::removeDeletesTheProfile() {
    vast::BrightnessProfileStore store;
    store.save(QStringLiteral("p"), QVariantMap{{QStringLiteral("a"), 1}});

    store.remove(QStringLiteral("p"));

    QVERIFY(!store.find(QStringLiteral("p")).has_value());
}

void TestBrightnessStore::removeUnknownNameIsANoOp() {
    vast::BrightnessProfileStore store;

    store.remove(QStringLiteral("never-existed"));
    QVERIFY(store.names().isEmpty());

    store.save(QStringLiteral("keep"), QVariantMap{{QStringLiteral("a"), 1}});
    store.remove(QStringLiteral("other"));
    QCOMPARE(store.names(), QStringList{QStringLiteral("keep")});
}

void TestBrightnessStore::namesAreSortedBecauseBackedByStdMap() {
    vast::BrightnessProfileStore store;

    store.save(QStringLiteral("zulu"), QVariantMap{{QStringLiteral("a"), 1}});
    store.save(QStringLiteral("alpha"), QVariantMap{{QStringLiteral("a"), 1}});
    store.save(QStringLiteral("mike"), QVariantMap{{QStringLiteral("a"), 1}});

    // QML renders profileNames() directly (Qml/Services/Brightness.qml:81), so
    // the ordering is user-visible and comes from std::map key ordering rather
    // than insertion order.
    QCOMPARE(store.names(), (QStringList{QStringLiteral("alpha"), QStringLiteral("mike"), QStringLiteral("zulu")}));
}

void TestBrightnessStore::namesExcludeRemovedProfiles() {
    vast::BrightnessProfileStore store;
    store.save(QStringLiteral("a"), QVariantMap{{QStringLiteral("x"), 1}});
    store.save(QStringLiteral("b"), QVariantMap{{QStringLiteral("x"), 1}});
    store.save(QStringLiteral("c"), QVariantMap{{QStringLiteral("x"), 1}});

    store.remove(QStringLiteral("b"));

    QCOMPARE(store.names(), (QStringList{QStringLiteral("a"), QStringLiteral("c")}));
}

void TestBrightnessStore::findReturnsACopyMutatingItDoesNotAffectTheStore() {
    vast::BrightnessProfileStore store;
    store.save(QStringLiteral("p"), QVariantMap{{QStringLiteral("a"), 1}});

    auto found = store.find(QStringLiteral("p"));
    QVERIFY(found.has_value());
    found->insert(QStringLiteral("injected"), 999);

    const auto again = store.find(QStringLiteral("p"));
    QVERIFY(again.has_value());
    QCOMPARE(again->size(), 1);
    QVERIFY(!again->contains(QStringLiteral("injected")));
}

void TestBrightnessStore::emptyTargetsRoundTripAsARealProfile() {
    vast::BrightnessProfileStore store;
    store.save(QStringLiteral("blank"), QVariantMap{});

    const auto found = store.find(QStringLiteral("blank"));
    QVERIFY(found.has_value());
    QVERIFY(found->isEmpty());
    QCOMPARE(store.names(), QStringList{QStringLiteral("blank")});
}

void TestBrightnessStore::concurrentFindDuringSaveIsSafe() {
    vast::BrightnessProfileStore store;
    store.save(QStringLiteral("p"), QVariantMap{{QStringLiteral("a"), 1}});

    // std::shared_mutex is the class's entire concurrency contract; nothing
    // else in the codebase exercises it under contention.
    auto reader = std::async(std::launch::async, [&store]() {
        for (int i = 0; i < 256; ++i) {
            const auto found = store.find(QStringLiteral("p"));
            if (!found.has_value())
                return false;
            (void)store.names();
        }
        return true;
    });

    for (int i = 0; i < 256; ++i) {
        store.save(QStringLiteral("p"), QVariantMap{{QStringLiteral("a"), i}});
        (void)store.names();
    }

    QVERIFY(reader.get());
}

QTEST_GUILESS_MAIN(TestBrightnessStore)
#include "tst_brightnessstore.moc"
