
# Project Summary – ChronoPilot

**ChronoPilot** is a smart mobile planner designed for students to manage lectures, tasks, and daily activities in a flexible and dynamic way. The application allows users to create, modify, and organize events, including **one-time, recurring, and temporary events**, making it suitable for constantly changing schedules such as university timetables.

---

## Core Features

The system provides the following functionality:

* **Event Management**

    * Create, edit, delete events
    * Support for:

        * One-time events
        * Recurring events (e.g., weekly lectures)
        * Temporary events (valid only for a specific day)

* **Schedule Visualization**

    * Weekly and daily views
    * Clear display of time slots and overlapping events

* **Smart Notifications**

    * Time-based reminders (e.g., 30 minutes before)
    * Location-aware notifications (triggered only if the user is far from the event location)

* **Media Attachments**

    * Add photos to events using camera or gallery (e.g., lecture notes)

* **Location Integration**

    * Assign locations to events
    * Calculate proximity to upcoming events

* **Authentication**

    * User registration and login
    * Personalized schedules per user

* **External Data Integration**

    * Use of APIs (e.g., holidays, optional calendar imports)

---

## System Structure

The application follows a **layered architecture**, separating responsibilities for better maintainability:

### 1. Presentation Layer (UI)

* Screens:
    * Weekly planner (main view)
    * Daily view
    * Add/Edit event
    * Event details
    * Profile / Settings
* Custom UI components (calendar grid, event cards)

---

### 2. State Management Layer

* Manages:
    * Current selected date/week
    * Event lists
    * UI updates on changes
* Ensures reactive updates across the app

---

### 3. Data Layer

#### Local Storage

* Stores events and user data locally (offline support)
* Handles:
    * Event models
    * Recurring logic
    * Temporary events

#### Remote Services

* Cloud synchronization (e.g., Firebase or REST API)
* User authentication
* Optional external API integration

---

### 4. Service Layer

Handles platform-specific features:

* **Location Service** – retrieves user location and calculates distance
* **Notification Service** – schedules and triggers reminders
* **Camera Service** – captures and attaches images to events

---

## System Behavior

The application operates as follows:

1. User logs into the system
2. User creates or imports events (lectures, tasks, etc.)
3. Events are stored locally and optionally synced to the cloud
4. The system continuously:

    * Updates UI based on state changes
    * Checks upcoming events
    * Triggers notifications (time + location-based)
5. Users can modify schedules dynamically (move, delete, or add temporary events)

---

## Key Characteristics

* **Flexible scheduling** (handles real-life changes in student timetables)
* **Context-aware behavior** (location-based reminders)
* **Offline-first design** with optional cloud sync
* **User-centered design** focused on simplicity and speed
