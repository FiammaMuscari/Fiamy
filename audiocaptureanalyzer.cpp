#include "audiocaptureanalyzer.h"

#ifndef __COSMOPOLITAN__
#define MINIAUDIO_IMPLEMENTATION
#include "miniaudio.h"
#endif

#include <QDateTime>
#include <QtMath>
#include <QDebug>
#include <QMetaObject>
#include <QMutexLocker>
#include <QThread>

#ifdef __COSMOPOLITAN__
extern "C" void qcosmoaudio_set_output_tap(
    void (*callback)(const float *samples, int frames, int channels, int sampleRate, void *userData),
    void *userData);

static QMutex s_cosmoAudioTapMutex;
static AudioCaptureAnalyzer *s_cosmoAudioAnalyzer = nullptr;

static void cosmoAudioTap(const float *samples, int frames, int channels, int sampleRate,
                          void *userData)
{
    Q_UNUSED(userData);

    QMutexLocker locker(&s_cosmoAudioTapMutex);
    auto *analyzer = s_cosmoAudioAnalyzer;
    if (!analyzer)
        return;

    analyzer->ingestFloatSamples(samples, frames, channels, sampleRate);
}
#endif

AudioCaptureAnalyzer::AudioCaptureAnalyzer(QObject *parent)
    : QObject(parent)
    , m_device(nullptr)
    , m_isRunning(false)
    , m_lastAnalysisMs(0)
    , m_analysisQueued(false)
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
    return m_isRunning.load(std::memory_order_acquire);
}

void AudioCaptureAnalyzer::start()
{
#ifdef __COSMOPOLITAN__
    if (m_isRunning.load(std::memory_order_acquire)) {
        qDebug() << "AudioCaptureAnalyzer: Ya está ejecutándose";
        return;
    }

    if (qEnvironmentVariableIsSet("FIAMY_DISABLE_AUDIO_TAP")) {
        m_isRunning.store(true, std::memory_order_release);
        qDebug() << "AudioCaptureAnalyzer: QtMultimedia/cosmoaudio tap deshabilitado por entorno";
        return;
    }

    {
        QMutexLocker locker(&s_cosmoAudioTapMutex);
        s_cosmoAudioAnalyzer = this;
        qcosmoaudio_set_output_tap(cosmoAudioTap, nullptr);
    }
    m_isRunning.store(true, std::memory_order_release);
    qDebug() << "AudioCaptureAnalyzer: Analizador conectado a QtMultimedia/cosmoaudio";
    return;
#else
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

    m_isRunning.store(true, std::memory_order_release);
    qDebug() << "AudioCaptureAnalyzer: Captura de audio iniciada (loopback)";
#endif
}

void AudioCaptureAnalyzer::stop()
{
#ifdef __COSMOPOLITAN__
    if (m_isRunning.load(std::memory_order_acquire) && !m_device) {
        QMutexLocker locker(&s_cosmoAudioTapMutex);
        if (s_cosmoAudioAnalyzer == this)
            s_cosmoAudioAnalyzer = nullptr;
        qcosmoaudio_set_output_tap(nullptr, nullptr);
        m_isRunning.store(false, std::memory_order_release);
        m_analysisQueued.store(false, std::memory_order_release);
        qDebug() << "AudioCaptureAnalyzer: Analizador QtMultimedia/cosmoaudio detenido";
        return;
    }
#endif

#ifndef __COSMOPOLITAN__
    if (m_device) {
        ma_device_uninit(m_device);
        delete m_device;
        m_device = nullptr;
        m_isRunning.store(false, std::memory_order_release);
        m_analysisQueued.store(false, std::memory_order_release);
        qDebug() << "AudioCaptureAnalyzer: Captura de audio detenida";
    }
#endif
}

void AudioCaptureAnalyzer::dataCallback(ma_device* pDevice, void* pOutput,
                                        const void* pInput, unsigned int frameCount)
{
#ifdef __COSMOPOLITAN__
    Q_UNUSED(pDevice);
    Q_UNUSED(pOutput);
    Q_UNUSED(pInput);
    Q_UNUSED(frameCount);
#else
    Q_UNUSED(pOutput);

    auto* analyzer = static_cast<AudioCaptureAnalyzer*>(pDevice->pUserData);
    if (!analyzer || !pInput || frameCount == 0) return;

    const float* samples = static_cast<const float*>(pInput);
    analyzer->calculateFFT(samples, int(frameCount), 2);
#endif
}

void AudioCaptureAnalyzer::ingestFloatSamples(const float *samples, int frames, int channels,
                                              int sampleRate)
{
    Q_UNUSED(sampleRate);

    if (!samples || frames <= 0 || channels <= 0 || !m_isRunning.load(std::memory_order_acquire))
        return;

    const qint64 now = QDateTime::currentMSecsSinceEpoch();
    const qint64 last = m_lastAnalysisMs.load(std::memory_order_relaxed);
    if (now - last < 33)
        return;

    m_lastAnalysisMs.store(now, std::memory_order_relaxed);
    if (m_analysisQueued.exchange(true, std::memory_order_acq_rel))
        return;

    const int safeChannels = qMax(1, channels);
    const int frameCount = qMin(frames, FFT_SIZE);
    QVector<float> monoSamples;
    monoSamples.reserve(frameCount);

    for (int frame = 0; frame < frameCount; ++frame) {
        float mixed = 0.0f;
        const int base = frame * safeChannels;
        for (int channel = 0; channel < safeChannels; ++channel)
            mixed += samples[base + channel];
        monoSamples.append(mixed / safeChannels);
    }

    if (monoSamples.size() < 64) {
        m_analysisQueued.store(false, std::memory_order_release);
        return;
    }

    QMetaObject::invokeMethod(this, [this, monoSamples = std::move(monoSamples)]() {
        m_analysisQueued.store(false, std::memory_order_release);
        if (!m_isRunning.load(std::memory_order_acquire))
            return;
        calculateFFT(monoSamples.constData(), monoSamples.size(), 1);
    }, Qt::QueuedConnection);
}

void AudioCaptureAnalyzer::calculateFFT(const float *samples, int frames, int channels)
{
    // Convertir estéreo a mono y limitar a FFT_SIZE
    QList<float> monoSamples;
    monoSamples.reserve(FFT_SIZE);

    const int safeChannels = qMax(1, channels);
    for (int frame = 0; frame < frames && monoSamples.size() < FFT_SIZE; ++frame) {
        float mixed = 0.0f;
        const int base = frame * safeChannels;
        for (int channel = 0; channel < safeChannels; ++channel)
            mixed += samples[base + channel];
        monoSamples.append(mixed / safeChannels);
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

    notifySpectrumChanged();
}

void AudioCaptureAnalyzer::notifySpectrumChanged()
{
    if (QThread::currentThread() == thread()) {
        emit spectrumChanged();
        return;
    }

    QMetaObject::invokeMethod(this, [this]() {
        emit spectrumChanged();
    }, Qt::QueuedConnection);
}

float AudioCaptureAnalyzer::hammingWindow(int n, int N)
{
    return 0.54f - 0.46f * qCos(2.0f * M_PI * n / (N - 1));
}
