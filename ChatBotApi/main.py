from fastapi import FastAPI, HTTPException, Depends, Header
from pydantic import BaseModel
from firebase.utils1 import insertTask, retriveAllTask, updateTask, deleteTask
from GeminiAPI.utils import generalDialog, conflictChecker
from CalendarAPI.utils import create_google_calendar_event, update_google_calendar_event, delete_google_calendar_event
from fastapi.middleware.cors import CORSMiddleware
import re
import logging

# Initialize logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = FastAPI()

class QueryInput(BaseModel):
    query: str
    chat_history: str
    stage: str
    email: str

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

def extract_access_token(authorization: str = Header(...)):
    match = re.match(r"Bearer (\S+)", authorization)
    if match:
        return match.group(1)
    raise HTTPException(status_code=400, detail="Invalid Authorization header format")

@app.post("/chat")
async def process_query(input: QueryInput, authorization: str = Depends(extract_access_token)):
    try:
        user_input = input.query
        history = input.chat_history
        email = input.email
        access_token = authorization
        logger.info(f"Access Token Received: {access_token}")

        info = await retriveAllTask(email)
        tasks = info.get('data', []) if isinstance(info, dict) else []
        history += f'\nDATARESULT:{tasks}'
        
        response = generalDialog(user_input, history)
        logger.info(f"Generated Response: {response}")

        if not response.get('isInfoIncomplete'):
            db_action = response.get('dbAction')
            
            if db_action == 'add':
                payload = response.get('payload', {})
                if all(k in payload for k in ['startdate', 'starttime', 'enddate', 'endtime']):
                    conflict_check = conflictChecker(payload, tasks, 'add')
                    if not conflict_check.get('isConflict'):
                        event_info = create_google_calendar_event(
                            access_token,
                            payload.get('summary', ''),
                            payload.get('desc', ''),
                            payload['startdate'],
                            payload['starttime'],
                            payload['enddate'],
                            payload['endtime'],
                            payload.get('daily', False)
                        )
                        payload['addedToCalendar'] = True
                        await insertTask(email, payload, event_info.get('id'))
                    else:
                        return conflict_check
                else:
                    payload['addedToCalendar'] = False
                    await insertTask(email, payload)
                response['intent'] = 'new'

            elif db_action == 'update':
                updated_payload = response.get('payload', {}).get('updatedPayload', {}).get('task', {})
                task_id = response.get('payload', {}).get('updatedPayload', {}).get('task_id', None)
                
                if updated_payload.get('addedToCalendar'):
                    tasks = [t for t in tasks if t.get('task_id') != task_id]
                    conflict_check = conflictChecker(updated_payload, tasks, 'update')
                    
                    if not conflict_check.get('isConflict'):
                        if response.get('calendarAction') == 'add':
                            event_info = create_google_calendar_event(
                                access_token,
                                updated_payload.get('summary', ''),
                                updated_payload.get('desc', ''),
                                updated_payload['startdate'],
                                updated_payload['starttime'],
                                updated_payload['enddate'],
                                updated_payload['endtime'],
                                updated_payload.get('daily', False)
                            )
                            response['payload']['updatedPayload']['task_id'] = event_info.get('id')
                        elif response.get('calendarAction') == 'update':
                            update_google_calendar_event(
                                access_token,
                                task_id,
                                updated_payload.get('summary', ''),
                                updated_payload.get('desc', ''),
                                updated_payload['startdate'],
                                updated_payload['starttime'],
                                updated_payload['enddate'],
                                updated_payload['endtime'],
                                updated_payload.get('daily', False)
                            )
                    else:
                        return conflict_check
                await updateTask(task_id, updated_payload, task_id)
                response['intent'] = 'new'

            elif db_action == 'delete':
                delete_payload = response.get('payload', {}).get('deletePayload', [])
                for obj in delete_payload:
                    if obj.get('addedToCalendar'):
                        delete_google_calendar_event(access_token, obj.get('_id'))
                    await deleteTask(obj.get('_id'))
                response['intent'] = 'new'
        return response
    except Exception as e:
        logger.error(f"Unexpected error: {e}")
        raise HTTPException(status_code=500, detail="Internal Server Error")
