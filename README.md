# 🛒 Multi-Market Flutter E-Commerce Solution

[![Flutter](https://img.shields.io/badge/Flutter-3.0%2B-blue?logo=flutter)](https://flutter.dev)
[![Supabase](https://img.shields.io/badge/Supabase-Backend-green?logo=supabase)](https://supabase.com)
[![License](https://img.shields.io/badge/License-MIT-purple.svg)](LICENSE)
[![Language](https://img.shields.io/badge/Language-Turkish-red)](README.tr.md)

> **[🇹🇷 Türkçe README için buraya tıklayın](README.tr.md)**

A comprehensive, full-stack e-commerce application built with **Flutter** and **Supabase**. This project features a unique **geolocation-based multi-market architecture**, allowing users to shop from the nearest store while providing market owners with a dedicated **Real-Time Admin Panel**.

## ✨ Key Features

### 📱 User App (Customer Experience)
* **📍 Location-Based Market Selection:** Users view and select active markets on an interactive map (`flutter_map` & `geolocator`). Automatically sorts by distance.
* **🛍️ Smart Shopping Cart:**
    * Dynamic delivery fee calculation.
    * Free delivery thresholds and minimum order limits managed by the market.
    * **Coupon System:** Supports percentage (%) and fixed amount (₺) discounts.
* **📦 Order Tracking:**
    * Real-time status updates (Preparing, On the Way, Delivered).
    * Live in-app notifications via Supabase Realtime.
* **🔎 Advanced Product Discovery:** Category filtering, search with sorting (Price, Discount), and Hero animations.
* **👤 User Profile:** Address management, order history, and secure password updates.

### 🛠️ Admin Panel (Market Owner Dashboard)
* **🛡️ Role-Based Access:** Automatically detects market owners upon login and redirects to the Admin Dashboard.
* **🔔 Real-Time Order Management:**
    * **Audio Notifications:** Plays a sound alert when a new order arrives.
    * Kanban-style status management (Pending -> Active -> Delivered/Cancelled).
    * View customer details and order snapshots.
* **📊 Analytics:** Visual revenue reports (Daily/Monthly) split by Cash vs. Credit Card.
* **⚙️ Store Management:**
    * One-tap Open/Close shop mechanism.
    * Manage delivery fees and limits instantly.
    * **Inventory & Campaigns:** Full CRUD for products and discount coupons.

### 🔧 System Capabilities
* **Maintenance Mode:** Remotely lock the app during server updates via Supabase settings.
* **Force Update:** Checks app version against the cloud and prompts users to update if critical changes are made.
* **Robust Backend:** Powered by Supabase Auth, Database, and Storage.

---

## 🏗️ Tech Stack

* **Frontend:** Flutter (Dart)
* **State Management:** Provider
* **Backend:** Supabase (PostgreSQL, Auth, Realtime, Storage)
* **Maps:** `flutter_map`, `latlong2`, `geolocator`
* **Utilities:** `audioplayers` (notifications), `url_launcher`, `package_info_plus`, `flutter_dotenv`
