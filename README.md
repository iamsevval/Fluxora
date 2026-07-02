# 📱 University Community Agenda Mobile App

This project is a **fully native, fully local mobile agenda application with data persistence**, developed to sustainably centralize the internal coordination, committee management, task distribution, and summit organization of university student communities.

To fully comply with academic project criteria, no external cloud service or complex state management library has been used; all data management and business logic are built on a **Flutter & SQLite (`sqflite`)** architecture.

---

## 🚀 Key Advanced Features

### 1. Campus Ambassador (Leadership) Portal
* **Global Overview:** If the logged-in user's role is "Campus Ambassador" or "Campus Ambassador Assistant," a graphical leadership dashboard opens showing the general status of all committees.
* **Graphical Tracking:** Each committee's total task count, completed task count, and percentage-based success rates are tracked live with `LinearProgressIndicator` and custom visual designs.
* **Interactive Filtering:** When a committee summary card on the leadership dashboard is tapped, the system automatically switches to the Tasks tab and filters the relevant committee.
* **Central Task Pool:** An advanced task panel with search and committee filtering where tasks from all committees are listed on a single screen.
<p align="center">
  <img width="229" height="434" alt="2" src="https://github.com/user-attachments/assets/e666f95a-3c45-47a0-bb0b-b62c218fed5a" />
</p>

### 2. Personalized Task Assignment System
* **Dynamic Member List:** A member dropdown list (`DbHelper.getAllUsers()`) that dynamically pulls all members from the SQLite database is integrated into the task adding (`AddEventScreen`) and editing (`EditEventScreen`) screens.
<p align="center">
  <img width="229" height="434" alt="13" src="https://github.com/user-attachments/assets/bbd936fa-22a1-4d65-b338-4eba8f723aa1" />
</p>
* **Visual Assignment Cards:** Who a created task is assigned to (`assignedTo`) is displayed elegantly with profile-icon chips under the task cards.
<p align="center">
  <img width="229" height="434" alt="3" src="https://github.com/user-attachments/assets/ffde2bb7-45a5-4460-b1d1-5c8a145ea536" />
</p>
### 3. Targeted Announcement Distribution System
* **Announcement Management Panel:** The Campus Ambassador can publish and delete rich-content announcements addressed to the entire community ("All Committees") or to a specific committee (e.g., "Sponsorship & Business Development").
* **Personalized Announcement Board:** When committee members enter their own panels, they encounter a horizontal ambassador announcements board at the top of the main screen, showing only current announcements relevant to their own committee or the whole club.

<p align="center">
  <img width="229" height="454" alt="10" src="https://github.com/user-attachments/assets/fd58553e-59db-4635-8d36-328b98c11ab9" />
  <img width="229" height="454" alt="4" src="https://github.com/user-attachments/assets/b0dc8a33-0c3c-4754-be16-4970dd04c447" />
</p>

<p align="center">
  <img width="229" height="454" alt="9" src="https://github.com/user-attachments/assets/8f9c9309-9ff0-4317-9403-4fb87b3ccf49" />
  <img width="229" height="454" alt="6" src="https://github.com/user-attachments/assets/ecccf3cd-1afc-46ef-91b0-adcd798b1790" />
</p>


### 4. Summit & Event Attendance Tracking System (Full CRUD)
* **Multiple Tracking Cards:** Dynamic attendance tracking cards can be created for summits and events.
* **Live Progress Bars:** Occupancy rates and progress bars are automatically calculated when the registered attendee count and target maximum capacity are entered.
* **Strict Validation:** The system prevents the registered attendee count from being negative, exceeding the maximum capacity, or the capacity being entered as zero/negative, and shows the user a SnackBar warning.
* **Event Finished (Delete) Option:** Successfully completed events can be permanently deleted from the editing menu.
<p align="center">
  <img width="229" height="434" alt="7" src="https://github.com/user-attachments/assets/1c1a7ce8-b884-4f3d-9669-f05bf3598c80" />
</p>

### 5. Advanced Committee-Specific Tools
The application includes smart tools designed for the unique needs of each committee:
* **Sponsorship & Business Development:**
  * *Sponsorship Package Calculator:* A CRUD-supported package simulator that dynamically calculates prices based on budget limits, social media posts, booth areas, and logo placements.
  * *Brand Negotiation List:* Data cards tracking the negotiation status of potential sponsor companies.
<p align="center">
    <img width="229" height="434" alt="9" src="https://github.com/user-attachments/assets/395ef1ff-dea5-4637-9463-1096cca4682f" />
</p>
* **Digital Media & Design:**
  * *Reels Draft Scoring Engine:* A smart algorithm that scores the viral potential (Viral Score) of Reels videos based on trending music usage, video duration, and hook strength.
  * *Weekly Content Calendar:* Status cards for visuals to be shared by day.
<p align="center">
 <img width="229" height="434" alt="11" src="https://github.com/user-attachments/assets/581dae32-7044-4f42-b012-8d4db2cdd992" />
</p>
* **Medium & YouTube (Publishing):**
  * *Live Stream Question Pool:* An interactive pool that compiles questions to be asked to stream guests by priority order and marks them as asked.
  * *YouTube Countdown Timer:* A timer engine that counts down live, second by second, to the planned live stream time.
<p align="center">
    <img width="229" height="434" alt="5" src="https://github.com/user-attachments/assets/f36f4bce-ce16-4b8c-acb3-73f2d69e37b2" />
</p>
* **Event & Organization:**
  * *Summit Duty Matrix:* A duty matrix showing which time slot and area (Welcoming, Sound, Backstage, etc.) each team member is on duty for on the day of the event.
  * *Organization Needs:* An event supplies and checklist management card.
<p align="center">
<img width="229" height="434" alt="8" src="https://github.com/user-attachments/assets/0acb4843-3793-4035-802d-02a4a8659f4a" />
</p>


---

## 🛠️ Technical Infrastructure and Data Persistence

### 📂 1. Project Architecture and File Structure
The application has a modular structure in line with Clean Architecture principles, in accordance with Flutter development standards. To make the code more readable and maintainable, data models, the database layer, and the user interface (UI) are completely separated from one another.

    lib/
    │
    ├── main.dart                      # Application entry point (Login check and Theme loading)
    │
    ├── database/
    │   └── db_helper.dart             # SQLite database connection, schema setup, and CRUD methods
    │
    ├── models/                        # Dart data models for SQLite tables (Serialization)
    │   ├── announcement_model.dart    # Announcement data model
    │   ├── committee_item_model.dart  # General committee tools model (Brand, summit capacity, etc.)
    │   ├── event_duty_model.dart      # Duty matrix (Time/Zone distribution) model
    │   ├── event_model.dart           # Task/Event data model
    │   ├── reels_draft_model.dart     # Reels video draft and viral score model
    │   ├── sponsorship_package_model.dart # Sponsorship package data model
    │   ├── stream_question_model.dart # Live stream question pool model
    │   └── user_model.dart            # User and role model
    │
    └── screens/                       # Interface (Visual Design) screens
        ├── splash_screen.dart         # Welcome and routing screen
        ├── login_screen.dart          # User login screen (SQLite-validated)
        ├── register_screen.dart       # New member registration screen (SQLite-integrated)
        ├── home_screen.dart           # Main screen (Leadership dashboard, committee tabs, and dedicated tools)
        ├── committee_selection_screen.dart # Committee selection and routing screen after first login
        ├── add_event_screen.dart      # New task adding screen with SQLite dynamic member selection
        └── edit_event_screen.dart     # Task editing and deletion screen with SQLite dynamic member selection

### 🗄️ 2. SQLite Database Architecture (`db_helper.dart`)
The heart of the application is formed by the SQLite-based `DbHelper` class. This class is written using the **Singleton Design Pattern**. This ensures that a single connection channel to the database is opened throughout the application, preventing unnecessary memory consumption and database locking issues.

#### Database Table Schemas

| Table Name | Purpose / Columns | Critical Details |
| :--- | :--- | :--- |
| **`users`** | `id`, `fullName`, `username` (UNIQUE), `password`, `primaryCommittee`, `isNewUser` | User authentication and onboarding status. |
| **`events`** | `id`, `title`, `date`, `location`, `description`, `committee`, `isCompleted`, `assignedTo` | Intra-committee tasks. Dynamically assigned to a member in the `users` table via the `assignedTo` column. |
| **`announcements`** | `id`, `title`, `content`, `date`, `targetCommittee`, `isCompleted` | Announcements published by the Campus Ambassador. |
| **`committee_items`** | `id`, `committee`, `type`, `title`, `subtitle`, `statusColor`, `isDone` | Committee-specific dynamic data tracking (Brand negotiations, budget tracking, summit occupancy status). |
| **`sponsorship_packages`**| `id`, `packageName`, `budgetLimit`, `socialMediaPosts`, `logoBanner`, `standArea`, `totalPrice` | CRUD data for the Sponsorship Package Calculator. |
| **`reels_drafts`** | `id`, `concept`, `duration`, `isTrendingMusic`, `hookStrength`, `calculatedViralScore`, `recommendations` | Video data saved by the Reels Draft Engine and the calculated viral scores. |
| **`stream_questions`** | `id`, `guestName`, `questioner`, `questionText`, `isAsked`, `priority` | Live stream question pool data. |
| **`event_duties`** | `id`, `staffName`, `dutyZone`, `timeSlot`, `status` | Team duties in the summit duty matrix. |
| **`app_settings`** | `id` (PRIMARY KEY 1), `isDarkMode` (0 or 1), `themeColor` | SQLite-backed persistent theme settings. |

#### Database Lifecycle Methods
- **`initDb()`:** Creates the database file (`topluluk_v14.db`) in device storage or connects to the existing file.
- **`onCreate()`:** When the database is created for the first time, sets up the 9 tables above with SQL queries and adds Seed Data (default user `elci`, sample announcements, duty matrix, draft reels, etc.). When the instructor opens the app for the first time, they don't see an empty screen but a system that is already populated and working.
- **`onUpgrade()`:** Updates the schema without losing data in case an update or column addition is needed in the database schema in the future.

---

## 🔑 Quick Start & Test Accounts

Default users and sample records have been automatically seeded into the database so the application can be tested in a fully populated and working state:

| Role | Username | Password | Access Rights |
| :--- | :--- | :--- | :--- |
| **Campus Ambassador (Leader)** | `elci` | `elci12345` | Global Leadership Portal, Announcement Publishing, All Tasks |
| **Digital Media & Design** | `tasarim_uyesi1` | `1tasarim123` | Design Tools and Reels Drafts Panel |
| **Medium & YouTube** | `medium_uyesi1` | `1medium123` | Publishing and Live Stream Questions Pool |
| **Sponsorship & Business Development** | `sponsorluk_uyesi` | `1sponsorluk123` | Sponsorship Package Calculator and Brand Negotiations |
| **Event & Organization** | `etkinlik_uyesi` | `1etkinlik123` | Summit Duty Matrix and Organization Management |
<p align="center">
<img width="229" height="434" alt="1" src="https://github.com/user-attachments/assets/efcceafb-0b35-43ea-b88f-d6d865212777" />
</p>
---

## 💻 Installation and Running

### Requirements
- Flutter SDK (v3.0.0 or higher)
- Android Studio / VS Code
- Android or iOS Simulator, or a physical test device

### Running Steps
1. Navigate to the project directory:

       cd Fluxora

2. Install dependencies:

       flutter pub get

3. Start the application:

       flutter run

### Running Tests
You can run the unit tests prepared to test the regex data validation logic in the application:

    flutter test

---

## 🎨 Design Aesthetics and User Experience
- **Theme Integration:** SQLite-backed persistent Dark Mode / Light Mode switching.
- **Color Palettes:** Premium and dynamic committee themes defined in unique HSL tones for each committee.
- **Ergonomics:** Related data-adding buttons have been moved directly next to their associated widget titles (e.g., next to the "Organization Needs" and "Attendance Tracking" titles) to reduce clutter across the page and increase intuitiveness.
