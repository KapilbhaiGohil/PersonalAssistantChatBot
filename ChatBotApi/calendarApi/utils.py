import datetime
from googleapiclient.discovery import build
from google.oauth2.credentials import Credentials
from google.auth.transport.requests import Request
from googleapiclient.errors import HttpError


def get_calendar_service(access_token):
    creds = Credentials(token=access_token)

    if creds and creds.expired and not creds.refresh_token:
        return {'status': 401, 'message': 'Token expired, re-authentication required.'}

    if creds and creds.expired and creds.refresh_token:
        creds.refresh(Request())

    service = build('calendar', 'v3', credentials=creds)
    return service

def create_event(access_token, summary, description, date, time, end_date=None, end_time=None):
    service = get_calendar_service(access_token)
    print(date)
    print(time)
    start_str = f"{date} {time}"
    print(start_str)
    start_time = datetime.datetime.strptime(start_str, "%Y-%m-%d %H:%M")

    event = {
        'summary': summary,
        'description': description,
        'start': {
            'dateTime': start_time.isoformat(),
            'timeZone': 'UTC',
        },
    }
    if end_date and end_time:
        end_str = f"{end_date} {end_time}"
        end_time = datetime.datetime.strptime(end_str, "%Y-%m-%d %H:%M")
        event['end'] = {
            'dateTime': end_time.isoformat(),
            'timeZone': 'UTC',
        }

    try:
        created_event = service.events().insert(calendarId='primary', body=event).execute()
        return {'status': 200, 'message': 'Event created successfully', 'event_id': created_event['id'], 'event': created_event}
    except HttpError as error:
        return {'status': 400, 'message': f'An error occurred: {error}'}

def get_events(access_token, time_min, time_max):
    service = get_calendar_service(access_token)

    try:
        events_result = service.events().list(
            calendarId='primary',
            timeMin=time_min,
            timeMax=time_max,
            maxResults=10,
            singleEvents=True,
            orderBy='startTime',
        ).execute()

        events = events_result.get('items', [])
        return {'status': 200, 'message': 'Events fetched successfully', 'events': events}
    except HttpError as error:
        return {'status': 400, 'message': f'An error occurred: {error}'}

def update_event(access_token, event_id, summary, location, description, start_time, end_time):
    service = get_calendar_service(access_token)

    event = {
        'summary': summary,
        'location': location,
        'description': description,
        'start': {
            'dateTime': start_time,
            'timeZone': 'UTC',
        },
        'end': {
            'dateTime': end_time,
            'timeZone': 'UTC',
        },
    }

    try:
        updated_event = service.events().update(
            calendarId='primary', eventId=event_id, body=event
        ).execute()
        return {'status': 200, 'message': 'Event updated successfully', 'event_id': updated_event['id'], 'event': updated_event}
    except HttpError as error:
        return {'status': 400, 'message': f'An error occurred: {error}'}

def delete_event(access_token, event_id):
    service = get_calendar_service(access_token)

    try:
        service.events().delete(calendarId='primary', eventId=event_id).execute()
        return {'status': 200, 'message': 'Event deleted successfully'}
    except HttpError as error:
        return {'status': 400, 'message': f'An error occurred: {error}'}
