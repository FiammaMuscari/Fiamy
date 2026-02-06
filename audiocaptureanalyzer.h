#ifndef AUDIOCAPTUREANALYZER_H
#define AUDIOCAPTUREANALYZER_H

#include <QObject>
#include <QTimer>
#include <QList>
#include <QMutex>
#include <QVariant>


// Forward declaration
typedef struct ma_device ma_device;

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

signals:
    void spectrumChanged();

private:
    void calculateFFT(const float* samples, int count);
    float hammingWindow(int n, int N);

    static void dataCallback(ma_device* pDevice, void* pOutput,
                             const void* pInput, unsigned int frameCount);

    ma_device* m_device;
    QVariantList m_spectrum;
    mutable QMutex m_mutex;
    bool m_isRunning;

    static const int SPECTRUM_SIZE = 16;
    static const int FFT_SIZE = 1024;
};

#endif // AUDIOCAPTUREANALYZER_H
