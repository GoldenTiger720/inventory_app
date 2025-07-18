# Inventory & Sales Mobile App

A robust, cross-platform mobile application built with Flutter for streamlining sales and inventory management operations. Compatible with both iOS and Android devices.

## 🚀 Features

### 📱 Core Functionality

#### 1. Price Lookup System
- **Barcode Scanning**: Integrated camera-based barcode scanner
- **Product Search**: Search by product code or description
- **Real-time Price Display**: Instant price and product information
- **Add to Orders**: Direct integration with POS system

#### 2. Sales Integration
- **SGW System Authentication**: Secure login linking sales to employee/cashier
- **Order Queue Management**: Add/remove products from exclusive POS
- **Quantity Selection**: Flexible quantity input with validation
- **Real-time Sync**: Orders transfer to user's laptop/computer

#### 3. Inventory Counting System
- **Dual Counting Modes**:
  - **Individual**: Count items one by one using product codes
  - **List View**: Bulk counting with grid layout
- **Three-Tab Interface**:
  - 📦 **Individual Count**: Focused item-by-item counting
  - 📝 **List to Count**: All pending items with search/filter
  - ✅ **Counted Items**: Completed counts with variance tracking

#### 4. Advanced Inventory Features
- **Variance Detection**: Automatic surplus/shortage identification
- **Real-time Statistics**: Live counting progress and summaries
- **Editable Fields**: Update product descriptions, locations, prices, and costs
- **Search & Filter**: Advanced filtering for large inventories
- **Recount Capability**: Easy recounting for accuracy verification

## 🎨 User Interface

### Modern Design Principles
- **Clean & Intuitive**: Minimalist design focused on usability
- **Responsive Layout**: Adaptive grid system for various screen sizes
- **Touch-Optimized**: Buttons and controls designed for mobile interaction
- **Visual Feedback**: Clear status indicators and progress tracking
- **Professional Color Scheme**: Blue primary with complementary accents

### Navigation Structure
- **Tab-based Interface**: Organized workflow navigation
- **Contextual Actions**: Relevant buttons and options per screen
- **Search Integration**: Built-in search across all modules
- **Quick Access**: Direct barcode scanning from multiple screens

## 🔧 Technical Architecture

### Framework & Dependencies
- **Flutter**: Cross-platform mobile development framework
- **BLoC Pattern**: State management for reactive programming
- **SQLite (sqflite)**: Local database for data storage
- **Dio**: HTTP client for API communication (optional)
- **Mobile Scanner**: Camera-based barcode scanning
- **Shared Preferences**: Local data persistence
- **Phosphor Icons**: Modern icon library
- **Crypto**: Password hashing for security

### Core Components
```
lib/
├── models/           # Data models (User, Product, InventoryItem, OrderItem)
├── services/         # Service layer with database and API integration
│   ├── api_service.dart      # API service with SQLite integration
│   └── database_helper.dart  # SQLite database operations
├── blocs/           # State management (Auth, Product, Order, Inventory)
├── screens/         # Main application screens
├── widgets/         # Reusable UI components
├── constants/       # App colors, themes, and configuration
└── main.dart        # Application entry point
```

### Database Architecture

#### SQLite Database Schema
The app uses SQLite for local data storage with the following tables:

**Users Table**
- Stores user authentication and profile information
- Password hashing using SHA-256 for security
- Supports multiple user roles

**Products Table**
- Pre-loaded with sample inventory items
- Supports barcode scanning and search functionality
- Tracks pricing, quantities, and locations

**Inventory Counts Table**
- Manages inventory counting sessions
- Tracks expected vs counted quantities
- Supports variance detection

**Order Items Table**
- Queue for POS integration
- Links products to users
- Maintains order history

### API Integration (Optional)
The app can also consume the following SGW system endpoints when available:

#### Authentication
- `POST /auth/login` - User authentication
- `POST /auth/register` - User registration
- `POST /auth/refresh` - Token refresh

#### Product Management
- `GET /products/code/{code}` - Get product by barcode/code
- `GET /products/search` - Search products by description
- `PUT /products/{id}` - Update product information

#### Order Management
- `POST /orders/queue` - Add product to order queue
- `DELETE /orders/queue/{productId}` - Remove product from queue

#### Inventory Management
- `POST /inventory/start-count` - Initialize inventory counting session
- `GET /inventory/items-for-count` - Retrieve items pending count
- `GET /inventory/counted-items` - Retrieve completed counts
- `PUT /inventory/count/{itemId}` - Update item count
- `POST /inventory/send-for-count` - Add item to counting list
- `DELETE /inventory/remove-from-count/{itemId}` - Remove from counting

## 🛠 Setup & Installation

### Prerequisites
- Flutter SDK (>=3.8.1)
- Android Studio / Xcode
- No external API required (uses local SQLite database)

### Installation Steps

1. **Clone the repository**
```bash
git clone <repository-url>
cd inventory_sales_app
```

2. **Install dependencies**
```bash
flutter pub get
```

3. **Build for Android**
```bash
flutter build apk --release
```

4. **Build for iOS**
```bash
flutter build ios --release
```

### Permissions Required
- **Camera**: For barcode scanning functionality
- **Internet**: For API communication
- **Network State**: For connectivity monitoring

## 📱 Usage Guide

### Getting Started
1. **Sign Up**: Create a new account with your details and role
2. **Login**: Use your SGW system credentials (or sign up if you're new)
3. **Dashboard**: Select from main features (Price Lookup, Inventory Count)
4. **Barcode Scanning**: Tap camera icon on any search field
5. **Navigation**: Use tab bars and back buttons for navigation

### Account Management
#### Creating an Account
1. On the login screen, tap "Sign Up"
2. Fill in your full name, email, and password
3. Select your role (cashier, manager, supervisor, etc.)
4. Tap "Create Account" to register
5. You'll be automatically logged in and taken to the dashboard

#### Logging In
1. Enter your email and password on the login screen
2. Tap "Sign In" to access the app
3. If you don't have an account, tap "Sign Up" to create one

### Price Lookup Workflow
1. Navigate to Price Lookup from dashboard
2. Enter product code or scan barcode
3. View product information and current price
4. Add to order with desired quantity
5. Confirm addition to POS queue

### Inventory Counting Workflow

#### Individual Mode
1. Switch to Individual Count tab
2. Enter or scan product code
3. Adjust quantity using +/- buttons or manual entry
4. Save count to move item to "Counted" list

#### List Mode
1. Switch to "List to Count" tab
2. Browse pending items in grid view
3. Tap "Count" button on item cards
4. Enter counted quantity in dialog
5. Confirm to update count

#### Review Counted Items
1. Switch to "Counted Items" tab
2. Review all completed counts
3. Check variance indicators (surplus/shortage)
4. Recount items if needed
5. Remove incorrect counts

## 🔐 Security Features

- **JWT Authentication**: Secure token-based authentication
- **Automatic Token Refresh**: Seamless session management
- **Local Storage Encryption**: Secure credential storage
- **Network Security**: HTTPS communication only
- **Session Management**: Automatic logout on token expiry

## 🚀 Performance Features

- **Lazy Loading**: Efficient memory management
- **Image Optimization**: Optimized asset loading
- **Network Caching**: Reduced API calls
- **Responsive Design**: Smooth performance across devices
- **Background Processing**: Non-blocking operations

## 🧪 Testing

Run the test suite:
```bash
flutter test
```

Analyze code quality:
```bash
flutter analyze
```

## 📄 License

This project is proprietary software developed for internal use.

## 🤝 Support

For technical support or feature requests, please contact the development team.

---

**Version**: 1.0.0  
**Last Updated**: 2024  
**Platform**: iOS & Android  
**Framework**: Flutter 3.8.1+