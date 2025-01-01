import json
import requests
from datetime import datetime

def create_google_calendar_event(access_token, summary, description, start_time, end_time):
    try:
        if not access_token:
            print('Failed to get access token')
            return {'success': False, 'message': 'Failed to get access token'}

        event = {
            'summary': summary,
            'description': description,
            'start': {
                'dateTime': start_time.isoformat(),
                'timeZone': 'UTC',
            },
            'end': {
                'dateTime': end_time.isoformat(),
                'timeZone': 'UTC',
            },
        }

        headers = {
            'Authorization': f'Bearer {access_token}',
            'Content-Type': 'application/json',
        }

        response = requests.post(
            'https://www.googleapis.com/calendar/v3/calendars/primary/events',
            headers=headers,
            data=json.dumps(event),
        )

        if response.status_code == 200:
            event_data = response.json()  # Parse the response JSON
            print('Event created successfully')
            return {
                'success': True,
                'message': 'Event created successfully',
                'event_id': event_data.get('id'),
                'summary': event_data.get('summary'),
                'description': event_data.get('description'),
                'start_time': event_data['start']['dateTime'],
                'end_time': event_data['end']['dateTime'],
                'event_data': event_data
            }
        else:
            print(f'Failed to create event: {response.status_code}')
            print(response.text)
            return {
                'success': False,
                'message': f'Failed to create event: {response.status_code}',
                'response': response.text
            }
    except Exception as e:
        print(f'Error creating Google Calendar event: {e}')
        return {
            'success': False,
            'message': f'Error creating event: {e}'
        }
