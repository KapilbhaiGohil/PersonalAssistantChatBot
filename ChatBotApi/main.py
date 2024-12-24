from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from mongo_db.models import User
from mongo_db.utils import createUser, insertTask, loginUser, retriveAllTask, saveGoogleToken, updateTask, deleteTask
from ExternalApis.utils import (
    DialogForAddingTask, DialogForRetrivingTask, DialogForUpdatingTask,
    intentClassification, DialogForDeletingTask
)
from fastapi.responses import JSONResponse
from fastapi.middleware.cors import CORSMiddleware

app = FastAPI()

class LoginRequest(BaseModel):
    email: str
    password: str

class QueryInput(BaseModel):
    query: str
    chat_history: str
    stage: str
    email: str

class TokenRequest(BaseModel):
    access_token: str  # User's access token (e.g., from Google)

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


@app.post("/register")
async def register(U: User):
    res = await createUser(U)
    return returnRequest(res)


@app.post("/login")
async def login(L: LoginRequest):
    res = await loginUser(L.email, L.password)
    return returnRequest(res)


@app.post("/chat")
async def process_query(input: QueryInput):
    user_input = input.query
    stage = input.stage
    history = input.chat_history
    email = input.email
    print(input)
    res = {'text': "sorry not able to fulfill your request now", 'intent': 'new'}
    if stage == 'new':
        stage = intentClassification(user_input)['intent']
    print(stage)
    if stage == 'general' or stage == 'ambiguous':
        res = DialogForAddingTask(user_input, history)
        res['intent'] = 'new'
        return res
    if stage == 'add':
        res = DialogForAddingTask(user_input, history)
        if res['dbAction'] == 'add' and not res['isInfoIncomplete']:
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


@app.post("/token")
async def get_token(token_request: TokenRequest):
    """Endpoint to receive and process the user's token and save it to MongoDB."""
    access_token = token_request.access_token
    email = token_request.email
    if access_token:
        result = await saveGoogleToken(email, access_token)
        if result["code"] == 200:
            return JSONResponse(content={"msg": "Token received and processed successfully."}, status_code=200)
        else:
            return JSONResponse(content={"msg": result["msg"]}, status_code=result["code"])
    else:
        raise HTTPException(status_code=400, detail="Invalid token.")
