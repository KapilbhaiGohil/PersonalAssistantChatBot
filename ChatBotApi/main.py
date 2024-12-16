from fastapi import FastAPI
from pydantic import BaseModel
from mongo_db.models import User
from mongo_db.utils import createUser, insertTask, loginUser,retriveAllTask
from ExternalApis.utils import DialogForAddingTask,DialogForRetrivingTask,intentClassification
from fastapi.responses import JSONResponse
from fastapi.middleware.cors import CORSMiddleware

app = FastAPI()

class LoginRequest(BaseModel):
    email: str
    password: str

class QueryInput(BaseModel):
    query: str 
    chat_history:str
    stage:str
    email:str

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"], 
    allow_headers=["*"],
)


def returnRequest(res):
    if('data' in res):
        return JSONResponse(content={"msg":res['msg'],"data":res['data']},status_code=res['code'])
    return JSONResponse(content={"msg":res['msg']},status_code=res['code'])

@app.post("/register")
async def register(U:User):
    res = await createUser(U)
    return returnRequest(res)

@app.post("/login")
async def login(L:LoginRequest):
    res = await loginUser(L.email,L.password)
    return returnRequest(res)



@app.post("/chat")
async def process_query(input: QueryInput):
    user_input = input.query
    stage = input.stage
    history = input.chat_history
    email = input.email
    print(input)
    res = {'text':"sorry not able to fullfill your request now",'intent':'new'}
    if(stage == 'new'):
        stage = intentClassification(user_input)['intent']
    print(stage)
    if stage == 'add' or stage =='general_chat' or stage == 'ambiguous' :
        res = DialogForAddingTask(user_input,history)
        if(res['dbAction']=='add' and res['isInfoIncomplete']==False):
            info = await insertTask(email,res['payload'])
            if(info['code']==200):
                return res
    
    elif stage == 'retrive':
        info = await retriveAllTask(email)
        print(info)
        history += '\nDATARESULT:{info}'
        res = await DialogForRetrivingTask(user_input,history)
    elif stage == 'delete':
        print('delete')
    else :
        print("error")
    return res