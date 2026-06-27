import os
import sys
import pyaudio
import numpy as np
import openwakeword
from openwakeword.model import Model

# Загружаем штатную модель Джарвиса
try:
    oww_model = Model(wakeword_models=["hey_jarvis_v0.1"], inference_framework="onnx")
except Exception as e:
    print(f"❌ Ошибка инициализации модели: {e}")
    sys.exit(1)

FORMAT = pyaudio.paInt16
CHANNELS = 1
RATE = 16000
CHUNK = 1280

audio = pyaudio.PyAudio()
stream = audio.open(format=FORMAT, channels=CHANNELS, rate=RATE, 
                    input=True, frames_per_buffer=CHUNK)

print("[ Ready - Скажи громко и четко 'Hey Jarvis'... ]")

while True:
    try:
        data = stream.read(CHUNK, exception_on_overflow=False)
        audio_frame = np.frombuffer(data, dtype=np.int16)
        
        # Передаем аудиопоток в модель
        prediction = oww_model.predict(audio_frame)
        
        # Проверяем уверенность распознавания по ключу модели
        if oww_model.prediction_buffer['hey_jarvis_v0.1'][-1] > 0.5:
            print("\n🔥 TRIGGERED! Wake word detected successfully!")
            sys.exit(0)
                
    except KeyboardInterrupt:
        print("\nExiting listener...")
        sys.exit(1)
