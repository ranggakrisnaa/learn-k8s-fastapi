from fastapi import FastAPI, HTTPException 
from prometheus_client import Counter, Histogram, generate_latest, CONTENT_TYPE_LATEST
from fastapi.responses import Response
from starlette.routing import Match
import time

app = FastAPI()

# Prometheus metrics
request_count = Counter('fastapi_requests_total', 'Total requests', ['method', 'endpoint', 'status'])
request_duration = Histogram('fastapi_request_duration_seconds', 'Request duration', ['method', 'endpoint'])


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


@app.get("/metrics")
async def metrics():
    return Response(generate_latest(), media_type=CONTENT_TYPE_LATEST)


@app.middleware("http")
async def metrics_middleware(request, call_next):
    if request.url.path == "/metrics":
        return await call_next(request)

    start_time = time.time()
    status_code = 500

    try:
        response = await call_next(request)
        status_code = response.status_code
        return response
    except Exception:
        status_code = 500
        raise
    finally:
        process_time = time.time() - start_time

        # Gunakan route template, bukan raw path
        endpoint = "unknown"
        for route in request.app.router.routes:
            match, _ = route.matches(request.scope)
            if match == Match.FULL:
                endpoint = route.path
                break

        request_count.labels(
            method=request.method,
            endpoint=endpoint,
            status=status_code
        ).inc()

        request_duration.labels(
            method=request.method,
            endpoint=endpoint
        ).observe(process_time)
