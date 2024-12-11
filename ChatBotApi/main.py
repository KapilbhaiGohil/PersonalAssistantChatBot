from fastapi import FastAPI
from pydantic import BaseModel
from mongo_db.models import User
from mongo_db.utils import createUser, loginUser
from vector_db.utils import insert_data
from ExternalApis.utils import DialogForAddingTask, generalDialog, generate_embedding
from fastapi.responses import JSONResponse
from fastapi.middleware.cors import CORSMiddleware

app = FastAPI()


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
    print(res)
    return JSONResponse(content=res['msg'],status_code=res['code'])

@app.post("/login")
async def register(U:User):
    res = await loginUser(U)
    return JSONResponse(content=res['msg'],status_code=res['code'])

@app.get("/")
async def register():
    print("Helo")
    return {"ok":"result"}


@app.post("/chat")
async def process_query(input: QueryInput):
    user_input = input.query
    stage = input.stage
    history = input.chat_history
    if(stage == 'add' or stage == "new"):
        res = DialogForAddingTask(user_input,history)
        if(res['isInfoIncomplete']==False and res['intent']=='add'):
            emb = generate_embedding(res['payload'])
            insert_data('Tasks',emb,res['payload'])
        return res
    return {"ok":'done'}
