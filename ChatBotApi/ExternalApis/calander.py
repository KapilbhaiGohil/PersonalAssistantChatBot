from fastapi import FastAPI, Depends
from google.oauth2.credentials import Credentials
from google_auth_oauthlib.flow import InstalledAppFlow
from googleapiclient.discovery import build
from pydantic import BaseModel
import os
import pickle

app = FastAPI()

# The Google API scopes we need access to
SCOPES = ['https://www.googleapis.com/auth/calendar']

# Google Calendar CRUD operations
def get_credentials(token: str):
    """Get the credentials from the token and load the Google Calendar API client"""
    credentials = Credentials.from_authorized_user_info(info=token)
    service = build('calendar', 'v3', credentials=credentials)
    return service

# Models
class CalendarEvent(BaseModel):
    summary: str
    location: str
    description: str
    start: str  # e.g., '2024-12-25T10:00:00Z'
    end: str  # e.g., '2024-12-25T11:00:00Z'

async def create_event(event: CalendarEvent, token: str):
    """Create a new event on the user's Google Calendar."""
    service = get_credentials(token)
    event_data = {
        'summary': event.summary,
        'location': event.location,
        'description': event.description,
        'start': {
            'dateTime': event.start,
            'timeZone': 'UTC',
        },
        'end': {
            'dateTime': event.end,
            'timeZone': 'UTC',
        },
    }
    
    created_event = service.events().insert(calendarId='primary', body=event_data).execute()
    return {"event_id": created_event['id'], "message": "Event created successfully"}

async def update_event(event_id: str, event: CalendarEvent, token: str):
    """Update an existing event on the user's Google Calendar."""
    service = get_credentials(token)
    updated_event_data = {
        'summary': event.summary,
        'location': event.location,
        'description': event.description,
        'start': {
            'dateTime': event.start,
            'timeZone': 'UTC',
        },
        'end': {
            'dateTime': event.end,
            'timeZone': 'UTC',
        },
    }
    
    updated_event = service.events().update(calendarId='primary', eventId=event_id, body=updated_event_data).execute()
    return {"event_id": updated_event['id'], "message": "Event updated successfully"}

async def delete_event(event_id: str, token: str):
    """Delete an event from the user's Google Calendar."""
    service = get_credentials(token)
    service.events().delete(calendarId='primary', eventId=event_id).execute()
    return {"message": "Event deleted successfully"}
