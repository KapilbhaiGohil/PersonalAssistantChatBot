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

def DialogForAddingTask(user_input, chat_history):
  prompt = f"""
  - i am personal assistance bot.
  - user tries to add something to database.(don't include in response)
  - so accordingly do converation with user.
  - user have all rights what to add and what to not
  - user tries to add reminder then date and time must included
  - in case of reminder the date and time must be of future not past
  -  Context:
          - Current Date: {current_date} ({current_day})
          - Previous Conversation: {chat_history}
          - User Input: "{user_input}"

  - Your response should be in JSON format with the following structure:
        {{
            "text": "Response text to user",
            "isInfoIncomplete": true/false,  # if informaion is good to go then false, else true
            "dbAction": "add/noaction",  # Database operation
            "intent":"add/update/delete/retrive/general_chat/ambiguous",
            "payload": {{
              task: <e.g., 'meeting', 'reminder', 'to-do'>,
              task_desc:task description
              remainder:true/false -if reminder is true then must have date and time for when to remind
              -other fields ...
            }}  # this field required if dbAction is other than noaction
        }}
  """
  eresult = model.generate_content(
            prompt,
            generation_config=genai.GenerationConfig(
                response_mime_type="application/json"
            ),
        )

        # Parse the model's JSON response
  extracted_data = json.loads(eresult.text)
  return extracted_data

def AddDBConversation():
    chat_history = ""
    user_input = input("Enter your query: ")
    chat_history += f"User: {user_input}"
    res = DialogForAddingTask(user_input, chat_history)
    while res['isInfoIncomplete']:
        print(res)
        print(f"Bot: {res['text']}")
        chat_history += f"\nBot: {res['text']}"

        user_input = input("Enter your query: ")
        chat_history += f"\nUser: {user_input}"

        res = DialogForAddingTask(user_input, chat_history)
    print("Final response:", res)
