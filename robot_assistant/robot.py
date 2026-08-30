"""
시니어케어 로봇 어시스턴트
- 낙상 감지 시 TTS로 안부 확인
- 평소 일상 대화
"""

import os
import json
import time
import threading
import tempfile
import subprocess

import paho.mqtt.client as mqtt
import speech_recognition as sr
from gtts import gTTS
import openai

# ============================================================
# 설정
# ============================================================

OPENAI_API_KEY = os.getenv("OPENAI_API_KEY", "")
MQTT_BROKER    = os.getenv("MQTT_BROKER", "13.238.255.200")
MQTT_PORT      = int(os.getenv("MQTT_PORT", "1883"))
ELDER_NAME     = os.getenv("ELDER_NAME", "어르신")

MQTT_TOPIC_ACTION = "senior_care/action"
MQTT_TOPIC_STATUS = "senior_care/robot_status"   # 로봇 응답 결과 앱으로 전송

LISTEN_TIMEOUT    = 3   # 낙상 후 응답 대기 시간 (초)
CONFIRM_WAIT      = 3   # TTS 재생 후 응답 대기 전 여유 시간 (초)

openai.api_key = OPENAI_API_KEY

# 대화 기록 (일상 대화용)
conversation_history = [
    {
        "role": "system",
        "content": (
            f"당신은 독거노인 {ELDER_NAME}을 돌보는 친절한 AI 로봇 어시스턴트입니다. "
            "말투는 따뜻하고 존댓말을 사용하며 짧고 명확하게 대답하세요. "
            "어르신이 불편함이나 통증을 호소하면 보호자에게 연락하겠다고 안심시켜 주세요. "
            "대화는 한국어로만 합니다."
        ),
    }
]

fall_lock = threading.Lock()
is_handling_fall = False


# ============================================================
# TTS
# ============================================================

def speak(text: str) -> None:
    print(f"[TTS] {text}")
    try:
        tts = gTTS(text=text, lang="ko")
        with tempfile.NamedTemporaryFile(suffix=".mp3", delete=False) as f:
            tmp_path = f.name
        tts.save(tmp_path)
        subprocess.run(["mpg123", "-q", "-a", "hw:UACDemoV10", tmp_path], check=True)
        os.remove(tmp_path)
    except Exception as e:
        print(f"[TTS] 오류: {e}")


# ============================================================
# STT
# ============================================================

def listen(timeout: int = LISTEN_TIMEOUT):
    recognizer = sr.Recognizer()
    mic_index = 0
    with sr.Microphone(device_index=mic_index) as source:
        recognizer.adjust_for_ambient_noise(source, duration=0.5)
        print(f"[STT] 듣는 중... ({timeout}초)")
        try:
            audio = recognizer.listen(source, timeout=timeout, phrase_time_limit=8)
        except sr.WaitTimeoutError:
            print("[STT] 응답 없음 (타임아웃)")
            return None

    try:
        text = recognizer.recognize_google(audio, language="ko-KR")
        print(f"[STT] 인식: {text}")
        return text
    except sr.UnknownValueError:
        print("[STT] 알아듣지 못함")
        return None
    except Exception as e:
        print(f"[STT] 오류: {e}")
        return None


# ============================================================
# GPT 대화
# ============================================================

def chat(user_message: str) -> str:
    conversation_history.append({"role": "user", "content": user_message})
    try:
        response = openai.ChatCompletion.create(
            model="gpt-3.5-turbo",
            messages=conversation_history,
            max_tokens=150,
            temperature=0.7,
        )
        reply = response.choices[0].message["content"].strip()
        conversation_history.append({"role": "assistant", "content": reply})
        return reply
    except Exception as e:
        print(f"[GPT] 오류: {e}")
        return "죄송해요, 잠시 후 다시 말씀해 주세요."


# ============================================================
# 낙상 대응 흐름
# ============================================================

def handle_fall(mqtt_client_ref: mqtt.Client) -> None:
    global is_handling_fall

    speak(f"{ELDER_NAME}, 괜찮으세요? 대답해 주세요.")
    time.sleep(CONFIRM_WAIT)

    response = listen(timeout=LISTEN_TIMEOUT)

    if response is None:
        # 응답 없음 → 긴급 알림
        speak("응답이 없어 보호자에게 연락할게요.")
        mqtt_client_ref.publish(MQTT_TOPIC_STATUS, json.dumps({
            "type": "fall_response",
            "result": "no_response",
            "message": "낙상 후 응답 없음 — 즉시 확인 필요",
        }))
    else:
        ok_keywords    = ["괜찮", "네", "예", "응", "좋아", "괜찬"]
        danger_keywords = ["아파", "못", "힘들", "다쳤", "쓰러", "병원", "살려"]

        if any(k in response for k in danger_keywords):
            speak("많이 불편하시군요. 보호자에게 바로 연락할게요.")
            mqtt_client_ref.publish(MQTT_TOPIC_STATUS, json.dumps({
                "type": "fall_response",
                "result": "needs_help",
                "message": f"낙상 후 어르신 응답: '{response}' — 도움 필요",
            }))
        elif any(k in response for k in ok_keywords):
            speak("다행이에요. 혹시 불편한 곳 있으시면 언제든 말씀해 주세요.")
            mqtt_client_ref.publish(MQTT_TOPIC_STATUS, json.dumps({
                "type": "fall_response",
                "result": "ok",
                "message": f"낙상 후 어르신 응답: '{response}' — 정상",
            }))
        else:
            # 애매한 응답 → GPT에게 판단 위임
            gpt_reply = chat(f"낙상 후 어르신이 '{response}'라고 하셨어요. 괜찮은지 한 번 더 확인해 주세요.")
            speak(gpt_reply)
            mqtt_client_ref.publish(MQTT_TOPIC_STATUS, json.dumps({
                "type": "fall_response",
                "result": "uncertain",
                "message": f"어르신 응답: '{response}'",
            }))

    with fall_lock:
        is_handling_fall = False


# ============================================================
# MQTT
# ============================================================

def on_action_message(client_ref, userdata, message):
    global is_handling_fall

    try:
        data = json.loads(message.payload.decode())
        action = data.get("action", "")
    except Exception:
        return

    if action not in ("Fall Down", "Lying Down"):
        return

    with fall_lock:
        if is_handling_fall:
            return
        is_handling_fall = True

    print(f"[MQTT] 낙상 이벤트 수신: {action}")
    threading.Thread(
        target=handle_fall,
        args=(client_ref,),
        daemon=True,
    ).start()


def setup_mqtt() -> mqtt.Client:
    mqtt_client = mqtt.Client()
    mqtt_client.on_connect = lambda c, u, f, rc: (
        print(f"[MQTT] 연결: {rc}"),
        c.subscribe(MQTT_TOPIC_ACTION),
    )
    mqtt_client.message_callback_add(MQTT_TOPIC_ACTION, on_action_message)
    mqtt_client.connect(MQTT_BROKER, MQTT_PORT, keepalive=60)
    mqtt_client.loop_start()
    return mqtt_client


# ============================================================
# 일상 대화 루프
# ============================================================

def conversation_loop() -> None:
    speak(f"안녕하세요 {ELDER_NAME}! 저는 케어 로봇이에요. 언제든지 말씀해 주세요.")
    print("[로봇] 일상 대화 모드 시작. Ctrl+C로 종료.")

    while True:
        with fall_lock:
            if is_handling_fall:
                time.sleep(0.5)
                continue

        # 낙상 처리 중이면 listen 자체를 건너뜀
        if is_handling_fall:
            time.sleep(0.5)
            continue

        user_input = listen(timeout=1)

        if user_input is None:
            continue

        # listen 끝난 후에도 낙상 처리 중이면 입력 무시
        if is_handling_fall:
            continue

        reply = chat(user_input)
        speak(reply)


# ============================================================
# 메인
# ============================================================

if __name__ == "__main__":
    if not OPENAI_API_KEY:
        print("❌ OPENAI_API_KEY 환경변수를 설정해주세요.")
        exit(1)

    print("[로봇] 시작 중...")
    mqtt_ref = setup_mqtt()
    time.sleep(1)

    try:
        conversation_loop()
    except KeyboardInterrupt:
        print("\n[로봇] 종료")
        mqtt_ref.loop_stop()
