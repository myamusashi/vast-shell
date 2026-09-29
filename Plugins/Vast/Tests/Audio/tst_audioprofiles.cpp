#include <qabstractitemmodel.h>
#include <qhash.h>
#include <qlist.h>
#include <qsignalspy.h>
#include <qstring.h>
#include <qtest.h>
#include <qvariant.h>

#include "../../Audio/AudioProfileFormat.hpp"
#include "../../Audio/AudioProfilesModel.hpp"

namespace {

    ProfileEntry profile(int index, const char* name, const char* desc, const char* avail, const char* readable) {
        ProfileEntry e;
        e.index       = index;
        e.name        = QString::fromLatin1(name);
        e.description = QString::fromLatin1(desc);
        e.available   = QString::fromLatin1(avail);
        e.readable    = QString::fromLatin1(readable);
        return e;
    }

    QList<ProfileEntry> threeProfiles() {
        return {
            profile(0, "output:stereo", "Stereo output", "yes", "Stereo"),
            profile(1, "output:surround-51", "5.1 surround", "yes", "Surround 51"),
            profile(2, "off", "No processing", "yes", "Off"),
        };
    }

} // namespace

class TestAudioProfiles : public QObject {
    Q_OBJECT

  private Q_SLOTS:
    void roleNamesMatchQmlContract();
    void rowCountRejectsValidParent();
    void dataRejectsOutOfRangeIndex();
    void dataReturnsInvalidForUnknownRole();
    void dataExposesEveryProfileField();
    void getReturnsAllFiveFields();
    void getRejectsOutOfRangeRow();
    void setProfilesReturnsFalseWhenUnchanged();
    void setProfilesEmitsResetWhenChanged();
    void setProfilesPreservesOrder();
    void countMatchesRowCount();
    void setProfilesWithEmptySpanClearsModel();

    void formatProfileNameMapsSpecialNames();
    void formatProfileNameStripsDirectionPrefixes();
    void formatProfileNameTitleCasesHyphenatedWords();
    void formatProfileNameJoinsAlternativesWithPlus();
    void formatProfileNameTrimsSurroundingWhitespace();
    void formatProfileNameLeavesUnknownPrefixes();
    void formatProfileNameHandlesDegenerateInput();
    void formatProfileNameAppliesSpecialCasesToWholeNameOnly();
};

void TestAudioProfiles::roleNamesMatchQmlContract() {
    AudioProfilesModel           model;
    const QHash<int, QByteArray> names = model.roleNames();

    QCOMPARE(names.size(), 5);
    QCOMPARE(names.value(static_cast<int>(AudioProfilesModel::IndexRole)), QByteArrayLiteral("index"));
    QCOMPARE(names.value(static_cast<int>(AudioProfilesModel::NameRole)), QByteArrayLiteral("name"));
    QCOMPARE(names.value(static_cast<int>(AudioProfilesModel::DescriptionRole)), QByteArrayLiteral("description"));
    QCOMPARE(names.value(static_cast<int>(AudioProfilesModel::AvailableRole)), QByteArrayLiteral("available"));
    QCOMPARE(names.value(static_cast<int>(AudioProfilesModel::ReadableRole)), QByteArrayLiteral("readable"));
}

void TestAudioProfiles::rowCountRejectsValidParent() {
    AudioProfilesModel model;
    const auto         entries = threeProfiles();
    model.setProfiles(entries);

    QCOMPARE(model.rowCount({}), 3);
    QCOMPARE(model.rowCount(model.index(0, 0)), 0);
}

void TestAudioProfiles::dataRejectsOutOfRangeIndex() {
    AudioProfilesModel model;
    const auto         entries = threeProfiles();
    model.setProfiles(entries);

    QVERIFY(!model.data(QModelIndex()).isValid());
    QVERIFY(!model.data(model.index(-1, 0)).isValid());
    QVERIFY(!model.data(model.index(3, 0)).isValid());
}

void TestAudioProfiles::dataReturnsInvalidForUnknownRole() {
    AudioProfilesModel model;
    const auto         entries = threeProfiles();
    model.setProfiles(entries);

    QVERIFY(!model.data(model.index(0, 0), 9999).isValid());
}

void TestAudioProfiles::dataExposesEveryProfileField() {
    AudioProfilesModel model;
    const auto         entries = threeProfiles();
    model.setProfiles(entries);

    using enum AudioProfilesModel::Roles;

    const QModelIndex idx = model.index(1, 0);
    QCOMPARE(model.data(idx, IndexRole).toInt(), 1);
    QCOMPARE(model.data(idx, NameRole).toString(), QStringLiteral("output:surround-51"));
    QCOMPARE(model.data(idx, DescriptionRole).toString(), QStringLiteral("5.1 surround"));
    QCOMPARE(model.data(idx, AvailableRole).toString(), QStringLiteral("yes"));
    QCOMPARE(model.data(idx, ReadableRole).toString(), QStringLiteral("Surround 51"));

    QCOMPARE(model.data(idx, IndexRole).metaType().id(), QMetaType::Int);
    QCOMPARE(model.data(idx, AvailableRole).metaType().id(), QMetaType::QString);
}

void TestAudioProfiles::getReturnsAllFiveFields() {
    AudioProfilesModel model;
    const auto         entries = threeProfiles();
    model.setProfiles(entries);

    const QVariantMap map = model.get(0);
    QCOMPARE(map.size(), 5);
    QCOMPARE(map.value(QStringLiteral("index")).toInt(), 0);
    QCOMPARE(map.value(QStringLiteral("name")).toString(), QStringLiteral("output:stereo"));
    QCOMPARE(map.value(QStringLiteral("description")).toString(), QStringLiteral("Stereo output"));
    QCOMPARE(map.value(QStringLiteral("available")).toString(), QStringLiteral("yes"));
    QCOMPARE(map.value(QStringLiteral("readable")).toString(), QStringLiteral("Stereo"));
}

void TestAudioProfiles::getRejectsOutOfRangeRow() {
    AudioProfilesModel model;
    const auto         entries = threeProfiles();
    model.setProfiles(entries);

    QVERIFY(model.get(-1).isEmpty());
    QVERIFY(model.get(3).isEmpty());
}

void TestAudioProfiles::setProfilesReturnsFalseWhenUnchanged() {
    AudioProfilesModel model;
    QSignalSpy         resetSpy(&model, &QAbstractItemModel::modelReset);

    const auto         entries = threeProfiles();
    QVERIFY(model.setProfiles(entries));
    QCOMPARE(resetSpy.count(), 1);

    // The std::ranges::equal fast path: an identical span must not reset the
    // model, or the QML view would rebuild on every PipeWire poll.
    QVERIFY(!model.setProfiles(entries));
    QCOMPARE(resetSpy.count(), 1);
}

void TestAudioProfiles::setProfilesEmitsResetWhenChanged() {
    AudioProfilesModel model;
    const auto         entries = threeProfiles();
    model.setProfiles(entries);

    QSignalSpy resetSpy(&model, &QAbstractItemModel::modelReset);

    auto       changed = threeProfiles();
    changed[1].name    = QStringLiteral("output:surround-71");
    QVERIFY(model.setProfiles(changed));
    QCOMPARE(resetSpy.count(), 1);
    QCOMPARE(model.rowCount({}), 3);
    QCOMPARE(model.get(1).value(QStringLiteral("name")).toString(), QStringLiteral("output:surround-71"));
}

void TestAudioProfiles::setProfilesPreservesOrder() {
    AudioProfilesModel model;
    const auto         entries = threeProfiles();
    model.setProfiles(entries);

    // Qml/Widgets/AudioProfiles.qml matches get(i) against AudioCard.activeIndex,
    // so the model must never reorder.
    QCOMPARE(model.get(0).value(QStringLiteral("index")).toInt(), 0);
    QCOMPARE(model.get(1).value(QStringLiteral("index")).toInt(), 1);
    QCOMPARE(model.get(2).value(QStringLiteral("index")).toInt(), 2);
}

void TestAudioProfiles::countMatchesRowCount() {
    AudioProfilesModel model;
    const auto         entries = threeProfiles();
    model.setProfiles(entries);

    QCOMPARE(model.count(), model.rowCount({}));
    QCOMPARE(model.count(), 3);
}

void TestAudioProfiles::setProfilesWithEmptySpanClearsModel() {
    AudioProfilesModel model;
    const auto         entries = threeProfiles();
    model.setProfiles(entries);

    const QList<ProfileEntry> empty;
    QVERIFY(model.setProfiles(empty));
    QCOMPARE(model.rowCount({}), 0);
    QVERIFY(model.get(0).isEmpty());
}

void TestAudioProfiles::formatProfileNameMapsSpecialNames() {
    QCOMPARE(formatProfileName(QStringLiteral("off")), QStringLiteral("Off"));
    QCOMPARE(formatProfileName(QStringLiteral("pro-audio")), QStringLiteral("Pro Audio"));
}

void TestAudioProfiles::formatProfileNameStripsDirectionPrefixes() {
    QCOMPARE(formatProfileName(QStringLiteral("output:stereo")), QStringLiteral("Stereo"));
    QCOMPARE(formatProfileName(QStringLiteral("input:mono")), QStringLiteral("Mono"));
}

void TestAudioProfiles::formatProfileNameTitleCasesHyphenatedWords() {
    QCOMPARE(formatProfileName(QStringLiteral("output:surround-51")), QStringLiteral("Surround 51"));
    QCOMPARE(formatProfileName(QStringLiteral("output:hdmi-stereo")), QStringLiteral("Hdmi Stereo"));
    // An already-capitalised word is left alone: only index 0 is replaced.
    QCOMPARE(formatProfileName(QStringLiteral("output:HDMI")), QStringLiteral("HDMI"));
}

void TestAudioProfiles::formatProfileNameJoinsAlternativesWithPlus() {
    QCOMPARE(formatProfileName(QStringLiteral("output:stereo+input:stereo")), QStringLiteral("Stereo + Stereo"));
    // A real four-way PipeWire name; this exact string is what the profile
    // dropdown renders via `textRole: "readable"`.
    QCOMPARE(formatProfileName(QStringLiteral("output:stereo+output:surround-51+input:stereo+input:mono")), QStringLiteral("Stereo + Surround 51 + Stereo + Mono"));
}

void TestAudioProfiles::formatProfileNameTrimsSurroundingWhitespace() {
    QCOMPARE(formatProfileName(QStringLiteral("  output:stereo  ")), QStringLiteral("Stereo"));
}

void TestAudioProfiles::formatProfileNameLeavesUnknownPrefixes() {
    // Only "output:" and "input:" are stripped; anything else stays literal.
    QCOMPARE(formatProfileName(QStringLiteral("foo:stereo")), QStringLiteral("Foo:stereo"));
}

void TestAudioProfiles::formatProfileNameHandlesDegenerateInput() {
    QCOMPARE(formatProfileName(QString()), QString());
    QCOMPARE(formatProfileName(QStringLiteral("output:")), QString());

    // An empty segment between two separators survives the join. This pins
    // current behaviour, not a desired outcome: if the formatter is ever
    // changed to drop empty parts, revisit this expectation deliberately.
    QCOMPARE(formatProfileName(QStringLiteral("output:stereo++input:mono")), QStringLiteral("Stereo +  + Mono"));
}

void TestAudioProfiles::formatProfileNameAppliesSpecialCasesToWholeNameOnly() {
    // "off"/"pro-audio" match the entire string, so as a component they go
    // through the generic path instead.
    QCOMPARE(formatProfileName(QStringLiteral("pro-audio+off")), QStringLiteral("Pro Audio + Off"));
}

QTEST_GUILESS_MAIN(TestAudioProfiles)
#include "tst_audioprofiles.moc"
