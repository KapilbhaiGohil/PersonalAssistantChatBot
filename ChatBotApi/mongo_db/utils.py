import bcrypt
from motor.motor_asyncio import AsyncIOMotorClient
import os
from dotenv import load_dotenv
from mongo_db.models import User
from bson import ObjectId

load_dotenv('./config.env')

MONGO_URI = os.getenv('MONGO_URI')
DATABASE = os.getenv('DATABASE')

client = AsyncIOMotorClient(MONGO_URI)
db = client[DATABASE]

UserCollection = db['User']
TaskCollection = db['Tasks']

async def createUser(U: User):
    user_exist = await UserCollection.find_one({"email": U.email})
    if user_exist:
        return {"msg": "User already exists", "code": 400}
    
    hashed_pass = bcrypt.hashpw(U.password.encode('utf-8'), bcrypt.gensalt())
    U.password = hashed_pass.decode('utf-8')
    data = await UserCollection.insert_one(U.model_dump())
    return {"msg": "User created successfully", "code": 200}

async def loginUser(email: str, password: str):
    user_exist = await UserCollection.find_one({"email": email})
    if not user_exist:
        return {"msg": "Invalid credentials", "code": 400}
    
    is_password_valid = bcrypt.checkpw(password.encode('utf-8'), user_exist['password'].encode('utf-8'))
    if not is_password_valid:
        return {"msg": "Invalid credentials", "code": 400}
    
    return {"msg": "Login successful", "code": 200, "data": {"email":user_exist['email'],"password":password,"name":user_exist['name']}}

async def insertTask(email, task):
    if not email or not task:
        return {"msg": f"email and task required ", "code": 400}
    task_document = {
        "email": email,
        "task": task,
    }
    try:
        result = await TaskCollection.insert_one(task_document)
        return {"msg": "Task inserted successfully", "code": 200, "task_id": str(result.inserted_id)}
    except Exception as e:
        return {"msg": f"Error inserting task: {e}", "code": 500}

async def retriveAllTask(email):
    if not email:
        raise ValueError("Email is required.")
    tasks = await TaskCollection.find({"email": email},{"_id": 0, "task": 1}).to_list(None)
    if not tasks:
        return {"msg": "No tasks found for this user", "code": 404}
    return {"msg": "Tasks retrieved successfully", "code": 200, "data": tasks}


async def updateTask(task_id: str, email: str, new_task: str):
    if not task_id or not email or not new_task:
        return {"msg": "Task ID, email, and new task content are required", "code": 400}
    
    if not ObjectId.is_valid(task_id):
        return {"msg": "Invalid task ID", "code": 400}
    
    try:
        result = await TaskCollection.update_one(
            {"_id": ObjectId(task_id), "email": email},  
            {"$set": {"task": new_task}}  
        )
        
        if result.matched_count == 0:
            return {"msg": "Task not found or not associated with this user", "code": 404}
        
        return {"msg": "Task updated successfully", "code": 200}
    
    except Exception as e:
        return {"msg": f"Error updating task: {e}", "code": 500}

async def deleteTask(task_id: str, email: str):
    if not task_id or not email:
        return {"msg": "Task ID and email are required", "code": 400}
    
    if not ObjectId.is_valid(task_id):
        return {"msg": "Invalid task ID", "code": 400}
    
    try:
        result = await TaskCollection.delete_one(
            {"_id": ObjectId(task_id), "email": email} 
        )
        
        if result.deleted_count == 0:
            return {"msg": "Task not found or not associated with this user", "code": 404}
        
        return {"msg": "Task deleted successfully", "code": 200}
    
    except Exception as e:
        return {"msg": f"Error deleting task: {e}", "code": 500}
