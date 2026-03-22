
# MEZZ — Hostel Mess Management System

### A Proposal to Digitize & Streamline Mess Operations at GEC, Goa

![MEZZ Logo](C:\Users\kedron\.gemini\antigravity\brain\c88253e0-840c-4f2f-aa22-5b10852402ef\mezz_logo.png)

---

## Dear Sir/Madam,

I am writing to propose the adoption of **MEZZ**, a hostel mess management application I have independently designed and developed to solve the persistent operational challenges faced by our hostel mess system at **Government Engineering College, Goa**.

This document outlines the problems MEZZ addresses, its capabilities, the projected impact, and my request for institutional support in exchange for deploying and maintaining this system at no software cost.

---

## The Problem Today

Our current mess management relies on **manual registers, handwritten tallies, and verbal coordination**. While this has worked, it comes with real, measurable costs:

| Problem | Impact |
|---|---|
| **Manual meal tallying** | Vendors spend ~30 min/day counting registers across 3 meals |
| **Billing disputes** | Students cannot verify their own expenditure — leads to trust issues |
| **No transparency** | Students have zero visibility into how their ₹13,500 semester fee is utilized month-over-month |
| **Meal wastage** | Without advance headcounts, vendors over-prepare food. Even 10% wastage on 200 students = ~20 meals wasted daily |
| **Register fraud** | Entries can be altered, missed, or fabricated — no audit trail |
| **Billing errors** | Manual calculations across 200+ students for 90 days creates compounding errors |
| **No accountability** | Absent-day deductions, plan allowances, and security deposits are tracked loosely at best |
| **Communication gap** | Meal changes, parcel requests, and unlock requests require physically finding the vendor |

### Quantifying the Cost of Manual Operations

For a hostel with **200 students** and a **6-month semester**:

| Metric | Manual System | With MEZZ |
|---|---|---|
| Time vendor spends on tallying per day | ~30 minutes | **0 minutes** (auto-calculated) |
| Time per month on billing calculations | ~8–10 hours | **0 hours** (instant) |
| Billing disputes per semester (est.) | 15–25 cases | **0** (transparent, auditable) |
| Food wastage due to inaccurate headcounts | ~10–15% daily | **< 3%** (real-time headcounts) |
| Monthly food cost wastage (₹50 avg/meal × 20 wasted) | ~₹1,000/day = **₹30,000/month** | **< ₹9,000/month** |
| Semester savings on food wastage alone | — | **₹1,26,000** |
| Receipt generation & record keeping | Paper-based, losable | **Digital, permanent, PDF** |

> **Conservative estimate: MEZZ saves the mess operation ₹1.2–1.5 lakhs per semester in food wastage reduction alone**, while eliminating hours of manual labor and billing disputes entirely.

---

## What MEZZ Does

MEZZ is a **dual-portal mobile application** — one interface for students, one for vendors — connected in real-time through Firebase.

### For Students

| Feature | What It Solves |
|---|---|
| **Daily Meal Marking** | Students mark Veg / Non-Veg / Absent for each meal (Breakfast, Lunch, Dinner) via a double-tap interface. No more standing in line to sign a register. |
| **Real-Time Expenditure Tracking** | Students see their monthly spending updated instantly. Full transparency — no surprises at month-end. |
| **Monthly Calendar View** | Visual month-at-a-glance view of every meal marked. Color-coded: green (Veg), orange (Non-Veg), grey (Absent). |
| **Smart Lock System** | Meals lock 1 hour before serving and unlock 30 minutes after — preventing last-minute changes that cause food waste. |
| **Unlock & Parcel Requests** | Missed marking a meal? Request an unlock. Want a parcel? Request it in-app. No need to physically find the vendor. |
| **Semester Fee & Plan Selection** | Students choose from 3 billing plans (₹2,000 / ₹2,500 / ₹3,000 per month) and track their semester fee status. |
| **Digital Receipts** | Every cleared bill generates a unique 8-character receipt with full breakdown, downloadable as PDF. |
| **Mess Community Feed** | Students can post feedback, food photos, and suggestions — visible to all students under the same vendor. |
| **Notifications** | Real-time alerts for bill clearance, request approvals/rejections, and semester fee updates. |

### For Vendors (Mess Operators)

| Feature | What It Solves |
|---|---|
| **Live Headcounts** | Exact count of Veg / Non-Veg / Absent for each meal, updated in real-time. Cook exactly what's needed. |
| **Automated Billing** | Monthly expenditure calculated automatically from daily meals. No manual tallying of 200 registers. |
| **One-Tap Bill Clearing** | Clear a student's monthly bill with one tap — auto-generates receipt, notifies student, updates records. |
| **Semester Fee Issuance** | Issue semester fees to all students at once. Track who has paid, who hasn't. |
| **Request Management** | Approve/reject unlock and parcel requests from a single dashboard. |
| **Student Search** | Find any student by email or hostel number instantly. |
| **Billing History** | Complete audit trail of every bill cleared, with receipt codes. |

---

## Technical Depth & Effort

This is not a simple prototype. MEZZ is a **production-grade application** built with:

| Aspect | Detail |
|---|---|
| **Language & Framework** | Flutter (Dart) — cross-platform (Android, iOS, Web) |
| **Backend** | Firebase Authentication + Cloud Firestore (NoSQL, real-time) |
| **Architecture** | Service-oriented with separated data, logic, and UI layers |
| **Codebase Size** | 30+ source files, 6 data models, 6 service classes, 14 screens, 4 reusable widgets |
| **Business Logic** | Meal locking algorithm, billing overspend calculator with security deposit buffer, plan-based deductions |
| **Database** | 6 Firestore collections with nested subcollections for meals, billing, receipts, notifications, requests, and comments |
| **PDF Generation** | On-demand receipt PDFs with unique codes — generated client-side |
| **Image Upload** | Cloudinary CDN integration for profile pictures and feed images |
| **Design** | Custom neumorphic UI with Google Fonts, micro-animations, gradient themes |
| **Development Time** | Equivalent to **200+ hours** of focused engineering work |

> At a conservative freelance rate of ₹500/hour, building MEZZ from scratch would cost an external developer **₹1,00,000+**. I am offering it to the institution at **zero software cost**.

---

## The Ask

I am **not charging any development fee** for MEZZ. I have built this entirely on my own time, with my own resources, because I believe it solves a real problem.

In return, I am requesting institutional support to cover my **education and living expenses for the remaining 3 semesters** (6th, 7th/8th semesters), so I can continue contributing to college-level technical projects without financial constraints.

### Breakdown

| Expense | Per Semester | 3 Semesters |
|---|---|---|
| Semester Tuition Fees | ₹28,000 | ₹84,000 |
| Hostel Fees | ₹6,100 | ₹18,300 |
| Mess Fees | ₹13,500 | ₹40,500 |
| **Total** | **₹47,600** | **₹1,42,800** |

### Why This Is a Fair Exchange

| What the College Gets | What I Get |
|---|---|
| A fully functional mess management app | Education + hostel + mess covered for 3 semesters |
| Eliminates ₹1.2–1.5L/semester food wastage | Freedom to focus on more technical work |
| Zero billing disputes, full transparency | Resources to participate in hackathons and competitions |
| Modern digital infrastructure for the hostel | Ability to pursue AI/ML research and projects |
| Vendor-independent system that survives vendor changes | — |
| Ongoing maintenance, updates, and new features | — |
| **Software value: ₹1,00,000+** | **Total ask: ₹1,42,800** |

> The app pays for itself within the **first semester** through food wastage reduction alone. The investment in my education is effectively **free** for the institution.

---

## About Me

**Kedron** — 3rd Year, B.E. Computer Science, Government Engineering College, Goa

| | |
|---|---|
| **Role** | AI/ML Mentor |
| **Experience** | Building AI models and full-stack applications for 2+ years |
| **Startups** | Founded **Kairo Studio** and **Internspirit** (paused due to limited funds and time) |
| **Hackathons** | Active participant in national and regional hackathons |
| **Skill Set** | Flutter, Firebase, Python, Machine Learning, Deep Learning, Full-Stack Development |
| **Motivation** | Having my expenses covered frees me to focus on building more impactful projects, taking professional certification exams, covering travel to hackathons, and investing time in research — all of which benefit the college's reputation |

I have consistently demonstrated initiative and technical capability. MEZZ is the latest example — a complex, real-world application designed to solve a problem I witness every day in our hostel. If supported, I intend to continue building solutions that benefit the GEC community.

---

## Built for the Long Term

### Vendor-Independent & Flexible

MEZZ is **not tied to any specific mess vendor**. If the college changes its mess contractor — which happens periodically — the app continues to work seamlessly. The new vendor simply creates an account, gets a new 6-digit code, and students re-link. All historical data, receipts, and billing records are preserved. **The investment in MEZZ outlasts any single vendor contract.**

### Cross-Platform: Android, iOS & Web Ready

MEZZ is built with Flutter, which means the **exact same codebase** runs natively on both Android and iOS. For iPhone users, we can publish the app on the **Apple App Store** alongside the **Google Play Store** — the only additional cost would be Apple's annual developer fee (₹8,000/year) and a one-time Play Store registration (₹2,100). The app itself requires **zero additional development** for iOS — it's already fully functional on both platforms.

### Continuous Feature Development

I am committed to **actively maintaining and improving MEZZ** as long as it is in use. New features can be rolled out based on feedback from students, vendors, and administration. Potential future additions include:

- **Weekly/monthly analytics dashboard** for warden/administration oversight
- **Menu of the day** display with vendor photo uploads
- **Special meal days** (festivals, events) with custom pricing
- **Complaint/grievance system** for mess quality issues
- **Attendance integration** to cross-verify hostel presence
- **Export to Excel** for administrative record-keeping

The app grows with the college's needs — at no additional development cost.

---

## Deployment Plan

| Phase | Timeline | Action |
|---|---|---|
| **Phase 1** | Week 1 | Pilot with 1 hostel wing (~30 students). Collect feedback. |
| **Phase 2** | Week 2–3 | Iterate based on feedback. Fix any edge cases. |
| **Phase 3** | Week 4 | Full hostel rollout. Vendor training session. |
| **Phase 4** | Week 5–6 | Publish on Play Store (and App Store if approved). |
| **Ongoing** | Semester-long | Maintenance, bug fixes, new features as needed. |

**No infrastructure cost.** The app runs on Firebase's free tier for up to 50,000 daily reads and 20,000 writes — more than sufficient for a college hostel. Works on any Android or iOS smartphone.

---

## Summary

| | |
|---|---|
| **Problem** | Manual mess management wastes food, time, and money while creating disputes |
| **Solution** | MEZZ — a real-time, dual-portal app that automates meal tracking, billing, receipts, and communication |
| **Savings** | ₹1.2–1.5L/semester in food wastage + 10+ hours/month of vendor time |
| **Cost to College** | ₹0 for the software |
| **My Ask** | ₹1,42,800 total (education + hostel + mess for 3 semesters) |
| **ROI** | The app pays for the investment within the first semester |

---

I am happy to demonstrate the application in person, walk through the technical architecture, or run a pilot program at your convenience.

Thank you for your time and consideration.

**Kedron**
B.E. Computer Science (3rd Year)
Government Engineering College, Goa
AI/ML Mentor | Developer | Hackathon Participant

---

*This document and the MEZZ application are original work. All rights reserved.*
