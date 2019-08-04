"""
json schema schemas for our input/outputs
"""
UserLoginResult = {
    "title": "UserLoginResult",
    "type" : "object",
    "required": ["preferences"],
    "properties" : {
        "preferences" : {
            "type" : "object",
            "required": ["background"],
            "properties": {
                "background": {"type": "string"},
            }
        }
    }
}
