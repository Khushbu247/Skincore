from fastapi.responses import JSONResponse


def success(data):
    return JSONResponse(
        status_code=200,
        content={
            "success": True,
            "data": data
        }
    )


def error(message, status=400):
    return JSONResponse(
        status_code=status,
        content={
            "success": False,
            "message": message
        }
    )