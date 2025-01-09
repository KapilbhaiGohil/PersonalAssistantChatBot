from fastapi import FastAPI, HTTPException, Depends, Header
from pydantic import BaseModel
from firebase.utils1 import insertTask, retriveAllTask, updateTask, deleteTask
from GeminiAPI.utils import generalDialog,conflictChecker
from CalendarAPI.utils import create_google_calendar_event,update_google_calendar_event,delete_google_calendar_event
from fastapi.middleware.cors import CORSMiddleware
import re

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
    user_input = input.query
    history = input.chat_history
    email = input.email
    access_token = authorization 
    print(f"Access Token: {access_token}") 
    res = {'text': "sorry not able to fulfill your request now", 'intent': 'new'}
    info = await retriveAllTask(email)
    if('data' in info):info = info['data']
    else:info=[]
    history += f'\nDATARESULT:{info}'
    res = generalDialog(user_input,history)
    print(info)
    print(history)
    if not res['isInfoIncomplete']:
        if res['dbAction'] == 'add':
            payload = res['payload']
            if 'startdate' in payload and 'starttime' in payload and 'enddate' in payload and 'endtime' in payload:
                res2 = conflictChecker(payload,info,'add')
                print(res2)
                if not res2['isConflict']:
                    eventInfo = create_google_calendar_event(
                        access_token,
                        payload['summary'],
                        payload['desc'],
                        payload['startdate'],
                        payload['starttime'],
                        payload['enddate'],
                        payload['endtime']
                    )
                    res['payload']['addedToCalendar'] = True
                    info = await insertTask(email,res['payload'],eventInfo['id'])
                else: return res2
            else:
                res['payload']['addedToCalendar'] = False
                info = await insertTask(email, res['payload'])
                res['intent'] = 'new'
                if info['code'] == 200:
                    return res
        elif res['dbAction'] == 'update':
            payload = res['payload']['updatedPayload']['task']
            print("-----------------------------------------------------------------------\n",res)
            if(payload['addedToCalendar']):
                info = [obj for obj in info if obj['task_id'] != res['payload']['updatedPayload']['task_id']] 
                res2 = conflictChecker(payload,info,'update')
                if not res2['isConflict']:
                    if res['calendarAction'] == 'add':
                        eventInfo = create_google_calendar_event(
                            access_token,
                            payload['summary'],
                            payload['desc'],
                            payload['startdate'],
                            payload['starttime'],
                            payload['enddate'],
                            payload['endtime']
                            )
                        res['payload']['updatedPayload']['task_id']=eventInfo['id']
                    elif res['calendarAction'] == 'update':
                        eventInfo = update_google_calendar_event(
                            access_token,
                            res['payload']['_id'],
                            payload['summary'],
                            payload['desc'],
                            payload['startdate'],
                            payload['starttime'],
                            payload['enddate'],
                            payload['endtime']
                            )
                else:
                    return res2
            await updateTask(res['payload']['_id'], res['payload']['updatedPayload']['task'],res['payload']['updatedPayload']['task_id'])
            res['intent'] = 'new'

        elif res['dbAction'] == 'delete':
            payload = res['payload']['deletePayload']
            for obj in payload:
                _id = obj['_id']
                if obj['addedToCalendar']:
                    delete_google_calendar_event(access_token,_id)
                await deleteTask(_id)
            res['intent'] = 'new'
    return res
