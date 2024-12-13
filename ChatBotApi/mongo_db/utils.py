import bcrypt
from motor.motor_asyncio import AsyncIOMotorClient
import os
from dotenv import load_dotenv
from mongo_db.models import User

load_dotenv('./config.env')

MONGO_URI = os.getenv('MONGO_URI')
DATABASE = os.getenv('DATABASE')

client = AsyncIOMotorClient(MONGO_URI)
db = client[DATABASE]

UserCollection = db['User']

async def createUser(U: User):
    user_exist = await UserCollection.find_one({"email": U.email})
    if user_exist:
        return {"msg": "User already exists", "code": 400}
    
    hashed_pass = bcrypt.hashpw(U.password.encode('utf-8'), bcrypt.gensalt())
    U.password = hashed_pass.decode('utf-8')
    await UserCollection.insert_one(U.model_dump())
    
    return {"msg": "User created successfully", "code": 200}

async def loginUser(email: str, password: str):
    user_exist = await UserCollection.find_one({"email": email})
    if not user_exist:
        return {"msg": "Invalid credentials", "code": 400}
    
    is_password_valid = bcrypt.checkpw(password.encode('utf-8'), user_exist['password'].encode('utf-8'))
    if not is_password_valid:
        return {"msg": "Invalid credentials", "code": 400}
    
    return {"msg": "Login successful", "code": 200, "data": {"email":user_exist['email'],"password":password,"name":user_exist['name']}}
