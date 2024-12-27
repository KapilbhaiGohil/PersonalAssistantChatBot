from pymongo import MongoClient
from pydantic import BaseModel
from bson import ObjectId
from typing import List, Dict, Any

# Initialize MongoDB client
client = MongoClient('mongodb://localhost:27017/') 
db = client['ChatBot']
tasks_collection = db['Tasks']

# Insert a task
async def insertTask(email: str, task: str) -> Dict[str, Any]:
    if not email or not task:
        return {"msg": "Email and task are required", "code": 400}
    
    try:
        task_data = {"email": email, "task": task}
        result = tasks_collection.insert_one(task_data)
        return {"msg": "Task inserted successfully", "code": 200, "task_id": str(result.inserted_id)}
    except Exception as e:
        return {"msg": f"Error inserting task: {e}", "code": 500}

# Retrieve all tasks
async def retriveAllTask(email: str) -> Dict[str, Any]:
    if not email:
        return {"msg": "Email is required", "code": 400}
    
    try:
        tasks = tasks_collection.find({"email": email})
        task_list = [{"id": str(task["_id"]), "task": task["task"]} for task in tasks]
        
        if not task_list:
            return {"msg": "No tasks found for this user", "code": 404}
        
        return {"msg": "Tasks retrieved successfully", "code": 200, "data": task_list}
    except Exception as e:
        return {"msg": f"Error retrieving tasks: {e}", "code": 500}

# Update a task
async def updateTask(task_id: str, new_task: str) -> Dict[str, Any]:
    if not task_id or not new_task:
        return {"msg": "Task ID and new task content are required", "code": 400}
    
    try:
        result = tasks_collection.update_one(
            {"_id": ObjectId(task_id)},
            {"$set": {"task": new_task}}
        )
        
        if result.matched_count == 0:
            return {"msg": "Task not found", "code": 404}
        
        return {"msg": "Task updated successfully", "code": 200}
    except Exception as e:
        return {"msg": f"Error updating task: {e}", "code": 500}

# Delete a task
async def deleteTask(task_id: str) -> Dict[str, Any]:
    if not task_id:
        return {"msg": "Task ID is required", "code": 400}
    try:
        print(task_id)
        result = tasks_collection.delete_one({"_id": ObjectId(task_id)})
        if result.deleted_count == 0:
            return {"msg": "Task not found", "code": 404}
        
        return {"msg": "Task deleted successfully", "code": 200}
    except Exception as e:
        return {"msg": f"Error deleting task: {e}", "code": 500}
