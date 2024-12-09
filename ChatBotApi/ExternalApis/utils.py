from datetime import datetime
from dotenv import load_dotenv
import os
import google.generativeai as genai
import json

load_dotenv('./config.env')

GEMINI_KEY = os.getenv("GEMINI_KEY")


genai.configure(api_key=GEMINI_KEY)
model = genai.GenerativeModel("gemini-1.5-flash")
emodel = genai.GenerativeModel('models/text-embedding-004')

# Get the current date and time
now = datetime.now()
current_date = now.strftime("%Y-%m-%d")  # Format: YYYY-MM-DD
current_day = now.strftime("%A")  # Full weekday name (e.g., Monday)

def generate_embedding(text: str):
    result = genai.embed_content(
        model="models/text-embedding-004",
        content=f"{text}"
    )
    return result['embedding']

def entityExtraction(user_input):
    try:
        # Get the current date and current day
        curr_date = datetime.datetime.today().strftime('%Y-%m-%d')  # '2024-12-08'
        curr_day = datetime.datetime.today().strftime('%A')  # 'Saturday'

        # Define the prompt with the current date context
        eprompt = f"""
        The current date is {curr_date} ({curr_day}). 
        Extract the entities from the following user input. 
        Return the entities in the format: 
        {{
          "task_type": <e.g., 'meeting', 'reminder', 'to-do'>,
          "task_name": <e.g., 'call John', 'submit report'>,
          "intent": <add_task,update_task,remove_task,retrive_task,general_chat,ambiguous> from this only 
          // Add more entities if it is present in user input
          // if the input wants the system to remind,alert or send notification 
          // then set the "notificaiton":"true"
        }}
        Convert any relative dates (like 'tomorrow', 'next Monday') to absolute dates based on the current date. 
        User Input: "{user_input}"
        """
        
        eresult = model.generate_content(
            eprompt,
            generation_config=genai.GenerationConfig(
                response_mime_type="application/json"
            ),
        )
        
        # Parse JSON response
        extracted_data = json.loads(eresult.text)
        
        return extracted_data
    except json.JSONDecodeError:
        print("Error decoding JSON from entity extraction response.")
        return {}
    except Exception as e:
        print(f"Error during entity extraction: {e}")
        return {}
    