#define MINIAUDIO_IMPLEMENTATION
#include "miniaudio.h"
#include "audiocaptureanalyzer.h"
#include <QtMath>
#include <QDebug>

AudioCaptureAnalyzer::AudioCaptureAnalyzer(QObject *parent)
    : QObject(parent)
    , m_device(nullptr)
    , m_isRunning(false)
{
    // Inicializar spectrum
    for (int i = 0; i < SPECTRUM_SIZE; ++i) {
        m_spectrum.append(0.15);
    }
}

AudioCaptureAnalyzer::~AudioCaptureAnalyzer()
{
    stop();
}

QVariantList AudioCaptureAnalyzer::spectrum() const
{
    QMutexLocker locker(&m_mutex);
    return m_spectrum;
}

bool AudioCaptureAnalyzer::isRunning() const
{
    return m_isRunning;
}

void AudioCaptureAnalyzer::start()
{
    if (m_device) {
        qDebug() << "AudioCaptureAnalyzer: Ya está ejecutándose";
        return;
    }

    m_device = new ma_device;

    ma_device_config config = ma_device_config_init(ma_device_type_loopback);
    config.capture.format   = ma_format_f32;
    config.capture.channels = 2;
    config.sampleRate       = 44100;
    config.dataCallback     = dataCallback;
    config.pUserData        = this;

    if (ma_device_init(nullptr, &config, m_device) != MA_SUCCESS) {
        qWarning() << "AudioCaptureAnalyzer: Error al inicializar dispositivo de audio";
        delete m_device;
        m_device = nullptr;
        return;
    }

    if (ma_device_start(m_device) != MA_SUCCESS) {
        qWarning() << "AudioCaptureAnalyzer: Error al iniciar dispositivo de audio";
        ma_device_uninit(m_device);
        delete m_device;
        m_device = nullptr;
        return;
    }

    m_isRunning = true;
    qDebug() << "AudioCaptureAnalyzer: Captura de audio iniciada (loopback)";
}

void AudioCaptureAnalyzer::stop()
{
    if (m_device) {
        ma_device_uninit(m_device);
        delete m_device;
        m_device = nullptr;
        m_isRunning = false;
        qDebug() << "AudioCaptureAnalyzer: Captura de audio detenida";
    }
}

void AudioCaptureAnalyzer::dataCallback(ma_device* pDevice, void* pOutput,
                                        const void* pInput, unsigned int frameCount)
{
    Q_UNUSED(pOutput);

    auto* analyzer = static_cast<AudioCaptureAnalyzer*>(pDevice->pUserData);
    if (!analyzer || !pInput || frameCount == 0) return;

    const float* samples = static_cast<const float*>(pInput);
    analyzer->calculateFFT(samples, frameCount * 2); // *2 por estéreo
}

void AudioCaptureAnalyzer::calculateFFT(const float* samples, int count)
{
    // Convertir estéreo a mono y limitar a FFT_SIZE
    QList<float> monoSamples;
    monoSamples.reserve(FFT_SIZE);

    for (int i = 0; i < count - 1 && monoSamples.size() < FFT_SIZE; i += 2) {
        monoSamples.append((samples[i] + samples[i + 1]) * 0.5f);
    }

    if (monoSamples.size() < 64) return; // Muy pocas muestras

    const int N = monoSamples.size();
    QList<float> magnitudes;
    magnitudes.reserve(N / 2);

    // DFT simple (solo calculamos la mitad - frecuencias positivas)
    for (int k = 0; k < N / 2; ++k) {
        float real = 0.0f;
        float imag = 0.0f;

        for (int n = 0; n < N; ++n) {
            float window = hammingWindow(n, N);
            float angle = -2.0f * M_PI * k * n / N;
            real += monoSamples[n] * window * qCos(angle);
            imag += monoSamples[n] * window * qSin(angle);
        }

        float magnitude = qSqrt(real * real + imag * imag) / N;
        magnitudes.append(magnitude);
    }

    if (magnitudes.isEmpty()) return;

    // Agrupar frecuencias en SPECTRUM_SIZE bandas
    QVariantList newSpectrum;
    const int bandsPerBar = qMax(1, magnitudes.size() / SPECTRUM_SIZE);

    for (int i = 0; i < SPECTRUM_SIZE; ++i) {
        float sum = 0.0f;
        int count = 0;

        for (int j = 0; j < bandsPerBar; ++j) {
            int idx = i * bandsPerBar + j;
            if (idx < magnitudes.size()) {
                sum += magnitudes[idx];
                count++;
            }
        }

        float avg = count > 0 ? sum / count : 0.0f;

        // Normalizar y escalar para visualización
        avg = qBound(0.0f, avg * 50.0f, 1.0f);

        // Aplicar escala logarítmica para mejor visualización
        avg = qPow(avg, 0.6f);

        // Valor mínimo para que siempre se vea algo
        avg = qMax(0.15f, avg);

        newSpectrum.append(avg);
    }

    // Actualizar spectrum de forma thread-safe
    QMutexLocker locker(&m_mutex);
    m_spectrum = newSpectrum;
    locker.unlock();

    emit spectrumChanged();
}

float AudioCaptureAnalyzer::hammingWindow(int n, int N)
{
    return 0.54f - 0.46f * qCos(2.0f * M_PI * n / (N - 1));
}
