import os
import imageio_ffmpeg
import whisper
import json
from pathlib import Path

def transcribe_files():
    # Set ffmpeg executable path in environment variable for whisper to use
    ffmpeg_exe = imageio_ffmpeg.get_ffmpeg_exe()
    venv_bin = os.path.abspath(".venv_whisper/bin")
    os.environ["PATH"] = venv_bin + os.pathsep + os.environ.get("PATH", "")
    
    print("Loading model...")
    try:
        model = whisper.load_model("turbo", download_root=".venv_whisper/models")
        print("Using turbo model")
    except Exception as e:
        print(f"Turbo model failed to load, falling back to small: {e}")
        model = whisper.load_model("small", download_root=".venv_whisper/models")
        print("Using small model")

    docs_dir = Path("docs")
    audio_files = list(docs_dir.glob("*.m4a"))
    
    results = []
    
    for f in audio_files:
        print(f"Transcribing {f.name}...")
        result = model.transcribe(str(f), language="ko")
        text = result["text"]
        
        # Save individual result
        out_path = docs_dir / f"{f.stem}.txt"
        with open(out_path, "w", encoding="utf-8") as out_f:
            out_f.write(text)
            
        print(f"Finished {f.name}")
        results.append(f"## {f.name}\n\n{text}\n\n")
        
    # Write combined result
    combined_path = docs_dir / "requirements_transcription.md"
    with open(combined_path, "w", encoding="utf-8") as pf:
        pf.write("# 음성 녹음 요구사항 변환 문서\n\n")
        pf.write("앱 개발을 의뢰한 사람의 요구사항 음성 녹음을 변환한 내용입니다.\n\n")
        for res in results:
            pf.write(res)
            
    print("All transcription tasks completed.")

if __name__ == "__main__":
    transcribe_files()
