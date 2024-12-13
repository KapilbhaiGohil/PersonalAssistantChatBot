from fastapi import FastAPI
from pydantic import BaseModel
from mongo_db.models import User
from mongo_db.utils import createUser, loginUser
from vector_db.utils import insert_data,retrieve_data
from ExternalApis.utils import DialogForAddingTask,DialogForRetrivingTask,intentClassification, generate_embedding
from fastapi.responses import JSONResponse
from fastapi.middleware.cors import CORSMiddleware

app = FastAPI()

class LoginRequest(BaseModel):
    email: str
    password: str

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Allow all origins or specify allowed domains
    allow_credentials=True,
    allow_methods=["*"],  # Allow all methods
    allow_headers=["*"],
)

class QueryInput(BaseModel):
    query: str 
    chat_history:str
    stage:str

@app.post("/register")
async def register(U:User):
    res = await createUser(U)
    return JSONResponse(content=res['msg'],status_code=res['code'])

@app.post("/login")
async def login(L:LoginRequest):
    res = await loginUser(L.email,L.password)
    if(res['code']==200):
        return JSONResponse(content=res['data'],status_code=res['code'])
    return JSONResponse(content=res['msg'],status_code=res['code'])



@app.post("/chat")
async def process_query(input: QueryInput):
    user_input = input.query
    stage = input.stage
    history = input.chat_history
    print(input)
    flag = 0
    res = {'text':"sorry not able to fullfill your request now",'intent':'new'}
    while(flag == 0):
        flag = 1
        if(stage == 'new'):
            stage = intentClassification(user_input)['intent']
        print('in first request : ' + stage)
        if(stage == 'add' or stage =='general_chat' or stage == 'ambiguous'):
            res = DialogForAddingTask(user_input,history)
            if(res['isInfoIncomplete']==False and res['dbAction']=='add'):
                emb = generate_embedding(res['payload'])
                insert_data('Tasks',emb,res['payload'])
                return res
            elif res['intent'] != 'add':
                stage = res['intent']
        print('in se request : ' + stage)
        if(stage == 'retrieve'):
            res = DialogForRetrivingTask(user_input, history)
            print(res)
            if res['dbAction'] == 'retrieve':
                flag = 0
                emb = generate_embedding(res['query'])
                data = retrieve_data('Tasks', emb, 10)
                history += f'\nDatabaseResult: {data}'  
                print(data)
        print(res)
    return res