from fastapi import FastAPI

from api.router import router

app = FastAPI(
    title="SkinCore API",
    version="1.0.0"
)

app.include_router(router)


@app.get("/")
def home():
    return {
        "message": "SkinCore Backend is running!"
    }