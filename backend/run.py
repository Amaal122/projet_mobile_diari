"""
Diari Backend - Main Entry Point
=================================
Run the Flask application
"""

from application import create_app

if __name__ == '__main__':
    app = create_app()
    print("\n" + "="*60)
    print("🍽️  DIARI BACKEND SERVER")
    print("="*60)
    print("Server running at: http://localhost:5000")
    print("API Base URL: http://localhost:5000/api")
    print("Health Check: http://localhost:5000/api/health")
    print("\n📚 API Documentation: backend/API_DOCUMENTATION.md")
    print("📊 Feature Report: backend/COMPLETE_IMPROVEMENTS.md")
    print("="*60 + "\n")
    
    app.run(
        host='0.0.0.0',
        port=5000,
        debug=True
    )
