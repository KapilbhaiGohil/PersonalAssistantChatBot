from fastapi import FastAPI
from pydantic import BaseModel
from mongo_db.models import User
from mongo_db.utils import createUser, loginUser
from vector_db.utils import insert_data
from ExternalApis.utils import entityExtraction, generate_embedding, intentClassification
from fastapi.responses import JSONResponse

app = FastAPI()

class QueryInput(BaseModel):
    query: str 

@app.post("/register")
async def register(U:User):
    res = await createUser(U)
    print(res)
    return JSONResponse(content=res['msg'],status_code=res['code'])

@app.post("/login")
async def register(U:User):
    res = await loginUser(U)
    return JSONResponse(content=res['msg'],status_code=res['code'])

@app.post("/chat")
async def process_query(input: QueryInput):
    user_input = input.query
    entities =  entityExtraction(user_input)
    if(entities['intent'].strip().lower() == "add_task"):
        embedding = generate_embedding(entities)
        
        if(entities['notification'] and entities['notification']==False):
            insert_data('Tasks',embedding,entities)
    return {"ok":'done'}
