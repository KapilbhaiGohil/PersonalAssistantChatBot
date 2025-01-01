from fastapi import FastAPI, HTTPException, Depends, Header
from pydantic import BaseModel
from firebase.utils1 import insertTask, retriveAllTask, updateTask, deleteTask
from GeminiAPI.utils import (
    DialogForAddingTask, DialogForRetrivingTask, DialogForUpdatingTask,
    intentClassification, DialogForDeletingTask
)
from CalendarAPI.utils import create_google_calendar_event
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

    if stage == 'general' or stage == 'ambiguous':
        res = DialogForAddingTask(user_input, history)
        res['intent'] = 'new'
        return res

    if stage == 'add':
        info = await retriveAllTask(email)
        history += f'\nDATARESULT:{info}'
        res = DialogForAddingTask(user_input, history)
        if res['dbAction'] == 'add' and not res['isInfoIncomplete']:
            print(res)
            payload = res['payload']
            if 'startdate' in res['payload'] and 'starttime' in res['payload']:
                if 'enddate' in payload and 'endtime' in payload:
                    # If both start and end times are provided
                    eventInfo = create_google_calendar_event(
                        access_token,
                        payload['summary'],
                        payload['desc'],
                        payload['startdate'],
                        payload['starttime'],
                        payload['enddate'],
                        payload['endtime']
                    )
                else:
                    eventInfo = create_google_calendar_event(
                        access_token,
                        payload['summary'],
                        payload['desc'],
                        payload['startdate'],
                        payload['starttime']
                    )
                info = await insertTask(email,res['payload'],eventInfo['id'])
            else:
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
        if not res['isInfoIncomplete'] and res['dbAction'] == 'update':
            await updateTask(res['_id'], res['payload']['task'])
            res['intent'] = 'new'

    elif stage == 'delete':
        info = await retriveAllTask(email)
        history += f'\nDATARESULT:{info}'
        res = DialogForDeletingTask(user_input, history)
        print(res)
        if not res['isInfoIncomplete'] and res['dbAction'] == 'delete':
            for _id in res['_id']:
                await deleteTask(_id)
            res['intent'] = 'new'
        return res
    else:
        print("error")
    return res
