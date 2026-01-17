from fastapi import FastAPI, HTTPException 

app = FastAPI()


@app.get("/")
async def root():
    return {"message": "Hello World"}


@app.get("/health")
async def health():
    return {"status": "healthy"}

@app.get("/items/")
async def read_items(data: str) -> dict[str, str | int | bool]:
        
    # Boolean
    if data.lower() in ("true", "false"):
        return {
            "type": "boolean",
            "value": data.lower() == "true"
        }

    # Integer
    if data.isdigit():
        return {
            "type": "integer",
            "value": int(data)
        }

    try:
        float(data)
        raise HTTPException(
            status_code=400,
            detail=f"Float values are not allowed: {data}"
        )
    except ValueError:
        pass

    # Special characters
    if not data.isalnum():
        return {
            "type": "special_characters",
            "value": data
        }

    # String
    return {
        "type": "string",
        "value": data
    }