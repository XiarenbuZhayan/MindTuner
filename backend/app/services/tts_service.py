import os
from google.cloud import texttospeech, storage
from datetime import datetime
from config.config import tts_client, storage_client

class TTSService:
    def __init__(self):
        self.client = tts_client
        self.storage_client = storage_client
        self.bucket_name = "mindtuner-8804e.firebasestorage.app"

    def generate_and_store_speech(self, text: str, record_id: str) -> str:
        audio_content = self._generate_speech(text)
        audio_url = self._upload_to_storage(audio_content, record_id)
        return audio_url
    
    def _generate_speech(self, text: str) -> bytes:
        synthesis_input = texttospeech.SynthesisInput(text=text)
        voice = texttospeech.VoiceSelectionParams(
            language_code="en-US",
            name="en-US-Standard-A",
            ssml_gender=texttospeech.SsmlVoiceGender.FEMALE
        )
        audio_config = texttospeech.AudioConfig(
            audio_encoding=texttospeech.AudioEncoding.MP3,
            speaking_rate=0.9
        )
        
        response = self.client.synthesize_speech(
            input=synthesis_input, voice=voice, audio_config=audio_config
        )
        return response.audio_content

       
    def _upload_to_storage(self, audio_content: bytes, record_id: str) -> str:
        bucket = self.storage_client.bucket(self.bucket_name)
        blob_name = f"meditations/{record_id}.mp3"
        blob = bucket.blob(blob_name)
        
        blob.upload_from_string(audio_content, content_type="audio/mpeg")
        blob.make_public()
        
        return blob.public_url