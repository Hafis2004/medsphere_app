# Firebase configuration notes

## Authentication
- Enable Email/Password sign-in in Firebase Authentication.

## Firestore
- Create a Firestore database in production mode.
- Add the following sample documents:

### appointments
```json
{
  "id": "apt_001",
  "patient": {
    "id": "PT1001",
    "name": "John Smith",
    "age": 29,
    "phone": "9876543210"
  },
  "appointmentTime": "2026-07-11T10:30:00.000Z",
  "status": "Unconfirmed",
  "notes": "Follow-up consultation"
}
```

### session_notes
```json
{
  "id": "note_001",
  "title": "Initial Assessment",
  "description": "Patient reported mild headaches and fatigue.",
  "createdAt": "2026-07-10T09:00:00.000Z"
}
```

## WebRTC signaling
- A real signaling implementation should use Firestore to exchange SDP offers/answers and ICE candidates between peers.
- The current app uses local media streams for the UI and call controls.
