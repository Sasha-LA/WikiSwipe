import os
import openai
from dotenv import load_dotenv

load_dotenv()
openai.api_key = os.getenv("OPENAI_API_KEY")

async def generate_summary(text: str) -> str:
    if not text:
        return ""
    try:
        response = openai.chat.completions.create(
            model="gpt-3.5-turbo",
            messages=[
                {"role": "system", "content": "Summarize the given text into 2 to 4 readable, engaging sentences in plain English. Keep it concise. No hallucinations."},
                {"role": "user", "content": text}
            ],
            max_tokens=150,
            temperature=0.5
        )
        return response.choices[0].message.content.strip()
    except Exception as e:
        print(f"Error generating summary: {e}")
        # fallback to first 2 sentences if failure
        sentences = text.split(". ")
        return ". ".join(sentences[:3]) + ("." if not sentences[:3][-1].endswith(".") else "")
