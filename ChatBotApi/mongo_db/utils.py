import bcrypt
from motor.motor_asyncio import AsyncIOMotorClient
import os
from dotenv import load_dotenv
from mongo_db.models import User

load_dotenv('./config.env')

MONGO_URI = os.getenv('MONGO_URI')
DATABASE = os.getenv('DATABASE')

client = AsyncIOMotorClient(MONGO_URI)
# print(MONGO_URI,DATABASE)
db = client[DATABASE]

UserCollection = db['User']

async def createUser(U:User):
    user_exist = await UserCollection.find_one({"email":U.email})
    if(user_exist):
        return {"msg":"User already exist","code":400}
    hash_pass = bcrypt.hashpw(U.password.encode('utf-8'),bcrypt.gensalt())
    U.password = hash_pass.decode('utf-8')
    await UserCollection.insert_one(U.model_dump())
    return {"msg":"User created successfully","code":200}

async def loginUser(U:User):
    user_exist = await UserCollection.find_one({"email":U.email})
    if(user_exist==None):
       return {"msg":"Invalid Credentials","code":400}
    match:bool = bcrypt.checkpw(U.password.encode('utf-8'),user_exist['password'].encode('utf-8'))
    if(match==False):
       return{"msg":"Invalid Credentials","code":400}
    return {"msg":"Successfull","code":200}