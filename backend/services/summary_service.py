import os
import openai
import json
from dotenv import load_dotenv

load_dotenv()
openai.api_key = os.getenv("OPENAI_API_KEY")

async def generate_summary(text: str) -> dict:
    if not text:
        return {"summary": "", "genres": []}
        
    allowed_genres = ["Fun", "Sarcastic", "Informative", "Dark", "Inspirational", "Controversial", "Academic", "Dramatic", "Mysterious", "Historic"]
    
    try:
        response = openai.chat.completions.create(
            model="gpt-3.5-turbo",
            response_format={ "type": "json_object" },
            messages=[
                {"role": "system", "content": f"Summarize the given text into 2-4 engaging sentences. Also classify the text into exactly 2 genres from this strict list: {allowed_genres}. Output strictly as JSON like: {{\"summary\": \"...\", \"genres\": [\"...\", \"...\"]}}"},
                {"role": "user", "content": text}
            ],
            max_tokens=200,
            temperature=0.5
        )
        content = response.choices[0].message.content.strip()
        return json.loads(content)
    except Exception as e:
        print(f"Error generating summary: {e}")
        # fallback to first 2 sentences if failure
        sentences = text.split(". ")
        fallback_summary = ". ".join(sentences[:3]) + ("." if not sentences[:3][-1].endswith(".") else "")
        return {"summary": fallback_summary, "genres": ["Informative"]}
