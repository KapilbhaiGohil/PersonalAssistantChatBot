from datetime import datetime
from fastapi import HTTPException, Depends
from fastapi.responses import JSONResponse
from google.auth.transport.requests import Request
from google.oauth2.credentials import Credentials
from googleapiclient.discovery import build
from pydantic import BaseModel
from typing import Optional
import json

def get_calendar_service(access_token):
    try:
        print('inside get calendar service-1')
        # with open('calendar/client-cred.json', 'r') as file:
        #     client_credentials = json.load(file)
        print('inside get calendar service')
        
        if isinstance(access_token, str):
            access_token_info = {
                'access_token': access_token,
                'client_id': '1092023347215-5dva20stdv2ip00p15j5airaj91p8s05.apps.googleusercontent.com',
                'client_secret': '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',
            }
        else:
            access_token_info = access_token  
        print(access_token_info)
        credentials = Credentials.from_authorized_user_info(info=access_token_info)

        if credentials.expired and credentials.refresh_token:
            credentials.refresh(Request())

        service = build('calendar', 'v3', credentials=credentials)
        return service

    except Exception as e:
        raise HTTPException(status_code=400, detail=f"Error with credentials: {str(e)}")

class Event(BaseModel):
    summary: str
    description: Optional[str] = None
    location: Optional[str] = None
    start: dict  
    end: Optional[dict] = None  

async def create_event(access_token: str, event: dict):
    try:
        print('inside create event ')
        service = await get_calendar_service(access_token)
        summary = event.get("summary", "No Title")
        description = event.get("desc", "No description")
        start_time_str = event.get("payload", {}).get("date") + "T" + event.get("payload", {}).get("time") + ":00"
        start_time = datetime.strptime(start_time_str, "%Y-%m-%dT%H:%M:%S")

        event_body = {
            "summary": summary,
            "description": description,
            "start": {
                "dateTime": start_time.isoformat(),
                "timeZone": "Asia/Kolkata",  # Set to IST (Indian Standard Time)
            },
        }

        end_time = event.get("endTime")
        if end_time:
            end_time_str = event.get("payload", {}).get("date") + "T" + end_time + ":00"
            end_time = datetime.strptime(end_time_str, "%Y-%m-%dT%H:%M:%S")
            event_body["end"] = {
                "dateTime": end_time.isoformat(),
                "timeZone": "Asia/Kolkata",  # Set to IST (Indian Standard Time)
            }
        print("This is insider create event in calander")
        created_event = service.events().insert(calendarId='primary', body=event_body).execute()

        return JSONResponse(status_code=201, content={"message": "Event created", "event": created_event})

    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error creating event: {str(e)}")