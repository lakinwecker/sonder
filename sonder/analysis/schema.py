"""
json schema schemas for our input/outputs
"""
# TODO: welp, this wasn't nearly as succinct as I was hoping. :P
FishnetRequest = {
    "title": "FishnetRequest",
    "type" : "object",
    "required": ["fishnet", "engine"],
    "properties" : {
        "fishnet" : {
            "type" : "object",
            "required": ["version", "python", "apikey"],
            "properties": {
                "version": {"type": "string"},
                "python": {"type": "string"},
                "apikey": {"type": "string"}
            }
        },
        "engine" : {
            "type" : "object",
            "required": ["name", "options"],
            "properties": {
                "name": {"type": "string"},
                "options": {
                    "type": "object",
                    "properties": {
                        "hash": {"type": "string"}, # TODO: string?!
                        "threads": {"type": "string"} # TODO: string?!
                    }
                }
            }
        }
    }
}
FishnetJob = {
    "title": "FishnetJob",
    "type" : "object",
    "required": ["work", "position", "variant", "moves"],
    "properties" : {
        "work" : {
            "type" : "object",
            "required": ["type", "id"],
            "properties": {
                "type": {"type": "string"},
                "id": {"type": "string"}
            }
        },
        "game_id": {"type": "string"},
        "position": {"type": "string"},
        "variant": {"type": "string"},
        "moves": {"type": "string"},
        "nodes": { "type": "number", "minimum": 0 },
        "skipPositions": {
            "type": "array",
            "items": {"type": "number"},
        }
    }
}
