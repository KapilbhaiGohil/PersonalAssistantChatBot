from datetime import datetime
from dotenv import load_dotenv
import os
import google.generativeai as genai
import json

load_dotenv('./config.env')

GEMINI_KEY = os.getenv("GEMINI_KEY")

genai.configure(api_key=GEMINI_KEY)
model = genai.GenerativeModel("gemini-1.5-flash")

now = datetime.now()
current_date = now.strftime("%Y-%m-%d")  
current_day = now.strftime("%A")  
current_time = now.strftime("%H:%M")

def DialogForAddingTask(user_input, chat_history):
  prompt = f"""
  - You are a personal assistant bot.
  - Your task is to help the user add events to their calendar and handle general conversations.
  - before any validation first check IF THE NEW TASK OVERLAPS WITH EXISTING TASKS THEN DON'T ADD IT.
  - If the user provides date and time, convert them into an absolute date and 24-hour time format. 
  - Foucs here you are making mistek -> Ensure the date and time are in the future, not in the past.
  - If the user's intent is not to add an event but to update, delete, retrieve, or handle other actions (e.g., ambiguous), specify the intent in the response.
  - The response should include a summary and description for Google Calendar if the event information is complete.
  - if end date and end time not provided then set according to task and confirm with user and then after only add into database.
  - for adding into database make dbAction to add and isInfoIncomplete to false.

  - Context:
      - Current Date: {current_date} ({current_day})
      - Current Time: {current_time}
      - Previous Conversation: {chat_history}
      - User Input: "{user_input}"
  
  - Your response should be in JSON format with the following structure:
    {{
        "text": "Response text to the user",
        "isInfoIncomplete": true/false,  # true if more information is needed; false if information is complete
        "dbAction": "add/noaction",  # Action to perform in the database, "add" if adding a task or event
        "intent": "add/update/delete/retrieve/general/ambiguous",  # Intent type for handling the user query
        "payload": {{
            "task": "<e.g., 'meeting', 'reminder', 'to-do'>",
            "desc": "Description of the task for Google Calendar (if all information is gathered)",
            "summary": "Summary of the task for Google Calendar (if all information is gathered)",
            --optional fields
            "startdate": "<date in YYYY-MM-DD format if specified>",
            "starttime": "<time in HH:MM format if specified>",
            "enddate": "<date in YYYY-MM-DD format if specified>",
            "endtime": "<time in HH:MM format if specified>",
            "other_info": "<other relevant information for the task>"
        }}  # This section is required if dbAction is other than noaction
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
  - user have all rights what to retrieve and what to not.
  - Dataresult contains the data availabe in the database using that data give output.
  - text should contains information in sentence format
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
  - when everything discussed at last make dbAction update and payload contains updated document and give successfull message to user.
  - _id contains id of the document to be update
  - IF REMINDER IS TRUE THEN UPDATED DATE OR TIME SHOULD BE IN FUTURE.
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
            "updatedPayload": {{
              
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
            "deletePayload":[list of objects of form Object("_id":"","addedToCalendar":"")] or none
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
