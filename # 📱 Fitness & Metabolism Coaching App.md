# 📱 Fitness & Metabolism Coaching App

## 📊 Flowchart + Developer Documentation

---

# 🎨 UI THEME (Also can use other colors accodingly)

* **Background:** Light Black (#121212)
* **Cards / Boxes:** Greyish Black (#1E1E1E)
* **Primary Color:** Blue (#2979FF)
* **Secondary Accent:** Light Purple (#9C7BFF)
* **Text:** White (#FFFFFF)
* **Icons:** Minimal line icons (white / blue highlights)
* **Style:** Modern, clean, card-based UI
* ❌ No Sidebar (Use Top + Bottom Navigation only(main routes shown in bottom))

---

# 🔁 COMPLETE APP FLOW (FLOWCHART)

```
                ┌──────────────┐
                │   START APP  │
                └──────┬───────┘
                       │
         ┌─────────────▼─────────────┐
         │ Authentication (AllAuth)  │
         │ Google / FB / Apple / OTP │
         └─────────────┬─────────────┘
                       │
              ┌────────▼────────┐
              │ Select Category │
              │ (Multi Select)  │
              └────────┬────────┘
                       │
              ┌────────▼────────┐
              │ Show Trainers   │
              │ (Filtered)      │
              └────────┬────────┘
                       │
              ┌────────▼────────┐
              │ Select Trainer  │
              └────────┬────────┘
                       │
              ┌────────▼────────┐
              │ Client Dashboard│
              └─────────────────┘

ADMIN FLOW:
Admin Login → Dashboard → Manage Trainers → Manage Clients → Create Master Data
(Diet / Workout / Exercise / Videos)

TRAINER FLOW:
Trainer Login → Dashboard → View Assigned Clients → Assign Master Plans

CLIENT FLOW:
Client Login → Dashboard → View Assigned Plans → Daily Goals → Videos
```

---

# 🧩 SYSTEM ARCHITECTURE

## 3 ROLES

### 1. 👑 ADMIN (MASTER CONTROL)

**Capabilities:**

* Create Trainers
* Create Clients
* Manage Users
* Create MASTER:

  * Diet Plans
  * Workouts
  * Exercises
  * Videos
* Assign content globally

**Restrictions:**

* Only admin can CREATE & EDIT content

---

### 2. 🧑‍🏫 TRAINER

**Capabilities:**

* View assigned clients
* Categorize clients:

  * Weight Loss
  * Weight Gain
  * Diabetes
  * etc.
* Assign plans to clients

**Restrictions:**

* ❌ Cannot create workout/diet
* ❌ Cannot edit master data
* ✅ Only SELECT & ASSIGN from admin data

---

### 3. 🧑 CLIENT

**Flow:**

1. Signup (AllAuth)
2. Select Fitness Goals (Multi-select)
3. Choose Trainer
4. Account Activated

**Capabilities:**

* View:

  * Daily Goals
  * Diet Plans
  * Workouts
  * Videos
* Track progress

---

# 📱 UI STRUCTURE (NO SIDEBAR)

## 🔐 AUTH SCREEN

* Logo
* Social Login Buttons
* Email / OTP
* Primary Button (Blue)

---

## 🏠 DASHBOARD (COMMON UI)

```
--------------------------------
| Greeting + Profile Icon       |
--------------------------------
| [ Card: Today's Goal ]        |
| [ Card: Diet Plan ]           |
| [ Card: Workout ]             |
| [ Card: Videos ]              |
--------------------------------
| Bottom Nav: Home | Plans | Videos | Profile |
--------------------------------
```

---

## 👑 ADMIN DASHBOARD UI

* Stats Cards (Users, Trainers, Clients)
* Action Buttons:

  * Add Trainer
  * Add Client
  * Create Diet Plan
  * Create Workout

---

## 🧑‍🏫 TRAINER DASHBOARD UI

* Client Categories (Cards):

  * Weight Loss (3)
  * Weight Gain (5)
  * Diabetes (10)

* Actions:

  * Assign Plan
  * View Client Progress

---

## 🧑 CLIENT DASHBOARD UI

* Today's Goal (Top Card)
* Calories / Tasks
* Buttons:

  * Start Workout
  * View Diet
  * Watch Video

---

# 📦 DATA FLOW LOGIC

## ADMIN → TRAINER

* Admin creates MASTER DATA
* Trainer FETCHES data
* Trainer ASSIGNS to clients

## TRAINER → CLIENT

* Trainer links plans
* Client consumes content

---


# 🎯 KEY RULES

* Only ADMIN creates content
* TRAINER only assigns
* CLIENT only views
* Category-based filtering everywhere

---

# 🎨 UI EXPERIENCE NOTES

* Use cards (rounded + shadow)
* Use icons for each feature
* Smooth animations
* Keep screens minimal
* Highlight CTA buttons (Blue)

---

# ✅ FINAL SUMMARY

This system ensures:

* Clear role separation
* Secure content control
* Scalable architecture
* Clean modern UI

---
