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
    intent = intentClassification(user_input)
    entities = entityExtraction(user_input)
    emb = generate_embedding(user_input)
    print(len(emb['embedding']))
    print(intent,entities)
    # insert_data('Tasks',emb['embedding'])
    return {"received_query": input.query}
