import json
import requests
from datetime import datetime
import pytz

from datetime import datetime, timedelta
import pytz
import json
import requests

def create_google_calendar_event(access_token, summary, description, start_date, start_time, end_date=None, end_time=None):
    try:
        if not access_token:
            print('Failed to get access token')
            return {'success': False, 'message': 'Failed to get access token'}
        
        start_str = f"{start_date}T{start_time}:00"
        start_time_obj = datetime.strptime(start_str, '%Y-%m-%dT%H:%M:%S')
        
        india_tz = pytz.timezone('UTC')

        # Localize the start time to IST
        start_time_obj = india_tz.localize(start_time_obj) if start_time_obj.tzinfo is None else start_time_obj.astimezone(india_tz)
        print(start_time_obj)

        # Default event object
        event = {
            'summary': summary,
            'description': description,
            'start': {
                'dateTime': start_time_obj.isoformat(),
                'timeZone': 'Asia/Kolkata', 
            },
        }

        # If end date and time are not provided, set the end time as 1 hour after start time
        if not end_date or not end_time:
            end_time_obj = start_time_obj + timedelta(hours=1)
        else:
            end_str = f"{end_date}T{end_time}:00"
            end_time_obj = datetime.strptime(end_str, '%Y-%m-%dT%H:%M:%S')

            # Localize the end time to IST
            end_time_obj = india_tz.localize(end_time_obj) if end_time_obj.tzinfo is None else end_time_obj.astimezone(india_tz)

        # Add the end time to the event if present
        event['end'] = {
            'dateTime': end_time_obj.isoformat(),
            'timeZone': 'Asia/Kolkata',  
        }

        headers = {
            'Authorization': f'Bearer {access_token}',
            'Content-Type': 'application/json',
        }

        # Send request to Google Calendar API to create the event
        response = requests.post(
            'https://www.googleapis.com/calendar/v3/calendars/primary/events',
            headers=headers,
            data=json.dumps(event),
        )
        
        if response.status_code == 200:
            event_data = response.json()
            print('Event created successfully')
            print(event_data)
            return {
                'success': True,
                'id': event_data.get('id'),
                'summary': event_data.get('summary'),
                'description': event_data.get('description'),
                'start_time': event_data['start']['dateTime'],
                'end_time': event_data.get('end', {}).get('dateTime', None),
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



# def create_google_calendar_task(access_token, summary, description, due_date=None, due_time=None):
#     try:
#         if not access_token:
#             print('Failed to get access token')
#             return {'success': False, 'message': 'Failed to get access token'}

#         task = {
#             'summary': summary,
#             'description': description,
#         }

#         if due_date:
#             due_date_obj = datetime.strptime(due_date, '%Y-%m-%d')
#             india_tz = pytz.timezone('Asia/Kolkata')
#             due_date_obj = india_tz.localize(due_date_obj)

#             if due_time:
#                 due_time_obj = datetime.strptime(due_time, '%H:%M')
#                 due_date_obj = due_date_obj.replace(hour=due_time_obj.hour, minute=due_time_obj.minute, second=0)

#             task['due'] = due_date_obj.isoformat()

#         headers = {
#             'Authorization': f'Bearer {access_token}',
#             'Content-Type': 'application/json',
#         }

#         response = requests.post(
#             'https://www.googleapis.com/tasks/v1/lists/@default/tasks',
#             headers=headers,
#             data=json.dumps(task),
#         )

#         if response.status_code == 200:
#             task_data = response.json()  
#             print('Task created successfully')
#             return {
#                 'success': True,
#                 'message': 'Task created successfully',
#                 'task_id': task_data.get('id'),
#                 'summary': task_data.get('summary'),
#                 'description': task_data.get('description'),
#                 'due_date': task_data.get('due'),
#                 'task_data': task_data
#             }
#         else:
#             print(f'Failed to create task: {response.status_code}')
#             print(response.text)
#             return {
#                 'success': False,
#                 'message': f'Failed to create task: {response.status_code}',
#                 'response': response.text
#             }
#     except Exception as e:
#         print(f'Error creating Google Calendar task: {e}')
#         return {
#             'success': False,
#             'message': f'Error creating task: {e}'
#         }