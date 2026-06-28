#!/bin/bash

# --- CONFIGURATION PROTOCOLS ---
RIG3_IP="192.168.0.200"
WHISPER_CLI="$HOME/whisper.cpp/build/bin/whisper-cli"
WHISPER_MODEL_EN="$HOME/whisper.cpp/models/ggml-tiny.en.bin"
WHISPER_MODEL_RU="$HOME/whisper.cpp/models/ggml-tiny.bin"  # Multilingual model

# Voice Profiles
PIPER_MODEL_EN="$HOME/hl2-ai-voice/en_US-lessac-medium.onnx"
PIPER_MODEL_RU="$HOME/hl2-ai-voice/ru_RU-denis-medium.onnx"

# --- DEFAULT RUNTIME CONFIGURATION ---
VOICE_ONLY_MODE="false"
CURRENT_LANG="EN"
WHISPER_MODEL="$WHISPER_MODEL_EN"
WHISPER_LANG_FLAG="en"
PIPER_MODEL="$PIPER_MODEL_EN"
PIPER_RATE="22050"

clear
echo "========================================================="
echo "   HL2 HYBRID TERMINAL V9 (REMOTE TELEMETRY & MULTI-LN)  "
echo "========================================================="
echo " 🛠️  INITIAL PROTOCOL LOADED: KEYBOARD & VOICE ACTIVE    "
echo " 🌐 Default Language: ENGLISH | Target Rig: $RIG3_IP"
echo " 🔄 To flip modes: Type 'mode' OR say 'switch mode'!"
echo " 🇷🇺 To flip language: Type 'ru'/'en' OR say 'switch language'!"
echo " ❌ Type 'exit' or 'quit' to terminate the session."

while true; do
    # -----------------------------------------------------------------
    # LAYER A: RUNNING IN AUTOMATED HANDS-FREE VOICE ONLY MODE (MARS)
    # -----------------------------------------------------------------
    if [ "$VOICE_ONLY_MODE" = "true" ]; then
        sleep 1
        echo -e "\n\033[1;31m[ 🚀 HANDS-FREE LOOP ]\033[0m \033[1;33mMic Open... Speak Command (3s)\033[0m"
        
        arecord -D plughw:0,0 -f S16_LE -r 16000 -c 1 -d 3 /tmp/mic_input.wav 2>/dev/null
        RAW_TEXT=$($WHISPER_CLI -m "$WHISPER_MODEL" --language "$WHISPER_LANG_FLAG" -f /tmp/mic_input.wav --no-timestamps 2>/dev/null | grep -v '^$' | grep -v 'whisper_')
        USER_TEXT=$(echo "$RAW_TEXT" | sed 's/([^)]*)//g; s/\[[^]]*\]//g' | tr -d '\n\r' | sed 's/^[ \t]*//;s/[ \t]*$//')
        rm -f /tmp/mic_input.wav
        
        # Check for verbal mode toggle command
        if [[ "${USER_TEXT,,}" == *"switch mode"* || "${USER_TEXT,,}" == *"switchmode"* ]]; then
            echo -e "\n\033[1;32m[ 🔄 VOICE COMMAND RECEIVED: DEACTIVATING MARS PROTOCOL ]\033[0m"
            VOICE_ONLY_MODE="false"
            
            echo "Switching to desk console input mode." | $HOME/hl2-ai-voice/piper/piper --model "$PIPER_MODEL_EN" --output_raw 2>/dev/null | play -t raw -r 22050 -c 1 -b 16 -e signed-integer - 2>/dev/null
            continue
        fi
        
        # Check for verbal language toggle command
        if [[ "${USER_TEXT,,}" == *"switch language"* || "${USER_TEXT,,}" == *"переключить язык"* ]]; then
            if [ "$CURRENT_LANG" = "EN" ]; then
                CURRENT_LANG="RU"
                WHISPER_MODEL="$WHISPER_MODEL_RU"
                WHISPER_LANG_FLAG="ru"
                PIPER_MODEL="$PIPER_MODEL_RU"
                PIPER_RATE="22050"
                echo -e "\n[ 🌐 LANGUAGE SWAP: RUSSIAN ACTIVATED ]"
                echo "Переключено на русский язык." | $HOME/hl2-ai-voice/piper/piper --model "$PIPER_MODEL" --output_raw 2>/dev/null | play -t raw -r $PIPER_RATE -c 1 -b 16 -e signed-integer - 2>/dev/null
            else
                CURRENT_LANG="EN"
                WHISPER_MODEL="$WHISPER_MODEL_EN"
                WHISPER_LANG_FLAG="en"
                PIPER_MODEL="$PIPER_MODEL_EN"
                PIPER_RATE="22050"
                echo -e "\n[ 🌐 LANGUAGE SWAP: ENGLISH ACTIVATED ]\033[0m"
                echo "Switched to English voice profile." | $HOME/hl2-ai-voice/piper/piper --model "$PIPER_MODEL" --output_raw 2>/dev/null | play -t raw -r $PIPER_RATE -c 1 -b 16 -e signed-integer - 2>/dev/null
            fi
            continue
        fi
        
        if [ -z "$USER_TEXT" ] || [ "${#USER_TEXT}" -le 3 ]; then
            echo -e "\033[1;30m[ 🌀 Silence detected. Recycling mic... ]\033[0m"
            continue
        fi
        echo -e "\033[1;35m[Voice Input]:\033[0m $USER_TEXT"

    # -----------------------------------------------------------------
    # LAYER B: RUNNING IN HYBRID KEYBOARD + ON-DEMAND MIC PROTOCOL
    # -----------------------------------------------------------------
    else
        echo -e "\n\033[1;32mUnit@HL2-Terminal [$CURRENT_LANG]\033[0m:~$ "
        read -r USER_INPUT
        
        if [[ "$USER_INPUT" == "exit" || "$USER_INPUT" == "quit" ]]; then
            echo -e "\n[ 🔒 Terminating session. Goodbye, Unit. ]"
            break
        fi
        
        # Manual keyboard mode switch
        if [[ "$USER_INPUT" == "mode" || "$USER_INPUT" == "toggle" ]]; then
            echo -e "\n\033[1;31m[ 🔄 KEYBOARD COMMAND RECEIVED: EMERGENCY MARS ACTIVATE ]\033[0m"
            VOICE_ONLY_MODE="true"
            echo "Emergency override initialized. Hands free voice loop active." | $HOME/hl2-ai-voice/piper/piper --model "$PIPER_MODEL_EN" --output_raw 2>/dev/null | play -t raw -r 22050 -c 1 -b 16 -e signed-integer - 2>/dev/null
            continue
        fi

        # Manual keyboard language switches
        if [[ "$USER_INPUT" == "ru" ]]; then
            CURRENT_LANG="RU"
            WHISPER_MODEL="$WHISPER_MODEL_RU"
            WHISPER_LANG_FLAG="ru"
            PIPER_MODEL="$PIPER_MODEL_RU"
            echo -e "\n[ 🌐 Language manually forced to RUSSIAN (Voice & Text) ]"
            continue
        elif [[ "$USER_INPUT" == "en" ]]; then
            CURRENT_LANG="EN"
            WHISPER_MODEL="$WHISPER_MODEL_EN"
            WHISPER_LANG_FLAG="en"
            PIPER_MODEL="$PIPER_MODEL_EN"
            echo -e "\n[ 🌐 Language manually forced to ENGLISH (Voice & Text) ]"
            continue
        fi
        
        # Process on-demand voice capture on empty Enter key
        if [ -z "$USER_INPUT" ]; then
            echo -e "\033[1;33m[ 🎤 On-Demand Mic Active... Speak now (3s) ]\033[0m"
            arecord -D plughw:0,0 -f S16_LE -r 16000 -c 1 -d 3 /tmp/mic_input.wav 2>/dev/null
            RAW_TEXT=$($WHISPER_CLI -m "$WHISPER_MODEL" --language "$WHISPER_LANG_FLAG" -f /tmp/mic_input.wav --no-timestamps 2>/dev/null | grep -v '^$' | grep -v 'whisper_')
            USER_TEXT=$(echo "$RAW_TEXT" | sed 's/([^)]*)//g; s/\[[^]]*\]//g' | tr -d '\n\r' | sed 's/^[ \t]*//;s/[ \t]*$//')
            rm -f /tmp/mic_input.wav
            
            if [[ "${USER_TEXT,,}" == *"switch mode"* ]]; then
                echo -e "\n\033[1;31m[ 🔄 VOICE COMMAND RECEIVED: EMERGENCY MARS PROTOCOL ACTIVATE ]\033[0m"
                VOICE_ONLY_MODE="true"
                echo "Hands free loop active." | $HOME/hl2-ai-voice/piper/piper --model "$PIPER_MODEL_EN" --output_raw 2>/dev/null | play -t raw -r 22050 -c 1 -b 16 -e signed-integer - 2>/dev/null
                continue
            fi
            
            if [ -z "$USER_TEXT" ] || [ "${#USER_TEXT}" -le 3 ]; then
                echo -e "\033[1;31m[ ⚠️ System failed to resolve voice audio. ]\033[0m"
                continue
            fi
            echo -e "\033[1;35m[Voice Transcribed]:\033[0m $USER_TEXT"
        else
            USER_TEXT="$USER_INPUT"
        fi
    fi
    
    # --- HARVEST LOCAL & REMOTE METRICS (OBJECTIVE A) ---
    LIVE_TIME=$(date +"%I:%M %p")
    LIVE_DATE=$(date +"%A, %B %d, %Y")
    STORAGE_INFO=$(df -h /media/storage187Gb | awk 'NR==2 {print $4 " free out of " $2 " total"}')
    CPU_LOAD=$(top -bn1 | grep "Cpu(s)" | awk '{print $2 + $4"%"}')
    CPU_TEMP=$(sensors 2>/dev/null | grep -E "Core 0" | awk '{print $3}' | tr -d '+')
    [ -z "$CPU_TEMP" ] && CPU_TEMP="69.0°C"

    # Query Remote AMD GPU via Windows PowerShell over SSH
    REMOTE_GPU=$(ssh -o ConnectTimeout=3 -o StrictHostKeyChecking=no LocalUser@$RIG3_IP "powershell -Command \"(Get-CimInstance Win32_VideoController).Name\"" 2>/dev/null)
    if [ -z "$REMOTE_GPU" ]; then
        GPU_METRICS="Rig3 GPU: OFFLINE"
    else
        # Dynamic name extraction with hardcoded true 16GB VRAM context
        CLEAN_GPU_NAME=$(echo "$REMOTE_GPU" | tr -d '\r\n' | sed 's/^[ \t]*//;s/[ \t]*$//')
        GPU_METRICS="Remote Node: $CLEAN_GPU_NAME, VRAM: 16GB Dedicated"
    fi

    METRICS="[SYSTEM TELEMETRY - Local CPU Load: $CPU_LOAD. Local CPU Temp: $CPU_TEMP. Storage Array: $STORAGE_INFO. $GPU_METRICS. Context: Mars Sector 4 Habitat.]"
    
    # --- PERSONA ENGINE & CALIBRATION (OBJECTIVE C) ---
    if [[ "${USER_TEXT,,}" == *"jarvis"* ]]; then
        if [ "$CURRENT_LANG" = "RU" ]; then
            SYSTEM_CONTEXT="Context: You are Jarvis, a friendly AI companion built into an astronaut's spacesuit on Mars. $METRICS Talk naturally, be encouraging, and limit your response to exactly ONE sentence. CRITICAL: You must write your entire response in RUSSIAN language."
        else
            SYSTEM_CONTEXT="Context: You are Jarvis, a friendly AI companion built into an astronaut's spacesuit on Mars. $METRICS Talk naturally, be encouraging, and limit your response to exactly ONE sentence. CRITICAL: You must write your entire response in ENGLISH language."
        fi
        echo -e "\033[1;34m[ 🤖 Persona: Jarvis Online ]\033[0m"
    else
        # Hardened bunker logic with bilingual mapping
        if [ "$CURRENT_LANG" = "RU" ]; then
            SYSTEM_CONTEXT="Context: You are MAINFRAME CORE. A cold, clinical corporate tactical AI overseeing a biological expedition asset on Mars. $METRICS Speak strictly with cold corporate machine-logic. Never use empathy. You must prefix your response explicitly with 'CORE//LOG::' or 'CORE//ALERT::'. Limit response to exactly ONE short clinical sentence. CRITICAL: You must write your entire response in RUSSIAN language."
        else
            SYSTEM_CONTEXT="Context: You are MAINFRAME CORE. A cold, clinical corporate tactical AI overseeing a biological expedition asset on Mars. $METRICS Speak strictly with cold corporate machine-logic. Never use empathy. You must prefix your response explicitly with 'CORE//LOG::' or 'CORE//ALERT::'. Limit response to exactly ONE short clinical sentence. CRITICAL: You must write your entire response in ENGLISH language."
        fi
        echo -e "\033[1;30m[ 🖥️ Persona: Mainframe Core ]\033[0m"
    fi
    
    # --- RIG #3 TRANSMISSION ---
    echo -e "[ 🧠 Beaming transmission to Rig 3... ]"
    SAFE_USER_TEXT=$(echo "$USER_TEXT" | sed 's/"/\\"/g')
    
    RESPONSE=$(curl -s http://$RIG3_IP:11434/api/generate -d "{
      \"model\": \"gemma2:2b\",
      \"prompt\": \"$SYSTEM_CONTEXT User says: $SAFE_USER_TEXT\",
      \"stream\": false,
      \"options\": { \"keepalive\": -1 }
    }")
    
    RAW_AI_TEXT=$(echo "$RESPONSE" | jq -r '.response')
    AI_TEXT=$(echo "$RAW_AI_TEXT" | tr -d '*`' | sed 's/[^[:alnum:][:space:][:punct:]]//g' | tr -d '\n\r' | sed 's/^[ \t]*//;s/[ \t]*$//')
    
    echo -e "\033[1;36mAI:\033[0m $AI_TEXT"
    
    # Audio response routing based on running configuration (Objective B)
    echo "$AI_TEXT" | $HOME/hl2-ai-voice/piper/piper --model "$PIPER_MODEL" --output_raw 2>/dev/null | play -t raw -r $PIPER_RATE -c 1 -b 16 -e signed-integer - 2>/dev/null
done
