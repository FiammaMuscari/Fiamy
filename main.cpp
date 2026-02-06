#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QtQuickControls2>
#include <QProcess>
#include <QTimer>
#include <QIcon>
#include "audiocaptureanalyzer.h"
#include "youtubedownloader.h"

void updateYtDlp() {
    QString ytdlpPath = QCoreApplication::applicationDirPath() + "/yt-dlp.exe";
    QProcess::execute(ytdlpPath, QStringList() << "-U");
}

int main(int argc, char *argv[])
{
    QCoreApplication::setAttribute(Qt::AA_EnableHighDpiScaling);
    QCoreApplication::setAttribute(Qt::AA_UseOpenGLES);

    QGuiApplication app(argc, argv);
    app.setWindowIcon(QIcon(":/pink.ico"));

    // Actualizar yt-dlp al iniciar
    QTimer::singleShot(1000, []() {
        updateYtDlp();
    });

    // Estilo mínimo
    QQuickStyle::setStyle("Basic");

    qmlRegisterType<AudioCaptureAnalyzer>("Fiamy", 1, 0, "AudioCaptureAnalyzer");
    qmlRegisterType<YoutubeDownloader>("Fiamy", 1, 0, "YoutubeDownloader");

    QQmlApplicationEngine engine;
    engine.setOutputWarningsToStandardError(false);

    const QUrl url(u"qrc:/Fiamy/Main.qml"_qs);
    QObject::connect(
        &engine, &QQmlApplicationEngine::objectCreated,
        &app, [url](QObject *obj, const QUrl &objUrl) {
            if (!obj && url == objUrl)
                QCoreApplication::exit(-1);
        },
        Qt::QueuedConnection);

    engine.load(url);

    return app.exec();
}
