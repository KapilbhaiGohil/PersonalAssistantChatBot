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

now = datetime.now()
current_date = now.strftime("%Y-%m-%d")  
current_day = now.strftime("%A")  

def generate_embedding(text):
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
  - if user tries to add reminder then date and time must included
  - the date and time must be of future not past
  - consider am / pm carefully 
  - you can only add the information into database if user has another intent then specify in the intent so accordingly it can be passed to other module
  -  Context:
          - Current Date: {current_date} ({current_day})
          - Previous Conversation: {chat_history}
          - User Input: "{user_input}"

  - Your response should be in JSON format with the following structure:
        {{
            "text": "Response text to user",
            "isInfoIncomplete": true/false,  # if informaion is good to go then false, else true
            "dbAction": "add/noaction",  # Database operation
            "intent":"add/update/delete/retrieve/general/ambiguous",
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
  extracted_data = json.loads(eresult.text)
  return extracted_data

def DialogForRetrivingTask(user_input, chat_history):
  prompt = f"""
  - i am personal assistance bot.
  - user tries to retrieve from database.(don't include in response)
  - so accordingly do converation with user.
  - user have all rights what to retrieve and what to not
  - Dataresult contains the data availabe in the database (mongodb)
  - return result in natural language format
  - give output in bullet points 
  -  Context:
          - Current Date: {current_date} ({current_day})
          - Previous Conversation: {chat_history}
          - User Input: "{user_input}"

  - Your response should be in JSON format with the following structure:
        {{
            "text": "Response text to user",
            "isInfoIncomplete": true/false,  # if informaion is good to go then false, else true
            "dbAction": "retrieve/noaction",  # Database operation
            "intent":"add/update/delete/retrieve/general/ambiguous",
            "query": {{
              # should contains field like date,time,task,task_desc,remainder,etc.
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


def DialogForUpdatingTask(user_input, chat_history):
  prompt = f"""
  - i am personal assistance bot.
  - user tries to update from database.(don't include in response)
  - so accordingly do converation with user.
  - user have all rights what to update and what to not
  - Dataresult contains the data availabe in the database (mongodb)
  - when everything confirmed at last make dbAction update and payload contains updated document
  - _id contains id of the document to be update

  -  Context:
          - Current Date: {current_date} ({current_day})
          - Previous Conversation: {chat_history}
          - User Input: "{user_input}"

  - Your response should be in JSON format with the following structure:
        {{
            "text": "Response text to user",
            "isInfoIncomplete": true/false,  # if informaion is good to go then false, else true
            "dbAction": "update/noaction",  # Database operation
            "intent":"add/update/delete/retrieve/general/ambiguous",
            "_id":object id or none
            "payload": {{
              
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


def DialogForDeletingTask(user_input, chat_history):
  prompt = f"""
  - i am personal assistance bot.
  - user tries to delete from database.(don't include in response)
  - so accordingly do converation with user.
  - user have all rights what to update and what to not
  - Dataresult contains the data availabe in the database (mongodb)
  - when everything confirmed at last make dbAction delete
  - _id contains list of ids of the document to be delete
  - don't give response like wait or something data already deleted once the dbAction = delete and isInfoIncomplete = true
  -  Context:
          - Current Date: {current_date} ({current_day})
          - Previous Conversation: {chat_history}
          - User Input: "{user_input}"

  - Your response should be in JSON format with the following structure:
        {{
            "text": "Response text to user",
            "isInfoIncomplete": true/false,  # if informaion is good to go then false, else true
            "dbAction": "update/noaction",  # Database operation
            "intent":"add/update/delete/retrieve/general/ambiguous",
            "_id":[object id list] or none
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

def intentClassification(user_input):
   prompt = f"""
  You are a personal assistant bot. Your task is to classify the user's intent based on their input.

  Instructions:
  - The input you receive will be in the form of a user's query or statement.
  - Your task is to determine the intent of the user's query.
  - Return the intent as a JSON object in the following format:

  {{
    "intent": "add" | "update" | "delete" | "retrieve" | "general" | "ambiguous"
  }}
  Explanation of intents:
  - "add": User wants to add a new task or item.
  - "update": User wants to update an existing task or item.
  - "delete": User wants to remove a task or item.
  - "retrieve": User is asking to retrieve information about a task.
  - "general": The user is engaging in a casual or general conversation.
  - "ambiguous": The input is unclear, and it's not possible to determine the intent.

  Example:
  - Input: "Can you remind me to call the doctor tomorrow?"
  - Output: {{
    "intent": "add"
  }}

  - Input: "Please show me my task list."
  - Output: {{
    "intent": "retrieve"
  }}

  Now, classify the following user input:
  - "{user_input}"
  """

   eresult = model.generate_content(
            prompt,
            generation_config=genai.GenerationConfig(
                response_mime_type="application/json"
            ),
        )

   extracted_data = json.loads(eresult.text)
   return extracted_data
