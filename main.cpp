#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QtQuickControls2>
#include <QProcess>
#include <QTimer>
#include <QIcon>
#include <QQuickWindow>
#include "audiocaptureanalyzer.h"
#include "youtubedownloader.h"

#ifdef QT_QML_DEBUG
#include <QFileSystemWatcher>
#include <QDir>
#include <QDebug>
#endif

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

#ifdef QT_QML_DEBUG
    // 🔥 HOT RELOAD COMPLETO CON RECARGA AUTOMÁTICA
    qDebug() << "====================================";
    qDebug() << "🔥 HOT RELOAD ACTIVADO";
    qDebug() << "====================================";

    QFileSystemWatcher *watcher = new QFileSystemWatcher(&app);

    // Directorio donde están los QML
    QString qmlDir = QCoreApplication::applicationDirPath();
    QString componentsDir = qmlDir + "/components";

    qDebug() << "📁 Directorio QML:" << qmlDir;
    qDebug() << "📁 Directorio components:" << componentsDir;

    // Observar directorios
    watcher->addPath(qmlDir);
    if (QDir(componentsDir).exists()) {
        watcher->addPath(componentsDir);
    }

    // Lista de archivos QML a observar
    QStringList qmlFiles = {
        "Main.qml",
        "components/QueueDrawer.qml",
        "components/PlayerCard.qml",
        "components/ActionButtons.qml",
        "components/AudioVisualizer.qml",
        "components/BookmarkPlayer.qml",
        "components/PlayerControls.qml",
        "components/ProgressBar.qml",
        "components/SongInfo.qml",
        "components/VisualizerBar.qml",
        "components/VisualizerBars.qml",
        "components/VolumeControl.qml",
        "components/YoutubeQueueInput.qml"
    };

    // Agregar cada archivo al watcher
    for (const QString &file : qmlFiles) {
        QString fullPath = qmlDir + "/" + file;
        if (QFile::exists(fullPath)) {
            watcher->addPath(fullPath);
            qDebug() << "👀" << file;
        }
    }

    qDebug() << "";
    qDebug() << "✅ Hot reload listo - guarda un QML para ver cambios";
    qDebug() << "====================================";
    qDebug() << "";

    // Variable para evitar recargas múltiples
    QTimer *reloadTimer = new QTimer(&app);
    reloadTimer->setSingleShot(true);
    reloadTimer->setInterval(300); // Esperar 300ms después del último cambio

    QObject::connect(reloadTimer, &QTimer::timeout, [&engine, qmlDir]() {
        qDebug() << "";
        qDebug() << "♻️  RECARGANDO APLICACIÓN...";

        // Limpiar caché
        engine.clearComponentCache();
        engine.trimComponentCache();

        // Obtener la ventana actual
        auto rootObjects = engine.rootObjects();
        QQuickWindow *oldWindow = nullptr;

        if (!rootObjects.isEmpty()) {
            oldWindow = qobject_cast<QQuickWindow*>(rootObjects.first());
        }

        // Guardar posición y estado de la ventana
        QPoint windowPos;
        QSize windowSize;
        bool wasVisible = false;

        if (oldWindow) {
            windowPos = oldWindow->position();
            windowSize = oldWindow->size();
            wasVisible = oldWindow->isVisible();
        }

        // Eliminar objetos antiguos
        for (auto obj : rootObjects) {
            if (obj) {
                obj->deleteLater();
            }
        }

        // Cargar Main.qml desde archivo
        QString mainQmlPath = qmlDir + "/Main.qml";
        QUrl url = QUrl::fromLocalFile(mainQmlPath);

        // Recargar
        engine.load(url);

        // Restaurar posición de ventana
        QTimer::singleShot(50, [&engine, windowPos, windowSize, wasVisible]() {
            auto newRootObjects = engine.rootObjects();
            if (!newRootObjects.isEmpty()) {
                QQuickWindow *newWindow = qobject_cast<QQuickWindow*>(newRootObjects.first());
                if (newWindow) {
                    if (windowSize.isValid()) {
                        newWindow->setPosition(windowPos);
                        newWindow->resize(windowSize);
                    }
                    if (wasVisible) {
                        newWindow->show();
                    }
                }
            }
        });

        qDebug() << "✨ Recarga completada";
        qDebug() << "";
    });

    // Conectar cambios de archivos
    QObject::connect(watcher, &QFileSystemWatcher::fileChanged,
                     [watcher, reloadTimer](const QString &path) {

                         qDebug() << "🔄" << QFileInfo(path).fileName() << "modificado";

                         // Re-agregar el archivo al watcher (se remueve automáticamente)
                         QTimer::singleShot(100, [watcher, path]() {
                             if (!watcher->files().contains(path)) {
                                 watcher->addPath(path);
                             }
                         });

                         // Reiniciar el timer (esperar a que terminen todos los cambios)
                         reloadTimer->start();
                     });

    // Cargar desde archivo en Debug
    QString mainQmlPath = qmlDir + "/Main.qml";
    const QUrl url = QUrl::fromLocalFile(mainQmlPath);
    qDebug() << "🔗 Cargando desde:" << mainQmlPath;

#else
    // En Release, cargar desde recursos
    const QUrl url(u"qrc:/Fiamy/Main.qml"_qs);
#endif

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
