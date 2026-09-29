#include <qbuffer.h>
#include <qbytearray.h>
#include <qcryptographichash.h>
#include <qimage.h>
#include <qstring.h>
#include <qtest.h>

#include "../../Clipboard/ClipboardContentClassifier.hpp"
#include "../../Clipboard/ClipboardEntry.hpp"
#include "../../Clipboard/ClipboardPreviewCache.hpp"
#include "../../Clipboard/LoopbackGuard.hpp"
#include "../../Clipboard/WaylandDataControl.hpp"

namespace {

    // The preview cache path is hardcoded, so ids must be unique per test to
    // keep repeated or parallel runs from colliding.
    qint64 uniqueId(const char* testName) {
        return qHash(QString::fromLatin1(testName)) & 0x7FFFFFFF;
    }

    QByteArray pngBytes(int width, int height) {
        QImage image(width, height, QImage::Format_RGB32);
        image.fill(Qt::red);
        QByteArray bytes;
        QBuffer    buffer(&bytes);
        buffer.open(QIODevice::WriteOnly);
        if (!image.save(&buffer, "PNG"))
            return {};
        return bytes;
    }

} // namespace

class TestClipboardHelpers : public QObject {
    Q_OBJECT

  private Q_SLOTS:
    // vast::ClipboardEntry
    void typeStringRoundTrips();
    void typeFromStringFallsBackToText();

    // vast::ClipboardContentClassifier
    void typeFromMimeMapsKnownTypes();
    void isBlankTextOrHtmlDetectsBlanks();
    void buildEntryRoutesImageDataToBlob();
    void buildEntryRoutesTextToContent();
    void buildEntryHashesTheRightBytes();
    void buildPreviewPassesTextThrough();
    void buildPreviewStripsHtmlMarkup();

    // vast::WaylandDataControl::htmlToPlainText
    void htmlToPlainTextStripsScriptAndStyle();
    void htmlToPlainTextConvertsBlockEndsToNewlines();
    void htmlToPlainTextTrimsResult();
    void htmlToPlainTextHandlesEmptyInput();

    // vast::LoopbackGuard
    void loopbackGuardUnarmedNeverSuppresses();
    void loopbackGuardSuppressesOnceAfterArm();
    void loopbackGuardDoesNotSuppressDifferentContent();
    void loopbackGuardArmingReplacesPreviousHash();

    // vast::ClipboardPreviewCache
    void previewCachePathFormat();
    void previewCacheExistsIsFalseBeforeWrite();
    void previewCacheWriteCreatesReadablePng();
    void previewCacheWriteIgnoresNonPngData();
    void previewCacheWriteScalesLargeImagesDown();
    void previewCacheWriteLeavesSmallImagesUnscaled();
    void previewCacheRemoveDeletesTheFile();
};

void TestClipboardHelpers::typeStringRoundTrips() {
    using vast::ClipboardType;

    for (const vast::ClipboardType type : {vast::ClipboardType::Text, vast::ClipboardType::Html, vast::ClipboardType::Image, vast::ClipboardType::Files}) {
        vast::ClipboardEntry entry;
        entry.type = type;
        QCOMPARE(vast::ClipboardEntry::typeFromString(entry.typeString()), type);
    }

    vast::ClipboardEntry probe;
    probe.type = vast::ClipboardType::Text;
    QCOMPARE(probe.typeString(), QStringLiteral("text"));
    probe.type = vast::ClipboardType::Html;
    QCOMPARE(probe.typeString(), QStringLiteral("html"));
    probe.type = vast::ClipboardType::Image;
    QCOMPARE(probe.typeString(), QStringLiteral("image"));
    probe.type = vast::ClipboardType::Files;
    QCOMPARE(probe.typeString(), QStringLiteral("files"));
}

void TestClipboardHelpers::typeFromStringFallsBackToText() {
    using vast::ClipboardType;

    QCOMPARE(vast::ClipboardEntry::typeFromString(QStringLiteral("unknown")), vast::ClipboardType::Text);
    QCOMPARE(vast::ClipboardEntry::typeFromString(QString()), vast::ClipboardType::Text);
    QCOMPARE(vast::ClipboardEntry::typeFromString(QStringLiteral("TEXT")), vast::ClipboardType::Text);
}

void TestClipboardHelpers::typeFromMimeMapsKnownTypes() {
    using vast::ClipboardContentClassifier;
    using vast::ClipboardType;

    QCOMPARE(vast::ClipboardContentClassifier::typeFromMime(QStringLiteral("image/png")), vast::ClipboardType::Image);
    QCOMPARE(vast::ClipboardContentClassifier::typeFromMime(QStringLiteral("text/html")), vast::ClipboardType::Html);
    QCOMPARE(vast::ClipboardContentClassifier::typeFromMime(QStringLiteral("text/uri-list")), vast::ClipboardType::Files);
    QCOMPARE(vast::ClipboardContentClassifier::typeFromMime(QStringLiteral("text/plain;charset=utf-8")), vast::ClipboardType::Text);
    QCOMPARE(vast::ClipboardContentClassifier::typeFromMime(QString()), vast::ClipboardType::Text);
}

void TestClipboardHelpers::isBlankTextOrHtmlDetectsBlanks() {
    using vast::ClipboardContentClassifier;
    using vast::ClipboardType;

    for (const vast::ClipboardType type : {vast::ClipboardType::Text, vast::ClipboardType::Html}) {
        QVERIFY(vast::ClipboardContentClassifier::isBlankTextOrHtml(type, QByteArray()));
        QVERIFY(vast::ClipboardContentClassifier::isBlankTextOrHtml(type, QByteArray(" ")));
        QVERIFY(vast::ClipboardContentClassifier::isBlankTextOrHtml(type, QByteArray("\t\n")));
        QVERIFY(!vast::ClipboardContentClassifier::isBlankTextOrHtml(type, QByteArray("x")));
    }

    QVERIFY(!vast::ClipboardContentClassifier::isBlankTextOrHtml(vast::ClipboardType::Image, QByteArray()));
    QVERIFY(!vast::ClipboardContentClassifier::isBlankTextOrHtml(vast::ClipboardType::Files, QByteArray(" ")));
}

void TestClipboardHelpers::buildEntryRoutesImageDataToBlob() {
    const QByteArray           bytes("\x89PNG\x0d\x0a-pretend", 15);
    const vast::ClipboardEntry entry = vast::ClipboardContentClassifier::buildEntry(QStringLiteral("image/png"), bytes, QStringLiteral("/tmp/pic.png"), QStringLiteral("gimp"));

    QVERIFY(entry.isImage());
    QVERIFY(entry.content.isEmpty());
    QCOMPARE(entry.data, bytes);
    QCOMPARE(entry.fileName, QStringLiteral("/tmp/pic.png"));
    QCOMPARE(entry.sizeBytes, bytes.size());
    QCOMPARE(entry.sourceApp, QStringLiteral("gimp"));
}

void TestClipboardHelpers::buildEntryRoutesTextToContent() {
    const QByteArray           bytes("hello");
    const vast::ClipboardEntry entry =
        vast::ClipboardContentClassifier::buildEntry(QStringLiteral("text/plain;charset=utf-8"), bytes, QStringLiteral("/tmp/ignored.txt"), QStringLiteral("editor"));

    QVERIFY(!entry.isImage());
    QCOMPARE(entry.content, QStringLiteral("hello"));
    QVERIFY(entry.data.isEmpty());
    QVERIFY2(entry.fileName.isEmpty(), "a text entry must not keep a file name");
}

void TestClipboardHelpers::buildEntryHashesTheRightBytes() {
    const QByteArray text = "same-text";
    const auto       a    = vast::ClipboardContentClassifier::buildEntry(QStringLiteral("text/plain;charset=utf-8"), text, {}, {});
    const auto       b    = vast::ClipboardContentClassifier::buildEntry(QStringLiteral("text/plain;charset=utf-8"), text, {}, {});
    const auto       c    = vast::ClipboardContentClassifier::buildEntry(QStringLiteral("text/plain;charset=utf-8"), QByteArray("other"), {}, {});

    QCOMPARE(a.hash, b.hash);
    QVERIFY(a.hash != c.hash);
    QCOMPARE(a.hash, QCryptographicHash::hash(text, QCryptographicHash::Sha256));

    const QByteArray image("\x89PNG-image", 10);
    const auto       img = vast::ClipboardContentClassifier::buildEntry(QStringLiteral("image/png"), image, {}, {});
    QCOMPARE(img.hash, QCryptographicHash::hash(image, QCryptographicHash::Sha256));
}

void TestClipboardHelpers::buildPreviewPassesTextThrough() {
    QCOMPARE(vast::ClipboardContentClassifier::buildPreview(vast::ClipboardType::Text, QStringLiteral("plain text")), QStringLiteral("plain text"));
}

void TestClipboardHelpers::buildPreviewStripsHtmlMarkup() {
    using vast::ClipboardContentClassifier;
    using vast::ClipboardType;

    QCOMPARE(vast::ClipboardContentClassifier::buildPreview(vast::ClipboardType::Html, QStringLiteral("<p>Hello</p>")), QStringLiteral("Hello"));
    QCOMPARE(vast::ClipboardContentClassifier::buildPreview(vast::ClipboardType::Html, QStringLiteral("<script>bad()</script>ok")), QStringLiteral("ok"));
    // buildPreview collapses whitespace runs, so the <br> newline becomes a space.
    QCOMPARE(vast::ClipboardContentClassifier::buildPreview(vast::ClipboardType::Html, QStringLiteral("a<br>b")), QStringLiteral("a b"));
    // A literal non-breaking space is part of buildPreview's whitespace run.
    QCOMPARE(vast::ClipboardContentClassifier::buildPreview(vast::ClipboardType::Html,
                                                            QString::fromUtf8("a\xc2\xa0"
                                                                              "b")),
             QStringLiteral("a b"));
}

void TestClipboardHelpers::htmlToPlainTextStripsScriptAndStyle() {
    const QByteArray html = "<style>p{color:red}</style><script>x()</script>text";
    QCOMPARE(QString::fromUtf8(vast::WaylandDataControl::htmlToPlainText(html)), QStringLiteral("text"));
}

void TestClipboardHelpers::htmlToPlainTextConvertsBlockEndsToNewlines() {
    const QByteArray html = "<p>a</p><p>b</p>";
    const QString    text = QString::fromUtf8(vast::WaylandDataControl::htmlToPlainText(html));
    QVERIFY2(text.contains(QLatin1Char('\n')), qPrintable(QStringLiteral("no newline in %1").arg(text)));
    QVERIFY(text.contains(QLatin1Char('a')));
    QVERIFY(text.contains(QLatin1Char('b')));
}

void TestClipboardHelpers::htmlToPlainTextTrimsResult() {
    QCOMPARE(QString::fromUtf8(vast::WaylandDataControl::htmlToPlainText("<b>  x  </b>")), QStringLiteral("x"));
}

void TestClipboardHelpers::htmlToPlainTextHandlesEmptyInput() {
    QVERIFY(vast::WaylandDataControl::htmlToPlainText(QByteArray()).isEmpty());
}

void TestClipboardHelpers::loopbackGuardUnarmedNeverSuppresses() {
    vast::LoopbackGuard guard;
    QVERIFY(!guard.shouldSuppress(QByteArray("anything")));
}

void TestClipboardHelpers::loopbackGuardSuppressesOnceAfterArm() {
    vast::LoopbackGuard guard;
    guard.arm(QByteArray("pasted"));
    QVERIFY(guard.shouldSuppress(QByteArray("pasted")));
    // The guard clears its hash after one check, so a repeat is not suppressed.
    QVERIFY(!guard.shouldSuppress(QByteArray("pasted")));
}

void TestClipboardHelpers::loopbackGuardDoesNotSuppressDifferentContent() {
    vast::LoopbackGuard guard;
    guard.arm(QByteArray("a"));
    QVERIFY(!guard.shouldSuppress(QByteArray("b")));
}

void TestClipboardHelpers::loopbackGuardArmingReplacesPreviousHash() {
    vast::LoopbackGuard guard;
    guard.arm(QByteArray("a"));
    guard.arm(QByteArray("b"));

    // Only the most recent arm is live, and it serves exactly one check: the
    // "a" probe does not match and consumes the hash, so "b" no longer matches.
    QVERIFY(!guard.shouldSuppress(QByteArray("a")));
    QVERIFY(!guard.shouldSuppress(QByteArray("b")));

    // Arming again restores suppression for the new content.
    guard.arm(QByteArray("b"));
    QVERIFY(guard.shouldSuppress(QByteArray("b")));
}

void TestClipboardHelpers::previewCachePathFormat() {
    QVERIFY(vast::ClipboardPreviewCache::path(7).endsWith(QStringLiteral("/7.png")));
}

void TestClipboardHelpers::previewCacheExistsIsFalseBeforeWrite() {
    const qint64 id = uniqueId("previewCacheExistsIsFalseBeforeWrite");
    QVERIFY(!vast::ClipboardPreviewCache::exists(id));
}

void TestClipboardHelpers::previewCacheWriteCreatesReadablePng() {
    const qint64 id = uniqueId("previewCacheWriteCreatesReadablePng");
    vast::ClipboardPreviewCache::write(id, pngBytes(1, 1));

    QVERIFY(vast::ClipboardPreviewCache::exists(id));
    QImage loaded(vast::ClipboardPreviewCache::path(id));
    QVERIFY(!loaded.isNull());

    vast::ClipboardPreviewCache::remove(id);
}

void TestClipboardHelpers::previewCacheWriteIgnoresNonPngData() {
    const qint64 id = uniqueId("previewCacheWriteIgnoresNonPngData");
    vast::ClipboardPreviewCache::write(id, QByteArray("not a png"));
    QVERIFY(!vast::ClipboardPreviewCache::exists(id));
}

void TestClipboardHelpers::previewCacheWriteScalesLargeImagesDown() {
    const qint64 id = uniqueId("previewCacheWriteScalesLargeImagesDown");
    vast::ClipboardPreviewCache::write(id, pngBytes(800, 600));

    QVERIFY(vast::ClipboardPreviewCache::exists(id));
    QImage loaded(vast::ClipboardPreviewCache::path(id));
    QVERIFY(!loaded.isNull());
    QVERIFY2(loaded.width() <= 400 && loaded.height() <= 400,
             qPrintable(QStringLiteral("thumbnail is %1x%2, expected max dimension 400").arg(loaded.width()).arg(loaded.height())));

    vast::ClipboardPreviewCache::remove(id);
}

void TestClipboardHelpers::previewCacheWriteLeavesSmallImagesUnscaled() {
    const qint64 id = uniqueId("previewCacheWriteLeavesSmallImagesUnscaled");
    vast::ClipboardPreviewCache::write(id, pngBytes(100, 80));

    QVERIFY(vast::ClipboardPreviewCache::exists(id));
    QImage loaded(vast::ClipboardPreviewCache::path(id));
    QCOMPARE(loaded.size(), QSize(100, 80));

    vast::ClipboardPreviewCache::remove(id);
}

void TestClipboardHelpers::previewCacheRemoveDeletesTheFile() {
    const qint64 id = uniqueId("previewCacheRemoveDeletesTheFile");
    vast::ClipboardPreviewCache::write(id, pngBytes(1, 1));
    QVERIFY(vast::ClipboardPreviewCache::exists(id));

    vast::ClipboardPreviewCache::remove(id);
    QVERIFY(!vast::ClipboardPreviewCache::exists(id));
}

QTEST_MAIN(TestClipboardHelpers)
#include "tst_clipboardhelpers.moc"
