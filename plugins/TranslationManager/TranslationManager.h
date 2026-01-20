#ifndef TRANSLATIONMANAGER_H
#define TRANSLATIONMANAGER_H

#include <QObject>
#include <QTranslator>
#include <QGuiApplication>
#include <QQmlEngine>

class TranslationManager : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString currentLanguage READ currentLanguage WRITE setCurrentLanguage NOTIFY languageChanged);
    QML_ELEMENT
    QML_SINGLETON;

public:
    explicit TranslationManager(QObject *parent = nullptr);
    ~TranslationManager();

    QString currentLanguage() const;
    void setCurrentLanguage(const QString &language);

    Q_INVOKABLE bool loadTranslation(const QString &language, const QString &translationPath = ":/translations");
    Q_INVOKABLE QStringList availableLanguages() const;

signals:
    void languageChanged();

private:
    QTranslator *m_translator;
    QString m_currentLanguage;
    QStringList m_availableLanguages;
};

#endif // TRANSLATIONMANAGER_H
