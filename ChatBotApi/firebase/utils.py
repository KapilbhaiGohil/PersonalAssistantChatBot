import firebase_admin
from firebase_admin import credentials, firestore, auth
from pydantic import BaseModel

# Initialize Firebase
cred = credentials.Certificate('firebase/firebase-cred.json')
firebase_admin.initialize_app(cred)

db = firestore.client()

# Firebase Firestore collections
TASK_COLLECTION = "tasks"

# Insert a task
async def insertTask(email: str, task: str):
    if not email or not task:
        return {"msg": "Email and task are required", "code": 400}
    
    try:
        task_ref = db.collection(TASK_COLLECTION).document()
        task_data = {"email": email, "task": task}
        task_ref.set(task_data)
        return {"msg": "Task inserted successfully", "code": 200, "task_id": task_ref.id}
    except Exception as e:
        return {"msg": f"Error inserting task: {e}", "code": 500}

# Retrieve all tasks
async def retriveAllTask(email: str):
    if not email:
        return {"msg": "Email is required", "code": 400}
    
    try:
        tasks = db.collection(TASK_COLLECTION).where("email", "==", email).stream()
        task_list = [{"id": task.id, "task": task.to_dict()['task']} for task in tasks]
        
        if not task_list:
            return {"msg": "No tasks found for this user", "code": 404}
        
        return {"msg": "Tasks retrieved successfully", "code": 200, "data": task_list}
    except Exception as e:
        return {"msg": f"Error retrieving tasks: {e}", "code": 500}

# Update a task
async def updateTask(task_id: str, new_task: str):
    if not task_id or not new_task:
        return {"msg": "Task ID and new task content are required", "code": 400}
    
    try:
        task_ref = db.collection(TASK_COLLECTION).document(task_id)
        task_ref.update({"task": new_task})
        return {"msg": "Task updated successfully", "code": 200}
    except Exception as e:
        return {"msg": f"Error updating task: {e}", "code": 500}

# Delete a task
async def deleteTask(task_id: str):
    if not task_id:
        return {"msg": "Task ID is required", "code": 400}
    
    try:
        task_ref = db.collection(TASK_COLLECTION).document(task_id)
        task_ref.delete()
        return {"msg": "Task deleted successfully", "code": 200}
    except Exception as e:
        return {"msg": f"Error deleting task: {e}", "code": 500}
