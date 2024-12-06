from datetime import datetime
from dotenv import load_dotenv
import os
import google.generativeai as genai


load_dotenv('./config.env')

GEMINI_KEY = os.getenv("GEMINI_KEY")


genai.configure(api_key=GEMINI_KEY)
model = genai.GenerativeModel("gemini-1.5-flash")
emodel = genai.GenerativeModel('models/text-embedding-004')

# Get the current date and time
now = datetime.now()
current_date = now.strftime("%Y-%m-%d")  # Format: YYYY-MM-DD
current_day = now.strftime("%A")  # Full weekday name (e.g., Monday)

def intentClassification(user_input):
    prompt = f"""
    Classify the following user input into one of these intents:
    - add_task
    - remove_task
    - update_task
    - retrieve_task
    - general_chat
    - ambiguous

    User input: "{user_input}"

    Output the intent only.
    """
    response = model.generate_content(
        prompt,
        generation_config=genai.GenerationConfig(
            response_mime_type="text/plain" 
        )
    )
    return response.text

def entityExtraction(user_input):
    eprompt = f"""
    Extract the entities from user input where each document contains only two fields "entity" and "value". Each collection must contain at least three entities "date,time,event". If any date is not mentioned then consider today date. time must be between 0 to 24.
    If there is any time related information mentioned then replace it with corresponding date by considering current date is "{current_date}" and current day is "{current_day}".
    User Input : "{user_input}"
    """
    eresult = model.generate_content(
        eprompt,
        generation_config=genai.GenerationConfig(
            response_mime_type="application/json"
        ),
    )
    return eresult.text

def generate_embedding(text: str):
    result = genai.embed_content(
        model="models/text-embedding-004",
        content=f"{text}"
    )
    return result