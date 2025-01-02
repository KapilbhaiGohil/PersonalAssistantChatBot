from fastapi import FastAPI, HTTPException, Depends, Header
from pydantic import BaseModel
from firebase.utils1 import insertTask, retriveAllTask, updateTask, deleteTask
from GeminiAPI.utils import (
    DialogForAddingTask, DialogForRetrivingTask, DialogForUpdatingTask,
    intentClassification, DialogForDeletingTask
)
from CalendarAPI.utils import create_google_calendar_event,update_google_calendar_event,delete_google_calendar_event
from fastapi.responses import JSONResponse
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

def returnRequest(res):
    if 'data' in res:
        return JSONResponse(content={"msg": res['msg'], "data": res['data']}, status_code=res['code'])
    return JSONResponse(content={"msg": res['msg']}, status_code=res['code'])

def extract_access_token(authorization: str = Header(...)):
    match = re.match(r"Bearer (\S+)", authorization)
    if match:
        return match.group(1) 
    raise HTTPException(status_code=400, detail="Invalid Authorization header format")

@app.post("/chat")
async def process_query(input: QueryInput, authorization: str = Depends(extract_access_token)):
    user_input = input.query
    stage = input.stage
    history = input.chat_history
    email = input.email
    access_token = authorization 
    print(f"Access Token: {access_token}") 
    res = {'text': "sorry not able to fulfill your request now", 'intent': 'new'}
    
    if stage == 'new':
        stage = intentClassification(user_input)['intent']

    print(stage)

    if stage == 'add' or stage == 'general' or stage == 'ambiguous':
        info = await retriveAllTask(email)
        history += f'\nDATARESULT:{info}'
        res = DialogForAddingTask(user_input, history)
        print(res)
        if res['dbAction'] == 'add' and not res['isInfoIncomplete']:
            print(res)
            payload = res['payload']
            if 'startdate' in payload and 'starttime' in payload and 'enddate' in payload and 'endtime' in payload:
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
            else:
                res['payload']['addedToCalendar'] = False
                info = await insertTask(email, res['payload'])
            res['intent'] = 'new'
            if info['code'] == 200:
                return res

    elif stage == 'retrieve':
        info = await retriveAllTask(email)
        print(info)
        history += f'\nDATARESULT:{info}'
        res = DialogForRetrivingTask(user_input, history)
        res['intent'] = 'new'


    elif stage == 'update':
        info = await retriveAllTask(email)
        history += f'\nDATARESULT:{info}'
        res = DialogForUpdatingTask(user_input, history)
        print(res)
        if not res['isInfoIncomplete'] and res['dbAction'] == 'update':
            payload = res['updatedPayload']['task']
            if(payload['addedToCalendar']):
                eventInfo = update_google_calendar_event(
                    access_token,
                    res['_id'],
                    payload['summary'],
                    payload['desc'],
                    payload['startdate'],
                    payload['starttime'],
                    payload['enddate'],
                    payload['endtime']
                    )
            await updateTask(res['_id'], res['updatedPayload']['task'])
            res['intent'] = 'new'

    elif stage == 'delete':
        info = await retriveAllTask(email)
        history += f'\nDATARESULT:{info}'
        res = DialogForDeletingTask(user_input, history)
        print(res)
        if not res['isInfoIncomplete'] and res['dbAction'] == 'delete':
            payload = res['deletePayload']
            for obj in payload:
                _id = obj['_id']
                if obj['addedToCalendar']:
                    delete_google_calendar_event(access_token,_id)
                await deleteTask(_id)
            res['intent'] = 'new'
        return res
    else:
        print("error")
    return res
