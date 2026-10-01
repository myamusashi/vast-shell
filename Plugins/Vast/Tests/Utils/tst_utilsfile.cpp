#include <qstring.h>
#include <qtest.h>
#include <qtemporarydir.h>

#include <memory>

#include "../../Utils/Read.hpp"
#include "../../Utils/Write.hpp"

class TestUtilsFile : public QObject {
    Q_OBJECT

  private Q_SLOTS:
    void initTestCase();

    void readingAMissingFileReturnsANullString();
    void writeThenReadRoundTrips();
    void roundTripsNonAsciiExactly();
    void writingAnEmptyStringSucceedsAndReadsBackEmpty();
    void writingOverAnExistingFileReplacesItEntirely();
    void writingIntoAMissingDirectoryFails();
    void writingIsIdempotentForIdenticalContents();

    void fileExistsRejectsMissingAndEmptyPaths();
    void fileExistsAcceptsARegularFile();
    void isReadableFileAcceptsARegularFile();
    void isReadableFileRejectsADirectory();

  private:
    [[nodiscard]] QString path(const char* name) const {
        return mDir->path() + QLatin1Char('/') + QLatin1String(name);
    }

    std::unique_ptr<QTemporaryDir> mDir;
};

void TestUtilsFile::initTestCase() {
    mDir = std::make_unique<QTemporaryDir>();
    QVERIFY(mDir->isValid());
}

void TestUtilsFile::readingAMissingFileReturnsANullString() {
    const QString text = Read::readFile(path("does-not-exist.txt"));

    QVERIFY(text.isNull());
}

void TestUtilsFile::writeThenReadRoundTrips() {
    QVERIFY(Write::writeFile(path("hello.txt"), QStringLiteral("hello")));
    QCOMPARE(Read::readFile(path("hello.txt")), QStringLiteral("hello"));
}

void TestUtilsFile::roundTripsNonAsciiExactly() {
    const QString original = QString::fromUtf8("héllo 日本語 \xF0\x9D\x8E\xB5");

    QVERIFY(Write::writeFile(path("utf8.txt"), original));

    const QString readBack = Read::readFile(path("utf8.txt"));
    QCOMPARE(readBack, original);
    QVERIFY(!readBack.isNull());
}

void TestUtilsFile::writingAnEmptyStringSucceedsAndReadsBackEmpty() {
    QVERIFY(Write::writeFile(path("empty.txt"), QString()));

    const QString text = Read::readFile(path("empty.txt"));
    QVERIFY(text.isEmpty());
    QVERIFY(text.isNull());
}

void TestUtilsFile::writingOverAnExistingFileReplacesItEntirely() {
    QVERIFY(Write::writeFile(path("replace.txt"), QStringLiteral("a much longer first value")));
    QVERIFY(Write::writeFile(path("replace.txt"), QStringLiteral("second")));

    // QIODevice::WriteOnly truncates; no bytes survive from the longer first write.
    QCOMPARE(Read::readFile(path("replace.txt")), QStringLiteral("second"));
}

void TestUtilsFile::writingIntoAMissingDirectoryFails() {
    // writeFile does not create parent directories (Write.cpp:9-12).
    QVERIFY(!Write::writeFile(path("nope/child.txt"), QStringLiteral("x")));
    QVERIFY(Read::readFile(path("nope/child.txt")).isNull());
}

void TestUtilsFile::writingIsIdempotentForIdenticalContents() {
    const QString value = QStringLiteral("stable contents");

    QVERIFY(Write::writeFile(path("idem.txt"), value));
    QCOMPARE(Read::readFile(path("idem.txt")), value);
    QVERIFY(Write::writeFile(path("idem.txt"), value));
    QCOMPARE(Read::readFile(path("idem.txt")), value);
}

void TestUtilsFile::fileExistsRejectsMissingAndEmptyPaths() {
    QVERIFY(!Read::fileExists(path("does-not-exist.txt")));
    QVERIFY(!Read::fileExists(QString()));
}

void TestUtilsFile::fileExistsAcceptsARegularFile() {
    QVERIFY(Write::writeFile(path("present.txt"), QStringLiteral("x")));

    QVERIFY(Read::fileExists(path("present.txt")));
}

void TestUtilsFile::isReadableFileAcceptsARegularFile() {
    QVERIFY(Write::writeFile(path("readable.txt"), QStringLiteral("x")));

    QVERIFY(Read::isReadableFile(path("readable.txt")));
}

void TestUtilsFile::isReadableFileRejectsADirectory() {
    QVERIFY(Read::fileExists(mDir->path()));
    QVERIFY(!Read::isReadableFile(mDir->path()));
}
QTEST_GUILESS_MAIN(TestUtilsFile)
#include "tst_utilsfile.moc"
