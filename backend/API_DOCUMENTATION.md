# Diari API Documentation

## Base URL
```
http://localhost:5000/api
```

## Authentication
All protected endpoints require a Bearer token in the Authorization header:
```
Authorization: Bearer <firebase_jwt_token>
```

---

## Authentication Endpoints

### POST /auth/verify
Verify Firebase ID token server-side
- **Body**: `{ "token": string }`
- **Response**: `{ "valid": boolean, "uid": string, "email": string }`

### GET /auth/profile
Get current user profile
- **Auth**: Required
- **Response**: User profile object

---

## Order Endpoints

### POST /orders
Create a new order
- **Auth**: Required
- **Body**:
```json
{
  "items": [{
    "dishId": "string",
    "dishName": "string",
    "quantity": number,
    "price": number,
    "cookerId": "string"
  }],
  "deliveryAddress": "string",
  "deliveryNotes": "string",
  "paymentMethod": "cash|card"
}
```
- **Response**: `{ "success": true, "orderId": string, "total": number }`

### GET /orders
Get all orders for current user
- **Auth**: Required
- **Response**: `{ "orders": [...] }`

### GET /orders/:orderId
Get single order by ID
- **Auth**: Required
- **Response**: Order object

### POST /orders/:orderId/cancel
Cancel an order
- **Auth**: Required
- **Response**: `{ "success": true }`

### PUT /orders/:orderId/status
Update order status (chef/admin only)
- **Auth**: Required (Chef)
- **Body**: `{ "status": "pending|accepted|ready|delivering|delivered|cancelled" }`
- **Response**: `{ "success": true }`

---

## Cart Endpoints

### GET /cart
Get current user's cart
- **Auth**: Required
- **Response**: `{ "items": [...], "total": number }`

### POST /cart/add
Add item to cart
- **Auth**: Required
- **Body**: `{ "dishId": string, "quantity": number }`
- **Response**: `{ "success": true, "itemCount": number, "total": number }`

### PUT /cart/update
Update cart item quantity
- **Auth**: Required
- **Body**: `{ "dishId": string, "quantity": number }`
- **Response**: `{ "success": true }`

### DELETE /cart/remove/:dishId
Remove item from cart
- **Auth**: Required
- **Response**: `{ "success": true }`

### DELETE /cart/clear
Clear entire cart
- **Auth**: Required
- **Response**: `{ "success": true }`

---

## Review Endpoints

### POST /reviews
Create a review
- **Auth**: Required
- **Body**: `{ "dishId": string, "rating": 1-5, "comment": string }`
- **Response**: `{ "success": true, "reviewId": string }`

### GET /reviews/dish/:dishId
Get all reviews for a dish
- **Query**: `?page=1&per_page=10`
- **Response**: Paginated reviews

### PUT /reviews/:reviewId
Edit a review
- **Auth**: Required (must be review owner)
- **Body**: `{ "rating": 1-5, "comment": string }`
- **Response**: `{ "success": true }`

### DELETE /reviews/:reviewId
Delete a review
- **Auth**: Required (owner or admin)
- **Response**: `{ "success": true }`

### POST /reviews/:reviewId/report
Report a review
- **Auth**: Required
- **Body**: `{ "reason": string }`
- **Response**: `{ "success": true }`

---

## Notification Endpoints

### POST /notifications/register
Register FCM token
- **Auth**: Required
- **Body**: `{ "token": string }`
- **Response**: `{ "success": true }`

### GET /notifications/settings
Get notification preferences
- **Auth**: Required
- **Response**: Notification settings object

### PUT /notifications/settings
Update notification preferences
- **Auth**: Required
- **Body**: `{ "orderUpdates": boolean, "promotions": boolean, etc. }`
- **Response**: `{ "success": true }`

### POST /notifications/test
Send test notification
- **Auth**: Required
- **Response**: `{ "success": true }`

---

## Payment Endpoints

### GET /payments/methods
List available payment methods
- **Auth**: Required
- **Response**: `{ "methods": [...] }`

### POST /payments/intent
Create payment intent
- **Auth**: Required
- **Body**: `{ "amount": number, "currency": "TND" }`
- **Response**: `{ "clientSecret": string, "paymentIntentId": string }`

### POST /payments/confirm
Confirm payment
- **Auth**: Required
- **Body**: `{ "paymentIntentId": string }`
- **Response**: `{ "success": true, "status": string }`

### GET /payments/history
Get payment history
- **Auth**: Required
- **Response**: `{ "payments": [...] }`

### POST /payments/refund
Request refund
- **Auth**: Required
- **Body**: `{ "paymentId": string, "reason": string }`
- **Response**: `{ "success": true }`

---

## Admin Endpoints

### GET /admin/stats
Get platform statistics
- **Auth**: Required (Admin)
- **Response**: Platform-wide stats

### GET /admin/users
List all users
- **Auth**: Required (Admin)
- **Query**: `?page=1&limit=20`
- **Response**: Paginated user list

### POST /admin/users/:userId/ban
Ban a user
- **Auth**: Required (Admin)
- **Body**: `{ "reason": string }`
- **Response**: `{ "success": true }`

### POST /admin/users/:userId/unban
Unban a user
- **Auth**: Required (Admin)
- **Response**: `{ "success": true }`

### GET /admin/chefs
List all chefs with stats
- **Auth**: Required (Admin)
- **Response**: Chef list with revenue/orders data

### POST /admin/chefs/:chefId/verify
Verify a chef account
- **Auth**: Required (Admin)
- **Response**: `{ "success": true }`

### GET /admin/orders
List all platform orders
- **Auth**: Required (Admin)
- **Query**: `?status=pending&limit=50`
- **Response**: Order list

### GET /admin/reports
Get reported content
- **Auth**: Required (Admin)
- **Response**: `{ "reports": [...] }`

### POST /admin/reports/:reportId/resolve
Resolve a report
- **Auth**: Required (Admin)
- **Body**: `{ "type": "review|chef", "action": "dismiss|remove|ban" }`
- **Response**: `{ "success": true }`

---

## Analytics Endpoints (Chef Only)

### GET /analytics/chef/overview
Get chef dashboard overview
- **Auth**: Required (Chef)
- **Query**: `?period=30` (days)
- **Response**: Revenue, orders, dishes stats

### GET /analytics/chef/popular-dishes
Get chef's most popular dishes
- **Auth**: Required (Chef)
- **Query**: `?limit=10`
- **Response**: `{ "popularDishes": [...] }`

### GET /analytics/chef/revenue-chart
Get revenue chart data
- **Auth**: Required (Chef)
- **Query**: `?days=30`
- **Response**: `{ "chartData": [...] }` (daily breakdown)

### GET /analytics/chef/customer-insights
Get customer behavior insights
- **Auth**: Required (Chef)
- **Response**: Customer stats, repeat rate, top customers

### GET /analytics/chef/peak-hours
Get peak ordering hours
- **Auth**: Required (Chef)
- **Response**: `{ "peakHours": [...] }` (hourly breakdown)

---

## Upload Endpoints

### POST /upload/image
Upload single image
- **Auth**: Required
- **Body**: multipart/form-data with `file` field
- **Form**: `context=dish|profile|chef`
- **Response**: `{ "success": true, "imageUrl": string }`

### POST /upload/image/multiple
Upload multiple images
- **Auth**: Required
- **Body**: multipart/form-data with `files[]` field (max 5)
- **Response**: `{ "success": true, "images": [...], "count": number }`

### POST /upload/image/delete
Delete an image
- **Auth**: Required
- **Body**: `{ "filename": string }`
- **Response**: `{ "success": true }`

---

## Dish Endpoints

### GET /dishes
List all dishes
- **Query**: `?category=breakfast&city=tunis&search=couscous`
- **Response**: Dish list

### GET /dishes/:dishId
Get single dish
- **Response**: Dish object with chef info

### GET /dishes/cooker/:cookerId
Get all dishes by a chef
- **Response**: Dish list

---

## Cooker Endpoints

### GET /cookers
List all active cookers
- **Response**: Cooker list

### GET /cookers/:cookerId
Get cooker profile
- **Response**: Cooker object

---

## Error Responses

All endpoints may return these error responses:

### 400 Bad Request
```json
{
  "error": "Description of what went wrong"
}
```

### 401 Unauthorized
```json
{
  "error": "Missing or invalid authorization header"
}
```

### 403 Forbidden
```json
{
  "error": "Access denied. Insufficient permissions."
}
```

### 404 Not Found
```json
{
  "error": "Resource not found"
}
```

### 429 Rate Limit
```json
{
  "error": "Rate limit exceeded. Please try again later."
}
```

### 500 Internal Server Error
```json
{
  "error": "Error description"
}
```

### 503 Service Unavailable
```json
{
  "error": "Database unavailable"
}
```

---

## Rate Limiting

- **Limit**: 100 requests per minute per IP
- **Response**: 429 Too Many Requests when exceeded
- **Reset**: Rolling window of 60 seconds

---

## Auto-Notifications

The system automatically sends push notifications for:
- **New Order**: Notifies chef when order is placed
- **Order Accepted**: Notifies customer when chef accepts
- **Order Ready**: Notifies customer when food is ready
- **Out for Delivery**: Notifies customer when order is on the way
- **Delivered**: Notifies customer on successful delivery
- **Cancelled**: Notifies the other party when order is cancelled
- **New Review**: Notifies chef when they receive a review
- **Payment Confirmed**: Notifies chef when payment is confirmed

---

## Notes

1. All timestamps are in ISO 8601 format
2. Prices are in Tunisian Dinar (TND)
3. Firebase handles user authentication - this API verifies tokens
4. Images are stored in Firebase Storage
5. Firestore is used for all data persistence
