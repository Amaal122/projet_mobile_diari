"""
Error Handling Utilities
=========================
Standardized error responses and error handling
"""

from flask import jsonify
from functools import wraps
import traceback


class APIError(Exception):
    """Base API exception with status code"""
    def __init__(self, message, status_code=400, payload=None):
        super().__init__()
        self.message = message
        self.status_code = status_code
        self.payload = payload
    
    def to_dict(self):
        rv = dict(self.payload or ())
        rv['error'] = self.message
        rv['status'] = self.status_code
        return rv


class ValidationError(APIError):
    """400 Bad Request - Invalid input"""
    def __init__(self, message, payload=None):
        super().__init__(message, 400, payload)


class UnauthorizedError(APIError):
    """401 Unauthorized - Missing/invalid token"""
    def __init__(self, message="Unauthorized", payload=None):
        super().__init__(message, 401, payload)


class ForbiddenError(APIError):
    """403 Forbidden - Insufficient permissions"""
    def __init__(self, message="Access denied", payload=None):
        super().__init__(message, 403, payload)


class NotFoundError(APIError):
    """404 Not Found - Resource doesn't exist"""
    def __init__(self, message="Resource not found", payload=None):
        super().__init__(message, 404, payload)


class ConflictError(APIError):
    """409 Conflict - Resource conflict"""
    def __init__(self, message="Resource conflict", payload=None):
        super().__init__(message, 409, payload)


class RateLimitError(APIError):
    """429 Too Many Requests"""
    def __init__(self, message="Rate limit exceeded", payload=None):
        super().__init__(message, 429, payload)


class ServerError(APIError):
    """500 Internal Server Error"""
    def __init__(self, message="Internal server error", payload=None):
        super().__init__(message, 500, payload)


class ServiceUnavailableError(APIError):
    """503 Service Unavailable"""
    def __init__(self, message="Service unavailable", payload=None):
        super().__init__(message, 503, payload)


def handle_error(error):
    """Central error handler - returns standardized JSON error response"""
    if isinstance(error, APIError):
        response = jsonify(error.to_dict())
        response.status_code = error.status_code
        return response
    
    # Handle unexpected errors
    print(f"Unexpected error: {error}")
    traceback.print_exc()
    
    response = jsonify({
        'error': 'An unexpected error occurred',
        'status': 500
    })
    response.status_code = 500
    return response


def with_error_handling(f):
    """Decorator to add error handling to route functions"""
    @wraps(f)
    def decorated(*args, **kwargs):
        try:
            return f(*args, **kwargs)
        except APIError as e:
            return handle_error(e)
        except Exception as e:
            return handle_error(ServerError(str(e)))
    
    return decorated


def validate_required_fields(data, required_fields):
    """Validate that all required fields are present in request data"""
    missing = [field for field in required_fields if field not in data or not data[field]]
    
    if missing:
        raise ValidationError(
            f"Missing required fields: {', '.join(missing)}",
            payload={'missing_fields': missing}
        )


def validate_rating(rating):
    """Validate rating is between 1 and 5"""
    if not isinstance(rating, (int, float)) or not (1 <= rating <= 5):
        raise ValidationError("Rating must be a number between 1 and 5")


def validate_email(email):
    """Basic email validation"""
    import re
    pattern = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'
    if not re.match(pattern, email):
        raise ValidationError("Invalid email format")


def validate_phone(phone):
    """Basic phone validation"""
    import re
    # Allow +216 country code and 8-digit numbers
    pattern = r'^\+?216?[0-9]{8}$'
    if not re.match(pattern, phone.replace(' ', '')):
        raise ValidationError("Invalid phone number format")


def validate_price(price):
    """Validate price is positive number"""
    if not isinstance(price, (int, float)) or price < 0:
        raise ValidationError("Price must be a positive number")


def validate_quantity(quantity):
    """Validate quantity is positive integer"""
    if not isinstance(quantity, int) or quantity < 1:
        raise ValidationError("Quantity must be a positive integer")


def validate_order_status(status):
    """Validate order status is valid"""
    valid_statuses = ['pending', 'accepted', 'preparing', 'ready', 'delivering', 'delivered', 'cancelled']
    if status not in valid_statuses:
        raise ValidationError(
            f"Invalid status. Must be one of: {', '.join(valid_statuses)}",
            payload={'valid_statuses': valid_statuses}
        )


def validate_pagination(page, per_page, max_per_page=100):
    """Validate pagination parameters"""
    try:
        page = int(page) if page else 1
        per_page = int(per_page) if per_page else 10
    except (ValueError, TypeError):
        raise ValidationError("Page and per_page must be integers")
    
    if page < 1:
        raise ValidationError("Page must be >= 1")
    
    if per_page < 1 or per_page > max_per_page:
        raise ValidationError(f"per_page must be between 1 and {max_per_page}")
    
    return page, per_page


def check_resource_ownership(user_id, resource_owner_id):
    """Check if user owns the resource"""
    if user_id != resource_owner_id:
        raise ForbiddenError("You don't have permission to access this resource")


def check_database_available(db):
    """Check if database connection is available"""
    if not db:
        raise ServiceUnavailableError("Database unavailable. Please try again later.")


# Error messages in Arabic
ERROR_MESSAGES_AR = {
    'unauthorized': 'غير مصرح',
    'forbidden': 'غير مسموح',
    'not_found': 'غير موجود',
    'invalid_input': 'بيانات غير صحيحة',
    'rate_limit': 'تم تجاوز الحد المسموح من الطلبات',
    'server_error': 'خطأ في الخادم',
    'service_unavailable': 'الخدمة غير متاحة',
    'order_cancelled': 'تم إلغاء الطلب',
    'order_not_cancellable': 'لا يمكن إلغاء الطلب',
    'payment_failed': 'فشل الدفع',
    'insufficient_balance': 'رصيد غير كافٍ',
}


def get_error_message(key, lang='en'):
    """Get error message in specified language"""
    if lang == 'ar':
        return ERROR_MESSAGES_AR.get(key, key)
    return key


def success_response(data=None, message=None, status_code=200):
    """Standardized success response"""
    response = {'success': True}
    
    if message:
        response['message'] = message
    
    if data is not None:
        if isinstance(data, dict):
            response.update(data)
        else:
            response['data'] = data
    
    return jsonify(response), status_code


def register_error_handlers(app):
    """Register error handlers with Flask app"""
    
    @app.errorhandler(APIError)
    def handle_api_error(error):
        return handle_error(error)
    
    @app.errorhandler(400)
    def handle_bad_request(error):
        return jsonify({'error': 'Bad request', 'status': 400}), 400
    
    @app.errorhandler(401)
    def handle_unauthorized(error):
        return jsonify({'error': 'Unauthorized', 'status': 401}), 401
    
    @app.errorhandler(403)
    def handle_forbidden(error):
        return jsonify({'error': 'Forbidden', 'status': 403}), 403
    
    @app.errorhandler(404)
    def handle_not_found(error):
        return jsonify({'error': 'Not found', 'status': 404}), 404
    
    @app.errorhandler(429)
    def handle_rate_limit(error):
        return jsonify({'error': 'Rate limit exceeded', 'status': 429}), 429
    
    @app.errorhandler(500)
    def handle_server_error(error):
        print(f"500 error: {error}")
        traceback.print_exc()
        return jsonify({'error': 'Internal server error', 'status': 500}), 500
    
    @app.errorhandler(503)
    def handle_service_unavailable(error):
        return jsonify({'error': 'Service unavailable', 'status': 503}), 503
    
    @app.errorhandler(Exception)
    def handle_unexpected_error(error):
        print(f"Unexpected error: {error}")
        traceback.print_exc()
        return jsonify({'error': 'An unexpected error occurred', 'status': 500}), 500
