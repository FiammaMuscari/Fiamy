#ifndef AUDIOCAPTUREANALYZER_H
#define AUDIOCAPTUREANALYZER_H

#include <QObject>
#include <QList>
#include <QMutex>
#include <QPointer>
#include <QVariant>
#include <QAudioBuffer>
#include <atomic>

#ifdef Q_OS_WIN
typedef struct ma_device ma_device;
#endif

class QMediaPlayer;
class QAudioBufferOutput;

class AudioCaptureAnalyzer : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QVariantList spectrum READ spectrum NOTIFY spectrumChanged)

public:
    explicit AudioCaptureAnalyzer(QObject *parent = nullptr);
    ~AudioCaptureAnalyzer();

    QVariantList spectrum() const;

    Q_INVOKABLE void start();
    Q_INVOKABLE void stop();
    Q_INVOKABLE bool isRunning() const;
    Q_INVOKABLE void attachToPlayer(QObject *playerObject);

signals:
    void spectrumChanged();

private:
    void resetSpectrum(float value = 0.0f);
    void calculateFFT(const float* samples, int count);
    float hammingWindow(int n, int N);
    void setupPlayerTap();
    void detachPlayerTap();

private slots:
    void handleAudioBuffer(const QAudioBuffer &buffer);

private:
#ifdef Q_OS_WIN
    static void dataCallback(ma_device* pDevice, void* pOutput,
                             const void* pInput, unsigned int frameCount);
    ma_device* m_device;
#endif
    QPointer<QMediaPlayer> m_player;
    QAudioBufferOutput* m_audioBufferOutput;
    QVariantList m_spectrum;
    mutable QMutex m_mutex;
    bool m_isRunning;
    std::atomic<qint64> m_lastEmitMs;

    static const int SPECTRUM_SIZE = 16;
    static const int FFT_SIZE = 512;
};

#endif // AUDIOCAPTUREANALYZER_H
