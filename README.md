# 🛒 Multi-Market Flutter E-Commerce Solution

[![Flutter](https://img.shields.io/badge/Flutter-3.0%2B-blue?logo=flutter)](https://flutter.dev)
[![Supabase](https://img.shields.io/badge/Supabase-Backend-green?logo=supabase)](https://supabase.com)
[![Language](https://img.shields.io/badge/Language-Turkish-red)](README.tr.md)

> **[🇹🇷 Türkçe README için buraya tıklayın](README.tr.md)**

A comprehensive, full-stack e-commerce application built with **Flutter** and **Supabase**. This project features a unique **geolocation-based multi-market architecture**, allowing users to shop from the nearest store while providing market owners with a dedicated **Real-Time Admin Panel**.

## 🚀 Key Features

### 📱 Customer App Experience
* **📍 Location-Based Market Selection:** Automatically detects user location, calculates distances using the Haversine formula, and lists the nearest active markets on an interactive map.
* **🛍️ Smart Cart Logic:**
    * **Dynamic Delivery Fees:** Automatically calculates fees based on market rules.
    * **Free Shipping Thresholds:** Encourages higher basket value by checking free delivery limits.
    * **Coupon Engine:** Supports both percentage-based (%) and fixed-amount (₺) discount codes with minimum basket requirements.
* **🔎 Advanced Product Discovery:**
    * Filter products by categories.
    * Sort by Price (Ascending/Descending) or Discounted items first.
    * Real-time search functionality.
* **📦 Order Tracking:**
    * **Live Status Updates:** Users can track their order status (Preparing, On the Way, Delivered) in real-time via Supabase streams.
    * **Order History:** Detailed view of past orders with snapshot data protection.
* **👤 Secure Profile Management:** Address book management, secure password updates, and profile editing.

### 🛠️ Market Owner (Admin) Dashboard
* **🛡️ Role-Based Access Control:** The system automatically detects if a logged-in user is a "Market Owner" and redirects them to the Admin Dashboard instead of the shopping interface.
* **🔔 Real-Time Order Command Center:**
    * **Audio Alerts:** Plays a notification sound instantly when a new order arrives.
    * **Kanban Workflow:** Manage orders through statuses: *Pending Approval -> Preparing -> On the Way -> Delivered*.
    * **Customer Snapshots:** View customer details (Name, Phone, Address) as they were at the time of the order.
* **📊 Revenue Analytics:**
    * Visual reports for Daily and Monthly revenue.
    * breakdown of sales by **Cash** vs. **Credit Card**.
    * "Best Sellers" analysis to track top-performing products.
* **⚙️ Store Operations:**
    * **One-Tap Shop Toggle:** Instantly open or close the market availability.
    * **Dynamic Service Limits:** Update delivery fees and minimum order amounts instantly without app updates.
* **📦 Inventory & Campaigns:** Full CRUD (Create, Read, Update, Delete) capabilities for Products and Discount Coupons.

### 🔧 System & Infrastructure
* **Maintenance Mode:** Remotely lock the app for all users during server maintenance via Supabase settings.
* **Force Update:** Checks the installed version against the cloud config and forces users to update if the version is obsolete.
* **Supabase Realtime:** Uses PostgreSQL Change Data Capture (CDC) for instant data synchronization across all devices.

---

## 🏗️ Tech Stack

* **Frontend:** Flutter (Dart)
* **Backend:** Supabase (PostgreSQL, Auth, Storage, Edge Functions)
* **State Management:** Provider
* **Maps:** `flutter_map`, `latlong2`, `geolocator`
* **Utilities:** `audioplayers` (notifications), `url_launcher`, `package_info_plus`, `flutter_dotenv`

---

## 📧 Contact

**Sami Erdoğmuş** - [GitHub Profile](https://github.com/samierdgms)
