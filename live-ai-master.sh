#!/bin/bash

# --- CONFIGURATION PROTOCOLS ---
RIG3_IP="192.168.0.200"
WHISPER_CLI="$HOME/whisper.cpp/build/bin/whisper-cli"
WHISPER_MODEL="$HOME/whisper.cpp/models/ggml-tiny.en.bin"
PIPER_MODEL="$HOME/hl2-ai-voice/en_US-lessac-medium.onnx"

# --- DEFAULT RUNTIME CONFIGURATION ---
# Starts in standard hybrid mode by default
VOICE_ONLY_MODE="false"

clear
echo "========================================================="
echo "   HL2 HYBRID TERMINAL V8 (DYNAMIC MODE TOGGLE SYSTEM)   "
echo "========================================================="
echo " 🛠️  INITIAL PROTOCOL LOADED: KEYBOARD & VOICE ACTIVE    "
echo " 🔄 To flip modes: Type 'mode' OR say 'switch mode'!"
echo " ❌ Type 'exit' or 'quit' to terminate the session."

while true; do
    # -----------------------------------------------------------------
    # LAYER A: RUNNING IN AUTOMATED HANDS-FREE VOICE ONLY MODE (MARS)
    # -----------------------------------------------------------------
    if [ "$VOICE_ONLY_MODE" = "true" ]; then
        sleep 1
        echo -e "\n\033[1;31m[ 🚀 HANDS-FREE LOOP ]\033[0m \033[1;33mMic Open... Speak Command (3s)\033[0m"
        
        # Audio block capture
        arecord -D plughw:0,0 -f S16_LE -r 16000 -c 1 -d 3 /tmp/mic_input.wav 2>/dev/null
        
        RAW_TEXT=$($WHISPER_CLI -m "$WHISPER_MODEL" -f /tmp/mic_input.wav --no-timestamps 2>/dev/null | grep -v '^$' | grep -v 'whisper_')
        USER_TEXT=$(echo "$RAW_TEXT" | sed 's/([^)]*)//g; s/\[[^]]*\]//g' | tr -d '\n\r' | sed 's/^[ \t]*//;s/[ \t]*$//')
        rm -f /tmp/mic_input.wav
        
        # Check for verbal mode toggle command
        if [[ "${USER_TEXT,,}" == *"switch mode"* || "${USER_TEXT,,}" == *"switchmode"* ]]; then
            echo -e "\n\033[1;32m[ 🔄 VOICE COMMAND RECEIVED: DEACTIVATING MARS PROTOCOL ]\033[0m"
            echo -e "[ Returning to standard Keyboard & Voice state... ]"
            VOICE_ONLY_MODE="false"
            
            # Audible verification from Piper
            echo "Switching to desk console input mode." | $HOME/hl2-ai-voice/piper/piper --model "$PIPER_MODEL" --output_raw 2>/dev/null | play -t raw -r 22050 -c 1 -b 16 -e signed-integer - 2>/dev/null
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
        echo -e "\n\033[1;32mUnit@HL2-Terminal\033[0m:~$ "
        read -r USER_INPUT
        
        # Standard exit check
        if [[ "$USER_INPUT" == "exit" || "$USER_INPUT" == "quit" ]]; then
            echo -e "\n[ 🔒 Terminating session. Goodbye, Unit. ]"
            break
        fi
        
        # Check for keyboard layout toggle switch command
        if [[ "$USER_INPUT" == "mode" || "$USER_INPUT" == "toggle" ]]; then
            echo -e "\n\033[1;31m[ 🔄 KEYBOARD COMMAND RECEIVED: EMERGENCY MARS协议 ACTIVATE ]\033[0m"
            echo -e "[ Locking console. 100% hands-free mic tracking initiated... ]"
            VOICE_ONLY_MODE="true"
            
            echo "Emergency override initialized. Hands free voice loop active." | $HOME/hl2-ai-voice/piper/piper --model "$PIPER_MODEL" --output_raw 2>/dev/null | play -t raw -r 22050 -c 1 -b 16 -e signed-integer - 2>/dev/null
            continue
        fi
        
        # Process on-demand voice capture on empty Enter key
        if [ -z "$USER_INPUT" ]; then
            echo -e "\033[1;33m[ 🎤 On-Demand Mic Active... Speak now (3s) ]\033[0m"
            arecord -D plughw:0,0 -f S16_LE -r 16000 -c 1 -d 3 /tmp/mic_input.wav 2>/dev/null
            RAW_TEXT=$($WHISPER_CLI -m "$WHISPER_MODEL" -f /tmp/mic_input.wav --no-timestamps 2>/dev/null | grep -v '^$' | grep -v 'whisper_')
            USER_TEXT=$(echo "$RAW_TEXT" | sed 's/([^)]*)//g; s/\[[^]]*\]//g' | tr -d '\n\r' | sed 's/^[ \t]*//;s/[ \t]*$//')
            rm -f /tmp/mic_input.wav
            
            # Check for verbal toggle in manual mode
            if [[ "${USER_TEXT,,}" == *"switch mode"* ]]; then
                echo -e "\n\033[1;31m[ 🔄 VOICE COMMAND RECEIVED: EMERGENCY MARS PROTOCOL ACTIVATE ]\033[0m"
                VOICE_ONLY_MODE="true"
                echo "Hands free loop active." | $HOME/hl2-ai-voice/piper/piper --model "$PIPER_MODEL" --output_raw 2>/dev/null | play -t raw -r 22050 -c 1 -b 16 -e signed-integer - 2>/dev/null
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
    
    # --- HARVEST METRICS ---
    LIVE_TIME=$(date +"%I:%M %p")
    LIVE_DATE=$(date +"%A, %B %d, %Y")
    STORAGE_INFO=$(df -h /media/storage187Gb | awk 'NR==2 {print $4 " free out of " $2 " total"}')
    CPU_LOAD=$(top -bn1 | grep "Cpu(s)" | awk '{print $2 + $4"%"}')
    CPU_TEMP=$(sensors 2>/dev/null | grep -E "Core 0" | awk '{print $3}' | tr -d '+')
    [ -z "$CPU_TEMP" ] && CPU_TEMP="69.0°C"

    METRICS="[SYSTEM TELEMETRY: Time: $LIVE_TIME. Date: $LIVE_DATE. Storage Array: $STORAGE_INFO. CPU Load: $CPU_LOAD. CPU Temp: $CPU_TEMP. Location: Mars Sector 4 Habitat.]"
    
    # --- PERSONA SWITCH ---
    if [[ "${USER_TEXT,,}" == *"jarvis"* ]]; then
        SYSTEM_CONTEXT="Context: You are Jarvis, a friendly AI companion built into an astronaut's spacesuit on Mars. $METRICS Talk naturally, be encouraging, give numerical telemetry facts if asked, and limit your response to exactly ONE sentence."
        echo -e "\033[1;34m[ 🤖 Persona: Jarvis Online ]\033[0m"
    else
        SYSTEM_CONTEXT="Context: You are a cold corporate tactical AI main core monitoring an astronaut on Mars. Treat the user strictly as an expedition asset. $METRICS Report metrics directly if queried. Limit response to exactly ONE short clinical sentence."
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
    echo "$AI_TEXT" | $HOME/hl2-ai-voice/piper/piper --model "$PIPER_MODEL" --output_raw 2>/dev/null | play -t raw -r 22050 -c 1 -b 16 -e signed-integer - 2>/dev/null
done
