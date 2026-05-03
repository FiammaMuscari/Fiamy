#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QtQuickControls2>
#include <QProcess>
#include <QTimer>
#include <QIcon>
#include <QImage>
#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QFont>
#include <QFontDatabase>
#include <QQuickWindow>
#include "audiocaptureanalyzer.h"
#include "youtubedownloader.h"

#ifdef __COSMOPOLITAN__
#include <QApplication>
using FiamyApplication = QApplication;
extern "C" {
#include <libc/dce.h>
}
#else
#include <QGuiApplication>
using FiamyApplication = QGuiApplication;
#endif

#ifdef QT_QML_DEBUG
#include <QFileSystemWatcher>
#include <QDir>
#include <QDebug>
#endif

#ifdef __COSMOPOLITAN__
static bool directoryHasUsableFonts(const QString &path)
{
    QDir dir(path);
    return dir.exists()
        && !dir.entryList({ "*.ttf", "*.ttc", "*.otf", "*.dfont", "*.pfa", "*.pfb" },
                          QDir::Files).isEmpty();
}

static void configureCosmopolitanFontDir()
{
    if (!qEnvironmentVariableIsEmpty("QT_QPA_FONTDIR"))
        return;

    const QStringList fontDirs = {
        "/System/Library/Fonts/Supplemental",
        "/System/Library/Fonts",
        "/Library/Fonts",
        "/usr/share/fonts/truetype/dejavu",
        "/usr/share/fonts/truetype/liberation2",
        "/usr/share/fonts/liberation",
        "/usr/share/fonts/TTF",
        "/usr/share/fonts",
        "C:/Windows/Fonts",
    };

    for (const QString &fontDir : fontDirs) {
        if (directoryHasUsableFonts(fontDir)) {
            qputenv("QT_QPA_FONTDIR", QFile::encodeName(fontDir));
            return;
        }
    }
}

static void configureCosmopolitanPlatform()
{
    if (qEnvironmentVariableIsEmpty("QT_QPA_PLATFORM"))
        qputenv("QT_QPA_PLATFORM", "cosmonative:size=420x720");
}

static void configureCosmopolitanApplicationFont()
{
    const QStringList preferredFamilies = {
        "Arial",
        "Helvetica",
        "SF Pro Text",
        "DejaVu Sans",
        "Liberation Sans",
        "Noto Sans",
        "Segoe UI",
    };

    const QStringList families = QFontDatabase::families();
    for (const QString &family : preferredFamilies) {
        if (families.contains(family, Qt::CaseInsensitive)) {
            QGuiApplication::setFont(QFont(family, 10));
            return;
        }
    }

    if (!families.isEmpty())
        QGuiApplication::setFont(QFont(families.first(), 10));
}

static void scheduleCosmopolitanScreenshot(QQmlApplicationEngine &engine, QObject *parent)
{
    const QByteArray screenshotPath = qgetenv("FIAMY_SCREENSHOT_PATH");
    if (screenshotPath.isEmpty())
        return;

    bool ok = false;
    int delayMs = qEnvironmentVariableIntValue("FIAMY_SCREENSHOT_DELAY_MS", &ok);
    if (!ok || delayMs < 0)
        delayMs = 1500;

    const QString path = QString::fromLocal8Bit(screenshotPath);
    QTimer::singleShot(delayMs, parent, [&engine, path]() {
        for (QObject *rootObject : engine.rootObjects()) {
            auto *window = qobject_cast<QQuickWindow *>(rootObject);
            if (!window)
                continue;

            window->requestUpdate();
            const QImage image = window->grabWindow();
            if (image.isNull()) {
                qWarning().noquote() << "Fiamy screenshot failed:" << path;
            } else {
                QDir().mkpath(QFileInfo(path).absolutePath());
                if (image.save(path))
                    qInfo().noquote() << "Fiamy screenshot saved:" << path;
                else
                    qWarning().noquote() << "Fiamy screenshot save failed:" << path;
            }

            if (!qEnvironmentVariableIsEmpty("FIAMY_SCREENSHOT_QUIT_AFTER"))
                QCoreApplication::quit();
            return;
        }

        qWarning().noquote() << "Fiamy screenshot failed: no QQuickWindow";
        if (!qEnvironmentVariableIsEmpty("FIAMY_SCREENSHOT_QUIT_AFTER"))
            QCoreApplication::quit();
    });
}
#endif

int main(int argc, char *argv[])
{
    QCoreApplication::setAttribute(Qt::AA_EnableHighDpiScaling);
#ifdef __COSMOPOLITAN__
    QQuickWindow::setGraphicsApi(QSGRendererInterface::Software);
#else
    QCoreApplication::setAttribute(Qt::AA_UseOpenGLES);
#endif
#ifdef __COSMOPOLITAN__
    configureCosmopolitanPlatform();
    configureCosmopolitanFontDir();
#endif
    FiamyApplication app(argc, argv);
    app.setWindowIcon(QIcon(":/pink.ico"));
#ifdef __COSMOPOLITAN__
    qInfo().noquote() << "Fiamy QPA platform:" << QGuiApplication::platformName();
    configureCosmopolitanApplicationFont();
#endif

    // Estilo mínimo
    QQuickStyle::setStyle("Basic");

    qmlRegisterType<AudioCaptureAnalyzer>("Fiamy", 1, 0, "AudioCaptureAnalyzer");
    qmlRegisterType<YoutubeDownloader>("Fiamy", 1, 0, "YoutubeDownloader");

    QQmlApplicationEngine engine;
#ifdef __COSMOPOLITAN__
    engine.setOutputWarningsToStandardError(true);
    engine.rootContext()->setContextProperty(
            "fiamyAutoSubmitUrl", QString::fromLocal8Bit(qgetenv("FIAMY_AUTO_SUBMIT_URL")));
    engine.rootContext()->setContextProperty(
            "fiamyDisableAutoplay", qEnvironmentVariableIsSet("FIAMY_DISABLE_AUTOPLAY"));
#else
    engine.setOutputWarningsToStandardError(false);
#endif

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
#ifdef __COSMOPOLITAN__
    for (QObject *rootObject : engine.rootObjects()) {
        if (auto *window = qobject_cast<QWindow *>(rootObject)) {
            window->create();
            QTimer::singleShot(0, window, [window]() {
                window->requestActivate();
                window->requestUpdate();
            });
        }
    }
    scheduleCosmopolitanScreenshot(engine, &app);
#endif

    return app.exec();
}
