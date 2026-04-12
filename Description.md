
# Project Summary – ChronoPilot

**ChronoPilot** is a smart student-focused scheduling application designed to manage lectures, tasks, and daily activities in a flexible and adaptive way. It supports **one-time events, recurring schedules, and temporary modifications**, making it suitable for dynamic university timetables.

---

## Core Features

### Event Management

* Create, edit, and delete events
* Supports:

    * One-time events
    * Recurring events (e.g., weekly lectures)
    * Temporary events (date-specific overrides or changes)
    * TODO tasks with deadlines or time slots

---

### Schedule Visualization

* Weekly view (primary interface)
* Daily detailed view (hour/minute level)
* Monthly overview (event indicators/dots)
* Conflict detection for overlapping events
* Visual differentiation between:
    * Lectures
    * Tasks
    * Recurring instances
    * Overrides

---

### Smart Notifications

* Time-based reminders (e.g., 30 minutes before)
* Location-aware notifications:

    * Trigger only if user is not near event location
* Future extension: adaptive notification rules

---

### Location Integration

* Assign geographic location to events
* Distance calculation using user’s current position
* Enables context-aware reminders

---

### Media Attachments

* Attach images to events (camera or gallery)
* Used for lecture notes, documents, or references

---

### Authentication

* User registration and login
* Each user has isolated personal schedule
* Future support for cloud sync

---

### External Data Integration

* Optional API integration for:

    * Holidays
    * Academic calendar imports
    * External schedules

---

## System Structure

The application follows a **layered architecture** with clear separation of responsibilities.

---

### 1. Presentation Layer (UI)

* Weekly planner (main screen)
* Daily detailed schedule view
* Monthly overview
* Add/Edit event screens
* Event details view
* Settings / Profile

Includes:

* Custom calendar UI
* Event cards
* Timeline components

---

### 2. State Management Layer

Responsible for:

* Selected date/week state
* Event list state
* UI synchronization
* Real-time updates after changes

Ensures reactive UI behavior across the app.

---

### 3. Data Layer

#### Local Storage (core source)

* Stores all event models
* Handles offline-first functionality
* Manages:
    * Events
    * Recurring definitions
    * Overrides / exceptions
    * TODOs

#### Remote Storage (optional sync)

* User authentication data
* Cloud backup (Firebase / REST API)
* External calendar data

---

### 4. Service Layer

Handles platform and system integrations:

* **Location Service**
    * Fetch user location
    * Calculate distance to event

* **Notification Service**
    * Schedule time-based reminders
    * Trigger location-aware alerts

* **Camera Service**
    * Capture images
    * Attach media to events

---

## System Behavior

1. User authenticates into the app
2. User creates or imports events (lectures, tasks, etc.)
3. Data is stored locally (and optionally synced remotely)
4. On each calendar view load:
    * Recurring events are expanded into occurrences
    * Overrides and exceptions are applied
    * Normal events and TODOs are merged
5. System continuously:
    * Updates UI state
    * Detects conflicts
    * Triggers notifications (time + location-based)
6. Users can dynamically modify schedule (move, edit, override, delete)

---

## Key Characteristics

* Flexible schedule handling for real-world academic changes
* Unified event system (events, lectures, tasks, recurring)
* Context-aware notifications (time + location)
* Offline-first architecture with optional cloud sync
* Strong separation between data, logic, and UI layers
* Conflict-aware scheduling system

---

## Next Steps (Implementation Roadmap)

1. Define final **data models (Event, RecurringEvent, Override, DisplayEvent)**
2. Implement **service layer (Calendar generation logic first)**
3. Build **state management (event stream + calendar state)**
4. Create **basic UI (week + day view first)**
5. Add **authentication**
6. Integrate **location + notifications**
7. Add **camera/media support**
8. Polish UX + conflict handling

---

