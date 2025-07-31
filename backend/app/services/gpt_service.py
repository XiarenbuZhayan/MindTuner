from config.config import client



def generate_meditation_script(mood:str, context: str) -> str:
    system_prompt = """
You are a professional and compassionate meditation guide.
Your task is to create a short, personalized meditation script that helps the user calm down and relax.
Always maintain a gentle, slow-paced, emotionally supportive tone.
Output should be in plain text, suitable for direct reading aloud (TTS).
"""
    user_prompt = f"""
Please generate a micro-meditation script based on the following:

- Mood: {mood}
- Situation: {context}

Requirements:
- Duration: 1 to 3 minutes (~120-300 words)
- Structure:
  1. Start with a calming breath cue.
  2. Create a moment of grounding or stillness using the user's current situation.
  3. Use gentle imagery and simple language.
  4. End with a soft closing line.
- Use second-person perspective ("You feel...", "Notice...").
- Do not include section headers or explanations.
- Avoid spiritual jargon or complex metaphors.

Output:
Only return the meditation script. No markdown, no formatting, no commentary.
"""
    
    response = client.chat.completions.create (
        model="gpt-4",
        messages = [
            {"role": "system", "content": system_prompt},
            {"role": "user", "content": user_prompt}
        ],
        temperature = 0.9,
        max_tokens = 500
    )

    return response.choices[0].message.content.strip()